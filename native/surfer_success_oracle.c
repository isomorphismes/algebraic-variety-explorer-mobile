/* Strict-FP byte observation of the existing successful numerical path.
 * The build selects either the exact retained base headers/core or the current
 * status API. This adapter changes no formula, camera or numerical operation.
 */
#include <surfer_raytracer.h>
#include <presets.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void write_exact(const void *bytes, size_t size)
{
    if (fwrite(bytes, 1, size, stdout) != size) exit(1);
}

int main(void)
{
    enum { WIDTH = 37, HEIGHT = 31 };
    uint32_t pixels[WIDTH * HEIGHT];
    const surfer_ray center = {{0, 0, 0}, {0, 0, -1}};
    for (size_t index = 0; index < ave_native_preset_count(); ++index) {
        ave_native_preset preset;
        if (!ave_native_load_preset(index, &preset)) exit(1);
        const surfer_scene scene = surfer_default_scene(&preset.surface);
#ifdef SURFER_STATUS_API
        if (surfer_render_orthographic(&scene, WIDTH, HEIGHT, 2.15,
                0.37, -0.19, 1.1, pixels, WIDTH * HEIGHT) != SURFER_OK) exit(1);
        uint32_t background = 0;
        if (surfer_color_to_argb(scene.background, &background) != SURFER_OK) exit(1);
#else
        if (!surfer_render_orthographic(&scene, WIDTH, HEIGHT, 2.15,
                0.37, -0.19, 1.1, pixels)) exit(1);
        const uint32_t background = surfer_color_to_argb(scene.background);
#endif
        size_t foreground = 0;
        for (size_t i = 0; i < WIDTH * HEIGHT; ++i) {
            if (pixels[i] != background) ++foreground;
        }
        if (foreground == 0) exit(1);
        write_exact(pixels, sizeof(pixels));
        double root = 99;
#ifdef SURFER_STATUS_API
        const surfer_status status = surfer_first_surface_root(&preset.surface, center, -1, 1, &root);
        if (status != SURFER_OK && status != SURFER_MISS) exit(1);
        const unsigned char hit = status == SURFER_OK ? 1 : 0;
#else
        const unsigned char hit = surfer_first_surface_root(&preset.surface, center, -1, 1, &root) ? 1 : 0;
#endif
        uint64_t root_bits = 0;
        memcpy(&root_bits, &root, sizeof(root_bits));
        write_exact(&hit, sizeof(hit));
        write_exact(&root_bits, sizeof(root_bits));
    }
    return fflush(stdout) == 0 ? 0 : 1;
}
