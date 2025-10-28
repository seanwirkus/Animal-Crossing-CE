# Quick Reference – Item Browser & Inventory# Quick Reference - Animal Crossing CE Inventory System



## Keybinds## 🎯 What the Client Does



| Key | Action |**Polls inventory GUI → Gets data from server → Displays items → Handles drag/drop → Sends updates to server**

|-----|--------|

| **E** | Toggle inventory (shows slots) |## 📁 File Structure

| **G** | Toggle item browser modal |```

| **← / →** | Change page when browser is open |src/

| **ESC** | Close the browser |├── client/

│   ├── init.client.luau         ← Main inventory logic (998 lines)

## Item Browser Overview│   └── InventoryClient.lua      ← (legacy, not used)

├── server/

- Opens as an 800×600 centered modal with a dimmed backdrop│   ├── init.server.luau

- Reuses a single instance for quick toggling (no more laggy rebuilds)│   └── CraftingSetup.luau

- 290 items displayed via pagination (20 items per page, 5×4 grid)└── shared/

- Each button shows sprite, sprite index, and item name/id    └── CraftingSystem.luau

- Hover highlights item; click sends `add_item` request to server```



```## 🎮 Controls

┌──────────────────────────────────────┐| Action | Key |

│ 🎮 Item Browser                [✕]  │|--------|-----|

├──────────────────────────────────────┤| Toggle Inventory | E |

│ Page X of 15 (290 total items)       │| Drag Item | Click + Drag |

│ ┌─────┬─────┬─────┬─────┬─────┐      │| Drop Item | Release Mouse |

│ │ I₁ │ I₂ │ I₃ │ I₄ │ I₅ │      │  ← 5 columns × 4 rows

│ ├─────┼─────┼─────┼─────┼─────┤      │## 🔌 Remote Events

│ │ …                                   │

│ └─────┴─────┴─────┴─────┴─────┘      │### Client → Server

├──────────────────────────────────────┤```lua

│ ◀ Previous    ← → keys    Next ▶     │inventoryRemote:FireServer("RequestInventory")

└──────────────────────────────────────┘inventoryRemote:FireServer("MoveItem", {

```    fromIndex = 1,

    toIndex = 2,

## Fast Workflow    swap = true

})

1. **Press G** → Browser opens instantly (same instance reused)inventoryRemote:FireServer("DropItem", {

2. **Navigate** → Use buttons or arrow keys to switch pages    itemId = "shovel",

3. **Click an item** → `InventoryEvent:FireServer("add_item", itemId)`    count = 1,

4. **Press E** → Inventory reflects new item    slotIndex = 1,

5. **Press ESC or G** → Browser hides (ScreenGui disabled, not destroyed)    worldPosition = Vector3.new(0, 1, 0)

})

## Server Interaction```



- Remote: `ReplicatedStorage.InventoryEvent`### Server → Client

- Client sends: `("add_item", itemId)````lua

- Server validates, inserts into slot list, and calls `SyncInventory`inventoryRemote:FireClient(player, "SyncInventory", {

- InventoryClient consumes `SyncInventory` payload and refreshes slots    maxSlots = 20,

    slots = {

## Important Files        [1] = { itemId = "shovel", count = 1 },

        [2] = { itemId = "net", count = 1 }

| File | Purpose |    }

|------|---------|})

| `src/client/init.client.luau` | Bootstraps client, registers keybinds |```

| `src/client/DebugInventoryGrid.lua` | Item browser singleton (modal logic) |

| `src/client/InventoryClient.lua` | Inventory UI/drag-drop system |## 🛠️ Key Functions

| `src/shared/ItemDataFetcher.lua` | Provides sorted item list (290 entries) |

| `src/shared/SpriteConfig.lua` | Sprite sheet math for offsets |### Find/Initialize

```lua

## Item Browser InternalsinitializeInventorySystem()  -- Finds GUI, validates structure

```

- Singleton stored on module table (`ItemBrowser._instance`)

- `ItemBrowser.toggleGlobal()` handles G key request and caches instance### Display

- `createGui()` runs only once; subsequent opens reuse the ScreenGui```lua

- `close()` simply disables the ScreenGui and detaches input listenerspopulateInventoryFromServer(data)  -- Updates all slots

- Keyboard handler reconnects on open and disconnects on closerefreshSlot(slotIndex)             -- Updates single slot

updateSlotAppearance(slot, state)  -- Renders item to UI

## Pagination Details```



- `itemsPerPage = 20`### Visibility

- `itemsPerRow = 5````lua

- Total pages = `math.ceil(290 / 20) = 15`setInventoryVisible(true)   -- Show inventory

- `renderPage()` rebuilds only current page buttons (UIGridLayout handles layout)setInventoryVisible(false)  -- Hide inventory

- Canvas height auto-calculated based on rows on that page```



## Sprite Rendering### Drag & Drop

```lua

```luabeginDrag(slotIndex)        -- Start drag

local zeroBased = item.spriteIndex - 1finishDrag(mousePos)        -- Complete drag

local col = zeroBased % SpriteConfig.COLUMNS```

local row = math.floor(zeroBased / SpriteConfig.COLUMNS)

local offsetX = SpriteConfig.OUTER.X + col * (SpriteConfig.TILE + SpriteConfig.INNER.X)## 📊 Item Data Structure

local offsetY = SpriteConfig.OUTER.Y + row * (SpriteConfig.TILE + SpriteConfig.INNER.Y)

imageLabel.Image = SpriteConfig.SHEET_ASSET```lua

imageLabel.ImageRectOffset = Vector2.new(offsetX, offsetY)ItemData = {

imageLabel.ImageRectSize = Vector2.new(36, 36)    shovel = { index = 2, name = "Shovel" },

```    net = { index = 3, name = "Net" },

    -- ... 114 more items

## Troubleshooting}

```

| Symptom | Fix |

|---------|-----|## 🎨 GUI Requirements

| G key does nothing | Ensure `InventoryEvent` is replicated and `SpriteConfig` loads | 

| Browser rebuilt each press | Call `ItemBrowser.toggleGlobal()` (already wired in `init.client.luau`) |```

| Names show IDs | Integrate `nookipedia_items.json` to map `spriteIndex → name` |PlayerGui

| Items not adding | Check server logs for `[Server] Debug: Added` confirmation |└── InventoryGUI (ScreenGui)

| Inventory empty after add | Verify `SyncInventory` fires and InventoryClient refreshes slots |    └── InventoryFrame (Frame)

        └── InventoryItems (ScrollingFrame)

## Next Enhancements            └── ItemSlotTemplate (Frame)

                ├── ItemIcon (ImageLabel)

1. Load real item names from `nookipedia_items.json`                ├── ItemCount (TextLabel)

2. Add search / filtering UI into the title bar                └── ItemName (TextLabel)

3. Provide category tabs (furniture, tools, clothing, etc.)```

4. Implement quick-fill and favorites for rapid testing

## ⚙️ Configuration

Stay focused on the three core files above; everything else is support code.

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
