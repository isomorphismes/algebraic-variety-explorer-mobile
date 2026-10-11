#!/usr/bin/env python3
"""Compare executed native Android SURFER screenshots with original Java/jsurf.

This is a bounded *diagnostic*, not a parity acceptance test. It invokes the
actual JsurfPreview class compiled from the maintained Java oracle sources with
the same polynomial, image dimensions, and zero yaw/pitch as NativeActivity.
The Java renderer uses adaptive QUINCUNX; native C currently uses one sample.
"""
import json
import os
import pathlib
import re
import runpy
import subprocess
import sys

SOURCE = pathlib.Path("SurfaceExamples.java")
EVIDENCE = pathlib.Path(sys.argv[1]) if len(sys.argv) == 2 else pathlib.Path("native-evidence")
EXPECTED = [
    ("Sphere", "sphere.png"),
    ("Torus", "torus.png"),
    ("Cayley cubic", "cayley.png"),
    ("Whitney umbrella", "whitney.png"),
    ("Roman surface", "roman.png"),
    ("Heart", "heart.png"),
    ("Madore E6 cubic", "madore-e6.png"),
]
JAVA_CLASS = "org.algebraicvarietyexplorer.render.JsurfPreview"
CLASS_PATH = os.pathsep.join([
    ".build/test/classes",
    ".dependencies/antlr-runtime-3.4.jar",
    ".dependencies/vecmath-1.5.2.jar",
    ".dependencies/junit-4.13.2.jar",
    ".dependencies/hamcrest-core-1.3.jar",
])
PNG_DECODER = runpy.run_path("ci/verify-native-screenshots.py")["decode"]


def load_java_256(path):
    raw = path.read_bytes()
    magic = b"P6\n256 256\n255\n"
    if not raw.startswith(magic) or len(raw) != len(magic) + 256 * 256 * 3:
        raise ValueError(f"malformed 256x256 Java PPM: {path}")
    return raw[len(magic):]


def load_native_256(path):
    width, height, pixels = PNG_DECODER(path.read_bytes())
    if (width, height) != (360, 640):
        raise ValueError(f"unexpected real emulator screenshot geometry: {width}x{height}")
    # NativeActivity renders its 256x256 square, scaled to the central 360x360
    # window. Sample within each nearest-neighbor block. Exclude system bars,
    # letterboxing and top preset indicator.
    top = (height - width) // 2
    output = bytearray(256 * 256 * 3)
    for v in range(256):
        src_y = top + min(width - 1, ((2*v + 1) * width) // 512)
        for u in range(256):
            src_x = min(width - 1, ((2*u + 1) * width) // 512)
            src = (src_y * width + src_x) * 3
            dst = (v * 256 + u) * 3
            output[dst:dst+3] = pixels[src:src+3]
    return output


def compare(java, native):
    total = 256 * 256
    if len(java) != len(native) or len(java) != total * 3:
        raise ValueError("wrong rendered pixel count")

    jbg, nbg = java[:3], native[:3]
    channel_error = 0
    pixels_within_four = 0
    pixel_equal = 0
    jmask_count = nmask_count = intersection = union = 0
    for index in range(total):
        start = index * 3
        jpixel, npixel = java[start:start+3], native[start:start+3]
        differences = [abs(int(a) - int(b)) for a, b in zip(jpixel, npixel)]
        channel_error += sum(differences)
        pixels_within_four += max(differences) <= 4
        pixel_equal += max(differences) == 0
        is_java = max(abs(int(jpixel[k])-int(jbg[k])) for k in range(3)) > 20
        is_native = max(abs(int(npixel[k])-int(nbg[k])) for k in range(3)) > 20
        jmask_count += is_java
        nmask_count += is_native
        intersection += is_java and is_native
        union += is_java or is_native

    if union == 0:
        raise ValueError("both surfaces are blank")
    return {
        "mean_absolute_rgb_channel_error": round(channel_error / (total * 3), 6),
        "fraction_pixels_all_channels_within_four": round(pixels_within_four / total, 6),
        "fraction_exact_rgb_pixels": round(pixel_equal / total, 6),
        "silhouette_intersection_over_union": round(intersection / union, 6),
        "java_foreground_pixels": jmask_count,
        "native_foreground_pixels": nmask_count,
    }


def main():
    text = SOURCE.read_text(encoding="utf-8")
    formulas = re.findall(
        r'new\s+SurfaceExample\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)',
        text, flags=re.S)
    if len(formulas) != len(EXPECTED):
        raise ValueError(f"expected seven Java formulas, got {len(formulas)}")
    if [name for name, formula in formulas] != [name for name, file in EXPECTED]:
        raise ValueError("Java example identities/order changed")

    if not pathlib.Path(".build/test/classes").is_dir():
        raise ValueError("run bash build.sh test before Java/jsurf parity diagnostic")
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    results = []
    for index, ((name, filename), (_, formula)) in enumerate(zip(EXPECTED, formulas)):
        out = EVIDENCE / f"java-reference-{index}.ppm"
        subprocess.run([
            "java", "-classpath", CLASS_PATH, JAVA_CLASS,
            str(out), formula, "0", "0", "256",
        ], check=True, timeout=150)
        row = {
            "index": index, "name": name, "formula": formula,
            "java_preview": out.name, "native_screenshot": filename,
            **compare(load_java_256(out), load_native_256(EVIDENCE / filename)),
        }
        print(json.dumps(row, sort_keys=True), flush=True)
        results.append(row)

    record = {
        "diagnostic_only": True,
        "java_source": str(SOURCE),
        "native_artifact_source_commit": "67c3911448f04e770dc6de9878ada4bdf3413ba7",
        "native_apk_run": 38137728366,
        "native_screenshot_emulator": "Android API 35 x86_64 360x640",
        "comparison": "Java yaw=pitch=0, 256x256 adaptive QUINCUNX vs native yaw=pitch=0 nearest-scaled single-sample 256x256; no full parity claim",
        "measurements": results,
    }
    (EVIDENCE / "java-native-diagnostic.json").write_text(
        json.dumps(record, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
        sys.exit(f"Java/native image diagnostic FAILED: {exc}")
