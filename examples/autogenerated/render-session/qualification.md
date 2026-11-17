# Session-bound Bitmap qualification

This probe calls the real checked `RenderSession` and `RequestedBitmap`
modules through `SessionExports.idric`. It does not supply a replacement
`Idric.Generated` class or a Java implementation. The compiler must emit the
actual `(JJJIIIDDDD[I)I` native method with eighteen register words, real
primitive output allocation and platform Bitmap calls.

`RenderSessionObserver` forwards to the actual JNI entry points and observes
the native registry, counters and per-call fault controls. Its protocol observer
requires two different positive epochs, old-current false, new-current true and
one live session/epoch. `SessionBitmapRunner` obtains all1147 expected pixels
from the already qualified fourteen-word renderer and compares the resulting
real Bitmap through the existing independent Bitmap observer. Both quality
selectors are exercised and their reference pixels must differ.

The runner also checks cancellation, supersession and release before source
rendering without entering render JNI; invalid dimensions before JNI; invalid
camera and released surface; cancellation at the native final gate without
array publication; and cancellation at the source post-publication query
without Bitmap creation. Every refusal retains the previous successful Bitmap
identity, pixels, recycled state and observation count. Actual session-create,
epoch-begin and staging allocation failures pass through the checked source.
All session/epoch/store/staging/borrow/temporary live counts must return to zero.
A direct receiver probe covers wrong length, unsupported quality, null output,
nonpositive session, cancelled and released epochs with sentinel output left
unchanged. Failed begin must leave the previous epoch current.

`verify-source.grease` emits the candidate twice and requires identical bytes.
It separately compiles two source mutants: bypassing the initial currentness
refusal and bypassing the post-publication currentness refusal. The first must
be caught by the independent JNI entry count; the second by the result and
Bitmap observation. Merely producing distinct DEX is not mutant rejection.
`observe.grease` requires exit0 plus the exact PASS marker for the candidate,
and exit83 plus `FAIL Explorer render session` for each mutant. Unexpected
Throwable prints a stack and exits84; existing Bitmap pixel failures exit81.
API34/x86_64 emulator identity is checked before remote writes, and every run
uses `-Xcheck:jni`, bounded timeouts and before/after all-buffer logcat/process
diagnostics. No physical device is targeted.

The JNI publisher runs synchronously inside the native final gate. It flips
unique staging rows once and performs one complete array-region write. It
retains no JNI environment, local reference, pixel pointer or callback state.
The array is private to this source request; publication does not mutate the
prior Bitmap. The UI must still repeat exact currentness when delivering its
completion. Managed allocation/platform exceptions currently propagate;
Activity exception cleanup is a separate integration concern.

Local actual source generation, deterministic repeat, decoding and both
compiled source mutants passed at `session-source-v1` and `session-source-v2`.
The final runner was separately assembled and decoded after its expected-quality
correction, SHA256 `69a34223257c95d7803ef5a0316d2f625c09ae51ea764aaee120bee95e44e2e6`.
The source candidate/repeat SHA256 is
`c67e65c439a194f982d6faaafc38a2dfd2682c8e308c8e4a0817f2d9e4834d69`.
No NDK headers/linker are locally available. Actual JNI
compilation, all three Android ABI import checks, JNI/ART mutant rejection,
Activity behavior and physical-device acceptance remain pending. The C session
owner's host cancellation/thread/fault tests are separate evidence.

Integration order: invoke `verify-source.grease` with the checked frontend and
combined DEX driver; invoke `verify-jni.grease` with qualified ICK and pinned
NDK29 to build production and test libraries; then invoke `observe.grease` with
the declared emulator, source evidence and session-JNI evidence. New session
JNI compilation is additive; the fourteen-word render fixture stays unchanged.
