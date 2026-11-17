/* Actual original RenderingTask tile bytes and serial composition oracle. */
#define SURFER_TEST_ALLOCATION_FAILURES
#include "surfer_raytracer.c"
#include <inttypes.h>
#include <stdio.h>

static char tile_frame[100] = "before first frame";
static size_t tile_ordinal;

static void tile_fail(const char *reason)
{
    (void)fflush(stdout);
    fprintf(stderr, "FAIL original tile: %s tile%zu %s\n", tile_frame, tile_ordinal, reason);
    exit(1);
}

static double tile_read_double(FILE *input)
{
    uint64_t bits;
    double value;
    if (fscanf(input, "%" SCNx64, &bits) != 1) tile_fail("binary64 input");
    memcpy(&value, &bits, sizeof(value));
    return value;
}

typedef struct { size_t checks, stop; } tile_cancel_probe;

static bool tile_cancelled(void *opaque)
{
    tile_cancel_probe *probe = opaque;
    return probe->checks++ == probe->stop;
}

static void check_tile_refusals_and_faults(void)
{
    const surfer_term surface[] = {{-0.3,0,0,0},{1,0,0,3},{1,0,3,0},{1,1,1,1},{1,3,0,0}};
    const surfer_term dx[] = {{1,0,1,1},{3,2,0,0}};
    const surfer_term dy[] = {{3,0,2,0},{1,1,0,1}};
    const surfer_term dz[] = {{3,0,0,2},{1,1,1,0}};
    const surfer_prepared_surface prepared = {3,{surface,5},{dx,2},{dy,2},{dz,2}};
    const surfer_scene scene = surfer_default_scene(&prepared);
    uint32_t pixels[4];
    for (size_t mode = 0; mode < 2; ++mode) {
        const surfer_render_quality quality = {(surfer_antialiasing_pattern)mode,0.3f};
        for (size_t pixel = 0; pixel < 4; ++pixel) pixels[pixel] = UINT32_C(0x12345678);
        if (surfer_render_orthographic_tile(&scene,3,3,2,1,1,2,2.15,0.43,-0.71,1,
                quality,NULL,pixels,4) != SURFER_INVALID_INPUT ||
            surfer_render_orthographic_tile(&scene,3,3,1,1,3,2,2.15,0.43,-0.71,1,
                quality,NULL,pixels,4) != SURFER_INVALID_INPUT ||
            surfer_render_orthographic_tile(&scene,3,3,1,1,2,2,2.15,0.43,-0.71,1,
                quality,NULL,pixels,3) != SURFER_INVALID_INPUT)
            tile_fail("invalid bounds/capacity accepted");
        for (size_t pixel = 0; pixel < 4; ++pixel)
            if (pixels[pixel] != UINT32_C(0x12345678)) tile_fail("invalid tile wrote output");
        surfer_allocation_probe probe = {SIZE_MAX,0,0};
        if (surfer_test_render_orthographic_tile(&scene,3,3,1,1,2,2,2.15,0.43,-0.71,1,
                quality,NULL,pixels,4,&probe) != SURFER_OK || probe.attempts == 0)
            tile_fail("allocation baseline");
        const size_t attempts = probe.attempts;
        for (size_t fault = 0; fault < attempts; ++fault) {
            probe = (surfer_allocation_probe){fault,0,0};
            if (surfer_test_render_orthographic_tile(&scene,3,3,1,1,2,2,2.15,0.43,-0.71,1,
                    quality,NULL,pixels,4,&probe) != SURFER_OUT_OF_MEMORY ||
                probe.attempts != fault + 1) tile_fail("actual private tile allocation fault");
        }
        tile_cancel_probe cancellation = {0,SIZE_MAX};
        const surfer_cancellation predicate = {tile_cancelled,&cancellation};
        if (surfer_render_orthographic_tile(&scene,3,3,1,1,2,2,2.15,0.43,-0.71,1,
                quality,&predicate,pixels,4) != SURFER_OK || cancellation.checks < 16)
            tile_fail("cancellation baseline");
        const size_t checks = cancellation.checks;
        for (size_t sample = 0; sample <= 16; ++sample) {
            cancellation = (tile_cancel_probe){0,(checks - 1) * sample / 16};
            if (surfer_render_orthographic_tile(&scene,3,3,1,1,2,2,2.15,0.43,-0.71,1,
                    quality,&predicate,pixels,4) != SURFER_CANCELLED)
                tile_fail("cancelled private tile cleanup");
        }
        printf("tile allocation faults mode%zu %zu cancellation stops 17\n", mode, attempts);
    }
}

int main(int argc, char **argv)
{
    if (argc != 2) tile_fail("reference argument");
    FILE *input = fopen(argv[1],"r");
    if (input == NULL) tile_fail("reference unavailable");
    surfer_term terms[4][256];
    surfer_prepared_surface prepared = {0};
    uint32_t full_reference[128 * 128], full_actual[128 * 128], composed[128 * 128], tile_pixels[128 * 128];
    bool covered[128 * 128];
    size_t width = 0, height = 0, x_step = 0, y_step = 0, next_x = 0, next_y = 0;
    size_t x_start = 0, y_start = 0, x_end = 0, y_end = 0, tile_width = 0, tile_height = 0;
    size_t frame_tiles = 0, current_pixels = 0, reference_pixels = 0, composed_pixels = 0, frame_differences = 0;
    size_t frames = 0, tiles = 0, tile_observations = 0, observations = 0, difference_frames = 0;
    double yaw = 0, pitch = 0, zoom = 0;
    surfer_render_quality quality = {0};
    char tag[40], identity[100], formula[512], pattern[32];
    while (fscanf(input,"%39s",tag) == 1) {
        if (strcmp(tag,"frame") == 0) {
            unsigned threshold_bits;
            if (fscanf(input,"%99s%511s%31s%x%zu%zu%la%la%la",tile_frame,formula,pattern,
                    &threshold_bits,&width,&height,&yaw,&pitch,&zoom) != 9 || width < 2 || height < 2 ||
                    width > 128 || height > 128) tile_fail("frame header");
            memcpy(&quality.threshold,&threshold_bits,sizeof(quality.threshold));
            quality.pattern = strcmp(pattern,"OG_1x1") == 0 ? SURFER_AA_OG_1X1 : SURFER_AA_QUINCUNX;
            if (strcmp(pattern,"OG_1x1") != 0 && strcmp(pattern,"QUINCUNX") != 0) tile_fail("sample pattern");
            prepared = (surfer_prepared_surface){0};
            memset(covered,0,sizeof(covered));
            frame_tiles = current_pixels = reference_pixels = composed_pixels = frame_differences = 0;
            next_x = next_y = 0;
            frames++;
        } else if (strcmp(tag,"family_degree") == 0) {
            if (fscanf(input,"%99s%" SCNd32,identity,&prepared.family_degree) != 2 ||
                strcmp(identity,tile_frame) != 0) tile_fail("family degree");
        } else if (strcmp(tag,"input") == 0) {
            unsigned component;
            size_t count;
            if (fscanf(input,"%99s%u%zu",identity,&component,&count) != 3 || component >= 4 || count > 256 ||
                strcmp(identity,tile_frame) != 0) tile_fail("prepared polynomial");
            surfer_sparse_polynomial *values[] = {&prepared.surface,&prepared.gradient_x,&prepared.gradient_y,&prepared.gradient_z};
            *values[component] = (surfer_sparse_polynomial){terms[component],count};
        } else if (strcmp(tag,"term") == 0) {
            unsigned component;
            size_t ordinal;
            if (fscanf(input,"%99s%u%zu",identity,&component,&ordinal) != 3 || component >= 4 || ordinal >= 256 ||
                strcmp(identity,tile_frame) != 0) tile_fail("prepared term identity");
            surfer_term *term = &terms[component][ordinal];
            term->coefficient = tile_read_double(input);
            if (fscanf(input,"%" SCNd32 "%" SCNd32 "%" SCNd32,&term->x_exponent,&term->y_exponent,&term->z_exponent) != 3)
                tile_fail("prepared term exponent");
        } else if (strcmp(tag,"pixel") == 0) {
            size_t x,y;
            unsigned expected;
            if (fscanf(input,"%99s%zu%zu%x",identity,&x,&y,&expected) != 4 || strcmp(identity,tile_frame) != 0 ||
                x != reference_pixels % width || y != reference_pixels / width || reference_pixels >= width * height)
                tile_fail("full-canvas reference order");
            full_reference[reference_pixels++] = expected;
        } else if (strcmp(tag,"ordered_profile") == 0) {
            size_t processors,pool;
            if (fscanf(input,"%99s%zu%zu%zu%zu",identity,&processors,&pool,&x_step,&y_step) != 5 ||
                strcmp(identity,tile_frame) != 0 || processors < 1 || pool != (processors < 4 ? processors : 4) ||
                x_step != width / (width < (processors < 2 ? 2 : processors) ? width : (processors < 2 ? 2 : processors)) ||
                y_step != height / (height < 3 ? height : 3) || reference_pixels != width * height)
                tile_fail("original partition profile");
            const surfer_scene scene = surfer_default_scene(&prepared);
            if (surfer_render_orthographic_quality(&scene,width,height,2.15,yaw,pitch,zoom,
                    quality,full_actual,width * height) != SURFER_OK ||
                memcmp(full_actual,full_reference,width * height * sizeof(*full_actual)) != 0)
                tile_fail("full-canvas wrapper changed");
        } else if (strcmp(tag,"tile") == 0) {
            if (frame_tiles > 0 && current_pixels != tile_width * tile_height) tile_fail("missing private tile pixels");
            if (fscanf(input,"%99s%zu%zu%zu%zu%zu",identity,&tile_ordinal,&x_start,&y_start,&x_end,&y_end) != 6 ||
                strcmp(identity,tile_frame) != 0 || tile_ordinal != frame_tiles || x_start != next_x || y_start != next_y ||
                x_end != (x_start + x_step < width ? x_start + x_step : width - 1) ||
                y_end != (y_start + y_step < height ? y_start + y_step : height - 1)) tile_fail("original inclusive tile bounds/order");
            tile_width = x_end - x_start + 1;
            tile_height = y_end - y_start + 1;
            const surfer_scene scene = surfer_default_scene(&prepared);
            if (surfer_render_orthographic_tile(&scene,width,height,x_start,y_start,x_end,y_end,
                    2.15,yaw,pitch,zoom,quality,NULL,tile_pixels,tile_width * tile_height) != SURFER_OK)
                tile_fail("private tile render status");
            current_pixels = 0;
            next_y += y_step;
            if (next_y >= height) { next_y = 0; next_x += x_step; }
            frame_tiles++; tiles++;
        } else if (strcmp(tag,"tile_pixel") == 0) {
            size_t ordinal,x,y;
            unsigned expected;
            if (fscanf(input,"%99s%zu%zu%zu%x",identity,&ordinal,&x,&y,&expected) != 5 ||
                strcmp(identity,tile_frame) != 0 || ordinal != tile_ordinal ||
                x != x_start + current_pixels % tile_width || y != y_start + current_pixels / tile_width ||
                current_pixels >= tile_width * tile_height) tile_fail("private pixel order");
            if (tile_pixels[current_pixels] != expected) {
                fprintf(stderr,"pixel %zu,%zu actual %08" PRIx32 " expected %08x\n",x,y,tile_pixels[current_pixels],expected);
                tile_fail("exact private tile pixel bytes");
            }
            printf("tile_argb\t%s\t%zu\t%zu\t%zu\t%08" PRIx32 "\n",tile_frame,tile_ordinal,x,y,
                tile_pixels[current_pixels]);
            composed[y * width + x] = tile_pixels[current_pixels++];
            covered[y * width + x] = true;
            tile_observations++;
        } else if (strcmp(tag,"ordered_pixel") == 0) {
            size_t x,y;
            unsigned expected;
            if (fscanf(input,"%99s%zu%zu%x",identity,&x,&y,&expected) != 4 ||
                strcmp(identity,tile_frame) != 0 || x != composed_pixels % width || y != composed_pixels / width ||
                composed_pixels >= width * height || current_pixels != tile_width * tile_height || next_x < width ||
                !covered[composed_pixels] || composed[composed_pixels] != expected) tile_fail("submission-order composition");
            printf("ordered_argb\t%s\t%zu\t%zu\t%08" PRIx32 "\n",tile_frame,x,y,composed[composed_pixels]);
            composed_pixels++; observations++;
        } else if (strcmp(tag,"ordered_difference") == 0) {
            size_t x,y;
            unsigned full,ordered;
            if (fscanf(input,"%99s%zu%zu%x%x",identity,&x,&y,&full,&ordered) != 5 ||
                strcmp(identity,tile_frame) != 0 || x >= width || y >= height || full == ordered ||
                full_reference[y * width + x] != full || composed[y * width + x] != ordered)
                tile_fail("original full-canvas difference map");
            frame_differences++;
        } else if (strcmp(tag,"ordered_summary") == 0) {
            size_t count,differences;
            if (fscanf(input,"%99s%zu%zu",identity,&count,&differences) != 3 || strcmp(identity,tile_frame) != 0 ||
                count != frame_tiles || differences != frame_differences || composed_pixels != width * height)
                tile_fail("ordered frame coverage");
            if (differences > 0) difference_frames++;
        } else if (strcmp(tag,"serial_ordered_match") == 0) {
            unsigned matches;
            if (fscanf(input,"%99s%u",identity,&matches) != 2 || strcmp(identity,tile_frame) != 0 || matches != 1)
                tile_fail("actual original serial draw comparison");
        } else tile_fail("unknown observation");
    }
    if (ferror(input) || fclose(input) != 0 || frames != 44 || observations != 5412 ||
        tiles < 44 || tile_observations < observations || difference_frames == 0)
        tile_fail("tile corpus coverage");
    printf("original tiles %zu private pixels %zu frames %zu composed pixels %zu full-canvas difference frames %zu\n",
        tiles,tile_observations,frames,observations,difference_frames);
    check_tile_refusals_and_faults();
    puts("PASS original private tile bytes inclusive overlaps and submission-order composition");
    return 0;
}
