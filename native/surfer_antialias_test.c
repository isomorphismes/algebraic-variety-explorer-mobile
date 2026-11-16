/* Native implementation acceptance against unchanged Stussak Java outputs. */
#define SURFER_TEST_ALLOCATION_FAILURES
#include "surfer_raytracer.c"
#include <float.h>
#include <inttypes.h>
#include <stdio.h>

_Static_assert(sizeof(float) == sizeof(uint32_t) && FLT_RADIX == 2 &&
    FLT_MANT_DIG == 24 && FLT_EVAL_METHOD == 0, "strict binary32 color evaluation required");
_Static_assert(sizeof(double) == sizeof(uint64_t) && DBL_MANT_DIG == 53 &&
    DBL_MAX_EXP == 1024, "binary64 geometry required");

static void fail(const char *message)
{
    fprintf(stderr, "FAIL original adaptive AA: %s\n", message);
    exit(1);
}

static float from_bits(uint32_t bits)
{
    float value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static uint32_t bits_of(float value)
{
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static FILE *open_reference(const char *path)
{
    FILE *input = fopen(path, "r");
    if (input == NULL) fail("reference file missing");
    return input;
}

static void check_blends(const char *path)
{
    FILE *input = open_reference(path);
    char tag[32], name[80];
    size_t count = 0;
    while (fscanf(input, "%31s", tag) == 1) {
        unsigned threshold_bits, reference_refines;
        if (strcmp(tag, "blend") != 0 ||
            fscanf(input, "%79s%x%u", name, &threshold_bits, &reference_refines) != 3)
            fail("malformed original blend record");
        surfer_color values[6];
        for (size_t color = 0; color < 6; ++color) {
            unsigned red, green, blue;
            if (fscanf(input, "%x%x%x", &red, &green, &blue) != 3)
                fail("incomplete original blend colors");
            values[color] = (surfer_color){from_bits(red), from_bits(green), from_bits(blue)};
        }
        unsigned expected_argb;
        if (fscanf(input, "%x", &expected_argb) != 1) fail("missing original blend pixel");
        const surfer_render_quality quality = {SURFER_AA_QUINCUNX, from_bits(threshold_bits)};
        if (antialias_refines(quality, values[0], values[1], values[2], values[3]) !=
            (reference_refines != 0)) {
            fprintf(stderr, "FAIL original adaptive AA refinement: %s\n", name);
            exit(1);
        }
        const surfer_color actual = antialias_color(quality,
            values[0], values[1], values[2], values[3], values[4]);
        if (bits_of(actual.red) != bits_of(values[5].red) ||
            bits_of(actual.green) != bits_of(values[5].green) ||
            bits_of(actual.blue) != bits_of(values[5].blue) ||
            color_to_argb_validated(actual) != expected_argb) {
            fprintf(stderr, "FAIL original adaptive AA blend: %s\n", name);
            exit(1);
        }
        count++;
    }
    if (ferror(input) || fclose(input) != 0 || count != 15)
        fail("original blend corpus coverage");
}

static const surfer_term plane[] = {{1.0, 0, 0, 1}};
static const surfer_term one[] = {{1.0, 0, 0, 0}};
static const surfer_term sphere[] = {
    {-0.64, 0, 0, 0}, {1.0, 0, 0, 2}, {1.0, 0, 2, 0}, {1.0, 2, 0, 0}
};
static const surfer_term dx[] = {{2.0, 1, 0, 0}};
static const surfer_term dy[] = {{2.0, 0, 1, 0}};
static const surfer_term dz[] = {{2.0, 0, 0, 1}};

static surfer_prepared_surface reference_surface(const char *formula)
{
    const surfer_sparse_polynomial empty = {NULL, 0};
    if (strcmp(formula, "z") == 0)
        return (surfer_prepared_surface){1, {plane, 1}, empty, empty, {one, 1}};
    if (strcmp(formula, "x^2+y^2+z^2-0.64") == 0)
        return (surfer_prepared_surface){2, {sphere, 4}, {dx, 1}, {dy, 1}, {dz, 1}};
    if (strcmp(formula, "1") == 0)
        return (surfer_prepared_surface){0, {one, 1}, empty, empty, empty};
    fail("unknown reference formula");
    return (surfer_prepared_surface){0};
}

static surfer_scene reference_scene(const surfer_prepared_surface *surface)
{
    surfer_scene scene = surfer_default_scene(surface);
    scene.front_material = (surfer_material){{0.90f, 0.47f, 0.18f}, 1.0f, 0.0f, 0.0f, 24.0f};
    scene.back_material = scene.front_material;
    scene.light_count = 0;
    return scene;
}

static void check_frames(const char *path)
{
    FILE *input = open_reference(path);
    char tag[32], name[80], formula[100], pattern[32];
    size_t frame_count = 0, pixel_count = 0;
    while (fscanf(input, "%31s", tag) == 1) {
        unsigned threshold;
        size_t width, height;
        double yaw, pitch, zoom;
        if (strcmp(tag, "frame") != 0 || fscanf(input, "%79s%99s%31s%x%zu%zu%la%la%la",
            name, formula, pattern, &threshold, &width, &height, &yaw, &pitch, &zoom) != 9 ||
            width < 2 || height < 2 || width > 128 || height > 128)
            fail("malformed original frame header");
        const surfer_prepared_surface surface = reference_surface(formula);
        const surfer_scene scene = reference_scene(&surface);
        surfer_antialiasing_pattern selected;
        if (strcmp(pattern, "OG_1x1") == 0) selected = SURFER_AA_OG_1X1;
        else if (strcmp(pattern, "QUINCUNX") == 0) selected = SURFER_AA_QUINCUNX;
        else { fail("unknown original sample pattern"); selected = SURFER_AA_OG_1X1; }
        const surfer_render_quality quality = {selected, from_bits(threshold)};
        uint32_t pixels[128 * 128];
        if (surfer_render_orthographic_quality(&scene, width, height, 2.15, yaw, pitch, zoom,
                quality, pixels, width * height) != SURFER_OK)
            fail("original frame render status");
        for (size_t y = 0; y < height; ++y) {
            for (size_t x = 0; x < width; ++x) {
                char pixel_name[80];
                size_t observed_x, observed_y;
                unsigned expected;
                if (fscanf(input, "%31s%79s%zu%zu%x", tag, pixel_name,
                        &observed_x, &observed_y, &expected) != 5 || strcmp(tag, "pixel") != 0 ||
                    strcmp(pixel_name, name) != 0 || observed_x != x || observed_y != y)
                    fail("incomplete or reordered original frame pixels");
                if (pixels[y * width + x] != expected) {
                    fprintf(stderr, "FAIL original adaptive AA pixel: %s %zu %zu %08" PRIx32
                        "; expected %08x\n", name, x, y, pixels[y * width + x], expected);
                    exit(1);
                }
                pixel_count++;
            }
        }
        frame_count++;
    }
    if (ferror(input) || fclose(input) != 0 || frame_count != 9 || pixel_count != 682)
        fail("original full-frame coverage");
}

static void check_status_and_faults(void)
{
    const surfer_prepared_surface surface = reference_surface("x^2+y^2+z^2-0.64");
    const surfer_scene scene = reference_scene(&surface);
    const surfer_render_quality quality = {SURFER_AA_QUINCUNX, 0.3f};
    uint32_t pixels[35];
    for (size_t index = 0; index < 35; ++index) pixels[index] = UINT32_C(0x12345678);
    surfer_render_quality invalid[] = {{(surfer_antialiasing_pattern)2, 0.3f},
        {SURFER_AA_QUINCUNX, -0.1f}, {SURFER_AA_QUINCUNX, NAN},
        {SURFER_AA_QUINCUNX, INFINITY}};
    for (size_t index = 0; index < sizeof(invalid) / sizeof(*invalid); ++index) {
        if (surfer_render_orthographic_quality(&scene, 7, 5, 2.15, 0, 0, 1,
                invalid[index], pixels, 35) != SURFER_INVALID_INPUT)
            fail("invalid quality accepted");
    }
    if (surfer_render_orthographic_quality(&scene, 7, 5, 2.15, 0, 0, 1,
            quality, pixels, 34) != SURFER_INVALID_INPUT ||
        surfer_render_orthographic_quality(&scene, SIZE_MAX / 8, 2, 2.15, 0, 0, 1,
            quality, pixels, SIZE_MAX) != SURFER_INVALID_INPUT)
        fail("capacity or corner-grid overflow accepted");
    for (size_t index = 0; index < 35; ++index)
        if (pixels[index] != UINT32_C(0x12345678)) fail("invalid request wrote pixels");
    surfer_allocation_probe successful = {SIZE_MAX, 0, 0};
    if (surfer_test_render_orthographic_quality(&scene, 7, 5, 2.15, 0, 0, 1,
            quality, pixels, 35, &successful) != SURFER_OK || successful.attempts < 2 ||
        (successful.paths & UINT32_C(0x300)) != UINT32_C(0x300))
        fail("allocation probe did not cover AA and ray storage");
    for (size_t failed = 0; failed < successful.attempts; ++failed) {
        surfer_allocation_probe probe = {failed, 0, 0};
        const surfer_status status = surfer_test_render_orthographic_quality(
            &scene, 7, 5, 2.15, 0, 0, 1, quality, pixels, 35, &probe);
        if (status != SURFER_OUT_OF_MEMORY) fail("allocation failure became successful/blank AA frame");
    }
    const surfer_prepared_surface constant = reference_surface("1");
    const surfer_scene smooth_scene = reference_scene(&constant);
    surfer_allocation_probe smooth = {SIZE_MAX, 0, 0};
    surfer_allocation_probe forced = {SIZE_MAX, 0, 0};
    const surfer_render_quality full = {SURFER_AA_QUINCUNX, 0.0f};
    if (surfer_test_render_orthographic_quality(&smooth_scene, 7, 5, 2.15, 0, 0, 1,
            quality, pixels, 35, &smooth) != SURFER_OK ||
        surfer_test_render_orthographic_quality(&smooth_scene, 7, 5, 2.15, 0, 0, 1,
            full, pixels, 35, &forced) != SURFER_OK ||
        (smooth.paths & UINT32_C(0x200)) != 0 ||
        (forced.paths & UINT32_C(0x200)) == 0 || forced.attempts <= smooth.attempts)
        fail("adaptive smooth pixels did not skip genuine center traces");
    printf("AA allocation faults checked: %zu\n", successful.attempts);
}

int main(int argc, char **argv)
{
    if (argc != 3) fail("blend and pixel reference paths required");
    check_blends(argv[1]);
    check_frames(argv[2]);
    check_status_and_faults();
    puts("SURFER original adaptive AA colors, pixels and allocation faults: PASS");
    return 0;
}
