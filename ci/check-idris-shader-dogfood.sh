#!/usr/bin/env bash
set -Eeuo pipefail

backend_root="${1:?usage: check-idris-shader-dogfood.sh BACKEND_ROOT OUTPUT_DIR}"
output_dir="${2:?usage: check-idris-shader-dogfood.sh BACKEND_ROOT OUTPUT_DIR}"
backend_root="$(cd "$backend_root" && pwd)"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"

backend="$backend_root/build/exec/idris2-glsles"
source_file="src/Example/SurferRootSearch.idr"
receipt="$output_dir/current-head-receipt.tsv"
log="$output_dir/current-head.log"
current_stage=backend_build
passed=backend_checkout
diagnostic=none
: > "$log"

consumer_root=$(cd "$(dirname -- "$0")/.." && pwd)
consumer_sha=$(git -C "$consumer_root" rev-parse HEAD)
backend_sha=$(git -C "$backend_root" rev-parse HEAD)
consumer_dirty=$(if git -C "$consumer_root" status --porcelain | grep -q .; then printf dirty; else printf clean; fi)
backend_dirty=$(if git -C "$backend_root" status --porcelain | grep -q .; then printf dirty; else printf clean; fi)

write_receipt() {
    local outcome="$1"
    {
        printf 'CURRENT_HEAD_COMPATIBILITY\t1\n'
        printf 'repository\tisomorphismes/algebraic-variety-explorer-mobile\n'
        printf 'requested_ref\t%s\n' "${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-local}}"
        printf 'resolved_sha\t%s\n' "$consumer_sha"
        printf 'dirty_state\t%s\n' "$consumer_dirty"
        printf 'dependent_repository\tisomorphisms/idris-shader-backend\n'
        printf 'dependent_requested_ref\t%s\n' "${SHADER_BACKEND_REF:-soap-f16-mode}"
        printf 'dependent_resolved_sha\t%s\n' "$backend_sha"
        printf 'dependent_dirty_state\t%s\n' "$backend_dirty"
        for stage in backend_checkout backend_build f16_compile f32_compile shader_validation invalid_width_rejection; do
            if [[ " $passed " == *" $stage "* ]]; then
                printf 'stage\t%s\tPASS\n' "$stage"
            elif [[ "$stage" == "$current_stage" ]]; then
                printf 'stage\t%s\t%s\n' "$stage" "$outcome"
            else
                printf 'stage\t%s\tSKIP\tprerequisite_not_met\n' "$stage"
            fi
        done
        if [[ "$outcome" == FAIL ]]; then
            printf 'first_failure\t%s\t%s\n' "$current_stage" "$diagnostic"
        else
            printf 'first_failure\tnone\n'
        fi
    } > "$receipt"
}

fail_receipt() {
    local status=$?
    trap - ERR
    if [[ "$diagnostic" == none ]]; then
        diagnostic=$(grep -E '(^FAIL|^Error:|^usage:|unsupported|rejected|not found|No such file)' "$log" | tail -n 1 || true)
        [[ -n "$diagnostic" ]] || diagnostic=$(tail -n 1 "$log" | tr '\t\r\n' '   ')
        [[ -n "$diagnostic" ]] || diagnostic="exit_$status"
    fi
    write_receipt FAIL
    cat "$receipt" >&2
    exit "$status"
}
trap fail_receipt ERR

fail() {
    diagnostic="$*"
    printf 'idris-shader-dogfood: %s\n' "$*" >&2
    false
}

current_stage=backend_build
make -C "$backend_root" backend 2>&1 | tee -a "$log"
[[ -x "$backend" ]] || fail "backend executable was not built: $backend"
command -v glslangValidator >/dev/null || fail "glslangValidator is required"
passed="$passed backend_build"

compile_width() {
    local width="$1"
    local name="$2"
    local ir="$output_dir/$name.ir"
    if ! (
        cd "$backend_root"
        "$backend" \
            --cg glsles \
            --source-dir src \
            --output-dir "$output_dir" \
            --directive "float-width=$width" \
            --directive "dump-ir=$ir" \
            "$source_file" \
            -o "$name"
    ) 2> >(tee -a "$log" >&2); then
        fail "$width backend compilation failed: $(tail -n 1 "$log")"
    fi
}

check_width() {
    local width="$1"
    local semantic="$2"
    local precision="$3"
    local forbidden_semantic="$4"
    local forbidden_precision="$5"
    local name="surfer-$width"
    local ir="$output_dir/$name.ir"
    local shader="$output_dir/$name.frag"

    [[ -s "$ir" ]] || fail "$width compilation did not write checked IR"
    [[ -s "$shader" ]] || fail "$width compilation did not write GLSL"

    grep -Fq "v_uv : in ${semantic}x2" "$ir" || fail "$width IR lost the input vector width"
    grep -Fq "u_coefficients : uniform ${semantic}[8]" "$ir" || fail "$width IR lost the coefficient-array width"
    grep -Fq "u_near : uniform ${semantic}" "$ir" || fail "$width IR lost u_near width"
    grep -Fq "u_far : uniform ${semantic}" "$ir" || fail "$width IR lost u_far width"
    grep -Fq -- "-> ${semantic}x4" "$ir" || fail "$width IR lost the fragment-result width"
    if grep -Fq "$forbidden_semantic" "$ir"; then
        fail "$width checked IR leaked $forbidden_semantic semantic types"
    fi

    grep -Fxq "precision $precision float;" "$shader" || fail "$width GLSL has the wrong float precision class"
    if grep -Fxq "precision $forbidden_precision float;" "$shader"; then
        fail "$width GLSL retained the opposite float precision class"
    fi
    grep -Fq 'uniform float u_coefficients[8];' "$shader" || fail "$width GLSL lost the eight polynomial coefficients"
    grep -Fq 'uniform float u_near;' "$shader" || fail "$width GLSL lost u_near"
    grep -Fq 'uniform float u_far;' "$shader" || fail "$width GLSL lost u_far"
    grep -Fq '16.0' "$shader" || fail "$width GLSL lost the sixteen-interval search bound"
    grep -Fq '0.5' "$shader" || fail "$width GLSL lost bisection arithmetic"

    if ! glslangValidator -S frag "$shader" > "$output_dir/$name.glslang.txt" 2>> "$log"; then
        fail "$width GLSL validation failed: $(tail -n 1 "$log")"
    fi
}

current_stage=f16_compile
compile_width f16 surfer-f16
passed="$passed f16_compile"
current_stage=f32_compile
compile_width f32 surfer-f32
passed="$passed f32_compile"
current_stage=shader_validation
check_width f16 F16 mediump F32 highp
check_width f32 F32 highp F16 mediump

if cmp -s "$output_dir/surfer-f16.frag" "$output_dir/surfer-f32.frag"; then
    fail "F16 and F32 generated identical shader bytes"
fi
passed="$passed shader_validation"

current_stage=invalid_width_rejection
if (
    cd "$backend_root"
    "$backend" \
        --cg glsles \
        --source-dir src \
        --output-dir "$output_dir" \
        --directive float-width=f64 \
        "$source_file" \
        -o surfer-f64
) > "$output_dir/surfer-f64.log" 2>&1; then
    fail "unsupported f64 width unexpectedly compiled"
fi
grep -Fq 'float-width must be f16 or f32' "$output_dir/surfer-f64.log" ||
    fail "f64 was rejected for the wrong reason"
[[ ! -e "$output_dir/surfer-f64.frag" ]] || fail "rejected f64 compilation wrote a shader"
passed="$passed invalid_width_rejection"

{
    printf 'backend_requested_ref\t%s\n' "${SHADER_BACKEND_REF:-soap-f16-mode}"
    printf 'backend_revision\t%s\n' "$(git -C "$backend_root" rev-parse HEAD)"
    printf 'source\t%s\n' "$source_file"
    printf 'f16_ir\t%s\n' "$(sha256sum "$output_dir/surfer-f16.ir" | awk '{print $1}')"
    printf 'f16_glsl\t%s\n' "$(sha256sum "$output_dir/surfer-f16.frag" | awk '{print $1}')"
    printf 'f32_ir\t%s\n' "$(sha256sum "$output_dir/surfer-f32.ir" | awk '{print $1}')"
    printf 'f32_glsl\t%s\n' "$(sha256sum "$output_dir/surfer-f32.frag" | awk '{print $1}')"
} > "$output_dir/evidence.tsv"

current_stage=complete
write_receipt PASS
trap - ERR

printf 'idris-shader-dogfood: algebraic-surface F16/F32 compile, IR, GLSL, validation, and f64 rejection passed\n'
