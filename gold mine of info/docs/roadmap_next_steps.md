# Shipping Roadmap Overview

This roadmap turns the high-level backlog into a practical set of milestones you can execute in order. Each milestone builds on the previous one and should be tackled sequentially unless you have a larger team that can parallelize work.

## Milestone 1 – Build & Content Pipeline
- [ ] Update `README.md` contributor docs with a release-ready Rojo workflow.
- [ ] Implement the spreadsheet importer described in `docs/data_pipeline.md` to regenerate `src/shared/Data/GeneratedItems.luau` before every publish.
- [ ] Fill out `src/shared/AssetManifest.luau` (and override folders) with real asset IDs so artists can swap content without touching scripts.

**Goal:** Anyone on the team can build, test, and publish a release candidate without manual asset hacking.

## Milestone 2 – Core Gameplay & Persistence
- [x] Replace debug hooks in `src/server/Services/ToolService.luau` so tools spawn resources, update `InventoryService`, and ping `QuestService`.
- [ ] Build real island terrain, hotspots, and `CollectionService` tags for schedules/quests/gathering nodes.
- [ ] Add DataStore saves for balances and inventory snapshots via `EconomyService`/`InventoryService`.

**Goal:** Players can perform all core loops and retain progress across sessions.

## Milestone 3 – Player Onboarding & Pillars
- [ ] Produce ceremony assets/UI from `docs/island_onboarding.md` and wire them through `OnboardingService`.
- [ ] Ship roadmap pillars in order: `WorldStateService`, décor, museum collections, and live ops hooks.
- [ ] Ensure each new system feeds the earn/spend/upgrade loop in the design plan.

**Goal:** A new player has a clear Day 0 experience and long-term goals that motivate retention.

## Milestone 4 – Monetization & Live Ops
- [ ] Extend `EconomyService` to process developer products/game passes and expose premium bundles in UI.
- [ ] Add spend sinks that consume Bells/Miles (décor upgrades, facility unlocks, etc.).
- [ ] Layer in limited-time events and bundles through the live-ops scheduler.

**Goal:** Introduce ethical monetization loops that align with the cozy pacing and give reasons to return.

## Milestone 5 – Original Content & Compliance
- [ ] Follow `docs/npc_content_pipeline.md` to replace placeholder villagers, furniture, and props with original assets.
- [ ] Populate `AssetManifest` overrides with your branded Roblox asset IDs.
- [ ] Move the Nookipedia API key out of `src/shared/Config.luau` into secure storage (e.g., Roblox secrets service).

**Goal:** Ship legally-compliant, original content without exposing secrets.

## Milestone 6 – QA & Launch Checklist
- [ ] Build regression test suites for services and onboarding flows.
- [ ] Run full playtests that cover Day 0 through late-game loops.
- [ ] Prepare store listing, community channels, and support workflows.

**Goal:** The game is stable, marketable, and ready for a public launch.

---

**Tip:** Treat each milestone as a mini-project with a dedicated branch and checklist. Share progress with your team or partners weekly so issues are caught early.
