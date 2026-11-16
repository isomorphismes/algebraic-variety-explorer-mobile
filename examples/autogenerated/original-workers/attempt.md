# Original bounded numerical worker acceptance

This host consumer exercises the existing C session owner. A session owns a
creation-time pool limit `min(4, processors_at_creation)`. A draw supplies its
fresh processor count for the original overlapping tile partition; it must not
change that stored pool limit. Four immutable prepared polynomial arrays are
copied into a retained surface snapshot. Each worker owns packed tile storage;
the owner joins all workers before one current-epoch whole-frame publication.

The test domains are positive session/epoch/surface handles, processor counts
1/2/4/8, bounded canvases and exact ARGB arrays recorded by unchanged original
tasks under explicit processor-count profiles. The central operation maps
`(Session, CurrentEpoch, Snapshot, OriginalPartition, Camera, Quality)` to
`Either RenderFailure PublishedFrame`. Publication is observable separately
from numerical completion. Cancellation, a new epoch and session close make
the old epoch ineligible; surface release alone preserves an existing borrow.

An Idriç-side ownership sketch would make `Session`, `Epoch session`,
`SurfaceBorrow` and unique `TilePixels` distinct scoped values. At most four
workers borrow the immutable scene. The complete frame is a unique staging
value and a publisher consumes it only after all joins and the final currentness
check. The implementation remains C at the selected numerical/runtime boundary;
this observer does not replace Idriç or introduce a second renderer.

The consumer compares every ordered frame at each actual original processor
profile. A real four-worker barrier proves simultaneous workers before testing
cancel/begin/close and snapshot release. Per-call test probes exercise worker
thread-start failures and every frame/worker-buffer allocation point. Live
session, epoch, snapshot and borrow counters must return to zero after cleanup.
ASan/UBSan/leak execution is separate from ordinary execution; local Java21
diagnostic references cannot be reported as hosted JDK17 acceptance.

## Ownership boundary

The numerical worker keeps no `JNIEnv` or Activity pointer. A positive Int32
processor count crosses the platform boundary, while the numerical owner fixes
its pool limit once and accepts a fresh draw count only for partitioning.
Every worker has its own numerical operation context, XYZ/row/AA values and
packed pixel buffer. Shared inputs are immutable borrows. An atomic boolean
stops the queue, at most four buffers and threads are live per draw, and ordered
copies affect only unique internal frame staging. The caller joins all created
threads before final publication under the session lock.

## Local development evidence

The exact qualified ICK compiler compares all 176 original frames and 21648
pixels for processor counts 1, 2, 4 and 8 through both the public tiled-render
entry and the instrumented synchronous publisher. The real four-worker barrier
passes cancel, begin, close and surface-release cases. Three more barriers
invalidate an already joined frame immediately before final publication.
Creation-time pool limits remain four when the draw count drops to one, and
remain one when the draw count rises to eight. Session, epoch, snapshot, borrow
and tracked owner allocations balance after every case.

All five frame/worker-buffer allocation points, all four thread-start failure
positions and publisher refusal preserve the caller's previous pixels. Four
compiled mutations are rejected: copy each tile's first row repeatedly, ignore
epoch cancellation in workers, recompute the fixed pool from the fresh draw
count, and omit the final publication currentness rejection.

The ordinary and ASan/UBSan binaries pass against the explicitly labelled
Java21/source17 development reference. Local leak detection is disabled only
for that separate sanitizer observation. The maintained verifier retains
`detect_leaks=1` and correctly stops at LeakSanitizer's ptrace refusal here.
Hosted frozen-original JDK17, actual leak checking, Android arithmetic/JNI and
physical devices remain separate acceptance gates. The test baseline imported
the in-progress numerical owner without modifying its production source.
