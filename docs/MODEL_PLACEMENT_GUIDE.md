# 🏗️ Model Placement Guide - Animal Crossing CE

## Overview

This document defines where models should be placed in your Roblox game structure for optimal organization, replication, and performance.

---

## 📦 ReplicatedStorage

**Purpose**: Templates and shared resources that need to be accessible by both server and client.

### What Goes Here:
- **Template Models** (that will be cloned)
- **Shared Modules** (code used by both client and server)
- **Asset References** (sprite sheets, sound IDs, etc.)
- **Configuration Data**

### Current Structure:

```
ReplicatedStorage/
├── Shared/                          # Shared Lua modules
│   ├── ItemDataFetcher.luau        # Item data access
│   ├── SpriteConfig.luau           # Sprite calculations
│   ├── SpriteManifest.luau         # Sprite index mapping
│   ├── CraftingSystem.luau         # Crafting logic
│   ├── ProceduralIslandSystem.luau # Island generation
│   ├── IslandAnalyzer.luau
│   ├── IslandGenerator.luau
│   ├── IslandAuditor.luau
│   └── ... (other shared modules)
│
├── OakTree                          # ✅ Tree model template
├── DIYWorkBench                     # ✅ Workbench model template
├── Rock                             # ✅ Rock model template
├── Flower                           # ✅ Flower model template
├── TomNook                          # ✅ NPC model
├── Orville                          # ✅ NPC model (airport)
│
├── Buildings/                       # ✅ Building templates
│   ├── TentHouse                   # Player starter home
│   ├── WoodenHouse                 # Upgraded home
│   ├── NooksCranny                 # Shop building
│   ├── Museum                      # Museum building
│   └── ResidentServices            # Town hall
│
├── Tools/                           # ✅ Tool models
│   ├── FishingRod
│   ├── Net
│   ├── Shovel
│   ├── Axe
│   └── WateringCan
│
├── Furniture/                       # ✅ Furniture templates
│   ├── WoodenChair
│   ├── WoodenTable
│   ├── Campfire
│   └── ... (more furniture)
│
└── Remotes/                         # ✅ RemoteEvents and RemoteFunctions
    ├── OpenCraftingGUI             # RemoteEvent
    ├── CraftingEvent               # RemoteEvent
    ├── InventoryEvent              # RemoteEvent
    ├── TalkToTomNook              # RemoteEvent
    ├── OpenOnboardingGUI          # RemoteEvent
    └── ... (other remotes)
```

---

## 🌍 Workspace

**Purpose**: Active game world where players interact with placed instances.

### What Goes Here:
- **Cloned/Instantiated Models** (from ReplicatedStorage)
- **Terrain** (generated or pre-built)
- **Active NPCs** (spawned from templates)
- **Player Islands** (generated per-player)
- **Placed Objects** (trees, rocks, buildings)

### Structure:

```
Workspace/
├── Terrain                          # Generated island terrain
│
├── PlayerIslands/                   # ✅ Per-player island folders
│   ├── Island_12345/               # Player userId
│   │   ├── Tree (multiple)
│   │   ├── Rock (multiple)
│   │   ├── Hole (multiple)
│   │   ├── DIYWorkBench
│   │   └── Buildings/
│   │       └── TentHouse
│   │
│   ├── Island_67890/               # Another player
│   │   └── ...
│   └── ...
│
├── NPCs/                            # ✅ Active NPCs in world
│   ├── TomNook                     # Cloned from ReplicatedStorage
│   └── Orville
│
├── GeneratedObjects/                # ✅ Procedurally placed objects
│   ├── trees/
│   ├── rocks/
│   ├── flowers/
│   └── furniture/
│
├── SpawnLocation                    # Default spawn (before island system)
│
└── Camera                           # Workspace camera
```

---

## 📂 ServerStorage

**Purpose**: Server-only assets that clients never need to access directly.

### What Goes Here:
- **Admin Tools**
- **Server-only Templates** (anti-exploit)
- **Backup Data**
- **Server Configuration**

### Structure:

```
ServerStorage/
├── AdminTools/                      # Admin commands, moderation
├── ServerConfig/                    # Server-side settings
└── Backups/                        # Backup models/data
```

---

## 👤 StarterPlayer

**Purpose**: Default player settings and starter equipment.

### Structure:

```
StarterPlayer/
├── StarterCharacterScripts/         # Scripts for player character
│   └── ... (empty for now)
│
├── StarterPlayerScripts/            # Client-side player scripts
│   └── ... (we use init.client.luau instead)
│
└── StarterCharacter/                # Custom character if needed
```

---

## 🎨 StarterGui

**Purpose**: Default GUI that appears when player joins.

### Structure:

```
StarterGui/
├── (Most GUIs are created dynamically by client scripts)
│
└── LoadingScreen                    # Optional initial loading screen
```

---

## 📊 ServerScriptService

**Purpose**: Server-side scripts and services.

### Current Structure:

```
ServerScriptService/
└── src/server/
    ├── init.server.luau             # Main server bootstrap
    ├── DIYWorkbenchService.luau     # ✅ Workbench management
    ├── PlayerIslandService.luau     # ✅ Per-player islands
    ├── CraftingSetup.luau           # Crafting system setup
    ├── CurrencyManager.luau         # Currency logic
    ├── FishingSystem.luau           # Fishing logic
    ├── ShovelSystem.luau            # Digging/hole logic
    ├── BalloonSpawner.luau          # Balloon spawning
    ├── HoleSpawner.luau             # Legacy hole spawner
    └── ... (other server modules)
```

---

## 💻 StarterPlayerScripts (via ReplicatedStorage)

**Purpose**: Client-side scripts.

### Current Structure:

```
StarterPlayerScripts/
└── src/client/
    ├── init.client.luau             # Main client bootstrap
    ├── InventoryClient.lua          # Inventory system
    ├── KeybindManager.lua           # Keybind registry
    └── Modules/
        ├── CraftingGUI.luau         # ✅ Crafting interface
        ├── DebugCraftingMenu.lua    # Debug crafting (C key)
        ├── RecipesInventoryGUI.luau # Recipe browser
        ├── ToolRingGUI.luau         # Tool ring
        ├── ContextMenu.luau         # Right-click menu
        ├── ACNHCamera.luau          # Camera controller
        ├── ChibiCharacter.luau      # Character controller
        ├── FishingController.luau   # Fishing client
        ├── LoadingScreen.luau       # Loading UI
        ├── VisualEffects.luau       # Effects system
        └── ... (other client modules)
```

---

## 🎯 Decision Tree: Where Should My Model Go?

### Question 1: Will it be cloned/reused?
- **YES** → ReplicatedStorage (as template)
- **NO** → Go to Question 2

### Question 2: Is it unique to each player?
- **YES** → Clone to `Workspace/PlayerIslands/Island_[userId]/`
- **NO** → Go to Question 3

### Question 3: Does the client need access to it?
- **YES** → ReplicatedStorage
- **NO** → ServerStorage

### Question 4: Is it an active world object?
- **YES** → Workspace (cloned from template)
- **NO** → Leave in ReplicatedStorage as template

---

## 📋 Model Checklist

### Trees
- ✅ Template: `ReplicatedStorage/OakTree`
- ✅ Instances: `Workspace/PlayerIslands/Island_[userId]/Tree`
- ⚠️ TODO: Add more tree varieties (Pine, Palm, Fruit Trees)

### Rocks
- ✅ Template: `ReplicatedStorage/Rock`
- ✅ Instances: `Workspace/PlayerIslands/Island_[userId]/Rock`

### Flowers
- ✅ Template: `ReplicatedStorage/Flower`
- ✅ Instances: `Workspace/GeneratedObjects/flowers/`

### DIY Workbench
- ✅ Template: `ReplicatedStorage/DIYWorkBench`
- ✅ Instances: `Workspace/PlayerIslands/Island_[userId]/DIYWorkBench`
- ✅ Service: `ServerScriptService/src/server/DIYWorkbenchService.luau`

### Buildings
- ✅ Templates: `ReplicatedStorage/Buildings/[BuildingName]`
- ✅ Instances: `Workspace/PlayerIslands/Island_[userId]/Buildings/[BuildingName]`
- ⚠️ TODO: Implement building placement system

### NPCs
- ✅ Templates: `ReplicatedStorage/TomNook`, `ReplicatedStorage/Orville`
- ✅ Instances: `Workspace/NPCs/[NPCName]`

### Tools
- ✅ Templates: `ReplicatedStorage/Tools/[ToolName]`
- ⚠️ Instances: Given to player backpack when equipped
- ⚠️ TODO: Implement tool system integration

### Holes (Digging)
- ✅ No template needed (created procedurally)
- ✅ Instances: `Workspace/PlayerIslands/Island_[userId]/Hole`
- ✅ Service: `ServerScriptService/src/server/ShovelSystem.luau`

---

## 🚀 Implementation Priority

### Phase 1: Core Models (NOW) ✅
- [x] OakTree template in ReplicatedStorage
- [x] DIYWorkBench template in ReplicatedStorage
- [x] Rock template in ReplicatedStorage
- [x] PlayerIslands folder structure in Workspace
- [x] DIYWorkbenchService
- [x] PlayerIslandService

### Phase 2: Buildings (NEXT)
- [ ] TentHouse template
- [ ] WoodenHouse template
- [ ] NooksCranny template
- [ ] Building placement system
- [ ] Building upgrade system

### Phase 3: Decorations & Furniture
- [ ] Furniture templates
- [ ] Furniture placement system
- [ ] Interior decoration system

### Phase 4: Polish & Variety
- [ ] Additional tree types
- [ ] Flower varieties
- [ ] Seasonal decorations
- [ ] Custom paths/terrain

---

## 💾 Saving Strategy

### What Gets Saved (DataStore):
- **Player Island Data**: Position, trees, rocks, holes, buildings
- **Player Inventory**: Items, quantities, equipped tools
- **Player Currency**: Bells, Miles
- **Player Progress**: Tutorial completion, unlocked recipes, achievements

### What Does NOT Get Saved:
- **Template Models**: Always in ReplicatedStorage
- **Terrain**: Regenerated based on saved island data
- **NPCs**: Spawned fresh each session
- **Temporary Effects**: Particles, sounds, visual effects

### Example Island Save Data:
```lua
{
    userId = 12345,
    center = { X = 0, Y = 50, Z = 0 },
    size = { X = 200, Y = 50, Z = 200 },
    trees = {
        { X = 10, Y = 55, Z = 20, type = "Oak" },
        { X = -15, Y = 53, Z = -10, type = "Oak" },
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

---

## 🔧 Best Practices

### DO:
- ✅ Keep templates in ReplicatedStorage
- ✅ Clone templates when creating instances
- ✅ Organize workspace into folders (PlayerIslands, NPCs, etc.)
- ✅ Save only data, not entire models
- ✅ Use services to manage model lifecycle

### DON'T:
- ❌ Put active instances in ReplicatedStorage
- ❌ Save entire Model objects to DataStore (save positions/data only)
- ❌ Create models directly in Workspace without templates
- ❌ Mix player islands together (keep them separate)
- ❌ Forget to anchor parts that shouldn't move

---

## 📞 Quick Reference

| Model Type | Template Location | Instance Location | Service |
|------------|------------------|-------------------|---------|
| OakTree | ReplicatedStorage | PlayerIslands/Island_[id]/ | PlayerIslandService |
| DIYWorkBench | ReplicatedStorage | PlayerIslands/Island_[id]/ | DIYWorkbenchService |
| Rock | ReplicatedStorage | PlayerIslands/Island_[id]/ | PlayerIslandService |
| Flower | ReplicatedStorage | GeneratedObjects/flowers/ | ProceduralIslandSystem |
| TentHouse | ReplicatedStorage/Buildings | PlayerIslands/Island_[id]/Buildings/ | (TBD) |
| TomNook | ReplicatedStorage | NPCs/ | TomNookSpawner |
| Hole | N/A (procedural) | PlayerIslands/Island_[id]/ | ShovelSystem |

---

**Last Updated**: November 11, 2025  
**Maintained By**: AI Assistant

