# Original lighting observation adapter

The candidate numerical layer is C. This test-only adapter executes the frozen
original Java methods, because a second implementation of lighting would not
provide independent evidence. It cannot enter the Android candidate.

The input domains are finite camera-space points and eye positions (F64),
camera-space normals (F64), material/light colors and intensities (F32), and
the original collected `DrawcallStaticData`. `RenderingTask.shade` maps these
to F32 RGB and mutates the supplied normal by the original normalization and
side selection. The central observation is
`shade(point, normal, eye) -> (color, mutated_normal)`.

The collector owns active-light selection, front/back ambient products and
`LightProducts`; the adapter supplies settings and records their values.
In particular it preserves the original collector's use of the *front*
ambient intensity for the back ambient product. Color arithmetic, normal
normalization, side selection, specular powers, root finding and pixel
sampling remain inside unchanged original methods.

The separate frame mode invokes one original full-canvas `RenderingTask`.
It does not qualify host-dependent overlapping worker tiles. Candidate C,
Android libm, APK execution and physical-device results remain separate.

The oracle needs the frozen public Java source, locked Vecmath/ANTLR jars and
JDK 17. The maintained entrypoint rejects other JDK versions. A local Java 21
exploratory compilation may diagnose source behavior but must not be recorded
as Java 17 acceptance. Idriç is not used to replace the original-method oracle:
the intended owner of the expected result is the unchanged original renderer.

Output uses ordinary TSV records and raw F32/F64 bits, preserving signed zero.
No approximate equality or pixel tolerance is introduced.

No Idriç language gap is exposed by this observation adapter. The needed next
acceptance is an independent C consumer comparing these actual original bits,
including compiled mutations for binary64 specular power, side choice and the
back ambient collector behavior.

## Development observation

The maintained Grease source parses with the retained exact Grease runtime.
The local build host has Java 21.0.13 and no `javac` launcher. A separately
labelled scratch diagnostic used its actual `jdk.compiler` module with
`-source 17 -target 17`; it did not satisfy the maintained JDK 17 gate. The
diagnostic extracted local commit `ea2d392949e53dd4adf46b6aae0c27a956b23b83`
because the frozen remote commit object was unavailable locally. All seven
required original material/source hashes matched. Both lighting and pixel
modes ran twice with identical bytes and all record counts passed.

The exploratory lighting output SHA-256 was
`d3a97e54c64dc17acdd4dae229087ec72d7362d794b911a215c41fbe88ab5d4e`;
the exploratory frame output was
`27acf37987c36a6c93fa178d9825f72b1e9298e48a7298225c80a1c325f75cfe`.
These hashes describe Java 21 development observations, not hosted JDK 17,
candidate C, Android or physical-device acceptance. The maintained command is
`grease reference.grease EXPLORER LOCKED_JAR_DIRECTORY FRESH_OUTPUT`, with all
three arguments absolute; it still requires the exact original baseline and
both JDK 17 compiler and runtime.

## Canonical 44-frame extension

The later extension retains the lighting observations and replaces the earlier
26-frame exploratory sample with the explicitly documented 44-frame audit
corpus: six presets × three fixed camera states × two qualities, plus eight
targeted numerical surfaces. The later Madore example remains a separately
labelled two-frame addition. The same local Java 21 diagnostic repeated the
44 full-canvas frames (5412 pixels) and two additions (286 pixels) identically.
The canonical output hash was
`7a951dea3e2028306287b25da2b623c415e81f32d23a8e29470a4ee2f4943f51`;
the additional output hash was
`140e14af48577eb9d842feb2041e3f0db5e842663edd3a1baca8376f3af91616`.

The diagnostic host reported nine processors and the original four-thread
pool. Actual original `draw` ran three times per canonical frame. Its
overlapping tiles did **not** reproduce the full canvas everywhere: examples
included one Cayley OG pixel, six Cayley FINAL pixels and 29–31 pixels on the
surface coincident with the clipping sphere. Repeated production draws were
also not identical: the boundary-sphere second trial differed from the first
at eight pixels; Roman FINAL and the repeated sphere also differed between
trials. Full pixel arrays and difference maps were retained in the diagnostic
output. These are Java 21 observations of the original production method,
not evidence about candidate C or behavior on another host. The maintained
JDK 17 run must independently observe its own actual partition and differences.

Worker comparison deliberately reports observations without an equality
claim. A decision about deterministic full-canvas semantics versus preserving
host-dependent overlapping production partitions remains an explicit separate
acceptance boundary.

## Selected actual ray calls

The `rays` extension records coordinates received from the actual unchanged
`RenderingTask` through a delegating creator wrapper. This avoids recreating
the task's start/increment/AA coordinate sequence. The 238 labelled component
observations repeated exactly in the Java 21 development diagnostic, with
SHA-256 `6de0b7c2dda5b400b763911b25d8344d2f9bd7f1e5011e8e2e3b8374c7082143`.
The final wrapper source was recompiled and repeated those exact bytes after
all inherited camera transformations were explicitly delegated.

The actual Whitney OG center call is index 49 at `u = v = +0` for 11 × 9.
Its original dense polynomial has two coefficients `[+0, +0]`; the original
root finder returns `−0` on the clipped interval `[-1, 1]`, rather than a
missing root. The zero normal selects back ambient and the original trace is
`ff4c3e21`. These observations preserve the distinction between checking the
stored polynomial degree before shrinking versus replacing it with a
constant-zero polynomial first. They are expected-value evidence, independent
of whether the current candidate C implements that distinction.

## Ordered original tile publication

The `ordered-workers` extension was executed twice by the same explicitly
labelled Java 21 development diagnostic. On that host's observed nine
processors, the original partition yielded 1812 private tile results across
the 44 canonical frames. Their submission-order composition repeated exactly
and matched the actual unchanged `draw` executed with a test-only serial
submission-order executor for all 44 frames. The ordered observation hash was
`5153a115d6cd48e1951fae0d2f052d0735b388b3c1bbdfb535e6b05047b0a4eb`.

The ordered result differed from the full canvas on nine frames. Examples
were 34 boundary-sphere pixels, six repeated-sphere pixels, and six Cayley
FINAL pixels. This establishes why a full-canvas match alone does not settle
the chosen original tile policy. The adapter records actual per-tile bytes
and a deterministic publication ordering; it does not recreate the task's
root, sampling or shading arithmetic. Candidate C must independently match
the original tiles and ordered result. The original racing worker results
remain recorded separately, with their differing values and nondeterminism.

## Controlled original processor-count profiles

The maintained reference now runs the unchanged ordered-tile adapter with
the real JVM `-XX:ActiveProcessorCount` values 1, 2, 4 and 8, verifying the
count actually observed by the original renderer. The Java 21 development
diagnostic passed all four profiles: each complete 44-frame run repeated
exactly and matched the actual serial original draw. The profiles yielded
468, 468, 888 and 1812 original tiles respectively, with 5412 ordered pixels
per profile. No default-host racing worker run was altered by those options.

| JVM processor count | Exploratory ordered-output SHA-256 |
| --- | --- |
| 1 | `ff3d759812d14bc513ecff7f6c3eecdc8313eed557ad39f3b217737d23148da9` |
| 2 | `9eded09b89c3b72a6e8d28de383e19e7ce4c04325c41e865bdc7590c9592c103` |
| 4 | `d9fe2ab0aa8004cd0b1354604679020e1bd86cbca738103231c49bc39440a0aa` |
| 8 | `d9c386f1cdb4b3ec985ef89c3322a1cf97d1b70a29248f370bf0cd6f72b41930` |

These are controlled Java 21 JVM observations on one development host, not
JDK 17, candidate C or physical multicore-device acceptance. The maintained
JDK 17 gate and separate C consumer must execute their own exact inputs.
