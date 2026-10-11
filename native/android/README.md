# Java-free SURFER native Android probe

This is a **separate experimental APK**, not the existing release and not a completed whole-program translation. It calls the maintained `surfer_render_orthographic` in `native/surfer_raytracer.c` through Android's platform `android.app.NativeActivity` and the pinned NDK's source-distributed `android_native_app_glue.c`. The new APK contains neither app-written Java nor DEX nor a Java/JNI relay.

## Current scope

The native app contains the seven exact polynomial presets from `SurfaceExamples.java`: sphere, torus, Cayley cubic, Whitney umbrella, Roman surface, heart, and David A. Madore's E6 cubic. It derives sparse gradients for each, renders a 256×256-or-smaller square through SURFER's C ray tracer, and writes the image into the native RGBA window. Tap cycles presets, drag rotates, and pinch zooms. A strip at the top marks the selected preset index, left to right.

Package: `org.algebraicvarietyexplorer.nativeprobe` (side-by-side with `org.algebraicvarietyexplorer`). Minimum Android API: 26 for this experimental build; do not infer compatibility with the current Java release's API 23 floor.

## Build

```sh
ICK_SOURCE_DIR=/path/to/pinned/ick \
ICK=/path/to/pinned/ick/stage/bin/aarch64-linux-gnu-gcc \
ANDROID_SDK_ROOT=/path/to/android/sdk \
native/android/build-native.sh arm64-v8a
```

Use `armeabi-v7a` with the matching `arm-linux-gnueabi-gcc` for MIRO A1. The CI-only `x86_64` build uses `x86_64-linux-gnu-gcc` and targets an Android emulator, not a physical phone. The required ICK source SHA is `c61e448251744a2f40ad743ebef1a027bdcd2f9d` and the NDK pin is `29.0.14206865`. This build refuses an absent, differently pinned, or non-owned ICK compiler. Every maintained C source (including the Android native glue) is compiled through ICK. The pinned Android NDK driver **only links produced object files**; it does not compile C sources. No GCC/Clang/DMD fallback exists.

The build verifies ELF architecture, entrypoint `ANativeActivity_onCreate`, segment alignment, exactly one native library in the APK, absence of DEX, debug signing and zip alignment. Object/library/APK SHA-256 hashes and compiler source identity are saved under `.build/native/<ABI>/`. See `ci/build-toolchain.tsv`.

## Not yet accepted

The existing Java app and its tests remain unchanged as the numerical/reference oracle. The C core has open parity gaps in `native/README.md`. The native shell does not implement arbitrary formula input and typed Idriç parsing, adaptive antialiasing, cancellation/latest-request-wins, system PNG picker/export, accessibility, or fully equivalent lifecycle/gesture behavior.

This is not merged or release-qualified until source-built ICK compiles the exact revision, the APK is installed/launched, semantic/image comparisons succeed, and an exact physical C67/A1 device receipt is collected. Compiled, packaged, launched, and verified equivalent are distinct evidence levels.

Flexible Pipes intent: https://github.com/isomorphisms/flexible-pipes/issues/82. Registered FP execution/delivery receipt and independent ai-ci acceptance remain required before promotion.

## Emulator execution

A third source-built ICK lane creates an x86_64 APK. The dependent emulator
job installs the exact same-head archive, launches its NativeActivity, then
runs all **seven** shipped formula presets: sphere, torus, Cayley cubic,
Whitney umbrella, Roman surface, heart, and Madore E6 cubic. It requires
a matching native preset identity, nonzero SURFER foreground, and an actual
Android screenshot for each. It decodes every image and compares all six
successive interior regions, excluding the on-screen preset indicator.

The screenshot checker rejects flat, identical, and indicator-only mutants.
The all-seven protocol passed previously in diagnostic run 38140033432 using
the ICK-built x86_64 APK from source commit 67c3911; that is provenance, not
acceptance of the current source head. The native exact-head sphere/torus gate
was green in run 38139176495 at commit 04221f4. After this protocol change
the newly selected head must pass all seven checks again. Neither protocol
proves numerical parity with Java for every polynomial or physical C67/A1
execution, nor does it replace the independent ai-ci/FP receipts.

## Bounded numerical Java/native image gate

The native emulator must additionally execute the **original maintained
Java/jsurf reference renderer** on all seven same-source polynomials, with
matching 256×256 image size and zero yaw/pitch. The Java side uses adaptive
QUINCUNX; the native side still uses single-sample orthographic rendering.
Decoded actual Android screenshots are mapped back from the centered 360×360
window to the 256×256 native grid, excluding system navigation and preset
indicator pixels.

For every case the required numerical bounds are mean absolute RGB channel
difference at most **4 of 255** and silhouette intersection-over-union at
least **0.90** (silhouette defined as over 20 channel counts from the
respective background). Earlier independent diagnostic run 38140765349
observed mean channel differences of 0.49–2.12 and IoU of 0.937–0.989.
Thresholds retain margin but must still reject wrong-surface, blank-native
and inverted-red-channel mutants for every preset: **21 negative controls**.
That exact diagnostic passed, but current-head CI must repeat it.

These are deliberately bounded single-view visual/numerical equivalence
checks, not a proof that all Java parser grammar, pathological root cases,
adaptive antialiasing, or concurrency and lifecycle behavior have been
translated. The original Java code is retained as a test oracle only until
the complete native path is qualified. Independent FP/ai-ci receipts and
physical A1/C67 tests remain mandatory.
