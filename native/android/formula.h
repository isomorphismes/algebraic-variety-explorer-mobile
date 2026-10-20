/* Bounded polynomial input to SURFER PreparedSurface boundary.
 * Native C bootstrap; typed Idriç lexer/lowering is a separate pending step.
 * Original SURFER/jsurf by Christian Stussak (Apache-2.0; see NOTICE).
 */
#ifndef AVE_NATIVE_FORMULA_H
#define AVE_NATIVE_FORMULA_H
#include "../surfer_raytracer.h"
#define AVE_FORMULA_MAX_SOURCE 128
#define AVE_FORMULA_MAX_TERMS 128
#define AVE_FORMULA_MAX_DEGREE 8

typedef struct {
    surfer_term terms[AVE_FORMULA_MAX_TERMS];
    surfer_term derivatives[3][AVE_FORMULA_MAX_TERMS];
    surfer_prepared_surface surface;
} ave_formula;

/* Failure leaves *result intact. Result owns its polynomial storage.
 * Do not copy ave_formula by value: its term pointers refer to itself.
 * Supports x,y,z, finite numbers, +,-,*,/,^,(),=,²,³,×,−,÷.
 * Division only by nonzero constant, degree <=8, <=128 collected terms;
 * products must be explicit. Not an unbounded general-purpose parser.
 */
bool ave_formula_compile(const char *source, ave_formula *result,
                         char *error, size_t error_capacity);
#endif
