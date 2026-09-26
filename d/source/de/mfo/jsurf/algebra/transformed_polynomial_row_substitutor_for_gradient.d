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

module de.mfo.jsurf.algebra.transformed_polynomial_row_substitutor_for_gradient;
import javax.vecmath : Vector3d;
import de.mfo.jsurf.algebra.row_substitutor : RowSubstitutor;
import de.mfo.jsurf.algebra.row_substitutor_for_gradient : RowSubstitutorForGradient;
import de.mfo.jsurf.algebra.column_substitutor : ColumnSubstitutor;
import de.mfo.jsurf.algebra.column_substitutor_for_gradient : ColumnSubstitutorForGradient;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.univariate_polynomial_vector3d : UnivariatePolynomialVector3d;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.expand : Expand;
import de.mfo.jsurf.algebra.xyz_polynomial : XYZPolynomial;
import de.mfo.jsurf.algebra.transformed_polynomial_row_substitutor : TransformedPolynomialRowSubstitutor;
import de.mfo.jsurf.algebra.visitor : accept;

class TransformedPolynomialRowSubstitutorForGradient : RowSubstitutorForGradient {
    private TransformedPolynomialRowSubstitutor px,py,pz;
    this(PolynomialOperation pox,PolynomialOperation poy,PolynomialOperation poz,PolynomialOperation rx,PolynomialOperation ry,PolynomialOperation rz){
        auto e=new Expand();
        XYZPolynomial x=accept(rx,e),y=accept(ry,e),z=accept(rz,e);
        px=new TransformedPolynomialRowSubstitutor(accept(pox,e),x,y,z);
        py=new TransformedPolynomialRowSubstitutor(accept(poy,e),x,y,z);
        pz=new TransformedPolynomialRowSubstitutor(accept(poz,e),x,y,z);
    }

    private class GradientPolynomialVector : UnivariatePolynomialVector3d {
        private UnivariatePolynomial px,py,pz;
        this(UnivariatePolynomial px,UnivariatePolynomial py,UnivariatePolynomial pz){this.px=px;this.py=py;this.pz=pz;}
        override Vector3d setT(double t){return new Vector3d(px.evaluateAt(t),py.evaluateAt(t),pz.evaluateAt(t));}
    }

    private class GradientColumn : ColumnSubstitutorForGradient {
        private ColumnSubstitutor cx,cy,cz;
        this(RowSubstitutor x,RowSubstitutor y,RowSubstitutor z,double v){cx=x.setV(v);cy=y.setV(v);cz=z.setV(v);}
        override UnivariatePolynomialVector3d setU(double u){return new GradientPolynomialVector(cx.setU(u),cy.setU(u),cz.setU(u));}
    }

    override ColumnSubstitutorForGradient setV(double v){return new GradientColumn(px,py,pz,v);}
}
