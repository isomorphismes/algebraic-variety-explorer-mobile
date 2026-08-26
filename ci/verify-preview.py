#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path

EXPECTED_SHA256 = "35fe31809bf931cbdedf5cd8af130c54849707de90df4392cb8097a0f7352db5"


def fail(message: str) -> None:
    raise SystemExit(f"preview: {message}")


if len(sys.argv) != 2:
    fail("usage: verify-preview.py FILE.ppm")

path = Path(sys.argv[1])
data = path.read_bytes()
try:
    magic, dimensions, maximum, pixels = data.split(b"\n", 3)
except ValueError:
    fail("truncated PPM header")

if magic != b"P6":
    fail("expected binary P6 PPM")
if dimensions != b"256 256":
    fail(f"unexpected dimensions: {dimensions!r}")
if maximum != b"255":
    fail(f"unexpected channel maximum: {maximum!r}")
if len(pixels) != 256 * 256 * 3:
    fail(f"unexpected pixel payload size: {len(pixels)}")

colors = {pixels[index:index + 3] for index in range(0, len(pixels), 3)}
if len(colors) < 64:
    fail(f"renderer produced only {len(colors)} distinct colors")

digest = hashlib.sha256(data).hexdigest()
if digest != EXPECTED_SHA256:
    fail(f"pixel regression: expected {EXPECTED_SHA256}, got {digest}")
print(f"preview: 256x256, {len(colors)} colors, sha256 {digest}")
