# Source-built Activity APK

`build.grease` sequences the maintained application source build. It compiles
the complete ordinary Activity from checked Idriç, compiles the C numerical and
JNI sources with the owned ICK compilers for all three declared ABIs, links
those objects against Android API 23 with NDK 29, and invokes the strict APK
producer. It consumes no APK, candidate DEX or application-library download.

Dependency provisioning is deliberately separate. A host must first build the
exact source revisions in `build-inputs.tsv`, provide the locked independent
Smali/Baksmali jars used to decode and reassemble the compiler output, and
install SDK 35, build tools 35.0.1 and NDK 29.0.14206865. The current hosted
provisioning is in `.github/workflows/idric-formula.yml` and
`.github/workflows/native-android.yml`. These jobs supply exact public source
revisions; their executable caches are acceleration, not application payloads.

Invoke `grease` with the absolute path of `build.grease` and `--help` for the
input order. The explicit repository and toolchain paths make the build
independent of the launch directory. A fresh output directory is mandatory.
The entry verifies each compiler-source checkout before building, rebuilds the
DEX backend, and leaves separate Activity, native ABI, packaging and aggregate
receipts. Native stages independently bind the actual `cc1`, source/header
bytes, object bytes, ABI, platform linker and resulting shared library.

The producer emits an **unsigned** APK. It does not manufacture a new signing
identity, install on a phone, or turn host compilation into runtime acceptance.
A persistent signer matching the installed package is still necessary for an
update. Installed emulator checks and physical C67 acceptance are separate.

## Migration boundary

At this checkpoint `build.sh`, the root manifest, and the old F-Droid recipe
still select the original Java application. `build.grease` is the replacement
source-build entry, but switching those defaults awaits the installed checked
Activity qualification. The original JVM parser/renderer remain reference
oracles; their tests do not qualify the new application package.

F-Droid must source-build Idriç, the DEX backend, Grease and three ICK compilers
inside its declared buildserver environment. The existing Java recipe and its
no-native-library policy do not cover this pipeline. A new F-Droid recipe,
scanner acceptance and two disjoint source-build reproducibility runs remain
unqualified. GitHub APK packaging cannot substitute for those results.
