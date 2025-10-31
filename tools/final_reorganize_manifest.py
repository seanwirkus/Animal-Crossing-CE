#!/usr/bin/env python3
"""
Final reorganization: Keep ALL items, group logically, add cherry at 192, fix scattered items.
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

def get_category_info(entry):
    """Get category, sort priority, and preferred index range."""
    key = entry['key'].lower()
    name = entry['name'].lower()
    
    # Basic Tools (1-15)
    if any(x in key for x in ['shovel', 'net', 'slingshot', 'fishing_rod', 'watering_can', 'axe', 'pole', 'ladder', 'flute', 'tambourine']):
        if 'golden' in key:
            return ('tools_golden', 2, 14, 20)
        if 'flimsy' in key:
            return ('tools_flimsy', 3, 268, 270)
        if key == 'leaf':
            return ('tools_basic', 0, 1, 1)
        return ('tools_basic', 1, 1, 15)
    
    # Currency & UI (20-30)
    if any(x in key for x in ['bell_bag', 'lost_item', 'bottle_message', 'recipe_card', 'paper_gift', 'leaf_fossil']):
        return ('currency_ui', 4, 20, 30)
    
    # Clothing (30-40)
    if any(x in key for x in ['glasses', 'shirt', 'bag', 'socks', 'shoes', 'umbrella']) and 'apple' not in key and 'cherry' not in key:
        return ('clothing', 5, 30, 40)
    
    # Eggs (40-44)
    if 'egg' in key:
        return ('eggs', 6, 40, 44)
    
    # Flowers - grouped by type
    if 'rose' in key:
        return ('flowers_roses', 7, 44, 51)
    if 'tulip' in key:
        return ('flowers_tulips', 8, 52, 54)
    if 'lily' in key:
        return ('flowers_lilies', 9, 55, 57)
    if 'mum' in key:
        return ('flowers_mums', 10, 58, 60)
    if 'hyacinth' in key:
        return ('flowers_hyacinths', 11, 61, 64)
    if 'cosmos' in key:
        return ('flowers_cosmos', 12, 65, 67)
    
    # Fish (70-80)
    if key.startswith('fish_'):
        return ('fish', 13, 70, 80)
    
    # Bugs (80-90)
    if key.startswith('bug_'):
        return ('bugs', 14, 80, 90)
    
    # Seasonal (90-110)
    if any(x in key for x in ['snowflake', 'ornament', 'pumpkin', 'heart']):
        return ('seasonal', 15, 90, 110)
    
    # Fruits - Apple (140-165)
    if key == 'apple' or (key.startswith('apple_') and not any(x in key for x in ['chair', 'dress', 'hat', 'rug', 'wall', 'umbrella'])):
        return ('fruits_apple', 16, 140, 165)
    
    # Fruits - Cherry (190-210) - SPECIAL: cherry at 192
    if key == 'cherry' or (key.startswith('cherry_') and 'blossom' not in key):
        return ('fruits_cherry', 17, 190, 210)
    
    # Cherry Blossom (260-265)
    if 'cherry_blossom' in key or 'cherry-blossom' in key:
        return ('cherry_blossom', 18, 260, 265)
    
    # Materials & Crafting (270-290)
    if any(x in key for x in ['wood', 'stone', 'clay', 'iron', 'gold', 'nugget', 'fragment', 'bamboo', 'sugarcane', 'flour', 'sugar', 'potato', 'maple_leaf', 'wasp_nest', 'weeds']):
        return ('materials', 19, 270, 290)
    
    # Everything else - try to keep near existing or fill gaps
    return ('other', 99, None, None)

def reorganize_manifest(entries):
    """Reorganize entries keeping all items."""
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
        cat, priority, start, end = get_category_info(entry)
        by_category[(priority, cat)].append((entry, start, end))
    
    # Sort items within each category
    for key in by_category:
        by_category[key].sort(key=lambda x: (x[0]['key'], x[0]['name']))
    
    # Assign indices
    reorganized = []
    used_indices = set()
    
    # Process categories in priority order
    sorted_cats = sorted(by_category.keys(), key=lambda x: x[0])
    
    for priority, category in sorted_cats:
        items_with_ranges = by_category[(priority, category)]
        
        # Special handling for cherry - must be at 192
        if category == 'fruits_cherry':
            cherry_item = next((x for x in items_with_ranges if x[0]['key'] == 'cherry'), None)
            cherry_others = [x for x in items_with_ranges if x[0]['key'] != 'cherry']
            
            if cherry_item:
                cherry_item[0]['spriteIndex'] = 192
                used_indices.add(192)
                reorganized.append(cherry_item[0])
            
            # Place other cherry items around 192
            current = 190
            for item_data, start, end in cherry_others:
                while current in used_indices or current == 192:
                    current += 1
                item_data['spriteIndex'] = current
                used_indices.add(current)
                reorganized.append(item_data)
                current += 1
        
        # Regular categories with ranges
        elif items_with_ranges and items_with_ranges[0][1] is not None:
            start = items_with_ranges[0][1]
            end = items_with_ranges[0][2]
            
            current = start
            for item_data, _, _ in items_with_ranges:
                # Skip 192 if not cherry category
                if current == 192:
                    current = 193
                
                while current in used_indices:
                    current += 1
                    if end and current > end:
                        # Extend range if needed
                        end = current + 10
                
                item_data['spriteIndex'] = current
                used_indices.add(current)
                reorganized.append(item_data)
                current += 1
        
        # Other category - fill gaps between 110-140 and 210-260
        else:
            # Use gaps: 110-140, 165-190, 210-260, 290+
            gap_ranges = [(110, 140), (165, 190), (210, 260), (290, 500)]
            gap_idx = 0
            current_range_start, current_range_end = gap_ranges[gap_idx] if gap_ranges else (300, 500)
            current = current_range_start
            
            for item_data, _, _ in items_with_ranges:
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
                
                item_data['spriteIndex'] = current
                used_indices.add(current)
                reorganized.append(item_data)
                current += 1
    
    # Sort by spriteIndex
    reorganized.sort(key=lambda x: x['spriteIndex'])
    
    return reorganized

def write_manifest(entries, output_path):
    """Write manifest with clean formatting and category comments."""
    lines = ['return {']
    
    current_category = None
    for entry in entries:
        cat, _, _, _ = get_category_info(entry)
        
        # Add category comment when category changes
        if cat != current_category:
            if current_category is not None:
                lines.append('')  # Blank line between categories
            cat_name = cat.replace('_', ' ').title()
            lines.append(f'    -- {cat_name}')
            current_category = cat
        
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
    
    # Verify all items kept
    if len(reorganized) != len(entries):
        print(f"⚠️  Warning: Entry count changed ({len(entries)} -> {len(reorganized)})")
    
    # Create backup
    backup_path = manifest_path.with_suffix('.luau.backup_final')
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
    else:
        print("❌ Error: Cherry not found!")
    
    # Print summary
    print("\nCategory summary:")
    categories = defaultdict(list)
    for entry in reorganized:
        cat, _, _, _ = get_category_info(entry)
        categories[cat].append(entry['spriteIndex'])
    
    for cat in sorted(set(get_category_info(e)[0] for e in reorganized)):
        if cat in categories:
            indices = sorted(categories[cat])
            print(f"  {cat:20s}: {len(indices):3d} items (indices {min(indices)}-{max(indices)})")

if __name__ == '__main__':
    main()

