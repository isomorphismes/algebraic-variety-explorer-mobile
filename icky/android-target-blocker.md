# Android target blocker for the Java-free app path

The Java-free Android application path is blocked before SURFER-specific code
generation. The Icky DMD build used for this translation rejects both Android
target triples, including a tiny runtime-free function.

Compiler qualification source: `dilapidated-shed/ick` commit
`ccf61ab82659b9eadee2d05b489fb195956cef88` (the Icky DMD line used with the
matching druntime and Phobos pins in `.github/workflows/icky-dmd.yml`). The
compiler reports DMD 2.113.0.

Minimal reproducer:

```d
module surfer_android_target_minimal;

extern(C) int surfer_android_entry() {
    return 0;
}
```

Compile it with either target:

```text
dmd -conf= -betterC -c -target=armv7a-linux-android surfer_android_target_minimal.d
dmd -conf= -betterC -c -target=aarch64-linux-android surfer_android_target_minimal.d
```

Both fail before producing an object with:

```text
Error: unknown architecture `armv7a` (or `aarch64`) for `-target`
Error: unknown C runtime environment `android` for `-target`
Error: the architecture must not be changed in the Environment64 section
```

The existing app targets Android, and its requested continuation removes the
Java implementation. Compiling an Icky D Android library or package therefore
depends on compiler support for the app's Android ABI and C runtime. This PR
does not add a C, JNI, DEX, or Java workaround inside SURFER. Stop the Android
entrypoint/package translation here and resolve compiler target support on the
Icky DMD line first.
