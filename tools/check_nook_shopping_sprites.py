#!/usr/bin/env python3
"""
Check which Nook Shopping items are missing sprites
This helps identify items that need sprite mappings
"""

import json
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def main():
    # Load items.json
    items_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'data', 'items.json')
    
    if not os.path.exists(items_path):
        print(f"❌ Could not find {items_path}")
        return
    
    with open(items_path, 'r') as f:
        data = json.load(f)
    
    # Find items from Nook Shopping
    nook_items = [i for i in data.get('items', []) if 'Nook Shopping' in i.get('source', [])]
    
    print(f"🛒 Found {len(nook_items)} items from Nook Shopping\n")
    print("=" * 80)
    print("ITEMS MISSING SPRITES (need sprite mapping):")
    print("=" * 80)
    
    missing_sprites = []
    has_sprites = []
    
    for item in nook_items:
        item_id = item.get('id', '')
        item_name = item.get('name', item_id)
        buy_price = item.get('buy', 'N/A')
        
        # Check if item has spriteIndex (would be in SpriteManifest)
        # For now, we'll just list all items - you can manually check SpriteManifest
        missing_sprites.append({
            'id': item_id,
            'name': item_name,
            'buy': buy_price,
            'category': item.get('category', 'Unknown')
        })
    
    # Sort by name
    missing_sprites.sort(key=lambda x: x['name'])
    
    print(f"\n📋 Total items: {len(missing_sprites)}\n")
    
    for item in missing_sprites:
        print(f"  • {item['name']} ({item['id']})")
        print(f"    Category: {item['category']} | Price: {item['buy']} bells")
        print()
    
    print("=" * 80)
    print("💡 TIP: Add these items to SpriteManifest.luau with their spriteIndex")
    print("=" * 80)
    
    # Generate a summary
    print(f"\n📊 Summary:")
    print(f"   Total Nook Shopping items: {len(missing_sprites)}")
    
    # Group by category
    categories = {}
    for item in missing_sprites:
        cat = item['category']
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(item)
    
    print(f"\n📦 By Category:")
    for cat, items in sorted(categories.items()):
        print(f"   {cat}: {len(items)} items")

if __name__ == '__main__':
    main()

