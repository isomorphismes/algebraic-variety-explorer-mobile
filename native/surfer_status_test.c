/* Include the exact maintained implementation to exercise private checked-size
 * boundaries without exporting an application allocator/test API for them.
 * The production renderer is also compiled and tested as its own translation
 * unit by surfer_raytracer_test.c. No replacement implementation exists here.
 */
#define SURFER_TEST_ALLOCATION_FAILURES
#include "surfer_raytracer.c"

#include <stdio.h>
#include <float.h>

static void require_status(surfer_status actual, surfer_status expected, const char *reason)
{
    if (actual != expected) {
        fprintf(stderr, "FAIL %s: %s; expected %s\n", reason,
            surfer_status_name(actual), surfer_status_name(expected));
        exit(1);
    }
}

static void require_condition(bool condition, const char *reason)
{
    if (!condition) {
        fprintf(stderr, "FAIL %s\n", reason);
        exit(1);
    }
}

static const surfer_term test_sphere_terms[] = {
    {1.0, 2, 0, 0}, {1.0, 0, 2, 0}, {1.0, 0, 0, 2}, {-0.64, 0, 0, 0}
};
static const surfer_term test_dx[] = {{2.0, 1, 0, 0}};
static const surfer_term test_dy[] = {{2.0, 0, 1, 0}};
static const surfer_term test_dz[] = {{2.0, 0, 0, 1}};
static const surfer_prepared_surface test_sphere = {
    2, {test_sphere_terms, 4}, {test_dx, 1}, {test_dy, 1}, {test_dz, 1}
};
static const surfer_ray test_center = {{0.0, 0.0, 0.0}, {0.0, 0.0, -1.0}};

static void invalid_frame_preserves_output(surfer_scene scene, const char *reason)
{
    uint32_t pixels[25];
    for (size_t i = 0; i < 25; ++i) pixels[i] = UINT32_C(0x12345678);
    require_status(surfer_render_orthographic(&scene, 5, 5, 2.15, 0.0, 0.0,
        1.0, pixels, 25), SURFER_INVALID_INPUT, reason);
    for (size_t i = 0; i < 25; ++i) {
        require_condition(pixels[i] == UINT32_C(0x12345678), "invalid frame wrote output");
    }
}

static void test_prepared_validation(void)
{
    surfer_prepared_surface malformed = test_sphere;
    surfer_scene scene = surfer_default_scene(&malformed);
    malformed.surface = (surfer_sparse_polynomial){NULL, 1};
    invalid_frame_preserves_output(scene, "missing surface storage");
    malformed = test_sphere;
    malformed.gradient_x = (surfer_sparse_polynomial){NULL, 1};
    invalid_frame_preserves_output(scene, "missing x derivative storage");
    malformed = test_sphere;
    malformed.gradient_y = (surfer_sparse_polynomial){NULL, 1};
    invalid_frame_preserves_output(scene, "missing y derivative storage");
    malformed = test_sphere;
    malformed.gradient_z = (surfer_sparse_polynomial){NULL, 1};
    invalid_frame_preserves_output(scene, "missing z derivative storage");

    surfer_term invalid = {NAN, 0, 0, 0};
    malformed = test_sphere;
    malformed.surface = (surfer_sparse_polynomial){&invalid, 1};
    invalid_frame_preserves_output(scene, "nonfinite surface coefficient");
    malformed = test_sphere;
    malformed.gradient_x = (surfer_sparse_polynomial){&invalid, 1};
    invalid_frame_preserves_output(scene, "nonfinite x derivative coefficient");
    malformed = test_sphere;
    malformed.gradient_y = (surfer_sparse_polynomial){&invalid, 1};
    invalid_frame_preserves_output(scene, "nonfinite y derivative coefficient");
    malformed = test_sphere;
    malformed.gradient_z = (surfer_sparse_polynomial){&invalid, 1};
    invalid_frame_preserves_output(scene, "nonfinite z derivative coefficient");
    invalid = (surfer_term){1.0, -1, 0, 0};
    invalid_frame_preserves_output(scene, "negative derivative exponent");
    malformed = test_sphere;
    malformed.surface = (surfer_sparse_polynomial){&invalid, 1};
    invalid_frame_preserves_output(scene, "negative surface exponent");
    malformed = test_sphere;
    malformed.gradient_y.term_count = SIZE_MAX;
    invalid_frame_preserves_output(scene, "derivative pointer-count byte overflow");
    malformed = test_sphere;
    malformed.family_degree = 1;
    invalid_frame_preserves_output(scene, "family degree below surface degree");
    malformed = test_sphere;
    malformed.family_degree = -1;
    invalid_frame_preserves_output(scene, "negative family degree");
}

static void test_scene_and_request_validation(void)
{
    surfer_scene scene = surfer_default_scene(&test_sphere);
    scene.light_count = SURFER_MAX_LIGHTS + 1;
    invalid_frame_preserves_output(scene, "excessive light count");
    scene = surfer_default_scene(&test_sphere);
    scene.background.red = NAN;
    invalid_frame_preserves_output(scene, "nonfinite background");
    scene = surfer_default_scene(&test_sphere);
    scene.front_material.shininess = INFINITY;
    invalid_frame_preserves_output(scene, "nonfinite material");
    scene = surfer_default_scene(&test_sphere);
    scene.lights[0].position.z = NAN;
    invalid_frame_preserves_output(scene, "nonfinite light position");
    scene = surfer_default_scene(&test_sphere);
    scene.lights[0].color.blue = INFINITY;
    invalid_frame_preserves_output(scene, "nonfinite light color");
    scene = surfer_default_scene(&test_sphere);
    scene.lights[0].intensity = NAN;
    invalid_frame_preserves_output(scene, "nonfinite light intensity");

    scene = surfer_default_scene(&test_sphere);
    uint32_t pixel = UINT32_C(0x12345678);
    require_status(surfer_render_orthographic(&scene, SIZE_MAX, 2, 2.15, 0, 0, 1,
        &pixel, SIZE_MAX), SURFER_INVALID_INPUT, "dimension multiplication overflow");
    require_status(surfer_render_orthographic(&scene, 2, 2, 2.15, 0, 0, 1,
        &pixel, 1), SURFER_INVALID_INPUT, "insufficient output capacity");
    require_status(surfer_render_orthographic(&scene, 2, 2, 2.15, NAN, 0, 1,
        &pixel, 4), SURFER_INVALID_INPUT, "nonfinite yaw");
    require_status(surfer_render_orthographic(&scene, 2, 2, 2.15, 0, INFINITY, 1,
        &pixel, 4), SURFER_INVALID_INPUT, "nonfinite pitch");
    require_status(surfer_render_orthographic(&scene, 2, 2, INFINITY, 0, 0, 1,
        &pixel, 4), SURFER_INVALID_INPUT, "nonfinite camera height");
    require_status(surfer_render_orthographic(&scene, 2, 2, 2.15, 0, 0, 0,
        &pixel, 4), SURFER_INVALID_INPUT, "nonpositive zoom");
    require_status(surfer_render_orthographic(&scene, 2, 2, 2.15, 0, 0, NAN,
        &pixel, 4), SURFER_INVALID_INPUT, "nonfinite zoom");
    require_status(surfer_render_orthographic(&scene, 2, 2, 0, 0, 0, 1,
        &pixel, 4), SURFER_INVALID_INPUT, "nonpositive camera height");
    require_condition(pixel == UINT32_C(0x12345678), "invalid request wrote pixels");

    double root = 99;
    surfer_ray invalid_ray = test_center;
    invalid_ray.origin.x = NAN;
    require_status(surfer_first_surface_root(&test_sphere, invalid_ray, -1, 1, &root),
        SURFER_INVALID_INPUT, "nonfinite ray");
    require_status(surfer_first_surface_root(&test_sphere, test_center, NAN, 1, &root),
        SURFER_INVALID_INPUT, "nonfinite interval");
    require_status(surfer_first_surface_root(&test_sphere, test_center, 1, -1, &root),
        SURFER_INVALID_INPUT, "reversed interval");
    require_condition(root == 99, "invalid root request overwrote output");
    uint32_t argb = UINT32_C(0x12345678);
    require_status(surfer_color_to_argb((surfer_color){NAN, 0, 0}, &argb),
        SURFER_INVALID_INPUT, "nonfinite color conversion");
    require_condition(argb == UINT32_C(0x12345678), "invalid conversion wrote output");
}

static void test_clip_trace_and_blank_success(void)
{
    surfer_interval interval = {12, 34};
    const surfer_ray miss = {{2.0, 0.0, 0.0}, {0.0, 0.0, -1.0}};
    require_status(surfer_clip_unit_sphere(miss, &interval), SURFER_MISS, "valid sphere clip miss");
    require_condition(interval.lower == 12 && interval.upper == 34, "clip miss wrote interval");
    const surfer_ray stationary = {{0, 0, 0}, {0, 0, 0}};
    require_status(surfer_clip_unit_sphere(stationary, &interval), SURFER_INVALID_INPUT,
        "stationary clip ray is invalid");

    const surfer_mat3 identity = {1, 0, 0, 0, 1, 0, 0, 0, 1};
    surfer_ray_bundle rays = {test_center, test_center, test_center, -1, identity};
    surfer_prepared_surface zero_gradient = test_sphere;
    zero_gradient.gradient_x = (surfer_sparse_polynomial){NULL, 0};
    zero_gradient.gradient_y = (surfer_sparse_polynomial){NULL, 0};
    zero_gradient.gradient_z = (surfer_sparse_polynomial){NULL, 0};
    surfer_scene scene = surfer_default_scene(&zero_gradient);
    require_status(surfer_trace_prepared_ray(&scene, rays).status, SURFER_OK, "zero gradient is valid");
    rays.surface_normal_to_camera.m10 = NAN;
    require_status(surfer_trace_prepared_ray(&scene, rays).status, SURFER_INVALID_INPUT,
        "nonfinite normal transform");

    const surfer_term constant_one = {1.0, 0, 0, 0};
    const surfer_prepared_surface empty = {0, {NULL, 0}, {NULL, 0}, {NULL, 0}, {NULL, 0}};
    surfer_prepared_surface blank = empty;
    blank.surface = (surfer_sparse_polynomial){&constant_one, 1};
    scene = surfer_default_scene(&blank);
    uint32_t pixels[25];
    require_status(surfer_render_orthographic(&scene, 5, 5, 2.15, 0, 0, 1, pixels, 25),
        SURFER_OK, "valid all-background frame");
    uint32_t background = 0;
    require_status(surfer_color_to_argb(scene.background, &background), SURFER_OK, "background conversion");
    for (size_t i = 0; i < 25; ++i) require_condition(pixels[i] == background, "blank frame differs from background");
    double root = 99;
    require_status(surfer_first_surface_root(&empty, test_center, -1, 1, &root), SURFER_MISS,
        "zero-count surface is valid");
    require_condition(root == 99, "valid root miss wrote output");

    const surfer_term linear_terms[] = {{1.0, 0, 0, 1}, {-0.25, 0, 0, 0}};
    surfer_prepared_surface specialized = {4, {linear_terms, 2}, {NULL, 0}, {NULL, 0}, {NULL, 0}};
    require_status(surfer_first_surface_root(&specialized, test_center, -1, 1, &root),
        SURFER_OK, "larger family degree after specialization is valid");
    require_condition(isfinite(root) && fabs(root + 0.25) <= SURFER_ROOT_EPSILON,
        "specialized linear root");
}

static void require_zero_surface_behavior(
    const surfer_prepared_surface *surface, const char *reason)
{
    require_status(surfer_validate_prepared_surface(surface), SURFER_OK, reason);
    double root = 99;
    require_status(surfer_first_surface_root(surface, test_center, -1, 1, &root),
        SURFER_MISS, reason);
    require_condition(root == 99, "zero surface miss wrote root output");

    const surfer_scene scene = surfer_default_scene(surface);
    uint32_t pixels[25];
    require_status(surfer_render_orthographic(&scene, 5, 5, 2.15, 0, 0, 1, pixels, 25),
        SURFER_OK, reason);
    uint32_t background = 0;
    require_status(surfer_color_to_argb(scene.background, &background), SURFER_OK,
        "zero surface background conversion");
    for (size_t i = 0; i < 25; ++i) {
        require_condition(pixels[i] == background, "zero surface frame is not all background");
    }

    surfer_allocation_probe baseline = {SIZE_MAX, 0, 0};
    require_status(surfer_test_first_surface_root(surface, test_center, -1, 1, &root, &baseline),
        SURFER_MISS, "zero surface allocation baseline is a valid miss");
    require_condition(baseline.attempts != 0, "zero surface allocation baseline did not execute");
    for (size_t fail_at = 0; fail_at < baseline.attempts; ++fail_at) {
        surfer_allocation_probe failure = {fail_at, 0, 0};
        root = 99;
        require_status(surfer_test_first_surface_root(surface, test_center, -1, 1, &root, &failure),
            SURFER_OUT_OF_MEMORY, "zero surface allocation failure is not a geometric miss");
        require_condition(root == 99, "failed zero surface preparation wrote root output");
        require_condition(failure.attempts == fail_at + 1, "zero surface allocation fault was not reached");
    }
    surfer_allocation_probe frame_failure = {0, 0, 0};
    require_status(surfer_test_render_orthographic(&scene, 5, 5, 2.15, 0, 0, 1,
        pixels, 25, &frame_failure), SURFER_OUT_OF_MEMORY,
        "zero surface frame allocation failure is not blank success");
    printf("zero_surface\t%s\troot_allocation_attempts=%zu\n", reason, baseline.attempts);
}

static void test_zero_surface_contract(void)
{
    const surfer_prepared_surface empty = {0, {NULL, 0}, {NULL, 0}, {NULL, 0}, {NULL, 0}};
    require_zero_surface_behavior(&empty, "zero-count surface");
    const surfer_term retained_zero_terms[] = {
        {0.0, 2, 0, 0}, {0.0, 0, 1, 0}, {-0.0, 0, 0, 0}
    };
    const surfer_prepared_surface retained_zero = {2, {retained_zero_terms, 3},
        {NULL, 0}, {NULL, 0}, {NULL, 0}};
    require_zero_surface_behavior(&retained_zero, "retained all-zero terms with family degree two");
    const surfer_term cancelled_terms[] = {{1.0, 2, 0, 0}, {-1.0, 2, 0, 0}};
    const surfer_prepared_surface cancelled = {2, {cancelled_terms, 2},
        {NULL, 0}, {NULL, 0}, {NULL, 0}};
    require_zero_surface_behavior(&cancelled, "cancelled degree-two surface");

    surfer_operation_context context = new_operation_context();
    surfer_allocation_probe probe = {0, 0, 0};
    context.probe = &probe;
    const univariate_polynomial no_coefficients = {NULL, 0};
    const double absent = first_root_for_surface_family(&context, &retained_zero,
        &no_coefficients, -1, 1);
    require_condition(isnan(absent) && context.status == SURFER_OK && probe.attempts == 0,
        "successful empty prepared polynomial is a miss without allocation");
}

static void test_checked_size_boundaries(void)
{
    surfer_operation_context context = new_operation_context();
    surfer_allocation_probe probe = {SIZE_MAX, 0, 0};
    context.probe = &probe;
    require_condition(allocate_array(&context, SIZE_MAX, 2, false) == NULL,
        "allocation size overflow refused");
    require_status(context.status, SURFER_INVALID_INPUT, "allocation size status");
    require_condition(probe.attempts == 0, "overflow reached allocator");
    context = new_operation_context();
    double one = 1;
    const univariate_polynomial huge = {&one, SIZE_MAX};
    const univariate_polynomial two = {&one, 2};
    univariate_polynomial product = multiply_univariate_polynomials(&context, &huge, &two);
    require_condition(product.coefficients == NULL, "polynomial length overflow refused");
    require_status(context.status, SURFER_INVALID_INPUT, "polynomial length overflow status");
    context = new_operation_context();
    descartes_candidate_stack stack = {NULL, SIZE_MAX, SIZE_MAX};
    const descartes_interval no_storage = {NULL, 0, false, 0, 1};
    require_condition(!push_descartes_candidate(&context, &stack, no_storage), "candidate stack growth overflow refused");
    require_status(context.status, SURFER_INVALID_INPUT, "candidate stack overflow status");

    if (SIZE_MAX / sizeof(double) > INT32_MAX) {
        const surfer_term maximum_exponent = {1.0, INT32_MAX, 0, 0};
        const surfer_prepared_surface high_degree = {INT32_MAX, {&maximum_exponent, 1},
            {NULL, 0}, {NULL, 0}, {NULL, 0}};
        probe = (surfer_allocation_probe){0, 0, 0};
        double root = 99;
        require_status(surfer_test_first_surface_root(&high_degree, test_center, -1, 1, &root, &probe),
            SURFER_OUT_OF_MEMORY, "representable high degree has no arbitrary ceiling");
        require_condition(probe.attempts == 1 && root == 99, "high-degree allocation control");
    }
}

static void test_finite_input_overflow_is_not_a_miss(void)
{
    const surfer_term cancellation[] = {
        {1.0, 2, 0, 0}, {-1.0, 2, 0, 0}, {1.0, 0, 0, 1}
    };
    const surfer_prepared_surface surface = {2, {cancellation, 3},
        {NULL, 0}, {NULL, 0}, {NULL, 0}};
    const surfer_ray ray = {{DBL_MAX, 0, 0}, {0, 0, -1}};
    double root = 99;
    require_status(surfer_first_surface_root(&surface, ray, -1, 1, &root),
        SURFER_INVALID_INPUT, "nonrepresentable coefficient expansion is not a geometric miss");
    require_condition(root == 99, "numerically invalid root wrote output");
}

static uint32_t fail_each_root_allocation(
    const surfer_prepared_surface *surface, double expected, const char *reason)
{
    surfer_allocation_probe baseline = {SIZE_MAX, 0, 0};
    double root = 99;
    require_status(surfer_test_first_surface_root(surface, test_center, -1, 1, &root, &baseline),
        SURFER_OK, reason);
    require_condition(isfinite(root) && fabs(root - expected) <= SURFER_ROOT_EPSILON,
        "allocation baseline root");
    require_condition(baseline.attempts != 0, "allocation baseline was not executed");
    for (size_t fail_at = 0; fail_at < baseline.attempts; ++fail_at) {
        surfer_allocation_probe failure = {fail_at, 0, 0};
        root = 99;
        require_status(surfer_test_first_surface_root(surface, test_center, -1, 1, &root, &failure),
            SURFER_OUT_OF_MEMORY, "injected root allocation failure");
        require_condition(failure.attempts == fail_at + 1, "injected allocation was not reached exactly");
        require_condition(root == 99, "incomplete search returned a saved candidate");
    }
    printf("allocation_root\t%s\tattempts=%zu\tpaths=%u\n", reason, baseline.attempts, baseline.paths);
    return baseline.paths;
}

static void test_every_allocation_and_frame_propagation(void)
{
    uint32_t paths = fail_each_root_allocation(&test_sphere, -0.8, "sphere");
    const surfer_term tangent_terms[] = {{1.0, 0, 0, 2}};
    const surfer_prepared_surface tangent = {2, {tangent_terms, 1}, {NULL, 0}, {NULL, 0}, {NULL, 0}};
    paths |= fail_each_root_allocation(&tangent, 0.0, "zero-root-deflation");
    const surfer_term repeated_terms[] = {
        {1.0, 0, 0, 5}, {-0.3125, 0, 0, 3}, {0.015625, 0, 0, 1}
    };
    const surfer_prepared_surface repeated = {5, {repeated_terms, 3}, {NULL, 0}, {NULL, 0}, {NULL, 0}};
    paths |= fail_each_root_allocation(&repeated, -0.5, "multiple-roots-and-saved-zero");
    require_condition(paths == UINT32_C(127), "not every allocation/copy/transform/stack path executed");

    const surfer_scene scene = surfer_default_scene(&test_sphere);
    uint32_t pixels[9];
    surfer_allocation_probe baseline = {SIZE_MAX, 0, 0};
    require_status(surfer_test_render_orthographic(&scene, 3, 3, 2.15, 0, 0, 1,
        pixels, 9, &baseline), SURFER_OK, "frame allocation baseline");
    require_condition(baseline.attempts != 0, "frame allocation path did not execute");
    for (size_t fail_at = 0; fail_at < baseline.attempts; ++fail_at) {
        surfer_allocation_probe failure = {fail_at, 0, 0};
        require_status(surfer_test_render_orthographic(&scene, 3, 3, 2.15, 0, 0, 1,
            pixels, 9, &failure), SURFER_OUT_OF_MEMORY, "injected frame failure is not blank success");
    }
    printf("allocation_frame\tattempts=%zu\n", baseline.attempts);
}

int main(void)
{
    test_prepared_validation();
    test_scene_and_request_validation();
    test_clip_trace_and_blank_success();
    test_zero_surface_contract();
    test_checked_size_boundaries();
    test_finite_input_overflow_is_not_a_miss();
    test_every_allocation_and_frame_propagation();
    puts("SURFER native status, validation and allocation propagation: PASS");
    return 0;
}
