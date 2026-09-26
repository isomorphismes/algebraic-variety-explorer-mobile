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

module de.mfo.jsurf.algebra.fast_gradient_calculator;
import javax.vecmath : Point3d,Point3f,Vector3d,Vector3f;
import de.mfo.jsurf.algebra.gradient_calculator : GradientCalculator;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.expand : Expand;
import de.mfo.jsurf.algebra.xyz_polynomial : XYZPolynomial;
import de.mfo.jsurf.algebra.visitor : accept;

class FastGradientCalculator : GradientCalculator {
    private XYZPolynomial gradientXPoly,gradientYPoly,gradientZPoly;
    this(PolynomialOperation x,PolynomialOperation y,PolynomialOperation z){
        auto e=new Expand();
        gradientXPoly=accept(x,e);gradientYPoly=accept(y,e);gradientZPoly=accept(z,e);
    }
    override Vector3d calculateGradient(Point3d p){
        return new Vector3d(gradientXPoly.evaluateXYZ(p.x,p.y,p.z),gradientYPoly.evaluateXYZ(p.x,p.y,p.z),gradientZPoly.evaluateXYZ(p.x,p.y,p.z));
    }
    override Vector3f calculateGradient(Point3f p){
        auto g=calculateGradient(new Point3d(p.x,p.y,p.z));
        return new Vector3f(cast(float)g.x,cast(float)g.y,cast(float)g.z);
    }
}
