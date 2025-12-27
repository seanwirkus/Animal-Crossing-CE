# Inventory Item Guide

## Debug Inventory vs Real Inventory

### Debug Inventory (B key)
- **Purpose**: Browse and test item sprites/UI
- **Does NOT add items**: It's just for visual testing
- **Location**: Press `B` key to open (debug mode only)

### Real Inventory System
- **Purpose**: Actual player inventory that persists
- **Storage**: Server-side, saved to DataStore
- **Access**: Press `E` key to open inventory GUI

## How to Add Items to Inventory

### Method 1: Server Command (Testing)
In **Server Command Bar**, use:
```lua
-- Get the player
local player = game.Players:GetPlayers()[1]

-- Add a single item
game.ReplicatedStorage.InventoryEvent:FireServer("add_item", {
    itemId = "1-up-mushroom",
    count = 1
})
```

### Method 2: Server Script (Using RemoteEvent)
In any server script, you can fire the RemoteEvent to the server:
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for inventory system to load
local inventoryRemote = ReplicatedStorage:WaitForChild("InventoryEvent")

-- Add item to a player (fires to server)
local function giveItemToPlayer(player, itemId, count)
    count = count or 1
    -- Fire to server (yes, server can fire to itself via RemoteEvent)
    inventoryRemote:FireServer("add_item", {
        itemId = itemId,
        count = count
    })
end

-- Example: Give player a mushroom when they join
Players.PlayerAdded:Connect(function(player)
    task.wait(2) -- Wait for inventory to initialize
    giveItemToPlayer(player, "1-up-mushroom", 1)
end)
```

**Note**: This works because the server's `OnServerEvent` handler processes "add_item" actions. However, Method 3 (direct function call) is more efficient.

### Method 3: Direct Server Function (Advanced)
If you have access to the server's `addItemToInventory` function:
```lua
-- In src/server/init.server.luau or a module that requires it
local success, err = addItemToInventory(player, {
    itemId = "1-up-mushroom",
    count = 5,
    metadata = {} -- Optional custom data
})
```

## Available Items

All items are defined in `data/items.json`. Some examples:
- `"1-up-mushroom"` - 1-Up Mushroom
- `"2021-celebratory-arch"` - 2021 Celebratory Arch
- `"2022-celebratory-arch"` - 2022 Celebratory Arch
- And 4,880+ more items!

## Item IDs

Item IDs match the `"id"` field in `data/items.json`. You can:
1. Browse items in the debug inventory (B key) to see sprites
2. Check `data/items.json` for the exact item ID
3. Use `ItemDataFetcher.getItem(itemId)` to validate an item exists

## Example: Give Starter Items

```lua
-- In a server script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local inventoryRemote = ReplicatedStorage:WaitForChild("InventoryEvent")

Players.PlayerAdded:Connect(function(player)
    task.wait(2) -- Wait for inventory initialization
    
    -- Give starter items
    local starterItems = {
        {itemId = "1-up-mushroom", count = 3},
        {itemId = "2021-celebratory-arch", count = 1},
    }
    
    for _, item in ipairs(starterItems) do
        inventoryRemote:FireServer("add_item", item)
        task.wait(0.1) -- Small delay between items
    end
end)
```

## Notes

- Items are automatically synced to the client when added
- Inventory has a max capacity (starts at 10 slots, can be upgraded)
- Items stack if they have the same `itemId` and `maxStack` allows it
- The inventory GUI (E key) will automatically update when items are added

