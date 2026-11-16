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
  shared `FormulaExports.idric` adapter supplies the direct-DEX
  exports and required nullary entry; the semantic library has no main. The
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
5. Single groups preserve expression category and decimal-literal provenance.
   Consecutive groups and an explicitly grouped function argument preserve the
   original generated walker's repeated-prefix refusal. That inherited parser
   limitation is named explicitly rather than presented as a mathematical rule.

The grouping boundary was executed using archived original classes from source
`f61f534fffbe29e41a19ae9133ab11301404a793`, without recompilation, on OpenJDK
21.0.13. The original preview accepted `x^(2)`, `sin(2)`, `(sin(2))` and
`(x)+(y)` cleanly; `x^((2))`, `sin((2))` and `((sin(2)))` exited 1 through
the recorded generated-walker failure chains. The qualifier now explicitly
rejects `Grouped (Grouped _)` and `Called _ (Grouped _)`, retaining ordinary
single groups. Host/source and ART regressions cover those same cases.

Leading-zero range comparison is a separate boundary. `Integer.parseInt` accepts
leading zeroes when supplied a decimal lexeme, so direct AST qualification strips
them only while comparing against the signed 32-bit limit and preserves the
entire original lexeme in the typed exponent and overflow notice. Expression
lexing still rejects leading-zero decimal source. The original generated lexer
reports lexical errors and can recover enough to produce an image for such
source; an exit-zero preview alone is therefore not clean parse evidence.
The original reference harness rejects parse diagnostics in clean acceptance
cases and records recovery-with-output separately in its observation matrix.

## Verification and integration

The initial working source passed its host suite through the exact retained
frontend740bbf2b1 and generated a combined parser/qualification DEX through
backend153e7fc. Pinned baksmali decoded both Text exports and the independent
combined runner assembled. `PolynomialQualificationCheck.idric` tests structural distinctions,
valid/invalid powers and divisors, named coefficients, supported functions and
overflow reporting. It must be compiled alongside the unchanged
`AlgebraicExpression.idric` and the new `PolynomialQualification.idric`.

The existing formula workflow copies the two production modules into the same
staged source directory, compiles/runs the new check separately on the host,
then generates direct DEX from the shared `FormulaExports.idric` adapter and
observes its exported `formula_qualification(Text) → Text` method. Existing parser checks and its
compiled mutation remain required. Do not present this source or host check as
F64, PreparedSurface/JNI, APK or physical-device acceptance.

Run43787844128 at source95040ff passed the host suite and generated/decoded the
candidate and both compiled source mutations. Run43789536232 at sourcef61f534
repeated those observations, then exposed a second inherited walker failure in
the original nested-group oracle. Its evidence artifact14192226224 had ZIP
SHA256 `0ed6386e039640cf9c8a78257b3dbe1c565ef778faf6f4b0efab861e4960d3db`.
The original Java grouping replay above used the archived classes and locked
dependencies from that artifact, with per-case statuses and outputs retained
separately. The oracle recognizes only the observed grammar/reporting chains;
unrelated crashes remain failures.

The archived compiler/driver came from run43785829334. Its ZIP and executable
hashes were verified before local replay. The original launchers refer to the
former runner, so compiler replay uses the archived exact Chez binary and its
explicit boot/runtime/package paths. The Grease runtime had not been fully
retained; the updated retention step now includes it for subsequent diagnostic
replay. The updated grouping-source host suite now executes PASS through the
exact retained frontend, including explicit repeated-group refusals, original
single-group positives, direct-AST exponent provenance and lexical refusals.
The updated combined source also emits direct DEX and its independent runner
assembles. At application sourced4bc9b3, run43792136217 then executed the actual
updated parser and qualifier on API34 ART and rejected their compiled source
mutations with designated statuses73/75. The original semantic-admission corpus
completed, preserving clean acceptance, explicit walker refusals and leading-zero
lexical-recovery output as separate outcomes. That same run also passed the
actual scalar coefficient evaluator against the original jsurf bit oracle.

## Remaining work

The next semantic stage must evaluate named/numeric scalar expressions at the
preserved binary64 boundary, simplify the original typed polynomial operations,
form their three symbolic derivatives, and only then expand each in the
original numerical order. Family degree is taken before simplification. This
qualification stage does not claim the established prepared-surface producer
or managed/native transport is implemented; see the native handoff note.
