/* Independent raw observations of original RayCreator and vecmath methods. */
#include "surfer_raytracer.c"
#include <inttypes.h>
#include <stdio.h>

static const char *camera_case_name = "before case";
static size_t camera_record;

static void camera_fail(const char *message)
{
    fprintf(stderr, "FAIL original camera: %s record%zu %s\n", camera_case_name, camera_record, message);
    exit(1);
}

static double camera_from_bits(uint64_t bits)
{
    double value; memcpy(&value, &bits, sizeof(value)); return value;
}

static uint64_t camera_bits(double value)
{
    uint64_t bits; memcpy(&bits, &value, sizeof(bits)); return bits;
}

static void check_camera_value(double value, uint64_t expected, const char *description)
{
    if (camera_bits(value) != expected) {
        fprintf(stderr, "actual%016" PRIx64 " expected%016" PRIx64 "\n", camera_bits(value), expected);
        camera_fail(description);
    }
}

static original_matrix4 named_camera_matrix(const original_camera_view *camera, const char *name)
{
    if (strcmp(name, "input_view") == 0) return camera->input_view;
    if (strcmp(name, "input_camera") == 0) return camera->input_camera;
    if (strcmp(name, "input_surface") == 0) return camera->input_surface;
    if (strcmp(name, "camera_to_clipping") == 0) return camera->camera_to_clipping;
    if (strcmp(name, "camera_to_surface") == 0) return camera->camera_to_surface;
    if (strcmp(name, "surface_normal_to_camera") == 0) return camera->surface_normal_to_camera;
    camera_fail("unknown matrix"); return original_identity4();
}

static surfer_vec3 named_camera_vector(const original_camera_view *camera, const char *name)
{
    if (strcmp(name, "camera_origin") == 0) return camera->camera_origin;
    if (strcmp(name, "camera_direction") == 0) return camera->camera_direction;
    if (strcmp(name, "camera_du") == 0) return camera->camera_du;
    if (strcmp(name, "camera_dv") == 0) return camera->camera_dv;
    if (strcmp(name, "surface_origin") == 0) return camera->surface_origin;
    if (strcmp(name, "surface_direction") == 0) return camera->surface_direction;
    if (strcmp(name, "surface_du") == 0) return camera->surface_du;
    if (strcmp(name, "surface_dv") == 0) return camera->surface_dv;
    if (strcmp(name, "clipping_origin") == 0) return camera->clipping_origin;
    if (strcmp(name, "clipping_direction") == 0) return camera->clipping_direction;
    if (strcmp(name, "clipping_du") == 0) return camera->clipping_du;
    if (strcmp(name, "clipping_dv") == 0) return camera->clipping_dv;
    camera_fail("unknown vector"); return (surfer_vec3){0};
}

static double named_camera_scalar(const original_camera_view *camera, const char *name)
{
    if (strcmp(name, "camera_height") == 0) return camera->camera_height;
    if (strcmp(name, "uscale") == 0) return camera->uscale;
    if (strcmp(name, "vscale") == 0) return camera->vscale;
    if (strcmp(name, "uoffset") == 0) return camera->uoffset;
    if (strcmp(name, "voffset") == 0) return camera->voffset;
    if (strcmp(name, "eye_location") == 0) return camera->eye_location;
    camera_fail("unknown scalar"); return 0;
}

static surfer_ray named_camera_ray(surfer_ray_bundle bundle, const char *space)
{
    if (strcmp(space, "camera") == 0) return bundle.camera_ray;
    if (strcmp(space, "clipping") == 0) return bundle.clipping_ray;
    if (strcmp(space, "surface") == 0) return bundle.surface_ray;
    camera_fail("unknown ray space"); return (surfer_ray){0};
}

static void check_camera_vector(surfer_vec3 value, const uint64_t expected[3], const char *name)
{
    check_camera_value(value.x, expected[0], name);
    check_camera_value(value.y, expected[1], name);
    check_camera_value(value.z, expected[2], name);
}

int main(int argc, char **argv)
{
    if (argc != 2) camera_fail("reference argument");
    FILE *input = fopen(argv[1], "r");
    if (input == NULL) camera_fail("reference missing");
    char line[2048], tag[64], identity[100], name[100], active_identity[100] = "none";
    original_camera_view camera = {0};
    orthographic_view view = {0};
    surfer_ray_bundle bundle = {0};
    size_t cases = 0, matrices = 0, vectors = 0, scalars = 0, intervals = 0, samples = 0, rays = 0, points = 0, normals = 0;
    while (fgets(line, sizeof(line), input) != NULL) {
        ++camera_record;
        if (strchr(line, '\n') == NULL || sscanf(line, "%63s%99s", tag, identity) != 2) camera_fail("malformed record");
        if (strcmp(tag, "camera_case") == 0) {
            size_t width, height;
            uint64_t camera_height, yaw, pitch, zoom;
            if (sscanf(line, "%*s%*s%zu%zu%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64,
                &width, &height, &camera_height, &yaw, &pitch, &zoom) != 6) camera_fail("case record");
            strcpy(active_identity, identity); camera_case_name = active_identity;
            surfer_operation_context context = new_operation_context();
            if (!make_original_orthographic_view(&context, width, height,
                camera_from_bits(camera_height), camera_from_bits(yaw), camera_from_bits(pitch),
                camera_from_bits(zoom), &camera, &view) || context.status != SURFER_OK)
                camera_fail("constructor status");
            ++cases;
            continue;
        }
        if (strcmp(identity, active_identity) != 0) camera_fail("wrong case identity");
        uint64_t bits[6]; unsigned index;
        if (strcmp(tag, "matrix") == 0) {
            unsigned row, column;
            if (sscanf(line, "%*s%*s%99s%u%u%" SCNx64, name, &row, &column, &bits[0]) != 4 || row >= 4 || column >= 4)
                camera_fail("matrix record");
            const original_matrix4 matrix = named_camera_matrix(&camera, name);
            check_camera_value(matrix.entries[4 * row + column], bits[0], name); ++matrices;
        } else if (strcmp(tag, "vector") == 0) {
            if (sscanf(line, "%*s%*s%99s%" SCNx64 "%" SCNx64 "%" SCNx64, name, &bits[0], &bits[1], &bits[2]) != 4)
                camera_fail("vector record");
            check_camera_vector(named_camera_vector(&camera, name), bits, name); ++vectors;
        } else if (strcmp(tag, "scalar") == 0) {
            if (sscanf(line, "%*s%*s%99s%" SCNx64, name, &bits[0]) != 2) camera_fail("scalar record");
            check_camera_value(named_camera_scalar(&camera, name), bits[0], name); ++scalars;
        } else if (strcmp(tag, "interval") == 0) {
            if (sscanf(line, "%*s%*s%99s%" SCNx64 "%" SCNx64, name, &bits[0], &bits[1]) != 3) camera_fail("interval record");
            const double offset = strcmp(name, "u") == 0 ? camera.uoffset : camera.voffset;
            const double scale = strcmp(name, "u") == 0 ? camera.uscale : camera.vscale;
            check_camera_value(offset - scale, bits[0], "interval lower");
            check_camera_value(offset + scale, bits[1], "interval upper"); ++intervals;
        } else if (strcmp(tag, "sample") == 0) {
            if (sscanf(line, "%*s%*s%u%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64,
                &index, &bits[0], &bits[1], &bits[2], &bits[3]) != 5) camera_fail("sample record");
            const double u = camera.uoffset + camera.uscale * (2.0 * camera_from_bits(bits[0]) - 1.0);
            const double v = camera.voffset + camera.vscale * (2.0 * camera_from_bits(bits[1]) - 1.0);
            check_camera_value(u, bits[2], "transformU"); check_camera_value(v, bits[3], "transformV");
            bundle = orthographic_ray_bundle_at(view, u, v); ++samples;
        } else if (strcmp(tag, "ray") == 0) {
            if (sscanf(line, "%*s%*s%u%99s%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64,
                &index, name, &bits[0], &bits[1], &bits[2], &bits[3], &bits[4], &bits[5]) != 8) camera_fail("ray record");
            const surfer_ray ray = named_camera_ray(bundle, name);
            check_camera_vector(ray.origin, bits, "ray origin"); check_camera_vector(ray.direction, bits + 3, "ray direction"); ++rays;
        } else if (strcmp(tag, "ray_point") == 0) {
            if (sscanf(line, "%*s%*s%u%99s%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64,
                &index, name, &bits[0], &bits[1], &bits[2], &bits[3]) != 6) camera_fail("point record");
            check_camera_vector(point_on_ray_at_parameter(named_camera_ray(bundle, name), camera_from_bits(bits[0])),
                bits + 1, "ray point"); ++points;
        } else if (strcmp(tag, "normal") == 0) {
            if (sscanf(line, "%*s%*s%u%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64,
                &index, &bits[0], &bits[1], &bits[2], &bits[3], &bits[4], &bits[5]) != 7) camera_fail("normal record");
            const surfer_vec3 normal = {camera_from_bits(bits[0]), camera_from_bits(bits[1]), camera_from_bits(bits[2])};
            check_camera_vector(apply_matrix_to_vector(view.surface_normal_to_camera, normal), bits + 3, "normal transform"); ++normals;
        } else if (strcmp(tag, "camera_end") != 0) camera_fail("unknown record");
    }
    if (ferror(input) || fclose(input) != 0 || cases != 7 || matrices != 672 || vectors != 84 || scalars != 42 ||
        intervals != 14 || samples != 109 || rays != 327 || points != 1962 || normals != 28) camera_fail("corpus coverage");
    puts("PASS original orthographic matrices normalization offsets rays and normals");
    return 0;
}
