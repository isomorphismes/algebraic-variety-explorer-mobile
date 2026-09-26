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

module de.mfo.jsurf.algebra.double_variable_extractor;

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

alias StringSet = bool[string];

class DoubleVariableExtractor {
    private static StringSet merged(StringSet first, StringSet second) {
        foreach (name; second.keys) first[name] = true;
        return first;
    }

    StringSet visit(PolynomialAddition value) {
        return merged(accept(value.getFirstOperand(), this), accept(value.getSecondOperand(), this));
    }
    StringSet visit(PolynomialSubtraction value) {
        return merged(accept(value.getFirstOperand(), this), accept(value.getSecondOperand(), this));
    }
    StringSet visit(PolynomialMultiplication value) {
        return merged(accept(value.getFirstOperand(), this), accept(value.getSecondOperand(), this));
    }
    StringSet visit(PolynomialPower value) { return accept(value.getBase(), this); }
    StringSet visit(PolynomialNegation value) { return accept(value.getOperand(), this); }
    StringSet visit(PolynomialDoubleDivision value) {
        return merged(accept(value.getDividend(), this), accept(value.getDivisor(), this));
    }
    StringSet visit(PolynomialVariable value) { return StringSet.init; }
    StringSet visit(DoubleBinaryOperation value) {
        return merged(accept(value.getFirstOperand(), this), accept(value.getSecondOperand(), this));
    }
    StringSet visit(DoubleUnaryOperation value) { return accept(value.getOperand(), this); }
    StringSet visit(DoubleValue value) { return StringSet.init; }
    StringSet visit(DoubleVariable value) {
        StringSet result; result[value.getName()] = true; return result;
    }
}
