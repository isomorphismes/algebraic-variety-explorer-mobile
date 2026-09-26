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

module de.mfo.jsurf.algebra.univariate_polynomial_expansion_coefficient_calculator;
import de.mfo.jsurf.algebra.coefficient_calculator : CoefficientCalculator;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.univariate_polynomial_expansion : UnivariatePolynomialExpansion;
import de.mfo.jsurf.algebra.visitor : accept;

class UnivariatePolynomialExpansionCoefficientCalculator : CoefficientCalculator {
    private PolynomialOperation polynomialOperation;
    this(PolynomialOperation po){polynomialOperation=po;}
    override UnivariatePolynomial calculateCoefficients(UnivariatePolynomial x,UnivariatePolynomial y,UnivariatePolynomial z){
        return accept(polynomialOperation,new UnivariatePolynomialExpansion(x,y,z));
    }
}
