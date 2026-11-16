/* Host JNI-table observation of the actual Runtime query and native owners.
 * Official JNI headers define the interface; the table below is test input,
 * not a replacement production adapter or a platform/ART implementation. */
#define _POSIX_C_SOURCE 200809L
#if !defined(SURFER_RENDER_SESSION_JNI_TESTING) || !defined(SURFER_RENDER_SESSION_TESTING) || !defined(SURFER_SURFACE_STORE_TESTING)
#error "processor query observation requires all three test-only owner interfaces"
#endif
#include "android/render_session_jni.c"

#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
#include <string.h>

enum { WIDTH = 11, HEIGHT = 9, PIXELS = WIDTH * HEIGHT };
enum fault_kind { NO_FAULT, NULL_RESULT, EXCEPTION_NULL, EXCEPTION_VALUE };
static const jint sentinel = 0x12345678;
static JNIEnv test_environment;
static int runtime_class_identity, runtime_identity, array_class_identity;
static int array_identity, static_method_identity, method_identity;

typedef struct {
    pthread_t caller;
    unsigned fault_stage, next_stage, query_calls, exception_identity;
    enum fault_kind fault;
    jint count;
    bool runtime_class_live, runtime_live, array_class_live;
    size_t references_created, references_deleted, jni_calls, publishes;
    jint output[PIXELS];
} mock_environment;

static mock_environment mock;
static size_t threads_started, threads_joined, render_thread_baseline;
static const char *test_case = "startup";
static JavaVM test_virtual_machine;
static bool expect_owned_workers;
static unsigned worker_fault_stage;
static enum fault_kind worker_fault;
static bool fail_detach, foreign_attachment, fail_get_env, fail_attach, fail_get_vm;
static _Atomic size_t attached_workers, detached_workers, live_attachments;
static _Atomic size_t worker_refs_created, worker_refs_deleted, priority_calls, numerical_tiles;
static _Atomic size_t cleared_worker_exceptions, foreign_detaches;
static _Atomic size_t failed_worker_steps;
static size_t caller_vm_queries;

typedef struct {
    JNIEnv environment;
    bool attached, foreign, class_live, object_live, priority_set, in_numerical;
    unsigned exception_identity, next_stage;
    int class_identity, object_identity, static_identity, method_identity;
} worker_environment;
static _Thread_local worker_environment worker;
static const struct JNINativeInterface_ worker_functions;

static void require(bool condition, const char *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL processor query: %s: %s\n", test_case, message);
        exit(1);
    }
}

static void worker_touch(JNIEnv *environment, bool allowed_pending)
{
    require(pthread_equal(pthread_self(), mock.caller) == 0, "Thread JNI call ran on the caller");
    require(environment == &worker.environment && *environment == &worker_functions,
        "worker used another thread's JNI environment");
    require(worker.attached, "worker used JNI after detach or without an owned attachment");
    require(allowed_pending || worker.exception_identity == 0, "worker JNI continued under a pending exception");
}

static bool worker_stage(unsigned stage)
{
    require(stage == worker.next_stage, "worker Thread lookup or invocation order changed");
    worker.next_stage++;
    if (stage != worker_fault_stage || worker_fault == NO_FAULT) return false;
    atomic_fetch_add(&failed_worker_steps, 1);
    if (worker_fault == EXCEPTION_NULL || worker_fault == EXCEPTION_VALUE)
        worker.exception_identity = 200U + stage;
    return true;
}

static jboolean JNICALL worker_exception_check(JNIEnv *environment)
{
    worker_touch(environment, true);
    return worker.exception_identity != 0 ? JNI_TRUE : JNI_FALSE;
}

static void JNICALL worker_exception_clear(JNIEnv *environment)
{
    worker_touch(environment, true);
    require(worker.exception_identity != 0, "worker cleared a missing exception");
    worker.exception_identity = 0;
    atomic_fetch_add(&cleared_worker_exceptions, 1);
}

static jclass JNICALL worker_find_class(JNIEnv *environment, const char *name)
{
    worker_touch(environment, false);
    require(strcmp(name, "java/lang/Thread") == 0, "worker did not use the bootstrap Thread class");
    const bool failed = worker_stage(1);
    if (failed && worker_fault != EXCEPTION_VALUE) return NULL;
    require(!worker.class_live, "worker acquired its Thread class twice");
    worker.class_live = true;
    atomic_fetch_add(&worker_refs_created, 1);
    return (jclass)(void *)&worker.class_identity;
}

static jmethodID JNICALL worker_get_static(JNIEnv *environment, jclass owner,
    const char *name, const char *signature)
{
    worker_touch(environment, false);
    require(owner == (jclass)(void *)&worker.class_identity && worker.class_live &&
        strcmp(name, "currentThread") == 0 && strcmp(signature, "()Ljava/lang/Thread;") == 0,
        "worker currentThread lookup changed");
    const bool failed = worker_stage(2);
    return failed && worker_fault != EXCEPTION_VALUE ? NULL : (jmethodID)(void *)&worker.static_identity;
}

static jobject JNICALL worker_current_thread(JNIEnv *environment, jclass owner, jmethodID identifier, ...)
{
    worker_touch(environment, false);
    require(owner == (jclass)(void *)&worker.class_identity && worker.class_live &&
        identifier == (jmethodID)(void *)&worker.static_identity, "worker currentThread receiver changed");
    const bool failed = worker_stage(3);
    if (failed && worker_fault != EXCEPTION_VALUE) return NULL;
    require(!worker.object_live, "worker acquired its Thread object twice");
    worker.object_live = true;
    atomic_fetch_add(&worker_refs_created, 1);
    return (jobject)(void *)&worker.object_identity;
}

static jmethodID JNICALL worker_get_method(JNIEnv *environment, jclass owner,
    const char *name, const char *signature)
{
    worker_touch(environment, false);
    require(owner == (jclass)(void *)&worker.class_identity && worker.class_live &&
        strcmp(name, "setPriority") == 0 && strcmp(signature, "(I)V") == 0,
        "worker setPriority descriptor changed");
    const bool failed = worker_stage(4);
    return failed && worker_fault != EXCEPTION_VALUE ? NULL : (jmethodID)(void *)&worker.method_identity;
}

static void JNICALL worker_set_priority(JNIEnv *environment, jobject receiver, jmethodID identifier, ...)
{
    worker_touch(environment, false);
    require(receiver == (jobject)(void *)&worker.object_identity && worker.object_live &&
        identifier == (jmethodID)(void *)&worker.method_identity, "worker setPriority receiver changed");
    va_list arguments;
    va_start(arguments, identifier);
    const jint priority = va_arg(arguments, jint);
    va_end(arguments);
    require(priority == 1 && !worker.priority_set, "worker did not set Thread.MIN_PRIORITY exactly once");
    (void)worker_stage(5);
    worker.priority_set = true;
    atomic_fetch_add(&priority_calls, 1);
}

static void JNICALL worker_delete_local(JNIEnv *environment, jobject reference)
{
    worker_touch(environment, true);
    if (reference == (jobject)(void *)&worker.object_identity) {
        require(worker.object_live, "worker Thread object released twice");
        worker.object_live = false;
    } else if (reference == (jobject)(void *)&worker.class_identity) {
        require(worker.class_live, "worker Thread class released twice");
        worker.class_live = false;
    } else require(false, "worker released a foreign reference");
    atomic_fetch_add(&worker_refs_deleted, 1);
}

static const struct JNINativeInterface_ worker_functions = {
    .FindClass = worker_find_class,
    .GetStaticMethodID = worker_get_static,
    .CallStaticObjectMethod = worker_current_thread,
    .GetMethodID = worker_get_method,
    .CallVoidMethod = worker_set_priority,
    .ExceptionCheck = worker_exception_check,
    .ExceptionClear = worker_exception_clear,
    .DeleteLocalRef = worker_delete_local
};

static void vm_touch(JavaVM *virtual_machine)
{
    require(virtual_machine == &test_virtual_machine && expect_owned_workers &&
        pthread_equal(pthread_self(), mock.caller) == 0, "worker JavaVM call used the wrong owner or thread");
}

static jint JNICALL vm_get_env(JavaVM *virtual_machine, void **environment, jint version)
{
    vm_touch(virtual_machine);
    require(environment != NULL && version == JNI_VERSION_1_6, "worker GetEnv version/output changed");
    if (worker.attached) { *environment = &worker.environment; return JNI_OK; }
    *environment = NULL;
    if (fail_get_env) { atomic_fetch_add(&failed_worker_steps, 1); return JNI_EVERSION; }
    if (foreign_attachment) {
        worker.foreign = true;
        *environment = &test_environment;
        atomic_fetch_add(&failed_worker_steps, 1);
        return JNI_OK;
    }
    return JNI_EDETACHED;
}

static jint JNICALL vm_attach_daemon(JavaVM *virtual_machine, void **environment, void *arguments)
{
    vm_touch(virtual_machine);
    require(environment != NULL && arguments == NULL && !worker.attached && !worker.foreign,
        "worker attachment ownership/arguments changed");
    if (fail_attach) { *environment = NULL; atomic_fetch_add(&failed_worker_steps, 1); return JNI_ERR; }
    worker.environment = &worker_functions;
    worker.attached = true;
    worker.next_stage = 1;
    atomic_fetch_add(&attached_workers, 1);
    atomic_fetch_add(&live_attachments, 1);
    *environment = &worker.environment;
    return JNI_OK;
}

static jint JNICALL vm_detach(JavaVM *virtual_machine)
{
    vm_touch(virtual_machine);
    if (worker.foreign) atomic_fetch_add(&foreign_detaches, 1);
    require(worker.attached && !worker.foreign && !worker.in_numerical,
        "worker detached foreign/unowned state or detached during numerical work");
    require(!worker.class_live && !worker.object_live && worker.exception_identity == 0,
        "worker detached with live locals or a pending exception");
    worker.attached = false;
    atomic_fetch_add(&detached_workers, 1);
    atomic_fetch_sub(&live_attachments, 1);
    return fail_detach ? JNI_ERR : JNI_OK;
}

static const struct JNIInvokeInterface_ invocation_functions = {
    .GetEnv = vm_get_env,
    .AttachCurrentThreadAsDaemon = vm_attach_daemon,
    .DetachCurrentThread = vm_detach
};
static JavaVM test_virtual_machine = &invocation_functions;

static jobject object(void *identity) { return (jobject)identity; }
static jmethodID method(void *identity) { return (jmethodID)identity; }

static void touch(JNIEnv *environment, bool allowed_pending)
{
    require(pthread_equal(pthread_self(), mock.caller) != 0, "JNI call escaped the original caller thread");
    require(environment == &test_environment, "JNI environment identity changed");
    require(allowed_pending || mock.exception_identity == 0, "JNI operation continued under a pending exception");
    mock.jni_calls++;
}

static bool query_stage(unsigned stage)
{
    require(stage == mock.next_stage, "Runtime query call order changed");
    mock.next_stage++;
    mock.query_calls++;
    if (stage != mock.fault_stage || mock.fault == NO_FAULT) return false;
    if (mock.fault == EXCEPTION_NULL || mock.fault == EXCEPTION_VALUE)
        mock.exception_identity = 100U + stage;
    return true;
}

static jboolean JNICALL exception_check(JNIEnv *environment)
{
    touch(environment, true);
    return mock.exception_identity != 0 ? JNI_TRUE : JNI_FALSE;
}

static void JNICALL exception_clear(JNIEnv *environment)
{
    touch(environment, true);
    require(false, "adapter cleared the original pending exception");
}

static jclass JNICALL find_class(JNIEnv *environment, const char *name)
{
    touch(environment, false);
    if (strcmp(name, "[I") == 0) {
        require(!mock.array_class_live, "array class local reference reacquired while live");
        mock.array_class_live = true;
        mock.references_created++;
        return object(&array_class_identity);
    }
    require(strcmp(name, "java/lang/Runtime") == 0, "unexpected platform class");
    const bool failed = query_stage(1);
    if (failed && mock.fault != EXCEPTION_VALUE) return NULL;
    require(!mock.runtime_class_live, "Runtime class local reference reacquired while live");
    mock.runtime_class_live = true;
    mock.references_created++;
    return object(&runtime_class_identity);
}

static jmethodID JNICALL get_static_method(JNIEnv *environment, jclass owner,
    const char *name, const char *signature)
{
    touch(environment, false);
    require(owner == object(&runtime_class_identity) && mock.runtime_class_live,
        "static method lookup did not use the live Runtime class");
    require(strcmp(name, "getRuntime") == 0 && strcmp(signature, "()Ljava/lang/Runtime;") == 0,
        "Runtime.getRuntime signature changed");
    const bool failed = query_stage(2);
    return failed && mock.fault != EXCEPTION_VALUE ? NULL : method(&static_method_identity);
}

static jobject JNICALL call_static_object(JNIEnv *environment, jclass owner, jmethodID identifier, ...)
{
    touch(environment, false);
    require(owner == object(&runtime_class_identity) && mock.runtime_class_live &&
        identifier == method(&static_method_identity), "static Runtime invocation identity changed");
    const bool failed = query_stage(3);
    if (failed && mock.fault != EXCEPTION_VALUE) return NULL;
    require(!mock.runtime_live, "Runtime object local reference reacquired while live");
    mock.runtime_live = true;
    mock.references_created++;
    return object(&runtime_identity);
}

static jmethodID JNICALL get_method(JNIEnv *environment, jclass owner,
    const char *name, const char *signature)
{
    touch(environment, false);
    require(owner == object(&runtime_class_identity) && mock.runtime_class_live,
        "instance method lookup did not use the live Runtime class");
    require(strcmp(name, "availableProcessors") == 0 && strcmp(signature, "()I") == 0,
        "Runtime.availableProcessors signature changed");
    const bool failed = query_stage(4);
    return failed && mock.fault != EXCEPTION_VALUE ? NULL : method(&method_identity);
}

static jint JNICALL call_int(JNIEnv *environment, jobject receiver, jmethodID identifier, ...)
{
    touch(environment, false);
    require(receiver == object(&runtime_identity) && mock.runtime_live &&
        identifier == method(&method_identity), "processor query receiver changed");
    (void)query_stage(5);
    return mock.count;
}

static void JNICALL delete_local(JNIEnv *environment, jobject reference)
{
    touch(environment, true);
    if (reference == object(&runtime_identity)) {
        require(mock.runtime_live, "Runtime object local reference deleted twice");
        mock.runtime_live = false;
    } else if (reference == object(&runtime_class_identity)) {
        require(mock.runtime_class_live, "Runtime class local reference deleted twice");
        mock.runtime_class_live = false;
    } else if (reference == object(&array_class_identity)) {
        require(mock.array_class_live, "array class local reference deleted twice");
        mock.array_class_live = false;
    } else require(false, "unknown or borrowed reference was deleted");
    mock.references_deleted++;
}

static jboolean JNICALL is_instance(JNIEnv *environment, jobject receiver, jclass owner)
{
    touch(environment, false);
    require(receiver == object(&array_identity) && owner == object(&array_class_identity) &&
        mock.array_class_live, "array type check used the wrong identities");
    return JNI_TRUE;
}

static jsize JNICALL array_length(JNIEnv *environment, jarray receiver)
{
    touch(environment, false);
    require(receiver == object(&array_identity), "array length receiver changed");
    return PIXELS;
}

static jint JNICALL get_virtual_machine(JNIEnv *environment, JavaVM **virtual_machine)
{
    touch(environment, false);
    require(virtual_machine != NULL, "caller GetJavaVM has no output");
    caller_vm_queries++;
    *virtual_machine = fail_get_vm ? NULL : &test_virtual_machine;
    return fail_get_vm ? JNI_ERR : JNI_OK;
}

static void JNICALL set_int_region(JNIEnv *environment, jintArray receiver,
    jsize start, jsize count, const jint *values)
{
    touch(environment, false);
    require(receiver == object(&array_identity) && start == 0 && count == PIXELS && values != NULL,
        "array publisher changed its complete region");
    require(!mock.runtime_live && !mock.runtime_class_live && !mock.array_class_live,
        "JNI local reference survived into numerical publication");
    require(threads_started > render_thread_baseline && threads_joined == threads_started,
        "array published before every actual numerical worker joined");
    require(atomic_load(&live_attachments) == 0 &&
        atomic_load(&attached_workers) == threads_started - render_thread_baseline &&
        atomic_load(&detached_workers) == atomic_load(&attached_workers) &&
        atomic_load(&priority_calls) == atomic_load(&attached_workers) &&
        atomic_load(&worker_refs_created) == atomic_load(&worker_refs_deleted),
        "array published before all owned worker priority/cleanup completed");
    memcpy(mock.output, values, sizeof(mock.output));
    mock.publishes++;
}

static const struct JNINativeInterface_ functions = {
    .FindClass = find_class,
    .GetStaticMethodID = get_static_method,
    .CallStaticObjectMethod = call_static_object,
    .GetMethodID = get_method,
    .CallIntMethod = call_int,
    .ExceptionCheck = exception_check,
    .ExceptionClear = exception_clear,
    .DeleteLocalRef = delete_local,
    .IsInstanceOf = is_instance,
    .GetArrayLength = array_length,
    .GetJavaVM = get_virtual_machine,
    .SetIntArrayRegion = set_int_region
};
static JNIEnv test_environment = &functions;

int __real_pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *);
int __real_pthread_join(pthread_t, void **);

int __wrap_pthread_create(pthread_t *thread, const pthread_attr_t *attributes,
    void *(*entry)(void *), void *state)
{
    require(pthread_equal(pthread_self(), mock.caller) != 0, "worker launched another worker");
    const int status = __real_pthread_create(thread, attributes, entry, state);
    if (status == 0) threads_started++;
    return status;
}

int __wrap_pthread_join(pthread_t thread, void **result)
{
    require(pthread_equal(pthread_self(), mock.caller) != 0, "worker performed the caller join");
    const int status = __real_pthread_join(thread, result);
    if (status == 0) threads_joined++;
    return status;
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
    if (expect_owned_workers) {
        worker_touch(&worker.environment, false);
        require(worker.priority_set && !worker.class_live && !worker.object_live,
            "numerical work began before priority setup/local cleanup");
        worker.in_numerical = true;
        atomic_fetch_add(&numerical_tiles, 1);
    }
    const surfer_status status = __real_surfer_render_orthographic_tile(scene, width, height,
        x_start, y_start, x_end, y_end, camera_height, yaw, pitch, zoom,
        quality, cancellation, pixels, capacity);
    if (expect_owned_workers) {
        worker_touch(&worker.environment, false);
        require(worker.in_numerical && worker.priority_set, "worker attachment/priority ended during numerical work");
        worker.in_numerical = false;
    }
    return status;
}

static void balanced(void)
{
    require(!mock.runtime_class_live && !mock.runtime_live && !mock.array_class_live &&
        mock.references_created == mock.references_deleted, "JNI local references are unbalanced");
    require(atomic_load(&live_attachments) == 0 &&
        atomic_load(&attached_workers) == atomic_load(&detached_workers) &&
        atomic_load(&worker_refs_created) == atomic_load(&worker_refs_deleted) &&
        atomic_load(&foreign_detaches) == 0, "owned/foreign worker attachment or local reference cleanup failed");
}

static void reset(jint count, unsigned stage, enum fault_kind fault)
{
    balanced();
    require(threads_started == threads_joined, "previous invocation left an unjoined worker");
    memset(&mock, 0, sizeof(mock));
    mock.caller = pthread_self();
    mock.count = count;
    mock.next_stage = 1;
    mock.fault_stage = stage;
    mock.fault = fault;
    for (size_t index = 0; index < PIXELS; index++) mock.output[index] = sentinel;
    render_thread_baseline = threads_started;
    expect_owned_workers = false;
    worker_fault_stage = 0; worker_fault = NO_FAULT;
    fail_detach = false; foreign_attachment = false; fail_get_env = false;
    fail_attach = false; fail_get_vm = false;
    caller_vm_queries = 0;
    atomic_store(&attached_workers, 0); atomic_store(&detached_workers, 0);
    atomic_store(&live_attachments, 0);
    atomic_store(&worker_refs_created, 0); atomic_store(&worker_refs_deleted, 0);
    atomic_store(&priority_calls, 0); atomic_store(&numerical_tiles, 0);
    atomic_store(&cleared_worker_exceptions, 0); atomic_store(&foreign_detaches, 0);
    atomic_store(&failed_worker_steps, 0);
}

static void unchanged_output(void)
{
    require(mock.publishes == 0, "rejected query published an array");
    for (size_t index = 0; index < PIXELS; index++)
        require(mock.output[index] == sentinel, "rejected query changed caller output");
}

static void empty_owners(void)
{
    require(surfer_render_session_test_live_sessions() == 0 &&
        surfer_render_session_test_live_epochs() == 0 &&
        surfer_render_session_test_live_allocations() == 0, "native session ownership leaked");
    require(surfer_surface_test_live_snapshots() == 0 && surfer_surface_test_live_borrows() == 0 &&
        surfer_surface_test_live_allocations() == 0, "native surface ownership leaked");
}

static void exception_preserved(unsigned stage, enum fault_kind fault)
{
    const unsigned expected = fault == EXCEPTION_NULL || fault == EXCEPTION_VALUE ? 100U + stage : 0;
    require(mock.exception_identity == expected, "pending query exception was replaced or cleared");
    require(mock.query_calls == stage, "query continued after the failing JNI stage");
    balanced();
}

static surfer_surface_handle make_surface(void)
{
    static const int32_t offsets[5] = {0, 5, 7, 9, 11};
    static const double coefficients[11] = {-1, 1, 1, 2, 1, 2, 2, 2, 2, 2, 2};
    static const int32_t xyz[33] = {
        0,0,0, 0,0,2, 0,2,0, 1,1,1, 2,0,0,
        0,1,1, 1,0,0, 0,1,0, 1,0,1, 0,0,1, 1,1,0
    };
    surfer_surface_handle handle = 0;
    require(surfer_surface_create_copied(1, 3, offsets, 5, coefficients, 11, xyz, 33, &handle) ==
        SURFER_OK && handle > 0, "Cayley prepared-surface setup failed");
    return handle;
}

static void direct_query(void)
{
    test_case = "direct query input and scalar admission";
    reset(4, 0, NO_FAULT);
    require(!platform_processor_count(&test_environment, NULL) && mock.jni_calls == 0,
        "null scalar output triggered JNI work");
    size_t output = SIZE_MAX;
    mock.exception_identity = 71;
    require(!platform_processor_count(&test_environment, &output) && output == SIZE_MAX &&
        mock.query_calls == 0 && mock.exception_identity == 71, "entry exception was not preserved");
    const jint counts[] = {1, 2, 4, 8, INT32_MAX};
    for (size_t index = 0; index < sizeof(counts) / sizeof(counts[0]); index++) {
        reset(counts[index], 0, NO_FAULT);
        output = SIZE_MAX;
        require(platform_processor_count(&test_environment, &output) && output == (size_t)counts[index] &&
            mock.query_calls == 5 && mock.exception_identity == 0, "positive Int32 count was not copied exactly");
        balanced();
    }
    for (jint count = -1; count <= 0; count++) {
        reset(count, 0, NO_FAULT);
        output = SIZE_MAX;
        require(!platform_processor_count(&test_environment, &output) && output == SIZE_MAX &&
            mock.query_calls == 5, "nonpositive count changed scalar output");
        balanced();
    }
    for (unsigned stage = 1; stage <= 5; stage++)
        for (enum fault_kind fault = NULL_RESULT; fault <= EXCEPTION_VALUE; fault++) {
            if (stage == 5 && fault != EXCEPTION_VALUE) continue;
            reset(4, stage, fault);
            output = SIZE_MAX;
            require(!platform_processor_count(&test_environment, &output) && output == SIZE_MAX,
                "failed query changed scalar output or reported success");
            exception_preserved(stage, fault);
        }
    empty_owners();
    puts("PASS direct Runtime query scalar values faults pending exceptions and local references");
}

static void create_refusals(void)
{
    test_case = "real createRenderSession query refusals";
    for (unsigned stage = 1; stage <= 5; stage++)
        for (enum fault_kind fault = NULL_RESULT; fault <= EXCEPTION_VALUE; fault++) {
            if (stage == 5 && fault != EXCEPTION_VALUE) continue;
            reset(8, stage, fault);
            const jlong result = Java_Idric_Generated_createRenderSession(&test_environment, NULL);
            require(result == (fault == NULL_RESULT ? -SURFER_INVALID_INPUT : 0), "create query refusal status");
            require(surfer_session_jni_test_create_attempts() == 0, "failed query acquired native create storage");
            exception_preserved(stage, fault);
            unchanged_output();
            empty_owners();
        }
    for (jint count = -1; count <= 0; count++) {
        reset(count, 0, NO_FAULT);
        require(Java_Idric_Generated_createRenderSession(&test_environment, NULL) == -SURFER_INVALID_INPUT &&
            surfer_session_jni_test_create_attempts() == 0, "create admitted nonpositive processors");
        balanced(); empty_owners();
    }
    reset(4, 0, NO_FAULT);
    mock.exception_identity = 72;
    require(Java_Idric_Generated_createRenderSession(&test_environment, NULL) == 0 &&
        mock.exception_identity == 72 && mock.query_calls == 0 &&
        surfer_session_jni_test_create_attempts() == 0, "create changed its entry exception");
    balanced(); empty_owners();
    puts("PASS real create query refusals allocate no native owners");
}

static jint render(jlong session, jlong epoch, jlong surface)
{
    expect_owned_workers = true;
    const jint status = Java_Idric_Generated_renderSessionSurface(&test_environment, NULL,
        session, epoch, surface, WIDTH, HEIGHT, 1, 2.15, 0, 0, 1, object(&array_identity));
    expect_owned_workers = false;
    return status;
}

static void render_refusal(unsigned stage, enum fault_kind fault, jint count, bool entry_exception)
{
    reset(count, stage, fault);
    surfer_render_session_handle session = 0;
    surfer_render_epoch epoch = 0;
    require(surfer_render_session_create_for_processors(4, &session) == SURFER_OK &&
        surfer_render_session_begin(session, &epoch) == SURFER_OK, "render refusal session setup");
    const surfer_surface_handle surface = make_surface();
    const size_t allocated = surfer_render_session_test_live_allocations();
    if (entry_exception) mock.exception_identity = 73;
    require(render(session, epoch, surface) == SURFER_INVALID_INPUT, "render query refusal status");
    if (entry_exception) require(mock.exception_identity == 73 && mock.query_calls == 0,
        "render changed its entry exception");
    else if (stage != 0) exception_preserved(stage, fault);
    else require(mock.exception_identity == 0 && mock.query_calls == 5, "render count refusal query");
    balanced(); unchanged_output();
    require(surfer_session_jni_test_render_attempts() == 0 && threads_started == render_thread_baseline &&
        surfer_render_session_test_live_allocations() == allocated && surfer_surface_test_live_borrows() == 0,
        "rejected query acquired staging, workers or surface borrows");
    require(surfer_render_session_release(session) == SURFER_OK && surfer_surface_release(surface) == SURFER_OK,
        "render refusal cleanup failed");
    empty_owners();
}

static void render_refusals(void)
{
    test_case = "real renderSessionSurface query refusals";
    for (unsigned stage = 1; stage <= 5; stage++)
        for (enum fault_kind fault = NULL_RESULT; fault <= EXCEPTION_VALUE; fault++) {
            if (stage == 5 && fault != EXCEPTION_VALUE) continue;
            render_refusal(stage, fault, 8, false);
        }
    render_refusal(0, NO_FAULT, 0, false);
    render_refusal(0, NO_FAULT, -1, false);
    render_refusal(0, NO_FAULT, 4, true);
    puts("PASS real render query refusals preserve output and acquire no staging or workers");
}

static void success(jint creation_count, jint draw_count)
{
    test_case = "real caller-thread query and publication after actual joins";
    reset(creation_count, 0, NO_FAULT);
    const jlong session = Java_Idric_Generated_createRenderSession(&test_environment, NULL);
    require(session > 0 && mock.query_calls == 5, "successful JNI session creation");
    balanced();
    const jlong epoch = Java_Idric_Generated_beginRenderEpoch(&test_environment, NULL, session);
    require(epoch > 0, "successful JNI epoch creation");
    const surfer_surface_handle surface = make_surface();
    const surfer_scene settings = surfer_default_scene(NULL);
    const surfer_render_quality quality = {SURFER_AA_QUINCUNX, 0.3f};
    uint32_t expected[PIXELS];
    require(surfer_render_session_render_tiled(session, epoch, surface, &settings,
        (size_t)draw_count, WIDTH, HEIGHT, 2.15, 0, 0, 1, quality, expected, PIXELS) == SURFER_OK,
        "native tiled frame setup");
    reset(draw_count, 0, NO_FAULT);
    require(render(session, epoch, surface) == SURFER_OK && mock.query_calls == 5 && mock.publishes == 1,
        "successful JNI draw did not perform a fresh query and publication");
    require(caller_vm_queries == 1 && atomic_load(&numerical_tiles) > 0,
        "successful draw did not acquire one VM or execute attached numerical workers");
    balanced();
    const size_t workers = creation_count < 4 ? (size_t)creation_count : 4U;
    require(threads_started - render_thread_baseline == workers && threads_joined == threads_started,
        "scalar creation-time worker limit or joined-worker count changed");
    bool foreground = false, variation = false;
    for (size_t y = 0; y < HEIGHT; y++) for (size_t x = 0; x < WIDTH; x++) {
        uint32_t actual;
        memcpy(&actual, &mock.output[y * WIDTH + x], sizeof(actual));
        require(actual == expected[(HEIGHT - 1U - y) * WIDTH + x], "JNI publication changed native tile pixels or row orientation");
        foreground = foreground || (actual & UINT32_C(0xff000000)) == UINT32_C(0xff000000);
        variation = variation || mock.output[y * WIDTH + x] != mock.output[0];
    }
    require(foreground && variation, "successful native frame was not a real nonuniform image");
    require(Java_Idric_Generated_releaseRenderSession(&test_environment, NULL, session) == SURFER_OK &&
        surfer_surface_release(surface) == SURFER_OK, "successful JNI ownership cleanup failed");
    balanced(); empty_owners();
}

static void priority_refusal(unsigned stage, enum fault_kind fault, unsigned special)
{
    reset(8, 0, NO_FAULT);
    worker_fault_stage = stage; worker_fault = fault;
    fail_get_env = special == 1;
    foreign_attachment = special == 2;
    fail_attach = special == 3;
    fail_detach = special == 4;
    fail_get_vm = special == 5;
    surfer_render_session_handle session = 0;
    surfer_render_epoch epoch = 0;
    require(surfer_render_session_create_for_processors(8, &session) == SURFER_OK &&
        surfer_render_session_begin(session, &epoch) == SURFER_OK, "worker failure session setup");
    const surfer_surface_handle surface = make_surface();
    require(render(session, epoch, surface) != SURFER_OK, "failed worker startup/cleanup published success");
    require(mock.exception_identity == 0 && caller_vm_queries == 1,
        "worker exception escaped into the caller or VM acquired more than once");
    unchanged_output(); balanced();
    require(threads_started == threads_joined && surfer_surface_test_live_borrows() == 0,
        "worker startup/cleanup failure escaped joins or retained the surface");
    if (stage != 0 || (special >= 1 && special <= 3))
        require(atomic_load(&failed_worker_steps) > 0, "designated worker failure was never observed");
    if (fault == EXCEPTION_NULL || fault == EXCEPTION_VALUE)
        require(atomic_load(&cleared_worker_exceptions) == atomic_load(&failed_worker_steps),
            "owned worker exceptions were not cleared exactly once before detach");
    if (special == 1 || special == 2 || special == 3)
        require(atomic_load(&attached_workers) == 0 && atomic_load(&detached_workers) == 0,
            "failed/foreign attachment was detached as owned");
    if (special == 4)
        require(atomic_load(&detached_workers) > 0, "detach failure was not reached with resources released");
    if (special == 5)
        require(threads_started == render_thread_baseline && surfer_session_jni_test_render_attempts() == 0,
            "failed caller GetJavaVM acquired workers or staging");
    require(surfer_render_session_release(session) == SURFER_OK && surfer_surface_release(surface) == SURFER_OK,
        "worker failure fixture cleanup");
    empty_owners();
}

static void worker_priority_refusals(void)
{
    test_case = "owned worker daemon attachment Thread priority and cleanup refusals";
    for (unsigned stage = 1; stage <= 5; stage++)
        for (enum fault_kind fault = NULL_RESULT; fault <= EXCEPTION_VALUE; fault++) {
            if (stage == 5 && fault != EXCEPTION_VALUE) continue;
            priority_refusal(stage, fault, 0);
        }
    for (unsigned special = 1; special <= 5; special++) priority_refusal(0, NO_FAULT, special);
    puts("PASS worker-owned daemon environments priority startup faults foreign attachments and cleanup failures");
}

int main(void)
{
    direct_query();
    create_refusals();
    render_refusals();
    success(1, 8);
    success(8, 1);
    success(4, 2);
    worker_priority_refusals();
    printf("actual pthread workers started %zu joined %zu\n", threads_started, threads_joined);
    puts("PASS processor query caller thread scalar transfer query faults local references owners and publication after joins");
    puts("PASS owned worker Thread priority attachment through numerical work and cleanup before publication");
    return 0;
}
