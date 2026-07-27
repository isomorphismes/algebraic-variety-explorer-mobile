package org.algebraicvarietyexplorer.render;

import android.graphics.Bitmap;
import android.os.SystemClock;

import javax.vecmath.Color3f;
import javax.vecmath.Matrix4d;
import javax.vecmath.Point3d;

import de.mfo.jsurf.rendering.Camera;
import de.mfo.jsurf.rendering.LightSource;
import de.mfo.jsurf.rendering.Material;
import de.mfo.jsurf.rendering.cpu.AntiAliasingPattern;
import de.mfo.jsurf.rendering.cpu.CPUAlgebraicSurfaceRenderer;

public final class RendererEngine {
    private final CPUAlgebraicSurfaceRenderer renderer;
    private String currentFormula;

    public RendererEngine() {
        renderer = new CPUAlgebraicSurfaceRenderer();
        configureCamera();
        configureMaterials();
        configureLights();
        renderer.setBackgroundColor(new Color3f(0.075f, 0.09f, 0.115f));
    }

    public RenderResult render(RenderRequest request) throws Exception {
        long startedAt = SystemClock.elapsedRealtime();

        setFormulaIfChanged(request.formula);
        configureView(request.yaw, request.pitch, request.zoom);
        configureQuality(request.quality);

        int[] pixels = new int[request.width * request.height];
        renderer.draw(pixels, request.width, request.height);
        flipRowsInPlace(pixels, request.width, request.height);

        Bitmap bitmap = Bitmap.createBitmap(
                pixels,
                request.width,
                request.height,
                Bitmap.Config.ARGB_8888);
        long elapsed = SystemClock.elapsedRealtime() - startedAt;
        return new RenderResult(bitmap, renderer.getSurfaceTotalDegree(), elapsed);
    }

    public void interrupt() {
        renderer.stopDrawing();
    }

    public void close() {
        renderer.stopDrawing();
        renderer.shutdown();
    }

    private void setFormulaIfChanged(String formula) throws Exception {
        if (!formula.equals(currentFormula)) {
            renderer.setSurfaceFamily(formula);
            currentFormula = formula;
        }
    }

    private void configureCamera() {
        Camera camera = renderer.getCamera();
        camera.setCameraType(Camera.CameraType.ORTHOGRAPHIC_CAMERA);
        camera.setHeight(2.15);

        Matrix4d cameraTransform = camera.getTransform();
        cameraTransform.setIdentity();
        cameraTransform.m23 = -1.0;
    }

    private void configureView(double yaw, double pitch, double zoom) {
        Matrix4d yawRotation = new Matrix4d();
        yawRotation.rotY(yaw);

        Matrix4d pitchRotation = new Matrix4d();
        pitchRotation.rotX(pitch);

        yawRotation.mul(pitchRotation);
        renderer.setTransform(yawRotation);
        renderer.getCamera().setHeight(2.15 / zoom);
    }

    private void configureMaterials() {
        Material front = renderer.getFrontMaterial();
        front.setColor(new Color3f(0.90f, 0.47f, 0.18f));
        front.setAmbientIntensity(0.32f);
        front.setDiffuseIntensity(0.76f);
        front.setSpecularIntensity(0.55f);
        front.setShininess(24.0f);

        Material back = renderer.getBackMaterial();
        back.setColor(new Color3f(0.93f, 0.76f, 0.40f));
        back.setAmbientIntensity(0.30f);
        back.setDiffuseIntensity(0.72f);
        back.setSpecularIntensity(0.45f);
        back.setShininess(18.0f);
    }

    private void configureLights() {
        setLight(0, new Point3d(-100.0, 100.0, 100.0), 0.55f);
        setLight(1, new Point3d(100.0, 100.0, 100.0), 0.70f);
        setLight(2, new Point3d(0.0, -100.0, 100.0), 0.30f);

        for (int index = 3; index < CPUAlgebraicSurfaceRenderer.MAX_LIGHTS; index++) {
            renderer.getLightSource(index).setStatus(LightSource.Status.OFF);
        }
    }

    private void setLight(int index, Point3d position, float intensity) {
        LightSource light = renderer.getLightSource(index);
        light.setStatus(LightSource.Status.ON);
        light.setPosition(position);
        light.setColor(new Color3f(1.0f, 1.0f, 1.0f));
        light.setIntensity(intensity);
    }

    private void configureQuality(RenderQuality quality) {
        renderer.setAntiAliasingMode(
                CPUAlgebraicSurfaceRenderer.AntiAliasingMode.ADAPTIVE_SUPERSAMPLING);
        renderer.setAntiAliasingPattern(
                quality == RenderQuality.INTERACTIVE
                        ? AntiAliasingPattern.OG_1x1
                        : AntiAliasingPattern.QUINCUNX);
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
}
