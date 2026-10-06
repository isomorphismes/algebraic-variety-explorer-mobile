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
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

bool surfer_poly_add_scalar(surfer_poly *out, const surfer_poly *poly, double scalar)
{
    if (out == NULL || poly == NULL || poly->coefficients == NULL) {
        return false;
    }
    if (!surfer_poly_copy(out, poly)) {
        return false;
    }
    out->coefficients[0] += scalar;
    compact_in_place(out);
    return true;
}

bool surfer_poly_sub(surfer_poly *out, const surfer_poly *left, const surfer_poly *right)
{
    surfer_poly negative = {0};
    bool ok = surfer_poly_neg(&negative, right) && surfer_poly_add(out, left, &negative);
    surfer_poly_destroy(&negative);
    return ok;
}

bool surfer_poly_mul(surfer_poly *out, const surfer_poly *left, const surfer_poly *right)
{
    if (out == NULL || left == NULL || right == NULL ||
        left->coefficients == NULL || right->coefficients == NULL) {
        return false;
    }
    if (surfer_poly_is_zero(left) || surfer_poly_is_zero(right)) {
        const double zero = 0.0;
        return surfer_poly_from_coefficients(out, &zero, 1);
    }
    if (surfer_poly_is_one(left)) {
        return replace_with_copy(out, right);
    }
    if (surfer_poly_is_one(right)) {
        return replace_with_copy(out, left);
    }

    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, left->degree + right->degree)) {
        return false;
    }
    for (size_t i = 0; i <= left->degree; ++i) {
        for (size_t j = 0; j <= right->degree; ++j) {
            tmp.coefficients[i + j] += left->coefficients[i] * right->coefficients[j];
        }
    }
    compact_in_place(&tmp);
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

bool surfer_poly_mul_scalar(surfer_poly *out, const surfer_poly *poly, double scalar)
{
    if (out == NULL || poly == NULL || poly->coefficients == NULL) {
        return false;
    }
    if (scalar == 0.0) {
        const double zero = 0.0;
        return surfer_poly_from_coefficients(out, &zero, 1);
    }
    if (scalar == 1.0) {
        return replace_with_copy(out, poly);
    }
    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, poly->degree)) {
        return false;
    }
    for (size_t i = 0; i <= poly->degree; ++i) {
        tmp.coefficients[i] = poly->coefficients[i] * scalar;
    }
    compact_in_place(&tmp);
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

bool surfer_poly_pow(surfer_poly *out, const surfer_poly *poly, unsigned exponent)
{
    if (out == NULL || poly == NULL || poly->coefficients == NULL) {
        return false;
    }
    if (exponent == 0) {
        const double one = 1.0;
        return surfer_poly_from_coefficients(out, &one, 1);
    }
    if (exponent == 1) {
        return replace_with_copy(out, poly);
    }

    /* Preserve Java's fast binomial path for a linear polynomial. */
    if (poly->degree == 1) {
        surfer_poly tmp = {0};
        if (!allocate_poly(&tmp, exponent)) {
            return false;
        }
        const double a0 = poly->coefficients[0];
        const double a1 = poly->coefficients[1];
        double *powers0 = calloc(exponent + 1, sizeof(*powers0));
        double *powers1 = calloc(exponent + 1, sizeof(*powers1));
        if (powers0 == NULL || powers1 == NULL) {
            free(powers0);
            free(powers1);
            surfer_poly_destroy(&tmp);
            return false;
        }
        powers0[0] = 1.0;
        powers1[0] = 1.0;
        if (exponent >= 1) {
            powers0[1] = a0;
            powers1[1] = a1;
        }
        for (unsigned i = 2; i <= exponent; ++i) {
            powers0[i] = powers0[i - 1] * a0;
            powers1[i] = powers1[i - 1] * a1;
        }
        unsigned a1_exp = exponent;
        unsigned a0_exp = 0;
        unsigned long long binomial = 1;
        for (unsigned degree = exponent;; --degree) {
            tmp.coefficients[degree] =
                (double)binomial * powers1[a1_exp] * powers0[a0_exp];
            if (degree == 0) {
                break;
            }
            ++a0_exp;
            binomial = (binomial * a1_exp) / a0_exp;
            --a1_exp;
        }
        free(powers0);
        free(powers1);
        surfer_poly_destroy(out);
        *out = tmp;
        return true;
    }

    surfer_poly result = {0};
    surfer_poly power = {0};
    const double one = 1.0;
    if (!surfer_poly_from_coefficients(&result, &one, 1) || !surfer_poly_copy(&power, poly)) {
        surfer_poly_destroy(&result);
        surfer_poly_destroy(&power);
        return false;
    }

    unsigned remaining = exponent;
    while (remaining > 0) {
        if ((remaining & 1U) != 0U) {
            surfer_poly next = {0};
            if (!surfer_poly_mul(&next, &result, &power)) {
                surfer_poly_destroy(&result);
                surfer_poly_destroy(&power);
                return false;
            }
            surfer_poly_destroy(&result);
            result = next;
        }
        remaining >>= 1U;
        if (remaining != 0) {
            surfer_poly square = {0};
            if (!surfer_poly_mul(&square, &power, &power)) {
                surfer_poly_destroy(&result);
                surfer_poly_destroy(&power);
                return false;
            }
            surfer_poly_destroy(&power);
            power = square;
        }
    }

    surfer_poly_destroy(&power);
    surfer_poly_destroy(out);
    *out = result;
    return true;
}

double surfer_poly_evaluate(const surfer_poly *poly, double where)
{
    if (poly == NULL || poly->coefficients == NULL) {
        return NAN;
    }
    if (fabs(where) <= 1.0) {
        double result = poly->coefficients[poly->degree];
        for (size_t i = poly->degree; i-- > 0;) {
            result = result * where + poly->coefficients[i];
        }
        return result;
    }

    double result = poly->coefficients[0];
    for (size_t i = 1; i <= poly->degree; ++i) {
        result = result / where + poly->coefficients[i];
    }
    return result * pow(where, (double)poly->degree);
}

bool surfer_poly_derive(surfer_poly *out, const surfer_poly *poly)
{
    if (out == NULL || poly == NULL || poly->coefficients == NULL) {
        return false;
    }
    const size_t result_degree = poly->degree > 0 ? poly->degree - 1 : 0;
    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, result_degree)) {
        return false;
    }
    for (size_t i = 1; i <= poly->degree; ++i) {
        tmp.coefficients[i - 1] = (double)i * poly->coefficients[i];
    }
    compact_in_place(&tmp);
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

static bool shift_impl(surfer_poly *out, const surfer_poly *poly, double amount, bool reverse)
{
    if (out == NULL || poly == NULL || poly->coefficients == NULL) {
        return false;
    }
    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, poly->degree)) {
        return false;
    }
    if (reverse) {
        for (size_t i = 0; i <= poly->degree; ++i) {
            tmp.coefficients[i] = poly->coefficients[poly->degree - i];
        }
    } else {
        memcpy(tmp.coefficients, poly->coefficients, (poly->degree + 1) * sizeof(double));
    }
    const size_t length = poly->degree + 1;
    for (size_t i = 1; i <= length; ++i) {
        for (size_t j = length - 1; j > i - 1;) {
            --j;
            tmp.coefficients[j] += amount * tmp.coefficients[j + 1];
        }
    }
    compact_in_place(&tmp);
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

bool surfer_poly_shift(surfer_poly *out, const surfer_poly *poly, double amount)
{
    return shift_impl(out, poly, amount, false);
}

bool surfer_poly_reverse_shift(surfer_poly *out, const surfer_poly *poly, double amount)
{
    return shift_impl(out, poly, amount, true);
}

bool surfer_poly_stretch(surfer_poly *out, const surfer_poly *poly, double factor)
{
    if (out == NULL || poly == NULL || poly->coefficients == NULL) {
        return false;
    }
    surfer_poly tmp = {0};
    if (!allocate_poly(&tmp, poly->degree)) {
        return false;
    }
    double multiplier = 1.0;
    for (size_t i = 0; i <= poly->degree; ++i) {
        tmp.coefficients[i] = poly->coefficients[i] * multiplier;
        multiplier *= factor;
    }
    compact_in_place(&tmp);
    surfer_poly_destroy(out);
    *out = tmp;
    return true;
}

int surfer_poly_coefficient_sign_changes(const surfer_poly *poly)
{
    if (poly == NULL || poly->coefficients == NULL) {
        return 0;
    }
    int changes = 0;
    double last = poly->coefficients[poly->degree];
    for (size_t i = poly->degree; i-- > 0;) {
        const double current = poly->coefficients[i];
        if (current != 0.0) {
            if (current * last < 0.0) {
                ++changes;
            }
            last = current;
        }
    }
    return changes;
}

static int descartes_shift1_impl(const surfer_poly *poly, bool reverse)
{
    const size_t length = poly->degree + 1;
    double *horner = malloc(length * sizeof(*horner));
    if (horner == NUL