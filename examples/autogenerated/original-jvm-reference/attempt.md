# Original JVM reference runner

## Purpose and boundary

Keep the existing jsurf parser tests and preview executable as an explicitly
original-reference path after the application build moves to checked Idriç
DEX and C. This helper cannot build an APK. It never compiles MainActivity,
the old Android controller, or another platform-dependent application source.

## Types and effects

The inputs are an absolute Explorer repository path and one of two actions:
`test`, or `preview [ABSOLUTE_OUTPUT [FORMULA]]`. The output of `test` is the
original JUnit process result. The output of `preview` is the original
`JsurfPreview` PPM and its process result. The formula is passed as one argument
without shell evaluation. Compilation produces `.build/test/classes`, preserving
the existing numerical comparison consumer's classpath.

The effects are checking JDK 17, verifying the four existing locked reference
jars through `polynomial-qualification/prepare-dependencies.grease`, replacing
only the reference test work directory, compiling the root `de.mfo.jsurf`
sources and the two example records, staging each `.test.java` under its Java
class filename, and running the selected original entrypoint. The classes are
never inputs to the candidate APK producer. Compiler and execution receipts
retain their separate results; a failed compilation cannot execute old classes.

Grease is the program's implementation language because this is composition of
existing host tools and an intentionally retained foreign Java oracle. Rewriting
the oracle in Idriç would remove its value as evidence about the original.

## Verification

The exact retained Grease implementation at
`f19c94c6df18cddbdc1e81463e5bd689533e3c13` parses the helper. Local execution
must stop before removing prior classes when JDK 17 is absent. This container
currently provides a Java 21 runtime and no Java compiler; original JDK 17
compilation, JUnit execution and preview execution remain NOT_RUN here. The
hosted JDK 17 jobs must execute both actions before this helper is qualified.

## Language work and fallback

No fallback. The candidate Idriç/DEX build is a separate owner and does not
inherit a pass from these original-reference tests.
