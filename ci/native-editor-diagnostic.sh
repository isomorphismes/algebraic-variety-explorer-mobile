#!/usr/bin/env bash
# Diagnostic only. Runs previously compiled ICK APK; this is not acceptance of
# a new head. Capture system state before and after the first top-right EDIT.
set -euo pipefail
apk="${1:?APK required}"
evidence="${2:?evidence directory required}"
mkdir -p "$evidence"
sha256sum "$apk" > "$evidence/diagnostic-apk.sha256"

adb shell wm size 360x640
adb shell wm density 160
adb logcat -G 16M || true
adb install -r "$apk" > "$evidence/install.txt"
adb shell am start -W -n \
    org.algebraicvarietyexplorer.nativeprobe/android.app.NativeActivity \
    > "$evidence/launch.txt"
sleep 3
for index in 1 2 3 4 5 6; do
    adb shell input tap 180 320
    sleep 2
done
adb exec-out screencap -p > "$evidence/before-edit.png"
adb shell dumpsys window > "$evidence/window-before.txt" || true
adb shell dumpsys activity activities > "$evidence/activity-before.txt" || true
adb shell pidof org.algebraicvarietyexplorer.nativeprobe \
    > "$evidence/pid-before.txt" || true

# Retain all tags, buffers, and crash metadata, not only SurferNative.
adb logcat -c
adb shell input tap 330 30
sleep 2
adb exec-out screencap -p > "$evidence/after-edit.png"
adb shell pidof org.algebraicvarietyexplorer.nativeprobe \
    > "$evidence/pid-after.txt" || true
adb shell dumpsys window > "$evidence/window-after.txt" || true
adb shell dumpsys activity activities > "$evidence/activity-after.txt" || true
adb logcat -d -v time > "$evidence/logcat-full.txt" || true
adb logcat -d -b crash -v time > "$evidence/logcat-crash.txt" || true
grep -E '(SurferNative|FATAL EXCEPTION|Fatal signal|Fatal JNI|native editor|am_crash)' \
    "$evidence/logcat-full.txt" > "$evidence/relevant-logcat.txt" || true

# Probe one user-facing keypad cell, even if EDIT did not actually open.
adb shell input tap 150 568
sleep 1
adb exec-out screencap -p > "$evidence/after-key.png"
adb logcat -d -v time > "$evidence/logcat-after-key.txt" || true
printf 'diagnostic APK: %s\n' "$(cat "$evidence/diagnostic-apk.sha256")"
printf 'process before=%s after=%s\n' \
    "$(cat "$evidence/pid-before.txt")" "$(cat "$evidence/pid-after.txt")"
cat "$evidence/relevant-logcat.txt"
printf '%s\n' 'Diagnostic capture complete (not emulator acceptance).'
