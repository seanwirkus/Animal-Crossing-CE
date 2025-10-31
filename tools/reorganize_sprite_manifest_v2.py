#!/usr/bin/env python3
"""
Better reorganization: Group items logically, add cherry at 192, fill gaps, and create clean structure.
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

def get_category(entry):
    """Get category and sort order for an entry."""
    key = entry['key'].lower()
    name = entry['name'].lower()
    
    # Tools (1-25)
    if 'golden' in key:
        return (1, 'Golden Tools')
    if any(x in key for x in ['shovel', 'net', 'slingshot', 'fishing_rod', 'watering_can', 'axe', 'pole', 'ladder', 'flute', 'tambourine']):
        if 'flimsy' in key:
            return (2, 'Flimsy Tools')
        return (0, 'Basic Tools')
    
    # Currency & UI (26-35)
    if any(x in key for x in ['bell_bag', 'lost_item', 'bottle_message', 'recipe_card', 'paper_gift', 'leaf_fossil']):
        return (3, 'Currency & UI')
    
    # Clothing (36-45)
    if any(x in key for x in ['glasses', 'shirt', 'bag', 'socks', 'shoes', 'umbrella']) and 'apple' not in key and 'cherry' not in key:
        return (4, 'Clothing')
    
    # Eggs (46-49)
    if 'egg' in key:
        return (5, 'Eggs')
    
    # Flowers grouped by type (50-80)
    if 'rose' in key:
        return (6, 'Roses')
    if 'tulip' in key:
        return (7, 'Tulips')
    if 'lily' in key:
        return (8, 'Lilies')
    if 'mum' in key:
        return (9, 'Mums')
    if 'hyacinth' in key:
        return (10, 'Hyacinths')
    if 'cosmos' in key:
        return (11, 'Cosmos')
    
    # Fish (81-95)
    if key.startswith('fish_'):
        return (12, 'Fish')
    
    # Bugs (96-110)
    if key.startswith('bug_'):
        return (13, 'Bugs')
    
    # Seasonal (111-125)
    if any(x in key for x in ['snowflake', 'ornament', 'pumpkin', 'heart']):
        return (14, 'Seasonal')
    
    # Fruits - Apple (140-165)
    if key == 'apple' or (key.startswith('apple_') and not any(x in key for x in ['chair', 'dress', 'hat', 'rug', 'wall', 'umbrella'])):
        return (15, 'Apple Items')
    
    # Fruits - Cherry (190-210) - SPECIAL: cherry at 192
    if key == 'cherry' or (key.startswith('cherry_') and 'blossom' not in key):
        return (16, 'Cherry Items')
    
    # Cherry Blossom (260-270)
    if 'cherry_blossom' in key or 'cherry-blossom' in key:
        return (17, 'Cherry Blossom')
    
    # Materials & Crafting (270-290)
    if any(x in key for x in ['wood', 'stone', 'clay', 'iron', 'gold', 'nugget', 'fragment', 'bamboo', 'sugarcane', 'flour', 'sugar', 'potato', 'maple_leaf', 'wasp_nest', 'weeds']):
        return (18, 'Materials')
    
    # Everything else
    return (99, 'Other')

def reorganize_manifest(entries):
    """Reorganize entries with cherry at 192."""
    # Ensure cherry exists
    has_cherry = any(e['key'] == 'cherry' for e in entries)
    if not has_cherry:
        entries.append({
            'key': 'cherry',
            'name': 'Cherry',
            'spriteIndex': 9999,
            'indent': '    '
        })
    
    # Group by category
    by_category = defaultdict(list)
    for entry in entries:
        sort_order, category = get_category(entry)
        by_category[(sort_order, category)].append(entry)
    
    # Sort items within each category
    for key in by_category:
        by_category[key].sort(key=lambda x: (x['key'], x['name']))
    
    # Assign indices
    reorganized = []
    used_indices = set()
    
    # Index ranges for each category
    ranges = {
        'Basic Tools': (1, 13),
        'Golden Tools': (14, 19),
        'Flimsy Tools': (268, 269),
        'Currency & UI': (20, 35),
        'Clothing': (36, 45),
        'Eggs': (46, 49),
        'Roses': (50, 56),
        'Tulips': (57, 59),
        'Lilies': (60, 62),
        'Mums': (63, 65),
        'Hyacinths': (66, 69),
        'Cosmos': (70, 72),
        'Fish': (81, 90),
        'Bugs': (91, 100),
        'Seasonal': (111, 125),
        'Apple Items': (140, 165),
        'Cherry Items': (190, 210),  # Cherry at 192
        'Cherry Blossom': (260, 265),
        'Materials': (270, 290),
        'Other': (125, 139),  # Fill gaps
    }
    
    # Process categories in order
    sorted_cats = sorted(by_category.keys(), key=lambda x: x[0])
    
    for sort_order, category in sorted_cats:
        items = by_category[(sort_order, category)]
        
        if category in ranges:
            start, end = ranges[category]
            
            # Special: cherry must be at 192
            if category == 'Cherry Items':
                cherry_item = next((x for x in items if x['key'] == 'cherry'), None)
                cherry_others = [x for x in items if x['key'] != 'cherry']
                
                if cherry_item:
                    cherry_item['spriteIndex'] = 192
                    used_indices.add(192)
                    reorganized.append(cherry_item)
                
                # Place other cherry items around 192
                current = 190
                for item in cherry_others:
                    while current in used_indices or current == 192:
                        current += 1
                    item['spriteIndex'] = current
                    used_indices.add(current)
                    reorganized.append(item)
                    current += 1
            else:
                current = start
                for item in items:
                    # Skip 192 if not cherry category
                    if current == 192:
                        current = 193
                    while current in used_indices:
                        current += 1
                        if end and current > end:
                            break
                    if not end or current <= end:
                        item['spriteIndex'] = current
                        used_indices.add(current)
                        reorganized.append(item)
                        current += 1
        else:
            # Other category - use available slots
            current = 125
            for item in items:
                while current in used_indices or current == 192:
                    current += 1
                item['spriteIndex'] = current
                used_indices.add(current)
                reorganized.append(item)
                current += 1
    
    # Sort by spriteIndex
    reorganized.sort(key=lambda x: x['spriteIndex'])
    
    return reorganized

def write_manifest(entries, output_path):
    """Write manifest with clean formatting."""
    lines = ['return {']
    
    current_category = None
    for entry in entries:
        _, category = get_category(entry)
        
        # Add category comment
        if category != current_category:
            if current_category is not None:
                lines.append('')  # Blank line between categories
            lines.append(f'    -- {category}')
            current_category = category
        
        line = f'    {entry["key"]} = {{ name = "{entry["name"]}", spriteIndex = {entry["spriteIndex"]} }},'
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
    backup_path = manifest_path.with_suffix('.luau.backup3')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Created backup: {backup_path}")
    
    # Write reorganized manifest
    write_manifest(reorganized, manifest_path)
    print(f"✅ Reorganized manifest written to {manifest_path}")
    
    # Verify cherry
    cherry_entry = next((e for e in reorganized if e['key'] == 'cherry'), None)
    if cherry_entry:
        print(f"✅ Cherry at index {cherry_entry['spriteIndex']}")
    
    # Print summary
    print("\nCategory summary:")
    categories = defaultdict(list)
    for entry in reorganized:
        _, cat = get_category(entry)
        categories[cat].append(entry['spriteIndex'])
    
    for cat in sorted(set(get_category(e)[1] for e in reorganized)):
        if cat in categories:
            indices = sorted(categories[cat])
            print(f"  {cat:20s}: {len(indices):3d} items (indices {min(indices)}-{max(indices)})")

if __name__ == '__main__':
    main()

