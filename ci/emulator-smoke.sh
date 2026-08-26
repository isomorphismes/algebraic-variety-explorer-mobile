#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/ci/release-values.sh"

readonly APK="${1:?usage: emulator-smoke.sh APK EVIDENCE_DIR}"
readonly EVIDENCE_DIR="${2:?usage: emulator-smoke.sh APK EVIDENCE_DIR}"
readonly ACTIVITY="$AVE_APPLICATION_ID/.MainActivity"
mkdir -p "$EVIDENCE_DIR"

snapshot() {
    local name="$1"
    adb shell uiautomator dump "/sdcard/$name.xml" >/dev/null
    adb pull "/sdcard/$name.xml" "$EVIDENCE_DIR/$name.xml" >/dev/null
}

wait_for_text() {
    local name="$1"
    local expected="$2"
    local attempt

    for attempt in $(seq 1 60); do
        snapshot "$name"
        if grep -Fq "$expected" "$EVIDENCE_DIR/$name.xml"; then
            return
        fi
        sleep 2
    done
    printf 'emulator: timed out waiting for UI text: %s\n' "$expected" >&2
    return 1
}

node_bounds() {
    local xml="$1"
    local attribute="$2"
    local expected="$3"
    python3 - "$xml" "$attribute" "$expected" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
attribute = sys.argv[2]
expected = sys.argv[3]
for node in root.iter("node"):
    if node.attrib.get(attribute) == expected:
        match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.attrib["bounds"])
        if not match:
            raise SystemExit(f"bad bounds for {expected}")
        left, top, right, bottom = map(int, match.groups())
        print(left, top, right, bottom)
        break
else:
    raise SystemExit(f"node not found: {attribute}={expected}")
PY
}

tap_text() {
    local text="$1"
    local bounds
    snapshot tap-target
    bounds="$(node_bounds "$EVIDENCE_DIR/tap-target.xml" text "$text")"
    read -r left top right bottom <<< "$bounds"
    adb shell input tap "$(((left + right) / 2))" "$(((top + bottom) / 2))"
}

drag_surface() {
    local bounds
    snapshot drag-target
    bounds="$(node_bounds \
        "$EVIDENCE_DIR/drag-target.xml" \
        content-desc \
        'Rendered real zero set of the entered polynomial')"
    read -r left top right bottom <<< "$bounds"
    local y="$(((top + bottom) / 2))"
    local start_x="$((left + (right - left) * 2 / 5))"
    local end_x="$((left + (right - left) * 3 / 5))"
    adb shell input swipe "$start_x" "$y" "$end_x" "$y" 450
}

test -s "$APK"
adb install -r "$APK"
adb logcat -c
adb shell am start -W \
    -a android.intent.action.MAIN \
    -c android.intent.category.LAUNCHER \
    -n "$ACTIVITY" \
    > "$EVIDENCE_DIR/start.txt"
grep -Fq 'Status: ok' "$EVIDENCE_DIR/start.txt"

wait_for_text initial 'Degree 2'
adb exec-out screencap -p > "$EVIDENCE_DIR/initial.png"
test -s "$EVIDENCE_DIR/initial.png"

tap_text About
wait_for_text about-dialog 'Apache License 2.0'
tap_text OK

tap_text Examples
wait_for_text examples-dialog 'Torus'
tap_text Torus
wait_for_text torus 'Degree 4'
adb exec-out screencap -p > "$EVIDENCE_DIR/torus.png"

drag_surface
wait_for_text dragged 'Degree 4'
adb exec-out screencap -p > "$EVIDENCE_DIR/torus-dragged.png"
if cmp -s "$EVIDENCE_DIR/torus.png" "$EVIDENCE_DIR/torus-dragged.png"; then
    printf 'emulator: drag did not change the rendered screen\n' >&2
    exit 1
fi

adb shell ps | tr -d '\r' | awk -v package="$AVE_APPLICATION_ID" \
    '$NF == package { found = 1 } END { exit !found }'
adb logcat -d > "$EVIDENCE_DIR/logcat.txt"
if grep -Eiq "FATAL EXCEPTION|ANR in $AVE_APPLICATION_ID|Algebraic Variety Explorer could not start" \
    "$EVIDENCE_DIR/logcat.txt"; then
    printf 'emulator: fatal process evidence found in logcat\n' >&2
    exit 1
fi

printf 'emulator: installed, launched, rendered degrees 2 and 4, opened About, and rotated a surface\n'
