# Native render pixels into a checked Bitmap

## Type sketch before implementation

The existing Idriç semantic producer and copied native PreparedSurface remain
the input. C owns rendering and its synchronous snapshot borrow. A new explicit
JNI output policy receives Int64 handle, Int32 dimensions and quality, four
binary64 camera settings and one private Int32 output array; it returns shared
native status.
This is writable output, not the previous input-copy contract.

The application wrapper allocates a private Int32 buffer/array, invokes native
rendering, and creates a real Android Bitmap only after native success. Failed
frames do not mutate an earlier Bitmap. Native pixels are staged until the
complete frame succeeds, then rows are flipped to the original Android shell's
order before one JNI array publication. Every failure balances native storage
and snapshot borrowing. Source array/Bitmap allocation may still propagate JVM
exceptions; no new exception recovery capability is assumed.

Central source operation:
`render_native_bitmap : NativeSurface → RenderSettings → IO (Either Text RenderedBitmap)`.
`RenderSettings` names width/height, quality and camera height/yaw/pitch/zoom. The native
view, array reference, typed handle and Bitmap remain distinct values. No AST,
Text pixel serialization, Java relay or numerical semantics cross this cut.

## Qualification and limits

Use the actual checked Idriç source and exact ICK native implementation.
Observe real Bitmap dimensions/pixels independently, malformed dimensions and
stale handles, allocation failures, unchanged prior Bitmap on rejection, and
compiled wrong-row/wrong-pixel mutations. Keep generated source, independent
decode, JNI/ART, Activity integration and device acceptance separate.

Source `Interactive` selects OG_1x1 and `Final` selects QUINCUNX, both using
the additive quality path with original binary32 threshold0.3. Cancellation,
latest-request-wins concurrency and general renderer parity remain unqualified.
The additive AA owner separately qualifies its sample/accumulation behavior.
This synchronous slice does not claim the complete Android screen or permission
to publish an APK.

## Implementation and current evidence

`RenderedBitmap.idric` implements the operation above. Its pixel array remains
private until native status0, and only then enters real Android
`Bitmap.Config.valueOf("ARGB_8888")` and `Bitmap.createBitmap` calls. The native
descriptor is locked as `(JIIIDDDD[I)I`: quality follows width and height,
then camera height/yaw/pitch/zoom and the output array. Selectors0/1 mean
Interactive/Final; other selectors are refused before allocation/publication.

The compiler prerequisite is the distinct synchronous output policy implemented
in android-NDK commit64ccf63. It does not relabel the previous copied-input
contract. Native rendering depends on the additive AA core/header commit
c695f1bb; that owner preserves the previous single-sample API separately.
The new frame and store-quality adapters do no semantic preparation or numerical
algorithm replacement.

The complete real source typechecks, emits directly to DEX, independently
decodes and repeats byte-identically. Its DEX SHA256 is
`ac59df3e541357558a203e0afb0a9f3bf2cfe79903de4aa3e0c710c19120812d`.
Decode contains the actual quality-aware native call, four Double unboxes,
primitive Int32 array and actual Bitmap platform calls. The first qualification
adapter attempt lacked the CoefficientValue import needed by the existing
preparation signature; adding that direct import fixed the source error.

The maintained source helper executed fully. Actual source mutations selecting
RGB_565 or mapping Final to Interactive emit distinct independently decodable
DEX. The independent observer reads all1147 pixels of real platform Bitmaps
and checks both qualities, prior Bitmap preservation, source/native refusals,
frame allocation failure and drained native storage. Observer assembly/decode
passes; execution of positive/mutants on JNI/ART remains PENDING.

The portable native side passed strict qualified ICK tests for both quality
modes, row reversal, malformed sizes/quality, stale handles, allocation faults
and borrow cleanup. Three actual compiled C mutations (blank-on-error, removed
row flip, forced Interactive) were rejected. ASan/UBSan passes with local leak
detection explicitly disabled; the maintained leak-enabled run retains the
execution environment's ptrace failure. Hosted leak checking remains required.

`copied-prepared-surface/verify-jni.grease` now compiles both new production C
files into the existing owned-surface library, and adds the separate test-only
render observer to its qualification library. It preserves ICK compilation,
object-only platform linking, exact JNI symbols and no test hooks in production.
Real NDK headers/linker and JNI/ART execution remain unavailable locally; no
generic compiler, Text pixel transport or Java candidate relay was used.

`RenderExports.idric` is qualification only. Production accepts an already
owned NativeSurface. JVM array/Bitmap allocation exceptions still propagate;
the source does not claim a new catch/finally facility or managed-OOM recovery.
Activity state publication and latest-request-wins/cancellation remain separate.
