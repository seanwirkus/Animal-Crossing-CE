# Animal Crossing CE

A polished Roblox recreation of Animal Crossing: New Horizons featuring inventory management, crafting, onboarding flows, island generation, and a unified GUI theme. This README consolidates every workflow, guide, and checklist that previously lived in `PROJECT_PLAN.md`, `QUICK_REFERENCE.md`, `STARTUP_GUIDE.md`, and the `gold mine of info/` folder—this file is now the canonical source of truth.

## 📚 Table of Contents
1. [Project Overview](#project-overview)
2. [Quick Start](#quick-start)
3. [Documentation Portal](#documentation-portal)
4. [Controls & Keybinds](#controls--keybinds)
5. [GUI & UX Architecture](#gui--ux-architecture)
6. [Core Gameplay Systems](#core-gameplay-systems)
7. [Onboarding & Roadmap](#onboarding--roadmap)
8. [Troubleshooting & References](#troubleshooting--references)

## Project Overview
* **Tech stack:** Roblox + Luau, Rojo project structure, Stylua + Selene linting, Luau-LSP analysis, and GitHub Actions CI.
* **Major pillars:**
  * **Inventory & Upgrades** – persistent drag-and-drop inventory backed by DataStore, now with purchasable pocket expansions.
  * **Crafting & Stations** – DIY workbench plus unlockable Forge/Cooking/Sewing/Alchemy stations with their own recipe sets.
  * **Discovery Layer** – server-driven recipe discovery system tied to milestones (inventory level, station unlocks, onboarding beats).
  * **Unified UI** – `GUIManager`, `GUIContentManager`, `GUIStyleUtil`, and `UniversalGUIPreset` guarantee the cream/beige ACNH aesthetic everywhere, including the new Emote Wheel and upgrades dashboard.
  * **Player Experience** – Minimap, Tool Ring, NookPhone, dialogue/cutscene loaders, and an onboarding flow ready for new villagers.

## Quick Start
### Requirements
* Roblox Studio + Rojo plugin
* Git + Ruby (for Rojo CLI), Bash, and optionally `aftman`

### Install & Build
```bash
aftman install
rojo build -o "Animal Crossing CE.rbxlx"
```
Open the place file in Roblox Studio and run `rojo serve` for hot reloading.

### Static Checks (run before every commit)
```bash
bash tools/run_static_checks.sh
```
This executes Stylua (format), Selene (lint), Luau-LSP (analyze), RemoteEvent validation, and a Rojo build. A lightweight lint-only pass is available via `scripts/check-lint.sh`.

### High-level workflow
1. **Sync & build** – `git pull`, `rojo build`.
2. **Iterate** – work inside `src/client`, `src/server`, or `src/shared`. GUI work happens in `src/client/Modules/*`.
3. **Run the game** – open the built place, press Play, and use the keybinds below to open GUIs.
4. **Validate** – `bash tools/run_static_checks.sh` and manual playtest.
5. **Commit** – include a descriptive message, push, and open/merge a PR.

## Documentation Portal
All of the legacy guides and feature-specific briefs now live behind one hub so you no longer need to guess which Markdown file contains the information you need. Review `docs/DOCUMENTATION_PORTAL.md` whenever you need:

* A categorized list of gameplay/system docs (inventory, crafting, onboarding, monetization, etc.).
* Links back to the setup checklists, production plans, GUI audits, and tooling references.
* A TODO section that tracks which legacy docs still need to be merged or refreshed.

Updating that single file keeps the rest of the documentation footprint maintainable.

## Controls & Keybinds
| Key | Action | Module |
|-----|--------|--------|
| **E** | Inventory toggle | `InventoryClient`, registered via `GUIManager`
| **R** | Recipe browser | `RecipesInventoryGUI` (filtered by discovery state)
| **C** | Crafting menu | `DebugCraftingMenu`/`CraftingGUI`
| **B** | Item browser (debug) | `DebugInventoryGrid`
| **T** | Tool Ring | `ToolRingGUI`
| **M** | Minimap | `Minimap`
| **P** | NookPhone (apps include map + shopping) | `NookPhoneGUI`
| **H** | Building/Construction UI | `BuildingGUI`
| **F2** | Premium Shop | `PremiumShopGUI`
| **\`** | Game Menu (inventory/settings/upgrades hub) | `GameMenu`
| **ESC** | Settings dialog | `SettingsController`
| **V** | Emote Wheel (new) | `EmoteWheel`
| **U** | Upgrades tab (inside Game Menu) | `GameMenu`
| **G** | Debug menu | `DebugManager`

## GUI & UX Architecture
### Core Components
* **`GUIManager`** – ensures only one major GUI is visible and pipes everything through `UniversalGUIPreset`.
* **`GUIContentManager`** – centralized copy/styling for Loading Screen, Inventory, Crafting, Shop, Dialogue, Notifications, Tutorials, Map, and the new Upgrades/Emote content blocks.
* **`GUIStyleUtil`** – helper introduced in this update to apply button/window/text presets and format copy placeholders (`{cost}`, `{level}`, etc.) consistently.
* **`UniversalGUIPreset`** – auto-injects cream/beige colors, rounded corners, and drop shadows into all ScreenGuis and children.

### Bringing a GUI online
1. Create the ScreenGui/Frame in `src/client/Modules/*`.
2. Require `GUIContentManager` + `GUIStyleUtil` and set attributes (`GUIStyleUtil.setTextContent(...)`, `applyButtonStyle`).
3. Register the object with `GUIManager` so it respects global exclusivity and ESC closing.
4. Add a keybind in `src/client/init.client.luau` via `KeybindManager`.

This update adopts the new pipeline in `GameMenu`, `RecipesInventoryGUI`, `EmoteWheel`, `Minimap`, and the upgrades dashboard so all copy/colors live in one file.

## Core Gameplay Systems
### Inventory & Pocket Upgrades
* Server `InventoryEvent` now exposes `GetInventoryUpgradeInfo` and `UpgradeInventory` actions.
* Shared `InventoryUpgrades` config defines four tiers (Starter → Pro Organizer) with bell costs and slot counts.
* `GameMenu`’s **Upgrades** tab shows current capacity, lets players buy the next upgrade, and surfaces error copy (max level, insufficient bells) straight from `GUIContentManager.Inventory.upgrades`.
* Server updates `player:SetAttribute("InventoryLevel")` and notifies the recipe discovery service whenever a new tier unlocks.

### Recipe Discovery
* New `RecipeDiscoveryService` tracks which DIY recipes each player has discovered (starter set + milestone unlocks).
* Client `RecipesInventoryGUI` subscribes to `RecipeDiscoveryEvent` so the recipe grid only shows unlocked entries while requesting more data via `RequestDiscovered`.
* Unlock triggers:
  * Pocket upgrades (levels 2–4) unlock additional furniture/tool DIYs.
  * Crafting station unlocks grant themed recipes (e.g., Forge → Ironwood set).
  * Server broadcasts toast data via `RecipesUnlocked`, prompting the client to refresh.

### Crafting Stations
* Shared `CraftingStationsConfig` enumerates Workbench (default), Forge, Cooking Stove, Sewing Table, and Potion Bench with bell costs + requirements.
* `CraftingEvent` gained `GetStationsStatus` and improved `UnlockStation` handling (inventory-level and prerequisite validation, bell deductions, recipe rewards via discovery service).
* `GameMenu` Upgrades tab displays each station card, lock status, and an Unlock button wired to the RemoteEvent.

### Emote Wheel & Social UX
* Press **V** to open the new Emote Wheel. Buttons play Roblox’s default R15 animations (wave, cheer, laugh, tilt, dance, clap) and immediately close the wheel.
* `GUIContentManager.Emotes` controls the title/hint copy while `GUIStyleUtil` keeps styling consistent with the ACNH palette.

### Map & Navigation
* The Minimap GUI now reads copy from `GUIContentManager` and stays in sync with island generation. Toggling (M key) refreshes the viewport and uses Tween animations for entrance/exit.

## Onboarding & Roadmap
### Current Flow
1. **Loading screen** – tips/assets pulled from `GUIContentManager.LoadingScreen`.
2. **Cutscene + Dialogue** – `DialogueGUI` handles Nook/Isabelle conversation before island selection.
3. **First steps** – Keybind Guide (disabled by default) and the Game Menu highlight the upgrades tab so players learn about pockets/stations before onboarding quests begin.

### Housing prerequisites
* **Server-gated placement** – `HomeBuildingService:RequestPlacement` now blocks the placement GUI unless the player has island data **and** the required tent materials (30 wood, 30 softwood, 15 stone). Clients receive a notification instead of entering placement when resources are missing.
* **Resource paths** – Tutorial rewards seed the starter kit, while `TreeShakingSystem` drops and quest progress (`QuestService` + `QuestHandlers`) keep resource gathering and onboarding quests aligned so players can actually collect what the home flow demands.

### Next Steps
* **Quest-driven discovery** – tie recipe unlock tags to quest completion handlers.
* **Crafting station props** – spawn actual station models when a player purchases them and auto-open the relevant GUI when interacting.
* **Controller/mobile UX** – extend `KeybindManager` to map to touch buttons for Minimap, Tool Ring, Emotes, and Upgrades.
* **Testing automation** – add Playtest scripts for upgrade purchase edge cases (insufficient bells, duplicate unlocks) and recipe filtering.

## Troubleshooting & References
* **Need a quick command?** Everything that used to live in `QUICK_REFERENCE.md`, `QUICK_START_GUIDE.md`, `SETUP_CHECKLIST.md`, and the `gold mine of info` folder is now represented above. The legacy files now simply link back here.
* **Static checks failing?** Run `aftman install` once, then re-run `bash tools/run_static_checks.sh`. Most issues are Stylua formatting or Selene lint errors.
* **Inventory or crafting remotes missing?** Verify `ReplicatedStorage.InventoryEvent`, `CraftingEvent`, and `RecipeDiscoveryEvent` exist; `init.server.luau` now creates all three during boot.
* **Where is feature X?**
  * `src/client/Modules/GameMenu.luau` – upgrades UI + station unlocks.
  * `src/server/init.server.luau` – inventory upgrade handling, recipe discovery hooks.
  * `src/server/RecipeDiscoveryService.luau` – authoritative recipe tracking.
  * `src/shared/inventory/InventoryUpgrades.luau` – slot/cost definitions.
  * `src/shared/crafting/CraftingStationsConfig.luau` – station metadata + requirements.
  * `src/shared/recipes/RecipeDiscoveryConfig.luau` – milestone → recipe mapping.
  * `src/client/Modules/EmoteWheel.luau` – emote GUI logic.

Happy building! 🌱
