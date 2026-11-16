# Source provisioning and release reproducibility

The domains are immutable public source revisions, recursive submodule object
databases, a declared Linux x86_64 buildserver runtime, checksum-locked host
inspection tools, one Chez source archive, SDK/NDK installations and fresh
build directories. Effects are source/compiler builds, local Git clones,
application compilation, native linking, packaging and byte comparison.

`source_tools : PinnedSources × VerifiedArchives × HostRuntime → IO Toolchains`
must finish before
`reproduce : SourceRevision × Toolchains × SDK → IO EqualUnsignedAPKs`.
The latter must rebuild the application twice in disjoint clean source
checkouts. Its equality witness is byte equality of the final unsigned APKs,
with both hashes and the exact source revision retained. Reusing compiler
prerequisites does not permit reusing DEX, application objects or libraries.

The maintained shell composition is Grease. F-Droid fixes its metadata shell
interface to Bash and Make fixes its bootstrap recipe interface to its command
shell; those narrow boundaries call the pinned existing ICK/Cat Food bootstrap
and then enter `fdroid/source-tools.grease`. No new Bash implementation of the
application build is introduced. The original Idriç application is the real
language program; this work does not create another semantic implementation.

F-Droid prebuild acquires source and the two locked Apache-2.0 host inspectors.
It does not build a compiler or another binary before source scanning. The
actual build phase compiles host ICK, Grease, all three cross ICK stages, Chez,
Idriç, the DEX backend, the Activity and the C payloads. Local compiler/application
source clones share only the fetched object databases. Chez uses the verified
source archive, and the application build has no network acquisition step.

The host compiler’s pinned ai-ci Makefile requires GCC 13 support-runtime files
and package metadata. The Trixie recipe explicitly requests `libgcc-13-dev`,
records its own runtime packages/bytes, and never reuses Ubuntu executable
qualification. JDK 21 operates Android/DEX host tools in Trixie; the separate
original-reference semantic CI uses JDK 17 and never supplies candidate classes.

The pinned fdroiddata schema accepts a closed License enum, not SPDX
conjunctions. Its application field remains Apache-2.0; this does not change or
erase the separately compiled Sun vecmath module's GPL-2.0 with Classpath
exception. The source and APK preserve its full license and notices, documented
in THIRD_PARTY_LICENSES.md and fdroid.README.md. A compound metadata expression
was rejected by source review against that exact schema before execution.

At introduction: pinned Grease parses the source-tools, reproducibility and
APK policy programs. Source metadata and its stale-version negative control
pass locally. Full provisioning, two builds, source/APK scanning and buildserver
execution are NOT_RUN: this local host has no Docker, and the pinned image must
be exercised by the hosted production-like F-Droid gate. Source presence and
the two narrow host-tool scan declarations do not establish scanner approval.

No new Idriç language primitive is required. The remaining acceptance boundary
is execution of this exact toolchain and application path in the pinned F-Droid
buildserver, followed by actual unsigned APK equality and scanner acceptance.
