# Home Building Service Implementation Guide

## Overview

The `HomeBuildingService` handles player home placement, upgrades, and management. It's fully integrated with `PlayerIslandService` for island-specific homes and data persistence.

## Current Implementation Status

### ✅ Completed Features

1. **Basic Home Placement**
   - Players can place a starter tent home
   - Position validation (terrain check, island bounds, spacing)
   - Integration with PlayerIslandService

2. **Home Upgrades**
   - Upgrade path: Tent → SmallHouse → LargeHouse → Mansion
   - Cost system defined (bells and materials)
   - Model replacement on upgrade

3. **Data Persistence**
   - Homes saved to island data
   - Home data includes: position, size, rooms, timestamps
   - Automatic saving on placement/upgrade

4. **Integration**
   - Connected to PlayerIslandService
   - OnboardingService uses HomeBuildingService
   - Homes placed in island Buildings folder

### ✅ Recently Completed

1. **Currency Integration** ✅
   - Fully integrated with CurrencyManager
   - Checks player bells before upgrade
   - Charges bells on successful upgrade
   - Refunds bells if upgrade fails

2. **Material Requirements** ✅
   - Integrated with inventory system
   - Checks materials before upgrade
   - Consumes materials on successful upgrade
   - Refunds bells if material consumption fails

3. **Client-Side UI** ✅
   - Created HomeBuildingGUI module
   - Shows current home status
   - Displays upgrade options with costs
   - Real-time currency updates
   - Can afford/cannot afford visual feedback

### ⚠️ Optional Enhancements

1. **Home Placement UI**
   - Visual placement preview (showing where home will be placed)
   - Interactive placement mode
   - Currently placement is done server-side via OnboardingService

2. **Home Templates**
   - Ensure Tent, SmallHouse, LargeHouse, Mansion models exist in ReplicatedStorage/Models
   - Or create fallback models (fallback tent already exists)

## API Reference

### Server-Side Functions

```lua
-- Place a home at a position
local success, message = HomeBuildingService:PlaceHome(player, position)
-- Returns: (bool success, string message)

-- Upgrade player's home
local success, message = HomeBuildingService:UpgradeHome(player)
-- Returns: (bool success, string message)

-- Get player's home data
local homeData = HomeBuildingService:GetPlayerHome(player)
-- Returns: {owner, position, size, rooms, created, lastModified}

-- Get player's home model
local homeModel = HomeBuildingService:GetPlayerHomeModel(player)
-- Returns: Model or nil

-- Check if player has a home
local hasHome = HomeBuildingService:HasHome(player)
-- Returns: bool

-- Get upgrade cost for current home size
local cost, materials = HomeBuildingService:GetUpgradeCost(currentSize)
-- Returns: (number bells, {materials})
```

### RemoteEvents

**Client → Server:**
- `RemoteEvents/PlaceHome` - Place a home at position
  - Parameters: `(player, Vector3 position)`
  
- `RemoteEvents/UpgradeHome` - Upgrade player's home
  - Parameters: `(player)`

## Home Upgrade Costs

```lua
Tent → SmallHouse: 5,000 bells
SmallHouse → LargeHouse: 10,000 bells
LargeHouse → Mansion: 25,000 bells
```

Materials can be added to `HOME_MATERIALS` table in `HomeBuildingService.luau`.

## Home Templates

The service looks for home models in:
- `ReplicatedStorage/Models/Tent`
- `ReplicatedStorage/Models/SmallHouse`
- `ReplicatedStorage/Models/LargeHouse`
- `ReplicatedStorage/Models/Mansion`

If templates aren't found, it creates a fallback tent model.

## Integration Points

### PlayerIslandService
- Homes are saved to `islandData.home`
- Homes are placed in `Island_X/Buildings/` folder
- `hasBuiltHome` flag is set in island data

### OnboardingService
- Uses `HomeBuildingService:PlaceHome()` for tutorial home building
- Automatically places tent near island center during onboarding

## Implementation Complete! ✅

All core features have been implemented:

### ✅ Currency Integration
- Fully integrated with CurrencyManager
- Checks player bells before upgrade
- Charges bells on successful upgrade
- Refunds bells if upgrade fails

### ✅ Material Integration
- Integrated with inventory system using `hasCraftingMaterials` and `consumeCraftingMaterials`
- Checks materials before upgrade
- Consumes materials on successful upgrade
- Refunds bells if material consumption fails

### ✅ Client-Side UI
- Created `HomeBuildingGUI.luau` module
- Shows current home status
- Displays upgrade options with costs
- Real-time currency updates
- Visual feedback for affordability

### Optional Enhancements

1. **Home Placement UI** (Optional)
   - Visual placement preview
   - Interactive placement mode
   - Currently placement is handled server-side

2. **Home Templates** (Optional)
   - Ensure Tent, SmallHouse, LargeHouse, Mansion models exist in ReplicatedStorage/Models
   - Fallback tent model already exists

## Example Usage

### Server-Side: Place Home
```lua
local HomeBuildingService = require(script.Parent.HomeBuildingService)
local position = Vector3.new(10, 50, 20)
local success, message = HomeBuildingService:PlaceHome(player, position)
if success then
    print("Home placed!")
else
    warn(message)
end
```

### Server-Side: Upgrade Home
```lua
local success, message = HomeBuildingService:UpgradeHome(player)
if success then
    print("Home upgraded!")
else
    warn(message)
end
```

### Client-Side: Request Home Placement
```lua
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local placeHomeRemote = remotes:WaitForChild("PlaceHome")
placeHomeRemote:FireServer(Vector3.new(10, 50, 20))
```

### Client-Side: Request Home Upgrade
```lua
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local upgradeHomeRemote = remotes:WaitForChild("UpgradeHome")
upgradeHomeRemote:FireServer()
```

### Client-Side: Open Home Building GUI
```lua
local HomeBuildingGUI = require(script.Parent.Modules.HomeBuildingGUI)
HomeBuildingGUI:open()  -- Opens the GUI
HomeBuildingGUI:toggle()  -- Toggles the GUI
HomeBuildingGUI:close()  -- Closes the GUI
```

## File Structure

```
src/server/
├── HomeBuildingService.luau    # Main service
├── OnboardingService.luau       # Uses HomeBuildingService
└── init.server.luau             # Connects services

ReplicatedStorage/
├── RemoteEvents/
│   ├── PlaceHome                # RemoteEvent for placing homes
│   └── UpgradeHome             # RemoteEvent for upgrading homes
└── Models/
    ├── Tent                     # Tent model (optional)
    ├── SmallHouse               # Small house model (optional)
    ├── LargeHouse               # Large house model (optional)
    └── Mansion                  # Mansion model (optional)
```

## Notes

- Homes are automatically saved to island data when placed/upgraded
- Home validation ensures homes are placed on valid terrain within island bounds
- Minimum spacing of 20 studs between homes
- Homes are clickable (BuildingType = "PlayerHome") for future interaction systems

