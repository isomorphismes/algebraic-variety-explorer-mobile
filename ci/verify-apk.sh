#!/bin/sh
# Historical executable interface; canonical APK policy is implemented in Grease.
set -eu
project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}
version=$(awk -F '\t' '$1 == "VERSION_NAME" { print $2 }' "$project_root/build-values.tsv")
apk=${2:-$project_root/.build/Algebraic-Variety-Explorer-$version-unsigned.apk}
exec "${AVE_GREASE:-grease}" "$project_root/ci/verify-apk.grease" "$project_root" "$sdk" "${1:-unsigned}" "$(realpath "$apk")"
