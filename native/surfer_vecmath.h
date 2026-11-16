/* Vecmath-derived arithmetic module: GPL-2.0-only WITH Classpath-exception-2.0.
 * Kept separate from the Apache-2.0 Stussak/application camera composition.
 */
#ifndef SURFER_VECMATH_H
#define SURFER_VECMATH_H
#include <stdbool.h>

typedef struct { double entries[16]; } surfer_vecmath_matrix4;
typedef struct { double x, y, z; } surfer_vecmath_vector3;
typedef bool (*surfer_vecmath_continue)(void *state);

#define SURFER_VECMATH_INTERNAL __attribute__((visibility("hidden")))
SURFER_VECMATH_INTERNAL surfer_vecmath_matrix4 surfer_vecmath_identity4(void);
SURFER_VECMATH_INTERNAL surfer_vecmath_matrix4 surfer_vecmath_multiply4(
    surfer_vecmath_matrix4 left, surfer_vecmath_matrix4 right);
SURFER_VECMATH_INTERNAL bool surfer_vecmath_inverse4(surfer_vecmath_matrix4 input,
    surfer_vecmath_matrix4 *output, surfer_vecmath_continue proceed, void *state);
SURFER_VECMATH_INTERNAL surfer_vecmath_vector3 surfer_vecmath_transform_vector4(
    surfer_vecmath_matrix4 matrix, surfer_vecmath_vector3 value);
SURFER_VECMATH_INTERNAL surfer_vecmath_vector3 surfer_vecmath_transform_point4(
    surfer_vecmath_matrix4 matrix, surfer_vecmath_vector3 value);
#endif
