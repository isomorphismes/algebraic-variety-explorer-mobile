#!/usr/bin/env python3
"""Fail-closed structural and motion checks for genuine rendered E6 frames.

Checks dimensions, background/foreground, color range, distinct viewpoints,
and encoded movie frame count. Does NOT prove the analytic singularity type:
that is a separate exact polynomial assertion, stated in the notes.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import subprocess
import sys

def fail(s):
    raise SystemExit("E6 render verification: " + s)

def main():
    if len(sys.argv) != 7:
        fail("usage: verify-e6-render.py frames|movie DIR N SIZE FPS ENGINE")
    phase, dirname, count_text, size_text, fps_text, engine = sys.argv[1:]
    if engine not in ("jsurf", "povray"):
        fail("unknown engine")
    root = Path(dirname)
    count = int(count_text)
    size = int(size_text)
    fps = int(fps_text)
    prefix = f"madore-e6-{ 'surfer' if engine == 'jsurf' else 'povray' }"
    manifest = root / (prefix + "-manifest.json")
    if phase == "frames":
        fingerprints = []
        foreground_counts = []
        for i in range(count):
            ext = ".ppm" if engine == "jsurf" else ".png"
            name = root / "frames" / (f"{i:03d}" + ext)
            if not name.is_file():
                fail(f"missing frame: {name}")
            # Use ffmpeg to decode both PPM and PNG with exactly the same test,
            # avoiding reliance on optional Pillow availability.
            frame = subprocess.run([
                "ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(name),
                "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"
            ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout
            if len(frame) != size * size * 3:
                fail(f"wrong decoded frame size: {name} ({len(frame)})")
            pixels = [frame[k:k+3] for k in range(0, len(frame), 3)]
            colors = set(pixels)
            if len(colors) < 32:
                fail(f"too few colors: {name} ({len(colors)})")
            corner = pixels[0]
            different = sum(pixel != corner for pixel in pixels)
            # In POV-Ray the background is black. In jsurf it is a fixed dark
            # color. Both frames must have a bounded nontrivial foreground.
            if not (0.01 * size * size <= different <= 0.95 * size * size):
                fail(f"empty or filled frame: {name}, different={different}")
            foreground_counts.append(different)
            fingerprints.append(hashlib.sha256(frame).hexdigest())
        unique = len(set(fingerprints))
        if unique < max(4, count // 3):
            fail(f"camera failed to move: only {unique}/{count} different frames")
        manifest.write_text(json.dumps({
            "engine": engine,
            "formula": "x^2+x*z^2+y^3",
            "attribution": {
                "polynomial": "David A. Madore, The Cubic Surfaces DVD (2006)",
                "original_source": "http://www.madore.org/cubic-dvd/SOURCE/cubic-dvd.tar.gz",
                "original_file": "cubic-dvd/03s01a.pov",
                "renderer": ("Christian Stussak / IMAGINARY jsurf, Apache-2.0"
                             if engine == "jsurf" else "POV-Ray rendering of Madore's original POV-Ray source"),
            },
            "width": size, "height": size, "frames": count, "fps": fps,
            "frames_unique": unique,
            "first_frame_sha256": fingerprints[0],
            "last_frame_sha256": fingerprints[-1],
            "foreground_counts": foreground_counts,
            "validation": "actual decoded pixels (color diversity, bounded foreground, camera motion)"
        }, indent=2) + "\n", encoding="utf-8")
        print(f"Frames PASS: {count} frames, {unique} unique, {size}x{size}")
    elif phase == "movie":
        path = root / (prefix + ".mp4")
        gif = root / (prefix + ".gif")
        still = root / (prefix + ".png")
        for filename in (path, gif, still):
            if not filename.is_file() or filename.stat().st_size < 500:
                fail(f"missing or empty deliverable: {filename}")
        proc = subprocess.run([
            "ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0",
            "-show_entries", "stream=nb_read_frames,width,height,avg_frame_rate",
            "-of", "json", str(path)
        ], capture_output=True, text=True, check=True)
        info = json.loads(proc.stdout)["streams"][0]
        if int(info["nb_read_frames"]) != count:
            fail(f"encoded movie has {info['nb_read_frames']} frames, expected {count}")
        if int(info["width"]) != size or int(info["height"]) != size:
            fail("movie dimensions mismatch")
        manifest_data = json.loads(manifest.read_text(encoding="utf-8"))
        manifest_data["movie_bytes"] = path.stat().st_size
        manifest_data["gif_bytes"] = gif.stat().st_size
        manifest_data["poster_bytes"] = still.stat().st_size
        manifest_data["movie_framerate"] = info["avg_frame_rate"]
        manifest.write_text(json.dumps(manifest_data, indent=2) + "\n", encoding="utf-8")
        print(f"Movie PASS: {path}, {count} frames, {size}x{size}")
    else:
        fail("unknown phase")

if __name__ == "__main__":
    main()
