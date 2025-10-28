```mermaid
graph TD
  S0[Boot] --> S1[Title / New Game]
  S1 --> S2[Profile Create / Select]
  S2 --> S3[Avatar Creator]
  S3 --> S4[Intro Cinematic (Skippable)]
  S4 --> S5[Tutorial A: Move & Camera]
  S5 --> S6[Tutorial B: Interact & Inventory]
  S6 --> S7[Tutorial C: Gather → Craft → Place]
  S7 --> S8[Meet Key NPC (Dialogue)]
  S8 --> S9[Unlock Phone + Quest Log]
  S9 --> S10[Place Tent/Home]
  S10 --> S11[FTUE Complete → Day 1 HUD]

  %% Optional/Exit paths
  S4 -->|Skip| S5
  S5 -->|Pause/Settings| P[Settings Modal]
  S6 -->|Open Inventory| I[Inventory Modal] --> S6
  S7 -->|Enter Placement| M[Placement Mode] --> S7
  S8 -->|Open Shop (optional)| J[Shop Modal] --> S8
  P --> S5
  I --> S6
  J --> S8
```
