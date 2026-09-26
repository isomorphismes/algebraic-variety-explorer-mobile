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

module de.mfo.jsurf.algebra.eval_root_finder;

import std.math : abs, isNaN;
import de.mfo.jsurf.algebra.real_root_finder : RealRootFinder;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;

class EVALRootFinder : RealRootFinder {
    enum EPSILON = 1.0e-7;
    private bool makeSquarefree;

    this(bool makeSquarefree) {
        this.makeSquarefree = makeSquarefree;
    }

    override double[] findAllRoots(UnivariatePolynomial p) {
        return findAllRootsIn(
            p,
            -p.stretch(-1.0).maxPositiveRootBound()
                * (1.0 + 2.220446049250313E-16),
            p.maxPositiveRootBound()
                * (1.0 + 2.220446049250313E-16));
    }

    override double[] findAllRootsIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        p = p.shrink();
        if (makeSquarefree) {
            auto polynomialGcd =
                UnivariatePolynomial.gcd(p, p.derive());
            if (polynomialGcd.degree() > 0)
                p = p.div(polynomialGcd);
        }

        // The Java source is unfinished here and returns null.
        return null;
    }

    override double findFirstRootIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        if (makeSquarefree) {
            auto polynomialGcd =
                UnivariatePolynomial.gcd(p, p.derive());
            if (polynomialGcd.degree() > 0)
                p = p.div(polynomialGcd);
        }

        return EVAL(
            p,
            lowerBound,
            upperBound,
            p.evaluateAt(lowerBound),
            p.evaluateAt(upperBound));
    }

    double EVAL(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound,
        double fl,
        double fu)
    {
        const middle = (lowerBound + upperBound) / 2.0;
        const radius = (upperBound - lowerBound) / 2.0;

        if (upperBound - lowerBound < EPSILON)
            return middle;

        auto translated = p.shift(middle);
        const fm = translated.getCoeff(0);
        auto coefficients = translated.getCoeffs();
        coefficients[0] = -abs(coefficients[0]);
        foreach (i; 1 .. coefficients.length)
            coefficients[i] = abs(coefficients[i]);

        if (new UnivariatePolynomial(coefficients)
                .evaluateAt(radius) < 0.0)
            return double.nan;

        auto translatedDerivative =
            p.derive().shift(middle);
        auto derivativeCoefficients =
            translatedDerivative.getCoeffs();
        derivativeCoefficients[0] =
            -abs(derivativeCoefficients[0]);

        foreach (i; 1 .. derivativeCoefficients.length)
            derivativeCoefficients[i] =
                abs(derivativeCoefficients[i]);

        if (fl * fu <= 0.0
            && new UnivariatePolynomial(
                    derivativeCoefficients)
                .evaluateAt(radius) < 0.0)
        {
            return bisect(
                p, lowerBound, upperBound, fl, fu);
        }

        const left =
            EVAL(
                p,
                lowerBound,
                middle,
                fl,
                fm);

        if (!isNaN(left))
            return left;

        return EVAL(
            p,
            middle,
            upperBound,
            fm,
            fu);
    }

    private static double bisect(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound,
        double fl,
        double fu)
    {
        auto coefficients = p.getCoeffs();

        assert(
            fl * fu < 0.0,
            "tried bisection on interval without sign change");

        while (abs(upperBound - lowerBound) > EPSILON) {
            const center =
                0.5 * (lowerBound + upperBound);
            double fc = coefficients[$ - 1];

            for (int i =
                    cast(int)coefficients.length - 2;
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

        return lowerBound;
    }
}
