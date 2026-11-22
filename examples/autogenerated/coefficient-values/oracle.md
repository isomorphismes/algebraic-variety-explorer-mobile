# Original coefficient observation

`OriginalCoefficientOracle.smali` is a test-only adapter over the retained
original jsurf parser and `ValueCalculator`. It contains no candidate
coefficient implementation and must not be included in the application APK.
Its only callable observation is `valueBits : String -> String`.

The adapter parses through `AlgebraicExpressionParser.parse`, requires an
original `DoubleOperation`, evaluates by the original visitor protocol with a
new `ValueCalculator`, and formats `Double.doubleToLongBits` using
`Long.toHexString`. The observation preserves signed zero and canonicalizes
NaN exactly as the candidate observation does. Non-scalar polynomial expressions
return the explicit coefficient-category error. No parameter bindings are set.

Only the evaluation call catches `UnsupportedOperationException`. The adapter
maps it to an error result only when its message has the original
unassigned-parameter prefix and closing quote. Other unsupported operations are
rethrown. Parser exceptions, original ANTLR reporting crashes, null parser
results, wrong visitor result types and all other failures remain failures.

`prepare-oracle.grease` consumes original classes and locked dependency JARs
archived by the existing original-jsurf admission stage. It packages only the
original `de.mfo.jsurf` classes, excluding application/preview/JUnit test
classes, and converts these with the project's existing SDK platform35 and
build-tools35.0.1 pins. It records the original source identity, source hashes,
D8 identity/version, input artifact hashes, output hash and independent decoded
signatures. This is reference-oracle packaging, never a fallback candidate
compiler or numerical implementation.

Local observation: the adapter assembled with the retained pinned smali3.0.10
JAR and independently decoded with baksmali3.0.10. The public method and original
parser/visitor/numeric descriptors were present. The host currently has no SDK
D8 or JDK `jar` executable; the prep helper and ART behavior are therefore
PENDING in the hosted workflow. Assembly is not execution or semantic parity.
