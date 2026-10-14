#!/usr/bin/env python3
"""Fail closed when maintained SURFER C source silently loses ICK division."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCES = (
    "native/surfer_raytracer.c",
    "native/surfer_raytracer_test.c",
    "native/surfer_raytracer.h",
)
EXPECTED_GLYPHS = 14


def executable_text(source: str) -> str:
    """Discard C comments and quoted literals, retaining operators and line order."""
    source = source.replace("\\\n", "")  # C translation phase: line splicing
    result = []
    state = "code"
    index = 0
    while index < len(source):
        char = source[index]
        next_char = source[index + 1] if index + 1 < len(source) else ""
        if state == "code":
            if char == "/" and next_char == "/":
                state = "line-comment"
                index += 2
                continue
            if char == "/" and next_char == "*":
                state = "block-comment"
                index += 2
                continue
            if char in ("'", '"'):
                state = char
                index += 1
                continue
            result.append(char)
        elif state == "line-comment":
            if char == "\n":
                result.append("\n")
                state = "code"
        elif state == "block-comment":
            if char == "*" and next_char == "/":
                state = "code"
                index += 2
                continue
        else:
            if char == "\\":
                index += 2
                continue
            if char == state:
                state = "code"
        index += 1
    if state in ("block-comment", "'", '"'):
        raise ValueError("unterminated C comment or quoted literal")
    return "".join(result)


def verify(sources: dict[str, str]) -> int:
    total = 0
    for path in SOURCES:
        code = executable_text(sources[path])
        if "/" in code:
            raise ValueError(f"{path}: ASCII quotient operator in executable C")
        total += code.count("÷")
    if total != EXPECTED_GLYPHS:
        raise ValueError(
            f"expected {EXPECTED_GLYPHS} executable ÷ tokens; found {total}"
        )
    return total


def self_test(sources: dict[str, str]) -> None:
    example = """const char *quoted = "÷ /"; /* ÷ / */
char slash = '/'; // ÷ /
double quotient = 8 ÷ 2;
"""
    code = executable_text(example)
    if code.count("÷") != 1 or "/" in code:
        raise AssertionError("lexer counted a comment or quoted literal")
    target = "native/surfer_raytracer.c"
    for old, label in (("/", "ASCII slash"), ("/=", "compound slash"), ("*", "lost glyph")):
        changed = dict(sources)
        changed[target] = changed[target].replace("÷", old, 1)
        try:
            verify(changed)
        except ValueError:
            pass
        else:
            raise AssertionError(f"negative control survived: {label}")
    print("native glyph inventory negative controls: PASS")


def main() -> int:
    sources = {path: (ROOT / path).read_text(encoding="utf-8") for path in SOURCES}
    total = verify(sources)
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test(sources)
    elif len(sys.argv) != 1:
        raise ValueError("usage: verify-native-division.py [--self-test]")
    print(f"native glyph inventory: {total} executable ÷ tokens, zero ASCII division")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, AssertionError) as error:
        raise SystemExit(f"FAIL: {error}")
