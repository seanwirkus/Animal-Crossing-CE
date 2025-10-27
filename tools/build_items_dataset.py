import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = ROOT / "nookipedia_items.json"
OUTPUT_JSON = ROOT / "data" / "items.json"
OUTPUT_LUA = ROOT / "src" / "shared" / "data" / "ItemsData.luau"

MAX_ITEMS = 120
MAX_RECIPES = 80

slug_cache = {}

def slugify(name: str) -> str:
    slug = slug_cache.get(name)
    if slug:
        return slug
    normalized = re.sub(r"[^0-9a-zA-Z]+", "-", name.lower()).strip("-")
    if not normalized:
        normalized = "item"
    slug_cache[name] = normalized
    return normalized


def coerce_sources(entries):
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


def lua_escape(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace("\"", "\\\"")
    escaped = escaped.replace("\n", "\\n")
    return f'"{escaped}"'


def to_lua(value, indent=0):
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


def ensure_output_dirs():
    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_LUA.parent.mkdir(parents=True, exist_ok=True)


def main():
    ensure_output_dirs()
    data = json.loads(SOURCE_PATH.read_text(encoding="utf-8"))

    items = {}
    recipes = []

    furniture = data.get("furniture", [])[:MAX_ITEMS]
    for entry in furniture:
        item_id = slugify(entry.get("name", "item"))
        buy_entries = entry.get("buy") or []
        price_values = [offer.get("price") for offer in buy_entries if isinstance(offer, dict) and offer.get("price") is not None]
        buy_price = min(price_values) if price_values else None
        items[item_id] = {
            "id": item_id,
            "name": entry.get("name"),
            "category": entry.get("category") or "misc",
            "series": entry.get("item_series") or None,
            "set": entry.get("item_set") or None,
            "tag": entry.get("tag") or None,
            "sell": entry.get("sell"),
            "buy": buy_price,
            "source": coerce_sources(entry.get("availability")),
            "themes": entry.get("themes") or [],
        }

    for entry in data.get("recipes", [])[:MAX_RECIPES]:
        recipe_id = slugify(entry.get("name", "recipe"))
        item_id = recipe_id

        if item_id not in items:
            items[item_id] = {
                "id": item_id,
                "name": entry.get("name"),
                "category": "crafted",
                "series": None,
                "set": None,
                "tag": None,
                "sell": entry.get("sell"),
                "buy": None,
                "source": coerce_sources(entry.get("availability")),
                "themes": [],
            }

        materials = []
        for mat in entry.get("materials", []):
            mat_name = mat.get("name", "Material")
            mat_id = slugify(mat_name)
            materials.append({
                "itemId": mat_id,
                "name": mat_name,
                "count": mat.get("count", 1),
            })

            if mat_id not in items:
                items[mat_id] = {
                    "id": mat_id,
                    "name": mat_name,
                    "category": "material",
                    "series": None,
                    "set": None,
                    "tag": None,
                    "sell": None,
                    "buy": None,
                    "source": [],
                    "themes": [],
                }

        base_time = max(4, 2 + 3 * len(materials))
        station = "workbench"
        lower_name = entry.get("name", "").lower()
        if any(token in lower_name for token in ("cake", "soup", "stew", "grill", "fry")):
            station = "cooking"
        elif "medicine" in lower_name or "potion" in lower_name:
            station = "alchemy"

        recipes.append({
            "id": recipe_id,
            "itemId": item_id,
            "name": entry.get("name"),
            "sell": entry.get("sell"),
            "station": station,
            "time": base_time,
            "materials": materials,
            "source": coerce_sources(entry.get("availability")),
        })

    sorted_items = sorted(items.values(), key=lambda item: item["name"].lower())
    recipes.sort(key=lambda recipe: recipe["name"].lower())

    payload = {
        "items": sorted_items,
        "recipes": recipes,
        "meta": {
            "source": "Nookipedia",
            "itemsSampled": len(sorted_items),
            "recipesSampled": len(recipes),
        },
    }

    OUTPUT_JSON.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    lua_table = ["return {"]
    for key in ("items", "recipes", "meta"):
        lua_table.append(f"    {key} = {to_lua(payload[key], 4)},")
    lua_table.append("}")
    OUTPUT_LUA.write_text("\n".join(lua_table) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
