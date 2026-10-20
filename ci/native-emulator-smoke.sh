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

# Exercise the actual editable NativeActivity UI on the same APK and emulator.
# Touch the EDIT control, clear, type the user's quartic, and submit.
adb shell input tap 330 30
adb shell input tap 150 616
for xy in \
  '30 472' '150 568' '270 520' \
  '90 520' '30 472' '150 520' '90 472' '150 568' '270 616' \
  '90 520' '150 472' '150 568' '270 520' \
  '30 520' '150 472' '210 568' '210 616'; do
    adb shell input tap $xy
done
adb shell input tap 330 616
for attempt in $(seq 1 45); do
    adb logcat -d -s 'SurferNative:I' 'SurferNative:E' '*:S' \
        > "$evidence/logcat.txt"
    if grep -Fq 'formula accepted=x^4-x*y^3-z^4+z=0' "$evidence/logcat.txt" &&
       grep -Eq 'frame custom size=.* foreground=[1-9][0-9]*' \
            "$evidence/logcat.txt"; then
        break
    fi
    sleep 2
done
grep -Fq 'formula accepted=x^4-x*y^3-z^4+z=0' "$evidence/logcat.txt"
grep -Eq 'frame custom size=.* foreground=[1-9][0-9]*' "$evidence/logcat.txt"
adb exec-out screencap -p > "$evidence/custom-quartic.png"
python3 ci/verify-native-screenshots.py \
    "$evidence/madore-e6.png" "$evidence/custom-quartic.png" \
    | tee -a "$evidence/image-verdict.txt"

# Invalid division must not evict the last valid surface.
adb shell input tap 330 30
adb shell input tap 150 616
for xy in '30 472' '210 520' '210 616'; do
    adb shell input tap $xy
done
adb shell input tap 330 616
adb logcat -d -s 'SurferNative:I' 'SurferNative:E' '*:S' \
    > "$evidence/logcat.txt"
grep -Fq 'formula rejected=x/0 reason=division needs a nonzero constant' \
    "$evidence/logcat.txt"
adb shell input tap 330 30

adb shell dumpsys package org.algebraicvarietyexplorer.nativeprobe \
    > "$evidence/package.txt"
adb shell am force-stop org.algebraicvarietyexplorer.nativeprobe
echo "NativeActivity executed seven presets, user quartic, and invalid-input rejection: PASS"
