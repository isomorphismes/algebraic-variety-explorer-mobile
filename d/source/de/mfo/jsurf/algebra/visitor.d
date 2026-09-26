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

module de.mfo.jsurf.algebra.visitor;

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

auto accept(V)(PolynomialOperation operation, V visitor) {
    if (auto value = cast(PolynomialAddition) operation) return visitor.visit(value);
    if (auto value = cast(PolynomialSubtraction) operation) return visitor.visit(value);
    if (auto value = cast(PolynomialMultiplication) operation) return visitor.visit(value);
    if (auto value = cast(PolynomialPower) operation) return visitor.visit(value);
    if (auto value = cast(PolynomialNegation) operation) return visitor.visit(value);
    if (auto value = cast(PolynomialDoubleDivision) operation) return visitor.visit(value);
    if (auto value = cast(PolynomialVariable) operation) return visitor.visit(value);
    if (auto value = cast(DoubleBinaryOperation) operation) return visitor.visit(value);
    if (auto value = cast(DoubleUnaryOperation) operation) return visitor.visit(value);
    if (auto value = cast(DoubleValue) operation) return visitor.visit(value);
    if (auto value = cast(DoubleVariable) operation) return visitor.visit(value);
    throw new Exception("unsupported polynomial operation");
}
