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

module de.mfo.jsurf.algebra.degree_calculator;

import std.algorithm.comparison : max;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.polynomial_addition : PolynomialAddition;
import de.mfo.jsurf.algebra.polynomial_subtraction : PolynomialSubtraction;
import de.mfo.jsurf.algebra.polynomial_multiplication : PolynomialMultiplication;
import de.mfo.jsurf.algebra.polynomial_power : PolynomialPower;
import de.mfo.jsurf.algebra.polynomial_negation : PolynomialNegation;
import de.mfo.jsurf.algebra.polynomial_double_division : PolynomialDoubleDivision;
import de.mfo.jsurf.algebra.polynomial_variable : PolynomialVariable;
import de.mfo.jsurf.algebra.double_operation : DoubleOperation;
import de.mfo.jsurf.algebra.double_binary_operation : DoubleBinaryOperation;
import de.mfo.jsurf.algebra.double_unary_operation : DoubleUnaryOperation;
import de.mfo.jsurf.algebra.double_value : DoubleValue;
import de.mfo.jsurf.algebra.double_variable : DoubleVariable;
import de.mfo.jsurf.algebra.visitor : accept;

class DegreeCalculator {
    int visit(PolynomialAddition value) {
        return max(accept(value.getFirstOperand(), this), accept(value.getSecondOperand(), this));
    }
    int visit(PolynomialSubtraction value) {
        return max(accept(value.getFirstOperand(), this), accept(value.getSecondOperand(), this));
    }
    int visit(PolynomialMultiplication value) {
        return accept(value.getFirstOperand(), this) + accept(value.getSecondOperand(), this);
    }
    int visit(PolynomialPower value) {
        return value.getExponent() * accept(value.getBase(), this);
    }
    int visit(PolynomialNegation value) { return accept(value.getOperand(), this); }
    int visit(PolynomialDoubleDivision value) { return accept(value.getDividend(), this); }
    int visit(PolynomialVariable value) { return 1; }
    int visit(DoubleBinaryOperation value) { return 0; }
    int visit(DoubleUnaryOperation value) { return 0; }
    int visit(DoubleValue value) { return 0; }
    int visit(DoubleVariable value) { return 0; }
}
