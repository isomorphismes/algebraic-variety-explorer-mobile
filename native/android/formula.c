/* Bounded C bridge for editable native SURFER formulas.
 * Typed Idriç grammar/lowering remains an independent unfinished milestone.
 * SURFER/jsurf's original renderer: Christian Stussak, Apache-2.0.
 */
#include "formula.h"
#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    surfer_term terms[AVE_FORMULA_MAX_TERMS];
    size_t count;
} poly;
typedef struct {
    const char *at;
    unsigned depth;
    char error[96];
} parser;

static bool reject(parser *p, const char *message)
{
    if (p->error[0] == '\0') snprintf(p->error, sizeof p->error, "%s", message);
    return false;
}
static void spaces(parser *p)
{
    while (*p->at == ' ' || *p->at == '\n' || *p->at == '\t') ++p->at;
}
static bool take(parser *p, const char *token)
{
    spaces(p);
    const size_t n = strlen(token);
    if (strncmp(p->at, token, n) != 0) return false;
    p->at += n;
    return true;
}
static bool add_term(parser *p, poly *out, surfer_term t)
{
    const int32_t d = t.x_exponent + t.y_exponent + t.z_exponent;
    if (d > AVE_FORMULA_MAX_DEGREE || d < 0 ||
        !isfinite(t.coefficient) || fabs(t.coefficient) > 1e100)
        return reject(p, "degree or coefficient exceeds native bound");
    if (t.coefficient == 0.0) return true;
    for (size_t i = 0; i < out->count; ++i) {
        surfer_term *old = &out->terms[i];
        if (old->x_exponent == t.x_exponent &&
            old->y_exponent == t.y_exponent &&
            old->z_exponent == t.z_exponent) {
            const double sum = old->coefficient + t.coefficient;
            if (!isfinite(sum) || fabs(sum) > 1e100)
                return reject(p, "coefficient overflow");
            if (sum == 0.0) {
                out->terms[i] = out->terms[--out->count];
            } else old->coefficient = sum;
            return true;
        }
    }
    if (out->count == AVE_FORMULA_MAX_TERMS)
        return reject(p, "too many monomials");
    out->terms[out->count++] = t;
    return true;
}
static bool constant(parser *p, poly *out, double coefficient)
{
    memset(out, 0, sizeof *out);
    surfer_term t = {coefficient, 0, 0, 0};
    return add_term(p, out, t);
}
static bool add_scaled(parser *p, poly *out, const poly *right, double factor)
{
    for (size_t i = 0; i < right->count; ++i) {
        surfer_term t = right->terms[i];
        t.coefficient *= factor;
        if (!add_term(p, out, t)) return false;
    }
    return true;
}
static bool multiply(parser *p, poly *result, const poly *left, const poly *right)
{
    poly tmp = {0};
    for (size_t i = 0; i < left->count; ++i) {
        for (size_t j = 0; j < right->count; ++j) {
            const surfer_term a = left->terms[i], b = right->terms[j];
            surfer_term t = {a.coefficient * b.coefficient,
                             a.x_exponent + b.x_exponent,
                             a.y_exponent + b.y_exponent,
                             a.z_exponent + b.z_exponent};
            if (!add_term(p, &tmp, t)) return false;
        }
    }
    *result = tmp;
    return true;
}
static bool exponentiate(parser *p, poly *out, const poly *base, unsigned n)
{
    poly total = {0}, power = *base;
    if (!constant(p, &total, 1.0)) return false;
    while (n != 0) {
        if (n & 1U) {
            poly next;
            if (!multiply(p, &next, &total, &power)) return false;
            total = next;
        }
        n >>= 1U;
        if (n != 0) {
            poly next;
            if (!multiply(p, &next, &power, &power)) return false;
            power = next;
        }
    }
    *out = total;
    return true;
}
static bool parse_sum(parser *, poly *);
static bool parse_unary(parser *, poly *);

static bool parse_atom(parser *p, poly *out)
{
    spaces(p);
    if (take(p, "(")) {
        if (++p->depth > 24) return reject(p, "parentheses too deep");
        bool ok = parse_sum(p, out);
        --p->depth;
        return ok && (take(p, ")") || reject(p, "expected ')'"));
    }
    const char ch = *p->at;
    if (ch == 'x' || ch == 'y' || ch == 'z') {
        ++p->at;
        memset(out, 0, sizeof *out);
        surfer_term t = {1, ch == 'x', ch == 'y', ch == 'z'};
        return add_term(p, out, t);
    }
    if (isdigit((unsigned char)ch) || ch == '.') {
        char *end;
        errno = 0;
        const double value = strtod(p->at, &end);
        if (end == p->at || errno == ERANGE || !isfinite(value))
            return reject(p, "invalid finite number");
        p->at = end;
        return constant(p, out, value);
    }
    return reject(p, "expected a number, x/y/z, or '('");
}
static bool parse_power(parser *p, poly *out)
{
    if (!parse_atom(p, out)) return false;
    unsigned n;
    if (take(p, "²")) n = 2;
    else if (take(p, "³")) n = 3;
    else if (take(p, "^")) {
        poly exponent = {0};
        if (!parse_unary(p, &exponent)) return false;
        if (exponent.count > 1 ||
            (exponent.count == 1 &&
             (exponent.terms[0].x_exponent != 0 ||
              exponent.terms[0].y_exponent != 0 ||
              exponent.terms[0].z_exponent != 0)))
            return reject(p, "power requires a constant integer");
        const double value = exponent.count == 0 ? 0.0 : exponent.terms[0].coefficient;
        if (value < 0 || value > AVE_FORMULA_MAX_DEGREE || floor(value) != value)
            return reject(p, "power must be an integer from 0 to 8");
        n = (unsigned)value;
    } else return true;
    poly base = *out;
    return exponentiate(p, out, &base, n);
}
static bool parse_unary(parser *p, poly *out)
{
    if (take(p, "+")) return parse_unary(p, out);
    if (take(p, "-") || take(p, "−")) {
        if (!parse_unary(p, out)) return false;
        for (size_t i = 0; i < out->count; ++i)
            out->terms[i].coefficient = -out->terms[i].coefficient;
        return true;
    }
    return parse_power(p, out);
}
static bool parse_product(parser *p, poly *out)
{
    if (!parse_unary(p, out)) return false;
    for (;;) {
        bool div = false;
        if (take(p, "*") || take(p, "×")) {}
        else if (take(p, "/") || take(p, "÷")) div = true;
        else break;
        poly right = {0};
        if (!parse_unary(p, &right)) return false;
        if (div) {
            if (right.count != 1 || right.terms[0].x_exponent != 0 ||
                right.terms[0].y_exponent != 0 || right.terms[0].z_exponent != 0 ||
                right.terms[0].coefficient == 0.0)
                return reject(p, "division needs a nonzero constant");
            const double inverse = 1.0 / right.terms[0].coefficient;
            poly scaled = {0};
            if (!add_scaled(p, &scaled, out, inverse)) return false;
            *out = scaled;
        } else {
            poly tmp;
            if (!multiply(p, &tmp, out, &right)) return false;
            *out = tmp;
        }
    }
    return true;
}
static bool parse_sum(parser *p, poly *out)
{
    if (!parse_product(p, out)) return false;
    for (;;) {
        double factor;
        if (take(p, "+")) factor = 1.0;
        else if (take(p, "-") || take(p, "−")) factor = -1.0;
        else break;
        poly right = {0};
        if (!parse_product(p, &right) ||
            !add_scaled(p, out, &right, factor)) return false;
    }
    return true;
}
bool ave_formula_compile(const char *source, ave_formula *result,
                         char *error, size_t error_capacity)
{
    if (error != NULL && error_capacity != 0) error[0] = '\0';
    if (source == NULL || result == NULL ||
        strlen(source) == 0 || strlen(source) > AVE_FORMULA_MAX_SOURCE) {
        if (error && error_capacity)
            snprintf(error, error_capacity, "formula length must be 1..128");
        return false;
    }
    parser p = {.at = source};
    poly polynomial = {0};
    bool ok = parse_sum(&p, &polynomial);
    if (ok && take(&p, "=")) {
        poly rhs = {0};
        ok = parse_sum(&p, &rhs) && add_scaled(&p, &polynomial, &rhs, -1.0);
    }
    spaces(&p);
    if (ok && *p.at != '\0') ok = reject(&p, "unexpected trailing token");
    if (ok && polynomial.count == 0)
        ok = reject(&p, "zero polynomial does not define a surface");
    if (!ok) {
        if (error && error_capacity)
            snprintf(error, error_capacity, "%s",
                     p.error[0] ? p.error : "invalid formula");
        return false;
    }
    /* Write only after a complete parse: failed inputs preserve last surface. */
    memset(result, 0, sizeof *result);
    result->surface.surface.terms = result->terms;
    result->surface.surface.term_count = polynomial.count;
    for (size_t i = 0; i < polynomial.count; ++i) {
        const surfer_term t = polynomial.terms[i];
        result->terms[i] = t;
        const int32_t degree = t.x_exponent + t.y_exponent + t.z_exponent;
        if (degree > result->surface.family_degree) result->surface.family_degree = degree;
        for (int axis = 0; axis < 3; ++axis) {
            surfer_term derivative = t;
            int32_t *exponent = axis == 0 ? &derivative.x_exponent :
                axis == 1 ? &derivative.y_exponent : &derivative.z_exponent;
            if (*exponent == 0) continue;
            derivative.coefficient *= (double)*exponent;
            --*exponent;
            surfer_sparse_polynomial *dp = axis == 0 ? &result->surface.gradient_x :
                axis == 1 ? &result->surface.gradient_y : &result->surface.gradient_z;
            result->derivatives[axis][dp->term_count++] = derivative;
        }
    }
    result->surface.gradient_x.terms = result->derivatives[0];
    result->surface.gradient_y.terms = result->derivatives[1];
    result->surface.gradient_z.terms = result->derivatives[2];
    return true;
}
