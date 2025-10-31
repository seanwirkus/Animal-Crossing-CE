#!/usr/bin/env python3
"""
Simple approach: Add cherry at 192, add category comments, fix only scattered flower indices.
Preserve everything else as-is.
"""

import re
import sys
from pathlib import Path

def parse_manifest(content):
    """Parse the manifest file preserving order."""
    entries = []
    lines = content.split('\n')
    
    for i, line in enumerate(lines):
        pattern = r'(\s+)(\w+)\s*=\s*\{\s*name\s*=\s*"([^"]+)",\s*spriteIndex\s*=\s*(\d+)\s*\},'
        match = re.match(pattern, line)
        if match:
            indent = match.group(1)
            key = match.group(2)
            name = match.group(3)
            sprite_index = int(match.group(4))
            entries.append({
                'key': key,
                'name': name,
                'spriteIndex': sprite_index,
                'indent': indent,
                'line': line,
                'line_num': i
            })
    
    return entries, lines

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

def fix_scattered_flowers(entries):
    """Fix scattered flower indices to group them together."""
    # Collect flowers by type
    roses = [e for e in entries if 'rose' in e['key'].lower()]
    tulips = [e for e in entries if 'tulip' in e['key'].lower()]
    
    # Fix roses: should be 44-50 (currently rose_yellow is at 261)
    rose_indices = {44, 45, 46, 47, 48, 49, 50}
    used = set()
    for rose in roses:
        if rose['spriteIndex'] not in rose_indices:
            # Find next available slot in range
            for idx in sorted(rose_indices):
                if idx not in used:
                    rose['spriteIndex'] = idx
                    used.add(idx)
                    # Update the line
                    rose['line'] = f'    {rose["key"]} = {{ name = "{rose["name"]}", spriteIndex = {idx} }},'
                    break
    
    # Fix tulips: should be 52-54 (currently scattered at 267-273)
    tulip_indices = {52, 53, 54}
    used = set()
    for tulip in tulips:
        if tulip['spriteIndex'] not in tulip_indices:
            for idx in sorted(tulip_indices):
                if idx not in used:
                    tulip['spriteIndex'] = idx
                    used.add(idx)
                    tulip['line'] = f'    {tulip["key"]} = {{ name = "{tulip["name"]}", spriteIndex = {idx} }},'
                    break
    
    return entries

def main():
    manifest_path = Path('src/shared/SpriteManifest.luau')
    
    if not manifest_path.exists():
        print(f"Error: {manifest_path} not found")
        sys.exit(1)
    
    # Read current manifest
    with open(manifest_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Parse entries
    entries, original_lines = parse_manifest(content)
    print(f"✅ Parsed {len(entries)} entries")
    
    # Check if cherry exists
    has_cherry = any(e['key'] == 'cherry' for e in entries)
    
    # Fix scattered flowers
    entries = fix_scattered_flowers(entries)
    
    # Build output with category comments
    output_lines = ['return {']
    current_category = None
    
    for entry in entries:
        category = get_category(entry['key'])
        
        # Add category comment when category changes
        if category != current_category:
            if current_category is not None:
                output_lines.append('')  # Blank line between categories
            output_lines.append(f'    -- {category}')
            current_category = category
        
        output_lines.append(entry['line'])
    
    # Add cherry if it doesn't exist (after apple items)
    if not has_cherry:
        # Find where to insert cherry
        apple_idx = None
        for i, entry in enumerate(entries):
            if entry['key'] == 'apple':
                apple_idx = i
                break
        
        if apple_idx is not None:
            # Insert cherry after apple section
            cherry_line = '    cherry = { name = "Cherry", spriteIndex = 192 },'
            # Find the right place in output_lines
            insert_pos = None
            for i, line in enumerate(output_lines):
                if 'Apple Items' in line:
                    # Find end of apple items section
                    for j in range(i+1, len(output_lines)):
                        if output_lines[j].startswith('    -- '):
                            insert_pos = j
                            break
                    if insert_pos:
                        break
            
            if insert_pos:
                output_lines.insert(insert_pos, '')
                output_lines.insert(insert_pos, '    -- Cherry Items')
                output_lines.insert(insert_pos + 1, cherry_line)
            else:
                # Fallback: add at end before closing brace
                output_lines.insert(-1, '')
                output_lines.insert(-1, '    -- Cherry Items')
                output_lines.insert(-1, cherry_line)
    
    output_lines.append('}')
    
    # Create backup
    backup_path = manifest_path.with_suffix('.luau.backup_pre_simple')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Created backup: {backup_path}")
    
    # Write output
    output_content = '\n'.join(output_lines) + '\n'
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(output_content)
    
    print(f"✅ Updated manifest written to {manifest_path}")
    
    # Verify cherry
    if not has_cherry:
        print(f"✅ Cherry added at index 192")
    
    # Verify first items
    first_entries = sorted([e for e in entries if e['spriteIndex'] <= 6], key=lambda x: x['spriteIndex'])
    print(f"✅ First items: {', '.join([f\"{e['key']}={e['spriteIndex']}\" for e in first_entries[:6]])}")

if __name__ == '__main__':
    main()

