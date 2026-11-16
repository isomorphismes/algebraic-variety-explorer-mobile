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
    surfer_status status;
    const surfer_cancellation *cancellation;
#ifdef SURFER_TEST_ALLOCATION_FAILURES
    surfer_allocation_probe *probe;
#endif
} surfer_operation_context;

static surfer_operation_context new_operation_context(void)
{
    surfer_operation_context context;
    context.status = SURFER_OK;
    context.cancellation = NULL;
#ifdef SURFER_TEST_ALLOCATION_FAILURES
    context.probe = NULL;
#endif
    return context;
}

const char *surfer_status_name(surfer_status status)
{
    switch (status) {
    case SURFER_OK: return "success (SURFER_OK)";
    case SURFER_MISS: return "geometric miss (SURFER_MISS)";
    case SURFER_INVALID_INPUT: return "invalid input (SURFER_INVALID_INPUT)";
    case SURFER_OUT_OF_MEMORY: return "out of memory (SURFER_OUT_OF_MEMORY)";
    case SURFER_CANCELLED: return "cancelled (SURFER_CANCELLED)";
    }
    return "unknown SURFER status";
}

/* Cancellation never changes arithmetic or replaces an earlier failure.
 * Existing public entry points leave the predicate NULL. */
static bool continue_operation(surfer_operation_context *context)
{
    if (context->status != SURFER_OK) return false;
    if (context->cancellation != NULL &&
        context->cancellation->cancelled(context->cancellation->state)) {
        context->status = SURFER_CANCELLED;
        return false;
    }
    return true;
}

static bool checked_array_bytes(
    surfer_operation_context *context, size_t count, size_t item_size,
    size_t *bytes)
{
    if (item_size != 0 && count > SIZE_MAX / item_size) {
        context->status = SURFER_INVALID_INPUT;
        return false;
    }
    *bytes = count * item_size;
    return true;
}

static bool should_fail_allocation(surfer_operation_context *context)
{
#ifdef SURFER_TEST_ALLOCATION_FAILURES
    if (context->probe != NULL) {
        const size_t attempt = context->probe->attempts;
        if (attempt == SIZE_MAX) {
            context->status = SURFER_INVALID_INPUT;
            return true;
        }
        context->probe->attempts = attempt + 1;
        if (attempt == context->probe->fail_at) {
            context->status = SURFER_OUT_OF_MEMORY;
            return true;
        }
    }
#else
    (void)context;
#endif
    return false;
}

/* Test coverage tags: storage, copy, zero deflation, shift, coefficient
 * transform, sign variations and candidate-stack growth. No global state.
 */
static void mark_allocation_path(surfer_operation_context *context, uint32_t path)
{
#ifdef SURFER_TEST_ALLOCATION_FAILURES
    if (context->probe != NULL) context->probe->paths |= path;
#else
    (void)context;
    (void)path;
#endif
}

static void *allocate_array(
    surfer_operation_context *context, size_t count, size_t item_size,
    bool clear)
{
    size_t bytes = 0;
    if (!continue_operation(context) ||
        !checked_array_bytes(context, count, item_size, &bytes) || bytes == 0 ||
        should_fail_allocation(context)) {
        return NULL;
    }
    void *result = clear ? calloc(count, item_size) : malloc(bytes);
    if (result == NULL) {
        context->status = SURFER_OUT_OF_MEMORY;
    }
    return result;
}

static void *resize_array(
    surfer_operation_context *context, void *previous,
    size_t count, size_t item_size)
{
    size_t bytes = 0;
    if (!continue_operation(context) ||
        !checked_array_bytes(context, count, item_size, &bytes) || bytes == 0 ||
        should_fail_allocation(context)) {
        return NULL;
    }
    void *result = realloc(previous, bytes);
    if (result == NULL) {
        context->status = SURFER_OUT_OF_MEMORY;
    }
    return result;
}

static bool finite_vector(surfer_vec3 value)
{
    return isfinite(value.x) && isfinite(value.y) && isfinite(value.z);
}

static bool finite_coefficients(
    surfer_operation_context *context, const double *coefficients, size_t length)
{
    for (size_t i = 0; i < length; ++i) {
        if (!continue_operation(context)) return false;
        if (!isfinite(coefficients[i])) {
            context->status = SURFER_INVALID_INPUT;
            return false;
        }
    }
    return true;
}

static bool finite_matrix(surfer_mat3 matrix)
{
    return isfinite(matrix.m00) && isfinite(matrix.m01) && isfinite(matrix.m02) &&
        isfinite(matrix.m10) && isfinite(matrix.m11) && isfinite(matrix.m12) &&
        isfinite(matrix.m20) && isfinite(matrix.m21) && isfinite(matrix.m22);
}

static bool finite_color(surfer_color color)
{
    return isfinite(color.red) && isfinite(color.green) && isfinite(color.blue);
}

static bool finite_material(surfer_material material)
{
    return finite_color(material.color) && isfinite(material.ambient_intensity) &&
        isfinite(material.diffuse_intensity) && isfinite(material.specular_intensity) &&
        isfinite(material.shininess);
}

static bool valid_ray(surfer_ray ray)
{
    return finite_vector(ray.origin) && finite_vector(ray.direction) &&
        (ray.direction.x != 0.0 || ray.direction.y != 0.0 || ray.direction.z != 0.0);
}

static bool valid_sparse_polynomial(
    surfer_operation_context *context,
    surfer_sparse_polynomial polynomial, int64_t *maximum_degree)
{
    if ((polynomial.term_count != 0 && polynomial.terms == NULL) ||
        polynomial.term_count > SIZE_MAX / sizeof(*polynomial.terms)) {
        return false;
    }
    int64_t degree = 0;
    for (size_t i = 0; i < polynomial.term_count; ++i) {
        if (!continue_operation(context)) return false;
        const surfer_term term = polynomial.terms[i];
        if (!isfinite(term.coefficient) || term.x_exponent < 0 ||
            term.y_exponent < 0 || term.z_exponent < 0) {
            return false;
        }
        const int64_t total = (int64_t)term.x_exponent +
            (int64_t)term.y_exponent + (int64_t)term.z_exponent;
        if (total > degree) degree = total;
    }
    *maximum_degree = degree;
    return true;
}

static bool valid_prepared_surface(
    surfer_operation_context *context, const surfer_prepared_surface *surface)
{
    int64_t degree = 0;
    int64_t ignored = 0;
    if (surface == NULL || surface->family_degree < 0 ||
        !valid_sparse_polynomial(context, surface->surface, &degree) ||
        !valid_sparse_polynomial(context, surface->gradient_x, &ignored) ||
        !valid_sparse_polynomial(context, surface->gradient_y, &ignored) ||
        !valid_sparse_polynomial(context, surface->gradient_z, &ignored) ||
        degree > surface->family_degree) {
        return false;
    }
    return (uint64_t)degree < SIZE_MAX / sizeof(double);
}

static bool valid_scene(surfer_operation_context *context, const surfer_scene *scene)
{
    if (scene == NULL || !valid_prepared_surface(context, scene->surface) ||
        !finite_color(scene->background) || !finite_material(scene->front_material) ||
        !finite_material(scene->back_material) || scene->light_count > SURFER_MAX_LIGHTS) {
        return false;
    }
    for (size_t i = 0; i < scene->light_count; ++i) {
        if (!finite_vector(scene->lights[i].position) ||
            !finite_color(scene->lights[i].color) || !isfinite(scene->lights[i].intensity)) {
            return false;
        }
    }
    return true;
}

surfer_status surfer_validate_prepared_surface(const surfer_prepared_surface *surface)
{
    surfer_operation_context context = new_operation_context();
    return valid_prepared_surface(&context, surface) ? SURFER_OK : SURFER_INVALID_INPUT;
}

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

typedef struct original_camera_view original_camera_view;

typedef struct {
    double half_u;
    double half_v;
    surfer_mat3 camera_to_surface;
    surfer_mat3 surface_normal_to_camera;
    surfer_vec3 surface_u;
    surfer_vec3 surface_v;
    surfer_vec3 surface_direction;
    const original_camera_view *original_camera;
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

static univariate_polynomial allocate_univariate_polynomial(surfer_operation_context *context, size_t length)
{
    univariate_polynomial result = empty_univariate_polynomial();
    if (length == 0) {
        return result;
    }
    mark_allocation_path(context, UINT32_C(1));
    result.coefficients = allocate_array(context, length, sizeof(*result.coefficients), true);
    if (result.coefficients == NULL) {
        return empty_univariate_polynomial();
    }
    result.length = length;
    return result;
}

static univariate_polynomial copy_univariate_polynomial(surfer_operation_context *context, const double *coefficients, size_t length)
{
    if (length != 0) mark_allocation_path(context, UINT32_C(2));
    univariate_polynomial result = allocate_univariate_polynomial(context, length);
    if (length != 0 && result.coefficients == NULL) {
        return empty_univariate_polynomial();
    }
    if (length != 0) {
        memcpy(result.coefficients, coefficients, length * sizeof(*coefficients));
    }
    if (!finite_coefficients(context, result.coefficients, length)) {
        free_univariate_polynomial(result);
        return empty_univariate_polynomial();
    }
    return result;
}

static size_t coefficient_count_without_trailing_zeroes(
    surfer_operation_context *context, const univariate_polynomial *polynomial)
{
    size_t length = polynomial->length;
    while (length > 1 && polynomial->coefficients[length - 1] == 0.0) {
        if (!continue_operation(context)) return 0;
        --length;
    }
    return length;
}

static univariate_polynomial copy_without_trailing_zeroes(surfer_operation_context *context, const univariate_polynomial *polynomial)
{
    return copy_univariate_polynomial(context, polynomial->coefficients,
        coefficient_count_without_trailing_zeroes(context, polynomial));
}

/*
 * Stussak: UnivariatePolynomial.evaluateAt.
 * Keep its two Horner directions because the choice is numerical, not cosmetic.
 */
static double evaluate_univariate_polynomial_at(surfer_operation_context *context,
    const univariate_polynomial *polynomial,
    double where)
{
    if (polynomial->length == 0) {
        return 0.0;
    }
    if (fabs(where) <= 1.0) {
        double result = polynomial->coefficients[polynomial->length - 1];
        for (size_t i = polynomial->length - 1; i-- > 0;) {
            if (!continue_operation(context)) return NAN;
            result = result * where + polynomial->coefficients[i];
            if (!isfinite(result)) {
                context->status = SURFER_INVALID_INPUT;
                return NAN;
            }
        }
        return result;
    }

    double result = polynomial->coefficients[0];
    for (size_t i = 1; i < polynomial->length; ++i) {
        if (!continue_operation(context)) return NAN;
        result = result / where + polynomial->coefficients[i];
        if (!isfinite(result)) {
            context->status = SURFER_INVALID_INPUT;
            return NAN;
        }
    }
    result *= pow(where, (double)(polynomial->length - 1));
    if (!isfinite(result)) context->status = SURFER_INVALID_INPUT;
    return result;
}

static univariate_polynomial stretch_univariate_polynomial(surfer_operation_context *context,
    const univariate_polynomial *polynomial,
    double factor)
{
    if (polynomial->length != 0) mark_allocation_path(context, UINT32_C(16));
    univariate_polynomial result = allocate_univariate_polynomial(context, polynomial->length);
    if (polynomial->length != 0 && result.coefficients == NULL) {
        return empty_univariate_polynomial();
    }
    double multiplier = 1.0;
    for (size_t i = 0; i < polynomial->length; ++i) {
        if (!continue_operation(context)) break;
        result.coefficients[i] = polynomial->coefficients[i] * multiplier;
        multiplier *= factor;
    }
    if (!finite_coefficients(context, result.coefficients, result.length)) {
        free_univariate_polynomial(result);
        return empty_univariate_polynomial();
    }
    return result;
}

static double *deflate_zero_root(surfer_operation_context *context, const double *coefficients, size_t length, size_t *new_length)
{
    if (length == 0) {
        *new_length = 0;
        return NULL;
    }
    *new_length = length - 1;
    if (*new_length == 0) {
        return NULL;
    }
    mark_allocation_path(context, UINT32_C(4));
    double *result = allocate_array(context, *new_length, sizeof(*result), false);
    if (result == NULL) {
        *new_length = 0;
        return NULL;
    }
    memcpy(result, coefficients + 1, *new_length * sizeof(*result));
    return result;
}

static double *shift_univariate_polynomial_by_one(surfer_operation_context *context, const double *coefficients, size_t length)
{
    if (length == 0) {
        return NULL;
    }
    mark_allocation_path(context, UINT32_C(8));
    double *result = allocate_array(context, length, sizeof(*result), false);
    if (result == NULL) {
        return NULL;
    }
    memcpy(result, coefficients, length * sizeof(*result));
    for (size_t i = 1; i <= length; ++i) {
        for (size_t j = length - 1; j > i - 1;) {
            if (!continue_operation(context)) { free(result); return NULL; }
            --j;
            result[j] += result[j + 1];
        }
    }
    if (!finite_coefficients(context, result, length)) {
        free(result);
        return NULL;
    }
    return result;
}

static double *stretch_univariate_polynomial_to_half_interval(surfer_operation_context *context, const double *coefficients, size_t length)
{
    if (length == 0) {
        return NULL;
    }
    mark_allocation_path(context, UINT32_C(16));
    double *result = allocate_array(context, length, sizeof(*result), false);
    if (result == NULL) {
        return NULL;
    }
    result[length - 1] = coefficients[length - 1];
    double multiplier = 2.0;
    for (size_t i = length - 1; i-- > 0;) {
        if (!continue_operation(context)) break;
        result[i] = coefficients[i] * multiplier;
        multiplier *= 2.0;
    }
    if (!finite_coefficients(context, result, length)) {
        free(result);
        return NULL;
    }
    return result;
}

static int descartes_sign_changes_after_reverse_shift_by_one(surfer_operation_context *context,
    const double *coefficients,
    size_t length)
{
    if (length == 0) {
        return 0;
    }
    mark_allocation_path(context, UINT32_C(32));
    double *horner = allocate_array(context, length, sizeof(*horner), false);
    if (horner == NULL) {
        return -1;
    }
    for (size_t i = 0; i < length; ++i) {
        if (!continue_operation(context)) { free(horner); return -1; }
        horner[i] = coefficients[length - i - 1];
    }

    int sign_changes = 0;
    double last_nonzero = NAN;
    for (size_t i = 1; i <= length; ++i) {
        for (size_t j = length - 1; j > i - 1;) {
            if (!continue_operation(context)) { free(horner); return -1; }
            --j;
            horner[j] += horner[j + 1];
            if (!isfinite(horner[j])) {
                context->status = SURFER_INVALID_INPUT;
                free(horner);
                return -1;
            }
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

static double bisect_root_interval(surfer_operation_context *context,
    const univariate_polynomial *polynomial,
    double lower,
    double upper,
    double lower_value,
    double upper_value)
{
    (void)upper_value;
    while (fabs(upper - lower) > SURFER_ROOT_EPSILON) {
        if (!continue_operation(context)) return NAN;
        const double center = 0.5 * (lower + upper);
        if (!isfinite(center)) {
            context->status = SURFER_INVALID_INPUT;
            return NAN;
        }
        double center_value = polynomial->coefficients[polynomial->length - 1];
        for (size_t i = polynomial->length - 1; i-- > 0;) {
            if (!continue_operation(context)) return NAN;
            center_value = center_value * center + polynomial->coefficients[i];
            if (!isfinite(center_value)) {
                context->status = SURFER_INVALID_INPUT;
                return NAN;
            }
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

static double restrict_interval_and_bisect_root(surfer_operation_context *context,
    const univariate_polynomial *polynomial,
    double lower,
    double upper,
    double strict_lower,
    double strict_upper)
{
    double lower_value = evaluate_univariate_polynomial_at(context, polynomial, lower);
    if (context->status != SURFER_OK) return NAN;
    if (lower < strict_lower) {
        if (upper < strict_lower) {
            return NAN;
        }
        const double strict_value = evaluate_univariate_polynomial_at(context, polynomial, strict_lower);
        if (context->status != SURFER_OK) return NAN;
        if (lower_value * strict_value < 0.0 || lower_value == 0.0) {
            return NAN;
        }
        lower = strict_lower;
        lower_value = strict_value;
    }

    double upper_value = evaluate_univariate_polynomial_at(context, polynomial, upper);
    if (context->status != SURFER_OK) return NAN;
    if (strict_upper < upper) {
        if (strict_upper < lower) {
            return NAN;
        }
        const double strict_value = evaluate_univariate_polynomial_at(context, polynomial, strict_upper);
        if (context->status != SURFER_OK) return NAN;
        if (upper_value * strict_value < 0.0 || upper_value == 0.0) {
            return NAN;
        }
        upper = strict_upper;
        upper_value = strict_value;
    }

    if (lower_value * upper_value <= 0.0) {
        return bisect_root_interval(context, polynomial, lower, upper, lower_value, upper_value);
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

static bool push_descartes_candidate(surfer_operation_context *context,
    descartes_candidate_stack *stack,
    descartes_interval interval)
{
    if (stack->length == stack->capacity) {
        mark_allocation_path(context, UINT32_C(64));
        if (stack->capacity > SIZE_MAX / 2) {
            context->status = SURFER_INVALID_INPUT;
            free_descartes_interval(&interval);
            return false;
        }
        const size_t new_capacity =
            stack->capacity == 0 ? 16 : 2 * stack->capacity;
        descartes_interval *new_items = resize_array(
            context, stack->items, new_capacity, sizeof(*new_items));
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

static double find_positive_root_with_descartes(surfer_operation_context *context,
    const univariate_polynomial *source,
    double lower_bound,
    double upper_bound,
    which_root order)
{
    if (upper_bound <= 0.0 || coefficient_count_without_trailing_zeroes(context, source) <= 1) {
        return NAN;
    }

    univariate_polynomial shrunk = copy_without_trailing_zeroes(context, source);
    if (shrunk.coefficients == NULL) {
        return NAN;
    }

    const double bound = next_power_of_two_outward(upper_bound);
    if (!(bound > 0.0) || !isfinite(bound)) {
        context->status = SURFER_INVALID_INPUT;
        free_univariate_polynomial(shrunk);
        return NAN;
    }
    const double transformed_lower = lower_bound / bound;
    const double transformed_upper = upper_bound / bound;

    univariate_polynomial polynomial = stretch_univariate_polynomial(context, &shrunk, bound);
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
        double *deflated = deflate_zero_root(context,
            polynomial.coefficients,
            polynomial.length,
            &deflated_length);
        free(polynomial.coefficients);
        polynomial.coefficients = deflated;
        polynomial.length = deflated_length;
        if (context->status != SURFER_OK) {
            free_univariate_polynomial(polynomial);
            return NAN;
        }
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
        copy_univariate_polynomial(context, polynomial.coefficients, polynomial.length).coefficients,
        polynomial.length,
        false,
        0.0,
        1.0
    };
    if (initial.coefficients == NULL ||
        !push_descartes_candidate(context, &candidates, initial)) {
        free_univariate_polynomial(polynomial);
        free_descartes_candidate_stack(&candidates);
        return NAN;
    }

    while (candidates.length != 0) {
        if (!continue_operation(context)) break;
        descartes_interval current = pop_descartes_candidate(&candidates);
        if (current.shift_by_one_when_used) {
            double *shifted = shift_univariate_polynomial_by_one(context, current.coefficients, current.length);
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
                double *deflated = deflate_zero_root(context,
                    current.coefficients,
                    current.length,
                    &deflated_length);
                free(current.coefficients);
                current.coefficients = deflated;
                current.length = deflated_length;
                if (context->status != SURFER_OK) {
                    free_descartes_interval(&current);
                    break;
                }
                if (current.length == 0) {
                    free_descartes_interval(&current);
                    continue;
                }
            }
        }

        const int variations = descartes_sign_changes_after_reverse_shift_by_one(context,
            current.coefficients,
            current.length);
        if (variations < 0) {
            free_descartes_interval(&current);
            break;
        }
        if (variations == 1) {
            const double transformed_root = restrict_interval_and_bisect_root(context,
                &polynomial,
                current.lower,
                current.upper,
                transformed_lower,
                transformed_upper);
            const double candidate = transformed_root * bound;
            free_descartes_interval(&current);
            if (context->status != SURFER_OK) {
                free_descartes_candidate_stack(&candidates);
                free_univariate_polynomial(polynomial);
                return NAN;
            }
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

            double *stretched = stretch_univariate_polynomial_to_half_interval(context,
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
                copy_univariate_polynomial(context, stretched, current.length).coefficients,
                current.length,
                false,
                current.lower,
                center
            };
            descartes_interval upper_child = {
                copy_univariate_polynomial(context, stretched, current.length).coefficients,
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
                    ok = push_descartes_candidate(context, &candidates, upper_child);
                    upper_child.coefficients = NULL;
                }
                if (ok && center >= transformed_lower) {
                    ok = push_descartes_candidate(context, &candidates, lower_child);
                    lower_child.coefficients = NULL;
                }
            } else {
                if (center >= transformed_lower) {
                    ok = push_descartes_candidate(context, &candidates, lower_child);
                    lower_child.coefficients = NULL;
                }
                if (ok && center <= transformed_upper) {
                    ok = push_descartes_candidate(context, &candidates, upper_child);
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
    return context->status == SURFER_OK ? saved_result : NAN;
}

static double find_first_root_with_descartes(surfer_operation_context *context,
    const univariate_polynomial *polynomial,
    double lower,
    double upper)
{
    univariate_polynomial reflected = stretch_univariate_polynomial(context, polynomial, -1.0);
    if (reflected.coefficients == NULL) {
        return NAN;
    }

    /*
     * Stussak's DescartesRootFinder searches the reflected negative half
     * first, asking for its largest positive root, then searches the positive
     * half for the smallest root.
     */
    const double negative = -find_positive_root_with_descartes(context,
        &reflected,
        -upper,
        -lower,
        LARGEST_ROOT);
    free_univariate_polynomial(reflected);
    if (context->status != SURFER_OK) {
        return NAN;
    }
    if (!isnan(negative)) {
        return negative;
    }
    return find_positive_root_with_descartes(context,
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

static bool polynomial_for_axis_power_along_ray(surfer_operation_context *context,
    double origin,
    double direction,
    int32_t exponent,
    univariate_polynomial *result)
{
    if (exponent < 0) {
        context->status = SURFER_INVALID_INPUT;
        return false;
    }
    *result = allocate_univariate_polynomial(context, (size_t)exponent + 1);
    if (result->coefficients == NULL) {
        return false;
    }
    if (exponent == 0) {
        result->coefficients[0] = 1.0;
        return true;
    }

    double binomial = 1.0;
    for (size_t index = 0; index <= (size_t)exponent; ++index) {
        if (!continue_operation(context)) break;
        const int32_t k = (int32_t)index;
        if (k != 0) {
            binomial *= (double)(exponent - (k - 1));
            binomial /= (double)k;
        }
        result->coefficients[k] =
            binomial *
            integer_power(origin, exponent - k) *
            integer_power(direction, k);
    }
    if (!finite_coefficients(context, result->coefficients, result->length)) {
        free_univariate_polynomial(*result);
        *result = empty_univariate_polynomial();
        return false;
    }
    return true;
}

static univariate_polynomial multiply_univariate_polynomials(surfer_operation_context *context,
    const univariate_polynomial *left,
    const univariate_polynomial *right)
{
    if (left->length == 0 || right->length == 0) {
        return empty_univariate_polynomial();
    }
    if (left->length > SIZE_MAX - (right->length - 1)) {
        context->status = SURFER_INVALID_INPUT;
        return empty_univariate_polynomial();
    }
    univariate_polynomial result = allocate_univariate_polynomial(context, left->length + right->length - 1);
    if (result.coefficients == NULL) {
        return empty_univariate_polynomial();
    }
    for (size_t i = 0; i < left->length; ++i) {
        for (size_t j = 0; j < right->length; ++j) {
            if (!continue_operation(context)) {
                free_univariate_polynomial(result);
                return empty_univariate_polynomial();
            }
            result.coefficients[i + j] +=
                left->coefficients[i] * right->coefficients[j];
        }
    }
    if (!finite_coefficients(context, result.coefficients, result.length)) {
        free_univariate_polynomial(result);
        return empty_univariate_polynomial();
    }
    return result;
}

static bool maximum_total_degree_of_sparse_polynomial(
    surfer_operation_context *context,
    surfer_sparse_polynomial polynomial,
    size_t *maximum_degree)
{
    int64_t largest_degree = 0;
    for (size_t i = 0; i < polynomial.term_count; ++i) {
        if (!continue_operation(context)) return false;
        const surfer_term term = polynomial.terms[i];
        if (term.x_exponent < 0 ||
            term.y_exponent < 0 ||
            term.z_exponent < 0) {
            return false;
        }

        const int64_t term_degree =
            (int64_t)term.x_exponent +
            (int64_t)term.y_exponent +
            (int64_t)term.z_exponent;
        if (term_degree > largest_degree) {
            largest_degree = term_degree;
        }
    }

    if ((uint64_t)largest_degree > SIZE_MAX - 1U) {
        return false;
    }
    *maximum_degree = (size_t)largest_degree;
    return true;
}

static bool polynomial_for_sparse_term_along_ray(surfer_operation_context *context,
    surfer_term term,
    surfer_ray ray,
    univariate_polynomial *result)
{
    univariate_polynomial x_power = empty_univariate_polynomial();
    univariate_polynomial y_power = empty_univariate_polynomial();
    univariate_polynomial z_power = empty_univariate_polynomial();

    if (!polynomial_for_axis_power_along_ray(context,
            ray.origin.x,
            ray.direction.x,
            term.x_exponent,
            &x_power) ||
        !polynomial_for_axis_power_along_ray(context,
            ray.origin.y,
            ray.direction.y,
            term.y_exponent,
            &y_power) ||
        !polynomial_for_axis_power_along_ray(context,
            ray.origin.z,
            ray.direction.z,
            term.z_exponent,
            &z_power)) {
        free_univariate_polynomial(x_power);
        free_univariate_polynomial(y_power);
        free_univariate_polynomial(z_power);
        return false;
    }

    univariate_polynomial xy_power =
        multiply_univariate_polynomials(context, &x_power, &y_power);
    free_univariate_polynomial(x_power);
    free_univariate_polynomial(y_power);
    if (xy_power.coefficients == NULL) {
        free_univariate_polynomial(z_power);
        return false;
    }

    univariate_polynomial xyz_power =
        multiply_univariate_polynomials(context, &xy_power, &z_power);
    free_univariate_polynomial(xy_power);
    free_univariate_polynomial(z_power);
    if (xyz_power.coefficients == NULL) {
        return false;
    }

    *result = xyz_power;
    return true;
}

static bool add_scaled_univariate_polynomial(
    surfer_operation_context *context,
    univariate_polynomial *sum,
    const univariate_polynomial *addition,
    double scale)
{
    for (size_t i = 0; i < addition->length; ++i) {
        if (!continue_operation(context)) return false;
        sum->coefficients[i] += scale * addition->coefficients[i];
    }
    return true;
}

/*
 * Current PreparedSurface bridge only.
 *
 * Stussak's production path specializes XYZ → XY → univariate in stages.
 * Until that exact path is translated, name this direct expansion for what it
 * is instead of hiding the difference behind a generic "specialize" name.
 *
 * term → x(t), y(t), z(t) powers → one term polynomial → accumulated sum
 */
static bool expand_sparse_polynomial_directly_along_ray(surfer_operation_context *context,
    surfer_sparse_polynomial source,
    surfer_ray ray,
    univariate_polynomial *result)
{
    size_t maximum_degree = 0;
    if (!maximum_total_degree_of_sparse_polynomial(context, source, &maximum_degree)) {
        if (context->status == SURFER_OK) context->status = SURFER_INVALID_INPUT;
        return false;
    }

    *result = allocate_univariate_polynomial(context, maximum_degree + 1);
    if (result->coefficients == NULL) {
        return false;
    }

    for (size_t i = 0; i < source.term_count; ++i) {
        const surfer_term term = source.terms[i];
        univariate_polynomial term_on_ray = empty_univariate_polynomial();
        if (!polynomial_for_sparse_term_along_ray(context,
                term,
                ray,
                &term_on_ray)) {
            free_univariate_polynomial(*result);
            *result = empty_univariate_polynomial();
            return false;
        }

        const bool added = add_scaled_univariate_polynomial(context,
            result,
            &term_on_ray,
            term.coefficient);
        free_univariate_polynomial(term_on_ray);
        if (!added) {
            free_univariate_polynomial(*result);
            *result = empty_univariate_polynomial();
            return false;
        }
    }
    if (!finite_coefficients(context, result->coefficients, result->length)) {
        free_univariate_polynomial(*result);
        *result = empty_univariate_polynomial();
        return false;
    }
    return true;
}

static double evaluate_sparse_polynomial_at_point(
    surfer_operation_context *context,
    surfer_sparse_polynomial polynomial, surfer_vec3 point)
{
    double result = 0.0;
    for (size_t i = 0; i < polynomial.term_count; ++i) {
        if (!continue_operation(context)) return NAN;
        const surfer_term term = polynomial.terms[i];
        result += term.coefficient *
            integer_power(point.x, term.x_exponent) *
            integer_power(point.y, term.y_exponent) *
            integer_power(point.z, term.z_exponent);
    }
    return result;
}

surfer_status surfer_clip_unit_sphere(surfer_ray ray, surfer_interval *interval)
{
    if (interval == NULL || !valid_ray(ray)) {
        return SURFER_INVALID_INPUT;
    }
    const double a = dot_product(ray.direction, ray.direction);
    if (!(a > 0.0) || !isfinite(a)) {
        return SURFER_INVALID_INPUT;
    }
    const double b = 2.0 * dot_product(ray.origin, ray.direction);
    const double c = dot_product(ray.origin, ray.origin) - 1.0;
    const double discriminant = b * b - 4.0 * a * c;
    if (!isfinite(b) || !isfinite(c) || !isfinite(discriminant)) {
        return SURFER_INVALID_INPUT;
    }
    if (discriminant < 0.0) {
        return SURFER_MISS;
    }
    const double root = sqrt(discriminant);
    double lower = (-b - root) / (2.0 * a);
    double upper = (-b + root) / (2.0 * a);
    if (lower > upper) {
        const double swap = lower;
        lower = upper;
        upper = swap;
    }
    if (!isfinite(lower) || !isfinite(upper)) {
        return SURFER_INVALID_INPUT;
    }
    interval->lower = lower;
    interval->upper = upper;
    return SURFER_OK;
}

static bool prepare_surface_polynomial_on_ray(surfer_operation_context *context,
    const surfer_prepared_surface *surface,
    surfer_ray surface_ray,
    univariate_polynomial *prepared_polynomial)
{
    univariate_polynomial expanded = empty_univariate_polynomial();
    if (!expand_sparse_polynomial_directly_along_ray(context,
            surface->surface,
            surface_ray,
            &expanded)) {
        return false;
    }

    *prepared_polynomial = copy_without_trailing_zeroes(context, &expanded);
    free_univariate_polynomial(expanded);
    return context->status == SURFER_OK &&
        (prepared_polynomial->length == 0 || prepared_polynomial->coefficients != NULL);
}

static double first_linear_root_in_interval(
    surfer_operation_context *context,
    const univariate_polynomial *polynomial,
    double lower,
    double upper)
{
    const size_t coefficient_count =
        coefficient_count_without_trailing_zeroes(context, polynomial);
    if (coefficient_count != 2) {
        return NAN;
    }

    const double root =
        -polynomial->coefficients[0] / polynomial->coefficients[1];
    return lower <= root && root <= upper ? root : NAN;
}

static double first_root_for_surface_family(surfer_operation_context *context,
    const surfer_prepared_surface *surface,
    const univariate_polynomial *polynomial,
    double lower,
    double upper)
{
    if (polynomial->length == 0) {
        return NAN;
    }
    /*
     * Stussak: CPUAlgebraicSurfaceRenderer chooses ClosedFormRootFinder below
     * family degree two and DescartesRootFinder(false) otherwise.
     */
    if (surface->family_degree < 2) {
        return first_linear_root_in_interval(context, polynomial, lower, upper);
    }
    return find_first_root_with_descartes(context, polynomial, lower, upper);
}

static surfer_status first_surface_root_validated(
    surfer_operation_context *context,
    const surfer_prepared_surface *surface,
    surfer_ray surface_ray,
    double lower,
    double upper,
    double *root)
{
    /* PreparedSurface + surface-space ray → p(t) → first permitted root */
    univariate_polynomial polynomial = empty_univariate_polynomial();
    if (!prepare_surface_polynomial_on_ray(context,
            surface,
            surface_ray,
            &polynomial)) {
        return context->status != SURFER_OK ? context->status : SURFER_INVALID_INPUT;
    }

    const double candidate = first_root_for_surface_family(context,
        surface,
        &polynomial,
        lower,
        upper);
    free_univariate_polynomial(polynomial);
    if (context->status != SURFER_OK) {
        return context->status;
    }
    if (isnan(candidate)) {
        return SURFER_MISS;
    }
    if (!isfinite(candidate)) {
        return SURFER_INVALID_INPUT;
    }
    *root = candidate;
    return SURFER_OK;
}

static surfer_status first_surface_root_request(
    surfer_operation_context *context,
    const surfer_prepared_surface *surface, surfer_ray surface_ray,
    double lower, double upper, double *root)
{
    if (!valid_prepared_surface(context, surface) || !valid_ray(surface_ray) ||
        root == NULL || !isfinite(lower) || !isfinite(upper) || lower > upper) {
        return SURFER_INVALID_INPUT;
    }
    return first_surface_root_validated(context, surface, surface_ray, lower, upper, root);
}

surfer_status surfer_first_surface_root(
    const surfer_prepared_surface *surface, surfer_ray surface_ray,
    double lower, double upper, double *root)
{
    surfer_operation_context context = new_operation_context();
    return first_surface_root_request(&context, surface, surface_ray, lower, upper, root);
}

#ifdef SURFER_TEST_ALLOCATION_FAILURES
surfer_status surfer_test_first_surface_root(
    const surfer_prepared_surface *surface, surfer_ray surface_ray,
    double lower, double upper, double *root, surfer_allocation_probe *probe)
{
    surfer_operation_context context = new_operation_context();
    context.probe = probe;
    return first_surface_root_request(&context, surface, surface_ray, lower, upper, root);
}
#endif

static surfer_color add_one_light_to_shaded_color(
    surfer_color color,
    surfer_light light,
    surfer_vec3 hit,
    surfer_vec3 view,
    surfer_vec3 normal,
    surfer_material material)
{
    if (!light.enabled) {
        return color;
    }

    const surfer_vec3 light_direction =
        normalize_vector(subtract_vectors(light.position, hit));
    const float lambert =
        (float)dot_product(normal, light_direction);
    if (lambert <= 0.0f) {
        return color;
    }

    const surfer_color diffuse_product = scale_color(
        multiply_colors(material.color, light.color),
        material.diffuse_intensity * light.intensity);
    color = add_scaled_color(color, lambert, diffuse_product);

    const surfer_vec3 half_vector =
        normalize_vector(add_vectors(light_direction, view));
    const float normal_half =
        (float)fmax(0.0, dot_product(normal, half_vector));
    const float specular_factor =
        powf(normal_half, material.shininess);
    const surfer_color specular_product = scale_color(
        light.color,
        material.specular_intensity * light.intensity);
    return add_scaled_color(color, specular_factor, specular_product);
}

/*
 * Stussak: RenderingTask.shade, expressed as a fold over enabled lights rather
 * than mutable javax.vecmath objects.
 *
 * material → ambient color → each light contribution → clamped color
 */
static surfer_color shade_hit_with_material(
    const surfer_scene *scene,
    surfer_vec3 hit,
    surfer_vec3 view,
    surfer_vec3 normal,
    surfer_material material)
{
    surfer_color color =
        scale_color(material.color, material.ambient_intensity);

    const size_t light_count =
        scene->light_count < SURFER_MAX_LIGHTS
            ? scene->light_count
            : SURFER_MAX_LIGHTS;
    for (size_t i = 0; i < light_count; ++i) {
        color = add_one_light_to_shaded_color(
            color,
            scene->lights[i],
            hit,
            view,
            normal,
            material);
    }
    return clamp_color_to_maximum(color, 1.0f);
}

static surfer_status visible_interval_for_ray_bundle(
    surfer_ray_bundle rays,
    surfer_interval *visible_interval)
{
    /*
     * Stussak's RayCreator keeps one parameter t across camera, clipping, and
     * surface space. ClipToSphere therefore returns an interval in that same t.
     */
    const surfer_status status = surfer_clip_unit_sphere(rays.clipping_ray, visible_interval);
    if (status != SURFER_OK) {
        return status;
    }
    if (visible_interval->lower < rays.eye_location_on_ray &&
        rays.eye_location_on_ray < visible_interval->upper) {
        visible_interval->lower =
            fmax(visible_interval->lower, rays.eye_location_on_ray);
    }
    return SURFER_OK;
}

static surfer_vec3 prepared_gradient_at_surface_point(
    surfer_operation_context *context,
    const surfer_prepared_surface *surface,
    surfer_vec3 surface_point)
{
    surfer_vec3 gradient = {
        evaluate_sparse_polynomial_at_point(context, surface->gradient_x, surface_point),
        evaluate_sparse_polynomial_at_point(context, surface->gradient_y, surface_point),
        evaluate_sparse_polynomial_at_point(context, surface->gradient_z, surface_point)
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

#include "surfer_original_specialization.inc"

static surfer_trace_result trace_prepared_ray_with_row(
    surfer_operation_context *context,
    const surfer_scene *scene,
    surfer_ray_bundle rays,
    const original_xy_polynomial *row,
    double horizontal)
{
    surfer_trace_result result = {
        SURFER_MISS,
        NAN,
        {0.0, 0.0, 0.0},
        {0.0, 0.0, 0.0},
        {0.0f, 0.0f, 0.0f}
    };
    result.color = scene->background;
    if (!continue_operation(context)) { result.status = context->status; return result; }

    /* ray bundle → visible t interval → first surface root */
    surfer_interval visible_interval;
    result.status = visible_interval_for_ray_bundle(rays, &visible_interval);
    if (result.status != SURFER_OK) {
        return result;
    }

    double hit_parameter = NAN;
    if (row == NULL) result.status = first_surface_root_validated(context,
            scene->surface,
            rays.surface_ray,
            visible_interval.lower,
            visible_interval.upper,
            &hit_parameter);
    else {
        univariate_polynomial polynomial = original_evaluate_y(context, &row[0], horizontal);
        const double candidate = context->status == SURFER_OK ?
            first_root_for_surface_family(context, scene->surface, &polynomial,
                visible_interval.lower, visible_interval.upper) : NAN;
        free_univariate_polynomial(polynomial);
        if (context->status != SURFER_OK) result.status = context->status;
        else if (isnan(candidate)) result.status = SURFER_MISS;
        else if (!isfinite(candidate)) result.status = SURFER_INVALID_INPUT;
        else { result.status = SURFER_OK; hit_parameter = candidate; }
    }
    if (result.status != SURFER_OK) {
        return result;
    }

    const surfer_vec3 clipping_point =
        point_on_ray_at_parameter(rays.clipping_ray, hit_parameter);
    if (dot_product(clipping_point, clipping_point) > 1.0 + 1e-12) {
        result.status = SURFER_MISS;
        return result;
    }

    /* surface point → prepared gradient → camera normal */
    const surfer_vec3 surface_point =
        point_on_ray_at_parameter(rays.surface_ray, hit_parameter);
    surfer_vec3 surface_gradient;
    if (row == NULL) surface_gradient =
        prepared_gradient_at_surface_point(context, scene->surface, surface_point);
    else {
        double components[3] = {NAN, NAN, NAN};
        for (size_t component = 0; component < 3 && continue_operation(context); ++component) {
            univariate_polynomial polynomial = original_evaluate_y(context, &row[component + 1], horizontal);
            if (context->status == SURFER_OK)
                components[component] = evaluate_univariate_polynomial_at(context, &polynomial, hit_parameter);
            free_univariate_polynomial(polynomial);
        }
        surface_gradient = (surfer_vec3){components[0], components[1], components[2]};
    }
    if (context->status != SURFER_OK) { result.status = context->status; return result; }
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

    if (!finite_vector(surface_point) || !finite_vector(surface_gradient) ||
        !finite_vector(camera_normal) || !finite_vector(camera_point) || !finite_vector(view)) {
        result.status = SURFER_INVALID_INPUT;
        return result;
    }

    result.status = SURFER_OK;
    result.ray_parameter = hit_parameter;
    result.point = camera_point;
    result.surface_normal = camera_normal;
    result.color =
        shade_hit_with_material(scene, camera_point, view, camera_normal, material);
    if (!finite_color(result.color)) {
        result.status = SURFER_INVALID_INPUT;
    }
    return result;
}

static surfer_trace_result trace_prepared_ray_validated(
    surfer_operation_context *context, const surfer_scene *scene, surfer_ray_bundle rays)
{
    return trace_prepared_ray_with_row(context, scene, rays, NULL, 0.0);
}

surfer_trace_result surfer_trace_prepared_ray(
    const surfer_scene *scene, surfer_ray_bundle rays)
{
    surfer_trace_result invalid = {SURFER_INVALID_INPUT, NAN,
        {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {0.0f, 0.0f, 0.0f}};
    surfer_operation_context context = new_operation_context();
    if (!valid_scene(&context, scene) || !valid_ray(rays.camera_ray) ||
        !valid_ray(rays.clipping_ray) || !valid_ray(rays.surface_ray) ||
        !isfinite(rays.eye_location_on_ray) || !finite_matrix(rays.surface_normal_to_camera)) {
        return invalid;
    }
    return trace_prepared_ray_validated(&context, scene, rays);
}

static uint32_t color_channel_to_byte(float channel)
{
    const float clamped =
        clamp_float_between(channel, 0.0f, 1.0f);
    return (uint32_t)lroundf(clamped * 255.0f);
}

static uint32_t color_to_argb_validated(surfer_color color)
{
    const uint32_t red_byte =
        color_channel_to_byte(color.red);
    const uint32_t green_byte =
        color_channel_to_byte(color.green);
    const uint32_t blue_byte =
        color_channel_to_byte(color.blue);

    return UINT32_C(0xff000000) |
        (red_byte << 16) |
        (green_byte << 8) |
        blue_byte;
}

surfer_status surfer_color_to_argb(surfer_color color, uint32_t *argb)
{
    if (argb == NULL || !finite_color(color)) {
        return SURFER_INVALID_INPUT;
    }
    *argb = color_to_argb_validated(color);
    return SURFER_OK;
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

#include "surfer_original_camera.inc"

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
            (surfer_vec3){0.0, 0.0, -1.0}),
        NULL
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
    if (view.original_camera != NULL) return original_camera_ray_bundle(view.original_camera, u, v);
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

static surfer_status render_orthographic_request(
    surfer_operation_context *context,
    const surfer_scene *scene,
    size_t width,
    size_t height,
    double camera_height,
    double yaw,
    double pitch,
    double zoom,
    uint32_t *argb_pixels,
    size_t pixel_capacity)
{
    if (argb_pixels == NULL || width < 2 || height < 2 ||
        width > SIZE_MAX / height || width * height > SIZE_MAX / sizeof(*argb_pixels) ||
        pixel_capacity < width * height || !isfinite(camera_height) ||
        !isfinite(yaw) || !isfinite(pitch) || !isfinite(zoom) ||
        !(camera_height > 0.0) || !(zoom > 0.0) || !valid_scene(context, scene)) {
        return SURFER_INVALID_INPUT;
    }

    const orthographic_view view = make_orthographic_view(
        width,
        height,
        camera_height,
        yaw,
        pitch,
        zoom);
    if (!isfinite(view.half_u) || !isfinite(view.half_v) ||
        !finite_matrix(view.camera_to_surface) || !finite_matrix(view.surface_normal_to_camera) ||
        !finite_vector(view.surface_u) || !finite_vector(view.surface_v) ||
        !finite_vector(view.surface_direction)) {
        return SURFER_INVALID_INPUT;
    }
    if (!isfinite(orthographic_coordinate(0, width, view.half_u)) ||
        !isfinite(orthographic_coordinate(width - 1, width, view.half_u)) ||
        !isfinite(orthographic_coordinate(0, height, view.half_v)) ||
        !isfinite(orthographic_coordinate(height - 1, height, view.half_v))) {
        return SURFER_INVALID_INPUT;
    }

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
                trace_prepared_ray_validated(context, scene, rays);
            if (trace.status != SURFER_OK && trace.status != SURFER_MISS) {
                return trace.status;
            }
            argb_pixels[y * width + x] =
                color_to_argb_validated(trace.color);
        }
    }
    return SURFER_OK;
}

surfer_status surfer_render_orthographic(
    const surfer_scene *scene, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    uint32_t *argb_pixels, size_t pixel_capacity)
{
    surfer_operation_context context = new_operation_context();
    return render_orthographic_request(&context, scene, width, height, camera_height,
        yaw, pitch, zoom, argb_pixels, pixel_capacity);
}

/* Stussak RenderingTask.colorDiffSqr uses Vector3f subtraction and dot, so
 * every operation here remains binary32, including the two left-to-right adds.
 */
static float color_distance_squared(surfer_color left, surfer_color right)
{
    const float red = left.red - right.red;
    const float green = left.green - right.green;
    const float blue = left.blue - right.blue;
    return red * red + green * green + blue * blue;
}

static bool antialias_refines(
    surfer_render_quality quality, surfer_color upper_left, surfer_color upper_right,
    surfer_color lower_left, surfer_color lower_right)
{
    const float threshold_squared = quality.threshold * quality.threshold;
    return quality.pattern == SURFER_AA_QUINCUNX &&
        (color_distance_squared(upper_left, upper_right) >= threshold_squared ||
         color_distance_squared(upper_left, lower_left) >= threshold_squared ||
         color_distance_squared(upper_left, lower_right) >= threshold_squared ||
         color_distance_squared(upper_right, lower_left) >= threshold_squared ||
         color_distance_squared(upper_right, lower_right) >= threshold_squared ||
         color_distance_squared(lower_left, lower_right) >= threshold_squared);
}

static surfer_color antialias_color(
    surfer_render_quality quality, surfer_color upper_left, surfer_color upper_right,
    surfer_color lower_left, surfer_color lower_right, surfer_color center)
{
    surfer_color result;
    if (antialias_refines(quality, upper_left, upper_right, lower_left, lower_right)) {
        /* AntiAliasingPattern.getQuincunxPattern and Color3f.scaleAdd order. */
        const float third_quarter = 0.25f / 3.0f;
        const float corner_weight = 0.0625f + third_quarter;
        const float center_weight = 1.0f - 4.0f * corner_weight;
        const surfer_color samples[5] = {
            lower_left, upper_left, upper_right, lower_right, center
        };
        result = (surfer_color){0.0f, 0.0f, 0.0f};
        for (size_t sample = 0; sample < 5; ++sample) {
            const float weight = sample == 4 ? center_weight : corner_weight;
            result.red = weight * samples[sample].red + result.red;
            result.green = weight * samples[sample].green + result.green;
            result.blue = weight * samples[sample].blue + result.blue;
        }
    } else {
        result = upper_left;
        result.red = result.red + upper_right.red;
        result.green = result.green + upper_right.green;
        result.blue = result.blue + upper_right.blue;
        result.red = result.red + lower_left.red;
        result.green = result.green + lower_left.green;
        result.blue = result.blue + lower_left.blue;
        result.red = result.red + lower_right.red;
        result.green = result.green + lower_right.green;
        result.blue = result.blue + lower_right.blue;
        result = scale_color(result, 0.25f);
    }
    return clamp_color_to_maximum(result, 1.0f);
}

static surfer_status quality_sample(
    surfer_operation_context *context, const surfer_scene *scene,
    orthographic_view view, original_render_pipeline *pipeline,
    double u, double v, surfer_color *color)
{
    if (!continue_operation(context)) return context->status;
    if (!isfinite(u) || !isfinite(v)) return SURFER_INVALID_INPUT;
    const original_xy_polynomial *row = original_row_for_sample(context, pipeline, v);
    if (row == NULL) return context->status;
    const surfer_trace_result trace = trace_prepared_ray_with_row(
        context, scene, orthographic_ray_bundle_at(view, u, v), row, u);
    if (trace.status != SURFER_OK && trace.status != SURFER_MISS) return trace.status;
    *color = trace.color;
    return SURFER_OK;
}

static surfer_status render_orthographic_quality_prepared(
    surfer_operation_context *context, const surfer_scene *scene,
    size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, uint32_t *argb_pixels, size_t pixel_capacity,
    original_render_pipeline *pipeline)
{
    if (!continue_operation(context)) return context->status;
    if (argb_pixels == NULL || width < 2 || height < 2 ||
        width > SIZE_MAX / height || width * height > SIZE_MAX / sizeof(*argb_pixels) ||
        pixel_capacity < width * height || !isfinite(camera_height) ||
        !isfinite(yaw) || !isfinite(pitch) || !isfinite(zoom) ||
        !(camera_height > 0.0) || !(zoom > 0.0) || !valid_scene(context, scene) ||
        (quality.pattern != SURFER_AA_OG_1X1 && quality.pattern != SURFER_AA_QUINCUNX) ||
        !isfinite(quality.threshold) || quality.threshold < 0.0f) {
        return context->status == SURFER_OK ? SURFER_INVALID_INPUT : context->status;
    }
    original_camera_view camera;
    orthographic_view view;
    if (!make_original_orthographic_view(context, width, height, camera_height,
        yaw, pitch, zoom, &camera, &view)) return context->status;
    if (!isfinite(view.half_u) || !isfinite(view.half_v) ||
        !finite_matrix(view.camera_to_surface) || !finite_matrix(view.surface_normal_to_camera) ||
        !finite_vector(view.surface_u) || !finite_vector(view.surface_v) ||
        !finite_vector(view.surface_direction)) return SURFER_INVALID_INPUT;

    const double u_increment = ((camera.uoffset + camera.uscale) -
        (camera.uoffset - camera.uscale)) / (double)(width - 1);
    const double v_increment = ((camera.voffset + camera.vscale) -
        (camera.voffset - camera.vscale)) / (double)(height - 1);
    const double start_fraction_u = quality.pattern == SURFER_AA_OG_1X1 ?
        0.0 : -0.5 / (double)(width - 1);
    const double start_fraction_v = quality.pattern == SURFER_AA_OG_1X1 ?
        0.0 : -0.5 / (double)(height - 1);
    const double u_start = camera.uoffset + camera.uscale * (2.0 * start_fraction_u - 1.0);
    const double v_start = camera.voffset + camera.vscale * (2.0 * start_fraction_v - 1.0);
    if (!isfinite(u_increment) || !isfinite(v_increment) ||
        !isfinite(u_start) || !isfinite(v_start)) return SURFER_INVALID_INPUT;

    if (!original_initialize_pipeline(context, scene->surface, view, pipeline)) return context->status;

    if (quality.pattern == SURFER_AA_OG_1X1) {
        if (!isfinite(u_start + (double)(width - 1) * u_increment) ||
            !isfinite(v_start + (double)(height - 1) * v_increment)) return SURFER_INVALID_INPUT;
        for (size_t y = 0; y < height; ++y) {
            const double v = v_start + (double)y * v_increment;
            for (size_t x = 0; x < width; ++x) {
                const double u = u_start + (double)x * u_increment;
                surfer_color color;
                const surfer_status status = quality_sample(context, scene, view, pipeline, u, v, &color);
                if (status != SURFER_OK) return status;
                argb_pixels[y * width + x] = color_to_argb_validated(color);
            }
        }
        return continue_operation(context) ? SURFER_OK : context->status;
    }

    if (width == SIZE_MAX || height == SIZE_MAX) return SURFER_INVALID_INPUT;
    const size_t corner_width = width + 1;
    const size_t corner_height = height + 1;
    if (corner_width > SIZE_MAX / corner_height ||
        corner_width * corner_height > SIZE_MAX / sizeof(surfer_color) ||
        !isfinite(u_start + (double)width * u_increment) ||
        !isfinite(v_start + (double)height * v_increment)) return SURFER_INVALID_INPUT;
    mark_allocation_path(context, UINT32_C(0x100)); /* AA corner storage. */
    surfer_color *corners = allocate_array(context,
        corner_width * corner_height, sizeof(*corners), false);
    if (corners == NULL) return context->status;
    surfer_status result = SURFER_OK;
    for (size_t y = 0; y < corner_height && result == SURFER_OK; ++y) {
        const double v = v_start + (double)y * v_increment;
        for (size_t x = 0; x < corner_width; ++x) {
            const double u = u_start + (double)x * u_increment;
            result = quality_sample(context, scene, view, pipeline, u, v, &corners[y * corner_width + x]);
            if (result != SURFER_OK) break;
            if (x > 0 && y > 0) {
                const surfer_color upper_left = corners[y * corner_width + x - 1];
                const surfer_color upper_right = corners[y * corner_width + x];
                const surfer_color lower_left = corners[(y - 1) * corner_width + x - 1];
                const surfer_color lower_right = corners[(y - 1) * corner_width + x];
                surfer_color center = {0.0f, 0.0f, 0.0f};
                if (antialias_refines(quality, upper_left, upper_right, lower_left, lower_right)) {
                    mark_allocation_path(context, UINT32_C(0x200)); /* AA center trace. */
                    /* Preserve the original subtract-then-add center coordinates. */
                    const double lower_u = u - u_increment;
                    const double lower_v = v - v_increment;
                    result = quality_sample(context, scene, view, pipeline,
                        lower_u + 0.5 * u_increment, lower_v + 0.5 * v_increment, &center);
                    if (result != SURFER_OK) break;
                }
                const surfer_color color = antialias_color(quality,
                    upper_left, upper_right, lower_left, lower_right, center);
                if (!finite_color(color)) { result = SURFER_INVALID_INPUT; break; }
                argb_pixels[(y - 1) * width + x - 1] = color_to_argb_validated(color);
            }
        }
    }
    free(corners);
    return result == SURFER_OK && !continue_operation(context) ? context->status : result;
}

static surfer_status render_orthographic_quality_request(
    surfer_operation_context *context, const surfer_scene *scene,
    size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, uint32_t *argb_pixels, size_t pixel_capacity)
{
    original_render_pipeline pipeline = {0};
    const surfer_status status = render_orthographic_quality_prepared(context, scene,
        width, height, camera_height, yaw, pitch, zoom, quality, argb_pixels, pixel_capacity, &pipeline);
    original_destroy_pipeline(&pipeline);
    return status;
}

surfer_status surfer_render_orthographic_quality(
    const surfer_scene *scene, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, uint32_t *argb_pixels, size_t pixel_capacity)
{
    surfer_operation_context context = new_operation_context();
    return render_orthographic_quality_request(&context, scene, width, height,
        camera_height, yaw, pitch, zoom, quality, argb_pixels, pixel_capacity);
}

surfer_status surfer_render_orthographic_cancellable(
    const surfer_scene *scene, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, const surfer_cancellation *cancellation,
    uint32_t *argb_pixels, size_t pixel_capacity)
{
    if (cancellation == NULL || cancellation->cancelled == NULL) return SURFER_INVALID_INPUT;
    surfer_operation_context context = new_operation_context();
    context.cancellation = cancellation;
    return render_orthographic_quality_request(&context, scene, width, height,
        camera_height, yaw, pitch, zoom, quality, argb_pixels, pixel_capacity);
}

#ifdef SURFER_TEST_ALLOCATION_FAILURES
surfer_status surfer_test_render_orthographic(
    const surfer_scene *scene, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    uint32_t *argb_pixels, size_t pixel_capacity, surfer_allocation_probe *probe)
{
    surfer_operation_context context = new_operation_context();
    context.probe = probe;
    return render_orthographic_request(&context, scene, width, height, camera_height,
        yaw, pitch, zoom, argb_pixels, pixel_capacity);
}

surfer_status surfer_test_render_orthographic_quality(
    const surfer_scene *scene, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, uint32_t *argb_pixels, size_t pixel_capacity,
    surfer_allocation_probe *probe)
{
    surfer_operation_context context = new_operation_context();
    context.probe = probe;
    return render_orthographic_quality_request(&context, scene, width, height,
        camera_height, yaw, pitch, zoom, quality, argb_pixels, pixel_capacity);
}
#endif
