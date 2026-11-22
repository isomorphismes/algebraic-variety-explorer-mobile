/* Test-only observations of unchanged Christian Stussak jsurf methods.
 * No polynomial substitution, collection, Horner or candidate renderer lives here.
 */
package de.mfo.jsurf.algebra;

import de.mfo.jsurf.rendering.cpu.CPUAlgebraicSurfaceRenderer;
import java.lang.reflect.Field;
import java.util.Locale;

public final class OriginalSpecializationOracle {
    private OriginalSpecializationOracle() {}

    private static final String[][] FORMULAS = {
        {"sphere", "x^2+y^2+z^2-0.64"},
        {"torus", "(x^2+y^2+z^2+0.36)^2-1.69*(x^2+y^2)"},
        {"cayley", "x^2+y^2+z^2+2*x*y*z-1"},
        {"whitney", "x^2-y^2*z"},
        {"roman", "x^2*y^2+y^2*z^2+z^2*x^2-x*y*z"},
        {"heart", "(x^2+2.25*y^2+z^2-1)^3-x^2*z^3-0.1125*y^2*z^3"},
        {"madore", "x^2+x*z^2+y^3"},
        {"cancellation", "10000000000000000*x+x-10000000000000000*x+y^2+z^3"},
        {"reciprocal", "x/3+y/7+z^5/11-0.17"},
        {"kahan", "10000000000000000*x^3+x^2*y-10000000000000000*y^3+z"}
    };
    // Each row is (constant, t coefficient, u coefficient, v coefficient).
    // These are explicit inputs, not an oracle for camera construction.
    private static final double[][][] MAPS = {
        {{0.0, 0.0, 1.0, 0.0}, {0.0, 0.0, 0.0, 1.0}, {0.0, -1.0, 0.0, 0.0}},
        {{0.0, -0.36, 0.8, 0.48}, {0.0, 0.6, 0.0, 0.8}, {0.0, -0.48, -0.6, 0.64}},
        {{0.0, -0.23, 0.1, -0.3}, {0.0, 0.37, -0.43, 0.83}, {0.0, -0.59, 0.13, 0.61}}
    };
    private static final String[] MAP_NAMES = {"axes", "rotated", "mixed"};
    private static final double[][] SAMPLES = {
        {-1.0, -1.0}, {-0.0, 0.0}, {0.0, -0.0}, {0.25, -0.75},
        {1.0, 1.0}, {1.25, -1.5}, {-2.0, 2.25}
    };
    private static final double[] PARAMETERS = {-2.0, -1.0, -0.0, 0.0, 0.5, 1.0, 1.5};

    private static String bits(double value) {
        return String.format(Locale.ROOT, "%016x", Double.doubleToRawLongBits(value));
    }

    private static PolynomialOperation coordinate(double[] coefficients) {
        PolynomialOperation expression = new DoubleValue(coefficients[0]);
        expression = new PolynomialAddition(expression, new PolynomialMultiplication(
                new PolynomialVariable(PolynomialVariable.Var.z), new DoubleValue(coefficients[3])));
        expression = new PolynomialAddition(expression, new PolynomialMultiplication(
                new PolynomialVariable(PolynomialVariable.Var.y), new DoubleValue(coefficients[2])));
        expression = new PolynomialAddition(expression, new PolynomialMultiplication(
                new PolynomialVariable(PolynomialVariable.Var.x), new DoubleValue(coefficients[1])));
        return expression;
    }

    private static void xyz(String prefix, String id, int polynomial, XYZPolynomial value) {
        XYZPolynomial.Term[] terms = value.getTerms();
        System.out.println(prefix + "\t" + id + "\t" + polynomial + "\t" + terms.length);
        for (int index = 0; index < terms.length; index++) {
            XYZPolynomial.Term term = terms[index];
            String termPrefix = prefix.equals("input") ? "term"
                    : prefix.equals("map_terms") ? "map_term" : prefix + "_term";
            System.out.println(termPrefix + "\t" + id + "\t" + polynomial + "\t" + index + "\t"
                    + bits(term.coeff) + "\t" + term.xExp + "\t" + term.yExp + "\t" + term.zExp);
        }
    }

    private static Field field(String name) throws Exception {
        Field result = XYPolynomial.class.getDeclaredField(name);
        result.setAccessible(true);
        return result;
    }

    private static void observe(String[] formula, int profile) throws Exception {
        String id = formula[0] + "-" + MAP_NAMES[profile];
        CPUAlgebraicSurfaceRenderer renderer = new CPUAlgebraicSurfaceRenderer();
        try {
            renderer.setSurfaceFamily(formula[1]);
            System.out.println("case\t" + id + "\t" + renderer.getSurfaceTotalDegree());
            System.out.println("formula\t" + id + "\t" + formula[1]);
            XYZPolynomial[] coordinates = new XYZPolynomial[3];
            for (int axis = 0; axis < coordinates.length; axis++) {
                double[] values = MAPS[profile][axis];
                System.out.println("map\t" + id + "\t" + axis + "\t" + bits(values[0])
                        + "\t" + bits(values[1]) + "\t" + bits(values[2]) + "\t" + bits(values[3]));
                coordinates[axis] = coordinate(values).accept(new Expand(), (Void) null);
                xyz("map_terms", id, axis, coordinates[axis]);
            }
            PolynomialOperation[] expressions = {
                renderer.getSurfaceExpression(), renderer.getGradientXExpression(),
                renderer.getGradientYExpression(), renderer.getGradientZExpression()
            };
            Field coefficientField = field("coeffs");
            Field xField = field("xExps");
            Field yField = field("yExps");
            for (int polynomial = 0; polynomial < expressions.length; polynomial++) {
                XYZPolynomial original = expressions[polynomial].accept(new Expand(), (Void) null);
                // Observe input BEFORE substitute; the original method may compact its input.
                xyz("input", id, polynomial, original);
                XYZPolynomial transformed = original.substitute(coordinates[0], coordinates[1], coordinates[2]);
                xyz("transformed", id, polynomial, transformed);
                for (int sample = 0; sample < SAMPLES.length; sample++) {
                    double u = SAMPLES[sample][0];
                    double v = SAMPLES[sample][1];
                    XYPolynomial row = transformed.evaluateZ(v);
                    double[] coefficients = (double[]) coefficientField.get(row);
                    byte[] xExponents = (byte[]) xField.get(row);
                    byte[] yExponents = (byte[]) yField.get(row);
                    System.out.println("row\t" + id + "\t" + polynomial + "\t" + sample
                            + "\t" + bits(v) + "\t" + coefficients.length);
                    for (int index = 0; index < coefficients.length; index++) {
                        System.out.println("row_term\t" + id + "\t" + polynomial + "\t" + sample
                                + "\t" + index + "\t" + bits(coefficients[index]) + "\t"
                                + xExponents[index] + "\t" + yExponents[index]);
                    }
                    UnivariatePolynomial column = row.evaluateY(u);
                    double[] dense = column.getCoeffs();
                    System.out.println("column\t" + id + "\t" + polynomial + "\t" + sample
                            + "\t" + bits(u) + "\t" + dense.length);
                    for (int index = 0; index < dense.length; index++) {
                        System.out.println("coefficient\t" + id + "\t" + polynomial + "\t" + sample
                                + "\t" + index + "\t" + bits(dense[index]));
                    }
                    for (double parameter : PARAMETERS) {
                        System.out.println("evaluation\t" + id + "\t" + polynomial + "\t" + sample
                                + "\t" + bits(parameter) + "\t" + bits(column.evaluateAt(parameter)));
                    }
                }
            }
            System.out.println("case_end\t" + id);
        } finally {
            renderer.shutdown();
        }
    }

    public static void main(String[] arguments) throws Exception {
        if (arguments.length != 0) throw new IllegalArgumentException("no oracle options");
        for (int exponent : new int[] {3, 5, 7}) {
            double magnitude = exponent == 3 ? 1e80 : exponent == 5 ? 1e50 : 1e40;
            for (double coefficient : new double[] {magnitude, -magnitude}) {
                XYZPolynomial result = new XYZPolynomial(coefficient).pow(exponent);
                XYZPolynomial.Term[] terms = result.getTerms();
                if (terms.length != 1 || !Double.isFinite(terms[0].coeff))
                    throw new AssertionError("finite original used power result required");
                System.out.println("unused_square\tconstant-" + exponent + "-" + bits(coefficient)
                        + "\t" + exponent + "\t" + bits(coefficient) + "\t" + bits(terms[0].coeff));
            }
        }
        for (String[] formula : FORMULAS) {
            for (int profile = 0; profile < MAPS.length; profile++) observe(formula, profile);
        }
    }
}
