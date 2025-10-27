# Animal Crossing CE - Inventory System Instructions for AI Assistants

## CRITICAL: Custom GUI Already Exists in Roblox Studio

**Sean has already created a custom GUI in Roblox Studio.** The client code should ONLY manipulate the existing GUI structure - it should NOT create new GUIs or modify styling.

### DO NOT:
- Create new ScreenGui objects
- Create new Frame/ScrollingFrame objects for inventory display
- Add GUI styling, colors, rounded corners, or visual effects
- Create debug GUIs or test tools
- Add W key handlers or world item features

### DO:
- Find and use the EXISTING inventory GUI structure in the Roblox Studio hierarchy
- Populate inventory slots based on server data
- Handle drag & drop between inventory slots
- Update item icons, quantities, and names
- Work with the existing RemoteEvent to sync with the server

## Expected GUI Structure

The code expects to find this hierarchy already built in Roblox Studio:

```
PlayerGui
└── InventoryGUI (ScreenGui)
    └── InventoryFrame (Frame)
        ├── InventoryItems (ScrollingFrame)
        │   ├── ItemSlotTemplate (Frame) - template for slots
        │   │   ├── ItemIcon (ImageLabel)
        │   │   ├── ItemCount (TextLabel)
        │   │   └── ItemName (TextLabel)
        │   ├── Slot_1 (Frame) - cloned from template
        │   ├── Slot_2 (Frame)
        │   └── ... more slots
        └── [Other GUI elements you designed]
```

## Key Code Functions

### Main Functions:
- `initializeInventorySystem()` - Finds existing GUI and initializes
- `populateInventoryFromServer(data)` - Updates GUI with server inventory data
- `setInventoryVisible(shouldShow)` - Shows/hides inventory with animations
- `refreshSlot(slotIndex)` - Updates a single slot's appearance
- `beginDrag(slotIndex)` - Starts drag operation
- `finishDrag(mousePos, cancelled)` - Ends drag operation and sends to server

### Remote Events:
- **Action: "RequestInventory"** - Client requests current inventory
- **Action: "MoveItem"** - Client sends when player moves items between slots
- **Action: "DropItem"** - Client sends when player drops item in world
- **Event: "SyncInventory"** - Server sends to update client inventory display

## What the Server Should Handle

The server-side code should:
1. Listen for "RequestInventory" and send back current player inventory
2. Listen for "MoveItem" and validate/process swaps
3. Listen for "DropItem" and spawn items in the world
4. Send "SyncInventory" events to keep client GUI in sync
5. Define maxSlots based on game rules
6. Validate all inventory changes according to game logic

## Controls (Already Implemented)

- **E Key**: Toggle inventory open/close
- **Mouse Drag**: Move items between slots or drop in world

## Sprite System

Items use a sprite sheet with coordinates:
- Asset: `rbxassetid://74324628581851`
- Grid: 21 columns × 24 rows
- Each sprite is 36.6 pixels with padding
- `ItemData` table maps item IDs to sprite indices

## Important Notes

1. **DO NOT add new input handlers** (W key, G key, etc.)
2. **DO NOT create or modify GUI structure** - only populate existing elements
3. **DO NOT add visual effects** - that's already in the Roblox Studio design
4. **Focus on logic only** - inventory state management, drag/drop, server sync
5. **The GUI is "owned" by Rojo/Roblox Studio** - treat it as an external asset

## If You Need to Modify the Client:

1. Check the current function signatures
2. Only modify logic inside functions
3. Don't add new GUI creation code
4. Don't add new input handlers
5. Keep all SpriteConfig and ItemData references intact
6. Make sure server communication still works

---

**Last Updated**: October 26, 2025
**For**: Animal Crossing Custom Edition
**Created by**: Sean Wirkus
