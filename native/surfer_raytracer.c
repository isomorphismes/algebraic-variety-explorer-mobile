/*
 * SURFER numerical ray-tracer core.
 *
 * Derived from Christian Stussak's 2008 jsurf renderer, Apache-2.0.
 * Android adaptation copyright 2026 Algebraic Variety Explorer contributors.
 *
 * This file begins at the PreparedSurface boundary. Formula parsing, semantic
 * checking, expansion, differentiation, and canonical sparse construction stay
 * above this layer. The numerical layer intentionally uses binary64 where the
 * Java oracle uses double and binary32 where its color/material path uses float.
 */

#include "surfer_raytracer.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

typedef struct {
    double *coefficients;
    size_t length;
} univariate_polynomial;

typedef enum {
    SMALLEST_ROOT,
    LARGEST_ROOT
} which_root;

/*
 * Stussak's DescartesRootFinder calls these PolyInterval candidates.
 * The candidate carries the transformed polynomial together with the interval
 * that transformation represents.
 */
typedef struct {
    double *coefficients;
    size_t length;
    bool shift_by_one_when_used;
    double lower;
    double upper;
} descartes_interval;

typedef struct {
    descartes_interval *items;
    size_t length;
    size_t capacity;
} descartes_candidate_stack;

typedef struct {
    double half_u;
    double half_v;
    surfer_mat3 camera_to_surface;
    surfer_mat3 surface_normal_to_camera;
    surfer_vec3 surface_u;
    surfer_vec3 surface_v;
    surfer_vec3 surface_direction;
} orthographic_view;

static surfer_vec3 add_vectors(surfer_vec3 left, surfer_vec3 right)
{
    surfer_vec3 result = {
        left.x + right.x,
        left.y + right.y,
        left.z + right.z
    };
    return result;
}

static surfer_vec3 subtract_vectors(surfer_vec3 left, surfer_vec3 right)
{
    surfer_vec3 result = {
        left.x - right.x,
        left.y - right.y,
        left.z - right.z
    };
    return result;
}

static surfer_vec3 scale_vector(surfer_vec3 value, double scale)
{
    surfer_vec3 result = {
        value.x * scale,
        value.y * scale,
        value.z * scale
    };
    return result;
}

static double dot_product(surfer_vec3 left, surfer_vec3 right)
{
    return left.x * right.x + left.y * right.y + left.z * right.z;
}

static double length_of_vector(surfer_vec3 value)
{
    return sqrt(dot_product(value, value));
}

static surfer_vec3 normalize_vector(surfer_vec3 value)
{
    const double length = length_of_vector(value);
    if (length == 0.0) {
        return value;
    }
    return scale_vector(value, 1.0 / length);
}

static surfer_vec3 point_on_ray_at_parameter(surfer_ray ray, double t)
{
    return add_vectors(ray.origin, scale_vector(ray.direction, t));
}

static surfer_vec3 apply_matrix_to_vector(surfer_mat3 matrix, surfer_vec3 value)
{
    surfer_vec3 result = {
        matrix.m00 * value.x + matrix.m01 * value.y + matrix.m02 * value.z,
        matrix.m10 * value.x + matrix.m11 * value.y + matrix.m12 * value.z,
        matrix.m20 * value.x + matrix.m21 * value.y + matrix.m22 * value.z
    };
    return result;
}

static surfer_mat3 transpose_matrix(surfer_mat3 matrix)
{
    surfer_mat3 result = {
        matrix.m00, matrix.m10, matrix.m20,
        matrix.m01, matrix.m11, matrix.m21,
        matrix.m02, matrix.m12, matrix.m22
    };
    return result;
}

static surfer_mat3 yaw_then_pitch_rotation(double yaw, double pitch)
{
    const double cy = cos(yaw);
    const double sy = sin(yaw);
    const double cp = cos(pitch);
    const double sp = sin(pitch);

    /* Matrix4d yawRotation.rotY(yaw); yawRotation.mul(pitchRotation.rotX(pitch)). */
    surfer_mat3 result = {
        cy, sy * sp, sy * cp,
        0.0, cp, -sp,
        -sy, cy * sp, cy * cp
    };
    return result;
}

static float clamp_float_between(float value, float lower, float upper)
{
    if (value < lower) {
        return lower;
    }
    if (value > upper) {
        return upper;
    }
    return value;
}

static surfer_color add_scaled_color(
    surfer_color color,
    float scale,
    surfer_color addition)
{
    surfer_color result = {
        color.red + scale * addition.red,
        color.green + scale * addition.green,
        color.blue + scale * addition.blue
    };
    return result;
}

static surfer_color multiply_colors(surfer_color left, surfer_color right)
{
    surfer_color result = {
        left.red * right.red,
        left.green * right.green,
        left.blue * right.blue
    };
    return result;
}

static surfer_color scale_color(surfer_color color, float scale)
{
    surfer_color result = {
        color.red * scale,
        color.green * scale,
        color.blue * scale
    };
    return result;
}

static surfer_color clamp_color_to_maximum(surfer_color color, float maximum)
{
    color.red = clamp_float_between(color.red, 0.0f, maximum);
    color.green = clamp_float_between(color.green, 0.0f, maximum);
    color.blue = clamp_float_between(color.blue, 0.0f, maximum);
    return color;
}

static univariate_polynomial empty_univariate_polynomial(void)
{
    univariate_polynomial result = {NULL, 0};
    return result;
}

static void free_univariate_polynomial(univariate_polynomial polynomial)
{
    free(polynomial.coefficients);
}

static univariate_polynomial allocate_univariate_polynomial(size_t length)
{
    univariate_polynomial result = empty_univariate_polynomial();
    if (length == 0) {
        return result;
    }
    result.coefficients = calloc(length, sizeof(*result.coefficients));
    if (result.coefficients == NULL) {
        return empty_univariate_polynomial();
    }
    result.length = length;
    return result;
}

static univariate_polynomial copy_univariate_polynomial(const double *coefficients, size_t length)
{
    univariate_polynomial result = allocate_univariate_polynomial(length);
    if (length != 0 && result.coefficients == NULL) {
        return empty_univariate_polynomial();
    }
    if (length != 0) {
        memcpy(result.coefficients, coefficients, length * sizeof(*coefficients));
    }
    return result;
}

static size_t coefficient_count_without_trailing_zeroes(const univariate_polynomial *polynomial)
{
    size_t length = polynomial->length;
    while (length > 1 && polynomial->coefficients[length - 1] == 0.0) {
        --length;
    }
    return length;
}

static univariate_polynomial copy_without_trailing_zeroes(const univariate_polynomial *polynomial)
{
    return copy_univariate_polynomial(polynomial->coefficients, coefficient_count_without_trailing_zeroes(polynomial));
}

static double evaluate_univariate_polynomial_at(const univariate_polynomial *polynomial, double where)
{
    if (polynomial->length == 0) {
        return 0.0;
    }
    if (fabs(where) <= 1.0) {
        double result = polynomial->coefficients[polynomial->length - 1];
        for (size_t i = polynomial->length - 1; i-- > 0;) {
            result = result * where + polynomial->coefficients[i];
        }
        return result;
    }

    double result = polynomial->coefficients[0];
    for (size_t i = 1; i < polynomial->length; ++i) {
        result = result / where + polynomial->coefficients[i];
    }
    return result * pow(where, (double)(polynomial->length - 1));
}

static univariate_polynomial stretch_univariate_polynomial(
    const univariate_polynomial *polynomial,
    double factor)
{
    univariate_polynomial result = allocate_univariate_polynomial(polynomial->length);
    if (polynomial->length != 0 && result.coefficients == NULL) {
        return empty_univariate_polynomial();
    }
    double multiplier = 1.0;
    for (size_t i = 0; i < polynomial->length; ++i) {
        result.coefficients[i] = polynomial->coefficients[i] * multiplier;
        multiplier *= factor;
    }
    return result;
}

static double *deflate_zero_root(const double *coefficients, size_t length, size_t *new_length)
{
    if (length == 0) {
        *new_length = 0;
        return NULL;
    }
    *new_length = length - 1;
    if (*new_length == 0) {
        return NULL;
    }
    double *result = malloc(*new_length * sizeof(*result));
    if (result == NULL) {
        *new_length = 0;
        return NULL;
    }
    memcpy(result, coefficients + 1, *new_length * sizeof(*result));
    return result;
}

static double *shift_univariate_polynomial_by_one(const double *coefficients, size_t length)
{
    if (length == 0) {
        return NULL;
    }
    double *result = malloc(length * sizeof(*result));
    if (result == NULL) {
        return NULL;
    }
    memcpy(result, coefficients, length * sizeof(*result));
    for (size_t i = 1; i <= length; ++i) {
        for (size_t j = length - 1; j > i - 1;) {
            --j;
            result[j] += result[j + 1];
        }
    }
    return result;
}

static double *stretch_univariate_polynomial_to_half_interval(const double *coefficients, size_t length)
{
    if (length == 0) {
        return NULL;
    }
    double *result = malloc(length * sizeof(*result));
    if (result == NULL) {
        return NULL;
    }
    result[length - 1] = coefficients[length - 1];
    double multiplier = 2.0;
    for (size_t i = length - 1; i-- > 0;) {
        result[i] = coefficients[i] * multiplier;
        multiplier *= 2.0;
    }
    return result;
}

static int descartes_sign_changes_reverse_shift_univariate_polynomial_by_one(
    const double *coefficients,
    size_t length)
{
    if (length == 0) {
        return 0;
    }

    double *horner = malloc(length * sizeof(*horner));
    if (horner == NULL) {
        return -1;
    }
    for (size_t i = 0; i < length; ++i) {
        horner[i] = coefficients[length - i - 1];
    }

    int sign_changes = 0;
    double last_nonzero = NAN;
    for (size_t i = 1; i <= length; ++i) {
        for (size_t j = length - 1; j > i - 1;) {
            --j;
            horner[j] += horner[j + 1];
        }
        if (horner[i - 1] != 0.0) {
            if (horner[i - 1] * last_nonzero < 0.0) {
                ++sign_changes;
            }
            if (sign_changes > 1) {
                free(horner);
                return sign_changes;
            }
            last_nonzero = horner[i - 1];
        }
    }
    if (horner[0] == 0.0) {
        ++sign_changes;
    }
    free(horner);
    return sign_changes;
}

static double next_power_of_two_outward(double value)
{
    uint64_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    if ((bits & UINT64_C(0x000fffffffffffff)) != 0) {
        const double doubled = 2.0 * value;
        memcpy(&bits, &doubled, sizeof(bits));
        bits &= UINT64_C(0xfff0000000000000);
    }
    double result = 0.0;
    memcpy(&result, &bits, sizeof(result));
    return result;
}

static double bisect_root_interval(
    const univariate_polynomial *polynomial,
    double lower,
    double upper,
    double lower_value,
    double upper_value)
{
    (void)upper_value;
    while (fabs(upper - lower) > SURFER_ROOT_EPSILON) {
        const double center = 0.5 * (lower + upper);
        double center_value = polynomial->coefficients[polynomial->length - 1];
        for (size_t i = polynomial->length - 1; i-- > 0;) {
            center_value = center_value * center + polynomial->coefficients[i];
        }

        if (center_value * lower_value < 0.0) {
            upper = center;
        } else if (center_value == 0.0) {
            return center;
        } else {
            lower = center;
            lower_value = center_value;
        }
    }
    return lower;
}

static double restrict_interval_and_bisect_root_root_interval(
    const univariate_polynomial *polynomial,
    double lower,
    double upper,
    double strict_lower,
    double strict_upper)
{
    double lower_value = evaluate_univariate_polynomial_at(polynomial, lower);
    if (lower < strict_lower) {
        if (upper < strict_lower) {
            return NAN;
        }
        const double strict_value = evaluate_univariate_polynomial_at(polynomial, strict_lower);
        if (lower_value * strict_value < 0.0 || lower_value == 0.0) {
            return NAN;
        }
        lower = strict_lower;
        lower_value = strict_value;
    }

    double upper_value = evaluate_univariate_polynomial_at(polynomial, upper);
    if (strict_upper < upper) {
        if (strict_upper < lower) {
            return NAN;
        }
        const double strict_value = evaluate_univariate_polynomial_at(polynomial, strict_upper);
        if (upper_value * strict_value < 0.0 || upper_value == 0.0) {
            return NAN;
        }
        upper = strict_upper;
        upper_value = strict_value;
    }

    if (lower_value * upper_value <= 0.0) {
        return bisect_root_interval(polynomial, lower, upper, lower_value, upper_value);
    }
    return NAN;
}

static void free_descartes_interval(descartes_interval *interval)
{
    free(interval->coefficients);
    interval->coefficients = NULL;
    interval->length = 0;
}

static descartes_candidate_stack empty_descartes_candidate_stack(void)
{
    descartes_candidate_stack result = {NULL, 0, 0};
    return result;
}

static void free_descartes_candidate_stack(descartes_candidate_stack *stack)
{
    for (size_t i = 0; i < stack->length; ++i) {
        free_descartes_interval(&stack->items[i]);
    }
    free(stack->items);
    *stack = empty_descartes_candidate_stack();
}

static bool push_descartes_candidate(
    descartes_candidate_stack *stack,
    descartes_interval interval)
{
    if (stack->length == stack->capacity) {
        const size_t new_capacity =
            stack->capacity == 0 ? 16 : 2 * stack->capacity;
        descartes_interval *new_items = realloc(
            stack->items,
            new_capacity * sizeof(*new_items));
        if (new_items == NULL) {
            free_descartes_interval(&interval);
            return false;
        }
        stack->items = new_items;
        stack->capacity = new_capacity;
    }
    stack->items[stack->length++] = interval;
    return true;
}

static descartes_interval pop_descartes_candidate(
    descartes_candidate_stack *stack)
{
    return stack->items[--stack->length];
}

static double find_positive_root_with_descartes(
    const univariate_polynomial *source,
    double lower_bound,
    double upper_bound,
    which_root order)
{
    if (upper_bound <= 0.0 || coefficient_count_without_trailing_zeroes(source) <= 1) {
        return NAN;
    }

    univariate_polynomial shrunk = copy_without_trailing_zeroes(source);
    if (shrunk.coefficients == NULL) {
        return NAN;
    }

    const double bound = next_power_of_two_outward(upper_bound);
    if (!(bound > 0.0) || !isfinite(bound)) {
        free_univariate_polynomial(shrunk);
        return NAN;
    }
    const double transformed_lower = lower_bound / bound;
    const double transformed_upper = upper_bound / bound;

    univariate_polynomial polynomial = stretch_univariate_polynomial(&shrunk, bound);
    free_univariate_polynomial(shrunk);
    if (polynomial.coefficients == NULL) {
        return NAN;
    }

    double saved_result = NAN;
    if (polynomial.coefficients[0] == 0.0) {
        if (lower_bound <= 0.0) {
            if (order == SMALLEST_ROOT) {
                free_univariate_polynomial(polynomial);
                return 0.0;
            }
            saved_result = 0.0;
        }
        size_t deflated_length = 0;
        double *deflated = deflate_zero_root(
            polynomial.coefficients,
            polynomial.length,
            &deflated_length);
        free(polynomial.coefficients);
        polynomial.coefficients = deflated;
        polynomial.length = deflated_length;
        if (deflated_length == 0) {
            return saved_result;
        }
    }

    if (lower_bound <= 0.0) {
        lower_bound = 0.0;
    }

    descartes_candidate_stack candidates =
        empty_descartes_candidate_stack();
    descartes_interval initial = {
        copy_univariate_polynomial(polynomial.coefficients, polynomial.length).coefficients,
        polynomial.length,
        false,
        0.0,
        1.0
    };
    if (initial.coefficients == NULL ||
        !push_descartes_candidate(&candidates, initial)) {
        free_univariate_polynomial(polynomial);
        free_descartes_candidate_stack(&candidates);
        return NAN;
    }

    while (candidates.length != 0) {
        descartes_interval current = pop_descartes_candidate(&candidates);
        if (current.shift_by_one_when_used) {
            double *shifted = shift_univariate_polynomial_by_one(current.coefficients, current.length);
            free(current.coefficients);
            current.coefficients = shifted;
            if (shifted == NULL && current.length != 0) {
                free_descartes_interval(&current);
                break;
            }
        }
        if (current.length == 0) {
            free_descartes_interval(&current);
            continue;
        }

        if (current.coefficients[0] == 0.0) {
            const double candidate = current.lower * bound;
            if (lower_bound <= candidate && candidate <= upper_bound) {
                if (order == SMALLEST_ROOT) {
                    free_descartes_candidate_stack(&candidates);
                    free_descartes_interval(&current);
                    free_univariate_polynomial(polynomial);
                    return candidate;
                }
                saved_result = candidate;
                size_t deflated_length = 0;
                double *deflated = deflate_zero_root(
                    current.coefficients,
                    current.length,
                    &deflated_length);
                free(current.coefficients);
                current.coefficients = deflated;
                current.length = deflated_length;
                if (current.length == 0) {
                    free_descartes_interval(&current);
                    continue;
                }
            }
        }

        const int variations = descartes_sign_changes_reverse_shift_univariate_polynomial_by_one(
            current.coefficients,
            current.length);
        if (variations < 0) {
            free_descartes_interval(&current);
            break;
        }
        if (variations == 1) {
            const double transformed_root = restrict_interval_and_bisect_root_root_interval(
                &polynomial,
                current.lower,
                current.upper,
                transformed_lower,
                transformed_upper);
            const double candidate = transformed_root * bound;
            free_descartes_interval(&current);
            if (!isnan(candidate)) {
                free_descartes_candidate_stack(&candidates);
                free_univariate_polynomial(polynomial);
                if (order == LARGEST_ROOT &&
                    !isnan(saved_result) && saved_result > candidate) {
                    return saved_result;
                }
                return candidate;
            }
            continue;
        }

        if (variations > 1) {
            const double center = 0.5 * (current.lower + current.upper);
            if (fabs(current.upper - current.lower) < 0.5 * SURFER_ROOT_EPSILON) {
                const double candidate =
                    current.lower <= transformed_lower
                        ? lower_bound
                        : current.lower * bound;
                free_descartes_interval(&current);
                free_descartes_candidate_stack(&candidates);
                free_univariate_polynomial(polynomial);
                return candidate;
            }

            double *stretched = stretch_univariate_polynomial_to_half_interval(
                current.coefficients,
                current.length);
            if (stretched == NULL) {
                free_descartes_interval(&current);
                break;
            }

            /* Java reuses the same coefficient array for both children, then
             * shifts the upper child only after it is popped. Give each child
             * an owned copy while preserving that numerical content/order.
             */
            descartes_interval lower_child = {
                copy_univariate_polynomial(stretched, current.length).coefficients,
                current.length,
                false,
                current.lower,
                center
            };
            descartes_interval upper_child = {
                copy_univariate_polynomial(stretched, current.length).coefficients,
                current.length,
                true,
                center,
                current.upper
            };
            free(stretched);
            free_descartes_interval(&current);

            if (lower_child.coefficients == NULL || upper_child.coefficients == NULL) {
                free_descartes_interval(&lower_child);
                free_descartes_interval(&upper_child);
                break;
            }

            bool ok = true;
            if (order == SMALLEST_ROOT) {
                /* Stack is LIFO: push upper first so lower is searched first. */
                if (center <= transformed_upper) {
                    ok = push_descartes_candidate(&candidates, upper_child);
                    upper_child.coefficients = NULL;
                }
                if (ok && center >= transformed_lower) {
                    ok = push_descartes_candidate(&candidates, lower_child);
                    lower_child.coefficients = NULL;
                }
            } else {
                if (center >= transformed_lower) {
                    ok = push_descartes_candidate(&candidates, lower_child);
                    lower_child.coefficients = NULL;
                }
                if (ok && center <= transformed_upper) {
                    ok = push_descartes_candidate(&candidates, upper_child);
                    upper_child.coefficients = NULL;
                }
            }
            free_descartes_interval(&lower_child);
            free_descartes_interval(&upper_child);
            if (!ok) {
                break;
            }
        } else {
            free_descartes_interval(&current);
        }
    }

    free_descartes_candidate_stack(&candidates);
    free_univariate_polynomial(polynomial);
    return saved_result;
}

static double find_first_root_with_descartes(
    const univariate_polynomial *polynomial,
    double lower,
    double upper)
{
    univariate_polynomial reflected = stretch_univariate_polynomial(polynomial, -1.0);
    if (reflected.coefficients == NULL) {
        return NAN;
    }

    /*
     * Stussak's DescartesRootFinder searches the reflected negative half
     * first, asking for its largest positive root, then searches the positive
     * half for the smallest root.
     */
    const double negative = -find_positive_root_with_descartes(
        &reflected,
        -upper,
        -lower,
        LARGEST_ROOT);
    free_univariate_polynomial(reflected);
    if (!isnan(negative)) {
        return negative;
    }
    return find_positive_root_with_descartes(
        polynomial,
        lower,
        upper,
        SMALLEST_ROOT);
}

static double integer_power(double base, int32_t exponent)
{
    double result = 1.0;
    double factor = base;
    uint32_t remaining = (uint32_t)exponent;
    while (remaining != 0) {
        if ((remaining & 1U) != 0) {
            result *= factor;
        }
        remaining >>= 1U;
        if (remaining != 0) {
            factor *= factor;
        }
    }
    return result;
}

static bool polynomial_for_axis_power_along_ray(
    double origin,
    double direction,
    int32_t exponent,
    univariate_polynomial *result)
{
    if (exponent < 0) {
        return false;
    }
    *result = allocate_univariate_polynomial((size_t)exponent + 1);
    if (result->coefficients == NULL) {
        return false;
    }
    if (exponent == 0) {
        result->coefficients[0] = 1.0;
        return true;
    }

    double binomial = 1.0;
    for (int32_t k = 0; k <= exponent; ++k) {
        if (k != 0) {
            binomial *= (double)(exponent - (k - 1));
            binomial /= (double)k;
        }
        result->coefficients[k] =
            binomial *
            integer_power(origin, exponent - k) *
            integer_power(direction, k);
    }
    return true;
}

static univariate_polynomial multiply_univariate_polynomials(
    const univariate_polynomial *left,
    const univariate_polynomial *right)
{
    if (left->length == 0 || right->length == 0) {
        return empty_univariate_polynomial();
    }
    univariate_polynomial result = allocate_univariate_polynomial(left->length + right->length - 1);
    if (result.coefficients == NULL) {
        return empty_univariate_polynomial();
    }
    for (size_t i = 0; i < left->length; ++i) {
        for (size_t j = 0; j < right->length; ++j) {
            result.coefficients[i + j] +=
                left->coefficients[i] * right->coefficients[j];
        }
    }
    return result;
}

static bool expand_sparse_polynomial_directly_along_ray(
    surfer_sparse_polynomial source,
    surfer_ray ray,
    univariate_polynomial *result)
{
    int64_t maximum_degree = 0;
    for (size_t i = 0; i < source.term_count; ++i) {
        const surfer_term term = source.terms[i];
        if (term.x_exponent < 0 || term.y_exponent < 0 || term.z_exponent < 0) {
            return false;
        }
        const int64_t degree =
            (int64_t)term.x_exponent +
            (int64_t)term.y_exponent +
            (int64_t)term.z_exponent;
        if (degree > maximum_degree) {
            maximum_degree = degree;
        }
    }
    if ((uint64_t)maximum_degree > SIZE_MAX - 1U) {
        return false;
    }

    *result = allocate_univariate_polynomial((size_t)maximum_degree + 1);
    if (result->coefficients == NULL) {
        return false;
    }

    for (size_t i = 0; i < source.term_count; ++i) {
        const surfer_term term = source.terms[i];
        univariate_polynomial x = empty_univariate_polynomial();
        univariate_polynomial y = empty_univariate_polynomial();
        univariate_polynomial z = empty_univariate_polynomial();
        univariate_polynomial xy = empty_univariate_polynomial();
        univariate_polynomial xyz = empty_univariate_polynomial();

        if (!polynomial_for_axis_power_along_ray(
                ray.origin.x,
                ray.direction.x,
                term.x_exponent,
                &x) ||
            !polynomial_for_axis_power_along_ray(
                ray.origin.y,
                ray.direction.y,
                term.y_exponent,
                &y) ||
            !polynomial_for_axis_power_along_ray(
                ray.origin.z,
                ray.direction.z,
                term.z_exponent,
                &z)) {
            free_univariate_polynomial(x);
            free_univariate_polynomial(y);
            free_univariate_polynomial(z);
            free_univariate_polynomial(*result);
            *result = empty_univariate_polynomial();
            return false;
        }
        xy = multiply_univariate_polynomials(&x, &y);
        xyz = multiply_univariate_polynomials(&xy, &z);
        free_univariate_polynomial(x);
        free_univariate_polynomial(y);
        free_univariate_polynomial(z);
        free_univariate_polynomial(xy);
        if (xyz.coefficients == NULL) {
            free_univariate_polynomial(*result);
            *result = empty_univariate_polynomial();
            return false;
        }

        for (size_t j = 0; j < xyz.length; ++j) {
            result->coefficients[j] += term.coefficient * xyz.coefficients[j];
        }
        free_univariate_polynomial(xyz);
    }
    return true;
}

static double evaluate_sparse_polynomial_at_point(surfer_sparse_polynomial polynomial, surfer_vec3 point)
{
    double result = 0.0;
    for (size_t i = 0; i < polynomial.term_count; ++i) {
        const surfer_term term = polynomial.terms[i];
        result += term.coefficient *
            integer_power(point.x, term.x_exponent) *
            integer_power(point.y, term.y_exponent) *
            integer_power(point.z, term.z_exponent);
    }
    return result;
}

bool surfer_clip_unit_sphere(surfer_ray ray, surfer_interval *interval)
{
    if (interval == NULL) {
        return false;
    }
    const double a = dot_product(ray.direction, ray.direction);
    if (a == 0.0) {
        return false;
    }
    const double b = 2.0 * dot_product(ray.origin, ray.direction);
    const double c = dot_product(ray.origin, ray.origin) - 1.0;
    const double discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) {
        return false;
    }
    const double root = sqrt(discriminant);
    double lower = (-b - root) / (2.0 * a);
    double upper = (-b + root) / (2.0 * a);
    if (lower > upper) {
        const double swap = lower;
        lower = upper;
        upper = swap;
    }
    interval->lower = lower;
    interval->upper = upper;
    return true;
}

bool surfer_first_surface_root(
    const surfer_prepared_surface *surface,
    surfer_ray surface_ray,
    double lower,
    double upper,
    double *root)
{
    if (surface == NULL || root == NULL || lower > upper) {
        return false;
    }

    univariate_polynomial polynomial = empty_univariate_polynomial();
    if (!expand_sparse_polynomial_directly_along_ray(surface->surface, surface_ray, &polynomial)) {
        return false;
    }
    univariate_polynomial shrunk = copy_without_trailing_zeroes(&polynomial);
    free_univariate_polynomial(polynomial);
    if (shrunk.coefficients == NULL) {
        return false;
    }

    double candidate = NAN;
    const size_t degree = coefficient_count_without_trailing_zeroes(&shrunk) - 1;
    if (surface->family_degree < 2) {
        if (degree == 1) {
            candidate = -shrunk.coefficients[0] / shrunk.coefficients[1];
            if (!(lower <= candidate && candidate <= upper)) {
                candidate = NAN;
            }
        }
    } else {
        candidate = find_first_root_with_descartes(&shrunk, lower, upper);
    }
    free_univariate_polynomial(shrunk);

    if (isnan(candidate)) {
        return false;
    }
    *root = candidate;
    return true;
}

static surfer_color shade_hit_with_material(
    const surfer_scene *scene,
    surfer_vec3 hit,
    surfer_vec3 view,
    surfer_vec3 normal,
    surfer_material material)
{
    surfer_color color = scale_color(material.color, material.ambient_intensity);

    const size_t light_count =
        scene->light_count < SURFER_MAX_LIGHTS
            ? scene->light_count
            : SURFER_MAX_LIGHTS;
    for (size_t i = 0; i < light_count; ++i) {
        const surfer_light light = scene->lights[i];
        if (!light.enabled) {
            continue;
        }
        const surfer_vec3 light_direction =
            normalize_vector(subtract_vectors(light.position, hit));
        const float lambert = (float)dot_product(normal, light_direction);
        if (lambert <= 0.0f) {
            continue;
        }

        const surfer_color diffuse_product = scale_color(
            multiply_colors(material.color, light.color),
            material.diffuse_intensity * light.intensity);
        color = add_scaled_color(color, lambert, diffuse_product);

        const surfer_vec3 half_vector =
            normalize_vector(add_vectors(light_direction, view));
        const float normal_half =
            (float)fmax(0.0, dot_product(normal, half_vector));
        const float specular_factor = powf(normal_half, material.shininess);
        const surfer_color specular_product = scale_color(
            light.color,
            material.specular_intensity * light.intensity);
        color = add_scaled_color(color, specular_factor, specular_product);
    }
    return clamp_color_to_maximum(color, 1.0f);
}

static bool visible_interval_for_ray_bundle(
    surfer_ray_bundle rays,
    surfer_interval *visible_interval)
{
    /*
     * Stussak's RayCreator keeps one parameter t across camera, clipping, and
     * surface space. ClipToSphere therefore returns an interval in that same t.
     */
    if (!surfer_clip_unit_sphere(rays.clipping_ray, visible_interval)) {
        return false;
    }
    if (visible_interval->lower < rays.eye_location_on_ray &&
        rays.eye_location_on_ray < visible_interval->upper) {
        visible_interval->lower =
            fmax(visible_interval->lower, rays.eye_location_on_ray);
    }
    return true;
}

static surfer_vec3 prepared_gradient_at_surface_point(
    const surfer_prepared_surface *surface,
    surfer_vec3 surface_point)
{
    surfer_vec3 gradient = {
        evaluate_sparse_polynomial_at_point(surface->gradient_x, surface_point),
        evaluate_sparse_polynomial_at_point(surface->gradient_y, surface_point),
        evaluate_sparse_polynomial_at_point(surface->gradient_z, surface_point)
    };
    return gradient;
}

static surfer_vec3 camera_normal_from_surface_gradient(
    surfer_ray_bundle rays,
    surfer_vec3 surface_gradient)
{
    surfer_vec3 camera_normal =
        apply_matrix_to_vector(rays.surface_normal_to_camera, surface_gradient);
    const float length = (float)length_of_vector(camera_normal);
    if (length != 0.0f) {
        camera_normal = scale_vector(camera_normal, 1.0f / length);
    }
    return camera_normal;
}

static surfer_material material_for_visible_side(
    const surfer_scene *scene,
    surfer_vec3 view,
    surfer_vec3 *camera_normal)
{
    if (dot_product(*camera_normal, view) > 0.0) {
        return scene->front_material;
    }
    *camera_normal = scale_vector(*camera_normal, -1.0);
    return scene->back_material;
}

surfer_trace_result surfer_trace_prepared_ray(
    const surfer_scene *scene,
    surfer_ray_bundle rays)
{
    surfer_trace_result result = {
        false,
        NAN,
        {0.0, 0.0, 0.0},
        {0.0, 0.0, 0.0},
        {0.0f, 0.0f, 0.0f}
    };
    if (scene == NULL || scene->surface == NULL) {
        return result;
    }
    result.color = scene->background;

    /* ray bundle → visible t interval → first surface root */
    surfer_interval visible_interval;
    if (!visible_interval_for_ray_bundle(rays, &visible_interval)) {
        return result;
    }

    double hit_parameter = NAN;
    if (!surfer_first_surface_root(
            scene->surface,
            rays.surface_ray,
            visible_interval.lower,
            visible_interval.upper,
            &hit_parameter)) {
        return result;
    }

    const surfer_vec3 clipping_point =
        point_on_ray_at_parameter(rays.clipping_ray, hit_parameter);
    if (dot_product(clipping_point, clipping_point) > 1.0 + 1e-12) {
        return result;
    }

    /* surface point → prepared gradient → camera normal */
    const surfer_vec3 surface_point =
        point_on_ray_at_parameter(rays.surface_ray, hit_parameter);
    const surfer_vec3 surface_gradient =
        prepared_gradient_at_surface_point(scene->surface, surface_point);
    surfer_vec3 camera_normal =
        camera_normal_from_surface_gradient(rays, surface_gradient);

    /* camera point + eye → view → visible side → shaded color */
    const surfer_vec3 camera_point =
        point_on_ray_at_parameter(rays.camera_ray, hit_parameter);
    const surfer_vec3 eye = point_on_ray_at_parameter(
        rays.camera_ray,
        rays.eye_location_on_ray);
    const surfer_vec3 view =
        normalize_vector(subtract_vectors(eye, camera_point));
    const surfer_material material =
        material_for_visible_side(scene, view, &camera_normal);

    result.hit = true;
    result.ray_parameter = hit_parameter;
    result.point = camera_point;
    result.surface_normal = camera_normal;
    result.color =
        shade_hit_with_material(scene, camera_point, view, camera_normal, material);
    return result;
}

uint32_t surfer_color_to_argb(surfer_color color)
{
    const float red = clamp_float_between(color.red, 0.0f, 1.0f);
    const float green = clamp_float_between(color.green, 0.0f, 1.0f);
    const float blue = clamp_float_between(color.blue, 0.0f, 1.0f);
    const uint32_t red_byte = (uint32_t)lroundf(red * 255.0f);
    const uint32_t green_byte = (uint32_t)lroundf(green * 255.0f);
    const uint32_t blue_byte = (uint32_t)lroundf(blue * 255.0f);
    return UINT32_C(0xff000000) |
        (red_byte << 16) |
        (green_byte << 8) |
        blue_byte;
}

surfer_scene surfer_default_scene(const surfer_prepared_surface *surface)
{
    surfer_scene scene;
    memset(&scene, 0, sizeof(scene));
    scene.surface = surface;
    scene.front_material = (surfer_material){
        {0.90f, 0.47f, 0.18f}, 0.32f, 0.76f, 0.55f, 24.0f
    };
    scene.back_material = (surfer_material){
        {0.93f, 0.76f, 0.40f}, 0.30f, 0.72f, 0.45f, 18.0f
    };
    scene.background = (surfer_color){0.075f, 0.09f, 0.115f};
    scene.light_count = 3;
    scene.lights[0] = (surfer_light){
        true, {-100.0, 100.0, 100.0}, {1.0f, 1.0f, 1.0f}, 0.55f
    };
    scene.lights[1] = (surfer_light){
        true, {100.0, 100.0, 100.0}, {1.0f, 1.0f, 1.0f}, 0.70f
    };
    scene.lights[2] = (surfer_light){
        true, {0.0, -100.0, 100.0}, {1.0f, 1.0f, 1.0f}, 0.30f
    };
    return scene;
}

static orthographic_view make_orthographic_view(
    size_t width,
    size_t height,
    double camera_height,
    double yaw,
    double pitch,
    double zoom)
{
    const double effective_height = camera_height / zoom;
    const double half_v = effective_height / 2.0;
    const double half_u = half_v * (double)width / (double)height;
    const surfer_mat3 camera_to_surface =
        yaw_then_pitch_rotation(yaw, pitch);

    orthographic_view view = {
        half_u,
        half_v,
        camera_to_surface,
        transpose_matrix(camera_to_surface),
        apply_matrix_to_vector(
            camera_to_surface,
            (surfer_vec3){1.0, 0.0, 0.0}),
        apply_matrix_to_vector(
            camera_to_surface,
            (surfer_vec3){0.0, 1.0, 0.0}),
        apply_matrix_to_vector(
            camera_to_surface,
            (surfer_vec3){0.0, 0.0, -1.0})
    };
    return view;
}

static double orthographic_coordinate(
    size_t index,
    size_t count,
    double half_extent)
{
    return -half_extent +
        (2.0 * half_extent * (double)index) / (double)(count - 1);
}

static surfer_ray_bundle orthographic_ray_bundle_at(
    orthographic_view view,
    double u,
    double v)
{
    const surfer_vec3 surface_origin = add_vectors(
        scale_vector(view.surface_u, u),
        scale_vector(view.surface_v, v));

    surfer_ray_bundle rays = {
        {{u, v, -1.0}, {0.0, 0.0, -1.0}},
        {surface_origin, view.surface_direction},
        {surface_origin, view.surface_direction},
        -1.0,
        view.surface_normal_to_camera
    };
    return rays;
}

bool surfer_render_orthographic(
    const surfer_scene *scene,
    size_t width,
    size_t height,
    double camera_height,
    double yaw,
    double pitch,
    double zoom,
    uint32_t *argb_pixels)
{
    if (scene == NULL || scene->surface == NULL || argb_pixels == NULL ||
        width < 2 || height < 2 || !(camera_height > 0.0) || !(zoom > 0.0)) {
        return false;
    }

    const orthographic_view view = make_orthographic_view(
        width,
        height,
        camera_height,
        yaw,
        pitch,
        zoom);

    /* (x,y) → (u,v) → ray bundle → trace → ARGB */
    for (size_t y = 0; y < height; ++y) {
        const double v =
            orthographic_coordinate(y, height, view.half_v);
        for (size_t x = 0; x < width; ++x) {
            const double u =
                orthographic_coordinate(x, width, view.half_u);
            const surfer_ray_bundle rays =
                orthographic_ray_bundle_at(view, u, v);
            const surfer_trace_result trace =
                surfer_trace_prepared_ray(scene, rays);
            argb_pixels[y * width + x] =
                surfer_color_to_argb(trace.color);
        }
    }
    return true;
}
