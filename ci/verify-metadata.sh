#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/ci/release-values.sh"

fail() {
    printf 'metadata: %s\n' "$*" >&2
    exit 1
}

field() {
    local expression="$1"
    local file="$2"
    sed -n "$expression" "$file"
}

readonly METADATA="$REPO_ROOT/org.algebraicvarietyexplorer.yml.template"
readonly LOCALE="$REPO_ROOT/fastlane/metadata/android/en-US"
readonly CHANGELOG="$LOCALE/changelogs/$AVE_VERSION_CODE.txt"

[[ "$(field 's/^  - versionName: \(.*\)$/\1/p' "$METADATA" | tail -n 1)" == "$AVE_VERSION_NAME" ]] ||
    fail "F-Droid build versionName does not match build.sh"
[[ "$(field 's/^    versionCode: \([0-9][0-9]*\)$/\1/p' "$METADATA" | tail -n 1)" == "$AVE_VERSION_CODE" ]] ||
    fail "F-Droid build versionCode does not match build.sh"
[[ "$(field 's/^    commit: \(.*\)$/\1/p' "$METADATA" | tail -n 1)" == "v$AVE_VERSION_NAME" ]] ||
    fail "F-Droid build commit must be v$AVE_VERSION_NAME"
[[ "$(field 's/^    output: \(.*\)$/\1/p' "$METADATA" | tail -n 1)" == ".build/$AVE_RELEASE_APK_NAME" ]] ||
    fail "F-Droid output does not match build.sh"
grep -Fxq '      - apt-get install -y openjdk-21-jdk-headless curl zip unzip' "$METADATA" ||
    fail "F-Droid sudo dependencies must match the pinned buildserver distribution"
grep -Fxq '    prebuild: sdkmanager "platforms;android-35" "build-tools;35.0.1"' "$METADATA" ||
    fail "F-Droid prebuild must install the pinned SDK and build tools"
grep -Fxq '    build: ANDROID_SDK_ROOT=$$SDK$$ bash ./build.sh release' "$METADATA" ||
    fail "F-Droid build command must use the F-Droid SDK and release target"
[[ "$(field 's/^CurrentVersion: \(.*\)$/\1/p' "$METADATA")" == "$AVE_VERSION_NAME" ]] ||
    fail "CurrentVersion does not match build.sh"
[[ "$(field 's/^CurrentVersionCode: \([0-9][0-9]*\)$/\1/p' "$METADATA")" == "$AVE_VERSION_CODE" ]] ||
    fail "CurrentVersionCode does not match build.sh"

grep -Fxq "    package=\"$AVE_APPLICATION_ID\">" "$REPO_ROOT/AndroidManifest.xml" ||
    fail "manifest package does not match build.sh"
grep -Fq 'android.intent.action.MAIN' "$REPO_ROOT/AndroidManifest.xml" ||
    fail "manifest has no launcher action"
grep -Fq 'android.intent.category.LAUNCHER' "$REPO_ROOT/AndroidManifest.xml" ||
    fail "manifest has no launcher category"
if grep -Eq '<uses-permission([[:space:]>])' "$REPO_ROOT/AndroidManifest.xml"; then
    fail "the release manifest unexpectedly requests a permission"
fi

for required in title.txt short_description.txt full_description.txt; do
    [[ -s "$LOCALE/$required" ]] || fail "missing Fastlane file: $required"
done
[[ -s "$CHANGELOG" ]] || fail "missing Fastlane changelog for versionCode $AVE_VERSION_CODE"
[[ "$(wc -m < "$LOCALE/title.txt")" -le 51 ]] || fail "Fastlane title exceeds 50 characters"
[[ "$(wc -m < "$LOCALE/short_description.txt")" -le 81 ]] ||
    fail "Fastlane short description exceeds 80 characters"
[[ "$(wc -m < "$LOCALE/full_description.txt")" -le 4001 ]] ||
    fail "Fastlane full description exceeds 4000 characters"
[[ "$(wc -m < "$CHANGELOG")" -le 501 ]] || fail "Fastlane changelog exceeds 500 characters"

cmp "$REPO_ROOT/store.title.txt" "$LOCALE/title.txt"
cmp "$REPO_ROOT/store.short_description.txt" "$LOCALE/short_description.txt"
cmp "$REPO_ROOT/store.full_description.txt" "$LOCALE/full_description.txt"
cmp "$REPO_ROOT/store.changelog.$AVE_VERSION_CODE.txt" "$CHANGELOG"

for dependency in ANTLR VECMATH JUNIT HAMCREST; do
    url="$(release_constant "${dependency}_URL")"
    sha256="$(release_constant "${dependency}_SHA256")"
    grep -Fxq "$url" "$REPO_ROOT/dependencies.lock" ||
        fail "$dependency URL is missing from dependencies.lock"
    grep -Fxq "sha256 $sha256" "$REPO_ROOT/dependencies.lock" ||
        fail "$dependency SHA-256 is missing from dependencies.lock"
done
[[ "$(grep -c '^sha256 [0-9a-f]\{64\}$' "$REPO_ROOT/dependencies.lock")" -eq 4 ]] ||
    fail "dependencies.lock must contain exactly four SHA-256 pins"

bash -n "$REPO_ROOT/build.sh"
while IFS= read -r script; do
    bash -n "$script"
done < <(find "$REPO_ROOT/ci" "$REPO_ROOT/fdroid" -type f -name '*.sh' -print | sort)
git -C "$REPO_ROOT" ls-files -s build.sh | grep -Eq '^100755 ' ||
    fail "build.sh is documented as executable but is not executable in Git"

if git -C "$REPO_ROOT" ls-files | grep -Eq '(^|/)(\.build|\.dependencies)(/|$)|\.apk$|\.aab$|\.debug\.keystore$'; then
    fail "generated build output or signing material is tracked"
fi

workflow_failure=0
while IFS= read -r use; do
    reference="${use##*@}"
    action="${use%@*}"
    if [[ "$action" != ./* && ! "$reference" =~ ^[0-9a-f]{40}$ ]]; then
        printf 'metadata: workflow action is not commit-pinned: %s\n' "$use" >&2
        workflow_failure=1
    fi
done < <(sed -n 's/^[[:space:]]*- uses: \([^ #]*\).*$/\1/p' "$REPO_ROOT"/.github/workflows/*)
(( workflow_failure == 0 )) || exit 1
if grep -R -Eq '^[[:space:]]*pull_request_target:' "$REPO_ROOT/.github/workflows"; then
    fail "pull_request_target is forbidden for build workflows"
fi

printf 'metadata: %s %s (%s), SDK %s/%s/%s, four locked dependencies\n' \
    "$AVE_APPLICATION_ID" "$AVE_VERSION_NAME" "$AVE_VERSION_CODE" \
    "$AVE_MIN_SDK" "$AVE_TARGET_SDK" "$AVE_COMPILE_SDK"
