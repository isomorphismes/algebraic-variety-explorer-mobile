#!/usr/bin/env bash
# Separate Java-free Android APK. ICK compiles every .c; pinned NDK only links.
set -euo pipefail

fail() { printf 'SURFER native: %s\n' "$*" >&2; exit 1; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
abi="${1:-arm64-v8a}"
pin=c61e448251744a2f40ad743ebef1a027bdcd2f9d

ndk_pin=29.0.14206865
api=26
sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
case "$abi" in
  arm64-v8a)
    gnu=aarch64-linux-gnu
    target_include=aarch64-linux-android
    ndk_driver=aarch64-linux-android26-clang
    flags=(-ffixed-x18)
    machine=AArch64
    alignment=16384 ;;
  x86_64)
    gnu=x86_64-linux-gnu
    target_include=x86_64-linux-android
    ndk_driver=x86_64-linux-android26-clang
    flags=(-march=x86-64-v2 -mno-avx -mno-movbe)
    machine="Advanced Micro Devices X86-64"
    alignment=16384 ;;
  armeabi-v7a)
    gnu=arm-linux-gnueabi
    target_include=arm-linux-androideabi
    ndk_driver=armv7a-linux-androideabi26-clang
    flags=(-march=armv7-a -marm -mfpu=vfpv3-d16 -mfloat-abi=softfp)
    machine=ARM
    alignment=4096 ;;
  *) fail "unsupported Android ABI $abi" ;;
esac

[[ -n "$sdk" ]] || fail "ANDROID_SDK_ROOT not set"
[[ -n "${ICK_SOURCE_DIR:-}" ]] || fail "ICK_SOURCE_DIR not set"
[[ -n "${ICK:-}" ]] || fail "ICK compiler not set: no compiler fallback"
[[ -x "$ICK" ]] || fail "ICK executable missing: $ICK"
actual_pin="$(git -C "$ICK_SOURCE_DIR" rev-parse HEAD)"
[[ "$actual_pin" == "$pin" ]] || fail "wrong ICK source revision: $actual_pin"
expected="$ICK_SOURCE_DIR/stage/bin/$gnu-gcc"
[[ "$(readlink -f "$ICK")" == "$(readlink -f "$expected")" ]] ||
  fail "ICK compiler is not the pinned checkout's installed compiler"
[[ "$("$ICK" -dumpmachine)" == "$gnu" ]] || fail "wrong ICK target"
cc1="$("$ICK" -print-prog-name=cc1)"
[[ -x "$cc1" ]] || fail "source-built ICK cc1 absent"
case "$(readlink -f "$cc1")" in
  "$(readlink -f "$ICK_SOURCE_DIR/stage")"/*) ;;
  *) fail "ICK cc1 escaped its own installation" ;;
esac

ndk="$sdk/ndk/$ndk_pin"
sysroot="$ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
bin="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
linker="$bin/$ndk_driver"
[[ -x "$linker" ]] || fail "pinned NDK platform linker missing"
grep -Eq '^Pkg.Revision[[:space:]]*=[[:space:]]*29\.0\.14206865$' \
  "$ndk/source.properties" || fail "wrong NDK version"
for tool in aapt2 zipalign apksigner; do
  [[ -x "$sdk/build-tools/35.0.1/$tool" ]] ||
    fail "Android 35.0.1 build tool $tool missing"
done
[[ -s "$sdk/platforms/android-35/android.jar" ]] || fail "Android platform 35 missing"
for tool in zip unzip keytool sha256sum; do
  command -v "$tool" >/dev/null || fail "missing $tool"
done

out="$root/.build/native/$abi"
mkdir -p "$out"
work="$(mktemp -d "$out/build.XXXXXXXX")"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/obj" "$work/res/values" "$work/lib/$abi"
cp "$root/native/android/values.strings.xml" "$work/res/values/strings.xml"
cflags=(--sysroot="$sysroot"
  -isystem "$sysroot/usr/include"
  -isystem "$sysroot/usr/include/$target_include"
  -I "$root/native" -I "$root/native/android"
  -I "$ndk/sources/android/native_app_glue"
  -D__ANDROID__ -D__ANDROID_API__="$api"
  -DBIONIC_IOCTL_NO_SIGNEDNESS_OVERLOAD
  -O2 -fPIC -fno-fast-math -ffp-contract=off)
for src in native/surfer_raytracer.c native/android/presets.c native/android/activity.c; do
  "$ICK" "${flags[@]}" "${cflags[@]}" -std=c17 \
    -Wall -Wextra -Werror -c "$root/$src" \
    -o "$work/obj/$(basename "$src" .c).o"
done
# The NDK glue is C source, not a binary substitute or a Java shim.
"$ICK" "${flags[@]}" "${cflags[@]}" -std=gnu11 \
  -c "$ndk/sources/android/native_app_glue/android_native_app_glue.c" \
  -o "$work/obj/android_native_app_glue.o"

lib="$work/lib/$abi/libave_nativeprobe.so"
# Linker driver sees .o only. It never receives any C source file.
"$linker" -shared -Wl,-z,defs -Wl,-z,relro -Wl,-z,now \
  -Wl,-z,max-page-size="$alignment" \
  -Wl,-soname,libave_nativeprobe.so \
  "$work"/obj/*.o -landroid -llog -lm -o "$lib"

"$bin/llvm-readelf" -h "$lib" > "$out/elf-header.txt"
grep -Eq "Machine:[[:space:]]*$machine" "$out/elf-header.txt" ||
  fail "wrong ELF architecture"
"$bin/llvm-nm" -D --defined-only "$lib" > "$out/exports.txt"
grep -Eq '[[:space:]]ANativeActivity_onCreate$' "$out/exports.txt" ||
  fail "NativeActivity entrypoint missing"
"$bin/llvm-readelf" -lW "$lib" > "$out/elf-segments.txt"
aligns="$(awk '$1 == "LOAD" {print $NF}' "$out/elf-segments.txt")"
[[ -n "$aligns" ]] || fail "no ELF LOAD segments"
while read -r value; do
  ((value >= alignment)) || fail "ELF load alignment too small: $value"
done <<< "$aligns"

aapt="$sdk/build-tools/35.0.1/aapt2"
"$aapt" compile --dir "$work/res" -o "$work/resources.zip"
"$aapt" link -o "$work/resources.apk" \
  -I "$sdk/platforms/android-35/android.jar" \
  --manifest "$root/native/android/AndroidManifest.xml" \
  --min-sdk-version 26 --target-sdk-version 35 \
  --version-code 1 --version-name 0.0.1 "$work/resources.zip"

cp "$work/resources.apk" "$work/unaligned.apk"
(
  cd "$work"
  TZ=UTC touch -t 198001010000.00 "lib/$abi/libave_nativeprobe.so"
  zip -q -X "$work/unaligned.apk" "lib/$abi/libave_nativeprobe.so"
)
unsigned="$out/SURFER-native-probe-$abi-unsigned.apk"
"$sdk/build-tools/35.0.1/zipalign" -p -f 4 "$work/unaligned.apk" "$unsigned"
unzip -Z1 "$unsigned" > "$out/entries.txt"
grep -Fxq "lib/$abi/libave_nativeprobe.so" "$out/entries.txt" ||
  fail "required native library missing from APK"
if grep -Eq '^classes[0-9]*\.dex$' "$out/entries.txt"; then
  fail "DEX unexpectedly present in Java-free APK"
fi
libraries="$(grep -Ec '^lib/[^/]+/[^/]+\.so$' "$out/entries.txt" || true)"
[[ "$libraries" == 1 ]] || fail "expected exactly one native library"

keystore="$root/.build/native/nativeprobe-debug.keystore"
if [[ ! -f "$keystore" ]]; then
  keytool -genkeypair -noprompt -keystore "$keystore" \
    -storepass android -keypass android -alias androiddebugkey \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=SURFER Native Probe,O=Development,C=US" >/dev/null
fi
signed="$out/SURFER-native-probe-$abi-debug.apk"
"$sdk/build-tools/35.0.1/apksigner" sign \
  --ks "$keystore" --ks-key-alias androiddebugkey \
  --ks-pass pass:android --key-pass pass:android \
  --out "$signed" "$unsigned"
"$sdk/build-tools/35.0.1/apksigner" verify --verbose "$signed"
"$sdk/build-tools/35.0.1/zipalign" -c -p 4 "$signed"
{
  printf 'source=%s\nick_revision=%s\nndk_revision=%s\nabi=%s\n' \
    "$(git -C "$root" rev-parse HEAD)" "$actual_pin" "$ndk_pin" "$abi"
  printf 'compiler=%s\n' "$(readlink -f "$ICK")"
  "$ICK" --version | head -1
  sha256sum "$work"/obj/*.o "$lib" "$unsigned" "$signed"
} > "$out/provenance.txt"
printf '%s\n' "$signed"
