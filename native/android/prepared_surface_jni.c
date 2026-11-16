/* Application-owned JNI adapter for the copied PreparedSurface ABI.
 * Only temporary primitive-array region copies are used. No managed reference
 * or borrowed array address is retained by the native store.
 */
#include "../surfer_surface_store.h"
#include "prepared_surface_jni.h"

#include <float.h>
#include <limits.h>
#include <stdlib.h>

_Static_assert(CHAR_BIT == 8 && sizeof(jint) == sizeof(int32_t), "JNI Int32 required");
_Static_assert(sizeof(jlong) == sizeof(int64_t), "JNI Int64 handle required");
_Static_assert(sizeof(jdouble) == sizeof(double) && DBL_MANT_DIG == 53 &&
    DBL_MAX_EXP == 1024, "JNI and native binary64 required");

#ifdef SURFER_SURFACE_JNI_TESTING
static _Thread_local size_t test_fail_at = SIZE_MAX;
static _Thread_local size_t test_attempts;
static _Thread_local size_t test_live_allocations;

int surfer_surface_jni_test_reset_allocator(size_t fail_at)
{
    if (test_live_allocations != 0) return 0;
    test_fail_at = fail_at;
    test_attempts = 0;
    return 1;
}

size_t surfer_surface_jni_test_allocation_attempts(void) { return test_attempts; }
size_t surfer_surface_jni_test_live_allocations(void) { return test_live_allocations; }
#endif

static void *allocate_temporary(size_t bytes)
{
#ifdef SURFER_SURFACE_JNI_TESTING
    const size_t attempt = test_attempts;
    if (attempt == SIZE_MAX) return NULL;
    test_attempts++;
    if (attempt == test_fail_at) return NULL;
#endif
    void *result = malloc(bytes);
#ifdef SURFER_SURFACE_JNI_TESTING
    if (result != NULL) test_live_allocations++;
#endif
    return result;
}

static void free_temporary(void *value)
{
#ifdef SURFER_SURFACE_JNI_TESTING
    if (value != NULL) test_live_allocations--;
#endif
    free(value);
}

static bool array_type(JNIEnv *environment, jobject value, const char *descriptor)
{
    if (value == NULL) return false;
    jclass expected = (*environment)->FindClass(environment, descriptor);
    if (expected == NULL) return false;
    const jboolean matches = (*environment)->IsInstanceOf(environment, value, expected);
    (*environment)->DeleteLocalRef(environment, expected);
    return matches == JNI_TRUE && !(*environment)->ExceptionCheck(environment);
}

static jlong copy_arrays(
    JNIEnv *environment, bool replacing, jlong previous,
    jint version, jint family_degree,
    jint offset0, jint offset1, jint offset2, jint offset3, jint offset4,
    jdoubleArray coefficients, jintArray xyz)
{
    if ((*environment)->ExceptionCheck(environment)) return 0;
    if (!array_type(environment, coefficients, "[D") ||
        !array_type(environment, xyz, "[I")) {
        return (*environment)->ExceptionCheck(environment) ? 0 : -SURFER_INVALID_INPUT;
    }
    const jsize coefficient_count = (*environment)->GetArrayLength(environment, coefficients);
    if ((*environment)->ExceptionCheck(environment)) return 0;
    const jsize xyz_count = (*environment)->GetArrayLength(environment, xyz);
    if ((*environment)->ExceptionCheck(environment)) return 0;
    const int32_t offsets[5] = {offset0, offset1, offset2, offset3, offset4};
    if (version != SURFER_PREPARED_SURFACE_ABI_VERSION || family_degree < 0 ||
        coefficient_count < 0 || xyz_count < 0 ||
        coefficient_count > INT32_MAX / 3 || xyz_count != coefficient_count * 3 ||
        (size_t)coefficient_count > SIZE_MAX / sizeof(double) ||
        (size_t)xyz_count > SIZE_MAX / sizeof(int32_t) ||
        offsets[0] != 0 || offsets[4] != coefficient_count) {
        return -SURFER_INVALID_INPUT;
    }
    for (size_t i = 1; i < 5; ++i)
        if (offsets[i] < offsets[i - 1] || offsets[i] > offsets[4])
            return -SURFER_INVALID_INPUT;

    double *coefficient_copy = NULL;
    int32_t *xyz_copy = NULL;
    if (coefficient_count != 0) {
        coefficient_copy = allocate_temporary((size_t)coefficient_count * sizeof(*coefficient_copy));
        if (coefficient_copy == NULL) return -SURFER_OUT_OF_MEMORY;
        xyz_copy = allocate_temporary((size_t)xyz_count * sizeof(*xyz_copy));
        if (xyz_copy == NULL) {
            free_temporary(coefficient_copy);
            return -SURFER_OUT_OF_MEMORY;
        }
        (*environment)->GetDoubleArrayRegion(environment, coefficients, 0,
            coefficient_count, coefficient_copy);
        if (!(*environment)->ExceptionCheck(environment))
            (*environment)->GetIntArrayRegion(environment, xyz, 0, xyz_count, xyz_copy);
        if ((*environment)->ExceptionCheck(environment)) {
            free_temporary(xyz_copy);
            free_temporary(coefficient_copy);
            return 0;
        }
    }
    surfer_surface_handle handle = 0;
    const surfer_status status = replacing ?
        surfer_surface_replace_copied(previous, version, family_degree, offsets, 5,
            coefficient_copy, (size_t)coefficient_count,
            xyz_copy, (size_t)xyz_count, &handle) :
        surfer_surface_create_copied(version, family_degree, offsets, 5,
            coefficient_copy, (size_t)coefficient_count,
            xyz_copy, (size_t)xyz_count, &handle);
    free_temporary(xyz_copy);
    free_temporary(coefficient_copy);
    return status == SURFER_OK ? handle : -(jlong)status;
}

JNIEXPORT jlong JNICALL Java_Idric_Generated_copyPreparedSurface(
    JNIEnv *environment, jclass owner,
    jint version, jint family_degree,
    jint offset0, jint offset1, jint offset2, jint offset3, jint offset4,
    jdoubleArray coefficients, jintArray xyz)
{
    (void)owner;
    return copy_arrays(environment, false, 0, version, family_degree,
        offset0, offset1, offset2, offset3, offset4, coefficients, xyz);
}

JNIEXPORT jlong JNICALL Java_Idric_Generated_replacePreparedSurface(
    JNIEnv *environment, jclass owner, jlong previous,
    jint version, jint family_degree,
    jint offset0, jint offset1, jint offset2, jint offset3, jint offset4,
    jdoubleArray coefficients, jintArray xyz)
{
    (void)owner;
    return copy_arrays(environment, true, previous, version, family_degree,
        offset0, offset1, offset2, offset3, offset4, coefficients, xyz);
}

JNIEXPORT jint JNICALL Java_Idric_Generated_releasePreparedSurface(
    JNIEnv *environment, jclass owner, jlong handle)
{
    (void)owner;
    if ((*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
    return (jint)surfer_surface_release(handle);
}
