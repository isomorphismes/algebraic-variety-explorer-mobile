/* Canonical polynomial presets from SurfaceExamples.java, expanded exactly.
 * This is only the preset adapter: future Idriç input owns arbitrary syntax.
 * Christian Stussak jsurf-derived SURFER work remains Apache-2.0.
 */
#include "presets.h"
#include <string.h>

typedef struct {
    const char *name;
    const surfer_term *terms;
    size_t count;
    int32_t degree;
} preset_definition;

static const surfer_term ave_terms_0[] = {
    {1.00000000, 2, 0, 0},
    {1.00000000, 0, 2, 0},
    {1.00000000, 0, 0, 2},
    {-0.64000000, 0, 0, 0}
};

static const surfer_term ave_terms_1[] = {
    {1.00000000, 4, 0, 0},
    {2.00000000, 2, 2, 0},
    {2.00000000, 2, 0, 2},
    {-0.97000000, 2, 0, 0},
    {1.00000000, 0, 4, 0},
    {2.00000000, 0, 2, 2},
    {-0.97000000, 0, 2, 0},
    {1.00000000, 0, 0, 4},
    {0.72000000, 0, 0, 2},
    {0.12960000, 0, 0, 0}
};

static const surfer_term ave_terms_2[] = {
    {1.00000000, 2, 0, 0},
    {2.00000000, 1, 1, 1},
    {1.00000000, 0, 2, 0},
    {1.00000000, 0, 0, 2},
    {-1.00000000, 0, 0, 0}
};

static const surfer_term ave_terms_3[] = {
    {1.00000000, 2, 0, 0},
    {-1.00000000, 0, 2, 1}
};

static const surfer_term ave_terms_4[] = {
    {1.00000000, 2, 2, 0},
    {1.00000000, 2, 0, 2},
    {-1.00000000, 1, 1, 1},
    {1.00000000, 0, 2, 2}
};

static const surfer_term ave_terms_5[] = {
    {1.00000000, 6, 0, 0},
    {6.75000000, 4, 2, 0},
    {3.00000000, 4, 0, 2},
    {-3.00000000, 4, 0, 0},
    {15.18750000, 2, 4, 0},
    {13.50000000, 2, 2, 2},
    {-13.50000000, 2, 2, 0},
    {3.00000000, 2, 0, 4},
    {-1.00000000, 2, 0, 3},
    {-6.00000000, 2, 0, 2},
    {3.00000000, 2, 0, 0},
    {11.39062500, 0, 6, 0},
    {15.18750000, 0, 4, 2},
    {-15.18750000, 0, 4, 0},
    {6.75000000, 0, 2, 4},
    {-0.11250000, 0, 2, 3},
    {-13.50000000, 0, 2, 2},
    {6.75000000, 0, 2, 0},
    {1.00000000, 0, 0, 6},
    {-3.00000000, 0, 0, 4},
    {3.00000000, 0, 0, 2},
    {-1.00000000, 0, 0, 0}
};

static const surfer_term ave_terms_6[] = {
    {1.00000000, 2, 0, 0},
    {1.00000000, 1, 0, 2},
    {1.00000000, 0, 3, 0}
};

static const preset_definition presets[] = {
    {"Sphere", ave_terms_0, sizeof(ave_terms_0) / sizeof(ave_terms_0[0]), 2},
    {"Torus", ave_terms_1, sizeof(ave_terms_1) / sizeof(ave_terms_1[0]), 4},
    {"Cayley cubic", ave_terms_2, sizeof(ave_terms_2) / sizeof(ave_terms_2[0]), 3},
    {"Whitney umbrella", ave_terms_3, sizeof(ave_terms_3) / sizeof(ave_terms_3[0]), 3},
    {"Roman surface", ave_terms_4, sizeof(ave_terms_4) / sizeof(ave_terms_4[0]), 4},
    {"Heart", ave_terms_5, sizeof(ave_terms_5) / sizeof(ave_terms_5[0]), 6},
    {"Madore E6 cubic", ave_terms_6, sizeof(ave_terms_6) / sizeof(ave_terms_6[0]), 3}
};

size_t ave_native_preset_count(void)
{
    return sizeof(presets) / sizeof(presets[0]);
}

bool ave_native_load_preset(size_t index, ave_native_preset *result)
{
    if (result == NULL || index >= ave_native_preset_count()) {
        return false;
    }

    const preset_definition *definition = &presets[index];
    if (definition->count > AVE_MAX_PRESET_TERMS) {
        return false;
    }
    memset(result, 0, sizeof(*result));
    result->name = definition->name;
    result->surface.family_degree = definition->degree;
    result->surface.surface.terms = definition->terms;
    result->surface.surface.term_count = definition->count;

    surfer_sparse_polynomial *derivatives[3] = {
        &result->surface.gradient_x,
        &result->surface.gradient_y,
        &result->surface.gradient_z
    };
    for (size_t axis = 0; axis < 3; ++axis) {
        size_t count = 0;
        for (size_t term = 0; term < definition->count; ++term) {
            surfer_term current = definition->terms[term];
            int32_t *exponent = axis == 0 ? &current.x_exponent :
                (axis == 1 ? &current.y_exponent : &current.z_exponent);
            if (*exponent == 0) {
                continue;
            }
            current.coefficient *= (double)*exponent;
            --*exponent;
            result->derivatives[axis][count++] = current;
        }
        derivatives[axis]->terms = result->derivatives[axis];
        derivatives[axis]->term_count = count;
    }
    return true;
}
