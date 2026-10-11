#!/usr/bin/env bash
# Verify the build-toolchain-v0 split; consumers still execute the actual compiler.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${1:-$root/ci/build-toolchain.tsv}"
expected="$(printf 'build_id\ttarget\ttoolchain\tick_revision\tick_status\tick_evidence')"
[[ "$(head -n 1 "$manifest")" == "$expected" ]] || exit 1
awk -F '\t' '
  BEGIN {
    rev="c61e448251744a2f40ad743ebef1a027bdcd2f9d"
    name[1]="native-probe-objects-arm64"; name[2]="native-probe-link-arm64"
    name[3]="native-probe-objects-arm32"; name[4]="native-probe-link-arm32"
    abi[1]="arm64-v8a"; abi[2]="arm64-v8a"
    abi[3]="armeabi-v7a"; abi[4]="armeabi-v7a"
  }
  NR > 1 {
    n=NR-1
    if (n > 4 || NF != 6 || $1 != name[n] || $2 != abi[n] ||
        $4 != rev) exit 1
    if (n % 2 == 1) {
      if ($3 != "ick" || $5 != "qualified" || $6 !~ /^receipt:/) exit 1
    } else {
      if ($3 != "ndk" || $5 !~ /^gap:/ || $6 !~ /^issue:/) exit 1
    }
  }
  END {if (NR != 5) exit 1}
' "$manifest"
echo "build-toolchain-v0: PASS"
