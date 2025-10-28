# Cozy Life Sim Roadmap

This roadmap covers the next four feature pillars after the Day 0 ceremony. Each section lists the player fantasy, high-value tasks, and cross-team dependencies so we can stage delivery without thrash.

## 2. Time-Driven World State
- **Fantasy**: The island breathes with the clock—crops grow, critters rotate, shops open/close, and ambience changes.
- **Key Tasks**
  - Build a `WorldStateService` that ticks with `IslandClock`, storing day/night segments and applying modifiers (e.g., rain boosts flower growth).
  - Model crop growth stages and watering requirements; push state to clients for rendering sprouts/blooms.
  - Expand spawn tables in `Config.SpawnTables` to reference `Data.GeneratedItems` + season/time tags; update spawners to respect the new weights.
  - Gate shop inventories and visitor NPC arrivals behind time windows, including signage/UI feedback when closed.
- **Dependencies**: Uses weather + clock remotes, needs inventory hooks for crops and shop stock tracking, plus asset support for growth stages.

## 3. Home & Décor Upgrades
- **Fantasy**: Players expand and personalize their home inside/outside using crafting and upgrade paths.
- **Key Tasks**
  - Implement `FurnitureService` + placement grid that supports interior and exterior slots, with save/load per player.
  - Extend the spreadsheet importer to generate furniture recipes, cost curves, and décor tags (cozy, natural, sporty) for scoring.
  - Add a home-upgrade progression (Resident Services analog) that unlocks room expansions and storage tiers; integrate with EconomyService for loan tracking.
  - Update client decorating UI (ghost placement, rotate, remove) and tie into QuestService for décor objectives.
- **Dependencies**: Needs asset pipeline for furniture prefabs, persistence layer for placements, and animation hooks for upgrade cutscenes.

## 4. Museum & Collections
- **Fantasy**: Donations showcase the island’s biodiversity while rewarding completion.
- **Key Tasks**
  - Create `CollectionService` to track donated fish/bugs/fossils, referencing generated item data for rarity and exhibit placement.
  - Build museum interior scenes with modular exhibit dioramas that light up as players donate.
  - Extend catch events (ToolService fishing/bug net) to call into `CollectionService` and surface donation prompts.
  - Add collection milestones to QuestService and reward economy bonuses (special décor, plaques).
- **Dependencies**: Requires inventory handoff from catches, museum assets, and UI panels for the collection log.

## 5. Seasonal Live Ops
- **Fantasy**: The island celebrates ongoing events (Cherry Blossom festival, Firefly nights) with rotating NPCs, décor, and activities.
- **Key Tasks**
  - Introduce a `LiveOpsScheduler` that reads the spreadsheet’s Events tab and schedules quests, weather overrides, and shop bundles.
  - Script visiting NPC behaviors (merchant tents, photo booths) with dialogue pools tied to event data.
  - Bundle themed décor + clothing into limited-time shop entries; use InventoryService for reward delivery.
  - Add calendar UI (Hud side panel) so players see upcoming events and rewards.
- **Dependencies**: Shares data pipeline with events tab, relies on NPC Content pipeline for assets, and touches economy + quest systems for rewards.

## Delivery Notes
- Ship pillars sequentially, but prototype overlapping tasks early (e.g., furniture placements help museum display cases).
- Keep generated data separate from handcrafted overrides so designers can hotfix quickly.
- As systems grow, add regression tooling (command bar cheats, automated island states) to validate daily/weekly rotations without manual playthroughs.
