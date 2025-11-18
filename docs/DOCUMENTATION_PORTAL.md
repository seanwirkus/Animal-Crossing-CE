# Documentation Portal

This portal consolidates the most important guides that were previously scattered across dozens of Markdown files. Treat it as a table of contents for the entire repository: every category below lists the authoritative docs plus a short note describing when to open them.

## How to Use This Portal
1. **Pick the topic you care about** (GUI polish, island generation, onboarding, etc.).
2. **Jump into the linked Markdown file** – each bullet links to an existing deep-dive so we avoid duplicating content.
3. **Mark gaps as TODOs in this file** whenever you add a new doc so the next developer can find it.

> Tip: The README already covers day-to-day workflows. Use this portal when you need historical context or system-specific reference material.

## Getting Started & Planning
- `PROJECT_PLAN.md` – master production schedule, feature sequencing, and dependency map.
- `GAME_LAUNCH_PLAN.md` – vertical slice launch checklist plus monetization beats.
- `IMPLEMENTATION_SUMMARY.md` / `IMPLEMENTATION_TRACKER.md` – audit trail of features that are complete vs. in-progress.
- `SETUP_CHECKLIST.md`, `QUICK_START_GUIDE.md`, `STARTUP_GUIDE.md` – workstation setup, Rojo build commands, and CI tooling.
- `COMPLETE_SYSTEM_IMPLEMENTATION_PLAN.md` – exhaustive backlog of every gameplay system still outstanding.

## GUI & UX
- `GUI_CONTENT_MANAGEMENT_README.md` – how `GUIContentManager` stores copy, styles, and layouts (now referenced by Inventory + NookPhone).
- `GUI_AUDIT_AND_IMPROVEMENTS.md` – punch list of every GUI that needs polish or responsive fixes.
- `ANIMAL_CROSSING_STYLE_GUIDE.md` – palette, fonts, spacing, and iconography used by the ThemeProvider.
- `UNIVERSAL_GUIPRESET` docs (`docs/GUI_AUDIT...` + README section) – hooking GUIs into the global preset pipeline.
- `NookPhone` & `GUIManager` notes (`docs/CONTEXT_MENU_GUIDE.md`, `docs/CONTEXT_MENU_INVENTORY_INTEGRATION.md`) – context menu wiring, GUI exclusivity rules, and layout expectations.

## Inventory, Crafting, & Economy
- `INVENTORY_ITEM_GUIDE.md` – server/client commands for awarding items, slot limits, and upgrade flow.
- `TOOL_RING_GUIDE.md` – explains how the Tool Ring reads from inventory state.
- `ERROR_FIXES_AUDIT.md` – running list of bug fixes applied to inventory & currency flows.
- `DIYWorkbenchGUI.luau` and `docs/CONTEXT_MENU_GUIDE.md` – references for crafting UI, recipe browsers, and context menus.

## Island Generation & World Systems
- `docs/AI_ISLAND_GENERATION_GUIDE.md`, `NEW_ISLAND_GENERATION_SYSTEM.md`, `ISLAND_GENERATION_GUI_SETUP.md` – procedural island plans, GUI controls, and test harnesses.
- `HOME_BUILDING_IMPLEMENTATION_GUIDE.md`, `BUILDING_SERVICE` docs – structure placement, lot validation, and save data expectations.
- `MODEL_PLACEMENT_GUIDE.md`, `TREE_SHAKING` / `FOSSIL` documents – spawn logic for interactable props.
- `GAME_LAUNCH_PLAN.md` (Day-by-day tasks) – includes worldbuilding beats (shops, visitors, museum hooks).

## Reference Data & Tooling
- `docs/SPRITESHEET_ANALYSIS_SUMMARY.md` – sprite manifest + coverage metrics.
- `tools/` folder READMEs – scripts for importing Nookipedia data, sprite analyzers, and remote manifest generation.
- `nookipedia_items.json`, `nookipedia_characters.json`, `sample_items.csv` – raw datasets consumed by ItemDataFetcher.
- `scripts/` utilities – lint wrappers, Rojo build helpers, and deployment scripts.

## TODO / Gaps
- [ ] Merge onboarding docs (`ONBOARDING_FLOW`, `CUTSCENES_AND_LOADING_GUIDE.md`) into a single narrative once the flow stabilizes.
- [ ] Document Premium Shop + monetization hooks after the Robux products are finalized.
- [ ] Add a dedicated testing/QA section that summarizes `ERROR_FIXES_AUDIT.md`, automated scripts, and manual test plans.

Keeping this portal up to date lets us retire duplicate documents over time without losing hard-won knowledge.
