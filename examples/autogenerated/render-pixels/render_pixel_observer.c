/* Independent test-only JNI observation. The candidate class is emitted from
 * real Idriç source. No rendering or Bitmap construction lives in this file. */
#include "../../../native/android/render_surface_jni.h"
#include "../../../native/surfer_frame_output.h"

#include <stdint.h>

JNIEXPORT jlong JNICALL Java_RenderPixelObserver_renderCalls(JNIEnv *environment, jclass owner)
{
    (void)environment; (void)owner;
    return surfer_render_jni_test_calls();
}

JNIEXPORT jlong JNICALL Java_RenderPixelObserver_publications(JNIEnv *environment, jclass owner)
{
    (void)environment; (void)owner;
    return surfer_render_jni_test_publications();
}

JNIEXPORT jint JNICALL Java_RenderPixelObserver_failFrameAllocation(
    JNIEnv *environment, jclass owner, jint index)
{
    (void)environment; (void)owner;
    return surfer_render_jni_test_reset_allocator(index < 0 ? SIZE_MAX : (size_t)index);
}

JNIEXPORT jint JNICALL Java_RenderPixelObserver_allocationAttempts(JNIEnv *environment, jclass owner)
{
    (void)environment; (void)owner;
    return (jint)surfer_render_jni_test_allocation_attempts();
}

JNIEXPORT jint JNICALL Java_RenderPixelObserver_liveFrames(JNIEnv *environment, jclass owner)
{
    (void)environment; (void)owner;
    return (jint)surfer_frame_test_live_allocations();
}

JNIEXPORT jint JNICALL Java_RenderPixelObserver_liveBorrows(JNIEnv *environment, jclass owner)
{
    (void)environment; (void)owner;
    return (jint)surfer_surface_test_live_borrows();
}

/* Allows the independent observer to exercise malformed receiver calls. Its
 * successful source/Bitmap path must still call the real generated producer. */
JNIEXPORT jint JNICALL Java_RenderPixelObserver_receiverRender(
    JNIEnv *environment, jclass owner, jlong handle, jint width, jint height, jint quality,
    jdouble camera_height, jdouble yaw, jdouble pitch, jdouble zoom, jintArray output)
{
    return Java_Idric_Generated_renderPreparedSurface(environment, owner, handle,
        width, height, quality, camera_height, yaw, pitch, zoom, output);
}
