#include "surfer_render_session.h"

#include <limits.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

typedef struct render_session render_session;
typedef struct render_epoch render_epoch;
struct render_epoch {
    surfer_render_epoch identity;
    _Atomic bool cancelled;
    size_t active;
};
struct render_session {
    surfer_render_session_handle identity;
    bool open;
    size_t active;
    render_epoch *current;
    render_session *next;
};

/* All identity/current/refcount state uses this mutex. The only value read by
 * the numerical predicate is its retained epoch's atomic boolean. No 64-bit
 * atomics or stdatomic.h macros are used. Lock order is session -> surface;
 * the surface store does not call this owner.
 */
static pthread_mutex_t registry_mutex = PTHREAD_MUTEX_INITIALIZER;
static render_session *sessions;
static int64_t next_identity = 1;

typedef enum { SESSION_ALLOCATION, EPOCH_ALLOCATION, STAGING_ALLOCATION } allocation_kind;
#ifdef SURFER_RENDER_SESSION_TESTING
typedef surfer_render_session_probe session_probe;
static pthread_mutex_t allocation_mutex = PTHREAD_MUTEX_INITIALIZER;
static size_t live_allocations[3];
#else
typedef struct { size_t unused; } session_probe;
#endif

static void *allocate(size_t bytes, allocation_kind kind, session_probe *probe)
{
#ifdef SURFER_RENDER_SESSION_TESTING
    if (probe != NULL) {
        const size_t attempt = probe->attempts;
        if (attempt == SIZE_MAX) return NULL;
        probe->attempts++;
        if (attempt == probe->fail_at) return NULL;
    }
#else
    (void)probe;
    (void)kind;
#endif
    void *value = malloc(bytes);
#ifdef SURFER_RENDER_SESSION_TESTING
    if (value != NULL) {
        (void)pthread_mutex_lock(&allocation_mutex);
        live_allocations[kind]++;
        (void)pthread_mutex_unlock(&allocation_mutex);
    }
#endif
    return value;
}

static void deallocate(void *value, allocation_kind kind)
{
#ifdef SURFER_RENDER_SESSION_TESTING
    if (value != NULL) {
        (void)pthread_mutex_lock(&allocation_mutex);
        live_allocations[kind]--;
        (void)pthread_mutex_unlock(&allocation_mutex);
    }
#else
    (void)kind;
#endif
    free(value);
}

/* registry_mutex is held for every following registry helper. */
static render_session *find_session(surfer_render_session_handle identity)
{
    for (render_session *session = sessions; session != NULL; session = session->next)
        if (session->identity == identity) return session;
    return NULL;
}

static void unlink_session(render_session *session)
{
    render_session **link = &sessions;
    while (*link != NULL && *link != session) link = &(*link)->next;
    if (*link == session) *link = session->next;
}

static bool is_current_locked(const render_session *session, const render_epoch *epoch)
{
    return session->open && session->current == epoch && !epoch->cancelled;
}

static surfer_status create_session(surfer_render_session_handle *result, session_probe *probe)
{
    if (result == NULL) return SURFER_INVALID_INPUT;
    render_session *session = allocate(sizeof(*session), SESSION_ALLOCATION, probe);
    if (session == NULL) return SURFER_OUT_OF_MEMORY;
    *session = (render_session){0};
    if (pthread_mutex_lock(&registry_mutex) != 0) {
        deallocate(session, SESSION_ALLOCATION);
        return SURFER_INVALID_INPUT;
    }
    surfer_status status = SURFER_OK;
    if (next_identity == INT64_MAX) status = SURFER_OUT_OF_MEMORY;
    else {
        session->identity = next_identity++;
        session->open = true;
        session->next = sessions;
        sessions = session;
        *result = session->identity;
    }
    (void)pthread_mutex_unlock(&registry_mutex);
    if (status != SURFER_OK) deallocate(session, SESSION_ALLOCATION);
    return status;
}

surfer_status surfer_render_session_create(surfer_render_session_handle *result)
{
    return create_session(result, NULL);
}

static surfer_status begin_epoch(
    surfer_render_session_handle identity, surfer_render_epoch *result, session_probe *probe)
{
    if (identity <= 0 || result == NULL) return SURFER_INVALID_INPUT;
    render_epoch *epoch = allocate(sizeof(*epoch), EPOCH_ALLOCATION, probe);
    if (epoch == NULL) return SURFER_OUT_OF_MEMORY;
    epoch->identity = 0;
    epoch->cancelled = false;
    epoch->active = 0;
    if (pthread_mutex_lock(&registry_mutex) != 0) {
        deallocate(epoch, EPOCH_ALLOCATION);
        return SURFER_INVALID_INPUT;
    }
    render_session *session = find_session(identity);
    render_epoch *retired = NULL;
    surfer_status status = SURFER_OK;
    if (session == NULL || !session->open) status = SURFER_INVALID_INPUT;
    else if (next_identity == INT64_MAX) status = SURFER_OUT_OF_MEMORY;
    else {
        epoch->identity = next_identity++;
        retired = session->current;
        if (retired != NULL) {
            retired->cancelled = true;
            if (retired->active != 0) retired = NULL;
        }
        session->current = epoch;
        *result = epoch->identity;
    }
    (void)pthread_mutex_unlock(&registry_mutex);
    if (status != SURFER_OK) deallocate(epoch, EPOCH_ALLOCATION);
    deallocate(retired, EPOCH_ALLOCATION);
    return status;
}

surfer_status surfer_render_session_begin(
    surfer_render_session_handle session, surfer_render_epoch *epoch)
{
    return begin_epoch(session, epoch, NULL);
}

surfer_status surfer_render_session_cancel(surfer_render_session_handle identity)
{
    if (identity <= 0) return SURFER_INVALID_INPUT;
    if (pthread_mutex_lock(&registry_mutex) != 0) return SURFER_INVALID_INPUT;
    render_session *session = find_session(identity);
    const surfer_status status = session == NULL || !session->open ?
        SURFER_INVALID_INPUT : SURFER_OK;
    if (status == SURFER_OK && session->current != NULL) session->current->cancelled = true;
    (void)pthread_mutex_unlock(&registry_mutex);
    return status;
}

surfer_status surfer_render_session_release(surfer_render_session_handle identity)
{
    if (identity <= 0) return SURFER_INVALID_INPUT;
    if (pthread_mutex_lock(&registry_mutex) != 0) return SURFER_INVALID_INPUT;
    render_session *session = find_session(identity);
    render_epoch *retired = NULL;
    const surfer_status status = session == NULL || !session->open ?
        SURFER_INVALID_INPUT : SURFER_OK;
    if (status == SURFER_OK) {
        session->open = false;
        retired = session->current;
        session->current = NULL;
        if (retired != NULL) {
            retired->cancelled = true;
            if (retired->active != 0) retired = NULL;
        }
        if (session->active == 0) unlink_session(session);
        else session = NULL;
    } else session = NULL;
    (void)pthread_mutex_unlock(&registry_mutex);
    deallocate(retired, EPOCH_ALLOCATION);
    deallocate(session, SESSION_ALLOCATION);
    return status;
}

surfer_status surfer_render_session_current(
    surfer_render_session_handle identity, surfer_render_epoch epoch, bool *current)
{
    if (identity <= 0 || epoch <= 0 || current == NULL) return SURFER_INVALID_INPUT;
    if (pthread_mutex_lock(&registry_mutex) != 0) return SURFER_INVALID_INPUT;
    render_session *session = find_session(identity);
    *current = session != NULL && session->current != NULL &&
        session->current->identity == epoch && is_current_locked(session, session->current);
    (void)pthread_mutex_unlock(&registry_mutex);
    return SURFER_OK;
}

static surfer_status retain_epoch(
    surfer_render_session_handle identity, surfer_render_epoch epoch_identity,
    render_session **owner, render_epoch **work)
{
    if (pthread_mutex_lock(&registry_mutex) != 0) return SURFER_INVALID_INPUT;
    render_session *session = find_session(identity);
    render_epoch *epoch = session == NULL ? NULL : session->current;
    surfer_status status;
    if (epoch == NULL || epoch->identity != epoch_identity || !is_current_locked(session, epoch))
        status = SURFER_CANCELLED;
    else if (session->active == SIZE_MAX || epoch->active == SIZE_MAX)
        status = SURFER_OUT_OF_MEMORY;
    else {
        session->active++;
        epoch->active++;
        *owner = session;
        *work = epoch;
        status = SURFER_OK;
    }
    (void)pthread_mutex_unlock(&registry_mutex);
    return status;
}

typedef struct {
    render_epoch *epoch;
    session_probe *probe;
} cancellation_state;

static bool epoch_cancelled(void *opaque)
{
    cancellation_state *state = opaque;
    const bool cancelled = state->epoch->cancelled;
#ifdef SURFER_RENDER_SESSION_TESTING
    if (state->probe != NULL) {
        if (state->probe->cancellation_checks != SIZE_MAX) state->probe->cancellation_checks++;
        if (cancelled && state->probe->observed_cancellation != SIZE_MAX)
            state->probe->observed_cancellation++;
    }
#endif
    return cancelled;
}

static void run_hook(session_probe *probe, int phase)
{
#ifdef SURFER_RENDER_SESSION_TESTING
    if (probe != NULL && probe->hook != NULL)
        probe->hook(probe->state, (surfer_render_session_test_phase)phase);
#else
    (void)probe;
    (void)phase;
#endif
}

static surfer_status finish_render(
    render_session *session, render_epoch *epoch, surfer_surface_borrow *borrow,
    bool borrowed, uint32_t *staging, size_t count, surfer_render_session_publisher publish,
    void *publish_state, surfer_status status)
{
    if (pthread_mutex_lock(&registry_mutex) != 0) {
        if (borrowed) (void)surfer_surface_end_borrow(borrow->token);
        deallocate(staging, STAGING_ALLOCATION);
        return SURFER_INVALID_INPUT;
    }
    const bool publish_current = is_current_locked(session, epoch);
    if (!publish_current) status = SURFER_CANCELLED;
    /* Finish the surface lifetime before publication so no cleanup failure can
     * be returned after modifying caller pixels. The core has finished using
     * its immutable view. This lock order is session -> surface, never reverse.
     */
    if (borrowed) {
        const surfer_status ended = surfer_surface_end_borrow(borrow->token);
        if (status == SURFER_OK && ended != SURFER_OK) status = ended;
    }
    if (status == SURFER_OK) status = publish(publish_state, staging, count);
    epoch->active--;
    session->active--;
    render_epoch *retired_epoch = epoch->active == 0 && session->current != epoch ? epoch : NULL;
    render_session *retired_session = NULL;
    if (!session->open && session->active == 0) {
        unlink_session(session);
        retired_session = session;
    }
    (void)pthread_mutex_unlock(&registry_mutex);
    deallocate(staging, STAGING_ALLOCATION);
    deallocate(retired_epoch, EPOCH_ALLOCATION);
    deallocate(retired_session, SESSION_ALLOCATION);
    return status;
}

static surfer_status render_publish(
    surfer_render_session_handle identity, surfer_render_epoch epoch_identity,
    surfer_surface_handle surface, const surfer_scene *settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    surfer_render_session_publisher publish, void *publish_state, size_t capacity, session_probe *probe)
{
    if (identity <= 0 || epoch_identity <= 0 || surface <= 0 || settings == NULL || publish == NULL ||
        width < 2 || height < 2 || width > SIZE_MAX / height ||
        width * height > SIZE_MAX / sizeof(uint32_t) || capacity < width * height)
        return SURFER_INVALID_INPUT;
    const size_t count = width * height;
    const size_t bytes = count * sizeof(uint32_t);
    render_session *session = NULL;
    render_epoch *epoch = NULL;
    surfer_status status = retain_epoch(identity, epoch_identity, &session, &epoch);
    if (status != SURFER_OK) return status;
    surfer_surface_borrow borrow = {0};
    status = surfer_surface_begin_borrow(surface, &borrow);
    if (status != SURFER_OK)
        return finish_render(session, epoch, &borrow, false, NULL, count, publish, publish_state, status);
    run_hook(probe, 1);
    uint32_t *staging = allocate(bytes, STAGING_ALLOCATION, probe);
    if (staging == NULL)
        return finish_render(session, epoch, &borrow, true, NULL, count, publish, publish_state,
            SURFER_OUT_OF_MEMORY);
    surfer_scene scene = *settings;
    scene.surface = borrow.surface;
    cancellation_state state = {epoch, probe};
    const surfer_cancellation cancellation = {epoch_cancelled, &state};
    status = surfer_render_orthographic_cancellable(&scene, width, height, camera_height,
        yaw, pitch, zoom, quality, &cancellation, staging, count);
    run_hook(probe, 2);
    return finish_render(session, epoch, &borrow, true, staging, count, publish, publish_state, status);
}

static surfer_status copy_pixels(void *destination, uint32_t *pixels, size_t count)
{
    memcpy(destination, pixels, count * sizeof(*pixels));
    return SURFER_OK;
}

surfer_status surfer_render_session_render_publish(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    surfer_render_session_publisher publish, void *publish_state, size_t capacity)
{
    return render_publish(session, epoch, surface, settings, width, height, camera_height,
        yaw, pitch, zoom, quality, publish, publish_state, capacity, NULL);
}

surfer_status surfer_render_session_render(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    uint32_t *pixels, size_t capacity)
{
    if (pixels == NULL) return SURFER_INVALID_INPUT;
    return render_publish(session, epoch, surface, settings, width, height, camera_height,
        yaw, pitch, zoom, quality, copy_pixels, pixels, capacity, NULL);
}

#ifdef SURFER_RENDER_SESSION_TESTING
surfer_status surfer_render_session_test_create(
    surfer_render_session_handle *session, surfer_render_session_probe *probe)
{
    return create_session(session, probe);
}

surfer_status surfer_render_session_test_begin(
    surfer_render_session_handle session, surfer_render_epoch *epoch,
    surfer_render_session_probe *probe)
{
    return begin_epoch(session, epoch, probe);
}

surfer_status surfer_render_session_test_render(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    uint32_t *pixels, size_t capacity, surfer_render_session_probe *probe)
{
    if (pixels == NULL) return SURFER_INVALID_INPUT;
    return render_publish(session, epoch, surface, settings, width, height, camera_height,
        yaw, pitch, zoom, quality, copy_pixels, pixels, capacity, probe);
}

surfer_status surfer_render_session_test_render_publish(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    surfer_render_session_publisher publish, void *publish_state, size_t capacity,
    surfer_render_session_probe *probe)
{
    return render_publish(session, epoch, surface, settings, width, height, camera_height,
        yaw, pitch, zoom, quality, publish, publish_state, capacity, probe);
}

static size_t live_count(int kind)
{
    (void)pthread_mutex_lock(&allocation_mutex);
    const size_t count = kind < 0 ? live_allocations[0] + live_allocations[1] + live_allocations[2] :
        live_allocations[kind];
    (void)pthread_mutex_unlock(&allocation_mutex);
    return count;
}
size_t surfer_render_session_test_live_sessions(void) { return live_count(SESSION_ALLOCATION); }
size_t surfer_render_session_test_live_epochs(void) { return live_count(EPOCH_ALLOCATION); }
size_t surfer_render_session_test_live_allocations(void) { return live_count(-1); }
#endif
