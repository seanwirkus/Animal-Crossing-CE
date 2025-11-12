# Complete System Implementation Plan

## Overview
This document outlines the complete implementation plan for:
1. DIYWorkBench usability
2. Model organization (ReplicatedStorage vs Workspace)
3. Complete crafting system
4. Home building for new players
5. Onboarding system
6. Island generation & saving
7. Holes, trees, and terrain generation

---

## 1. Model Organization Plan

### ReplicatedStorage (Templates/Assets)
Models that should be in ReplicatedStorage:
- **OakTree** - Tree template for generation
- **DIYWorkBench** - Crafting station model
- **PlayerHome** - Home template
- **ToolModels** - All tool models (shovel, axe, net, etc.)
- **FurnitureModels** - All furniture items
- **RockModel** - Rock template
- **HoleModel** - Hole template
- **XMarker** - X marker template
- **NPCModels** - All NPC/villager models
- **BuildingModels** - Nook's Cranny, Resident Services, etc.

### Workspace (Active Instances)
Models that should be in Workspace:
- **GeneratedObjects/** - Procedurally generated trees, rocks, flowers
- **SavedIslands/[PlayerName]/** - Player-specific saved islands
- **PlayerHomes/** - Active player homes
- **CraftingStations/** - Placed DIYWorkBench instances
- **NPCs/** - Active NPC instances
- **Buildings/** - Active building instances

---

## 2. DIYWorkBench System

### Components Needed:
1. **DIYWorkBench Model** (ReplicatedStorage)
   - Model with ProximityPrompt for interaction
   - Visual model of workbench

2. **DIYWorkBench Controller** (Client)
   - Handles proximity prompt interaction
   - Opens crafting GUI when interacted with
   - Shows visual feedback

3. **DIYWorkBench Service** (Server)
   - Manages placed workbench instances
   - Handles crafting requests
   - Validates player is near workbench

4. **Crafting GUI Integration**
   - Connect existing DIYWorkbenchGUI to workbench interaction
   - Show recipes available at workbench
   - Handle crafting requests

---

## 3. Complete Crafting System

### Current State:
- ✅ CraftingSystem.luau exists and works
- ✅ CraftingSetup.luau handles RemoteEvents
- ✅ DIYWorkbenchGUI.luau exists (in gold mine)
- ⚠️ Need to integrate GUI with actual workbench interaction
- ⚠️ Need to ensure recipes load correctly

### Implementation Steps:
1. Copy DIYWorkbenchGUI from gold mine to active src
2. Create DIYWorkBench interaction controller
3. Connect GUI to workbench proximity prompts
4. Test crafting flow end-to-end

---

## 4. Home Building System

### Components Needed:
1. **Home Placement System**
   - Allow players to place home on their island
   - Validate placement (flat ground, not too close to other objects)
   - Save home position

2. **Home Model System**
   - Start with tent model
   - Upgrade to house later
   - Interior system (future)

3. **Home Service** (Server)
   - Create home for new players
   - Save home data to DataStore
   - Load home on player join

---

## 5. Onboarding System

### Flow:
1. **New Player Detection**
   - Check if player has island data
   - If not, start onboarding

2. **Island Generation**
   - Generate island for new player
   - Place starter objects (trees, rocks, flowers)
   - Create home location

3. **Tutorial Steps**
   - Welcome message
   - Island tour
   - Home placement tutorial
   - Crafting tutorial
   - First quest

4. **Starter Kit**
   - Give starter tools
   - Give starter materials
   - Give starter recipes

---

## 6. Island Generation & Saving

### Current State:
- ✅ IslandGenerationInterface.server.luau exists
- ✅ ProceduralIslandSystem.luau exists
- ✅ Terrain generation works
- ✅ Tree/rock/flower generation works
- ⚠️ Saving needs DataStore integration

### Implementation Steps:
1. **Island Data Structure**
   ```lua
   {
     owner = userId,
     name = "Island Name",
     center = Vector3,
     size = Vector3,
     terrain = {...}, -- Terrain data
     objects = {...}, -- Trees, rocks, flowers
     buildings = {...}, -- Buildings placed
     generated = timestamp,
     lastModified = timestamp
   }
   ```

2. **Save System**
   - Save island data to DataStore on save
   - Load island data on player join
   - Reconstruct island from saved data

3. **Terrain Saving**
   - Save terrain modifications
   - Load terrain on island load

---

## 7. Holes, Trees, and Terrain Generation

### Current State:
- ✅ HoleSpawner.luau exists
- ✅ ProceduralIslandSystem creates trees with holes
- ✅ Terrain generation in IslandGenerationInterface

### Implementation Steps:
1. **Hole System**
   - Ensure holes spawn correctly
   - Save hole positions
   - Load holes on island load

2. **Tree Generation**
   - Trees already generate with holes
   - Need to ensure trees save/load correctly
   - Add tree growth system (future)

3. **Terrain Generation**
   - Terrain generation works
   - Need to save terrain modifications
   - Load terrain on island load

---

## Implementation Priority

### Phase 1: Core Systems (Immediate)
1. ✅ Create model organization plan
2. Create DIYWorkBench interaction system
3. Integrate crafting GUI with workbench
4. Create island saving system

### Phase 2: Onboarding (Next)
1. Create onboarding service
2. Integrate island generation with onboarding
3. Create home placement system
4. Create starter kit system

### Phase 3: Polish (After)
1. Improve terrain saving/loading
2. Add tree growth system
3. Add home upgrade system
4. Add more crafting stations

---

## File Structure

```
src/
├── client/
│   ├── Modules/
│   │   ├── DIYWorkBenchController.luau (NEW)
│   │   └── DIYWorkbenchGUI.luau (COPY from gold mine)
│   └── ...
├── server/
│   ├── DIYWorkBenchService.luau (NEW)
│   ├── HomeBuildingService.luau (NEW)
│   ├── OnboardingService.luau (NEW)
│   ├── IslandSaveService.luau (NEW)
│   └── ...
└── shared/
    ├── IslandData.luau (NEW - data structures)
    └── ...
```

---

## Next Steps

1. Create DIYWorkBench interaction system
2. Copy and integrate crafting GUI
3. Create island saving service
4. Create onboarding service
5. Create home building service
6. Test complete flow

