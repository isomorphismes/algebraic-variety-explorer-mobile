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
unpacks it without compiling, rejects non-regular/non-directory entries,
requires the fixed 1167-file content manifest and records provenance. The
canonical sorted file-hash manifest has SHA256
`edb1c9560113d60a4e2ace1e74defd67e71005414379b2b7c27eb8d976cf55c6`.
The complete 1292-entry file/directory profile has SHA256
`c81fed0074a5a2a1837df5ec3b4a35e78cb92178e0a27081b984762357455364`;
this also rejects added empty directories and non-regular entries.
Only after those checks succeed does preparation remove the consumed archive.
All source files and portable bootstrap seeds remain visible to F-Droid's
source scanner. The two existing locked Smali inspector declarations are
unchanged; no scanner exclusion is added for Chez or candidate code.

During the actual build, `verify-chez-source` recomputes the entire manifest
against that fixed digest. It rejects additions as well as changed/missing
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

Local execution of preparation passed: the unchanged archive was verified,
all source content/entries matched their fixed profiles, provenance was written
and the consumed archive was absent afterward. A changed archive failed before
creating a source directory. A changed source file and an added empty directory
each failed its intended profile check; the restored tree passed. Grease
parsing and metadata checks passed. The new source-scanner pass and actual Chez
compilation in the pinned F-Droid buildserver remain NOT_RUN at this checkpoint.
