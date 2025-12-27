# Onboarding Follow-Up Plan

This plan focuses on making the starter kit reliable, calming home placement, and removing reliance on external tent meshes. It lays out immediate checks plus the next slices of work to stabilize onboarding.

## Current State (what just landed)
- Starter kit waits for inventory attributes before granting and retries instead of silently failing.
- Starter kit retries use exponential backoff and can still grant even if the tutorial UI is skipped.
- Tent placement uses an in-house primitive template (no OBJ dependencies) and smoother ghost movement with grid snapping.
- Onboarding UI lets players proceed even if they place their tent later; auto-completes once a home is registered.

## Quick Validation Steps
1. Join as a brand-new player; confirm inventory attributes appear before tools are granted.
2. Verify starter tools arrive (axe, shovel, fishing rod, net, slingshot) and bells/miles grant fires.
3. Start placement: confirm ghost snaps to a ~2-stud grid, keeps last valid spot, and rotation increments by 45°.
4. Cancel placement and ensure movement speed restores to 16.
5. Place tent once; confirm server rejects second placement attempts and sends HomeDataUpdate.
6. Complete onboarding without placing: ensure flow reaches “All Set!” step.

## Next Work Items
- **Starter Kit Reliability**
  - Add telemetry counters for grant attempts, successes, and retries.
  - Surface a toast if a retry is queued (client) and log to server console with player + wait duration.
  - Add a small exponential backoff (up to 3 attempts) to avoid hammering inventory init.
- **Placement UX Polish**
  - Add a ground-aligned hover decal to show exact footprint (10×10 studs) with red/green state.
  - Allow Q/E to rotate ±15° for finer control while keeping R for 45° increments.
  - Add “center to player” hotkey to reduce edge-of-island jitter.
  - Clamp placement to island bounds client-side (mirror server rule) to avoid confusing rejections.
- **Content Compliance**
  - Replace any remaining tent/object references to external meshes with procedural templates in HomeTemplates (e.g., future SmallHouse).
  - Add a simple color palette config for tents so art can tweak without touching scripts.
- **Persistence & Recovery**
  - When placement fails server-side, push the reason back to the client and keep the ghost open instead of closing.
  - On reconnect, re-open placement if a pending placement flag exists and no home is recorded.
- **QA Checklist Expansion**
  - Write a deterministic Studio test harness that spawns a fake island + terrain patch for placement regression runs.
  - Add a short smoke list for manual QA (join, grant, place, skip, rejoin).

## Dependencies / Coordination
- Needs telemetry/logging endpoints (or temporary print hooks) to record starter-kit retries.
- Requires small art input for tent color palette defaults (optional).
- Client-side clamp to island bounds needs island center/size from PlayerIslandService exposed via a RemoteFunction.

## Definition of Done for this slice
- Starter kit success rate > 99% on first attempt; retries surface a visible toast.
- Placement ghost never “flies” when invalid; keeps stable last-valid position and clear footprint.
- Players can always finish onboarding without placing immediately, but HomeDataUpdate still advances the step when they do place later.
