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

module de.mfo.jsurf.algebra.differentiator;

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

class Differentiator {
    private PolynomialVariable.Var variable;

    this(PolynomialVariable.Var variable) { this.variable = variable; }

    PolynomialVariable.Var getVariable() { return variable; }
    void setVariable(PolynomialVariable.Var variable) { this.variable = variable; }

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
        auto u = value.getFirstOperand();
        auto v = value.getSecondOperand();
        auto udiff = accept(u, this);
        auto vdiff = accept(v, this);
        return new PolynomialAddition(
            new PolynomialMultiplication(udiff, v),
            new PolynomialMultiplication(u, vdiff));
    }
    PolynomialOperation visit(PolynomialPower value) {
        switch (value.getExponent()) {
            case 1:
                return new DoubleValue(1.0);
            case 2: {
                auto u = value.getBase();
                auto udiff = accept(u, this);
                return new PolynomialMultiplication(
                    new PolynomialMultiplication(
                        new DoubleValue(cast(double) value.getExponent()), u),
                    udiff);
            }
            default: {
                auto u = value.getBase();
                auto udiff = accept(u, this);
                return new PolynomialMultiplication(
                    new PolynomialMultiplication(
                        new DoubleValue(cast(double) value.getExponent()),
                        new PolynomialPower(u, value.getExponent() - 1)),
                    udiff);
            }
        }
    }
    PolynomialOperation visit(PolynomialNegation value) {
        return new PolynomialNegation(accept(value.getOperand(), this));
    }
    PolynomialOperation visit(PolynomialDoubleDivision value) {
        return new PolynomialDoubleDivision(
            accept(value.getDividend(), this), value.getDivisor());
    }
    PolynomialOperation visit(PolynomialVariable value) {
        return value.getVariable() == variable
            ? cast(PolynomialOperation) new DoubleValue(1.0)
            : cast(PolynomialOperation) new DoubleValue(0.0);
    }
    PolynomialOperation visit(DoubleBinaryOperation value) { return new DoubleValue(0.0); }
    PolynomialOperation visit(DoubleUnaryOperation value) { return new DoubleValue(0.0); }
    PolynomialOperation visit(DoubleValue value) { return new DoubleValue(0.0); }
    PolynomialOperation visit(DoubleVariable value) { return new DoubleValue(0.0); }
}
