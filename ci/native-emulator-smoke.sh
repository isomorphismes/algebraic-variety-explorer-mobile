#!/usr/bin/env bash
# Install the exact ICK-created APK, exercise actual NativeActivity and pixels.
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

observe() {
    local index="$1" attempt
    for attempt in $(seq 1 90); do
        adb logcat -d -s 'SurferNative:I' '*:S' > "$evidence/logcat.txt"
        if grep -Eq "frame preset=$index size=.* foreground=[1-9][0-9]*" \
                "$evidence/logcat.txt"; then
            return 0
        fi
        sleep 2
    done
    echo "no positive native SURFER foreground for preset $index" >&2
    cat "$evidence/logcat.txt" >&2
    return 1
}

observe 0
sleep 1
adb exec-out screencap -p > "$evidence/sphere.png"
test -s "$evidence/sphere.png"
adb shell input tap 180 320
observe 1
grep -q 'preset=1 name=Torus' "$evidence/logcat.txt"
sleep 1
adb exec-out screencap -p > "$evidence/torus.png"
test -s "$evidence/torus.png"
python3 ci/verify-native-screenshots.py \
    "$evidence/sphere.png" "$evidence/torus.png" \
    | tee "$evidence/image-verdict.txt"
adb shell dumpsys package org.algebraicvarietyexplorer.nativeprobe \
    > "$evidence/package.txt"
adb shell am force-stop org.algebraicvarietyexplorer.nativeprobe
echo "NativeActivity launched, rendered, accepted input, and visibly changed: PASS"
