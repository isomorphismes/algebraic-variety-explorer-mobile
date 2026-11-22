/* Stussak's original orthographic camera composition, Apache-2.0.
 * Copyright 2008 Christian Stussak; C adaptation copyright 2026 AVE contributors.
 * The separately compiled vecmath primitives retain their own GPL2 Classpath
 * license and notices in surfer_vecmath.c and licenses/vecmath-GPL-2-CE.txt.
 */
#include "surfer_vecmath.h"

typedef surfer_vecmath_matrix4 original_matrix4;

struct original_camera_view {
    original_matrix4 input_view, input_camera, input_surface;
    original_matrix4 camera_to_clipping, camera_to_surface, surface_normal_to_camera;
    surfer_vec3 camera_origin, camera_direction, camera_du, camera_dv;
    surfer_vec3 surface_origin, surface_direction, surface_du, surface_dv;
    surfer_vec3 clipping_origin, clipping_direction, clipping_du, clipping_dv;
    double camera_height, uscale, vscale, uoffset, voffset, eye_location;
};

static original_matrix4 original_identity4(void)
{
    return surfer_vecmath_identity4();
}

static original_matrix4 original_multiply4(original_matrix4 left, original_matrix4 right)
{
    return surfer_vecmath_multiply4(left, right);
}

static bool original_matrix_proceed(void *state)
{
    return continue_operation(state);
}

static bool original_inverse4(surfer_operation_context *context,
    original_matrix4 input, original_matrix4 *inverse)
{
    if (surfer_vecmath_inverse4(input, inverse, original_matrix_proceed, context)) return true;
    if (context->status == SURFER_OK) context->status = SURFER_INVALID_INPUT;
    return false;
}

static surfer_vec3 original_transform_vector4(original_matrix4 matrix, surfer_vec3 value)
{
    const surfer_vecmath_vector3 result = surfer_vecmath_transform_vector4(matrix,
        (surfer_vecmath_vector3){value.x, value.y, value.z});
    return (surfer_vec3){result.x, result.y, result.z};
}

static surfer_vec3 original_transform_point4(original_matrix4 matrix, surfer_vec3 value)
{
    const surfer_vecmath_vector3 result = surfer_vecmath_transform_point4(matrix,
        (surfer_vecmath_vector3){value.x, value.y, value.z});
    return (surfer_vec3){result.x, result.y, result.z};
}

static surfer_mat3 original_upper_matrix3(original_matrix4 matrix)
{
    const double *entries = matrix.entries;
    return (surfer_mat3){entries[0], entries[1], entries[2], entries[4], entries[5],
        entries[6], entries[8], entries[9], entries[10]};
}

static surfer_vec3 original_scale_add(double scale, surfer_vec3 vector, surfer_vec3 base)
{
    return (surfer_vec3){scale * vector.x + base.x, scale * vector.y + base.y, scale * vector.z + base.z};
}

static surfer_vec3 original_interpolate2(surfer_vec3 origin, surfer_vec3 horizontal,
    surfer_vec3 vertical, double u, double v)
{
    return (surfer_vec3){origin.x + horizontal.x * u + vertical.x * v,
        origin.y + horizontal.y * u + vertical.y * v,
        origin.z + horizontal.z * u + vertical.z * v};
}

static surfer_ray_bundle original_camera_ray_bundle(const original_camera_view *camera,
    double u, double v)
{
    return (surfer_ray_bundle){
        {original_interpolate2(camera->camera_origin, camera->camera_du, camera->camera_dv, u, v), camera->camera_direction},
        {original_interpolate2(camera->clipping_origin, camera->clipping_du, camera->clipping_dv, u, v), camera->clipping_direction},
        {original_interpolate2(camera->surface_origin, camera->surface_du, camera->surface_dv, u, v), camera->surface_direction},
        camera->eye_location, original_upper_matrix3(camera->surface_normal_to_camera)};
}

static bool make_original_orthographic_view(surfer_operation_context *context,
    size_t width, size_t height, double camera_height, double yaw, double pitch, double zoom,
    original_camera_view *camera, orthographic_view *view)
{
    if (!continue_operation(context)) return false;
    memset(camera, 0, sizeof(*camera));
    const double sine_yaw = sin(yaw), cosine_yaw = cos(yaw);
    const double sine_pitch = sin(pitch), cosine_pitch = cos(pitch);
    const original_matrix4 yaw_rotation = {{cosine_yaw, 0.0, sine_yaw, 0.0,
        0.0, 1.0, 0.0, 0.0, -sine_yaw, 0.0, cosine_yaw, 0.0, 0.0, 0.0, 0.0, 1.0}};
    const original_matrix4 pitch_rotation = {{1.0, 0.0, 0.0, 0.0,
        0.0, cosine_pitch, -sine_pitch, 0.0, 0.0, sine_pitch, cosine_pitch, 0.0, 0.0, 0.0, 0.0, 1.0}};
    camera->input_view = original_multiply4(yaw_rotation, pitch_rotation);
    camera->input_camera = original_identity4();
    camera->input_camera.entries[11] = -1.0;
    camera->input_surface = original_identity4();
    original_matrix4 inverse_camera;
    if (!original_inverse4(context, camera->input_camera, &inverse_camera)) return false;
    camera->camera_to_clipping = original_multiply4(camera->input_view, inverse_camera);
    camera->camera_to_surface = original_multiply4(camera->input_surface, camera->camera_to_clipping);
    if (!original_inverse4(context, camera->camera_to_surface, &camera->surface_normal_to_camera)) return false;
    camera->camera_height = camera_height / zoom;
    camera->camera_dv = (surfer_vec3){0.0, camera->camera_height / 2.0, 0.0};
    camera->camera_du = (surfer_vec3){(camera->camera_dv.y * (double)width) / (double)height, 0.0, 0.0};
    camera->camera_direction = (surfer_vec3){0.0, 0.0, -1.0};
    camera->surface_du = original_transform_vector4(camera->camera_to_surface, camera->camera_du);
    camera->surface_dv = original_transform_vector4(camera->camera_to_surface, camera->camera_dv);
    camera->uscale = length_of_vector(camera->surface_du);
    camera->vscale = length_of_vector(camera->surface_dv);
    camera->surface_du = scale_vector(camera->surface_du, 1.0 / camera->uscale);
    camera->surface_dv = scale_vector(camera->surface_dv, 1.0 / camera->vscale);
    camera->surface_direction = original_transform_vector4(camera->camera_to_surface, camera->camera_direction);
    const double direction_scale = length_of_vector(camera->surface_direction);
    camera->surface_direction = scale_vector(camera->surface_direction, 1.0 / direction_scale);
    camera->surface_origin = original_transform_point4(camera->camera_to_surface, (surfer_vec3){0.0, 0.0, 0.0});
    const double plane_distance = dot_product(camera->surface_direction, camera->surface_origin);
    const surfer_vec3 projected = original_scale_add(-plane_distance, camera->surface_direction, camera->surface_origin);
    camera->uoffset = dot_product(projected, camera->surface_du);
    camera->voffset = dot_product(projected, camera->surface_dv);
    camera->surface_origin = (surfer_vec3){0.0, 0.0, 0.0};
    camera->camera_du = scale_vector(camera->camera_du, 1.0 / camera->uscale);
    camera->camera_dv = scale_vector(camera->camera_dv, 1.0 / camera->vscale);
    camera->camera_direction = scale_vector(camera->camera_direction, 1.0 / direction_scale);
    camera->camera_origin = scale_vector(camera->camera_direction, -plane_distance);
    camera->camera_origin = original_scale_add(camera->uoffset, camera->camera_du, camera->camera_origin);
    camera->camera_origin = original_scale_add(camera->voffset, camera->camera_dv, camera->camera_origin);
    camera->clipping_origin = original_transform_point4(camera->camera_to_clipping, camera->camera_origin);
    camera->clipping_du = original_transform_vector4(camera->camera_to_clipping, camera->camera_du);
    camera->clipping_dv = original_transform_vector4(camera->camera_to_clipping, camera->camera_dv);
    camera->clipping_direction = original_transform_vector4(camera->camera_to_clipping, camera->camera_direction);
    camera->eye_location = plane_distance;
    *view = (orthographic_view){camera->uscale, camera->vscale,
        original_upper_matrix3(camera->camera_to_surface), original_upper_matrix3(camera->surface_normal_to_camera),
        camera->surface_du, camera->surface_dv, camera->surface_direction, camera};
    const surfer_vec3 vectors[] = {camera->camera_origin, camera->camera_direction,
        camera->camera_du, camera->camera_dv, camera->surface_origin, camera->surface_direction,
        camera->surface_du, camera->surface_dv, camera->clipping_origin, camera->clipping_direction,
        camera->clipping_du, camera->clipping_dv};
    for (size_t index = 0; index < sizeof(vectors) / sizeof(vectors[0]); ++index)
        if (!finite_vector(vectors[index])) { context->status = SURFER_INVALID_INPUT; return false; }
    if (!isfinite(camera->uoffset) || !isfinite(camera->voffset) ||
        !isfinite(camera->uscale) || !isfinite(camera->vscale) ||
        !isfinite(camera->eye_location)) { context->status = SURFER_INVALID_INPUT; return false; }
    return continue_operation(context);
}
