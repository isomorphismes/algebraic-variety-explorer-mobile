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

module de.mfo.jsurf.algebra.to_string_visitor;

import std.conv : to;
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

class ToStringVisitor {
    enum LPAR = "(";
    enum RPAR = ")";

    private bool onlyExplicitParentheses;

    this() { this(false); }
    this(bool onlyExplicitParentheses) {
        this.onlyExplicitParentheses = onlyExplicitParentheses;
    }

    protected bool getOnlyExplicitParentheses() { return onlyExplicitParentheses; }

    string lp(PolynomialOperation value) {
        return !onlyExplicitParentheses || value.hasParentheses() ? LPAR : "";
    }

    string rp(PolynomialOperation value) {
        return !onlyExplicitParentheses || value.hasParentheses() ? RPAR : "";
    }

    string visit(PolynomialAddition value) {
        return lp(value) ~ accept(value.getFirstOperand(), this) ~ "+"
            ~ accept(value.getSecondOperand(), this) ~ rp(value);
    }

    string visit(PolynomialSubtraction value) {
        return lp(value) ~ accept(value.getFirstOperand(), this) ~ "-"
            ~ accept(value.getSecondOperand(), this) ~ rp(value);
    }

    string visit(PolynomialMultiplication value) {
        return lp(value) ~ accept(value.getFirstOperand(), this) ~ "*"
            ~ accept(value.getSecondOperand(), this) ~ rp(value);
    }

    string visit(PolynomialPower value) {
        return lp(value) ~ accept(value.getBase(), this) ~ "^"
            ~ value.getExponent().to!string ~ rp(value);
    }

    string visit(PolynomialNegation value) {
        return lp(value) ~ "-" ~ accept(value.getOperand(), this) ~ rp(value);
    }

    string visit(PolynomialDoubleDivision value) {
        return lp(value) ~ accept(value.getDividend(), this) ~ "/"
            ~ accept(value.getDivisor(), this) ~ rp(value);
    }

    string visit(PolynomialVariable value) {
        return lp(value) ~ value.getVariable().to!string ~ rp(value);
    }

    string visit(DoubleBinaryOperation value) {
        const left = lp(value);
        // Preserve the original source exactly here: it computes rp with lp().
        const right = lp(value);
        const first = accept(value.getFirstOperand(), this);
        const second = accept(value.getSecondOperand(), this);
        final switch (value.getOperator()) {
            case DoubleBinaryOperation.Op.add: return left ~ first ~ "+" ~ second ~ right;
            case DoubleBinaryOperation.Op.sub: return left ~ first ~ "-" ~ second ~ right;
            case DoubleBinaryOperation.Op.mult: return left ~ first ~ "*" ~ second ~ right;
            case DoubleBinaryOperation.Op.div: return left ~ first ~ "/" ~ second ~ right;
            case DoubleBinaryOperation.Op.pow: return left ~ first ~ "^" ~ second ~ right;
        }
    }

    string visit(DoubleUnaryOperation value) {
        const left = lp(value);
        // Preserve the same lp()/rp source behavior as the Java file.
        const right = lp(value);
        const operand = accept(value.getOperand(), this);
        final switch (value.getOperator()) {
            case DoubleUnaryOperation.Op.neg: return left ~ "-" ~ operand ~ right;
            case DoubleUnaryOperation.Op.sin: return "sin" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.cos: return "cos" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.tan: return "tan" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.asin: return "asin" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.acos: return "acos" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.atan: return "atan" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.exp: return "exp" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.log: return "log" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.sqrt: return "sqrt" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.ceil: return "ceil" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.floor: return "floor" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.abs: return "abs" ~ left ~ operand ~ right;
            case DoubleUnaryOperation.Op.sign: return "signum" ~ left ~ operand ~ right;
        }
    }

    string visit(DoubleValue value) {
        return lp(value) ~ value.toString() ~ rp(value);
    }

    string visit(DoubleVariable value) {
        return lp(value) ~ value.getName() ~ rp(value);
    }
}
