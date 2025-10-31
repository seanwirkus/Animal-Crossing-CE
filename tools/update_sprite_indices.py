#!/usr/bin/env python3
"""
Update SpriteManifest.luau with correct item names based on sprite indices.
These are GUI icons for clothing/materials.
"""

import re
from pathlib import Path

def main():
    manifest_path = Path('src/shared/SpriteManifest.luau')
    
    with open(manifest_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Map of spriteIndex -> (id, name)
    updates = {
        23: ('construction_hat', 'Construction Hat'),
        24: ('red_motorcycle_helmet', 'Red Motorcycle Helmet'),
        25: ('red_hat', 'Red Hat'),
        30: ('blue_striped_gloves', 'Blue Striped Gloves'),
        31: ('jeans', 'Jeans'),
        39: ('egg_pink', 'Pink Egg'),
        42: ('egg_blue', 'Blue Egg'),
        43: ('rainbow_striped_jar', 'Rainbow-Striped Jar'),
        44: ('hardwood', 'Hardwood'),  # Dark wood
        45: ('wood', 'Wood'),  # Normal wood
        46: ('softwood', 'Softwood'),  # Light wood
        47: ('bamboo_piece', 'Bamboo Piece'),
        49: ('tree_branch', 'Tree Branch'),
        50: ('clay', 'Clay'),  # Already exists, keep
        51: ('charcoal', 'Charcoal'),
        68: ('young_spring_bamboo', 'Young Spring Bamboo'),  # Lighter bamboo
    }
    
    # Find and replace entries by spriteIndex
    for sprite_index, (item_id, item_name) in updates.items():
        # Pattern to match entries with this spriteIndex
        pattern = rf'(\s+)(\w+)\s*=\s*\{\s*name\s*=\s*"[^"]*",\s*spriteIndex\s*=\s*{sprite_index}\s*\},'
        
        def replace_match(match):
            indent = match.group(1)
            old_id = match.group(2)
            return f'{indent}{item_id} = {{ name = "{item_name}", spriteIndex = {sprite_index} }},'
        
        content = re.sub(pattern, replace_match, content)
    
    # Also need to handle items that are currently at wrong indices
    # Move paper_gift from 39 to somewhere else (we'll keep it but need to find its new spot)
    # Move rose_white from 42 (update to egg_blue)
    # Move rose_pink from 43 (update to rainbow_striped_jar)
    # Move lily_yellow from 49 (update to tree_branch)
    # Move mum_purple from 51 (update to charcoal)
    # Move fish_koi from 68 (update to young_spring_bamboo)
    
    # For items that need to be moved, we'll need to find new indices for them
    # But first, let's update the ones we know
    
    # Write back
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Updated SpriteManifest.luau with correct item names")

if __name__ == '__main__':
    main()

