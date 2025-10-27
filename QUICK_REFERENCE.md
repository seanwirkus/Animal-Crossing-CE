# Quick Reference - Animal Crossing CE Inventory System

## 🎯 What the Client Does

**Polls inventory GUI → Gets data from server → Displays items → Handles drag/drop → Sends updates to server**

## 📁 File Structure
```
src/
├── client/
│   ├── init.client.luau         ← Main inventory logic (998 lines)
│   └── InventoryClient.lua      ← (legacy, not used)
├── server/
│   ├── init.server.luau
│   └── CraftingSetup.luau
└── shared/
    └── CraftingSystem.luau
```

## 🎮 Controls
| Action | Key |
|--------|-----|
| Toggle Inventory | E |
| Drag Item | Click + Drag |
| Drop Item | Release Mouse |

## 🔌 Remote Events

### Client → Server
```lua
inventoryRemote:FireServer("RequestInventory")
inventoryRemote:FireServer("MoveItem", {
    fromIndex = 1,
    toIndex = 2,
    swap = true
})
inventoryRemote:FireServer("DropItem", {
    itemId = "shovel",
    count = 1,
    slotIndex = 1,
    worldPosition = Vector3.new(0, 1, 0)
})
```

### Server → Client
```lua
inventoryRemote:FireClient(player, "SyncInventory", {
    maxSlots = 20,
    slots = {
        [1] = { itemId = "shovel", count = 1 },
        [2] = { itemId = "net", count = 1 }
    }
})
```

## 🛠️ Key Functions

### Find/Initialize
```lua
initializeInventorySystem()  -- Finds GUI, validates structure
```

### Display
```lua
populateInventoryFromServer(data)  -- Updates all slots
refreshSlot(slotIndex)             -- Updates single slot
updateSlotAppearance(slot, state)  -- Renders item to UI
```

### Visibility
```lua
setInventoryVisible(true)   -- Show inventory
setInventoryVisible(false)  -- Hide inventory
```

### Drag & Drop
```lua
beginDrag(slotIndex)        -- Start drag
finishDrag(mousePos)        -- Complete drag
```

## 📊 Item Data Structure

```lua
ItemData = {
    shovel = { index = 2, name = "Shovel" },
    net = { index = 3, name = "Net" },
    -- ... 114 more items
}
```

## 🎨 GUI Requirements

```
PlayerGui
└── InventoryGUI (ScreenGui)
    └── InventoryFrame (Frame)
        └── InventoryItems (ScrollingFrame)
            └── ItemSlotTemplate (Frame)
                ├── ItemIcon (ImageLabel)
                ├── ItemCount (TextLabel)
                └── ItemName (TextLabel)
```

## ⚙️ Configuration

### Sprite Sheet
```lua
SpriteConfig = {
    SHEET_ASSET = "rbxassetid://74324628581851",
    COLUMNS = 21,
    ROWS = 24,
    TILE = 36.6,
    INNER = Vector2.new(6, 6),
    OUTER = Vector2.new(4, 4),
    BLEED_FIX = 0.25
}
```

### Inventory Capacity
```lua
maxSlots = 20  -- Set by server in SyncInventory
```

## 🐛 Debug Tips

### Check if GUI exists
```lua
if not gui:FindFirstChild("InventoryGUI") then
    print("InventoryGUI not found!")
end
```

### See inventory state
```lua
print("Slots:", maxSlots)
print("Filled:", table.getn(slotState))
for i, slot in pairs(slotState) do
    print(i, slot.itemId, slot.count)
end
```

### Check server communication
```lua
-- Look for: "[Debug] Received remote event: SyncInventory"
-- in Output window
```

## 📝 Common Issues

| Error | Fix |
|-------|-----|
| "Could not find InventoryGUI" | Build GUI in Roblox Studio |
| Items don't show | Check ItemData has correct item IDs |
| Drag doesn't work | Verify slot structure and ItemSlotTemplate |
| No animation | Check TweenService works in game |

## 🔗 Related Files

- `AI_INSTRUCTIONS.md` - For AI assistants
- `GUI_STRUCTURE.md` - GUI setup guide
- `CLEANUP_LOG.md` - What was changed
- `CODE_STATUS.md` - Current status

---

**Last Updated**: October 26, 2025
