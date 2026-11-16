#include "surfer_frame_output.h"

#include <limits.h>
#include <math.h>
#include <stdlib.h>

#ifdef SURFER_FRAME_OUTPUT_TESTING
typedef surfer_frame_allocation_probe allocation_probe;
static _Atomic size_t live_allocations;
#else
typedef struct { size_t unused; } allocation_probe;
#endif

static void *allocate_frame(size_t bytes, allocation_probe *probe)
{
#ifdef SURFER_FRAME_OUTPUT_TESTING
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
#ifdef SURFER_FRAME_OUTPUT_TESTING
    if (result != NULL) live_allocations++;
#endif
    return result;
}

static void free_frame(void *pixels)
{
#ifdef SURFER_FRAME_OUTPUT_TESTING
    if (pixels != NULL) live_allocations--;
#endif
    free(pixels);
}

/* Same row reversal as RendererEngine.flipRowsInPlace. This is Android output
 * layout adaptation, not a change to the renderer's mathematical coordinates.
 */
static void flip_rows(uint32_t *pixels, size_t width, size_t height)
{
    for (size_t top = 0; top < height / 2U; ++top) {
        const size_t bottom = height - 1U - top;
        for (size_t x = 0; x < width; ++x) {
            const size_t upper = top * width + x;
            const size_t lower = bottom * width + x;
            const uint32_t swap = pixels[upper];
            pixels[upper] = pixels[lower];
            pixels[lower] = swap;
        }
    }
}

static surfer_status render_copied_frame(
    surfer_surface_handle handle, int32_t width, int32_t height, int32_t quality,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_owned_frame *frame, allocation_probe *probe)
{
    if (frame == NULL || handle <= 0 || width < 2 || height < 2 ||
        (quality != 0 && quality != 1) ||
        (size_t)width > SIZE_MAX / (size_t)height ||
        (size_t)width * (size_t)height > INT32_MAX ||
        (size_t)width * (size_t)height > SIZE_MAX / sizeof(uint32_t) ||
        !isfinite(camera_height) || !isfinite(yaw) || !isfinite(pitch) ||
        !isfinite(zoom) || !(camera_height > 0.0) || !(zoom > 0.0)) {
        return SURFER_INVALID_INPUT;
    }
    const size_t count = (size_t)width * (size_t)height;
    uint32_t *pixels = allocate_frame(count * sizeof(*pixels), probe);
    if (pixels == NULL) return SURFER_OUT_OF_MEMORY;
    const surfer_scene settings = surfer_default_scene(NULL);
    const surfer_render_quality render_quality = {
        quality == 0 ? SURFER_AA_OG_1X1 : SURFER_AA_QUINCUNX, 0.3f
    };
    const surfer_status status = surfer_surface_render_orthographic_quality(
        handle, &settings, (size_t)width, (size_t)height,
        camera_height, yaw, pitch, zoom, render_quality, pixels, count);
    if (status != SURFER_OK) {
        free_frame(pixels);
        return status; /* render failure must not publish a frame */
    }
    flip_rows(pixels, (size_t)width, (size_t)height);
    *frame = (surfer_owned_frame){pixels, count};
    return SURFER_OK;
}

surfer_status surfer_surface_render_copied_frame(
    surfer_surface_handle handle, int32_t width, int32_t height, int32_t quality,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_owned_frame *frame)
{
    return render_copied_frame(handle, width, height, quality, camera_height,
        yaw, pitch, zoom, frame, NULL);
}

void surfer_owned_frame_destroy(surfer_owned_frame *frame)
{
    if (frame == NULL) return;
    free_frame(frame->argb_pixels);
    *frame = (surfer_owned_frame){NULL, 0};
}

#ifdef SURFER_FRAME_OUTPUT_TESTING
surfer_status surfer_frame_test_render_copied(
    surfer_surface_handle handle, int32_t width, int32_t height, int32_t quality,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_owned_frame *frame, surfer_frame_allocation_probe *probe)
{
    return render_copied_frame(handle, width, height, quality, camera_height,
        yaw, pitch, zoom, frame, probe);
}

size_t surfer_frame_test_live_allocations(void) { return live_allocations; }
#endif
