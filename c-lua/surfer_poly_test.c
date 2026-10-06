#include "surfer_poly.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

static void require_true(bool condition, const char *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message);
        exit(1);
    }
}

static void require_near(double actual, double expected, double tolerance, const char *message)
{
    if (fabs(actual - expected) > tolerance) {
        fprintf(stderr, "FAIL: %s actual=%.17g expected=%.17g\n", message, actual, expected);
        exit(1);
    }
}

static surfer_poly poly(const double *coefficients, size_t count)
{
    surfer_poly result = {0};
    require_true(surfer_poly_from_coefficients(&result, coefficients, count), "allocate polynomial");
    return result;
}

static void test_java_horner_split(void)
{
    const double coefficients[] = {1.0, -2.0, 3.0, -4.0};
    surfer_poly p = poly(coefficients, 4);
    require_near(surfer_poly_evaluate(&p, 0.25), 0.625, 1e-15, "Horner |x| <= 1");
    require_near(surfer_poly_evaluate(&p, 4.0), -215.0, 1e-12, "reversed Horner |x| > 1");
    surfer_poly_destroy(&p);
}

static void test_linear_power_uses_binomial_coefficients(void)
{
    const double coefficients[] = {2.0, 3.0};
    surfer_poly p = poly(coefficients, 2);
    surfer_poly p4 = {0};
    require_true(surfer_poly_pow(&p4, &p, 4), "linear power");
    const double expected[] = {16.0, 96.0, 216.0, 216.0, 81.0};
    require_true(p4.degree == 4, "linear power degree");
    for (size_t i = 0; i < 5; ++i) {
        require_near(p4.coefficients[i], expected[i], 1e-12, "linear power coefficient");
    }
    surfer_poly_destroy(&p4);
    surfer_poly_destroy(&p);
}

static void test_shift_and_reverse_shift(void)
{
    const double coefficients[] = {1.0, 2.0, 3.0};
    surfer_poly p = poly(coefficients, 3);
    surfer_poly shifted = {0};
    surfer_poly reversed = {0};
    require_true(surfer_poly_shift(&shifted, &p, 1.0), "shift");
    require_true(surfer_poly_reverse_shift(&reversed, &p, 1.0), "reverse shift");
    /* p(x+1) = 6 + 8x + 3x^2 */
    require_near(shifted.coefficients[0], 6.0, 1e-15, "shift a0");
    require_near(shifted.coefficients[1], 8.0, 1e-15, "shift a1");
    require_near(shifted.coefficients[2], 3.0, 1e-15, "shift a2");
    /* x^2 p(1/(x+1)) transformed by the Java reverse-shift routine. */
    require_near(reversed.coefficients[0], 6.0, 1e-15, "reverse shift a0");
    require_near(reversed.coefficients[1], 4.0, 1e-15, "reverse shift a1");
    require_near(reversed.coefficients[2], 1.0, 1e-15, "reverse shift a2");
    surfer_poly_destroy(&reversed);
    surfer_poly_destroy(&shifted);
    surfer_poly_destroy(&p);
}

static void test_closed_form_roots(void)
{
    const double quadratic_coefficients[] = {-1.0, 0.0, 1.0};
    surfer_poly q = poly(quadratic_coefficients, 3);
    surfer_roots4 roots = {0};
    require_true(surfer_closed_form_roots(&q, &roots), "quadratic roots");
    require_true(roots.count == 2, "quadratic root count");
    require_near(roots.values[0], -1.0, 1e-15, "quadratic first");
    require_near(roots.values[1], 1.0, 1e-15, "quadratic second");
    surfer_poly_destroy(&q);

    const double cubic_coefficients[] = {-6.0, 11.0, -6.0, 1.0};
    surfer_poly c = poly(cubic_coefficients, 4);
    require_true(surfer_closed_form_roots(&c, &roots), "cubic roots");
    require_true(roots.count == 3, "cubic root count");
    require_near(roots.values[0], 1.0, 1e-12, "cubic first");
    require_near(roots.values[1], 2.0, 1e-12, "cubic second");
    require_near(roots.values[2], 3.0, 1e-12, "cubic third");
    surfer_poly_destroy(&c);

    const double quartic_coefficients[] = {4.0, 0.0, -5.0, 0.0, 1.0};
    surfer_poly r = poly(quartic_coefficients, 5);
    require_true(surfer_closed_form_roots(&r, &roots), "quartic roots");
    require_true(roots.count == 4, "quartic root count");
    require_near(roots.values[0], -2.0, 2e-8, "quartic root -2");
    require_near(roots.values[1], -1.0, 2e-8, "quartic root -1");
    require_near(roots.values[2], 1.0, 2e-8, "quartic root 1");
    require_near(roots.values[3], 2.0, 2e-8, "quartic root 2");
    surfer_poly_destroy(&r);
}

static void test_repeated_roots_are_repeated(void)
{
    const double coefficients[] = {1.0, -2.0, 1.0};
    surfer_poly p = poly(coefficients, 3);
    surfer_roots4 roots = {0};
    require_true(surfer_closed_form_roots(&p, &roots), "repeated quadratic");
    require_true(roots.count == 2, "double root is reported twice");
    require_near(roots.values[0], 1.0, 1e-15, "double root 1");
    require_near(roots.values[1], 1.0, 1e-15, "double root 2");
    surfer_poly_destroy(&p);
}

int main(void)
{
    test_java_horner_split();
    test_linear_power_uses_binomial_coefficients();
    test_shift_and_reverse_shift();
    test_closed_form_roots();
    test_repeated_roots_are_repeated();
    puts("SURFER Java->C polynomial/root slice: PASS");
    return 0;
}
