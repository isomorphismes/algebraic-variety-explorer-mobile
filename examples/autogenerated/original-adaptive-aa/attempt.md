# Original adaptive antialiasing numerical slice

## Owner and type sketch before implementation

The original application maps INTERACTIVE to Stussak's `OG_1x1` and FINAL to
adaptive `QUINCUNX`, with the original threshold `0.3f`. The native renderer
must retain the sample coordinates, corner reuse, adaptive decision and ordered
binary32 color accumulation. Geometry, polynomial evaluation and root finding
remain the existing binary64 numerical core; this slice adds no replacement
solver or semantic polynomial preparation.

An additive `surfer_render_orthographic_quality` API takes explicit sampling
pattern (`SURFER_AA_OG_1X1` or `SURFER_AA_QUINCUNX`) and binary32 threshold.
Threshold zero reproduces the original nonadaptive supersampling mode. The old
`surfer_render_orthographic` entry and its successful output bytes remain stable.
The new quality entry follows one original full-canvas `RenderingTask`, including
its start-plus-increment geometry order; global worker/tile scheduling and
cancellation remain outside this slice.

`OG_1x1` samples the original viewing-grid points. Quincunx first traces a
`(width+1) × (height+1)` corner grid at half-pixel-expanded coordinates. Its
six pairwise RGB squared distances and threshold square use binary32, with the
original `>=` decision. A refined pixel accumulates lower-left, upper-left,
upper-right, lower-right and center in the original pattern order, retaining
the original binary32 corner/center weights. A smooth pixel adds upper-left,
upper-right, lower-left and lower-right, then scales by `0.25f`. Coordinates and
increments remain binary64; the samples are not converted to bytes before
filtering.

All grid/byte products are checked before allocation. Caller-owned fault probes
exercise allocation failure without publishing a successful partial frame.
Strict qualified ICK compilation keeps `-fno-fast-math -ffp-contract=off`.
Existing success/status tests remain in force, with independent original Java
test-only sample/color and pixel outputs plus targeted source mutants. The Java
oracle is the actual retained implementation, not an Idriç or C recreation of
that reference algorithm.

Full rendering equivalence is not inferred: current ray-specialization/root
limitations, worker/cancellation behavior, the complete app interface, physical
devices and full FINAL-quality corpus remain separate acceptance boundaries.
Local leak detection under ptrace is unavailable; hosted leak execution remains
required even when local numerical and sanitizer checks pass.

## Implementation and local observations

The additive core/header API and private fault-probe entry are implemented.
This extends the existing derived ordinary-C17 numerical port with the same
qualified ICK stage; it does not claim a different source profile or a generic
compiler fallback. Source, reference, sanitizer, mutant and baseline stages are
declared separately in `ci/native-aa-toolchain.tsv` and wired into the existing
unfiltered native ICK job. Original Java compilation is an explicitly test-only
reference stage, not a candidate implementation or packaging mechanism.

Qualified ICK compilation and execution pass the existing numerical suite and
the new fifteen-blend/nine-frame comparison against actual original-method
local observations. All 682 ARGB pixels match, including the nonsquare,
minimal, rotated-plane, sphere and all-background cases. All 525 observed
AA/ray allocation failures return out-of-memory status. Smooth background
pixels skip genuine center traces, while zero threshold forces them.
ASan/UBSan with local leak detection explicitly disabled passes the same test.

Compiled incorrect corner weights, strict `>` threshold comparison, meaningful
refined and smooth corner accumulation reordering, F64 weighting and shifted center coordinates
each fail their designated independent diagnostic. A swap of the first two
equal-weight additions is commutative and was correctly not retained as a
required failing mutation; the retained reorder changes a later grouping and
fails the float-order case.

The complete legacy seven-preset pixel/root observation remains exactly
32179 bytes with SHA256
`65f44c201676e330068804e4059a369cb6479efa1673660fd78a42681a1f55ca`.
The local pre-AA C/header/preset blobs were checked against public baseline
`cfd543e1886bc6b7eb9e1ede6641569b673aac8d` before comparison. The original
single-sample function body and signature have not changed.

The local original-Java experiment used the installed Java21 compiler module
with explicit source/target17 because its stripped image lacks both the javac
launcher and ct.sym; the actual `--release17` refusal is retained in `oracle.md`.
That experiment executes unchanged original methods, but does not establish
the stricter hosted Java17 reference stage. All maintained Grease helpers parse
with the exact retained runtime. Hosted full-JDK17 reference and leak-enabled
execution remain pending; no full FINAL, Android or physical parity follows.

## Dependency acquisition

The AA reference now reuses
`polynomial-qualification/prepare-dependencies.grease`: every cached jar is
digest-checked, cold acquisition can use the two Maven Central endpoints, and
the same four original-reference lock entries supply both JVM and AA checks.
Only the unchanged ANTLR and vecmath jars are copied into the AA classpath.
Native-host CI restores and saves that same dependency-lock-keyed cache before
later reference execution; this is separate from mathematical acceptance.

The actual AA preparation entry passed with a fresh empty cache and with a
verified warm cache. Both produced the exact original ANTLR
`5b7cf53b7b30b034023f58030c8147c433f2bee0fe7dec8fae6bebf3708c5a63`
and vecmath
`3558e81ca74c60dc01baca7ef05f48594bbaed43af45d4f1b9196e479734e675`
bytes. A deliberately corrupted cached ANTLR jar was rejected by its checksum
with exit 1 before an AA classpath jar was published. No dependency version or
accepted digest changed.
