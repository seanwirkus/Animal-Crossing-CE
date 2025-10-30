#!/usr/bin/env python3
"""Fix all incomplete items in items.json"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_ITEMS = ROOT / "data" / "items.json"

def fix_all_items():
    """Fix all items with missing fields."""
    content = DATA_ITEMS.read_text(encoding='utf-8')
    
    # Pattern: item ending with empty lines before }
    # Matches: "category": "material",\n\n\n  }
    pattern = r'("category":\s*"[^"]+",)\n\s*\n\s*(},\s*\n)'
    replacement = r'\1\n      "series": null,\n      "set": null,\n      "tag": null,\n      "sell": null,\n      "buy": null,\n      "source": [],\n      "themes": []\n    \2'
    
    fixed = re.sub(pattern, replacement, content)
    
    # Handle items that also need to be last in items array (no trailing comma)
    pattern2 = r'("category":\s*"[^"]+",)\n\s*\n\s*(\}\s*\n\s*\]\s*,)'
    replacement2 = r'\1\n      "series": null,\n      "set": null,\n      "tag": null,\n      "sell": null,\n      "buy": null,\n      "source": [],\n      "themes": []\n    \2'
    
    fixed = re.sub(pattern2, replacement2, fixed)
    
    DATA_ITEMS.write_text(fixed, encoding='utf-8')
    
    # Validate
    try:
        data = json.loads(fixed)
        items = data.get('items', [])
        print(f"Successfully fixed! Total items: {len(items)}")
        
        incomplete = [item['id'] for item in items if 'series' not in item]
        if incomplete:
            print(f"Still {len(incomplete)} incomplete: {incomplete}")
        else:
            print("All items complete!")
            
    except json.JSONDecodeError as e:
        print(f"Error: {e} at line {e.lineno}")

if __name__ == "__main__":
    fix_all_items()

