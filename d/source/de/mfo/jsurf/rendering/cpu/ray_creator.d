/*
 *    Copyright 2008 Christian Stussak
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module de.mfo.jsurf.rendering.cpu.ray_creator;

import javax.vecmath : Matrix4d, Point3d, Vector2d, Vector3d, Vector4d;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.rendering.camera : Camera;
import de.mfo.jsurf.rendering.cpu.ray : Ray;

abstract class RayCreator {
    package Matrix4d cameraSpaceToSurfaceSpaceMatrix;
    package Matrix4d cameraSpaceToClippingSpaceMatrix;
    package Matrix4d surfaceSpaceNormalToCameraSpaceNormalMatrix;

    this(Matrix4d transformMatrix, Matrix4d surfaceTransformMatrix, Camera cam) {
        auto cameraInverse = new Matrix4d(cam.getTransform());
        cameraInverse.invert();

        cameraSpaceToClippingSpaceMatrix = new Matrix4d(transformMatrix);
        cameraSpaceToClippingSpaceMatrix.mul(cameraInverse);

        cameraSpaceToSurfaceSpaceMatrix = new Matrix4d(surfaceTransformMatrix);
        cameraSpaceToSurfaceSpaceMatrix.mul(cameraSpaceToClippingSpaceMatrix);

        surfaceSpaceNormalToCameraSpaceNormalMatrix =
            new Matrix4d(cameraSpaceToSurfaceSpaceMatrix);
        surfaceSpaceNormalToCameraSpaceNormalMatrix.invert();
    }

    static RayCreator createRayCreator(
        Matrix4d transformMatrix,
        Matrix4d surfaceTransformMatrix,
        Camera cam,
        int width,
        int height)
    {
        import de.mfo.jsurf.rendering.cpu.orthographic_camera_ray_creator
            : OrthographicCameraRayCreator;
        import de.mfo.jsurf.rendering.cpu.perspective_camera_ray_creator
            : PerspectiveCameraRayCreator;

        final switch (cam.getCameraType()) {
            case Camera.CameraType.ORTHOGRAPHIC_CAMERA:
                return new OrthographicCameraRayCreator(
                    transformMatrix, surfaceTransformMatrix, cam, width, height);
            case Camera.CameraType.PERSPECTIVE_CAMERA:
                return new PerspectiveCameraRayCreator(
                    transformMatrix, surfaceTransformMatrix, cam, width, height);
        }
    }

    Vector3d cameraSpaceToSurfaceSpace(Vector3d v) {
        auto transformed = new Vector4d(v);
        cameraSpaceToSurfaceSpaceMatrix.transform(transformed);
        return new Vector3d(transformed.x, transformed.y, transformed.z);
    }

    Point3d cameraSpaceToSurfaceSpace(Point3d p) {
        auto transformed = new Point3d(p);
        cameraSpaceToSurfaceSpaceMatrix.transform(transformed);
        return transformed;
    }

    Vector3d cameraSpaceToClippingSpace(Vector3d v) {
        auto transformed = new Vector4d(v);
        cameraSpaceToClippingSpaceMatrix.transform(transformed);
        return new Vector3d(transformed.x, transformed.y, transformed.z);
    }

    Point3d cameraSpaceToClippingSpace(Point3d p) {
        auto transformed = new Point3d(p);
        cameraSpaceToClippingSpaceMatrix.transform(transformed);
        return transformed;
    }

    Vector3d surfaceSpaceNormalToCameraSpaceNormal(Vector3d n) {
        auto transformed = new Vector3d(n);
        surfaceSpaceNormalToCameraSpaceNormalMatrix.transform(transformed);
        return transformed;
    }

    abstract Ray createCameraSpaceRay(double u, double v);
    abstract Ray createSurfaceSpaceRay(double u, double v);
    abstract Ray createClippingSpaceRay(double u, double v);
    abstract double getEyeLocationOnRay();

    abstract PolynomialOperation getXForSomeA();
    abstract PolynomialOperation getYForSomeA();
    abstract PolynomialOperation getZForSomeA();

    abstract Vector2d getUInterval();
    abstract Vector2d getVInterval();
    abstract double transformU(double u);
    abstract double transformV(double v);

    // decomposeTRS is translated together with AffineDecomposition.java,
    // because it depends directly on that source file's quaternion/stretch
    // representation rather than on the executable ray path.
}
