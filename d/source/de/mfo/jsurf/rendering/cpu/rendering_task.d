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

module de.mfo.jsurf.rendering.cpu.rendering_task;

import core.atomic : atomicLoad;
import std.algorithm.comparison : max;
import std.math : isNaN, pow;

import javax.vecmath : Color3f, Point3d, Vector3d, Vector3f;

import de.mfo.jsurf.algebra.column_substitutor : ColumnSubstitutor;
import de.mfo.jsurf.algebra.column_substitutor_for_gradient : ColumnSubstitutorForGradient;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.univariate_polynomial_vector3d : UnivariatePolynomialVector3d;
import de.mfo.jsurf.rendering.light_products : LightProducts;
import de.mfo.jsurf.rendering.light_source : LightSource;
import de.mfo.jsurf.rendering.rendering_interrupted_exception : RenderingInterruptedException;
import de.mfo.jsurf.rendering.cpu.anti_aliasing_pattern : AntiAliasingPattern;
import de.mfo.jsurf.rendering.cpu.color_int : toArgb;
import de.mfo.jsurf.rendering.cpu.drawcall_static_data : DrawcallStaticData;
import de.mfo.jsurf.rendering.cpu.ray : Ray;

class RenderingTask {
    private int xStart, yStart, xEnd, yEnd;
    private DrawcallStaticData dcsd;

    this(
        DrawcallStaticData dcsd,
        int xStart,
        int yStart,
        int xEnd,
        int yEnd)
    {
        this.dcsd = dcsd;
        this.xStart = xStart;
        this.yStart = yStart;
        this.xEnd = xEnd;
        this.yEnd = yEnd;
    }

    bool call() {
        try {
            render();
            return true;
        } catch (RenderingInterruptedException) {
            return false;
        } catch (Throwable) {
            return false;
        }
    }

    private class ColumnSubstitutorPair {
        ColumnSubstitutor scs;
        ColumnSubstitutorForGradient gcs;
        this(ColumnSubstitutor scs, ColumnSubstitutorForGradient gcs) {
            this.scs = scs;
            this.gcs = gcs;
        }
    }

    protected void render() {
        if (dcsd.antiAliasingPattern is AntiAliasingPattern.OG_1x1) {
            const internalWidth = xEnd - xStart + 1;
            const internalHeight = yEnd - yStart + 1;
            const uStart =
                dcsd.rayCreator.transformU(
                    xStart / (dcsd.width - 1.0));
            const vStart =
                dcsd.rayCreator.transformV(
                    yStart / (dcsd.height - 1.0));
            const uIncrement =
                (dcsd.rayCreator.getUInterval().y
                    - dcsd.rayCreator.getUInterval().x)
                / (dcsd.width - 1.0);
            const vIncrement =
                (dcsd.rayCreator.getVInterval().y
                    - dcsd.rayCreator.getVInterval().x)
                / (dcsd.height - 1.0);

            for (int y = 0; y < internalHeight; ++y) {
                const v = vStart + y * vIncrement;
                auto scs = dcsd.surfaceRowSubstitutor.setV(v);
                auto gcs = dcsd.gradientRowSubstitutor.setV(v);

                for (int x = 0; x < internalWidth; ++x) {
                    checkInterrupted();
                    const u = uStart + x * uIncrement;
                    dcsd.colorBuffer[
                        dcsd.width * (yStart + y) + xStart + x] =
                        toArgb(tracePolynomial(scs, gcs, u, v));
                }
            }
            return;
        }

        const internalWidth = xEnd - xStart + 2;
        const internalHeight = yEnd - yStart + 2;
        auto internalColorBuffer =
            new Color3f[internalWidth * internalHeight];

        ColumnSubstitutor scs;
        ColumnSubstitutorForGradient gcs;
        ColumnSubstitutorPair[double] pairs;

        const uStart =
            dcsd.rayCreator.transformU(
                (xStart - 0.5) / (dcsd.width - 1.0));
        const vStart =
            dcsd.rayCreator.transformV(
                (yStart - 0.5) / (dcsd.height - 1.0));
        const uIncrement =
            (dcsd.rayCreator.getUInterval().y
                - dcsd.rayCreator.getUInterval().x)
            / (dcsd.width - 1.0);
        const vIncrement =
            (dcsd.rayCreator.getVInterval().y
                - dcsd.rayCreator.getVInterval().x)
            / (dcsd.height - 1.0);

        double v = 0.0;
        for (int y = 0; y < internalHeight; ++y) {
            pairs = null;
            pairs[v] = new ColumnSubstitutorPair(scs, gcs);

            v = vStart + y * vIncrement;
            scs = dcsd.surfaceRowSubstitutor.setV(v);
            gcs = dcsd.gradientRowSubstitutor.setV(v);
            pairs[v] = new ColumnSubstitutorPair(scs, gcs);

            for (int x = 0; x < internalWidth; ++x) {
                checkInterrupted();
                const u = uStart + x * uIncrement;

                internalColorBuffer[y * internalWidth + x] =
                    tracePolynomial(scs, gcs, u, v);

                if (x > 0 && y > 0) {
                    auto upperLeft =
                        internalColorBuffer[
                            y * internalWidth + x - 1];
                    auto upperRight =
                        internalColorBuffer[
                            y * internalWidth + x];
                    auto lowerLeft =
                        internalColorBuffer[
                            (y - 1) * internalWidth + x - 1];
                    auto lowerRight =
                        internalColorBuffer[
                            (y - 1) * internalWidth + x];

                    dcsd.colorBuffer[
                        (yStart + y - 1) * dcsd.width
                            + (xStart + x - 1)] =
                        toArgb(
                            antiAliasPixel(
                                u - uIncrement,
                                v - vIncrement,
                                uIncrement,
                                vIncrement,
                                dcsd.antiAliasingPattern,
                                upperLeft,
                                upperRight,
                                lowerLeft,
                                lowerRight,
                                pairs));
                }
            }
        }
    }

    private void checkInterrupted() {
        if (atomicLoad(dcsd.stopRequested))
            throw new RenderingInterruptedException();
    }

    private Color3f antiAliasPixel(
        double lowerLeftU,
        double lowerLeftV,
        double uIncrement,
        double vIncrement,
        AntiAliasingPattern pattern,
        Color3f upperLeft,
        Color3f upperRight,
        Color3f lowerLeft,
        Color3f lowerRight,
        ref ColumnSubstitutorPair[double] pairs)
    {
        Color3f finalColor;
        const thresholdSquared =
            dcsd.antiAliasingThreshold
            * dcsd.antiAliasingThreshold;

        const needsRefinement =
            pattern !is AntiAliasingPattern.OG_2x2
            && (
                colorDiffSqr(upperLeft, upperRight)
                    >= thresholdSquared
                || colorDiffSqr(upperLeft, lowerLeft)
                    >= thresholdSquared
                || colorDiffSqr(upperLeft, lowerRight)
                    >= thresholdSquared
                || colorDiffSqr(upperRight, lowerLeft)
                    >= thresholdSquared
                || colorDiffSqr(upperRight, lowerRight)
                    >= thresholdSquared
                || colorDiffSqr(lowerLeft, lowerRight)
                    >= thresholdSquared);

        if (needsRefinement) {
            finalColor = new Color3f();

            foreach (samplingPoint; pattern) {
                checkInterrupted();

                Color3f sampleColor;
                if (samplingPoint.getU() == 0.0f
                    && samplingPoint.getV() == 0.0f)
                {
                    sampleColor = lowerLeft;
                } else if (
                    samplingPoint.getU() == 0.0f
                    && samplingPoint.getV() == 1.0f)
                {
                    sampleColor = upperLeft;
                } else if (
                    samplingPoint.getU() == 1.0f
                    && samplingPoint.getV() == 1.0f)
                {
                    sampleColor = upperRight;
                } else if (
                    samplingPoint.getU() == 1.0f
                    && samplingPoint.getV() == 0.0f)
                {
                    sampleColor = lowerRight;
                } else {
                    const v =
                        lowerLeftV
                        + samplingPoint.getV() * vIncrement;
                    const u =
                        lowerLeftU
                        + samplingPoint.getU() * uIncrement;

                    auto existing = v in pairs;
                    ColumnSubstitutorPair pair;
                    if (existing is null) {
                        pair =
                            new ColumnSubstitutorPair(
                                dcsd.surfaceRowSubstitutor.setV(v),
                                dcsd.gradientRowSubstitutor.setV(v));
                        pairs[v] = pair;
                    } else {
                        pair = *existing;
                    }

                    sampleColor =
                        tracePolynomial(
                            pair.scs, pair.gcs, u, v);
                }

                finalColor.scaleAdd(
                    samplingPoint.getWeight(),
                    sampleColor,
                    finalColor);
            }
        } else {
            finalColor = new Color3f(upperLeft);
            finalColor.add(upperRight);
            finalColor.add(lowerLeft);
            finalColor.add(lowerRight);
            finalColor.scale(0.25f);
        }

        finalColor.clamp(0.0f, 1.0f);
        return finalColor;
    }

    private Color3f tracePolynomial(
        ColumnSubstitutor scs,
        ColumnSubstitutorForGradient gcs,
        double u,
        double v)
    {
        auto ray = dcsd.rayCreator.createCameraSpaceRay(u, v);
        auto clippingRay =
            dcsd.rayCreator.createClippingSpaceRay(u, v);
        auto surfaceRay =
            dcsd.rayCreator.createSurfaceSpaceRay(u, v);

        auto eye =
            ray.at(dcsd.rayCreator.getEyeLocationOnRay());
        UnivariatePolynomialVector3d gradientPolynomials;

        auto intervals =
            dcsd.rayClipper.clipRay(clippingRay);

        if (intervals.length != 0) {
            auto surfacePolynomial = scs.setU(u);

            foreach (interval; intervals) {
                const eyeLocation =
                    dcsd.rayCreator.getEyeLocationOnRay();

                if (interval.x < eyeLocation
                    && eyeLocation < interval.y)
                {
                    interval.x = max(
                        interval.x, eyeLocation);
                }

                const hit =
                    dcsd.realRootFinder.findFirstRootIn(
                        surfacePolynomial,
                        interval.x,
                        interval.y);

                if (isNaN(hit))
                    continue;

                if (dcsd.rayClipper.clipPoint(
                        surfaceRay.at(hit), true))
                {
                    if (gradientPolynomials is null)
                        gradientPolynomials = gcs.setU(u);

                    auto surfaceNormal =
                        gradientPolynomials.setT(hit);
                    auto cameraNormal =
                        dcsd.rayCreator
                            .surfaceSpaceNormalToCameraSpaceNormal(
                                surfaceNormal);

                    return shade(
                        ray.at(hit),
                        cameraNormal,
                        eye);
                }
            }
        }

        return dcsd.backgroundColor;
    }

    private float colorDiffSqr(Color3f c1, Color3f c2) {
        auto difference = new Vector3f(c1);
        difference.sub(c2);
        return difference.dot(difference);
    }

    protected bool intersectPolynomial(
        UnivariatePolynomial p,
        double rayStart,
        double rayEnd,
        double[] hit)
    {
        hit[0] =
            dcsd.realRootFinder.findFirstRootIn(
                p, rayStart, rayEnd);
        return !isNaN(hit[0]);
    }

    protected bool intersect(
        Ray r,
        double rayStart,
        double rayEnd,
        double[] hit)
    {
        auto x =
            new UnivariatePolynomial(r.o.x, r.d.x);
        auto y =
            new UnivariatePolynomial(r.o.y, r.d.y);
        auto z =
            new UnivariatePolynomial(r.o.z, r.d.z);

        auto p =
            dcsd.coefficientCalculator
                .calculateCoefficients(x, y, z)
                .shrink();

        hit[0] =
            dcsd.realRootFinder.findFirstRootIn(
                p, rayStart, rayEnd);
        return !isNaN(hit[0]);
    }

    protected Color3f shade(
        Point3d p,
        Vector3d n,
        Point3d eye)
    {
        const normalLength = cast(float)n.length();
        if (normalLength != 0.0f)
            n.scale(1.0f / normalLength);

        auto view = new Vector3d(eye);
        view.sub(p);
        view.normalize();

        if (n.dot(view) > 0.0)
            return shadeWithMaterial(
                p,
                view,
                n,
                dcsd.frontAmbientColor,
                dcsd.frontLightProducts);

        n.negate();
        return shadeWithMaterial(
            p,
            view,
            n,
            dcsd.backAmbientColor,
            dcsd.backLightProducts);
    }

    protected Color3f shadeWithMaterial(
        Point3d hitPoint,
        Vector3d view,
        Vector3d normal,
        Color3f ambientColor,
        LightProducts[] lightProducts)
    {
        auto lightDirection = new Vector3d();
        auto halfVector = new Vector3d();
        auto color = new Color3f(ambientColor);

        foreach (i, lightSource; dcsd.lightSources) {
            lightDirection.sub(
                lightSource.getPosition(), hitPoint);
            lightDirection.normalize();

            const lambertTerm =
                cast(float)normal.dot(lightDirection);

            if (lambertTerm > 0.0f) {
                color.scaleAdd(
                    lambertTerm,
                    lightProducts[i].getDiffuseProduct(),
                    color);

                halfVector.add(lightDirection, view);
                halfVector.normalize();

                color.scaleAdd(
                    cast(float)pow(
                        max(
                            0.0,
                            normal.dot(halfVector)),
                        lightProducts[i]
                            .getMaterial()
                            .getShininess()),
                    lightProducts[i].getSpecularProduct(),
                    color);
            }
        }

        color.clampMax(1.0f);
        return color;
    }
}
