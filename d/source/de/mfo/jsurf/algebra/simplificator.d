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

module de.mfo.jsurf.algebra.simplificator;

import std.math : abs, acos, asin, atan, ceil, cos, exp, floor, log, pow, sin, sqrt, tan;
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

class Simplificator {
    private double[string] dict;

    double getParameterValue(string name) { return dict[name]; }
    string[] getKnownParameterNames() { return dict.keys; }
    void setParameterValue(string name, double value) { dict[name] = value; }
    void unsetParameterValue(string name) { dict.remove(name); }

    PolynomialOperation visit(PolynomialAddition value) {
        auto first = accept(value.getFirstOperand(), this);
        auto second = accept(value.getSecondOperand(), this);

        if (auto number = cast(DoubleValue) first)
            if (number.getValue() == 0.0) return second;
        if (auto number = cast(DoubleValue) second)
            if (number.getValue() == 0.0) return first;

        auto firstDouble = cast(DoubleOperation) first;
        auto secondDouble = cast(DoubleOperation) second;
        if (firstDouble !is null && secondDouble !is null)
            return new DoubleBinaryOperation(DoubleBinaryOperation.Op.add, firstDouble, secondDouble);
        return new PolynomialAddition(first, second);
    }

    PolynomialOperation visit(PolynomialSubtraction value) {
        auto first = accept(value.getFirstOperand(), this);
        auto second = accept(value.getSecondOperand(), this);

        if (auto number = cast(DoubleValue) first)
            if (number.getValue() == 0.0)
                return accept(cast(PolynomialOperation) new PolynomialNegation(second), this);
        if (auto number = cast(DoubleValue) second)
            if (number.getValue() == 0.0) return first;

        auto firstDouble = cast(DoubleOperation) first;
        auto secondDouble = cast(DoubleOperation) second;
        if (firstDouble !is null && secondDouble !is null)
            return new DoubleBinaryOperation(DoubleBinaryOperation.Op.sub, firstDouble, secondDouble);
        return new PolynomialSubtraction(first, second);
    }

    PolynomialOperation visit(PolynomialMultiplication value) {
        auto first = accept(value.getFirstOperand(), this);
        auto second = accept(value.getSecondOperand(), this);

        if (auto number = cast(DoubleValue) first) {
            if (number.getValue() == 0.0) return first;
            if (number.getValue() == 1.0) return second;
        }
        if (auto number = cast(DoubleValue) second) {
            if (number.getValue() == 0.0) return second;
            if (number.getValue() == 1.0) return first;
        }

        auto firstDouble = cast(DoubleOperation) first;
        auto secondDouble = cast(DoubleOperation) second;
        if (firstDouble !is null && secondDouble !is null)
            return new DoubleBinaryOperation(DoubleBinaryOperation.Op.mult, firstDouble, secondDouble);
        return new PolynomialMultiplication(first, second);
    }

    PolynomialOperation visit(PolynomialPower value) {
        auto base = accept(value.getBase(), this);
        if (value.getExponent() == 0) return new DoubleValue(1.0);
        if (value.getExponent() == 1) return base;
        if (auto number = cast(DoubleValue) base)
            return new DoubleValue(pow(number.getValue(), cast(double) value.getExponent()));
        return new PolynomialPower(base, value.getExponent());
    }

    PolynomialOperation visit(PolynomialNegation value) {
        auto operand = accept(value.getOperand(), this);
        if (auto number = cast(DoubleValue) operand)
            return new DoubleValue(-number.getValue());
        return new PolynomialNegation(operand);
    }

    PolynomialOperation visit(PolynomialDoubleDivision value) {
        auto dividend = accept(value.getDividend(), this);
        auto divisorOperation = accept(value.getDivisor(), this);
        auto dividendValue = cast(DoubleValue) dividend;
        auto divisorValue = cast(DoubleValue) divisorOperation;
        if (dividendValue !is null && divisorValue !is null)
            return new DoubleValue(dividendValue.getValue() / divisorValue.getValue());

        auto dividendDouble = cast(DoubleOperation) dividend;
        auto divisorDouble = cast(DoubleOperation) divisorOperation;
        if (dividendDouble !is null && divisorDouble !is null)
            return new DoubleBinaryOperation(DoubleBinaryOperation.Op.div, dividendDouble, divisorDouble);
        return new PolynomialDoubleDivision(dividend, divisorDouble);
    }

    PolynomialOperation visit(PolynomialVariable value) { return value; }

    PolynomialOperation visit(DoubleBinaryOperation value) {
        auto first = cast(DoubleOperation) accept(value.getFirstOperand(), this);
        auto second = cast(DoubleOperation) accept(value.getSecondOperand(), this);
        auto firstValue = cast(DoubleValue) first;
        auto secondValue = cast(DoubleValue) second;

        if (firstValue !is null && secondValue !is null) {
            double result;
            final switch (value.getOperator()) {
                case DoubleBinaryOperation.Op.add: result = firstValue.getValue() + secondValue.getValue(); break;
                case DoubleBinaryOperation.Op.sub: result = firstValue.getValue() - secondValue.getValue(); break;
                case DoubleBinaryOperation.Op.mult: result = firstValue.getValue() * secondValue.getValue(); break;
                case DoubleBinaryOperation.Op.div: result = firstValue.getValue() / secondValue.getValue(); break;
                case DoubleBinaryOperation.Op.pow: result = pow(firstValue.getValue(), secondValue.getValue()); break;
            }
            return new DoubleValue(result);
        }

        return new DoubleBinaryOperation(value.getOperator(), first, second);
    }

    PolynomialOperation visit(DoubleUnaryOperation value) {
        auto operand = cast(DoubleOperation) accept(value.getOperand(), this);
        if (auto number = cast(DoubleValue) operand) {
            const x = number.getValue();
            double result;
            final switch (value.getOperator()) {
                case DoubleUnaryOperation.Op.neg: result = -x; break;
                case DoubleUnaryOperation.Op.sin: result = sin(x); break;
                case DoubleUnaryOperation.Op.cos: result = cos(x); break;
                case DoubleUnaryOperation.Op.tan: result = tan(x); break;
                case DoubleUnaryOperation.Op.asin: result = asin(x); break;
                case DoubleUnaryOperation.Op.acos: result = acos(x); break;
                case DoubleUnaryOperation.Op.atan: result = atan(x); break;
                case DoubleUnaryOperation.Op.exp: result = exp(x); break;
                case DoubleUnaryOperation.Op.log: result = log(x); break;
                case DoubleUnaryOperation.Op.sqrt: result = sqrt(x); break;
                case DoubleUnaryOperation.Op.ceil: result = ceil(x); break;
                case DoubleUnaryOperation.Op.floor: result = floor(x); break;
                case DoubleUnaryOperation.Op.abs: result = abs(x); break;
                case DoubleUnaryOperation.Op.sign: result = x > 0.0 ? 1.0 : x < 0.0 ? -1.0 : 0.0; break;
            }
            return new DoubleValue(result);
        }
        return new DoubleUnaryOperation(value.getOperator(), operand);
    }

    PolynomialOperation visit(DoubleValue value) { return value; }

    PolynomialOperation visit(DoubleVariable value) {
        auto found = value.getName() in dict;
        return found is null ? cast(PolynomialOperation) value
            : cast(PolynomialOperation) new DoubleValue(*found);
    }
}
