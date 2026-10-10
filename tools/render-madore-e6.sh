#!/usr/bin/env bash
# David A. Madore's E6 cubic, rendered using Christian Stussak's jsurf core.
# Original polynomial and POV-Ray scene: http://www.madore.org/cubic-dvd/
# Source file: 03s01a.pov, preserved in isomorphisms/resolution.
# jsurf core: Christian Stussak / IMAGINARY, Apache License 2.0.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/renders/madore-e6}"
FRAMES="${E6_FRAMES:-32}"
FPS="${E6_FPS:-16}"
SIZE="${E6_SIZE:-320}"
PITCH="${E6_PITCH:--0.35}"
FORMULA="x^2+x*z^2+y^3"
case "$FRAMES" in *[!0-9]*|"") echo 'E6_FRAMES must be an integer' >&2; exit 2;; esac
case "$FPS" in *[!0-9]*|"") echo 'E6_FPS must be an integer' >&2; exit 2;; esac
case "$SIZE" in *[!0-9]*|"") echo 'E6_SIZE must be an integer' >&2; exit 2;; esac
(( FRAMES >= 8 && FRAMES <= 120 && FPS >= 1 && FPS <= 60 && SIZE >= 64 && SIZE <= 1024 )) || {
  echo 'Invalid E6 render dimensions, frame count or fps' >&2
  exit 2
}

command -v ffmpeg >/dev/null || { echo 'ffmpeg required' >&2; exit 2; }
command -v ffprobe >/dev/null || { echo 'ffprobe required' >&2; exit 2; }
mkdir -p "$OUT/frames"
# Uses only the real jsurf CPU renderer; no matplotlib, mesh surrogate,
# pre-rendered imagery or hand-drawn intermediate frame.
(
  cd "$ROOT"
  bash ./build.sh test
)
ANTLR_CLASSPATH="${ANTLR_JAR:-$ROOT/.dependencies/antlr-runtime-3.4.jar}"
VECMATH_CLASSPATH="${VECMATH_JAR:-$ROOT/.dependencies/vecmath-1.5.2.jar}"
CLASSPATH="$ROOT/.build/test/classes:$ANTLR_CLASSPATH:$VECMATH_CLASSPATH"
for (( index=0; index<FRAMES; index++ )); do
  printf -v number '%03d' "$index"
  # Fixed pitch; yaw moves a full turn, with no duplicate final frame.
  yaw="$(awk -v i="$index" -v n="$FRAMES" 'BEGIN{printf "%.12f",0.55+2*atan2(0,-1)*i/n}')"
  java -Xmx512m -classpath "$CLASSPATH" \
    org.algebraicvarietyexplorer.render.JsurfPreview \
    "$OUT/frames/$number.ppm" "$FORMULA" "$yaw" "$PITCH" "$SIZE"
done

python3 "$ROOT/tools/verify-e6-render.py" frames "$OUT" "$FRAMES" "$SIZE" "$FPS" "jsurf"
ffmpeg -hide_banner -loglevel error -y -framerate "$FPS" \
  -start_number 0 -i "$OUT/frames/%03d.ppm" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart \
  "$OUT/madore-e6-surfer.mp4"
ffmpeg -hide_banner -loglevel error -y -i "$OUT/madore-e6-surfer.mp4" \
  -filter_complex "[0:v]fps=$FPS,scale=$SIZE:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" \
  -loop 0 "$OUT/madore-e6-surfer.gif"
ffmpeg -hide_banner -loglevel error -y -i "$OUT/frames/008.ppm" \
  -frames:v 1 "$OUT/madore-e6-surfer.png"
python3 "$ROOT/tools/verify-e6-render.py" movie "$OUT" "$FRAMES" "$SIZE" "$FPS" "jsurf"
printf 'SURFER E6 rendered and verified: %s\n' "$OUT"
