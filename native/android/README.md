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

Use `armeabi-v7a` with the matching `arm-linux-gnueabi-gcc` for MIRO A1. The required ICK source SHA is `c61e448251744a2f40ad743ebef1a027bdcd2f9d` and the NDK pin is `29.0.14206865`. This build refuses an absent, differently pinned, or non-owned ICK compiler. Every maintained C source (including the Android native glue) is compiled through ICK. The pinned Android NDK driver **only links produced object files**; it does not compile C sources. No GCC/Clang/DMD fallback exists.

The build verifies ELF architecture, entrypoint `ANativeActivity_onCreate`, segment alignment, exactly one native library in the APK, absence of DEX, debug signing and zip alignment. Object/library/APK SHA-256 hashes and compiler source identity are saved under `.build/native/<ABI>/`. See `ci/build-toolchain.tsv`.

## Not yet accepted

The existing Java app and its tests remain unchanged as the numerical/reference oracle. The C core has open parity gaps in `native/README.md`. The native shell does not implement arbitrary formula input and typed Idriç parsing, adaptive antialiasing, cancellation/latest-request-wins, system PNG picker/export, accessibility, or fully equivalent lifecycle/gesture behavior.

This is not merged or release-qualified until source-built ICK compiles the exact revision, the APK is installed/launched, semantic/image comparisons succeed, and an exact physical C67/A1 device receipt is collected. Compiled, packaged, launched, and verified equivalent are distinct evidence levels.

Flexible Pipes intent: https://github.com/isomorphisms/flexible-pipes/issues/82. Registered FP execution/delivery receipt and independent ai-ci acceptance remain required before promotion.
