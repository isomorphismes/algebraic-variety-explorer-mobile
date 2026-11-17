# Verified Chez source before the F-Droid scanner

The official Chez Scheme 10.4.1 source release remains fixed at archive SHA256
`2e74952db7bc177f0c3602e2217a341ba677d733eec4cd7726418c3a4e1ef308`.
It contains 1167 regular files, no symbolic links and no nested gzip/ZIP/JAR or
native ELF/object libraries. Its C, Scheme and Zuo sources include two portable
bytecode bootstrap seeds in `boot/pb`. The upstream `BUILDING` account explains
that these standard portable seeds bootstrap native machine types; they are
not a substitute native compiler executable.

F-Droid's [metadata reference](https://f-droid.org/docs/Build_Metadata_Reference/)
places preparation before source scanning and compilation in the actual build
phase. The source scanner rejected the still-packed source distribution before
any compiler bootstrap ran. This repair prepares inspectable source rather
than adding an archive exception or changing the requested Scheme program.

`make -f fdroid/Makefile prepare-chez-source` verifies the original archive,
unpacks it without compiling, rejects non-regular/non-directory entries and
requires the fixed 1167-file upstream content manifest. That canonical sorted
file-hash manifest has SHA256
`edb1c9560113d60a4e2ace1e74defd67e71005414379b2b7c27eb8d976cf55c6`.
The complete 1292-entry file/directory profile has SHA256
`c81fed0074a5a2a1837df5ec3b4a35e78cb92178e0a27081b984762357455364`;
this also rejects added empty directories and non-regular entries. Both full
upstream manifests are retained independently of the prepared profiles.

Preparation then verifies and removes exactly the 38-byte upstream LZ4
command-line test fixture `lz4/tests/goldenSamples/skip.bin`, SHA256
`3fec2ac0604510a1327930b4450f2b48080d648a1d593d7b3b2072394275adc4`.
Its sole textual consumer is `lz4/tests/test-lz4-skippable.sh:3`, invoked by
`lz4/tests/Makefile`'s explicit `test-lz4-skippable` target. Chez instead lists
its production LZ4 source inputs in `c/build.zuo:163–168` and builds `liblz4.a`
in `lz4/lib` at lines 357–368. That library path does not consume the fixture.
This prepared snapshot does not qualify the full upstream LZ4 CLI test suite.

The resulting prepared tree has 1166 files and 1291 file/directory entries.
Its content manifest has SHA256
`2293add776428288d30d1f90d90ab6b411cf93ed1ccf2ae707f6d7821a566f97`
and its entry profile has SHA256
`c5694ec102f4b86a69fe10414e27e2e988f5d37a7f2f62b88748e14ee2110054`.
The original and prepared manifests differ by precisely that one fixture;
every production source and both portable boot seeds retain their bytes.
Only after both profile checks succeed does preparation remove the consumed
archive. All retained files remain visible to F-Droid's source scanner. The two
existing locked Smali inspector declarations are unchanged; no scanner
exclusion is added for Chez or candidate code.

During the actual build, `verify-chez-source` recomputes the prepared manifests
against their fixed digests. It rejects additions as well as changed/missing
files. The source-tools entry compiles this exact tree through the owned ICK
host compiler with the unchanged pinned bootstrap's threaded, no-X11,
no-curses, as-is profile. It installs to Idriç's expected versioned toolchain
prefix, verifies version 10.4.1 and threading, and verifies the source profile
again. The unchanged pinned Idriç bootstrap then uses that already source-built
Scheme through its existing first branch. No frontend source patch, apt Chez,
repacked archive or network acquisition is involved in the application build.

The input contracts are `VerifiedArchive → IO VerifiedSourceTree` before the
scanner and `VerifiedSourceTree × OwnedHostCompiler → IO ThreadedChez10_4_1`
during the build. Missing, changed, extra or non-regular source entries are
failures. The original archive and fixed manifest digests bind provenance;
neither a mutable local receipt nor the existence of an executable establishes
source identity. Signing, candidate payload production and installed behavior
remain separate stages.

Local execution of preparation passed: both upstream and prepared profiles
matched, the exact fixture was verified before removal, provenance retained
both stages, and the consumed archive was absent afterward. The earlier
changed-archive, changed-source and added-directory refusals remain enforced.

The exact pinned `fdroidserver` revision
`6af4c4216e43d0fcb29e33919cd0fe8fef7e7400` was acquired and its existing scanner
CLI executed locally in current-source-state mode against the repository and
prepared Chez tree. It found 0 problems and exited 0. Restoring the exact
fixture reproduced `Found binary at .../lz4/tests/goldenSamples/skip.bin` and
exit 1; removal restored 0 problems/exit 0. No new checker was written. The two
Smali inspector jars were absent in this local source-scan case; their existing
two exemptions had already been exercised by the hosted scan. This local
source result is separate from a full Trixie buildserver run, APK scan, Chez
compilation or F-Droid policy approval.
