#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly OUTPUT_DIR_INPUT="${FDROID_OUTPUT_DIR:-$REPO_ROOT/build/fdroiddata}"
readonly IMAGE="${FDROID_BUILDSERVER_IMAGE:-registry.gitlab.com/fdroid/fdroidserver:buildserver-trixie@sha256:9bae53bb4ddbf8fa5bb7385bf2e62e7c6318f99ab0d25b2a551ad38abb528068}"
readonly SOURCE_REVISION="${SOURCE_REVISION:-$(git -C "$REPO_ROOT" rev-parse HEAD)}"
readonly SOURCE_REPO="${SOURCE_REPO:-https://github.com/isomorphisms/algebraic-variety-explorer-mobile.git}"

command -v docker >/dev/null 2>&1 || {
    printf 'fdroiddata: docker is required\n' >&2
    exit 1
}
[[ "$SOURCE_REVISION" =~ ^[0-9a-f]{40}$ ]]
[[ "$IMAGE" =~ @sha256:[0-9a-f]{64}$ ]] || {
    printf 'fdroiddata: buildserver image must be pinned by digest\n' >&2
    exit 1
}

remote_refs="$(git ls-remote "$SOURCE_REPO")"
grep -Fq "$SOURCE_REVISION" <<< "$remote_refs" || {
    printf 'fdroiddata: source revision is not the tip of a public ref: %s\n' "$SOURCE_REVISION" >&2
    exit 1
}

mkdir -p "$OUTPUT_DIR_INPUT"
readonly OUTPUT_DIR="$(cd "$OUTPUT_DIR_INPUT" && pwd)"

docker run --rm \
    --volume "$REPO_ROOT:/workspace/algebraic-variety-explorer-mobile:ro" \
    --volume "$OUTPUT_DIR:/output" \
    --env SOURCE_REPO="$SOURCE_REPO" \
    --env SOURCE_REVISION="$SOURCE_REVISION" \
    "$IMAGE" \
    /workspace/algebraic-variety-explorer-mobile/fdroid/test-inside-buildserver.sh
