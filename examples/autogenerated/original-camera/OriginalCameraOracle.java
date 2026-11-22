/*
 * Test-only observations of unchanged Stussak RayCreator and vecmath methods.
 * This adapter supplies the original application's settings and records fields;
 * it does not invert matrices, normalize vectors or implement camera arithmetic.
 */
package de.mfo.jsurf.rendering.cpu;

import de.mfo.jsurf.rendering.Camera;
import java.util.Locale;
import javax.vecmath.Matrix4d;
import javax.vecmath.Point3d;
import javax.vecmath.Tuple3d;
import javax.vecmath.Vector2d;
import javax.vecmath.Vector3d;

public final class OriginalCameraOracle {
    private OriginalCameraOracle() {}

    private static final String[] NAMES = {
        "zero-square", "negative-zero-square", "zero-wide", "rotated-wide",
        "rotated-tall", "negative-wide", "zoom-high-wide"
    };
    private static final int[][] SIZES = {
        {7, 7}, {7, 7}, {13, 5}, {11, 7}, {5, 13}, {13, 7}, {13, 7}
    };
    private static final double[][] VIEWS = {
        {0.0, 0.0, 1.0}, {-0.0, -0.0, 1.0}, {0.0, 0.0, 1.0},
        {0.43, -0.71, 1.0}, {-0.61, 0.28, 1.75},
        {-1.2, -0.7, 0.55}, {0.1, 0.3, 6.0}
    };
    private static final double[] PARAMETERS = {-2.0, -1.0, -0.0, 0.0, 0.75, 1.5};
    private static final double[][] NORMALS = {
        {1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}, {0.1, -0.3, 0.71}
    };

    private static String bits(double value) {
        return String.format(Locale.ROOT, "%016x", Double.doubleToRawLongBits(value));
    }

    private static String triple(Tuple3d value) {
        return bits(value.x) + "\t" + bits(value.y) + "\t" + bits(value.z);
    }

    private static void vector(String id, String name, Tuple3d value) {
        System.out.println("vector\t" + id + "\t" + name + "\t" + triple(value));
    }

    private static void scalar(String id, String name, double value) {
        System.out.println("scalar\t" + id + "\t" + name + "\t" + bits(value));
    }

    private static void matrix(String id, String name, Matrix4d value) {
        for (int row = 0; row < 4; row++) {
            for (int column = 0; column < 4; column++) {
                System.out.println("matrix\t" + id + "\t" + name + "\t" + row
                        + "\t" + column + "\t" + bits(value.getElement(row, column)));
            }
        }
    }

    private static void ray(String id, int sample, String space, Ray value) {
        System.out.println("ray\t" + id + "\t" + sample + "\t" + space + "\t"
                + triple(value.o) + "\t" + triple(value.d));
        for (double parameter : PARAMETERS) {
            Point3d point = value.at(parameter);
            System.out.println("ray_point\t" + id + "\t" + sample + "\t" + space
                    + "\t" + bits(parameter) + "\t" + triple(point));
        }
    }

    private static void sample(String id, int index, double fractionU, double fractionV,
            OrthographicCameraRayCreator creator) {
        double u = creator.transformU(fractionU);
        double v = creator.transformV(fractionV);
        System.out.println("sample\t" + id + "\t" + index + "\t" + bits(fractionU)
                + "\t" + bits(fractionV) + "\t" + bits(u) + "\t" + bits(v));
        ray(id, index, "camera", creator.createCameraSpaceRay(u, v));
        ray(id, index, "clipping", creator.createClippingSpaceRay(u, v));
        ray(id, index, "surface", creator.createSurfaceSpaceRay(u, v));
    }

    private static void observe(int profile) {
        String id = NAMES[profile];
        int width = SIZES[profile][0];
        int height = SIZES[profile][1];
        double yaw = VIEWS[profile][0];
        double pitch = VIEWS[profile][1];
        double zoom = VIEWS[profile][2];
        double baseHeight = 2.15;
        Camera camera = new Camera();
        camera.setCameraType(Camera.CameraType.ORTHOGRAPHIC_CAMERA);
        camera.setHeight(baseHeight);
        camera.getTransform().setIdentity();
        camera.getTransform().m23 = -1.0;
        Matrix4d view = new Matrix4d();
        view.rotY(yaw);
        Matrix4d pitchRotation = new Matrix4d();
        pitchRotation.rotX(pitch);
        view.mul(pitchRotation);
        camera.setHeight(baseHeight / zoom);
        Matrix4d surface = new Matrix4d();
        surface.setIdentity();

        System.out.println("camera_case\t" + id + "\t" + width + "\t" + height + "\t"
                + bits(baseHeight) + "\t" + bits(yaw) + "\t" + bits(pitch) + "\t" + bits(zoom));
        matrix(id, "input_view", view);
        matrix(id, "input_camera", camera.getTransform());
        matrix(id, "input_surface", surface);
        OrthographicCameraRayCreator creator = (OrthographicCameraRayCreator)
                RayCreator.createRayCreator(view, surface, camera, width, height);
        matrix(id, "camera_to_surface", creator.cameraSpaceToSurfaceSpaceMatrix);
        matrix(id, "camera_to_clipping", creator.cameraSpaceToClippingSpaceMatrix);
        matrix(id, "surface_normal_to_camera", creator.surfaceSpaceNormalToCameraSpaceNormalMatrix);
        vector(id, "camera_origin", creator.rayOrigin);
        vector(id, "camera_direction", creator.rayDir);
        vector(id, "camera_du", creator.du);
        vector(id, "camera_dv", creator.dv);
        vector(id, "surface_origin", creator.surfaceRayOrigin);
        vector(id, "surface_direction", creator.surfaceRayDir);
        vector(id, "surface_du", creator.surfaceDu);
        vector(id, "surface_dv", creator.surfaceDv);
        vector(id, "clipping_origin", creator.clippingRayOrigin);
        vector(id, "clipping_direction", creator.clippingRayDir);
        vector(id, "clipping_du", creator.clippingDu);
        vector(id, "clipping_dv", creator.clippingDv);
        scalar(id, "camera_height", camera.getHeight());
        scalar(id, "uscale", creator.uscale);
        scalar(id, "vscale", creator.vscale);
        scalar(id, "uoffset", creator.uoffset);
        scalar(id, "voffset", creator.voffset);
        scalar(id, "eye_location", creator.getEyeLocationOnRay());
        Vector2d uInterval = creator.getUInterval();
        Vector2d vInterval = creator.getVInterval();
        System.out.println("interval\t" + id + "\tu\t" + bits(uInterval.x) + "\t" + bits(uInterval.y));
        System.out.println("interval\t" + id + "\tv\t" + bits(vInterval.x) + "\t" + bits(vInterval.y));
        int index = 0;
        for (double fractionV : new double[] {0.0, 0.5, 1.0}) {
            for (double fractionU : new double[] {0.0, 0.5, 1.0}) {
                sample(id, index++, fractionU, fractionV, creator);
            }
        }
        sample(id, index++, -0.5 / (width - 1.0), -0.5 / (height - 1.0), creator);
        sample(id, index++, 1.0 + 0.5 / (width - 1.0), 1.0 + 0.5 / (height - 1.0), creator);
        for (double[] fractional : new double[][] {
                {0.1, 0.3}, {0.23, 0.77}, {-0.17, 1.13}, {0.371, 0.619}}) {
            sample(id, index++, fractional[0], fractional[1], creator);
        }
        if (creator.clippingDv.x != 0.0) {
            // Choose a cancellation-sensitive INPUT from observed basis fields.
            // Expected rays still come only from the unchanged original methods.
            double fractionU = 0.25;
            double actualU = creator.transformU(fractionU);
            double targetV = -(creator.clippingDu.x * actualU) / creator.clippingDv.x;
            double fractionV = ((targetV - creator.voffset) / creator.vscale + 1.0) / 2.0;
            sample(id, index, fractionU, fractionV, creator);
        }
        for (int normal = 0; normal < NORMALS.length; normal++) {
            Vector3d input = new Vector3d(NORMALS[normal]);
            Vector3d result = creator.surfaceSpaceNormalToCameraSpaceNormal(input);
            System.out.println("normal\t" + id + "\t" + normal + "\t"
                    + triple(input) + "\t" + triple(result));
        }
        System.out.println("camera_end\t" + id);
    }

    public static void main(String[] arguments) {
        if (arguments.length != 0) throw new IllegalArgumentException("no camera oracle options");
        for (int profile = 0; profile < NAMES.length; profile++) observe(profile);
    }
}
