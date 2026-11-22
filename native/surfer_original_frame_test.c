/* Bounded default-lit frames recorded by unchanged original RenderingTask. */
#include "surfer_raytracer.c"
#include <inttypes.h>
#include <stdio.h>

static const char *frame_identity = "before first frame";

static void frame_fail(const char *reason)
{
    (void)fflush(stdout);
    fprintf(stderr, "FAIL original lit frame: %s %s\n", frame_identity, reason);
    exit(1);
}

static double frame_double_from_bits(uint64_t bits)
{
    double value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

int main(int argc, char **argv)
{
    if (argc != 2) frame_fail("reference argument");
    FILE *input = fopen(argv[1], "r");
    if (input == NULL) frame_fail("reference unavailable");
    char tag[32], name[100], record_name[100], formula[512], pattern[32];
    size_t frames = 0, observations = 0;
    while (fscanf(input, "%31s", tag) == 1) {
        size_t width, height;
        uint32_t threshold_bits;
        double yaw, pitch, zoom;
        if (strcmp(tag, "frame") != 0 ||
            fscanf(input, "%99s%511s%31s%" SCNx32 "%zu%zu%la%la%la", name, formula, pattern,
                &threshold_bits, &width, &height, &yaw, &pitch, &zoom) != 9 ||
            width < 2 || height < 2 || width > 128 || height > 128)
            frame_fail("frame header");
        frame_identity = name;
        surfer_prepared_surface prepared = {0};
        if (fscanf(input, "%31s%99s%" SCNd32, tag, record_name, &prepared.family_degree) != 3 ||
            strcmp(tag, "family_degree") != 0 || strcmp(record_name, name) != 0)
            frame_fail("original family degree");
        surfer_term terms[4][256];
        surfer_sparse_polynomial *polynomials[] = {&prepared.surface, &prepared.gradient_x,
            &prepared.gradient_y, &prepared.gradient_z};
        for (unsigned component = 0; component < 4; ++component) {
            unsigned recorded_component;
            size_t count;
            if (fscanf(input, "%31s%99s%u%zu", tag, record_name, &recorded_component, &count) != 4 ||
                strcmp(tag, "input") != 0 || strcmp(record_name, name) != 0 ||
                recorded_component != component || count > 256) frame_fail("prepared polynomial header");
            polynomials[component]->terms = terms[component];
            polynomials[component]->term_count = count;
            for (size_t index = 0; index < count; ++index) {
                size_t ordinal;
                uint64_t coefficient;
                surfer_term *term = &terms[component][index];
                if (fscanf(input, "%31s%99s%u%zu%" SCNx64 "%" SCNd32 "%" SCNd32 "%" SCNd32,
                        tag, record_name, &recorded_component, &ordinal, &coefficient,
                        &term->x_exponent, &term->y_exponent, &term->z_exponent) != 8 ||
                    strcmp(tag, "term") != 0 || strcmp(record_name, name) != 0 ||
                    recorded_component != component || ordinal != index) frame_fail("prepared term bytes/order");
                term->coefficient = frame_double_from_bits(coefficient);
            }
        }
        float threshold;
        memcpy(&threshold, &threshold_bits, sizeof(threshold));
        const surfer_render_quality quality = {
            strcmp(pattern, "OG_1x1") == 0 ? SURFER_AA_OG_1X1 : SURFER_AA_QUINCUNX, threshold};
        if (strcmp(pattern, "OG_1x1") != 0 && strcmp(pattern, "QUINCUNX") != 0)
            frame_fail("sample pattern");
        const surfer_scene scene = surfer_default_scene(&prepared);
        uint32_t pixels[128 * 128];
        surfer_status status = surfer_render_orthographic_quality(&scene, width, height, 2.15,
            yaw, pitch, zoom, quality, pixels, width * height);
        if (status != SURFER_OK) {
            fprintf(stderr, "native status %d\n", status);
            frame_fail("render status");
        }
        for (size_t y = 0; y < height; ++y) {
            for (size_t x = 0; x < width; ++x) {
                size_t recorded_x, recorded_y;
                uint32_t expected;
                if (fscanf(input, "%31s%99s%zu%zu%" SCNx32, tag, record_name,
                        &recorded_x, &recorded_y, &expected) != 5 || strcmp(tag, "pixel") != 0 ||
                    strcmp(record_name, name) != 0 || recorded_x != x || recorded_y != y)
                    frame_fail("pixel record order");
                if (pixels[y * width + x] != expected) {
                    fprintf(stderr, "pixel %zu,%zu actual %08" PRIx32 " expected %08" PRIx32 "\n",
                        x, y, pixels[y * width + x], expected);
                    frame_fail("exact pixel bytes");
                }
                printf("argb\t%s\t%zu\t%zu\t%08" PRIx32 "\n", name, x, y, pixels[y * width + x]);
                observations++;
            }
        }
        frames++;
    }
    if (ferror(input) || fclose(input) != 0 || frames != 44 || observations != 5412)
        frame_fail("bounded frame coverage");
    printf("default-lit frames %zu pixels %zu\n", frames, observations);
    puts("PASS original full-canvas default-lit prepared polynomial pixels");
    return 0;
}
