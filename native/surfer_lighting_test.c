/* Test-only comparisons with frozen Stussak RenderingTask observations. */
#include "surfer_raytracer.c"
#include <float.h>
#include <inttypes.h>
#include <stdio.h>

_Static_assert(FLT_RADIX == 2 && FLT_MANT_DIG == 24 && FLT_EVAL_METHOD == 0,
    "strict binary32 color operations required");
_Static_assert(DBL_MANT_DIG == 53 && sizeof(double) == sizeof(uint64_t),
    "binary64 geometry required");

static const char *lighting_case = "before first scene";

static void lighting_fail(const char *reason)
{
    fprintf(stderr, "FAIL original lighting: %s %s\n", lighting_case, reason);
    exit(1);
}

static uint32_t lighting_float_bits(float value)
{
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static uint64_t lighting_double_bits(double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static float lighting_read_float(FILE *input)
{
    uint32_t bits;
    if (fscanf(input, "%" SCNx32, &bits) != 1) lighting_fail("missing binary32 input");
    float value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static double lighting_read_double(FILE *input)
{
    uint64_t bits;
    if (fscanf(input, "%" SCNx64, &bits) != 1) lighting_fail("missing binary64 input");
    double value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static surfer_color lighting_read_color(FILE *input)
{
    const float red = lighting_read_float(input);
    const float green = lighting_read_float(input);
    const float blue = lighting_read_float(input);
    return (surfer_color){red, green, blue};
}

static surfer_vec3 lighting_read_vector(FILE *input)
{
    const double x = lighting_read_double(input);
    const double y = lighting_read_double(input);
    const double z = lighting_read_double(input);
    return (surfer_vec3){x, y, z};
}

static void lighting_require_color(surfer_color actual, surfer_color expected)
{
    if (lighting_float_bits(actual.red) != lighting_float_bits(expected.red) ||
        lighting_float_bits(actual.green) != lighting_float_bits(expected.green) ||
        lighting_float_bits(actual.blue) != lighting_float_bits(expected.blue)) {
        fprintf(stderr, "actual %08" PRIx32 " %08" PRIx32 " %08" PRIx32
            "; expected %08" PRIx32 " %08" PRIx32 " %08" PRIx32 "\n",
            lighting_float_bits(actual.red), lighting_float_bits(actual.green),
            lighting_float_bits(actual.blue), lighting_float_bits(expected.red),
            lighting_float_bits(expected.green), lighting_float_bits(expected.blue));
        lighting_fail("binary32 color bytes");
    }
}

static void lighting_require_vector(surfer_vec3 actual, surfer_vec3 expected)
{
    if (lighting_double_bits(actual.x) != lighting_double_bits(expected.x) ||
        lighting_double_bits(actual.y) != lighting_double_bits(expected.y) ||
        lighting_double_bits(actual.z) != lighting_double_bits(expected.z))
        lighting_fail("post-shade normal bytes");
}

int main(int argc, char **argv)
{
    if (argc != 2) lighting_fail("reference argument");
    FILE *input = fopen(argv[1], "r");
    if (input == NULL) lighting_fail("reference file unavailable");
    const surfer_prepared_surface unused = {0};
    surfer_scene scene = surfer_default_scene(&unused);
    char tag[32], identity[100], side[20], scene_name[100];
    size_t scenes = 0, shades = 0, products = 0, ambient = 0;
    while (fscanf(input, "%31s", tag) == 1) {
        if (strcmp(tag, "scene") == 0) {
            if (fscanf(input, "%99s", scene_name) != 1) lighting_fail("scene identity");
            lighting_case = scene_name;
            scene = surfer_default_scene(&unused);
            scene.light_count = 0;
            scenes++;
        } else if (strcmp(tag, "material") == 0) {
            if (fscanf(input, "%19s", side) != 1) lighting_fail("material side");
            surfer_material *material = strcmp(side, "front") == 0 ? &scene.front_material :
                strcmp(side, "back") == 0 ? &scene.back_material : NULL;
            if (material == NULL) lighting_fail("unknown material side");
            material->color = lighting_read_color(input);
            material->ambient_intensity = lighting_read_float(input);
            material->diffuse_intensity = lighting_read_float(input);
            material->specular_intensity = lighting_read_float(input);
            material->shininess = lighting_read_float(input);
        } else if (strcmp(tag, "light") == 0) {
            size_t index;
            if (fscanf(input, "%zu", &index) != 1 || index != scene.light_count ||
                index >= SURFER_MAX_LIGHTS) lighting_fail("active light order");
            surfer_light *light = &scene.lights[scene.light_count++];
            light->enabled = true;
            light->position = lighting_read_vector(input);
            light->color = lighting_read_color(input);
            light->intensity = lighting_read_float(input);
        } else if (strcmp(tag, "ambient") == 0) {
            if (fscanf(input, "%19s", side) != 1) lighting_fail("ambient side");
            const surfer_material material = strcmp(side, "front") == 0 ? scene.front_material :
                scene.back_material;
            const surfer_color expected = lighting_read_color(input);
            lighting_require_color(scale_color(material.color, scene.front_material.ambient_intensity), expected);
            ambient++;
        } else if (strcmp(tag, "products") == 0) {
            size_t index;
            if (fscanf(input, "%zu%19s", &index, side) != 2 || index >= scene.light_count)
                lighting_fail("light product identity");
            const surfer_material material = strcmp(side, "front") == 0 ? scene.front_material :
                scene.back_material;
            const surfer_light light = scene.lights[index];
            const surfer_color diffuse = lighting_read_color(input);
            const surfer_color specular = lighting_read_color(input);
            lighting_require_color(scale_color(multiply_colors(material.color, light.color),
                material.diffuse_intensity * light.intensity), diffuse);
            lighting_require_color(scale_color(light.color,
                material.specular_intensity * light.intensity), specular);
            products++;
        } else if (strcmp(tag, "shade") == 0) {
            if (fscanf(input, "%99s", identity) != 1) lighting_fail("shade identity");
            lighting_case = identity;
            const surfer_vec3 point = lighting_read_vector(input);
            const surfer_vec3 normal_input = lighting_read_vector(input);
            const surfer_vec3 eye = lighting_read_vector(input);
            const surfer_color expected = lighting_read_color(input);
            const surfer_vec3 normal_expected = lighting_read_vector(input);
            surfer_vec3 normal = normalize_surface_normal(normal_input);
            const surfer_vec3 view = normalize_vector(subtract_vectors(eye, point));
            const surfer_material material = material_for_visible_side(&scene, view, &normal);
            lighting_require_color(shade_hit_with_original_material(&scene, point, view, normal,
                material), expected);
            lighting_require_vector(normal, normal_expected);
            shades++;
            lighting_case = scene_name;
        } else if (strcmp(tag, "scene_end") == 0) {
            if (fscanf(input, "%99s", identity) != 1 || strcmp(identity, scene_name) != 0)
                lighting_fail("scene end identity");
        } else lighting_fail("unknown record");
    }
    if (ferror(input) || fclose(input) != 0 || scenes != 6 || shades != 288 ||
        products != 26 || ambient != 12) lighting_fail("required lighting coverage");
    printf("lighting scenes %zu shades %zu products %zu ambient %zu\n", scenes, shades, products, ambient);
    puts("PASS original ambient light products normal material and binary64 specular bytes");
    return 0;
}
