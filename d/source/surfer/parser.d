module surfer.parser;

import std.ascii : isAlpha, isDigit, isWhite;
import std.conv : to;
import std.exception : enforce;
import std.math : abs, acos, asin, atan, ceil, cos, exp, floor, log, pow, sin, sqrt, tan;
import std.string : strip;

import surfer.polynomial : Polynomial;

class ParseError : Exception {
    this(string message) {
        super(message);
    }
}

private enum TokenKind {
    end,
    number,
    identifier,
    plus,
    minus,
    multiply,
    divide,
    power,
    left_parenthesis,
    right_parenthesis
}

private struct Token {
    TokenKind kind;
    string text;
    size_t offset;
}

private class Lexer {
    private string source;
    private size_t position;

    this(string source) {
        this.source = source;
    }

    Token next() {
        while (position < source.length && isWhite(source[position]))
            ++position;

        if (position == source.length)
            return Token(TokenKind.end, "", position);

        const start = position;
        const c = source[position++];
        switch (c) {
            case '+': return Token(TokenKind.plus, "+", start);
            case '-': return Token(TokenKind.minus, "-", start);
            case '*': return Token(TokenKind.multiply, "*", start);
            case '/': return Token(TokenKind.divide, "/", start);
            case '^': return Token(TokenKind.power, "^", start);
            case '(': return Token(TokenKind.left_parenthesis, "(", start);
            case ')': return Token(TokenKind.right_parenthesis, ")", start);
            default: break;
        }

        if (isDigit(c) || c == '.') {
            bool saw_digit = isDigit(c);
            bool saw_dot = c == '.';
            while (position < source.length) {
                const d = source[position];
                if (isDigit(d)) {
                    saw_digit = true;
                    ++position;
                } else if (d == '.' && !saw_dot) {
                    saw_dot = true;
                    ++position;
                } else {
                    break;
                }
            }
            if (!saw_digit)
                throw error_at(start, "expected a digit after '.'");

            if (position < source.length && (source[position] == 'e' || source[position] == 'E')) {
                const exponent_marker = position++;
                if (position < source.length && (source[position] == '+' || source[position] == '-'))
                    ++position;
                const exponent_start = position;
                while (position < source.length && isDigit(source[position]))
                    ++position;
                if (position == exponent_start)
                    throw error_at(exponent_marker, "malformed exponent");
            }
            return Token(TokenKind.number, source[start .. position], start);
        }

        if (isAlpha(c) || c == '_') {
            while (position < source.length) {
                const d = source[position];
                if (!(isAlpha(d) || isDigit(d) || d == '_'))
                    break;
                ++position;
            }
            return Token(TokenKind.identifier, source[start .. position], start);
        }

        throw error_at(start, "unexpected character '" ~ c.to!string ~ "'");
    }

    private ParseError error_at(size_t offset, string message) const {
        return new ParseError(message ~ " at byte " ~ offset.to!string);
    }
}

private class Parser {
    private Lexer lexer;
    private Token current;
    private const(double[string]) parameters;

    this(string source, const(double[string]) parameters) {
        lexer = new Lexer(source);
        this.parameters = parameters;
        current = lexer.next();
    }

    Polynomial parse() {
        auto result = parse_addition();
        expect(TokenKind.end, "end of formula");
        return result;
    }

    private Polynomial parse_addition() {
        auto value = parse_multiplication();
        while (current.kind == TokenKind.plus || current.kind == TokenKind.minus) {
            const operation = current.kind;
            advance();
            auto rhs = parse_multiplication();
            value = operation == TokenKind.plus ? value.added(rhs) : value.subtracted(rhs);
        }
        return value;
    }

    private Polynomial parse_multiplication() {
        auto value = parse_negation();
        while (current.kind == TokenKind.multiply || current.kind == TokenKind.divide) {
            const operation = current.kind;
            advance();
            auto rhs = parse_negation();
            if (operation == TokenKind.multiply) {
                value = value.multiplied(rhs);
            } else {
                if (!rhs.is_constant())
                    throw error("a polynomial may only be divided by a scalar");
                const divisor = rhs.constant_value();
                if (divisor == 0.0)
                    throw error("division by zero");
                value = value.scaled(1.0 / divisor);
            }
        }
        return value;
    }

    private Polynomial parse_negation() {
        if (current.kind == TokenKind.minus) {
            advance();
            return parse_power().scaled(-1.0);
        }
        return parse_power();
    }

    private Polynomial parse_power() {
        auto base = parse_primary();
        if (current.kind != TokenKind.power)
            return base;

        advance();
        auto exponent = parse_power(); // right associative, as in Stussak's grammar
        if (!exponent.is_constant())
            throw error("polynomial exponent must be a scalar integer");
        const value = exponent.constant_value();
        const rounded = cast(long) value;
        if (value != cast(double) rounded || rounded < 0 || rounded > uint.max)
            throw error("polynomial exponent must be a non-negative integer");
        return base.power(cast(uint) rounded);
    }

    private Polynomial parse_primary() {
        if (current.kind == TokenKind.number) {
            const token = current;
            advance();
            try {
                return Polynomial(token.text.to!double);
            } catch (Exception) {
                throw new ParseError("invalid number '" ~ token.text ~ "'");
            }
        }

        if (current.kind == TokenKind.identifier) {
            const name = current.text;
            advance();
            if (current.kind == TokenKind.left_parenthesis) {
                advance();
                auto argument = parse_addition();
                expect(TokenKind.right_parenthesis, "')'");
                advance();
                return apply_scalar_function(name, argument);
            }

            if (name == "x" || name == "y" || name == "z")
                return Polynomial.variable(name[0]);

            if (auto value = name in parameters)
                return Polynomial(*value);
            throw error("parameter '" ~ name ~ "' has no value");
        }

        if (current.kind == TokenKind.left_parenthesis) {
            advance();
            auto value = parse_addition();
            expect(TokenKind.right_parenthesis, "')'");
            advance();
            return value;
        }

        throw error("expected a number, name, or parenthesized expression");
    }

    private Polynomial apply_scalar_function(string name, Polynomial argument) {
        if (!argument.is_constant())
            throw error("function '" ~ name ~ "' may only be applied to a scalar parameter expression");
        const x = argument.constant_value();
        double result;
        switch (name) {
            case "neg": result = -x; break;
            case "sin": result = sin(x); break;
            case "cos": result = cos(x); break;
            case "tan": result = tan(x); break;
            case "asin": result = asin(x); break;
            case "acos": result = acos(x); break;
            case "atan": result = atan(x); break;
            case "exp": result = exp(x); break;
            case "log": result = log(x); break;
            case "sqrt": result = sqrt(x); break;
            case "ceil": result = ceil(x); break;
            case "floor": result = floor(x); break;
            case "abs": result = abs(x); break;
            case "sign": result = x < 0.0 ? -1.0 : (x > 0.0 ? 1.0 : 0.0); break;
            default: throw error("unknown scalar function '" ~ name ~ "'");
        }
        return Polynomial(result);
    }

    private void expect(TokenKind kind, string description) {
        if (current.kind != kind)
            throw error("expected " ~ description);
    }

    private void advance() {
        current = lexer.next();
    }

    private ParseError error(string message) const {
        return new ParseError(message ~ " at byte " ~ current.offset.to!string);
    }
}

Polynomial parse_polynomial(string source, const(double[string]) parameters = null) {
    if (source.strip.length == 0)
        throw new ParseError("empty formula");
    return new Parser(source, parameters).parse();
}

unittest {
    auto sphere = parse_polynomial("x^2+y^2+z^2-0.64");
    assert(sphere.total_degree() == 2);

    double[string] parameters = ["a": 2.0];
    auto family = parse_polynomial("x^2+a*y^2-1", parameters);
    assert(family.total_degree() == 2);
    assert(!family.is_constant());
}
