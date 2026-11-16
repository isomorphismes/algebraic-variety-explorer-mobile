#ifndef SURFER_RENDER_SESSION_JNI_H
#define SURFER_RENDER_SESSION_JNI_H

#include <jni.h>
#include <stddef.h>

JNIEXPORT jlong JNICALL Java_Idric_Generated_createRenderSession(JNIEnv *, jclass);
JNIEXPORT jlong JNICALL Java_Idric_Generated_beginRenderEpoch(JNIEnv *, jclass, jlong);
JNIEXPORT jint JNICALL Java_Idric_Generated_isRenderEpochCurrent(JNIEnv *, jclass, jlong, jlong);
JNIEXPORT jint JNICALL Java_Idric_Generated_cancelRenderSession(JNIEnv *, jclass, jlong);
JNIEXPORT jint JNICALL Java_Idric_Generated_releaseRenderSession(JNIEnv *, jclass, jlong);
JNIEXPORT jint JNICALL Java_Idric_Generated_renderSessionSurface(
    JNIEnv *, jclass, jlong, jlong, jlong, jint, jint, jint,
    jdouble, jdouble, jdouble, jdouble, jintArray);

#ifdef SURFER_RENDER_SESSION_JNI_TESTING
/* Current-thread test configuration only; each actual call gets a stack probe. */
int surfer_session_jni_test_fail_create(size_t);
int surfer_session_jni_test_fail_begin(size_t);
int surfer_session_jni_test_fail_render(size_t);
int surfer_session_jni_test_cancel_before_publish(int);
size_t surfer_session_jni_test_create_attempts(void);
size_t surfer_session_jni_test_begin_attempts(void);
size_t surfer_session_jni_test_render_attempts(void);
jlong surfer_session_jni_test_render_calls(void);
jlong surfer_session_jni_test_publications(void);
jlong surfer_session_jni_test_create_calls(void);
jlong surfer_session_jni_test_begin_calls(void);
jlong surfer_session_jni_test_current_calls(void);
jlong surfer_session_jni_test_cancel_calls(void);
jlong surfer_session_jni_test_release_calls(void);
int surfer_session_jni_test_cancel_on_current(jlong);
#endif

#endif
