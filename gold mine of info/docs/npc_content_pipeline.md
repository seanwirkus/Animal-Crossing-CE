# NPC & Model Expansion Plan

This note outlines how we'll grow the island population and world props while keeping production efficient and cozy-life friendly.

## 1. Data Source Strategy
- **Spreadsheet linkage**: Extend `docs/acnh.xlsx` by adding tabs for `Residents`, `NPCRoles`, and `Buildables`. Each row should capture IDs, display/localized names, personalities, preferred biomes, schedule presets, dialogue seeds, and associated asset slugs.
- **Importer additions**: Expand `scripts/import_acnh.py` (or spin a sibling script) to transform these sheets into:
  - `src/shared/Data/GeneratedVillagers.luau` (new definitions that merge with handcrafted residents),
  - `src/shared/Data/GeneratedFurniture.luau` / JSON payloads for buildables.
- **Schema alignment**: Ensure new tables map cleanly to `Types.VillagerDefinition` and any forthcoming furniture types. Stick to IDs that reference original assets we design in-house (no Nintendo IP usage).

## 2. Asset Pipeline
- **Model library**: For every new NPC/furniture entry, reference a Roblox asset ID from `src/ReplicatedStorage/Assets/Models`. Keep each model grouped with texture folders following the naming convention `category_itemName_variant`.
- **Texture authoring**: Drop stylized textures into `Assets/Textures` using the ACNH-inspired palette defined in `docs/data_pipeline.md`. Use layered PSD/SVG master files so variants are trivial.
- **Thumbnail + icon pass**: Generate consistent portrait renders (512×512) for the island picker, quest UI, and inventory. Store them alongside the models with matching IDs for easy lookup.
- **Automation goal**: Hook a simple CLI (e.g. `scripts/render_thumbnails.rbxlx`) to spawn thumbnails from models at nightlies to catch regressions.

## 3. Implementation Steps
1. **Template merge**: Update `src/shared/Data/Villagers.luau` to build from `GeneratedVillagers` plus handcrafted characters—giving design the option to override without editing generated files.
2. **Spawner hooks**: Teach `src/server/Systems/VillagerService.luau` to read the player's chosen island template (`IslandService:GetSelection`) and spawn NPCs whose `biomeTags` align.
3. **Quest authoring**: Feed the new NPC IDs into quest templates so they request items and crafts that highlight the island's initial biome and resources.
4. **World props**: Similar to NPCs, wire buildable/furniture data into an upcoming `FurnitureService` so the starting island loads the correct décor set.

## 4. Content Roadmap
- Wave 1: Finish base trio of island templates (`coral_cove`, `forest_glade`, `highland_spring`) with 2 starter villagers each and 10 themed props.
- Wave 2: Layer in seasonal NPCs (travelling merchants, event hosts) and rotating décor bundles tied to the live-ops calendar in the spreadsheet.
- Wave 3: Unlock player-crafted villagers (UGC) and allow creators to publish blueprint bundles that the importer can ingest after validation.

Keep everything "inspired by"—build fresh silhouettes, patterns, and dialogue so the game stands on its own while still delivering that cozy, neighborly feel.
