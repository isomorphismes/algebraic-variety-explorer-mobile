#ifndef SURFER_PREPARED_SURFACE_JNI_H
#define SURFER_PREPARED_SURFACE_JNI_H

#include <jni.h>
#include <stddef.h>

JNIEXPORT jlong JNICALL Java_Idric_Generated_copyPreparedSurface(
    JNIEnv *, jclass, jint, jint, jint, jint, jint, jint, jint, jdoubleArray, jintArray);
JNIEXPORT jlong JNICALL Java_Idric_Generated_replacePreparedSurface(
    JNIEnv *, jclass, jlong, jint, jint, jint, jint, jint, jint, jint, jdoubleArray, jintArray);
JNIEXPORT jint JNICALL Java_Idric_Generated_releasePreparedSurface(JNIEnv *, jclass, jlong);

#ifdef SURFER_SURFACE_JNI_TESTING
/* Current-thread temporary-buffer fault injection, absent from production.
 * Returns false if the preceding call leaked temporary storage. */
int surfer_surface_jni_test_reset_allocator(size_t fail_at);
size_t surfer_surface_jni_test_allocation_attempts(void);
size_t surfer_surface_jni_test_live_allocations(void);
int surfer_surface_jni_test_reset_store_allocator(size_t fail_at);
size_t surfer_surface_jni_test_store_allocation_attempts(void);
jlong surfer_surface_jni_test_copy_calls(void);
#endif

#endif
