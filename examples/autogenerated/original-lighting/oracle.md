# Original lighting and full-canvas observation

`reference.grease` extracts the immutable original jsurf Java sources from
`cfd543e1886bc6b7eb9e1ede6641569b673aac8d`, verifies material renderer files
and locked dependencies, requires JDK 17, and adds only the observation adapter.
No candidate source is in that compilation. Each mode runs twice with identical
bytes required.

The lighting mode records six scenes, 288 actual calls to
`RenderingTask.shade`, the normal mutated by that method, 12 actual collector
ambient values and 26 actual `LightProducts` pairs. Scenes exercise default
AVE materials, colored lights and materials, noninteger shininess,
specular-only, distinct front/back ambient values with all lights off,
clamping and an active light separated by disabled light slots. Inputs include
front, back, grazing and singular normals, signed zero, tiny/large normals and
40 oblique camera-space cases per scene.

The collector's original behavior is authoritative: back ambient is scaled by
the front ambient intensity. Replacing that intensity with the back material's
value would change the observed original image even though it might seem a
more natural formula.

TSV lighting records are scene-scoped. `material` contains side, RGB, ambient,
diffuse, specular and shininess as F32 hex. `ambient` contains side and RGB.
`light` contains active index, three F64 position bits, three F32 color bits and
F32 intensity bits. `products` contains active index, side and diffuse/specular
RGB bits. `shade` contains a case name; nine F64 input values (point, normal,
eye); three F32 output color bits; and three F64 post-call normal bits.

The canonical frame mode records 44 default-lit frames (5412 pixels). The six
audit presets (Sphere, Torus, Cayley, Whitney, Roman and Heart) each run at
three fixed camera states in both INTERACTIVE and FINAL sampling: 36 frames.
The chosen states are explicit qualification inputs from the existing camera
observations, not values prescribed by the audit or by the human:

| State | Canvas | Yaw | Pitch | Zoom |
| --- | --- | --- | --- | --- |
| identity | 11 × 9 | 0 | 0 | 1 |
| rotated | 13 × 11 | 0.43 | −0.71 | 1 |
| rotated-zoom | 11 × 13 | −0.61 | 0.28 | 1.75 |

Eight targeted FINAL frames use the identity state and 11 × 9 canvas:

| Name | Formula | Intended observation |
| --- | --- | --- |
| zero-empty | `0` | Constant zero / empty polynomial, background |
| plane | `z` | Linear family |
| cancellation | `(10000000000000000*x+x)-10000000000000000*x+z` | Original coefficient cancellation |
| tangent-double-plane | `z^2` | Even multiplicity and singular gradient |
| sphere-clipping-boundary | `x^2+y^2+z^2-1` | Surface coincident with clipping boundary |
| singular-umbrella | `x^2-y^2*z` | Singular surface |
| nonsquarefree-sphere | `(x^2+y^2+z^2-0.64)^2` | Repeated non-squarefree factor |
| degree-eight | `x^8+y^8+z^8-0.125` | Higher degree |

The separately labelled `additional-pixels` mode keeps the later Madore E6
example in OG/FINAL at the rotated state (2 frames, 286 pixels), without
changing the canonical audit count.

The `rays` mode captures the actual coordinates passed by the unchanged task
to `createCameraSpaceRay`. A delegating observation wrapper records arguments;
every camera operation and value is forwarded to the original creator. The
task itself computes its start, increments and adaptive sampling positions.
After the actual render, the adapter chooses observed calls nearest the view
center/corners, and the actual center-pixel call index for OG sampling. The
238 labelled records may intentionally select the same call twice; they are
not 238 distinct-ray claims.

For each selected observed coordinate, the adapter records actual camera,
clipping and surface rays; the original eye point; the original dense
univariate coefficients; the intervals from `clipRay`; the original root
finder's first root; original gradient evaluation and normal transform; and
actual `shade` and private `tracePolynomial` results. Only the task's simple
eye-interval admission is sequenced in the adapter. No root solver, polynomial
evaluation, clipping algorithm, normalization or lighting formula is recreated.
`selected_trace` is the direct original method result, separate from the
component observations. `selected_admitted` records the original
`clipPoint(point, true)` result; it preserves `ClipToSphere`'s deliberate
omission of additional point clipping after interval clipping.

Each expected frame uses one unchanged full-canvas `RenderingTask`.
`input`/`term` records expose all four original expanded XYZ polynomial arrays
before candidate transport. Coefficients are raw F64 values and exponents are
integers. Camera and pattern metadata follow the existing AA oracle format.
Pixel orientation is the original renderer's buffer, before the Android
wrapper flips rows.

The separate `workers` mode also calls the unchanged production
`CPUAlgebraicSurfaceRenderer.draw` three times per canonical frame. It records
the actual host processor count, pool size, horizontal/vertical tile steps,
every production pixel, every difference from the full canvas, and a summary
of differences from both the full canvas and the first production draw.
Overlapping endpoints and original scheduling are preserved. The reference
records these observations without requiring workers to equal the full
canvas or one another. `worker_summary` fields are frame ID, trial index,
full-canvas difference count and first-production-draw difference count.

`ordered-workers` separately observes a deterministic publication policy. It
uses the original production tile bounds and submission order, runs each
unchanged `RenderingTask` into a fresh private pixel buffer, records every
covered rectangle pixel, and composes the result in submission order. The
global canvas dimensions and shared original draw-call data remain the same;
only the output buffer changes between tasks. Endpoints overlap exactly as in
the original. The later tile's pixel wins in the explicit ordered composition.

The adapter then runs the unchanged production `draw` using a test-only
single-thread submission-order executor and requires exact equality to that
independent private-tile composition. This checks the chosen legal serial
ordering; it does not rewrite the racing production result as deterministic.
`ordered_profile` records ID, observed processors, original pool size and
original horizontal/vertical tile steps. `tile` records ID, ordinal and
inclusive global bounds. `tile_pixel` records ID, ordinal, global x/y and
ARGB. `ordered_pixel` records the composite. `ordered_difference` compares it
with the full canvas; `ordered_summary` reports ID, tile count and differing
pixel count. `serial_ordered_match` is emitted only after the actual serial
production method matches exactly. The whole mode must repeat byte for byte.

These observations are the expected values, not evidence that candidate C
matches them. The C consumer must independently verify raw fields/pixels and
reject compiled mutations. Target libm, Android execution, worker partitions
and physical devices require separate observations.
