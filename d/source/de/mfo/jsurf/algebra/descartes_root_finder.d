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

module de.mfo.jsurf.algebra.descartes_root_finder;

import std.math : abs, isNaN;

import de.mfo.jsurf.algebra.real_root_finder : RealRootFinder;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;

class DescartesRootFinder : RealRootFinder {
    enum EPSILON = 1.0e-7;

    private bool makeSquarefree;

    private class PolyInterval {
        double[] a;
        bool shift;
        double l;
        double u;

        this(double[] a, double l, double u) {
            this(a, false, l, u);
        }

        this(double[] a, bool shift, double l, double u) {
            this.a = a;
            this.shift = shift;
            this.l = l;
            this.u = u;
        }
    }

    this(bool makeSquarefree) {
        this.makeSquarefree = makeSquarefree;
    }

    override double[] findAllRoots(UnivariatePolynomial p) {
        return findAllRootsIn(
            p,
            -p.stretch(-1.0).maxPositiveRootBound()
                * (1.0 + 2.220446049250313E-16),
            p.maxPositiveRootBound()
                * (1.0 + 2.220446049250313E-16)
        );
    }

    override double[] findAllRootsIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        p = p.shrink();

        if (makeSquarefree) {
            auto polynomialGcd = UnivariatePolynomial.gcd(p, p.derive());
            if (polynomialGcd.degree() > 0)
                p = p.div(polynomialGcd);
        }

        auto negRoots = findAllNegRootsIn(p, lowerBound, upperBound);
        auto posRoots = findAllPosRootsIn(p, lowerBound, upperBound);

        auto roots = new double[negRoots.length + posRoots.length];
        roots[0 .. negRoots.length] = negRoots[];
        roots[negRoots.length .. $] = posRoots[];
        return roots;
    }

    package double[] findAllPosRootsIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        if (upperBound < 0.0)
            return [];

        const bound2 = nextPowerOfTwo(upperBound);

        p = p.shrink();
        const tlb = lowerBound / bound2;
        const tub = upperBound / bound2;

        p = p.stretch(bound2);

        auto results = new double[cast(size_t) p.degree()];
        size_t resultsLength = 0;

        if (p.getCoeff(0) == 0.0) {
            if (lowerBound <= 0.0)
                results[resultsLength++] = 0.0;
            p = new UnivariatePolynomial(deflate0(p.getCoeffs()));
        }

        if (lowerBound < 0.0)
            lowerBound = 0.0;

        if (resultsLength != results.length) {
            PolyInterval[] candidates;
            candidates ~= new PolyInterval(
                p.getCoeff(0) == 0.0
                    ? deflate0(p.getCoeffs())
                    : p.getCoeffs(),
                0.0,
                1.0
            );

            while (candidates.length != 0) {
                auto pi = candidates[$ - 1];
                candidates.length = candidates.length - 1;

                if (pi.shift)
                    pi.a = shift1(pi.a);

                if (pi.a[0] == 0.0) {
                    const candidateRoot = pi.l * bound2;
                    if (lowerBound <= candidateRoot
                        && candidateRoot <= upperBound)
                        results[resultsLength++] = candidateRoot;

                    p = new UnivariatePolynomial(
                        deflate(p.getCoeffs(), pi.l));
                }

                if (resultsLength == results.length)
                    break;

                const variations =
                    descartesRuleOfSignReverseShift1(pi.a);

                if (variations == 1) {
                    const candidateRoot =
                        adjustIntervalAndBisect(
                            p, pi.l, pi.u, tlb, tub)
                        * bound2;

                    if (!isNaN(candidateRoot))
                        results[resultsLength++] = candidateRoot;
                }

                if (resultsLength == results.length)
                    break;

                if (variations > 1) {
                    const center = 0.5 * (pi.l + pi.u);

                    if (abs(pi.u - pi.l) < 0.5 * EPSILON) {
                        if (pi.l <= tlb)
                            results[resultsLength++] = lowerBound;
                        else
                            results[resultsLength++] = pi.l * bound2;
                        continue;
                    }

                    auto stretchedA = stretchNormalize0_5(pi.a);

                    if (center <= tub)
                        candidates ~= new PolyInterval(
                            stretchedA, true, center, pi.u);

                    if (center >= tlb)
                        candidates ~= new PolyInterval(
                            stretchedA, false, pi.l, center);
                }
            }
        }

        return results[0 .. resultsLength].dup;
    }

    package double[] findAllNegRootsIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        if (lowerBound >= 0.0)
            return [];

        p = p.stretch(-1.0);
        auto roots = findAllPosRootsIn(
            p, -upperBound, -lowerBound);

        for (size_t i = 0, j = roots.length - 1;
             i < (roots.length + 1) / 2;
             ++i, --j)
        {
            const temporary = -roots[i];
            roots[i] = -roots[j];
            roots[j] = temporary;
        }

        return roots;
    }

    private enum WhichRoot {
        SMALLEST,
        LARGEST
    }

    override double findFirstRootIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        if (makeSquarefree) {
            auto polynomialGcd = UnivariatePolynomial.gcd(
                p, p.derive());

            if (polynomialGcd.degree() > 0)
                p = p.div(polynomialGcd);
        }

        const root = -findPosRootIn(
            p.stretch(-1.0),
            -upperBound,
            -lowerBound,
            WhichRoot.LARGEST
        );

        return isNaN(root)
            ? findPosRootIn(
                p, lowerBound, upperBound, WhichRoot.SMALLEST)
            : root;
    }

    private double findPosRootIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound,
        WhichRoot whichRoot)
    {
        if (upperBound <= 0.0 || p.degree() == 0)
            return double.nan;

        p = p.shrink();

        const bound2 = nextPowerOfTwo(upperBound);
        const tlb = lowerBound / bound2;
        const tub = upperBound / bound2;

        p = p.stretch(bound2);

        double temporaryResult = double.nan;

        if (p.getCoeff(0) == 0.0) {
            if (lowerBound <= 0.0) {
                if (whichRoot == WhichRoot.SMALLEST)
                    return 0.0;
                temporaryResult = 0.0;
            }

            p = new UnivariatePolynomial(
                deflate0(p.getCoeffs()));
        }

        if (lowerBound <= 0.0)
            lowerBound = 0.0;

        PolyInterval[] candidates;
        candidates ~= new PolyInterval(
            p.getCoeffs(), 0.0, 1.0);

        while (candidates.length != 0) {
            auto pi = candidates[$ - 1];
            candidates.length = candidates.length - 1;

            if (pi.shift)
                pi.a = shift1(pi.a);

            if (pi.a.length == 0)
                continue;

            if (pi.a[0] == 0.0) {
                const candidateRoot = pi.l * bound2;

                if (lowerBound <= candidateRoot
                    && candidateRoot <= upperBound)
                {
                    if (whichRoot == WhichRoot.SMALLEST)
                        return pi.l * bound2;

                    temporaryResult = candidateRoot;
                    pi.a = deflate0(pi.a);
                }
            }

            const variations =
                descartesRuleOfSignReverseShift1(pi.a);

            if (variations == 1) {
                const candidateRoot =
                    adjustIntervalAndBisect(
                        p, pi.l, pi.u, tlb, tub)
                    * bound2;

                if (!isNaN(candidateRoot)) {
                    if (whichRoot == WhichRoot.LARGEST
                        && !isNaN(temporaryResult)
                        && temporaryResult > candidateRoot)
                        return temporaryResult;

                    return candidateRoot;
                }
            } else if (variations > 1) {
                const center = 0.5 * (pi.l + pi.u);

                if (abs(pi.u - pi.l) < 0.5 * EPSILON) {
                    if (pi.l <= tlb)
                        return lowerBound;
                    return pi.l * bound2;
                }

                auto stretchedA = stretchNormalize0_5(pi.a);

                if (whichRoot == WhichRoot.SMALLEST) {
                    if (center <= tub)
                        candidates ~= new PolyInterval(
                            stretchedA, true, center, pi.u);

                    if (center >= tlb)
                        candidates ~= new PolyInterval(
                            stretchedA, false, pi.l, center);
                } else {
                    if (center >= tlb)
                        candidates ~= new PolyInterval(
                            stretchedA, false, pi.l, center);

                    if (center <= tub)
                        candidates ~= new PolyInterval(
                            stretchedA, true, center, pi.u);
                }
            }
        }

        return temporaryResult;
    }

    private static double adjustIntervalAndBisect(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound,
        double strictLowerBound,
        double strictUpperBound)
    {
        double fl = p.evaluateAt(lowerBound);

        if (lowerBound < strictLowerBound) {
            if (upperBound < strictLowerBound) {
                return double.nan;
            } else {
                const fsl = p.evaluateAt(strictLowerBound);

                if (fl * fsl < 0.0 || fl == 0.0) {
                    return double.nan;
                } else {
                    lowerBound = strictLowerBound;
                    fl = fsl;
                }
            }
        }

        double fu = p.evaluateAt(upperBound);

        if (strictUpperBound < upperBound) {
            if (strictUpperBound < lowerBound) {
                return double.nan;
            } else {
                const fsu = p.evaluateAt(strictUpperBound);

                if (fu * fsu < 0.0 || fu == 0.0) {
                    return double.nan;
                } else {
                    upperBound = strictUpperBound;
                    fu = fsu;
                }
            }
        }

        if (fl * fu <= 0.0)
            return bisect(p, lowerBound, upperBound, fl, fu);

        return double.nan;
    }

    private static double bisect(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        return bisect(
            p,
            lowerBound,
            upperBound,
            p.evaluateAt(lowerBound),
            p.evaluateAt(upperBound)
        );
    }

    private static double bisect(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound,
        double fl,
        double fu)
    {
        const a = p.getCoeffs();

        assert(
            fl * fu < 0.0,
            "tried bisection on interval without sign change"
        );

        while (abs(upperBound - lowerBound) > EPSILON) {
            const center = 0.5 * (lowerBound + upperBound);

            double fc = a[$ - 1];
            for (int i = cast(int) a.length - 2;
                 i >= 0;
                 --i)
                fc = fc * center + a[i];

            if (fc * fl < 0.0) {
                upperBound = center;
                fu = fc;
            } else if (fc == 0.0) {
                return center;
            } else {
                lowerBound = center;
                fl = fc;
            }
        }

        return lowerBound;
    }

    double[] stretchNormalize0_5(double[] a) {
        auto resultCoeffs = new double[a.length];
        resultCoeffs[$ - 1] = a[$ - 1];

        double multiplier = 2.0;

        for (int i = cast(int) resultCoeffs.length - 2;
             i >= 0;
             --i)
        {
            resultCoeffs[i] = a[i] * multiplier;
            multiplier *= 2.0;
        }

        return resultCoeffs;
    }

    private double[] shift1(double[] a) {
        auto hornerCoeffs = a.dup;

        for (int i = 1;
             i <= cast(int) hornerCoeffs.length;
             ++i)
            for (int j = cast(int) hornerCoeffs.length - 2;
                 j >= i - 1;
                 --j)
                hornerCoeffs[j] =
                    hornerCoeffs[j] + hornerCoeffs[j + 1];

        return hornerCoeffs;
    }

    private double[] deflate0(double[] a) {
        if (a.length == 0)
            return a;

        return a[1 .. $].dup;
    }

    private double[] deflate(double[] a, double b) {
        if (a.length == 0)
            return a;

        auto result = new double[a.length - 1];
        result[$ - 1] = a[$ - 1];

        for (int i = cast(int) a.length - 3;
             i >= 0;
             --i)
            result[i] = result[i + 1] * b + a[i + 1];

        return result;
    }

    private int descartesRuleOfSignReverseShift1(double[] a) {
        int signChanges = 0;
        auto hornerCoeffs = new double[a.length];

        foreach (i; 0 .. a.length)
            hornerCoeffs[i] = a[$ - i - 1];

        double lastNonZeroCoeff = double.nan;

        for (int i = 1; i <= cast(int) a.length; ++i) {
            for (int j = cast(int) hornerCoeffs.length - 2;
                 j >= i - 1;
                 --j)
                hornerCoeffs[j] =
                    hornerCoeffs[j] + hornerCoeffs[j + 1];

            if (hornerCoeffs[i - 1] != 0.0) {
                if (hornerCoeffs[i - 1]
                    * lastNonZeroCoeff < 0.0)
                    ++signChanges;

                if (signChanges > 1)
                    return signChanges;

                lastNonZeroCoeff = hornerCoeffs[i - 1];
            }
        }

        if (hornerCoeffs[0] == 0.0)
            ++signChanges;

        return signChanges;
    }

    private union DoubleBits {
        double value;
        ulong bits;
    }

    static double nextPowerOfTwo(double d) {
        DoubleBits conversion;
        conversion.value = d;

        ulong bits = conversion.bits;

        if ((bits & 0x000f_ffff_ffff_ffffUL) != 0UL) {
            conversion.value = 2.0 * d;
            bits = conversion.bits;
            bits &= 0xfff0_0000_0000_0000UL;
            conversion.bits = bits;
        }

        return conversion.value;
    }
}

unittest {
    auto finder = new DescartesRootFinder(false);

    auto p = UnivariatePolynomial.fromRealRoots(-2.0, 0.5, 3.0);
    auto roots = finder.findAllRootsIn(p, -4.0, 4.0);
    assert(roots.length == 3);
    assert(abs(roots[0] + 2.0) < DescartesRootFinder.EPSILON);
    assert(abs(roots[1] - 0.5) < DescartesRootFinder.EPSILON);
    assert(abs(roots[2] - 3.0) < DescartesRootFinder.EPSILON);

    const first = finder.findFirstRootIn(p, -4.0, 4.0);
    assert(abs(first + 2.0) < DescartesRootFinder.EPSILON);
}
