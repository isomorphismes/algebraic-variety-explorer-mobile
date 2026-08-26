#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly METADATA="$REPO_ROOT/org.algebraicvarietyexplorer.yml.template"
readonly SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/ave-ci-self-test.XXXXXX")"
trap 'cp "$SCRATCH/metadata.yml" "$METADATA"; rm -rf "$SCRATCH"' EXIT

cp "$METADATA" "$SCRATCH/metadata.yml"
sed -i 's/^CurrentVersionCode: .*/CurrentVersionCode: 999999/' "$METADATA"
if bash "$REPO_ROOT/ci/verify-metadata.sh" > "$SCRATCH/metadata-output" 2>&1; then
    printf 'self-test: metadata verifier accepted a stale version code\n' >&2
    exit 1
fi
cp "$SCRATCH/metadata.yml" "$METADATA"
bash "$REPO_ROOT/ci/verify-metadata.sh" >/dev/null

printf 'P6\n256 256\n255\nshort' > "$SCRATCH/truncated.ppm"
if python3 "$REPO_ROOT/ci/verify-preview.py" "$SCRATCH/truncated.ppm" \
    > "$SCRATCH/preview-output" 2>&1; then
    printf 'self-test: preview verifier accepted a truncated image\n' >&2
    exit 1
fi

printf 'self-test: metadata drift and truncated renderer evidence were rejected\n'
