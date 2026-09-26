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

module de.mfo.jsurf.algebra.double_value;

import std.conv : to;
import de.mfo.jsurf.algebra.double_operation : DoubleOperation;

class DoubleValue : DoubleOperation {
    private double value;
    private string stringValue;
    private bool parentheses;

    this(string stringValue) {
        this(stringValue, false);
    }

    this(string stringValue, bool hasParentheses) {
        this.stringValue = stringValue;
        this.value = stringValue.to!double;
        this.parentheses = hasParentheses;
    }

    this(double value) {
        this(value, false);
    }

    this(double value, bool hasParentheses) {
        this.value = value;
        const intValue = cast(int) value;
        this.stringValue = value == cast(double) intValue
            ? intValue.to!string
            : value.to!string;
        this.parentheses = hasParentheses;
    }

    double getValue() { return value; }
    override bool hasParentheses() { return parentheses; }
    override string toString() { return stringValue; }
}
