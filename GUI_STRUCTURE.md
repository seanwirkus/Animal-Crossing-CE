# Roblox Studio GUI Structure Reference

## Expected Hierarchy for Animal Crossing CE Inventory

Your GUI in Roblox Studio should match this structure:

```
StarterPlayer
└── StarterCharacterScripts
└── StarterPlayerScripts
    └── PlayerGui (auto-created by Roblox)
        └── InventoryGUI (ScreenGui)
            ├── InventoryFrame (Frame)
            │   ├── InventoryItems (ScrollingFrame)
            │   │   └── ItemSlotTemplate (Frame) ← Template to be cloned
            │   │       ├── ItemIcon (ImageLabel)
            │   │       ├── ItemCount (TextLabel)
            │   │       └── ItemName (TextLabel)
            │   └── [Other elements you designed]
            └── [Other ScreenGui elements]
```

## Required Element Names (Case-Sensitive)

### Main Containers
| Element Name | Type | Purpose |
|---|---|---|
| `InventoryGUI` | ScreenGui | Main container |
| `InventoryFrame` | Frame | Frame containing all inventory UI |
| `InventoryItems` | ScrollingFrame | Container for inventory slots |
| `ItemSlotTemplate` | Frame | Template frame cloned for each slot |

### Template Children
| Element Name | Type | Parent | Purpose |
|---|---|---|---|
| `ItemIcon` | ImageLabel | ItemSlotTemplate | Displays item sprite |
| `ItemCount` | TextLabel | ItemSlotTemplate | Shows quantity (e.g., "5") |
| `ItemName` | TextLabel | ItemSlotTemplate | Shows item name on hover |

## What the Client Does

1. **On Script Load**:
   - Waits for PlayerGui to exist
   - Searches for `InventoryGUI` ScreenGui
   - Finds `InventoryFrame` inside it
   - Finds `InventoryItems` ScrollingFrame inside frame
   - Finds `ItemSlotTemplate` inside items

2. **When Inventory Opens (E Key)**:
   - Makes `InventoryFrame` visible
   - Requests inventory data from server
   - Populates slots by cloning the template

3. **When Server Sends Data**:
   - Updates each slot's ItemIcon image (sprite)
   - Updates ItemCount text (quantity)
   - Updates ItemName text (item name)
   - Stores state locally for drag/drop

4. **On Item Drag**:
   - Creates a "ghost" of the template
   - Tracks mouse movement
   - On drop: validates destination and sends to server

## Customization Notes

You can customize:
- ✅ Frame colors and transparency
- ✅ Font, text size, and alignment
- ✅ Position and size of all elements
- ✅ Animations and transitions
- ✅ Additional UI elements (titles, labels, etc.)
- ✅ ScrollingFrame styling

You should NOT change:
- ❌ Element names (ItemIcon, ItemCount, etc.)
- ❌ Parent hierarchy
- ❌ ItemSlotTemplate structure (it gets cloned)

## Testing Your Setup

1. Open Roblox Studio
2. Build your GUI with the structure above
3. Copy the init.client.luau script to PlayerScripts
4. Run the game
5. Check the Output window for debug messages
6. Press E to test opening inventory
7. Server should send inventory data and populate slots

## Troubleshooting

If you see errors like:
- `"Could not find InventoryGUI"` → Check that InventoryGUI exists as a ScreenGui child of PlayerGui
- `"Could not find InventoryFrame"` → Check that InventoryFrame is a child of InventoryGUI
- `"Could not find InventoryItems"` → Check that InventoryItems is a child of InventoryFrame
- `"Could not find ItemSlotTemplate"` → Check that ItemSlotTemplate is a child of InventoryItems

---

**Version**: 1.0
**Date**: October 26, 2025
**For**: Animal Crossing CE
