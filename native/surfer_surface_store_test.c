#include "surfer_surface_store.h"

#include <assert.h>
#include <limits.h>
#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>

static const int32_t offsets[5] = {0, 4, 5, 6, 7};
static const double coefficients[7] = {-0.64, 1.0, 1.0, 1.0, 2.0, 2.0, 2.0};
static const int32_t powers[21] = {
    0,0,0, 0,0,2, 0,2,0, 2,0,0,
    1,0,0, 0,1,0, 0,0,1
};

static surfer_surface_handle sphere(void)
{
    surfer_surface_handle result = 0;
    assert(surfer_surface_create_copied(1, 2, offsets, 5,
        coefficients, 7, powers, 21, &result) == SURFER_OK);
    assert(result > 0);
    return result;
}

static void empty_store(void)
{
    assert(surfer_surface_test_live_snapshots() == 0);
    assert(surfer_surface_test_live_borrows() == 0);
    assert(surfer_surface_test_live_allocations() == 0);
}

static void copy_and_lifetime(void)
{
    double mutable_coefficients[7];
    int32_t mutable_powers[21];
    int32_t mutable_offsets[5];
    memcpy(mutable_coefficients, coefficients, sizeof(coefficients));
    memcpy(mutable_powers, powers, sizeof(powers));
    memcpy(mutable_offsets, offsets, sizeof(offsets));
    surfer_surface_handle handle = 0;
    assert(surfer_surface_create_copied(1, 4096, mutable_offsets, 5,
        mutable_coefficients, 7, mutable_powers, 21, &handle) == SURFER_OK);
    memset(mutable_coefficients, 0, sizeof(mutable_coefficients));
    memset(mutable_powers, 0, sizeof(mutable_powers));
    memset(mutable_offsets, 0, sizeof(mutable_offsets));
    surfer_surface_borrow first = {0, NULL};
    surfer_surface_borrow second = {0, NULL};
    assert(surfer_surface_begin_borrow(handle, &first) == SURFER_OK);
    assert(surfer_surface_begin_borrow(handle, &second) == SURFER_OK);
    assert(first.token != second.token && first.surface == second.surface);
    assert(first.surface->family_degree == 4096);
    assert(first.surface->surface.term_count == 4);
    assert(first.surface->surface.terms[0].coefficient == -0.64);
    assert(first.surface->surface.terms[3].x_exponent == 2);
    assert(first.surface->gradient_x.terms[0].coefficient == 2.0);
    assert(first.surface->gradient_y.terms[0].y_exponent == 1);
    assert(first.surface->gradient_z.terms[0].z_exponent == 1);
    assert(surfer_surface_release(handle) == SURFER_OK);
    surfer_surface_borrow untouched = {-91, NULL};
    assert(surfer_surface_begin_borrow(handle, &untouched) == SURFER_INVALID_INPUT);
    assert(untouched.token == -91 && untouched.surface == NULL);
    assert(surfer_surface_test_live_snapshots() == 1);
    assert(first.surface->gradient_z.terms[0].coefficient == 2.0);
    assert(surfer_surface_end_borrow(first.token) == SURFER_OK);
    assert(surfer_surface_end_borrow(first.token) == SURFER_INVALID_INPUT);
    assert(second.surface->surface.terms[3].coefficient == 1.0);
    assert(surfer_surface_end_borrow(second.token) == SURFER_OK);
    assert(surfer_surface_release(handle) == SURFER_INVALID_INPUT);
    assert(surfer_surface_release(INT64_MAX) == SURFER_INVALID_INPUT);
    assert(surfer_surface_end_borrow(INT64_MAX) == SURFER_INVALID_INPUT);
    assert(surfer_surface_release(0) == SURFER_INVALID_INPUT);
    empty_store();
}

static void invalid_inputs(void)
{
    surfer_surface_handle result = -91;
    int32_t invalid_offsets[5];
    double invalid_coefficients[7];
    int32_t invalid_powers[21];
#define INVALID(VERSION, DEGREE, OFFSETS, OFFSET_COUNT, COEFS, COUNT, XYZ, XYZ_COUNT) \
    do { \
        assert(surfer_surface_create_copied(VERSION, DEGREE, OFFSETS, OFFSET_COUNT, \
            COEFS, COUNT, XYZ, XYZ_COUNT, &result) == SURFER_INVALID_INPUT); \
        assert(result == -91); \
        empty_store(); \
    } while (0)
    INVALID(2, 2, offsets, 5, coefficients, 7, powers, 21);
    INVALID(1, -1, offsets, 5, coefficients, 7, powers, 21);
    INVALID(1, 1, offsets, 5, coefficients, 7, powers, 21);
    INVALID(1, 2, NULL, 5, coefficients, 7, powers, 21);
    INVALID(1, 2, offsets, 4, coefficients, 7, powers, 21);
    INVALID(1, 2, offsets, 5, NULL, 7, powers, 21);
    INVALID(1, 2, offsets, 5, coefficients, 7, NULL, 21);
    INVALID(1, 2, offsets, 5, coefficients, 7, powers, 20);
    INVALID(1, 2, offsets, 5, coefficients, SIZE_MAX, powers, 21);
    memcpy(invalid_offsets, offsets, sizeof(offsets));
    invalid_offsets[0] = 1;
    INVALID(1, 2, invalid_offsets, 5, coefficients, 7, powers, 21);
    invalid_offsets[0] = 0; invalid_offsets[2] = 3;
    INVALID(1, 2, invalid_offsets, 5, coefficients, 7, powers, 21);
    invalid_offsets[2] = 5; invalid_offsets[4] = 8;
    INVALID(1, 2, invalid_offsets, 5, coefficients, 7, powers, 21);
    memcpy(invalid_coefficients, coefficients, sizeof(coefficients));
    invalid_coefficients[5] = INFINITY;
    INVALID(1, 2, offsets, 5, invalid_coefficients, 7, powers, 21);
    invalid_coefficients[5] = NAN;
    INVALID(1, 2, offsets, 5, invalid_coefficients, 7, powers, 21);
    memcpy(invalid_powers, powers, sizeof(powers));
    invalid_powers[19] = -1;
    INVALID(1, 2, offsets, 5, coefficients, 7, invalid_powers, 21);
    invalid_powers[19] = INT32_MAX; invalid_powers[20] = 1;
    INVALID(1, 2, offsets, 5, coefficients, 7, invalid_powers, 21);
    memcpy(invalid_powers, powers, sizeof(powers));
    /* Duplicate monomials and reverse order are independently refused. */
    memcpy(invalid_powers + 3, invalid_powers, 3 * sizeof(int32_t));
    INVALID(1, 2, offsets, 5, coefficients, 7, invalid_powers, 21);
    memcpy(invalid_powers, powers, sizeof(powers));
    invalid_powers[0] = 3;
    INVALID(1, 3, offsets, 5, coefficients, 7, invalid_powers, 21);
    /* Ordering and duplicate rejection apply independently to every range. */
    const double three_coefficients[3] = {1, 2, 3};
    int32_t three_powers[9] = {0,0,0, 2,0,0, 1,0,0};
    for (size_t p = 0; p < 4; ++p) {
        for (size_t i = 0; i < 5; ++i) invalid_offsets[i] = i <= p ? 0 : 3;
        three_powers[6] = 1;
        INVALID(1, 3, invalid_offsets, 5, three_coefficients, 3, three_powers, 9);
        three_powers[6] = 2;
        INVALID(1, 3, invalid_offsets, 5, three_coefficients, 3, three_powers, 9);
    }
    assert(surfer_surface_create_copied(1, 2, offsets, 5,
        coefficients, 7, powers, 21, NULL) == SURFER_INVALID_INPUT);
#undef INVALID
}

static void zero_and_large_exponent(void)
{
    const int32_t zero_offsets[5] = {0,0,0,0,0};
    surfer_surface_handle handle = 0;
    assert(surfer_surface_create_copied(1, 0, zero_offsets, 5,
        NULL, 0, NULL, 0, &handle) == SURFER_OK);
    surfer_surface_borrow borrow;
    assert(surfer_surface_begin_borrow(handle, &borrow) == SURFER_OK);
    assert(borrow.surface->surface.term_count == 0);
    assert(borrow.surface->surface.terms == NULL);
    assert(surfer_surface_end_borrow(borrow.token) == SURFER_OK);
    assert(surfer_surface_release(handle) == SURFER_OK);
    const int32_t one_offsets[5] = {0,1,1,1,1};
    const int32_t xyz[3] = {256,0,0};
    const double value[1] = {-0.0};
    assert(surfer_surface_create_copied(1, 4096, one_offsets, 5,
        value, 1, xyz, 3, &handle) == SURFER_OK);
    assert(surfer_surface_begin_borrow(handle, &borrow) == SURFER_OK);
    assert(signbit(borrow.surface->surface.terms[0].coefficient));
    assert(borrow.surface->surface.terms[0].x_exponent == 256);
    assert(surfer_surface_end_borrow(borrow.token) == SURFER_OK);
    assert(surfer_surface_release(handle) == SURFER_OK);
    /* The receiver validates storage, not derivative semantics: a producer-
     * supplied gradient is not recomputed or bounded by family_degree-1. */
    const int32_t gradient_offsets[5] = {0,0,1,1,1};
    assert(surfer_surface_create_copied(1, 0, gradient_offsets, 5,
        value, 1, xyz, 3, &handle) == SURFER_OK);
    assert(surfer_surface_release(handle) == SURFER_OK);
    empty_store();
}

static void allocation_and_replacement(void)
{
    for (size_t failure = 0; failure < 2; ++failure) {
        surfer_surface_allocation_probe probe = {failure, 0};
        surfer_surface_handle output = -91;
        assert(surfer_surface_test_create_copied(1, 2, offsets, 5,
            coefficients, 7, powers, 21, &output, &probe) == SURFER_OUT_OF_MEMORY);
        assert(output == -91 && probe.attempts == failure + 1);
        empty_store();
    }
    const surfer_surface_handle previous = sphere();
    for (size_t failure = 0; failure < 2; ++failure) {
        surfer_surface_allocation_probe probe = {failure, 0};
        surfer_surface_handle output = -91;
        assert(surfer_surface_test_replace_copied(previous, 1, 2, offsets, 5,
            coefficients, 7, powers, 21, &output, &probe) == SURFER_OUT_OF_MEMORY);
        assert(output == -91 && surfer_surface_test_live_snapshots() == 1);
        assert(surfer_surface_test_live_allocations() == 2);
    }
    surfer_surface_borrow old;
    surfer_surface_allocation_probe borrow_failure = {0, 0};
    assert(surfer_surface_test_begin_borrow(previous, &old, &borrow_failure) == SURFER_OUT_OF_MEMORY);
    assert(surfer_surface_test_live_borrows() == 0);
    assert(surfer_surface_begin_borrow(previous, &old) == SURFER_OK);
    surfer_surface_handle replacement = -91;
    assert(surfer_surface_replace_copied(previous, 2, 2, offsets, 5,
        coefficients, 7, powers, 21, &replacement) == SURFER_INVALID_INPUT);
    assert(replacement == -91);
    assert(surfer_surface_replace_copied(previous, 1, 4096, offsets, 5,
        coefficients, 7, powers, 21, &replacement) == SURFER_OK);
    assert(replacement > previous);
    surfer_surface_borrow current;
    assert(surfer_surface_begin_borrow(previous, &current) == SURFER_INVALID_INPUT);
    assert(old.surface->family_degree == 2);
    assert(surfer_surface_begin_borrow(replacement, &current) == SURFER_OK);
    assert(current.surface->family_degree == 4096);
    assert(surfer_surface_end_borrow(old.token) == SURFER_OK);
    assert(surfer_surface_end_borrow(current.token) == SURFER_OK);
    assert(surfer_surface_release(replacement) == SURFER_OK);
    assert(surfer_surface_replace_copied(previous, 1, 2, offsets, 5,
        coefficients, 7, powers, 21, &replacement) == SURFER_INVALID_INPUT);
    empty_store();
}

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t changed;
    bool acquired;
    bool released;
    surfer_surface_handle handle;
} worker_state;

static void *render_worker(void *argument)
{
    worker_state *state = argument;
    surfer_surface_borrow borrow;
    assert(surfer_surface_begin_borrow(state->handle, &borrow) == SURFER_OK);
    assert(pthread_mutex_lock(&state->mutex) == 0);
    state->acquired = true;
    assert(pthread_cond_signal(&state->changed) == 0);
    while (!state->released) assert(pthread_cond_wait(&state->changed, &state->mutex) == 0);
    assert(pthread_mutex_unlock(&state->mutex) == 0);
    /* The public handle has been retired. The actual renderer still reads the
     * immutable snapshot retained by this worker's borrow. */
    surfer_scene scene = surfer_default_scene(borrow.surface);
    uint32_t pixels[9];
    assert(surfer_render_orthographic(&scene, 3, 3, 2.15, 0, 0, 1, pixels, 9) == SURFER_OK);
    assert(pixels[4] != pixels[0]);
    assert(surfer_surface_end_borrow(borrow.token) == SURFER_OK);
    return NULL;
}

static void concurrent_render_lifetime(void)
{
    worker_state state = {PTHREAD_MUTEX_INITIALIZER, PTHREAD_COND_INITIALIZER,
        false, false, sphere()};
    pthread_t thread;
    assert(pthread_create(&thread, NULL, render_worker, &state) == 0);
    assert(pthread_mutex_lock(&state.mutex) == 0);
    while (!state.acquired) assert(pthread_cond_wait(&state.changed, &state.mutex) == 0);
    assert(surfer_surface_release(state.handle) == SURFER_OK);
    state.released = true;
    assert(pthread_cond_signal(&state.changed) == 0);
    assert(pthread_mutex_unlock(&state.mutex) == 0);
    assert(pthread_join(thread, NULL) == 0);
    assert(pthread_cond_destroy(&state.changed) == 0);
    assert(pthread_mutex_destroy(&state.mutex) == 0);
    empty_store();
}

int main(void)
{
    empty_store();
    invalid_inputs();
    copy_and_lifetime();
    zero_and_large_exponent();
    allocation_and_replacement();
    concurrent_render_lifetime();
    const surfer_surface_handle handle = sphere();
    surfer_scene scene = surfer_default_scene(NULL);
    uint32_t pixels[9];
    assert(surfer_surface_render_orthographic(handle, &scene, 3, 3,
        2.15, 0, 0, 1, pixels, 9) == SURFER_OK);
    assert(surfer_surface_release(handle) == SURFER_OK);
    assert(surfer_surface_render_orthographic(handle, &scene, 3, 3,
        2.15, 0, 0, 1, pixels, 9) == SURFER_INVALID_INPUT);
    empty_store();
    puts("PASS copied PreparedSurface ownership and render borrowing");
    return 0;
}
