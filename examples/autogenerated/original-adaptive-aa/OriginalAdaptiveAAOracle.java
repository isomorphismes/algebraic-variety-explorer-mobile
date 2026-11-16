/*
 * Test-only observations of Christian Stussak's unchanged jsurf renderer.
 * The inherited renderer is Apache-2.0; see its original source headers.
 * This harness supplies inputs and records outputs. It does not implement AA,
 * root finding, polynomial specialization, shading or a candidate renderer.
 */
package de.mfo.jsurf.rendering.cpu;

import de.mfo.jsurf.algebra.ColumnSubstitutor;
import de.mfo.jsurf.algebra.ColumnSubstitutorForGradient;
import de.mfo.jsurf.rendering.Camera;
import de.mfo.jsurf.rendering.LightSource;
import de.mfo.jsurf.rendering.Material;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Locale;
import javax.vecmath.Color3f;
import javax.vecmath.Matrix4d;

public final class OriginalAdaptiveAAOracle {
    private OriginalAdaptiveAAOracle() {}

    private static String bits(float value) {
        return String.format(Locale.ROOT, "%08x", Float.floatToRawIntBits(value));
    }

    private static String colorBits(Color3f value) {
        return bits(value.x) + "\t" + bits(value.y) + "\t" + bits(value.z);
    }

    private static void material(Material value) {
        value.setColor(new Color3f(0.90f, 0.47f, 0.18f));
        value.setAmbientIntensity(1.0f);
        value.setDiffuseIntensity(0.0f);
        value.setSpecularIntensity(0.0f);
        value.setShininess(24.0f);
    }

    private static CPUAlgebraicSurfaceRenderer renderer(
            String formula, double yaw, double pitch, double zoom) throws Exception {
        CPUAlgebraicSurfaceRenderer renderer = new CPUAlgebraicSurfaceRenderer();
        renderer.setSurfaceFamily(formula);
        renderer.getCamera().setCameraType(Camera.CameraType.ORTHOGRAPHIC_CAMERA);
        renderer.getCamera().setHeight(2.15 / zoom);
        renderer.getCamera().getTransform().setIdentity();
        renderer.getCamera().getTransform().m23 = -1.0;
        Matrix4d yawRotation = new Matrix4d();
        yawRotation.rotY(yaw);
        Matrix4d pitchRotation = new Matrix4d();
        pitchRotation.rotX(pitch);
        yawRotation.mul(pitchRotation);
        renderer.setTransform(yawRotation);
        material(renderer.getFrontMaterial());
        material(renderer.getBackMaterial());
        for (int index = 0; index < CPUAlgebraicSurfaceRenderer.MAX_LIGHTS; index++) {
            renderer.getLightSource(index).setStatus(LightSource.Status.OFF);
        }
        renderer.setBackgroundColor(new Color3f(0.075f, 0.09f, 0.115f));
        return renderer;
    }

    private static void patterns() {
        for (AntiAliasingPattern pattern : new AntiAliasingPattern[] {
                AntiAliasingPattern.OG_1x1, AntiAliasingPattern.QUINCUNX }) {
            int index = 0;
            for (AntiAliasingPattern.SamplingPoint point : pattern) {
                System.out.println("pattern\t" + pattern + "\t" + index++ + "\t" +
                        bits(point.getU()) + "\t" + bits(point.getV()) + "\t" + bits(point.getWeight()));
            }
        }
    }

    private static Color3f traceCenter(RenderingTask task, DrawcallStaticData data) throws Exception {
        Method trace = RenderingTask.class.getDeclaredMethod("tracePolynomial",
                ColumnSubstitutor.class, ColumnSubstitutorForGradient.class, double.class, double.class);
        trace.setAccessible(true);
        return (Color3f) trace.invoke(task, data.surfaceRowSubstitutor.setV(0.0),
                data.gradientRowSubstitutor.setV(0.0), 0.0, 0.0);
    }

    private static void blend(String name, float threshold,
            Color3f ul, Color3f ur, Color3f ll, Color3f lr) throws Exception {
        CPUAlgebraicSurfaceRenderer renderer = renderer("z", 0.0, 0.0, 1.0);
        try {
            DrawcallStaticData data = renderer.collectDrawCallStaticData(new int[9], 3, 3);
            data.antiAliasingThreshold = threshold;
            RenderingTask task = new RenderingTask(data, 0, 0, 2, 2);
            Color3f center = traceCenter(task, data);
            Method antiAlias = RenderingTask.class.getDeclaredMethod("antiAliasPixel",
                    double.class, double.class, double.class, double.class,
                    AntiAliasingPattern.class, Color3f.class, Color3f.class,
                    Color3f.class, Color3f.class, HashMap.class);
            antiAlias.setAccessible(true);
            HashMap<Double, Object> columns = new HashMap<>();
            Color3f result = (Color3f) antiAlias.invoke(task, -0.125, -0.125, 0.25, 0.25,
                    AntiAliasingPattern.QUINCUNX, ul, ur, ll, lr, columns);
            // Only the original advanced branch adds the genuine center row.
            int refined = columns.isEmpty() ? 0 : 1;
            System.out.println("blend\t" + name + "\t" + bits(threshold) + "\t" + refined + "\t" +
                    colorBits(ul) + "\t" + colorBits(ur) + "\t" + colorBits(ll) + "\t" + colorBits(lr) + "\t" +
                    colorBits(center) + "\t" + colorBits(result) + "\t" +
                    String.format(Locale.ROOT, "%08x", ColorInt.toArgb(result)));
        } finally {
            renderer.shutdown();
        }
    }

    private static Color3f red(float value) { return new Color3f(value, 0.2f, 0.4f); }

    private static Color3f eighth(Color3f value) {
        Color3f scaled = new Color3f(value);
        scaled.scale(0.125f);
        return scaled;
    }

    private static void blends() throws Exception {
        Color3f zero = new Color3f();
        blend("uniform", 0.3f, red(0.8f), red(0.8f), red(0.8f), red(0.8f));
        blend("uniform-force", 0.0f, red(0.8f), red(0.8f), red(0.8f), red(0.8f));
        blend("below-threshold", 0.3f, new Color3f(Math.nextDown(0.3f), 0, 0), zero, zero, zero);
        blend("exact-threshold", 0.3f, new Color3f(0.3f, 0, 0), zero, zero, zero);
        blend("above-threshold", 0.3f, new Color3f(Math.nextUp(0.3f), 0, 0), zero, zero, zero);
        blend("three-channel-threshold", 0.3f, new Color3f(0.1f, 0.2f, 0.2f), zero, zero, zero);
        String[] names = {"ul-ur", "ul-ll", "ul-lr", "ur-ll", "ur-lr", "ll-lr"};
        int[][] endpoints = {{0,1}, {0,2}, {0,3}, {1,2}, {1,3}, {2,3}};
        for (int index = 0; index < names.length; index++) {
            Color3f[] corners = {red(0.155f), red(0.155f), red(0.155f), red(0.155f)};
            corners[endpoints[index][0]] = red(0.0f);
            corners[endpoints[index][1]] = red(0.31f);
            blend("pair-" + names[index], 0.3f, corners[0], corners[1], corners[2], corners[3]);
        }
        Color3f orderUpperLeft = new Color3f(0.91234565f, 0.017812341f, 0.33333334f);
        Color3f orderUpperRight = new Color3f(0.00000001f, 0.70000005f, 0.9876543f);
        Color3f orderLowerLeft = new Color3f(0.00234567f, 0.000000001f, 0.12345678f);
        Color3f orderLowerRight = new Color3f(0.7765432f, 0.49999997f, 0.00000002f);
        blend("float-order", 0.3f, orderUpperLeft, orderUpperRight, orderLowerLeft, orderLowerRight);
        blend("smooth-float-order", 0.3f, eighth(orderUpperLeft), eighth(orderUpperRight),
                eighth(orderLowerLeft), eighth(orderLowerRight));
        blend("clamp", 0.0f,
                new Color3f(-2.0f, 4.0f, 0.5f), new Color3f(-2.0f, 4.0f, 0.5f),
                new Color3f(-2.0f, 4.0f, 0.5f), new Color3f(-2.0f, 4.0f, 0.5f));
    }

    private static void frame(String name, String formula, int width, int height,
            double yaw, double pitch, double zoom, AntiAliasingPattern pattern, boolean full) throws Exception {
        CPUAlgebraicSurfaceRenderer renderer = renderer(formula, yaw, pitch, zoom);
        try {
            renderer.setAntiAliasingMode(full ? CPUAlgebraicSurfaceRenderer.AntiAliasingMode.SUPERSAMPLING :
                    CPUAlgebraicSurfaceRenderer.AntiAliasingMode.ADAPTIVE_SUPERSAMPLING);
            renderer.setAntiAliasingPattern(pattern);
            int[] pixels = new int[width * height];
            DrawcallStaticData data = renderer.collectDrawCallStaticData(pixels, width, height);
            // One actual full-canvas task preserves original numerical order
            // without making a thread partition/overlapping-tile parity claim.
            new RenderingTask(data, 0, 0, width - 1, height - 1).render();
            System.out.println("frame\t" + name + "\t" + formula + "\t" + pattern + "\t" +
                    bits(data.antiAliasingThreshold) + "\t" + width + "\t" + height + "\t" +
                    Double.toHexString(yaw) + "\t" + Double.toHexString(pitch) + "\t" + Double.toHexString(zoom));
            for (int y = 0; y < height; y++) {
                for (int x = 0; x < width; x++) {
                    System.out.println("pixel\t" + name + "\t" + x + "\t" + y + "\t" +
                            String.format(Locale.ROOT, "%08x", pixels[y * width + x]));
                }
            }
        } finally {
            renderer.shutdown();
        }
    }

    private static void frames() throws Exception {
        frame("plane-og-9x7", "z", 9, 7, 0.0, 0.0, 1.0, AntiAliasingPattern.OG_1x1, false);
        frame("plane-final-9x7", "z", 9, 7, 0.0, 0.0, 1.0, AntiAliasingPattern.QUINCUNX, false);
        frame("plane-full-9x7", "z", 9, 7, 0.0, 0.0, 1.0, AntiAliasingPattern.QUINCUNX, true);
        frame("plane-final-2x2", "z", 2, 2, 0.0, 0.0, 1.0, AntiAliasingPattern.QUINCUNX, false);
        frame("plane-rotated-9x7", "z", 9, 7, 0.23, -0.17, 1.1, AntiAliasingPattern.QUINCUNX, false);
        frame("sphere-og-11x11", "x^2+y^2+z^2-0.64", 11, 11, 0.0, 0.0, 1.0, AntiAliasingPattern.OG_1x1, false);
        frame("sphere-final-11x11", "x^2+y^2+z^2-0.64", 11, 11, 0.0, 0.0, 1.0, AntiAliasingPattern.QUINCUNX, false);
        frame("sphere-full-11x11", "x^2+y^2+z^2-0.64", 11, 11, 0.0, 0.0, 1.0, AntiAliasingPattern.QUINCUNX, true);
        frame("background-final-9x7", "1", 9, 7, 0.0, 0.0, 1.0, AntiAliasingPattern.QUINCUNX, false);
    }

    public static void main(String[] arguments) throws Exception {
        if (arguments.length != 1) throw new IllegalArgumentException("patterns|blends|pixels required");
        switch (arguments[0]) {
            case "patterns": patterns(); break;
            case "blends": blends(); break;
            case "pixels": frames(); break;
            default: throw new IllegalArgumentException("unknown oracle mode");
        }
    }
}
