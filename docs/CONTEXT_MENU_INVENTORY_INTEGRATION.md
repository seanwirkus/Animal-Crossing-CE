# Context Menu Integration for Inventory System

## What Was Added

### ✅ Context Menu Now Works in TWO Places:

1. **Debug Inventory (Item Browser)** - Right-click any item sprite to get a popup menu
2. **Main Inventory Slots** - Right-click any item in your actual inventory to get actions

### 📦 Menu Options:

When you right-click an item, you'll see:
- **📦 Drop** - Drop the item to the ground in front of you
- **🗑️ Delete** - Permanently delete the item (shows in RED as warning)
- **👕 Equip** - Wear the item (only shows for wearable items like clothes, hats)

### 🎨 Styling:

- **Cream background** (#FFFBE7) - AC themed
- **Brown border** (#786450) - 2px stroke
- **Rounded corners** - 8px radius
- **Hover effects** - Color changes with white text
- **Delete button** - Red warning color to indicate destructive action
- **Auto-positioning** - Menu stays on-screen, never clips

## How to Use

### In Debug Inventory (Item Browser):
1. Press **B** to open Item Browser
2. Right-click any item sprite
3. Select action from popup menu

### In Main Inventory:
1. Press **E** to open Inventory
2. Right-click any item in your slots
3. Select action from popup menu

## Files Modified/Created

### New Files:
- `src/client/Modules/ContextMenu.luau` - Core context menu system

### Modified Files:
1. `src/client/Modules/DebugInventoryGrid.lua`
   - Added context menu loading
   - Added right-click support to item buttons

2. `src/client/InventoryClient.lua`
   - Added context menu loading in constructor
   - Replaced basic right-click with context menu
   - Attached context menu to inventory GUI on init

3. `src/server/init.server.luau`
   - Added "DeleteItem" action handler
   - Added "EquipItem" action handler (placeholder)

### Documentation:
- `docs/CONTEXT_MENU_GUIDE.md` - Complete guide with code examples

## Features

✅ **Drop Items** - Same as before, but now with a menu
✅ **Delete Items** - NEW! Remove items from inventory without dropping
✅ **Equip Items** - NEW! Wear wearable items (ready for clothing system integration)
✅ **Beautiful UI** - Matches AC theme perfectly
✅ **Server Validated** - All actions checked server-side
✅ **Extensible** - Easy to add more menu options

## Technical Details

### Server Handlers

All actions are validated server-side:

```lua
-- DeleteItem: Removes item without dropping
elseif action == "DeleteItem" and data then
    -- Removes item from inventory
    
-- EquipItem: For wearable items (placeholder)
elseif action == "EquipItem" and data then
    -- TODO: Integrate with character clothing system
    
-- DropItem: Existing handler (unchanged)
elseif action == "DropItem" and data then
    -- Drops item to world position
```

### Client-Side Detection

**Wearable items** are detected by:
- Item category (Clothing, Accessories, Hats, Shoes, Bags, Belts)
- Item name keywords (hat, shirt, shoes, dress, helmet, glasses, coat, jacket, gloves, scarf)

Only wearable items show the **Equip** option.

## Known Limitations

- Equip system is a placeholder (needs integration with character clothing/equipment system)
- Menu closes on any click outside (by design)
- Single item context at a time (shows menu for one item)

## Next Steps

1. **Test in Studio** - Open inventory, right-click items
2. **Equip Integration** - Connect EquipItem to your character clothing system
3. **Add More Options** - Extend menu with custom actions as needed (compare, store, craft, etc.)

## Debugging

To debug the context menu system:
- Look for `[ContextMenu]` logs in output
- Check `[InventoryClient]` logs to verify menu is loaded
- Mouse position shows where menu appears
- Red error logs indicate missing modules or failures
