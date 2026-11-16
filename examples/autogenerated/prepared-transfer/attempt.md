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
