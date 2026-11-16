# Bounded installed replay of the first complete checked Activity APK

## Purpose and boundaries

The exact source/native build at
`b779e912328fa52a5f5c6595b41b22608a590f68`, workflow run43829052041,
completed checked-source/formula ART and all three native ABI jobs. Its
[package job133180974400](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/actions/runs/43829052041/job/133180974400)
assembled the APK, then stopped because the checker expected `sdkVersion:'23'`
while pinned aapt2 emitted `minSdkVersion:'23'`. Installed execution did not run.

This diagnostic replays only that frozen candidate while current-head canonical
builds proceed independently. It is not a current-head gate or shipping build.

## Inputs, actions and evidence

The workflow checks out its own exact head separately from the frozen b779
source. Four exact artifact IDs from run43829052041 supply the checked DEX and
three production native libraries. Single-ID downloads use merge-multiple to
retain the known artifact-root layout. The retained input identities are:

| Artifact | ID |
| --- | --- |
| explorer-formula-b779e912328fa52a5f5c6595b41b22608a590f68 | 14207839986 |
| surfer-native-arm64-v8a-b779e912328fa52a5f5c6595b41b22608a590f68 | 14208823177 |
| surfer-native-armeabi-v7a-b779e912328fa52a5f5c6595b41b22608a590f68 | 14208009901 |
| surfer-native-x86_64-b779e912328fa52a5f5c6595b41b22608a590f68 | 14208654512 |

The Grease wrapper requires the exact old source revision, clean tracked old
source, old Activity evidence head and all three old native source-head rows.
It retains the original package helper, makes exactly the observed diagnostic
literal correction in a separate copy, checks both fixed SHA256 values and
retains the patch. The frozen helper then checks all material Idriç, C, header,
resource, native-library and DEX bytes against that old source and its receipts.
It creates fresh complete unsigned-package evidence; the failed earlier APK is
not used as qualified input. No candidate compilation or native rebuild occurs.

The unchanged old `qualify-installed.grease` and old independent observer then
run their negative blank-Bitmap control and all nine installed scenarios on a
fresh API34/x86_64 emulator. They preserve their test-only signing boundary,
PNG-provider byte/dimension/pixel/close observations and exact installed bytes.
The APK keeps the old `-idric-unsigned.apk` filename expected by that helper.
No new shipping certificate is introduced.
The uploaded evidence excludes every `**/*.p12` file: the unchanged old helper
can leave its test-only private key after an early signing failure. This is an
artifact exclusion, not a claim that every old-helper failure cleans that file.

`provenance.tsv` distinguishes candidate source head/run from workflow source
head. Installed observations, including any failure, belong only to b779.
Current-head acceptance and physical-device/update identity remain NOT_RUN.

## Local status

The intended input/output types are absolute paths to immutable source and
downloaded evidence, producing fresh package/diagnostic files or a failing
status. This is shell orchestration of maintained producers/observers, so Grease
is used directly; no replacement Idriç program or numerical oracle is needed.
No fallback is proposed. SDK packaging and installed execution remain NOT_RUN
until this workflow executes; source/parsing checks do not imply UI behavior.

Local checks pass: the wrapper parses through the exact retained Grease runtime;
its actual literal transform yields patched-helper SHA256
`01520bf79898e072bb5ca34ff5b5ca04c2d719440ffcdeb8ccbe0eab8ff7f600`
from original-helper
`77e6e1955f702b8756d15b9bec526944be99446bc001feb84f90f043e5004115`.
The unchanged installed helper is pinned as
`ed018b4160fd1ecc167965e6ea3ca5a1627d27753979c3bf38f1d63b0fc5f30d`.
Passing current source as the frozen source fails at the exact revision guard,
with its intended diagnostic and no output directory created. No SDK package
or installed-execution PASS is inferred from these checks. No GitHub dispatch
operation is exposed in this session; the narrow PR trigger runs on publication.
