/* Test-only observation and forwarding. The production JNI entrypoints do all
 * copying/validation; the production store owns every snapshot and borrow. */
#include "../../../native/android/prepared_surface_jni.h"
#include "../../../native/surfer_surface_store.h"

#include <stdint.h>
#include <string.h>

JNIEXPORT jlong JNICALL Java_CopiedSurfaceObserver_copy(
    JNIEnv *environment, jclass owner,
    jint version, jint degree, jint a, jint b, jint c, jint d, jint e,
    jdoubleArray coefficients, jintArray xyz)
{
    return Java_Idric_Generated_copyPreparedSurface(environment, owner,
        version, degree, a, b, c, d, e, coefficients, xyz);
}

JNIEXPORT jlong JNICALL Java_CopiedSurfaceObserver_replace(
    JNIEnv *environment, jclass owner, jlong previous,
    jint version, jint degree, jint a, jint b, jint c, jint d, jint e,
    jdoubleArray coefficients, jintArray xyz)
{
    return Java_Idric_Generated_replacePreparedSurface(environment, owner, previous,
        version, degree, a, b, c, d, e, coefficients, xyz);
}

JNIEXPORT jint JNICALL Java_CopiedSurfaceObserver_release(
    JNIEnv *environment, jclass owner, jlong handle)
{
    return Java_Idric_Generated_releasePreparedSurface(environment, owner, handle);
}

static const surfer_sparse_polynomial *polynomial(
    const surfer_prepared_surface *surface, jint index)
{
    switch (index) {
        case 0: return &surface->surface;
        case 1: return &surface->gradient_x;
        case 2: return &surface->gradient_y;
        case 3: return &surface->gradient_z;
        default: return NULL;
    }
}

/* field0: family, 1:count, 2:coefficient bits, 3/4/5:x/y/z. Error uses a
 * separate status observation (field6), so no coefficient bits are normalized. */
JNIEXPORT jlong JNICALL Java_CopiedSurfaceObserver_observe(
    JNIEnv *environment, jclass owner, jlong handle, jint p, jint index, jint field)
{
    (void)environment; (void)owner;
    surfer_surface_borrow borrow;
    const surfer_status status = surfer_surface_begin_borrow(handle, &borrow);
    if (field == 6) {
        if (status == SURFER_OK) (void)surfer_surface_end_borrow(borrow.token);
        return status;
    }
    if (status != SURFER_OK) return -status;
    jlong result = -SURFER_INVALID_INPUT;
    const surfer_sparse_polynomial *source = polynomial(borrow.surface, p);
    if (field == 0) result = borrow.surface->family_degree;
    else if (source != NULL) {
        if (field == 1) result = (jlong)source->term_count;
        else if (index >= 0 && (size_t)index < source->term_count) {
            const surfer_term term = source->terms[index];
            if (field == 2) memcpy(&result, &term.coefficient, sizeof(result));
            else if (field == 3) result = term.x_exponent;
            else if (field == 4) result = term.y_exponent;
            else if (field == 5) result = term.z_exponent;
        }
    }
    (void)surfer_surface_end_borrow(borrow.token);
    return result;
}

JNIEXPORT jint JNICALL Java_CopiedSurfaceObserver_failAllocation(
    JNIEnv *environment, jclass owner, jint index)
{
    (void)environment; (void)owner;
    return surfer_surface_jni_test_reset_allocator(index < 0 ? SIZE_MAX : (size_t)index);
}

JNIEXPORT jint JNICALL Java_CopiedSurfaceObserver_allocationAttempts(JNIEnv *environment, jclass owner)
{
    (void)environment; (void)owner;
    return (jint)surfer_surface_jni_test_allocation_attempts();
}

JNIEXPORT jint JNICALL Java_CopiedSurfaceObserver_liveTemporaries(JNIEnv *environment, jclass owner)
{
    (void)environment; (void)owner;
    return (jint)surfer_surface_jni_test_live_allocations();
}

JNIEXPORT jint JNICALL Java_CopiedSurfaceObserver_liveSnapshots(JNIEnv *environment, jclass owner)
{
    (void)environment; (void)owner;
    return (jint)surfer_surface_test_live_snapshots();
}
