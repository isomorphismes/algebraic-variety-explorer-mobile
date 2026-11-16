/* Host JNI-table observation of the actual Runtime query and native owners.
 * Official JNI headers define the interface; the table below is test input,
 * not a replacement production adapter or a platform/ART implementation. */
#define _POSIX_C_SOURCE 200809L
#if !defined(SURFER_RENDER_SESSION_JNI_TESTING) || !defined(SURFER_RENDER_SESSION_TESTING) || !defined(SURFER_SURFACE_STORE_TESTING)
#error "processor query observation requires all three test-only owner interfaces"
#endif
#include "android/render_session_jni.c"

#include <pthread.h>
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

static void require(bool condition, const char *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL processor query: %s: %s\n", test_case, message);
        exit(1);
    }
}

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

static void balanced(void)
{
    require(!mock.runtime_class_live && !mock.runtime_live && !mock.array_class_live &&
        mock.references_created == mock.references_deleted, "JNI local references are unbalanced");
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
    return Java_Idric_Generated_renderSessionSurface(&test_environment, NULL,
        session, epoch, surface, WIDTH, HEIGHT, 1, 2.15, 0, 0, 1, object(&array_identity));
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

int main(void)
{
    direct_query();
    create_refusals();
    render_refusals();
    success(1, 8);
    success(8, 1);
    success(4, 2);
    printf("actual pthread workers started %zu joined %zu\n", threads_started, threads_joined);
    puts("PASS processor query caller thread scalar transfer query faults local references owners and publication after joins");
    return 0;
}
