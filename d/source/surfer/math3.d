module surfer.math3;

import std.exception : enforce;
import std.math : abs, cos, sin, sqrt;

struct Vec3 {
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;

    double length_squared() const pure nothrow @safe {
        return x * x + y * y + z * z;
    }

    double length() const pure nothrow @safe {
        return sqrt(length_squared());
    }

    Vec3 normalized() const @safe {
        const n = length();
        return n == 0.0 ? this : this / n;
    }

    Vec3 opBinary(string op)(Vec3 rhs) const pure nothrow @safe
        if (op == "+" || op == "-")
    {
        static if (op == "+")
            return Vec3(x + rhs.x, y + rhs.y, z + rhs.z);
        else
            return Vec3(x - rhs.x, y - rhs.y, z - rhs.z);
    }

    Vec3 opBinary(string op)(double scalar) const pure nothrow @safe
        if (op == "*" || op == "/")
    {
        static if (op == "*")
            return Vec3(x * scalar, y * scalar, z * scalar);
        else
            return Vec3(x / scalar, y / scalar, z / scalar);
    }

    Vec3 opUnary(string op)() const pure nothrow @safe if (op == "-") {
        return Vec3(-x, -y, -z);
    }
}

Vec3 scale(double scalar, Vec3 value) pure nothrow @safe {
    return value * scalar;
}

double dot(Vec3 a, Vec3 b) pure nothrow @safe {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

Vec3 cross(Vec3 a, Vec3 b) pure nothrow @safe {
    return Vec3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    );
}

struct Color {
    float r = 0.0f;
    float g = 0.0f;
    float b = 0.0f;

    Color opBinary(string op)(Color rhs) const pure nothrow @safe
        if (op == "+" || op == "-")
    {
        static if (op == "+")
            return Color(r + rhs.r, g + rhs.g, b + rhs.b);
        else
            return Color(r - rhs.r, g - rhs.g, b - rhs.b);
    }

    Color opBinary(string op)(float scalar) const pure nothrow @safe
        if (op == "*")
    {
        return Color(r * scalar, g * scalar, b * scalar);
    }

    Color multiplied(Color rhs) const pure nothrow @safe {
        return Color(r * rhs.r, g * rhs.g, b * rhs.b);
    }

    Color clamped() const pure nothrow @safe {
        return Color(clamp01(r), clamp01(g), clamp01(b));
    }

    uint to_argb() const pure nothrow @safe {
        const c = clamped();
        const rr = cast(uint) (c.r * 255.0f + 0.5f);
        const gg = cast(uint) (c.g * 255.0f + 0.5f);
        const bb = cast(uint) (c.b * 255.0f + 0.5f);
        return 0xff00_0000u | (rr << 16) | (gg << 8) | bb;
    }

    private static float clamp01(float value) pure nothrow @safe {
        if (value < 0.0f) return 0.0f;
        if (value > 1.0f) return 1.0f;
        return value;
    }
}

float color_difference_squared(Color a, Color b) pure nothrow @safe {
    const dr = a.r - b.r;
    const dg = a.g - b.g;
    const db = a.b - b.b;
    return dr * dr + dg * dg + db * db;
}

struct Ray {
    Vec3 origin;
    Vec3 direction;

    Vec3 at(double t) const pure nothrow @safe {
        return origin + direction * t;
    }
}

struct Interval {
    double lower;
    double upper;
}

/**
 * Affine map p -> linear*p + translation.
 * The original Java renderer only accepts affine, non-projective transforms.
 */
struct Affine {
    // Row-major 3x3 matrix.
    double[9] linear;
    Vec3 translation = Vec3(0.0, 0.0, 0.0);

    static Affine identity() pure nothrow @safe {
        Affine result;
        result.linear = [1.0, 0.0, 0.0,
                         0.0, 1.0, 0.0,
                         0.0, 0.0, 1.0];
        return result;
    }

    static Affine translation_by(Vec3 t) pure nothrow @safe {
        auto result = identity();
        result.translation = t;
        return result;
    }

    static Affine rotation_x(double angle) pure nothrow @safe {
        const c = cos(angle);
        const s = sin(angle);
        Affine result;
        result.linear = [1.0, 0.0, 0.0,
                         0.0, c, -s,
                         0.0, s, c];
        return result;
    }

    static Affine rotation_y(double angle) pure nothrow @safe {
        const c = cos(angle);
        const s = sin(angle);
        Affine result;
        result.linear = [c, 0.0, s,
                         0.0, 1.0, 0.0,
                         -s, 0.0, c];
        return result;
    }

    static Affine scale_by(double x, double y, double z) pure nothrow @safe {
        Affine result;
        result.linear = [x, 0.0, 0.0,
                         0.0, y, 0.0,
                         0.0, 0.0, z];
        return result;
    }

    Vec3 apply_vector(Vec3 v) const pure nothrow @safe {
        return Vec3(
            linear[0] * v.x + linear[1] * v.y + linear[2] * v.z,
            linear[3] * v.x + linear[4] * v.y + linear[5] * v.z,
            linear[6] * v.x + linear[7] * v.y + linear[8] * v.z
        );
    }

    Vec3 apply_point(Vec3 p) const pure nothrow @safe {
        return apply_vector(p) + translation;
    }

    Affine opBinary(string op)(Affine rhs) const pure nothrow @safe if (op == "*") {
        // Composition: (this * rhs)(p) = this(rhs(p)).
        Affine result;
        foreach (row; 0 .. 3) {
            foreach (column; 0 .. 3) {
                double value = 0.0;
                foreach (k; 0 .. 3)
                    value += linear[row * 3 + k] * rhs.linear[k * 3 + column];
                result.linear[row * 3 + column] = value;
            }
        }
        result.translation = apply_vector(rhs.translation) + translation;
        return result;
    }

    Affine inverse() const @safe {
        const a = linear[0]; const b = linear[1]; const c = linear[2];
        const d = linear[3]; const e = linear[4]; const f = linear[5];
        const g = linear[6]; const h = linear[7]; const i = linear[8];

        const det = a * (e * i - f * h)
                  - b * (d * i - f * g)
                  + c * (d * h - e * g);
        enforce(abs(det) > 1.0e-15, "singular affine transform");

        const inverse_det = 1.0 / det;
        Affine result;
        result.linear = [
            (e * i - f * h) * inverse_det,
            (c * h - b * i) * inverse_det,
            (b * f - c * e) * inverse_det,
            (f * g - d * i) * inverse_det,
            (a * i - c * g) * inverse_det,
            (c * d - a * f) * inverse_det,
            (d * h - e * g) * inverse_det,
            (b * g - a * h) * inverse_det,
            (a * e - b * d) * inverse_det
        ];
        result.translation = -result.apply_vector(translation);
        return result;
    }
}
