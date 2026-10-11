#!/usr/bin/env bash
# Diagnostic expansion: execute all seven real SURFER presets on Android.
# The native executable is the earlier exact source-built ICK APK, not a mock.
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

adb shell dumpsys package org.algebraicvarietyexplorer.nativeprobe \
    > "$evidence/package.txt"
adb shell am force-stop org.algebraicvarietyexplorer.nativeprobe
echo "NativeActivity executed all seven real SURFER presets with distinct renders: PASS"
