# Source-owned Explorer interaction and quality

## Type sketch before implementation

The maintained source target is `c-lua/idric/AVEInteraction.idric`; this directory
owns its qualification sources and receipts. The reference behavior is the
current `AlgebraicSurfaceView.java`, `SurfaceRenderController.java` and
`RenderQuality.java` in this checkout. The numerical renderer is outside this
change.

`Orientation` contains Double yaw, pitch and zoom. `InteractionState` retains
that orientation, the previous Float32 coordinates and the Int64 uptime of the
last delivered notification. The initial orientation is `(0.55, -0.35, 1.0)`
and the initial last-notification uptime is zero. An absent previous coordinate
pair denotes the original zero-valued Java float fields, until the first touch
sample arrives.

The local Float32 type is an independent checked external domain using the
qualified module's type name. Its representation and operations stay private;
its abstract type must be visible to an Activity's typed MotionEvent bindings.
The existing qualified generic `dex:float32:subtract` operation performs each
drag subtraction before explicit `Float.doubleValue` widening. No Double alias,
new numeric syntax or Java candidate producer is selected.

Central APIs are initial/reset state; touch down/move; Float32 scale-factor
application; `notify_view_changed : Bool -> Bool -> Int64 -> InteractionState ->
(InteractionState, Maybe ViewChange)`; and
`render_size : RenderQuality -> Int32 -> Int32 -> Maybe RenderSize`.
`ViewChange` carries the orientation and Interactive/Final quality selected from
the gesture-finished flag. The clock and listener presence are supplied by the
Activity, so these functions own no framework side effects or callback lifetime.

Invariants: drag multiplication/division remains left-associated in the
original order; width/height divisors are at least 1; pitch is clamped to
[-1.45,1.45]; zoom to [0.45,4]. Java Math min/max foreign bindings preserve the
original floating-point edge behavior. A notification without a listener
leaves the timestamp unchanged. Interactive updates require a signed Int64
uptime difference of at least 70ms; final updates bypass that condition and
become the new timestamp. Suppression does not discard the updated orientation.

Quality sizing rejects nonpositive input dimensions, then uses maximum 144 or
384, Double division by the larger input dimension, a maximum scale of 1,
per-axis multiplication, `Math.round(D)J`, Int64-to-Int32 cast and only then a
minimum of 32. Positive input dimensions bound the rounded value by 384, making
the cast exact. Whether the actual compiler supports this cast is an execution
question, not an assumption; preserve its first diagnostic if refused.

The exact frontend is the retained compiler under
`compiler-replay/.tools/Idric/_`. The authoritative compiled DEX driver must be
supplied by the coordinating agent before generation. No driver build or
alternative candidate-producing backend is authorized here. Host checks can
exercise pure timestamp/reset/quality-selection behavior without pretending to
execute DEX-only Float32 and Java Math foreign operations. Source-to-DEX,
independent decode, ART and actual normal-Activity behavior are separate gates.

## Results

The retained frontend successfully typechecks `AVEInteraction.idric`. Its first
attempt required an explicit `Orientation` annotation on the local record
update in `scale_view`; the unannotated expression
`let camera = { zoom := ... } state.camera` produced `Can't infer type for this
record update`. No numeric rule changed.

The first host check included `render_size` calls with invalid dimensions.
Chez still visited its DEX-only `Math.round` declaration and refused:
`The given specifier '["dex:static:Ljava/lang/Math;:round:(D)J"]' was not accepted
by any backend.` Those invalid-dimension checks belong in the actual DEX fixture;
the host fixture is limited to state, timestamp and quality-selection behavior.
No host replacement for the Float32/Java Math operations was introduced.

`RenderQuality` is imported publicly from the authoritative shared pure module
at `ave-render-session/c-lua/idric/RenderQuality.idric`, commit `b4746acd`.
The provisional local enum was removed after that owner was supplied.
Dependency TTCs are the coordinating agent's actual checked files at
`ave-activity-build/dependencies/ttc`; the interaction source does not edit or
reproduce that shared module.

The final shared-quality source and scalar qualification exports typecheck.
The host state/reset/notification fixture compiles and executes through the
retained frontend and Chez runtime. Its actual source mutation changing the
interactive threshold from 70 to 71 exits 1 with the designated `at 70ms`
failure. The real Float32 and Math operations remain in the DEX qualification
graph; the host fixture does not replace them.

The coordinating agent supplied the authoritative compiled driver from backend
`0ae25e38a35e829197644cecf8ec2d63935c0705`, program SHA256
`f80c83b5f51f9403f27a6fa693a4005720d203385e25936e70a42534ac70ac7b`.
`verify.grease` ran through the exact retained Grease runtime with that driver,
the checked backend/dependency TTC paths, and pinned smali/baksmali jars. The
complete verifier passed. Its actual source candidate is 22812 bytes, SHA256
`4bc1e646ad55d7c18b270ee6edc2de8b8f1da4f0c024514de0cb73febb2b2d03`.
The repeat is byte-identical. Independent decoding observes `sub-float`,
`Float.doubleValue` and `Math.round(D)J`; source sizing's Int64-to-Int32 cast
therefore compiles through the actual checked backend rather than being merely
assumed supported.

The compiled source mutant that widens coordinates before subtracting has
SHA256 `34ebb994f1710ea43979d5ded68c1bbaef89a7c1ca50b10153932e409f212383`.
The quality-maximum mutation from 144 to 145 has SHA256
`5f9a5ebc8cbc22082fd98cd1299eecc561a0dd4d2c2557e9d2700d63c025af09`.
Both differ from the positive candidate. The independent runner assembles,
SHA256 `76d0a364bf94395b9bb9303da339c78a41e8403a7263a905f1dcbc7e1d6c9042`.
Its fixed expectations include these order-sensitive witnesses:

| Observation | Expected |
| --- | --- |
| yaw after x = 33554432f, previous x = 1f, width = 33554432 | 5.26238898038469 |
| zoom after 3 * widen(0.2f) | 0.6000000089406967 |
| Interactive sizing 288 by 65 | 144 by 33 |
| Final sizing 768 by 65 | 384 by 33 |
| Interactive sizing 10000 by 1 | 144 by 32 |
| either quality sizing 10 by 100 | 32 by 100 |

The runner also checks pitch/zoom clamps, previous-sample retention through
blocked moves and reset, zero coordinates before the first DOWN, notification
timestamps and invalid dimensions. `observe-art.grease` requires status 0 and
the exact positive marker; each compiled mutation must produce the designated
failure marker and status 87. Unexpected Throwable status 88 cannot count as a
mutation rejection. ART and actual normal-Activity execution remain pending.

Local execution receipts are under
`/workspace/scratch/38fef1ec20fc/ave-interaction-verified`; `inputs.sha256` binds
the actual source, shared quality TTC, frontend program and supplied driver.

## Language work

The actual checked Int64-to-Int32 cast of `Math.round`'s bounded result is
supported by the supplied compiler. No backend change or fallback was needed
for these interaction semantics. The next unexercised acceptance boundary is
ART behavior of this exact candidate and independent observer, followed by
integration into the normal Activity's source-owned state and real events.
