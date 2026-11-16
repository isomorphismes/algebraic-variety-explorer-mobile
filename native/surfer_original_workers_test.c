#define _POSIX_C_SOURCE 200809L
#include "surfer_render_session.h"
#include <errno.h>
#include <inttypes.h>
#include <limits.h>
#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

enum { MAX_SIDE = 128, MAX_PIXELS = MAX_SIDE * MAX_SIDE, SMALL_WIDTH = 7,
    SMALL_HEIGHT = 5, SMALL_PIXELS = SMALL_WIDTH * SMALL_HEIGHT };
static const uint32_t untouched_pixel = UINT32_C(0x12345678);
static char worker_frame[100] = "ownership tests";

static void require(bool condition, const char *reason)
{
    if (!condition) {
        (void)fflush(stdout);
        fprintf(stderr,"FAIL original workers: %s %s\n",worker_frame,reason);
        exit(1);
    }
}

static void no_owners(void)
{
    require(surfer_render_session_test_live_sessions() == 0 &&
        surfer_render_session_test_live_epochs() == 0 &&
        surfer_render_session_test_live_allocations() == 0,"session owners leaked");
    require(surfer_surface_test_live_snapshots() == 0 && surfer_surface_test_live_borrows() == 0 &&
        surfer_surface_test_live_allocations() == 0,"surface owners leaked");
}

static void fill(uint32_t *pixels, size_t count)
{
    for (size_t index = 0; index < count; ++index) pixels[index] = untouched_pixel;
}

static void unmodified(const uint32_t *pixels, size_t count)
{
    for (size_t index = 0; index < count; ++index)
        require(pixels[index] == untouched_pixel,"failed/stale work published output");
}

static surfer_surface_handle copy_surface(const surfer_prepared_surface *prepared)
{
    double coefficients[4 * 256];
    int32_t xyz[4 * 256 * 3], offsets[5] = {0};
    const surfer_sparse_polynomial values[] = {prepared->surface,prepared->gradient_x,
        prepared->gradient_y,prepared->gradient_z};
    size_t count = 0;
    for (size_t component = 0; component < 4; ++component) {
        require(values[component].term_count <= 256,"prepared polynomial too large");
        for (size_t term = 0; term < values[component].term_count; ++term) {
            const surfer_term value = values[component].terms[term];
            coefficients[count] = value.coefficient;
            xyz[count * 3] = value.x_exponent;
            xyz[count * 3 + 1] = value.y_exponent;
            xyz[count * 3 + 2] = value.z_exponent;
            count++;
        }
        offsets[component + 1] = (int32_t)count;
    }
    surfer_surface_handle handle = -1;
    require(surfer_surface_create_copied(1,prepared->family_degree,offsets,5,coefficients,count,
        xyz,count * 3,&handle) == SURFER_OK && handle > 0,"copied surface creation");
    return handle;
}

static surfer_surface_handle small_surface(void)
{
    static const surfer_term surface[] = {{-0.64,0,0,0},{1,0,0,2},{1,0,2,0},{1,2,0,0}};
    static const surfer_term dx[] = {{2,1,0,0}}, dy[] = {{2,0,1,0}}, dz[] = {{2,0,0,1}};
    const surfer_prepared_surface prepared = {2,{surface,4},{dx,1},{dy,1},{dz,1}};
    return copy_surface(&prepared);
}

static void new_session(size_t processors, surfer_render_session_handle *session, surfer_render_epoch *epoch)
{
    require(surfer_render_session_create_for_processors(processors,session) == SURFER_OK && *session > 0,
        "processor-bound session creation");
    require(surfer_render_session_begin(*session,epoch) == SURFER_OK && *epoch > 0,"epoch creation");
}

typedef struct {
    uint32_t pixels[MAX_PIXELS];
    size_t count, calls;
    bool refuse;
} publication;

static surfer_status publish(void *opaque, uint32_t *pixels, size_t count)
{
    publication *result = opaque;
    require(count == result->count,"publisher element count");
    result->calls++;
    if (result->refuse) return SURFER_OUT_OF_MEMORY;
    memcpy(result->pixels,pixels,count * sizeof(*pixels));
    return SURFER_OK;
}

static surfer_status small_render(surfer_render_session_handle session,surfer_render_epoch epoch,
    surfer_surface_handle surface,size_t processors,publication *result,
    surfer_render_session_probe *probe,surfer_parallel_render_probe *parallel)
{
    const surfer_scene scene = surfer_default_scene(NULL);
    const surfer_render_quality quality = {SURFER_AA_QUINCUNX,0.3f};
    return surfer_render_session_test_render_tiled_publish(session,epoch,surface,&scene,processors,
        SMALL_WIDTH,SMALL_HEIGHT,2.15,0.43,-0.71,1,quality,publish,result,SMALL_PIXELS,probe,parallel);
}

static void reference_corpus(const char *path,size_t processors)
{
    FILE *input = fopen(path,"r");
    require(input != NULL,"ordered reference missing");
    surfer_term terms[4][256];
    surfer_prepared_surface prepared = {0};
    surfer_render_quality quality = {0};
    size_t width = 0,height = 0,frames = 0,observations = 0,frame_observations = 0,expected_tiles = 0;
    double yaw = 0,pitch = 0,zoom = 0;
    publication result = {0};
    uint32_t public_pixels[MAX_PIXELS];
    surfer_surface_handle surface = 0;
    surfer_render_session_handle session = 0;
    surfer_render_epoch epoch = 0;
    surfer_parallel_render_probe parallel = {0};
    char line[2048],tag[40],identity[100],formula[512],pattern[32];
    while (fgets(line,sizeof(line),input) != NULL) {
        require(strchr(line,'\n') != NULL && sscanf(line,"%39s",tag) == 1,"reference record");
        if (strcmp(tag,"frame") == 0) {
            require(surface == 0 && session == 0,"preceding frame not finalized");
            unsigned threshold;
            require(sscanf(line,"%*s%99s%511s%31s%x%zu%zu%la%la%la",worker_frame,formula,pattern,
                &threshold,&width,&height,&yaw,&pitch,&zoom) == 9 && width >= 2 && height >= 2 &&
                width <= MAX_SIDE && height <= MAX_SIDE,"frame header");
            prepared = (surfer_prepared_surface){0};
            memcpy(&quality.threshold,&threshold,sizeof(quality.threshold));
            quality.pattern = strcmp(pattern,"OG_1x1") == 0 ? SURFER_AA_OG_1X1 : SURFER_AA_QUINCUNX;
            require(strcmp(pattern,"OG_1x1") == 0 || strcmp(pattern,"QUINCUNX") == 0,"sample pattern");
            frame_observations = 0;
            frames++;
        } else if (strcmp(tag,"family_degree") == 0) {
            require(sscanf(line,"%*s%99s%" SCNd32,identity,&prepared.family_degree) == 2 &&
                strcmp(identity,worker_frame) == 0,"family degree");
        } else if (strcmp(tag,"input") == 0) {
            unsigned component;
            size_t count;
            require(sscanf(line,"%*s%99s%u%zu",identity,&component,&count) == 3 && component < 4 && count <= 256 &&
                strcmp(identity,worker_frame) == 0,"prepared input");
            surfer_sparse_polynomial *values[] = {&prepared.surface,&prepared.gradient_x,&prepared.gradient_y,&prepared.gradient_z};
            *values[component] = (surfer_sparse_polynomial){terms[component],count};
        } else if (strcmp(tag,"term") == 0) {
            unsigned component;
            size_t ordinal;
            uint64_t bits;
            int32_t x,y,z;
            require(sscanf(line,"%*s%99s%u%zu%" SCNx64 "%" SCNd32 "%" SCNd32 "%" SCNd32,
                identity,&component,&ordinal,&bits,&x,&y,&z) == 7 && component < 4 && ordinal < 256 &&
                strcmp(identity,worker_frame) == 0,"prepared term");
            double coefficient;
            memcpy(&coefficient,&bits,sizeof(coefficient));
            terms[component][ordinal] = (surfer_term){coefficient,x,y,z};
        } else if (strcmp(tag,"ordered_profile") == 0) {
            size_t observed,pool,x_step,y_step;
            require(sscanf(line,"%*s%99s%zu%zu%zu%zu",identity,&observed,&pool,&x_step,&y_step) == 5 &&
                strcmp(identity,worker_frame) == 0 && observed == processors && pool == (processors < 4 ? processors : 4) &&
                x_step == width / (width < (processors < 2 ? 2 : processors) ? width : (processors < 2 ? 2 : processors)) &&
                y_step == height / (height < 3 ? height : 3),
                "actual original processor profile");
            expected_tiles = ((width - 1) / x_step + 1) * ((height - 1) / y_step + 1);
            surface = copy_surface(&prepared);
            new_session(processors,&session,&epoch);
            result = (publication){.count = width * height};
            fill(result.pixels,result.count);
            parallel = (surfer_parallel_render_probe){.fail_thread_at = SIZE_MAX};
            surfer_render_session_probe probe = {.fail_at = SIZE_MAX};
            const surfer_scene scene = surfer_default_scene(NULL);
            fill(public_pixels,result.count);
            require(surfer_render_session_render_tiled(session,epoch,surface,&scene,processors,
                width,height,2.15,yaw,pitch,zoom,quality,public_pixels,result.count) == SURFER_OK,
                "public tiled render");
            require(surfer_render_session_test_render_tiled_publish(session,epoch,surface,&scene,processors,
                width,height,2.15,yaw,pitch,zoom,quality,publish,&result,result.count,&probe,&parallel) == SURFER_OK &&
                result.calls == 1,"parallel original render/publication");
            require(parallel.threads_started == pool && parallel.peak_workers <= pool &&
                parallel.peak_workers > 0 && parallel.committed_tiles == expected_tiles,"bounded pool and tile commit count");
        } else if (strcmp(tag,"ordered_pixel") == 0) {
            size_t x,y;
            uint32_t expected;
            require(sscanf(line,"%*s%99s%zu%zu%" SCNx32,identity,&x,&y,&expected) == 4 &&
                strcmp(identity,worker_frame) == 0 && x == frame_observations % width &&
                y == frame_observations / width && frame_observations < result.count,"ordered pixel record");
            if (result.pixels[frame_observations] != expected || public_pixels[frame_observations] != expected) {
                fprintf(stderr,"pixel %zu,%zu actual %08" PRIx32 " expected %08" PRIx32 "\n",x,y,
                    result.pixels[frame_observations],expected);
                require(false,"exact actual original ordered worker pixels");
            }
            printf("worker_argb\t%zu\t%s\t%zu\t%zu\t%08" PRIx32 "\n",processors,worker_frame,x,y,
                result.pixels[frame_observations]);
            frame_observations++; observations++;
        } else if (strcmp(tag,"serial_ordered_match") == 0) {
            unsigned equal;
            require(sscanf(line,"%*s%99s%u",identity,&equal) == 2 && equal == 1 &&
                strcmp(identity,worker_frame) == 0 && frame_observations == width * height,"actual original serial match");
            require(surfer_surface_release(surface) == SURFER_OK &&
                surfer_render_session_release(session) == SURFER_OK,"frame ownership cleanup");
            surface = session = 0;
            no_owners();
        } else {
            require(strcmp(tag,"pixel") == 0 || strcmp(tag,"tile") == 0 || strcmp(tag,"tile_pixel") == 0 ||
                strcmp(tag,"ordered_difference") == 0 || strcmp(tag,"ordered_summary") == 0,"unknown reference record");
        }
    }
    require(!ferror(input) && fclose(input) == 0 && frames == 44 && observations == 5412 &&
        surface == 0 && session == 0,"processor corpus coverage");
    printf("processor profile %zu exact frames %zu pixels %zu\n",processors,frames,observations);
}

static void faults_and_refusals(void)
{
    strcpy(worker_frame,"faults and refusals");
    surfer_render_session_handle session = -91;
    require(surfer_render_session_create_for_processors(0,&session) == SURFER_INVALID_INPUT && session == -91,
        "zero creation processor count accepted");
    require(surfer_render_session_create_for_processors((size_t)INT32_MAX + 1,&session) == SURFER_INVALID_INPUT &&
        session == -91,"oversized creation processor count accepted");
    surfer_render_session_probe failed_create = {.fail_at = 0};
    require(surfer_render_session_test_create_for_processors(8,&session,&failed_create) == SURFER_OUT_OF_MEMORY &&
        session == -91 && failed_create.attempts == 1,"session allocation refusal");
    no_owners();
    surfer_render_epoch epoch,fresh = -91;
    new_session(8,&session,&epoch);
    const surfer_surface_handle surface = small_surface();
    surfer_render_session_probe failed_begin = {.fail_at = 0};
    require(surfer_render_session_test_begin(session,&fresh,&failed_begin) == SURFER_OUT_OF_MEMORY &&
        fresh == -91,"epoch allocation refusal");
    publication result = {.count = SMALL_PIXELS};
    fill(result.pixels,result.count);
    surfer_render_session_probe probe = {.fail_at = SIZE_MAX};
    surfer_parallel_render_probe parallel = {.fail_thread_at = SIZE_MAX};
    require(small_render(session,epoch,surface,0,&result,&probe,&parallel) == SURFER_INVALID_INPUT &&
        probe.attempts == 0 && result.calls == 0,"zero draw processor count accepted");
    require(small_render(session,epoch,surface,(size_t)INT32_MAX + 1,&result,&probe,&parallel) == SURFER_INVALID_INPUT &&
        probe.attempts == 0 && result.calls == 0,"oversized draw processor count accepted");
    const surfer_scene scene = surfer_default_scene(NULL);
    const surfer_render_quality quality = {SURFER_AA_QUINCUNX,0.3f};
    require(surfer_render_session_render_tiled(session,epoch,surface,&scene,0,SMALL_WIDTH,SMALL_HEIGHT,
        2.15,0.43,-0.71,1,quality,result.pixels,result.count) == SURFER_INVALID_INPUT &&
        surfer_render_session_render_tiled_publish(session,epoch,surface,&scene,0,SMALL_WIDTH,SMALL_HEIGHT,
            2.15,0.43,-0.71,1,quality,publish,&result,result.count) == SURFER_INVALID_INPUT && result.calls == 0,
        "public tiled entry accepted zero processor count");
    unmodified(result.pixels,result.count);
    require(small_render(session,epoch,surface,8,&result,&probe,&parallel) == SURFER_OK && result.calls == 1 &&
        probe.attempts == 5 && parallel.threads_started == 4,"frame/worker allocation baseline");
    const size_t allocations = probe.attempts;
    for (size_t fault = 0; fault < allocations; ++fault) {
        result = (publication){.count = SMALL_PIXELS}; fill(result.pixels,result.count);
        probe = (surfer_render_session_probe){.fail_at = fault};
        parallel = (surfer_parallel_render_probe){.fail_thread_at = SIZE_MAX};
        require(small_render(session,epoch,surface,8,&result,&probe,&parallel) == SURFER_OUT_OF_MEMORY &&
            probe.attempts == fault + 1 && parallel.threads_started == 0 && result.calls == 0,
            "actual frame/worker buffer allocation fault");
        unmodified(result.pixels,result.count);
        require(surfer_surface_test_live_borrows() == 0 && surfer_render_session_test_live_allocations() == 2,
            "allocation failure leaked staged frame or borrow");
    }
    for (size_t thread = 0; thread < 4; ++thread) {
        result = (publication){.count = SMALL_PIXELS}; fill(result.pixels,result.count);
        probe = (surfer_render_session_probe){.fail_at = SIZE_MAX};
        parallel = (surfer_parallel_render_probe){.fail_thread_at = thread};
        require(small_render(session,epoch,surface,8,&result,&probe,&parallel) == SURFER_OUT_OF_MEMORY &&
            parallel.threads_started == thread && parallel.peak_workers <= thread && result.calls == 0,
            "thread-start failure did not join prior workers");
        unmodified(result.pixels,result.count);
        require(surfer_surface_test_live_borrows() == 0 && surfer_render_session_test_live_allocations() == 2,
            "thread-start failure leaked worker state");
    }
    result = (publication){.count = SMALL_PIXELS,.refuse = true}; fill(result.pixels,result.count);
    parallel = (surfer_parallel_render_probe){.fail_thread_at = SIZE_MAX};
    require(small_render(session,epoch,surface,8,&result,NULL,&parallel) == SURFER_OUT_OF_MEMORY &&
        result.calls == 1,"publisher refusal status lost");
    unmodified(result.pixels,result.count);
    require(surfer_surface_release(surface) == SURFER_OK && surfer_render_session_release(session) == SURFER_OK,
        "fault cleanup");
    no_owners();
    printf("parallel fault coverage frame/worker allocations %zu thread-start failures 4\n",allocations);
}

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t changed;
    size_t arrived,target;
    bool released;
    surfer_render_session_test_phase phase;
} four_worker_barrier;

static void barrier_hook(void *opaque,surfer_render_session_test_phase phase)
{
    four_worker_barrier *barrier = opaque;
    if (phase != barrier->phase) return;
    require(pthread_mutex_lock(&barrier->mutex) == 0,"barrier hook lock");
    if (!barrier->released) {
        barrier->arrived++;
        require(barrier->arrived <= barrier->target,"more simultaneous numerical workers than fixed pool");
        require(pthread_cond_broadcast(&barrier->changed) == 0,"barrier hook signal");
        while (!barrier->released)
            require(pthread_cond_wait(&barrier->changed,&barrier->mutex) == 0,"barrier hook wait");
    }
    require(pthread_mutex_unlock(&barrier->mutex) == 0,"barrier hook unlock");
}

static void await_barrier(four_worker_barrier *barrier)
{
    struct timespec deadline;
    require(clock_gettime(CLOCK_REALTIME,&deadline) == 0,"barrier deadline");
    deadline.tv_sec += 15;
    require(pthread_mutex_lock(&barrier->mutex) == 0,"barrier wait lock");
    while (barrier->arrived != barrier->target) {
        const int status = pthread_cond_timedwait(&barrier->changed,&barrier->mutex,&deadline);
        require(status != ETIMEDOUT,"numerical workers failed to reach real concurrency barrier");
        require(status == 0,"barrier timed wait");
    }
    require(pthread_mutex_unlock(&barrier->mutex) == 0,"barrier wait unlock");
}

static void release_barrier(four_worker_barrier *barrier)
{
    require(pthread_mutex_lock(&barrier->mutex) == 0,"barrier release lock");
    barrier->released = true;
    require(pthread_cond_broadcast(&barrier->changed) == 0,"barrier release signal");
    require(pthread_mutex_unlock(&barrier->mutex) == 0,"barrier release unlock");
}

typedef struct {
    surfer_render_session_handle session;
    surfer_render_epoch epoch;
    surfer_surface_handle surface;
    size_t processors;
    publication output;
    surfer_render_session_probe probe;
    surfer_parallel_render_probe parallel;
    surfer_status status;
} active_render;

static void *render_on_thread(void *opaque)
{
    active_render *work = opaque;
    work->status = small_render(work->session,work->epoch,work->surface,work->processors,
        &work->output,&work->probe,&work->parallel);
    return NULL;
}

enum active_action { ACTIVE_CANCEL,ACTIVE_BEGIN,ACTIVE_CLOSE,ACTIVE_RELEASE_SURFACE,ACTIVE_KEEP };

static void concurrent_boundary(size_t creation_processors,size_t draw_processors,enum active_action action)
{
    strcpy(worker_frame,"four-worker ownership and immutable pool");
    active_render work = {.processors = draw_processors,.output = {.count = SMALL_PIXELS},
        .parallel = {.fail_thread_at = SIZE_MAX}};
    new_session(creation_processors,&work.session,&work.epoch);
    work.surface = small_surface();
    fill(work.output.pixels,work.output.count);
    const size_t limit = creation_processors < 4 ? creation_processors : 4;
    four_worker_barrier barrier = {.mutex = PTHREAD_MUTEX_INITIALIZER,.changed = PTHREAD_COND_INITIALIZER,
        .target = limit,.phase = SURFER_SESSION_TILE_STARTED};
    work.probe = (surfer_render_session_probe){.fail_at = SIZE_MAX,.hook = barrier_hook,.state = &barrier};
    pthread_t thread;
    require(pthread_create(&thread,NULL,render_on_thread,&work) == 0,"active render thread creation");
    await_barrier(&barrier);
    require(surfer_surface_test_live_borrows() == 1 && surfer_surface_test_live_snapshots() == 1 &&
        surfer_render_session_test_live_sessions() == 1 && surfer_render_session_test_live_epochs() == 1,
        "four blocked workers lack retained owners");
    surfer_render_epoch fresh = 0;
    if (action == ACTIVE_CANCEL) require(surfer_render_session_cancel(work.session) == SURFER_OK,"active cancel");
    if (action == ACTIVE_BEGIN) require(surfer_render_session_begin(work.session,&fresh) == SURFER_OK &&
        fresh != work.epoch,"active new epoch");
    if (action == ACTIVE_CLOSE) require(surfer_render_session_release(work.session) == SURFER_OK,"active close");
    if (action != ACTIVE_KEEP) {
        require(surfer_surface_release(work.surface) == SURFER_OK,"active surface release");
        require(surfer_surface_test_live_snapshots() == 1 && surfer_surface_test_live_borrows() == 1,
            "surface released before four workers joined");
    }
    release_barrier(&barrier);
    require(pthread_join(thread,NULL) == 0,"active render thread join");
    require(work.parallel.threads_started == limit && work.parallel.peak_workers == limit,
        "draw processor count changed immutable creation-time pool");
    if (action == ACTIVE_CANCEL || action == ACTIVE_BEGIN || action == ACTIVE_CLOSE) {
        require(work.status == SURFER_CANCELLED && work.output.calls == 0 &&
            work.parallel.committed_tiles == 0,"cancelled four-worker frame committed work or published");
        unmodified(work.output.pixels,work.output.count);
    } else require(work.status == SURFER_OK && work.output.calls == 1 && work.parallel.committed_tiles > 0,
        "current worker frame failed or surface release broke retained borrow");
    if (action == ACTIVE_KEEP) require(surfer_surface_release(work.surface) == SURFER_OK,"kept surface cleanup");
    if (action != ACTIVE_CLOSE) require(surfer_render_session_release(work.session) == SURFER_OK,"active session cleanup");
    require(pthread_cond_destroy(&barrier.changed) == 0 && pthread_mutex_destroy(&barrier.mutex) == 0,
        "barrier cleanup");
    no_owners();
    printf("parallel barrier creation processors %zu draw processors %zu simultaneous %zu action %d PASS\n",
        creation_processors,draw_processors,limit,(int)action);
}

static void final_currentness_boundary(enum active_action action)
{
    strcpy(worker_frame,"joined workers final currentness");
    active_render work = {.processors = 8,.output = {.count = SMALL_PIXELS},
        .parallel = {.fail_thread_at = SIZE_MAX}};
    new_session(8,&work.session,&work.epoch);
    work.surface = small_surface();
    fill(work.output.pixels,work.output.count);
    four_worker_barrier barrier = {.mutex = PTHREAD_MUTEX_INITIALIZER,.changed = PTHREAD_COND_INITIALIZER,
        .target = 1,.phase = SURFER_SESSION_BEFORE_PUBLISH};
    work.probe = (surfer_render_session_probe){.fail_at = SIZE_MAX,.hook = barrier_hook,.state = &barrier};
    pthread_t thread;
    require(pthread_create(&thread,NULL,render_on_thread,&work) == 0,"final currentness render thread");
    await_barrier(&barrier);
    surfer_render_epoch fresh = 0;
    if (action == ACTIVE_CANCEL) require(surfer_render_session_cancel(work.session) == SURFER_OK,"final active cancel");
    if (action == ACTIVE_BEGIN) require(surfer_render_session_begin(work.session,&fresh) == SURFER_OK,"final active begin");
    if (action == ACTIVE_CLOSE) require(surfer_render_session_release(work.session) == SURFER_OK,"final active close");
    require(surfer_surface_release(work.surface) == SURFER_OK,"final surface release");
    release_barrier(&barrier);
    require(pthread_join(thread,NULL) == 0,"final currentness join");
    require(work.parallel.threads_started == 4 && work.parallel.committed_tiles > 0 &&
        work.status == SURFER_CANCELLED && work.output.calls == 0,"joined stale worker frame reached publisher");
    unmodified(work.output.pixels,work.output.count);
    if (action != ACTIVE_CLOSE) require(surfer_render_session_release(work.session) == SURFER_OK,"final session cleanup");
    require(pthread_cond_destroy(&barrier.changed) == 0 && pthread_mutex_destroy(&barrier.mutex) == 0,
        "final barrier cleanup");
    no_owners();
    printf("parallel joined-frame currentness action %d PASS\n",(int)action);
}

int main(int argc,char **argv)
{
    require(argc == 5,"four processor reference paths required");
    no_owners();
    const size_t processors[] = {1,2,4,8};
    for (size_t profile = 0; profile < 4; ++profile) reference_corpus(argv[profile + 1],processors[profile]);
    faults_and_refusals();
    for (enum active_action action = ACTIVE_CANCEL; action <= ACTIVE_RELEASE_SURFACE; ++action)
        concurrent_boundary(8,8,action);
    concurrent_boundary(8,1,ACTIVE_KEEP);
    concurrent_boundary(1,8,ACTIVE_KEEP);
    for (enum active_action action = ACTIVE_CANCEL; action <= ACTIVE_CLOSE; ++action)
        final_currentness_boundary(action);
    no_owners();
    puts("PASS original bounded workers processor profiles cancellation faults and retained ownership");
    return 0;
}
