#!/usr/bin/env bash
set -euo pipefail

backend_root="${1:?usage: check-idris-shader-dogfood.sh BACKEND_ROOT OUTPUT_DIR}"
output_dir="${2:?usage: check-idris-shader-dogfood.sh BACKEND_ROOT OUTPUT_DIR}"
backend_root="$(cd "$backend_root" && pwd)"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"

backend="$backend_root/build/exec/idris2-glsles"
source_file="src/Example/SurferRootSearch.idr"

fail() {
    printf 'idris-shader-dogfood: %s\n' "$*" >&2
    exit 1
}

make -C "$backend_root" backend
[[ -x "$backend" ]] || fail "backend executable was not built: $backend"
command -v glslangValidator >/dev/null || fail "glslangValidator is required"

compile_width() {
    local width="$1"
    local name="$2"
    local ir="$output_dir/$name.ir"
    (
        cd "$backend_root"
        "$backend" \
            --cg glsles \
            --source-dir src \
            --output-dir "$output_dir" \
            --directive "float-width=$width" \
            --directive "dump-ir=$ir" \
            "$source_file" \
            -o "$name"
    )
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

    glslangValidator -S frag "$shader" > "$output_dir/$name.glslang.txt"
}

compile_width f16 surfer-f16
compile_width f32 surfer-f32
check_width f16 F16 mediump F32 highp
check_width f32 F32 highp F16 mediump

if cmp -s "$output_dir/surfer-f16.frag" "$output_dir/surfer-f32.frag"; then
    fail "F16 and F32 generated identical shader bytes"
fi

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

{
    printf 'backend_revision\t%s\n' "$(git -C "$backend_root" rev-parse HEAD)"
    printf 'source\t%s\n' "$source_file"
    printf 'f16_ir\t%s\n' "$(sha256sum "$output_dir/surfer-f16.ir" | awk '{print $1}')"
    printf 'f16_glsl\t%s\n' "$(sha256sum "$output_dir/surfer-f16.frag" | awk '{print $1}')"
    printf 'f32_ir\t%s\n' "$(sha256sum "$output_dir/surfer-f32.ir" | awk '{print $1}')"
    printf 'f32_glsl\t%s\n' "$(sha256sum "$output_dir/surfer-f32.frag" | awk '{print $1}')"
} > "$output_dir/evidence.tsv"

printf 'idris-shader-dogfood: algebraic-surface F16/F32 compile, IR, GLSL, validation, and f64 rejection passed\n'
