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
