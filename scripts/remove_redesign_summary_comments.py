#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path

PATTERN = re.compile(r"/\*\s*REDESIGN SUMMARY:[\s\S]*?\*/", re.MULTILINE)
SKIP_DIRS = {".git", ".build", "build", "DerivedData", ".swiftpm", ".idea", ".vscode"}


def should_skip(path: Path) -> bool:
    return any(part in SKIP_DIRS for part in path.parts)


def process_file(path: Path) -> bool:
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return False

    updated = PATTERN.sub("", text)
    if updated == text:
        return False

    path.write_text(updated, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Remove block comments containing REDESIGN SUMMARY.")
    parser.add_argument("root", nargs="?", default=".", help="Repository root to scan recursively")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    modified: list[str] = []

    for path in root.rglob("*"):
        if not path.is_file() or should_skip(path):
            continue
        if process_file(path):
            modified.append(str(path))

    for file in modified:
        print(file)

    print(f"Modified files: {len(modified)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
