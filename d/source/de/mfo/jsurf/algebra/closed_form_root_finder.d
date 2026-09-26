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

module de.mfo.jsurf.algebra.closed_form_root_finder;

import std.algorithm.sorting : sort;
import std.math : PI, abs, acos, cos, math_pow = pow, sqrt;

import de.mfo.jsurf.algebra.real_root_finder : RealRootFinder;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;

class ClosedFormRootFinder : RealRootFinder {
    override double[] findAllRoots(UnivariatePolynomial p) {
        switch (p.degree()) {
            case 0:
                return [];
            case 1:
                return solveLinear(p);
            case 2:
                return solveQuadric(p);
            case 3:
                return solveCubic(p);
            case 4:
                return solveQuartic(p);
            default:
                throw new Exception(
                    "no closed form solution exists for polynomials of degree > 4");
        }
    }

    override double[] findAllRootsIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        return clip(findAllRoots(p), lowerBound, upperBound);
    }

    override double findFirstRootIn(
        UnivariatePolynomial p,
        double lowerBound,
        double upperBound)
    {
        auto roots = clip(findAllRoots(p), lowerBound, upperBound);
        return roots.length > 0 ? roots[0] : double.nan;
    }

    private double[] solveLinear(UnivariatePolynomial poly) {
        return [-poly.getCoeff(0) / poly.getCoeff(1)];
    }

    private double[] solveQuadric(UnivariatePolynomial poly) {
        const p = poly.getCoeff(1) / (2.0 * poly.getCoeff(2));
        const q = poly.getCoeff(0) / poly.getCoeff(2);

        const discriminant = p * p - q;

        if (isZero(discriminant))
            return solutions(-p, -p);
        if (discriminant < 0.0)
            return solutions();

        const sqrtDiscriminant = sqrt(discriminant);
        return solutions(sqrtDiscriminant - p, -sqrtDiscriminant - p);
    }

    package double[] solveCubic(UnivariatePolynomial poly) {
        const A = poly.getCoeff(2) / poly.getCoeff(3);
        const B = poly.getCoeff(1) / poly.getCoeff(3);
        const C = poly.getCoeff(0) / poly.getCoeff(3);

        const sqA = A * A;
        const p = 1.0 / 3.0 * (-1.0 / 3.0 * sqA + B);
        const q = 1.0 / 2.0
            * (2.0 / 27.0 * A * sqA - 1.0 / 3.0 * A * B + C);

        const cbP = p * p * p;
        const discriminant = q * q + cbP;
        double[] roots;

        if (isZero(discriminant)) {
            if (isZero(q)) {
                roots = solutions(0.0, 0.0, 0.0);
            } else {
                const u = cubeRoot(-q);
                roots = solutions(2.0 * u, -u, -u);
            }
        } else if (discriminant < 0.0) {
            const phi = 1.0 / 3.0 * acos(-q / sqrt(-cbP));
            const t = 2.0 * sqrt(-p);
            roots = solutions(
                t * cos(phi),
                -t * cos(phi + PI / 3.0),
                -t * cos(phi - PI / 3.0)
            );
        } else {
            const sqrtDiscriminant = sqrt(discriminant);
            const u = cubeRoot(sqrtDiscriminant - q);
            roots = solutions(
                cubeRoot(sqrtDiscriminant - q)
                    - cubeRoot(sqrtDiscriminant + q)
            );
        }

        const substitution = 1.0 / 3.0 * A;
        foreach (ref root; roots)
            root -= substitution;

        return roots;
    }

    package double[] solveQuartic(UnivariatePolynomial poly) {
        const A = poly.getCoeff(3) / poly.getCoeff(4);
        const B = poly.getCoeff(2) / poly.getCoeff(4);
        const C = poly.getCoeff(1) / poly.getCoeff(4);
        const D = poly.getCoeff(0) / poly.getCoeff(4);

        const sqA = A * A;
        const p = -3.0 / 8.0 * sqA + B;
        const q = 1.0 / 8.0 * sqA * A - 1.0 / 2.0 * A * B + C;
        const r = -3.0 / 256.0 * sqA * sqA
            + 1.0 / 16.0 * sqA * B
            - 1.0 / 4.0 * A * C
            + D;

        double[] roots;

        if (isZero(r)) {
            auto cubic = new UnivariatePolynomial(q, p, 0.0, 1.0);
            roots = solveCubic(cubic);
            roots = solutions(roots[0], roots[1], roots[2], 0.0);
        } else {
            auto cubic = new UnivariatePolynomial(
                1.0 / 2.0 * r * p - 1.0 / 8.0 * q * q,
                -r,
                -1.0 / 2.0 * p,
                1.0
            );
            roots = solveCubic(cubic);

            const z = roots[0];

            double u = z * z - r;
            double v = 2.0 * z - p;

            if (isZero(u))
                u = 0.0;
            else if (u > 0.0)
                u = sqrt(u);
            else
                return solutions();

            if (isZero(v))
                v = 0.0;
            else if (v > 0.0)
                v = sqrt(v);
            else
                return solutions();

            auto quadric1 = new UnivariatePolynomial(
                z - u,
                q < 0.0 ? -v : v,
                1.0
            );
            auto roots1 = solveQuadric(quadric1);

            auto quadric2 = new UnivariatePolynomial(
                z + u,
                q < 0.0 ? v : -v,
                1.0
            );
            auto roots2 = solveQuadric(quadric2);

            roots = new double[roots1.length + roots2.length];
            roots[0 .. roots1.length] = roots1[];
            roots[roots1.length .. $] = roots2[];
        }

        const substitution = 1.0 / 4.0 * A;
        foreach (ref root; roots)
            root -= substitution;

        sort(roots);
        return roots;
    }

    private static double cubeRoot(double x) {
        return x >= 0.0
            ? math_pow(x, 1.0 / 3.0)
            : -math_pow(-x, 1.0 / 3.0);
    }

    private static bool isZero(double value) {
        return -1.0e-20 < value && value < 1.0e-20;
    }

    static double[] solutions(double[] values...) {
        auto result = values.dup;
        sort(result);
        return result;
    }

    private static double[] clip(double[] values, double lower, double upper) {
        auto temporary = new double[values.length];
        size_t length = 0;

        foreach (value; values)
            if (lower <= value && value <= upper)
                temporary[length++] = value;

        if (length == temporary.length)
            return temporary;
        return temporary[0 .. length].dup;
    }
}

unittest {
    auto finder = new ClosedFormRootFinder();

    auto quadratic = new UnivariatePolynomial(6.0, -5.0, 1.0);
    auto roots = finder.findAllRoots(quadratic);
    assert(roots.length == 2);
    assert(roots[0] == 2.0);
    assert(roots[1] == 3.0);

    auto cubic = UnivariatePolynomial.fromRealRoots(-2.0, 0.5, 3.0);
    roots = finder.findAllRoots(cubic);
    assert(roots.length == 3);
    assert(roots[0] < roots[1] && roots[1] < roots[2]);

    assert(abs(finder.findFirstRootIn(cubic, 0.0, 10.0) - 0.5) < 1.0e-12);
}
