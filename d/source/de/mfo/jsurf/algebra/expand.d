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

module de.mfo.jsurf.algebra.expand;
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
import de.mfo.jsurf.algebra.visitor : accept;

import de.mfo.jsurf.algebra.value_calculator : ValueCalculator;
import de.mfo.jsurf.algebra.xyz_polynomial : XYZPolynomial;

class Expand {
    private ValueCalculator valueCalculator;
    this(){valueCalculator=new ValueCalculator(0,0,0);}
    XYZPolynomial visit(PolynomialAddition v){return accept(v.getFirstOperand(),this).add(accept(v.getSecondOperand(),this));}
    XYZPolynomial visit(PolynomialSubtraction v){return accept(v.getFirstOperand(),this).sub(accept(v.getSecondOperand(),this));}
    XYZPolynomial visit(PolynomialMultiplication v){return accept(v.getFirstOperand(),this).mult(accept(v.getSecondOperand(),this));}
    XYZPolynomial visit(PolynomialPower v){return accept(v.getBase(),this).pow(v.getExponent());}
    XYZPolynomial visit(PolynomialNegation v){return accept(v.getOperand(),this).neg();}
    XYZPolynomial visit(PolynomialDoubleDivision v){return accept(v.getDividend(),this).mult(1.0/accept(v.getDivisor(),valueCalculator));}
    XYZPolynomial visit(PolynomialVariable v){
        final switch(v.getVariable()){
            case PolynomialVariable.Var.x:return XYZPolynomial.X;
            case PolynomialVariable.Var.y:return XYZPolynomial.Y;
            case PolynomialVariable.Var.z:return XYZPolynomial.Z;
        }
    }
    XYZPolynomial visit(DoubleBinaryOperation v){return new XYZPolynomial(accept(v,valueCalculator));}
    XYZPolynomial visit(DoubleUnaryOperation v){return new XYZPolynomial(accept(v,valueCalculator));}
    XYZPolynomial visit(DoubleVariable v){throw new Exception("no value has been assigned to parameter '"~v.getName()~"'");}
    XYZPolynomial visit(DoubleValue v){return new XYZPolynomial(v.getValue());}
}
