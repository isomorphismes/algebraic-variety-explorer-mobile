#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD_DIR="$PROJECT_DIR/.build"
readonly DEPENDENCY_DIR="$PROJECT_DIR/.dependencies"

readonly APPLICATION_ID="org.algebraicvarietyexplorer"
readonly COMPILE_SDK="35"
readonly BUILD_TOOLS_VERSION="35.0.1"
readonly MIN_SDK="23"
readonly TARGET_SDK="35"
readonly VERSION_CODE="2"
readonly VERSION_NAME="0.1.1"

# ZIP stores local timestamps. Fix the timezone and the timestamps of files we
# add after aapt2 so two clean builds of one source tree produce identical APKs.
export TZ=UTC
readonly ZIP_ENTRY_TIMESTAMP="198001010000.00"

readonly ANTLR_URL="https://repo.maven.apache.org/maven2/org/antlr/antlr-runtime/3.4/antlr-runtime-3.4.jar"
readonly ANTLR_SHA256="5b7cf53b7b30b034023f58030c8147c433f2bee0fe7dec8fae6bebf3708c5a63"
readonly VECMATH_URL="https://repo.maven.apache.org/maven2/javax/vecmath/vecmath/1.5.2/vecmath-1.5.2.jar"
readonly VECMATH_SHA256="3558e81ca74c60dc01baca7ef05f48594bbaed43af45d4f1b9196e479734e675"
readonly JUNIT_URL="https://repo.maven.apache.org/maven2/junit/junit/4.13.2/junit-4.13.2.jar"
readonly JUNIT_SHA256="8e495b634469d64fb8acfa3495a065cbacc8a0fff55ce1e31007be4c16dc57d3"
readonly HAMCREST_URL="https://repo.maven.apache.org/maven2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar"
readonly HAMCREST_SHA256="66fdef91e9739348df7a096aa384a5685f4e875584cce89386a7a47251c4d8e9"

main() {
    case "${1:-debug}" in
        debug)
            build_debug
            ;;
        release)
            build_release
            ;;
        diagnostic)
            build_diagnostic
            ;;
        test)
            run_tests
            ;;
        preview)
            render_preview "${2:-}"
            ;;
        clean)
            clean
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
}

usage() {
    cat <<'EOF'
Usage:
  ./build.sh                 Build a signed development APK
  ./build.sh debug           Build a signed development APK
  ./build.sh release         Build an unsigned APK for F-Droid or external signing
  ./build.sh diagnostic      Build a side-by-side package for install diagnosis
  ./build.sh test            Run the JVM parser and renderer tests
  ./build.sh preview [FILE]  Render a JVM-only PPM smoke-test image
  ./build.sh clean           Remove generated build output

Required for APK builds:
  JDK 17
  Android SDK platform 35
  Android build tools
  ANDROID_SDK_ROOT set to the SDK directory

ANTLR_JAR, VECMATH_JAR, JUNIT_JAR, and HAMCREST_JAR may point to
already-provided dependencies. Otherwise the exact locked versions are
downloaded from Maven Central and verified by SHA-256.
EOF
}

fail() {
    printf 'build: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        fail "sha256sum or shasum is required"
    fi
}

download_dependency() {
    local target="$1"
    local url="$2"
    local expected_sha256="$3"
    local actual_sha256
    local temporary

    if [[ -f "$target" ]]; then
        actual_sha256="$(sha256_of "$target")"
        [[ "$actual_sha256" == "$expected_sha256" ]] ||
            fail "wrong SHA-256 for $target"
        return
    fi

    require_command curl
    mkdir -p "$DEPENDENCY_DIR"
    temporary="$target.partial"
    curl --fail --location --retry 3 --output "$temporary" "$url"
    actual_sha256="$(sha256_of "$temporary")"
    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
        rm -f -- "$temporary"
        fail "downloaded file has the wrong SHA-256: $url"
    fi
    mv "$temporary" "$target"
}

runtime_dependencies() {
    if [[ -n "${ANTLR_JAR:-}" ]]; then
        [[ -f "$ANTLR_JAR" ]] || fail "ANTLR_JAR does not exist: $ANTLR_JAR"
    else
        ANTLR_JAR="$DEPENDENCY_DIR/antlr-runtime-3.4.jar"
        download_dependency "$ANTLR_JAR" "$ANTLR_URL" "$ANTLR_SHA256"
    fi

    if [[ -n "${VECMATH_JAR:-}" ]]; then
        [[ -f "$VECMATH_JAR" ]] || fail "VECMATH_JAR does not exist: $VECMATH_JAR"
    else
        VECMATH_JAR="$DEPENDENCY_DIR/vecmath-1.5.2.jar"
        download_dependency "$VECMATH_JAR" "$VECMATH_URL" "$VECMATH_SHA256"
    fi
}

test_dependencies() {
    runtime_dependencies

    if [[ -n "${JUNIT_JAR:-}" ]]; then
        [[ -f "$JUNIT_JAR" ]] || fail "JUNIT_JAR does not exist: $JUNIT_JAR"
    else
        JUNIT_JAR="$DEPENDENCY_DIR/junit-4.13.2.jar"
        download_dependency "$JUNIT_JAR" "$JUNIT_URL" "$JUNIT_SHA256"
    fi

    if [[ -n "${HAMCREST_JAR:-}" ]]; then
        [[ -f "$HAMCREST_JAR" ]] || fail "HAMCREST_JAR does not exist: $HAMCREST_JAR"
    else
        HAMCREST_JAR="$DEPENDENCY_DIR/hamcrest-core-1.3.jar"
        download_dependency "$HAMCREST_JAR" "$HAMCREST_URL" "$HAMCREST_SHA256"
    fi
}

java_tools() {
    JAVAC="${JAVAC:-$(command -v javac || true)}"
    JAR="${JAR:-$(command -v jar || true)}"
    JAVA="${JAVA:-$(command -v java || true)}"

    [[ -n "$JAVAC" ]] || fail "javac was not found; install JDK 17"
    [[ -n "$JAR" ]] || fail "jar was not found; install JDK 17"
    [[ -n "$JAVA" ]] || fail "java was not found; install JDK 17"
}

android_tools() {
    SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
    [[ -n "$SDK_ROOT" ]] ||
        fail "set ANDROID_SDK_ROOT to an Android SDK containing platform 35"

    ANDROID_JAR="$SDK_ROOT/platforms/android-$COMPILE_SDK/android.jar"
    [[ -f "$ANDROID_JAR" ]] ||
        fail "Android platform $COMPILE_SDK is missing: $ANDROID_JAR"

    if [[ -n "${ANDROID_BUILD_TOOLS:-}" ]]; then
        BUILD_TOOLS="$ANDROID_BUILD_TOOLS"
    else
        BUILD_TOOLS="$SDK_ROOT/build-tools/$BUILD_TOOLS_VERSION"
    fi

    AAPT2="$BUILD_TOOLS/aapt2"
    R8_JAR="$BUILD_TOOLS/lib/d8.jar"
    ZIPALIGN="$BUILD_TOOLS/zipalign"
    APKSIGNER="$BUILD_TOOLS/apksigner"

    [[ -x "$AAPT2" ]] ||
        fail "Android build tools $BUILD_TOOLS_VERSION were not found in $BUILD_TOOLS"
    [[ -f "$R8_JAR" ]] || fail "R8 was not found in $BUILD_TOOLS"
    [[ -x "$ZIPALIGN" ]] || fail "zipalign was not found in $BUILD_TOOLS"
    [[ -x "$APKSIGNER" ]] || fail "apksigner was not found in $BUILD_TOOLS"
}

stage_android_resources() {
    local staged="$BUILD_DIR/work/res"

    mkdir -p "$staged/drawable" "$staged/layout" "$staged/values"
    cp "$PROJECT_DIR/drawable.formula_field.xml" "$staged/drawable/formula_field.xml"
    cp "$PROJECT_DIR/drawable.ic_launcher.xml" "$staged/drawable/ic_launcher.xml"
    cp "$PROJECT_DIR/drawable.surface_frame.xml" "$staged/drawable/surface_frame.xml"
    cp "$PROJECT_DIR/layout.activity_main.xml" "$staged/layout/activity_main.xml"
    cp "$PROJECT_DIR/values.colors.xml" "$staged/values/colors.xml"
    cp "$PROJECT_DIR/values.strings.xml" "$staged/values/strings.xml"
    cp "$PROJECT_DIR/values.styles.xml" "$staged/values/styles.xml"
}

list_application_sources() {
    find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -type f \
        -name '*.java' ! -name '*.test.java' -print |
        sort
}

compile_apk() {
    local manifest="${1:-$PROJECT_DIR/AndroidManifest.xml}"
    local output_name="${2:-Algebraic-Variety-Explorer-$VERSION_NAME-unsigned.apk}"
    local generated_r_package="${3:-}"
    local work="$BUILD_DIR/work"
    local resources="$work/resources.zip"
    local generated="$work/generated"
    local classes="$work/classes"
    local dex="$work/dex"
    local java_resources="$work/java-resources"
    local source_list="$work/application-sources.txt"
    local classpath="$ANDROID_JAR:$ANTLR_JAR:$VECMATH_JAR"
    local class_jar="$work/application.jar"
    local resource_apk="$work/resources.apk"
    local unaligned_apk="$work/unaligned.apk"
    local aligned_apk="$BUILD_DIR/$output_name"
    local package_arguments=()

    if [[ -n "$generated_r_package" ]]; then
        package_arguments=(--custom-package "$generated_r_package")
    fi

    rm -rf -- "$work"
    mkdir -p "$work" "$generated" "$classes" "$dex" "$java_resources"
    stage_android_resources

    "$AAPT2" compile --dir "$work/res" -o "$resources"
    "$AAPT2" link \
        -o "$resource_apk" \
        -I "$ANDROID_JAR" \
        --manifest "$manifest" \
        --java "$generated" \
        "${package_arguments[@]}" \
        --min-sdk-version "$MIN_SDK" \
        --target-sdk-version "$TARGET_SDK" \
        --version-code "$VERSION_CODE" \
        --version-name "$VERSION_NAME" \
        "$resources"

    list_application_sources > "$source_list"
    find "$generated" -type f -name '*.java' -print | sort >> "$source_list"
    "$JAVAC" \
        --release 11 \
        -encoding UTF-8 \
        -classpath "$classpath" \
        -d "$classes" \
        @"$source_list"

    "$JAR" --create --file "$class_jar" -C "$classes" .
    "$JAVA" -classpath "$R8_JAR" com.android.tools.r8.R8 \
        --release \
        --min-api "$MIN_SDK" \
        --lib "$ANDROID_JAR" \
        --no-data-resources \
        --pg-conf "$PROJECT_DIR/r8-rules.pro" \
        --output "$dex" \
        "$class_jar" "$ANTLR_JAR" "$VECMATH_JAR"

    find "$dex" -type f -exec touch -t "$ZIP_ENTRY_TIMESTAMP" {} +

    cp "$resource_apk" "$unaligned_apk"
    (
        cd "$dex"
        zip -q -j "$unaligned_apk" classes.dex
    )

    unzip -q "$VECMATH_JAR" \
        javax/vecmath/ExceptionStrings.properties \
        -d "$java_resources"
    # `zip -r` emits directory entries as well as files. Normalize every staged
    # path so those directory headers do not retain the build's wall-clock time.
    find "$java_resources" -exec touch -t "$ZIP_ENTRY_TIMESTAMP" {} +
    (
        cd "$java_resources"
        zip -q -r "$unaligned_apk" .
    )

    "$ZIPALIGN" -p -f 4 "$unaligned_apk" "$aligned_apk"
    printf '%s\n' "$aligned_apk"
}

sign_debug_apk() {
    local unsigned_apk="$1"
    local output_name="${2:-Algebraic-Variety-Explorer-$VERSION_NAME-debug.apk}"
    local keystore="${SIGNING_KEYSTORE:-$PROJECT_DIR/.debug.keystore}"
    local alias="${SIGNING_ALIAS:-androiddebugkey}"
    local store_password="${SIGNING_STORE_PASSWORD:-android}"
    local key_password="${SIGNING_KEY_PASSWORD:-$store_password}"
    local signed_apk="$BUILD_DIR/$output_name"
    local keytool

    if [[ ! -f "$keystore" ]]; then
        [[ -z "${SIGNING_KEYSTORE:-}" ]] ||
            fail "SIGNING_KEYSTORE does not exist: $keystore"
        keytool="${KEYTOOL:-$(command -v keytool || true)}"
        [[ -n "$keytool" ]] || fail "keytool was not found; install JDK 17"
        "$keytool" -genkeypair \
            -keystore "$keystore" \
            -storepass "$store_password" \
            -keypass "$key_password" \
            -alias "$alias" \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -dname "CN=Android Debug,O=Algebraic Variety Explorer,C=US" \
            >/dev/null
    fi

    "$APKSIGNER" sign \
        --ks "$keystore" \
        --ks-key-alias "$alias" \
        --ks-pass "pass:$store_password" \
        --key-pass "pass:$key_password" \
        --v4-signing-enabled false \
        --out "$signed_apk" \
        "$unsigned_apk"
    "$APKSIGNER" verify --verbose --print-certs "$signed_apk"
    "$ZIPALIGN" -c -p 4 "$signed_apk"
    printf '%s\n' "$signed_apk"
}

build_release() {
    runtime_dependencies
    java_tools
    android_tools
    require_command zip
    require_command unzip
    compile_apk \
        "$PROJECT_DIR/AndroidManifest.xml" \
        "Algebraic-Variety-Explorer-$VERSION_NAME-unsigned.apk"
}

build_debug() {
    local unsigned_apk

    runtime_dependencies
    java_tools
    android_tools
    require_command zip
    require_command unzip
    unsigned_apk="$(
        compile_apk \
            "$PROJECT_DIR/AndroidManifest.xml" \
            "Algebraic-Variety-Explorer-$VERSION_NAME-unsigned.apk"
    )"
    sign_debug_apk "$unsigned_apk"
}

build_diagnostic() {
    local unsigned_apk

    runtime_dependencies
    java_tools
    android_tools
    require_command zip
    require_command unzip
    unsigned_apk="$(
        compile_apk \
            "$PROJECT_DIR/AndroidManifest.local.xml" \
            "Algebraic-Variety-Explorer-$VERSION_NAME-diagnostic-unsigned.apk" \
            "$APPLICATION_ID"
    )"
    sign_debug_apk \
        "$unsigned_apk" \
        "Algebraic-Variety-Explorer-$VERSION_NAME-diagnostic.apk"
}

stage_test_sources() {
    local test_source
    local staged_name
    local staged_dir="$BUILD_DIR/test/sources"

    mkdir -p "$staged_dir"
    for test_source in "$PROJECT_DIR"/*.test.java; do
        staged_name="$(basename "$test_source" .test.java).java"
        cp "$test_source" "$staged_dir/$staged_name"
    done
}

list_core_sources() {
    local source

    for source in "$PROJECT_DIR"/*.java; do
        [[ "$source" == *.test.java ]] && continue
        if grep -q '^package de\.mfo\.jsurf' "$source"; then
            printf '%s\n' "$source"
        fi
    done
}

compile_tests() {
    local test_work="$BUILD_DIR/test"
    local test_classes="$test_work/classes"
    local source_list="$test_work/test-sources.txt"
    local classpath="$ANTLR_JAR:$VECMATH_JAR:$JUNIT_JAR:$HAMCREST_JAR"

    rm -rf -- "$test_work"
    mkdir -p "$test_classes"
    stage_test_sources
    list_core_sources | sort > "$source_list"
    printf '%s\n' \
        "$PROJECT_DIR/SurfaceExample.java" \
        "$PROJECT_DIR/SurfaceExamples.java" \
        >> "$source_list"
    find "$test_work/sources" -type f -name '*.java' -print | sort >> "$source_list"
    "$JAVAC" \
        --release 11 \
        -encoding UTF-8 \
        -classpath "$classpath" \
        -d "$test_classes" \
        @"$source_list"
}

run_tests() {
    local classpath

    test_dependencies
    java_tools
    compile_tests
    classpath="$BUILD_DIR/test/classes:$ANTLR_JAR:$VECMATH_JAR:$JUNIT_JAR:$HAMCREST_JAR"
    "$JAVA" -classpath "$classpath" \
        org.junit.runner.JUnitCore \
        org.algebraicvarietyexplorer.render.JsurfCoreTest
}

render_preview() {
    local output="${1:-$BUILD_DIR/jsurf-preview.ppm}"
    local classpath

    test_dependencies
    java_tools
    compile_tests
    classpath="$BUILD_DIR/test/classes:$ANTLR_JAR:$VECMATH_JAR:$JUNIT_JAR:$HAMCREST_JAR"
    "$JAVA" -classpath "$classpath" \
        org.algebraicvarietyexplorer.render.JsurfPreview \
        "$output"
    printf '%s\n' "$output"
}

clean() {
    rm -rf -- "$BUILD_DIR"
}

main "$@"
