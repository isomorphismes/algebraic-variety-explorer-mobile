/*
 * Direct C translation slice of Christian Stussak's jsurf algebra core.
 * Derived from UnivariatePolynomial.java and ClosedFormRootFinder.java,
 * Apache-2.0.
 */
#ifndef SURFER_POLY_H
#define SURFER_POLY_H

#include <stdbool.h>
#include <stddef.h>

typedef struct {
    double *coefficients; /* a[0] + a[1] x + ... */
    size_t degree;
} surfer_poly;

typedef struct {
    double values[4];
    size_t count;
} surfer_roots4;

bool surfer_poly_from_coefficients(
    surfer_poly *out,
    const double *coefficients,
    size_t coefficient_count);
bool surfer_poly_zeroed(surfer_poly *out, size_t degree);
bool surfer_poly_copy(surfer_poly *out, const surfer_poly *source);
void surfer_poly_destroy(surfer_poly *poly);

bool surfer_poly_is_zero(const surfer_poly *poly);
bool surfer_poly_is_one(const surfer_poly *poly);
double surfer_poly_coefficient(const surfer_poly *poly, size_t degree);

bool surfer_poly_neg(surfer_poly *out, const surfer_poly *poly);
bool surfer_poly_add(surfer_poly *out, const surfer_poly *left, const surfer_poly *right);
bool surfer_poly_add_scalar(surfer_poly *out, const surfer_poly *poly, double scalar);
bool surfer_poly_sub(surfer_poly *out, const surfer_poly *left, const surfer_poly *right);
bool surfer_poly_mul(surfer_poly *out, const surfer_poly *left, const surfer_poly *right);
bool surfer_poly_mul_scalar(surfer_poly *out, const surfer_poly *poly, double scalar);
bool surfer_poly_pow(surfer_poly *out, const surfer_poly *poly, unsigned exponent);
bool surfer_poly_derive(surfer_poly *out, const surfer_poly *poly);
bool surfer_poly_shift(surfer_poly *out, const surfer_poly *poly, double amount);
bool surfer_poly_reverse_shift(surfer_poly *out, const surfer_poly *poly, double amount);
bool surfer_poly_stretch(surfer_poly *out, const surfer_poly *poly, double factor);

double surfer_poly_evaluate(const surfer_poly *poly, double x);
int surfer_poly_coefficient_sign_changes(const surfer_poly *poly);
int surfer_poly_descartes_sign_changes_shift1(const surfer_poly *poly);
int surfer_poly_descartes_sign_changes_reverse_shift1(const surfer_poly *poly);

/* Direct C port of ClosedFormRootFinder.java for degree <= 4. */
bool surfer_closed_form_roots(const surfer_poly *poly, surfer_roots4 *out);
bool surfer_closed_form_roots_in(
    const surfer_poly *poly,
    double lower,
    double upper,
    surfer_roots4 *out);
bool surfer_closed_form_first_root_in(
    const surfer_poly *poly,
    double lower,
    double upper,
    double *root);

#endif
