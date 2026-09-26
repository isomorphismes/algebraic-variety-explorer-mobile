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

module de.mfo.jsurf.parser.algebraic_expression_parser;

import std.ascii : isAlpha, isDigit, isWhite;
import std.conv : ConvException, to;

import de.mfo.jsurf.algebra.polynomial_operation : PolynomialOperation;
import de.mfo.jsurf.algebra.double_operation : DoubleOperation;
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

class AlgebraicExpressionParser {
    private enum Kind { decimal, floating, identifier, plus, minus, mult, div, power, lpar, rpar, eof }

    private struct Token { Kind kind; string text; }

    private struct Parsed {
        PolynomialOperation operation;
        int* decimal;
    }

    private Token[] tokens;
    private size_t position;

    static PolynomialOperation parse(string source) {
        auto parser = new AlgebraicExpressionParser(source);
        auto result = parser.parseAdd();
        parser.expect(Kind.eof);
        return result.operation;
    }

    private this(string source) { tokens = lex(source); }

    private static Token[] lex(string source) {
        Token[] result;
        size_t i;
        while (i < source.length) {
            const c = source[i];
            if (isWhite(c)) { ++i; continue; }
            switch (c) {
                case '+': result ~= Token(Kind.plus, "+"); ++i; continue;
                case '-': result ~= Token(Kind.minus, "-"); ++i; continue;
                case '*': result ~= Token(Kind.mult, "*"); ++i; continue;
                case '/': result ~= Token(Kind.div, "/"); ++i; continue;
                case '^': result ~= Token(Kind.power, "^"); ++i; continue;
                case '(': result ~= Token(Kind.lpar, "("); ++i; continue;
                case ')': result ~= Token(Kind.rpar, ")"); ++i; continue;
                default: break;
            }

            if (isAlpha(c) || c == '_') {
                const start=i++;
                while(i<source.length && (isAlpha(source[i]) || isDigit(source[i]) || source[i]=='_')) ++i;
                result ~= Token(Kind.identifier, source[start..i]);
                continue;
            }

            if (isDigit(c) || (c=='.' && i+1<source.length && isDigit(source[i+1]))) {
                const start=i;
                bool hasDot=false,hasExponent=false;
                if(c=='.'){hasDot=true;++i;} else {
                    while(i<source.length && isDigit(source[i])) ++i;
                    if(i<source.length && source[i]=='.'){hasDot=true;++i;while(i<source.length && isDigit(source[i]))++i;}
                }
                if(i<source.length && (source[i]=='e'||source[i]=='E')){
                    hasExponent=true;++i;
                    if(i<source.length && (source[i]=='+'||source[i]=='-'))++i;
                    const exponentStart=i;
                    while(i<source.length && isDigit(source[i]))++i;
                    if(i==exponentStart) throw new Exception("invalid exponent");
                }
                const text=source[start..i];
                if(!hasDot && !hasExponent && text.length>1 && text[0]=='0')
                    throw new Exception("invalid decimal literal: "~text);
                result ~= Token(hasDot||hasExponent?Kind.floating:Kind.decimal,text);
                continue;
            }

            throw new Exception("unexpected character: "~source[i..i+1]);
        }
        result ~= Token(Kind.eof,"");
        return result;
    }

    private Token current(){return tokens[position];}
    private bool take(Kind kind){if(current().kind==kind){++position;return true;}return false;}
    private Token expect(Kind kind){if(current().kind!=kind)throw new Exception("unexpected token '"~current().text~"'");return tokens[position++];}

    private Parsed parseAdd(){
        auto left=parseMult();
        while(current().kind==Kind.plus || current().kind==Kind.minus){
            const op=current().kind;++position;auto right=parseMult();
            left=combineBinary(op,left,right,false);
        }
        return left;
    }

    private Parsed parseMult(){
        auto left=parseNeg();
        while(current().kind==Kind.mult || current().kind==Kind.div){
            const op=current().kind;++position;auto right=parseNeg();
            left=combineBinary(op,left,right,false);
        }
        return left;
    }

    private Parsed parseNeg(){
        if(take(Kind.minus)){
            auto value=parsePower();
            auto scalar=cast(DoubleOperation)value.operation;
            PolynomialOperation operation = scalar !is null
                ? cast(PolynomialOperation)new DoubleUnaryOperation(DoubleUnaryOperation.Op.neg,scalar,false)
                : cast(PolynomialOperation)new PolynomialNegation(value.operation,false);
            return Parsed(operation,null);
        }
        return parsePower();
    }

    private Parsed parsePower(){
        auto left=parseUnary();
        if(take(Kind.power)){
            auto right=parsePower();
            return combineBinary(Kind.power,left,right,false);
        }
        return left;
    }

    private Parsed parseUnary(){
        if(current().kind==Kind.identifier && position+1<tokens.length && tokens[position+1].kind==Kind.lpar){
            const name=expect(Kind.identifier).text;
            expect(Kind.lpar);
            auto value=parseAdd();
            expect(Kind.rpar);
            auto scalar=cast(DoubleOperation)value.operation;
            if(scalar is null) throw new Exception("function argument is not scalar");
            DoubleUnaryOperation.Op op;
            switch(name){
                case "neg":op=DoubleUnaryOperation.Op.neg;break;
                case "sin":op=DoubleUnaryOperation.Op.sin;break;
                case "cos":op=DoubleUnaryOperation.Op.cos;break;
                case "tan":op=DoubleUnaryOperation.Op.tan;break;
                case "asin":op=DoubleUnaryOperation.Op.asin;break;
                case "acos":op=DoubleUnaryOperation.Op.acos;break;
                case "atan":op=DoubleUnaryOperation.Op.atan;break;
                case "exp":op=DoubleUnaryOperation.Op.exp;break;
                case "log":op=DoubleUnaryOperation.Op.log;break;
                case "sqrt":op=DoubleUnaryOperation.Op.sqrt;break;
                case "ceil":op=DoubleUnaryOperation.Op.ceil;break;
                case "floor":op=DoubleUnaryOperation.Op.floor;break;
                case "abs":op=DoubleUnaryOperation.Op.abs;break;
                case "sign":op=DoubleUnaryOperation.Op.sign;break;
                default:throw new Exception("unknown scalar function: "~name);
            }
            return Parsed(new DoubleUnaryOperation(op,scalar,true),null);
        }
        return parsePrimary();
    }

    private Parsed parsePrimary(){
        if(take(Kind.lpar)){
            auto value=parseAdd();
            expect(Kind.rpar);
            return withParentheses(value);
        }
        if(current().kind==Kind.decimal){
            const t=expect(Kind.decimal);int value;
            try{value=t.text.to!int;}catch(ConvException){value=0;}
            int* stored=new int;*stored=value;
            return Parsed(new DoubleValue(t.text,false),stored);
        }
        if(current().kind==Kind.floating){
            const t=expect(Kind.floating);
            return Parsed(new DoubleValue(t.text,false),null);
        }
        if(current().kind==Kind.identifier){
            const name=expect(Kind.identifier).text;
            return Parsed(createVariable(name,false),null);
        }
        throw new Exception("expected primary expression");
    }

    private static PolynomialOperation createVariable(string name,bool parentheses){
        switch(name){
            case "x":return new PolynomialVariable(PolynomialVariable.Var.x,parentheses);
            case "y":return new PolynomialVariable(PolynomialVariable.Var.y,parentheses);
            case "z":return new PolynomialVariable(PolynomialVariable.Var.z,parentheses);
            default:return new DoubleVariable(name,parentheses);
        }
    }

    private static Parsed withParentheses(Parsed value){
        auto op=value.operation;
        if(auto v=cast(PolynomialAddition)op)return Parsed(new PolynomialAddition(v.getFirstOperand(),v.getSecondOperand(),true),value.decimal);
        if(auto v=cast(PolynomialSubtraction)op)return Parsed(new PolynomialSubtraction(v.getFirstOperand(),v.getSecondOperand(),true),value.decimal);
        if(auto v=cast(PolynomialMultiplication)op)return Parsed(new PolynomialMultiplication(v.getFirstOperand(),v.getSecondOperand(),true),value.decimal);
        if(auto v=cast(PolynomialPower)op)return Parsed(new PolynomialPower(v.getBase(),v.getExponent(),true),value.decimal);
        if(auto v=cast(PolynomialNegation)op)return Parsed(new PolynomialNegation(v.getOperand(),true),value.decimal);
        if(auto v=cast(PolynomialDoubleDivision)op)return Parsed(new PolynomialDoubleDivision(v.getDividend(),v.getDivisor(),true),value.decimal);
        if(auto v=cast(PolynomialVariable)op)return Parsed(new PolynomialVariable(v.getVariable(),true),value.decimal);
        if(auto v=cast(DoubleBinaryOperation)op)return Parsed(new DoubleBinaryOperation(v.getOperator(),v.getFirstOperand(),v.getSecondOperand(),true),value.decimal);
        if(auto v=cast(DoubleUnaryOperation)op)return Parsed(new DoubleUnaryOperation(v.getOperator(),v.getOperand(),true),value.decimal);
        if(auto v=cast(DoubleValue)op)return Parsed(new DoubleValue(v.toString(),true),value.decimal);
        if(auto v=cast(DoubleVariable)op)return Parsed(new DoubleVariable(v.getName(),true),value.decimal);
        return value;
    }

    private static Parsed combineBinary(Kind kind,Parsed left,Parsed right,bool parentheses){
        auto l=cast(DoubleOperation)left.operation;
        auto r=cast(DoubleOperation)right.operation;
        if(l !is null && r !is null){
            DoubleBinaryOperation.Op op;
            switch(kind){
                case Kind.plus:op=DoubleBinaryOperation.Op.add;break;
                case Kind.minus:op=DoubleBinaryOperation.Op.sub;break;
                case Kind.mult:op=DoubleBinaryOperation.Op.mult;break;
                case Kind.div:op=DoubleBinaryOperation.Op.div;break;
                case Kind.power:op=DoubleBinaryOperation.Op.pow;break;
                default:assert(0);
            }
            // The original walker drops the explicit-parentheses flag for
            // scalar multiplication; preserve that source behavior.
            const keepParens=kind==Kind.mult?false:parentheses;
            return Parsed(new DoubleBinaryOperation(op,l,r,keepParens),null);
        }

        switch(kind){
            case Kind.plus:return Parsed(new PolynomialAddition(left.operation,right.operation,parentheses),null);
            case Kind.minus:return Parsed(new PolynomialSubtraction(left.operation,right.operation,parentheses),null);
            case Kind.mult:return Parsed(new PolynomialMultiplication(left.operation,right.operation,parentheses),null);
            case Kind.div:
                if(r is null)throw new Exception("polynomial division requires scalar divisor");
                return Parsed(new PolynomialDoubleDivision(left.operation,r,parentheses),null);
            case Kind.power:
                if(right.decimal is null)throw new Exception("polynomial exponent must be a decimal integer");
                return Parsed(new PolynomialPower(left.operation,*right.decimal,parentheses),null);
            default:assert(0);
        }
    }
}

unittest {
    import de.mfo.jsurf.algebra.degree_calculator : DegreeCalculator;
    import de.mfo.jsurf.algebra.value_calculator : ValueCalculator;
    import de.mfo.jsurf.algebra.visitor : accept;
    auto p=AlgebraicExpressionParser.parse("x^2+y^2+z^2-0.64");
    assert(accept(p,new DegreeCalculator())==2);
    assert(accept(p,new ValueCalculator(0.8,0,0))==0.0);
}
