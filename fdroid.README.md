# F-Droid release path

Algebraic Variety Explorer already has an Apache-2.0 license and a source-only unsigned Android release build.

1. Run the `F-Droid release build` workflow. It runs the JVM tests, builds `bash ./build.sh release`, verifies package/version identity, and retains the unsigned APK as evidence.
2. Commit the intended release and tag that exact commit `v0.1.1`.
3. Replace `FULL_COMMIT_HASH` in `org.algebraicvarietyexplorer.yml.template` with the full hash of the tagged commit.
4. Copy the template to `fdroiddata/metadata/org.algebraicvarietyexplorer.yml`.
5. Copy the flat `store.*.txt` files into F-Droid's localized metadata layout.
6. Run `fdroid lint org.algebraicvarietyexplorer` and submit the fdroiddata merge request.

The metadata invokes `bash ./build.sh release`. The build script downloads the exact ANTLR 3.4 and vecmath 1.5.2 runtime jars from Maven Central and checks their pinned SHA-256 values from `dependencies.lock` before compiling. No private signing material or fdroiddata-only extlib is required.

F-Droid rebuilds from public source and applies its own signing key. The upstream unsigned APK is a build gate and inspection artifact rather than a submitted binary.

After first inclusion, `UpdateCheckMode: Tags` and `AutoUpdateMode: Version` let F-Droid discover stable `v<major>.<minor>.<patch>` tags automatically.
