# Original SURFER coefficient values

## Meaning and owner

Continue the actual qualified `ScalarExpression` producer. This stage evaluates
the scalar coefficients that the polynomial front end must prepare. Rays,
intersection/root solving, pixels and rendering remain in the maintained C
numerical layer. No JNI array or frame format is selected by this work.

The semantic source is Christian Stussak's `DoubleValue.java` and
`ValueCalculator.java`: binary64 decimal parsing, ordered binary64 arithmetic,
`Math.pow`, and the exact listed `Math` unary operations. A direct call to the
platform `Double.parseDouble` preserves the original valid-literal contract.
It does not implement or redefine Idriç's broader Text-to-Double cast.

## Type sketch

- `Coefficient = Double` is the explicit original binary64 compatibility type;
  it does not use Idriç's ordinary Float16 default.
- `evaluate_coefficient : (Text → Maybe Coefficient) → ScalarExpression →
  Either Text Coefficient` resolves named parameters through caller-supplied
  bindings and evaluates left before right. Unassigned parameters remain errors.
- The input is already produced by lexical and scalar/polynomial qualification.
  Arbitrary unchecked text is not fed to the platform number parser.
- Primitive operations are named through a tiny `.idr` operator compatibility
  boundary because frontend740bbf2b1 does not admit the current Unicode infix
  declarations. The candidate still comes from that checked Idriç compiler's
  DEX backend; there is no Java, generated-C or other candidate fallback.
- Platform parsing/math calls are pure checked foreign calls with `D`/`J`
  descriptors. Their managed argument/result boxing must preserve register pairs.
- A separate `coefficient_bits : Text → Text` observation export reports
  `Double.doubleToLongBits` through `Long.toHexString`, preserving signed zero
  and canonicalizing NaN. This is a test observation, not a polynomial ABI.

## Backend requirements and evidence

The retained backend153e7fc lacks managed binary64 values and the `D` checked
foreign boundary. The owner continuation in `android-NDK` implements these
capabilities separately; its exact tested revision must be pinned before this
producer can claim DEX execution. General Double exports, generic Text casts,
Float32 and primitive-array/JNI contracts remain distinct capabilities.

The actual evaluator and observation export typechecked through the retained
frontend740bbf2b1. The working binary64 backend then generated the full producer
DEX, including the real parser and qualifier. Pinned baksmali decoded its
`coefficient_bits` export, the four Double arithmetic operations, every listed
Math call, and the parsing/canonical-bit foreign calls. The first local DEX was
SHA256 `e938b270ebaf7d78bd013b397485de5eb5fc22f565569e0c6fdf5e8e4b09c695`.
That working backend is published at
`73dc47634b100e689247ff24fed518a040cdf414`. The application workflow pins that
exact revision; hosted dependency qualification remains a separate observation.

The qualification uses the actual evaluator, with a source mutation changing
its sum implementation to subtraction. The independent observer requires exact
bits for values wider than Float32 can represent, signed zero, infinity, NaN,
ordered arithmetic and all supported unary-function paths. It also executes
the retained original jsurf parser/ValueCalculator as a separate reference on
the same ART runtime; original Java source is never compiled into the candidate.
Unbound names and polynomial-valued coefficients have explicit error checks.
Positive caller-supplied parameter bindings remain unqualified by this observer.

This replaces the earlier standalone `CoefficientCheck.idric` admission gate.
That probe required generic Text casts and `Show Double`, which the actual
producer does not use. Its diagnostic remains recorded in the formula-front-end
attempt; those broader language operations remain explicitly unsupported.
The replacement requires original-platform parsing/math and stronger bit-level
observations rather than weakening the binary64 requirement.

PENDING: hosted source generation, repeated-byte comparison, original-oracle
comparison, and actual ART execution of the producer and compiled source
mutation. No host numerical execution, polynomial expansion, APK or physical
device result is inferred from successful generation or decoding.
