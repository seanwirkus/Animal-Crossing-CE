#!/usr/bin/env python3
"""Fix remaining incomplete items that have some fields but are missing series/set/tag"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_ITEMS = ROOT / "data" / "items.json"

def fix_remaining():
    """Fix items missing series/set/tag fields."""
    with open(DATA_ITEMS, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Fix each item
    fixed_count = 0
    for item in data.get('items', []):
        if 'series' not in item:
            item['series'] = None
            fixed_count += 1
        if 'set' not in item:
            item['set'] = None
        if 'tag' not in item:
            item['tag'] = None
        if 'sell' not in item:
            item['sell'] = None
        if 'buy' not in item:
            item['buy'] = None
        if 'source' not in item:
            item['source'] = []
        if 'themes' not in item:
            item['themes'] = []
    
    # Write back
    with open(DATA_ITEMS, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"Fixed {fixed_count} items missing fields")
    print(f"Total items: {len(data.get('items', []))}")
    
    # Validate
    incomplete = [item['id'] for item in data['items'] if 'series' not in item]
    if incomplete:
        print(f"Still incomplete: {incomplete}")
    else:
        print("All items complete!")

if __name__ == "__main__":
    fix_remaining()

