#!/usr/bin/env python3
"""
Sort SpriteManifest.luau by spriteIndex to keep them in order.
"""
import re

def main():
    manifest_path = 'src/shared/SpriteManifest.luau'
    
    # Read the manifest file
    with open(manifest_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Parse all entries
    lines = content.split('\n')
    entries = []
    
    for line in lines:
        line_stripped = line.strip()
        # Skip blank lines, comments, and the return statement
        if not line_stripped or line_stripped.startswith('--') or line_stripped == 'return {' or line_stripped == '}':
            continue
        
        # Extract the entry
        # Format: key = { name = "Name", spriteIndex = number },
        match = re.search(r'spriteIndex\s*=\s*(\d+)', line)
        if match:
            index = int(match.group(1))
            entries.append((index, line.rstrip()))
    
    # Sort by spriteIndex
    entries.sort(key=lambda x: x[0])
    
    # Write back sorted entries
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write('return {\n')
        for _, entry in entries:
            f.write(entry + '\n')
        f.write('}\n')
    
    print(f"✅ Sorted {len(entries)} entries by spriteIndex")

if __name__ == '__main__':
    main()

