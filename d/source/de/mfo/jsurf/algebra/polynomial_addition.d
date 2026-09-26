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

module de.mfo.jsurf.algebra.polynomial_addition;

import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;

class PolynomialAddition : PolynomialOperation {
    private PolynomialOperation firstOperand;
    private PolynomialOperation secondOperand;
    private bool parentheses;

    this(PolynomialOperation firstOperand, PolynomialOperation secondOperand) {
        this(firstOperand, secondOperand, false);
    }

    this(PolynomialOperation firstOperand, PolynomialOperation secondOperand, bool hasParentheses) {
        this.firstOperand = firstOperand;
        this.secondOperand = secondOperand;
        this.parentheses = hasParentheses;
    }

    PolynomialOperation getFirstOperand() { return firstOperand; }
    PolynomialOperation getSecondOperand() { return secondOperand; }
    override bool hasParentheses() { return parentheses; }
}
