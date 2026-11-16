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

## First hosted execution and verifier repair

At source `91d8e7a16c13b6dbca1f8e5583849ee7f9079b4d`, CI run43800812201
job133080375550 compiled and passed both ordinary numerical tests and the
AddressSanitizer/UndefinedBehaviorSanitizer numerical and allocation/status
tests, with leak detection enabled. The compiled blank-on-error mutant was
correctly rejected with exit1. Its first diagnostic came from the newly earlier
zero-surface control, while the verifier still required the later ordinary
frame-control diagnostic. The gate therefore failed in the diagnostic checker;
the successful-byte comparison and copied-receiver step were skipped.

The verifier now requires the exact observed whole-line zero-surface diagnostic
and retains the designated exit1 requirement. This does not accept arbitrary
crashes or weaken the mutant to a source-text check. Artifact14196303377 was
downloaded and its ZIP SHA256 matched the uploaded
`e27a086a67b9233e90838d1930f3fa97fa060133bc56baf00cb1e623aa450d0e`.
The corrected match passed against the actual retained `mutant/result.txt`.
The repaired helper parses through the retained pinned Grease runtime.

The retained ICK-compiled numerical binary also passed local replay. Local leak
checking is blocked because LeakSanitizer detects the execution environment's
ptrace; with local leak detection explicitly disabled, the retained sanitizer
tests passed and the mutant again produced the same designated failure. This
local replay adds no leak-check claim; the hosted execution above supplied it.
No compiler was substituted. Full repaired-gate execution remains pending.

After recovering that exact qualified compiler, an independent local build and
execution of the helper's successful-byte stage compared the frozen d4bc9b3
core with the published91d8e7a status core. Both seven-preset observations are
32179 bytes and have SHA256
`65f44c201676e330068804e4059a369cb6479efa1673660fd78a42681a1f55ca`.
Compiler/cc1, all input sources, both executables and both observations were
hashed in the local replay evidence. This supplies the narrow unchanged-success
comparison skipped by the initial hosted gate; it is not Java or image parity.
