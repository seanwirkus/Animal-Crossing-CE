# Save System Setup Guide

## Overview
This guide will help you set up the new comprehensive save/load system with unlimited save slots for your Animal Crossing game.

## What's Been Fixed

### Client Side (NookPhoneGUI.luau)
✅ Updated the "Save Game" app in NookPhone to show save slots
✅ Added functions to create, load, and delete save slots
✅ Collects all game data including currency, inventory, quests, position

### Server Side (SaveSlotManager.luau)
✅ Created new service to manage unlimited save slots per player
✅ Saves ALL game data:
  - Currency (Bells & Miles)
  - Full inventory snapshot
  - Quest progress
  - Island data (trees, rocks, buildings, terrain)
  - Home/house data
  - Player settings
  - Player position

## Server Integration Steps

### Step 1: Find your main server script
Look for a file like:
- `src/server/init.server.luau`
- `src/server/Main.server.luau`
- `src/server/ServerMain.luau`

### Step 2: Initialize SaveSlotManager

Add this code to your server initialization:

```lua
-- At the top with other requires
local SaveSlotManager = require(script.Parent.SaveSlotManager)

-- After initializing other services (CurrencyManager, QuestService, etc.)
local saveSlotManager = SaveSlotManager.new()

-- Connect all the services so SaveSlotManager can access game data
saveSlotManager:SetServices({
    currencyManager = currencyManager,          -- Your CurrencyManager instance
    playerIslandService = playerIslandService,  -- Your PlayerIslandService instance
    questService = questService,                -- Your QuestService instance
    homeBuildingService = homeBuildingService,  -- Your HomeBuildingService instance
    playerSettingsService = playerSettingsService, -- Your PlayerSettingsService instance
})
```

### Step 3: Update Service Methods (if needed)

The SaveSlotManager expects these methods on your services:

#### CurrencyManager
```lua
function CurrencyManager:GetPlayerState(player)
    -- Return {bells = number, miles = number, ...}
end

function CurrencyManager:SetPlayerState(player, state)
    -- Restore currency state
end
```

#### QuestService
```lua
function QuestService:GetPlayerQuests(player)
    -- Return table of all quests for player
end

function QuestService:RestorePlayerQuests(player, questsData)
    -- Restore all quests from save data
end
```

#### HomeBuildingService
```lua
function HomeBuildingService:GetPlayerHome(player)
    -- Return home data
end

function HomeBuildingService:RestorePlayerHome(player, homeData)
    -- Restore home from save data
end
```

#### PlayerSettingsService
```lua
function PlayerSettingsService:GetSettings(player)
    -- Return player settings
end

function PlayerSettingsService:LoadSettings(player, settings)
    -- Restore settings from save data
end
```

### Step 4: Verify Remote Events

The system creates these RemoteEvents automatically:
- `GetSaveSlots` - Request save slots list
- `SaveSlotsResult` - Send slots to client
- `SaveToSlot` - Save to a slot
- `LoadFromSlot` - Load from a slot
- `DeleteSaveSlot` - Delete a slot

These are created in `ReplicatedStorage.RemoteEvents`

## How It Works

### Saving
1. Player opens NookPhone → "Save Game" app
2. Clicks "➕ Create New Save"
3. Client collects visible data (currency, quest counts)
4. Sends to server via `SaveToSlot` remote
5. Server collects ALL data from all services
6. Saves to DataStore: `ACNH_SaveSlots` (or `ACNH_SaveSlots_Dev` in Studio)
7. Refreshes the slots list in the GUI

### Loading
1. Player clicks "📂 Load" on a save slot
2. Client sends slot index to server
3. Server loads data from DataStore
4. Restores currency, inventory, quests, island, home, settings, position
5. Player is teleported to saved position
6. All game state is restored

### Data Structure
Each save slot stores:
```lua
{
    name = "Save 12/28 14:30",
    timestamp = "2025-12-28 14:30:45",
    bells = 50000,
    miles = 2500,
    inventorySnapshot = {...},
    inventoryCount = 15,
    questsData = {...},
    questsActive = {...},
    questsCompleted = 5,
    questsCount = 8,
    islandData = {...},
    homeData = {...},
    homeType = "SmallHouse",
    playerSettings = {...},
    playerPosition = {X = 100, Y = 50, Z = 200},
}
```

## Example Server Setup

Here's a complete example of how to set this up in your main server script:

```lua
-- src/server/init.server.luau

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Require all services
local CurrencyManager = require(script.CurrencyManager)
local QuestService = require(script.QuestService)
local PlayerIslandService = require(script.PlayerIslandService)
local HomeBuildingService = require(script.HomeBuildingService)
local PlayerSettingsService = require(script.PlayerSettingsService)
local SaveSlotManager = require(script.SaveSlotManager)

-- Initialize services
local currencyManager = CurrencyManager.new()
local questService = QuestService.new()
local playerIslandService = PlayerIslandService.new()
local homeBuildingService = HomeBuildingService.new()
local playerSettingsService = PlayerSettingsService.new()

-- Initialize SaveSlotManager
local saveSlotManager = SaveSlotManager.new()

-- Connect services to SaveSlotManager
saveSlotManager:SetServices({
    currencyManager = currencyManager,
    playerIslandService = playerIslandService,
    questService = questService,
    homeBuildingService = homeBuildingService,
    playerSettingsService = playerSettingsService,
})

print("✅ All services initialized including SaveSlotManager")

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
    -- Initialize player data in all services
    currencyManager:InitializePlayer(player)
    questService:InitializePlayer(player)
    -- etc...
end)
```

## Testing

1. Start the game in Studio
2. Earn some currency, collect items, start quests
3. Open NookPhone (default key: P)
4. Go to "Save Game" app
5. Click "➕ Create New Save"
6. You should see a new save slot appear with your data
7. Make some changes in the game
8. Create another save
9. Click "📂 Load" on the first save
10. Your game should revert to that save state

## Troubleshooting

### "Save system unavailable" error
- Check that SaveSlotManager is initialized on the server
- Check that RemoteEvents folder exists in ReplicatedStorage

### Save not working
- Check server output for errors
- Make sure all services are passed to `SetServices()`
- Check DataStore is enabled in game settings

### Load not working
- Check that all services have the required restore methods
- Check server output for errors
- Verify player character exists when loading

## DataStore Info

- **Name**: `ACNH_SaveSlots` (production) or `ACNH_SaveSlots_Dev` (Studio)
- **Key**: Player's UserId as string
- **Structure**: `{slots = {[1] = saveData, [2] = saveData, ...}}`
- **Unlimited slots**: Players can create as many saves as they want

## Next Steps

After setting up:
1. Test thoroughly with different scenarios
2. Consider adding save slot naming/renaming
3. Consider adding save slot icons/thumbnails
4. Add confirmation dialogs for delete/load actions
5. Add loading indicators when saving/loading

## Files Modified/Created

### Modified
- `src/client/Modules/NookPhoneGUI.luau` - Added save/load UI and functions

### Created
- `src/server/SaveSlotManager.luau` - New save slot management service
- `src/client/Modules/NookPhoneSaveLoadFunctions.luau` - Reference copy of functions (can be deleted)

## Need Help?

If you encounter issues:
1. Check the console for error messages
2. Verify all services are initialized in the correct order
3. Make sure DataStore is enabled
4. Check that all required methods exist on your services
