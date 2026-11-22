#include "surfer_frame_output.h"

#include <float.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void require_condition(bool condition, const char *label)
{
    if (condition) return;
    fprintf(stderr, "FAIL copied render pixels: %s\n", label);
    exit(1);
}

static void require_status(surfer_status actual, surfer_status expected, const char *label)
{
    if (actual == expected) return;
    fprintf(stderr, "FAIL copied render pixels: %s: got%d expected%d\n", label, actual, expected);
    exit(1);
}

/* Sphere with center y=.25 and radius .6: its row asymmetry is intentional. */
static surfer_surface_handle asymmetric_surface(void)
{
    const int32_t offsets[5] = {0,5,6,8,9};
    const double coefficients[9] = {-0.2975,1,-0.5,1,1, 2, -0.5,2, 2};
    const int32_t xyz[27] = {
        0,0,0, 0,0,2, 0,1,0, 0,2,0, 2,0,0,
        1,0,0, 0,0,0, 0,1,0, 0,0,1
    };
    surfer_surface_handle handle = 0;
    require_status(surfer_surface_create_copied(1, 2, offsets, 5,
        coefficients, 9, xyz, 27, &handle), SURFER_OK, "construct asymmetric surface");
    return handle;
}

static void require_no_borrows(void)
{
    require_condition(surfer_surface_test_live_borrows() == 0, "native borrow leaked");
}

static void test_rows_and_failure_preservation(int32_t quality)
{
    enum { WIDTH = 9, HEIGHT = 7, COUNT = WIDTH * HEIGHT };
    const surfer_surface_handle handle = asymmetric_surface();
    uint32_t mathematical[COUNT];
    const surfer_scene scene = surfer_default_scene(NULL);
    const surfer_render_quality original_quality = {
        quality == 0 ? SURFER_AA_OG_1X1 : SURFER_AA_QUINCUNX, 0.3f
    };
    require_status(surfer_surface_render_orthographic_quality(handle, &scene, WIDTH, HEIGHT,
        2.15, 0, 0, 1, original_quality, mathematical, COUNT), SURFER_OK, "render mathematical rows");
    surfer_owned_frame frame = {NULL, 0};
    require_status(surfer_surface_render_copied_frame(handle, WIDTH, HEIGHT, quality,
        2.15, 0, 0, 1, &frame), SURFER_OK, "render copied Android rows");
    require_condition(frame.argb_pixels != NULL && frame.pixel_count == COUNT, "complete copied frame");
    bool asymmetric = false;
    for (size_t y = 0; y < HEIGHT; ++y) {
        for (size_t x = 0; x < WIDTH; ++x) {
            const size_t i = y * WIDTH + x;
            const size_t opposite = (HEIGHT - 1U - y) * WIDTH + x;
            if (mathematical[i] != mathematical[opposite]) asymmetric = true;
            require_condition(frame.argb_pixels[i] == mathematical[opposite], "exact Android row reversal");
        }
    }
    require_condition(asymmetric, "row reversal control must be asymmetric");
    require_no_borrows();
    require_condition(surfer_frame_test_live_allocations() == 1, "one retained frame allocation");
    const surfer_owned_frame retained = frame;
    uint32_t retained_pixels[COUNT];
    memcpy(retained_pixels, frame.argb_pixels, sizeof(retained_pixels));
    /* All scalars are finite and positive where required; division in the
     * actual view preparation overflows and must refuse before publication. */
    require_status(surfer_surface_render_copied_frame(handle, WIDTH, HEIGHT, quality,
        DBL_MAX, 0, 0, DBL_MIN, &frame), SURFER_INVALID_INPUT,
        "numerical refusal preserves prior frame");
    require_condition(frame.argb_pixels == retained.argb_pixels && frame.pixel_count == retained.pixel_count,
        "failed render changed previous frame ownership");
    require_condition(memcmp(retained_pixels, frame.argb_pixels, sizeof(retained_pixels)) == 0,
        "failed render changed previous frame pixels");
    require_condition(surfer_frame_test_live_allocations() == 1, "failed render leaked private frame");
    require_no_borrows();
    require_status(surfer_surface_release(handle), SURFER_OK, "release retained surface");
    require_status(surfer_surface_render_copied_frame(handle, WIDTH, HEIGHT, quality,
        2.15, 0, 0, 1, &frame), SURFER_INVALID_INPUT, "stale handle refusal");
    require_condition(frame.argb_pixels == retained.argb_pixels, "stale handle changed previous frame");
    require_condition(surfer_frame_test_live_allocations() == 1, "stale handle leaked private frame");
    surfer_owned_frame_destroy(&frame);
    require_condition(frame.argb_pixels == NULL && frame.pixel_count == 0, "destroy clears ownership");
    surfer_owned_frame_destroy(&frame);
    require_no_borrows();
}

static void test_sizes_inputs_and_allocation(void)
{
    const surfer_surface_handle handle = asymmetric_surface();
    surfer_owned_frame frame = {NULL, 0};
    const int32_t dimensions[][2] = {
        {0,3}, {-1,3}, {3,0}, {3,-1}, {1,3}, {3,1}, {INT32_MAX,INT32_MAX}, {INT32_MAX,2}
    };
    for (size_t i = 0; i < sizeof(dimensions) / sizeof(dimensions[0]); ++i) {
        surfer_frame_allocation_probe probe = {SIZE_MAX, 0};
        require_status(surfer_frame_test_render_copied(handle, dimensions[i][0], dimensions[i][1], 0,
            2.15, 0, 0, 1, &frame, &probe), SURFER_INVALID_INPUT, "invalid frame dimensions");
        require_condition(probe.attempts == 0, "invalid dimensions reached allocator");
    }
    require_status(surfer_surface_render_copied_frame(handle, 3, 3, 0, NAN, 0, 0, 1, &frame),
        SURFER_INVALID_INPUT, "nonfinite camera");
    require_status(surfer_surface_render_copied_frame(handle, 3, 3, 0, 2.15, INFINITY, 0, 1, &frame),
        SURFER_INVALID_INPUT, "nonfinite yaw");
    require_status(surfer_surface_render_copied_frame(handle, 3, 3, 0, 2.15, 0, NAN, 1, &frame),
        SURFER_INVALID_INPUT, "nonfinite pitch");
    require_status(surfer_surface_render_copied_frame(handle, 3, 3, 0, 2.15, 0, 0, INFINITY, &frame),
        SURFER_INVALID_INPUT, "nonfinite zoom");
    require_status(surfer_surface_render_copied_frame(handle, 3, 3, 0, 0, 0, 0, 1, &frame),
        SURFER_INVALID_INPUT, "zero camera");
    require_status(surfer_surface_render_copied_frame(handle, 3, 3, 0, 2.15, 0, 0, 0, &frame),
        SURFER_INVALID_INPUT, "zero zoom");
    require_status(surfer_surface_render_copied_frame(0, 3, 3, 0, 2.15, 0, 0, 1, &frame),
        SURFER_INVALID_INPUT, "zero handle");
    require_status(surfer_surface_render_copied_frame(INT64_MAX, 3, 3, 0, 2.15, 0, 0, 1, &frame),
        SURFER_INVALID_INPUT, "forged identifier");
    require_status(surfer_surface_render_copied_frame(handle, 3, 3, 0, 2.15, 0, 0, 1, NULL),
        SURFER_INVALID_INPUT, "null output");
    surfer_frame_allocation_probe failure = {0, 0};
    require_status(surfer_frame_test_render_copied(handle, 3, 3, 0, 2.15, 0, 0, 1, &frame, &failure),
        SURFER_OUT_OF_MEMORY, "private frame allocation failure");
    require_condition(failure.attempts == 1, "frame allocation control did not execute");
    require_condition(frame.argb_pixels == NULL && frame.pixel_count == 0, "failure published frame");
    require_condition(surfer_frame_test_live_allocations() == 0, "private frame allocation leaked");
    require_no_borrows();
    const int32_t invalid_quality[] = {-1, 2, INT32_MAX};
    for (size_t i = 0; i < sizeof(invalid_quality) / sizeof(invalid_quality[0]); ++i) {
        surfer_frame_allocation_probe probe = {SIZE_MAX, 0};
        require_status(surfer_frame_test_render_copied(handle, 3, 3, invalid_quality[i],
            2.15, 0, 0, 1, &frame, &probe), SURFER_INVALID_INPUT, "invalid quality refusal");
        require_condition(probe.attempts == 0, "invalid quality reached allocator");
        require_condition(frame.argb_pixels == NULL && frame.pixel_count == 0, "invalid quality published pixels");
    }
    require_status(surfer_surface_release(handle), SURFER_OK, "release input control");
}

static void test_valid_blank_frame(void)
{
    const int32_t offsets[5] = {0,0,0,0,0};
    surfer_surface_handle handle = 0;
    require_status(surfer_surface_create_copied(1, 2, offsets, 5,
        NULL, 0, NULL, 0, &handle), SURFER_OK, "create zero polynomial");
    surfer_owned_frame frame = {NULL, 0};
    require_status(surfer_surface_render_copied_frame(handle, 3, 3, 0, 2.15, 0, 0, 1, &frame),
        SURFER_OK, "valid blank frame is success");
    const surfer_scene scene = surfer_default_scene(NULL);
    uint32_t background = 0;
    require_status(surfer_color_to_argb(scene.background, &background), SURFER_OK, "background conversion");
    for (size_t i = 0; i < frame.pixel_count; ++i)
        require_condition(frame.argb_pixels[i] == background, "zero polynomial background pixels");
    surfer_owned_frame_destroy(&frame);
    require_status(surfer_surface_release(handle), SURFER_OK, "release zero polynomial");
}

static void test_quality_is_observable(void)
{
    const surfer_surface_handle handle = asymmetric_surface();
    surfer_owned_frame interactive = {NULL, 0};
    surfer_owned_frame final = {NULL, 0};
    require_status(surfer_surface_render_copied_frame(handle, 9, 7, 0, 2.15, 0, 0, 1, &interactive),
        SURFER_OK, "Interactive quality");
    require_status(surfer_surface_render_copied_frame(handle, 9, 7, 1, 2.15, 0, 0, 1, &final),
        SURFER_OK, "Final quality");
    require_condition(interactive.pixel_count == final.pixel_count &&
        memcmp(interactive.argb_pixels, final.argb_pixels, final.pixel_count * sizeof(uint32_t)) != 0,
        "Interactive and Final quality must be observable");
    surfer_owned_frame_destroy(&interactive);
    surfer_owned_frame_destroy(&final);
    require_status(surfer_surface_release(handle), SURFER_OK, "release quality control");
}

int main(void)
{
    test_rows_and_failure_preservation(0);
    test_rows_and_failure_preservation(1);
    test_sizes_inputs_and_allocation();
    test_valid_blank_frame();
    test_quality_is_observable();
    require_condition(surfer_frame_test_live_allocations() == 0, "final frame allocation count");
    require_condition(surfer_surface_test_live_snapshots() == 0, "final snapshot count");
    require_condition(surfer_surface_test_live_allocations() == 0, "final native store allocations");
    require_no_borrows();
    puts("PASS copied native render pixels and failure preservation");
    return 0;
}
