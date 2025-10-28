#!/usr/bin/env python3
"""
Extract JSON Data for Roblox Studio Setup

This script reads the nookipedia JSON files and outputs them in a format
that can be easily copied into Roblox Studio as StringValue objects.

Usage: Run this script and copy the output into Roblox Studio's
ReplicatedStorage/data StringValues.
"""
import json
import os
import sys

def read_json_file(filepath):
    """Read JSON file and return content as string"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
            # Convert back to compact JSON string for Roblox
            return json.dumps(data, separators=(',', ':'))
    except Exception as e:
        print(f"❌ Error reading {filepath}: {e}", file=sys.stderr)
        return None

def main():
    """Main function to extract and format JSON data"""
    data_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'data')

    # Files to process
    files_to_process = [
        ('nookipedia_characters.json', 'nookipedia_characters'),
        ('nookipedia_items.json', 'nookipedia_items')
    ]

    print("=" * 60)
    print("Roblox Studio Data Setup - StringValue Values")
    print("=" * 60)
    print()
    print("INSTRUCTIONS:")
    print("1. Open Roblox Studio")
    print("2. Navigate to ReplicatedStorage")
    print("3. Create folder 'data' if it doesn't exist")
    print("4. For each entry below:")
    print("   a. Create StringValue with the given name")
    print("   b. Copy the JSON content into the Value property")
    print()
    print("-" * 60)

    for filename, stringvalue_name in files_to_process:
        filepath = os.path.join(data_dir, filename)

        print(f"\n🔸 STRINGVALUE NAME: {stringvalue_name}")
        print("-" * 40)

        if not os.path.exists(filepath):
            print(f"❌ FILE NOT FOUND: {filepath}")
            print("⚠️  Skipping this file - check data directory")
            continue

        content = read_json_file(filepath)
        if content is None:
            print("⚠️  Skipping due to read error")
            continue

        # Check size for Roblox limits
        content_size = len(content.encode('utf-8'))
        if content_size > 2 * 1024 * 1024:  # 2MB limit for StringValue
            print(f"⚠️  WARNING: Content size {content_size:,} bytes exceeds Roblox StringValue limit (2MB)")
        else:
            print(f"✅ Content size: {content_size:,} bytes")

        print("\n🔸 COPY THIS JSON CONTENT:")
        print("=" * 40)
        print()
        # Use repr to escape properly for terminal output
        print(content)
        print()
        print("=" * 40)

    print("\n" + "=" * 60)
    print("Setup complete! Copy the JSON strings above into Roblox Studio.")
    print("=" * 60)

if __name__ == '__main__':
    main()
