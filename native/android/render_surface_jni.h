#ifndef SURFER_RENDER_SURFACE_JNI_H
#define SURFER_RENDER_SURFACE_JNI_H

#include <jni.h>
#include <stddef.h>

JNIEXPORT jint JNICALL Java_Idric_Generated_renderPreparedSurface(
    JNIEnv *, jclass, jlong, jint, jint, jint, jdouble, jdouble, jdouble, jdouble, jintArray);

#ifdef SURFER_RENDER_JNI_TESTING
int surfer_render_jni_test_reset_allocator(size_t fail_at);
size_t surfer_render_jni_test_allocation_attempts(void);
jlong surfer_render_jni_test_calls(void);
jlong surfer_render_jni_test_publications(void);
#endif

#endif
