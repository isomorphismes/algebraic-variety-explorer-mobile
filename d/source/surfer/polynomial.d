module surfer.polynomial;

import std.algorithm.sorting : sort;
import std.exception : enforce;
import std.math : abs;

import surfer.math3 : Ray, Vec3;

struct UnivariatePolynomial {
    // Low degree first: coefficients[i] multiplies t^^i.
    double[] coefficients;

    this(double constant) {
        coefficients = [constant];
    }

    this(double[] values) {
        coefficients = values.dup;
        canonicalize();
    }

    int degree() const pure nothrow @safe {
        return cast(int) coefficients.length - 1;
    }

    double coefficient(size_t exponent) const pure nothrow @safe {
        return exponent < coefficients.length ? coefficients[exponent] : 0.0;
    }

    double evaluate(double t) const pure nothrow @safe {
        if (coefficients.length == 0)
            return 0.0;
        double result = coefficients[$ - 1];
        for (size_t i = coefficients.length - 1; i > 0; --i)
            result = result * t + coefficients[i - 1];
        return result;
    }

    UnivariatePolynomial derivative() const {
        if (coefficients.length <= 1)
            return UnivariatePolynomial(0.0);
        auto result = new double[coefficients.length - 1];
        foreach (i; 1 .. coefficients.length)
            result[i - 1] = coefficients[i] * cast(double) i;
        return UnivariatePolynomial(result);
    }

    UnivariatePolynomial stretched(double factor) const {
        auto result = coefficients.dup;
        double power = 1.0;
        foreach (i; 0 .. result.length) {
            result[i] *= power;
            power *= factor;
        }
        return UnivariatePolynomial(result);
    }

    UnivariatePolynomial added(UnivariatePolynomial rhs) const {
        const length = coefficients.length > rhs.coefficients.length
            ? coefficients.length : rhs.coefficients.length;
        auto result = new double[length];
        foreach (i; 0 .. length)
            result[i] = coefficient(i) + rhs.coefficient(i);
        return UnivariatePolynomial(result);
    }

    UnivariatePolynomial multiplied(UnivariatePolynomial rhs) const {
        if (coefficients.length == 0 || rhs.coefficients.length == 0)
            return UnivariatePolynomial(0.0);
        auto result = new double[coefficients.length + rhs.coefficients.length - 1];
        result[] = 0.0;
        foreach (i, left; coefficients)
            foreach (j, right; rhs.coefficients)
                result[i + j] += left * right;
        return UnivariatePolynomial(result);
    }

    UnivariatePolynomial scaled(double factor) const {
        auto result = coefficients.dup;
        foreach (ref value; result)
            value *= factor;
        return UnivariatePolynomial(result);
    }

    UnivariatePolynomial power(uint exponent) {
        auto result = UnivariatePolynomial(1.0);
        auto base = this;
        auto remaining = exponent;
        while (remaining != 0) {
            if ((remaining & 1u) != 0)
                result = result.multiplied(base);
            remaining >>= 1;
            if (remaining != 0)
                base = base.multiplied(base);
        }
        return result;
    }

    private void canonicalize() {
        if (coefficients.length == 0) {
            coefficients = [0.0];
            return;
        }
        while (coefficients.length > 1 && coefficients[$ - 1] == 0.0)
            coefficients.length = coefficients.length - 1;
    }
}

struct Term {
    double coefficient;
    ubyte x_exponent;
    ubyte y_exponent;
    ubyte z_exponent;

    uint total_degree() const pure nothrow @safe {
        return cast(uint) x_exponent + y_exponent + z_exponent;
    }
}

private bool term_less(Term a, Term b) pure nothrow @safe {
    if (a.x_exponent != b.x_exponent)
        return a.x_exponent > b.x_exponent;
    if (a.y_exponent != b.y_exponent)
        return a.y_exponent > b.y_exponent;
    return a.z_exponent > b.z_exponent;
}

private bool same_power(Term a, Term b) pure nothrow @safe {
    return a.x_exponent == b.x_exponent
        && a.y_exponent == b.y_exponent
        && a.z_exponent == b.z_exponent;
}

struct Polynomial {
    Term[] terms;

    this(double constant) {
        terms = constant == 0.0 ? [] : [Term(constant, 0, 0, 0)];
    }

    this(Term[] input) {
        terms = compact(input.dup);
    }

    static Polynomial variable(char name) {
        switch (name) {
            case 'x': return Polynomial([Term(1.0, 1, 0, 0)]);
            case 'y': return Polynomial([Term(1.0, 0, 1, 0)]);
            case 'z': return Polynomial([Term(1.0, 0, 0, 1)]);
            default: assert(0, "unknown polynomial variable");
        }
    }

    bool is_zero() const pure nothrow @safe {
        return terms.length == 0;
    }

    bool is_constant() const pure nothrow @safe {
        return terms.length == 0
            || (terms.length == 1
                && terms[0].x_exponent == 0
                && terms[0].y_exponent == 0
                && terms[0].z_exponent == 0);
    }

    double constant_value() const @safe {
        enforce(is_constant(), "expected a scalar expression");
        return terms.length == 0 ? 0.0 : terms[0].coefficient;
    }

    uint total_degree() const pure nothrow @safe {
        uint result = 0;
        foreach (term; terms)
            if (term.total_degree() > result)
                result = term.total_degree();
        return result;
    }

    Polynomial added(Polynomial rhs) const {
        auto all = new Term[terms.length + rhs.terms.length];
        all[0 .. terms.length] = terms[];
        all[terms.length .. $] = rhs.terms[];
        return Polynomial(all);
    }

    Polynomial subtracted(Polynomial rhs) const {
        auto all = new Term[terms.length + rhs.terms.length];
        all[0 .. terms.length] = terms[];
        foreach (i, term; rhs.terms) {
            term.coefficient = -term.coefficient;
            all[terms.length + i] = term;
        }
        return Polynomial(all);
    }

    Polynomial scaled(double factor) const {
        if (factor == 0.0)
            return Polynomial(0.0);
        auto result = terms.dup;
        foreach (ref term; result)
            term.coefficient *= factor;
        return Polynomial(result);
    }

    Polynomial multiplied(Polynomial rhs) const {
        if (is_zero() || rhs.is_zero())
            return Polynomial(0.0);
        auto products = new Term[terms.length * rhs.terms.length];
        size_t next;
        foreach (left; terms) {
            foreach (right; rhs.terms) {
                const x = cast(uint) left.x_exponent + right.x_exponent;
                const y = cast(uint) left.y_exponent + right.y_exponent;
                const z = cast(uint) left.z_exponent + right.z_exponent;
                enforce(x <= ubyte.max && y <= ubyte.max && z <= ubyte.max,
                        "polynomial degree exceeds 255");
                products[next++] = Term(
                    left.coefficient * right.coefficient,
                    cast(ubyte) x,
                    cast(ubyte) y,
                    cast(ubyte) z
                );
            }
        }
        return Polynomial(products);
    }

    Polynomial power(uint exponent) {
        auto result = Polynomial(1.0);
        auto base = this;
        auto remaining = exponent;
        while (remaining != 0) {
            if ((remaining & 1u) != 0)
                result = result.multiplied(base);
            remaining >>= 1;
            if (remaining != 0)
                base = base.multiplied(base);
        }
        return result;
    }

    Polynomial derivative(char variable_name) {
        Term[] result;
        result.reserve(terms.length);
        foreach (term; terms) {
            uint exponent;
            switch (variable_name) {
                case 'x': exponent = term.x_exponent; break;
                case 'y': exponent = term.y_exponent; break;
                case 'z': exponent = term.z_exponent; break;
                default: assert(0, "unknown differentiation variable");
            }
            if (exponent == 0)
                continue;
            auto derived = term;
            derived.coefficient *= cast(double) exponent;
            switch (variable_name) {
                case 'x': --derived.x_exponent; break;
                case 'y': --derived.y_exponent; break;
                case 'z': --derived.z_exponent; break;
                default: assert(0, "unknown differentiation variable");
            }
            result ~= derived;
        }
        return Polynomial(result);
    }

    double evaluate(Vec3 point) const {
        double result = 0.0;
        foreach (term; terms) {
            result += term.coefficient
                * integer_power(point.x, term.x_exponent)
                * integer_power(point.y, term.y_exponent)
                * integer_power(point.z, term.z_exponent);
        }
        return result;
    }

    UnivariatePolynomial along(Ray ray) {
        auto result = UnivariatePolynomial(0.0);
        auto x = UnivariatePolynomial([ray.origin.x, ray.direction.x]);
        auto y = UnivariatePolynomial([ray.origin.y, ray.direction.y]);
        auto z = UnivariatePolynomial([ray.origin.z, ray.direction.z]);

        foreach (term; terms) {
            auto expanded = x.power(term.x_exponent)
                .multiplied(y.power(term.y_exponent))
                .multiplied(z.power(term.z_exponent))
                .scaled(term.coefficient);
            result = result.added(expanded);
        }
        return result;
    }

    private static Term[] compact(Term[] values) {
        if (values.length == 0)
            return [];

        sort!term_less(values);
        Term[] result;
        result.reserve(values.length);
        size_t first = 0;
        while (first < values.length) {
            size_t after = first + 1;
            while (after < values.length && same_power(values[first], values[after]))
                ++after;

            // Stussak's XYZPolynomial also uses compensated summation when
            // collecting equal terms. Keep that numerical choice here.
            double sum = values[first].coefficient;
            double correction = 0.0;
            foreach (i; first + 1 .. after) {
                const y = values[i].coefficient - correction;
                const t = sum + y;
                correction = (t - sum) - y;
                sum = t;
            }
            if (sum != 0.0) {
                auto collected = values[first];
                collected.coefficient = sum;
                result ~= collected;
            }
            first = after;
        }
        return result;
    }
}

private double integer_power(double base, uint exponent) pure nothrow @safe {
    double result = 1.0;
    double factor = base;
    auto remaining = exponent;
    while (remaining != 0) {
        if ((remaining & 1u) != 0)
            result *= factor;
        remaining >>= 1;
        if (remaining != 0)
            factor *= factor;
    }
    return result;
}

unittest {
    auto sphere = Polynomial.variable('x').power(2)
        .added(Polynomial.variable('y').power(2))
        .added(Polynomial.variable('z').power(2))
        .subtracted(Polynomial(0.64));
    assert(sphere.total_degree() == 2);
    assert(abs(sphere.evaluate(Vec3(0.8, 0.0, 0.0))) < 1.0e-12);

    auto ray_polynomial = sphere.along(Ray(Vec3(0.0, 0.0, 1.0), Vec3(0.0, 0.0, -1.0)));
    assert(ray_polynomial.degree() == 2);
    assert(abs(ray_polynomial.evaluate(0.2)) < 1.0e-12);
}
