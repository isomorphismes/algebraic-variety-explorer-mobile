#ifndef SURFER_FRAME_OUTPUT_H
#define SURFER_FRAME_OUTPUT_H

#include "surfer_surface_store.h"

typedef struct {
    uint32_t *argb_pixels;
    size_t pixel_count;
} surfer_owned_frame;

/* Output changes only on OK and then owns a complete Android-row-order frame.
 * Use a separate output value when replacing a retained frame; destroy the old
 * frame only after success. Dimensions are Int32-array-compatible and >=2.
 * quality0 is original OG_1x1, quality1 is original QUINCUNX; both use0.3f.
 * Other qualities refuse before allocation or output publication.
 */
surfer_status surfer_surface_render_copied_frame(
    surfer_surface_handle handle, int32_t width, int32_t height, int32_t quality,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_owned_frame *frame);
void surfer_owned_frame_destroy(surfer_owned_frame *frame);

#ifdef SURFER_FRAME_OUTPUT_TESTING
typedef struct {
    size_t fail_at;
    size_t attempts;
} surfer_frame_allocation_probe;

surfer_status surfer_frame_test_render_copied(
    surfer_surface_handle handle, int32_t width, int32_t height, int32_t quality,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_owned_frame *frame, surfer_frame_allocation_probe *probe);
size_t surfer_frame_test_live_allocations(void);
#endif

#endif
