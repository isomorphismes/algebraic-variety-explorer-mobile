# Original Java AA observation

`OriginalAdaptiveAAOracle.java` is a test-only package-local input/output
adapter. It extracts every original Java source from immutable public baseline
`cfd543e1886bc6b7eb9e1ede6641569b673aac8d`, selects only its root
`de.mfo.jsurf` package sources, and executes
the actual `RenderingTask`, `AntiAliasingPattern`, root finder, row/column
substitutors and shading methods. It contains no replacement antialiasing,
polynomial, ray or root implementation. The current test adapter is compiled
separately with that frozen source closure; mutable candidate Java cannot enter
the oracle. This is a different owner from the C
candidate; tests never obtain expected output by calling a second C renderer.

The full-frame corpus uses one original `RenderingTask` over the full canvas.
`CPUAlgebraicSurfaceRenderer.draw` partitions overlapping tasks according to the
host's available processors; that scheduling can change the rounding of
tile-local start-plus-increment coordinates. Thread partition and cancellation
parity are deliberately outside these numerical observations.

The camera is the application's orthographic camera with height `2.15 / zoom`,
camera translation `m23 = -1`, and yaw-then-pitch surface rotation. Both materials
use the original front RGB `(0.90f, 0.47f, 0.18f)` with ambient intensity one,
all lights disabled and the original `(0.075f, 0.09f, 0.115f)` background. This
keeps real original parser/root/ray/gradient work while making color independent
of the separately unfinished lighting/specialization equivalence. Frames cover
a plane, sphere and all-background constant; nonsquare, minimal and rotated
views; OG_1x1, adaptive QUINCUNX, and zero-threshold supersampling.

The focused blend corpus reflectively calls the unchanged private
`RenderingTask.antiAliasPixel`. Supplied corner colors are explicit test inputs.
Its center sample still uses the genuine original plane trace. Whether the
advanced branch was entered is observed from its center-row cache insertion,
not recomputed by a second threshold implementation. Cases distinguish below
and exact `>=` threshold, zero threshold, all six decisive color pairs, F32
accumulation order in both branches and final clamping. The smooth-order case
scales the varied palette by exact binary32 `0.125f`; original execution must
report no refinement. The initial `0.25f` proposal was measured to refine
(its upper-left/upper-right RGB distance remains about 0.328), so it could not
qualify the smooth branch. Color/sample inputs and outputs are
recorded as raw binary32 hex bits, with final ARGB bytes as a separate output.

The deterministic TSV formats are:

- `pattern`: pattern name, index, u bits, v bits, weight bits.
- `blend`: name, threshold bits, refined flag, UL/UR/LL/LR RGB bits (12
  fields), genuine center RGB bits (3), result RGB bits (3), ARGB.
- `frame`: name, formula, pattern, threshold bits, width, height, yaw, pitch,
  zoom. Binary64 view values use Java's exact hexadecimal notation.
- `pixel`: frame name, x, y, ARGB in mathematical row order.

`reference.grease` requires full JDK support for `javac --release 17`, the two
locked dependency jars, exact hashes for original AA/rendering/color sources,
and fresh evidence. `git archive` and tar extract the frozen source into fresh
evidence; a missing baseline commit fails rather than selecting candidate
sources. Full CI history supplies that commit. Candidate and original source
revisions are recorded separately. The stage retains source hashes, compiler/runtime versions,
original output and byte-identical repeated observations. `-XX:-UsePerfData`
disables JVM performance counters because concurrent sandbox processes can
otherwise print a shared-memory lock warning into stdout; it does not change
floating-point behavior or filter diagnostics.

Local experiment: the installed OpenJDK 21.0.13 includes `jdk.compiler` but has
no `javac` launcher or `ct.sym`; the actual compiler module refused
`--release 17` with `release version 17 not supported`. The harness/core were
then compiled for local numerical exploration with the same module's explicit
`-source 17 -target 17`; its warning about system modules records that API/runtime
provenance is Java 21. This does not establish the hosted Java17 reference gate.
Those original-method experiments successfully emitted all six samples,
fifteen blends and 682 pixels. Candidate equality, allocation faults and
mutation rejection belong to the separately executed C qualification; no full
FINAL image, renderer-thread, Android or physical-device claim follows.
