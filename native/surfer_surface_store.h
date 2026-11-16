/* Immutable copied PreparedSurface ownership. No polynomial semantics live here. */
#ifndef SURFER_SURFACE_STORE_H
#define SURFER_SURFACE_STORE_H

#include "surfer_raytracer.h"

#define SURFER_PREPARED_SURFACE_ABI_VERSION 1

typedef int64_t surfer_surface_handle;

typedef struct {
    int64_t token;
    const surfer_prepared_surface *surface;
} surfer_surface_borrow;

/* Outputs change only on OK. Input buffers are borrowed for this call only
 * and must remain unchanged for its duration. Concurrent input mutation is
 * outside this contract; copying two buffers is not an atomic combined read.
 * Offsets must have length five; all other lengths are element counts.
 * Empty ranges are valid zero polynomials. Terms within each range must be
 * strictly lexicographically ordered by (x,y,z); zeros are retained verbatim.
 */
surfer_status surfer_surface_create_copied(
    int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count,
    surfer_surface_handle *handle);

/* The previous handle is retired only after the complete replacement has
 * been validated and copied. Failure leaves it and the output unchanged.
 */
surfer_status surfer_surface_replace_copied(
    surfer_surface_handle previous,
    int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count,
    surfer_surface_handle *handle);

/* Handles are positive monotonically assigned IDs, never addresses or secret
 * capabilities. Released
 * handles cannot begin another borrow. Existing borrows retain their snapshot.
 * Each successful begin must have exactly one end. Copying a borrow does not
 * acquire another reference; a second end returns INVALID_INPUT safely.
 * Acquire before dispatching asynchronous work; end after its final access.
 */
surfer_status surfer_surface_begin_borrow(
    surfer_surface_handle handle, surfer_surface_borrow *borrow);
surfer_status surfer_surface_end_borrow(int64_t token);
surfer_status surfer_surface_release(surfer_surface_handle handle);

/* Synchronous render with ownership held for the complete numerical call.
 * scene_settings->surface is ignored; all other scene settings are copied.
 */
surfer_status surfer_surface_render_orthographic(
    surfer_surface_handle handle, const surfer_scene *scene_settings,
    size_t width, size_t height, double camera_height,
    double yaw, double pitch, double zoom,
    uint32_t *argb_pixels, size_t pixel_capacity);

#ifdef SURFER_SURFACE_STORE_TESTING
/* Test-only per-call failure injection. No allocator state is retained.
 * fail_at is zero-based; SIZE_MAX disables failures. */
typedef struct {
    size_t fail_at;
    size_t attempts;
} surfer_surface_allocation_probe;

surfer_status surfer_surface_test_create_copied(
    int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count,
    surfer_surface_handle *handle, surfer_surface_allocation_probe *probe);
surfer_status surfer_surface_test_replace_copied(
    surfer_surface_handle previous,
    int32_t version, int32_t family_degree,
    const int32_t *offsets, size_t offset_count,
    const double *coefficients, size_t coefficient_count,
    const int32_t *xyz, size_t xyz_count,
    surfer_surface_handle *handle, surfer_surface_allocation_probe *probe);
surfer_status surfer_surface_test_begin_borrow(
    surfer_surface_handle handle, surfer_surface_borrow *borrow,
    surfer_surface_allocation_probe *probe);
size_t surfer_surface_test_live_snapshots(void);
size_t surfer_surface_test_live_borrows(void);
size_t surfer_surface_test_live_allocations(void);
#endif

#endif
