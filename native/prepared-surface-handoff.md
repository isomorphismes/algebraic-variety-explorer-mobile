# Semantic preparation and the numerical handoff

Source audit at `f61f534fffbe29e41a19ae9133ab11301404a793`.
The audit below preserves the original ownership and order requirements.
Subsequent implementation and execution evidence is recorded here separately.

## Implemented stages and remaining acceptance

`PreparedFormula.idric` now owns family degree, parameter simplification and
symbolic derivatives. Its actual source passed API34 ART comparisons with the
retained original visitors at `0f980e5a00761aac145d756ec81ca4da819f863f`
([run43794450670](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43794450670)).

`OrderedExpansion.idric` now owns the ordered sparse expansion below. At
`5d43e830c3180db68b6ce4e3bb40e187606fdb68`, actual API34 ART execution matched
the original coefficient bits, exponents, family degree and all three gradients
for the seven presets, the user quartic and sensitive collection cases. Compiled
Kahan and family-degree mutations were rejected
([run43795348438](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43795348438)).
The producer explicitly refuses nonfinite intermediates, unsafe signed-byte
exponents and caller-specified resource limits; this is bounded equivalence.

`surfer_surface_store` and `android/prepared_surface_jni` now implement copied
immutable snapshots, checked replacement/release and worker borrows. The first
host run at `91d8e7a16c13b6dbca1f8e5583849ee7f9079b4d` passed strict numerical,
allocation and sanitizer checks, then stopped at a stale expected mutation
diagnostic before the receiver step
([run43800812201](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43800812201)).
No receiver execution is inferred from that run. The source-level
`PreparedSurfaceTransfer.idric` connects the real expanded values to primitive
arrays and generated JNI; its actual native/ART observation remains pending.
After reconstruction of the same qualified ICK compiler, strict host receiver
tests passed. The fixed and frozen numerical observers separately produced
identical 32179-byte outputs for the seven presets, SHA256
`65f44c201676e330068804e4059a369cb6479efa1673660fd78a42681a1f55ca`.
Local ASan/UBSan receiver execution passed with leak detection explicitly
disabled; the maintained leak-enabled run stops because this environment uses
ptrace. Hosted leak-enabled receiver execution remains required.

The accepted normal Activity still needs checked callback returns and state,
additional lifecycle methods, float-valued touch/scale calls and reliable
provider-stream cleanup. The NativeActivity keypad remains a bootstrap. These
semantic and transport stages do not remove the shipping Java implementation
or establish a complete APK or physical-device behavior.

## Existing ownership

The retained application outcome is the typed Idriç semantic front end, the
maintained binary64 C numerical renderer, and a direct-DEX Android framework
interface. The Idriç stage prepares the surface meaning and its three
derivatives. Ray substitution, clipping, root selection, normals, shading and
pixels remain numerical-layer work.

The C numerical core already consumes `surfer_prepared_surface` in
`surfer_raytracer.h`: one `int32_t family_degree` and four
`surfer_sparse_polynomial` values. Each polynomial has a borrowed
`const surfer_term *terms` and `size_t term_count`; each term has a binary64
coefficient and three `int32_t` exponents. This is an in-process C interface.
The record itself has no version field or transport layout. Those now belong
to the separate copied-snapshot interface; the pointer fields remain an
in-process C interface rather than a serializable representation.

`android/formula.h` is a bounded C bootstrap, not that missing transport.
Its `ave_formula` embeds storage and points into itself. Its explicit
do-not-copy rule must not be lost by treating the record as serializable.

## Original preparation order

The production Java oracle is more specific than differentiating collected
terms:

1. `AlgebraicSurfaceRenderer.setSurfaceFamily` stores the parsed family and
   applies `DegreeCalculator` to that original expression.
2. `getSurfaceExpression` applies `Simplificator` with the current parameter
   bindings. This evaluates scalar operations when possible, removes literal
   zero/one polynomial operands, and removes polynomial powers zero and one.
3. Each `getGradient*Expression` applies `Differentiator` to that concrete
   simplified expression. It preserves the product rule and the original
   construction/evaluation order.
4. `TransformedPolynomialRowSubstitutor` and its gradient variant apply
   `Expand` separately to the surface and the three derivative expressions,
   then perform the camera/ray substitution and row/column specializations.

The separate `family_degree` is intentional. For `x^2-x^2+y`, the original
family degree is two although collection leaves a linear polynomial. The C
root layer selects its degree-below-two closed-form path from this family
value, so recomputing it from surviving terms changes behavior.

The standalone `Differentiator` contains unusual exponent-zero/one branches.
Those branches alone do not describe the production renderer: the preceding
`Simplificator` removes those powers. Preserve and test the production
sequence rather than reproducing an unreachable defect or silently changing
the sequence to make a mathematically convenient derivative implementation.

## Expansion order that remains material

`Expand` and `XYZPolynomial` already provide a source-owned term representation;
there is no reason to invent a different representation from the current
bootstrap tests.

- Addition merges lexicographically ordered exponent lists. Equal terms use
  one ordered binary64 addition and are retained even if that sum is zero.
- Subtraction negates the right polynomial and then uses addition.
- Multiplication enumerates left terms outermost, right terms innermost, then
  sorts by exponents and coefficient before collecting equal monomials.
  Collection uses the original Kahan summation sequence and removes zero sums;
  an all-zero result becomes one constant-zero term.
- Polynomial division computes the reciprocal once, then scales each term.
  This differs in rounding from dividing every coefficient separately.
- Power uses the original repeated-squaring sequence. Starting from a generic
  identity accumulator would change its multiplication order.
- Original `XYZPolynomial.Term` exponent fields are signed Java bytes and
  arithmetic casts can wrap. The C boundary fields are signed 32-bit values.
  Resource/degree bounds and treatment of original overflow must be recorded
  explicitly before claiming unrestricted equivalence.

Derivative expansion after symbolic differentiation can round differently
from differentiating a previously expanded polynomial. A conventional symbolic
formula is not sufficient evidence for this numerical boundary.

## Semantic-stage requirements

The original requirements for semantic preparation, now implemented separately
from rendering, use these conceptual types:

- `PreparedCoefficient`: the explicit original binary64 compatibility value.
- `PreparedPolynomial`: the original ordered polynomial terms with the
  collection state/ordering needed to preserve the algorithm above.
- `PreparedSurface`: family degree from the qualified original expression,
  prepared surface, and three separately prepared derivatives.
- `prepare_surface`: parameter bindings and a qualified formula to either an
  explicit preparation failure or one complete immutable surface snapshot.

These are semantic-stage design requirements, not names or a final exported
ABI. Keep syntax/meaning failures, missing parameters, resource refusals and
transport failures distinguishable. An invalid replacement must preserve the
previous usable surface. Do not use the C bootstrap as the candidate Idriç
producer.

The accepted Boundary B′ design in the September translation audit specifies
the logical managed/native representation; arrays are not a newly selected
wire format:

| Value | Representation |
| --- | --- |
| ABI version and original family degree | Two Int32 scalars |
| Four polynomial ranges | Five Int32 offsets |
| Concatenated coefficients | F64 primitive array |
| Corresponding exponents | Int32 primitive array, interleaved x/y/z |
| Prepared native snapshot | Opaque jlong handle |

The native prepare call must check lengths, ordering, bounds, coefficients,
version and integer size arithmetic, then copy the four polynomials into one
native-owned immutable snapshot. Publish only after every validation and copy
succeeds, and keep that snapshot alive while any render worker uses it.
Replacement and destruction cannot race an active render. No AST, parameter
object graph or serialized Text crosses this cut. The receiver is implemented;
the full actual generated producer-to-JNI path still requires execution. Do not retain
temporary array access pointers through asynchronous rendering.

## Required observations

Use the retained original Java/jsurf program as the oracle, never the shipping
candidate. Record exact source and dependency identities with the outputs.

- Compare family degree, ordered exponent tuples and coefficient bits for all
  seven shipped examples, the user's quartic, and a parameterized family.
- Include cancellation such as `x^2-x^2+y`, literal zero/one simplification,
  zero powers, grouped bases, scalar quotient scaling, and missing parameters.
- Include numerically sensitive collection/power cases that distinguish naive
  summation, altered multiplication order, narrower coefficients and deriving
  after expansion. Keep signed zero and nonfinite treatment explicit.
- Execute actual producer code on ART. Require targeted compiled source
  mutations to fail the independent observer for collection order, derivative
  preparation and family-degree provenance.
- Validate the eventual JNI receiver independently with malformed lengths,
  invalid exponents/counts, coefficient bit transport, partial allocation
  failure, replacement failure and worker lifetime cases.

These observations will qualify semantic preparation and transport only.
`native/README.md` still records numerical substitution/gradient and adaptive
antialiasing gaps. Issue #17 separately requires repeated/tangent/near-multiple
roots and the link from the selected root to the final pixel. Existing bounded
seven-image tests, a compiler pass or an emulator launch do not settle those
obligations or physical C67/A1 acceptance.
