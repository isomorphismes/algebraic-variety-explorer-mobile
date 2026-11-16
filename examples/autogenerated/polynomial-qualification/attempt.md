# Qualify Explorer expressions as polynomial or scalar

## Purpose and source

Continue the real lexer/parser in `c-lua/idric/AlgebraicExpression.idric` with
the semantic distinctions made by Christian Stussak's
`AlgebraicExpressionWalker.g` (copyright 2008, Apache-2.0). Parsing an expression
tree is not the same as qualifying a polynomial. In particular, `x/y`,
`sin(x)` and `x^2.0` have valid expression syntax but the original walker rejects
them.

This stage preserves that distinction before expansion, numeric evaluation,
derivatives, rendering or Android transport. It does not select a new sparse
polynomial representation or ABI.

## Types and operations

- `ScalarExpression` describes original `DoubleOperation` expressions without
  evaluating them: numeric lexemes, named coefficients, arithmetic and supported
  unary functions.
- `PolynomialExpression` describes original polynomial operations: exact
  `x`/`y`/`z` coordinates, lifted scalar coefficients, arithmetic, division by a
  scalar and nonnegative decimal-literal powers.
- `QualifiedExpression` distinguishes scalar expressions from expressions that
  have entered the polynomial-operation family. This is the original walker's
  class distinction, not a claim that an expression has been algebraically
  simplified. For example `x-x` remains a polynomial expression.
- `DecimalExponent` retains the original decimal source. In-range literals and
  inherited overflow-to-zero behavior have different constructors. No enormous
  unary `Number` is materialized merely to retain an exponent.
- `QualificationNotice` records inherited exponent overflow. The Java walker
  catches `Integer.parseInt` overflow and substitutes zero. Qualification must
  expose that fact rather than silently treating an overflowing exponent as an
  ordinary zero or silently changing it into rejection.
- `qualify_expression : Expression → Either QualificationError QualifiedFormula`
  converts the existing syntax tree. Named coefficients other than exact lower
  case `x`, `y`, `z` stay symbolic; environment binding is a later stage.
- `qualify_formula : Text → Either FormulaFailure QualifiedFormula` composes the
  existing parser with the semantic stage. It preserves syntax failures and
  semantic failures separately.
- `formula_qualification : Text → Text` is a small observation function. The
  separate `PolynomialQualificationExports.idric` supplies the direct-DEX
  export and required nullary entry; the semantic library has no main. The
  report does not replace the typed result used by a future polynomial producer.

All operations in this stage are pure. Required runtime capabilities are lists,
records, algebraic cases, Text/Char traversal and recursive checked calls. No
F64 arithmetic is performed; that capability is being qualified separately.

## Invariants and error states

1. Both scalar operands produce a scalar arithmetic expression. Once either
   operand has entered the polynomial family, addition/subtraction/product
   retain polynomial ownership even if cancellation could simplify the value.
2. A polynomial divisor is rejected before any algebraic simplification.
   Qualification alone does not reject a scalar zero divisor: that belongs to
   the original numerical behavior, not this class distinction.
3. A polynomial power requires a decimal-literal exponent, allowing grouped
   decimal literals but not floating/scientific literals, arithmetic expressions
   or negation. Scalar powers retain the original scalar rule.
4. Function names are exactly the original `DoubleUnaryOperation.Op` names;
   functions require a scalar argument. The grammar exposes one argument only.
5. Groups preserve expression category and decimal-literal provenance.

One inherited parser/walker interaction remains an oracle question: the grammar
rewrites grouping into `PARENTHESES` prefixes, and the tree walker consumes one
optional prefix at each operation. Verify nested grouping such as `x^((2))`
against the actual Java parser before claiming full grouping parity. This module
retains group nodes and their scalar/polynomial meaning; it does not erase that
source-level question by claiming all inherited grouping has been qualified.

## Verification and integration

PENDING: source checks and execution through the pinned frontend and direct DEX
backend. `PolynomialQualificationCheck.idric` tests structural distinctions,
valid/invalid powers and divisors, named coefficients, supported functions and
overflow reporting. It must be compiled alongside the unchanged
`AlgebraicExpression.idric` and the new `PolynomialQualification.idric`.

Suggested integration with the existing formula qualification: copy the two
production modules into the same staged source directory, compile/run the new
check separately on the host, then generate direct DEX from the separate
`PolynomialQualificationExports.idric` adapter and observe its exported
`formula_qualification(Text) → Text` method. Existing parser checks and its
compiled mutation remain required. Do not present this source or host check as
F64, PreparedSurface/JNI, APK or physical-device acceptance.

Local checks: `git diff --cached --check` passed in the isolated checkout.
`command -v idric idris2 grease` found no local compiler/runtime entrypoint, so
no host or DEX execution is claimed from this checkout. The parent task owns
hosted qualification through the already selected pinned compiler.

## Remaining work

The next semantic stage must evaluate named/numeric scalar expressions at the
preserved binary64 boundary and expand the typed polynomial operations with the
original numerical order, then form derivatives and the established prepared
surface. This qualification stage does not claim those stages are implemented.
