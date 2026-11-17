#include "surfer_surface_store.h"

#include <limits.h>
#include <math.h>
#include <pthread.h>
#include <stdlib.h>

typedef struct snapshot snapshot;
struct snapshot {
    surfer_surface_handle handle;
    bool published;
    size_t borrows;
    surfer_prepared_surface view;
    surfer_term *terms;
    snapshot *next;
};

typedef struct borrow_entry borrow_entry;
struct borrow_entry {
    int64_t token;
    snapshot *owner;
    borrow_entry *next;
};

/* No registry node, mutable reference count or ID generator escapes this file.
 * Numerical workers only receive the immutable view while holding a borrow.
 */
static pthread_mutex_t registry_mutex = PTHREAD_MUTEX_INITIALIZER;
static snapshot *snapshots;
static borrow_entry *borrows;
static int64_t next_identifier = 1;

#ifdef SURFER_SURFACE_STORE_TESTING
typedef surfer_surface_allocation_probe allocation_probe;
/* C17 atomic scalar operators preserve sequential consistency without using
 * the Android NDK stdatomic.h macros, which require Clang-only intrinsics. */
static _Atomic size_t live_allocations;
#else
typedef struct { size_t unused; } allocation_probe;
#endif

static void *allocate(size_t bytes, allocation_probe *probe)
{
#ifdef SURFER_SURFACE_STORE_TESTING
    if (probe != NULL) {
        const size_t attempt = probe->attempts;
        if (attempt == SIZE_MAX) return NULL;
        probe->attempts++;
        if (attempt == probe->fail_at) return NULL;
    }
#else
    (void)probe;
#endif
    void *result = malloc(bytes);
#ifdef SURFER_SURFACE_STORE_TESTING
    if (result != NULL) live_allocations++;
#endif
    return result;
}

static void deallocate(void *value)
{
#ifdef SURFER_SURFACE_STORE_TESTING
    if (value != NULL) live_allocations--;
#endif
    free(value);
}

static void destroy_snapshot(snapshot *value)
{
    if (value == NULL) return;
    deallocate(value->terms);
    deallocate(value);
}

static bool strictly_before(const surfer_term *left, const surfer_term *right)
{
    if (left->x_exponent != right->x_exponent)
        return left->x_exponent < right->x_exponent;
    if (left->y_exponent != right->y_exponent)
        return left->y_exponent < right->y_exponent;
    return left->z_exponent < right->z_exponent;
}

static surfer_sparse_polynomial range(
    const surfer_term *terms, int32_t start, int32_t end)
{
    surfer_sparse_polynomial result;
    result.terms = terms == NULL ? NULL : terms + (size_t)start;
    result.term_count = (size_t)(end - start);
    return result;
}

static surfer_status copy_snapshot(
    int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count,
    snapshot **result, allocation_probe *probe)
{
    /* Int32 array lengths/offsets are the logical transport ABI, including
     * on hosts where size_t is wider. Check products before computing them. */
    if (version != SURFER_PREPARED_SURFACE_ABI_VERSION || family_degree < 0 ||
        offsets == NULL || offset_count != 5 ||
        coefficient_count > (size_t)INT32_MAX / 3U ||
        coefficient_count > SIZE_MAX / sizeof(surfer_term) ||
        xyz_count != coefficient_count * 3U ||
        (coefficient_count != 0 && (coefficients == NULL || xyz == NULL)) ||
        offsets[0] != 0 || offsets[4] != (int32_t)coefficient_count) {
        return SURFER_INVALID_INPUT;
    }
    for (size_t i = 1; i < 5; ++i) {
        if (offsets[i] < offsets[i - 1] || offsets[i] > offsets[4])
            return SURFER_INVALID_INPUT;
    }

    snapshot *value = allocate(sizeof(*value), probe);
    if (value == NULL) return SURFER_OUT_OF_MEMORY;
    *value = (snapshot){0};
    if (coefficient_count != 0) {
        value->terms = allocate(coefficient_count * sizeof(*value->terms), probe);
        if (value->terms == NULL) {
            destroy_snapshot(value);
            return SURFER_OUT_OF_MEMORY;
        }
    }
    for (size_t i = 0; i < coefficient_count; ++i) {
        const int32_t x = xyz[i * 3U];
        const int32_t y = xyz[i * 3U + 1U];
        const int32_t z = xyz[i * 3U + 2U];
        const int64_t degree = (int64_t)x + (int64_t)y + (int64_t)z;
        if (!isfinite(coefficients[i]) || x < 0 || y < 0 || z < 0 ||
            degree > INT32_MAX) {
            destroy_snapshot(value);
            return SURFER_INVALID_INPUT;
        }
        value->terms[i] = (surfer_term){coefficients[i], x, y, z};
    }
    value->view = (surfer_prepared_surface){
        family_degree,
        range(value->terms, offsets[0], offsets[1]),
        range(value->terms, offsets[1], offsets[2]),
        range(value->terms, offsets[2], offsets[3]),
        range(value->terms, offsets[3], offsets[4])
    };
    const surfer_sparse_polynomial polynomials[4] = {
        value->view.surface, value->view.gradient_x,
        value->view.gradient_y, value->view.gradient_z
    };
    for (size_t p = 0; p < 4; ++p) {
        for (size_t i = 1; i < polynomials[p].term_count; ++i) {
            if (!strictly_before(&polynomials[p].terms[i - 1], &polynomials[p].terms[i])) {
                destroy_snapshot(value);
                return SURFER_INVALID_INPUT;
            }
        }
    }
    const surfer_status status = surfer_validate_prepared_surface(&value->view);
    if (status != SURFER_OK) {
        destroy_snapshot(value);
        return status;
    }
    *result = value;
    return SURFER_OK;
}

/* The mutex is held by all following registry helpers. */
static snapshot *find_published(surfer_surface_handle handle)
{
    if (handle <= 0) return NULL;
    for (snapshot *value = snapshots; value != NULL; value = value->next)
        if (value->handle == handle && value->published) return value;
    return NULL;
}

static void unlink_snapshot(snapshot *value)
{
    snapshot **link = &snapshots;
    while (*link != NULL && *link != value) link = &(*link)->next;
    if (*link == value) *link = value->next;
}

static surfer_status create_or_replace(
    bool replacing, surfer_surface_handle previous,
    int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count,
    surfer_surface_handle *handle, allocation_probe *probe)
{
    if (handle == NULL) return SURFER_INVALID_INPUT;
    snapshot *value = NULL;
    surfer_status status = copy_snapshot(version, family_degree, offsets, offset_count,
        coefficients, coefficient_count, xyz, xyz_count, &value, probe);
    if (status != SURFER_OK) return status;

    if (pthread_mutex_lock(&registry_mutex) != 0) {
        destroy_snapshot(value);
        return SURFER_INVALID_INPUT;
    }
    snapshot *old = replacing ? find_published(previous) : NULL;
    if (replacing && old == NULL) status = SURFER_INVALID_INPUT;
    else if (next_identifier == INT64_MAX) status = SURFER_OUT_OF_MEMORY;
    else {
        value->handle = next_identifier++;
        value->published = true;
        value->next = snapshots;
        snapshots = value;
        if (old != NULL) {
            old->published = false;
            if (old->borrows == 0) unlink_snapshot(old);
            else old = NULL;
        }
        *handle = value->handle;
    }
    (void)pthread_mutex_unlock(&registry_mutex);
    if (status != SURFER_OK) destroy_snapshot(value);
    else destroy_snapshot(old);
    return status;
}

surfer_status surfer_surface_create_copied(
    int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count, surfer_surface_handle *handle)
{
    return create_or_replace(false, 0, version, family_degree, offsets, offset_count,
        coefficients, coefficient_count, xyz, xyz_count, handle, NULL);
}

surfer_status surfer_surface_replace_copied(
    surfer_surface_handle previous, int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count, surfer_surface_handle *handle)
{
    return create_or_replace(true, previous, version, family_degree, offsets, offset_count,
        coefficients, coefficient_count, xyz, xyz_count, handle, NULL);
}

static surfer_status begin_borrow(
    surfer_surface_handle handle, surfer_surface_borrow *borrow, allocation_probe *probe)
{
    if (borrow == NULL || handle <= 0) return SURFER_INVALID_INPUT;
    borrow_entry *entry = allocate(sizeof(*entry), probe);
    if (entry == NULL) return SURFER_OUT_OF_MEMORY;
    if (pthread_mutex_lock(&registry_mutex) != 0) {
        deallocate(entry);
        return SURFER_INVALID_INPUT;
    }
    snapshot *value = find_published(handle);
    surfer_status status = SURFER_OK;
    if (value == NULL) status = SURFER_INVALID_INPUT;
    else if (value->borrows == SIZE_MAX || next_identifier == INT64_MAX)
        status = SURFER_OUT_OF_MEMORY;
    else {
        entry->token = next_identifier++;
        entry->owner = value;
        entry->next = borrows;
        borrows = entry;
        value->borrows++;
        *borrow = (surfer_surface_borrow){entry->token, &value->view};
    }
    (void)pthread_mutex_unlock(&registry_mutex);
    if (status != SURFER_OK) deallocate(entry);
    return status;
}

surfer_status surfer_surface_begin_borrow(
    surfer_surface_handle handle, surfer_surface_borrow *borrow)
{
    return begin_borrow(handle, borrow, NULL);
}

surfer_status surfer_surface_end_borrow(int64_t token)
{
    if (token <= 0) return SURFER_INVALID_INPUT;
    if (pthread_mutex_lock(&registry_mutex) != 0) return SURFER_INVALID_INPUT;
    borrow_entry **link = &borrows;
    while (*link != NULL && (*link)->token != token) link = &(*link)->next;
    borrow_entry *entry = *link;
    snapshot *retired = NULL;
    if (entry != NULL) {
        *link = entry->next;
        snapshot *value = entry->owner;
        value->borrows--;
        if (!value->published && value->borrows == 0) {
            unlink_snapshot(value);
            retired = value;
        }
    }
    (void)pthread_mutex_unlock(&registry_mutex);
    const surfer_status status = entry == NULL ? SURFER_INVALID_INPUT : SURFER_OK;
    destroy_snapshot(retired);
    deallocate(entry);
    return status;
}

surfer_status surfer_surface_release(surfer_surface_handle handle)
{
    if (handle <= 0) return SURFER_INVALID_INPUT;
    if (pthread_mutex_lock(&registry_mutex) != 0) return SURFER_INVALID_INPUT;
    snapshot *value = find_published(handle);
    const surfer_status status = value == NULL ? SURFER_INVALID_INPUT : SURFER_OK;
    if (value != NULL) {
        value->published = false;
        if (value->borrows == 0) unlink_snapshot(value);
        else value = NULL;
    }
    (void)pthread_mutex_unlock(&registry_mutex);
    destroy_snapshot(value);
    return status;
}

surfer_status surfer_surface_render_orthographic(
    surfer_surface_handle handle, const surfer_scene *scene_settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom,
    uint32_t *argb_pixels, size_t pixel_capacity)
{
    if (scene_settings == NULL) return SURFER_INVALID_INPUT;
    surfer_surface_borrow borrow;
    surfer_status status = surfer_surface_begin_borrow(handle, &borrow);
    if (status != SURFER_OK) return status;
    surfer_scene scene = *scene_settings;
    scene.surface = borrow.surface;
    status = surfer_render_orthographic(&scene, width, height, camera_height,
        yaw, pitch, zoom, argb_pixels, pixel_capacity);
    (void)surfer_surface_end_borrow(borrow.token);
    return status;
}

surfer_status surfer_surface_render_orthographic_quality(
    surfer_surface_handle handle, const surfer_scene *scene_settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom, surfer_render_quality quality,
    uint32_t *argb_pixels, size_t pixel_capacity)
{
    if (scene_settings == NULL) return SURFER_INVALID_INPUT;
    surfer_surface_borrow borrow;
    surfer_status status = surfer_surface_begin_borrow(handle, &borrow);
    if (status != SURFER_OK) return status;
    surfer_scene scene = *scene_settings;
    scene.surface = borrow.surface;
    status = surfer_render_orthographic_quality(&scene, width, height, camera_height,
        yaw, pitch, zoom, quality, argb_pixels, pixel_capacity);
    (void)surfer_surface_end_borrow(borrow.token);
    return status;
}

#ifdef SURFER_SURFACE_STORE_TESTING
surfer_status surfer_surface_test_create_copied(
    int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count,
    surfer_surface_handle *handle, surfer_surface_allocation_probe *probe)
{
    return create_or_replace(false, 0, version, family_degree, offsets, offset_count,
        coefficients, coefficient_count, xyz, xyz_count, handle, probe);
}

surfer_status surfer_surface_test_replace_copied(
    surfer_surface_handle previous, int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count,
    surfer_surface_handle *handle, surfer_surface_allocation_probe *probe)
{
    return create_or_replace(true, previous, version, family_degree, offsets, offset_count,
        coefficients, coefficient_count, xyz, xyz_count, handle, probe);
}

surfer_status surfer_surface_test_begin_borrow(
    surfer_surface_handle handle, surfer_surface_borrow *borrow,
    surfer_surface_allocation_probe *probe)
{
    return begin_borrow(handle, borrow, probe);
}

size_t surfer_surface_test_live_snapshots(void)
{
    size_t count = 0;
    if (pthread_mutex_lock(&registry_mutex) != 0) return SIZE_MAX;
    for (snapshot *value = snapshots; value != NULL; value = value->next) count++;
    (void)pthread_mutex_unlock(&registry_mutex);
    return count;
}

size_t surfer_surface_test_live_borrows(void)
{
    size_t count = 0;
    if (pthread_mutex_lock(&registry_mutex) != 0) return SIZE_MAX;
    for (borrow_entry *value = borrows; value != NULL; value = value->next) count++;
    (void)pthread_mutex_unlock(&registry_mutex);
    return count;
}

size_t surfer_surface_test_live_allocations(void)
{
    return live_allocations;
}
#endif
