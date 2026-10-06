/*
 * Direct C translation slice of Christian Stussak's jsurf algebra core.
 * Derived from UnivariatePolynomial.java and ClosedFormRootFinder.java,
 * Apache-2.0.
 *
 * Keep the Java algorithms recognizable. This is deliberately not a cleanup
 * pass: numerical equivalence comes before C-specific redesign.
 */
#include "surfer_poly.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static bool allocate_poly(surfer_poly *out, size_t degree)
{
    out->coefficients = calloc(degree + 1, sizeof(*out->coefficients));
    if (out->coefficients == NULL) {
        out->degree = 0;
        return false;
    }
    out->degree = degree;
    return true;
}

static void compact_in_place(surfer_poly *poly)
{
    while (poly->degree > 0 && poly->coefficients[poly->degree] == 0.0) {
        --poly->degree;
    }
}

static bool replace_with_copy(surfer_poly *out, const surfer_poly *source)
{
    surfer_poly tmp = {0};
    if (!surfer_poly_copy(&tmp, source)) {
        return false;
    }
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

bool surfer_poly_from_coefficients(
    surfer_poly *out,
    const double *coefficients,
    size_t coefficient_count)
{
    if (out == NULL || coefficients == NULL || coefficient_count == 0) {
        return false;
    }
    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, coefficient_count - 1)) {
        return false;
    }
    memcpy(tmp.coefficients, coefficients, coefficient_count * sizeof(*coefficients));
    compact_in_place(&tmp);
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

bool surfer_poly_zeroed(surfer_poly *out, size_t degree)
{
    if (out == NULL) {
        return false;
    }
    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, degree)) {
        return false;
    }
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

bool surfer_poly_copy(surfer_poly *out, const surfer_poly *source)
{
    if (out == NULL || source == NULL || source->coefficients == NULL) {
        return false;
    }
    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, source->degree)) {
        return false;
    }
    memcpy(
        tmp.coefficients,
        source->coefficients,
        (source->degree + 1) * sizeof(*source->coefficients));
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

void surfer_poly_destroy(surfer_poly *poly)
{
    if (poly == NULL) {
        return;
    }
    free(poly->coefficients);
    poly->coefficients = NULL;
    poly->degree = 0;
}

bool surfer_poly_is_zero(const surfer_poly *poly)
{
    if (poly == NULL || poly->coefficients == NULL) {
        return true;
    }
    for (size_t i = 0; i <= poly->degree; ++i) {
        if (poly->coefficients[i] != 0.0) {
            return false;
        }
    }
    return true;
}

bool surfer_poly_is_one(const surfer_poly *poly)
{
    if (poly == NULL || poly->coefficients == NULL || poly->coefficients[0] != 1.0) {
        return false;
    }
    for (size_t i = 1; i <= poly->degree; ++i) {
        if (poly->coefficients[i] != 0.0) {
            return false;
        }
    }
    return true;
}

double surfer_poly_coefficient(const surfer_poly *poly, size_t degree)
{
    if (poly == NULL || poly->coefficients == NULL || degree > poly->degree) {
        return 0.0;
    }
    return poly->coefficients[degree];
}

bool surfer_poly_neg(surfer_poly *out, const surfer_poly *poly)
{
    if (out == NULL || poly == NULL || poly->coefficients == NULL) {
        return false;
    }
    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, poly->degree)) {
        return false;
    }
    for (size_t i = 0; i <= poly->degree; ++i) {
        tmp.coefficients[i] = -poly->coefficients[i];
    }
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

bool surfer_poly_add(surfer_poly *out, const surfer_poly *left, const surfer_poly *right)
{
    if (out == NULL || left == NULL || right == NULL ||
        left->coefficients == NULL || right->coefficients == NULL) {
        return false;
    }
    const size_t degree = left->degree > right->degree ? left->degree : right->degree;
    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, degree)) {
        return false;
    }
    for (size_t i = 0; i <= left->degree; ++i) {
        tmp.coefficients[i] += left->coefficients[i];
    }
    for (size_t i = 0; i <= right->degree; ++i) {
        tmp.coefficients[i] += right->coefficients[i];
    }
    compact_in_place(&tmp);
   