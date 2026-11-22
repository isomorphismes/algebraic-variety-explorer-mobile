# Actual prepared-surface transfer

## Owner and type sketch before implementation

Connect the actual `ExpandedSurface` producer to the accepted primitive-array
boundary. Idriç has already resolved parameters, simplified, differentiated and
expanded each polynomial in original binary64 order. This module only flattens
that typed result; it never reparses source or asks C to construct its meaning.

- Two distinct external array domains carry F64 coefficients and Int32 powers.
  Platform NIO buffers allocate/fill these primitive arrays inside the checked
  source. Buffers are construction objects, not the native ABI.
- A checked layout has five Int32 offsets for the four ordered polynomials.
  Count arithmetic uses Integer before narrowing. The total coefficient count
  must permit its interleaved xyz length in a signed32 array length.
- The native call takes version1, original family degree, the five offsets and
  the two arrays. It validates/copies synchronously before returning a positive
  Int64 handle. No AST, source text or parameter map crosses JNI.
- `NativeSurface` is a managed handle value, not a proof of unique ownership.
  The native registry validates membership and owns worker-borrow lifetimes.
  Explicit release/replacement functions preserve their typed Int64 arguments;
  no cast through the old unbounded-Int native convention is used.
- Native validation/allocation failures remain errors. A failed replacement
  does not release the previous usable handle. The arrays remain private and
  unchanged during the synchronous copy; later native use never borrows them.

Managed allocation/foreign-call exceptions currently propagate through ART.
Source-level exception/finally support and complete Activity/worker ownership
remain separate language/application prerequisites; this source does not claim
those behaviors or an APK merely from successfully producing a native handle.

## Required evidence

Compile the actual formula→preparation→ordered-expansion→array-fill source with
the typed copy-input and scalar-handle compiler capability. Observe actual
native snapshots, original ordered coefficient bits/exponents and all four
ranges; require source mutations to fail. Test release/replacement, invalid
input preserving previous state, and complete C allocation unwinding separately.
No host, JNI or ART pass is inferred before those operations execute.

The first retained-frontend check refused a multiline `if not` condition at its
`then` boundary. The layout comparison now has a descriptive Boolean binding
and explicit Boolean cases after a second offside error at `else`. No compiler
or language fallback is used.
The adapter then required an explicit `CoefficientValue` import for the
coefficient type appearing in the imported binding function's signature.

The first actual DEX attempt exposed a real compiler boundary: public source
`Int64` exports were refused, although the internal/native Int64 representation
already worked. The compiler owner added explicit signed64/J exports through
the existing paired managed bridge; no handle was reformatted as Text or cast
through the default Int ABI. With that working driver, the full actual producer
emitted323076 bytes, SHA256
`11f6548d4922f288f897d48cdea57126c5e3867a7e917dcbae1e096a395f3307`.
Pinned baksmali decoded `actual_prepare_handle(String)J` and the actual copy,
replacement and release native calls with their correct paired argument words.
This is local source/generation evidence; native and ART behavior remain pending.

The complete source-to-native path subsequently passed API34/x86_64 ART at
`cfd543e1886bc6b7eb9e1ede6641569b673aac8d` in
[run43803682868](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43803682868).
The independent native snapshot/original four-polynomial comparison, source
validation before JNI, successful/rejected replacement cycles, actual temporary
and store allocation failures, stale handles and final zero live counts passed.
Both compiled transfer-source mutations failed with designated exit80.
See `qualification.md` for exact evidence and remaining boundaries. Normal
Activity state/lifecycle/cleanup and the shipping Java replacement remain open.

## Positive bindings through the complete copied-array path

The maintained producer already accepts one immutable environment
`Text → Maybe Coefficient`; this qualification supplies `radius ↦ 2.0`, with
every other name absent. The new checked adapter has the same
`Text → IO Int64` observation type as the existing unbound adapter and calls
the same `prepare_native_surface` function. A paired Text error observation
keeps invalid/unknown parameter outcomes visible without inventing a handle.
Production preparation, derivative, expansion, array and native APIs remain
unchanged. No binding map is passed over JNI.

The independent original observer already binds radius through the original
renderer's `setParameterValue` and expands its own surface/three derivatives.
Compare those exact family degree, ordered exponents and coefficient bits with
the copied native snapshot for `x^2+y^2+z^2-radius^2` and
`radius*x+radius*y`. The latter also has one fixed expected four-polynomial
report, so a shared wrong radius cannot qualify by agreement. Repeated radius
occurrences resolve through the same function. There is no binding-list or
duplicate-key admission API: this test must not invent duplicate-key semantics.

Keep the original no-binding adapter and unbound-radius error. A formula that
mixes the known radius with an unknown name must still refuse before any JNI
entry/allocation. A third compiled source mutant binds radius to3.0; the
unchanged original/native snapshot observer must reject it with designated
exit80, while the existing coefficient/axis mutants remain required.

Status before implementation: positive bound preparation/managed expansion
already qualified separately; complete bound source→JNI behavior NOT_RUN.
Current checked Idriç and typed primitive-array transport are sufficient; no
language/runtime fallback or new semantic implementation is needed.

The amended complete `verify.grease` now passes locally through frontend
`740bbf2b1d9e811fd00c719c3473eede17ceea3b` and the exact source checkout
`89f366f7f2ee62e0a7567c558e6880e1fa7f6eec`. The reused compiler executable was
verified before and after as SHA256
`a2641ca7eb34f596b6d3ad9a9ba821b7014d5116ec1454572e6ab80f9f45b773`.
The actual325176-byte candidate is SHA256
`41d821cd60270535cfb39643c52838dfd1609a2ecd40bbf3a43aacdfcb49d07f`.
A repeated emission is identical; all three actual compiled source mutants
emit different independently decoded DEX. The wrong-radius mutant is
`8401143842169a840efde7bcf5b2f6bc7e26b93747501931fdce9a03a673defb`.
The separately assembled/decoded observer is
`469bbf36126b4b141445157d878a06d62b4456e03f748e19321b825426b464b7`.
Both maintained Grease helpers also parse through the retained exact runtime.

These are source/generation/determinism/structural observations. Positive bound
native snapshots, pre-JNI errors, original-program agreement and all three
compiled mutant rejections remain ART NOT_RUN until the maintained observers
execute. This adapter does not add parameter controls to the Activity.
