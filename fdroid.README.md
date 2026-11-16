# F-Droid source recipe

The recipe builds the checked Idriç Activity and production C/JNI libraries.
The previous Java-only recipe and its no-native-library rule do not apply to
this candidate.

`org.algebraicvarietyexplorer.yml.template` declares seven immutable source
libraries. Their companion definitions are in `fdroid/srclibs`; copy those
definitions alongside the application metadata when submitting to fdroiddata.
The actual pinned fdroiddata/buildserver qualification copies them itself.

Provisioning proceeds in distinct phases:

1. F-Droid fetches the declared source revisions and recursive ICK/Grease
   submodules. The prebuild phase installs the exact Android SDK/NDK and fetches
   the checksum-locked Chez source archive plus two independent DEX inspection
   tools. No source compiler is built before the source scanner.
2. During the build phase, `fdroid/Makefile` invokes ai-ci’s pinned host ICK
   source bootstrap and qualification. The declared Trixie buildserver installs
   `libgcc-13-dev` because that bootstrap requires its exact runtime layout.
   The resulting runtime package and byte receipts remain separate from the
   Ubuntu-hosted compiler evidence.
3. The pinned Cat Food source bootstrap builds Grease through owned host ICK.
   `fdroid/source-tools.grease` then builds three separate cross-compiler
   stages from the fetched ICK source and bootstraps Idriç through host ICK.
   Local source clones use only the fetched Git object databases. Chez receives
   the pre-fetched verified source archive.
4. `fdroid/reproducible.grease` creates two disjoint clean application source
   checkouts. Each independently rebuilds the DEX backend, Activity and all
   three native application payloads, then packages and inspects an unsigned
   APK. It requires byte equality and copies the canonical unsigned output.
   Exact source-built compiler prerequisites are shared between these two
   application builds; no prebuilt application artifact is consumed.
5. The pinned fdroiddata/fdroidserver buildserver test runs the real metadata
   lint, schema, source scanner, build, APK scanner and independent APK policy.

The two Smali jars are Apache-2.0 build-time inspectors, with exact hashes in
the recipe and compiler qualifier. They never supply candidate DEX. The two
narrow `scanignore` paths refer only to those locked host tools; the producer
permits exactly the compiler-emitted `classes.dex` and three declared
`libave.so` payloads. F-Droid review and actual scanner execution must accept
this declaration; its presence is not evidence that the scanner passed.

The package ID remains `org.algebraicvarietyexplorer`, version code 2/name
0.1.1, min API 23 and target API 35. Libraries are stored uncompressed, with
16 KiB ELF and ZIP alignment. The manifest selects `Idric.Generated`.
The APK is unsigned; F-Droid applies its own persistent signing key.

The schema’s single License field names the main application’s Apache-2.0
license. The separately compiled vecmath module retains Sun’s GPL-2.0 with
Classpath exception, including its complete source notices and APK license
asset. That obligation is not replaced by the metadata field.

All new recipe/bootstrap/reproducibility/scanner results are **NOT_RUN** until
the exact current source completes the hosted production-like buildserver
gate. Earlier Java recipe success is historical evidence. Installed emulator
behavior and C67 replacement/physical behavior remain separate acceptance.

Do not tag or submit this version based only on source presence. Require the
exact-head source, renderer, complete candidate APK/installed behavior and
F-Droid buildserver results, plus the intended physical-device acceptance.
