#!/usr/bin/env python3
"""Fetch asset metadata from the Nookipedia API and export a CSV manifest.

The script is intentionally lightweight so it can run outside of Roblox Studio.
It mirrors the in-game resource categories (fish, bugs, sea creatures, fossils)
and captures image URLs that can later be uploaded to Roblox as image or mesh
assets.

Example usage:
    NOOKIPEDIA_API_KEY=your_key \
        python scripts/fetch_nookipedia_assets.py --category fish bugs --output data/nookipedia_assets.csv
"""

from __future__ import annotations

import argparse
import csv
import os
import sys
import time
from typing import Iterable, List, Mapping, MutableMapping

try:
    import requests
except ImportError as exc:  # pragma: no cover - handled at runtime
    raise SystemExit(
        "The 'requests' package is required. Install it with 'pip install requests'."
    ) from exc

BASE_URL = "https://api.nookipedia.com"
API_VERSION = "2.0.0"
DEFAULT_CATEGORIES = ["fish", "bugs", "sea"]
CATEGORY_ENDPOINTS: Mapping[str, str] = {
    "fish": "/nh/fish",
    "bugs": "/nh/bugs",
    "sea": "/nh/sea",
    "fossils": "/nh/fossils",
}

OUTPUT_FIELDS = [
    "category",
    "name",
    "image_url",
    "render_url",
    "icon_asset_id",
    "model_asset_id",
    "notes",
]


def get_api_key() -> str:
    key = os.getenv("NOOKIPEDIA_API_KEY")
    if not key:
        raise SystemExit(
            "Missing NOOKIPEDIA_API_KEY environment variable. "
            "Visit https://nookipedia.com/api to request an API key."
        )
    return key


def fetch_category(category: str, session: requests.Session) -> List[MutableMapping[str, str]]:
    endpoint = CATEGORY_ENDPOINTS.get(category)
    if not endpoint:
        raise ValueError(f"Unsupported category: {category}")

    url = f"{BASE_URL}{endpoint}"
    params = {"game": "nh"}
    headers = {
        "X-API-KEY": get_api_key(),
        "Accept-Version": API_VERSION,
    }

    response = session.get(url, params=params, headers=headers, timeout=30)
    response.raise_for_status()
    payload = response.json()

    rows: List[MutableMapping[str, str]] = []
    for entry in payload:
        name = entry.get("name") or entry.get("title") or "Unnamed"
        rows.append(
            {
                "category": category,
                "name": name,
                "image_url": entry.get("image_url") or entry.get("image"),
                "render_url": entry.get("render_url") or entry.get("render") or "",
                "icon_asset_id": "",
                "model_asset_id": "",
                "notes": entry.get("catchphrase") or entry.get("museum") or "",
            }
        )
    return rows


def build_manifest(categories: Iterable[str]) -> List[MutableMapping[str, str]]:
    session = requests.Session()
    manifest: List[MutableMapping[str, str]] = []

    for category in categories:
        print(f"[fetch] Requesting {category} from Nookipedia…", file=sys.stderr)
        try:
            manifest.extend(fetch_category(category, session))
        except requests.HTTPError as exc:
            print(f"[warn] Failed to fetch {category}: {exc}", file=sys.stderr)
        time.sleep(0.25)

    session.close()
    return manifest


def write_manifest(rows: Iterable[Mapping[str, str]], output_path: str) -> None:
    directory = os.path.dirname(output_path)
    if directory:
        os.makedirs(directory, exist_ok=True)
    with open(output_path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=OUTPUT_FIELDS)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def parse_args(argv: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Download Nookipedia asset metadata into a CSV manifest.")
    parser.add_argument(
        "--category",
        nargs="*",
        default=None,
        choices=sorted(CATEGORY_ENDPOINTS.keys()),
        help="Categories to fetch (default: fish, bugs, sea).",
    )
    parser.add_argument(
        "--output",
        default="data/nookipedia_assets.csv",
        help="Where to write the resulting CSV manifest.",
    )
    return parser.parse_args(argv)


def main(argv: List[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    categories = args.category or DEFAULT_CATEGORIES
    rows = build_manifest(categories)
    if not rows:
        print("[error] No rows generated. Check API key and category selection.", file=sys.stderr)
        return 1

    write_manifest(rows, args.output)
    print(f"[done] Wrote {len(rows)} rows to {args.output}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
