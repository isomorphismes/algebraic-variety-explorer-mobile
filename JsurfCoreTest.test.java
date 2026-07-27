package org.algebraicvarietyexplorer.render;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import javax.vecmath.Color3f;
import javax.vecmath.Matrix4d;

import de.mfo.jsurf.rendering.cpu.AntiAliasingPattern;
import de.mfo.jsurf.rendering.cpu.CPUAlgebraicSurfaceRenderer;

public final class JsurfCoreTest {
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
}
