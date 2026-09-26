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

module de.mfo.jsurf.algebra.newton_interpolation_coefficient_calculator;
import de.mfo.jsurf.algebra.coefficient_calculator : CoefficientCalculator;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.degree_calculator : DegreeCalculator;
import de.mfo.jsurf.algebra.value_calculator : ValueCalculator;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.visitor : accept;

class NewtonInterpolationCoefficientCalculator : CoefficientCalculator {
    private PolynomialOperation polynomialOperation; private int degree,size;
    this(PolynomialOperation po){polynomialOperation=po;degree=accept(po,new DegreeCalculator());size=degree+1;}
    override UnivariatePolynomial calculateCoefficients(UnivariatePolynomial xPoly,UnivariatePolynomial yPoly,UnivariatePolynomial zPoly){
        auto x=new double[size];auto y=new double[size];auto basis=new double[size];auto vc=new ValueCalculator();
        for(int i=0;i<=degree;++i){
            x[i]=-1.0+(2.0*i)/degree;
            vc.setX(xPoly.getCoeff(0)+xPoly.getCoeff(1)*x[i]);
            vc.setY(yPoly.getCoeff(0)+yPoly.getCoeff(1)*x[i]);
            vc.setZ(zPoly.getCoeff(0)+zPoly.getCoeff(1)*x[i]);
            y[i]=accept(polynomialOperation,vc);
        }
        for(int i=1;i<=degree;++i)for(int j=degree;j>=i;--j)y[j]=(y[j]-y[j-1])/(x[j]-x[j-i]);
        auto a=new double[size];basis[degree]=1.0;a[0]=y[0];
        for(int i=1;i<=degree;++i){
            basis[degree-i]=0.0;a[i]=0.0;
            for(int j=degree-i;j<degree;++j)basis[j]=basis[j]-basis[j+1]*x[i-1];
            for(int j=0;j<=i;++j)a[j]+=basis[degree-i+j]*y[i];
        }
        return new UnivariatePolynomial(a);
    }
}
