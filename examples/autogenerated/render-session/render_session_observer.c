/* Independent JNI observation and test-only fault controls. No source body,
 * surface arithmetic, pixel algorithm or registry replacement lives here. */
#include "../../../native/android/render_session_jni.h"
#include "../../../native/surfer_render_session.h"
#include <limits.h>
#include <stdlib.h>
#ifndef SURFER_RENDER_SESSION_JNI_TESTING
#error "Session observer must never enter a production build"
#endif

JNIEXPORT jint JNICALL Java_RenderSessionObserver_failCreateAllocation(JNIEnv *environment, jclass owner, jint index)
{ (void)environment; (void)owner; return index < -1 ? 0 : surfer_session_jni_test_fail_create(index < 0 ? SIZE_MAX : (size_t)index); }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_failBeginAllocation(JNIEnv *environment, jclass owner, jint index)
{ (void)environment; (void)owner; return index < -1 ? 0 : surfer_session_jni_test_fail_begin(index < 0 ? SIZE_MAX : (size_t)index); }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_failRenderAllocation(JNIEnv *environment, jclass owner, jint index)
{ (void)environment; (void)owner; return index < -1 ? 0 : surfer_session_jni_test_fail_render(index < 0 ? SIZE_MAX : (size_t)index); }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_cancelBeforePublish(JNIEnv *environment, jclass owner, jint enabled)
{ (void)environment; (void)owner; return surfer_session_jni_test_cancel_before_publish(enabled); }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_cancelOnCurrent(JNIEnv *environment, jclass owner, jlong ordinal)
{ (void)environment; (void)owner; return surfer_session_jni_test_cancel_on_current(ordinal); }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_createAttempts(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; size_t value = surfer_session_jni_test_create_attempts(); if (value > INT_MAX) abort(); return (jint)value; }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_beginAttempts(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; size_t value = surfer_session_jni_test_begin_attempts(); if (value > INT_MAX) abort(); return (jint)value; }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_renderAttempts(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; size_t value = surfer_session_jni_test_render_attempts(); if (value > INT_MAX) abort(); return (jint)value; }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_liveSessions(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; size_t value = surfer_render_session_test_live_sessions(); if (value > INT_MAX) abort(); return (jint)value; }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_liveEpochs(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; size_t value = surfer_render_session_test_live_epochs(); if (value > INT_MAX) abort(); return (jint)value; }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_liveAllocations(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; size_t value = surfer_render_session_test_live_allocations(); if (value > INT_MAX) abort(); return (jint)value; }
JNIEXPORT jlong JNICALL Java_RenderSessionObserver_renderCalls(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; return surfer_session_jni_test_render_calls(); }
JNIEXPORT jlong JNICALL Java_RenderSessionObserver_publications(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; return surfer_session_jni_test_publications(); }
JNIEXPORT jlong JNICALL Java_RenderSessionObserver_currentCalls(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; return surfer_session_jni_test_current_calls(); }
JNIEXPORT jlong JNICALL Java_RenderSessionObserver_createCalls(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; return surfer_session_jni_test_create_calls(); }
JNIEXPORT jlong JNICALL Java_RenderSessionObserver_beginCalls(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; return surfer_session_jni_test_begin_calls(); }
JNIEXPORT jlong JNICALL Java_RenderSessionObserver_cancelCalls(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; return surfer_session_jni_test_cancel_calls(); }
JNIEXPORT jlong JNICALL Java_RenderSessionObserver_releaseCalls(JNIEnv *environment, jclass owner)
{ (void)environment; (void)owner; return surfer_session_jni_test_release_calls(); }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_current(JNIEnv *environment, jclass owner, jlong session, jlong epoch)
{ return Java_Idric_Generated_isRenderEpochCurrent(environment, owner, session, epoch); }
JNIEXPORT jint JNICALL Java_RenderSessionObserver_receiverRender(JNIEnv *environment, jclass owner,
 jlong session,jlong epoch,jlong surface,jint width,jint height,jint quality,
 jdouble camera,jdouble yaw,jdouble pitch,jdouble zoom,jintArray pixels)
{ return Java_Idric_Generated_renderSessionSurface(environment,owner,session,epoch,surface,
 width,height,quality,camera,yaw,pitch,zoom,pixels); }

