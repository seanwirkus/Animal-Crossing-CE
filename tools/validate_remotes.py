#!/usr/bin/env python3
"""Static validation that critical RemoteEvents are referenced on both server and client."""

from __future__ import annotations

import json
import os
import sys
from typing import List, Dict

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
MANIFEST_PATH = os.path.join(SCRIPT_DIR, "remote_manifest.json")


def load_manifest() -> List[Dict[str, object]]:
    if not os.path.exists(MANIFEST_PATH):
        raise FileNotFoundError(f"Remote manifest missing at {MANIFEST_PATH}")

    with open(MANIFEST_PATH, "r", encoding="utf-8") as handle:
        return json.load(handle)


def read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as handle:
        return handle.read()


def validate_side(remote: Dict[str, object], side: str, files: List[str], failures: List[str]) -> None:
    if not files:
        failures.append(
            f"[{remote['name']}] No files listed for {side}. Update tools/remote_manifest.json."
        )
        return

    for rel_path in files:
        abs_path = os.path.join(PROJECT_ROOT, rel_path)
        if not os.path.exists(abs_path):
            failures.append(f"[{remote['name']}] {side} file missing: {rel_path}")
            continue

        try:
            contents = read_file(abs_path)
        except OSError as exc:
            failures.append(f"[{remote['name']}] Failed to read {rel_path}: {exc}")
            continue

        if remote["name"] not in contents:
            failures.append(
                f"[{remote['name']}] {side} file does not reference remote name: {rel_path}"
            )


def main() -> int:
    manifest = load_manifest()
    failures: List[str] = []

    for remote in manifest:
        server_files = remote.get("serverFiles", []) or []
        client_files = remote.get("clientFiles", []) or []

        validate_side(remote, "server", server_files, failures)
        validate_side(remote, "client", client_files, failures)

    if failures:
        print("[RemoteValidator] ❌ Issues detected:")
        for issue in failures:
            print(f" - {issue}")
        return 1

    print("[RemoteValidator] ✅ All listed remotes reference both server and client files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
