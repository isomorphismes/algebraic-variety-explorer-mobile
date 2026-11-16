# Native SURFER status and validation boundary

## Settled behavior and scope

Continue the accepted native error contract against source
`d4bc9b3c84d8adeb4c82d1354c84833aace5aec9`. The numerical algorithms,
binary64/binary32 split, original operation order, antialiasing and quality
remain unchanged. All polynomial arrays are immutable, caller-owned borrows
for one synchronous call. This stage introduces no JNI arrays, native-owned
surface handles or asynchronous lifetime protocol.

The current source conflates allocation failure, malformed input and a geometric
miss. In particular, Descartes search can break after a failed allocation and
return a previously saved candidate; the public root/trace/image chain can then
report a successful background frame. A blank valid image must remain success,
while any failed computation invalidates the complete frame.

## Type and ownership sketch

- `surfer_status` has exactly `SURFER_OK`, `SURFER_MISS`,
  `SURFER_INVALID_INPUT` and `SURFER_OUT_OF_MEMORY`.
- Clip and root functions return the authoritative status and fill their output
  only on `SURFER_OK`. `SURFER_MISS` means a successful geometric miss.
- `surfer_trace_result` has one authoritative status, replacing the ambiguous
  `hit` boolean. Valid misses carry the scene background; fields describing a
  hit are meaningful only for `SURFER_OK`.
- Image rendering returns `SURFER_OK` when every ray completes, including a
  frame containing only background. It receives an explicit pixel capacity.
- A private per-call context carries allocation/size failures through the
  existing helpers. There is no production global error state or allocator.
- Test-only entry points receive a caller-owned allocation probe, allowing each
  actual allocation attempt to fail deterministically without global controls.
  The production allocator remains libc; every owned allocation unwinds through
  the same existing ownership paths.

## Validation and evidence requirements

Validate all four pointer/count pairs before use (zero-count polynomials are
valid), finite coefficients, nonnegative exponents and family degree at least
the actual surface degree. Larger family degree is valid after specialization;
the C layer must not recalculate derivatives. Validate finite scene/ray/camera
inputs, valid zero gradients, positive camera height/zoom and light count.
Check every allocation byte count, polynomial-length sum, stack growth and
image dimension/index/capacity calculation without an arbitrary degree cap or
signed loop overflow. Invalid requests must not write pixels. Runtime failure
may leave partial output, which the caller must discard in full.

Current source uses ordinary C assignment/division syntax; the separate
unmerged glyph migration is not duplicated here. Builds must use the selected
source-built ICK and strict floating-point flags. The current Linux x86_64 host
has no qualified ICK or Grease executable; compilation, sanitizers and leak
checks must execute on the declared hosted ICK path, with no `cc`/GCC/Clang
fallback.

## Implemented source and pending execution

The core, public header, existing C tests and NativeActivity caller now use the
authoritative status API. All allocation helpers carry a private per-call
context. Failed deflation, transformed arrays, sign-variation storage and stack
growth unwind and cannot publish a previously saved root. Checked sizes cover
coefficient storage, polynomial products, stack growth and output dimensions.
The axis-power loop uses a size index, preserving the original coefficient
calculation while avoiding signed loop overflow at the maximum exponent.

A separate read-only source review found a concrete additional failure: finite
inputs can overflow coefficient expansion to NaN and be reported as a miss.
The implementation now checks generated/transformed coefficient arrays and
univariate evaluation, and includes a finite `DBL_MAX` cancellation regression
which requires `SURFER_INVALID_INPUT` rather than `SURFER_MISS`. Successful
finite calculations retain their original operations and order.

The test program includes the exact core source to reach private size-boundary
checks without exporting application APIs for synthetic internal states. The
normal numerical program separately compiles the core as its own translation
unit. Allocation baselines require all seven storage/copy/deflation/shift/
transform/sign/stack coverage tags, then fail each actual allocation attempt
and require the exact error with unchanged root output. A compiled mutation
which paints background after ray failure must fail the frame-error assertion.
The status test defines its test-only feature macro itself; the compiler does
not redefine it on the command line.

The successful-numerics observer selects either the exact unmodified base core
or the current status API and writes actual pixels/root bits for all seven
maintained presets under the same camera. The hosted gate must compare those
bytes exactly. This is a narrow unchanged-success check, not general Java
parity or root-algorithm acceptance.

The new Grease helper parsed successfully through the exact retained pinned
runtime. The first parse exposed an unsupported legacy quoted-string form;
the source now uses the runtime's declared byte-string syntax and parses cleanly.
The CI job invokes the reviewed pinned `ai-ci/ick-host` action, retains compiler
and source identities, and uses its declared scalar-link flag. The existing
generic-compiler core test command is replaced by this stronger separate job.

ICK compilation, sanitizer/leak execution, fault injection, mutation rejection,
exact successful-numerics comparison, Android ABI builds and device execution
remain PENDING. No fallback compiler was used, and no runtime result is claimed
from source review or parsing.

Additional zero-surface qualification preserves the current representation:
`coefficient_count_without_trailing_zeroes` deliberately retains one zero
coefficient because its loop stops at length one. No executed zero-surface
regression was observed. The preparation success predicate now nevertheless
uses the authoritative context and explicitly permits a successful zero-length
internal polynomial; root-family dispatch treats that empty value as a miss
without allocation. Allocation failure remains a distinct context error.
Public root/render controls cover zero-count storage, retained all-zero terms
with family degree two and cancellation of degree-two terms. Each must produce
an unchanged root output on `SURFER_MISS` and a successful all-background frame;
each actually reached allocation is separately failed and must report
`SURFER_OUT_OF_MEMORY`, never a miss or successful blank frame. These controls
remain pending hosted ICK execution with the rest of this gate.
