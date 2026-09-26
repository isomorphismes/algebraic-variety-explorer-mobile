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

module de.mfo.jsurf.algebra.clone_visitor;

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

class CloneVisitor {
    PolynomialOperation visit(PolynomialAddition value) {
        return new PolynomialAddition(
            accept(value.getFirstOperand(), this),
            accept(value.getSecondOperand(), this));
    }
    PolynomialOperation visit(PolynomialSubtraction value) {
        return new PolynomialSubtraction(
            accept(value.getFirstOperand(), this),
            accept(value.getSecondOperand(), this));
    }
    PolynomialOperation visit(PolynomialMultiplication value) {
        return new PolynomialMultiplication(
            accept(value.getFirstOperand(), this),
            accept(value.getSecondOperand(), this));
    }
    PolynomialOperation visit(PolynomialPower value) {
        return new PolynomialPower(accept(value.getBase(), this), value.getExponent());
    }
    PolynomialOperation visit(PolynomialNegation value) {
        return new PolynomialNegation(accept(value.getOperand(), this));
    }
    PolynomialOperation visit(PolynomialDoubleDivision value) {
        return new PolynomialDoubleDivision(
            accept(value.getDividend(), this),
            cast(DoubleOperation) accept(value.getDivisor(), this));
    }
    PolynomialOperation visit(PolynomialVariable value) { return value; }
    PolynomialOperation visit(DoubleBinaryOperation value) {
        return new DoubleBinaryOperation(
            value.getOperator(),
            cast(DoubleOperation) accept(value.getFirstOperand(), this),
            cast(DoubleOperation) accept(value.getSecondOperand(), this));
    }
    PolynomialOperation visit(DoubleUnaryOperation value) {
        return new DoubleUnaryOperation(
            value.getOperator(),
            cast(DoubleOperation) accept(value.getOperand(), this));
    }
    PolynomialOperation visit(DoubleValue value) { return value; }
    PolynomialOperation visit(DoubleVariable value) {
        return new DoubleVariable(value.getName());
    }
}
