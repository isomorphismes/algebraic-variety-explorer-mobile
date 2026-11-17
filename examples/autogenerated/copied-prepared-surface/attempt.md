# Copied PreparedSurface receiver

## Type and ownership sketch before implementation

The existing Idriç producer owns parsing, qualification, scalar evaluation,
symbolic preparation and ordered expansion. This task implements its explicitly
requested C/JNI ownership counterparty, not another semantic producer.

Input is ABI version Int32, original family degree Int32, five Int32 offsets,
an F64 coefficient array and interleaved Int32 x/y/z exponents. Four half-open
ranges describe surface, dx, dy and dz. Empty ranges represent zero. A
successful copy returns an opaque positive Int64 identifier, never a pointer.
The borrowed numerical view remains `surfer_prepared_surface`.

`create_copied : Arrays -> Status × Handle` validates sizes, version, ordering,
duplicates, finite coefficients, nonnegative checked exponent sums and family
degree, then copies all four ranges before publishing. It accepts larger
original family degree after cancellation and adds no bootstrap degree/term
cap. The current producer's 0…127 intermediate exponent restriction stays in
the producer; this receiver accepts safe nonnegative Int32 totals.

`begin_borrow : Handle -> Status × (BorrowToken, ConstView)` keeps the immutable
snapshot alive. `end_borrow : BorrowToken -> Status` drops that ownership.
Release immediately prevents further borrows, while existing borrows remain
valid. Replacement publishes a complete new snapshot and retires the previous
handle under one mutex; any failure leaves the previous snapshot usable.
Neither operation dereferences a user-supplied identifier. Monotonic IDs are
never reused; exhaustion refuses rather than wrapping.

The JNI entry uses exact primitive array lengths and region copies. No JNI
reference, critical region, pinned array pointer or managed object survives
the call. Both source arrays must remain unchanged during this synchronous
call; two region reads do not make an atomic combined managed snapshot.
Mutation after return is safe. IDs are registry identifiers, not unguessable
security capabilities. Successful JNI creation/replacement returns a positive handle;
`-SURFER_INVALID_INPUT` and `-SURFER_OUT_OF_MEMORY` are typed transport failures.
Zero is reserved for a pre-existing or newly raised JVM exception. Release
returns the shared `surfer_status`. This transports no AST or Text.

## Required evidence

Use strict ICK C17 with no compiler substitution. Constructor tests cover
independent copies, malformed arrays/offsets/order/duplicates/degree/nonfinite
values, failure of each allocation, stale and forged handles, replacement
failure and a render borrow surviving release. A worker-thread test exercises
retirement during an active borrow. JNI/ART execution is a separate result;
source review or host tests must not be reported as ART or device acceptance.

## Current result

Implemented in the isolated checkout based on
`5d43e830c3180db68b6ce4e3bb40e187606fdb68`. The shared native status change must
be integrated first: this receiver uses `surfer_status`, the status-returning
render API and `surfer_validate_prepared_surface`. No numerical algorithms or
existing API-owner files were changed here.

Independent read-only C/JNI review found no concrete ownership or validation
defect. It prompted the explicit unchanged-during-copy input contract above.
The two Smali files assembled with retained smali3.0.10 and independently
decoded with baksmali3.0.10. All three Grease helpers parsed through the exact
retained pinned runtime with its relocated Python/source paths. The archived
launcher itself first failed with exit127 because it retained CI absolute
paths; the restored invocation used the same runtime, not another parser.

The retained qualified compiler was reconstructed from independently checked
archive parts after the original combined bundle exceeded the download limit.
Strict ICK C17 host compilation and ordinary receiver tests now PASS. The same
ICK-built ASan/UBSan receiver tests PASS with local leak detection explicitly
disabled. The maintained helper's leak-enabled run is preserved as a failure:
LeakSanitizer cannot run under this environment's ptrace. Hosted leak checking
remains required. No `cc`, Clang or other compiler was substituted. JNI native
compilation/linking and ART execution remain PENDING. No generated Idriç
producer, APK or physical-device result follows from these host tests.

`verify-host.grease` takes the repository, qualified host ICK executable and a
fresh output directory. It builds/runs the real numerical core with the store
tests. Tests require validation of all four ranges, copied-input independence,
both constructor allocation failures, borrow allocation failure, replacement
failure, stale/forged IDs, signed zero, empty ranges, degree256, family4096 and
a real render worker retaining its view after public release. Test-only
allocation counters check complete native cleanup.

`verify-jni.grease` takes repository, qualified x86_64 ICK, pinned NDK29 root,
fresh output, smali and baksmali. ICK compiles every C file; the NDK platform
driver receives objects only. It builds both a production library without test
hooks and a separate qualification library. The independent test-only forwarder
calls the real production JNI functions. Its observer reads through real store
borrows. `observe-jni.grease` checks byte-identical target delivery then executes
the JNI observer on ART. It checks exact coefficient bits for all four copied
ranges after managed input mutation, transport refusals, both temporary-buffer
allocation failures, replacement and release. Failure is exit79 with
`FAIL Explorer copied PreparedSurface`.

The parent integration retains API26 for the production library and uses API29
for the qualification build with thread-local allocation controls, matching the
API29/API34 execution lanes. Host qualification also runs the receiver tests
under ASan/UBSan with leak checking, using the qualified host's required
`-fno-link-libatomic` option. These remain pending executions until their gates run.

The JNI observer deliberately does not define a counterfeit generated producer
class. Actual Idriç array construction, checked native declarations and producer
execution remain a separate integration gate owned by the semantic producer.
The application must load `libave_prepared_surface.so` and use the native
declarations in `prepared_surface_jni.h`. Test forwarding symbols are confined
to the qualification library.

The retained Grease runtime was also checked directly: an ordinary failing
command and a failing left side of a pipeline both stopped before a following
marker. All three receiver helpers now state `set -eu -o pipefail` explicitly
and parse through that same runtime. JNI C compilation disables stack
protection to avoid host compiler-default canary ABI assumptions during Android
cross-compilation. The helper records dynamic imports for both libraries and
requires no `__stack_chk` import. Actual JNI builds and these import checks
remain pending; no native result follows from helper parsing.

The qualification library also supports store-allocation controls through the
actual JNI create/replace path. Each call creates a local store allocation
probe; no probe pointer or allocator state is retained by a snapshot. Observer
methods `failStoreAllocation` and `storeAllocationAttempts` select/check node0
and terms1 failures, while `liveStoreAllocations` and `liveBorrows` expose the
existing test-only cleanup counters. These controls compile out of production
and let the generated producer observer require actual native -3 propagation.
Execution of this additional generated-producer fault path remains pending.
The current-thread `copyCalls` counter observes actual JNI entry even when it
rejects before allocation, so a producer-level semantic error can be checked
to leave the receiver completely uncalled rather than inferred from mallocs.

The first hosted ICK JNI build at source91d8e7a compiled the production store,
then failed in the qualification store because NDK29 `stdatomic.h` expands to
Clang-only `__c11_atomic_*` intrinsics. The test counter now uses C17 `_Atomic`
scalar increment, decrement and load directly, preserving sequentially
consistent operations without that incompatible header. Production ownership
code does not include the counter. Rebuilt JNI/ART execution remains pending.

## Executed repaired receiver

At source `cfd543e1886bc6b7eb9e1ede6641569b673aac8d`, the strict host and
leak-enabled ASan/UBSan receiver gate passed in
[run43803682852](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43803682852),
job133089448951. Qualified ICK then compiled all JNI C, the pinned NDK linked
objects only, and the real receiver observer passed API34/x86_64 ART with JNI
checking in [run43803682868](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43803682868),
job133089448400. Production test-symbol/stack-guard import checks also passed.

That same run separately executed the actual Idriç producer through these JNI
entrypoints and store probes; its stronger original-polynomial/fault/cleanup
receipt is in `../prepared-transfer/qualification.md`. The raw receiver stage
still correctly reports that it alone did not execute an Idriç producer. No
Activity, packaged application or physical-device result follows from either
stage.
