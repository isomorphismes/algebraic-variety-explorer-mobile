/*
 *    Copyright 2008 Christian Stussak
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module de.mfo.jsurf.algebra.univariate_polynomial;

import std.algorithm.comparison : max;
import std.conv : to;
import std.math : abs, math_pow = pow;

class UnivariatePolynomial {
    private static UnivariatePolynomial zero_instance;
    private static UnivariatePolynomial one_instance;

    static @property UnivariatePolynomial ZERO() {
        if (zero_instance is null)
            zero_instance = new UnivariatePolynomial(0.0);
        return zero_instance;
    }

    static @property UnivariatePolynomial ONE() {
        if (one_instance is null)
            one_instance = new UnivariatePolynomial(1.0);
        return one_instance;
    }

    private double[] a;
    private int polynomial_degree;

    private this() {}

    this(int degree) {
        this.a = new double[cast(size_t) degree + 1];
        this.polynomial_degree = degree;
    }

    this(double[] coeffs...) {
        // Java's varargs array survives the constructor. D's variadic slice
        // may be temporary, so retain equivalent object lifetime explicitly.
        setCoeffs(coeffs, true);
    }

    this(double[] coeffs, bool copy) {
        if (copy)
            this.a = coeffs.dup;
        else
            this.a = coeffs;
        this.polynomial_degree = cast(int) coeffs.length - 1;
    }

    this(UnivariatePolynomial p) {
        setCoeffs(p.a, true);
    }

    private this(int degree, double[] coeffs) {
        this.a = new double[cast(size_t) degree + 1];
        this.a[] = coeffs[0 .. this.a.length];
        this.polynomial_degree = degree;
    }

    bool isZero() {
        foreach (c; a)
            if (c != 0.0)
                return false;
        return true;
    }

    bool isOne() {
        if (a[0] != 1.0)
            return false;
        for (int i = cast(int) a.length - 1; i > 0; --i)
            if (a[i] != 0.0)
                return false;
        return true;
    }

    private void setCoeff(int which, double value) {
        this.a[which] = value;
    }

    private void setCoeffs(double[] coeffs, bool copy) {
        if (copy)
            this.a = coeffs.dup;
        else
            this.a = coeffs;
        this.polynomial_degree = cast(int) coeffs.length - 1;
    }

    double getCoeff(int which) {
        return this.a[which];
    }

    double[] getCoeffs() {
        return a.dup;
    }

    int degree() {
        return this.polynomial_degree;
    }

    UnivariatePolynomial neg() {
        auto result = new UnivariatePolynomial(this.polynomial_degree);
        foreach (i; 0 .. this.a.length)
            result.a[i] = -this.a[i];
        return result;
    }

    UnivariatePolynomial add(UnivariatePolynomial p) {
        UnivariatePolynomial result;
        UnivariatePolynomial summand;
        if (this.polynomial_degree > p.polynomial_degree) {
            result = new UnivariatePolynomial(this);
            summand = p;
        } else {
            result = new UnivariatePolynomial(p);
            summand = this;
        }
        foreach (i; 0 .. summand.a.length)
            result.a[i] += summand.a[i];
        return result.compact();
    }

    UnivariatePolynomial add(double d) {
        if (d == 0.0)
            return this;
        auto result = new UnivariatePolynomial(this);
        result.a[0] += d;
        return result.compact();
    }

    UnivariatePolynomial sub(UnivariatePolynomial p) {
        return this.add(p.neg()).compact();
    }

    UnivariatePolynomial sub(double d) {
        if (d == 0.0)
            return this;
        return this.add(-d);
    }

    package UnivariatePolynomial mult(UnivariatePolynomial p, int min_degree) {
        if (p.polynomial_degree == 1) {
            auto result = new UnivariatePolynomial(
                max(this.polynomial_degree + p.polynomial_degree, min_degree + 1));
            result.a[0] = this.a[0] * p.a[0];
            for (int i = 1; i < cast(int) result.a.length - 1; ++i)
                result.a[i] = this.a[i] * p.a[0] + this.a[i - 1] * p.a[1];
            result.a[$ - 1] = this.a[this.polynomial_degree] * p.a[1];
            return result.compact();
        } else if (this.polynomial_degree == 1) {
            return p.mult(this, min_degree);
        } else {
            auto result = new UnivariatePolynomial(
                max(this.polynomial_degree + p.polynomial_degree, min_degree + 1));
            foreach (i; 0 .. this.a.length)
                foreach (j; 0 .. p.a.length)
                    result.a[i + j] += this.a[i] * p.a[j];
            return result.compact();
        }
    }

    UnivariatePolynomial mult(UnivariatePolynomial p) {
        if (p.isOne() || this.isZero())
            return this;
        if (p.isZero() || this.isOne())
            return p;
        return this.mult(p, 0);
    }

    UnivariatePolynomial mult(double d) {
        if (d == 0.0)
            return ZERO;
        if (d == 1.0)
            return this;

        auto result = new UnivariatePolynomial(this.polynomial_degree);
        foreach (i; 0 .. this.a.length)
            result.a[i] = this.a[i] * d;
        return result.compact();
    }

    UnivariatePolynomial mult_add(UnivariatePolynomial factor, double summand) {
        auto result = this.mult(factor);
        result.a[0] += summand;
        return result;
    }

    UnivariatePolynomial mult_add(
        UnivariatePolynomial factor,
        UnivariatePolynomial summand)
    {
        if (factor.isOne() || this.isZero())
            return this.add(summand);
        if (factor.isZero() || this.isOne())
            return factor.add(summand);

        auto result = this.mult(factor, summand.polynomial_degree);
        for (int i = 0; i <= summand.polynomial_degree; ++i)
            result.a[i] += summand.a[i];
        return result;
    }

    UnivariatePolynomial add_mult(double summand, UnivariatePolynomial factor) {
        if (factor.isOne())
            return this.add(summand);
        if (factor.isZero())
            return ZERO;

        auto result = new UnivariatePolynomial(
            this.polynomial_degree + factor.polynomial_degree);
        const tmp = this.a[0] + summand;
        foreach (j; 0 .. factor.a.length)
            result.a[j] += tmp * factor.a[j];
        foreach (i; 1 .. this.a.length)
            foreach (j; 0 .. factor.a.length)
                result.a[i + j] += this.a[i] * factor.a[j];
        return result.compact();
    }

    UnivariatePolynomial pow(int exp) {
        if (exp == 0)
            return ONE;
        if (exp == 1)
            return this;

        if (this.polynomial_degree == 1) {
            const a0 = a[0];
            const a1 = a[1];
            auto powers_0 = new double[cast(size_t) exp + 1];
            auto powers_1 = new double[cast(size_t) exp + 1];
            powers_0[0] = 1.0;
            powers_0[1] = a0;
            powers_1[0] = 1.0;
            powers_1[1] = a1;
            for (int i = 2; i <= exp; ++i) {
                powers_0[i] = powers_0[i - 1] * a0;
                powers_1[i] = powers_1[i - 1] * a1;
            }

            auto res = new UnivariatePolynomial(exp);
            int a1_exp = exp;
            int a0_exp = 0;
            long bin_coeff = 1;
            for (int deg = exp; deg >= 0; --deg) {
                res.a[deg] = cast(double) bin_coeff
                    * powers_1[a1_exp]
                    * powers_0[a0_exp];
                ++a0_exp;
                bin_coeff = (bin_coeff * a1_exp) / a0_exp;
                --a1_exp;
            }
            return new UnivariatePolynomial(res);
        }

        auto result = this;
        auto x = this;
        --exp;
        while (exp > 0) {
            if ((exp & 1) == 1) {
                result = result.mult(x);
                --exp;
            }
            x = x.mult(x);
            exp /= 2;
        }
        return result.compact();
    }

    UnivariatePolynomial pow(int exp, UnivariatePolynomial[] cache) {
        if (cache[exp] is null) {
            if (exp == 0) {
                cache[exp] = ONE;
            } else if (exp == 1) {
                cache[exp] = this;
            } else {
                auto sqrt_poly = pow(exp / 2, cache);
                cache[exp] = sqrt_poly.mult(sqrt_poly);
                if ((exp & 1) == 1)
                    cache[exp] = cache[exp].mult(this);
            }
        }
        return cache[exp];
    }

    UnivariatePolynomial substitute(UnivariatePolynomial xPoly) {
        auto result = new UnivariatePolynomial(a[$ - 1]);
        for (int i = cast(int) a.length - 2; i >= 0; --i)
            result = result.mult(xPoly).add(a[i]);
        return result;
    }

    UnivariatePolynomial div(double d) {
        auto result = new UnivariatePolynomial(this);
        foreach (i; 0 .. result.a.length)
            result.a[i] = result.a[i] / d;
        return result.compact();
    }

    private double[] reduceCoefficients(
        double[] aa,
        int degA,
        double[] b,
        int degB)
    {
        const degDiff = degA - degB;

        auto result = new double[cast(size_t) degA];
        for (int i = degA - 1; i >= degDiff; --i)
            result[i] = aa[i] - b[i - degDiff] / b[degB] * aa[degA];

        for (int i = 0; i < degDiff; ++i)
            result[i] = aa[i];

        return result;
    }

    private double[] modCoefficients(
        double[] aa,
        int degA,
        double[] b,
        int degB)
    {
        if (degB < 1) {
            if (degB == -1)
                throw new Exception("Cannot divide by constant polynomials");
            return [0.0];
        }

        if (degA < degB)
            return aa;

        auto result = reduceCoefficients(aa, degA, b, degB);

        int newDeg = degA - 1;
        while (newDeg >= 0 && result[newDeg] == 0.0)
            --newDeg;

        return modCoefficients(result, newDeg, b, degB);
    }

    UnivariatePolynomial mod(UnivariatePolynomial other) {
        return new UnivariatePolynomial(
            modCoefficients(this.a, degree(), other.a, other.degree()),
            false
        ).compact();
    }

    UnivariatePolynomial div(UnivariatePolynomial other) {
        return new UnivariatePolynomial(
            reduceCoefficients(this.a, degree(), other.a, other.degree()),
            false
        ).compact();
    }

    double evaluateAt(double where) {
        if (abs(where) <= 1.0) {
            double result = this.a[$ - 1];
            for (int i = cast(int) this.a.length - 2; i >= 0; --i)
                result = result * where + this.a[i];
            return result;
        }

        double result = this.a[0];
        foreach (i; 1 .. this.a.length)
            result = result / where + this.a[i];
        return result * math_pow(where, cast(double) this.a.length - 1.0);
    }

    UnivariatePolynomial shrink() {
        while (this.a[this.polynomial_degree] == 0.0
            && this.polynomial_degree > 0)
            --this.polynomial_degree;

        auto result = new UnivariatePolynomial();
        result.a = new double[cast(size_t) this.polynomial_degree + 1];
        result.polynomial_degree = cast(int) result.a.length - 1;
        result.a[] = a[0 .. result.a.length];
        return result;
    }

    UnivariatePolynomial derive() {
        auto result = new UnivariatePolynomial(max(0, this.polynomial_degree - 1));
        foreach (i; 1 .. this.a.length)
            result.a[i - 1] = cast(double) i * this.a[i];
        return result;
    }

    UnivariatePolynomial shift2(double value) {
        auto shiftedDerValues = evaluateDerivativesAt(value);
        auto result = new double[this.a.length];
        double fac = 1.0;
        result[0] = shiftedDerValues[0];
        foreach (i; 1 .. shiftedDerValues.length) {
            fac *= cast(double) i;
            result[i] = shiftedDerValues[i] / fac;
        }
        return new UnivariatePolynomial(result);
    }

    UnivariatePolynomial shift(double value) {
        return shifted(value, false);
    }

    UnivariatePolynomial reverseShift(double value) {
        return shifted(value, true);
    }

    private UnivariatePolynomial shifted(double value, bool revert) {
        auto hornerCoeffs = new double[this.a.length];

        if (revert) {
            foreach (i; 0 .. this.a.length)
                hornerCoeffs[i] = this.a[$ - i - 1];
        } else {
            hornerCoeffs[] = this.a[];
        }

        for (int i = 1; i <= cast(int) this.a.length; ++i)
            for (int j = cast(int) hornerCoeffs.length - 2; j >= i - 1; --j)
                hornerCoeffs[j] = hornerCoeffs[j] + value * hornerCoeffs[j + 1];

        return new UnivariatePolynomial(hornerCoeffs, false);
    }

    UnivariatePolynomial shift1() {
        auto hornerCoeffs = this.a.dup;

        for (int i = 1; i <= cast(int) this.a.length; ++i)
            for (int j = cast(int) hornerCoeffs.length - 2; j >= i - 1; --j)
                hornerCoeffs[j] = hornerCoeffs[j] + hornerCoeffs[j + 1];

        return new UnivariatePolynomial(hornerCoeffs, false);
    }

    UnivariatePolynomial reverseShift1() {
        auto hornerCoeffs = new double[this.a.length];
        foreach (i; 0 .. this.a.length)
            hornerCoeffs[i] = this.a[$ - i - 1];

        for (int i = 1; i <= cast(int) this.a.length; ++i)
            for (int j = cast(int) hornerCoeffs.length - 2; j >= i - 1; --j)
                hornerCoeffs[j] = hornerCoeffs[j] + hornerCoeffs[j + 1];

        return new UnivariatePolynomial(hornerCoeffs, false);
    }

    int descartesRuleOfSignShift1() {
        int signChanges = 0;
        auto hornerCoeffs = this.a.dup;

        double lastNonZeroCoeff = double.nan;
        for (int i = 1; i <= cast(int) this.a.length; ++i) {
            for (int j = cast(int) hornerCoeffs.length - 2; j >= i - 1; --j)
                hornerCoeffs[j] = hornerCoeffs[j] + hornerCoeffs[j + 1];

            if (hornerCoeffs[i - 1] != 0.0) {
                if (hornerCoeffs[i - 1] * lastNonZeroCoeff < 0.0)
                    ++signChanges;
                if (signChanges > 1)
                    return signChanges;
                lastNonZeroCoeff = hornerCoeffs[i - 1];
            }
        }

        return signChanges;
    }

    int descartesRuleOfSignReverseShift1() {
        int signChanges = 0;
        auto hornerCoeffs = new double[this.a.length];
        foreach (i; 0 .. this.a.length)
            hornerCoeffs[i] = this.a[$ - i - 1];

        double lastNonZeroCoeff = double.nan;
        for (int i = 1; i <= cast(int) this.a.length; ++i) {
            for (int j = cast(int) hornerCoeffs.length - 2; j >= i - 1; --j)
                hornerCoeffs[j] = hornerCoeffs[j] + hornerCoeffs[j + 1];

            if (hornerCoeffs[i - 1] != 0.0) {
                if (hornerCoeffs[i - 1] * lastNonZeroCoeff < 0.0)
                    ++signChanges;
                if (signChanges > 1)
                    return signChanges;
                lastNonZeroCoeff = hornerCoeffs[i - 1];
            }
        }

        return signChanges;
    }

    UnivariatePolynomial revert() {
        auto result = new UnivariatePolynomial(this.degree());
        foreach (i; 0 .. this.a.length)
            result.a[i] = this.a[$ - i - 1];
        return result;
    }

    UnivariatePolynomial stretch(double value) {
        auto resultCoeffs = new double[this.a.length];
        double multiplier = 1.0;
        foreach (i; 0 .. resultCoeffs.length) {
            resultCoeffs[i] = this.a[i] * multiplier;
            multiplier *= value;
        }
        return new UnivariatePolynomial(resultCoeffs, false);
    }

    double[] evaluateDerivativesAt(double where) {
        auto c = this.a;
        const nc = this.degree();
        const x = where;
        const nd = nc;
        auto pd = new double[cast(size_t) nc + 1];

        double cnst = 1.0;

        pd[0] = c[nc];
        for (int j = 1; j <= nd; ++j)
            pd[j] = 0.0;

        for (int i = nc - 1; i >= 0; --i) {
            const nnd = nd < (nc - i) ? nd : nc - i;
            for (int j = nnd; j >= 1; --j)
                pd[j] = pd[j] * x + pd[j - 1];
            pd[0] = pd[0] * x + c[i];
        }

        for (int i = 2; i <= nd; ++i) {
            cnst *= i;
            pd[i] *= cnst;
        }

        UnivariatePolynomial der = this;
        for (int i = 0; i < nc; ++i) {
            pd[i] = der.evaluateAt(x);
            der = der.derive();
        }

        return pd;
    }

    int coeffSignChanges() {
        int signChanges = 0;
        double lastNonZeroCoeff = this.a[$ - 1];
        for (int i = cast(int) this.a.length - 2; i >= 0; --i) {
            if (this.a[i] != 0.0) {
                if (this.a[i] * lastNonZeroCoeff < 0.0)
                    ++signChanges;
                lastNonZeroCoeff = this.a[i];
            }
        }
        return signChanges;
    }

    double rootBound() {
        double rootBoundValue = 0.0;
        for (int i = 0; i < cast(int) a.length - 1; ++i)
            rootBoundValue = max(
                rootBoundValue,
                2.0 * math_pow(
                    abs(a[i] / a[$ - 1]),
                    1.0 / cast(double) (this.degree() - i)
                )
            );
        return rootBoundValue;
    }

    double maxPositiveRootBound() {
        auto normCoeff = new double[this.a.length];
        for (int i = 0; i < cast(int) this.a.length - 1; ++i)
            normCoeff[i] = this.a[i] / this.a[$ - 1];

        int negCoeffs = 0;
        for (int i = 0; i < cast(int) normCoeff.length - 1; ++i)
            if (normCoeff[i] < 0.0)
                ++negCoeffs;

        double rootBoundValue = 0.0;
        negCoeffs = -negCoeffs;
        for (int i = 0; i < cast(int) normCoeff.length - 1; ++i)
            if (normCoeff[i] < 0.0)
                rootBoundValue = max(
                    rootBoundValue,
                    math_pow(
                        negCoeffs * normCoeff[i],
                        1.0 / cast(double) (this.polynomial_degree - i)
                    )
                );
        return rootBoundValue;
    }

    double minPositiveRootBound() {
        int negCoeffs = 0;
        foreach (coefficient; this.a)
            if (coefficient < 0.0)
                ++negCoeffs;

        double rootBoundValue = 0.0;
        negCoeffs = -negCoeffs;
        for (int i = 1; i < cast(int) this.a.length; ++i) {
            if (this.a[this.degree() - i] < 0.0) {
                const tempRootBound = math_pow(
                    negCoeffs * this.a[i],
                    1.0 / cast(double) i
                );
                if (rootBoundValue < tempRootBound)
                    rootBoundValue = tempRootBound;
            }
        }
        return 1.0 / rootBoundValue;
    }

    override string toString() {
        string s = a[0].to!string;
        for (int i = 1; i < cast(int) a.length; ++i) {
            const exponent = i == 1 ? "" : "^" ~ i.to!string;
            if (a[i] < 0.0)
                s ~= "-" ~ (-a[i]).to!string ~ "x" ~ exponent;
            else
                s ~= "+" ~ a[i].to!string ~ "x" ~ exponent;
        }
        return s;
    }

    static UnivariatePolynomial fromRealRoots(double[] roots...) {
        auto result = new UnivariatePolynomial(1.0);
        foreach (root; roots)
            result = result.mult(new UnivariatePolynomial(-root, 1.0));
        return result;
    }

    static UnivariatePolynomial gcd(
        UnivariatePolynomial a,
        UnivariatePolynomial b)
    {
        while (!(b.degree() == 0 && b.getCoeff(0) == 0.0)) {
            auto t = b;
            b = a.mod(b);
            a = t;
        }
        return a;
    }

    package UnivariatePolynomial compact() {
        int newDegree = polynomial_degree;
        for (; newDegree > 0 && a[newDegree] == 0.0; --newDegree) {}
        return newDegree == polynomial_degree
            ? this
            : new UnivariatePolynomial(newDegree, a);
    }
}

unittest {
    auto p = new UnivariatePolynomial(-6.0, 11.0, -6.0, 1.0);
    assert(p.degree() == 3);
    assert(abs(p.evaluateAt(1.0)) < 1.0e-12);
    assert(abs(p.evaluateAt(2.0)) < 1.0e-12);
    assert(abs(p.evaluateAt(3.0)) < 1.0e-12);

    auto derivative = p.derive();
    assert(derivative.degree() == 2);
    assert(abs(derivative.evaluateAt(2.0) + 1.0) < 1.0e-12);

    auto shifted = p.shift1();
    assert(abs(shifted.evaluateAt(0.0) - p.evaluateAt(1.0)) < 1.0e-12);
}
