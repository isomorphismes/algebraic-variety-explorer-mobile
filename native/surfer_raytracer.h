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

typedef enum {
    SURFER_OK = 0,
    SURFER_MISS = 1,
    SURFER_INVALID_INPUT = 2,
    SURFER_OUT_OF_MEMORY = 3,
    SURFER_CANCELLED = 4
} surfer_status;

const char *surfer_status_name(surfer_status status);

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

/*
 * Stussak's RayCreator contract: camera, clipping, and surface-space rays all
 * use the same parameter t. Keeping them together makes that invariant visible.
 */
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

/*
 * PreparedSurface is the adaptation boundary, not a replacement name for a
 * Stussak class: the semantic layer hands the numerical renderer the surface
 * and the three already-differentiated polynomials.
 */
typedef struct {
    int32_t family_degree;
    surfer_sparse_polynomial surface;
    surfer_sparse_polynomial gradient_x;
    surfer_sparse_polynomial gradient_y;
    surfer_sparse_polynomial gradient_z;
} surfer_prepared_surface;

/* Validate borrowed storage and source-family degree without computing or
 * semantically verifying derivatives. Zero-count polynomials are valid.
 */
surfer_status surfer_validate_prepared_surface(const surfer_prepared_surface *surface);

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
    surfer_status status;
    double ray_parameter;
    surfer_vec3 point;
    surfer_vec3 surface_normal;
    surfer_color color;
} surfer_trace_result;

/* Preserve the parameter t of origin + t * direction. */
surfer_status surfer_clip_unit_sphere(surfer_ray ray, surfer_interval *interval);

/* Build and solve the ray polynomial with the same production split as jsurf:
 * degree-zero/one families use the closed-form linear path; degree >= 2 uses
 * the Descartes subdivision path with SURFER_ROOT_EPSILON.
 */
surfer_status surfer_first_surface_root(
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
surfer_status surfer_render_orthographic(
    const surfer_scene *scene,
    size_t width,
    size_t height,
    double camera_height,
    double yaw,
    double pitch,
    double zoom,
    uint32_t *argb_pixels,
    size_t pixel_capacity);

typedef enum {
    SURFER_AA_OG_1X1 = 0,
    SURFER_AA_QUINCUNX = 1
} surfer_antialiasing_pattern;

typedef struct {
    surfer_antialiasing_pattern pattern;
    /* Original ADAPTIVE_SUPERSAMPLING uses 0.3f; SUPERSAMPLING uses 0.0f. */
    float threshold;
} surfer_render_quality;

/* One full-canvas original RenderingTask sampling order. This additive entry
 * leaves the legacy single-sample entry above unchanged. Four prepared XYZ
 * polynomials are transformed once, specialized by row and column, and their
 * gradient univariates are evaluated at the hit. Threshold, weights and colors
 * remain F32. The restricted AVE orthographic camera preserves the original
 * matrix/inverse/normalization/offset sequence. Full image and tile parity
 * require separate observations.
 */
surfer_status surfer_render_orthographic_quality(
    const surfer_scene *scene, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, uint32_t *argb_pixels, size_t pixel_capacity);

/* Synchronous borrowed predicate; its state must stay alive for this call and
 * be safe to read while another thread cancels. No pointer is retained.
 * A non-OK result invalidates the complete output, including partial writes.
 * The session owner provides retained identities and transactional publication.
 */
typedef struct {
    bool (*cancelled)(void *state);
    void *state;
} surfer_cancellation;

surfer_status surfer_render_orthographic_cancellable(
    const surfer_scene *scene, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, const surfer_cancellation *cancellation,
    uint32_t *argb_pixels, size_t pixel_capacity);

/* One original RenderingTask rectangle in the complete canvas coordinate
 * system. Bounds are inclusive. Output is a tightly packed rectangle of
 * (x_end-x_start+1)*(y_end-y_start+1) pixels in mathematical row order.
 * Its transformed polynomial/row/corner storage is private to this call.
 * No scene, cancellation state or pixel pointer is retained. NULL cancellation
 * selects no cancellation; a supplied predicate must be safe on this worker.
 * Invalid inputs write no pixels; runtime failure invalidates the whole tile.
 * The caller owns overlapping-tile ordering and complete-frame publication.
 */
surfer_status surfer_render_orthographic_tile(
    const surfer_scene *scene, size_t width, size_t height,
    size_t x_start, size_t y_start, size_t x_end, size_t y_end,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, const surfer_cancellation *cancellation,
    uint32_t *argb_pixels, size_t pixel_capacity);

surfer_scene surfer_default_scene(const surfer_prepared_surface *surface);
surfer_status surfer_color_to_argb(surfer_color color, uint32_t *argb);

/* Output values are written only on OK, except a valid trace MISS carries the
 * background. Render validates input before writing any pixels. Runtime failure
 * invalidates the complete frame even when some output pixels were written.
 * Surface arrays are borrowed and immutable for the synchronous call only.
 */

#ifdef SURFER_TEST_ALLOCATION_FAILURES
/* Caller-owned fault injection; no global state or production ABI. SIZE_MAX
 * disables injection. Each nonzero allocation/reallocation attempt is counted.
 */
typedef struct {
    size_t fail_at;
    size_t attempts;
    uint32_t paths;
} surfer_allocation_probe;

surfer_status surfer_test_first_surface_root(
    const surfer_prepared_surface *surface, surfer_ray ray,
    double lower, double upper, double *root, surfer_allocation_probe *probe);
surfer_status surfer_test_render_orthographic(
    const surfer_scene *scene, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    uint32_t *argb_pixels, size_t pixel_capacity, surfer_allocation_probe *probe);
surfer_status surfer_test_render_orthographic_quality(
    const surfer_scene *scene, size_t width, size_t height,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, uint32_t *argb_pixels, size_t pixel_capacity,
    surfer_allocation_probe *probe);
surfer_status surfer_test_render_orthographic_tile(
    const surfer_scene *scene, size_t width, size_t height,
    size_t x_start, size_t y_start, size_t x_end, size_t y_end,
    double camera_height, double yaw, double pitch, double zoom,
    surfer_render_quality quality, const surfer_cancellation *cancellation,
    uint32_t *argb_pixels, size_t pixel_capacity, surfer_allocation_probe *probe);
#endif

#endif
