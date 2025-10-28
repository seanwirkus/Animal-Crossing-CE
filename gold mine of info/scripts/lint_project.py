#!/usr/bin/env python3
"""Simple linter utilities for Luau sources.

The script performs a light-weight normalization pass over all tracked Luau
files so Studio can load the project without issues caused by mixed line
endings or stray trailing whitespace.
"""

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

LUAU_EXTENSIONS = {".luau", ".lua"}


def iter_source_files(root: Path):
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() in LUAU_EXTENSIONS:
            yield path


def lint_file(path: Path) -> bool:
    original = path.read_text(encoding="utf-8")
    # Normalize line endings and strip trailing whitespace on each line.
    normalized_lines = [line.rstrip() for line in original.replace("\r\n", "\n").replace("\r", "\n").split("\n")]

    # Ensure the file ends with a single newline.
    new_content = "\n".join(normalized_lines)
    if not new_content.endswith("\n"):
        new_content += "\n"

    if new_content == original:
        return False

    path.write_text(new_content, encoding="utf-8")
    return True


def main() -> None:
    changed_files = []
    for source in iter_source_files(REPO_ROOT / "src"):
        if lint_file(source):
            changed_files.append(source.relative_to(REPO_ROOT))

    if not changed_files:
        print("No files required lint fixes.")
    else:
        print("Linted files:")
        for path in changed_files:
            print(f" - {path}")


if __name__ == "__main__":
    main()
