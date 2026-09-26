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

module de.mfo.jsurf.rendering.cpu.drawcall_static_data;

import javax.vecmath : Color3f;
import de.mfo.jsurf.algebra.coefficient_calculator : CoefficientCalculator;
import de.mfo.jsurf.algebra.row_substitutor : RowSubstitutor;
import de.mfo.jsurf.algebra.row_substitutor_for_gradient : RowSubstitutorForGradient;
import de.mfo.jsurf.algebra.real_root_finder : RealRootFinder;
import de.mfo.jsurf.rendering.light_source : LightSource;
import de.mfo.jsurf.rendering.light_products : LightProducts;
import de.mfo.jsurf.rendering.cpu.anti_aliasing_pattern : AntiAliasingPattern;
import de.mfo.jsurf.rendering.cpu.ray_creator : RayCreator;
import de.mfo.jsurf.rendering.cpu.clipping.clipper : Clipper;

class DrawcallStaticData {
    int[] colorBuffer;
    int width;
    int height;

    CoefficientCalculator coefficientCalculator;
    RowSubstitutor surfaceRowSubstitutor;
    RowSubstitutorForGradient gradientRowSubstitutor;
    RealRootFinder realRootFinder;

    LightSource[] lightSources;
    Color3f frontAmbientColor;
    Color3f backAmbientColor;
    LightProducts[] frontLightProducts;
    LightProducts[] backLightProducts;
    Color3f backgroundColor;

    AntiAliasingPattern antiAliasingPattern;
    float antiAliasingThreshold;

    RayCreator rayCreator;
    Clipper rayClipper;

    shared bool stopRequested;
}
