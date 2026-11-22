#!/usr/bin/env bash
set -euo pipefail

# Prepare a Cat Food index candidate. This is not signing or publication.
# The caller must run the pinned AICI release-delivery action on the actual
# finished APK immediately before calling this script.
if (( $# != 6 )); then
    echo "usage: c67-release-record.sh SOURCE_SHA UNSIGNED_DIR SIGNED_APK AICI_RECEIPT RELEASE_ASSET_URL NEW_OUTPUT_ROW" >&2
    exit 2
fi
source_sha=$1
unsigned_dir=$2
signed_apk=$3
receipt=$4
release_url=$5
output=$6
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
repo=isomorphismes/algebraic-variety-explorer-mobile
policy_sha=fcc9ea05c952c75605af5cd8cd23d0db6f31142b

fail() { printf 'C67 producer record refused: %s\n' "$*" >&2; exit 1; }
field() {
    awk -F '\t' -v key="$1" '$1 == key { n++; value = $2 } END {
        if (n != 1 || value == "") exit 2
        print value
    }' "$receipt"
}
require_value() {
    local key=$1 expected=$2 observed
    observed=$(field "$key") || fail "missing or duplicate receipt field: $key"
    [[ "$observed" == "$expected" ]] || fail "receipt $key mismatch"
}
build_value() {
    awk -F '\t' -v key="$1" '$1 == key { n++; value = $2 } END {
        if (n != 1 || value == "") exit 2
        print value
    }' "$root/build-values.tsv"
}

[[ "$source_sha" =~ ^[0-9a-f]{40}$ ]] || fail 'source revision must be a full SHA'
[[ "$(git -C "$root" rev-parse HEAD)" == "$source_sha" ]] || fail 'checked-out source differs from producer source'
[[ -z "$(git -C "$root" status --porcelain --untracked-files=no)" ]] || fail 'producer checkout has tracked modifications'
[[ -d "$unsigned_dir" && -f "$signed_apk" && -f "$receipt" ]] || fail 'required file missing'
[[ ! -e "$output" && -d "$(dirname -- "$output")" ]] || fail 'output location is not fresh'

package=$(build_value APPLICATION_ID) || fail 'application package configuration missing'
version_code=$(build_value VERSION_CODE) || fail 'version configuration missing'
[[ "$package" == org.algebraicvarietyexplorer ]] || fail 'unexpected package migration'
[[ "$version_code" =~ ^[1-9][0-9]*$ ]] || fail 'invalid version code'

mapfile -d '' -t unsigned_apks < <(find "$unsigned_dir" -maxdepth 1 -type f -name '*-C67-unsigned.apk' -print0)
(( ${#unsigned_apks[@]} == 1 )) || fail 'expected exactly one C67 unsigned input'
unsigned_apk=${unsigned_apks[0]}
[[ -f "$unsigned_dir/apk.sha256" && -f "$unsigned_dir/profile.tsv" &&
   -f "$unsigned_dir/result.tsv" &&
   -f "$unsigned_dir/evidence/packaging-head.txt" &&
   -f "$unsigned_dir/evidence/packaging-status.txt" ]] || fail 'C67 packaging evidence incomplete'
[[ "$(cat "$unsigned_dir/evidence/packaging-head.txt")" == "$source_sha" ]] || fail 'wrong packaging source revision'
[[ ! -s "$unsigned_dir/evidence/packaging-status.txt" ]] || fail 'dirty packaging source'
cmp -s "$unsigned_dir/profile.tsv" <(printf 'profile\tc67\nabi\tarm64-v8a\n') || fail 'C67 profile is not single ARM64'
grep -Fxq "$(printf 'production_JNI_arm64-v8a\tPASS')" "$unsigned_dir/result.tsv" || fail 'ARM64 producer did not pass'
grep -Fxq "$(printf 'unsigned_pure_DEX_APK\tPASS')" "$unsigned_dir/result.tsv" || fail 'unsigned producer did not pass'
[[ "$(wc -l < "$unsigned_dir/apk.sha256")" == 1 ]] || fail 'APK digest manifest must contain one entry'
unsigned_hash=$(sha256sum "$unsigned_apk" | cut -d ' ' -f1)
grep -Fxq "$unsigned_hash  $(basename -- "$unsigned_apk")" "$unsigned_dir/apk.sha256" || fail 'unsigned source digest mismatch'

# Receipt binding is supplementary to, not a substitute for, AICI inspection.
awk -F '\t' 'NF != 2 || $1 == "" || seen[$1]++ { bad = 1 }
    END { if (bad || NR != 11) exit 2 }' "$receipt" || fail 'malformed AICI receipt'
require_value schema aici-android-release-delivery-v1
require_value result PASS
require_value package "$package"
require_value version_code "$version_code"
require_value abi arm64-v8a
require_value target c67
require_value signing_lane release
require_value policy_commit "$policy_sha"
signed_hash=$(sha256sum "$signed_apk" | cut -d ' ' -f1)
signed_bytes=$(wc -c < "$signed_apk" | tr -d '[:space:]')
require_value apk_sha256 "$signed_hash"
require_value apk_bytes "$signed_bytes"
signer=$(field signer_cert_sha256) || fail 'no signer certificate digest'
[[ "$signer" =~ ^[0-9a-f]{64}$ ]] || fail 'invalid signer certificate digest'

# Signing may add v1 META-INF files but must not rewrite any application byte.
unzip -t "$unsigned_apk" >/dev/null || fail 'invalid unsigned APK'
unzip -t "$signed_apk" >/dev/null || fail 'invalid signed APK'
signed_entries=$(unzip -Z1 "$signed_apk") || fail 'invalid signed ZIP entries'
if printf '%s\n' "$signed_entries" | grep '^META-INF/' | \
   grep -Ev '^META-INF/(MANIFEST.MF|[^/]+\.(SF|RSA|EC|DSA))$'; then
    fail 'unexpected signing metadata'
fi
cmp -s <(unzip -Z1 "$unsigned_apk" | sort) \
       <(printf '%s\n' "$signed_entries" | grep -v '^META-INF/' | sort) ||
    fail 'signed APK entry inventory differs from unsigned source'
while IFS= read -r entry; do
    cmp -s <(unzip -p "$unsigned_apk" "$entry") <(unzip -p "$signed_apk" "$entry") ||
        fail "signed APK changed producer entry $entry"
done < <(unzip -Z1 "$unsigned_apk")

[[ "$release_url" =~ ^https://github[.]com/isomorphismes/algebraic-variety-explorer-mobile/releases/download/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+[.]apk$ ]] ||
    fail 'release asset URL must be a canonical Explorer GitHub release URL'
[[ "$release_url" == */"$(basename -- "$signed_apk")" ]] || fail 'release URL filename differs from signed APK'

temporary=$(mktemp -- "$(dirname -- "$output")/.c67-row.XXXXXXXX")
trap 'rm -f -- "$temporary"' EXIT
printf '%s\t%s\tc67\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$repo" "$source_sha" "$package" "$version_code" "$source_sha" \
    "$policy_sha" "$signed_hash" "$signed_bytes" "$release_url" > "$temporary"
mv -T -- "$temporary" "$output"
printf 'C67 producer record prepared for review only (not published): %s\n' "$output"
