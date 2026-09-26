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

module de.mfo.jsurf.algebra.transformed_polynomial_row_substitutor;
import de.mfo.jsurf.algebra.row_substitutor : RowSubstitutor;
import de.mfo.jsurf.algebra.column_substitutor : ColumnSubstitutor;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.expand : Expand;
import de.mfo.jsurf.algebra.xyz_polynomial : XYZPolynomial;
import de.mfo.jsurf.algebra.xy_polynomial : XYPolynomial;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.visitor : accept;

class TransformedPolynomialRowSubstitutor : RowSubstitutor {
    private XYZPolynomial tuvPolynomial;
    this(PolynomialOperation po,PolynomialOperation rx,PolynomialOperation ry,PolynomialOperation rz){
        auto e=new Expand();auto p=accept(po,e);auto x=accept(rx,e);auto y=accept(ry,e);auto z=accept(rz,e);
        tuvPolynomial=p.substitute(x,y,z);
    }
    this(XYZPolynomial p,XYZPolynomial rx,XYZPolynomial ry,XYZPolynomial rz){tuvPolynomial=p.substitute(rx,ry,rz);}
    private static class MyColumnSubstitutor : ColumnSubstitutor {
        private XYPolynomial tuPolynomial; private double v;
        this(XYZPolynomial tvu,double v){this.v=v;tuPolynomial=tvu.evaluateZ(v);}
        override UnivariatePolynomial setU(double u){return tuPolynomial.evaluateY(u);}
    }
    override ColumnSubstitutor setV(double v){return new MyColumnSubstitutor(tuvPolynomial,v);}
}
