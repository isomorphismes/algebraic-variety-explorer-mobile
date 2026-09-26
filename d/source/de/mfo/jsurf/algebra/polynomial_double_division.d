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

module de.mfo.jsurf.algebra.polynomial_double_division;

import de.mfo.jsurf.algebra.double_operation : DoubleOperation;
import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;

class PolynomialDoubleDivision : PolynomialOperation {
    private PolynomialOperation dividend;
    private DoubleOperation divisor;
    private bool parentheses;

    this(PolynomialOperation dividend, DoubleOperation divisor) {
        this(dividend, divisor, false);
    }

    this(PolynomialOperation dividend, DoubleOperation divisor, bool hasParentheses) {
        this.dividend = dividend;
        this.divisor = divisor;
        this.parentheses = hasParentheses;
    }

    PolynomialOperation getDividend() { return dividend; }
    DoubleOperation getDivisor() { return divisor; }
    override bool hasParentheses() { return parentheses; }
}
