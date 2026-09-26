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

module de.mfo.jsurf.algebra.fast_row_substitutor_for_gradient;

import javax.vecmath : Point3d,Vector3d;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.expand : Expand;
import de.mfo.jsurf.algebra.xyz_polynomial : XYZPolynomial;
import de.mfo.jsurf.algebra.row_substitutor_for_gradient : RowSubstitutorForGradient;
import de.mfo.jsurf.algebra.column_substitutor_for_gradient : ColumnSubstitutorForGradient;
import de.mfo.jsurf.algebra.univariate_polynomial_vector3d : UnivariatePolynomialVector3d;
import de.mfo.jsurf.algebra.visitor : accept;
import de.mfo.jsurf.rendering.cpu.ray : Ray;
import de.mfo.jsurf.rendering.cpu.ray_creator : RayCreator;

class FastRowSubstitutorForGradient : RowSubstitutorForGradient {
    private XYZPolynomial gradientXPoly,gradientYPoly,gradientZPoly;
    private RayCreator rayCreator;

    this(PolynomialOperation gx,PolynomialOperation gy,PolynomialOperation gz,RayCreator rayCreator){
        this.rayCreator=rayCreator;auto e=new Expand();
        gradientXPoly=accept(gx,e);gradientYPoly=accept(gy,e);gradientZPoly=accept(gz,e);
    }

    override ColumnSubstitutorForGradient setV(double v){
        return new FastColumnSubstitutorForGradient(v);
    }

    private class FastColumnSubstitutorForGradient : ColumnSubstitutorForGradient {
        double v;
        this(double v){this.v=v;}
        override UnivariatePolynomialVector3d setU(double u){
            return new MyUnivariatePolynomialVector3d(rayCreator.createSurfaceSpaceRay(u,v));
        }
    }

    private class MyUnivariatePolynomialVector3d : UnivariatePolynomialVector3d {
        Ray ray;
        this(Ray ray){this.ray=ray;}
        override Vector3d setT(double t){
            const p=ray.at(t);
            return new Vector3d(
                gradientXPoly.evaluateXYZ(p.x,p.y,p.z),
                gradientYPoly.evaluateXYZ(p.x,p.y,p.z),
                gradientZPoly.evaluateXYZ(p.x,p.y,p.z));
        }
    }
}
