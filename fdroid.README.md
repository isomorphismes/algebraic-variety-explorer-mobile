# F-Droid release path

Algebraic Variety Explorer already has an Apache-2.0 license and a source-only unsigned Android release build.

1. Run the `F-Droid release build` workflow. It runs the JVM tests, builds `./build.sh release`, verifies package/version identity, and retains the unsigned APK as evidence.
2. Commit the intended release and tag that exact commit `v0.1.1`.
3. Replace `FULL_COMMIT_HASH` in `org.algebraicvarietyexplorer.yml.template` with the full hash of the tagged commit.
4. Copy the template to `fdroiddata/metadata/org.algebraicvarietyexplorer.yml`.
5. Make the two Maven Central libraries named under `extlibs` available to the F-Droid build, as expected by the metadata recipe.
6. Copy the flat `store.*.txt` files into F-Droid's localized metadata layout.
7. Run `fdroid lint org.algebraicvarietyexplorer` and submit the fdroiddata merge request.

The metadata invokes `./build.sh release`; F-Droid rebuilds from public source and applies its own signing key. The upstream unsigned APK is a build gate and inspection artifact rather than a submitted binary.

After first inclusion, `UpdateCheckMode: Tags` and `AutoUpdateMode: Version` let F-Droid discover stable `v<major>.<minor>.<patch>` tags automatically.
