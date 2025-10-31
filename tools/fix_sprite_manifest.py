#!/usr/bin/env python3
"""
Fix SpriteManifest.luau by removing duplicates and renumbering all entries sequentially.
"""
import re

def main():
    manifest_path = 'src/shared/SpriteManifest.luau'
    
    # Read the manifest file
    with open(manifest_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Parse all entries
    entries = []
    seen_keys = set()
    
    for line in lines:
        line_stripped = line.strip()
        # Skip blank lines, comments, and the return statement/closing brace
        if not line_stripped or line_stripped.startswith('--') or line_stripped == 'return {' or line_stripped == '}':
            continue
        
        # Extract the key
        match = re.match(r'(\S+)\s*=\s*\{', line)
        if match:
            key = match.group(1)
            # Only add if we haven't seen this key before
            if key not in seen_keys:
                entries.append(line.rstrip())
                seen_keys.add(key)
            else:
                print(f"⚠️  Skipping duplicate key: {key}")
    
    # Write back sorted entries with sequential indices
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write('return {\n')
        for i, entry in enumerate(entries, 1):
            # Replace the spriteIndex with the sequential index
            new_entry = re.sub(r'spriteIndex\s*=\s*\d+', f'spriteIndex = {i}', entry)
            # Ensure it starts with proper indentation
            if not new_entry.startswith('    '):
                f.write('    ' + new_entry + ',\n')
            else:
                f.write(new_entry + ',\n')
        f.write('}\n')
    
    print(f"\n✅ Fixed {len(entries)} entries with sequential indices 1-{len(entries)}")

if __name__ == '__main__':
    main()

