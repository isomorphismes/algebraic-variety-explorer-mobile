# Synchronous native rendered pixels

## Type and ownership sketch before implementation

The accepted B′ boundary remains unchanged: Idriç owns formula semantics and
copies four prepared polynomials into a native snapshot; the C renderer owns
numerical roots, normals, lighting and pixels. This continuation accepts only
the existing positive Int64 snapshot identifier, Int32 width, height and quality, four
binary64 camera/yaw/pitch/zoom values and one private Int32 output array.

The locked JNI descriptor is `(JIIIDDDD[I)I`, exported as
`Java_Idric_Generated_renderPreparedSurface`. Its policy must explicitly admit
synchronous writable output; the existing input-copy policy is insufficient.
No native reference or array element address is retained after the call.

`render_copied_frame : Handle × Dimensions × Quality × Camera -> Status × OwnedFrame`
validates the Int32 array-length range and checked byte sizes, allocates a
private native frame, and calls `surfer_surface_render_orthographic_quality`. That
existing wrapper retains the real immutable snapshot borrow throughout the
numerical render. Any failure destroys the private frame and leaves the caller's
previous frame unchanged. Success flips mathematical rows exactly as the
original Android `RendererEngine.flipRowsInPlace`, then publishes ownership.

The thin JNI adapter validates an actual non-null `[I` whose exact length is
width×height, asks for the complete copied frame and calls `SetIntArrayRegion`
once only after `SURFER_OK`. The source must keep this array private and create
or publish a Bitmap only after the successful call. Pending JVM exceptions
propagate; no partial frame is treated as a successful result.

`destroy_frame : OwnedFrame -> Unit` balances successful native ownership. JNI
always destroys it after publication or a platform exception. The shared
`surfer_status` values remain authoritative. The numerical renderer currently
requires both dimensions at least two; this adapter preserves that contract.

## Required checks

Use the recovered qualified ICK host compiler, strict C17 and strict floating
point flags. Compare the complete output against the existing renderer's rows
reversed, using an asymmetric surface so a missing flip is observable. Require
invalid dimensions, size overflow, stale identifiers, nonfinite scalars,
actual frame allocation failure and numerical refusal to preserve a previous
frame and drain snapshot borrows. Compile a source mutation that treats a
failed render as success and another that omits row flipping; require the
designated test failure. JNI/ART execution is separate and needs real headers
and the actual new source contract; no fabricated header or compiler fallback.

Cancellation, broad antialiasing parity, general Java renderer parity, Activity
publication and physical-device acceptance are not qualified by this slice.

## Current result

Implemented in an isolated worktree from
`ea2d392949e53dd4adf46b6aae0c27a956b23b83`. No shared numerical or receiver files
were changed. The parent owns the checked output-array compiler policy and
actual Idriç/Bitmap caller.

The recovered exact qualified ICK compiler at
`ick-replay91/stage/bin/gcc` built the strict C17 tests. Ordinary tests PASS,
including exact reversed-row comparison on the asymmetric surface, positive
blank output, malformed dimensions/scalars, stale and forged identifiers,
one actual private-frame allocation failure and the finite-input numerical
refusal that must retain the old frame. Snapshot borrows and native frame/store
allocations drain completely.

Both real source mutations compiled through the same ICK and were rejected:
treating a failed render as success exits1 with the exact numerical-refusal
assertion, and omitting row reversal exits1 with the exact row comparison.
The maintained Grease helper parsed through the retained pinned runtime and
executed all these stages. Its final leak-enabled sanitizer run is preserved
as a failure because LeakSanitizer cannot work under this environment's ptrace.
The same ICK-built ASan/UBSan test passes with local leak detection explicitly
disabled. Hosted leak checking remains required; no local leak PASS is claimed.
Compiler/cc1, source and binary hashes are retained with the local evidence.

`RenderPixelObserver.smali` assembled with retained smali3.0.10 and decoded
independently with baksmali3.0.10. Its native methods expose actual render entry,
completed publication, actual frame allocation attempts/failure, and live frame
and snapshot-borrow counts. The optional `receiverRender` forwarding method
exercises the real JNI adapter for malformed receiver inputs; it does not
replace the generated source/Bitmap path. No candidate class is handwritten.

Native JNI compilation and ART remain PENDING: real `jni.h` is not present in
this local replay environment. No fabricated header, other compiler, Java relay
or serialization was used to bypass that gap.

## Integration

Compile `native/surfer_frame_output.c` and
`native/android/render_surface_jni.c` into the same native library as the actual
prepared-surface JNI receiver, core and store. This keeps the existing live
registry and loaded-library identity. Exported production method:
`Idric.Generated.renderPreparedSurface(JIIIDDDD[I)I`.

For the separate qualification library, additionally define
`SURFER_FRAME_OUTPUT_TESTING`, `SURFER_RENDER_JNI_TESTING` and
`SURFER_SURFACE_STORE_TESTING`, then compile
`examples/autogenerated/render-pixels/render_pixel_observer.c`. The existing
API29 qualification target permits thread-local counters. Production builds
omit these macros and observer symbols. Continue using ICK compilation with
the pinned Android sysroot, `-fno-stack-protector`, strict floating-point flags,
and object-only platform linking, as in the current receiver helper.

The output array must remain private and unmodified by other threads during
the call. Native validation/allocation/render failures do not call the JNI
publication operation. A JVM exception during publication invalidates this
private output and propagates; the source must retain the prior Bitmap and
discard the failed new array. Cancellation and broad rendering parity
remain separate acceptance work.

## Explicit original quality continuation

The new render API now takes quality before its binary64 camera arguments.
Source0 Interactive selects `{SURFER_AA_OG_1X1,0.3f}`; source1 Final selects
`{SURFER_AA_QUINCUNX,0.3f}`. Other values refuse before frame allocation or
managed writes. An additive store wrapper holds the same real snapshot borrow
while calling the AA owner's `surfer_render_orthographic_quality`; both earlier
store and numerical render APIs remain unchanged.

The AA owner's header/core overlay is used only for local integration testing
and is excluded from this commit. The tests compare row-reversed mathematical
output independently for both modes, require the two modes to be observable,
and check malformed quality. This integration does not itself establish the
AA owner's original Java parity; that owner maintains its separate oracle.

Actual strict ICK integration tests PASS for both explicit modes, their exact
row-reversed output, observable quality differences, invalid modes before
allocation, and the original failure/lifetime controls. A third compiled source
mutation forcing Final to OG_1x1 was rejected with the exact output assertion.
The existing unchanged store test also compiles and passes against the additive
AA core and wrapper. ASan/UBSan again PASS with local leaks disabled; maintained
leak-enabled execution is preserved as the ptrace-blocked failure. JNI/ART
remains pending real platform headers and execution.
