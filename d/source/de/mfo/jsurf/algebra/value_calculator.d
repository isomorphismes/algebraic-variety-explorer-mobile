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

module de.mfo.jsurf.algebra.value_calculator;

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

class ValueCalculator {
    private double x;
    private double y;
    private double z;
    private double[string] dict;

    this() { this(0.0, 0.0, 0.0); }
    this(double x, double y, double z) {
        this.x = x; this.y = y; this.z = z;
    }

    double getX() { return x; }
    double getY() { return y; }
    double getZ() { return z; }
    void setX(double value) { x = value; }
    void setY(double value) { y = value; }
    void setZ(double value) { z = value; }
    void setXYZ(double x, double y, double z) { this.x=x; this.y=y; this.z=z; }

    double getParameterValue(string name) {
        auto found = name in dict;
        return found is null ? double.nan : *found;
    }

    string[] getParameters() { return dict.keys; }
    void setParameterValue(string name, double value) { dict[name] = value; }

    double visit(PolynomialAddition value) {
        return accept(value.getFirstOperand(), this) + accept(value.getSecondOperand(), this);
    }
    double visit(PolynomialSubtraction value) {
        return accept(value.getFirstOperand(), this) - accept(value.getSecondOperand(), this);
    }
    double visit(PolynomialMultiplication value) {
        return accept(value.getFirstOperand(), this) * accept(value.getSecondOperand(), this);
    }
    double visit(PolynomialPower value) {
        return pow(accept(value.getBase(), this), cast(double) value.getExponent());
    }
    double visit(PolynomialNegation value) { return -accept(value.getOperand(), this); }
    double visit(PolynomialDoubleDivision value) {
        return accept(value.getDividend(), this) / accept(value.getDivisor(), this);
    }
    double visit(PolynomialVariable value) {
        final switch (value.getVariable()) {
            case PolynomialVariable.Var.x: return x;
            case PolynomialVariable.Var.y: return y;
            case PolynomialVariable.Var.z: return z;
        }
    }
    double visit(DoubleBinaryOperation value) {
        const first = accept(value.getFirstOperand(), this);
        const second = accept(value.getSecondOperand(), this);
        final switch (value.getOperator()) {
            case DoubleBinaryOperation.Op.add: return first + second;
            case DoubleBinaryOperation.Op.sub: return first - second;
            case DoubleBinaryOperation.Op.mult: return first * second;
            case DoubleBinaryOperation.Op.div: return first / second;
            case DoubleBinaryOperation.Op.pow: return pow(first, second);
        }
    }
    double visit(DoubleUnaryOperation value) {
        const operand = accept(value.getOperand(), this);
        final switch (value.getOperator()) {
            case DoubleUnaryOperation.Op.neg: return -operand;
            case DoubleUnaryOperation.Op.sin: return sin(operand);
            case DoubleUnaryOperation.Op.cos: return cos(operand);
            case DoubleUnaryOperation.Op.tan: return tan(operand);
            case DoubleUnaryOperation.Op.asin: return asin(operand);
            case DoubleUnaryOperation.Op.acos: return acos(operand);
            case DoubleUnaryOperation.Op.atan: return atan(operand);
            case DoubleUnaryOperation.Op.exp: return exp(operand);
            case DoubleUnaryOperation.Op.log: return log(operand);
            case DoubleUnaryOperation.Op.sqrt: return sqrt(operand);
            case DoubleUnaryOperation.Op.ceil: return ceil(operand);
            case DoubleUnaryOperation.Op.floor: return floor(operand);
            case DoubleUnaryOperation.Op.abs: return abs(operand);
            case DoubleUnaryOperation.Op.sign: return operand > 0.0 ? 1.0 : operand < 0.0 ? -1.0 : 0.0;
        }
    }
    double visit(DoubleVariable value) {
        auto found = value.getName() in dict;
        if (found is null)
            throw new Exception("no value has been assigned to parameter '" ~ value.getName() ~ "'");
        return *found;
    }
    double visit(DoubleValue value) { return value.getValue(); }
}
