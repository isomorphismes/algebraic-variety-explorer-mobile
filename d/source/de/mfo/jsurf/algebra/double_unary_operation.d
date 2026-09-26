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

module de.mfo.jsurf.algebra.double_unary_operation;

import de.mfo.jsurf.algebra.double_operation : DoubleOperation;

class DoubleUnaryOperation : DoubleOperation {
    enum Op { neg, sin, cos, tan, asin, acos, atan, exp, log, sqrt, ceil, floor, abs, sign }

    private Op operator;
    private DoubleOperation operand;
    private bool parentheses;

    this(Op operator, DoubleOperation operand) {
        this(operator, operand, false);
    }

    this(Op operator, DoubleOperation operand, bool hasParentheses) {
        this.operator = operator;
        this.operand = operand;
        this.parentheses = hasParentheses;
    }

    Op getOperator() { return operator; }
    DoubleOperation getOperand() { return operand; }
    override bool hasParentheses() { return parentheses; }
}
