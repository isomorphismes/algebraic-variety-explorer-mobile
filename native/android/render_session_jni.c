/* Additive synchronous session JNI. Publication occurs inside the native
 * session's final locked gate; no environment, array reference or staging
 * pointer survives this invocation. The fourteen-word probe is unchanged. */
#include "render_session_jni.h"
#include "../surfer_render_session.h"

#include <float.h>
#include <limits.h>
#include <math.h>
#include <stdlib.h>

_Static_assert(CHAR_BIT == 8 && sizeof(jint) == sizeof(uint32_t), "JNI Int32 ARGB required");
_Static_assert(sizeof(jlong) == sizeof(int64_t), "JNI Int64 identities required");
_Static_assert(sizeof(jdouble) == sizeof(double) && DBL_MANT_DIG == 53 &&
    DBL_MAX_EXP == 1024, "JNI/native binary64 required");

#ifdef SURFER_RENDER_SESSION_JNI_TESTING
#ifndef SURFER_RENDER_SESSION_TESTING
#error "Session JNI fault controls require the test-only native session API"
#endif
static _Thread_local size_t create_fail_at = SIZE_MAX;
static _Thread_local size_t begin_fail_at = SIZE_MAX;
static _Thread_local size_t render_fail_at = SIZE_MAX;
static _Thread_local size_t create_attempts;
static _Thread_local size_t begin_attempts;
static _Thread_local size_t render_attempts;
static _Thread_local bool cancel_before_publish;
static _Thread_local int64_t render_calls;
static _Thread_local int64_t publications;
static _Thread_local int64_t create_calls;
static _Thread_local int64_t begin_calls;
static _Thread_local int64_t current_calls;
static _Thread_local int64_t cancel_calls;
static _Thread_local int64_t release_calls;
static _Thread_local int64_t cancel_on_current;

static void record_call(int64_t *counter)
{
    if (*counter == INT64_MAX) abort();
    (*counter)++;
}

int surfer_session_jni_test_fail_create(size_t index) { create_fail_at = index; create_attempts = 0; return 1; }
int surfer_session_jni_test_fail_begin(size_t index) { begin_fail_at = index; begin_attempts = 0; return 1; }
int surfer_session_jni_test_fail_render(size_t index) { render_fail_at = index; render_attempts = 0; return 1; }
int surfer_session_jni_test_cancel_before_publish(int enabled) { cancel_before_publish = enabled != 0; return 1; }
size_t surfer_session_jni_test_create_attempts(void) { return create_attempts; }
size_t surfer_session_jni_test_begin_attempts(void) { return begin_attempts; }
size_t surfer_session_jni_test_render_attempts(void) { return render_attempts; }
jlong surfer_session_jni_test_render_calls(void) { return render_calls; }
jlong surfer_session_jni_test_publications(void) { return publications; }
jlong surfer_session_jni_test_create_calls(void) { return create_calls; }
jlong surfer_session_jni_test_begin_calls(void) { return begin_calls; }
jlong surfer_session_jni_test_current_calls(void) { return current_calls; }
jlong surfer_session_jni_test_cancel_calls(void) { return cancel_calls; }
jlong surfer_session_jni_test_release_calls(void) { return release_calls; }
int surfer_session_jni_test_cancel_on_current(jlong ordinal)
{
    if (ordinal < 0) return 0;
    current_calls = 0;
    cancel_on_current = ordinal;
    return 1;
}

static void cancel_at_commit(void *state, surfer_render_session_test_phase phase)
{
    if (phase == SURFER_SESSION_BEFORE_PUBLISH) {
        const surfer_render_session_handle *session = state;
        (void)surfer_render_session_cancel(*session);
    }
}
#endif

/* Query the same standard platform value used by the original Activity.
 * All class/object refs are synchronous locals on this calling thread. The
 * numerical owner receives only the checked scalar and never sees JNIEnv.
 */
static bool platform_processor_count(JNIEnv *environment, size_t *processors)
{
    if (processors == NULL || (*environment)->ExceptionCheck(environment)) return false;
    bool success = false;
    jobject runtime = NULL;
    jclass runtime_class = (*environment)->FindClass(environment, "java/lang/Runtime");
    if (runtime_class == NULL || (*environment)->ExceptionCheck(environment)) goto cleanup;
    jmethodID get_runtime = (*environment)->GetStaticMethodID(environment, runtime_class,
        "getRuntime", "()Ljava/lang/Runtime;");
    if (get_runtime == NULL || (*environment)->ExceptionCheck(environment)) goto cleanup;
    runtime = (*environment)->CallStaticObjectMethod(environment, runtime_class, get_runtime);
    if (runtime == NULL || (*environment)->ExceptionCheck(environment)) goto cleanup;
    jmethodID available_processors = (*environment)->GetMethodID(environment, runtime_class,
        "availableProcessors", "()I");
    if (available_processors == NULL || (*environment)->ExceptionCheck(environment)) goto cleanup;
    const jint count = (*environment)->CallIntMethod(environment, runtime, available_processors);
    if ((*environment)->ExceptionCheck(environment) || count <= 0) goto cleanup;
    *processors = (size_t)count;
    success = true;
cleanup:
    if (runtime != NULL) (*environment)->DeleteLocalRef(environment, runtime);
    if (runtime_class != NULL) (*environment)->DeleteLocalRef(environment, runtime_class);
    return success;
}

/* A fresh pthread acquires its own daemon attachment and bootstrap Thread
 * object. Thread.MIN_PRIORITY uses ART's full priority/task-profile path;
 * setting only an OS nice value would not preserve that behavior. The caller
 * environment is never supplied to this hook or to a numerical worker.
 */
static surfer_status start_android_worker(void *state, void **worker_token)
{
    JavaVM *virtual_machine = state;
    if (virtual_machine == NULL || worker_token == NULL) return SURFER_INVALID_INPUT;
    *worker_token = NULL;
    void *previous_environment = NULL;
    if ((*virtual_machine)->GetEnv(virtual_machine, &previous_environment, JNI_VERSION_1_6) != JNI_EDETACHED ||
        previous_environment != NULL) return SURFER_INVALID_INPUT;
    JNIEnv *environment = NULL;
#ifdef __ANDROID__
    const jint attached = (*virtual_machine)->AttachCurrentThreadAsDaemon(virtual_machine, &environment, NULL);
#else
    const jint attached = (*virtual_machine)->AttachCurrentThreadAsDaemon(virtual_machine, (void **)&environment, NULL);
#endif
    if (attached != JNI_OK || environment == NULL) return SURFER_OUT_OF_MEMORY;
    *worker_token = environment;
    bool success = false;
    jobject thread = NULL;
    jclass thread_class = (*environment)->FindClass(environment, "java/lang/Thread");
    if (thread_class == NULL || (*environment)->ExceptionCheck(environment)) goto cleanup;
    jmethodID current_thread = (*environment)->GetStaticMethodID(environment, thread_class,
        "currentThread", "()Ljava/lang/Thread;");
    if (current_thread == NULL || (*environment)->ExceptionCheck(environment)) goto cleanup;
    thread = (*environment)->CallStaticObjectMethod(environment, thread_class, current_thread);
    if (thread == NULL || (*environment)->ExceptionCheck(environment)) goto cleanup;
    jmethodID set_priority = (*environment)->GetMethodID(environment, thread_class, "setPriority", "(I)V");
    if (set_priority == NULL || (*environment)->ExceptionCheck(environment)) goto cleanup;
    (*environment)->CallVoidMethod(environment, thread, set_priority, (jint)1);
    if ((*environment)->ExceptionCheck(environment)) goto cleanup;
    success = true;
cleanup:
    if (thread != NULL) (*environment)->DeleteLocalRef(environment, thread);
    if (thread_class != NULL) (*environment)->DeleteLocalRef(environment, thread_class);
    /* Attachment remains owned until finish_android_worker, even on partial
     * startup failure. The core always invokes that cleanup before completion.
     */
    return success ? SURFER_OK : SURFER_INVALID_INPUT;
}

static surfer_status finish_android_worker(void *state, void *worker_token)
{
    if (worker_token == NULL) return SURFER_OK;
    JavaVM *virtual_machine = state;
    JNIEnv *environment = worker_token;
    void *current_environment = NULL;
    if (virtual_machine == NULL ||
        (*virtual_machine)->GetEnv(virtual_machine, &current_environment, JNI_VERSION_1_6) != JNI_OK ||
        current_environment != environment) return SURFER_INVALID_INPUT;
    /* A worker exception is recorded as native startup failure, rather than
     * moved across environments. Clear it only on that worker before detach.
     */
    if ((*environment)->ExceptionCheck(environment)) (*environment)->ExceptionClear(environment);
    return (*virtual_machine)->DetachCurrentThread(virtual_machine) == JNI_OK
        ? SURFER_OK : SURFER_INVALID_INPUT;
}

JNIEXPORT jlong JNICALL Java_Idric_Generated_createRenderSession(JNIEnv *environment, jclass owner)
{
    (void)owner;
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    create_attempts = 0;
    record_call(&create_calls);
#endif
    if ((*environment)->ExceptionCheck(environment)) return 0;
    size_t processors = 0;
    if (!platform_processor_count(environment, &processors))
        return (*environment)->ExceptionCheck(environment) ? 0 : -SURFER_INVALID_INPUT;
    surfer_render_session_handle session = 0;
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    surfer_render_session_probe probe = {create_fail_at, 0, 0, 0, NULL, NULL};
    const surfer_status status = surfer_render_session_test_create_for_processors(processors, &session, &probe);
    create_attempts = probe.attempts;
#else
    const surfer_status status = surfer_render_session_create_for_processors(processors, &session);
#endif
    return status == SURFER_OK ? session : -(jlong)status;
}

JNIEXPORT jlong JNICALL Java_Idric_Generated_beginRenderEpoch(
    JNIEnv *environment, jclass owner, jlong session)
{
    (void)owner;
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    begin_attempts = 0;
    record_call(&begin_calls);
#endif
    if ((*environment)->ExceptionCheck(environment)) return 0;
    surfer_render_epoch epoch = 0;
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    surfer_render_session_probe probe = {begin_fail_at, 0, 0, 0, NULL, NULL};
    const surfer_status status = surfer_render_session_test_begin(session, &epoch, &probe);
    begin_attempts = probe.attempts;
#else
    const surfer_status status = surfer_render_session_begin(session, &epoch);
#endif
    return status == SURFER_OK ? epoch : -(jlong)status;
}

JNIEXPORT jint JNICALL Java_Idric_Generated_isRenderEpochCurrent(
    JNIEnv *environment, jclass owner, jlong session, jlong epoch)
{
    (void)owner;
    if ((*environment)->ExceptionCheck(environment)) return -SURFER_INVALID_INPUT;
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    record_call(&current_calls);
    if (cancel_on_current != 0 && current_calls == cancel_on_current)
        (void)surfer_render_session_cancel(session);
#endif
    bool current = false;
    const surfer_status status = surfer_render_session_current(session, epoch, &current);
    return status == SURFER_OK ? (current ? 1 : 0) : -(jint)status;
}

JNIEXPORT jint JNICALL Java_Idric_Generated_cancelRenderSession(
    JNIEnv *environment, jclass owner, jlong session)
{
    (void)owner;
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    record_call(&cancel_calls);
#endif
    if ((*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
    return (jint)surfer_render_session_cancel(session);
}

JNIEXPORT jint JNICALL Java_Idric_Generated_releaseRenderSession(
    JNIEnv *environment, jclass owner, jlong session)
{
    (void)owner;
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    record_call(&release_calls);
#endif
    if ((*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
    return (jint)surfer_render_session_release(session);
}

typedef struct {
    JNIEnv *environment;
    jintArray output;
    size_t width;
    size_t height;
    jsize count;
} array_publication;

static surfer_status publish_android_rows(void *state, uint32_t *pixels, size_t count)
{
    array_publication *publication = state;
    JNIEnv *environment = publication->environment;
    if (pixels == NULL || count != (size_t)publication->count ||
        (*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
    /* Unique native staging is no longer used by the numerical core. This
     * reverses mathematical rows once, exactly like the existing frame adapter. */
    for (size_t top = 0; top < publication->height / 2U; ++top) {
        const size_t bottom = publication->height - 1U - top;
        for (size_t x = 0; x < publication->width; ++x) {
            const size_t upper = top * publication->width + x;
            const size_t lower = bottom * publication->width + x;
            const uint32_t value = pixels[upper];
            pixels[upper] = pixels[lower];
            pixels[lower] = value;
        }
    }
    (*environment)->SetIntArrayRegion(environment, publication->output, 0,
        publication->count, (const jint *)pixels);
    if ((*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    record_call(&publications);
#endif
    return SURFER_OK;
}

static bool output_array(JNIEnv *environment, jobject value)
{
    if (value == NULL) return false;
    jclass expected = (*environment)->FindClass(environment, "[I");
    if (expected == NULL) return false;
    const jboolean matches = (*environment)->IsInstanceOf(environment, value, expected);
    (*environment)->DeleteLocalRef(environment, expected);
    return matches == JNI_TRUE && !(*environment)->ExceptionCheck(environment);
}

JNIEXPORT jint JNICALL Java_Idric_Generated_renderSessionSurface(
    JNIEnv *environment, jclass owner, jlong session, jlong epoch, jlong surface,
    jint width, jint height, jint quality,
    jdouble camera_height, jdouble yaw, jdouble pitch, jdouble zoom, jintArray output)
{
    (void)owner;
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    render_attempts = 0;
    record_call(&render_calls);
#endif
    if ((*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
    if (!output_array(environment, output)) return SURFER_INVALID_INPUT;
    const jsize count = (*environment)->GetArrayLength(environment, output);
    if ((*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
    if (width < 2 || height < 2 || quality < 0 || quality > 1 || count < 0 ||
        (size_t)width > SIZE_MAX / (size_t)height ||
        (size_t)width * (size_t)height > INT32_MAX ||
        (size_t)width * (size_t)height > SIZE_MAX / sizeof(uint32_t) ||
        (size_t)count != (size_t)width * (size_t)height ||
        !isfinite(camera_height) || !isfinite(yaw) || !isfinite(pitch) || !isfinite(zoom) ||
        !(camera_height > 0.0) || !(zoom > 0.0)) return SURFER_INVALID_INPUT;
    array_publication publication = {environment, output, (size_t)width, (size_t)height, count};
    const surfer_scene settings = surfer_default_scene(NULL);
    const surfer_render_quality selected = {
        quality == 0 ? SURFER_AA_OG_1X1 : SURFER_AA_QUINCUNX, 0.3f
    };
    size_t processors = 0;
    if (!platform_processor_count(environment, &processors)) return SURFER_INVALID_INPUT;
    JavaVM *virtual_machine = NULL;
    if ((*environment)->GetJavaVM(environment, &virtual_machine) != JNI_OK || virtual_machine == NULL ||
        (*environment)->ExceptionCheck(environment)) return SURFER_INVALID_INPUT;
    const surfer_render_worker_hooks worker_hooks = {
        start_android_worker, finish_android_worker, virtual_machine
    };
#ifdef SURFER_RENDER_SESSION_JNI_TESTING
    surfer_render_session_handle hook_session = session;
    surfer_render_session_probe probe = {render_fail_at, 0, 0, 0,
        cancel_before_publish ? cancel_at_commit : NULL, &hook_session};
    const surfer_status status = surfer_render_session_test_render_tiled_publish_with_hooks(session, epoch, surface,
        &settings, processors, (size_t)width, (size_t)height, camera_height, yaw, pitch, zoom, selected,
        publish_android_rows, &publication, (size_t)count, &probe, NULL, &worker_hooks);
    render_attempts = probe.attempts;
#else
    const surfer_status status = surfer_render_session_render_tiled_publish_with_hooks(session, epoch, surface,
        &settings, processors, (size_t)width, (size_t)height, camera_height, yaw, pitch, zoom, selected,
        publish_android_rows, &publication, (size_t)count, &worker_hooks);
#endif
    return (jint)status;
}
