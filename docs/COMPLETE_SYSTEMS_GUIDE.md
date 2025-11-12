# 🎮 Complete Systems Guide - Animal Crossing CE

## Overview

This guide documents all the newly implemented systems for crafting, island generation, player onboarding, and model management.

---

## 🔨 DIY Workbench System

### What It Does
- Allows players to interact with workbench models in the world
- Opens a full-featured crafting GUI when players approach and interact
- Manages workbench placement and proximity prompts

### Files Created
- **Server**: `src/server/DIYWorkbenchService.luau`
- **Client**: `src/client/Modules/CraftingGUI.luau`

### How It Works

1. **Server Side** (`DIYWorkbenchService.luau`):
   - Scans workspace for DIYWorkBench models
   - Adds ProximityPrompts to workbenches
   - Fires remote event to open crafting GUI when player interacts
   - Can place new workbenches programmatically

2. **Client Side** (`CraftingGUI.luau`):
   - Beautiful Animal Crossing-themed crafting interface
   - Shows recipe list with materials required
   - Displays player's inventory to check if they have materials
   - Color-coded indicators (green = can craft, red = cannot craft)
   - Sends crafting requests to server
   - Updates automatically when inventory changes

### Usage

**To place a workbench in Studio:**
1. Add DIYWorkBench model template to ReplicatedStorage
2. Clone it to Workspace at desired location
3. Service will automatically add ProximityPrompt and make it functional

**To place a workbench via script:**
```lua
local workbenchService = DIYWorkbenchService.new()
workbenchService:initialize()
workbenchService:placeWorkbench(Vector3.new(0, 10, 0), 0) -- position, rotation
```

**For players:**
- Walk up to any DIYWorkBench in the world
- Press the interaction button when prompt appears
- Crafting GUI opens automatically
- Select recipe, check materials, click "Craft"

---

## 🏝️ Player Island System

### What It Does
- Each player gets their own unique island
- Islands are spaced apart in the world (1000 studs between islands)
- Generates terrain, trees, rocks, and holes for each island
- Saves island data to DataStore
- Spawns players on their own island when they join

### Files Created
- **Server**: `src/server/PlayerIslandService.luau`
- **Data**: Saved in `PlayerIslands_v1` DataStore

### How It Works

1. **Player Joins**:
   - Service checks if player has existing island data in DataStore
   - If new player: Creates new island, assigns unique position
   - If returning player: Loads saved island data

2. **Island Generation**:
   - Creates terrain using noise-based height generation
   - Adds grass terrain with sand beaches at edges
   - Places 10-20 trees randomly across island
   - Places 5-8 rocks
   - Places starter DIY workbench near center

3. **Island Structure**:
   ```
   Workspace/
   └── PlayerIslands/
       └── Island_[userId]/
           ├── Tree (multiple)
           ├── Rock (multiple)
           ├── Hole (multiple)
           ├── DIYWorkBench
           └── Buildings/
               └── TentHouse (after onboarding)
   ```

4. **Saving**:
   - Saves island center position
   - Saves all tree positions and types
   - Saves all rock positions
   - Saves all hole positions (from digging)
   - Saves building positions and types
   - Saves tutorial progress

### Island Data Structure
```lua
{
    userId = 12345,
    center = { X = 0, Y = 50, Z = 0 },
    size = { X = 200, Y = 50, Z = 200 },
    createdAt = 1699999999,
    lastVisited = 1699999999,
    
    trees = {
        { X = 10, Y = 55, Z = 20, type = "Oak" },
        -- ...
    },
    rocks = {
        { X = 30, Y = 52, Z = 40 },
        -- ...
    },
    holes = {
        { X = 5, Y = 51, Z = 5 },
        -- ...
    },
    buildings = {
        { type = "TentHouse", X = 0, Y = 55, Z = 0, rotation = 0 },
        -- ...
    },
    
    hasCompletedTutorial = false,
    hasBuiltHome = false,
}
```

### API Functions

**Get player's island:**
```lua
local islandData = PlayerIslandService:getPlayerIsland(userId)
```

**Add tree to island:**
```lua
PlayerIslandService:addTreeToIsland(userId, Vector3.new(10, 50, 20), "Oak")
```

**Add hole to island:**
```lua
PlayerIslandService:addHoleToIsland(userId, Vector3.new(5, 50, 5))
```

**Save island:**
```lua
PlayerIslandService:saveIsland(userId)
```

---

## 📚 Onboarding/Tutorial System

### What It Does
- Guides new players through their first experience
- Teaches basic controls and mechanics
- Helps players build their first home
- Marks tutorial completion in island data
- Awards starter currency

### Files Created
- **Server**: `src/server/OnboardingService.luau`
- **Client**: `src/client/Modules/OnboardingController.luau`

### Tutorial Steps

1. **Welcome**: Greets player to their new island
2. **Movement**: Teaches WASD movement and camera controls
3. **Find Workbench**: Directs player to locate DIY workbench
4. **Craft Tools**: Encourages crafting basic tools
5. **Build Home**: Guides player to build their first tent
6. **Complete**: Congratulates player and awards rewards

### How It Works

1. **Server Side** (`OnboardingService.luau`):
   - Checks if player needs tutorial when they join
   - Fires remote event to start tutorial UI on client
   - Listens for tutorial completion event
   - Handles home building request
   - Marks tutorial complete in island data
   - Awards starter rewards (1000 bells, 500 miles)

2. **Client Side** (`OnboardingController.luau`):
   - Creates beautiful tutorial UI overlay
   - Shows step-by-step instructions
   - Provides "Next" buttons to progress
   - Allows skipping tutorial
   - Sends completion/build home requests to server

### UI Design
- Bottom-centered tutorial box
- Animal Crossing themed colors (cream, brown, orange)
- Large icon (🏝️) for visual appeal
- Clear instructional text
- Action buttons (Next, Skip, Build Home, etc.)

### Remote Events
- `StartOnboarding`: Server → Client (starts tutorial)
- `TutorialComplete`: Client → Server (marks complete)
- `BuildPlayerHome`: Client → Server (builds tent)

---

## 📦 Model Placement System

### Complete Documentation
See `docs/MODEL_PLACEMENT_GUIDE.md` for full details.

### Quick Reference

**Templates (ReplicatedStorage):**
- `OakTree` - Tree model
- `DIYWorkBench` - Workbench model
- `Rock` - Rock model
- `TentHouse` - Player starting home
- `Buildings/` - All building templates

**Active Instances (Workspace):**
- `PlayerIslands/Island_[userId]/` - Per-player islands
- `NPCs/` - Active NPC models
- `GeneratedObjects/` - Procedurally placed objects

**Key Principle:**
- Templates in ReplicatedStorage → Clone to Workspace
- Save only data (positions, types) → Regenerate from templates on load

---

## 🔗 System Integration

### Initialization Order

1. **Server** (`src/server/init.server.luau`):
   ```lua
   -- 1. Initialize Workbench Service
   local workbenchService = DIYWorkbenchService.new()
   workbenchService:initialize()
   
   -- 2. Initialize Island Service
   local islandService = PlayerIslandService.new()
   islandService:initialize()
   
   -- 3. Initialize Onboarding (needs island service)
   local onboardingService = OnboardingService.new()
   onboardingService:initialize(islandService)
   ```

2. **Client** (`src/client/init.client.luau`):
   ```lua
   -- 1. Initialize Crafting GUI
   local craftingGUI = CraftingGUIModule.new()
   
   -- 2. Initialize Onboarding Controller
   local onboardingController = OnboardingControllerModule.new()
   ```

### Data Flow

**Crafting:**
```
Player → ProximityPrompt → Server → RemoteEvent → Client → CraftingGUI
Player clicks Craft → CraftingEvent → Server validates → Updates inventory
Server syncs inventory → InventoryEvent → Client updates display
```

**Island Generation:**
```
Player joins → PlayerIslandService checks DataStore
New player → Generate island → Place in workspace → Spawn player
Returning player → Load data → Regenerate island → Spawn player
```

**Tutorial:**
```
New player joins → OnboardingService checks tutorial status
Not completed → StartOnboarding RemoteEvent → OnboardingController
Player completes steps → TutorialComplete → Server marks complete
Player builds home → BuildPlayerHome → Server places tent
```

---

## 🎯 Required Models

To make the system work, you need these models in ReplicatedStorage:

### Essential:
- [ ] **OakTree** - Tree model with trunk and leaves
- [ ] **DIYWorkBench** - Workbench table with tools
- [ ] **Rock** - Rock model (can use built-in fallback if missing)

### For Tutorial/Onboarding:
- [ ] **TentHouse** - Player starter home (tent model)

### Optional (can use fallbacks):
- [ ] **Buildings/** folder with:
  - WoodenHouse
  - NooksCranny
  - Museum
  - ResidentServices

### Creating Simple Models

**If you don't have these models yet**, the system has fallbacks:

1. **Simple Tree** (automatic fallback):
   - Brown trunk (Part)
   - Green ball leaves (Part, Ball shape)

2. **Simple Workbench** (automatic fallback):
   - Wooden table top
   - 4 legs
   - Decorative hammer

3. **Simple Tent** (automatic fallback):
   - Red wedge tent body
   - Brown floor
   - Orange door flap

---

## 🚀 Testing the Systems

### Test Crafting:
1. Place a DIYWorkBench model in workspace
2. Join game as player
3. Walk up to workbench
4. Interact with prompt
5. Crafting GUI should open with recipes

### Test Island Generation:
1. Clear any existing player island data (optional)
2. Join game as new player
3. Should spawn on unique island
4. Island should have terrain, trees, rocks
5. Should find a workbench near center

### Test Tutorial:
1. Join as new player (without completed tutorial)
2. Tutorial UI should appear at bottom
3. Follow through steps
4. Click "Build Home" at end
5. Tent should appear on island
6. Tutorial should complete

---

## 🐛 Troubleshooting

### Workbench doesn't respond:
- Check that model is named "DIYWorkBench" exactly
- Check that ProximityPrompt was added
- Check server output for DIYWorkbenchService logs

### Island not generating:
- Check that terrain generation is enabled
- Check for errors in PlayerIslandService
- Verify DataStore is accessible (not in Studio without API access)

### Tutorial not starting:
- Check that island data has `hasCompletedTutorial = false`
- Check OnboardingService initialization
- Check remote events exist in ReplicatedStorage/Remotes

### Crafting not working:
- Check that CraftingSystem is initialized
- Check that item data is loaded
- Verify player has materials in inventory

---

## 📝 Next Steps

### Phase 1: Complete Core Systems ✅
- [x] DIY Workbench interaction
- [x] Crafting GUI
- [x] Player Island generation
- [x] Island persistence
- [x] Onboarding/tutorial

### Phase 2: Enhance Systems
- [ ] Add more tree varieties (Pine, Palm, Fruit)
- [ ] Add flower generation
- [ ] Implement building upgrade system
- [ ] Add furniture placement system
- [ ] Create more building types

### Phase 3: Gameplay Features
- [ ] Tool system integration (fishing, bug catching, digging)
- [ ] Currency rewards for activities
- [ ] NPC visitors
- [ ] Island customization (paths, fences)
- [ ] Multiplayer island visiting

### Phase 4: Polish
- [ ] Sound effects
- [ ] Particle effects
- [ ] Animations
- [ ] Mobile support
- [ ] Performance optimization

---

## 🎨 Customization

### Island Size:
Edit `PlayerIslandService.luau`:
```lua
local ISLAND_SIZE = Vector3.new(200, 50, 200) -- Change dimensions
```

### Island Spacing:
```lua
local ISLAND_SPACING = 1000 -- Distance between islands
```

### Tree/Rock Count:
In `generateInitialTrees()` and `generateInitialRocks()`:
```lua
local treeCount = math.random(10, 20) -- Change range
local rockCount = math.random(5, 8)   -- Change range
```

### Tutorial Steps:
Edit `OnboardingController.luau` to add/remove/modify steps.

---

## 📞 Support

If you encounter issues:
1. Check server output for error messages
2. Check that all required models exist
3. Verify DataStore is accessible
4. Check remote events are created
5. Test in both Studio and live server

---

**Last Updated**: November 11, 2025  
**Systems Version**: 1.0  
**Status**: Production Ready ✅

