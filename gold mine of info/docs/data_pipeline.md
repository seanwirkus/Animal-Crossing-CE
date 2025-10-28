# ACNH Data Integration Plan

This document tracks how the spreadsheet at `docs/acnh.xlsx` will flow into the live game data. It focuses on the minimum viable slice that lets us ship a measurable loop while keeping the pipeline repeatable.

## 1. MVP Scope
- **Items**: Import catalog rows for `Fish` and `Insects` to back the gathering → museum/economy loop. These map cleanly onto `Types.ItemDefinition`.
- **Future hooks** (once the pipeline is proven): `Housewares` → furniture catalog, `ToolsGoods` → tool upgrades, `Villagers` & `Paradise Planning` → dialogue/schedules, `Seasons and Events` → live-ops calendar.

## 2. Target Item Schema
`Types.ItemDefinition` currently expects:
| Field | Description | Source column(s) | Notes |
| --- | --- | --- | --- |
| `id` | Stable lowercase identifier | `Name` | Slugify the name (e.g. `anchovy` → `fish_anchovy`). Prefix by category to prevent collisions. |
| `name` | Display string | `Name` | Keep capitalization from sheet. |
| `category` | `"Fish"` \| `"Bug"` | Sheet name | Direct map: `Fish` → `"Fish"`, `Insects` → `"Bug"`. |
| `baseValue` | Sell price in Bells | `Sell` | Parse as number; default to 0 if blank. |
| `rarity` | `"Common"`, `"Uncommon"`, `"Rare"`, `"UltraRare"` | Derived | Use sell price bands: `<1 000` → Common, `<3 000` → Uncommon, `<8 000` → Rare, else UltraRare. |
| `description` | Museum/lore text | `Description` | Trim whitespace. |
| `seasonTags` | High-level availability | `NH Jan`…`NH Dec` | Map months with non-`NA` entries into seasons (Winter = Dec/Jan/Feb, Spring = Mar/Apr/May, Summer = Jun/Jul/Aug, Autumn = Sep/Oct/Nov). |
| `timeWindows` | Spawn hours | Same as `seasonTags` | For each unique time range string (e.g. `4 AM – 9 PM`), parse into `{ startHour, endHour }`. Treat `All day` as `{0, 24}`. |
| `requirements` | Location hints | `Where/How` | Convert the location text into tag identifiers (e.g. `"River"` → `{"LocationRiver"}`). Leave nil if no clear mapping. |

Edge Cases:
- Values like `4 PM – 9 AM` wrap past midnight; we will store `startHour = 16`, `endHour = 9`.
- Some rows list multiple windows separated by `&` or `,`; split on these separators before parsing.
- Lines that we cannot parse get logged and skipped so we can review them manually.

## 3. Conversion Script
`scripts/import_acnh.py` will:
1. Load `docs/acnh.xlsx` with `openpyxl` (we already seeded a repo-local `.venv`).
2. Normalize each relevant sheet into the schema above.
3. Emit `Data/Generated/items.json` (one big array) plus a Luau module `src/shared/Data/GeneratedItems.luau` for runtime consumption.
4. Warn about unhandled columns, missing assets, or parsing failures.

The Luau module will look like:
```lua
return {
    fish_anchovy = {
        id = "fish_anchovy",
        name = "anchovy",
        category = "Fish",
        baseValue = 200,
        rarity = "Common",
        description = "...",
        seasonTags = { "Spring", "Summer", "Autumn", "Winter" },
        timeWindows = {
            { startHour = 4, endHour = 21 },
        },
        requirements = { "LocationSea" },
    },
}
```

## 4. Integration Steps
1. **Runtime selection**: Update `src/shared/Data/init.luau` to merge generated entries (from `GeneratedItems.luau`) with the handcrafted prototypes until we are comfortable removing the old tables.
2. **Economy tuning**: Point spawn/loot tables and quest rewards to the generated IDs (e.g. `QuestService:RecordInteraction` and any future fishing/bug-catching systems).
3. **Client UI**: Update `src/client/UI/Hud.luau` and `src/client/UI/ToolSelector.luau` to pull names/descriptions from the new data table.
4. **Asset binding**: Extend `src/shared/AssetManager.luau` with a lookup table that matches spreadsheet `Icon Filename` / `Furniture Filename` values to Roblox asset IDs as they are imported.

## 5. Open Questions
- Do we want hemisphere-specific availability? If so, duplicate the season/time parsing for `SH` columns and tag them separately.
- Should rarity map to spawn probability instead of sell price? Once spawn tables are wired, we can revisit.
- Where should we surface museum flavor text versus short UI descriptions? The sheet only gives us the long version right now.

## 6. Short-Term TODOs
- Wire `src/shared/Data/init.luau` so it returns `{ Generated = require(script.GeneratedItems), Prototypes = require(script.Items) }` and update call sites to use the generated table as the canonical source.
- Backfill spawn logic (once implemented) with the new `seasonTags` and `timeWindows` so island time gates actual spawns.
- Expand `LOCATION_KEYWORDS` in `scripts/import_acnh.py` when we encounter missing biome tags, and push the resulting tag IDs into gameplay systems (e.g. fishing spots, flower beds).
- Add CI guard (Git hook or simple CLI check) that runs `python scripts/import_acnh.py` and ensures `GeneratedItems.luau` is up to date before publishing builds.
