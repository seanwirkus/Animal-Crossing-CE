#!/usr/bin/env python3
"""
Fix items.json file properly by adding missing fields to incomplete items.
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_ITEMS = ROOT / "data" / "items.json"

def fix_json():
    """Fix the items.json file."""
    # Read content
    with open(DATA_ITEMS, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all incomplete items (those with just category and nothing else)
    # Pattern: {"id": "...", "name": "...", "category": "...", followed by empty lines before }
    pattern = r'("category":\s*"[^"]+",)\s*\n\s*\n\s*(},)'
    
    replacement = r'\1\n      "series": null,\n      "set": null,\n      "tag": null,\n      "sell": null,\n      "buy": null,\n      "source": [],\n      "themes": []\n    \2'
    
    fixed_content = re.sub(pattern, replacement, content)
    
    # Write fixed content
    with open(DATA_ITEMS, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print("Applied regex fix. Validating...")
    
    # Try to parse
    try:
        data = json.loads(fixed_content)
        print(f"Successfully fixed! Loaded {len(data.get('items', []))} items")
        
        # Check for incomplete items
        incomplete = []
        for item in data.get('items', []):
            if 'series' not in item or 'set' not in item or 'source' not in item:
                incomplete.append(item.get('id', 'unknown'))
        
        if incomplete:
            print(f"Still {len(incomplete)} incomplete items: {incomplete[:5]}")
        else:
            print("All items have required fields!")
            
    except json.JSONDecodeError as e:
        print(f"Still has errors: {e}")
        print(f"Line {e.lineno}: {e.msg}")

if __name__ == "__main__":
    fix_json()

