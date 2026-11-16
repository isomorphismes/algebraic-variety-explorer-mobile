# Runtime processor-count JNI observer

The maintained Android adapter queries `Runtime.availableProcessors()` on the
JNI caller thread, then passes a positive Int32 count into the C session owner
as a scalar. A platform startup hook separately owns each worker's daemon JVM
attachment and Thread priority call; that worker retains its own environment
through numerical work until platform cleanup. The numerical kernel receives
no JNI environment, and the generic C owner keeps only an opaque cleanup token.
This test exercises that actual adapter and actual native session/store/core
through the official JDK 17 JNI C interface.

The input domains are a mock JNI function table with controlled results and a
pending-exception bit; opaque local-reference identities; positive Int64
session/epoch/surface tokens; and an Int32 output array. The query operation is
`(JNIEnv, output Count) -> Bool`, with an unchanged output on failure. Session
creation and render carry the same query through their real entry points.

The test owns the mock external environment, not an alternative query. It
includes the actual production JNI source to reach its private query and
links the actual session/store/core and separately licensed vecmath module.
Fault cases control each standard JNI stage; source expectations are local
reference balance, unchanged pending exceptions, checked scalar admission,
unchanged rejected output and complete native-owner cleanup. Link-time
pthread observers require every actual started worker to join before the
real JNI publisher reaches `SetIntArrayRegion`. A numerical-tile observer also
requires an owned daemon attachment and Thread.MIN_PRIORITY at entry and exit.
Worker Thread calls use their own environment; Runtime/query and array calls
use the original caller environment.

The candidate owner and JNI boundary are C, so this is a C foreign-interface
test rather than an Idriç replacement. No Idriç language gap is inferred.
General JVM execution, ART, Android JNI ABI, APK behavior and physical devices
remain separate. The C host test uses official `jni.h` and `jni_md.h`; it does
not invent or vendor replacement platform headers.

The local implementation baseline is an isolated test-only snapshot of the
current bounded-worker/session/Runtime-query source. That baseline commit is
not part of the deliverable. Only the observer, Grease helper and documentation
are to be adopted onto the current implementation branch.

## Initial query-only observation

The qualified ICK at source revision
`fbe86e23d55cfec2000c08e61deea2a407fd7175` compiled and executed the real
adapter/owner test successfully. All three compiled mutations were rejected
with the designated exit status and observer diagnostics. The successful
integration calls started and joined 18 actual numerical workers; local JNI
references, session/epoch allocations and copied-surface ownership balanced.

The official external OpenJDK 17 GA header digests were:

- `jni.h`: `1266aea5b9f5d5db1cb6f8e5c6c43cfa7f80bc4f72d7fe42c6131bb939dc70f4`
- `jni_md.h`: `88cb5c33e306900dd35a78d5a439087123b8e91b0986bb5acb42cc9bd2fcc42e`

The initial, pre-priority production-input digests were:

- `render_session_jni.c`: `c6b2dbee72d10e62f335636f93f3d169d09628f83112c9d6245f7dbd8cd1e255`
- `surfer_render_session.c`: `8ca5e2c3cf2a88a4b0f62f41e9a85ee21951492506552b26e1b4e18988294cf2`
- `surfer_original_workers.inc`: `d3c06f2e7620b033d458234b4612e08faf450e573752e5fa2b0a55f8faed4c1b`

The maintained Grease helper parsed and ran its positive and mutation stages.
Its required leak-enabled sanitizer stage could not complete: LeakSanitizer
reported that it does not work under the local ptrace environment. The helper
failed and emitted no passing final receipt. A separate execution of that
same ASan/UBSan binary with leak detection disabled passed all observations.
That is ASan/UBSan execution evidence, not a leak-detection pass. The helper
retains `detect_leaks=1` for the hosted qualification.

The maintained invocation is `grease verify.grease EXPLORER ICK_SOURCE
QUALIFIED_ICK JNI_INCLUDE JNI_PLATFORM_INCLUDE FRESH_OUTPUT`, with all six
paths absolute. The test-only local baseline commit must not be adopted;
only the subsequent observer/helper/documentation commit is the deliverable.

## Owned worker priority extension

The external mock JVM now supplies a distinct thread-local JNI table and
opaque Thread identities to each actually attached worker. It observes the
real startup/finish hooks. Startup acquires an owned daemon attachment after
GetEnv reports detached; Thread.currentThread and Thread.setPriority(1) use
that environment. The attachment survives actual numerical tile calls; finish
clears only its own pending exception and detaches. Worker exceptions do not
replace or clear caller exceptions.

The type boundary is `worker_start(VM) -> (Status, opaque owned token)` followed
by `worker_finish(VM, token) -> Status`. The C kernel sees neither JVM type.
All startup attempts, including partial failures, require cleanup. A cleanup
failure with mock resources already released must still reject publication.
Already attached foreign environments are refused and never detached as owned.

The extended local ICK positive run passed with 86 actual workers started and
86 joined. It exercises all Thread lookup/invocation fault stages, GetEnv and
daemon-attach failure, foreign attachment, caller GetJavaVM failure, and a
detach failure after releasing the mock resources. Actual numerical calls
require owned attachment and priority throughout. The earlier blanket
caller-thread-only JNI claim applies only to the historical query-only
snapshot: current Runtime/query/array calls are caller-owned, while current
Thread priority and attachment cleanup are worker-owned.

All seven compiled mutants were rejected: the three original query faults,
bypassed priority, early detachment, caller-environment reuse and skipped
detachment. The copied caller-reuse mutant captures a valid caller environment
solely to demonstrate rejection on the wrong thread; the maintained source
contains no such caller capture.

The priority-input digests for this observation were:

- `render_session_jni.c`: `dcdbd8b4abe694f5c8f1dd3dcc9271df590db94d9803a1f94b56e2baf6afc6dc`
- `surfer_render_session.c`: `022f1a77d70d3592dfe5da563d33635f1e9758f85f9133088a6211345a20dbc8`
- `surfer_original_workers.inc`: `d29c69a71ce5a4b4bbe3883ac1b588770bc206716bf81c7b0af8137d07507da4`

The extended ASan/UBSan binary also passed all observations with leak detection
disabled. The maintained leak-enabled stage again stopped with the local
LeakSanitizer ptrace limitation and produced no passing final receipt. Its
`detect_leaks=1` requirement remains intact for hosted qualification. These
are mocked JNI interface and actual C worker results; actual JVM priority,
Android JNI ABI, ART and physical-device behavior remain untested here.
