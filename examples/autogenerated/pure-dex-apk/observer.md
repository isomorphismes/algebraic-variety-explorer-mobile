# Independent installed Activity observer

`observer/InstalledObserver.smali` extends Android Instrumentation and implements
Runnable solely for synchronized main-thread observation/actions. It is packaged
in the separate test-only application declared by `ObserverManifest.xml`.
It does not replace, subclass, reflect into or invoke exports of `Idric.Generated`;
the framework launches the real installed `Idric.Generated` Activity.

The logical observation is `InstalledActivity → IO (Either Failure NineScenarios)`.
Resource identifiers resolve against the original application package. All view,
Drawable and displayed pixel snapshots run through `runOnMainSync`; only the
instrumentation thread waits/polls. A main-thread exception is relayed back to
the instrumentation thread. Each frame deadline is90seconds, dialog selection
10seconds, recreation monitor90seconds and destruction10seconds. An external
740second host timeout bounds each complete invocation. The known system
timeout also bounds the remote command to720seconds where present. API23 may
use the explicit host-only bound described below; its absence is recorded.

## Exact installed targets

`qualify-installed.grease` takes `EXPECTED_API` immediately after `SERIAL`.
It admits exactly23,34 or35 and requires the observed level to equal that
argument, plus x86_64, qemu1, user0 and no preexisting candidate/test package or
retained package data. API34 retains the same nine positive scenarios and
zero-scenario applied blank-Bitmap negative control. No target shares another
target's success receipt.

The native workflow compiles source and three native ABIs once, then packages
one unsigned candidate. That artifact has a single upload root, so download
places `apk-name.txt`, `result.tsv`, the unsigned APK, extracted payload and
`oracles/` directly in the named destination. The pinned observation JARs sit
beside the candidate evidence; they are never added to the APK. Three separate
fresh emulator jobs download those same unsigned bytes, create their own
test-only signed copies and retain API-specific installed artifacts. Packaging
and each installation are distinct jobs with distinct pass/failure boundaries.

API23's adbd does not provide the modern raw shell/remote-exit protocol. The
qualifier uses `shell -tt` there, retains raw PTY output, removes CR only for
text assertions and requires exactly one fresh per-invocation exit marker with
remote status0. A transport failure, absent/duplicate marker, nonzero remote
status or missing instrumentation fields fails. API34/35 use `shell -T` and
require the actual shell-v2 exit status0. All existing negative/positive
instrumentation-code, scenario-count, cleanup and PNG assertions stay intact.
Binary PNG retrieval remains `exec-out`; it is never read through a PTY.

API23 also lacks `am get-current-user`. Its retained `dumpsys activity processes`
must contain exactly two declarations of `mStartedUserArray: [0]` and one of
`mUserLru: [0]`, with no additional declarations. The AOSP6 explicit processes
dump uses dumpAll=true and prints its started array twice; both must agree.
This intentionally admits only
a fresh emulator with singleton started-user/current-user-history lists. Newer
targets keep the direct current-user query. API23 uses its supported plain
`ps` diagnostic; newer targets retain `ps -A`.

Only `/system/bin/timeout` is admitted as the remote timer. It remains required
on API34/35; an empty API23 lookup permits the explicit host-only timeout scope.
Unknown timeout paths and a timed-out lookup fail. A host-only bound cannot
prove the remote instrumentation stopped after a host timeout; that case fails
qualification and the fresh emulator job terminates. It cannot produce a PASS.
Actual per-target execution is pending until its own installed evidence exists.

The nine scenarios are:

1. Framework launch, attached original controls, source-owned initial Sphere
   formula and a completed actual ImageView Bitmap with opaque nonuniform pixels.
2. A real Render click for an affine polynomial produces a different Bitmap and
   different complete pixel array.
3. A real Render click for `x/y` produces an actual Formula error while retaining
   the previous Bitmap identity, full pixels and unrecycled state. The baseline
   is captured in the same main-thread action immediately before the invalid
   request, avoiding a stale observer snapshot.
4. `TextView.onEditorAction(IME_ACTION_DONE)` uses the real installed editor
   listener and produces a new Sphere frame. This is a framework editor-action
   callback check, not physical keyboard/IME acceptance.
5. A real Examples click opens the actual dialog; UiAutomation selects its Torus
   accessibility item. The editor must contain the exact source-owned formula
   and the displayed Bitmap must change.
6. Save PNG must issue exactly one actual CREATE_DOCUMENT intent matching
   OPENABLE and image/png. An Instrumentation ActivityMonitor blocks only that
   request and returns RESULT_CANCELED. The current Bitmap identity/pixels stay
   intact. No document provider, stream encoding or external file is accepted
   by this scenario.
7. A second real Save click receives framework RESULT_OK with a fresh destination
   URI supplied by an ActivityMonitor. The unchanged installed Activity must
   open the separate test application's provider with exact mode `w`, encode
   its pending Bitmap and close the actual output descriptor within90seconds.
   The observer checks the exact PNG signature, decodes the actual provider
   bytes through BitmapFactory and compares width, height and every pixel with
   the ImageView snapshot taken in the Save click's main-thread action. Save
   must retain the displayed Bitmap and complete pixel array.
8. `Activity.recreate()` produces a distinct framework Activity, destroys the
   previous one and restores the Torus formula and complete deterministic pixel
   array. It does not simulate lifecycle exports.
9. A new real render request is submitted immediately before `Activity.finish()`;
   the framework must destroy the Activity within10seconds. A further bounded
   idle interval permits queued cleanup/delivery to run. Production native
   registry counters remain private; this is not a leak-counter assertion.

The entry is
`org.algebraicvarietyexplorer.idricqualification.InstalledObserver`. Success
requires Instrumentation.finish(-1) and Bundle fields
`ave_observer_result=PASS Explorer installed checked-DEX Activity` and
`scenarios=9`. Failure finishes with0, the corresponding FAIL marker,
the completed scenario count and `stack` containing the first Throwable trace.
The host must inspect those exact fields and code, not only adb exit status.

The unchanged Smali observer is independently assembled and decoded locally.
Android framework execution for the matrix is pending. Pixel observations prove actual image content,
change, retention and deterministic recreation; they are not an independent
numerical implementation. Pinch, physical IME, interaction with the real system
picker UI, physical devices and production signing/update compatibility remain
unqualified. The test provider does not qualify arbitrary third-party providers.

## Positive PNG destination and close observation

`ExportProvider` and `ExportCloseListener` belong only to the separate test APK.
The provider is exported solely so the unchanged candidate can reach it without
adding test permissions, a shared UID or production URI grants. It serves only
`/exports/<32 lowercase hex digits>` paths in its own private files directory.
Each positive invocation generates a fresh random token and requires no prior
open or bytes. The first exact `w` open creates an atomic open receipt; repeated
write opens and other write modes fail. Read opens use read-only descriptors.

The actual output descriptor uses Android's ParcelFileDescriptor OnCloseListener.
Only its asynchronous clean-close callback creates the close receipt; an error
creates a separate failure receipt. The instrumentation waits on the provider's
own inspection before reading, so partial files or preexisting exports cannot
satisfy the check. This observes descriptor closure, not an explicit-close versus
finalization distinction, native live counters or arbitrary provider error
recovery. Reads and decoding close their own streams. Saved Bitmap dimensions
are immutable metadata read on the instrumentation thread.

The ActivityMonitor supplies an ordinary ActivityResult from the real
CREATE_DOCUMENT request. Android delivers that result to the actual Activity;
the observer never calls onActivityResult, source exports, the PNG encoder or
the candidate's worker directly. The test provider never creates PNG content.
Only the production ContentResolver/Bitmap.compress path can create it.

Successful instrumentation returns `png_export_token` and
`png_export=PASS actual provider bytes dimensions pixels and descriptor close`.
The host validates the token, retrieves that exact provider-private PNG using
the debug test APK's run-as capability, independently checks its eight-byte
signature and retains the bytes and SHA256 with the installed observations.
These artifacts remain pending until an actual hosted execution succeeds.

## Blank-Bitmap sensitivity control

The separate instrumentation invocation with Bundle argument
`ave_negative_control=blank_bitmap` first obtains a completed real Activity
frame through the same normal launch/wait path. Before the first scenario is
counted, it creates a fresh equally sized ARGB_8888 Bitmap, fills it with one
opaque color and assigns it to the real ImageView on the main thread. It then
reuses the ordinary snapshot and `actualPixels` predicate in the same main-thread
action, so no source callback can replace that test image between mutation and
measurement. The existing nonuniform assertion must fail with
`actual ImageView Bitmap must contain more than one opaque pixel color`.
There is no unconditional failure in this control and the candidate DEX is
unchanged. A PASS result would mean the observer sensitivity check failed.

Expected control receipt: Instrumentation code0, the ordinary FAIL marker,
`ave_negative_control=blank_bitmap`, `scenarios=0`, the exact nonuniform
assertion in `stack`, `ave_negative_control_applied=true`, and
`observer_cleanup=destroyed`. The applied flag changes only after the real
ImageView mutation and its snapshot, so a uniform first application frame
cannot masquerade as control detection. Failure cleanup uses a
main-thread finish-only action and waits at most10seconds for real framework
destruction before finishing instrumentation; cleanup failure is reported
separately without replacing the first diagnostic. The positive invocation
omits that argument and retains its exact nine scenarios. Run this control in
a separate process before the primary invocation; it is observer sensitivity
evidence, never an application defect or candidate mutant.
