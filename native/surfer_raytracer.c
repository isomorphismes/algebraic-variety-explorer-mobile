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
} dense_polynomial;

typedef enum {
    SURFER_SMALLEST_ROOT,
    SURFER_LARGEST_ROOT
} root_order;

typedef struct {
    double *coefficients;
    size_t length;
    bool shift;
    double lower;
    double upper;
} polynomial_interval;

static surfer_vec3 vec3_add(surfer_vec3 left, surfer_vec3 right)
{
    surfer_vec3 result = {
        left.x + right.x,
        left.y + right.y,
        left.z + right.z
    };
    return result;
}

static surfer_vec3 vec3_subtract(surfer_vec3 left, surfer_vec3 right)
{
    surfer_vec3 result = {
        left.x - right.x,
        left.y - right.y,
        left.z - right.z
    };
    return result;
}

static surfer_vec3 vec3_scale(surfer_vec3 value, double scale)
{
    surfer_vec3 result = {
        value.x * scale,
        value.y * scale,
        value.z * scale
    };
    return result;
}

static double vec3_dot(surfer_vec3 left, surfer_vec3 right)
{
    return left.x * right.x + left.y * right.y + left.z * right.z;
}

static double vec3_length(surfer_vec3 value)
{
    return sqrt(vec3_dot(value, value));
}

static surfer_vec3 vec3_normalize(surfer_vec3 value)
{
    const double length = vec3_length(value);
    if (length == 0.0) {
        return value;
    }
    return vec3_scale(value, 1.0 / length);
}

static surfer_vec3 ray_at(surfer_ray ray, double t)
{
    return vec3_add(ray.origin, vec3_scale(ray.direction, t));
}

static surfer_vec3 mat3_apply(surfer_mat3 matrix, surfer_vec3 value)
{
    surfer_vec3 result = {
        matrix.m00 * value.x + matrix.m01 * value.y + matrix.m02 * value.z,
        matrix.m10 * value.x + matrix.m11 * value.y + matrix.m12 * value.z,
        matrix.m20 * value.x + matrix.m21 * value.y + matrix.m22 * value.z
    };
    return result;
}

static surfer_mat3 mat3_transpose(surfer_mat3 matrix)
{
    surfer_mat3 result = {
        matrix.m00, matrix.m10, matrix.m20,
        matrix.m01, matrix.m11, matrix.m21,
        matrix.m02, matrix.m12, matrix.m22
    };
    return result;
}

static surfer_mat3 view_rotation(double yaw, double pitch)
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

static float clamp_float(float value, float lower, float upper)
{
    if (value < lower) {
        return lower;
    }
    if (value > upper) {
        return upper;
    }
    return value;
}

static surfer_color color_scale_add(
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

static surfer_color color_product(surfer_color left, surfer_color right)
{
    surfer_color result = {
        left.red * right.red,
        left.green * right.green,
        left.blue * right.blue
    };
    return result;
}

static surfer_color color_scale(surfer_color color, float scale)
{
    surfer_color result = {
        color.red * scale,
        color.green * scale,
        color.blue * scale
    };
    return result;
}

static surfer_color color_clamp_max(surfer_color color, float maximum)
{
    color.red = clamp_float(color.red, 0.0f, maximum);
    color.green = clamp_float(color.green, 0.0f, maximum);
    color.blue = clamp_float(color.blue, 0.0f, maximum);
    return color;
}

static dense_polynomial dense_empty(void)
{
    dense_polynomial result = {NULL, 0};
    return result;
}

static void dense_free(dense_polynomial polynomial)
{
    free(polynomial.coefficients);
}

static dense_polynomial dense_allocate(size_t length)
{
    dense_polynomial result = dense_empty();
    if (length == 0) {
        return result;
    }
    result.coefficients = calloc(length, sizeof(*result.coefficients));
    if (result.coefficients == NULL) {
        return dense_empty();
    }
    result.length = length;
    return result;
}

static dense_polynomial dense_copy(const double *coefficients, size_t length)
{
    dense_polynomial result = dense_allocate(length);
    if (length != 0 && result.coefficients == NULL) {
        return dense_empty();
    }
    if (length != 0) {
        memcpy(result.coefficients, coefficients, length * sizeof(*coefficients));
    }
    return result;
}

static size_t dense_true_length(const dense_polynomial *polynomial)
{
    size_t length = polynomial->length;
    while (length > 1 && polynomial->coefficients[length - 1] == 0.0) {
        --length;
    }
    return length;
}

static dense_polynomial dense_shrink_copy(const dense_polynomial *polynomial)
{
    return dense_copy(polynomial->coefficients, dense_true_length(polynomial));
}

static double dense_evaluate(const dense_polynomial *polynomial, double where)
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

static dense_polynomial dense_stretch(
    const dense_polynomial *polynomial,
    double factor)
{
    dense_polynomial result = dense_allocate(polynomial->length);
    if (polynomial->length != 0 && result.coefficients == NULL) {
        return dense_empty();
    }
    double multiplier = 1.0;
    for (size_t i = 0; i < polynomial->length; ++i) {
        result.coefficients[i] = polynomial->coefficients[i] * multiplier;
        multiplier *= factor;
    }
    return result;
}

static double *deflate_zero(const double *coefficients, size_t length, size_t *new_length)
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

static double *shift_one(const double *coefficients, size_t length)
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

static double *stretch_normalize_half(const double *coefficients, size_t length)
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

static int descartes_sign_changes_reverse_shift_one(
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

static double next_power_of_two(double value)
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

static double bisect(
    const dense_polynomial *polynomial,
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

static double adjust_interval_and_bisect(
    const dense_polynomial *polynomial,
    double lower,
    double upper,
    double strict_lower,
    double strict_upper)
{
    double lower_value = dense_evaluate(polynomial, lower);
    if (lower < strict_lower) {
        if (upper < strict_lower) {
            return NAN;
        }
        const double strict_value = dense_evaluate(polynomial, strict_lower);
        if (lower_value * strict_value < 0.0 || lower_value == 0.0) {
            return NAN;
        }
        lower = strict_lower;
        lower_value = strict_value;
    }

    double upper_value = dense_evaluate(polynomial, upper);
    if (strict_upper < upper) {
        if (strict_upper < lower) {
            return NAN;
        }
        const double strict_value = dense_evaluate(polynomial, strict_upper);
        if (upper_value * strict_value < 0.0 || upper_value == 0.0) {
            return NAN;
        }
        upper = strict_upper;
        upper_value = strict_value;
    }

    if (lower_value * upper_value <= 0.0) {
        return bisect(polynomial, lower, upper, lower_value, upper_value);
    }
    return NAN;
}

static void free_interval(polynomial_interval *interval)
{
    free(interval->coefficients);
    interval->coefficients = NULL;
    interval->length = 0;
}

static bool push_interval(
    polynomial_interval **stack,
    size_t *length,
    size_t *capacity,
    polynomial_interval interval)
{
    if (*length == *capacity) {
        const size_t new_capacity = *capacity == 0 ? 16 : 2 * *capacity;
        polynomial_interval *new_stack = realloc(
            *stack,
            new_capacity * sizeof(*new_stack));
        if (new_stack == NULL) {
            free_interval(&interval);
            return false;
        }
        *stack = new_stack;
        *capacity = new_capacity;
    }
    (*stack)[(*length)++] = interval;
    return true;
}

static double find_positive_root(
    const dense_polynomial *source,
    double lower_bound,
    double upper_bound,
    root_order order)
{
    if (upper_bound <= 0.0 || dense_true_length(source) <= 1) {
        return NAN;
    }

    dense_polynomial shrunk = dense_shrink_copy(source);
    if (shrunk.coefficients == NULL) {
        return NAN;
    }

    const double bound = next_power_of_two(upper_bound);
    if (!(bound > 0.0) || !isfinite(bound)) {
        dense_free(shrunk);
        return NAN;
    }
    const double transformed_lower = lower_bound / bound;
    const double transformed_upper = upper_bound / bound;

    dense_polynomial polynomial = dense_stretch(&shrunk, bound);
    dense_free(shrunk);
    if (polynomial.coefficients == NULL) {
        return NAN;
    }

    double saved_result = NAN;
    if (polynomial.coefficients[0] == 0.0) {
        if (lower_bound <= 0.0) {
            if (order == SURFER_SMALLEST_ROOT) {
                dense_free(polynomial);
                return 0.0;
            }
            saved_result = 0.0;
        }
        size_t deflated_length = 0;
        double *deflated = deflate_zero(
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

    polynomial_interval *stack = NULL;
    size_t stack_length = 0;
    size_t stack_capacity = 0;
    polynomial_interval initial = {
        dense_copy(polynomial.coefficients, polynomial.length).coefficients,
        polynomial.length,
        false,
        0.0,
        1.0
    };
    if (initial.coefficients == NULL ||
        !push_interval(&stack, &stack_length, &stack_capacity, initial)) {
        dense_free(polynomial);
        free(stack);
        return NAN;
    }

    while (stack_length != 0) {
        polynomial_interval current = stack[--stack_length];
        if (current.shift) {
            double *shifted = shift_one(current.coefficients, current.length);
            free(current.coefficients);
            current.coefficients = shifted;
            if (shifted == NULL && current.length != 0) {
                free_interval(&current);
                break;
            }
        }
        if (current.length == 0) {
            free_interval(&current);
            continue;
        }

        if (current.coefficients[0] == 0.0) {
            const double candidate = current.lower * bound;
            if (lower_bound <= candidate && candidate <= upper_bound) {
                if (order == SURFER_SMALLEST_ROOT) {
                    for (size_t i = 0; i < stack_length; ++i) {
                        free_interval(&stack[i]);
                    }
                    free(stack);
                    free_interval(&current);
                    dense_free(polynomial);
                    return candidate;
                }
                saved_result = candidate;
                size_t deflated_length = 0;
                double *deflated = deflate_zero(
                    current.coefficients,
                    current.length,
                    &deflated_length);
                free(current.coefficients);
                current.coefficients = deflated;
                current.length = deflated_length;
                if (current.length == 0) {
                    free_interval(&current);
                    continue;
                }
            }
        }

        const int variations = descartes_sign_changes_reverse_shift_one(
            current.coefficients,
            current.length);
        if (variations < 0) {
            free_interval(&current);
            break;
        }
        if (variations == 1) {
            const double transformed_root = adjust_interval_and_bisect(
                &polynomial,
                current.lower,
                current.upper,
                transformed_lower,
                transformed_upper);
            const double candidate = transformed_root * bound;
            free_interval(&current);
            if (!isnan(candidate)) {
                for (size_t i = 0; i < stack_length; ++i) {
                    free_interval(&stack[i]);
                }
                free(stack);
                dense_free(polynomial);
                if (order == SURFER_LARGEST_ROOT &&
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
                free_interval(&current);
                for (size_t i = 0; i < stack_length; ++i) {
                    free_interval(&stack[i]);
                }
                free(stack);
                dense_free(polynomial);
                return candidate;
            }

            double *stretched = stretch_normalize_half(
                current.coefficients,
                current.length);
            if (stretched == NULL) {
                free_interval(&current);
                break;
            }

            /* Java reuses the same coefficient array for both children, then
             * shifts the upper child only after it is popped. Give each child
             * an owned copy while preserving that numerical content/order.
             */
            polynomial_interval lower_child = {
                dense_copy(stretched, current.length).coefficients,
                current.length,
                false,
                current.lower,
                center
            };
            polynomial_interval upper_child = {
                dense_copy(stretched, current.length).coefficients,
                current.length,
                true,
                center,
                current.upper
            };
            free(stretched);
            free_interval(&current);

            if (lower_child.coefficients == NULL || upper_child.coefficients == NULL) {
                free_interval(&lower_child);
                free_interval(&upper_child);
                break;
            }

            bool ok = true;
            if (order == SURFER_SMALLEST_ROOT) {
                /* Stack is LIFO: push upper first so lower is searched first. */
                if (center <= transformed_upper) {
                    ok = push_interval(
                        &stack, &stack_length, &stack_capacity, upper_child);
                    upper_child.coefficients = NULL;
                }
                if (ok && center >= transformed_lower) {
                    ok = push_interval(
                        &stack, &stack_length, &stack_capacity, lower_child);
                    lower_child.coefficients = NULL;
                }
            } else {
                if (center >= transformed_lower) {
                    ok = push_interval(
                        &stack, &stack_length, &stack_capacity, lower_child);
                    lower_child.coefficients = NULL;
                }
                if (ok && center <= transformed_upper) {
                    ok = push_interval(
                        &stack, &stack_length, &stack_capacity, upper_child);
                    upper_child.coefficients = NULL;
                }
            }
            free_interval(&lower_child);
            free_interval(&upper_child);
            if (!ok) {
                break;
            }
        } else {
            free_interval(&current);
        }
    }

    for (size_t i = 0; i < stack_length; ++i) {
        free_interval(&stack[i]);
    }
    free(stack);
    dense_free(polynomial);
    return saved_result;
}

static double find_first_descartes_root(
    const dense_polynomial *polynomial,
    double lower,
    double upper)
{
    dense_polynomial reflected = dense_stretch(polynomial, -1.0);
    if (reflected.coefficients == NULL) {
        return NAN;
    }
    const double negative = -find_positive_root(
        &reflected,
        -upper,
        -lower,
        SURFER_LARGEST_ROOT);
    dense_free(reflected);
    if (!isnan(negative)) {
        return negative;
    }
    return find_positive_root(
        polynomial,
        lower,
        upper,
        SURFER_SMALLEST_ROOT);
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

static bool axis_power_polynomial(
    double origin,
    double direction,
    int32_t exponent,
    dense_polynomial *result)
{
    if (exponent < 0) {
        return false;
    }
    *result = dense_allocate((size_t)exponent + 1);
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

static dense_polynomial dense_multiply(
    const dense_polynomial *left,
    const dense_polynomial *right)
{
    if (left->length == 0 || right->length == 0) {
        return dense_empty();
    }
    dense_polynomial result = dense_allocate(left->length + right->length - 1);
    if (result.coefficients == NULL) {
        return dense_empty();
    }
    for (size_t i = 0; i < left->length; ++i) {
        for (size_t j = 0; j < right->length; ++j) {
            result.coefficients[i + j] +=
                left->coefficients[i] * right->coefficients[j];
        }
    }
    return result;
}

static bool sparse_on_ray(
    surfer_sparse_polynomial source,
    surfer_ray ray,
    dense_polynomial *result)
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

    *result = dense_allocate((size_t)maximum_degree + 1);
    if (result->coefficients == NULL) {
        return false;
    }

    for (size_t i = 0; i < source.term_count; ++i) {
        const surfer_term term = source.terms[i];
        dense_polynomial x = dense_empty();
        dense_polynomial y = dense_empty();
        dense_polynomial z = dense_empty();
        dense_polynomial xy = dense_empty();
        dense_polynomial xyz = dense_empty();

        if (!axis_power_polynomial(
                ray.origin.x,
                ray.direction.x,
                term.x_exponent,
                &x) ||
            !axis_power_polynomial(
                ray.origin.y,
                ray.direction.y,
                term.y_exponent,
                &y) ||
            !axis_power_polynomial(
                ray.origin.z,
                ray.direction.z,
                term.z_exponent,
                &z)) {
            dense_free(x);
            dense_free(y);
            dense_free(z);
            dense_free(*result);
            *result = dense_empty();
            return false;
        }
        xy = dense_multiply(&x, &y);
        xyz = dense_multiply(&xy, &z);
        dense_free(x);
        dense_free(y);
        dense_free(z);
        dense_free(xy);
        if (xyz.coefficients == NULL) {
            dense_free(*result);
            *result = dense_empty();
            return false;
        }

        for (size_t j = 0; j < xyz.length; ++j) {
            result->coefficients[j] += term.coefficient * xyz.coefficients[j];
        }
        dense_free(xyz);
    }
    return true;
}

static double sparse_evaluate(surfer_sparse_polynomial polynomial, surfer_vec3 point)
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
    const double a = vec3_dot(ray.direction, ray.direction);
    if (a == 0.0) {
        return false;
    }
    const double b = 2.0 * vec3_dot(ray.origin, ray.direction);
    const double c = vec3_dot(ray.origin, ray.origin) - 1.0;
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

    dense_polynomial polynomial = dense_empty();
    if (!sparse_on_ray(surface->surface, surface_ray, &polynomial)) {
        return false;
    }
    dense_polynomial shrunk = dense_shrink_copy(&polynomial);
    dense_free(polynomial);
    if (shrunk.coefficients == NULL) {
        return false;
    }

    double candidate = NAN;
    const size_t degree = dense_true_length(&shrunk) - 1;
    if (surface->family_degree < 2) {
        if (degree == 1) {
            candidate = -shrunk.coefficients[0] / shrunk.coefficients[1];
            if (!(lower <= candidate && candidate <= upper)) {
                candidate = NAN;
            }
        }
    } else {
        candidate = find_first_descartes_root(&shrunk, lower, upper);
    }
    dense_free(shrunk);

    if (isnan(candidate)) {
        return false;
    }
    *root = candidate;
    return true;
}

static surfer_color shade_with_material(
    const surfer_scene *scene,
    surfer_vec3 hit,
    surfer_vec3 view,
    surfer_vec3 normal,
    surfer_material material)
{
    surfer_color color = color_scale(material.color, material.ambient_intensity);

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
            vec3_normalize(vec3_subtract(light.position, hit));
        const float lambert = (float)vec3_dot(normal, light_direction);
        if (lambert <= 0.0f) {
            continue;
        }

        const surfer_color diffuse_product = color_scale(
            color_product(material.color, light.color),
            material.diffuse_intensity * light.intensity);
        color = color_scale_add(color, lambert, diffuse_product);

        const surfer_vec3 half_vector =
            vec3_normalize(vec3_add(light_direction, view));
        const float normal_half =
            (float)fmax(0.0, vec3_dot(normal, half_vector));
        const float specular_factor = powf(normal_half, material.shininess);
        const surfer_color specular_product = color_scale(
            light.color,
            material.specular_intensity * light.intensity);
        color = color_scale_add(color, specular_factor, specular_product);
    }
    return color_clamp_max(color, 1.0f);
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

    surfer_interval interval;
    if (!surfer_clip_unit_sphere(rays.clipping_ray, &interval)) {
        return result;
    }
    if (interval.lower < rays.eye_location_on_ray &&
        rays.eye_location_on_ray < interval.upper) {
        interval.lower = fmax(interval.lower, rays.eye_location_on_ray);
    }

    double hit_parameter = NAN;
    if (!surfer_first_surface_root(
            scene->surface,
            rays.surface_ray,
            interval.lower,
            interval.upper,
            &hit_parameter)) {
        return result;
    }

    const surfer_vec3 clipping_hit = ray_at(rays.clipping_ray, hit_parameter);
    if (vec3_dot(clipping_hit, clipping_hit) > 1.0 + 1e-12) {
        return result;
    }

    const surfer_vec3 surface_hit = ray_at(rays.surface_ray, hit_parameter);
    surfer_vec3 surface_normal = {
        sparse_evaluate(scene->surface->gradient_x, surface_hit),
        sparse_evaluate(scene->surface->gradient_y, surface_hit),
        sparse_evaluate(scene->surface->gradient_z, surface_hit)
    };
    surfer_vec3 normal = mat3_apply(rays.surface_normal_to_camera, surface_normal);
    const float normal_length = (float)vec3_length(normal);
    if (normal_length != 0.0f) {
        normal = vec3_scale(normal, 1.0f / normal_length);
    }

    const surfer_vec3 camera_hit = ray_at(rays.camera_ray, hit_parameter);
    const surfer_vec3 eye = ray_at(rays.camera_ray, rays.eye_location_on_ray);
    const surfer_vec3 view = vec3_normalize(vec3_subtract(eye, camera_hit));
    surfer_material material = scene->front_material;
    if (vec3_dot(normal, view) <= 0.0) {
        normal = vec3_scale(normal, -1.0);
        material = scene->back_material;
    }

    result.hit = true;
    result.ray_parameter = hit_parameter;
    result.point = camera_hit;
    result.surface_normal = normal;
    result.color = shade_with_material(scene, camera_hit, view, normal, material);
    return result;
}

uint32_t surfer_color_to_argb(surfer_color color)
{
    const float red = clamp_float(color.red, 0.0f, 1.0f);
    const float green = clamp_float(color.green, 0.0f, 1.0f);
    const float blue = clamp_float(color.blue, 0.0f, 1.0f);
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

    const double effective_height = camera_height / zoom;
    const double half_v = effective_height / 2.0;
    const double half_u = half_v * (double)width / (double)height;
    const surfer_mat3 camera_to_surface = view_rotation(yaw, pitch);
    const surfer_mat3 normal_to_camera = mat3_transpose(camera_to_surface);
    const surfer_vec3 surface_u = mat3_apply(
        camera_to_surface, (surfer_vec3){1.0, 0.0, 0.0});
    const surfer_vec3 surface_v = mat3_apply(
        camera_to_surface, (surfer_vec3){0.0, 1.0, 0.0});
    const surfer_vec3 surface_direction = mat3_apply(
        camera_to_surface, (surfer_vec3){0.0, 0.0, -1.0});

    for (size_t y = 0; y < height; ++y) {
        const double v = -half_v +
            (2.0 * half_v * (double)y) / (double)(height - 1);
        for (size_t x = 0; x < width; ++x) {
            const double u = -half_u +
                (2.0 * half_u * (double)x) / (double)(width - 1);
            const surfer_vec3 surface_origin = vec3_add(
                vec3_scale(surface_u, u),
                vec3_scale(surface_v, v));
            const surfer_ray_bundle rays = {
                {{u, v, -1.0}, {0.0, 0.0, -1.0}},
                {surface_origin, surface_direction},
                {surface_origin, surface_direction},
                -1.0,
                normal_to_camera
            };
            const surfer_trace_result trace =
                surfer_trace_prepared_ray(scene, rays);
            argb_pixels[y * width + x] = surfer_color_to_argb(trace.color);
        }
    }
    return true;
}
