module surfer.roots;

import std.math : abs, ceil, exp2, isNaN, log2;

import surfer.polynomial : UnivariatePolynomial;

/**
 * Stussak's live CPU renderer selects the Descartes root finder. This is a
 * direct recasting of that search strategy: roots are normalized into (0,1),
 * isolated by Descartes' rule after the reverse/shift transform, and refined
 * by bisection when the isolating interval has a sign change.
 */
struct DescartesRootFinder {
    enum epsilon = 1.0e-7;

    private enum WhichRoot { smallest, largest }

    private struct Candidate {
        double[] coefficients;
        bool shift;
        double lower;
        double upper;
    }

    double find_first_root_in(UnivariatePolynomial polynomial,
                              double lower_bound,
                              double upper_bound) const
    {
        if (upper_bound < lower_bound)
            return double.nan;

        auto negative = polynomial.stretched(-1.0);
        const negative_root = -find_positive_root_in(
            negative,
            -upper_bound,
            -lower_bound,
            WhichRoot.largest
        );
        if (!isNaN(negative_root))
            return negative_root;

        return find_positive_root_in(
            polynomial,
            lower_bound,
            upper_bound,
            WhichRoot.smallest
        );
    }

    private double find_positive_root_in(UnivariatePolynomial polynomial,
                                         double lower_bound,
                                         double upper_bound,
                                         WhichRoot which) const
    {
        if (upper_bound <= 0.0 || polynomial.degree() == 0)
            return double.nan;

        auto p = polynomial;
        const bound = next_power_of_two(upper_bound);
        if (!(bound > 0.0))
            return double.nan;

        const strict_lower = lower_bound / bound;
        const strict_upper = upper_bound / bound;
        p = p.stretched(bound);

        double remembered = double.nan;
        auto coefficients = p.coefficients.dup;
        if (coefficients.length != 0 && coefficients[0] == 0.0) {
            if (lower_bound <= 0.0) {
                if (which == WhichRoot.smallest)
                    return 0.0;
                remembered = 0.0;
            }
            coefficients = deflate_zero(coefficients);
        }

        if (lower_bound <= 0.0)
            lower_bound = 0.0;

        Candidate[] candidates;
        candidates ~= Candidate(coefficients, false, 0.0, 1.0);

        while (candidates.length != 0) {
            auto interval = candidates[$ - 1];
            candidates.length = candidates.length - 1;

            auto a = interval.coefficients;
            if (interval.shift)
                a = shift_one(a);
            if (a.length == 0)
                continue;

            if (a[0] == 0.0) {
                const root = interval.lower * bound;
                if (lower_bound <= root && root <= upper_bound) {
                    if (which == WhichRoot.smallest)
                        return root;
                    remembered = root;
                    a = deflate_zero(a);
                }
            }
            if (a.length == 0)
                continue;

            const variations = descartes_rule_of_sign_reverse_shift_one(a);
            if (variations == 1) {
                const normalized_root = adjust_interval_and_bisect(
                    p,
                    interval.lower,
                    interval.upper,
                    strict_lower,
                    strict_upper
                );
                if (!isNaN(normalized_root)) {
                    const root = normalized_root * bound;
                    if (which == WhichRoot.largest
                        && !isNaN(remembered)
                        && remembered > root)
                        return remembered;
                    return root;
                }
            } else if (variations > 1) {
                const center = 0.5 * (interval.lower + interval.upper);
                if (abs(interval.upper - interval.lower) < 0.5 * epsilon) {
                    return interval.lower <= strict_lower
                        ? lower_bound
                        : interval.lower * bound;
                }

                const stretched = stretch_normalize_half(a);
                if (which == WhichRoot.smallest) {
                    // Stack is LIFO: push the right half first so the left half
                    // is searched first, exactly as in the Java implementation.
                    if (center <= strict_upper)
                        candidates ~= Candidate(stretched, true, center, interval.upper);
                    if (center >= strict_lower)
                        candidates ~= Candidate(stretched, false, interval.lower, center);
                } else {
                    if (center >= strict_lower)
                        candidates ~= Candidate(stretched, false, interval.lower, center);
                    if (center <= strict_upper)
                        candidates ~= Candidate(stretched, true, center, interval.upper);
                }
            }
        }

        return remembered;
    }

    private static double adjust_interval_and_bisect(
        UnivariatePolynomial polynomial,
        double lower_bound,
        double upper_bound,
        double strict_lower,
        double strict_upper)
    {
        double f_lower = polynomial.evaluate(lower_bound);
        if (lower_bound < strict_lower) {
            if (upper_bound < strict_lower)
                return double.nan;
            const f_strict = polynomial.evaluate(strict_lower);
            if (f_lower * f_strict < 0.0 || f_lower == 0.0)
                return double.nan;
            lower_bound = strict_lower;
            f_lower = f_strict;
        }

        double f_upper = polynomial.evaluate(upper_bound);
        if (strict_upper < upper_bound) {
            if (strict_upper < lower_bound)
                return double.nan;
            const f_strict = polynomial.evaluate(strict_upper);
            if (f_upper * f_strict < 0.0 || f_upper == 0.0)
                return double.nan;
            upper_bound = strict_upper;
            f_upper = f_strict;
        }

        if (f_lower == 0.0)
            return lower_bound;
        if (f_upper == 0.0)
            return upper_bound;
        if (f_lower * f_upper > 0.0)
            return double.nan;
        return bisect(polynomial, lower_bound, upper_bound, f_lower, f_upper);
    }

    private static double bisect(UnivariatePolynomial polynomial,
                                 double lower_bound,
                                 double upper_bound,
                                 double f_lower,
                                 double f_upper)
    {
        while (abs(upper_bound - lower_bound) > epsilon) {
            const center = 0.5 * (lower_bound + upper_bound);
            const f_center = polynomial.evaluate(center);
            if (f_center == 0.0)
                return center;
            if (f_center * f_lower < 0.0) {
                upper_bound = center;
                f_upper = f_center;
            } else {
                lower_bound = center;
                f_lower = f_center;
            }
        }
        return lower_bound;
    }

    private static double[] stretch_normalize_half(const(double)[] a) {
        if (a.length == 0)
            return [];
        auto result = new double[a.length];
        result[$ - 1] = a[$ - 1];
        double multiplier = 2.0;
        for (size_t i = result.length - 1; i > 0; --i) {
            result[i - 1] = a[i - 1] * multiplier;
            multiplier *= 2.0;
        }
        return result;
    }

    private static double[] shift_one(const(double)[] a) {
        auto result = a.dup;
        foreach (i; 1 .. result.length + 1) {
            for (size_t j = result.length - 1; j >= i; --j) {
                result[j - 1] += result[j];
                if (j == i)
                    break;
            }
        }
        return result;
    }

    private static double[] deflate_zero(const(double)[] a) {
        return a.length <= 1 ? [] : a[1 .. $].dup;
    }

    private static int descartes_rule_of_sign_reverse_shift_one(const(double)[] a) {
        if (a.length == 0)
            return 0;

        auto horner = new double[a.length];
        foreach (i; 0 .. a.length)
            horner[i] = a[$ - i - 1];

        int sign_changes;
        double last_nonzero = double.nan;
        foreach (i; 1 .. a.length + 1) {
            for (size_t j = horner.length - 1; j >= i; --j) {
                horner[j - 1] += horner[j];
                if (j == i)
                    break;
            }
            const coefficient = horner[i - 1];
            if (coefficient != 0.0) {
                if (!isNaN(last_nonzero) && coefficient * last_nonzero < 0.0)
                    ++sign_changes;
                if (sign_changes > 1)
                    return sign_changes;
                last_nonzero = coefficient;
            }
        }
        if (horner[0] == 0.0)
            ++sign_changes;
        return sign_changes;
    }

    private static double next_power_of_two(double value) {
        if (!(value > 0.0))
            return 0.0;
        return exp2(ceil(log2(value)));
    }
}

unittest {
    auto finder = DescartesRootFinder();
    auto p = UnivariatePolynomial([-1.0, 0.0, 1.0]);
    const first = finder.find_first_root_in(p, -2.0, 2.0);
    assert(abs(first + 1.0) < 2.0e-6);

    auto q = UnivariatePolynomial([-0.64, 0.0, 1.0]);
    const sphere_hit = finder.find_first_root_in(q, 0.0, 2.0);
    assert(abs(sphere_hit - 0.8) < 2.0e-6);
}
