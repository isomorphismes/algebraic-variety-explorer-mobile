#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APK="${1:?usage: self-test-apk.sh APK}"
readonly SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/ave-apk-self-test.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

cp "$APK" "$SCRATCH/forbidden-native.apk"
mkdir -p "$SCRATCH/payload/lib/arm64-v8a"
printf 'not an ELF library\n' > "$SCRATCH/payload/lib/arm64-v8a/libunexpected.so"
(
    cd "$SCRATCH/payload"
    zip -q -r "$SCRATCH/forbidden-native.apk" lib
)

if bash "$REPO_ROOT/ci/verify-apk.sh" unsigned "$SCRATCH/forbidden-native.apk" \
    > "$SCRATCH/verifier-output" 2>&1; then
    printf 'self-test: APK verifier accepted an undeclared native payload\n' >&2
    exit 1
fi
grep -Fq 'unexpectedly contains native ABI libraries' "$SCRATCH/verifier-output" || {
    cat "$SCRATCH/verifier-output" >&2
    printf 'self-test: APK verifier failed for the wrong reason\n' >&2
    exit 1
}

printf 'self-test: forbidden native APK payload was rejected\n'
