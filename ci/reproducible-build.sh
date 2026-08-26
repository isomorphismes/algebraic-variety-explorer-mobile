#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/ci/release-values.sh"

readonly OUTPUT_DIR_INPUT="${1:-$REPO_ROOT/build/reproducible-fdroid}"
readonly SOURCE_REVISION_INPUT="${SOURCE_REVISION:-HEAD}"
readonly SOURCE_REVISION="$(git -C "$REPO_ROOT" rev-parse --verify "$SOURCE_REVISION_INPUT^{commit}")"
readonly REPRODUCIBLE_SOURCE_DATE_EPOCH="$(git -C "$REPO_ROOT" show -s --format=%ct "$SOURCE_REVISION")"
readonly WORK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ave-reproducible.XXXXXX")"
trap 'rm -rf "$WORK_ROOT"' EXIT

mkdir -p "$OUTPUT_DIR_INPUT"
readonly OUTPUT_DIR="$(cd "$OUTPUT_DIR_INPUT" && pwd)"

build_once() {
    local run="$1"
    local source_dir="$WORK_ROOT/source-$run"
    local result="$OUTPUT_DIR/run-$run.apk"

    mkdir -p "$source_dir"
    git -C "$REPO_ROOT" archive "$SOURCE_REVISION" | tar -x -C "$source_dir"
    (
        cd "$source_dir"
        SOURCE_DATE_EPOCH="$REPRODUCIBLE_SOURCE_DATE_EPOCH" bash ./build.sh release
    )
    cp "$source_dir/.build/$AVE_RELEASE_APK_NAME" "$result"
    "$REPO_ROOT/ci/verify-apk.sh" unsigned "$result"
}

build_once 1
build_once 2

{
    printf 'source_revision\t%s\n' "$SOURCE_REVISION"
    printf 'source_date_epoch\t%s\n' "$REPRODUCIBLE_SOURCE_DATE_EPOCH"
    sha256sum "$OUTPUT_DIR/run-1.apk" "$OUTPUT_DIR/run-2.apk"
} > "$OUTPUT_DIR/reproducibility.txt"

if ! cmp -s "$OUTPUT_DIR/run-1.apk" "$OUTPUT_DIR/run-2.apk"; then
    if command -v diffoscope >/dev/null 2>&1; then
        diffoscope "$OUTPUT_DIR/run-1.apk" "$OUTPUT_DIR/run-2.apk" \
            > "$OUTPUT_DIR/diffoscope.txt" || true
    fi
    printf 'reproducible-build: clean APKs differ\n' >&2
    cat "$OUTPUT_DIR/reproducibility.txt" >&2
    exit 1
fi

cp "$OUTPUT_DIR/run-1.apk" "$OUTPUT_DIR/$AVE_RELEASE_APK_NAME"
(
    cd "$OUTPUT_DIR"
    sha256sum "$AVE_RELEASE_APK_NAME" > "$AVE_RELEASE_APK_NAME.sha256"
)
printf 'reproducible-build: byte-identical clean APKs from %s\n' "$SOURCE_REVISION"
