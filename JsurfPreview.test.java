package org.algebraicvarietyexplorer.render;

import java.io.BufferedOutputStream;
import java.io.FileOutputStream;
import java.io.OutputStream;

import javax.vecmath.Color3f;
import javax.vecmath.Matrix4d;
import javax.vecmath.Point3d;

import de.mfo.jsurf.rendering.Camera;
import de.mfo.jsurf.rendering.LightSource;
import de.mfo.jsurf.rendering.Material;
import de.mfo.jsurf.rendering.cpu.AntiAliasingPattern;
import de.mfo.jsurf.rendering.cpu.CPUAlgebraicSurfaceRenderer;

/**
 * Small JVM-only visual smoke test used to inspect the ray tracer without an emulator.
 */
public final class JsurfPreview {
    private JsurfPreview() {
    }

    public static void main(String[] arguments) throws Exception {
        if (arguments.length < 1 || arguments.length > 5) {
            throw new IllegalArgumentException(
                    "Expected output.ppm [polynomial] [yawRadians] [pitchRadians] [size]");
        }
        String formula = arguments.length >= 2
                ? arguments[1]
                : "x^2+y^2+z^2-0.64";
        double yaw = arguments.length >= 3 ? Double.parseDouble(arguments[2]) : 0.55;
        double pitch = arguments.length >= 4 ? Double.parseDouble(arguments[3]) : -0.35;
        int size = arguments.length >= 5 ? Integer.parseInt(arguments[4]) : 256;
        if (!Double.isFinite(yaw) || !Double.isFinite(pitch) || size < 64 || size > 1024) {
            throw new IllegalArgumentException("Invalid rotation or image dimension");
        }

        CPUAlgebraicSurfaceRenderer renderer = new CPUAlgebraicSurfaceRenderer();
        try {
            configure(renderer, formula, yaw, pitch);
            int[] pixels = new int[size * size];
            renderer.draw(pixels, size, size);
            flipRowsInPlace(pixels, size, size);
            writePpm(arguments[0], pixels, size, size);
        } finally {
            renderer.shutdown();
        }
    }

    private static void configure(
            CPUAlgebraicSurfaceRenderer renderer,
            String formula,
            double yawAngle,
            double pitchAngle) throws Exception {
        renderer.setSurfaceFamily(formula);
        renderer.setBackgroundColor(new Color3f(0.075f, 0.09f, 0.115f));
        renderer.setAntiAliasingMode(
                CPUAlgebraicSurfaceRenderer.AntiAliasingMode.ADAPTIVE_SUPERSAMPLING);
        renderer.setAntiAliasingPattern(AntiAliasingPattern.QUINCUNX);

        Camera camera = renderer.getCamera();
        camera.setCameraType(Camera.CameraType.ORTHOGRAPHIC_CAMERA);
        camera.setHeight(2.15);
        Matrix4d cameraTransform = camera.getTransform();
        cameraTransform.setIdentity();
        cameraTransform.m23 = -1.0;

        Matrix4d yaw = new Matrix4d();
        yaw.rotY(yawAngle);
        Matrix4d pitch = new Matrix4d();
        pitch.rotX(pitchAngle);
        yaw.mul(pitch);
        renderer.setTransform(yaw);

        configureMaterial(
                renderer.getFrontMaterial(),
                new Color3f(0.90f, 0.47f, 0.18f),
                0.32f,
                0.76f,
                0.55f,
                24.0f);
        configureMaterial(
                renderer.getBackMaterial(),
                new Color3f(0.93f, 0.76f, 0.40f),
                0.30f,
                0.72f,
                0.45f,
                18.0f);

        configureLight(renderer, 0, new Point3d(-100.0, 100.0, 100.0), 0.55f);
        configureLight(renderer, 1, new Point3d(100.0, 100.0, 100.0), 0.70f);
        configureLight(renderer, 2, new Point3d(0.0, -100.0, 100.0), 0.30f);
    }

    private static void configureMaterial(
            Material material,
            Color3f color,
            float ambient,
            float diffuse,
            float specular,
            float shininess) {
        material.setColor(color);
        material.setAmbientIntensity(ambient);
        material.setDiffuseIntensity(diffuse);
        material.setSpecularIntensity(specular);
        material.setShininess(shininess);
    }

    private static void configureLight(
            CPUAlgebraicSurfaceRenderer renderer,
            int index,
            Point3d position,
            float intensity) {
        LightSource light = renderer.getLightSource(index);
        light.setStatus(LightSource.Status.ON);
        light.setPosition(position);
        light.setColor(new Color3f(1.0f, 1.0f, 1.0f));
        light.setIntensity(intensity);
    }

    private static void flipRowsInPlace(int[] pixels, int width, int height) {
        for (int top = 0; top < height / 2; top++) {
            int bottom = height - 1 - top;
            for (int x = 0; x < width; x++) {
                int topIndex = top * width + x;
                int bottomIndex = bottom * width + x;
                int swap = pixels[topIndex];
                pixels[topIndex] = pixels[bottomIndex];
                pixels[bottomIndex] = swap;
            }
        }
    }

    private static void writePpm(
            String path,
            int[] pixels,
            int width,
            int height) throws Exception {
        try (OutputStream output = new BufferedOutputStream(new FileOutputStream(path))) {
            output.write(("P6\n" + width + " " + height + "\n255\n").getBytes("US-ASCII"));
            for (int pixel : pixels) {
                output.write((pixel >> 16) & 0xff);
                output.write((pixel >> 8) & 0xff);
                output.write(pixel & 0xff);
            }
        }
    }
}
