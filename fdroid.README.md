# F-Droid release path

Algebraic Variety Explorer has an Apache-2.0 license and a source-only unsigned
Android release build. Release acceptance has several distinct parts:

1. Open a pull request and require every `CI` and `F-Droid release build` job to
   pass on its exact head. The CI lane runs the parser and renderer tests,
   validates a real preview, builds a signed test APK, and installs and exercises
   it on Android API 23 and API 35 emulators.
2. The F-Droid lane verifies the release/Fastlane/dependency metadata, makes two
   clean source-archive builds, requires byte-identical unsigned APKs, and
   inspects package, version, SDK levels, launcher, permissions, signing state,
   ZIP structure, alignment, and the absence of native ABI payloads.
3. The separate `fdroiddata-recipe` job runs the metadata, scanner, and build
   path inside pinned fdroiddata and fdroidserver revisions and a buildserver
   image pinned by digest. An ordinary upstream APK build is not treated as
   proof that this recipe works.
4. After merging, require fresh successful main-branch runs for the exact commit.
   Install the exact candidate on the intended real phone and tablet and verify
   startup, rendering, drag, pinch, formula editing, examples, and PNG export.
5. Only then tag that unchanged commit `v0.1.1`. The metadata template already
   binds the build to that tag.
6. Copy `org.algebraicvarietyexplorer.yml.template` to
   `fdroiddata/metadata/org.algebraicvarietyexplorer.yml`, run
   `fdroid lint org.algebraicvarietyexplorer`, and submit the fdroiddata merge
   request.

The metadata invokes `bash ./build.sh release`. The build downloads the exact
ANTLR 3.4 and vecmath 1.5.2 runtime jars from Maven Central and checks their
SHA-256 values against `dependencies.lock`. Android platform 35 and build tools
35.0.1 are selected exactly. No private signing material or fdroiddata-only
extension library is required.

F-Droid rebuilds from public source and applies its own signing key. The
upstream unsigned APK is inspection evidence, not the submitted binary. Emulator
success does not substitute for the real-device acceptance in step 4.

After first inclusion, `UpdateCheckMode: Tags` and `AutoUpdateMode: Version` let
F-Droid discover stable `v<major>.<minor>.<patch>` tags automatically.
