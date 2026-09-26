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

module de.mfo.jsurf.algebra.d_chain_root_finder;

import std.algorithm.comparison : min, max;
import std.math : abs, isNaN, log, pow, sqrt;

import de.mfo.jsurf.algebra.real_root_finder : RealRootFinder;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;

class DChainRootFinder : RealRootFinder {
    private class SearchStruct {
        UnivariatePolynomial poly;
        double smallestPossibleRoot;
        double valueAtSmallestPossibleRoot;

        this(
            UnivariatePolynomial poly,
            double smallestPossibleRoot)
        {
            this.poly = poly;
            this.smallestPossibleRoot =
                smallestPossibleRoot;
            this.valueAtSmallestPossibleRoot =
                poly.evaluateAt(smallestPossibleRoot);
        }
    }

    override double[] findAllRoots(
        UnivariatePolynomial p)
    {
        double rootBound;

        for (int i = 0; i < p.degree(); ++i)
            rootBound =
                max(
                    rootBound,
                    2.0 * pow(
                        abs(
                            p.getCoeff(i)
                            / p.getCoeff(
                                p.degree())),
                        1.0
                            / (p.degree() - i)));

        return findAllRootsIn(
            p, -rootBound, rootBound);
    }

    override double findFirstRootIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        switch (p.degree()) {
            case 0:
                return double.nan;

            case 1: {
                auto roots =
                    solveLinear(
                        p.getCoeff(0),
                        p.getCoeff(1),
                        lowerBound,
                        upperBound);
                return roots.length
                    ? roots[0]
                    : double.nan;
            }

            case 2: {
                auto roots =
                    solveQuadratic(
                        p.getCoeff(0),
                        p.getCoeff(1),
                        p.getCoeff(2),
                        lowerBound,
                        upperBound);
                return roots.length
                    ? roots[0]
                    : double.nan;
            }

            default: {
                auto root = new double[1];
                auto searchStructs =
                    new SearchStruct[p.degree()];

                foreach (i; 0 .. searchStructs.length) {
                    searchStructs[i] =
                        new SearchStruct(
                            i == 0
                                ? p
                                : searchStructs[i - 1]
                                    .poly.derive(),
                            lowerBound);
                }

                if (findFirstRecursive(
                        searchStructs,
                        cast(int)
                            searchStructs.length
                            - 1,
                        upperBound,
                        upperBound,
                        root))
                {
                    return root[0];
                }

                return double.nan;
            }
        }
    }

    private bool findFirstRecursive(
        SearchStruct[] searchStructs,
        int startWith,
        double searchUpperBound,
        double largestPossibleRoot,
        double[] root)
    {
        auto search = searchStructs[startWith];
        double divider = double.nan;

        if (search.poly.degree() == 1) {
            divider =
                -search.poly.getCoeff(0)
                / search.poly.getCoeff(1);

            if (divider
                    < search.smallestPossibleRoot
                || divider
                    >= searchUpperBound)
            {
                divider = double.nan;
            }
        } else {
            const fl =
                search.valueAtSmallestPossibleRoot;
            const fu =
                search.poly.evaluateAt(
                    searchUpperBound);

            if (fl * fu < 0.0) {
                divider =
                    bisect(
                        search.poly,
                        search.smallestPossibleRoot,
                        searchUpperBound,
                        fl,
                        fu);
            } else if (fl == 0.0) {
                divider =
                    search.smallestPossibleRoot;
            }

            search.smallestPossibleRoot =
                searchUpperBound;
            search.valueAtSmallestPossibleRoot =
                fu;
        }

        const hasDivider = !isNaN(divider);

        if (startWith == 0 && hasDivider) {
            root[0] = divider;
            return true;
        }

        return (
                hasDivider
                && findFirstRecursive(
                    searchStructs,
                    startWith - 1,
                    divider,
                    largestPossibleRoot,
                    root))
            || (
                searchUpperBound
                    == largestPossibleRoot
                && startWith != 0
                && findFirstRecursive(
                    searchStructs,
                    startWith - 1,
                    largestPossibleRoot,
                    largestPossibleRoot,
                    root));
    }

    override double[] findAllRootsIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        switch (p.degree()) {
            case 0:
                return [];

            case 1:
                return solveLinear(
                    p.getCoeff(0),
                    p.getCoeff(1),
                    lowerBound,
                    upperBound);

            case 2:
                return solveQuadratic(
                    p.getCoeff(0),
                    p.getCoeff(1),
                    p.getCoeff(2),
                    lowerBound,
                    upperBound);

            default:
                auto resultLength =
                    new int[1];
                auto temporary =
                    findAllRecursive(
                        p,
                        lowerBound,
                        upperBound,
                        resultLength);

                return temporary[
                    1
                    .. cast(size_t)
                        resultLength[0]
                        - 1].dup;
        }
    }

    private double[] findAllRecursive(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound,
        int[] resultLength)
    {
        if (p.degree() == 1) {
            const root =
                -p.getCoeff(0)
                / p.getCoeff(1);

            auto roots = new double[3];

            if (lowerBound < root
                && root < upperBound)
            {
                roots[0] = lowerBound;
                roots[1] = root;
                roots[2] = upperBound;
                resultLength[0] = 3;
            } else {
                roots[0] = lowerBound;
                roots[1] = upperBound;
                resultLength[0] = 2;
            }

            return roots;
        }

        auto derivative = p.derive();
        auto derivativeLength =
            new int[1];
        auto derivativeRoots =
            findAllRecursive(
                derivative,
                lowerBound,
                upperBound,
                derivativeLength);

        auto roots =
            new double[
                derivativeLength[0] + 1];
        roots[0] = lowerBound;
        resultLength[0] = 1;

        double fu =
            p.evaluateAt(
                derivativeRoots[0]);

        for (int i = 1;
             i < derivativeLength[0];
             ++i)
        {
            const fl = fu;
            fu =
                p.evaluateAt(
                    derivativeRoots[i]);

            if (fl * fu < 0.0) {
                roots[resultLength[0]++] =
                    bisect(
                        p,
                        derivativeRoots[i - 1],
                        derivativeRoots[i],
                        fl,
                        fu);
            } else if (fl == 0.0) {
                roots[resultLength[0]++] =
                    derivativeRoots[i - 1];
            }
        }

        roots[resultLength[0]++] =
            upperBound;
        return roots;
    }

    private double[] solveLinear(
        double a0,
        double a1,
        double lowerBound,
        double upperBound)
    {
        const root = -a0 / a1;

        if (lowerBound < root
            && root < upperBound)
        {
            return [root];
        }

        return [];
    }

    private double[] solveQuadratic(
        double a0,
        double a1,
        double a2,
        double lowerBound,
        double upperBound)
    {
        const discriminant =
            a1 * a1 - 4.0 * a2 * a0;

        if (discriminant < 0.0)
            return [];

        const q =
            -0.5
            * (
                a1
                + (a1 < 0.0 ? -1.0 : 1.0)
                    * sqrt(discriminant));

        double r1 = q / a2;
        double r2 = a0 / q;

        if (r1 > r2) {
            const temporary = r1;
            r1 = r2;
            r2 = temporary;
        }

        double[] result;

        if (lowerBound < r1
            && r1 < upperBound)
            result ~= r1;

        if (lowerBound < r2
            && r2 < upperBound)
            result ~= r2;

        return result;
    }

    private double bisect(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound,
        double fl,
        double fu)
    {
        enum epsilon = 2.22045e-016;

        double center = lowerBound;
        auto coefficients = p.getCoeffs();

        const m = p.degree();
        double M;

        // Preserve the Java source literally: it assigns absCoeff = M
        // instead of M = absCoeff.
        foreach (coefficient; coefficients) {
            double absCoeff = abs(coefficient);
            if (absCoeff > M)
                absCoeff = M;
        }

        const delta =
            pow(m, -3.0 * m - 9.0)
            * pow(1.0 + M, -6.0 * m);

        int iterations =
            min(
                cast(int)(
                    log(
                        (upperBound
                            - lowerBound)
                        / epsilon)
                    / log(2.0)),
                cast(int)(
                    log(delta / epsilon)
                    / log(2.0)));

        for (; iterations > 0; --iterations) {
            center =
                0.5
                * (lowerBound + upperBound);

            double fc =
                coefficients[$ - 1];

            for (int i =
                    cast(int)
                        coefficients.length
                        - 2;
                 i >= 0;
                 --i)
            {
                fc =
                    fc * center
                    + coefficients[i];
            }

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

        return center;
    }
}
