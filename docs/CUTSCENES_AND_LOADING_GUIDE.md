# Cutscenes & Loading Screens - Quick Reference Guide

## Overview

Three new modules for creating cinematic experiences in your Animal Crossing game:

1. **CutsceneManager** - Camera control, transitions, sequence orchestration
2. **LoadingScreen** - ACNH-style loading with spinner, tips, progress
3. **OnboardingFlow** - Complete integration example (dialogue → island selection → loading → arrival cutscene → start-of-day → onboarding stepper)

---

## CutsceneManager

### Basic Usage

```lua
local CutsceneManager = require(path.to.CutsceneManager)
local cutscene = CutsceneManager.new()

-- Simple fade
cutscene:fade("in", 1) -- Fade to black over 1 second
cutscene:fade("out", 1) -- Fade from black over 1 second

-- Focus camera on something
local targetPart = workspace.TomNook.Head
cutscene:focusCamera(targetPart, 2) -- Move camera over 2 seconds

-- Reset camera to player
cutscene:resetCamera()
```

### Sequence System (Recommended)

Create a complete cinematic sequence:

```lua
cutscene:startSequence({
    {type = "fade", direction = "in", duration = 1},
    {type = "camera", target = workspace.TomNook.Head, duration = 2, offset = CFrame.new(0, 2, 5)},
    {type = "wait", duration = 2},
    {type = "camera", target = workspace.SpawnLocation, duration = 3},
    {type = "fade", direction = "out", duration = 1},
    {type = "reset"}
}, function()
    print("Cutscene complete!")
end)
```

### Step Types

| Type | Parameters | Description |
|------|-----------|-------------|
| `fade` | `direction` ("in"/"out"), `duration` | Fade to/from black |
| `camera` | `target` (Part/Model/CFrame), `duration`, `offset` | Move camera |
| `wait` | `duration` | Pause for X seconds |
| `callback` | `func` | Run custom function |
| `reset` | - | Return camera to player |

### Camera Targets

```lua
-- Focus on a Part
{type = "camera", target = workspace.Landmark, duration = 2}

-- Focus on a Model
{type = "camera", target = workspace.TomNook, duration = 2}

-- Focus on a CFrame (exact position)
{type = "camera", target = CFrame.new(0, 10, 0), duration = 2}

-- Focus with custom offset (move camera back/up)
{type = "camera", target = workspace.Landmark, duration = 2, offset = CFrame.new(0, 5, 10)}
```

---

## LoadingScreen

### Basic Usage

```lua
local LoadingScreen = require(path.to.LoadingScreen)

-- Show loading screen
LoadingScreen.show("Loading your island...")

-- Update progress (optional)
LoadingScreen.setProgress(0.5) -- 50%
LoadingScreen.setStatus("Planting trees...")

-- Hide when done
LoadingScreen.hide()
```

### With Progress Bar

```lua
-- Enable progress bar
LoadingScreen.show("Loading island...", true) -- true = show progress bar

-- Update progress
for i = 0, 100, 10 do
    LoadingScreen.setProgress(i / 100)
    task.wait(0.3)
end

LoadingScreen.hide()
```

### Quick Helper

```lua
-- Automatically show/hide around a task
LoadingScreen.showDuring("Loading...", function()
    -- Do loading work here
    task.wait(2)
    -- Loading screen will auto-hide when done
end)
```

### Features

- **Animated Nook Leaf spinner** - Rotates continuously
- **Random tips** - Shows ACNH-style tips like "Did you know? Shake trees for furniture!"
- **Optional progress bar** - 0-100% with smooth tweening
- **ACNH styling** - Cream background, brown text, teal accents

---

## Complete Onboarding Example

```lua
local OnboardingFlow = require(path.to.OnboardingFlow)

-- Start complete onboarding flow:
-- 1. Tom Nook dialogue
-- 2. Island selection
-- 3. Loading screen with progress
-- 4. Arrival cutscene
-- 5. Start-of-day screen
-- 6. OnboardingController stepper
OnboardingFlow.start()

-- Or test individual systems:
OnboardingFlow.testLoadingScreen()
OnboardingFlow.testCutscene()
```

---

## Dialogue Handling (NookPhone)

`OnboardingFlow` now routes onboarding dialogue through the NookPhone UI (with a lightweight overlay fallback if the phone isn't ready). You only need to call:

```lua
OnboardingFlow.start()
```

---

## Common Patterns

### Island Arrival

```lua
-- Player arrives at new island
LoadingScreen.show("Loading island...", true)

-- Simulate loading
task.spawn(function()
    LoadingScreen.setProgress(0.2)
    LoadingScreen.setStatus("Generating terrain...")
    task.wait(1)
    
    LoadingScreen.setProgress(0.6)
    LoadingScreen.setStatus("Planting trees...")
    task.wait(1)
    
    LoadingScreen.setProgress(1.0)
    LoadingScreen.setStatus("Almost ready...")
    task.wait(0.5)
    
    LoadingScreen.hide()
    
    -- Play arrival cutscene
    local cutscene = CutsceneManager.new()
    cutscene:startSequence({
        {type = "fade", direction = "out", duration = 1.5},
        {type = "camera", target = workspace.TownSquare, duration = 3},
        {type = "reset"}
    })
end)
```

### Shop Transaction

```lua
-- Player buys expensive item
local cutscene = CutsceneManager.new()

cutscene:startSequence({
    {type = "fade", direction = "in", duration = 0.5},
    {type = "camera", target = workspace.NooksCranny, duration = 2},
    {type = "wait", duration = 1},
    {type = "callback", func = function()
        -- Process transaction
        print("Item purchased!")
    end},
    {type = "fade", direction = "out", duration = 0.5},
    {type = "reset"}
})
```

### Museum Donation

```lua
-- Dramatic reveal of new fossil
local cutscene = CutsceneManager.new()

cutscene:startSequence({
    {type = "camera", target = workspace.Museum.Exhibit, duration = 2},
    {type = "wait", duration = 3}, -- Let player admire it
    {type = "camera", target = workspace.Blathers.Head, duration = 1.5},
    {type = "reset"}
}, function()
    -- Show dialogue using your custom overlay
end)
```

---

## Files Created

1. **`src/client/Modules/CutsceneManager.luau`** - Camera control & transitions
2. **`src/client/Modules/LoadingScreen.luau`** - ACNH-style loading screens
3. **`src/client/Modules/OnboardingFlow.luau`** - Complete integration example

---

## Next Steps

1. **Create Island Selection GUI** in Roblox Studio
2. **Test cutscenes** with `OnboardingFlow.testCutscene()`
3. **Test loading screen** with `OnboardingFlow.testLoadingScreen()`
4. **Integrate with your N key** to start onboarding flow

---

## Debugging

All modules have extensive console logging:

```
[CutsceneManager] 🎬 Starting sequence with 5 steps
[CutsceneManager] 🎥 Focusing camera on target over 2.0s
[LoadingScreen] 📺 Showing: 'Loading your island...'
[LoadingScreen] 📊 Progress: 50%
[OnboardingFlow] 🎬 Starting onboarding sequence...
```

Check console for step-by-step progress!

---

## Tips

- **Always reset camera** after cutscenes with `{type = "reset"}`
- **Use fade transitions** between major scene changes
- **Progress bars** are optional - use for long loads only
- **Test sequences** in Studio before production
- **Camera offsets** help create dynamic angles (e.g., `CFrame.new(5, 3, 5)` for over-shoulder)

Enjoy creating cinematic experiences! 🎬🎮
