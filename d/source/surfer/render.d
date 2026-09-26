module surfer.render;

import core.atomic : atomicLoad, atomicStore;
import std.algorithm.comparison : max;
import std.exception : enforce;
import std.math : PI, isNaN, pow, sqrt, tan;
import std.parallelism : parallel;
import std.range : iota;

import surfer.math3 : Affine, Color, Interval, Ray, Vec3, color_difference_squared, dot;
import surfer.parser : parse_polynomial;
import surfer.polynomial : Polynomial;
import surfer.roots : DescartesRootFinder;

enum CameraType {
    orthographic,
    perspective
}

struct Camera {
    CameraType type = CameraType.orthographic;
    double fov_y_degrees = 60.0;
    double height = 2.0;
    Affine transform;

    static Camera defaults() {
        Camera result;
        result.transform = Affine.identity();
        return result;
    }
}

struct Material {
    Color color = Color(0.5f, 0.5f, 0.5f);
    float ambient = 0.1f;
    float diffuse = 0.23232f;
    float specular = 0.9f;
    float shininess = 1.0f;
}

struct Light {
    bool enabled;
    Vec3 position;
    Color color = Color(1.0f, 1.0f, 1.0f);
    float intensity = 1.0f;
}

enum AntiAliasingMode {
    supersampling,
    adaptive_supersampling
}

enum AntiAliasingPattern {
    og_1x1,
    og_2x2,
    og_3x3,
    og_4x4,
    og_5x5,
    og_6x6,
    og_7x7,
    og_8x8,
    rg_2x2,
    quincunx
}

struct SamplingPoint {
    double u;
    double v;
    float weight;
}

private uint ordered_grid_size(AntiAliasingPattern pattern) pure nothrow @safe {
    final switch (pattern) {
        case AntiAliasingPattern.og_1x1: return 1;
        case AntiAliasingPattern.og_2x2: return 2;
        case AntiAliasingPattern.og_3x3: return 3;
        case AntiAliasingPattern.og_4x4: return 4;
        case AntiAliasingPattern.og_5x5: return 5;
        case AntiAliasingPattern.og_6x6: return 6;
        case AntiAliasingPattern.og_7x7: return 7;
        case AntiAliasingPattern.og_8x8: return 8;
        case AntiAliasingPattern.rg_2x2: return 0;
        case AntiAliasingPattern.quincunx: return 0;
    }
}

SamplingPoint[] sampling_points(AntiAliasingPattern pattern) {
    const size = ordered_grid_size(pattern);
    if (size != 0) {
        if (size == 1)
            return [SamplingPoint(0.5, 0.5, 1.0f)];

        double[] axis_weight = new double[size];
        double axis_sum = 0.0;
        foreach (i; 0 .. size) {
            const left = cast(double) (i + 1);
            const right = cast(double) (size - i);
            axis_weight[i] = left < right ? left : right;
            axis_sum += axis_weight[i];
        }

        SamplingPoint[] points;
        points.reserve(size * size);
        foreach (i; 0 .. size) {
            foreach (j; 0 .. size) {
                points ~= SamplingPoint(
                    cast(double) i / cast(double) (size - 1),
                    cast(double) j / cast(double) (size - 1),
                    cast(float) ((axis_weight[i] * axis_weight[j]) / (axis_sum * axis_sum))
                );
            }
        }
        return points;
    }

    if (pattern == AntiAliasingPattern.rg_2x2) {
        enum inner_weight = 0.15f;
        enum outer_weight = 0.25f * (1.0f - 4.0f * inner_weight);
        return [
            SamplingPoint(0.185416, 0.282652, inner_weight),
            SamplingPoint(0.28262799, 0.234047, inner_weight),
            SamplingPoint(0.136813, 0.18544099, inner_weight),
            SamplingPoint(0.234026, 0.136838, inner_weight),
            SamplingPoint(0.0, 0.0, outer_weight),
            SamplingPoint(0.0, 1.0, outer_weight),
            SamplingPoint(1.0, 1.0, outer_weight),
            SamplingPoint(1.0, 0.0, outer_weight)
        ];
    }

    enum boundary_weight = 0.0625f + 0.25f / 3.0f;
    return [
        SamplingPoint(0.0, 0.0, boundary_weight),
        SamplingPoint(0.0, 1.0, boundary_weight),
        SamplingPoint(1.0, 1.0, boundary_weight),
        SamplingPoint(1.0, 0.0, boundary_weight),
        SamplingPoint(0.5, 0.5, 1.0f - 4.0f * boundary_weight)
    ];
}

private struct RayBundle {
    Ray camera;
    Ray clipping;
    Ray surface;
}

private struct RayFactory {
    CameraType type;
    Affine camera_to_clipping;
    Affine camera_to_surface;
    Affine surface_normal_to_camera;

    Vec3 ray_origin;
    Vec3 ray_direction;
    Vec3 du;
    Vec3 dv;
    Vec3 clipping_ray_origin;
    Vec3 clipping_ray_direction;
    Vec3 clipping_du;
    Vec3 clipping_dv;
    Vec3 surface_ray_origin;
    Vec3 surface_ray_direction;
    Vec3 surface_du;
    Vec3 surface_dv;
    double u_scale;
    double v_scale;
    double u_offset;
    double v_offset;
    double eye_location;

    Vec3 upper_left;
    Vec3 perspective_dx;
    Vec3 perspective_dy;
    Vec3 clipping_upper_left;
    Vec3 clipping_dx;
    Vec3 clipping_dy;
    Vec3 surface_upper_left;
    Vec3 surface_dx;
    Vec3 surface_dy;
    double best_start;
    double perspective_scale;

    static RayFactory make(Affine transform,
                           Affine surface_transform,
                           Camera camera,
                           uint width,
                           uint height)
    {
        enforce(width > 1 && height > 1, "render dimensions must both exceed one pixel");
        RayFactory result;
        result.type = camera.type;
        const camera_inverse = camera.transform.inverse();
        result.camera_to_clipping = transform * camera_inverse;
        result.camera_to_surface = surface_transform * result.camera_to_clipping;
        result.surface_normal_to_camera = result.camera_to_surface.inverse();

        if (camera.type == CameraType.orthographic)
            result.configure_orthographic(camera, width, height);
        else
            result.configure_perspective(camera, width, height);
        return result;
    }

    private void configure_orthographic(Camera camera, uint width, uint height) {
        dv = Vec3(0.0, camera.height / 2.0, 0.0);
        du = Vec3((dv.y * cast(double) width) / cast(double) height, 0.0, 0.0);
        ray_direction = Vec3(0.0, 0.0, -1.0);

        surface_du = camera_to_surface.apply_vector(du);
        surface_dv = camera_to_surface.apply_vector(dv);
        u_scale = surface_du.length();
        v_scale = surface_dv.length();
        surface_du = surface_du / u_scale;
        surface_dv = surface_dv / v_scale;

        surface_ray_direction = camera_to_surface.apply_vector(ray_direction);
        const direction_scale = surface_ray_direction.length();
        surface_ray_direction = surface_ray_direction / direction_scale;

        auto transformed_origin = camera_to_surface.apply_point(Vec3(0.0, 0.0, 0.0));
        const plane_distance = dot(surface_ray_direction, transformed_origin);
        const projected_camera_origin = transformed_origin + surface_ray_direction * (-plane_distance);
        u_offset = dot(projected_camera_origin, surface_du);
        v_offset = dot(projected_camera_origin, surface_dv);

        surface_ray_origin = Vec3(0.0, 0.0, 0.0);
        du = du / u_scale;
        dv = dv / v_scale;
        ray_direction = ray_direction / direction_scale;
        ray_origin = ray_direction * (-plane_distance) + du * u_offset + dv * v_offset;

        clipping_ray_origin = camera_to_clipping.apply_point(ray_origin);
        clipping_du = camera_to_clipping.apply_vector(du);
        clipping_dv = camera_to_clipping.apply_vector(dv);
        clipping_ray_direction = camera_to_clipping.apply_vector(ray_direction);
        eye_location = plane_distance;
    }

    private void configure_perspective(Camera camera, uint width, uint height) {
        upper_left = Vec3();
        upper_left.y = tan(PI / 180.0 * (camera.fov_y_degrees / 2.0));
        upper_left.x = upper_left.y * cast(double) width / cast(double) height;
        upper_left.z = -1.0;
        perspective_dx = Vec3(2.0 * upper_left.x, 0.0, 0.0);
        perspective_dy = Vec3(0.0, 2.0 * upper_left.y, 0.0);

        clipping_upper_left = camera_to_clipping.apply_point(upper_left);
        clipping_dx = camera_to_clipping.apply_vector(perspective_dx);
        clipping_dy = camera_to_clipping.apply_vector(perspective_dy);
        surface_upper_left = camera_to_surface.apply_point(upper_left);
        surface_dx = camera_to_surface.apply_vector(perspective_dx);
        surface_dy = camera_to_surface.apply_vector(perspective_dy);

        ray_origin = Vec3(0.0, 0.0, 0.0);
        clipping_ray_origin = camera_to_clipping.apply_point(ray_origin);
        surface_ray_origin = camera_to_surface.apply_point(ray_origin);

        auto clipping_direction =
            interpolate2(clipping_upper_left, clipping_dx, clipping_dy, 0.5, 0.5)
            - clipping_ray_origin;
        auto surface_direction =
            interpolate2(surface_upper_left, surface_dx, surface_dy, 0.5, 0.5)
            - surface_ray_origin;
        best_start = -dot(clipping_upper_left, clipping_direction)
            / dot(clipping_direction, clipping_direction);
        perspective_scale = 0.5 * surface_direction.length();
        eye_location = -best_start;
    }

    double transform_u(double normalized) const pure nothrow @safe {
        return type == CameraType.orthographic
            ? u_offset + u_scale * (2.0 * normalized - 1.0)
            : normalized;
    }

    double transform_v(double normalized) const pure nothrow @safe {
        return type == CameraType.orthographic
            ? v_offset + v_scale * (2.0 * normalized - 1.0)
            : normalized;
    }

    RayBundle rays(double u, double v) const {
        if (type == CameraType.orthographic) {
            return RayBundle(
                Ray(interpolate2(ray_origin, du, dv, u, v), ray_direction),
                Ray(interpolate2(clipping_ray_origin, clipping_du, clipping_dv, u, v),
                    clipping_ray_direction),
                Ray(interpolate2(surface_ray_origin, surface_du, surface_dv, u, v),
                    surface_ray_direction)
            );
        }

        auto camera_direction =
            interpolate2(upper_left, perspective_dx, perspective_dy, u, v) - ray_origin;
        auto clipping_direction =
            interpolate2(clipping_upper_left, clipping_dx, clipping_dy, u, v)
            - clipping_ray_origin;
        auto surface_direction =
            interpolate2(surface_upper_left, surface_dx, surface_dy, u, v)
            - surface_ray_origin;

        return RayBundle(
            optimized_perspective_ray(ray_origin, camera_direction),
            optimized_perspective_ray(clipping_ray_origin, clipping_direction),
            optimized_perspective_ray(surface_ray_origin, surface_direction)
        );
    }

    Vec3 normal_to_camera(Vec3 surface_normal) const {
        return surface_normal_to_camera.apply_vector(surface_normal);
    }

    private Ray optimized_perspective_ray(Vec3 origin, Vec3 direction) const pure nothrow @safe {
        return Ray(origin + direction * best_start, direction * perspective_scale);
    }

    private static Vec3 interpolate2(Vec3 origin, Vec3 horizontal, Vec3 vertical,
                                     double u, double v) pure nothrow @safe
    {
        return origin + horizontal * u + vertical * v;
    }
}

class Renderer {
    string formula = "z";
    double[string] parameters;

    Camera camera;
    Affine transform;
    Affine surface_transform;
    Material front_material;
    Material back_material;
    Light[8] lights;
    Color background = Color(1.0f, 1.0f, 1.0f);
    AntiAliasingMode anti_aliasing_mode = AntiAliasingMode.adaptive_supersampling;
    AntiAliasingPattern anti_aliasing_pattern = AntiAliasingPattern.og_4x4;
    float anti_aliasing_threshold = 0.3f;

    private shared bool stop_requested;

    this() {
        camera = Camera.defaults();
        transform = Affine.identity();
        surface_transform = Affine.identity();
        front_material = Material();
        back_material = Material();
        lights[0].enabled = true;
    }

    void set_surface_family(string source) {
        formula = source;
    }

    void set_parameter(string name, double value) {
        parameters[name] = value;
    }

    uint surface_total_degree() {
        return parse_polynomial(formula, parameters).total_degree();
    }

    void cancel() nothrow {
        atomicStore(stop_requested, true);
    }

    uint[] draw(uint width, uint height) {
        enforce(width > 1 && height > 1, "render dimensions must both exceed one pixel");
        atomicStore(stop_requested, false);

        auto surface = parse_polynomial(formula, parameters);
        auto gradient_x = surface.derivative('x');
        auto gradient_y = surface.derivative('y');
        auto gradient_z = surface.derivative('z');
        auto ray_factory = RayFactory.make(transform, surface_transform, camera, width, height);
        const threshold = anti_aliasing_mode == AntiAliasingMode.supersampling
            ? 0.0f : anti_aliasing_threshold;

        auto pixels = new uint[cast(size_t) width * height];
        const count = pixels.length;
        foreach (index; parallel(iota(count))) {
            if (atomicLoad(stop_requested))
                continue;
            const y = cast(uint) (index / width);
            const x = cast(uint) (index % width);
            const color = sample_pixel(
                x, y, width, height,
                ray_factory,
                surface, gradient_x, gradient_y, gradient_z,
                threshold
            );
            pixels[index] = color.to_argb();
        }
        return pixels;
    }

    private Color sample_pixel(uint x, uint y, uint width, uint height,
                               RayFactory ray_factory,
                               Polynomial surface,
                               Polynomial gradient_x,
                               Polynomial gradient_y,
                               Polynomial gradient_z,
                               float threshold) const
    {
        if (anti_aliasing_pattern == AntiAliasingPattern.og_1x1) {
            const u = ray_factory.transform_u(cast(double) x / cast(double) (width - 1));
            const v = ray_factory.transform_v(cast(double) y / cast(double) (height - 1));
            return trace(u, v, ray_factory, surface, gradient_x, gradient_y, gradient_z);
        }

        const lower_u_normalized = (cast(double) x - 0.5) / cast(double) (width - 1);
        const lower_v_normalized = (cast(double) y - 0.5) / cast(double) (height - 1);
        const upper_u_normalized = (cast(double) x + 0.5) / cast(double) (width - 1);
        const upper_v_normalized = (cast(double) y + 0.5) / cast(double) (height - 1);

        const lower_u = ray_factory.transform_u(lower_u_normalized);
        const lower_v = ray_factory.transform_v(lower_v_normalized);
        const upper_u = ray_factory.transform_u(upper_u_normalized);
        const upper_v = ray_factory.transform_v(upper_v_normalized);

        const lower_left =
            trace(lower_u, lower_v, ray_factory, surface, gradient_x, gradient_y, gradient_z);
        const upper_left =
            trace(lower_u, upper_v, ray_factory, surface, gradient_x, gradient_y, gradient_z);
        const upper_right =
            trace(upper_u, upper_v, ray_factory, surface, gradient_x, gradient_y, gradient_z);
        const lower_right =
            trace(upper_u, lower_v, ray_factory, surface, gradient_x, gradient_y, gradient_z);

        const threshold_squared = threshold * threshold;
        const needs_refinement = anti_aliasing_pattern != AntiAliasingPattern.og_2x2
            && (color_difference_squared(upper_left, upper_right) >= threshold_squared
                || color_difference_squared(upper_left, lower_left) >= threshold_squared
                || color_difference_squared(upper_left, lower_right) >= threshold_squared
                || color_difference_squared(upper_right, lower_left) >= threshold_squared
                || color_difference_squared(upper_right, lower_right) >= threshold_squared
                || color_difference_squared(lower_left, lower_right) >= threshold_squared);

        if (!needs_refinement)
            return ((upper_left + upper_right + lower_left + lower_right) * 0.25f).clamped();

        Color result;
        const u_width = upper_u - lower_u;
        const v_height = upper_v - lower_v;
        foreach (point; sampling_points(anti_aliasing_pattern)) {
            Color sample;
            if (point.u == 0.0 && point.v == 0.0)
                sample = lower_left;
            else if (point.u == 0.0 && point.v == 1.0)
                sample = upper_left;
            else if (point.u == 1.0 && point.v == 1.0)
                sample = upper_right;
            else if (point.u == 1.0 && point.v == 0.0)
                sample = lower_right;
            else
                sample = trace(
                    lower_u + point.u * u_width,
                    lower_v + point.v * v_height,
                    ray_factory, surface, gradient_x, gradient_y, gradient_z
                );
            result = result + sample * point.weight;
        }
        return result.clamped();
    }

    private Color trace(double u, double v,
                        RayFactory ray_factory,
                        Polynomial surface,
                        Polynomial gradient_x,
                        Polynomial gradient_y,
                        Polynomial gradient_z) const
    {
        const bundle = ray_factory.rays(u, v);
        const clipping = clip_to_unit_sphere(bundle.clipping);
        if (clipping.upper < clipping.lower)
            return background;

        auto lower = clipping.lower;
        const upper = clipping.upper;
        const eye = ray_factory.eye_location;
        if (lower < eye && eye < upper)
            lower = eye;

        const along_ray = surface.along(bundle.surface);
        const hit = DescartesRootFinder().find_first_root_in(along_ray, lower, upper);
        if (isNaN(hit))
            return background;

        const surface_point = bundle.surface.at(hit);
        const gradient = Vec3(
            gradient_x.evaluate(surface_point),
            gradient_y.evaluate(surface_point),
            gradient_z.evaluate(surface_point)
        );
        const normal = ray_factory.normal_to_camera(gradient);
        return shade(bundle.camera.at(hit), normal, bundle.camera.at(eye));
    }

    private Color shade(Vec3 point, Vec3 normal, Vec3 eye) const {
        const normal_length = normal.length();
        if (normal_length != 0.0)
            normal = normal / normal_length;
        const view = (eye - point).normalized();

        if (dot(normal, view) > 0.0)
            return shade_with_material(point, view, normal, front_material);
        return shade_with_material(point, view, -normal, back_material);
    }

    private Color shade_with_material(Vec3 point, Vec3 view, Vec3 normal,
                                      Material material) const
    {
        auto color = material.color * material.ambient;
        foreach (light; lights) {
            if (!light.enabled)
                continue;
            const direction = (light.position - point).normalized();
            const lambert = dot(normal, direction);
            if (lambert <= 0.0)
                continue;

            const diffuse_product = material.color.multiplied(light.color)
                * (material.diffuse * light.intensity);
            color = color + diffuse_product * cast(float) lambert;

            const half_vector = (direction + view).normalized();
            const specular_angle = max(0.0, dot(normal, half_vector));
            const specular_product = light.color * (material.specular * light.intensity);
            color = color + specular_product
                * cast(float) pow(specular_angle, material.shininess);
        }
        return color.clamped();
    }
}

private Interval clip_to_unit_sphere(Ray ray) {
    const length = ray.direction.length();
    if (length == 0.0)
        return Interval(1.0, 0.0);
    const direction = ray.direction / length;
    const b = -dot(ray.origin, direction);
    const c = dot(ray.origin, ray.origin) - 1.0;
    const discriminant = b * b - c;
    if (discriminant < 0.0)
        return Interval(1.0, 0.0);
    const root = sqrt(discriminant);
    return Interval((b - root) / length, (b + root) / length);
}

unittest {
    auto renderer = new Renderer();
    renderer.set_surface_family("x^2+y^2+z^2-0.64");
    renderer.background = Color(0.0f, 0.0f, 0.0f);
    renderer.anti_aliasing_pattern = AntiAliasingPattern.og_1x1;
    renderer.camera.transform = Affine.translation_by(Vec3(0.0, 0.0, -1.0));

    auto pixels = renderer.draw(64, 64);
    size_t foreground;
    foreach (pixel; pixels)
        if ((pixel & 0x00ff_ffffu) != 0)
            ++foreground;
    assert(foreground > 500);
    assert(foreground < pixels.length);
}
