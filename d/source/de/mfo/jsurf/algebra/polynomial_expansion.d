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

module de.mfo.jsurf.algebra.polynomial_expansion;

import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.polynomial_addition : PolynomialAddition;
import de.mfo.jsurf.algebra.polynomial_subtraction : PolynomialSubtraction;
import de.mfo.jsurf.algebra.polynomial_multiplication : PolynomialMultiplication;
import de.mfo.jsurf.algebra.polynomial_power : PolynomialPower;
import de.mfo.jsurf.algebra.polynomial_negation : PolynomialNegation;
import de.mfo.jsurf.algebra.polynomial_double_division : PolynomialDoubleDivision;
import de.mfo.jsurf.algebra.polynomial_variable : PolynomialVariable;
import de.mfo.jsurf.algebra.double_binary_operation : DoubleBinaryOperation;
import de.mfo.jsurf.algebra.double_unary_operation : DoubleUnaryOperation;
import de.mfo.jsurf.algebra.double_value : DoubleValue;
import de.mfo.jsurf.algebra.double_variable : DoubleVariable;
import de.mfo.jsurf.algebra.univariate_polynomial : UnivariatePolynomial;
import de.mfo.jsurf.algebra.value_calculator : ValueCalculator;
import de.mfo.jsurf.algebra.visitor : accept;

class PolynomialExpansion {
    private UnivariatePolynomial x,y,z;
    private ValueCalculator valueCalculator;

    this(UnivariatePolynomial x,UnivariatePolynomial y,UnivariatePolynomial z){
        this.x=x;this.y=y;this.z=z;valueCalculator=new ValueCalculator(0,0,0);
    }
    UnivariatePolynomial getX(){return x;} UnivariatePolynomial getY(){return y;} UnivariatePolynomial getZ(){return z;}
    void setX(UnivariatePolynomial v){x=v;} void setY(UnivariatePolynomial v){y=v;} void setZ(UnivariatePolynomial v){z=v;}
    void setXYZ(UnivariatePolynomial x,UnivariatePolynomial y,UnivariatePolynomial z){this.x=x;this.y=y;this.z=z;}

    UnivariatePolynomial visit(PolynomialAddition v){return accept(v.getFirstOperand(),this).add(accept(v.getSecondOperand(),this));}
    UnivariatePolynomial visit(PolynomialSubtraction v){return accept(v.getFirstOperand(),this).sub(accept(v.getSecondOperand(),this));}
    UnivariatePolynomial visit(PolynomialMultiplication v){return accept(v.getFirstOperand(),this).mult(accept(v.getSecondOperand(),this));}
    UnivariatePolynomial visit(PolynomialPower v){return accept(v.getBase(),this).pow(v.getExponent());}
    UnivariatePolynomial visit(PolynomialNegation v){return accept(v.getOperand(),this).neg();}
    UnivariatePolynomial visit(PolynomialDoubleDivision v){return accept(v.getDividend(),this).div(accept(v.getDivisor(),valueCalculator));}
    UnivariatePolynomial visit(PolynomialVariable v){
        final switch(v.getVariable()){
            case PolynomialVariable.Var.x:return x;
            case PolynomialVariable.Var.y:return y;
            case PolynomialVariable.Var.z:return z;
        }
    }
    UnivariatePolynomial visit(DoubleBinaryOperation v){return new UnivariatePolynomial(accept(v,valueCalculator));}
    UnivariatePolynomial visit(DoubleUnaryOperation v){return new UnivariatePolynomial(accept(v,valueCalculator));}
    UnivariatePolynomial visit(DoubleVariable v){throw new Exception("unsupported double variable");}
    UnivariatePolynomial visit(DoubleValue v){return new UnivariatePolynomial(v.getValue());}
}
