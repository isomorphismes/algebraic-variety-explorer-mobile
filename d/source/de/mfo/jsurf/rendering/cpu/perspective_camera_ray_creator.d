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

module de.mfo.jsurf.rendering.cpu.perspective_camera_ray_creator;

import std.math : PI, tan;
import javax.vecmath : Matrix4d, Point3d, Vector2d, Vector3d;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.polynomial_addition : PolynomialAddition;
import de.mfo.jsurf.algebra.polynomial_subtraction : PolynomialSubtraction;
import de.mfo.jsurf.algebra.polynomial_multiplication : PolynomialMultiplication;
import de.mfo.jsurf.algebra.polynomial_variable : PolynomialVariable;
import de.mfo.jsurf.algebra.double_value : DoubleValue;
import de.mfo.jsurf.rendering.camera : Camera;
import de.mfo.jsurf.rendering.cpu.helper : interpolate1D, interpolate2D;
import de.mfo.jsurf.rendering.cpu.ray : Ray;
import de.mfo.jsurf.rendering.cpu.ray_creator : RayCreator;

class PerspectiveCameraRayCreator : RayCreator {
    private Point3d upperLeft;
    private Vector3d dx, dy;
    private Point3d clippingUpperLeft;
    private Vector3d clippingDx, clippingDy;
    private Point3d surfaceUpperLeft;
    private Vector3d surfaceDx, surfaceDy;
    private Point3d rayOrigin, clippingRayOrigin, surfaceRayOrigin;
    private double bestStart;
    private double scale;
    private PolynomialOperation optimizedSubstitute;

    this(
        Matrix4d transformMatrix,
        Matrix4d surfaceTransformMatrix,
        Camera cam,
        double width,
        double height)
    {
        super(transformMatrix, surfaceTransformMatrix, cam);

        upperLeft = new Point3d();
        upperLeft.y = tan(PI / 180.0 * (cam.getFoVY() / 2.0));
        upperLeft.x = (upperLeft.y * width) / height;
        upperLeft.z = -1.0;

        dx = new Vector3d(2.0 * upperLeft.x, 0.0, 0.0);
        dy = new Vector3d(0.0, 2.0 * upperLeft.y, 0.0);

        clippingUpperLeft = cameraSpaceToClippingSpace(upperLeft);
        clippingDx = cameraSpaceToClippingSpace(dx);
        clippingDy = cameraSpaceToClippingSpace(dy);

        surfaceUpperLeft = cameraSpaceToSurfaceSpace(upperLeft);
        surfaceDx = cameraSpaceToSurfaceSpace(dx);
        surfaceDy = cameraSpaceToSurfaceSpace(dy);

        rayOrigin = new Point3d(0.0, 0.0, 0.0);
        clippingRayOrigin = cameraSpaceToClippingSpace(rayOrigin);
        surfaceRayOrigin = cameraSpaceToSurfaceSpace(rayOrigin);

        auto clippingRayDir =
            new Vector3d(interpolate2D(
                clippingUpperLeft, clippingDx, clippingDy, 0.5, 0.5));
        clippingRayDir.sub(clippingRayOrigin);

        auto surfaceRayDir =
            new Vector3d(interpolate2D(
                surfaceUpperLeft, surfaceDx, surfaceDy, 0.5, 0.5));
        surfaceRayDir.sub(surfaceRayOrigin);

        bestStart =
            -new Vector3d(clippingUpperLeft).dot(clippingRayDir)
            / clippingRayDir.dot(clippingRayDir);
        scale = 0.5 * surfaceRayDir.length();

        optimizedSubstitute =
            new PolynomialMultiplication(
                new DoubleValue(scale),
                new PolynomialVariable(PolynomialVariable.Var.x));
        optimizedSubstitute =
            new PolynomialAddition(
                optimizedSubstitute,
                new DoubleValue(bestStart));
    }

    private Ray optimizedRay(
        Point3d origin,
        Point3d upperLeft,
        Vector3d dx,
        Vector3d dy,
        double u,
        double v)
    {
        auto direction =
            new Vector3d(interpolate2D(upperLeft, dx, dy, u, v));
        direction.sub(origin);
        auto result = new Ray(origin, direction);
        result.o = interpolate1D(result.o, result.d, bestStart);
        result.d.scale(scale);
        return result;
    }

    override Ray createCameraSpaceRay(double u, double v) {
        return optimizedRay(rayOrigin, upperLeft, dx, dy, u, v);
    }

    override Ray createSurfaceSpaceRay(double u, double v) {
        return optimizedRay(
            surfaceRayOrigin, surfaceUpperLeft, surfaceDx, surfaceDy, u, v);
    }

    override Ray createClippingSpaceRay(double u, double v) {
        return optimizedRay(
            clippingRayOrigin, clippingUpperLeft, clippingDx, clippingDy, u, v);
    }

    override double getEyeLocationOnRay() {
        return -bestStart;
    }

    private PolynomialOperation coordinate(
        double upperLeftComponent,
        double dyComponent,
        double dxComponent,
        double originComponent)
    {
        PolynomialOperation result =
            new DoubleValue(upperLeftComponent);
        result =
            new PolynomialAddition(
                result,
                new PolynomialMultiplication(
                    new PolynomialVariable(PolynomialVariable.Var.z),
                    new DoubleValue(dyComponent)));
        result =
            new PolynomialAddition(
                result,
                new PolynomialMultiplication(
                    new PolynomialVariable(PolynomialVariable.Var.y),
                    new DoubleValue(dxComponent)));
        result =
            new PolynomialSubtraction(
                result,
                new DoubleValue(originComponent));
        result =
            new PolynomialMultiplication(
                result,
                optimizedSubstitute);
        result =
            new PolynomialAddition(
                result,
                new DoubleValue(originComponent));
        return result;
    }

    override PolynomialOperation getXForSomeA() {
        return coordinate(
            surfaceUpperLeft.x,
            surfaceDy.x,
            surfaceDx.x,
            surfaceRayOrigin.x);
    }

    override PolynomialOperation getYForSomeA() {
        return coordinate(
            surfaceUpperLeft.y,
            surfaceDy.y,
            surfaceDx.y,
            surfaceRayOrigin.y);
    }

    override PolynomialOperation getZForSomeA() {
        return coordinate(
            surfaceUpperLeft.z,
            surfaceDy.z,
            surfaceDx.z,
            surfaceRayOrigin.z);
    }

    override Vector2d getUInterval() {
        return new Vector2d(0.0, 1.0);
    }

    override Vector2d getVInterval() {
        return new Vector2d(0.0, 1.0);
    }

    override double transformU(double u) {
        return u;
    }

    override double transformV(double v) {
        return v;
    }
}
