/* Synchronous writable-output JNI. No Java array pointer or reference survives
 * this call. The caller must keep output private until the status is OK.
 */
#include "render_surface_jni.h"
#include "../surfer_frame_output.h"

#include <float.h>
#include <limits.h>
#include <stdlib.h>

_Static_assert(CHAR_BIT == 8 && sizeof(jint) == sizeof(uint32_t), "JNI Int32 ARGB required");
_Static_assert(sizeof(jlong) == sizeof(int64_t), "JNI Int64 handle required");
_Static_assert(sizeof(jdouble) == sizeof(double) && DBL_MANT_DIG == 53 &&
    DBL_MAX_EXP == 1024, "native and JNI binary64 required");

#ifdef SURFER_RENDER_JNI_TESTING
#ifndef SURFER_FRAME_OUTPUT_TESTING
#error "JNI frame controls require test-only owned-frame API"
#endif
static _Thread_local size_t fail_at = SIZE_MAX;
static _Thread_local size_t allocation_attempts;
static _Thread_local int64_t calls;
static _Thread_local int64_t publications;

int surfer_render_jni_test_reset_allocator(size_t index)
{
    fail_at = index;
    allocation_attempts = 0;
    return 1;
}
size_t surfer_render_jni_test_allocation_attempts(void) { return allocation_attempts; }
jlong surfer_render_jni_test_calls(void) { return calls; }
jlong surfer_render_jni_test_publications(void) { return publications; }
#endif

static bool int_array(JNIEnv *environment, jobject value)
{
    if (value == NULL) return false;
    jclass expected = (*environment)->FindClass(environment, "[I");
    if (expected == NULL) return false;
    const jboolean matches = (*environment)->IsInstanceOf(environment, value, expected);
    (*environment)->DeleteLocalRef(environment, expected);
    return matches == JNI_TRUE && !(*environment)->ExceptionCheck(environment);
}

JNIEXPORT jint JNICALL Java_Idric_Generated_renderPreparedSurface(
    JNIEnv *environment, jclass owner, jlong handle, jint width, jint height, jint quality,
    jdouble camera_height, jdouble yaw, jdouble pitch, jdouble zoom, jintArray output)
{
    (void)owner;
#ifdef SURFER_RENDER_JNI_TESTING
    if (calls == INT64_MAX) abort();
    calls++;
#endif
    if ((*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
    if (!int_array(environment, output)) return SURFER_INVALID_INPUT;
    const jsize length = (*environment)->GetArrayLength(environment, output);
    if ((*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
    if (width < 2 || height < 2 || (quality != 0 && quality != 1) ||
        (size_t)width > SIZE_MAX / (size_t)height ||
        (size_t)width * (size_t)height > INT32_MAX ||
        length < 0 || (size_t)length != (size_t)width * (size_t)height) {
        return SURFER_INVALID_INPUT;
    }
    surfer_owned_frame frame = {NULL, 0};
#ifdef SURFER_RENDER_JNI_TESTING
    surfer_frame_allocation_probe probe = {fail_at, 0};
    const surfer_status status = surfer_frame_test_render_copied(handle, width, height, quality,
        camera_height, yaw, pitch, zoom, &frame, &probe);
    allocation_attempts = probe.attempts;
#else
    const surfer_status status = surfer_surface_render_copied_frame(handle, width, height, quality,
        camera_height, yaw, pitch, zoom, &frame);
#endif
    if (status != SURFER_OK) return (jint)status;
    /* jint and uint32_t are corresponding signed/unsigned Int32 types on the
     * Android JNI ABI. Copy raw ARGB bits once, after the complete render. */
    (*environment)->SetIntArrayRegion(environment, output, 0, length, (const jint *)frame.argb_pixels);
#ifdef SURFER_RENDER_JNI_TESTING
    if (!(*environment)->ExceptionCheck(environment)) {
        if (publications == INT64_MAX) abort();
        publications++;
    }
#endif
    surfer_owned_frame_destroy(&frame);
    return (*environment)->ExceptionCheck(environment) ? SURFER_INVALID_INPUT : SURFER_OK;
}
