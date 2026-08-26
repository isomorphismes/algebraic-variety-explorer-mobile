#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/ci/release-values.sh"

mode="${1:-unsigned}"
apk="${2:-$REPO_ROOT/.build/$AVE_RELEASE_APK_NAME}"
[[ "$mode" == unsigned || "$mode" == signed ]] || {
    printf 'usage: %s [unsigned|signed] [APK]\n' "$0" >&2
    exit 2
}

fail() {
    printf 'apk: %s\n' "$*" >&2
    exit 1
}

readonly SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
[[ -n "$SDK_ROOT" ]] || fail "ANDROID_SDK_ROOT or ANDROID_HOME is required"
readonly BUILD_TOOLS="$SDK_ROOT/build-tools/$AVE_BUILD_TOOLS_VERSION"
readonly AAPT="$BUILD_TOOLS/aapt"
readonly APKSIGNER="$BUILD_TOOLS/apksigner"
readonly ZIPALIGN="$BUILD_TOOLS/zipalign"
[[ -x "$AAPT" ]] || fail "missing $AAPT"
[[ -x "$APKSIGNER" ]] || fail "missing $APKSIGNER"
[[ -x "$ZIPALIGN" ]] || fail "missing $ZIPALIGN"
[[ -s "$apk" ]] || fail "missing or empty APK: $apk"

scratch="$(mktemp -d "${TMPDIR:-/tmp}/ave-apk.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT

unzip -t "$apk" >/dev/null
unzip -Z1 "$apk" > "$scratch/files"
[[ ! -s "$scratch/files" ]] && fail "APK has no entries"
for required in AndroidManifest.xml classes.dex resources.arsc; do
    grep -Fxq "$required" "$scratch/files" || fail "APK is missing $required"
done
if sort "$scratch/files" | uniq -d | grep -q .; then
    fail "APK contains duplicate ZIP entries"
fi
if grep -Eq '^lib/[^/]+/' "$scratch/files"; then
    fail "this Java-only release unexpectedly contains native ABI libraries"
fi
if grep -Eq '^META-INF/.*\.(RSA|DSA|EC|SF)$' "$scratch/files"; then
    fail "APK contains JAR signing entries"
fi

"$ZIPALIGN" -c -p 4 "$apk"
if [[ "$mode" == unsigned ]]; then
    if "$APKSIGNER" verify "$apk" >/dev/null 2>&1; then
        fail "F-Droid input APK is unexpectedly signed"
    fi
else
    "$APKSIGNER" verify --verbose --print-certs "$apk" > "$scratch/signing"
    grep -Fq 'Verifies' "$scratch/signing" || fail "APK signature verification produced no result"
fi

"$AAPT" dump badging "$apk" > "$scratch/badging"
grep -Fq "package: name='$AVE_APPLICATION_ID' versionCode='$AVE_VERSION_CODE' versionName='$AVE_VERSION_NAME'" \
    "$scratch/badging" || fail "package or version identity is wrong"
grep -Fq "sdkVersion:'$AVE_MIN_SDK'" "$scratch/badging" || fail "minimum SDK is wrong"
grep -Fq "targetSdkVersion:'$AVE_TARGET_SDK'" "$scratch/badging" || fail "target SDK is wrong"
grep -Fq "application-label:'Algebraic Variety Explorer'" "$scratch/badging" ||
    fail "application label is wrong"
grep -Fq "launchable-activity: name='$AVE_APPLICATION_ID.MainActivity'" "$scratch/badging" ||
    fail "launcher activity is wrong"
if grep -Eq '^uses-permission' "$scratch/badging"; then
    fail "the built APK unexpectedly requests a permission"
fi

"$AAPT" dump xmltree "$apk" AndroidManifest.xml > "$scratch/manifest-tree"
if grep -Eq 'android:(debuggable|testOnly|usesCleartextTraffic)' "$scratch/manifest-tree"; then
    fail "release manifest contains a forbidden debug/test/network attribute"
fi

sha256sum "$apk"
