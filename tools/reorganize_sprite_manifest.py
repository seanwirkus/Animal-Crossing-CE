#!/usr/bin/env python3
"""
Reorganize SpriteManifest.luau by category, add cherry at index 192, and fill gaps.
Groups items logically for easier mapping while maintaining sensible index ranges.
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

def parse_manifest(content):
    """Parse the manifest file and extract entries."""
    entries = []
    pattern = r'(\s+)(\w+)\s*=\s*\{\s*name\s*=\s*"([^"]+)",\s*spriteIndex\s*=\s*(\d+)\s*\},'
    
    for match in re.finditer(pattern, content):
        indent = match.group(1)
        key = match.group(2)
        name = match.group(3)
        sprite_index = int(match.group(4))
        entries.append({
            'key': key,
            'name': name,
            'spriteIndex': sprite_index,
            'indent': indent
        })
    
    return entries

def categorize_item(key, name):
    """Categorize an item for organization."""
    key_lower = key.lower()
    name_lower = name.lower()
    
    # Basic tools (1-20)
    if any(x in key_lower for x in ['shovel', 'net', 'slingshot', 'fishing_rod', 'watering_can', 'axe', 'pole', 'ladder', 'flute', 'tambourine']):
        if 'golden' in key_lower:
            return ('tools_golden', 1)
        if 'flimsy' in key_lower:
            return ('tools_flimsy', 10)
        return ('tools_basic', 0)
    
    # Currency & special items (20-30)
    if any(x in key_lower for x in ['bell_bag', 'lost_item', 'bottle_message', 'recipe_card', 'paper_gift', 'leaf_fossil']):
        return ('currency_misc', 20)
    
    # Clothing (30-40)
    if any(x in key_lower for x in ['glasses', 'shirt', 'bag', 'socks', 'shoes', 'umbrella']):
        return ('clothing', 30)
    
    # Eggs (40-44)
    if 'egg' in key_lower:
        return ('eggs', 40)
    
    # Flowers - roses (45-48)
    if 'rose' in key_lower:
        return ('flowers_roses', 45)
    
    # Flowers - tulips (49-52)
    if 'tulip' in key_lower:
        return ('flowers_tulips', 49)
    
    # Flowers - lilies (53-56)
    if 'lily' in key_lower:
        return ('flowers_lilies', 53)
    
    # Flowers - mums (57-60)
    if 'mum' in key_lower:
        return ('flowers_mums', 57)
    
    # Flowers - hyacinths (61-64)
    if 'hyacinth' in key_lower:
        return ('flowers_hyacinths', 61)
    
    # Flowers - cosmos (65-68)
    if 'cosmos' in key_lower:
        return ('flowers_cosmos', 65)
    
    # Fish (70-85)
    if key_lower.startswith('fish_'):
        return ('fish', 70)
    
    # Bugs (85-100)
    if key_lower.startswith('bug_'):
        return ('bugs', 85)
    
    # Seasonal items (100-110)
    if any(x in key_lower for x in ['snowflake', 'ornament', 'pumpkin', 'heart']):
        return ('seasonal', 100)
    
    # Fruits - apple (140-165)
    if key_lower == 'apple' or (key_lower.startswith('apple_') and not any(x in key_lower for x in ['chair', 'dress', 'hat', 'rug', 'wall', 'umbrella'])):
        return ('fruits_apple', 140)
    
    # Fruits - cherry (190-210) - around index 192
    if key_lower == 'cherry' or (key_lower.startswith('cherry_') and 'blossom' not in key_lower):
        return ('fruits_cherry', 190)
    
    # Cherry blossom items (260-270)
    if 'cherry_blossom' in key_lower or 'cherry-blossom' in key_lower:
        return ('cherry_blossom', 260)
    
    # Materials & crafting (270-290)
    if any(x in key_lower for x in ['wood', 'stone', 'clay', 'iron', 'gold', 'nugget', 'fragment', 'bamboo', 'sugarcane', 'flour', 'sugar', 'potato', 'maple_leaf', 'wasp_nest', 'weeds', 'flimsy']):
        return ('materials', 270)
    
    # Everything else - keep current order roughly
    return ('other', 999)

def reorganize_manifest(entries):
    """Reorganize entries by category."""
    # Check if cherry exists
    cherry_exists = any(e['key'] == 'cherry' for e in entries)
    if not cherry_exists:
        entries.append({
            'key': 'cherry',
            'name': 'Cherry',
            'spriteIndex': 9999,  # Temporary, will be set to 192
            'indent': '    '
        })
    
    # Group by category
    categorized = defaultdict(list)
    for entry in entries:
        cat, base_index = categorize_item(entry['key'], entry['name'])
        categorized[cat].append((entry, base_index))
    
    # Sort items within each category by name/key
    for cat in categorized:
        categorized[cat].sort(key=lambda x: (x[0]['key'], x[0]['name']))
    
    # Define processing order with target index ranges
    processing_order = [
        ('tools_basic', 1, 19),
        ('tools_golden', 14, 19),  # Overlap with basic tools is fine, will adjust
        ('currency_misc', 20, 32),
        ('clothing', 30, 40),
        ('eggs', 40, 44),
        ('flowers_roses', 44, 48),
        ('flowers_tulips', 48, 52),
        ('flowers_lilies', 52, 56),
        ('flowers_mums', 56, 60),
        ('flowers_hyacinths', 60, 64),
        ('flowers_cosmos', 64, 68),
        ('fish', 70, 85),
        ('bugs', 85, 100),
        ('seasonal', 100, 115),
        ('fruits_apple', 140, 165),
        ('fruits_cherry', 190, 210),  # Cherry at 192
        ('cherry_blossom', 260, 270),
        ('materials', 270, 290),
        ('tools_flimsy', 268, 270),  # Near materials
        ('other', None, None),  # Keep existing indices where possible
    ]
    
    # Track used indices
    used_indices = set()
    reorganized = []
    
    # Process each category
    for cat, start_idx, end_idx in processing_order:
        if cat not in categorized:
            continue
        
        items_with_base = categorized[cat]
        
        # Special handling for cherry - must be at 192
        if cat == 'fruits_cherry':
            cherry_item = next((x for x in items_with_base if x[0]['key'] == 'cherry'), None)
            cherry_others = [x for x in items_with_base if x[0]['key'] != 'cherry']
            
            if cherry_item:
                cherry_item[0]['spriteIndex'] = 192
                used_indices.add(192)
                reorganized.append(cherry_item[0])
            
            # Place other cherry items around 192
            current = 190
            for item_data, _ in cherry_others:
                while current in used_indices or current == 192:
                    current += 1
                item_data['spriteIndex'] = current
                used_indices.add(current)
                reorganized.append(item_data)
                current += 1
        
        # Special handling for other - try to keep existing indices
        elif cat == 'other':
            for item_data, _ in items_with_base:
                original_idx = item_data['spriteIndex']
                if original_idx not in used_indices and original_idx < 500:
                    item_data['spriteIndex'] = original_idx
                    used_indices.add(original_idx)
                else:
                    # Find next available
                    current = start_idx if start_idx else 300
                    while current in used_indices:
                        current += 1
                    item_data['spriteIndex'] = current
                    used_indices.add(current)
                reorganized.append(item_data)
        
        else:
            # Assign sequential indices within range
            current = start_idx
            for item_data, _ in items_with_base:
                # Skip if we'd overwrite cherry's spot
                if current == 192 and cat != 'fruits_cherry':
                    current = 193
                
                while current in used_indices:
                    current += 1
                    if end_idx and current > end_idx:
                        # Go slightly beyond range if needed
                        pass
                
                item_data['spriteIndex'] = current
                used_indices.add(current)
                reorganized.append(item_data)
                current += 1
    
    # Sort by spriteIndex
    reorganized.sort(key=lambda x: x['spriteIndex'])
    
    return reorganized

def write_manifest(entries, output_path):
    """Write the reorganized manifest to file."""
    lines = ['return {']
    
    # Group entries with comments for categories
    current_cat = None
    for entry in entries:
        cat, _ = categorize_item(entry['key'], entry['name'])
        
        # Add category comment when category changes
        if cat != current_cat:
            cat_name = cat.replace('_', ' ').title()
            lines.append(f'    -- {cat_name}')
            current_cat = cat
        
        line = f'{entry["indent"]}{entry["key"]} = {{ name = "{entry["name"]}", spriteIndex = {entry["spriteIndex"]} }},'
        lines.append(line)
    
    lines.append('}')
    
    content = '\n'.join(lines) + '\n'
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    manifest_path = Path('src/shared/SpriteManifest.luau')
    
    if not manifest_path.exists():
        print(f"Error: {manifest_path} not found")
        sys.exit(1)
    
    # Read current manifest
    with open(manifest_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Parse entries
    entries = parse_manifest(content)
    print(f"Parsed {len(entries)} entries")
    
    # Reorganize
    reorganized = reorganize_manifest(entries)
    print(f"Reorganized into {len(reorganized)} entries")
    
    # Create backup
    backup_path = manifest_path.with_suffix('.luau.backup2')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Created backup: {backup_path}")
    
    # Write reorganized manifest
    write_manifest(reorganized, manifest_path)
    print(f"✅ Reorganized manifest written to {manifest_path}")
    
    # Verify cherry is at 192
    cherry_entry = next((e for e in reorganized if e['key'] == 'cherry'), None)
    if cherry_entry:
        print(f"✅ Cherry added at index {cherry_entry['spriteIndex']}")
    else:
        print("⚠️  Warning: Cherry not found in reorganized manifest")
    
    # Print index ranges
    print("\nIndex ranges by category:")
    categories = defaultdict(list)
    for entry in reorganized:
        cat, _ = categorize_item(entry['key'], entry['name'])
        categories[cat].append(entry['spriteIndex'])
    
    for cat in sorted(categories.keys()):
        indices = sorted(categories[cat])
        if indices:
            print(f"  {cat:20s}: {len(indices):3d} items (indices {min(indices)}-{max(indices)})")

if __name__ == '__main__':
    main()
