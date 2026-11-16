# Unsigned checked-DEX application packaging

## Type and ownership sketch before code

The candidate is one exact checked Idriç `candidate.dex`, its source/emission
receipt and the production `libave.so` outputs of the qualified ICK Android
cross-build. Packaging combines those immutable inputs with the original AVE
resources and manifest identity. It does not compile, rewrite, disassemble or
roundtrip the candidate. The application identifier remains
`org.algebraicvarietyexplorer`, with entry Activity `Idric.Generated`, original
name/icon/theme and min23/target35. Version constants come from `build.sh`.

`package_unsigned : CheckedDex × ProductionLibraries × OriginalResources →
IO (Either PackagingFailure UnsignedApk)` is the logical boundary. SDK35.0.1
aapt2 compiles/links resources without generated Java; zip adds the exact DEX
and native libraries; zipalign verifies alignment. The producer never signs.
Input/output hashes, APK entries, manifest badging and native ELF evidence bind
the resulting APK to its inputs. First SDK compilation is hosted because this
workspace has no SDK35 tools. Grease orchestrates the external fixed-format SDK
tools; Idriç application source remains the sole candidate owner.

The installed qualification is a separate application containing only an
independent Smali Instrumentation observer. A qualifier-owned throwaway signer
may sign temporary copies of both APKs solely for the declared API34 x86_64
emulator. It cannot establish compatibility with any existing production/C67
installation. The qualifier checks exact emulator identity and package absence
before installing, never replaces or uninstalls an existing application and
records signed/unsigned digests and the temporary certificate fingerprint.

Instrumentation launches the real Activity through the Android framework and
observes actual controls, status and ImageView Bitmap data. UI operations run
on the main thread; waits are bounded on the instrumentation thread. The test
must preserve the candidate and must not impersonate its exports or implement
formula/render/UI logic. Close/recreation, error-preserves-prior-frame, editor
Done and Examples are bounded intended scenarios. IME interaction, pinch,
document-provider PNG behavior and physical-device acceptance remain separate
unless actually observed. Logs and failure statuses survive failed runs.

## Attempt and current boundary

The source candidate is provided by the normal-Activity owner and must include
the final exception-cleanup follow-up. No candidate Java, Kotlin, javac, d8,
Gradle, generated Java resources, production signer or package migration is
introduced. Test Smali is independent observation only.

Both maintained Grease helpers parse under the recovered pinned Grease runtime.
The independent Instrumentation observer assembles and decodes with the pinned
Smali tools; final observer DEX SHA256 is
`f0f2800bcfdcd68a01dd1520b1e39a150e6c730155d79f7eae27d9c4ab34937b`.
The qualifier first requires rejection of an actually applied uniform Bitmap
replacement in the real ImageView, then runs all eight positive scenarios in a
new instrumentation process. This observer mutation leaves the candidate DEX
unchanged and is not an application defect or a numerical oracle.

The ordinary Activity owner's post-cleanup input completed source emission and
independent decode/reassembly with raw compiler exit0, source snapshot a997329
and candidate SHA256
`cf9b314a3211b2abf78b0b465aee44e8d0b3b2ddde0ef8475ddf8c92a1ad3025`.
Packaging must use the current ink-background XML rather than an older layout
snapshot. Producer validation compares actual material source bytes and exact
DEX/library hashes; an ancestor revision label alone is insufficient.

The native provenance gate includes the separately compiled `surfer_vecmath.c`,
its header and `surfer_original_camera.inc`, plus the original specialization
include. Production objects must hide C symbols while explicit JNIEXPORT stays
public: the APK gate accepts exactly the ten declared JNI dynamic exports. This
is an export-visibility claim, not an absence-of-test-code claim.

The APK bundles exact repository copies of LICENSE, NOTICE,
THIRD_PARTY_LICENSES.md and native/licenses/vecmath-GPL-2-CE.txt under
assets/licenses, naming the project license PROJECT-LICENSE. Input hashes and
extracted byte comparisons cover all four, including after test signing.
No Java ExceptionStrings properties or JAR payload is introduced.

First SDK packaging and emulator execution remain pending on the hosted build.
No SDK35.0.1 tools, Android sysroot or emulator are locally available. Local
parsing and assembly do not establish packaging, installation, interaction,
update identity or physical-device acceptance. The existing checked Idriç
application owns the semantics; these Grease helpers sequence the declared SDK
tools and do not introduce an alternate candidate implementation.
