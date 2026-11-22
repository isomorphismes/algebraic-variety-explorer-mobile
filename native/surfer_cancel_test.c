/* Exercise the actual numerical loops, without a replacement solver/oracle. */
#define SURFER_TEST_ALLOCATION_FAILURES
#include "surfer_raytracer.c"

#include <stdio.h>

static void fail(const char *message)
{
    fprintf(stderr, "FAIL cooperative numerical cancellation: %s\n", message);
    exit(1);
}

typedef struct {
    size_t checks;
    size_t cancel_at;
} cancellation_counter;

static bool cancel_at_check(void *state)
{
    cancellation_counter *counter = state;
    const size_t check = counter->checks++;
    return check >= counter->cancel_at;
}

static surfer_operation_context controlled_context(
    surfer_cancellation *cancellation, cancellation_counter *counter,
    size_t cancel_at)
{
    *counter = (cancellation_counter){0, cancel_at};
    *cancellation = (surfer_cancellation){cancel_at_check, counter};
    surfer_operation_context result = new_operation_context();
    result.cancellation = cancellation;
    return result;
}

static void numerical_loops(void)
{
    double coefficients[6] = {-0.2, 0, 1, 0, 0, 0};
    univariate_polynomial quadratic = {coefficients, 3};
    surfer_cancellation cancellation;
    cancellation_counter counter;
    surfer_operation_context context = controlled_context(&cancellation, &counter, 3);
    double root = bisect_root_interval(&context, &quadratic, 0, 1, -0.2, 0.8);
    if (!isnan(root) || context.status != SURFER_CANCELLED || counter.checks != 4)
        fail("bisection cancellation");

    context = controlled_context(&cancellation, &counter, SIZE_MAX);
    root = bisect_root_interval(&context, &quadratic, 0, 1, -0.2, 0.8);
    if (!isfinite(root) || context.status != SURFER_OK || counter.checks < 20)
        fail("uncancelled bisection");

    context = controlled_context(&cancellation, &counter, 1);
    if (!isnan(evaluate_univariate_polynomial_at(&context, &quadratic, 0.5)) ||
        context.status != SURFER_CANCELLED || counter.checks != 2)
        fail("Horner cancellation");

    context = controlled_context(&cancellation, &counter, 4);
    double *shifted = shift_univariate_polynomial_by_one(&context, coefficients, 6);
    if (shifted != NULL || context.status != SURFER_CANCELLED || counter.checks != 5)
        fail("coefficient shift cancellation");

    context = controlled_context(&cancellation, &counter, 9);
    if (descartes_sign_changes_after_reverse_shift_by_one(&context, coefficients, 6) != -1 ||
        context.status != SURFER_CANCELLED || counter.checks != 10)
        fail("Descartes transform cancellation");

    context = controlled_context(&cancellation, &counter, 5);
    univariate_polynomial axis = empty_univariate_polynomial();
    if (polynomial_for_axis_power_along_ray(&context, 0.25, 0.5, 30, &axis) ||
        axis.coefficients != NULL || context.status != SURFER_CANCELLED || counter.checks != 6)
        fail("axis expansion cancellation");

    context = controlled_context(&cancellation, &counter, 5);
    univariate_polynomial product = multiply_univariate_polynomials(
        &context, &quadratic, &quadratic);
    if (product.coefficients != NULL || context.status != SURFER_CANCELLED || counter.checks != 6)
        fail("polynomial product cancellation");

    const surfer_term terms[3] = {{1, 0, 0, 0}, {2, 0, 1, 0}, {3, 1, 0, 0}};
    context = controlled_context(&cancellation, &counter, 1);
    if (!isnan(evaluate_sparse_polynomial_at_point(&context,
            (surfer_sparse_polynomial){terms, 3}, (surfer_vec3){1, 1, 1})) ||
        context.status != SURFER_CANCELLED || counter.checks != 2)
        fail("gradient cancellation");

    context = controlled_context(&cancellation, &counter, 0);
    context.status = SURFER_OUT_OF_MEMORY;
    if (continue_operation(&context) || context.status != SURFER_OUT_OF_MEMORY || counter.checks != 0)
        fail("cancellation replaced earlier failure");
}

static void frames(void)
{
    const surfer_term surface_terms[4] = {
        {-0.64, 0, 0, 0}, {1, 0, 0, 2}, {1, 0, 2, 0}, {1, 2, 0, 0}
    };
    const surfer_term dx = {2, 1, 0, 0};
    const surfer_term dy = {2, 0, 1, 0};
    const surfer_term dz = {2, 0, 0, 1};
    const surfer_prepared_surface surface = {
        2, {surface_terms, 4}, {&dx, 1}, {&dy, 1}, {&dz, 1}
    };
    const surfer_scene scene = surfer_default_scene(&surface);
    uint32_t reference[35], controlled[35];
    surfer_cancellation cancellation;
    cancellation_counter counter;
    for (int mode = 0; mode < 2; ++mode) {
        const surfer_render_quality quality = {(surfer_antialiasing_pattern)mode, 0.3f};
        if (surfer_render_orthographic_quality(&scene, 7, 5, 2.15, 0.23, -0.17, 1.1,
                quality, reference, 35) != SURFER_OK) fail("quality reference");
        counter = (cancellation_counter){0, SIZE_MAX};
        cancellation = (surfer_cancellation){cancel_at_check, &counter};
        if (surfer_render_orthographic_cancellable(&scene, 7, 5, 2.15, 0.23, -0.17, 1.1,
                quality, &cancellation, controlled, 35) != SURFER_OK ||
            memcmp(reference, controlled, sizeof(reference)) != 0 || counter.checks < 100)
            fail("completed quality bytes changed");
        const size_t completed_checks = counter.checks;
        const size_t checks[] = {0, 1, 10, 50, completed_checks / 2, completed_checks - 1};
        for (size_t i = 0; i < sizeof(checks) / sizeof(checks[0]); ++i) {
            for (size_t j = 0; j < 35; ++j) controlled[j] = UINT32_C(0x12345678);
            counter = (cancellation_counter){0, checks[i]};
            if (surfer_render_orthographic_cancellable(&scene, 7, 5, 2.15, 0.23, -0.17, 1.1,
                    quality, &cancellation, controlled, 35) != SURFER_CANCELLED ||
                counter.checks != checks[i] + 1)
                fail("selected frame checkpoint");
            if (checks[i] == 0) {
                for (size_t j = 0; j < 35; ++j)
                    if (controlled[j] != UINT32_C(0x12345678)) fail("pre-cancelled frame wrote output");
            }
        }
        printf("cooperative quality %d completed checks: %zu\n", mode, completed_checks);
    }
    const surfer_render_quality quality = {SURFER_AA_QUINCUNX, 0.3f};
    counter = (cancellation_counter){0, SIZE_MAX};
    cancellation = (surfer_cancellation){cancel_at_check, &counter};
    surfer_operation_context context = new_operation_context();
    context.cancellation = &cancellation;
    surfer_allocation_probe allocations = {0, 0, 0};
    context.probe = &allocations;
    if (render_orthographic_quality_request(&context, &scene, 7, 5, 2.15, 0, 0, 1,
            quality, controlled, 35) != SURFER_OUT_OF_MEMORY || allocations.attempts != 1)
        fail("allocation failure became cancellation");
    const surfer_cancellation malformed = {NULL, NULL};
    if (surfer_render_orthographic_cancellable(&scene, 7, 5, 2.15, 0, 0, 1,
            quality, &malformed, controlled, 35) != SURFER_INVALID_INPUT ||
        surfer_render_orthographic_cancellable(&scene, 7, 5, 2.15, 0, 0, 1,
            quality, NULL, controlled, 35) != SURFER_INVALID_INPUT)
        fail("missing predicate admitted");
}

int main(void)
{
    numerical_loops();
    frames();
    puts("SURFER cooperative numerical cancellation: PASS");
    return 0;
}
