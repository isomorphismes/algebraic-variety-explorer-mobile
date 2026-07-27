# F-Droid submission

1. Publish this source in a public HTTPS Git repository.
2. Commit and tag version `v0.1.1`.
3. Copy `org.algebraicvarietyexplorer.yml.template` to
   `fdroiddata/metadata/org.algebraicvarietyexplorer.yml`.
4. Replace `REPOSITORY_URL` and `FULL_COMMIT_HASH`.
5. Make the two Maven Central libraries named under `extlibs` available to the
   F-Droid build, or replace those entries with the dependency mechanism chosen
   by the reviewing packager.
6. Copy the flat `store.*.txt` files into F-Droid's localized metadata layout.
7. Run `fdroid lint org.algebraicvarietyexplorer` and submit the fdroiddata
   merge request.

The metadata invokes `./build.sh release`. F-Droid then applies its own
signature to the resulting unsigned APK.
