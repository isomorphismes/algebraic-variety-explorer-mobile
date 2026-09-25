/*
 * SURFER numerical ray-tracer core.
 *
 * Derived from Christian Stussak's 2008 jsurf renderer, Apache-2.0.
 * Android adaptation copyright 2026 Algebraic Variety Explorer contributors.
 */
#ifndef SURFER_RAYTRACER_H
#define SURFER_RAYTRACER_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define SURFER_ROOT_EPSILON 1e-7
#define SURFER_MAX_LIGHTS 8

typedef struct {
    double x;
    double y;
    double z;
} surfer_vec3;

typedef struct {
    surfer_vec3 origin;
    surfer_vec3 direction;
} surfer_ray;

typedef struct {
    double m00, m01, m02;
    double m10, m11, m12;
    double m20, m21, m22;
} surfer_mat3;

typedef struct {
    surfer_ray camera_ray;
    surfer_ray clipping_ray;
    surfer_ray surface_ray;
    double eye_location_on_ray;
    surfer_mat3 surface_normal_to_camera;
} surfer_ray_bundle;

typedef struct {
    double lower;
    double upper;
} surfer_interval;

typedef struct {
    double coefficient;
    int32_t x_exponent;
    int32_t y_exponent;
    int32_t z_exponent;
} surfer_term;

typedef struct {
    const surfer_term *terms;
    size_t term_count;
} surfer_sparse_polynomial;

typedef struct {
    int32_t family_degree;
    surfer_sparse_polynomial surface;
    surfer_sparse_polynomial gradient_x;
    surfer_sparse_polynomial gradient_y;
    surfer_sparse_polynomial gradient_z;
} surfer_prepared_surface;

typedef struct {
    float red;
    float green;
    float blue;
} surfer_color;

typedef struct {
    surfer_color color;
    float ambient_intensity;
    float diffuse_intensity;
    float specular_intensity;
    float shininess;
} surfer_material;

typedef struct {
    bool enabled;
    surfer_vec3 position;
    surfer_color color;
    float intensity;
} surfer_light;

typedef struct {
    const surfer_prepared_surface *surface;
    surfer_material front_material;
    surfer_material back_material;
    surfer_color background;
    surfer_light lights[SURFER_MAX_LIGHTS];
    size_t light_count;
} surfer_scene;

typedef struct {
    bool hit;
    double ray_parameter;
    surfer_vec3 point;
    surfer_vec3 surface_normal;
    surfer_color color;
} surfer_trace_result;

/* Preserve the parameter t of origin + t * direction. */
bool surfer_clip_unit_sphere(surfer_ray ray, surfer_interval *interval);

/* Build and solve the ray polynomial with the same production split as jsurf:
 * degree-zero/one families use the closed-form linear path; degree >= 2 uses
 * the Descartes subdivision path with SURFER_ROOT_EPSILON.
 */
bool surfer_first_surface_root(
    const surfer_prepared_surface *surface,
    surfer_ray surface_ray,
    double lower,
    double upper,
    double *root);

surfer_trace_result surfer_trace_prepared_ray(
    const surfer_scene *scene,
    surfer_ray_bundle rays);

/* Current AVE orthographic camera with yaw/pitch view rotation. Pixels are
 * returned in the renderer's mathematical row order; Android's existing shell
 * flips rows. zoom=1 reproduces the configured camera height.
 */
bool surfer_render_orthographic(
    const surfer_scene *scene,
    size_t width,
    size_t height,
    double camera_height,
    double yaw,
    double pitch,
    double zoom,
    uint32_t *argb_pixels);

surfer_scene surfer_default_scene(const surfer_prepared_surface *surface);
uint32_t surfer_color_to_argb(surfer_color color);

#endif
