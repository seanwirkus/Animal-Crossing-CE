# Game Loop & Post-Onboarding Flow

This document describes the assembled core game loop for Animal Crossing CE and
how a player moves from first launch into ongoing play.

## The full player journey

```
Join ─▶ Onboarding ─▶ First-Day Cutscene ─▶ ┌──────── CORE LOOP ────────┐
        (one time)     (one time)            │                          │
                                             │   Gather materials       │
                                             │   (axe / shovel / shake) │
                                             │            │             │
                                             │            ▼             │
                                             │   Craft at DIY bench     │
                                             │   Fish & catch bugs      │
                                             │            │             │
                                             │            ▼             │
                                             │   Complete quests        │
                                             │   (Objective Tracker)    │
                                             │            │             │
                                             │            ▼             │
                                             │   Claim Bells + Miles    │
                                             │            │             │
                                             │            ▼             │
                                             │   Spend: shop, inventory │
                                             │   upgrades, decorate     │
                                             │            │             │
                                             └────────────┘─────────────┘
                                                 (new daily quest rolls in)
```

## Phase 1 — Onboarding (one time, new players only)

Driven by `OnboardingService` (server) and `OnboardingFlow` (client):

1. Tom Nook welcome dialogue (NookPhone dialogue sequence).
2. Island selection.
3. Loading screen.
4. Arrival cutscene (camera pan over spawn).
5. Start-of-day handoff into the `OnboardingController` stepper
   (Welcome → Movement → Build Home → Complete).

The server grants the **starter kit** (flimsy + basic tools, 1000 Bells,
500 Miles) and marks `hasCompletedTutorial` so onboarding never repeats.

## Phase 2 — First-Day Cutscene (the "what now?" bridge)

`OnboardingFlow.completeOnboarding()` now hands off into
`FirstDayCutscene.play()` instead of dead-ending.

`FirstDayCutscene` (client) uses the upgraded `CutsceneManager` to:

- Apply cinematic **letterbox** bars.
- **Tour island landmarks** with the camera (Resident Services, the DIY
  workbench, the airport/dock, your tent) — whichever exist in the world.
- Have **Isabelle** explain the core loop in cinematic **dialogue**
  (gather → craft → fish → complete quests → earn currency → upgrade).
- Hand control back, **reveal the Objective Tracker**, and **open the quest
  log** so the player's next action is unambiguous.

It plays once per session; because onboarding only runs once, returning players
never replay it.

## Phase 3 — The Core Loop

The loop is kept visible and rewarding by three connected systems:

### Quests (`QuestService` / `QuestHandlers` / `QuestData`)
- New players are seeded with tutorial quests (fishing, crafting, collect fruit,
  chop trees, gather stone) plus a random daily quest.
- Game events (chopping, fishing, crafting, collecting, digging) increment quest
  progress through `QuestHandlers`.
- **Claiming a quest now actually pays out.** `QuestService:setRewardGranter`
  is wired in `init.server.luau` to grant Bells, Miles, and item rewards via
  `CurrencyManager` and the inventory system. (Previously the server fired
  `RewardsClaimed` but never granted anything — the loop had no payoff.)
- Finishing a **daily** quest automatically rolls a fresh daily, so the loop
  never runs dry.

### Objective Tracker (`ObjectiveTracker`, client HUD)
- An always-visible card (mid-left of the screen) that surfaces the single most
  relevant objective from the player's quest list.
- Priority: a quest that's **ready to claim** > tutorial > story > daily >
  weekly > milestone, breaking ties by progress.
- Shows the quest name, a contextual hint, and a live progress bar fed by
  `QuestEvent / SyncQuests`.
- Revealed by the first-day cutscene; auto-shown for returning players once
  their quests sync; refreshed whenever the player opens the quest log.

### Spending & progression
Earned currency feeds back into the loop via existing systems:
- **Nook Shopping** / shop for furniture and resources.
- **Inventory upgrades** (more slots) purchased with Bells.
- **Crafting & building** to decorate and expand the island.
- **Daily challenges** (`DailyChallengeService`) for extra Bells/Miles.

## Key code touch points

| Concern | File |
| --- | --- |
| Cinematic engine (camera, fade, letterbox, dialogue) | `src/client/Modules/CutsceneManager.luau` |
| Post-onboarding cinematic | `src/client/Modules/FirstDayCutscene.luau` |
| "What to do next" HUD | `src/client/Modules/ObjectiveTracker.luau` |
| Onboarding → first-day handoff | `src/client/Modules/OnboardingFlow.luau` |
| Client wiring / tracker init | `src/client/init.client.luau` |
| Quest reward payout + daily reroll | `src/server/init.server.luau` |
| Reward granter hook | `src/server/QuestService.luau` |

## Extending the loop

- **More story beats:** add cutscenes by composing `CutsceneManager` step lists
  (`fade`, `letterbox`, `camera`, `dialogue`, `wait`, `callback`, `reset`).
- **More quests:** add entries to `QuestData` (tutorial/daily/weekly/milestone);
  the tracker and reward payout pick them up automatically.
- **New objective sources:** anything that calls `QuestHandlers.on*` will drive
  tracker progress with no extra UI work.
