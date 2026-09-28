module surfer_test;

import core.stdc.math : fabs;
import core.stdc.stdio : printf, puts;
import std.file : read;
import std.stdio : File;

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

private void test_complete_polynomial_surface_grammar() {
    PreparedSurface surface;

    require_true(
        prepare_surface("x^(8)+y²+z²−0.64", surface),
        "parenthesized integer ASCII power mixes with superscripts");
    require_true(surface.family_degree ≟ 8, "integer power exponent degree");

    require_true(
        prepare_surface("(x²+y²+z²−4e-1)/2", surface),
        "parentheses, scalar division, and scientific literal parse");
    require_near(
        evaluate(surface.surface, Vec3(1.0, 0.0, 0.0)),
        0.3,
        1e-15,
        "scalar polynomial division");

    require_true(
        prepare_surface("sqrt(4)*x²+abs(-1.5)*y²+floor(2.4)*z²−6", surface),
        "constant functions in polynomial coefficients parse");
    require_near(
        evaluate(surface.surface, Vec3(1.0, 0.0, 0.0)),
        −4.0,
        1e-15,
        "constant function value enters polynomial");

    require_true(
        prepare_surface("x/2+y/(1+1)+z/2", surface),
        "constant expressions may divide polynomial expressions");
    require_near(
        evaluate(surface.surface, Vec3(2.0, 4.0, 6.0)),
        6.0,
        1e-15,
        "polynomial divided by evaluated constants");

    require_true(
        prepare_surface(".5*x²+5.*y²+1e-3*z²", surface),
        "decimal literals accept leading dot, trailing dot, and exponent");
    require_near(
        evaluate(surface.surface, Vec3(2.0, 0.0, 0.0)),
        2.0,
        1e-15,
        "leading-dot decimal value");

    require_true(
        !prepare_surface("x/y", surface),
        "nonconstant polynomial divisor is rejected");
    require_true(
        !prepare_surface("sin(x)", surface),
        "nonconstant function argument is rejected");
    require_true(
        !prepare_surface("w²+y²+z²", surface),
        "unknown coordinate is rejected");
    require_true(
        !prepare_surface("x^", surface),
        "trailing exponent operator is rejected");
    require_true(
        !prepare_surface("x^2^3", surface),
        "compound power exponent is rejected like the source walker");
    require_true(
        !prepare_surface("x^(2+1)", surface),
        "compound integer expression is not an exponent literal");
    require_true(
        !prepare_surface("x^2.0", surface),
        "floating literal is not an integer exponent token");
}

private void test_shipped_examples_and_render_paths() {
    const(char)[][6] formulas = [
        "x²+y²+z²−0.64",
        "(x²+y²+z²+0.36)²−1.69×(x²+y²)",
        "x²+y²+z²+2×x×y×z−1",
        "x²−y²×z",
        "x²×y²+y²×z²+z²×x²−x×y×z",
        "(x²+2.25×y²+z²−1)³−x²×z³−0.1125×y²×z³"
    ];
    const int[6] degrees = [2, 4, 3, 3, 4, 6];

    enum width = 40;
    enum height = 40;
    foreach (i; 0 .. formulas.length) {
        PreparedSurface surface;
        require_true(
            prepare_surface(formulas[i], surface),
            "parse shipped surface example");
        require_true(
            surface.family_degree ≟ degrees[i],
            "shipped surface example has oracle degree");

        Scene scene = default_scene(&surface);
        const background = color_to_argb(scene.background);
        uint[width × height] first;
        uint[width × height] repeated;
        uint[width × height] production;
        uint[width × height] production_repeat;
        require_true(
            render_orthographic(
                &scene, width, height, 2.15, 0.0, 0.0, 1.0, first.ptr),
            "shipped example orthographic render succeeds");
        require_true(
            render_orthographic(
                &scene, width, height, 2.15, 0.0, 0.0, 1.0, repeated.ptr),
            "repeat shipped example render succeeds");
        require_true(
            render_orthographic_quality(
                &scene,
                width,
                height,
                2.15,
                0.0,
                0.0,
                1.0,
                RenderQuality.production,
                production.ptr),
            "production-quality shipped example render succeeds");
        require_true(
            render_orthographic_quality(
                &scene,
                width,
                height,
                2.15,
                0.0,
                0.0,
                1.0,
                RenderQuality.production,
                production_repeat.ptr),
            "repeat production-quality shipped example render succeeds");

        size_t foreground;
        foreach (pixel; 0 .. first.length) {
            if (first[pixel] ≠ background) ++foreground;
            require_true(first[pixel] ≟ repeated[pixel], "repeat render is pixel-stable");
            require_true(
                production[pixel] ≟ production_repeat[pixel],
                "repeat production render is pixel-stable");
        }
        require_true(foreground > 0, "shipped example render has surface pixels");
        require_true(foreground < first.length, "shipped example render retains background");
    }
}

private bool app_preview_pixels_close(
    const(uint)[] reference,
    const(uint)[] translated,
    out double mean_absolute_error,
    out double changed_pixel_fraction)
{
    if (reference.length != translated.length || reference.length == 0) return false;

    size_t channel_error;
    size_t changed_pixels;
    foreach (i; 0 .. reference.length) {
        const a = reference[i];
        const b = translated[i];
        const red_a = (a >> 16) & 0xff;
        const red_b = (b >> 16) & 0xff;
        const red_error = red_a > red_b ? red_a - red_b : red_b - red_a;
        const green_a = (a >> 8) & 0xff;
        const green_b = (b >> 8) & 0xff;
        const blue_a = a & 0xff;
        const blue_b = b & 0xff;
        const green_error = green_a > green_b ? green_a - green_b : green_b - green_a;
        const blue_error = blue_a > blue_b ? blue_a - blue_b : blue_b - blue_a;
        channel_error += red_error + green_error + blue_error;
        if (red_error != 0 || green_error != 0 || blue_error != 0) ++changed_pixels;
    }

    mean_absolute_error = cast(double)channel_error /
        (cast(double)reference.length × 3.0 × 255.0);
    changed_pixel_fraction = cast(double)changed_pixels / cast(double)reference.length;
    return mean_absolute_error <= 0.0002 && changed_pixel_fraction <= 0.005;
}

private void test_image_comparison_rejects_a_broken_render() {
    uint[64] reference;
    uint[64] matching;
    uint[64] broken;
    foreach (i; 0 .. reference.length) {
        reference[i] = 0xff305070;
        matching[i] = reference[i];
        broken[i] = reference[i];
    }
    foreach (i; 0 .. broken.length / 2) broken[i] = 0xff000000;

    double mae;
    double changed;
    require_true(
        app_preview_pixels_close(reference[], matching[], mae, changed),
        "identical image fixture passes differential threshold");
    require_true(
        !app_preview_pixels_close(reference[], broken[], mae, changed),
        "half-black known-bad image fails differential threshold");
}

private RenderQuality preview_quality(string pattern) {
    return pattern == "QUINCUNX"
        ? RenderQuality.production
        : RenderQuality.interactive;
}

private void write_app_preview(string path, string formula, RenderQuality quality) {
    PreparedSurface sphere;
    if (!prepare_surface(formula, sphere)) return;
    Scene scene = default_scene(&sphere);
    enum size = 256;
    uint[size × size] pixels;
    if (!render_orthographic_quality(
        &scene, size, size, 2.15, 0.55, −0.35, 1.0, quality, pixels.ptr))
    {
        return;
    }

    auto output = File(path, "wb");
    output.writef("P6\n%u %u\n255\n", size, size);
    foreach (pixel; pixels) {
        ubyte[3] rgb = [
            cast(ubyte)(pixel >> 16),
            cast(ubyte)(pixel >> 8),
            cast(ubyte)pixel];
        output.rawWrite(rgb[]);
    }
    output.close();
}

private bool compare_app_preview(
    string reference_path,
    string formula,
    RenderQuality quality)
{
    enum size = 256;
    enum header = "P6\n256 256\n255\n";
    enum pixel_bytes = size × size × 3;
    auto reference_file = cast(const(ubyte)[])read(reference_path);
    if (reference_file.length != header.length + pixel_bytes) return false;
    foreach (i; 0 .. header.length) {
        if (reference_file[i] ≠ header[i]) return false;
    }

    PreparedSurface sphere;
    if (!prepare_surface(formula, sphere)) return false;
    Scene scene = default_scene(&sphere);
    uint[size × size] translated_pixels;
    if (!render_orthographic_quality(
        &scene,
        size,
        size,
        2.15,
        0.55,
        −0.35,
        1.0,
        quality,
        translated_pixels.ptr))
    {
        return false;
    }

    uint[size × size] reference_pixels;
    foreach (i; 0 .. reference_pixels.length) {
        const offset = header.length + i × 3;
        reference_pixels[i] = 0xff000000u |
            (cast(uint)reference_file[offset] << 16) |
            (cast(uint)reference_file[offset + 1] << 8) |
            cast(uint)reference_file[offset + 2];
    }

    double mean_error;
    double changed_fraction;
    const accepted = app_preview_pixels_close(
        reference_pixels[], translated_pixels[], mean_error, changed_fraction);
    printf(
        "Java preview comparison: mean absolute error=%.6f, changed pixels=%.4f\n",
        mean_error,
        changed_fraction);
    return accepted;
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

private void test_root_oracle_cases() {
    double[3] tangent = [0.0625, −0.5, 1.0];
    double[max_degree] roots = void;
    size_t count = real_roots(tangent.ptr, 2, 0.0, 1.0, roots.ptr, roots.length);
    require_true(count > 0, "Java Descartes tangent oracle has a root");
    if (count > 0) {
        require_near(roots[0], 0.24999994039535522, 1e-7, "first tangent root matches Java oracle");
    }

    double[4] repeated = [−0.015625, 0.1875, −0.75, 1.0];
    count = real_roots(repeated.ptr, 3, 0.0, 1.0, roots.ptr, roots.length);
    require_true(count > 0, "Java Descartes repeated-root oracle has a root");
    if (count > 0) {
        require_near(roots[0], 0.2499990463256836, 1e-6, "repeated root matches Java oracle");
    }

    double[3] near_double = [0.0625 − 1e-12, −0.5, 1.0];
    count = real_roots(near_double.ptr, 2, 0.0, 1.0, roots.ptr, roots.length);
    require_true(count > 1, "near-double Java oracle has two separated roots");
    if (count > 1) {
        require_near(roots[0], 0.24999898672103882, 1e-7, "first near-double root matches Java oracle");
        require_near(roots[1], 0.2500009536743164, 1e-7, "second near-double root matches Java oracle");
    }

    count = real_roots(near_double.ptr, 2, 0.2499995, 0.2500005, roots.ptr, roots.length);
    require_true(count ≟ 0, "narrow interval matches Java no-root result");

    double[5] four_roots = [0.027, 0.2085, −0.67, −0.45, 1.0];
    count = real_roots(four_roots.ptr, 4, −1.0, 1.0, roots.ptr, roots.length);
    require_true(count ≟ 4, "quartic Java oracle has four roots");
    if (count ≟ 4) {
        require_near(roots[0], −0.75, 1e-7, "quartic first-root ordering");
        require_near(roots[1], −0.1, 1e-7, "quartic second-root ordering");
        require_near(roots[2], 0.4, 1e-7, "quartic third-root ordering");
        require_near(roots[3], 0.9, 1e-7, "quartic fourth-root ordering");
    }
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

int main(string[] args) {
    if ((args.length == 3 || args.length == 4 || args.length == 5) && args[1] == "--write-preview") {
        const formula = args.length >= 4 ? args[3] : "x²+y²+z²−0.64";
        const pattern = args.length == 5 ? args[4] : "OG_1x1";
        write_app_preview(args[2], formula, preview_quality(pattern));
        return 0;
    }
    if (args.length == 5 && args[1] == "--compare-java-preview") {
        if (compare_app_preview(args[2], args[3], preview_quality(args[4]))) return 0;
        puts("FAIL: translated render diverges from the Java preview");
        return 1;
    }
    if (args.length != 1) return 2;

    test_image_comparison_rejects_a_broken_render();
    test_formula_to_prepared_surface();
    test_complete_polynomial_surface_grammar();
    test_shipped_examples_and_render_paths();
    test_clip_preserves_parameter();
    test_ray_polynomial_coefficients();
    test_first_roots();
    test_root_oracle_cases();
    test_trace_contract();
    test_orthographic_render();

    if (failures ≠ 0) {
        printf("SURFER Icky D formula/render tests: %d failure(s)\n", failures);
        return 1;
    }

    puts("SURFER Icky D formula/render tests: PASS");
    return 0;
}
