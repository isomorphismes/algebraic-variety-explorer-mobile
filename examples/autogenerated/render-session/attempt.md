# Opaque render sessions and epochs

## Type sketch before implementation

`RenderSession` owns a native session identifier; `RenderEpoch` pairs that
session with a native-assigned epoch. Both remain opaque source values. The
source never increments, orders or reconstructs Int64 identities. Native begin
atomically invalidates the old epoch; failure leaves it current. Source/UI
completion checks the exact epoch again when its callback executes.

The existing14-word synchronous Bitmap probe remains unchanged. The additive
render call is `renderSessionSurface(JJJIIIDDDD[I)I`: session, epoch, surface,
width, height, quality, four Double camera values and private Int32 output.
Its explicit output contract is the same checked current-thread, synchronous,
no-retention policy, now18 DEX words. No compiler expansion is required.

Native C owns session/epoch lifetime, cancellation polling, complete staging
and final publication under its registry mutex. The synchronous publisher gets
unique mutable native staging only after computation; JNI reverses rows there
and performs one primitive-array region write. It cannot reenter session APIs
or retain its staging/context. Begin/cancel/release linearize outside that
publication. Neither a Java array reference nor a JNIEnv pointer is retained.

Create/begin return positive Int64 or negative shared status. Current returns1
for an exact live pair,0 for positive stale/closed/unknown pairs and negative
status for malformed input. Cancel/release return ordinary shared status.
Rendering adds explicit `SURFER_CANCELLED=4`; every non-OK frame is discarded.

Public source actions create a session, begin an epoch, test currentness,
cancel/release and render a Bitmap for an epoch. `render_epoch_bitmap` receives
an already owned NativeSurface and RenderSettings, allocates private output and
constructs a Bitmap only on native success and current epoch. Activity owns its
immutable request, retained surface/Bitmap and latest-request orchestration.

## Required evidence and boundaries

Use actual source→DEX→JNI, exact descriptor/wide-register checks and independent
native/Bitmap observers. Cover invalid/stale/cross-session epochs, begin/cancel/
release, cancellation before publication, publication exclusion, balanced native
lifetimes and source stale-result refusal without Int64 arithmetic. Native C
host/thread/fault tests belong to the session owner. ARMv7 build/import checks,
JNI/ART, Activity behavior and device acceptance remain distinct gates.

The native dependency is9d89dafe from the numerical/session owner; the compiler
dependency is the already qualified explicit output policy. Actual source
generation, deterministic repeat and distinct compiled currentness mutants
passed locally. The decoded native invoke occupies v26 through v43, eighteen
words. JNI compilation and ART execution remain pending. No generic compiler fallback,
Text pixel transport, Java relay or native thread pool is introduced.
