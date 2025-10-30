#!/usr/bin/env python3
"""
Fix items.json file by adding missing fields and fixing JSON syntax issues.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_ITEMS = ROOT / "data" / "items.json"

def fix_json():
    """Fix the items.json file."""
    # Read the file as text first to see the raw content
    with open(DATA_ITEMS, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Try to parse, catching specific errors
    try:
        data = json.loads(content)
        print("JSON is valid!")
        return
    except json.JSONDecodeError as e:
        print(f"JSON Error: {e}")
        print(f"Line {e.lineno}: {e.msg}")
        
        # Read line by line to fix
        lines = content.split('\n')
        fixed_lines = []
        in_item = False
        item_fields = set()
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Check if we're starting a new item
            if '{' in line and '"id"' in line:
                in_item = True
                item_fields = set()
                fixed_lines.append(line)
                continue
            
            # Check if we're ending an item
            if '}' in line:
                in_item = False
                
                # Make sure we have all required fields
                if item_fields:
                    if 'series' not in item_fields and '"series"' not in str(item_fields):
                        fixed_lines.append('      "series": null,')
                    if 'set' not in item_fields and '"set"' not in str(item_fields):
                        fixed_lines.append('      "set": null,')
                    if 'tag' not in item_fields and '"tag"' not in str(item_fields):
                        fixed_lines.append('      "tag": null,')
                    if 'sell' not in item_fields and '"sell"' not in str(item_fields):
                        fixed_lines.append('      "sell": null,')
                    if 'buy' not in item_fields and '"buy"' not in str(item_fields):
                        fixed_lines.append('      "buy": null,')
                    if 'source' not in item_fields and '"source"' not in str(item_fields):
                        fixed_lines.append('      "source": [],')
                    if 'themes' not in item_fields and '"themes"' not in str(item_fields):
                        fixed_lines.append('      "themes": []')
                
                fixed_lines.append(line)
                continue
            
            # Track field names
            if in_item:
                for field in ['series', 'set', 'tag', 'sell', 'buy', 'source', 'themes']:
                    if f'"{field}"' in line:
                        item_fields.add(field)
            
            # Fix empty lines that should have values
            stripped = line.strip()
            if stripped == '' or (stripped == '{' or stripped == '}'):
                fixed_lines.append(line)
                continue
            
            # Fix lines with just "category" and nothing else
            if 'category' in line and 'series' not in content[max(0, i-5):i+5]:
                fixed_lines.append(line)
                continue
            
            fixed_lines.append(line)
        
        # Write fixed content
        fixed_content = '\n'.join(fixed_lines)
        with open(DATA_ITEMS, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        
        print("Attempted to fix JSON. Trying to parse again...")
        
        # Try again
        try:
            data = json.loads(fixed_content)
            print("Successfully fixed!")
        except json.JSONDecodeError as e2:
            print(f"Still has errors: {e2}")
            print(f"Suggest manual fix at line {e2.lineno}")

if __name__ == "__main__":
    fix_json()

