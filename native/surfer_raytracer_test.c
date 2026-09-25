#include "surfer_raytracer.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

static void require_true(bool condition, const char *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message);
        exit(1);
    }
}

static void require_near(double actual, double expected, double tolerance, const char *message)
{
    if (fabs(actual - expected) > tolerance) {
        fprintf(stderr, "FAIL: %s: actual=%.17g expected=%.17g\n", message, actual, expected);
        exit(1);
    }
}

static const surfer_term sphere_terms[] = {
    {1.0, 2, 0, 0},
    {1.0, 0, 2, 0},
    {1.0, 0, 0, 2},
    {-0.64, 0, 0, 0}
};
static const surfer_term sphere_dx_terms[] = {{2.0, 1, 0, 0}};
static const surfer_term sphere_dy_terms[] = {{2.0, 0, 1, 0}};
static const surfer_term sphere_dz_terms[] = {{2.0, 0, 0, 1}};

static const surfer_prepared_surface sphere = {
    2,
    {sphere_terms, sizeof(sphere_terms) / sizeof(sphere_terms[0])},
    {sphere_dx_terms, 1},
    {sphere_dy_terms, 1},
    {sphere_dz_terms, 1}
};


static const surfer_term tangent_terms[] = {
    {1.0, 2, 0, 0},
    {1.0, 0, 0, 2},
    {-0.25, 0, 0, 0}
};
static const surfer_prepared_surface tangent_surface = {
    2,
    {tangent_terms, 3},
    {NULL, 0},
    {NULL, 0},
    {NULL, 0}
};

static const surfer_term plane_terms[] = {
    {1.0, 0, 0, 1},
    {-0.25, 0, 0, 0}
};
static const surfer_term plane_dz_terms[] = {{1.0, 0, 0, 0}};
static const surfer_prepared_surface plane = {
    1,
    {plane_terms, 2},
    {NULL, 0},
    {NULL, 0},
    {plane_dz_terms, 1}
};

static void test_clip_preserves_parameter(void)
{
    surfer_interval interval;
    const surfer_ray ray = {{0.0, 0.0, 0.0}, {0.0, 0.0, -2.0}};
    require_true(surfer_clip_unit_sphere(ray, &interval), "unit-sphere clip exists");
    require_near(interval.lower, -0.5, 1e-15, "clip lower keeps original t");
    require_near(interval.upper, 0.5, 1e-15, "clip upper keeps original t");
}

static void test_sphere_first_root(void)
{
    const surfer_ray center = {{0.0, 0.0, 0.0}, {0.0, 0.0, -1.0}};
    double root = 0.0;
    require_true(
        surfer_first_surface_root(&sphere, center, -1.0, 1.0, &root),
        "sphere center ray has a root");
    require_near(root, -0.8, SURFER_ROOT_EPSILON, "first visible sphere root");
}

static void test_exact_tangent_root(void)
{
    const surfer_ray tangent = {{0.5, 0.0, 0.0}, {0.0, 0.0, -1.0}};
    double root = 99.0;
    require_true(
        surfer_first_surface_root(&tangent_surface, tangent, -0.6, 0.6, &root),
        "dyadic tangent root is retained");
    require_near(root, 0.0, 1e-15, "tangent root is zero");
}

static void test_miss(void)
{
    const surfer_ray miss = {{0.9, 0.0, 0.0}, {0.0, 0.0, -1.0}};
    double root = 0.0;
    require_true(
        !surfer_first_surface_root(&sphere, miss, -0.5, 0.5, &root),
        "ray outside sphere surface misses");
}

static void test_linear_family_uses_closed_form(void)
{
    const surfer_ray ray = {{0.0, 0.0, 0.0}, {0.0, 0.0, -1.0}};
    double root = 0.0;
    require_true(
        surfer_first_surface_root(&plane, ray, -1.0, 1.0, &root),
        "linear family has root");
    require_near(root, -0.25, 1e-15, "linear root");
}

static void test_trace_and_normal(void)
{
    const surfer_scene scene = surfer_default_scene(&sphere);
    const surfer_mat3 identity = {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0};
    const surfer_ray_bundle rays = {
        {{0.0, 0.0, -1.0}, {0.0, 0.0, -1.0}},
        {{0.0, 0.0, 0.0}, {0.0, 0.0, -1.0}},
        {{0.0, 0.0, 0.0}, {0.0, 0.0, -1.0}},
        -1.0,
        identity
    };
    const surfer_trace_result trace = surfer_trace_prepared_ray(&scene, rays);
    require_true(trace.hit, "center ray hits sphere");
    require_near(trace.point.z, -0.2, SURFER_ROOT_EPSILON, "camera-space hit follows Java ray parameter");
    require_near(trace.surface_normal.x, 0.0, 1e-7, "normal x");
    require_near(trace.surface_normal.y, 0.0, 1e-7, "normal y");
    require_near(trace.surface_normal.z, 1.0, 1e-7, "normal faces eye");
    require_true(trace.color.red > trace.color.green, "front material remains orange-red");
}


static size_t foreground_count(const uint32_t *pixels, size_t count, uint32_t background)
{
    size_t foreground = 0;
    for (size_t i = 0; i < count; ++i) {
        if (pixels[i] != background) {
            ++foreground;
        }
    }
    return foreground;
}

static void test_render_has_surface_and_background(void)
{
    enum { WIDTH = 48, HEIGHT = 48 };
    uint32_t pixels[WIDTH * HEIGHT];
    const surfer_scene scene = surfer_default_scene(&sphere);
    require_true(
        surfer_render_orthographic(&scene, WIDTH, HEIGHT, 2.15, 0.0, 0.0, 1.0, pixels),
        "orthographic render succeeds");

    const uint32_t background = surfer_color_to_argb(scene.background);
    const size_t foreground = foreground_count(
        pixels, WIDTH * HEIGHT, background);
    require_true(foreground > 500, "render contains sphere foreground");
    require_true(foreground < 1400, "render retains background around sphere");
}


static void test_rotated_sphere_keeps_silhouette(void)
{
    enum { WIDTH = 40, HEIGHT = 40 };
    uint32_t identity_pixels[WIDTH * HEIGHT];
    uint32_t rotated_pixels[WIDTH * HEIGHT];
    const surfer_scene scene = surfer_default_scene(&sphere);
    const uint32_t background = surfer_color_to_argb(scene.background);
    require_true(
        surfer_render_orthographic(
            &scene, WIDTH, HEIGHT, 2.15, 0.0, 0.0, 1.0, identity_pixels),
        "identity sphere render succeeds");
    require_true(
        surfer_render_orthographic(
            &scene, WIDTH, HEIGHT, 2.15, 0.63, -0.41, 1.0, rotated_pixels),
        "rotated sphere render succeeds");
    require_true(
        foreground_count(identity_pixels, WIDTH * HEIGHT, background) ==
            foreground_count(rotated_pixels, WIDTH * HEIGHT, background),
        "rotating a sphere preserves its silhouette");
}

int main(void)
{
    test_clip_preserves_parameter();
    test_sphere_first_root();
    test_exact_tangent_root();
    test_miss();
    test_linear_family_uses_closed_form();
    test_trace_and_normal();
    test_render_has_surface_and_background();
    test_rotated_sphere_keeps_silhouette();
    puts("SURFER prepared-surface C ray tracer: PASS");
    return 0;
}
