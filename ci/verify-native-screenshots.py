#!/usr/bin/env python3
"""Verify actual Android PNG pixels change beyond the preset-index strip."""
import argparse
import pathlib
import struct
import sys
import zlib

SIGNATURE = b"\x89PNG\r\n\x1a\n"


def decode(raw):
    if not raw.startswith(SIGNATURE):
        raise ValueError("missing PNG signature")
    pos, width, height, channels = 8, None, None, None
    idat, ended = bytearray(), False
    while pos + 12 <= len(raw):
        length = int.from_bytes(raw[pos:pos + 4], "big")
        tag = raw[pos + 4:pos + 8]
        end = pos + 12 + length
        if end > len(raw):
            raise ValueError("truncated PNG chunk")
        chunk = raw[pos + 8:end - 4]
        if zlib.crc32(tag + chunk) != int.from_bytes(raw[end - 4:end], "big"):
            raise ValueError("PNG CRC mismatch")
        pos = end
        if tag == b"IHDR":
            if width is not None or len(chunk) != 13:
                raise ValueError("invalid IHDR")
            width, height, depth, color, comp, filt, interlace = struct.unpack(">IIBBBBB", chunk)
            channels = {2: 3, 6: 4}.get(color)
            if (width < 16 or height < 16 or width > 4096 or height > 4096 or
                    depth != 8 or channels is None or (comp, filt, interlace) != (0, 0, 0)):
                raise ValueError("unsupported PNG encoding")
        elif tag == b"IDAT":
            if width is None:
                raise ValueError("IDAT before IHDR")
            idat.extend(chunk)
        elif tag == b"IEND":
            ended = True
            break
    if not ended or width is None:
        raise ValueError("incomplete PNG")
    stride = width * channels
    uncompressed = zlib.decompress(bytes(idat))
    if len(uncompressed) != height * (stride + 1):
        raise ValueError("wrong decoded length")
    previous, output = bytearray(stride), bytearray(width * height * 3)
    pos = 0
    for y in range(height):
        kind = uncompressed[pos]
        pos += 1
        current = bytearray(uncompressed[pos:pos + stride])
        pos += stride
        if kind > 4:
            raise ValueError("invalid PNG filter")
        for i in range(stride):
            left = current[i - channels] if i >= channels else 0
            above = previous[i]
            corner = previous[i - channels] if i >= channels else 0
            if kind == 1:
                predictor = left
            elif kind == 2:
                predictor = above
            elif kind == 3:
                predictor = (left + above) // 2
            elif kind == 4:
                p = left + above - corner
                a, b, c = abs(p - left), abs(p - above), abs(p - corner)
                predictor = left if a <= b and a <= c else (above if b <= c else corner)
            else:
                predictor = 0
            current[i] = (current[i] + predictor) & 255
        rgb = current if channels == 3 else bytearray(current[i] for i in range(stride) if i % 4 != 3)
        output[y * width * 3:(y + 1) * width * 3] = rgb
        previous = current
    return width, height, output


def check(before_png, after_png):
    width, height, before = decode(before_png)
    width2, height2, after = decode(after_png)
    if (width, height) != (width2, height2):
        raise ValueError("screenshot dimensions differ")
    colors_a, colors_b, changed = set(), set(), 0
    # Cropped interior excludes status bars and the preset index strip.
    x0, x1 = width // 10, width * 9 // 10
    y0, y1 = height * 3 // 10, height * 7 // 10
    pixels = (x1 - x0) * (y1 - y0)
    for y in range(y0, y1):
        for x in range(x0, x1):
            offset = (y * width + x) * 3
            a, b = bytes(before[offset:offset + 3]), bytes(after[offset:offset + 3])
            colors_a.add(a)
            colors_b.add(b)
            changed += a != b
    if min(len(colors_a), len(colors_b)) < 32:
        raise ValueError("flat or blank interior screenshot")
    if changed < max(500, pixels // 40):
        raise ValueError(f"unchanged geometry: {changed}/{pixels} interior pixels")
    print(f"native screenshot PASS {width}x{height}, colors={len(colors_a)}/{len(colors_b)}, changed={changed}/{pixels}")


def synthetic(width, height, pixel):
    def chunk(tag, data):
        return len(data).to_bytes(4, "big") + tag + data + zlib.crc32(tag + data).to_bytes(4, "big")
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            raw.extend(pixel(x, y))
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return SIGNATURE + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")


def self_test():
    gradient = synthetic(360, 640, lambda x, y: bytes(((x+y) % 256, x % 256, y % 256)))
    altered = synthetic(360, 640, lambda x, y: bytes(((x*3+y) % 256, x % 256, y % 256)))
    strip = synthetic(360, 640, lambda x, y: bytes(((x+y+(20 if y<16 else 0)) % 256, x % 256, y % 256)))
    flat = synthetic(360, 640, lambda x, y: b"\x20\x20\x20")
    check(gradient, altered)
    for a, b, name in ((gradient, gradient, "identical"), (gradient, strip, "indicator-only"), (flat, altered, "blank")):
        try:
            check(a, b)
        except ValueError:
            print("rejected mutant:", name)
        else:
            raise AssertionError("false pass: " + name)
    print("native screenshot control suite PASS")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("before", nargs="?")
    parser.add_argument("after", nargs="?")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    elif args.before and args.after:
        check(pathlib.Path(args.before).read_bytes(), pathlib.Path(args.after).read_bytes())
    else:
        parser.error("two screenshots are required")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, zlib.error, AssertionError) as exc:
        sys.exit(f"native screenshot FAIL: {exc}")
