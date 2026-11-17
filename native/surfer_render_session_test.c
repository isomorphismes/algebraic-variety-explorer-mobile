#define _POSIX_C_SOURCE 200809L
#include "surfer_render_session.h"

#include <errno.h>
#include <limits.h>
#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

enum { WIDTH = 7, HEIGHT = 5, PIXELS = WIDTH * HEIGHT };
static const uint32_t sentinel = UINT32_C(0x12345678);
static const surfer_render_quality quality = {SURFER_AA_QUINCUNX, 0.3f};
static const int32_t offsets[5] = {0, 4, 5, 6, 7};
static const double coefficients[7] = {-0.64, 1.0, 1.0, 1.0, 2.0, 2.0, 2.0};
static const int32_t xyz[21] = {
    0,0,0, 0,0,2, 0,2,0, 2,0,0, 1,0,0, 0,1,0, 0,0,1
};

static void require(bool condition, const char *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL render session: %s\n", message);
        exit(1);
    }
}

static void fill_sentinel(uint32_t *pixels)
{
    for (size_t i = 0; i < PIXELS; ++i) pixels[i] = sentinel;
}

static void unchanged(const uint32_t *pixels, const char *message)
{
    for (size_t i = 0; i < PIXELS; ++i) require(pixels[i] == sentinel, message);
}

static void empty_owners(void)
{
    require(surfer_render_session_test_live_sessions() == 0 &&
        surfer_render_session_test_live_epochs() == 0 &&
        surfer_render_session_test_live_allocations() == 0, "session allocations not balanced");
    require(surfer_surface_test_live_snapshots() == 0 && surfer_surface_test_live_borrows() == 0 &&
        surfer_surface_test_live_allocations() == 0, "surface ownership not balanced");
}

static surfer_surface_handle surface(void)
{
    surfer_surface_handle value = -91;
    require(surfer_surface_create_copied(1, 2, offsets, 5, coefficients, 7, xyz, 21, &value) ==
        SURFER_OK && value > 0, "surface creation");
    return value;
}

static surfer_scene settings(void)
{
    surfer_scene scene = surfer_default_scene(NULL);
    scene.light_count = 0;
    scene.front_material.ambient_intensity = 1.0f;
    scene.back_material = scene.front_material;
    return scene;
}

static void new_session(surfer_render_session_handle *session, surfer_render_epoch *epoch)
{
    require(surfer_render_session_create(session) == SURFER_OK && *session > 0, "session creation");
    require(surfer_render_session_begin(*session, epoch) == SURFER_OK && *epoch > 0 &&
        *epoch != *session, "epoch creation");
}

static bool current(surfer_render_session_handle session, surfer_render_epoch epoch)
{
    bool result = false;
    require(surfer_render_session_current(session, epoch, &result) == SURFER_OK, "currentness status");
    return result;
}

static void reference_frame(surfer_surface_handle handle, uint32_t *pixels)
{
    surfer_surface_borrow borrow;
    require(surfer_surface_begin_borrow(handle, &borrow) == SURFER_OK, "reference borrow");
    surfer_scene scene = settings();
    scene.surface = borrow.surface;
    require(surfer_render_orthographic_quality(&scene, WIDTH, HEIGHT, 2.15, 0, 0, 1,
        quality, pixels, PIXELS) == SURFER_OK, "reference render");
    require(surfer_surface_end_borrow(borrow.token) == SURFER_OK, "reference borrow release");
}

static surfer_status render(
    surfer_render_session_handle session, surfer_render_epoch epoch, surfer_surface_handle handle,
    uint32_t *pixels, surfer_render_session_probe *probe)
{
    const surfer_scene scene = settings();
    return surfer_render_session_test_render(session, epoch, handle, &scene,
        WIDTH, HEIGHT, 2.15, 0, 0, 1, quality, pixels, PIXELS, probe);
}

static void identities_and_success(void)
{
    surfer_render_session_handle first, second;
    surfer_render_epoch old, fresh, other;
    new_session(&first, &old);
    new_session(&second, &other);
    require(first != second && old != other && first != other && second != old, "IDs reused");
    require(current(first, old) && current(second, other), "new epoch not current");
    require(!current(first, other) && !current(second, old), "cross-session epoch became current");
    require(!current(INT64_MAX, old) && !current(first, INT64_MAX), "unknown identity became current");
    bool result = true;
    require(surfer_render_session_current(0, old, &result) == SURFER_INVALID_INPUT && result,
        "malformed query changed output");
    require(surfer_render_session_begin(first, &fresh) == SURFER_OK && fresh != old,
        "advance epoch");
    require(!current(first, old) && current(first, fresh), "old epoch became current again");
    const surfer_surface_handle handle = surface();
    uint32_t pixels[PIXELS], expected[PIXELS];
    fill_sentinel(pixels);
    surfer_render_session_probe stale = {.fail_at = SIZE_MAX};
    require(render(first, old, handle, pixels, &stale) == SURFER_CANCELLED && stale.attempts == 0,
        "stale queued work started");
    unchanged(pixels, "stale work modified output");
    require(render(first, other, handle, pixels, NULL) == SURFER_CANCELLED,
        "cross-session render accepted");
    unchanged(pixels, "cross-session work modified output");
    reference_frame(handle, expected);
    surfer_render_session_probe complete = {.fail_at = SIZE_MAX};
    require(render(first, fresh, handle, pixels, &complete) == SURFER_OK &&
        complete.cancellation_checks > 1 && complete.observed_cancellation == 0,
        "current render failed or did not poll");
    require(memcmp(pixels, expected, sizeof(pixels)) == 0, "successful pixels changed");
    require(surfer_surface_test_live_borrows() == 0, "successful render retained surface borrow");
    require(surfer_render_session_cancel(first) == SURFER_OK &&
        surfer_render_session_cancel(first) == SURFER_OK && !current(first, fresh), "cancel idempotence");
    require(surfer_render_session_release(first) == SURFER_OK &&
        surfer_render_session_release(first) == SURFER_INVALID_INPUT, "safe double release");
    require(!current(first, fresh), "closed session still current");
    require(surfer_render_session_release(second) == SURFER_OK &&
        surfer_surface_release(handle) == SURFER_OK, "success cleanup");
    empty_owners();
}

static void faults_and_bad_requests(void)
{
    surfer_render_session_handle session = -91;
    surfer_render_session_probe failed_create = {.fail_at = 0};
    require(surfer_render_session_test_create(&session, &failed_create) == SURFER_OUT_OF_MEMORY &&
        session == -91 && failed_create.attempts == 1, "session allocation failure");
    empty_owners();
    surfer_render_epoch epoch, unchanged_epoch = -91;
    new_session(&session, &epoch);
    surfer_render_session_probe failed_begin = {.fail_at = 0};
    require(surfer_render_session_test_begin(session, &unchanged_epoch, &failed_begin) ==
        SURFER_OUT_OF_MEMORY && unchanged_epoch == -91 && current(session, epoch),
        "failed begin retired old epoch");
    const surfer_surface_handle handle = surface();
    uint32_t pixels[PIXELS];
    fill_sentinel(pixels);
    surfer_render_session_probe failed_staging = {.fail_at = 0};
    require(render(session, epoch, handle, pixels, &failed_staging) == SURFER_OUT_OF_MEMORY &&
        failed_staging.attempts == 1, "staging allocation failure");
    unchanged(pixels, "allocation failure published output");
    require(surfer_surface_test_live_borrows() == 0 && current(session, epoch),
        "failed render lost ownership");
    const surfer_scene scene = settings();
    require(surfer_render_session_render(session, epoch, handle, &scene,
        SIZE_MAX, 2, 2.15, 0, 0, 1, quality, pixels, SIZE_MAX) == SURFER_INVALID_INPUT,
        "pixel product overflow accepted");
    require(surfer_render_session_render(session, epoch, handle, &scene,
        WIDTH, HEIGHT, 2.15, 0, 0, 1, quality, pixels, PIXELS - 1) == SURFER_INVALID_INPUT,
        "short capacity accepted");
    require(surfer_render_session_render(session, epoch, handle, &scene,
        WIDTH, HEIGHT, NAN, 0, 0, 1, quality, pixels, PIXELS) == SURFER_INVALID_INPUT,
        "numerical validation failure lost");
    require(render(session, epoch, INT64_MAX, pixels, NULL) == SURFER_INVALID_INPUT,
        "invalid surface accepted");
    require(render(0, epoch, handle, pixels, NULL) == SURFER_INVALID_INPUT,
        "malformed session accepted");
    unchanged(pixels, "invalid request published output");
    require(surfer_surface_test_live_borrows() == 0, "failure retained surface borrow");
    require(surfer_render_session_release(session) == SURFER_OK &&
        surfer_surface_release(handle) == SURFER_OK, "fault cleanup");
    empty_owners();
}

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t changed;
    bool ready;
    bool proceed;
    surfer_render_session_test_phase phase;
} pause_point;

static void pause_hook(void *opaque, surfer_render_session_test_phase phase)
{
    pause_point *pause = opaque;
    if (phase != pause->phase) return;
    require(pthread_mutex_lock(&pause->mutex) == 0, "hook mutex");
    pause->ready = true;
    require(pthread_cond_broadcast(&pause->changed) == 0, "hook signal");
    while (!pause->proceed)
        require(pthread_cond_wait(&pause->changed, &pause->mutex) == 0, "hook wait");
    require(pthread_mutex_unlock(&pause->mutex) == 0, "hook unlock");
}

static void await_pause(pause_point *pause)
{
    struct timespec deadline;
    require(clock_gettime(CLOCK_REALTIME, &deadline) == 0, "test deadline");
    deadline.tv_sec += 30;
    require(pthread_mutex_lock(&pause->mutex) == 0, "wait mutex");
    while (!pause->ready) {
        const int status = pthread_cond_timedwait(&pause->changed, &pause->mutex, &deadline);
        require(status != ETIMEDOUT, "worker failed before synchronization hook");
        require(status == 0, "test wait");
    }
    require(pthread_mutex_unlock(&pause->mutex) == 0, "wait unlock");
}

static void resume(pause_point *pause)
{
    require(pthread_mutex_lock(&pause->mutex) == 0, "resume mutex");
    pause->proceed = true;
    require(pthread_cond_broadcast(&pause->changed) == 0, "resume signal");
    require(pthread_mutex_unlock(&pause->mutex) == 0, "resume unlock");
}

typedef struct {
    surfer_render_session_handle session;
    surfer_render_epoch epoch;
    surfer_surface_handle surface;
    uint32_t pixels[PIXELS];
    surfer_render_session_probe probe;
    surfer_status status;
} work;

static void *worker(void *opaque)
{
    work *request = opaque;
    request->status = render(request->session, request->epoch, request->surface,
        request->pixels, &request->probe);
    return NULL;
}

enum action { CANCEL, ADVANCE, RELEASE, RELEASE_SURFACE };

static void concurrent_action(surfer_render_session_test_phase phase, enum action action)
{
    work request = {0};
    new_session(&request.session, &request.epoch);
    request.surface = surface();
    fill_sentinel(request.pixels);
    uint32_t expected[PIXELS];
    if (action == RELEASE_SURFACE) reference_frame(request.surface, expected);
    pause_point pause = {.mutex = PTHREAD_MUTEX_INITIALIZER,
        .changed = PTHREAD_COND_INITIALIZER, .phase = phase};
    request.probe = (surfer_render_session_probe){.fail_at = SIZE_MAX,
        .hook = pause_hook, .state = &pause};
    pthread_t thread;
    require(pthread_create(&thread, NULL, worker, &request) == 0, "worker creation");
    await_pause(&pause);
    require(surfer_surface_test_live_borrows() == 1, "surface not retained through work");
    surfer_render_epoch fresh = 0;
    if (action == CANCEL) require(surfer_render_session_cancel(request.session) == SURFER_OK, "active cancel");
    if (action == ADVANCE) require(surfer_render_session_begin(request.session, &fresh) == SURFER_OK, "active advance");
    if (action == RELEASE) {
        require(surfer_render_session_release(request.session) == SURFER_OK, "active release");
        require(surfer_render_session_test_live_sessions() == 1 &&
            surfer_render_session_test_live_epochs() == 1, "active release freed retained state");
    }
    if (action == RELEASE_SURFACE) {
        require(surfer_surface_release(request.surface) == SURFER_OK, "active surface release");
        require(surfer_surface_test_live_snapshots() == 1, "active surface freed too soon");
    }
    resume(&pause);
    require(pthread_join(thread, NULL) == 0, "worker join");
    if (action == RELEASE_SURFACE) {
        require(request.status == SURFER_OK && memcmp(request.pixels, expected, sizeof(expected)) == 0,
            "surface release broke active render borrow");
        require(surfer_surface_test_live_snapshots() == 0, "retired surface survived final borrow");
    } else {
        require(request.status == SURFER_CANCELLED, phase == SURFER_SESSION_BEFORE_PUBLISH ?
            "final currentness gate accepted stale frame" : "stale/closed active render was not cancelled");
        unchanged(request.pixels, "cancelled/stale render published pixels");
        if (phase == SURFER_SESSION_AFTER_RETAINS)
            require(request.probe.cancellation_checks == 1 && request.probe.observed_cancellation == 1,
                "epoch flag did not stop first numerical cancellation poll");
        else
            require(request.probe.cancellation_checks > 1 && request.probe.observed_cancellation == 0,
                "before-publish cancellation did not follow completed numerical work");
        require(surfer_surface_release(request.surface) == SURFER_OK, "cancel surface cleanup");
    }
    if (action != RELEASE) {
        if (action == ADVANCE) require(current(request.session, fresh), "new epoch lost currentness");
        require(surfer_render_session_release(request.session) == SURFER_OK, "active session cleanup");
    }
    require(!current(request.session, request.epoch), "retired epoch became current");
    require(pthread_cond_destroy(&pause.changed) == 0 && pthread_mutex_destroy(&pause.mutex) == 0,
        "test synchronization cleanup");
    empty_owners();
}

static void multiple_active_calls(void)
{
    work first = {0}, second = {0};
    new_session(&first.session, &first.epoch);
    first.surface = surface();
    second.session = first.session;
    second.epoch = first.epoch;
    second.surface = first.surface;
    fill_sentinel(first.pixels);
    fill_sentinel(second.pixels);
    pause_point a = {.mutex = PTHREAD_MUTEX_INITIALIZER, .changed = PTHREAD_COND_INITIALIZER,
        .phase = SURFER_SESSION_AFTER_RETAINS};
    pause_point b = {.mutex = PTHREAD_MUTEX_INITIALIZER, .changed = PTHREAD_COND_INITIALIZER,
        .phase = SURFER_SESSION_AFTER_RETAINS};
    first.probe = (surfer_render_session_probe){.fail_at = SIZE_MAX, .hook = pause_hook, .state = &a};
    second.probe = (surfer_render_session_probe){.fail_at = SIZE_MAX, .hook = pause_hook, .state = &b};
    pthread_t one, two;
    require(pthread_create(&one, NULL, worker, &first) == 0 &&
        pthread_create(&two, NULL, worker, &second) == 0, "shared-epoch workers");
    await_pause(&a);
    await_pause(&b);
    require(surfer_surface_test_live_borrows() == 2, "shared-epoch surface retains missing");
    require(surfer_render_session_release(first.session) == SURFER_OK &&
        surfer_surface_release(first.surface) == SURFER_OK, "shared-epoch release");
    resume(&a);
    require(pthread_join(one, NULL) == 0, "first shared-epoch join");
    require(surfer_render_session_test_live_sessions() == 1 &&
        surfer_render_session_test_live_epochs() == 1 && surfer_surface_test_live_borrows() == 1 &&
        surfer_surface_test_live_snapshots() == 1, "first return freed another active call's owners");
    resume(&b);
    require(pthread_join(two, NULL) == 0, "second shared-epoch join");
    require(first.status == SURFER_CANCELLED && second.status == SURFER_CANCELLED &&
        first.probe.cancellation_checks == 1 && second.probe.cancellation_checks == 1 &&
        first.probe.observed_cancellation == 1 && second.probe.observed_cancellation == 1,
        "shared-epoch cancellation did not stop both numerical calls");
    unchanged(first.pixels, "first shared-epoch call published");
    unchanged(second.pixels, "second shared-epoch call published");
    require(pthread_cond_destroy(&a.changed) == 0 && pthread_mutex_destroy(&a.mutex) == 0 &&
        pthread_cond_destroy(&b.changed) == 0 && pthread_mutex_destroy(&b.mutex) == 0,
        "shared-epoch synchronization cleanup");
    empty_owners();
}

typedef struct {
    uint32_t pixels[PIXELS];
    size_t calls;
    bool fail;
} publication;

static surfer_status publish(void *opaque, uint32_t *pixels, size_t count)
{
    publication *result = opaque;
    require(count == PIXELS, "publisher received wrong element count");
    result->calls++;
    if (result->fail) return SURFER_OUT_OF_MEMORY;
    memcpy(result->pixels, pixels, count * sizeof(*pixels));
    return SURFER_OK;
}

static void publication_contract(void)
{
    surfer_render_session_handle session;
    surfer_render_epoch epoch;
    new_session(&session, &epoch);
    const surfer_surface_handle handle = surface();
    const surfer_scene scene = settings();
    publication result = {.fail = true};
    fill_sentinel(result.pixels);
    require(surfer_render_session_render_publish(session, epoch, handle, &scene,
        WIDTH, HEIGHT, 2.15, 0, 0, 1, quality, publish, &result, PIXELS) == SURFER_OUT_OF_MEMORY &&
        result.calls == 1, "publisher failure status lost");
    unchanged(result.pixels, "publisher failure changed output");
    result.fail = false;
    uint32_t expected[PIXELS];
    reference_frame(handle, expected);
    require(surfer_render_session_render_publish(session, epoch, handle, &scene,
        WIDTH, HEIGHT, 2.15, 0, 0, 1, quality, publish, &result, PIXELS) == SURFER_OK &&
        result.calls == 2 && memcmp(result.pixels, expected, sizeof(expected)) == 0,
        "synchronous publisher changed successful output");
    require(surfer_render_session_release(session) == SURFER_OK &&
        surfer_surface_release(handle) == SURFER_OK, "publication cleanup");
    empty_owners();
}

enum { ADVANCES = 128 };
typedef struct {
    surfer_render_session_handle session;
    surfer_render_epoch epochs[ADVANCES];
} advances;

static void *advance_repeatedly(void *opaque)
{
    advances *work = opaque;
    for (size_t i = 0; i < ADVANCES; ++i) {
        require(surfer_render_session_begin(work->session, &work->epochs[i]) == SURFER_OK,
            "concurrent repeated begin failed");
        (void)current(work->session, work->epochs[i]);
    }
    return NULL;
}

static void concurrent_advances(void)
{
    surfer_render_session_handle session;
    surfer_render_epoch initial;
    new_session(&session, &initial);
    advances first = {.session = session}, second = {.session = session};
    pthread_t a, b;
    require(pthread_create(&a, NULL, advance_repeatedly, &first) == 0 &&
        pthread_create(&b, NULL, advance_repeatedly, &second) == 0, "advance workers");
    require(pthread_join(a, NULL) == 0 && pthread_join(b, NULL) == 0, "advance joins");
    require(!current(session, initial), "initial epoch resurrected");
    for (size_t i = 0; i < ADVANCES; ++i) {
        require(first.epochs[i] > initial && second.epochs[i] > initial, "nonmonotonic epoch ID");
        for (size_t j = 0; j < ADVANCES; ++j)
            require(first.epochs[i] != second.epochs[j], "concurrent epoch ID reused");
        if (i > 0) require(first.epochs[i] > first.epochs[i - 1] &&
            second.epochs[i] > second.epochs[i - 1], "thread epoch order reversed");
    }
    require(surfer_render_session_release(session) == SURFER_OK, "advance cleanup");
    empty_owners();
}

int main(void)
{
    empty_owners();
    identities_and_success();
    faults_and_bad_requests();
    for (enum action action = CANCEL; action <= RELEASE; action++) {
        concurrent_action(SURFER_SESSION_AFTER_RETAINS, action);
        concurrent_action(SURFER_SESSION_BEFORE_PUBLISH, action);
    }
    concurrent_action(SURFER_SESSION_AFTER_RETAINS, RELEASE_SURFACE);
    multiple_active_calls();
    publication_contract();
    concurrent_advances();
    puts("SURFER cooperative render sessions, publication and ownership: PASS");
    return 0;
}
