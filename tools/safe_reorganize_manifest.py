#!/usr/bin/env python3
"""
Safe reorganization: Preserve ALL items from backup2, add cherry at 192, group logically.
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

def get_category_group(entry):
    """Get category group for organization."""
    key = entry['key'].lower()
    
    # Tools
    if 'golden' in key:
        return (1, 'Golden Tools')
    if 'flimsy' in key:
        return (3, 'Flimsy Tools')
    if any(x in key for x in ['shovel', 'net', 'slingshot', 'fishing_rod', 'watering_can', 'axe', 'pole', 'ladder', 'flute', 'tambourine']) or key == 'leaf':
        return (0, 'Basic Tools')
    
    # Currency & UI
    if any(x in key for x in ['bell_bag', 'lost_item', 'bottle_message', 'recipe_card', 'paper_gift', 'leaf_fossil']):
        return (4, 'Currency & UI')
    
    # Clothing
    if any(x in key for x in ['glasses', 'shirt', 'bag', 'socks', 'shoes', 'umbrella']) and 'apple' not in key and 'cherry' not in key:
        return (5, 'Clothing')
    
    # Eggs
    if 'egg' in key:
        return (6, 'Eggs')
    
    # Flowers - grouped
    if 'rose' in key:
        return (7, 'Roses')
    if 'tulip' in key:
        return (8, 'Tulips')
    if 'lily' in key:
        return (9, 'Lilies')
    if 'mum' in key:
        return (10, 'Mums')
    if 'hyacinth' in key:
        return (11, 'Hyacinths')
    if 'cosmos' in key:
        return (12, 'Cosmos')
    
    # Fish
    if key.startswith('fish_'):
        return (13, 'Fish')
    
    # Bugs
    if key.startswith('bug_'):
        return (14, 'Bugs')
    
    # Seasonal
    if any(x in key for x in ['snowflake', 'ornament', 'pumpkin', 'heart']):
        return (15, 'Seasonal')
    
    # Fruits - Apple
    if key == 'apple' or (key.startswith('apple_') and not any(x in key for x in ['chair', 'dress', 'hat', 'rug', 'wall', 'umbrella'])):
        return (16, 'Apple Items')
    
    # Fruits - Cherry (special: must be at 192)
    if key == 'cherry' or (key.startswith('cherry_') and 'blossom' not in key):
        return (17, 'Cherry Items')
    
    # Cherry Blossom
    if 'cherry_blossom' in key or 'cherry-blossom' in key:
        return (18, 'Cherry Blossom')
    
    # Materials
    if any(x in key for x in ['wood', 'stone', 'clay', 'iron', 'gold', 'nugget', 'fragment', 'bamboo', 'sugarcane', 'flour', 'sugar', 'potato', 'maple_leaf', 'wasp_nest', 'weeds']):
        return (19, 'Materials')
    
    # Everything else
    return (99, 'Other')

def reorganize_manifest(entries):
    """Reorganize entries, adding cherry at 192."""
    # Check if cherry exists
    has_cherry = any(e['key'] == 'cherry' for e in entries)
    if not has_cherry:
        entries.append({
            'key': 'cherry',
            'name': 'Cherry',
            'spriteIndex': 9999,  # Temporary
            'indent': '    '
        })
    
    # Group by category
    by_category = defaultdict(list)
    for entry in entries:
        priority, category = get_category_group(entry)
        by_category[(priority, category)].append(entry)
    
    # Sort items within each category alphabetically
    for key in by_category:
        by_category[key].sort(key=lambda x: (x['key'], x['name']))
    
    # Define index ranges for each category
    index_ranges = {
        'Basic Tools': (1, 13),
        'Golden Tools': (14, 19),
        'Flimsy Tools': (268, 269),
        'Currency & UI': (20, 35),
        'Clothing': (30, 45),
        'Eggs': (40, 43),
        'Roses': (44, 50),
        'Tulips': (52, 54),
        'Lilies': (55, 57),
        'Mums': (58, 60),
        'Hyacinths': (61, 64),
        'Cosmos': (65, 67),
        'Fish': (70, 79),
        'Bugs': (80, 89),
        'Seasonal': (90, 110),
        'Apple Items': (140, 165),
        'Cherry Items': (190, 210),  # Cherry at 192
        'Cherry Blossom': (260, 265),
        'Materials': (270, 290),
        'Other': (110, 139),  # Fill gaps
    }
    
    # Assign indices
    reorganized = []
    used_indices = set()
    
    # Process categories in order
    sorted_cats = sorted(by_category.keys(), key=lambda x: x[0])
    
    for priority, category in sorted_cats:
        items = by_category[(priority, category)]
        
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
        
        # Categories with defined ranges
        elif category in index_ranges:
            start, end = index_ranges[category]
            current = start
            
            for item in items:
                # Skip 192 if not cherry category
                if current == 192:
                    current = 193
                
                # Find next available slot
                while current in used_indices:
                    current += 1
                    if end and current > end:
                        # Extend range slightly if needed
                        end = current + 5
                
                item['spriteIndex'] = current
                used_indices.add(current)
                reorganized.append(item)
                current += 1
        
        # Other category - fill gaps
        else:
            # Fill gaps: 110-140, 165-190, 210-260, 290+
            gap_ranges = [(110, 140), (165, 190), (210, 260), (290, 500)]
            gap_idx = 0
            current_range_start, current_range_end = gap_ranges[gap_idx]
            current = current_range_start
            
            for item in items:
                # Skip 192
                if current == 192:
                    current = 193
                
                # Find next available slot
                while current in used_indices:
                    current += 1
                    # Move to next gap range if needed
                    if current > current_range_end and gap_idx < len(gap_ranges) - 1:
                        gap_idx += 1
                        current_range_start, current_range_end = gap_ranges[gap_idx]
                        current = current_range_start
                
                item['spriteIndex'] = current
                used_indices.add(current)
                reorganized.append(item)
                current += 1
    
    # Sort by spriteIndex
    reorganized.sort(key=lambda x: x['spriteIndex'])
    
    return reorganized

def write_manifest(entries, output_path):
    """Write manifest with category comments."""
    lines = ['return {']
    
    current_category = None
    for entry in entries:
        _, category = get_category_group(entry)
        
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
    original_count = len(entries)
    print(f"✅ Parsed {original_count} entries from backup2")
    
    # Reorganize
    reorganized = reorganize_manifest(entries)
    new_count = len(reorganized)
    print(f"✅ Reorganized into {new_count} entries")
    
    # Verify all items kept
    if new_count != original_count + 1:  # +1 for cherry
        print(f"⚠️  Warning: Entry count unexpected ({original_count} -> {new_count}, expected {original_count + 1})")
    
    # Create backup before writing
    backup_path = manifest_path.with_suffix('.luau.backup_pre_reorg')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Created safety backup: {backup_path}")
    
    # Write reorganized manifest
    write_manifest(reorganized, manifest_path)
    print(f"✅ Reorganized manifest written to {manifest_path}")
    
    # Verify cherry
    cherry_entry = next((e for e in reorganized if e['key'] == 'cherry'), None)
    if cherry_entry:
        print(f"✅ Cherry added at index {cherry_entry['spriteIndex']}")
    else:
        print("❌ Error: Cherry not found!")
    
    # Print summary
    print("\n📊 Category summary:")
    categories = defaultdict(list)
    for entry in reorganized:
        _, cat = get_category_group(entry)
        categories[cat].append(entry['spriteIndex'])
    
    for cat in sorted(set(get_category_group(e)[1] for e in reorganized)):
        if cat in categories:
            indices = sorted(categories[cat])
            min_idx, max_idx = min(indices), max(indices)
            print(f"  {cat:20s}: {len(indices):3d} items (indices {min_idx}-{max_idx})")

if __name__ == '__main__':
    main()

