module surfer_test;

import core.stdc.math : fabs;
import core.stdc.stdio : printf, puts;

import surfer;

private int failures;

private void require_true(bool condition, const(char)[] message) {
    if (!condition) {
        printf("FAIL: %.*s\n", cast(int)message.length, message.ptr);
        ++failures;
    }
}

private void require_near(
    double actual,
    double expected,
    double tolerance,
    const(char)[] message)
{
    if (actual ≠ actual || expected ≠ expected ||
        fabs(actual − expected) > tolerance)
    {
        printf(
            "FAIL: %.*s: actual=%.17g expected=%.17g\n",
            cast(int)message.length,
            message.ptr,
            actual,
            expected);
        ++failures;
    }
}

private size_t count_foreground(
    const uint* pixels,
    size_t count,
    uint background)
{
    size_t foreground;
    foreach (i; 0 .. count) {
        if (pixels[i] ≠ background) ++foreground;
    }
    return foreground;
}

private void test_formula_to_prepared_surface() {
    PreparedSurface sphere;
    require_true(
        prepare_surface("x²+y²+z²−0.64", sphere),
        "parse superscript sphere");
    require_true(sphere.family_degree ≟ 2, "sphere degree is two");

    require_near(
        evaluate(sphere.surface, Vec3(0.8, 0.0, 0.0)),
        0.0,
        1e-15,
        "sphere polynomial");
    require_near(
        evaluate(sphere.gradient_x, Vec3(0.8, 0.0, 0.0)),
        1.6,
        1e-15,
        "symbolic x derivative");
}

private void test_clip_preserves_parameter() {
    Interval interval;
    const ray = Ray(
        Vec3(0.0, 0.0, 0.0),
        Vec3(0.0, 0.0, −2.0));

    require_true(
        clip_unit_sphere(ray, interval),
        "unit-sphere clip exists");
    require_near(interval.lower, −0.5, 1e-15, "clip lower keeps t");
    require_near(interval.upper, 0.5, 1e-15, "clip upper keeps t");
}

private void test_ray_polynomial_coefficients() {
    PreparedSurface sphere;
    PreparedSurface plane;
    require_true(prepare_surface("x²+y²+z²−0.64", sphere), "prepare coefficient sphere");
    require_true(prepare_surface("z−0.25", plane), "prepare coefficient plane");

    double[max_degree + 1] coefficients = void;
    int degree;
    const ray = Ray(Vec3(0.0, 0.0, 0.0), Vec3(0.0, 0.0, −1.0));

    require_true(
        ray_polynomial(sphere.surface, ray, coefficients, degree),
        "expand sphere ray polynomial");
    require_true(degree ≟ 2, "sphere ray polynomial degree");
    require_near(coefficients[0], −0.64, 1e-15, "sphere ray constant");
    require_near(coefficients[1], 0.0, 1e-15, "sphere ray linear");
    require_near(coefficients[2], 1.0, 1e-15, "sphere ray quadratic");

    require_true(
        ray_polynomial(plane.surface, ray, coefficients, degree),
        "expand plane ray polynomial");
    require_true(degree ≟ 1, "plane ray polynomial degree");
    require_near(coefficients[0], −0.25, 1e-15, "plane ray constant");
    require_near(coefficients[1], −1.0, 1e-15, "plane ray linear");
}

private void test_first_roots() {
    PreparedSurface sphere;
    PreparedSurface tangent;
    PreparedSurface plane;

    require_true(
        prepare_surface("x²+y²+z²−0.64", sphere),
        "prepare sphere");
    require_true(
        prepare_surface("x²+z²−0.25", tangent),
        "prepare tangent surface");
    require_true(
        prepare_surface("z−0.25", plane),
        "prepare plane");

    double root;

    const center = Ray(
        Vec3(0.0, 0.0, 0.0),
        Vec3(0.0, 0.0, −1.0));
    require_true(
        first_surface_root(&sphere, center, −1.0, 1.0, root),
        "sphere center root");
    require_near(root, −0.8, root_epsilon, "first sphere root");

    const tangent_ray = Ray(
        Vec3(0.5, 0.0, 0.0),
        Vec3(0.0, 0.0, −1.0));
    root = 99.0;
    require_true(
        first_surface_root(&tangent, tangent_ray, −0.6, 0.6, root),
        "even tangent root");
    require_near(root, 0.0, 1e-15, "tangent root is zero");

    const miss = Ray(
        Vec3(0.9, 0.0, 0.0),
        Vec3(0.0, 0.0, −1.0));
    require_true(
        !first_surface_root(&sphere, miss, −0.5, 0.5, root),
        "surface miss");

    double[max_degree + 1] linear_coefficients = void;
    int linear_degree;
    require_true(
        ray_polynomial(plane.surface, center, linear_coefficients, linear_degree),
        "linear root coefficients");
    require_true(plane.family_degree ≟ 1, "linear family degree");
    require_true(linear_degree ≟ 1, "linear ray degree");
    const linear_candidate = −linear_coefficients[0] / linear_coefficients[1];
    require_near(linear_candidate, −0.25, 1e-15, "linear candidate");
    require_true(
        linear_candidate >= −1.0 && linear_candidate <= 1.0,
        "linear candidate lies in interval");

    root = 0.0;
    const linear_hit = first_surface_root(&plane, center, −1.0, 1.0, root);
    require_true(linear_hit, "linear family root");
    require_near(root, −0.25, 1e-15, "linear root");
}

private void test_trace_contract() {
    PreparedSurface sphere;
    require_true(
        prepare_surface("x²+y²+z²−0.64", sphere),
        "prepare trace sphere");

    Scene scene = default_scene(&sphere);
    const identity = Mat3(
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0);

    const rays = RayBundle(
        Ray(Vec3(0.0, 0.0, −1.0), Vec3(0.0, 0.0, −1.0)),
        Ray(Vec3(0.0, 0.0, 0.0), Vec3(0.0, 0.0, −1.0)),
        Ray(Vec3(0.0, 0.0, 0.0), Vec3(0.0, 0.0, −1.0)),
        −1.0,
        identity);

    const trace = trace_prepared_ray(&scene, rays);
    require_true(trace.hit, "center trace hits");
    require_near(trace.point.z, −0.2, root_epsilon, "camera point shares t");
    require_near(trace.surface_normal.x, 0.0, 1e-7, "normal x");
    require_near(trace.surface_normal.y, 0.0, 1e-7, "normal y");
    require_near(trace.surface_normal.z, 1.0, 1e-7, "normal faces eye");
    require_true(
        trace.color.red > trace.color.green,
        "front material remains orange-red");
}

private void test_orthographic_render() {
    PreparedSurface sphere;
    require_true(
        prepare_surface("x²+y²+z²−0.64", sphere),
        "prepare render sphere");

    Scene scene = default_scene(&sphere);
    const background = color_to_argb(scene.background);

    enum width = 48;
    enum height = 48;
    uint[width × height] pixels;

    require_true(
        render_orthographic(
            &scene,
            width,
            height,
            2.15,
            0.0,
            0.0,
            1.0,
            pixels.ptr),
        "orthographic render succeeds");

    const foreground =
        count_foreground(pixels.ptr, pixels.length, background);
    require_true(foreground > 500, "render contains foreground");
    require_true(foreground < 1400, "render retains background");

    enum rotated_width = 40;
    enum rotated_height = 40;
    uint[rotated_width × rotated_height] identity_pixels;
    uint[rotated_width × rotated_height] rotated_pixels;

    require_true(
        render_orthographic(
            &scene,
            rotated_width,
            rotated_height,
            2.15,
            0.0,
            0.0,
            1.0,
            identity_pixels.ptr),
        "identity render succeeds");

    require_true(
        render_orthographic(
            &scene,
            rotated_width,
            rotated_height,
            2.15,
            0.63,
            −0.41,
            1.0,
            rotated_pixels.ptr),
        "rotated render succeeds");

    require_true(
        count_foreground(
            identity_pixels.ptr,
            identity_pixels.length,
            background)
        ≟
        count_foreground(
            rotated_pixels.ptr,
            rotated_pixels.length,
            background),
        "sphere silhouette survives rotation");
}

extern(C) int main() {
    test_formula_to_prepared_surface();
    test_clip_preserves_parameter();
    test_ray_polynomial_coefficients();
    test_first_roots();
    test_trace_contract();
    test_orthographic_render();

    if (failures ≠ 0) {
        printf("SURFER Icky D vertical slice: %d failure(s)\n", failures);
        return 1;
    }

    puts("SURFER Icky D vertical slice: PASS");
    return 0;
}
