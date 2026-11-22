# Independent Bitmap handoff observation

## Type sketch before implementation

The candidate is the actual source-generated `Idric.Generated` class from
`RenderExports.idric` and the maintained `RenderedBitmap.idric` module. The
observer defines no candidate class, bitmap constructor or rendering algorithm.

`RenderBitmapObserver.configure : Int32[1147] -> Unit` privately copies the
expected primitive pixels. `observe : Bitmap -> Unit` requires width37,
height31 and all actual `Bitmap.getPixel` values to equal those pixels, then
retains the successful platform Bitmap and its expected values. Observation
count and retained-object/pixel checks prove failed new frames do not replace,
recycle or modify the previous successful Bitmap.

The runner obtains an independent reference array from the actual native
receiver: it prepares a real surface through generated source, directly calls
`RenderPixelObserver.receiverRender(JIIIDDDD[I)I` with quality0 or1 and the
locked camera, then releases that reference handle. The generated Bitmap path
must independently allocate its private array, call its real native method,
construct the actual platform Bitmap and call the observer exactly once.

Render-entry/publication counters distinguish source rejection from native
refusal, and frame allocation failure must travel through the real generated
path. Snapshot, store, borrow, temporary-buffer and owned-frame counts must all
drain. A malformed formula additionally leaves the copied-surface JNI actor
uncalled. Failure uses exit81 and `FAIL Explorer rendered Bitmap`.

## Evidence boundary

Source inspection, actual candidate generation, Smali assembly and independent
decoding are local checks. JNI, Bitmap and ART behavior remain PENDING until
the parent executes this observer with the real emitted candidate and native
library. The native reference establishes transport/Bitmap fidelity to the
maintained renderer; it does not establish general Java renderer parity, AA
oracle parity, cancellation, Activity publication, APK or physical-device
acceptance.

## Source and local result

Read the parent's actual `RenderExports.idric` and `RenderedBitmap.idric`
before writing the observer. The runner matches their exact exports and error
strings: modes0/4 are Interactive/Final37x31; mode1 rejects width0 in source,
mode2 refuses camera0 natively and mode3 renders a real released handle. A
native owned-frame allocation failure is injected through the actual generated
call. The previous successful platform Bitmap is checked by object identity,
observation count, unrecycled state and every pixel after each failure. The
source-invalid `x/y` case also requires both copy-JNI and render-JNI actors to
remain uncalled. All native live counts drain after each case.

Expected camera literals are the exact binary64 values2.15,0.37,-0.19,1.1.
The reference call uses the locked `(JIIIDDDD[I)I` descriptor and14 argument
register slots; the candidate uses real generated source. Final reference
pixels must differ from the Interactive reference, making dropped quality
selection observable rather than presumed.

Both new Smali files assembled successfully with retained smali3.0.10 together
with the actual native observer declarations and independently decoded with
baksmali3.0.10. Source/register review found no parameter or wide-value overlap.
These observer checks are assembly/decoder observations only. The maintained
parent source qualifier separately generated/decode-checked the actual source,
byte-identical repeat and distinct RGB_565/forced-Interactive source mutants.
Platform Bitmap behavior, JNI/ART execution and designated failure behavior
remain PENDING.

The local four-observer-class DEX has SHA256
`57858a52e5aa23435d29b5331fac378c3c343c224b4482f396ca59652d025f44`.

## Runtime diagnostic boundary

The ART helper now checks device state, API34, x86_64 and emulator property1
before any remote file mutation. It verifies both host and Android timeout
entrypoints, uses `-Xcheck:jni`, bounds the remote process and its host client,
and retains all-buffer logcat, process lists and device state before/after
every positive or mutant invocation. Diagnostic command statuses and the exact
process result are retained even when the candidate fails or is killed.

The independent runner catches unexpected main Throwables, prints the complete
stack trace and exits82. Ordinary success0 and designated mutant rejection81
remain distinct. This changes no candidate source or native API. The revised
helper parses and runner assembles/decodes; actual emulator execution remains
pending.

The next observer-only delta adds direct malformed JNI output controls while
retaining all actual-source Bitmap cases. A real generated surface handle is
held across wrong-length1146, unsupported-quality2 and null-array requests.
Each requires `SURFER_INVALID_INPUT`, zero frame allocation attempts and no
publication. Both allocated arrays retain every sentinel pixel, and temporary,
frame and borrow counts stay zero while the one snapshot retains exactly its
two native allocations. A subsequent successful direct render into the valid
array proves the same handle remains usable, then release drains the store.
This is receiver observation only; it does not replace the actual source path.
Assembly and independent decoding of this delta PASS and remain the only local
checks; runtime behavior remains pending. The new observer DEX SHA256 is
`e6f54d140050ccb68001ff5356b048ec00987d7785eaa480c338149d6684ee4e`.
