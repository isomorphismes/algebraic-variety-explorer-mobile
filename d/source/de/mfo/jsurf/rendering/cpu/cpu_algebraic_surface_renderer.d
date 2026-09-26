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

module de.mfo.jsurf.rendering.cpu.cpu_algebraic_surface_renderer;

import core.atomic : atomicStore;
import std.algorithm.comparison : min, max;
import std.parallelism : parallel, totalCPUs;

import javax.vecmath : Color3f;

import de.mfo.jsurf.algebra.closed_form_root_finder : ClosedFormRootFinder;
import de.mfo.jsurf.algebra.descartes_root_finder : DescartesRootFinder;
import de.mfo.jsurf.algebra.polynomial_expansion_coefficient_calculator
    : PolynomialExpansionCoefficientCalculator;
import de.mfo.jsurf.algebra.transformed_polynomial_row_substitutor
    : TransformedPolynomialRowSubstitutor;
import de.mfo.jsurf.algebra.transformed_polynomial_row_substitutor_for_gradient
    : TransformedPolynomialRowSubstitutorForGradient;

import de.mfo.jsurf.rendering.algebraic_surface_renderer
    : AlgebraicSurfaceRenderer;
import de.mfo.jsurf.rendering.light_products : LightProducts;
import de.mfo.jsurf.rendering.light_source : LightSource;
import de.mfo.jsurf.rendering.rendering_interrupted_exception
    : RenderingInterruptedException;

import de.mfo.jsurf.rendering.cpu.anti_aliasing_pattern
    : AntiAliasingPattern;
import de.mfo.jsurf.rendering.cpu.color_int : toArgb;
import de.mfo.jsurf.rendering.cpu.drawcall_static_data
    : DrawcallStaticData;
import de.mfo.jsurf.rendering.cpu.ray_creator : RayCreator;
import de.mfo.jsurf.rendering.cpu.rendering_task : RenderingTask;
import de.mfo.jsurf.rendering.cpu.clipping.clip_to_sphere
    : ClipToSphere;

class CPUAlgebraicSurfaceRenderer : AlgebraicSurfaceRenderer {
    enum AntiAliasingMode {
        SUPERSAMPLING,
        ADAPTIVE_SUPERSAMPLING
    }

    private AntiAliasingMode aaMode;
    private float aaThreshold;
    private AntiAliasingPattern aaPattern;
    private DrawcallStaticData currentDrawcall;

    this() {
        super();
        setAntiAliasingMode(
            AntiAliasingMode.ADAPTIVE_SUPERSAMPLING);
        setAntiAliasingPattern(
            AntiAliasingPattern.OG_4x4);
    }

    private DrawcallStaticData collectDrawCallStaticData(
        int[] colorBuffer,
        int width,
        int height)
    {
        auto data = new DrawcallStaticData();
        data.colorBuffer = colorBuffer;
        data.width = width;
        data.height = height;

        data.coefficientCalculator =
            new PolynomialExpansionCoefficientCalculator(
                getSurfaceExpression());

        if (getSurfaceTotalDegree() < 2)
            data.realRootFinder =
                new ClosedFormRootFinder();
        else
            data.realRootFinder =
                new DescartesRootFinder(false);

        data.frontAmbientColor =
            new Color3f(getFrontMaterial().getColor());
        data.frontAmbientColor.scale(
            getFrontMaterial().getAmbientIntensity());

        data.backAmbientColor =
            new Color3f(getBackMaterial().getColor());

        // Preserve the Java source exactly: back ambient uses the
        // front material's ambient intensity here.
        data.backAmbientColor.scale(
            getFrontMaterial().getAmbientIntensity());

        size_t lightCount;
        for (int i = 0; i < MAX_LIGHTS; ++i) {
            auto light = getLightSource(i);
            if (light !is null
                && light.getStatus() == LightSource.Status.ON)
                ++lightCount;
        }

        data.lightSources =
            new LightSource[lightCount];
        data.frontLightProducts =
            new LightProducts[lightCount];
        data.backLightProducts =
            new LightProducts[lightCount];

        size_t lightIndex;
        for (int i = 0; i < MAX_LIGHTS; ++i) {
            auto light = getLightSource(i);
            if (light !is null
                && light.getStatus() == LightSource.Status.ON)
            {
                data.lightSources[lightIndex] = light;
                data.frontLightProducts[lightIndex] =
                    new LightProducts(
                        light, getFrontMaterial());
                data.backLightProducts[lightIndex] =
                    new LightProducts(
                        light, getBackMaterial());
                ++lightIndex;
            }
        }

        data.backgroundColor = getBackgroundColor();
        data.antiAliasingPattern =
            getAntiAliasingPattern();
        data.antiAliasingThreshold = aaThreshold;

        data.rayCreator =
            RayCreator.createRayCreator(
                getTransform(),
                getSurfaceTransform(),
                getCamera(),
                width,
                height);

        data.rayClipper = new ClipToSphere();

        data.surfaceRowSubstitutor =
            new TransformedPolynomialRowSubstitutor(
                getSurfaceExpression(),
                data.rayCreator.getXForSomeA(),
                data.rayCreator.getYForSomeA(),
                data.rayCreator.getZForSomeA());

        data.gradientRowSubstitutor =
            new TransformedPolynomialRowSubstitutorForGradient(
                getGradientXExpression(),
                getGradientYExpression(),
                getGradientZExpression(),
                data.rayCreator.getXForSomeA(),
                data.rayCreator.getYForSomeA(),
                data.rayCreator.getZForSomeA());

        const background = toArgb(data.backgroundColor);
        data.colorBuffer[] = background;

        atomicStore(data.stopRequested, false);
        return data;
    }

    void setAntiAliasingMode(AntiAliasingMode mode) {
        aaMode = mode;
        aaThreshold =
            mode == AntiAliasingMode.SUPERSAMPLING
                ? 0.0f
                : 0.3f;
    }

    AntiAliasingMode getAntiAliasingMode() {
        return aaMode;
    }

    void setAntiAliasingPattern(
        AntiAliasingPattern pattern)
    {
        aaPattern = pattern;
    }

    AntiAliasingPattern getAntiAliasingPattern() {
        return aaPattern;
    }

    override void draw(
        int[] colorBuffer,
        int width,
        int height)
    {
        if (width == 0 || height == 0)
            return;

        auto data =
            collectDrawCallStaticData(
                colorBuffer, width, height);
        currentDrawcall = data;

        const processors =
            max(1, cast(int)totalCPUs);
        const xStep =
            width
            / min(
                width,
                max(2, processors));
        const yStep =
            height
            / min(height, 3);

        RenderingTask[] tasks;
        for (int x = 0; x < width; x += xStep)
            for (int y = 0; y < height; y += yStep)
                tasks ~=
                    new RenderingTask(
                        data,
                        x,
                        y,
                        min(x + xStep, width - 1),
                        min(y + yStep, height - 1));

        shared bool success = true;

        // Java uses its own fixed low-priority ExecutorService.
        // D uses the standard task pool for the same independent
        // tile execution; the rendering/task boundaries stay intact.
        foreach (task; parallel(tasks)) {
            if (!task.call())
                atomicStore(success, false);
        }

        if (!success)
            throw new RenderingInterruptedException(
                "Rendering interrupted");
    }

    void stopDrawing() {
        auto data = currentDrawcall;
        if (data !is null)
            atomicStore(data.stopRequested, true);
    }

    void shutdown() {
        stopDrawing();
    }
}

unittest {
    import std.algorithm.searching : count;
    import de.mfo.jsurf.rendering.cpu.anti_aliasing_pattern
        : AntiAliasingPattern;

    auto renderer =
        new CPUAlgebraicSurfaceRenderer();
    renderer.setSurfaceFamily(
        "x^2+y^2+z^2-0.64");
    renderer.setAntiAliasingPattern(
        AntiAliasingPattern.OG_1x1);

    auto probePixels = new int[64 * 64];
    auto probe = renderer.collectDrawCallStaticData(probePixels, 64, 64);
    auto centerSurface = probe.surfaceRowSubstitutor.setV(0.0).setU(0.0);
    import std.math : abs, isNaN;
    assert(abs(centerSurface.evaluateAt(0.8)) < 1.0e-10,
        "transformed center ray polynomial is wrong");
    const centerRoot = probe.realRootFinder.findFirstRootIn(centerSurface, 0.0, 1.0);
    assert(!isNaN(centerRoot), "center ray root is missing");
    assert(abs(centerRoot - 0.8) < 1.0e-5, "center ray root is wrong");

    auto pixels = new int[64 * 64];
    renderer.draw(pixels, 64, 64);

    const background =
        toArgb(renderer.getBackgroundColor());
    size_t foreground;
    foreach (pixel; pixels)
        if (pixel != background)
            ++foreground;

    import std.conv : to;
    assert(foreground > 0, "foreground=" ~ foreground.to!string);
    assert(foreground < pixels.length, "foreground=" ~ foreground.to!string);
}
