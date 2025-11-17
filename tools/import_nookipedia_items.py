#!/usr/bin/env python3
"""
Import Nookipedia items into ItemsData.luau
Focuses on items available from Nook Shopping and other purchasable items.
Merges with existing ItemsData instead of overwriting.
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = ROOT / "nookipedia_items.json"
EXISTING_LUA = ROOT / "src" / "shared" / "data" / "ItemsData.luau"
OUTPUT_LUA = ROOT / "src" / "shared" / "data" / "ItemsData.luau"

# Limits (set to None for unlimited)
MAX_FURNITURE = None  # None = all items
MAX_CLOTHING = None
MAX_OTHER = None

slug_cache = {}

def slugify(name: str) -> str:
    """Convert item name to slug ID"""
    slug = slug_cache.get(name)
    if slug:
        return slug
    normalized = re.sub(r"[^0-9a-zA-Z]+", "-", name.lower()).strip("-")
    if not normalized:
        normalized = "item"
    slug_cache[name] = normalized
    return normalized


def coerce_sources(entries):
    """Extract source names from availability entries"""
    sources = []
    for entry in entries or []:
        source = entry.get("from")
        if source:
            sources.append(source)
    seen = set()
    ordered = []
    for src in sources:
        if src not in seen:
            seen.add(src)
            ordered.append(src)
    return ordered


def has_nook_shopping(availability):
    """Check if item is available from Nook Shopping"""
    if not availability:
        return False
    for entry in availability:
        source = entry.get("from", "")
        if "Nook Shopping" in source:
            return True
    return False


def has_buy_price(buy_entries):
    """Check if item has a buy price"""
    if not buy_entries:
        return False
    for entry in buy_entries:
        if isinstance(entry, dict) and entry.get("price") is not None:
            return True
    return False


def lua_escape(value: str) -> str:
    """Escape string for Lua"""
    escaped = value.replace("\\", "\\\\").replace("\"", "\\\"")
    escaped = escaped.replace("\n", "\\n")
    return f'"{escaped}"'


def to_lua(value, indent=0):
    """Convert Python value to Lua representation"""
    space = " " * indent
    if isinstance(value, dict):
        if not value:
            return "{}"
        parts = ["{"]
        for key, val in value.items():
            parts.append(f"{space}    [{lua_escape(str(key))}] = {to_lua(val, indent + 4)},")
        parts.append(f"{space}}}")
        return "\n".join(parts)
    if isinstance(value, list):
        if not value:
            return "{}"
        parts = ["{"]
        for item in value:
            parts.append(f"{space}    {to_lua(item, indent + 4)},")
        parts.append(f"{space}}}")
        return "\n".join(parts)
    if isinstance(value, str):
        return lua_escape(value)
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "nil"
    return str(value)


def load_existing_items():
    """Load existing items from ItemsData.luau"""
    existing_items = {}
    existing_items_list = []
    existing_recipes = []
    existing_meta = {}
    
    if EXISTING_LUA.exists():
        print(f"[Import] 📖 Reading existing ItemsData.luau...")
        content = EXISTING_LUA.read_text(encoding="utf-8")
        
        # Extract item IDs using regex
        # Pattern: ["id"] = "item-id",
        import re
        id_pattern = r'\["id"\]\s*=\s*"([^"]+)"'
        item_matches = re.finditer(id_pattern, content)
        
        for match in item_matches:
            item_id = match.group(1)
            existing_items[item_id] = True
        
        # Try to extract the items array structure
        # Find items = { ... }
        items_match = re.search(r'items\s*=\s*\{', content)
        if items_match:
            # Find the matching closing brace
            start_pos = items_match.end()
            brace_count = 1
            i = start_pos
            while i < len(content) and brace_count > 0:
                if content[i] == '{':
                    brace_count += 1
                elif content[i] == '}':
                    brace_count -= 1
                i += 1
            
            # Extract items section
            items_section = content[start_pos:i-1]
            # Split by item entries (rough approximation)
            existing_items_list = items_section
        
        print(f"[Import] ✅ Found {len(existing_items)} existing items")
    
    return existing_items, existing_items_list, existing_recipes, existing_meta


def process_item(entry, category_override=None):
    """Process a single item entry from Nookipedia JSON"""
    item_id = slugify(entry.get("name", "item"))
    buy_entries = entry.get("buy") or []
    price_values = [offer.get("price") for offer in buy_entries 
                   if isinstance(offer, dict) and offer.get("price") is not None]
    buy_price = min(price_values) if price_values else None
    
    category = category_override or entry.get("category") or "Miscellaneous"
    
    # Normalize category names
    category_map = {
        "misc": "Miscellaneous",
        "miscellaneous": "Miscellaneous",
        "housewares": "Housewares",
        "wall-mounted": "Wall-Mounted",
        "wall mounted": "Wall-Mounted",
    }
    category = category_map.get(category.lower(), category)
    
    return {
        "id": item_id,
        "name": entry.get("name"),
        "category": category,
        "series": entry.get("item_series") or None,
        "set": entry.get("item_set") or None,
        "tag": entry.get("tag") or None,
        "sell": entry.get("sell"),
        "buy": buy_price,
        "source": coerce_sources(entry.get("availability")),
        "themes": entry.get("themes") or [],
    }


def main():
    print("[Import] 🚀 Starting Nookipedia item import...")
    
    if not SOURCE_PATH.exists():
        print(f"[Import] ❌ Error: {SOURCE_PATH} not found!")
        return
    
    # Load Nookipedia data
    print(f"[Import] 📦 Loading {SOURCE_PATH.name}...")
    data = json.loads(SOURCE_PATH.read_text(encoding="utf-8"))
    
    # Load existing items
    existing_items, existing_items_list, existing_recipes, existing_meta = load_existing_items()
    
    # Process items
    items = {}
    stats = {
        "furniture": {"total": 0, "nook_shopping": 0, "with_price": 0, "imported": 0},
        "clothing": {"total": 0, "nook_shopping": 0, "with_price": 0, "imported": 0},
        "other": {"total": 0, "nook_shopping": 0, "with_price": 0, "imported": 0},
    }
    
    # Process furniture
    print("[Import] 🪑 Processing furniture...")
    furniture = data.get("furniture", [])
    if MAX_FURNITURE:
        furniture = furniture[:MAX_FURNITURE]
    
    for entry in furniture:
        stats["furniture"]["total"] += 1
        has_ns = has_nook_shopping(entry.get("availability"))
        has_price = has_buy_price(entry.get("buy"))
        
        if has_ns:
            stats["furniture"]["nook_shopping"] += 1
        if has_price:
            stats["furniture"]["with_price"] += 1
        
        # Import if: has Nook Shopping OR has buy price (prioritize Nook Shopping)
        if has_ns or has_price:
            item = process_item(entry)
            item_id = item["id"]
            
            # Only add if not already exists (preserve existing items)
            if item_id not in items and item_id not in existing_items:
                items[item_id] = item
                stats["furniture"]["imported"] += 1
    
    # Process clothing
    print("[Import] 👕 Processing clothing...")
    clothing = data.get("clothing", [])
    if MAX_CLOTHING:
        clothing = clothing[:MAX_CLOTHING]
    
    for entry in clothing:
        stats["clothing"]["total"] += 1
        has_ns = has_nook_shopping(entry.get("availability"))
        has_price = has_buy_price(entry.get("buy"))
        
        if has_ns:
            stats["clothing"]["nook_shopping"] += 1
        if has_price:
            stats["clothing"]["with_price"] += 1
        
        if has_ns or has_price:
            item = process_item(entry, "Clothing")
            item_id = item["id"]
            
            if item_id not in items and item_id not in existing_items:
                items[item_id] = item
                stats["clothing"]["imported"] += 1
    
    # Process other categories (tools, etc.)
    print("[Import] 📦 Processing other categories...")
    for category_key in ["tools", "misc", "other"]:
        category_items = data.get(category_key, [])
        if MAX_OTHER and category_items:
            category_items = category_items[:MAX_OTHER]
        
        for entry in category_items:
            stats["other"]["total"] += 1
            has_ns = has_nook_shopping(entry.get("availability"))
            has_price = has_buy_price(entry.get("buy"))
            
            if has_ns:
                stats["other"]["nook_shopping"] += 1
            if has_price:
                stats["other"]["with_price"] += 1
            
            if has_ns or has_price:
                item = process_item(entry)
                item_id = item["id"]
                
                if item_id not in items and item_id not in existing_items:
                    items[item_id] = item
                    stats["other"]["imported"] += 1
    
    # Filter out items that already exist
    print("[Import] 🔄 Filtering out existing items...")
    new_items = {k: v for k, v in items.items() if k not in existing_items}
    items = new_items
    print(f"[Import] 📋 {len(items)} new items after filtering")
    
    # Read existing file structure (we'll need to parse it properly)
    # For now, we'll append to the existing structure
    # This is a simplified approach - a full Lua parser would be better
    
    # Convert to list and sort
    items_list = sorted(items.values(), key=lambda item: item["name"].lower() if item["name"] else "")
    
    # Print statistics
    print("\n[Import] 📊 Import Statistics:")
    print(f"  Furniture: {stats['furniture']['imported']} imported")
    print(f"    - Total: {stats['furniture']['total']}")
    print(f"    - Nook Shopping: {stats['furniture']['nook_shopping']}")
    print(f"    - With buy price: {stats['furniture']['with_price']}")
    print(f"  Clothing: {stats['clothing']['imported']} imported")
    print(f"    - Total: {stats['clothing']['total']}")
    print(f"    - Nook Shopping: {stats['clothing']['nook_shopping']}")
    print(f"    - With buy price: {stats['clothing']['with_price']}")
    print(f"  Other: {stats['other']['imported']} imported")
    print(f"    - Total: {stats['other']['total']}")
    print(f"    - Nook Shopping: {stats['other']['nook_shopping']}")
    print(f"    - With buy price: {stats['other']['with_price']}")
    print(f"\n[Import] ✅ Total new items to add: {len(items_list)}")
    
    if len(items_list) == 0:
        print("[Import] ⚠️  No new items to import!")
        return
    
    # Append to existing file
    print(f"[Import] 💾 Appending to {OUTPUT_LUA.name}...")
    
    if EXISTING_LUA.exists() and len(items_list) > 0:
        # Read existing content
        existing_content = EXISTING_LUA.read_text(encoding="utf-8")
        
        # Find the items array closing brace and insert before it
        import re
        # Find: items = { ... }
        items_pattern = r'(items\s*=\s*\{)(.*?)(\s*\}\s*,)'
        match = re.search(items_pattern, existing_content, re.DOTALL)
        
        if match:
            items_start = match.group(1)
            items_content = match.group(2)
            items_end = match.group(3)
            
            # Generate new items as Lua code
            new_items_lua = []
            for item in items_list:
                new_items_lua.append("        {")
                new_items_lua.append(f'            ["id"] = "{item["id"]}",')
                new_items_lua.append(f'            ["name"] = "{item["name"]}",')
                new_items_lua.append(f'            ["category"] = "{item["category"]}",')
                new_items_lua.append(f'            ["series"] = {to_lua(item["series"])},')
                new_items_lua.append(f'            ["set"] = {to_lua(item["set"])},')
                new_items_lua.append(f'            ["tag"] = {to_lua(item["tag"])},')
                new_items_lua.append(f'            ["sell"] = {to_lua(item["sell"])},')
                new_items_lua.append(f'            ["buy"] = {to_lua(item["buy"])},')
                new_items_lua.append(f'            ["source"] = {to_lua(item["source"])},')
                new_items_lua.append(f'            ["themes"] = {to_lua(item["themes"])},')
                new_items_lua.append("        },")
            
            # Insert new items before closing brace
            new_items_text = '\n'.join(new_items_lua)
            # Add newline if items_content doesn't end with one
            if items_content and not items_content.rstrip().endswith(','):
                new_items_text = '\n' + new_items_text
            
            # Reconstruct the items section
            new_items_section = items_start + items_content.rstrip() + '\n' + new_items_text + items_end
            
            # Replace in original content
            new_content = existing_content[:match.start()] + new_items_section + existing_content[match.end():]
            
            OUTPUT_LUA.write_text(new_content, encoding="utf-8")
            print(f"[Import] ✅ Successfully appended {len(items_list)} items to existing file!")
        else:
            print("[Import] ⚠️  Could not find items section. Appending to end of file...")
            # Try to append before the final closing brace
            if existing_content.rstrip().endswith('}'):
                # Remove final brace, add items, add brace back
                content_without_brace = existing_content.rstrip()[:-1].rstrip()
                # Find recipes section to insert before
                if 'recipes = {' in content_without_brace:
                    # Insert before recipes
                    recipes_pos = content_without_brace.rfind('recipes = {')
                    before_recipes = content_without_brace[:recipes_pos].rstrip()
                    after_recipes = content_without_brace[recipes_pos:]
                    
                    new_items_lua = []
                    for item in items_list:
                        new_items_lua.append("        {")
                        new_items_lua.append(f'            ["id"] = "{item["id"]}",')
                        new_items_lua.append(f'            ["name"] = "{item["name"]}",')
                        new_items_lua.append(f'            ["category"] = "{item["category"]}",')
                        new_items_lua.append(f'            ["series"] = {to_lua(item["series"])},')
                        new_items_lua.append(f'            ["set"] = {to_lua(item["set"])},')
                        new_items_lua.append(f'            ["tag"] = {to_lua(item["tag"])},')
                        new_items_lua.append(f'            ["sell"] = {to_lua(item["sell"])},')
                        new_items_lua.append(f'            ["buy"] = {to_lua(item["buy"])},')
                        new_items_lua.append(f'            ["source"] = {to_lua(item["source"])},')
                        new_items_lua.append(f'            ["themes"] = {to_lua(item["themes"])},')
                        new_items_lua.append("        },")
                    new_items_text = '\n'.join(new_items_lua)
                    
                    # Find items closing brace
                    items_brace_pos = before_recipes.rfind('},')
                    if items_brace_pos > 0:
                        before_brace = before_recipes[:items_brace_pos+2]
                        after_brace = before_recipes[items_brace_pos+2:]
                        new_content = before_brace + '\n' + new_items_text + after_brace + '\n' + after_recipes + '\n}'
                        OUTPUT_LUA.write_text(new_content, encoding="utf-8")
                        print(f"[Import] ✅ Successfully appended {len(items_list)} items!")
                    else:
                        create_new_file(items_list, existing_recipes, existing_meta)
                else:
                    create_new_file(items_list, existing_recipes, existing_meta)
            else:
                create_new_file(items_list, existing_recipes, existing_meta)
    elif len(items_list) > 0:
        create_new_file(items_list, existing_recipes, existing_meta)
    else:
        print("[Import] ⚠️  No new items to add!")


def create_new_file(items_list, recipes, meta):
    """Create a new ItemsData.luau file"""
    lua_table = ["return {"]
    lua_table.append("    items = {")
    for item in items_list:
        lua_table.append("        {")
        lua_table.append(f'            ["id"] = "{item["id"]}",')
        lua_table.append(f'            ["name"] = "{item["name"]}",')
        lua_table.append(f'            ["category"] = "{item["category"]}",')
        lua_table.append(f'            ["series"] = {to_lua(item["series"])},')
        lua_table.append(f'            ["set"] = {to_lua(item["set"])},')
        lua_table.append(f'            ["tag"] = {to_lua(item["tag"])},')
        lua_table.append(f'            ["sell"] = {to_lua(item["sell"])},')
        lua_table.append(f'            ["buy"] = {to_lua(item["buy"])},')
        lua_table.append(f'            ["source"] = {to_lua(item["source"])},')
        lua_table.append(f'            ["themes"] = {to_lua(item["themes"])},')
        lua_table.append("        },")
    lua_table.append("    },")
    lua_table.append("    recipes = {},")
    lua_table.append("    meta = {},")
    lua_table.append("}")
    
    OUTPUT_LUA.write_text('\n'.join(lua_table) + '\n', encoding="utf-8")
    print(f"[Import] ✅ Created new ItemsData.luau with {len(items_list)} items!")


if __name__ == "__main__":
    main()

