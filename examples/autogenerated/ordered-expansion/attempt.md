# Ordered SURFER polynomial expansion

## Owner and input meaning

Continue the actual Idriç semantic producer after `PreparedFormula`. This is
Christian Stussak's `Expand`/`XYZPolynomial` algorithm, not the C bootstrap's
formula compiler and not ray substitution. Preparation computes original
family degree, simplifies parameters and constructs the three derivative ASTs
before this stage expands the surface and derivatives separately.

## Type sketch before implementation

- `ExpandedTerm` carries an explicit binary64 `Coefficient` and three signed32
  exponents. This is a managed semantic value, not a serialized JNI record.
- `ExpandedPolynomial` is the original lexicographically ordered term sequence.
  Addition may retain a zero coefficient at its original monomial. Product
  collection drops zero groups and represents an all-zero result as one
  constant positive-zero term.
- `ExpandedSurface` retains `family_degree` from preparation and four separately
  expanded polynomials. It never recomputes family degree from collected terms.
- `ExpansionLimits` uses caller-supplied Integer counters for maximum terms
  and products per multiplication. It does not materialize large unary budget
  literals. Source size and the fixed signed32 power traversal bound separately
  bound the number of operations. Exceeding these limits is an explicit
  resource refusal. They do not select the C bootstrap's fixed128-term/degree8
  model or establish unrestricted equivalence.
- Expansion returns a typed failure for missing parameters, nonfinite
  coefficients/intermediate values, resource exhaustion or exponents outside
  the original nonnegative signed-byte-safe range. Every retained/intermediate
  term must have coordinate exponents and total degree in `0…127`. This avoids
  silently translating original byte overflow into different signed32 math.

## Numerical order to preserve

Addition merges ordered monomials with one left-plus-right addition, including
zero results. Subtraction negates the right sequence then merges. Products
enumerate left terms outside/right terms inside, then perform a stable sort by
monomial and coefficient, using the original comparator's sign/equality rules.
Within a monomial group, Kahan starts from its first coefficient rather than
adding it to zero. Division evaluates the divisor once, takes its reciprocal
once, then scales with reciprocal as the left operand. Power uses the original
base/result initialization and decrement/odd-product/square/halve sequence,
including the final unused square. Checked refusals apply to those intermediate
operations too, so the admitted subset is intentionally narrower than every
finite final polynomial that the original happens to return.

NaN makes the original coefficient comparator non-total; nonfinite values are
therefore an explicit unsupported expansion boundary. Scalar evaluation still
preserves original NaN/infinity behavior in its own separately qualified stage.
No decimal coefficient formatting/reparsing, alternate backend, Java/Kotlin
candidate source or C semantic fallback is permitted.

## Intended evidence

Compile the real producer through frontend740bbf2b1 and the direct DEX backend
with its checked binary64/Int32 conversion support. Decode independently and
compare ordered exponent tuples and exact coefficient bits against original
Java/jsurf production getters plus `Expand`, using a test-only Smali observer.
Include cancellation retained by addition, collection order/Kahan cases,
reciprocal scaling, power order, original presets and three separately prepared
derivatives. Compile mutations for family-degree provenance and collection
order; the independent observer must reject them on ART.

## Observed source and generation

`OrderedExpansion.idric` typechecks through the exact retained
frontend740bbf2b1 and emits through the rebuilt backend tree published as
`682515f1c90c77b509940f90a696965d6139b5bd`. The actual producer/observation graph
is308572 bytes, SHA256
`c49f4432978d3e6b06adab943982ad359a75dd11faa35e3e1ab192dbb0d3bc20`.
Pinned baksmali independently decoded all three pure Text exports and the
required signed Int32-to-binary64 instruction. A repeated emission is identical.

The two actual source mutations emit different, independently decodable DEX:
zeroing the Kahan correction gives
`b57701201ed6ff18bc64d1e6a3ebe334cf94af2f9565f137995ce81b96968b60`;
replacing preserved family degree with zero gives
`8c1e45c3a811b83dd2d55e5ecf95f846dc9a75ca4a107837bc46dffff8a53212`.
The independent candidate/original observation runner assembles separately.
The parent review added one fixed elementary `x`-plane report, checked first
against the original and then the candidate, so an axis-label error in the
original adapter cannot pass merely because both reports share that mistake.
Both maintained Grease helpers parse through the recovered exact pinned Grease
runtime. These are source/generation/decoder observations, not ART behavior.

The first source check rejected the reserved local name `total`; it was changed
to descriptive `updated_sum`. The first DEX attempt then refused an implicit
Integer-to-Double conversion in `OrderedExpansion.{collect_groups:1}`. The
coefficient identities are now explicitly binary64 `0.0`/`1.0`, as in the
original numerical code. Exponents and resource counters remain integral. No
coefficient decimal formatting/reparsing or compiler fallback was introduced.
Generic Integer-to-Double conversion remains a separate unsupported language
boundary; exponent conversion uses the implemented checked Int32 instruction.

`verify.grease` compiles the actual producer, deterministic repeat and both
mutants, decodes independently and assembles only the observer. `observe.grease`
requires byte-identical target roundtrips, compares exact original ordered
terms for the seven presets, user's quartic and focused semantic/rounding cases,
and requires both source mutants to exit77 with their designated assertion.
It also checks explicit resource, nonfinite, exponent and missing-parameter
refusals. The Kahan corpus has four same-monomial contributions sorted as
`[-1e16,1,1,1e16]`, which distinguish compensated summation from zeroed
compensation. The original Java program remains a separate reference DEX.

At application source `5d43e830c3180db68b6ce4e3bb40e187606fdb68`,
run43795348438 completed the full maintained helper and actual API34 ART
comparison. All seven presets, the user's quartic, cancellation/rounding/Kahan
cases, bound radius and explicit refusal cases passed. The fixed plane report
matched both original and candidate. Both compiled Kahan/family mutations
failed with designated status77 and the expected assertion marker.
Evidence artifact14194851821 has ZIP SHA256
`edfe268493a2ad0a03dc286386bea9fe3e0dff937fe97ba6214ef01b92dc6cb0`.
No C/native transfer, APK or physical-device acceptance follows from this
managed-stage ART pass.
