# Context Menu System - Right-Click Item Actions

## Overview
The Context Menu system provides a right-click popup interface for quick item actions in the inventory browser. When you right-click any item, a stylish AC-themed menu appears with available actions.

## Features

### Menu Options
1. **📦 Drop** - Drop item to world in front of player
2. **🗑️ Delete** - Permanently delete item from inventory
3. **👕 Equip** - Equip wearable items (if applicable)

### Design
- **Styling**: Animal Crossing theme with CREAM (#FFFBE7) background
- **Borders**: BROWN (#786450) 2px stroke
- **Corners**: Rounded 8px corners (UICorner)
- **Hover Effects**: Color transitions with WHITE text on hover
- **Positioning**: Auto-clamps to screen boundaries to prevent off-screen menus

### Delete Option Styling
- Normal state: Light RED background (255, 200, 200)
- Hover state: Darker RED (255, 100, 100) with WHITE text
- Visual indicator that this is a destructive action

### Equip Option
- Only shows for wearable items (clothing, hats, accessories, etc.)
- Detected by category or item name keywords
- Ready for integration with character clothing system

## Implementation Details

### Files Modified
1. **src/client/Modules/ContextMenu.luau** (NEW)
   - Core context menu module
   - Handles menu creation, positioning, and actions
   - `show(item, mousePos)` - Display menu
   - `close()` - Hide menu
   - `dropItem(item)` - Drop to world
   - `deleteItem(item)` - Delete from inventory
   - `equipItem(item)` - Equip item
   - `isWearable(item)` - Check if item is wearable

2. **src/client/Modules/DebugInventoryGrid.lua** (MODIFIED)
   - Added context menu initialization in `new()`
   - Added right-click support in `createItemButton()`
   - Menu attaches to existing ScreenGui

3. **src/server/init.server.luau** (MODIFIED)
   - Added "DeleteItem" action handler
   - Added "EquipItem" action handler (placeholder)
   - DropItem already existed, no changes needed

### Server-Side Handlers

#### DeleteItem
```lua
-- Removes item from inventory without dropping to world
self.inventoryRemote:FireServer("DeleteItem", {
    itemId = item.id,
    count = item.count or 1,
})
```

#### EquipItem
```lua
-- Sends equip request to server (integrates with clothing system)
self.inventoryRemote:FireServer("EquipItem", {
    itemId = item.id,
})
```

#### DropItem
```lua
-- Existing handler - drops item to world in front of player
self.inventoryRemote:FireServer("DropItem", {
    itemId = item.id,
    count = item.count or 1,
    position = worldPosition,
})
```

## Usage

### For Players
1. Open Item Browser (Press **B**)
2. Right-click any item
3. Select desired action:
   - **Drop**: Item falls in front of player and becomes pickupable
   - **Delete**: Item is permanently deleted (RED warning color)
   - **Equip**: Wears the item (only for clothing/accessories)
4. Click outside menu or press ESC to close

### For Developers

#### Using the Context Menu Module Standalone
```lua
local ContextMenu = require(game:GetService("ReplicatedStorage").Shared.Modules.ContextMenu)
local contextMenu = ContextMenu.new(screenGui, inventoryRemote, itemDataFetcher)

-- Show menu at mouse position
contextMenu:show(item, mouse.Position)

-- Programmatically trigger actions
contextMenu:dropItem(item)
contextMenu:deleteItem(item)
contextMenu:equipItem(item)
contextMenu:close()
```

#### Adding New Menu Items
Modify the `createMenuItems()` method in `ContextMenu.luau`:
```lua
table.insert(items, {
    label = "🎨 Custom Action",
    action = function(item)
        -- Custom action code
    end,
    color = Color3.fromRGB(200, 220, 255),
    hoverColor = Color3.fromRGB(100, 150, 255)
})
```

## Integration Points

### With Character Clothing System
The `EquipItem` action is a placeholder ready for integration:
```lua
function ContextMenu:equipItem(item)
    -- TODO: Integrate with CharacterClothingSystem or similar
    self.inventoryRemote:FireServer("EquipItem", {
        itemId = item.id,
    })
end
```

Update server handler in `init.server.luau` to actually equip items:
```lua
elseif action == "EquipItem" and data then
    local itemId = data.itemId
    -- Call your character equipping system
    CharacterClothingSystem:EquipItem(player, itemId)
end
```

## Styling Customization

### Theme Colors
```lua
local CREAM = Color3.fromRGB(255, 251, 231)      -- #FFFBE7
local BROWN = Color3.fromRGB(120, 100, 80)       -- #786450
local DARK = Color3.fromRGB(60, 50, 40)
local WHITE = Color3.fromRGB(255, 255, 255)
```

### Menu Layout
```lua
local MENU_WIDTH = 160              -- Menu width in pixels
local MENU_ITEM_HEIGHT = 40         -- Height of each menu item
local CORNER_RADIUS = UDim.new(0, 8)  -- Corner roundness
local PADDING = 8                   -- Menu padding
```

## Features & Benefits

✅ **Quick Access** - Right-click instead of drag-and-drop for fast item management
✅ **Visual Feedback** - Hover effects and color coding
✅ **Auto-Positioning** - Menu stays on-screen, no clipping
✅ **AC Themed** - Matches game's aesthetic perfectly
✅ **Extensible** - Easy to add new menu options
✅ **Server Validated** - All actions validated server-side
✅ **Destruction Warning** - Delete option uses warning colors

## Known Limitations

- Equip system is placeholder (needs character clothing integration)
- Menu closes on any click outside (by design)
- Single item per menu (context for one item at a time)

## Future Enhancements

- Batch delete/drop for multiple items
- Duplicate item option
- Favorite/tag system
- Hotkey assignments
- Craft item shortcut
- Trade item option
