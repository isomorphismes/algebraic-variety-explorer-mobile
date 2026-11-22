#!/usr/bin/env bash
set -euo pipefail

# Pure provenance-fixture tests. These files are deliberately NOT signed APKs.
# Cryptographic positive/hostile-signature cases live in ai-ci's real APK test.
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/repo/ci" "$work/input/evidence" "$work/payload/lib/arm64-v8a"
cp "$root/ci/c67-release-record.sh" "$work/repo/ci/"
printf 'APPLICATION_ID\torg.algebraicvarietyexplorer\nVERSION_CODE\t2\n' > "$work/repo/build-values.tsv"
git -C "$work/repo" init -q
git -C "$work/repo" add .
git -C "$work/repo" -c user.name=fixture -c user.email=fixture@example.invalid commit -qm fixture
source_sha=$(git -C "$work/repo" rev-parse HEAD)
printf '%s\n' "$source_sha" > "$work/input/evidence/packaging-head.txt"
: > "$work/input/evidence/packaging-status.txt"
printf 'profile\tc67\nabi\tarm64-v8a\n' > "$work/input/profile.tsv"
printf 'unsigned_pure_DEX_APK\tPASS\nproduction_JNI_arm64-v8a\tPASS\n' > "$work/input/result.tsv"
printf 'manifest\n' > "$work/payload/AndroidManifest.xml"
printf 'dex\n' > "$work/payload/classes.dex"
printf 'native library\n' > "$work/payload/lib/arm64-v8a/libave.so"
unsigned="$work/input/Algebraic-Variety-Explorer-0.1.1-C67-unsigned.apk"
(cd "$work/payload" && zip -q -X "$unsigned" AndroidManifest.xml classes.dex lib/arm64-v8a/libave.so)
(cd "$work/input" && sha256sum "$(basename "$unsigned")" > apk.sha256)
signed="$work/Algebraic-Variety-Explorer-C67-candidate.apk"
cp "$unsigned" "$signed"
receipt="$work/verified.tsv"
output="$work/candidate.tsv"
url="https://github.com/isomorphismes/algebraic-variety-explorer-mobile/releases/download/candidate/$(basename "$signed")"
signer=$(printf 'a%.0s' {1..64})
policy=fcc9ea05c952c75605af5cd8cd23d0db6f31142b
write_receipt() {
    local hash bytes
    hash=$(sha256sum "$signed" | cut -d ' ' -f1)
    bytes=$(wc -c < "$signed" | tr -d '[:space:]')
    printf 'schema\taici-android-release-delivery-v1\nresult\tPASS\npackage\torg.algebraicvarietyexplorer\nversion_code\t2\nabi\tarm64-v8a\ntarget\tc67\nsigning_lane\trelease\nsigner_cert_sha256\t%s\napk_sha256\t%s\napk_bytes\t%s\npolicy_commit\t%s\n' "$signer" "$hash" "$bytes" "$policy" > "$receipt"
}
run() {
    bash "$work/repo/ci/c67-release-record.sh" "$1" "$work/input" "$signed" "$receipt" "$2" "$output"
}
refuse() {
    local name=$1 source=$2 address=$3
    rm -f -- "$output"
    if run "$source" "$address" > "$work/$name.log" 2>&1; then
        echo "unexpected admission: $name" >&2
        exit 1
    fi
    [[ ! -e "$output" ]] || { echo "row left behind on $name" >&2; exit 1; }
    printf 'REJECTED\t%s\n' "$name"
}
write_receipt
run "$source_sha" "$url"
[[ $(awk -F '\t' '{print NF}' "$output") == 10 ]]
[[ $(cut -f2 "$output") == "$source_sha" ]]
[[ $(cut -f7 "$output") == "$policy" ]]
[[ $(cut -f8 "$output") == "$(sha256sum "$signed" | cut -d ' ' -f1)" ]]
printf 'PASS\tbound source, ABI, receipt, final bytes, and index row\n'

refuse wrong-source 0000000000000000000000000000000000000000 "$url"
refuse wrong-asset "$source_sha" "https://github.com/other/repo/releases/download/candidate/$(basename "$signed")"
cp "$work/input/profile.tsv" "$work/profile.saved"
printf 'profile\tuniversal\nabi\tarm64-v8a\n' > "$work/input/profile.tsv"
refuse wrong-profile "$source_sha" "$url"
cp "$work/profile.saved" "$work/input/profile.tsv"
printf 'policy_commit\t%s\n' "$policy" >> "$receipt"
refuse duplicate-receipt "$source_sha" "$url"
write_receipt
sed -i "s/$policy/0000000000000000000000000000000000000000/" "$receipt"
refuse wrong-policy "$source_sha" "$url"
write_receipt
printf 'tampered\n' > "$work/payload/lib/arm64-v8a/libave.so"
(cd "$work/payload" && zip -q -X "$signed" lib/arm64-v8a/libave.so)
write_receipt
refuse signed-payload-substitution "$source_sha" "$url"
cp "$unsigned" "$signed"
write_receipt
printf 'junk\n' >> "$signed"
refuse digest-mismatch "$source_sha" "$url"
printf 'PASS\tprovenance hostile controls (no signing claims)\n'
