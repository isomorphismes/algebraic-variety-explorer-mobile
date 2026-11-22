#!/usr/bin/env bash
# Execute all seven shipped SURFER formulas through the actual native Android APK.
# The enclosing CI job downloads its exact same-head ICK-built artifact.
set -euo pipefail

apk="${1:?expected signed APK path}"
evidence="${2:?expected output directory}"
test -s "$apk"
mkdir -p "$evidence"
sha256sum "$apk" > "$evidence/executed-apk.sha256"

adb shell wm size 360x640
adb shell wm density 160
adb logcat -c
adb install -r "$apk" | tee "$evidence/install.txt"
grep -q 'Success' "$evidence/install.txt"
adb shell am start -W -n \
    org.algebraicvarietyexplorer.nativeprobe/android.app.NativeActivity \
    > "$evidence/launch.txt"
cat "$evidence/launch.txt"
grep -Eq 'Status: ok' "$evidence/launch.txt"

preset_names=(
    "Sphere"
    "Torus"
    "Cayley cubic"
    "Whitney umbrella"
    "Roman surface"
    "Heart"
    "Madore E6 cubic"
)
file_names=(sphere torus cayley whitney roman heart madore-e6)

observe() {
    local index="$1" attempt
    for attempt in $(seq 1 90); do
        adb logcat -d -s 'SurferNative:I' '*:S' > "$evidence/logcat.txt"
        if grep -Fq "preset=$index name=${preset_names[$index]}" "$evidence/logcat.txt" &&
           grep -Eq "frame preset=$index size=.* foreground=[1-9][0-9]*" \
                    "$evidence/logcat.txt"; then
            return 0
        fi
        sleep 2
    done
    printf 'no native foreground for preset %s (%s)\n' \
        "$index" "${preset_names[$index]}" >&2
    cat "$evidence/logcat.txt" >&2
    return 1
}

: > "$evidence/image-verdict.txt"
previous=""
for index in "${!preset_names[@]}"; do
    if (( index > 0 )); then
        adb shell input tap 180 320
    fi
    observe "$index"
    sleep 1
    screenshot="$evidence/${file_names[$index]}.png"
    adb exec-out screencap -p > "$screenshot"
    test -s "$screenshot"

    if [[ -n "$previous" ]]; then
        printf 'Transition %s -> %s: ' \
            "${preset_names[$((index - 1))]}" "${preset_names[$index]}" \
            | tee -a "$evidence/image-verdict.txt"
        python3 ci/verify-native-screenshots.py "$previous" "$screenshot" \
            | tee -a "$evidence/image-verdict.txt"
    fi
    previous="$screenshot"
done

# Exercise the actual native keypad. API 35 draws edge-to-edge under
# Android's three-button navigation bar; raw (x,y) positions at y=616 are
# *system navigation*, not the editor's bottom row.
adb shell input tap 330 30
# Retain screen and raw logs even if a future input/window regression causes
# the editor geometry to disappear. The one tag priority admits INFO and ERROR.
adb exec-out screencap -p > "$evidence/editor-open.png"
layout=""
for attempt in $(seq 1 15); do
    adb logcat -d -s 'SurferNative:I' '*:S' \
        > "$evidence/editor-open-logcat.txt"
    layout="$(grep -E 'editor open width=[0-9]+ height=[0-9]+ bottom_inset=[0-9]+ row_height=[0-9]+' \
        "$evidence/editor-open-logcat.txt" | tail -1 || true)"
    [[ -n "$layout" ]] && break
    sleep 1
done
if [[ -z "$layout" ]]; then
    adb logcat -d -v time > "$evidence/editor-open-full-logcat.txt" || true
    adb logcat -d -b crash -v time > "$evidence/editor-open-crash-logcat.txt" || true
    adb shell pidof org.algebraicvarietyexplorer.nativeprobe \
        > "$evidence/editor-open-pid.txt" || true
    echo 'native editor opening/geometry log not observed' >&2
    exit 1
fi
if [[ "$layout" =~ width=([0-9]+)[[:space:]]height=([0-9]+)[[:space:]]bottom_inset=([0-9]+)[[:space:]]row_height=([0-9]+) ]]; then
    editor_width="${BASH_REMATCH[1]}"
    editor_height="${BASH_REMATCH[2]}"
    bottom_inset="${BASH_REMATCH[3]}"
    row_height="${BASH_REMATCH[4]}"
else
    echo "invalid editor geometry: $layout" >&2
    exit 1
fi
keypad_bottom=$((editor_height - bottom_inset))
keypad_top=$((keypad_bottom - 4 * row_height))
# Pixel 2 / 360x640 emulator uses a 48-pixel navigation area. Fail closed if
# a future layout change would put the last editor row beneath system buttons.
(( editor_width == 360 && editor_height == 640 &&
   bottom_inset >= 40 && bottom_inset <= 80 &&
   row_height == 48 && keypad_top >= 0 && keypad_bottom <= 592 )) || {
    echo "unsafe native keypad geometry: $layout" >&2
    exit 1
}
printf '%s\n' "$layout" > "$evidence/editor-geometry.txt"

tap_key() {
    local key="$1" row col x y
    case "$key" in
        x) row=0; col=0;; y) row=0; col=1;; z) row=0; col=2;;
        4) row=1; col=4;; 3) row=3; col=4;;
        '+') row=1; col=0;; '-') row=1; col=1;;
        '*') row=1; col=2;; '/') row=1; col=3;;
        '^') row=2; col=2;; '=') row=2; col=3;;
        0) row=3; col=3;; CLR) row=3; col=2;; OK) row=3; col=5;;
        *) echo "key not mapped: $key" >&2; return 1;;
    esac
    x=$(( (2 * col + 1) * editor_width / 12 ))
    y=$(( keypad_top + row * row_height + row_height / 2 ))
    (( y > 40 && y < keypad_bottom && y < 592 )) || {
        echo "key $key would touch Android system navigation at $x,$y" >&2
        return 1
    }
    adb shell input tap "$x" "$y"
}

python3 ci/verify-native-screenshots.py \
    "$evidence/madore-e6.png" "$evidence/editor-open.png" \
    | tee -a "$evidence/image-verdict.txt"
tap_key CLR
for key in x '^' 4 - x '*' y '^' 3 - z '^' 4 + z = 0; do
    tap_key "$key"
done
adb exec-out screencap -p > "$evidence/editor-quartic-typed.png"
# Formula typing does not alter the underlying surface until OK; compare
# the actual formula strip instead of applying the preset geometry oracle.
python3 ci/verify-native-screenshots.py --editor-text \
    "$evidence/editor-open.png" "$evidence/editor-quartic-typed.png" \
    | tee -a "$evidence/image-verdict.txt"
tap_key OK
for attempt in $(seq 1 45); do
    adb logcat -d -s 'SurferNative:I' '*:S' \
        > "$evidence/quartic-logcat.txt"
    if grep -Fq 'formula accepted=x^4-x*y^3-z^4+z=0' "$evidence/quartic-logcat.txt" &&
       grep -Eq 'frame custom size=.* foreground=[1-9][0-9]*' \
            "$evidence/quartic-logcat.txt"; then
        break
    fi
    sleep 2
done
grep -Fq 'formula accepted=x^4-x*y^3-z^4+z=0' "$evidence/quartic-logcat.txt"
grep -Eq 'frame custom size=.* foreground=[1-9][0-9]*' "$evidence/quartic-logcat.txt"
adb exec-out screencap -p > "$evidence/custom-quartic.png"
python3 ci/verify-native-screenshots.py \
    "$evidence/madore-e6.png" "$evidence/custom-quartic.png" \
    | tee -a "$evidence/image-verdict.txt"

# Invalid division must leave the last valid custom surface selected.
adb shell input tap 330 30
tap_key CLR
for key in x / 0; do tap_key "$key"; done
tap_key OK
for attempt in $(seq 1 15); do
    adb logcat -d -s 'SurferNative:I' '*:S' \
        > "$evidence/rejection-logcat.txt"
    if grep -Fq 'formula rejected=x/0 reason=division needs a nonzero constant' \
        "$evidence/rejection-logcat.txt"; then
        break
    fi
    sleep 1
done
grep -Fq 'formula rejected=x/0 reason=division needs a nonzero constant' \
    "$evidence/rejection-logcat.txt"
adb exec-out screencap -p > "$evidence/editor-rejection.png"
adb shell input tap 330 30

adb shell dumpsys package org.algebraicvarietyexplorer.nativeprobe \
    > "$evidence/package.txt"
adb shell am force-stop org.algebraicvarietyexplorer.nativeprobe
echo "NativeActivity executed seven presets, user quartic, and invalid-input rejection: PASS"
