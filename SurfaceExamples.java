package org.algebraicvarietyexplorer.samples;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public final class SurfaceExamples {
    private static final List<SurfaceExample> EXAMPLES = Collections.unmodifiableList(
            Arrays.asList(
                    new SurfaceExample("Sphere", "x^2+y^2+z^2-0.64"),
                    new SurfaceExample(
                            "Torus",
                            "(x^2+y^2+z^2+0.36)^2-1.69*(x^2+y^2)"),
                    new SurfaceExample(
                            "Cayley cubic",
                            "x^2+y^2+z^2+2*x*y*z-1"),
                    new SurfaceExample(
                            "Whitney umbrella",
                            "x^2-y^2*z"),
                    new SurfaceExample(
                            "Roman surface",
                            "x^2*y^2+y^2*z^2+z^2*x^2-x*y*z"),
                    new SurfaceExample(
                            "Heart",
                            "(x^2+2.25*y^2+z^2-1)^3-x^2*z^3-0.1125*y^2*z^3")
            ));

    private SurfaceExamples() {
    }

    public static List<SurfaceExample> all() {
        return EXAMPLES;
    }
}
