# Build the application from source

The values are absolute host paths, six pinned source revisions, three Android
ABI names, source bytes, compiler objects, a DEX image and one unsigned APK.
The operation is an effectful build, with separate source compilation, native
link and packaging stages. `build.grease` is the maintained shell composition;
the Idriç application implementation remains in `c-lua/idric`.

Central operations have these contracts:

- `source_at : AbsoluteDirectory × Component → IO Unit` accepts exactly one
  revision from `build-inputs.tsv` and rejects tracked source modifications.
- `compiler_at : AbsoluteDirectory × GNUTarget → IO Unit` verifies the declared
  compiler path and target before output creation.
- `release : Inputs × FreshDirectory → IO UnsignedApplicationEvidence` compiles
  the direct DEX backend, checked Activity and production C sources, then
  packages only those emitted bytes through the existing strict producer.

The backend compiles in a fresh local source clone for every application build.
Forcing a Make recipe without removing Idriç's TTC cache would not suffice to
prove a fresh backend compilation. The provided checkout's outputs are neither
consumed nor removed.

No reference Java class, raw candidate Smali, generated C, downloaded DEX or
prebuilt application library is an input. The locked independent decoder and
assembler inspect the emitted DEX; only the original emitted DEX is packaged.
Signing and installation are not effects of this operation.

The current Idriç project already supplies all application semantics. A shell
composition is appropriate here because it sequences the existing compiler,
resource, ELF and ZIP tools; it does not create another semantic implementation.
Grease remains the requested shell language, without a Python or Bash fallback.

Verification at introduction: exact pinned Grease parsing passed after replacing
an invalid attempted destructuring loop with three explicit `compiler_at`
calls. Help executed successfully from `/tmp`, independent of the launch
directory. Wrong command/relative paths are rejected before output creation.
The complete entry has not yet run: the local environment lacks the three
qualified cross-compiler stages and the pinned Android SDK/NDK. Hosted APK
packaging and installed acceptance remain separate obligations.

There is no new Idriç language blocker in this shell composition. The open
boundary is reproducible provisioning of the existing compiler/runtime inputs
inside F-Droid's buildserver, followed by two complete disjoint source builds.
