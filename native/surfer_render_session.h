/* Opaque synchronous render-session identities and transactional publication. */
#ifndef SURFER_RENDER_SESSION_H
#define SURFER_RENDER_SESSION_H

#include "surfer_surface_store.h"

typedef int64_t surfer_render_session_handle;
typedef int64_t surfer_render_epoch;

/* IDs are positive, never reused, and are not addresses/security capabilities.
 * Outputs change only on OK. A successful begin cancels the old epoch before
 * returning the new one; allocation failure leaves the old epoch current.
 */
surfer_status surfer_render_session_create(surfer_render_session_handle *session);
/* Original numerical pool limit is fixed at creation: min(4, processors).
 * The platform adapter supplies the actual Runtime.availableProcessors value;
 * numerical host tests inject it explicitly. */
surfer_status surfer_render_session_create_for_processors(
    size_t processors, surfer_render_session_handle *session);
surfer_status surfer_render_session_begin(
    surfer_render_session_handle session, surfer_render_epoch *epoch);
surfer_status surfer_render_session_cancel(surfer_render_session_handle session);
surfer_status surfer_render_session_release(surfer_render_session_handle session);

/* Any positive pair may be queried: unknown/stale/closed/cross-session pairs
 * return OK/false. Nonpositive IDs or a missing result pointer are invalid.
 * UI completion must repeat this check when its callback actually executes.
 */
surfer_status surfer_render_session_current(
    surfer_render_session_handle session, surfer_render_epoch epoch, bool *current);

/* Retain the exact session/epoch and copied surface during numerical work.
 * scene_settings->surface is ignored. Every non-OK result leaves caller pixels
 * unchanged. Rendering uses private staging and a final currentness check under
 * the session lock before copying the complete frame. Positive noncurrent pairs
 * return CANCELLED; malformed tokens/request dimensions return INVALID_INPUT.
 * Caller storage/settings must remain valid and unchanged for the whole call.
 */
surfer_status surfer_render_session_render(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *scene_settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    uint32_t *argb_pixels, size_t pixel_capacity);

typedef surfer_status (*surfer_render_session_publisher)(
    void *state, uint32_t *pixels, size_t count);

/* Optional platform startup/cleanup on each newly created numerical worker.
 * No platform types enter the numerical owner. finish runs once after every
 * attempted start, including partial startup failure and cancellation. The
 * private token belongs only to that worker; state remains borrowed until all
 * workers have finished and joined. Either failure rejects whole publication.
 */
typedef struct {
    surfer_status (*start)(void *state, void **worker_token);
    surfer_status (*finish)(void *state, void *worker_token);
    void *state;
} surfer_render_worker_hooks;

/* Synchronous internal publication under the session lock after the final
 * currentness check. Pixels are a unique mutable staging borrow; the publisher
 * may rearrange them in place, but must not reenter session APIs or retain the
 * borrowed pixels/state. It owns its output and must leave that output unchanged when
 * returning non-OK. Session/epoch retains remain live through publication;
 * the surface borrow ends after tracing, before commit. This lets JNI copy a
 * complete primitive-array region without a cancel gap after returning here.
 */
surfer_status surfer_render_session_render_publish(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *scene_settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    surfer_render_session_publisher publish, void *publish_state, size_t pixel_capacity);

/* Original overlapping tile partition, private tile buffers, at most the
 * creation-time pool limit, deterministic submission-order tile composition.
 * processors is queried afresh for this draw; it controls the original xStep.
 * Every numerical worker joins before the locked whole-frame publisher runs.
 */
surfer_status surfer_render_session_render_tiled_publish(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *scene_settings,
    size_t processors, size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    surfer_render_session_publisher publish, void *publish_state, size_t pixel_capacity);

surfer_status surfer_render_session_render_tiled_publish_with_hooks(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *scene_settings,
    size_t processors, size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    surfer_render_session_publisher publish, void *publish_state, size_t pixel_capacity,
    const surfer_render_worker_hooks *hooks);

surfer_status surfer_render_session_render_tiled(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *scene_settings,
    size_t processors, size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    uint32_t *argb_pixels, size_t pixel_capacity);

#ifdef SURFER_RENDER_SESSION_TESTING
typedef enum {
    SURFER_SESSION_AFTER_RETAINS = 1,
    SURFER_SESSION_BEFORE_PUBLISH = 2,
    SURFER_SESSION_TILE_STARTED = 3
} surfer_render_session_test_phase;

/* Per-call fault and synchronization state; no global injection settings.
 * Own nonzero session/epoch/staging allocations are counted. The existing
 * surface-store and core fault suites cover their separate allocations.
 * Counters are worker-owned and may be inspected after that call has joined.
 */
typedef struct {
    size_t fail_at;
    size_t attempts;
    size_t cancellation_checks;
    size_t observed_cancellation;
    void (*hook)(void *state, surfer_render_session_test_phase phase);
    void *state;
} surfer_render_session_probe;

surfer_status surfer_render_session_test_create(
    surfer_render_session_handle *session, surfer_render_session_probe *probe);
surfer_status surfer_render_session_test_create_for_processors(
    size_t processors, surfer_render_session_handle *session, surfer_render_session_probe *probe);
surfer_status surfer_render_session_test_begin(
    surfer_render_session_handle session, surfer_render_epoch *epoch,
    surfer_render_session_probe *probe);
surfer_status surfer_render_session_test_render(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *scene_settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    uint32_t *argb_pixels, size_t pixel_capacity, surfer_render_session_probe *probe);
surfer_status surfer_render_session_test_render_publish(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *scene_settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    surfer_render_session_publisher publish, void *publish_state, size_t pixel_capacity,
    surfer_render_session_probe *probe);
size_t surfer_render_session_test_live_sessions(void);
size_t surfer_render_session_test_live_epochs(void);
size_t surfer_render_session_test_live_allocations(void);

typedef struct {
    size_t fail_thread_at; /* SIZE_MAX disables thread-start fault injection. */
    size_t threads_started;
    size_t peak_workers;
    size_t committed_tiles;
} surfer_parallel_render_probe;

surfer_status surfer_render_session_test_render_tiled_publish(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *scene_settings,
    size_t processors, size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    surfer_render_session_publisher publish, void *publish_state, size_t pixel_capacity,
    surfer_render_session_probe *probe, surfer_parallel_render_probe *parallel_probe);

surfer_status surfer_render_session_test_render_tiled_publish_with_hooks(
    surfer_render_session_handle session, surfer_render_epoch epoch,
    surfer_surface_handle surface, const surfer_scene *scene_settings,
    size_t processors, size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    surfer_render_session_publisher publish, void *publish_state, size_t pixel_capacity,
    surfer_render_session_probe *probe, surfer_parallel_render_probe *parallel_probe,
    const surfer_render_worker_hooks *hooks);
#endif

#endif
