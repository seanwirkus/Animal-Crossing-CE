# Quick Reference - Animal Crossing CE

## 🎮 Keybinds

| Key | Action | Description |
|-----|--------|-------------|
| **E** | Inventory | Toggle inventory GUI |
| **R** | Recipes | Open recipe browser GUI |
| **C** | Crafting | Open crafting menu (debug) |
| **B** | Item Browser | Open item browser (debug) |
| **G** | Debug GUI | Open debug manager |
| **ESC** | Close GUI | Close currently open GUI |

## 📁 File Structure

```
src/
├── client/
│   ├── init.client.luau          # Client entry point & initialization
│   ├── InventoryClient.lua       # Main inventory logic & drag-and-drop
│   ├── KeybindManager.lua        # Centralized keybind system
│   └── Modules/
│       ├── GUIManager.luau       # Exclusive GUI visibility manager
│       ├── DebugInventoryGrid.lua # Item browser GUI (B key)
│       ├── DebugCraftingMenu.lua  # Crafting menu GUI (C key)
│       ├── RecipesInventoryGUI.luau # Recipe browser GUI (R key)
│       └── InventoryGuiSetup.lua  # GUI creation helpers
├── server/
│   ├── init.server.luau          # Server entry point & inventory persistence
│   └── CraftingSetup.luau        # Crafting system setup
└── shared/
    ├── SpriteConfig.luau          # Sprite sheet configuration (fixed dimensions)
    ├── SpriteManifest.luau        # Item-to-sprite index mapping
    ├── ItemDataFetcher.luau       # Item & recipe data fetcher
    └── CraftingSystem.luau         # Core crafting logic
```

## 🎯 GUI System

### GUIManager
- **Purpose**: Ensures only one GUI is visible at a time
- **Behavior**: Opening a new GUI automatically hides the current one
- **Methods**:
  - `registerGUI(name, guiObject)` - Register a GUI
  - `toggleGUI(name)` - Toggle a GUI (show/hide)
  - `showGUI(name)` - Show a GUI (hides current)
  - `hideGUI(name)` - Hide a GUI
  - `getCurrentVisible()` - Get currently visible GUI name

### Available GUIs
- **inventory** - Main inventory (E key)
- **recipes** - Recipe browser (R key)
- **crafting** - Crafting menu (C key)
- **itemBrowser** - Item browser (B key)
- **debug** - Debug manager (G key)

## 📦 Inventory System

### Features
- **Click-to-Pick**: Click an item to attach it to cursor
- **Click-to-Drop**: Click again to drop in slot or world
- **Drag-and-Drop**: Visual ghost item follows cursor
- **Persistence**: Auto-saves every 30 seconds + on leave
- **Level System**: Slots unlock with inventory level (starts at 10 slots)

### Data Flow
1. Client requests inventory from server
2. Server loads from DataStore (`PlayerInventories`)
3. Server sends inventory data to client
4. Client displays items in slots
5. Client handles drag/drop locally
6. Client sends updates to server
7. Server validates and saves to DataStore

### Inventory Actions
- **MoveItem**: Move item between slots
- **SwapItem**: Swap two items
- **DropItem**: Drop item to world
- **add_item**: Add item to inventory (from browser/crafting)

## 🎨 Sprite System

### Configuration (SpriteConfig.luau)
```lua
-- Main item spritesheet
SPRITE_SIZE = 250          -- Each sprite is 250px × 250px
PADDING = 10              -- Padding between sprites
OUTER_PADDING = 10        -- Padding around edges
COLUMNS = 21              -- Grid columns
ROWS = 24                 -- Grid rows

-- DIY recipe icons
DIY_SPRITE_SIZE = 300     -- Each icon is 300px × 300px
DIY_PADDING = 10         -- Padding between icons
DIY_COLUMNS = 26          -- Grid columns
DIY_ROWS = 23             -- Grid rows
```

### Sprite Calculation
```lua
-- Calculate sprite position
cellWidth = SPRITE_SIZE + PADDING
offsetX = OUTER_PADDING + col * cellWidth
offsetY = OUTER_PADDING + row * cellWidth

-- Sprite size
rectSize = Vector2.new(SPRITE_SIZE, SPRITE_SIZE)
```

## 🔨 Crafting System

### Recipe Browser (R key)
- Shows all available recipes in a scrollable grid
- Displays recipe result sprite and name
- Shows required materials with owned/required counts
- Color-coded: Green if craftable, red if missing materials
- Click "Craft" button to craft item

### Crafting Menu (C key - Debug)
- Shows all recipes in a larger grid
- Shows station label, result icon, recipe name
- Displays materials with icons and counts
- Click "Craft" button for instant crafting
- Click materials to navigate to recipe (if available)

### Crafting Flow
1. Player opens recipe browser/crafting menu
2. System checks player inventory for materials
3. Recipe is highlighted if craftable
4. Player clicks "Craft" button
5. Server validates materials
6. Server consumes materials
7. Server adds result item to inventory
8. Client refreshes inventory display

## 🗂️ Item Browser (B key - Debug)

### Features
- Browse all 494 items from sprite sheet
- Shows sprite, index number, and item name
- Click any item to add it directly to inventory
- Scrollable grid layout
- Shows both mapped and unmapped items

### Item Display
- **Mapped Items**: Shows sprite, index, and name
- **Unmapped Items**: Shows placeholder (can't be added)
- **Layout**: 10 items per row in scrollable frame

## 💾 Data Persistence

### DataStore
- **Name**: `PlayerInventories`
- **Structure**: 
  ```lua
  {
      level = 1,
      slots = {
          {itemId = "leaf", count = 5},
          -- ...
      }
  }
  ```

### Save Triggers
- Every 30 seconds (auto-save)
- On player leave
- After inventory modifications:
  - MoveItem
  - SwapItem
  - DropItem
  - add_item
  - Crafting (material consumption)

## 🐛 Debug Commands

### Console Variables
Access these in Roblox Studio console:
- `_G.KeybindManager` - Keybind system
- `_G.InventoryClient` - Inventory client
- `_G.GUIManager` - GUI manager
- `_G.DebugInventoryGrid` - Item browser
- `_G.RecipesInventoryGUI` - Recipe browser

### Useful Commands
```lua
-- Toggle inventory
_G.GUIManager:toggleGUI("inventory")

-- Show item browser
_G.GUIManager:showGUI("itemBrowser")

-- Check current visible GUI
_G.GUIManager:getCurrentVisible()

-- Force refresh inventory
_G.InventoryClient:requestInventory()
```

## 🎨 Styling Guide

### Color Palette
```lua
CREAM = Color3.fromRGB(255, 251, 231)      -- Main background
BROWN = Color3.fromRGB(120, 100, 80)       -- Title bars
BEIGE = Color3.fromRGB(231, 221, 185)     -- Details panels
TEAL = Color3.fromRGB(4, 175, 166)         -- Accent/buttons
WHITE = Color3.fromRGB(255, 255, 255)      -- Text/backgrounds
DARK = Color3.fromRGB(60, 50, 40)          -- Dark text
```

### Typography
- **Title Font**: `Enum.Font.GothamBold`
- **Body Font**: `Enum.Font.Gotham`
- **Title Size**: 18-24px
- **Body Size**: 12-16px

### Layout
- **Corner Radius**: 8px
- **Padding**: 10px
- **Spacing**: 6-10px between elements

## 📝 Common Issues & Solutions

### Issue: Keybinds not working
**Solution**: Check console for connection errors. Ensure UserInputService is available.

### Issue: GUI not showing
**Solution**: 
- Check if ScreenGui is enabled: `gui.Enabled = true`
- Check if mainFrame is visible: `frame.Visible = true`
- Verify GUI is registered with GUIManager

### Issue: Sprites not displaying correctly
**Solution**: 
- Verify SpriteConfig dimensions match actual spritesheet
- Check ImageRectOffset and ImageRectSize are set correctly
- Ensure ImageTransparency = 0

### Issue: Inventory not saving
**Solution**:
- Enable Studio API access in Studio settings
- Check DataStore is accessible
- Verify save triggers are firing

## 🚀 Quick Setup Checklist

- [ ] Enable Studio API access (Settings → Security)
- [ ] Load all required modules (check console for errors)
- [ ] Verify GUIManager loads successfully
- [ ] Test keybinds (E, R, C, B, G)
- [ ] Test inventory drag-and-drop
- [ ] Test crafting system
- [ ] Verify DataStore persistence

---

**Last Updated**: December 2024
