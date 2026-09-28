package org.algebraicvarietyexplorer.render;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import javax.vecmath.Color3f;
import javax.vecmath.Matrix4d;

import de.mfo.jsurf.rendering.cpu.AntiAliasingPattern;
import de.mfo.jsurf.rendering.cpu.CPUAlgebraicSurfaceRenderer;
import de.mfo.jsurf.algebra.DescartesRootFinder;
import de.mfo.jsurf.algebra.UnivariatePolynomial;
import org.algebraicvarietyexplorer.samples.SurfaceExample;
import org.algebraicvarietyexplorer.samples.SurfaceExamples;

public final class JsurfCoreTest {
    @Test
    public void productionDescartesRootOracleCoversTangentNearAndNarrowIntervals() {
        DescartesRootFinder roots = new DescartesRootFinder(false);

        UnivariatePolynomial tangent = new UnivariatePolynomial(0.0625, -0.5, 1.0);
        assertEquals(
                0.24999994039535522,
                roots.findFirstRootIn(tangent, 0.0, 1.0),
                0.0);

        UnivariatePolynomial nearDouble = new UnivariatePolynomial(0.0625 - 1e-12, -0.5, 1.0);
        assertEquals(
                0.24999898672103882,
                roots.findFirstRootIn(nearDouble, 0.0, 1.0),
                0.0);
        assertTrue(Double.isNaN(roots.findFirstRootIn(nearDouble, 0.2499995, 0.2500005)));

        UnivariatePolynomial fourRoots = new UnivariatePolynomial(0.027, 0.2085, -0.67, -0.45, 1.0);
        assertArrayEquals(
                new double[] {-0.75, -0.09999996423721313, 0.3999999761581421, 0.8999999761581421},
                roots.findAllRootsIn(fourRoots, -1.0, 1.0),
                0.0);
    }

    @Test
    public void parserReportsTheSphereAsDegreeTwo() throws Exception {
        CPUAlgebraicSurfaceRenderer renderer = new CPUAlgebraicSurfaceRenderer();
        try {
            renderer.setSurfaceFamily("x^2+y^2+z^2-0.64");
            assertEquals(2, renderer.getSurfaceTotalDegree());
        } finally {
            renderer.shutdown();
        }
    }

    @Test
    public void everyShippedExampleParsesAtItsExpectedDegree() throws Exception {
        int[] expectedDegrees = {2, 4, 3, 3, 4, 6};
        assertEquals(expectedDegrees.length, SurfaceExamples.all().size());

        CPUAlgebraicSurfaceRenderer renderer = new CPUAlgebraicSurfaceRenderer();
        try {
            int index = 0;
            for (SurfaceExample example : SurfaceExamples.all()) {
                renderer.setSurfaceFamily(example.formula);
                assertEquals(example.name, expectedDegrees[index], renderer.getSurfaceTotalDegree());
                index++;
            }
        } finally {
            renderer.shutdown();
        }
    }

    @Test
    public void malformedFormulaIsRejected() throws Exception {
        CPUAlgebraicSurfaceRenderer renderer = new CPUAlgebraicSurfaceRenderer();
        try {
            boolean rejected = false;
            try {
                renderer.setSurfaceFamily("x^");
            } catch (Exception expected) {
                rejected = true;
            }
            assertTrue("a trailing exponent operator must not parse", rejected);
        } finally {
            renderer.shutdown();
        }
    }

    @Test
    public void rayTracerDrawsForegroundPixelsForSphere() throws Exception {
        CPUAlgebraicSurfaceRenderer renderer = new CPUAlgebraicSurfaceRenderer();
        try {
            renderer.setSurfaceFamily("x^2+y^2+z^2-0.64");
            renderer.setBackgroundColor(new Color3f(0.0f, 0.0f, 0.0f));
            renderer.setAntiAliasingPattern(AntiAliasingPattern.OG_1x1);

            Matrix4d cameraTransform = renderer.getCamera().getTransform();
            cameraTransform.setIdentity();
            cameraTransform.m23 = -1.0;

            int[] pixels = new int[64 * 64];
            renderer.draw(pixels, 64, 64);

            int foregroundPixels = 0;
            for (int pixel : pixels) {
                if ((pixel & 0x00ffffff) != 0) {
                    foregroundPixels++;
                }
            }
            assertTrue(foregroundPixels > 500);
            assertTrue(foregroundPixels < pixels.length);
        } finally {
            renderer.shutdown();
        }
    }

    @Test
    public void identicalRequestsProduceIdenticalPixels() throws Exception {
        CPUAlgebraicSurfaceRenderer renderer = new CPUAlgebraicSurfaceRenderer();
        try {
            renderer.setSurfaceFamily("x^2+y^2+z^2-0.64");
            renderer.setBackgroundColor(new Color3f(0.0f, 0.0f, 0.0f));
            renderer.setAntiAliasingPattern(AntiAliasingPattern.OG_1x1);

            Matrix4d cameraTransform = renderer.getCamera().getTransform();
            cameraTransform.setIdentity();
            cameraTransform.m23 = -1.0;

            int[] first = new int[48 * 48];
            int[] second = new int[48 * 48];
            renderer.draw(first, 48, 48);
            renderer.draw(second, 48, 48);
            assertArrayEquals(first, second);
        } finally {
            renderer.shutdown();
        }
    }
}
