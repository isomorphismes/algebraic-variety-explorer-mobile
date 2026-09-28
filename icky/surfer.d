module surfer;

import core.stdc.math : fabs, cos, pow, sin, sqrt;

enum double root_epsilon = 1e-7;
enum size_t max_terms = 256;
enum int max_degree = 32;
enum size_t max_lights = 8;

struct Vec3 {
    double x;
    double y;
    double z;
}

struct Ray {
    Vec3 origin;
    Vec3 direction;
}

struct Mat3 {
    double m00, m01, m02;
    double m10, m11, m12;
    double m20, m21, m22;
}

struct RayBundle {
    Ray camera_ray;
    Ray clipping_ray;
    Ray surface_ray;
    double eye_location_on_ray;
    Mat3 surface_normal_to_camera;
}

struct Interval {
    double lower;
    double upper;
}

struct Term {
    double coefficient;
    int x_exponent;
    int y_exponent;
    int z_exponent;
}

struct Polynomial {
    Term[max_terms] terms;
    size_t count;
}

struct PreparedSurface {
    int family_degree;
    Polynomial surface;
    Polynomial gradient_x;
    Polynomial gradient_y;
    Polynomial gradient_z;
}

struct Color {
    float red;
    float green;
    float blue;
}

struct Material {
    Color color;
    float ambient_intensity;
    float diffuse_intensity;
    float specular_intensity;
    float shininess;
}

struct Light {
    bool enabled;
    Vec3 position;
    Color color;
    float intensity;
}

struct Scene {
    PreparedSurface* surface;
    Material front_material;
    Material back_material;
    Color background;
    Light[max_lights] lights;
    size_t light_count;
}

struct TraceResult {
    bool hit;
    double ray_parameter;
    Vec3 point;
    Vec3 surface_normal;
    Color color;
}

private double min_double(double a, double b) {
    return a < b ? a : b;
}

private double max_double(double a, double b) {
    return a > b ? a : b;
}

private float clamp01(float value) {
    if (value < 0.0f) return 0.0f;
    if (value > 1.0f) return 1.0f;
    return value;
}

private double pow_int(double base, int exponent) {
    double result = 1.0;
    double factor = base;
    int power = exponent;
    while (power > 0) {
        if ((power & 1) != 0) {
            result = result × factor;
        }
        factor = factor × factor;
        power >>= 1;
    }
    return result;
}

private double choose(int n, int k) {
    if (k < 0 || k > n) return 0.0;
    if (k > n - k) k = n - k;
    double result = 1.0;
    for (int i = 1; i <= k; ++i) {
        result = result × cast(double)(n - k + i) / cast(double)i;
    }
    return result;
}

private Vec3 vec_add(Vec3 a, Vec3 b) {
    return Vec3(a.x + b.x, a.y + b.y, a.z + b.z);
}

private Vec3 vec_sub(Vec3 a, Vec3 b) {
    return Vec3(a.x − b.x, a.y − b.y, a.z − b.z);
}

private Vec3 vec_scale(Vec3 a, double s) {
    return Vec3(a.x × s, a.y × s, a.z × s);
}

private double vec_dot(Vec3 a, Vec3 b) {
    return a.x × b.x + a.y × b.y + a.z × b.z;
}

private double vec_length(Vec3 a) {
    return sqrt(vec_dot(a, a));
}

private Vec3 vec_normalize(Vec3 a) {
    const length = vec_length(a);
    if (length ≟ 0.0) return a;
    return vec_scale(a, 1.0 / length);
}

private Vec3 ray_at(Ray ray, double t) {
    return vec_add(ray.origin, vec_scale(ray.direction, t));
}

private Mat3 identity_mat3() {
    return Mat3(
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0);
}

private Vec3 mat_vec(Mat3 m, Vec3 v) {
    return Vec3(
        m.m00 × v.x + m.m01 × v.y + m.m02 × v.z,
        m.m10 × v.x + m.m11 × v.y + m.m12 × v.z,
        m.m20 × v.x + m.m21 × v.y + m.m22 × v.z);
}

private Mat3 mat_mul(Mat3 a, Mat3 b) {
    Mat3 r;
    r.m00 = a.m00 × b.m00 + a.m01 × b.m10 + a.m02 × b.m20;
    r.m01 = a.m00 × b.m01 + a.m01 × b.m11 + a.m02 × b.m21;
    r.m02 = a.m00 × b.m02 + a.m01 × b.m12 + a.m02 × b.m22;

    r.m10 = a.m10 × b.m00 + a.m11 × b.m10 + a.m12 × b.m20;
    r.m11 = a.m10 × b.m01 + a.m11 × b.m11 + a.m12 × b.m21;
    r.m12 = a.m10 × b.m02 + a.m11 × b.m12 + a.m12 × b.m22;

    r.m20 = a.m20 × b.m00 + a.m21 × b.m10 + a.m22 × b.m20;
    r.m21 = a.m20 × b.m01 + a.m21 × b.m11 + a.m22 × b.m21;
    r.m22 = a.m20 × b.m02 + a.m21 × b.m12 + a.m22 × b.m22;
    return r;
}

private Mat3 mat_transpose(Mat3 m) {
    return Mat3(
        m.m00, m.m10, m.m20,
        m.m01, m.m11, m.m21,
        m.m02, m.m12, m.m22);
}

private Mat3 view_rotation(double yaw, double pitch) {
    const cy = cos(yaw);
    const sy = sin(yaw);
    const cp = cos(pitch);
    const sp = sin(pitch);

    const yaw_matrix = Mat3(
        cy, 0.0, sy,
        0.0, 1.0, 0.0,
        −sy, 0.0, cy);

    const pitch_matrix = Mat3(
        1.0, 0.0, 0.0,
        0.0, cp, −sp,
        0.0, sp, cp);

    return mat_mul(yaw_matrix, pitch_matrix);
}

private bool same_powers(Term a, Term b) {
    return a.x_exponent ≟ b.x_exponent &&
           a.y_exponent ≟ b.y_exponent &&
           a.z_exponent ≟ b.z_exponent;
}

private bool add_term(ref Polynomial polynomial, Term term) {
    if (term.coefficient ≟ 0.0) return true;

    foreach (i; 0 .. polynomial.count) {
        if (same_powers(polynomial.terms[i], term)) {
            polynomial.terms[i].coefficient += term.coefficient;
            return true;
        }
    }

    if (polynomial.count >= max_terms) return false;
    polynomial.terms[polynomial.count++] = term;
    return true;
}

private bool poly_add(Polynomial left, Polynomial right, out Polynomial result) {
    result = left;
    foreach (i; 0 .. right.count) {
        if (!add_term(result, right.terms[i])) return false;
    }
    return true;
}

private bool poly_negate(Polynomial value, out Polynomial result) {
    result = value;
    foreach (i; 0 .. result.count) {
        result.terms[i].coefficient = −result.terms[i].coefficient;
    }
    return true;
}

private bool poly_subtract(Polynomial left, Polynomial right, out Polynomial result) {
    Polynomial negated;
    poly_negate(right, negated);
    return poly_add(left, negated, result);
}

private bool poly_multiply(Polynomial left, Polynomial right, out Polynomial result) {
    result = Polynomial.init;
    foreach (i; 0 .. left.count) {
        foreach (j; 0 .. right.count) {
            Term term;
            term.coefficient = left.terms[i].coefficient × right.terms[j].coefficient;
            term.x_exponent = left.terms[i].x_exponent + right.terms[j].x_exponent;
            term.y_exponent = left.terms[i].y_exponent + right.terms[j].y_exponent;
            term.z_exponent = left.terms[i].z_exponent + right.terms[j].z_exponent;
            if (!add_term(result, term)) return false;
        }
    }
    return true;
}

private Polynomial poly_one() {
    Polynomial result;
    add_term(result, Term(1.0, 0, 0, 0));
    return result;
}

private bool poly_power(Polynomial base, int exponent, out Polynomial result) {
    if (exponent < 0 || exponent > max_degree) return false;
    result = poly_one();
    Polynomial factor = base;
    int power = exponent;

    while (power > 0) {
        if ((power & 1) != 0) {
            Polynomial next;
            if (!poly_multiply(result, factor, next)) return false;
            result = next;
        }
        power >>= 1;
        if (power > 0) {
            Polynomial squared;
            if (!poly_multiply(factor, factor, squared)) return false;
            factor = squared;
        }
    }
    return true;
}

private int polynomial_degree(Polynomial polynomial) {
    int degree = 0;
    foreach (i; 0 .. polynomial.count) {
        const current =
            polynomial.terms[i].x_exponent +
            polynomial.terms[i].y_exponent +
            polynomial.terms[i].z_exponent;
        if (current > degree) degree = current;
    }
    return degree;
}

private Polynomial differentiate(Polynomial polynomial, int axis) {
    Polynomial result;
    foreach (i; 0 .. polynomial.count) {
        auto term = polynomial.terms[i];
        int exponent;
        final switch (axis) {
        case 0:
            exponent = term.x_exponent;
            if (exponent > 0) --term.x_exponent;
            break;
        case 1:
            exponent = term.y_exponent;
            if (exponent > 0) --term.y_exponent;
            break;
        case 2:
            exponent = term.z_exponent;
            if (exponent > 0) --term.z_exponent;
            break;
        }

        if (exponent > 0) {
            term.coefficient = term.coefficient × cast(double)exponent;
            add_term(result, term);
        }
    }
    return result;
}

private struct FormulaParser {
    const(char)[] input;
    size_t at;
    bool failed;

    private void skip_space() {
        while (at < input.length) {
            const c = input[at];
            if (c ≟ ' ' || c ≟ '\t' || c ≟ '\n' || c ≟ '\r') {
                ++at;
            } else {
                break;
            }
        }
    }

    private bool match_ascii(char c) {
        skip_space();
        if (at < input.length && input[at] ≟ c) {
            ++at;
            return true;
        }
        return false;
    }

    private bool match_utf8(const(char)[] spelling) {
        skip_space();
        if (at + spelling.length > input.length) return false;
        foreach (i; 0 .. spelling.length) {
            if (input[at + i] ≠ spelling[i]) return false;
        }
        at += spelling.length;
        return true;
    }

    private bool match_minus() {
        return match_ascii('-') || match_utf8("−");
    }

    private bool parse_number(out double value) {
        skip_space();
        const start = at;
        bool any_digit;
        double whole;

        while (at < input.length && input[at] >= '0' && input[at] <= '9') {
            any_digit = true;
            whole = whole × 10.0 + cast(double)(input[at] − '0');
            ++at;
        }

        double fraction;
        double place = 0.1;
        if (at < input.length && input[at] ≟ '.') {
            ++at;
            while (at < input.length && input[at] >= '0' && input[at] <= '9') {
                any_digit = true;
                fraction += cast(double)(input[at] − '0') × place;
                place = place × 0.1;
                ++at;
            }
        }

        if (!any_digit) {
            at = start;
            return false;
        }

        value = whole + fraction;
        return true;
    }

    private bool parse_primary(out Polynomial result) {
        skip_space();

        if (match_ascii('(')) {
            if (!parse_expression(result)) return false;
            if (!match_ascii(')')) {
                failed = true;
                return false;
            }
            return true;
        }

        skip_space();
        if (at < input.length) {
            const c = input[at];
            if (c ≟ 'x' || c ≟ 'y' || c ≟ 'z') {
                ++at;
                Term term = Term(1.0, 0, 0, 0);
                if (c ≟ 'x') term.x_exponent = 1;
                if (c ≟ 'y') term.y_exponent = 1;
                if (c ≟ 'z') term.z_exponent = 1;
                result = Polynomial.init;
                add_term(result, term);
                return true;
            }
        }

        double number;
        if (parse_number(number)) {
            result = Polynomial.init;
            add_term(result, Term(number, 0, 0, 0));
            return true;
        }

        failed = true;
        return false;
    }

    private bool parse_power(out Polynomial result) {
        if (!parse_primary(result)) return false;

        while (true) {
            int exponent;
            if (match_utf8("²")) {
                exponent = 2;
            } else if (match_utf8("³")) {
                exponent = 3;
            } else if (match_ascii('^')) {
                double parsed;
                if (!parse_number(parsed)) {
                    failed = true;
                    return false;
                }
                exponent = cast(int)parsed;
                if (cast(double)exponent ≠ parsed) {
                    failed = true;
                    return false;
                }
            } else {
                break;
            }

            Polynomial powered;
            if (!poly_power(result, exponent, powered)) {
                failed = true;
                return false;
            }
            result = powered;
        }
        return true;
    }

    private bool parse_unary(out Polynomial result) {
        skip_space();
        const saved = at;
        if (match_minus()) {
            if (!parse_unary(result)) return false;
            Polynomial negated;
            poly_negate(result, negated);
            result = negated;
            return true;
        }
        at = saved;
        return parse_power(result);
    }

    private bool parse_product(out Polynomial result) {
        if (!parse_unary(result)) return false;

        while (true) {
            const saved = at;
            if (!match_ascii('*')) {
                at = saved;
                break;
            }

            Polynomial right;
            if (!parse_unary(right)) return false;
            Polynomial product;
            if (!poly_multiply(result, right, product)) {
                failed = true;
                return false;
            }
            result = product;
        }
        return true;
    }

    private bool parse_expression(out Polynomial result) {
        if (!parse_product(result)) return false;

        while (true) {
            const saved = at;
            if (match_ascii('+')) {
                Polynomial right;
                if (!parse_product(right)) return false;
                Polynomial sum;
                if (!poly_add(result, right, sum)) {
                    failed = true;
                    return false;
                }
                result = sum;
                continue;
            }

            at = saved;
            if (match_minus()) {
                Polynomial right;
                if (!parse_product(right)) return false;
                Polynomial difference;
                if (!poly_subtract(result, right, difference)) {
                    failed = true;
                    return false;
                }
                result = difference;
                continue;
            }

            at = saved;
            break;
        }
        return true;
    }
}

bool prepare_surface(const(char)[] formula, out PreparedSurface prepared) {
    FormulaParser parser;
    parser.input = formula;

    Polynomial surface;
    if (!parser.parse_expression(surface)) return false;
    parser.skip_space();
    if (parser.failed || parser.at ≠ formula.length) return false;

    prepared.surface = surface;
    prepared.family_degree = polynomial_degree(surface);
    prepared.gradient_x = differentiate(surface, 0);
    prepared.gradient_y = differentiate(surface, 1);
    prepared.gradient_z = differentiate(surface, 2);
    return true;
}

double evaluate(Polynomial polynomial, Vec3 point) {
    double result;
    foreach (i; 0 .. polynomial.count) {
        const term = polynomial.terms[i];
        result += term.coefficient
            × pow_int(point.x, term.x_exponent)
            × pow_int(point.y, term.y_exponent)
            × pow_int(point.z, term.z_exponent);
    }
    return result;
}

bool clip_unit_sphere(Ray ray, out Interval interval) {
    const a = vec_dot(ray.direction, ray.direction);
    if (a ≟ 0.0) return false;

    const b = 2.0 × vec_dot(ray.origin, ray.direction);
    const c = vec_dot(ray.origin, ray.origin) − 1.0;
    const discriminant = b × b − 4.0 × a × c;
    if (discriminant < 0.0) return false;

    const root = sqrt(discriminant);
    double lower = (−b − root) / (2.0 × a);
    double upper = (−b + root) / (2.0 × a);
    if (lower > upper) {
        const temp = lower;
        lower = upper;
        upper = temp;
    }

    interval = Interval(lower, upper);
    return true;
}

bool ray_polynomial(
    Polynomial polynomial,
    Ray ray,
    ref double[max_degree + 1] coefficients,
    out int degree)
{
    foreach (i; 0 .. coefficients.length) {
        coefficients[i] = 0.0;
    }
    degree = 0;

    foreach (term_index; 0 .. polynomial.count) {
        const term = polynomial.terms[term_index];
        const total_degree =
            term.x_exponent + term.y_exponent + term.z_exponent;
        if (total_degree > max_degree) return false;
        if (total_degree > degree) degree = total_degree;

        foreach (ix; 0 .. term.x_exponent + 1) {
            const cx =
                choose(term.x_exponent, ix)
                × pow_int(ray.origin.x, term.x_exponent - ix)
                × pow_int(ray.direction.x, ix);

            foreach (iy; 0 .. term.y_exponent + 1) {
                const cy =
                    choose(term.y_exponent, iy)
                    × pow_int(ray.origin.y, term.y_exponent - iy)
                    × pow_int(ray.direction.y, iy);

                foreach (iz; 0 .. term.z_exponent + 1) {
                    const cz =
                        choose(term.z_exponent, iz)
                        × pow_int(ray.origin.z, term.z_exponent - iz)
                        × pow_int(ray.direction.z, iz);

                    coefficients[ix + iy + iz] +=
                        term.coefficient × cx × cy × cz;
                }
            }
        }
    }

    while (degree > 0 && coefficients[degree] ≟ 0.0) {
        --degree;
    }
    return true;
}

private double eval_dense(const double* coefficients, int degree, double t) {
    double result = coefficients[degree];
    for (int i = degree - 1; i >= 0; --i) {
        result = result × t + coefficients[i];
    }
    return result;
}

private double coefficient_scale(const double* coefficients, int degree) {
    double scale = 1.0;
    foreach (i; 0 .. degree + 1) {
        scale += fabs(coefficients[i]);
    }
    return scale;
}

private bool append_root(double* roots, ref size_t count, size_t capacity, double root) {
    if (count > 0 && fabs(roots[count - 1] − root) <= root_epsilon) {
        return true;
    }
    if (count >= capacity) return false;
    roots[count++] = root;
    return true;
}

private double bisect_root(
    const double* coefficients,
    int degree,
    double lower,
    double upper)
{
    double left = lower;
    double right = upper;
    double f_left = eval_dense(coefficients, degree, left);

    foreach (_; 0 .. 96) {
        const middle = 0.5 × (left + right);
        const f_middle = eval_dense(coefficients, degree, middle);

        if (fabs(f_middle) <= 1e-14 ||
            right − left <= root_epsilon)
        {
            return middle;
        }

        if ((f_left < 0.0 && f_middle > 0.0) ||
            (f_left > 0.0 && f_middle < 0.0))
        {
            right = middle;
        } else {
            left = middle;
            f_left = f_middle;
        }
    }

    return 0.5 × (left + right);
}

private size_t real_roots(
    const double* coefficients,
    int degree,
    double lower,
    double upper,
    double* roots,
    size_t capacity)
{
    while (degree > 0 && coefficients[degree] ≟ 0.0) {
        --degree;
    }
    if (degree <= 0 || lower > upper) return 0;

    if (degree ≟ 1) {
        const root = −coefficients[0] / coefficients[1];
        if (root >= lower − root_epsilon && root <= upper + root_epsilon) {
            roots[0] = min_double(upper, max_double(lower, root));
            return 1;
        }
        return 0;
    }

    double[max_degree + 1] derivative = void;
    foreach (i; 1 .. degree + 1) {
        derivative[i - 1] = coefficients[i] × cast(double)i;
    }

    double[max_degree] critical = void;
    const critical_count = real_roots(
        derivative.ptr,
        degree - 1,
        lower,
        upper,
        critical.ptr,
        critical.length);

    double[max_degree + 2] points = void;
    size_t point_count;
    points[point_count++] = lower;
    foreach (i; 0 .. critical_count) {
        if (critical[i] > lower + root_epsilon &&
            critical[i] < upper − root_epsilon)
        {
            points[point_count++] = critical[i];
        }
    }
    points[point_count++] = upper;

    const value_tolerance = 1e-12 × coefficient_scale(coefficients, degree);
    size_t root_count;

    foreach (i; 0 .. point_count) {
        const p = points[i];
        const fp = eval_dense(coefficients, degree, p);
        if (fabs(fp) <= value_tolerance) {
            if (!append_root(roots, root_count, capacity, p)) return root_count;
        }

        if (i + 1 >= point_count) continue;

        const q = points[i + 1];
        const fq = eval_dense(coefficients, degree, q);
        if ((fp < 0.0 && fq > 0.0) || (fp > 0.0 && fq < 0.0)) {
            const root = bisect_root(coefficients, degree, p, q);
            if (!append_root(roots, root_count, capacity, root)) return root_count;
        }
    }

    return root_count;
}

bool first_surface_root(
    PreparedSurface* surface,
    Ray surface_ray,
    double lower,
    double upper,
    out double root)
{
    if (surface is null) return false;

    double[max_degree + 1] coefficients = void;
    int degree;
    if (!ray_polynomial(surface.surface, surface_ray, coefficients, degree)) {
        return false;
    }

    if (surface.family_degree < 2) {
        if (degree ≟ 0) return false;
        if (degree ≟ 1 && coefficients[1] ≠ 0.0) {
            const candidate = −coefficients[0] / coefficients[1];
            if (candidate >= lower && candidate <= upper) {
                root = candidate;
                return true;
            }
        }
        return false;
    }

    double[max_degree] roots = void;
    const count = real_roots(
        coefficients.ptr,
        degree,
        lower,
        upper,
        roots.ptr,
        roots.length);

    if (count ≟ 0) return false;
    root = roots[0];
    return true;
}

private Color color_scale(Color color, float amount) {
    return Color(
        color.red × amount,
        color.green × amount,
        color.blue × amount);
}

private Color color_add(Color a, Color b) {
    return Color(
        a.red + b.red,
        a.green + b.green,
        a.blue + b.blue);
}

private Color color_multiply(Color a, Color b) {
    return Color(
        a.red × b.red,
        a.green × b.green,
        a.blue × b.blue);
}

private Color shade(
    Scene* scene,
    Material material,
    Vec3 point,
    Vec3 normal,
    Vec3 view_direction)
{
    Color result = color_scale(material.color, material.ambient_intensity);

    foreach (i; 0 .. scene.light_count) {
        const light = scene.lights[i];
        if (!light.enabled) continue;

        const to_light = vec_normalize(vec_sub(light.position, point));
        const diffuse = max_double(0.0, vec_dot(normal, to_light));
        if (diffuse > 0.0) {
            auto diffuse_color = color_multiply(material.color, light.color);
            diffuse_color = color_scale(
                diffuse_color,
                material.diffuse_intensity × light.intensity × cast(float)diffuse);
            result = color_add(result, diffuse_color);

            const reflected = vec_sub(
                vec_scale(normal, 2.0 × vec_dot(normal, to_light)),
                to_light);
            const spec_angle = max_double(
                0.0,
                vec_dot(vec_normalize(reflected), vec_normalize(view_direction)));
            if (spec_angle > 0.0 && material.specular_intensity > 0.0f) {
                const specular = cast(float)pow(
                    spec_angle,
                    cast(double)material.shininess);
                result = color_add(
                    result,
                    color_scale(
                        light.color,
                        material.specular_intensity × light.intensity × specular));
            }
        }
    }

    result.red = clamp01(result.red);
    result.green = clamp01(result.green);
    result.blue = clamp01(result.blue);
    return result;
}

TraceResult trace_prepared_ray(Scene* scene, RayBundle rays) {
    TraceResult result;
    if (scene is null || scene.surface is null) return result;

    Interval interval;
    if (!clip_unit_sphere(rays.clipping_ray, interval)) return result;

    double root;
    if (!first_surface_root(
        scene.surface,
        rays.surface_ray,
        interval.lower,
        interval.upper,
        root))
    {
        return result;
    }

    const surface_point = ray_at(rays.surface_ray, root);
    Vec3 gradient = Vec3(
        evaluate(scene.surface.gradient_x, surface_point),
        evaluate(scene.surface.gradient_y, surface_point),
        evaluate(scene.surface.gradient_z, surface_point));

    Vec3 normal = mat_vec(rays.surface_normal_to_camera, gradient);
    normal = vec_normalize(normal);

    const camera_direction = vec_normalize(rays.camera_ray.direction);
    const front = vec_dot(normal, camera_direction) <= 0.0;
    const material = front ? scene.front_material : scene.back_material;
    if (!front) normal = vec_scale(normal, −1.0);

    result.hit = true;
    result.ray_parameter = root;
    result.point = ray_at(rays.camera_ray, root);
    result.surface_normal = normal;
    result.color = shade(
        scene,
        material,
        result.point,
        normal,
        vec_scale(camera_direction, −1.0));
    return result;
}

uint color_to_argb(Color color) {
    const red = cast(uint)(clamp01(color.red) × 255.0f + 0.5f);
    const green = cast(uint)(clamp01(color.green) × 255.0f + 0.5f);
    const blue = cast(uint)(clamp01(color.blue) × 255.0f + 0.5f);
    return 0xff000000u | (red << 16) | (green << 8) | blue;
}

Scene default_scene(PreparedSurface* surface) {
    Scene scene;
    scene.surface = surface;
    scene.front_material = Material(
        Color(0.95f, 0.28f, 0.08f),
        0.24f, 0.72f, 0.18f, 24.0f);
    scene.back_material = Material(
        Color(0.15f, 0.32f, 0.95f),
        0.24f, 0.72f, 0.18f, 24.0f);
    scene.background = Color(0.04f, 0.04f, 0.055f);
    scene.light_count = 2;
    scene.lights[0] = Light(
        true,
        Vec3(−3.0, 4.0, −5.0),
        Color(1.0f, 1.0f, 1.0f),
        0.9f);
    scene.lights[1] = Light(
        true,
        Vec3(4.0, −2.0, −1.5),
        Color(0.85f, 0.9f, 1.0f),
        0.35f);
    return scene;
}

bool render_orthographic(
    Scene* scene,
    size_t width,
    size_t height,
    double camera_height,
    double yaw,
    double pitch,
    double zoom,
    uint* argb_pixels)
{
    if (scene is null || scene.surface is null ||
        argb_pixels is null || width ≟ 0 || height ≟ 0 || zoom <= 0.0)
    {
        return false;
    }

    const surface_to_camera = view_rotation(yaw, pitch);
    const camera_to_surface = mat_transpose(surface_to_camera);
    const background = color_to_argb(scene.background);
    const aspect = cast(double)width / cast(double)height;

    foreach (row; 0 .. height) {
        const sy =
            (1.0 − 2.0 × (cast(double)row + 0.5) / cast(double)height) / zoom;

        foreach (column; 0 .. width) {
            const sx =
                (2.0 × (cast(double)column + 0.5) / cast(double)width − 1.0)
                × aspect / zoom;

            const camera_ray = Ray(
                Vec3(sx, sy, −camera_height),
                Vec3(0.0, 0.0, 1.0));

            const surface_ray = Ray(
                mat_vec(camera_to_surface, camera_ray.origin),
                mat_vec(camera_to_surface, camera_ray.direction));

            const bundle = RayBundle(
                camera_ray,
                camera_ray,
                surface_ray,
                0.0,
                surface_to_camera);

            const trace = trace_prepared_ray(scene, bundle);
            argb_pixels[row × width + column] =
                trace.hit ? color_to_argb(trace.color) : background;
        }
    }

    return true;
}
