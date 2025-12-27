# Debug Mode Reference

## Quick Start for Testing

The game has been updated with a **debug mode** that skips the cutscene and loading screen for **much faster testing**.

### Current Debug Setting

**File**: `src/client/Modules/OnboardingFlow.luau` (line 615)

```lua
local skipCutsceneAndLoading = true  -- Currently ENABLED
```

---

## How to Toggle

### Enable Fast Testing (CURRENT)
```lua
local skipCutsceneAndLoading = true
```
- ✅ Skips cutscene (saves ~10 seconds)
- ✅ Skips loading screen (saves ~3 seconds)
- ✅ Direct to gameplay (~5 seconds total startup)
- **Best for**: Bug fixing, testing game mechanics

### Disable for Full Experience
```lua
local skipCutsceneAndLoading = false
```
- ✅ Shows airplane arrival cutscene
- ✅ Shows loading screen with plane animation
- ✅ Better narrative experience (~18 seconds total startup)
- **Best for**: Demo, final testing, visual verification

---

## What Each Mode Does

### Fast Testing Mode (skipCutsceneAndLoading = true)
1. Player joins
2. Island loads immediately
3. Player spawned on island
4. Start-of-day screen shown
5. Onboarding begins
6. **Total startup**: ~5 seconds

```
Player Join
    ↓
Load Island (skip cutscene + loading screen)
    ↓
Show Start-of-Day Screen
    ↓
Begin Onboarding Tutorial
```

### Full Experience Mode (skipCutsceneAndLoading = false)
1. Player joins
2. Airplane arrival cutscene plays (10 seconds)
3. Loading screen shows with plane animation (3 seconds)
4. Island loads
5. Player spawned on island
6. Start-of-day screen shown
7. Onboarding begins
8. **Total startup**: ~18 seconds

```
Player Join
    ↓
Play Cutscene (fade, camera pans, etc.)
    ↓
Show Loading Screen (plane flying in)
    ↓
Load Island
    ↓
Show Start-of-Day Screen
    ↓
Begin Onboarding Tutorial
```

---

## Quick Fix Guide

When you're ready to **disable debug mode and use full experience**, change line 615:

```lua
-- BEFORE (Fast Testing)
local skipCutsceneAndLoading = true

-- AFTER (Full Experience)
local skipCutsceneAndLoading = false
```

Then press **F5** to reload the game.

---

## Testing Checklist

### With Debug Mode Enabled ✅
- [ ] Game starts within 5 seconds
- [ ] Island loads properly
- [ ] Player spawned at spawn point (0, 75, 0)
- [ ] Starter kit given (check with E key)
- [ ] Onboarding shows correctly
- [ ] Can build home via Nook Phone
- [ ] Can gather resources
- [ ] Can craft items
- [ ] Can fish

### With Debug Mode Disabled ✅
- [ ] Cutscene plays (10 seconds)
- [ ] Camera pans correctly
- [ ] Loading screen shows
- [ ] Island loads after loading screen
- [ ] Rest of gameplay works normally

---

## Current Game Status

✅ **Ready for Fast Testing**
- Cutscene and loading screen temporarily disabled
- Game starts in ~5 seconds instead of ~18 seconds
- Faster iteration for bug fixes

🎬 **Cutscene Ready (when needed)**
- Cutscene code implemented and working
- Loading screen code implemented and working
- Can be re-enabled anytime by changing one line

---

## Related Files

- `src/client/Modules/OnboardingFlow.luau` - Lines 614-631 (main toggle)
- `src/client/Modules/CutsceneManager.luau` - Handles arrival cutscene
- `src/client/Modules/LoadingScreen.luau` - Handles loading screen

---

**Status**: Debug mode active for faster testing
**Last Updated**: December 26, 2025
