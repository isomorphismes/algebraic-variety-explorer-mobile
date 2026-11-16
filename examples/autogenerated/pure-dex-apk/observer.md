# Independent installed Activity observer

`observer/InstalledObserver.smali` extends Android Instrumentation and implements
Runnable solely for synchronized main-thread observation/actions. It is packaged
in the separate test-only application declared by `ObserverManifest.xml`.
It does not replace, subclass, reflect into or invoke exports of `Idric.Generated`;
the framework launches the real installed `Idric.Generated` Activity.

The logical observation is `InstalledActivity → IO (Either Failure EightScenarios)`.
Resource identifiers resolve against the original application package. All view,
Drawable and Bitmap reads and changes run through `runOnMainSync`; only the
instrumentation thread waits/polls. A main-thread exception is relayed back to
the instrumentation thread. Each frame deadline is90seconds, dialog selection
10seconds, recreation monitor90seconds and destruction10seconds. An external
720second device timeout and740second host timeout bound each complete invocation.

The eight scenarios are:

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
7. `Activity.recreate()` produces a distinct framework Activity, destroys the
   previous one and restores the Torus formula and complete deterministic pixel
   array. It does not simulate lifecycle exports.
8. A new real render request is submitted immediately before `Activity.finish()`;
   the framework must destroy the Activity within10seconds. A further bounded
   idle interval permits queued cleanup/delivery to run. Production native
   registry counters remain private; this is not a leak-counter assertion.

The entry is
`org.algebraicvarietyexplorer.idricqualification.InstalledObserver`. Success
requires Instrumentation.finish(-1) and Bundle fields
`ave_observer_result=PASS Explorer installed checked-DEX Activity` and
`scenarios=8`. Failure finishes with0, the corresponding FAIL marker,
the completed scenario count and `stack` containing the first Throwable trace.
The host must inspect those exact fields and code, not only adb exit status.

The Smali observer is independently assembled and decoded locally. Android
framework execution is pending. Pixel observations prove actual image content,
change, retention and deterministic recreation; they are not an independent
numerical implementation. Pinch, physical IME, document-provider PNG writing,
physical devices and production signing/update compatibility remain unqualified.

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
omits that argument and retains its exact eight scenarios. Run this control in
a separate process before the primary invocation; it is observer sensitivity
evidence, never an application defect or candidate mutant.
