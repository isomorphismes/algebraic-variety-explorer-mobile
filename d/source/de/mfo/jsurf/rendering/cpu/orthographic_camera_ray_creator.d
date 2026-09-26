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

module de.mfo.jsurf.rendering.cpu.orthographic_camera_ray_creator;

import javax.vecmath : Matrix4d, Point3d, Vector2d, Vector3d;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.polynomial_addition : PolynomialAddition;
import de.mfo.jsurf.algebra.polynomial_multiplication : PolynomialMultiplication;
import de.mfo.jsurf.algebra.polynomial_variable : PolynomialVariable;
import de.mfo.jsurf.algebra.double_value : DoubleValue;
import de.mfo.jsurf.rendering.camera : Camera;
import de.mfo.jsurf.rendering.cpu.helper : interpolate2D;
import de.mfo.jsurf.rendering.cpu.ray : Ray;
import de.mfo.jsurf.rendering.cpu.ray_creator : RayCreator;

class OrthographicCameraRayCreator : RayCreator {
    private Point3d rayOrigin;
    private Vector3d rayDir, du, dv;
    private Point3d surfaceRayOrigin;
    private Vector3d surfaceRayDir, surfaceDu, surfaceDv;
    private Point3d clippingRayOrigin;
    private Vector3d clippingRayDir, clippingDu, clippingDv;
    private double uscale, vscale, uoffset, voffset;
    private double eyeLocationOnRay;

    this(
        Matrix4d transformMatrix,
        Matrix4d surfaceTransformMatrix,
        Camera cam,
        double width,
        double height)
    {
        super(transformMatrix, surfaceTransformMatrix, cam);

        dv = new Vector3d(0.0, cam.getHeight() / 2.0, 0.0);
        du = new Vector3d((dv.y * width) / height, 0.0, 0.0);
        rayDir = new Vector3d(0.0, 0.0, -1.0);

        surfaceDu = cameraSpaceToSurfaceSpace(du);
        surfaceDv = cameraSpaceToSurfaceSpace(dv);

        uscale = surfaceDu.length();
        vscale = surfaceDv.length();
        surfaceDu.scale(1.0 / uscale);
        surfaceDv.scale(1.0 / vscale);

        surfaceRayDir = cameraSpaceToSurfaceSpace(rayDir);
        const rayDirScale = surfaceRayDir.length();
        surfaceRayDir.scale(1.0 / rayDirScale);

        surfaceRayOrigin = cameraSpaceToSurfaceSpace(new Point3d(0.0, 0.0, 0.0));

        const planeDistance =
            surfaceRayDir.dot(new Vector3d(surfaceRayOrigin));

        auto projectedCameraOrigin = new Vector3d();
        projectedCameraOrigin.scaleAdd(
            -planeDistance, surfaceRayDir, surfaceRayOrigin);

        uoffset = projectedCameraOrigin.dot(surfaceDu);
        voffset = projectedCameraOrigin.dot(surfaceDv);

        surfaceRayOrigin = new Point3d(0.0, 0.0, 0.0);

        du.scale(1.0 / uscale);
        dv.scale(1.0 / vscale);
        rayDir.scale(1.0 / rayDirScale);

        rayOrigin = new Point3d(rayDir);
        rayOrigin.scale(-planeDistance);
        rayOrigin.scaleAdd(uoffset, du, rayOrigin);
        rayOrigin.scaleAdd(voffset, dv, rayOrigin);

        clippingRayOrigin = cameraSpaceToClippingSpace(rayOrigin);
        clippingDu = cameraSpaceToClippingSpace(du);
        clippingDv = cameraSpaceToClippingSpace(dv);
        clippingRayDir = cameraSpaceToClippingSpace(rayDir);

        eyeLocationOnRay = planeDistance;
    }

    override Ray createCameraSpaceRay(double u, double v) {
        return new Ray(interpolate2D(rayOrigin, du, dv, u, v), rayDir);
    }

    override Ray createSurfaceSpaceRay(double u, double v) {
        return new Ray(
            interpolate2D(surfaceRayOrigin, surfaceDu, surfaceDv, u, v),
            surfaceRayDir);
    }

    override Ray createClippingSpaceRay(double u, double v) {
        return new Ray(
            interpolate2D(clippingRayOrigin, clippingDu, clippingDv, u, v),
            clippingRayDir);
    }

    override double getEyeLocationOnRay() {
        return eyeLocationOnRay;
    }

    private PolynomialOperation coordinate(
        double origin,
        double dvComponent,
        double duComponent,
        double direction)
    {
        PolynomialOperation result = new DoubleValue(origin);
        result = new PolynomialAddition(
            result,
            new PolynomialMultiplication(
                new PolynomialVariable(PolynomialVariable.Var.z),
                new DoubleValue(dvComponent)));
        result = new PolynomialAddition(
            result,
            new PolynomialMultiplication(
                new PolynomialVariable(PolynomialVariable.Var.y),
                new DoubleValue(duComponent)));
        result = new PolynomialAddition(
            result,
            new PolynomialMultiplication(
                new PolynomialVariable(PolynomialVariable.Var.x),
                new DoubleValue(direction)));
        return result;
    }

    override PolynomialOperation getXForSomeA() {
        return coordinate(
            surfaceRayOrigin.x, surfaceDv.x, surfaceDu.x, surfaceRayDir.x);
    }

    override PolynomialOperation getYForSomeA() {
        return coordinate(
            surfaceRayOrigin.y, surfaceDv.y, surfaceDu.y, surfaceRayDir.y);
    }

    override PolynomialOperation getZForSomeA() {
        return coordinate(
            surfaceRayOrigin.z, surfaceDv.z, surfaceDu.z, surfaceRayDir.z);
    }

    override Vector2d getUInterval() {
        return new Vector2d(uoffset - uscale, uoffset + uscale);
    }

    override Vector2d getVInterval() {
        return new Vector2d(voffset - vscale, voffset + vscale);
    }

    override double transformU(double u) {
        return uoffset + uscale * (2.0 * u - 1.0);
    }

    override double transformV(double v) {
        return voffset + vscale * (2.0 * v - 1.0);
    }
}
