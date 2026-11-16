# Original semantic preparation before expansion

## Purpose and type sketch

Continue the application's actual qualified formula, preserving the production
sequence in `AlgebraicSurfaceRenderer`, `Simplificator` and `Differentiator`.
This stage does not expand terms, choose a JNI format or move ray numerics out
of the maintained C layer.

- `PreparedScalar` distinguishes an already evaluated binary64 coefficient,
  an unassigned named coefficient, a scalar binary calculation and a scalar
  function application. An unevaluated calculation is not a literal value.
- `PreparedExpression` distinguishes those scalar operations from original
  polynomial coordinate, sum, difference, product, quotient, power and negation
  operations. A polynomial wrapper may contain an expression which became
  scalar during simplification, just as the original Java operation classes do.
- Polynomial powers retain explicit `Int32` exponents. Original overflowing
  decimal exponents retain the qualifier's notice and become zero; validated
  in-range exponent text is converted to `Int32` without rounding.
- `PreparedFormula` contains the original family degree, simplified surface,
  and its three separately constructed symbolic derivatives. It also retains
  qualification notices. It is an immutable managed semantic value, not the C
  `surfer_prepared_surface` or a transfer record.
- `prepare_formula` computes family degree before binding/simplification,
  lowers the original operation classes, simplifies with one caller-supplied
  parameter environment, then differentiates the simplified expression once
  for each coordinate. Expansion and collection remain later work.
- `evaluate_prepared_scalar` evaluates the scalar operation objects retained by
  that one simplification pass when the later expansion stage needs them. It
  shares this stage's calculation dispatch and the existing coefficient owner,
  preserves left-before-right evaluation, and reports unassigned parameters.

## Original behavior and explicit limits

Family-degree arithmetic is evaluated exactly, with an explicit refusal if an
original degree operation would overflow nonnegative signed32 range. This is a
bounded refusal, not a claim to reproduce Java's wrapped family-degree result.
Malformed manually constructed exponent provenance also refuses. Source-level
leading-zero decimal admission remains the parser's responsibility; Java
`parseInt` accepting zeros alone does not establish grammar admission.

Scalar folding uses `CoefficientValue`, with only the needed parsing, power and
unary-operation helpers exported from that owner. The new stage introduces no
second numeric implementation. Original polynomial zero/one shortcuts apply
only to already evaluated coefficient values. Reclassification of polynomial
addition/multiplication to a scalar operation does not eagerly fold that new
operation: the original visitor does not revisit it at that point. The special
zero-left subtraction path does revisit a newly constructed negation, as the
original source does.

That revisit is implemented with explicit source-node-derived fuel, so the
whole checked implementation remains total. Every recursive descent consumes
fuel; a rewritten zero-left subtraction is strictly smaller than its original
node because its left child has been removed. Exhaustion remains an explicit
preparation failure, not a partial result or a hidden alternate implementation.

Symbolic differentiation preserves original constructor and operand order,
including the product rule and distinct power-two branch. It does not derive
from expanded/collected coefficients. Powers zero/one are simplified before
the production derivative pass. No unassigned-parameter error is invented at
this stage: unresolved named scalar values remain symbolic for the later
expansion/evaluation boundary to reject if still unassigned.

The real implementation requires `Int32 -> Double` conversion for the original
power exponent coefficient. It uses the semantic `cast` directly. The numeric
backend owner must implement checked integral-to-binary64 lowering or refuse
it explicitly; formatting/reparsing an exponent is not a fallback.

## Evidence

The implemented source and separate export adapter typechecked through the
retained frontend740bbf2b1. The local numeric-owner driver then emitted a
271084-byte DEX containing both pure Text exports and the actual `int-to-double`
instruction. A repeated build produced identical bytes. The candidate hash is
`4be9c9fb48b16a7c28599e0135d1f906a99679e501c4802dd59125541e7d759e`.
Two actual compiled source mutations also emitted and independently decoded:
an eager revisit of newly reclassified scalar calculations and a broken product
rule. Their hashes are respectively
`3ef9bac32deb46393cd591de987be88bcec6e877d49d92496a66b7050572ac96`
and `e1e9b0db0cb83ec91d834f4bde786f37c3be92d52876fae63655fee200f55818`.

The driver executable hash was
`6e31f96b7f3c0fd5c2b83624a843b7a5266193bbba606b3b9a6f086759240963`;
its owner's local checkout was observed at
`392665849de43aca1a3c73ae6ff60d9eac7068b1`. These local observations do not
stand in for hosted qualification of the script's exact remote backend pin.
The staged sources included the current application qualifier grouping fixes.

`PreparationRunner.smali` has 26 structural/exact-bit cases. Twenty-three first
check independently written expectations against original jsurf's actual
`DegreeCalculator`, `Simplificator` and `Differentiator`, accessed through a
getter-only observer. The observer does not implement those semantic passes.
The remaining cases separately check inherited exponent-overflow notice and
the explicit family-degree overflow refusals; the wrapped Java overflow result
is not claimed equivalent. Cases include family-degree retention after the
surface becomes linear, large exact exponent coefficients, signed zero,
scalar-operation reclassification, parameter substitution and derivative order.
Both independent smali classes assembled; actual ART execution remains PENDING.

The scripts require positive ART behavior and designated status77 rejection of
both compiled mutants. Original-oracle expectation failure is distinguished by
status78. No expansion, C/JNI transfer, renderer, APK or physical-device result
is inferred from compilation, assembly or independent decoding.
