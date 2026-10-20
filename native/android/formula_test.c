/* Native editable formula oracle: sparse terms, derivatives and rejection.
 * Independent of Android controls; runs with ASan/UBSan before device builds.
 */
#include "formula.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static ave_formula formula;
static char diagnostic[128];
static void need(int yes, const char *message)
{
    if (!yes) {
        fprintf(stderr, "FAIL %s: %s\n", message, diagnostic);
        exit(1);
    }
}
static double coefficient(int x, int y, int z)
{
    double value = 0.0;
    for (size_t i = 0; i < formula.surface.surface.term_count; ++i) {
        const surfer_term t = formula.terms[i];
        if (t.x_exponent == x && t.y_exponent == y && t.z_exponent == z)
            value += t.coefficient;
    }
    return value;
}
static double evaluate(double x, double y, double z, int derivative)
{
    const surfer_sparse_polynomial polynomial =
        derivative == 0 ? formula.surface.surface :
        derivative == 1 ? formula.surface.gradient_x :
        derivative == 2 ? formula.surface.gradient_y :
                          formula.surface.gradient_z;
    double value = 0;
    for (size_t i = 0; i < polynomial.term_count; ++i) {
        const surfer_term t = polynomial.terms[i];
        value += t.coefficient *
            pow(x, t.x_exponent) * pow(y, t.y_exponent) *
            pow(z, t.z_exponent);
    }
    return value;
}
static void near(double a, double b, const char *message)
{
    need(isfinite(a) && fabs(a-b) <= 1e-9, message);
}
int main(void)
{
    need(ave_formula_compile("x^4-x*y^3-z^4+z=0",
        &formula, diagnostic, sizeof diagnostic), "user quartic parsed");
    near(coefficient(4,0,0), 1, "x^4 coefficient");
    near(coefficient(1,3,0), -1, "xy^3 coefficient");
    near(coefficient(0,0,4), -1, "z^4 coefficient");
    near(coefficient(0,0,1), 1, "z coefficient");
    near(evaluate(2,3,4,0), 16-54-256+4, "quartic value");
    near(evaluate(2,3,4,1), 32-27, "quartic dx");
    near(evaluate(2,3,4,2), -54, "quartic dy");
    near(evaluate(2,3,4,3), -256+1, "quartic dz");

    need(ave_formula_compile("x²+y³−z",
        &formula, diagnostic, sizeof diagnostic), "Unicode glyphs");
    near(coefficient(2,0,0), 1, "superscript 2");
    near(coefficient(0,3,0), 1, "superscript 3");
    near(coefficient(0,0,1), -1, "Unicode minus");
    need(ave_formula_compile("x^2^3",
        &formula, diagnostic, sizeof diagnostic), "associativity");
    near(coefficient(8,0,0), 1, "right-associative x^8");
    need(ave_formula_compile("x^0+y",
        &formula, diagnostic, sizeof diagnostic), "zero exponent");
    near(coefficient(0,0,0), 1, "x^0 is one");
    need(ave_formula_compile("-x^2+(-x)^2",
        &formula, diagnostic, sizeof diagnostic) == false,
        "zero polynomial rejected");
    need(ave_formula_compile("(x^2+y^2+z^2+0.4)^2-1.1*(x^2+y^2)",
        &formula, diagnostic, sizeof diagnostic), "torus formula");
    near(evaluate(1,0,0,0), 1.96-1.1, "torus value");
    near(coefficient(0,0,4), 1, "torus z^4");
    const surfer_term saved = formula.terms[0];
    const surfer_term *saved_pointer = formula.surface.surface.terms;
    const char *invalid[] = {
        "x/(y+1)", "x^-1", "x^9", "x+y garbage", "x+y=",
        "x/(2-2)", "1e300*x", "x^1.2", "(x+y",
        "x*y^6*z^3", "", "sin(x)", "x*x*x*x*x*x*x*x*x",
    };
    for (size_t i = 0; i < sizeof invalid / sizeof invalid[0]; ++i) {
        need(!ave_formula_compile(invalid[i], &formula,
             diagnostic, sizeof diagnostic), invalid[i]);
        need(formula.surface.surface.terms == saved_pointer &&
             memcmp(formula.terms, &saved, sizeof saved) == 0,
             "invalid input preserves previous surface");
    }
    need(ave_formula_compile("(x+1)*(x-1)/2",
        &formula, diagnostic, sizeof diagnostic), "constant division");
    near(coefficient(2,0,0), 0.5, "division coefficient");
    near(coefficient(0,0,0), -0.5, "division constant");
    need(ave_formula_compile("x=y",
        &formula, diagnostic, sizeof diagnostic), "equation both sides");
    near(coefficient(1,0,0), 1, "equation lhs");
    near(coefficient(0,1,0), -1, "equation rhs");
    puts("Native arbitrary formula parser, derivatives, and failure invariants: PASS");
    return 0;
}
