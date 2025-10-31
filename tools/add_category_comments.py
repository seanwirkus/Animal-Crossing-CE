#!/usr/bin/env python3
"""
Add category comments to SpriteManifest.luau to make it easier to read.
Preserves all existing order and indices.
"""

import re
from pathlib import Path

def get_category(key):
    """Get category for an entry."""
    key_lower = key.lower()
    
    if 'golden' in key_lower:
        return 'Golden Tools'
    if 'flimsy' in key_lower:
        return 'Flimsy Tools'
    if any(x in key_lower for x in ['shovel', 'net', 'slingshot', 'fishing_rod', 'watering_can', 'axe', 'pole', 'ladder', 'flute', 'tambourine']) or key_lower == 'leaf':
        return 'Basic Tools'
    if any(x in key_lower for x in ['bell_bag', 'lost_item', 'bottle_message', 'recipe_card', 'paper_gift', 'leaf_fossil']):
        return 'Currency & UI'
    if any(x in key_lower for x in ['glasses', 'shirt', 'bag', 'socks', 'shoes', 'umbrella']) and 'apple' not in key_lower and 'cherry' not in key_lower:
        return 'Clothing'
    if 'egg' in key_lower:
        return 'Eggs'
    if 'rose' in key_lower:
        return 'Roses'
    if 'tulip' in key_lower:
        return 'Tulips'
    if 'lily' in key_lower:
        return 'Lilies'
    if 'mum' in key_lower:
        return 'Mums'
    if 'hyacinth' in key_lower:
        return 'Hyacinths'
    if 'cosmos' in key_lower:
        return 'Cosmos'
    if key_lower.startswith('fish_'):
        return 'Fish'
    if key_lower.startswith('bug_'):
        return 'Bugs'
    if any(x in key_lower for x in ['snowflake', 'ornament', 'pumpkin', 'heart']):
        return 'Seasonal'
    if key_lower == 'apple' or (key_lower.startswith('apple_') and not any(x in key_lower for x in ['chair', 'dress', 'hat', 'rug', 'wall', 'umbrella'])):
        return 'Apple Items'
    if key_lower == 'cherry' or (key_lower.startswith('cherry_') and 'blossom' not in key_lower):
        return 'Cherry Items'
    if 'cherry_blossom' in key_lower or 'cherry-blossom' in key_lower:
        return 'Cherry Blossom'
    if any(x in key_lower for x in ['wood', 'stone', 'clay', 'iron', 'gold', 'nugget', 'fragment', 'bamboo', 'sugarcane', 'flour', 'sugar', 'potato', 'maple_leaf', 'wasp_nest', 'weeds']):
        return 'Materials'
    return 'Other'

def main():
    manifest_path = Path('src/shared/SpriteManifest.luau')
    
    with open(manifest_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    output_lines = []
    current_category = None
    
    for line in lines:
        # Check if this is an entry line
        pattern = r'^\s+(\w+)\s*=\s*\{'
        match = re.match(pattern, line)
        
        if match:
            key = match.group(1)
            category = get_category(key)
            
            # Add category comment when category changes
            if category != current_category:
                if current_category is not None:
                    output_lines.append('\n')  # Blank line between categories
                output_lines.append(f'    -- {category}\n')
                current_category = category
            
            output_lines.append(line)
        else:
            # Non-entry line (return {, }, etc.)
            output_lines.append(line)
    
    # Write back
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.writelines(output_lines)
    
    print(f"✅ Added category comments to {manifest_path}")

if __name__ == '__main__':
    main()

