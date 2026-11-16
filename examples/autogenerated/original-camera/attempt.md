# Original camera translation

The earlier quality path used an algebraically simplified rotation recipe.
Actual original observations disagree: the rotated-wide camera direction has
z bits `bff0000000000001`; its origin and inverse normal matrix have small
nonzero components. The candidate therefore ports the complete original
sequence instead of replacing those values with ideal rotation identities.

`surfer_original_camera.inc` composes the unchanged AVE settings, including
camera translation, full matrix products, LU inverse, normalization, projected
offsets, all three ray spaces and left-to-right interpolation. The separate
Sun-derived `surfer_vecmath.c` arithmetic module retains the original GPLv2
with Classpath Exception notices and complete license. Its interface has only
fixed-size numeric values and a synchronous continuation callback.

The four transformed polynomials consume the resulting surface basis. Sample
coordinates use the original viewport offsets, endpoints and start/increment
sequence. Legacy single-sample rendering retains its previous recipe and
successful bytes. No Java candidate or alternate compiler is introduced.

## Ownership and type sketch

The current implementation language boundary remains typed Idriç prepared
surface ownership followed by the existing C numerical adapter. A future
Idriç representation would use `Matrix 4 4 F64`, `Vector 3 F64`, three distinct
ray-space types, and a scoped `CameraView` borrowed by a synchronous render.
Its constructor would return either validated finite geometry, cancellation,
or invalid input. An inverse operation should carry an operation-order
witness or opaque primitive so a backend cannot silently use a symbolic
transpose or reassociate the arithmetic. No runtime/compiler language gap
required a new helper language for this fixed-array C translation.

The actual C camera lives on the render stack; its pointer cannot outlive the
synchronous call. The vecmath module owns no heap storage or global state.
Its continuation callback propagates the authoritative operation context;
singularity/nonfinite inverse refusal cannot overwrite cancellation.

## Local observations and remaining gates

The exact qualified ICK host compiler at source
`fbe86e23d55cfec2000c08e61deea2a407fd7175` compiled with
`-fno-fast-math -ffp-contract=off`. Candidate raw bits match all 3252 records
from the exploratory original observer documented in `oracle.md`. Real
compiled mutations of normalization, offset, interpolation and LU inverse
each fail on a designated camera observation. In particular, cancellation
inputs distinguish `(origin+du*u)+dv*v` from `origin+(du*u+dv*v)`.

The existing transformed-polynomial corpus and its four compiled mutants
still pass after linking the separate vecmath module. Interactive and Final
exercise respectively 228 and 317 injected allocation failures; their 33
cancellation checkpoints per mode preserve status and private ownership.
Core, status, bounded AA, render-frame and cooperative-session tests pass.
The legacy 32179-byte control remains SHA256
`65f44c201676e330068804e4059a369cb6479efa1673660fd78a42681a1f55ca`.

Local ASan/UBSan execution passes with leak detection disabled. Both maintained
verification helpers correctly stop when LeakSanitizer refuses this ptraced
environment. They retain that failure and require actual hosted leak checks;
no local leak PASS or Java 17 PASS is claimed. Hosted frozen-original/JDK17
execution, complete default-lit images, roots/gradient/lighting composition,
tile/thread behavior, Android target arithmetic and physical devices remain
separate acceptance obligations.
