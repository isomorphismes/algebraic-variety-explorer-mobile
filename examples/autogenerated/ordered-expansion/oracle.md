# Original ordered-expansion observation

`OriginalExpansionOracle.smali` is an independent test-only adapter. It invokes
the unchanged original `CPUAlgebraicSurfaceRenderer`, sets its source family,
and uses the original public family-degree, simplified-surface and gradient
getters. It then invokes the unchanged original `Expand` visitor separately on
each of those four expressions. The adapter does not contain a candidate
simplifier, differentiator, polynomial arithmetic or collection algorithm.

The observation is
`family=<degree>;surface=<terms>;dx=<terms>;dy=<terms>;dz=<terms>`.
Each original term is printed in its actual existing order as
`xExponent,yExponent,zExponent:canonicalCoefficientBits`, separated by `|`.
Coefficient bits use `Double.doubleToLongBits` followed by `Long.toHexString`;
signed zero is preserved and NaN is canonicalized. Original zero terms are
retained exactly as exposed by the original term array. Package membership is
needed only to read original package-private term fields and `getTerms()`.

`original_expansion(String)` sets no parameter bindings.
`original_expansion_with_radius(String)` sets the original renderer's `radius`
parameter to binary64 2.0 before asking for its prepared expressions.
Errors and original parser failures propagate; no failed result is normalized
into an ordinary term observation.

This class belongs only in the independent observation runner alongside the
retained original jsurf oracle DEX. It must never be included in the candidate
application. The original renderer constructor creates a lazy fixed worker
pool, but this observer submits no render work and never calls `draw`.

Local assembly/independent decoding and actual ART execution are separate
evidence levels. The hosted observer must compare the actual candidate export
against this original observation and independent expected constants, and must
reject a compiled candidate source mutation. No APK, native transfer, numerical
ray-tracing or physical-device result follows from this observation alone.

Local source inspection used the original files at
`d4bc9b3c84d8adeb4c82d1354c84833aace5aec9`. The observer assembled with the
retained smali3.0.10 and independently decoded with baksmali3.0.10. Its DEX
SHA256 was `7d6b344df1b525c4124ee545eb6309f35c3c2d80c5a77a0acdfd557adba65c9f`.
Decoded instructions include the original renderer constructor/family setup,
all four production expression getters, original `Expand` visitor dispatch,
the original `getTerms()` array and signed-byte exponent fields, and bit-text
formatting. ART execution remains PENDING.
