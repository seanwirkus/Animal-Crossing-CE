#!/usr/bin/env python3
"""
Add missing items from ItemsData to SpriteManifest with placeholder sprite indices.
"""
import re
import sys

def extract_items_from_items_data(filepath):
    """Extract item id and name pairs from ItemsData.luau"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    items = []
    # Match item entries: { ["id"] = "...", ["name"] = "...", ... }
    pattern = r'\{[^}]*\[\"id\"\]\s*=\s*\"([^\"]+)\"[^}]*\[\"name\"\]\s*=\s*\"([^\"]+)\"'
    
    for match in re.finditer(pattern, content, re.DOTALL):
        item_id = match.group(1)
        item_name = match.group(2)
        items.append((item_id, item_name))
    
    return items

def extract_existing_manifest_items(filepath):
    """Extract existing item IDs from SpriteManifest"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    existing = set()
    # Match: item_id = { name = "...", spriteIndex = ... }
    # Also match item_ prefixed keys
    pattern = r'(\w+(?:_\w+)*)\s*=\s*\{'
    for match in re.finditer(pattern, content):
        item_id = match.group(1)
        existing.add(item_id)
        # Also add without item_ prefix if it starts with item_
        if item_id.startswith('item_'):
            existing.add(item_id[5:])  # Remove 'item_' prefix
    
    return existing

def get_max_sprite_index(filepath):
    """Get the maximum sprite index from SpriteManifest"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    max_index = 0
    pattern = r'spriteIndex\s*=\s*(\d+)'
    for match in re.finditer(pattern, content):
        index = int(match.group(1))
        max_index = max(max_index, index)
    
    return max_index

def convert_id_to_manifest_key(item_id):
    """Convert item ID to manifest key format (lowercase, underscores)"""
    # Replace hyphens with underscores
    key = item_id.replace('-', '_')
    # Remove any other special characters
    key = re.sub(r'[^a-z0-9_]', '', key.lower())
    # If key starts with a number, prefix with 'item_' (Lua identifiers can't start with numbers)
    if key and key[0].isdigit():
        key = 'item_' + key
    return key

def main():
    items_data_path = 'src/shared/data/ItemsData.luau'
    manifest_path = 'src/shared/SpriteManifest.luau'
    
    print("Loading items from ItemsData...")
    all_items = extract_items_from_items_data(items_data_path)
    print(f"Found {len(all_items)} items")
    
    print("Loading existing SpriteManifest...")
    existing_ids = extract_existing_manifest_items(manifest_path)
    print(f"Found {len(existing_ids)} existing items")
    
    max_index = get_max_sprite_index(manifest_path)
    print(f"Max sprite index: {max_index}")
    
    # Find missing items
    missing_items = []
    seen_keys = set()
    for item_id, item_name in all_items:
        manifest_key = convert_id_to_manifest_key(item_id)
        # Check both the key and if it's already in existing_ids
        if manifest_key not in existing_ids and manifest_key not in seen_keys:
            missing_items.append((manifest_key, item_name))
            seen_keys.add(manifest_key)
    
    print(f"\nFound {len(missing_items)} missing items")
    
    if not missing_items:
        print("No missing items to add!")
        return
    
    # Read manifest file
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest_content = f.read()
    
    # Find the closing brace before the final '}'
    # We need to insert before the last '}' of the return block
    lines = manifest_content.split('\n')
    
    # Find the last line with '}' (closing the return block)
    last_brace_line = -1
    for i in range(len(lines) - 1, -1, -1):
        if lines[i].strip() == '}':
            last_brace_line = i
            break
    
    if last_brace_line == -1:
        print("Error: Could not find closing brace in manifest file")
        return
    
    # Generate new entries
    new_entries = []
    current_index = max_index + 1
    
    # Limit to 494 max (excluding 495-504)
    max_allowed_index = 494
    
    for manifest_key, item_name in missing_items:
        if current_index > max_allowed_index:
            print(f"\n⚠️  Warning: Reached max sprite index {max_allowed_index}. {len(missing_items) - len(new_entries)} items not added.")
            break
        
        # Escape quotes in name
        safe_name = item_name.replace('"', '\\"')
        entry = f'    {manifest_key} = {{ name = "{safe_name}", spriteIndex = {current_index} }},'
        new_entries.append(entry)
        current_index += 1
    
    # Insert new entries before the closing brace
    new_lines = lines[:last_brace_line] + new_entries + lines[last_brace_line:]
    new_content = '\n'.join(new_lines)
    
    # Write back
    backup_path = manifest_path + '.backup'
    print(f"\nCreating backup: {backup_path}")
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(manifest_content)
    
    print(f"Writing {len(new_entries)} new entries to {manifest_path}")
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"\n✅ Done! Added {len(new_entries)} items (sprite indices {max_index + 1} to {current_index - 1})")

if __name__ == '__main__':
    main()

