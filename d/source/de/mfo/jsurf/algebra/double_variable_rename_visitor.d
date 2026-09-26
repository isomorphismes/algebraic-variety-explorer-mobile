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

module de.mfo.jsurf.algebra.double_variable_rename_visitor;

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

class DoubleVariableRenameVisitor {
    private string[string] names;

    this(string[string] names) { this.names = names; }

    PolynomialOperation visit(PolynomialAddition value) {
        accept(value.getFirstOperand(), this); accept(value.getSecondOperand(), this); return value;
    }
    PolynomialOperation visit(PolynomialSubtraction value) {
        accept(value.getFirstOperand(), this); accept(value.getSecondOperand(), this); return value;
    }
    PolynomialOperation visit(PolynomialMultiplication value) {
        accept(value.getFirstOperand(), this); accept(value.getSecondOperand(), this); return value;
    }
    PolynomialOperation visit(PolynomialPower value) { return accept(value.getBase(), this); }
    PolynomialOperation visit(PolynomialNegation value) { accept(value.getOperand(), this); return value; }
    PolynomialOperation visit(PolynomialDoubleDivision value) {
        accept(value.getDividend(), this); accept(value.getDivisor(), this); return value;
    }
    PolynomialOperation visit(PolynomialVariable value) { return value; }
    PolynomialOperation visit(DoubleBinaryOperation value) {
        accept(value.getFirstOperand(), this); accept(value.getSecondOperand(), this); return value;
    }
    PolynomialOperation visit(DoubleUnaryOperation value) { return accept(value.getOperand(), this); }
    PolynomialOperation visit(DoubleValue value) { return value; }
    PolynomialOperation visit(DoubleVariable value) {
        auto found = value.getName() in names;
        return new DoubleVariable(found is null ? value.getName() : *found);
    }
}
