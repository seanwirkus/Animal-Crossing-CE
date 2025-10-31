#!/usr/bin/env python3
"""
Generate DIY Icon Mapping Reference
Shows which recipe ID maps to which DIY icon index (1-80)
"""

import json
import sys
from pathlib import Path

def generate_diy_mapping():
    # Load items.json
    data_path = Path(__file__).parent.parent / "data" / "items.json"
    
    if not data_path.exists():
        print(f"❌ Error: {data_path} not found")
        return
    
    with open(data_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    recipes = data.get('recipes', [])
    
    print(f"📋 DIY Icon Mapping for {len(recipes)} Recipes")
    print("=" * 80)
    print(f"{'Index':<8} {'Recipe ID':<30} {'Recipe Name':<40}")
    print("-" * 80)
    
    # Generate mapping (1-indexed to match Lua)
    mapping = {}
    for idx, recipe in enumerate(recipes, start=1):
        recipe_id = recipe.get('id') or recipe.get('itemId', 'unknown')
        recipe_name = recipe.get('name', 'Unknown Recipe')
        mapping[recipe_id] = idx
        
        print(f"{idx:<8} {recipe_id:<30} {recipe_name:<40}")
    
    print("=" * 80)
    print(f"\n✅ Total: {len(recipes)} recipes mapped to DIY icon indices 1-{len(recipes)}")
    print(f"\nDIY Spritesheet Info:")
    print(f"  - Asset ID: rbxassetid://97942095241212")
    print(f"  - Grid: 26 columns × 23 rows = 598 total slots")
    print(f"  - Sprite size: 300px × 300px")
    print(f"  - Padding: 10px between sprites")
    print(f"\n📝 Note: Recipe indices are assigned sequentially based on their order")
    print(f"         in the data/items.json recipes array.")
    
    # Save mapping to JSON for reference
    output_path = Path(__file__).parent / "diy_icon_mapping.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(mapping, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Mapping saved to: {output_path}")

if __name__ == "__main__":
    generate_diy_mapping()
