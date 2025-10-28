#!/usr/bin/env python3
"""
Fetch villager data from Nookipedia API and cache it locally.
This prevents the game from needing to make API calls at runtime.

Usage:
    python scripts/cache_nookipedia.py
"""

import json
import requests
from pathlib import Path

API_BASE_URL = "https://api.nookipedia.com"
API_KEY = "153cf201-7ca1-44d7-9f17-efd59e6c45e0"
OUTPUT_DIR = Path("src/shared/Data/CachedNookipedia")
OUTPUT_FILE = OUTPUT_DIR / "villagers.json"

def fetch_villagers():
    """Fetch all villagers from Nookipedia."""
    print("[*] Fetching villagers from Nookipedia...")
    headers = {"x-api-key": API_KEY}
    
    try:
        response = requests.get(
            f"{API_BASE_URL}/villagers",
            headers=headers,
            timeout=30
        )
        response.raise_for_status()
        data = response.json()
        print(f"[✓] Fetched {len(data) if isinstance(data, list) else 1} villagers")
        return data
    except Exception as e:
        print(f"[✗] Failed to fetch villagers: {e}")
        return None

def cache_villagers(villagers):
    """Cache villager data locally."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(json.dumps(villagers, indent=2, ensure_ascii=False))
    print(f"[✓] Cached villagers to {OUTPUT_FILE}")
    print(f"    Total entries: {len(villagers) if isinstance(villagers, list) else 1}")

def main():
    villagers = fetch_villagers()
    if villagers:
        cache_villagers(villagers)
        print("[✓] Nookipedia cache updated!")
    else:
        print("[✗] Failed to cache Nookipedia data")

if __name__ == "__main__":
    main()
