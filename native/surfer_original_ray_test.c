/* Compare components on coordinates captured from the actual original task. */
#include "surfer_raytracer.c"
#include <inttypes.h>
#include <stdio.h>

static char selected_frame[100] = "before first frame";
static char selected_label[100] = "before first ray";
static const char *selected_observation = "before first observation";

static void selected_fail(const char *reason)
{
    fprintf(stderr, "FAIL original selected ray: %s %s %s %s\n", selected_frame, selected_label,
        selected_observation, reason);
    exit(1);
}

static double selected_double(FILE *input)
{
    uint64_t bits;
    double value;
    if (fscanf(input, "%" SCNx64, &bits) != 1) selected_fail("binary64 record");
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static float selected_float(FILE *input)
{
    uint32_t bits;
    float value;
    if (fscanf(input, "%" SCNx32, &bits) != 1) selected_fail("binary32 record");
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static surfer_vec3 selected_vector(FILE *input)
{
    const double x = selected_double(input), y = selected_double(input), z = selected_double(input);
    return (surfer_vec3){x, y, z};
}

static surfer_color selected_color(FILE *input)
{
    const float red = selected_float(input), green = selected_float(input), blue = selected_float(input);
    return (surfer_color){red, green, blue};
}

static void selected_require_double(double actual, double expected)
{
    if (isnan(actual) && isnan(expected)) return;
    if (memcmp(&actual, &expected, sizeof(actual)) != 0) {
        uint64_t left, right;
        memcpy(&left, &actual, sizeof(left)); memcpy(&right, &expected, sizeof(right));
        fprintf(stderr, "actual %016" PRIx64 " expected %016" PRIx64 "\n", left, right);
        selected_fail("binary64 value");
    }
}

static void selected_require_vector(surfer_vec3 actual, surfer_vec3 expected)
{
    selected_require_double(actual.x, expected.x);
    selected_require_double(actual.y, expected.y);
    selected_require_double(actual.z, expected.z);
}

static void selected_require_color(surfer_color actual, surfer_color expected)
{
    if (memcmp(&actual.red, &expected.red, sizeof(float)) != 0 ||
        memcmp(&actual.green, &expected.green, sizeof(float)) != 0 ||
        memcmp(&actual.blue, &expected.blue, sizeof(float)) != 0)
        selected_fail("binary32 color");
}

int main(int argc, char **argv)
{
    if (argc != 2) selected_fail("reference argument");
    FILE *input = fopen(argv[1], "r");
    if (input == NULL) selected_fail("reference unavailable");
    surfer_operation_context context = new_operation_context();
    surfer_term terms[4][256];
    surfer_prepared_surface prepared = {0};
    surfer_scene scene = surfer_default_scene(&prepared);
    original_camera_view camera;
    orthographic_view view = {0};
    original_render_pipeline pipeline = {0};
    univariate_polynomial polynomial = {0};
    const original_xy_polynomial *row = NULL;
    surfer_ray_bundle rays = {0};
    surfer_trace_result trace = {0};
    surfer_vec3 gradient = {0}, camera_normal = {0};
    double horizontal = 0.0, root = NAN;
    char tag[40], identity[100], formula[512], pattern[32], space[20];
    size_t frames = 0, selected = 0, roots = 0, shades = 0, clips = 0, coefficients = 0;
    while (fscanf(input, "%39s", tag) == 1) {
        selected_observation = tag;
        if (strcmp(tag, "frame") == 0) {
            original_destroy_pipeline(&pipeline);
            free_univariate_polynomial(polynomial); polynomial = empty_univariate_polynomial();
            size_t width, height;
            unsigned threshold;
            double yaw, pitch, zoom;
            if (fscanf(input, "%99s%511s%31s%x%zu%zu%la%la%la", selected_frame, formula, pattern,
                    &threshold, &width, &height, &yaw, &pitch, &zoom) != 9) selected_fail("frame header");
            context = new_operation_context();
            prepared = (surfer_prepared_surface){0};
            if (!make_original_orthographic_view(&context, width, height, 2.15, yaw, pitch, zoom,
                    &camera, &view)) selected_fail("camera construction");
            frames++;
        } else if (strcmp(tag, "family_degree") == 0) {
            if (fscanf(input, "%99s%" SCNd32, identity, &prepared.family_degree) != 2 ||
                strcmp(identity, selected_frame) != 0) selected_fail("family degree");
        } else if (strcmp(tag, "input") == 0) {
            unsigned component;
            size_t count;
            if (fscanf(input, "%99s%u%zu", identity, &component, &count) != 3 ||
                component >= 4 || count > 256 || strcmp(identity, selected_frame) != 0)
                selected_fail("prepared input");
            surfer_sparse_polynomial *values[] = {&prepared.surface, &prepared.gradient_x,
                &prepared.gradient_y, &prepared.gradient_z};
            *values[component] = (surfer_sparse_polynomial){terms[component], count};
        } else if (strcmp(tag, "term") == 0) {
            unsigned component;
            size_t ordinal;
            if (fscanf(input, "%99s%u%zu", identity, &component, &ordinal) != 3 ||
                component >= 4 || ordinal >= 256 || strcmp(identity, selected_frame) != 0)
                selected_fail("prepared term identity");
            surfer_term *term = &terms[component][ordinal];
            term->coefficient = selected_double(input);
            if (fscanf(input, "%" SCNd32 "%" SCNd32 "%" SCNd32,
                &term->x_exponent, &term->y_exponent, &term->z_exponent) != 3) selected_fail("term exponent");
        } else if (strcmp(tag, "captured_calls") == 0) {
            size_t count;
            if (fscanf(input, "%99s%zu", identity, &count) != 2 || count == 0 ||
                strcmp(identity, selected_frame) != 0) selected_fail("actual task sample count");
            if (!original_initialize_pipeline(&context, &prepared, view, &pipeline))
                selected_fail("prepared pipeline construction");
        } else if (strcmp(tag, "selected_ray") == 0) {
            size_t ordinal;
            if (fscanf(input, "%99s%99s%zu", identity, selected_label, &ordinal) != 3 ||
                strcmp(identity, selected_frame) != 0) selected_fail("selected sample identity");
            horizontal = selected_double(input);
            const double vertical = selected_double(input);
            rays = orthographic_ray_bundle_at(view, horizontal, vertical);
            row = original_row_for_sample(&context, &pipeline, vertical);
            if (row == NULL) selected_fail("row construction");
            free_univariate_polynomial(polynomial);
            polynomial = original_evaluate_y(&context, &row[0], horizontal);
            trace = trace_prepared_ray_with_row(&context, &scene, rays, row, horizontal);
            root = NAN;
        } else if (strcmp(tag, "selected_bundle") == 0) {
            if (fscanf(input, "%19s", space) != 1) selected_fail("ray space");
            const surfer_ray actual = strcmp(space, "camera") == 0 ? rays.camera_ray :
                strcmp(space, "clipping") == 0 ? rays.clipping_ray : rays.surface_ray;
            selected_require_vector(actual.origin, selected_vector(input));
            selected_require_vector(actual.direction, selected_vector(input));
        } else if (strcmp(tag, "selected_eye") == 0) {
            selected_require_double(rays.eye_location_on_ray, selected_double(input));
            selected_require_vector(point_on_ray_at_parameter(rays.camera_ray, rays.eye_location_on_ray),
                selected_vector(input));
        } else if (strcmp(tag, "selected_polynomial") == 0) {
            size_t count;
            if (fscanf(input, "%zu", &count) != 1 || polynomial.length != count)
                selected_fail("dense polynomial length");
        } else if (strcmp(tag, "selected_coefficient") == 0) {
            size_t ordinal;
            if (fscanf(input, "%zu", &ordinal) != 1 || ordinal >= polynomial.length)
                selected_fail("coefficient ordinal");
            selected_require_double(polynomial.coefficients[ordinal], selected_double(input));
            coefficients++;
        } else if (strcmp(tag, "selected_clip") == 0) {
            unsigned interval;
            surfer_interval actual;
            if (fscanf(input, "%u", &interval) != 1 || interval != 0 ||
                clip_original_unit_sphere(rays.clipping_ray, &actual) != SURFER_OK) selected_fail("sphere clip");
            selected_require_double(actual.lower, selected_double(input));
            selected_require_double(actual.upper, selected_double(input));
            clips++;
        } else if (strcmp(tag, "selected_root") == 0) {
            unsigned interval;
            if (fscanf(input, "%u", &interval) != 1 || interval != 0) selected_fail("root interval");
            const double lower = selected_double(input), upper = selected_double(input);
            const double expected = selected_double(input);
            root = first_root_for_surface_family(&context, &prepared, &polynomial, lower, upper);
            selected_require_double(root, expected);
            roots++;
        } else if (strcmp(tag, "selected_surface_point") == 0) {
            selected_require_vector(point_on_ray_at_parameter(rays.surface_ray, root), selected_vector(input));
        } else if (strcmp(tag, "selected_camera_point") == 0) {
            selected_require_vector(point_on_ray_at_parameter(rays.camera_ray, root), selected_vector(input));
        } else if (strcmp(tag, "selected_admitted") == 0) {
            unsigned admitted;
            if (fscanf(input, "%u", &admitted) != 1 || admitted != 1) selected_fail("original clipping bypass");
        } else if (strcmp(tag, "selected_gradient") == 0) {
            double components[3];
            for (size_t component = 0; component < 3; ++component) {
                univariate_polynomial value = original_evaluate_y(&context, &row[component + 1], horizontal);
                components[component] = evaluate_univariate_polynomial_at(&context, &value, root);
                free_univariate_polynomial(value);
            }
            gradient = (surfer_vec3){components[0], components[1], components[2]};
            selected_require_vector(gradient, selected_vector(input));
        } else if (strcmp(tag, "selected_camera_normal") == 0) {
            camera_normal = apply_matrix_to_vector(rays.surface_normal_to_camera, gradient);
            selected_require_vector(camera_normal, selected_vector(input));
        } else if (strcmp(tag, "selected_shade") == 0) {
            surfer_vec3 normal = normalize_surface_normal(camera_normal);
            const surfer_vec3 point = point_on_ray_at_parameter(rays.camera_ray, root);
            const surfer_vec3 eye = point_on_ray_at_parameter(rays.camera_ray, rays.eye_location_on_ray);
            const surfer_vec3 direction = normalize_vector(subtract_vectors(eye, point));
            const surfer_material material = material_for_visible_side(&scene, direction, &normal);
            selected_require_color(shade_hit_with_original_material(&scene, point, direction, normal, material),
                selected_color(input));
            selected_require_vector(normal, selected_vector(input));
            shades++;
        } else if (strcmp(tag, "selected_trace") == 0) {
            selected_require_color(trace.color, selected_color(input));
            uint32_t expected;
            if (fscanf(input, "%" SCNx32, &expected) != 1 ||
                (trace.status != SURFER_OK && trace.status != SURFER_MISS) ||
                color_to_argb_validated(trace.color) != expected) selected_fail("actual trace pixel");
        } else if (strcmp(tag, "selected_end") == 0) {
            char label[100];
            if (fscanf(input, "%99s%99s", identity, label) != 2 ||
                strcmp(identity, selected_frame) != 0 || strcmp(label, selected_label) != 0)
                selected_fail("selected end identity");
            selected++;
        } else selected_fail("unknown observation");
        if (context.status != SURFER_OK) selected_fail("native operation status");
    }
    original_destroy_pipeline(&pipeline);
    free_univariate_polynomial(polynomial);
    if (ferror(input) || fclose(input) != 0 || frames != 44 || selected != 238 ||
        roots < 40 || clips < 40 || shades < 20 || coefficients < 500) selected_fail("component corpus coverage");
    printf("selected rays %zu frames %zu clips %zu roots %zu shades %zu coefficients %zu\n",
        selected, frames, clips, roots, shades, coefficients);
    puts("PASS original captured ray clip coefficients root gradient normal shade and pixel components");
    return 0;
}
