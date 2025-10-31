#!/usr/bin/env python3
"""
Reorganize while preserving original order: Keep items in same sequence, add cherry at 192, group logically.
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

def parse_manifest(content):
    """Parse the manifest file preserving order."""
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
            'indent': indent,
            'original_order': len(entries)  # Track original position
        })
    
    return entries

def get_category_group(entry):
    """Get category group for organization."""
    key = entry['key'].lower()
    
    # Tools
    if 'golden' in key:
        return 'Golden Tools'
    if 'flimsy' in key:
        return 'Flimsy Tools'
    if any(x in key for x in ['shovel', 'net', 'slingshot', 'fishing_rod', 'watering_can', 'axe', 'pole', 'ladder', 'flute', 'tambourine']) or key == 'leaf':
        return 'Basic Tools'
    
    # Currency & UI
    if any(x in key for x in ['bell_bag', 'lost_item', 'bottle_message', 'recipe_card', 'paper_gift', 'leaf_fossil']):
        return 'Currency & UI'
    
    # Clothing
    if any(x in key for x in ['glasses', 'shirt', 'bag', 'socks', 'shoes', 'umbrella']) and 'apple' not in key and 'cherry' not in key:
        return 'Clothing'
    
    # Eggs
    if 'egg' in key:
        return 'Eggs'
    
    # Flowers - grouped
    if 'rose' in key:
        return 'Roses'
    if 'tulip' in key:
        return 'Tulips'
    if 'lily' in key:
        return 'Lilies'
    if 'mum' in key:
        return 'Mums'
    if 'hyacinth' in key:
        return 'Hyacinths'
    if 'cosmos' in key:
        return 'Cosmos'
    
    # Fish
    if key.startswith('fish_'):
        return 'Fish'
    
    # Bugs
    if key.startswith('bug_'):
        return 'Bugs'
    
    # Seasonal
    if any(x in key for x in ['snowflake', 'ornament', 'pumpkin', 'heart']):
        return 'Seasonal'
    
    # Fruits - Apple
    if key == 'apple' or (key.startswith('apple_') and not any(x in key for x in ['chair', 'dress', 'hat', 'rug', 'wall', 'umbrella'])):
        return 'Apple Items'
    
    # Fruits - Cherry
    if key == 'cherry' or (key.startswith('cherry_') and 'blossom' not in key):
        return 'Cherry Items'
    
    # Cherry Blossom
    if 'cherry_blossom' in key or 'cherry-blossom' in key:
        return 'Cherry Blossom'
    
    # Materials
    if any(x in key for x in ['wood', 'stone', 'clay', 'iron', 'gold', 'nugget', 'fragment', 'bamboo', 'sugarcane', 'flour', 'sugar', 'potato', 'maple_leaf', 'wasp_nest', 'weeds']):
        return 'Materials'
    
    # Everything else
    return 'Other'

def reorganize_manifest(entries):
    """Reorganize entries preserving original order, adding cherry at 192."""
    # Check if cherry exists
    has_cherry = any(e['key'] == 'cherry' for e in entries)
    if not has_cherry:
        # Find where to insert cherry (around apple items or after fruits)
        insert_pos = None
        for i, entry in enumerate(entries):
            if entry['key'] == 'apple':
                insert_pos = i + 1
                break
        if insert_pos is None:
            insert_pos = len(entries)
        
        entries.insert(insert_pos, {
            'key': 'cherry',
            'name': 'Cherry',
            'spriteIndex': 9999,
            'indent': '    ',
            'original_order': insert_pos
        })
    
    # Group by category while preserving order
    by_category = defaultdict(list)
    for entry in entries:
        category = get_category_group(entry)
        by_category[category].append(entry)
    
    # Define index ranges and category order
    category_order = [
        ('Basic Tools', 1, 13),
        ('Golden Tools', 14, 19),
        ('Currency & UI', 20, 35),
        ('Clothing', 30, 45),
        ('Eggs', 40, 43),
        ('Roses', 44, 50),
        ('Tulips', 52, 54),
        ('Lilies', 55, 57),
        ('Mums', 58, 60),
        ('Hyacinths', 61, 64),
        ('Cosmos', 65, 67),
        ('Fish', 70, 79),
        ('Bugs', 80, 89),
        ('Seasonal', 90, 110),
        ('Apple Items', 140, 165),
        ('Cherry Items', 190, 210),  # Cherry at 192
        ('Cherry Blossom', 260, 265),
        ('Materials', 270, 290),
        ('Flimsy Tools', 268, 269),
        ('Other', 110, 139),  # Fill gaps
    ]
    
    # Assign indices preserving order within categories
    reorganized = []
    used_indices = set()
    
    for category, start, end in category_order:
        if category not in by_category:
            continue
        
        items = by_category[category]
        
        # Preserve original order within category
        items.sort(key=lambda x: x['original_order'])
        
        # Special: cherry must be at 192
        if category == 'Cherry Items':
            cherry_item = next((x for x in items if x['key'] == 'cherry'), None)
            cherry_others = [x for x in items if x['key'] != 'cherry']
            
            if cherry_item:
                cherry_item['spriteIndex'] = 192
                used_indices.add(192)
                reorganized.append(cherry_item)
            
            # Place other cherry items around 192, preserving order
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
                
                # Find next available slot
                while current in used_indices:
                    current += 1
                    if end and current > end:
                        end = current + 5  # Extend range if needed
                
                item['spriteIndex'] = current
                used_indices.add(current)
                reorganized.append(item)
                current += 1
    
    # Process remaining "Other" items, preserving their original order
    if 'Other' in by_category:
        other_items = by_category['Other']
        other_items.sort(key=lambda x: x['original_order'])
        
        # Fill gaps: 110-140, 165-190, 210-260, 290+
        gap_ranges = [(110, 140), (165, 190), (210, 260), (290, 500)]
        gap_idx = 0
        current_range_start, current_range_end = gap_ranges[gap_idx]
        current = current_range_start
        
        for item in other_items:
            # Skip 192
            if current == 192:
                current = 193
            
            # Find next available slot
            while current in used_indices:
                current += 1
                if current > current_range_end and gap_idx < len(gap_ranges) - 1:
                    gap_idx += 1
                    current_range_start, current_range_end = gap_ranges[gap_idx]
                    current = current_range_start
            
            item['spriteIndex'] = current
            used_indices.add(current)
            reorganized.append(item)
            current += 1
    
    # Sort by spriteIndex for final output
    reorganized.sort(key=lambda x: x['spriteIndex'])
    
    return reorganized

def write_manifest(entries, output_path):
    """Write manifest with category comments, preserving visual grouping."""
    lines = ['return {']
    
    current_category = None
    for entry in entries:
        category = get_category_group(entry)
        
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
    backup_path = manifest_path.with_suffix('.luau.backup_pre_reorg2')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Created safety backup: {backup_path}")
    
    # Write reorganized manifest
    write_manifest(reorganized, manifest_path)
    print(f"✅ Reorganized manifest written to {manifest_path}")
    
    # Verify cherry and original order
    cherry_entry = next((e for e in reorganized if e['key'] == 'cherry'), None)
    if cherry_entry:
        print(f"✅ Cherry added at index {cherry_entry['spriteIndex']}")
    
    # Verify first few items are in correct order
    first_items = [e for e in reorganized if e['spriteIndex'] <= 6]
    first_items.sort(key=lambda x: x['spriteIndex'])
    print(f"✅ First items: {', '.join([e['key'] for e in first_items[:6]])}")
    
    # Print summary
    print("\n📊 Category summary:")
    categories = defaultdict(list)
    for entry in reorganized:
        cat = get_category_group(entry)
        categories[cat].append(entry['spriteIndex'])
    
    for cat in sorted(set(get_category_group(e) for e in reorganized)):
        if cat in categories:
            indices = sorted(categories[cat])
            min_idx, max_idx = min(indices), max(indices)
            print(f"  {cat:20s}: {len(indices):3d} items (indices {min_idx}-{max_idx})")

if __name__ == '__main__':
    main()

