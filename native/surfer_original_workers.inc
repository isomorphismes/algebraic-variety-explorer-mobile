/* Original task partition with bounded private workers. Included by the
 * synchronous session owner. Numerical code has no JNI/platform types;
 * optional worker hooks own any thread-local platform startup and cleanup.
 */
#ifdef SURFER_RENDER_SESSION_TESTING
typedef surfer_parallel_render_probe parallel_probe;
#else
typedef struct { size_t unused; } parallel_probe;
#endif

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t changed;
    _Atomic bool stopped;
    const surfer_scene *scene;
    const surfer_cancellation *cancellation;
    session_probe *probe;
    parallel_probe *parallel_probe;
    const surfer_render_worker_hooks *hooks;
    size_t width, height, x_step, y_step, y_tiles, tile_count;
    size_t next_work, next_commit, completed_workers, active_workers;
    double camera_height, yaw, pitch, zoom;
    surfer_render_quality quality;
    uint32_t *staging;
    size_t tile_capacity;
    surfer_status status;
} original_worker_queue;

typedef struct {
    original_worker_queue *queue;
    uint32_t *pixels;
} original_worker;

static bool original_workers_cancelled(void *opaque)
{
    original_worker_queue *queue = opaque;
    return queue->stopped || (queue->cancellation != NULL &&
        queue->cancellation->cancelled(queue->cancellation->state));
}

/* queue mutex is held. The first failure invalidates the whole staged frame. */
static void original_workers_fail(original_worker_queue *queue, surfer_status status)
{
    if (queue->status == SURFER_OK) queue->status = status;
    queue->stopped = true;
    (void)pthread_cond_broadcast(&queue->changed);
}

static void *original_numerical_worker(void *opaque)
{
    original_worker *worker = opaque;
    original_worker_queue *queue = worker->queue;
    const surfer_cancellation cancellation = {original_workers_cancelled, queue};
    void *worker_token = NULL;
    surfer_status startup_status = SURFER_OK;
    if (queue->hooks != NULL) {
        startup_status = queue->hooks->start(queue->hooks->state, &worker_token);
        if (startup_status != SURFER_OK) {
            (void)pthread_mutex_lock(&queue->mutex);
            original_workers_fail(queue, startup_status);
            (void)pthread_mutex_unlock(&queue->mutex);
        }
    }
    for (; startup_status == SURFER_OK;) {
        (void)pthread_mutex_lock(&queue->mutex);
        if (queue->status != SURFER_OK || queue->next_work == queue->tile_count) {
            (void)pthread_mutex_unlock(&queue->mutex);
            break;
        }
        const size_t ordinal = queue->next_work++;
        queue->active_workers++;
#ifdef SURFER_RENDER_SESSION_TESTING
        if (queue->parallel_probe != NULL &&
            queue->active_workers > queue->parallel_probe->peak_workers)
            queue->parallel_probe->peak_workers = queue->active_workers;
#endif
        (void)pthread_mutex_unlock(&queue->mutex);
        run_hook(queue->probe, 3);

        const size_t x_start = (ordinal / queue->y_tiles) * queue->x_step;
        const size_t y_start = (ordinal % queue->y_tiles) * queue->y_step;
        const size_t x_end = queue->x_step > queue->width - 1 - x_start
            ? queue->width - 1 : x_start + queue->x_step;
        const size_t y_end = queue->y_step > queue->height - 1 - y_start
            ? queue->height - 1 : y_start + queue->y_step;
        const surfer_status status = surfer_render_orthographic_tile(queue->scene,
            queue->width, queue->height, x_start, y_start, x_end, y_end,
            queue->camera_height, queue->yaw, queue->pitch, queue->zoom,
            queue->quality, &cancellation, worker->pixels, queue->tile_capacity);

        (void)pthread_mutex_lock(&queue->mutex);
        queue->active_workers--;
        if (status != SURFER_OK) original_workers_fail(queue, status);
        while (queue->status == SURFER_OK && queue->next_commit != ordinal) {
            if (pthread_cond_wait(&queue->changed, &queue->mutex) != 0)
                original_workers_fail(queue, SURFER_INVALID_INPUT);
        }
        if (queue->status == SURFER_OK && original_workers_cancelled(queue))
            original_workers_fail(queue, SURFER_CANCELLED);
        if (queue->status == SURFER_OK) {
            /* The same x-major/y-minor submission sequence as original draw.
             * Later original tiles overwrite their inclusive overlaps. A
             * bounded worker retains its packed pixels until this turn.
             */
            const size_t tile_width = x_end - x_start + 1;
            for (size_t y = y_start; y <= y_end; ++y)
                memcpy(&queue->staging[y * queue->width + x_start],
                    &worker->pixels[(y - y_start) * tile_width],
                    tile_width * sizeof(*worker->pixels));
            queue->next_commit++;
#ifdef SURFER_RENDER_SESSION_TESTING
            if (queue->parallel_probe != NULL) queue->parallel_probe->committed_tiles++;
#endif
            (void)pthread_cond_broadcast(&queue->changed);
        }
        (void)pthread_mutex_unlock(&queue->mutex);
    }
    if (queue->hooks != NULL) {
        const surfer_status cleanup_status = queue->hooks->finish(queue->hooks->state, worker_token);
        if (cleanup_status != SURFER_OK) {
            (void)pthread_mutex_lock(&queue->mutex);
            original_workers_fail(queue, cleanup_status);
            (void)pthread_mutex_unlock(&queue->mutex);
        }
    }
    /* This is the worker's final access to caller-owned queue/state. The
     * caller waits for all completions and joins every created joinable handle
     * before destroying queue synchronization or returning its stack storage.
     */
    (void)pthread_mutex_lock(&queue->mutex);
    queue->completed_workers++;
    (void)pthread_cond_broadcast(&queue->changed);
    (void)pthread_mutex_unlock(&queue->mutex);
    return NULL;
}

static surfer_status render_original_workers(const surfer_scene *scene,
    size_t processors, size_t worker_limit, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, const surfer_cancellation *cancellation,
    uint32_t *staging, session_probe *probe, parallel_probe *parallel,
    const surfer_render_worker_hooks *hooks)
{
    if (processors == 0 || processors > INT32_MAX || worker_limit == 0 || worker_limit > 4 ||
        width < 2 || height < 2 || width > SIZE_MAX / height ||
        width * height > SIZE_MAX / sizeof(*staging)) return SURFER_INVALID_INPUT;
    const size_t horizontal_partitions = processors < 2 ? 2 : processors;
    const size_t x_step = width / (width < horizontal_partitions ? width : horizontal_partitions);
    const size_t y_step = height / (height < 3 ? height : 3);
    const size_t x_tiles = (width - 1) / x_step + 1;
    const size_t y_tiles = (height - 1) / y_step + 1;
    if (x_tiles > SIZE_MAX / y_tiles || x_step + 1 > SIZE_MAX / (y_step + 1))
        return SURFER_INVALID_INPUT;
    original_worker_queue queue = {0};
    queue.stopped = false;
    queue.scene = scene;
    queue.cancellation = cancellation;
    queue.probe = probe;
    queue.parallel_probe = parallel;
    queue.hooks = hooks;
    queue.width = width; queue.height = height;
    queue.x_step = x_step; queue.y_step = y_step; queue.y_tiles = y_tiles;
    queue.tile_count = x_tiles * y_tiles;
    queue.camera_height = camera_height; queue.yaw = yaw; queue.pitch = pitch; queue.zoom = zoom;
    queue.quality = quality; queue.staging = staging;
    queue.tile_capacity = (x_step + 1) * (y_step + 1);
    queue.status = SURFER_OK;
    if (pthread_mutex_init(&queue.mutex, NULL) != 0) return SURFER_OUT_OF_MEMORY;
    if (pthread_cond_init(&queue.changed, NULL) != 0) {
        (void)pthread_mutex_destroy(&queue.mutex);
        return SURFER_OUT_OF_MEMORY;
    }
    original_worker workers[4] = {{0}};
    pthread_t threads[4];
    size_t started = 0;
    const size_t count = worker_limit < queue.tile_count ? worker_limit : queue.tile_count;
    for (size_t index = 0; index < count; ++index) {
        workers[index].queue = &queue;
        workers[index].pixels = allocate(queue.tile_capacity * sizeof(uint32_t), STAGING_ALLOCATION, probe);
        if (workers[index].pixels == NULL) { queue.status = SURFER_OUT_OF_MEMORY; break; }
    }
    if (queue.status == SURFER_OK) {
        for (size_t index = 0; index < count; ++index) {
            int failed = 0;
#ifdef SURFER_RENDER_SESSION_TESTING
            if (parallel != NULL && parallel->fail_thread_at == index) failed = 1;
#endif
            if (!failed) failed = pthread_create(&threads[index], NULL,
                original_numerical_worker, &workers[index]);
            if (failed != 0) {
                (void)pthread_mutex_lock(&queue.mutex);
                original_workers_fail(&queue, SURFER_OUT_OF_MEMORY);
                (void)pthread_mutex_unlock(&queue.mutex);
                break;
            }
            started++;
#ifdef SURFER_RENDER_SESSION_TESTING
            if (parallel != NULL) parallel->threads_started++;
#endif
        }
    }
    (void)pthread_mutex_lock(&queue.mutex);
    while (queue.completed_workers != started) {
        if (pthread_cond_wait(&queue.changed, &queue.mutex) != 0)
            original_workers_fail(&queue, SURFER_INVALID_INPUT);
    }
    (void)pthread_mutex_unlock(&queue.mutex);
    for (size_t index = 0; index < started; ++index)
        if (pthread_join(threads[index], NULL) != 0) queue.status = SURFER_INVALID_INPUT;
    /* No worker can still touch buffers/queue after the completion barrier. */
    for (size_t index = 0; index < count; ++index)
        deallocate(workers[index].pixels, STAGING_ALLOCATION);
    if (pthread_cond_destroy(&queue.changed) != 0) queue.status = SURFER_INVALID_INPUT;
    if (pthread_mutex_destroy(&queue.mutex) != 0) queue.status = SURFER_INVALID_INPUT;
    return queue.status;
}
