/* Exact observations from unchanged original Java, not another implementation. */
#define SURFER_TEST_ALLOCATION_FAILURES
#include "surfer_raytracer.c"
#include <inttypes.h>
#include <stdio.h>

static const char *case_name = "before first case";
static size_t record_number;

static void specialization_fail(const char *reason)
{
    fprintf(stderr, "FAIL original specialization: %s record%zu %s\n", case_name, record_number, reason);
    exit(1);
}

static double double_from_bits(uint64_t bits)
{
    double value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static uint64_t double_bits(double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static void require_term(surfer_term actual, uint64_t coefficient, int x, int y, int z)
{
    if (double_bits(actual.coefficient) != coefficient || actual.x_exponent != x ||
        actual.y_exponent != y || actual.z_exponent != z) {
        fprintf(stderr, "actual %016" PRIx64 " %d %d %d; expected %016" PRIx64 " %d %d %d\n",
            double_bits(actual.coefficient), actual.x_exponent, actual.y_exponent, actual.z_exponent,
            coefficient, x, y, z);
        specialization_fail("term bytes/order");
    }
}

typedef struct { size_t checks, stop; } specialization_cancel_probe;

static bool cancel_specialization(void *opaque)
{
    specialization_cancel_probe *probe = opaque;
    return probe->checks++ == probe->stop;
}

static void check_specialization_failures(void)
{
    /* A nontrivial cubic and all three genuine prepared derivatives exercise
     * transformed products, Kahan storage, row and column ownership. */
    const surfer_term surface[] = {{-0.3, 0, 0, 0}, {1, 0, 0, 3}, {1, 0, 3, 0}, {1, 1, 1, 1}, {1, 3, 0, 0}};
    const surfer_term dx[] = {{1, 0, 1, 1}, {3, 2, 0, 0}};
    const surfer_term dy[] = {{3, 0, 2, 0}, {1, 1, 0, 1}};
    const surfer_term dz[] = {{3, 0, 0, 2}, {1, 1, 1, 0}};
    const surfer_prepared_surface prepared = {3, {surface, 5}, {dx, 2}, {dy, 2}, {dz, 2}};
    const surfer_scene scene = surfer_default_scene(&prepared);
    uint32_t pixels[9];
    for (unsigned mode = 0; mode < 2; ++mode) {
        const surfer_render_quality quality = {(surfer_antialiasing_pattern)mode, 0.3f};
        surfer_allocation_probe probe = {SIZE_MAX, 0, 0};
        if (surfer_test_render_orthographic_quality(&scene, 3, 3, 2.15, 0.43, -0.71, 1,
            quality, pixels, 9, &probe) != SURFER_OK || probe.attempts == 0 ||
            (probe.paths & UINT32_C(0x400)) == 0) specialization_fail("allocation baseline");
        const size_t count = probe.attempts;
        for (size_t failure = 0; failure < count; ++failure) {
            probe = (surfer_allocation_probe){failure, 0, 0};
            const surfer_status status = surfer_test_render_orthographic_quality(&scene,
                3, 3, 2.15, 0.43, -0.71, 1, quality, pixels, 9, &probe);
            if (status != SURFER_OUT_OF_MEMORY || probe.attempts != failure + 1) {
                fprintf(stderr, "mode%u fault%zu status%d attempts%zu\n", mode, failure, status, probe.attempts);
                specialization_fail("actual transformed allocation fault");
            }
        }
        printf("specialization allocation faults mode%u: %zu\n", mode, count);
        specialization_cancel_probe cancellation = {0, SIZE_MAX};
        const surfer_cancellation predicate = {cancel_specialization, &cancellation};
        if (surfer_render_orthographic_cancellable(&scene, 3, 3, 2.15, 0.43, -0.71, 1,
            quality, &predicate, pixels, 9) != SURFER_OK || cancellation.checks < 32)
            specialization_fail("cancellation baseline");
        const size_t checks = cancellation.checks;
        for (size_t sample = 0; sample <= 32; ++sample) {
            cancellation = (specialization_cancel_probe){0, (checks - 1) * sample / 32};
            if (surfer_render_orthographic_cancellable(&scene, 3, 3, 2.15, 0.43, -0.71, 1,
                quality, &predicate, pixels, 9) != SURFER_CANCELLED)
                specialization_fail("cancel transformed work and release private ownership");
        }
    }
}

int main(int argc, char **argv)
{
    if (argc != 2) specialization_fail("reference argument");
    FILE *input = fopen(argv[1], "r");
    if (input == NULL) specialization_fail("reference unavailable");
    char line[2048], tag[64], identity[120], current_identity[120] = "none";
    surfer_operation_context context = new_operation_context();
    original_xyz_polynomial coordinates[3] = {{0}};
    original_xyz_polynomial polynomials[4] = {{0}}, transformed[4] = {{0}};
    original_xy_polynomial row = {0};
    univariate_polynomial column = {0};
    size_t cases = 0, transformations = 0, rows = 0, columns = 0, evaluations = 0, unused_squares = 0;
    bool reduced_difference = false;
    while (fgets(line, sizeof(line), input) != NULL) {
        ++record_number;
        if (strchr(line, '\n') == NULL || sscanf(line, "%63s%119s", tag, identity) != 2)
            specialization_fail("malformed record");
        if (strcmp(tag, "unused_square") == 0) {
            int exponent;
            uint64_t base, expected;
            if (sscanf(line, "%*s%*s%d%" SCNx64 "%" SCNx64, &exponent, &base, &expected) != 3)
                specialization_fail("unused final square observation");
            surfer_operation_context power_context = new_operation_context();
            original_xyz_polynomial original_base = original_constant_xyz(&power_context,
                double_from_bits(base));
            original_xyz_polynomial power = original_power_xyz(&power_context, &original_base, exponent);
            if (power_context.status != SURFER_OK || power.count != 1 ||
                double_bits(power.terms[0].coefficient) != expected)
                specialization_fail("finite used power rejected by unused square");
            original_free_xyz(power); original_free_xyz(original_base);
            ++unused_squares;
            continue;
        }
        if (strcmp(tag, "case") == 0) {
            strcpy(current_identity, identity); case_name = current_identity;
            context = new_operation_context(); ++cases;
            continue;
        }
        if (strcmp(identity, current_identity) != 0) specialization_fail("mixed case identity");
        unsigned component, sample;
        size_t count, index;
        uint64_t bits;
        int x, y, z;
        if (strcmp(tag, "formula") == 0) continue;
        if (strcmp(tag, "map") == 0) {
            uint64_t constant, direction, horizontal, vertical;
            if (sscanf(line, "%*s%*s%u%" SCNx64 "%" SCNx64 "%" SCNx64 "%" SCNx64,
                &component, &constant, &direction, &horizontal, &vertical) != 5 || component >= 3)
                specialization_fail("map record");
            coordinates[component] = original_coordinate_xyz(&context,
                double_from_bits(constant), double_from_bits(direction),
                double_from_bits(horizontal), double_from_bits(vertical));
        } else if (strcmp(tag, "map_terms") == 0) {
            if (sscanf(line, "%*s%*s%u%zu", &component, &count) != 2 || component >= 3 ||
                coordinates[component].count != count) specialization_fail("coordinate term count");
        } else if (strcmp(tag, "map_term") == 0) {
            if (sscanf(line, "%*s%*s%u%zu%" SCNx64 "%d%d%d", &component, &index, &bits, &x, &y, &z) != 6 ||
                component >= 3 || index >= coordinates[component].count) specialization_fail("coordinate term");
            require_term(coordinates[component].terms[index], bits, x, y, z);
        } else if (strcmp(tag, "input") == 0) {
            if (sscanf(line, "%*s%*s%u%zu", &component, &count) != 2 || component >= 4)
                specialization_fail("input record");
            polynomials[component] = original_allocate_xyz(&context, count);
        } else if (strcmp(tag, "term") == 0) {
            if (sscanf(line, "%*s%*s%u%zu%" SCNx64 "%d%d%d", &component, &index, &bits, &x, &y, &z) != 6 ||
                component >= 4 || index >= polynomials[component].count) specialization_fail("input term");
            polynomials[component].terms[index] = (surfer_term){double_from_bits(bits), x, y, z};
        } else if (strcmp(tag, "transformed") == 0) {
            if (sscanf(line, "%*s%*s%u%zu", &component, &count) != 2 || component >= 4)
                specialization_fail("transformed record");
            transformed[component] = original_substitute_xyz(&context,
                (surfer_sparse_polynomial){polynomials[component].terms, polynomials[component].count}, coordinates);
            if (context.status != SURFER_OK || transformed[component].count != count)
                specialization_fail("transformed count/status");
            ++transformations;
        } else if (strcmp(tag, "transformed_term") == 0) {
            if (sscanf(line, "%*s%*s%u%zu%" SCNx64 "%d%d%d", &component, &index, &bits, &x, &y, &z) != 6 ||
                component >= 4 || index >= transformed[component].count) specialization_fail("transformed term");
            require_term(transformed[component].terms[index], bits, x, y, z);
        } else if (strcmp(tag, "row") == 0) {
            if (sscanf(line, "%*s%*s%u%u%" SCNx64 "%zu", &component, &sample, &bits, &count) != 4 || component >= 4)
                specialization_fail("row record");
            original_free_xyz(row);
            row = original_evaluate_z(&context, &transformed[component], double_from_bits(bits));
            if (context.status != SURFER_OK || row.count != count) specialization_fail("row count/status");
            ++rows;
        } else if (strcmp(tag, "row_term") == 0) {
            if (sscanf(line, "%*s%*s%u%u%zu%" SCNx64 "%d%d", &component, &sample, &index, &bits, &x, &y) != 6 ||
                index >= row.count) specialization_fail("row term record");
            require_term(row.terms[index], bits, x, y, 0);
        } else if (strcmp(tag, "column") == 0) {
            if (sscanf(line, "%*s%*s%u%u%" SCNx64 "%zu", &component, &sample, &bits, &count) != 4 || component >= 4)
                specialization_fail("column record");
            free_univariate_polynomial(column);
            column = original_evaluate_y(&context, &row, double_from_bits(bits));
            if (context.status != SURFER_OK || column.length != count) specialization_fail("column count/status");
            ++columns;
            if (strcmp(current_identity, "sphere-rotated") == 0 && component == 0 && sample == 0) {
                const surfer_vec3 horizontal = {0.8, 0.0, -0.6}, vertical = {0.48, 0.8, 0.64};
                const surfer_ray ray = {add_vectors(scale_vector(horizontal, -1.0),
                    scale_vector(vertical, -1.0)), {-0.36, 0.6, -0.48}};
                univariate_polynomial direct = {0};
                surfer_operation_context control = new_operation_context();
                if (!expand_sparse_polynomial_directly_along_ray(&control,
                    (surfer_sparse_polynomial){polynomials[0].terms, polynomials[0].count}, ray, &direct) ||
                    direct.length != 3 || column.length != 3 || double_bits(direct.coefficients[1]) != 0 ||
                    double_bits(column.coefficients[1]) != UINT64_C(0xbc90000000000000))
                    specialization_fail("reduced direct-versus-original discrepancy absent");
                reduced_difference = true;
                free_univariate_polynomial(direct);
            }
        } else if (strcmp(tag, "coefficient") == 0) {
            if (sscanf(line, "%*s%*s%u%u%zu%" SCNx64, &component, &sample, &index, &bits) != 4 ||
                index >= column.length) specialization_fail("coefficient record");
            if (double_bits(column.coefficients[index]) != bits) {
                fprintf(stderr, "coefficient%zu actual%016" PRIx64 " expected%016" PRIx64 "\n",
                    index, double_bits(column.coefficients[index]), bits);
                specialization_fail("coefficient raw bits");
            }
        } else if (strcmp(tag, "evaluation") == 0) {
            uint64_t expected;
            if (sscanf(line, "%*s%*s%u%u%" SCNx64 "%" SCNx64, &component, &sample, &bits, &expected) != 4)
                specialization_fail("evaluation record");
            const double actual = evaluate_univariate_polynomial_at(&context, &column, double_from_bits(bits));
            if (context.status != SURFER_OK || double_bits(actual) != expected) {
                fprintf(stderr, "at%016" PRIx64 " actual%016" PRIx64 " expected%016" PRIx64 "\n",
                    bits, double_bits(actual), expected);
                specialization_fail("evaluation raw bits");
            }
            ++evaluations;
        } else if (strcmp(tag, "case_end") == 0) {
            for (size_t axis = 0; axis < 3; ++axis) { original_free_xyz(coordinates[axis]); coordinates[axis] = original_empty_xyz(); }
            for (size_t polynomial = 0; polynomial < 4; ++polynomial) {
                original_free_xyz(polynomials[polynomial]); polynomials[polynomial] = original_empty_xyz();
                original_free_xyz(transformed[polynomial]); transformed[polynomial] = original_empty_xyz();
            }
            original_free_xyz(row); row = original_empty_xyz();
            free_univariate_polynomial(column); column = empty_univariate_polynomial();
        } else specialization_fail("unknown record");
        if (context.status != SURFER_OK) specialization_fail("native status");
    }
    if (ferror(input) || fclose(input) != 0 || cases != 30 || transformations != 120 ||
        rows != 840 || columns != 840 || evaluations != 5880 || unused_squares != 6 || !reduced_difference)
        specialization_fail("corpus coverage");
    check_specialization_failures();
    puts("PASS original transformed XYZ row column and gradient univariate bytes");
    return 0;
}
