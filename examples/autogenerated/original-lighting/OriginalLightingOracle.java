/*
 * Test-only adapter for Christian Stussak's unchanged SURFER/jsurf methods.
 * Supplies settings and records actual collector, lighting and pixel results.
 * It implements no candidate normal, light, power, root or sample arithmetic.
 */
package de.mfo.jsurf.rendering.cpu;

import de.mfo.jsurf.algebra.Expand;
import de.mfo.jsurf.algebra.ColumnSubstitutor;
import de.mfo.jsurf.algebra.ColumnSubstitutorForGradient;
import de.mfo.jsurf.algebra.PolynomialOperation;
import de.mfo.jsurf.algebra.UnivariatePolynomial;
import de.mfo.jsurf.algebra.XYZPolynomial;
import de.mfo.jsurf.rendering.Camera;
import de.mfo.jsurf.rendering.LightProducts;
import de.mfo.jsurf.rendering.LightSource;
import de.mfo.jsurf.rendering.Material;
import java.util.Locale;
import java.util.ArrayList;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import javax.vecmath.Color3f;
import javax.vecmath.Matrix4d;
import javax.vecmath.Point3d;
import javax.vecmath.Tuple3d;
import javax.vecmath.Vector3d;
import javax.vecmath.Vector2d;

public final class OriginalLightingOracle {
    private OriginalLightingOracle() {}
    private static boolean observeWorkers;
    private static boolean observeRays;
    private static boolean observeOrderedTiles;
    private static final String[] SCENES = {
        "default", "colored", "specular", "ambient-only", "clamped", "one-light"
    };

    private static String bits(float value) {
        return String.format(Locale.ROOT, "%08x", Float.floatToRawIntBits(value));
    }
    private static String bits(double value) {
        return String.format(Locale.ROOT, "%016x", Double.doubleToRawLongBits(value));
    }
    private static String color(Color3f value) {
        return bits(value.x) + "\t" + bits(value.y) + "\t" + bits(value.z);
    }
    private static String triple(Tuple3d value) {
        return bits(value.x) + "\t" + bits(value.y) + "\t" + bits(value.z);
    }

    private static void material(Material value, Color3f color, float ambient,
            float diffuse, float specular, float shininess) {
        value.setColor(color);
        value.setAmbientIntensity(ambient);
        value.setDiffuseIntensity(diffuse);
        value.setSpecularIntensity(specular);
        value.setShininess(shininess);
    }

    private static CPUAlgebraicSurfaceRenderer renderer(String scene, String formula,
            double yaw, double pitch, double zoom) throws Exception {
        CPUAlgebraicSurfaceRenderer value = new CPUAlgebraicSurfaceRenderer();
        value.setSurfaceFamily(formula);
        value.getCamera().setCameraType(Camera.CameraType.ORTHOGRAPHIC_CAMERA);
        value.getCamera().setHeight(2.15 / zoom);
        value.getCamera().getTransform().setIdentity();
        value.getCamera().getTransform().m23 = -1.0;
        Matrix4d rotation = new Matrix4d();
        rotation.rotY(yaw);
        Matrix4d tilt = new Matrix4d();
        tilt.rotX(pitch);
        rotation.mul(tilt);
        value.setTransform(rotation);
        material(value.getFrontMaterial(), new Color3f(0.90f, 0.47f, 0.18f),
                0.32f, 0.76f, 0.55f, 24.0f);
        material(value.getBackMaterial(), new Color3f(0.93f, 0.76f, 0.40f),
                0.30f, 0.72f, 0.45f, 18.0f);
        double[][] positions = {{-100, 100, 100}, {100, 100, 100}, {0, -100, 100}};
        float[] intensities = {0.55f, 0.70f, 0.30f};
        for (int index = 0; index < CPUAlgebraicSurfaceRenderer.MAX_LIGHTS; index++) {
            LightSource light = value.getLightSource(index);
            light.setStatus(index < 3 ? LightSource.Status.ON : LightSource.Status.OFF);
            if (index < 3) {
                light.setPosition(new Point3d(positions[index]));
                light.setColor(new Color3f(1, 1, 1));
                light.setIntensity(intensities[index]);
            }
        }
        if (scene.equals("colored") || scene.equals("specular")) {
            value.getLightSource(0).setColor(new Color3f(0.91234565f, 0.017812341f, 0.33333334f));
            value.getLightSource(1).setColor(new Color3f(0.7765432f, 0.49999997f, 0.00000002f));
            value.getLightSource(2).setColor(new Color3f(0.00234567f, 0.70000005f, 0.9876543f));
            material(value.getFrontMaterial(), new Color3f(0.31234568f, 0.8876543f, 0.12345678f),
                    0.09123457f, 0.6323457f, 0.71234566f, 17.3f);
            material(value.getBackMaterial(), new Color3f(0.6123457f, 0.2111111f, 0.4323457f),
                    0.3876543f, 0.7323457f, 0.8123457f, 3.7f);
        }
        if (scene.equals("specular")) {
            value.getFrontMaterial().setAmbientIntensity(0.0f);
            value.getFrontMaterial().setDiffuseIntensity(0.0f);
            value.getBackMaterial().setAmbientIntensity(0.0f);
            value.getBackMaterial().setDiffuseIntensity(0.0f);
        }
        if (scene.equals("ambient-only")) {
            value.getFrontMaterial().setAmbientIntensity(0.12765433f);
            value.getBackMaterial().setAmbientIntensity(0.8912346f);
            for (int index = 0; index < CPUAlgebraicSurfaceRenderer.MAX_LIGHTS; index++)
                value.getLightSource(index).setStatus(LightSource.Status.OFF);
        }
        if (scene.equals("clamped")) {
            value.getFrontMaterial().setAmbientIntensity(1.5f);
            value.getBackMaterial().setAmbientIntensity(0.01f);
            value.getFrontMaterial().setSpecularIntensity(2.5f);
            value.getBackMaterial().setSpecularIntensity(3.5f);
        }
        if (scene.equals("one-light")) {
            value.getLightSource(0).setStatus(LightSource.Status.OFF);
            value.getLightSource(2).setStatus(LightSource.Status.OFF);
        }
        value.setBackgroundColor(new Color3f(0.075f, 0.09f, 0.115f));
        return value;
    }

    private static void recordMaterial(String side, Material value) {
        System.out.println("material\t" + side + "\t" + color(value.getColor()) + "\t"
                + bits(value.getAmbientIntensity()) + "\t" + bits(value.getDiffuseIntensity()) + "\t"
                + bits(value.getSpecularIntensity()) + "\t" + bits(value.getShininess()));
    }

    private static void recordProducts(String side, LightProducts[] products) {
        for (int index = 0; index < products.length; index++)
            System.out.println("products\t" + index + "\t" + side + "\t"
                    + color(products[index].getDiffuseProduct()) + "\t"
                    + color(products[index].getSpecularProduct()));
    }

    private static void shade(RenderingTask task, String name, Point3d point,
            Vector3d inputNormal, Point3d eye) {
        Vector3d normal = new Vector3d(inputNormal);
        Color3f result = task.shade(point, normal, eye);
        System.out.println("shade\t" + name + "\t" + triple(point) + "\t"
                + triple(inputNormal) + "\t" + triple(eye) + "\t"
                + color(result) + "\t" + triple(normal));
    }

    private static void lighting() throws Exception {
        for (String scene : SCENES) {
            CPUAlgebraicSurfaceRenderer renderer = renderer(scene, "z", 0, 0, 1);
            try {
                DrawcallStaticData data = renderer.collectDrawCallStaticData(new int[9], 3, 3);
                RenderingTask task = new RenderingTask(data, 0, 0, 2, 2);
                System.out.println("scene\t" + scene);
                recordMaterial("front", renderer.getFrontMaterial());
                recordMaterial("back", renderer.getBackMaterial());
                System.out.println("ambient\tfront\t" + color(data.frontAmbientColor));
                System.out.println("ambient\tback\t" + color(data.backAmbientColor));
                for (int index = 0; index < data.lightSources.length; index++) {
                    LightSource light = data.lightSources[index];
                    System.out.println("light\t" + index + "\t" + triple(light.getPosition())
                            + "\t" + color(light.getColor()) + "\t" + bits(light.getIntensity()));
                }
                recordProducts("front", data.frontLightProducts);
                recordProducts("back", data.backLightProducts);
                Point3d origin = new Point3d(0, 0, 0);
                Point3d eye = new Point3d(0, 0, 1);
                shade(task, "front-axis", origin, new Vector3d(0, 0, 1), eye);
                shade(task, "back-axis", origin, new Vector3d(0, 0, -1), eye);
                shade(task, "grazing", origin, new Vector3d(1, 0, 0), eye);
                shade(task, "singular", origin, new Vector3d(0, 0, 0), eye);
                shade(task, "negative-zero", origin, new Vector3d(-0.0, 0.0, -0.0), eye);
                shade(task, "float-length", new Point3d(0.1, -0.3, 0.7),
                        new Vector3d(0.123456789, -0.987654321, 0.713579135), new Point3d(0, 0, 2));
                shade(task, "tiny-normal", origin, new Vector3d(1e-30, -2e-30, 3e-30), eye);
                shade(task, "large-normal", origin, new Vector3d(1e30, -2e30, 3e30), eye);
                for (int index = 0; index < 40; index++) {
                    double step = index + 1.0;
                    Point3d point = new Point3d((index % 7 - 3.0) / 17.0,
                            (index % 11 - 5.0) / 13.0, (index % 5 - 2.0) / 19.0);
                    Vector3d normal = new Vector3d((step * 17 % 71 - 35) / 29.0,
                            (step * 29 % 59 - 29) / 31.0, (step * 11 % 43 - 21) / 23.0);
                    shade(task, "oblique-" + index, point, normal,
                            new Point3d(0.031 * step, -0.019 * step, 2.0));
                }
                System.out.println("scene_end\t" + scene);
            } finally { renderer.shutdown(); }
        }
    }

    /** Records arguments computed by the unchanged task, delegating every value. */
    private static final class CapturedRayCreator extends RayCreator {
        final RayCreator original;
        final ArrayList<double[]> calls = new ArrayList<>();
        CapturedRayCreator(RayCreator original, CPUAlgebraicSurfaceRenderer renderer) {
            super(renderer.getTransform(), renderer.getSurfaceTransform(), renderer.getCamera());
            this.original = original;
        }
        @Override public Ray createCameraSpaceRay(double u, double v) {
            calls.add(new double[] {u, v});
            return original.createCameraSpaceRay(u, v);
        }
        @Override public Ray createSurfaceSpaceRay(double u, double v) { return original.createSurfaceSpaceRay(u, v); }
        @Override public Ray createClippingSpaceRay(double u, double v) { return original.createClippingSpaceRay(u, v); }
        @Override public double getEyeLocationOnRay() { return original.getEyeLocationOnRay(); }
        @Override public PolynomialOperation getXForSomeA() { return original.getXForSomeA(); }
        @Override public PolynomialOperation getYForSomeA() { return original.getYForSomeA(); }
        @Override public PolynomialOperation getZForSomeA() { return original.getZForSomeA(); }
        @Override public Vector2d getUInterval() { return original.getUInterval(); }
        @Override public Vector2d getVInterval() { return original.getVInterval(); }
        @Override public double transformU(double u) { return original.transformU(u); }
        @Override public double transformV(double v) { return original.transformV(v); }
        @Override public Vector3d cameraSpaceToSurfaceSpace(Vector3d value) { return original.cameraSpaceToSurfaceSpace(value); }
        @Override public Point3d cameraSpaceToSurfaceSpace(Point3d value) { return original.cameraSpaceToSurfaceSpace(value); }
        @Override public Vector3d cameraSpaceToClippingSpace(Vector3d value) { return original.cameraSpaceToClippingSpace(value); }
        @Override public Point3d cameraSpaceToClippingSpace(Point3d value) { return original.cameraSpaceToClippingSpace(value); }
        @Override public Vector3d surfaceSpaceNormalToCameraSpaceNormal(Vector3d normal) {
            return original.surfaceSpaceNormalToCameraSpaceNormal(normal);
        }
    }

    private static void ray(String space, Ray value) {
        System.out.println("selected_bundle\t" + space + "\t" + triple(value.o) + "\t" + triple(value.d));
    }

    private static void selectedRay(String frame, String label, int call,
            CapturedRayCreator capture, DrawcallStaticData data, RenderingTask task) throws Exception {
        double[] coordinates = capture.calls.get(call);
        double u = coordinates[0];
        double v = coordinates[1];
        System.out.println("selected_ray\t" + frame + "\t" + label + "\t" + call + "\t" + bits(u) + "\t" + bits(v));
        RayCreator creator = capture.original;
        Ray camera = creator.createCameraSpaceRay(u, v);
        Ray clipping = creator.createClippingSpaceRay(u, v);
        Ray surface = creator.createSurfaceSpaceRay(u, v);
        ray("camera", camera);
        ray("clipping", clipping);
        ray("surface", surface);
        double eyeParameter = creator.getEyeLocationOnRay();
        Point3d eye = camera.at(eyeParameter);
        System.out.println("selected_eye\t" + bits(eyeParameter) + "\t" + triple(eye));
        ColumnSubstitutor row = data.surfaceRowSubstitutor.setV(v);
        ColumnSubstitutorForGradient gradientRow = data.gradientRowSubstitutor.setV(v);
        UnivariatePolynomial polynomial = row.setU(u);
        double[] coefficients = polynomial.getCoeffs();
        System.out.println("selected_polynomial\t" + coefficients.length);
        for (int index = 0; index < coefficients.length; index++)
            System.out.println("selected_coefficient\t" + index + "\t" + bits(coefficients[index]));
        int intervalIndex = 0;
        for (Vector2d interval : data.rayClipper.clipRay(clipping)) {
            System.out.println("selected_clip\t" + intervalIndex + "\t" + bits(interval.x) + "\t" + bits(interval.y));
            // This is the original task's eye-interval admission, not a root
            // solver or a replacement clipping implementation.
            double lower = interval.x;
            if (lower < eyeParameter && eyeParameter < interval.y) lower = Math.max(lower, eyeParameter);
            double root = data.realRootFinder.findFirstRootIn(polynomial, lower, interval.y);
            System.out.println("selected_root\t" + intervalIndex + "\t" + bits(lower) + "\t" + bits(interval.y) + "\t" + bits(root));
            if (!Double.isNaN(root)) {
                Point3d surfacePoint = surface.at(root);
                Point3d cameraPoint = camera.at(root);
                boolean admitted = data.rayClipper.clipPoint(surfacePoint, true);
                Vector3d gradient = gradientRow.setU(u).setT(root);
                Vector3d normal = creator.surfaceSpaceNormalToCameraSpaceNormal(gradient);
                System.out.println("selected_surface_point\t" + triple(surfacePoint));
                System.out.println("selected_camera_point\t" + triple(cameraPoint));
                System.out.println("selected_admitted\t" + (admitted ? 1 : 0));
                System.out.println("selected_gradient\t" + triple(gradient));
                System.out.println("selected_camera_normal\t" + triple(normal));
                Color3f shaded = task.shade(cameraPoint, normal, eye);
                System.out.println("selected_shade\t" + color(shaded) + "\t" + triple(normal));
            }
            intervalIndex++;
        }
        Method trace = RenderingTask.class.getDeclaredMethod("tracePolynomial",
                ColumnSubstitutor.class, ColumnSubstitutorForGradient.class, double.class, double.class);
        trace.setAccessible(true);
        // Use the original creator for the final observation so the recording
        // wrapper itself cannot add a recursive capture or alter ray results.
        data.rayCreator = creator;
        Color3f traced;
        try { traced = (Color3f) trace.invoke(task, row, gradientRow, u, v); }
        finally { data.rayCreator = capture; }
        System.out.println("selected_trace\t" + color(traced) + "\t"
                + String.format(Locale.ROOT, "%08x", ColorInt.toArgb(traced)));
        System.out.println("selected_end\t" + frame + "\t" + label);
    }

    private static void selectedRays(String frame, int width, int height,
            CapturedRayCreator capture, DrawcallStaticData data, RenderingTask task) throws Exception {
        System.out.println("captured_calls\t" + frame + "\t" + capture.calls.size());
        Vector2d uInterval = capture.getUInterval();
        Vector2d vInterval = capture.getVInterval();
        double[][] targets = {{0, 0}, {uInterval.x, vInterval.x}, {uInterval.y, vInterval.x},
                {uInterval.x, vInterval.y}, {uInterval.y, vInterval.y}};
        String[] labels = {"nearest-view-center", "nearest-lower-left", "nearest-lower-right",
                "nearest-upper-left", "nearest-upper-right"};
        for (int target = 0; target < targets.length; target++) {
            int nearest = 0;
            double distance = Double.POSITIVE_INFINITY;
            for (int index = 0; index < capture.calls.size(); index++) {
                double[] point = capture.calls.get(index);
                double candidate = Math.abs(point[0] - targets[target][0]) + Math.abs(point[1] - targets[target][1]);
                if (candidate < distance) { distance = candidate; nearest = index; }
            }
            selectedRay(frame, labels[target], nearest, capture, data, task);
        }
        if (data.antiAliasingPattern == AntiAliasingPattern.OG_1x1)
            selectedRay(frame, "actual-center-pixel", (height / 2) * width + width / 2, capture, data, task);
    }

    private static void orderedTiles(String frame, int width, int height,
            CPUAlgebraicSurfaceRenderer renderer, DrawcallStaticData data, int[] fullCanvas) throws Exception {
        int processors = Runtime.getRuntime().availableProcessors();
        int poolSize = ((java.util.concurrent.ThreadPoolExecutor) renderer.threadPoolExecutor).getCorePoolSize();
        int xStep = width / Math.min(width, Math.max(2, processors));
        int yStep = height / Math.min(height, 3);
        System.out.println("ordered_profile\t" + frame + "\t" + processors + "\t" + poolSize
                + "\t" + xStep + "\t" + yStep);
        int[] composed = new int[fullCanvas.length];
        boolean[] covered = new boolean[fullCanvas.length];
        int[] savedBuffer = data.colorBuffer;
        int tile = 0;
        try {
            // Bounds and iteration order are the original draw submission
            // inputs. Each numerical result comes from an unchanged task in
            // an independent buffer, with its original global canvas size.
            for (int xStart = 0; xStart < width; xStart += xStep)
                for (int yStart = 0; yStart < height; yStart += yStep) {
                    int xEnd = Math.min(xStart + xStep, width - 1);
                    int yEnd = Math.min(yStart + yStep, height - 1);
                    int[] privatePixels = new int[fullCanvas.length];
                    data.colorBuffer = privatePixels;
                    new RenderingTask(data, xStart, yStart, xEnd, yEnd).render();
                    System.out.println("tile\t" + frame + "\t" + tile + "\t" + xStart + "\t"
                            + yStart + "\t" + xEnd + "\t" + yEnd);
                    for (int y = yStart; y <= yEnd; y++) for (int x = xStart; x <= xEnd; x++) {
                        int index = y * width + x;
                        int argb = privatePixels[index];
                        System.out.println("tile_pixel\t" + frame + "\t" + tile + "\t" + x + "\t"
                                + y + "\t" + String.format(Locale.ROOT, "%08x", argb));
                        // Submission-order publication is explicit. It is a
                        // deterministic legal ordering of original writes,
                        // not a claim about the racing production scheduler.
                        composed[index] = argb;
                        covered[index] = true;
                    }
                    tile++;
                }
        } finally { data.colorBuffer = savedBuffer; }
        int differences = 0;
        for (int y = 0; y < height; y++) for (int x = 0; x < width; x++) {
            int index = y * width + x;
            if (!covered[index]) throw new AssertionError("original tile coverage " + frame + " " + x + " " + y);
            System.out.println("ordered_pixel\t" + frame + "\t" + x + "\t" + y + "\t"
                    + String.format(Locale.ROOT, "%08x", composed[index]));
            if (composed[index] != fullCanvas[index]) {
                differences++;
                System.out.println("ordered_difference\t" + frame + "\t" + x + "\t" + y + "\t"
                        + String.format(Locale.ROOT, "%08x", fullCanvas[index]) + "\t"
                        + String.format(Locale.ROOT, "%08x", composed[index]));
            }
        }
        System.out.println("ordered_summary\t" + frame + "\t" + tile + "\t" + differences);
        // Independently run the unchanged production draw with a serial
        // submission-order executor. This test-only scheduling choice must
        // reproduce the independent private-tile composition exactly.
        renderer.threadPoolExecutor.shutdownNow();
        renderer.threadPoolExecutor = java.util.concurrent.Executors.newSingleThreadExecutor();
        int[] serial = new int[fullCanvas.length];
        renderer.draw(serial, width, height);
        if (!java.util.Arrays.equals(serial, composed))
            throw new AssertionError("original serial draw differs from ordered private tiles: " + frame);
        System.out.println("serial_ordered_match\t" + frame + "\t1");
    }

    private static void frame(String name, String formula, int width, int height,
            double yaw, double pitch, double zoom, AntiAliasingPattern pattern) throws Exception {
        CPUAlgebraicSurfaceRenderer renderer = renderer("default", formula, yaw, pitch, zoom);
        try {
            renderer.setAntiAliasingMode(CPUAlgebraicSurfaceRenderer.AntiAliasingMode.ADAPTIVE_SUPERSAMPLING);
            renderer.setAntiAliasingPattern(pattern);
            int[] pixels = new int[width * height];
            DrawcallStaticData data = renderer.collectDrawCallStaticData(pixels, width, height);
            System.out.println("frame\t" + name + "\t" + formula + "\t" + pattern + "\t"
                    + bits(data.antiAliasingThreshold) + "\t" + width + "\t" + height + "\t"
                    + Double.toHexString(yaw) + "\t" + Double.toHexString(pitch) + "\t" + Double.toHexString(zoom));
            System.out.println("family_degree\t" + name + "\t" + renderer.getSurfaceTotalDegree());
            PolynomialOperation[] expressions = {
                renderer.getSurfaceExpression(), renderer.getGradientXExpression(),
                renderer.getGradientYExpression(), renderer.getGradientZExpression()
            };
            Method getTerms = XYZPolynomial.class.getDeclaredMethod("getTerms");
            getTerms.setAccessible(true);
            Field coefficient = XYZPolynomial.Term.class.getDeclaredField("coeff");
            coefficient.setAccessible(true);
            Field[] exponents = {
                XYZPolynomial.Term.class.getDeclaredField("xExp"),
                XYZPolynomial.Term.class.getDeclaredField("yExp"),
                XYZPolynomial.Term.class.getDeclaredField("zExp")
            };
            for (Field exponent : exponents) exponent.setAccessible(true);
            for (int polynomial = 0; polynomial < expressions.length; polynomial++) {
                XYZPolynomial expanded = expressions[polynomial].accept(new Expand(), (Void) null);
                XYZPolynomial.Term[] terms = (XYZPolynomial.Term[]) getTerms.invoke(expanded);
                System.out.println("input\t" + name + "\t" + polynomial + "\t" + terms.length);
                for (int index = 0; index < terms.length; index++) {
                    XYZPolynomial.Term term = terms[index];
                    System.out.println("term\t" + name + "\t" + polynomial + "\t" + index
                            + "\t" + bits(coefficient.getDouble(term)) + "\t"
                            + exponents[0].getByte(term) + "\t" + exponents[1].getByte(term)
                            + "\t" + exponents[2].getByte(term));
                }
            }
            CapturedRayCreator captured = observeRays ? new CapturedRayCreator(data.rayCreator, renderer) : null;
            if (captured != null) data.rayCreator = captured;
            RenderingTask task = new RenderingTask(data, 0, 0, width - 1, height - 1);
            task.render();
            if (observeRays) { selectedRays(name, width, height, captured, data, task); return; }
            for (int y = 0; y < height; y++) for (int x = 0; x < width; x++)
                System.out.println("pixel\t" + name + "\t" + x + "\t" + y + "\t"
                        + String.format(Locale.ROOT, "%08x", pixels[y * width + x]));
            if (observeOrderedTiles) orderedTiles(name, width, height, renderer, data, pixels);
            if (observeWorkers) {
                int processors = Runtime.getRuntime().availableProcessors();
                int poolSize = ((java.util.concurrent.ThreadPoolExecutor)
                        renderer.threadPoolExecutor).getCorePoolSize();
                int xStep = width / Math.min(width, Math.max(2, processors));
                int yStep = height / Math.min(height, 3);
                int[] first = null;
                for (int trial = 0; trial < 3; trial++) {
                    int[] tiled = new int[pixels.length];
                    // This is the unchanged production partition and scheduler,
                    // including overlapping endpoints. The adapter does not
                    // force an order or choose a winner for shared pixels.
                    renderer.draw(tiled, width, height);
                    System.out.println("worker_frame\t" + name + "\t" + trial
                            + "\t" + processors + "\t" + poolSize + "\t" + xStep + "\t" + yStep);
                    int differences = 0;
                    int changed = 0;
                    for (int y = 0; y < height; y++) for (int x = 0; x < width; x++) {
                        int index = y * width + x;
                        System.out.println("worker_pixel\t" + name + "\t" + trial + "\t" + x
                                + "\t" + y + "\t" + String.format(Locale.ROOT, "%08x", tiled[index]));
                        if (tiled[index] != pixels[index]) {
                            differences++;
                            System.out.println("worker_difference\t" + name + "\t" + trial + "\t"
                                    + x + "\t" + y + "\t" + String.format(Locale.ROOT, "%08x", pixels[index])
                                    + "\t" + String.format(Locale.ROOT, "%08x", tiled[index]));
                        }
                        if (first != null && tiled[index] != first[index]) changed++;
                    }
                    System.out.println("worker_summary\t" + name + "\t" + trial + "\t"
                            + differences + "\t" + changed);
                    if (first == null) first = tiled;
                }
            }
        } finally { renderer.shutdown(); }
    }

    private static void frames() throws Exception {
        String[][] presets = {
            {"sphere", "x^2+y^2+z^2-0.64"},
            {"torus", "(x^2+y^2+z^2+0.36)^2-1.69*(x^2+y^2)"},
            {"cayley", "x^2+y^2+z^2+2*x*y*z-1"},
            {"whitney", "x^2-y^2*z"},
            {"roman", "x^2*y^2+y^2*z^2+z^2*x^2-x*y*z"},
            {"heart", "(x^2+2.25*y^2+z^2-1)^3-x^2*z^3-0.1125*y^2*z^3"}
        };
        // Fixed qualification states, selected from the existing camera
        // observations. They are explicit test inputs, not human preferences.
        String[] states = {"identity", "rotated", "rotated-zoom"};
        int[][] dimensions = {{11, 9}, {13, 11}, {11, 13}};
        double[][] views = {{0, 0, 1}, {0.43, -0.71, 1}, {-0.61, 0.28, 1.75}};
        for (String[] preset : presets) {
            for (int state = 0; state < states.length; state++) {
                frame("preset-" + preset[0] + "-" + states[state] + "-og", preset[1],
                        dimensions[state][0], dimensions[state][1], views[state][0],
                        views[state][1], views[state][2], AntiAliasingPattern.OG_1x1);
                frame("preset-" + preset[0] + "-" + states[state] + "-final", preset[1],
                        dimensions[state][0], dimensions[state][1], views[state][0],
                        views[state][1], views[state][2], AntiAliasingPattern.QUINCUNX);
            }
        }
        String[][] targeted = {
            {"zero-empty", "0"},
            {"plane", "z"},
            {"cancellation", "(10000000000000000*x+x)-10000000000000000*x+z"},
            {"tangent-double-plane", "z^2"},
            {"sphere-clipping-boundary", "x^2+y^2+z^2-1"},
            {"singular-umbrella", "x^2-y^2*z"},
            {"nonsquarefree-sphere", "(x^2+y^2+z^2-0.64)^2"},
            {"degree-eight", "x^8+y^8+z^8-0.125"}
        };
        for (String[] target : targeted)
            frame("target-" + target[0] + "-final", target[1], 11, 9, 0, 0, 1,
                    AntiAliasingPattern.QUINCUNX);
    }

    private static void additionalFrames() throws Exception {
        frame("additional-madore-og", "x^2+x*z^2+y^3", 13, 11, 0.43, -0.71, 1,
                AntiAliasingPattern.OG_1x1);
        frame("additional-madore-final", "x^2+x*z^2+y^3", 13, 11, 0.43, -0.71, 1,
                AntiAliasingPattern.QUINCUNX);
    }

    public static void main(String[] arguments) throws Exception {
        if (arguments.length != 1) throw new IllegalArgumentException("lighting|pixels|additional-pixels|workers|rays|ordered-workers required");
        if (arguments[0].equals("lighting")) lighting();
        else if (arguments[0].equals("pixels")) frames();
        else if (arguments[0].equals("additional-pixels")) additionalFrames();
        else if (arguments[0].equals("workers")) { observeWorkers = true; frames(); }
        else if (arguments[0].equals("rays")) { observeRays = true; frames(); }
        else if (arguments[0].equals("ordered-workers")) { observeOrderedTiles = true; frames(); }
        else throw new IllegalArgumentException("unknown original lighting mode");
    }
}
