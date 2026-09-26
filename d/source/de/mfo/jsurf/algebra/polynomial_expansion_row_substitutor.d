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

module de.mfo.jsurf.algebra.polynomial_expansion_row_substitutor;
import de.mfo.jsurf.algebra.row_substitutor : RowSubstitutor;
import de.mfo.jsurf.algebra.column_substitutor : ColumnSubstitutor;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.expand : Expand;
import de.mfo.jsurf.algebra.xyz_polynomial : XYZPolynomial;
import de.mfo.jsurf.algebra.xy_polynomial : XYPolynomial;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.visitor : accept;

class PolynomialExpansionRowSubstitutor : RowSubstitutor {
    private PolynomialOperation po;
    private XYZPolynomial xyzp,x3,y3,z3;
    this(PolynomialOperation po,PolynomialOperation rx,PolynomialOperation ry,PolynomialOperation rz){
        auto e=new Expand();this.po=po;xyzp=accept(po,e);x3=accept(rx,e);y3=accept(ry,e);z3=accept(rz,e);
    }
    private static class MyColumnSubstitutor : ColumnSubstitutor {
        private PolynomialOperation po; private XYZPolynomial xyzp; private XYPolynomial x2,y2,z2; private double v;
        this(PolynomialOperation po,XYZPolynomial xyzp,XYZPolynomial x3,XYZPolynomial y3,XYZPolynomial z3,double v){
            this.v=v;this.po=po;this.xyzp=xyzp;x2=x3.evaluateZ(v);y2=y3.evaluateZ(v);z2=z3.evaluateZ(v);
        }
        override UnivariatePolynomial setU(double u){
            auto x=x2.evaluateY(u);auto y=y2.evaluateY(u);auto z=z2.evaluateY(u);
            return xyzp.substitute(x,y,z);
        }
    }
    override ColumnSubstitutor setV(double v){return new MyColumnSubstitutor(po,xyzp,x3,y3,z3,v);}
}
