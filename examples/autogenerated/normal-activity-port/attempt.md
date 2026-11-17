# Program attempt: normal AVE Activity

Status: PARTIAL — source port in progress; no APK or UI execution claim.

## Purpose

Replace the application's Java source with the accepted B′ arrangement:
Idriç owns formula semantics and screen state, C owns the existing numerical
renderer, and direct DEX owns an ordinary platform Activity. The program keeps
the platform EditText, IME, selection/composition, dialogs and document picker.
It does not replace them with a native editor or a Java relay.

The original MainActivity, SurfaceRenderController, AlgebraicSurfaceView,
RendererEngine, PNG exporter, XML and strings were read before implementation.
The accepted audit is `ave_no_java_translation_audit.md`, Library
`libfile_a10d65077ba88191b8d76e31804a11e1` (September22,280lines); the later
`surfer-refactor-review-and-moon-jobs.md` separately identifies the original
controller's pre-post generation race. Its historical implementation stop was
superseded by the user's instruction to proceed. No acceptance gate is erased.

## Intended behavior

Retain the original formula language and seven examples, platform editing and
Done/Enter action, render/examples/save/about controls, status messages, image
fit, original F32 drag subtraction before widening, pinch clamps,70ms throttle,
144/384 quality sizing, system-bar insets, lifecycle and system PNG picker.
Failed preparation/render/save leaves the prior successful display available.

## Type-system sketch

### Values and domains

- Platform references remain distinct checked external domains: Activity,
  View/EditText/TextView/ImageView, Editable, MotionEvent, ScaleGestureDetector,
  WindowInsets, dialog/listeners, Intent/Uri, Bitmap, Executor/Runnable and stream.
- `AVEInteraction` owns the camera/gesture recipe and shares `RenderQuality`
  with `RenderedBitmap`; it does not define a second quality model.
- A private per-Activity `IORef ActivityPhase` is installed before acquiring
  widgets, native session or executors. Its `Starting`, `Ready`, `Diagnostic`
  and `Closed` cases distinguish acquisition, live state and diagnostic display.
  Only `Ready` contains the UI-thread `IORef ActivityState`, which holds widget references, original padding,
  interaction state, current accepted surface/bitmap, one active-request marker,
  latest pending immutable request, pending PNG bitmap and closed state.
- Native session/epoch values are opaque thread-safe cancellation identities,
  not counters manipulated in source and not storage for formula/UI semantics.
- A worker carries immutable request values. It prepares a NEW native surface,
  renders to a fresh bitmap, and posts a typed result. It never reads/writes the
  Activity IORef. Only the UI completion reads that cell.

### Types and signatures

```text
read_activity_phase : ActivityReference → PrimIO (IORef ActivityPhase)
write_activity_phase : ActivityReference → IORef ActivityPhase → PrimIO ()
activity_state : ActivityReference → IO (Maybe (IORef ActivityState))
request_render : ActivityReference → RenderQuality → IO ()
run_request : ImmutableRequest → IO ()
deliver_result : ActivityReference → RequestIdentity → RenderOutcome → IO ()
receive_editor_action : ActivityReference → TextViewReference → Int32 → KeyEventReference → IO Bool
receive_touch : ActivityReference → ViewReference → MotionEventReference → IO Bool
receive_picker : ActivityReference → Int32 → Int32 → IntentReference → IO ()
```

### Actions and effects

UI actions read/modify only their Activity's cell. The ordinary IORef is never
shared for concurrent mutation or observation. While a worker is active, a new
request overwrites the UI-owned pending request and begins a new native epoch;
it does not append another executor task. Completion clears the active marker
and starts only the newest pending request. Captured Runnable values retain
immutable request/result data through the generic checked callback factory.

### Laws, invariants, and errors

1. At most one worker is submitted/running per controller; pending work is at
   most the newest request. An obsolete worker checks its epoch before work.
2. UI completion rechecks both closed state and current epoch when it executes.
   A generation check made before posting is insufficient.
3. The accepted surface/bitmap pair changes only after current-generation
   rendering succeeds. A newly prepared surface is released on stale/error
   delivery; the previous pair remains intact. `replace_native_formula` is not
   used for this transaction because it retires the old handle before rendering.
4. Close invalidates the native session and marks UI state closed. Late results
   cannot replace the display and still release their provisional resources.
5. Callback fields never return null as a source cell. Platform null values
   (notably KeyEvent, picker Intent/Uri and output stream) require explicit checks.
6. Startup, worker, Bitmap and PNG exceptions require real source catch/finally
   support. No missing exception path is silently treated as success.
7. Startup brackets each successfully acquired executor and session until the
   complete state is committed. Close attempts every acquired owner with nested
   finally actions and ends the phase even if cleanup throws. Callbacks on a
   non-Ready phase do not read an uninitialized ActivityState field.
8. The PNG action closes an opened stream once, retains the primary encoder
   exception and adds a close exception as suppressed, matching try-with-resources.
   Its bookkeeping cell is allocated before the stream is opened, and a true
   outer finally attempts close even if exception bookkeeping itself throws.
9. A completion's commit guard is allocated before native surface acquisition.
   The worker hands it off unchanged; only the UI reads or writes it. The outer
   delivery finally covers phase/currentness lookup and pending-request startup,
   releasing an uncommitted surface even when one of those operations throws.

### Runtime and backend boundary

Use retained checked frontend740bbf2b1, the exact combined normal-Activity DEX
backend supplied by the parent, checked private Activity fields, copied native
snapshots, fresh output arrays/Bitmap and captured IO Unit Runnables. Native
session/epoch cancellation is provided by its numerical owner. Source wrappers
`RenderQuality`, `RenderedBitmap`, `RenderSession` and `RequestedBitmap` are exact
copies of the independent owner commit02da16296a81358fdf2f7aa213aeb95698b988c1.
The main candidate uses the18-word epoch renderer. Its map requires the actual
packaged `libave.so` through `library ave`; no property or Java loading relay is
used. Root owns native integration and packaging.

The initial expansion budgets are2147483647 terms/products, reflecting the
existing signed-Int32 array/count transport boundary, rather than the4096-item
fixture budgets. This is a checked resource refusal boundary, not a degree cap
or a promise that such an allocation fits the device.

## Idriç attempt

Maintained source modules live in `c-lua/idric`; focused failing programs,
checks and accounts remain under this directory. The additive XML layout uses
platform ImageView with fitCenter and retains the original platform EditText.
Existing Java remains the reference until the complete replacement is accepted.

## Result or failure

All 20 modules of the complete Activity source pass a fresh frontend check
using frontend740bbf2b1 and the combined direct-DEX driver. The post-correction
`final-v2` emission completed with raw compiler exit0 using driver SHA256
`a2641ca7eb34f596b6d3ad9a9ba821b7014d5116ec1454572e6ab80f9f45b773`.
Its clean source snapshot is commita997329077025e8de85844deed959e2e3a01c469.
The original emitted DEX is522520 bytes, SHA256
`cf9b314a3211b2abf78b0b465aee44e8d0b3b2ddde0ef8475ddf8c92a1ad3025`.
Independent baksmali decode and independent Smali reassembly both pass. The
original DEX is retained as candidate; reassembly is a separate structural check.

The decoded candidate contains the Activity superclass, private managed field,
all seven callback interfaces, correctly ordered parent lifecycle calls,
Boolean/reference callback returns, `System.loadLibrary`, copied preparation
and the18-word native renderer. It includes diagnostic-screen insets, PNG
exception cleanup and a platform `OnLayoutChangeListener` that
requests Final rendering when nonzero image dimensions change. The exact
original Java file at this checkout has no `onSizeChanged` override; the layout
listener supplies resize behavior for the normal ImageView port. Its real
ten-argument source export is included in the maintained compilation helper.
`emit.grease` preserves raw exit, source snapshots, source/compiler
hashes, decoded classes and explicit pending execution gates.

Independent source review subsequently found two exception-only cleanup windows:
PNG bookkeeping could throw before close, and UI lookup could throw before the
delivery guard was installed. Both are corrected as described above, and the
complete20-module source check and post-correction emission pass. Independent
review found no additional concrete startup or ordinary-path coalescing race;
this is bounded source review, not runtime evidence. The later XML-only
commitb7f4439 preserves the original ink background around the fitted bitmap;
it changes no DEX source.

Interaction host/state/throttle/Float32 emission checks are separately recorded
in `interaction/attempt.md`. Whole Activity ART, installed lifecycle, editor/IME,
gestures/insets, picker/PNG, APK/update identity and physical-device checks have
not run. No alternate compiler or hand-encoded candidate is substituted.

## Fallback

None. No Java/Kotlin/native editor, app-specific raw DEX plan or signer is added.

## Idriç language work exposed

Reduced source programs exposed the real callback lifecycle, API23 null,
Object[] resource-formatting and typed exception capabilities that are now in
the combined backend. `PickerLifecycle.idric` intentionally retains its initial
API24 `Objects.isNull` mistake as evidence; it is not the production path or an
API23 claim. Production uses the checked null intrinsic. `FormattedStatus`
retains the actual SDK `Resources.getString(I,Object[])` requirement; production
uses boxed Integer/Long and a real ArrayList.toArray result, not text replacement.
The main producer required no app-specific raw plan or native UI mechanism.

## Allocation after UI handoff

The decoded composite initially constructed a new Nothing object after posting
the completed frame to the UI, before clearing the worker's provisional owner.
If that allocation failed after delivery, worker cleanup could release an
already transferred surface. The worker now reads and retains its existing
empty marker before native acquisition and reuses it for both clear operations.
The final full-Activity qualifier passed emission, independent decode and
reassembly. Its retained plan shows the post call followed by ArrayList.set
and return, without a new constructor allocation in that handoff interval.
This is the bounded handoff correction, not a claim that every possible JVM
allocation failure has been exercised.
