/* Actual host JVM invocation and CheckJNI observation; no Java adapter. */
#define _POSIX_C_SOURCE 200809L
#include "android/render_session_jni.h"
#include "surfer_render_session.h"

#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if !defined(SURFER_RENDER_SESSION_TESTING) || !defined(SURFER_SURFACE_STORE_TESTING)
#error "actual JVM observation requires native owner counters"
#endif

enum { WIDTH = 11, HEIGHT = 9, PIXELS = WIDTH * HEIGHT };
static JavaVM *virtual_machine;
static JNIEnv *caller_environment;
static pthread_t caller;
static _Atomic size_t worker_observations, observer_refs_created, observer_refs_deleted;
static size_t numerical_threads_started, numerical_threads_joined;

static void require(bool condition, const char *message)
{
    if (!condition) { fprintf(stderr, "FAIL actual JVM: %s\n", message); exit(1); }
}

static bool no_exception(JNIEnv *environment, const char *operation)
{
    if (!(*environment)->ExceptionCheck(environment)) return true;
    fprintf(stderr, "FAIL actual JVM: exception after %s\n", operation);
    (*environment)->ExceptionDescribe(environment);
    return false;
}

int __real_pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *);
int __real_pthread_join(pthread_t, void **);

int __wrap_pthread_create(pthread_t *thread, const pthread_attr_t *attributes,
    void *(*entry)(void *), void *state)
{
    require(pthread_equal(pthread_self(), caller) != 0, "numerical workers were not created by the caller");
    const int status = __real_pthread_create(thread, attributes, entry, state);
    if (status == 0) numerical_threads_started++;
    return status;
}

int __wrap_pthread_join(pthread_t thread, void **result)
{
    require(pthread_equal(pthread_self(), caller) != 0, "numerical workers were not joined by the caller");
    const int status = __real_pthread_join(thread, result);
    if (status == 0) numerical_threads_joined++;
    return status;
}

static bool inspect_actual_worker(void)
{
    JNIEnv *environment = NULL;
    require(pthread_equal(pthread_self(), caller) == 0, "numerical work ran on the original caller");
    if ((*virtual_machine)->GetEnv(virtual_machine, (void **)&environment, JNI_VERSION_1_6) != JNI_OK ||
        environment == NULL || environment == caller_environment) {
        fprintf(stderr, "FAIL actual JVM: numerical worker lacks its own existing attachment\n");
        return false;
    }
    bool success = false;
    jobject thread = NULL;
    jclass thread_class = (*environment)->FindClass(environment, "java/lang/Thread");
    if (thread_class != NULL) atomic_fetch_add(&observer_refs_created, 1);
    if (!no_exception(environment, "Thread class lookup") || thread_class == NULL) goto cleanup;
    jmethodID current_thread = (*environment)->GetStaticMethodID(environment, thread_class,
        "currentThread", "()Ljava/lang/Thread;");
    if (!no_exception(environment, "currentThread lookup") || current_thread == NULL) goto cleanup;
    thread = (*environment)->CallStaticObjectMethod(environment, thread_class, current_thread);
    if (thread != NULL) atomic_fetch_add(&observer_refs_created, 1);
    if (!no_exception(environment, "currentThread invocation") || thread == NULL) goto cleanup;
    jmethodID get_priority = (*environment)->GetMethodID(environment, thread_class, "getPriority", "()I");
    if (!no_exception(environment, "getPriority lookup") || get_priority == NULL) goto cleanup;
    const jint priority = (*environment)->CallIntMethod(environment, thread, get_priority);
    if (!no_exception(environment, "getPriority invocation")) goto cleanup;
    jmethodID is_daemon = (*environment)->GetMethodID(environment, thread_class, "isDaemon", "()Z");
    if (!no_exception(environment, "isDaemon lookup") || is_daemon == NULL) goto cleanup;
    const jboolean daemon = (*environment)->CallBooleanMethod(environment, thread, is_daemon);
    if (!no_exception(environment, "isDaemon invocation")) goto cleanup;
    if (priority != 1 || daemon != JNI_TRUE) {
        fprintf(stderr, "FAIL actual JVM: worker priority %d daemon %u\n", (int)priority, (unsigned)daemon);
        goto cleanup;
    }
    atomic_fetch_add(&worker_observations, 1);
    success = true;
cleanup:
    if (thread != NULL) {
        (*environment)->DeleteLocalRef(environment, thread);
        atomic_fetch_add(&observer_refs_deleted, 1);
    }
    if (thread_class != NULL) {
        (*environment)->DeleteLocalRef(environment, thread_class);
        atomic_fetch_add(&observer_refs_deleted, 1);
    }
    return success;
}

surfer_status __real_surfer_render_orthographic_tile(const surfer_scene *, size_t, size_t,
    size_t, size_t, size_t, size_t, double, double, double, double,
    surfer_render_quality, const surfer_cancellation *, uint32_t *, size_t);

surfer_status __wrap_surfer_render_orthographic_tile(const surfer_scene *scene, size_t width, size_t height,
    size_t x_start, size_t y_start, size_t x_end, size_t y_end,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, const surfer_cancellation *cancellation,
    uint32_t *pixels, size_t capacity)
{
    if (!inspect_actual_worker()) return SURFER_INVALID_INPUT;
    const surfer_status status = __real_surfer_render_orthographic_tile(scene, width, height,
        x_start, y_start, x_end, y_end, camera_height, yaw, pitch, zoom,
        quality, cancellation, pixels, capacity);
    return inspect_actual_worker() ? status : SURFER_INVALID_INPUT;
}

static void runtime_property(const char *key)
{
    JNIEnv *environment = caller_environment;
    jclass system = (*environment)->FindClass(environment, "java/lang/System");
    require(no_exception(environment, "System lookup") && system != NULL, "System class unavailable");
    jmethodID get_property = (*environment)->GetStaticMethodID(environment, system,
        "getProperty", "(Ljava/lang/String;)Ljava/lang/String;");
    require(no_exception(environment, "getProperty lookup") && get_property != NULL, "getProperty unavailable");
    jstring name = (*environment)->NewStringUTF(environment, key);
    require(no_exception(environment, "property name creation") && name != NULL, "property name unavailable");
    jstring value = (jstring)(*environment)->CallStaticObjectMethod(environment, system, get_property, name);
    require(no_exception(environment, "getProperty invocation") && value != NULL, "runtime property unavailable");
    const char *text = (*environment)->GetStringUTFChars(environment, value, NULL);
    require(no_exception(environment, "property character access") && text != NULL, "runtime property characters unavailable");
    printf("actual_runtime_property\t%s\t%s\n", key, text);
    (*environment)->ReleaseStringUTFChars(environment, value, text);
    (*environment)->DeleteLocalRef(environment, value);
    (*environment)->DeleteLocalRef(environment, name);
    (*environment)->DeleteLocalRef(environment, system);
}

static void empty_owners(void)
{
    require(surfer_render_session_test_live_sessions() == 0 &&
        surfer_render_session_test_live_epochs() == 0 &&
        surfer_render_session_test_live_allocations() == 0, "session/epoch native ownership leaked");
    require(surfer_surface_test_live_snapshots() == 0 && surfer_surface_test_live_borrows() == 0 &&
        surfer_surface_test_live_allocations() == 0, "copied surface native ownership leaked");
}

int main(void)
{
    caller = pthread_self();
    JavaVMOption options[] = {
        {.optionString = "-Xcheck:jni", .extraInfo = NULL},
        {.optionString = "-XX:-UsePerfData", .extraInfo = NULL},
        {.optionString = "-Xms16m", .extraInfo = NULL},
        {.optionString = "-Xmx128m", .extraInfo = NULL},
        {.optionString = "-XX:ActiveProcessorCount=4", .extraInfo = NULL}
    };
    JavaVMInitArgs arguments = {JNI_VERSION_1_6, 5, options, JNI_FALSE};
    require(JNI_CreateJavaVM(&virtual_machine, (void **)&caller_environment, &arguments) == JNI_OK &&
        virtual_machine != NULL && caller_environment != NULL, "JNI_CreateJavaVM failed");
    runtime_property("java.version");
    runtime_property("java.runtime.version");
    runtime_property("java.vm.name");
    runtime_property("java.vm.version");
    JNIEnv *environment = caller_environment;
    static const int32_t offsets[5] = {0, 4, 5, 6, 7};
    static const double coefficients[7] = {-0.64, 1, 1, 1, 2, 2, 2};
    static const int32_t xyz[21] = {
        0,0,0, 0,0,2, 0,2,0, 2,0,0, 1,0,0, 0,1,0, 0,0,1
    };
    surfer_surface_handle surface = 0;
    require(surfer_surface_create_copied(1, 2, offsets, 5, coefficients, 7, xyz, 21, &surface) == SURFER_OK &&
        surface > 0, "prepared surface creation failed");
    const jlong session = Java_Idric_Generated_createRenderSession(environment, NULL);
    require(no_exception(environment, "createRenderSession") && session > 0, "real JNI session creation failed");
    const jlong epoch = Java_Idric_Generated_beginRenderEpoch(environment, NULL, session);
    require(no_exception(environment, "beginRenderEpoch") && epoch > 0, "real JNI epoch creation failed");
    jintArray output = (*environment)->NewIntArray(environment, PIXELS);
    require(no_exception(environment, "output array creation") && output != NULL, "actual output array unavailable");
    jint pixels[PIXELS];
    for (size_t index = 0; index < PIXELS; index++) pixels[index] = 0x12345678;
    (*environment)->SetIntArrayRegion(environment, output, 0, PIXELS, pixels);
    require(no_exception(environment, "output sentinel initialization"), "actual output array initialization failed");
    const jint status = Java_Idric_Generated_renderSessionSurface(environment, NULL,
        session, epoch, surface, WIDTH, HEIGHT, 1, 2.15, 0, 0, 1, output);
    require(no_exception(environment, "renderSessionSurface") && status == SURFER_OK,
        "actual JNI threaded render failed");
    require(numerical_threads_started == 4 && numerical_threads_joined == 4,
        "actual four-worker JNI render did not join every numerical thread");
    (*environment)->GetIntArrayRegion(environment, output, 0, PIXELS, pixels);
    require(no_exception(environment, "output array observation"), "actual output array read failed");
    bool variation = false;
    for (size_t index = 0; index < PIXELS; index++) {
        uint32_t argb;
        memcpy(&argb, &pixels[index], sizeof(argb));
        require((argb & UINT32_C(0xff000000)) == UINT32_C(0xff000000), "actual JNI output retained sentinel or invalid alpha");
        variation = variation || pixels[index] != pixels[0];
    }
    require(variation && atomic_load(&worker_observations) > 0 &&
        atomic_load(&worker_observations) % 2 == 0 &&
        atomic_load(&observer_refs_created) == atomic_load(&observer_refs_deleted),
        "actual worker/image observations or observer local references unbalanced");
    require(Java_Idric_Generated_releaseRenderSession(environment, NULL, session) == SURFER_OK &&
        no_exception(environment, "releaseRenderSession") && surfer_surface_release(surface) == SURFER_OK,
        "actual JNI/native release failed");
    (*environment)->DeleteLocalRef(environment, output);
    empty_owners();
    printf("actual_numerical_threads_started_joined\t%zu\t%zu\n",
        numerical_threads_started, numerical_threads_joined);
    printf("actual_native_live_owners_after_release\t0\n");
    printf("actual_worker_priority_daemon_observations\t%zu\n", atomic_load(&worker_observations));
    printf("actual_observer_local_references_created_deleted\t%zu\t%zu\n",
        atomic_load(&observer_refs_created), atomic_load(&observer_refs_deleted));
    require((*virtual_machine)->DestroyJavaVM(virtual_machine) == JNI_OK, "DestroyJavaVM failed");
    puts("PASS actual host JVM CheckJNI daemon priority through numerical work array publication owners and VM destruction");
    return 0;
}
