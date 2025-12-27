# 🏠 Home Building System - Complete Guide

**Last Updated**: December 19, 2025

---

## 📊 Overview

The home building system now includes **material gathering**, **placement validation**, and an **interactive placement editor**. Players must collect materials before they can build their home, and they can choose exactly where to place it on their island.

---

## ✅ What's Been Implemented

### 1. Material Requirements ✅
Players MUST gather materials before building:

**Tent (First Home)**:
- 30x Wood
- 30x Softwood
- 15x Stone

**SmallHouse Upgrade**:
- 50x Wood
- 30x Hardwood
- 20x Iron Nugget
- 30x Stone
- 5000 Bells

**LargeHouse Upgrade**:
- 80x Wood
- 50x Hardwood
- 40x Iron Nugget
- 30x Clay
- 10,000 Bells

**Mansion Upgrade**:
- 150x Wood
- 100x Hardwood
- 80x Iron Nugget
- 10x Gold Nugget
- 25,000 Bells

### 2. Starter Tools & Materials ✅
When players complete the tutorial, they receive:

**Tools**:
- Flimsy Axe
- Stone Axe
- Shovel
- Fishing Rod
- Net
- Slingshot

**Starting Materials** (for first home):
- 30x Wood
- 30x Softwood
- 15x Stone

**Currency**:
- 1000 Bells
- 500 Nook Miles

### 3. Interactive Placement System ✅
**File**: `src/client/Modules/HomePlacementGUI.luau`

**Features**:
- **Ghost Preview**: Transparent model shows where home will be placed
- **Visual Feedback**: Green = valid, Red = invalid
- **Rotation**: Press R to rotate in 45° increments
- **Mouse Placement**: Move mouse to position home
- **Click to Confirm**: Click mouse to place
- **ESC to Cancel**: Cancel placement anytime

**Controls**:
- Move Mouse = Position home
- R = Rotate 45°
- Click = Confirm placement
- ESC = Cancel

### 4. Enhanced Placement Validation ✅
**Server-side validation** (HomeBuildingService.luau):

❌ **Prevents placement**:
- In the air (must be on solid ground)
- On steep terrain (max 3 stud height difference)
- Near other homes (20 stud minimum distance)
- Near trees, rocks, buildings
- Near large objects (5+ stud size)
- Outside island boundaries

✅ **Allows placement**:
- On flat terrain
- Away from obstacles
- Within island bounds
- With all required materials

### 5. Material Checking & Consumption ✅
**Flow**:
1. Player clicks "Build Home"
2. **`HomeBuildingService:RequestPlacement()`** verifies the player has island data, the tent material bundle, and that inventory/resource systems are online.
3. If anything is missing → Server sends a failure response; client shows a notification with the missing materials.
4. If everything is ready → Server opens placement GUI with a ghost preview.
5. Player places home
6. Server validates position
7. Server consumes materials
8. Home is placed

---

## 🎮 How It Works (Player Experience)

### Tutorial Flow:
1. **Player Joins** → Tutorial starts
2. **Tutorial Complete** → Receives starter tools + materials
3. **"Build Home" Button** → Opens placement mode
4. **Move Mouse** → Ghost home follows mouse
5. **Find Good Spot** → Green = valid, Red = invalid
6. **Press R** → Rotate home
7. **Click** → Confirm placement
8. **Materials Consumed** → Home is built!

### If Player Doesn't Have Materials:
1. **"Build Home" Button** → Error: "Missing materials: Wood"
2. **Player Must Gather**:
   - Chop trees for wood
   - Hit rocks for stone
   - Shake trees for resources
3. **Try Again** → Once all materials collected

---

## 🔧 Technical Implementation

### Server Files Modified:
1. **HomeBuildingService.luau**:
   - Added material requirements (HOME_MATERIALS)
   - Enhanced placement validation
   - Material checking & consumption
   - New RemoteEvent: `StartHomePlacement`
   - **Placement gate** shared by onboarding + client requests to block the GUI until resources exist

2. **OnboardingService.luau**:
   - Modified `giveStarterRewards()` to give tools
   - Modified `buildPlayerHome()` to trigger placement mode
   - Added starter materials (30 wood, 30 softwood, 15 stone)

### Client Files Created:
1. **HomePlacementGUI.luau** (NEW):
   - Ghost model preview
   - Position validation
   - Rotation controls
   - Click-to-place confirmation

### RemoteEvents:
1. **StartHomePlacement** (Client ← Server):
   - Triggers placement mode
   - Sends success/failure + materials list

2. **PlaceHome** (Server ← Client):
   - Position + rotation from client
   - Server validates & places home

---

## 📋 TODO: Resource Gathering Systems

### ❌ Still Need Implementation:

#### Tree Chopping System:
- [ ] Equip axe from inventory
- [ ] Click tree to chop
- [ ] Tree shakes/animation
- [ ] Drops wood/softwood/hardwood
- [ ] Tree eventually falls or respawns

#### Rock Hitting System:
- [ ] Equip shovel or axe
- [ ] Click rock to hit
- [ ] Rock particles/animation
- [ ] Drops stone/iron nugget/clay/gold nugget
- [ ] Max 8 resources per rock per day

#### Tree Shaking System:
**Status**: ✅ Exists (`TreeShakingSystem.luau`)
**Needs**: Testing to ensure items drop correctly

#### Material Spawning:
- [ ] Trees spawned across island
- [ ] Rocks spawned across island
- [ ] Trees respawn daily
- [ ] Rocks respawn resources daily

---

## 🎯 Next Steps

### Priority 1: Resource Gathering (CRITICAL)
Without this, players can't get materials to build!

1. **Enable Tree Chopping**:
   - Read `src/server/TreeShakingSystem.luau`
   - Verify axe tool works
   - Test wood drops

2. **Enable Rock Hitting**:
   - Check if system exists
   - Create if needed
   - Test resource drops

3. **Spawn Resources**:
   - Place 20+ trees on island
   - Place 10+ rocks on island
   - Set respawn timers

### Priority 2: Testing & Polish
1. Test full flow: gather materials → build home
2. Test placement validation
3. Add visual/sound effects
4. Add progress indicators

### Priority 3: Advanced Features
1. Material storage/stacking
2. Resource respawn system
3. Daily resource limits (rocks)
4. Tool durability

---

## 🐛 Known Issues

### Material System:
- ✅ Material requirements defined
- ✅ Material checking works
- ❌ Players can't actually GATHER materials yet
- ❌ Need working tree/rock systems

### Placement System:
- ✅ Ghost preview working
- ✅ Validation working
- ⚠️ Needs testing in actual game

### Starter Items:
- ✅ Tools given on tutorial complete
- ✅ Materials given on tutorial complete
- ⚠️ Tools may not be usable yet (need tool systems)

---

## 📝 Code Examples

### Check if Player Has Materials (Server):
```lua
local materials = HOME_MATERIALS.Tent
local hasMaterials, missingItem = InventoryCheckFunction(player, materials)
if not hasMaterials then
    warn("Player missing:", missingItem)
end
```

### Start Placement Mode (Server):
```lua
local startPlacementRemote = ReplicatedStorage.RemoteEvents.StartHomePlacement
startPlacementRemote:FireClient(player, true, "Place your home!")
```

### Handle Placement (Client):
```lua
local HomePlacementGUI = require(script.Parent.HomePlacementGUI)
local placementGUI = HomePlacementGUI.new()

-- When server triggers placement:
placementGUI:startPlacement(homeTemplate)
```

---

## 🚀 Testing Checklist

### Material System:
- [ ] Player receives starter materials
- [ ] Build home without materials → Error message
- [ ] Build home with materials → Success
- [ ] Materials are consumed on placement

### Placement System:
- [ ] Ghost model appears
- [ ] Ghost follows mouse
- [ ] Green when valid, red when invalid
- [ ] Can rotate with R key
- [ ] Can cancel with ESC
- [ ] Click places home
- [ ] Can't place in air
- [ ] Can't place near objects

### Resource Gathering:
- [ ] Axe equipped from inventory
- [ ] Click tree drops wood
- [ ] Click rock drops stone
- [ ] Items appear in inventory
- [ ] Resources respawn

---

## 📞 Integration Points

### Files That Interact:
1. **OnboardingService** → Triggers placement mode
2. **HomeBuildingService** → Validates & places home
3. **InventorySystem** → Stores materials & tools
4. **CurrencyManager** → Handles bell costs
5. **PlayerIslandService** → Tracks island data

### RemoteEvents Used:
- `StartHomePlacement` - Start placement mode
- `PlaceHome` - Confirm placement
- `InventoryEvent` - Add/remove items
- `CurrencyUpdate` - Add/remove bells

---

**Status**: 🟡 Partially Complete
**Blocker**: Resource gathering systems needed
**Next**: Implement tree chopping & rock hitting

---

Ready to gather materials and build homes! 🏡🌲⛏️
