#!/usr/bin/env bash
set -euo pipefail

readonly RELEASE_VALUES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly RELEASE_VALUES_BUILD="$RELEASE_VALUES_ROOT/build.sh"

release_constant() {
    local name="$1"
    local value

    value="$(sed -n "s/^readonly $name=\"\([^\"]*\)\"$/\1/p" "$RELEASE_VALUES_BUILD")"
    [[ -n "$value" ]] || {
        printf 'release-values: missing %s in %s\n' "$name" "$RELEASE_VALUES_BUILD" >&2
        return 1
    }
    [[ "$(printf '%s\n' "$value" | wc -l)" -eq 1 ]] || {
        printf 'release-values: duplicate %s in %s\n' "$name" "$RELEASE_VALUES_BUILD" >&2
        return 1
    }
    printf '%s\n' "$value"
}

AVE_APPLICATION_ID="$(release_constant APPLICATION_ID)"
AVE_COMPILE_SDK="$(release_constant COMPILE_SDK)"
AVE_BUILD_TOOLS_VERSION="$(release_constant BUILD_TOOLS_VERSION)"
AVE_MIN_SDK="$(release_constant MIN_SDK)"
AVE_TARGET_SDK="$(release_constant TARGET_SDK)"
AVE_VERSION_CODE="$(release_constant VERSION_CODE)"
AVE_VERSION_NAME="$(release_constant VERSION_NAME)"
AVE_RELEASE_APK_NAME="Algebraic-Variety-Explorer-$AVE_VERSION_NAME-unsigned.apk"
AVE_DEBUG_APK_NAME="Algebraic-Variety-Explorer-$AVE_VERSION_NAME-debug.apk"

[[ "$AVE_APPLICATION_ID" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]
[[ "$AVE_COMPILE_SDK" =~ ^[0-9]+$ ]]
[[ "$AVE_BUILD_TOOLS_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$AVE_MIN_SDK" =~ ^[0-9]+$ ]]
[[ "$AVE_TARGET_SDK" =~ ^[0-9]+$ ]]
[[ "$AVE_VERSION_CODE" =~ ^[1-9][0-9]*$ ]]
[[ "$AVE_VERSION_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
(( AVE_MIN_SDK <= AVE_TARGET_SDK ))
(( AVE_TARGET_SDK <= AVE_COMPILE_SDK ))

export \
    AVE_APPLICATION_ID \
    AVE_COMPILE_SDK \
    AVE_BUILD_TOOLS_VERSION \
    AVE_MIN_SDK \
    AVE_TARGET_SDK \
    AVE_VERSION_CODE \
    AVE_VERSION_NAME \
    AVE_RELEASE_APK_NAME \
    AVE_DEBUG_APK_NAME
