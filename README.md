# Animal Crossing CE - Roblox Game

A complete Animal Crossing: New Horizons-inspired game built in Roblox, featuring inventory management, crafting, item browsing, and more.

## 🚀 Getting Started

### Building the Project

To build the place from scratch, use:

```bash
rojo build -o "Animal Crossing CE.rbxlx"
```

Next, open `Animal Crossing CE.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).

### Static Checks & Continuous Integration

Install the shared toolchain once per machine, then run the bundled script before every commit:

```bash
aftman install
bash tools/run_static_checks.sh
```

`tools/run_static_checks.sh` runs Stylua formatting (in check mode), Selene linting, Luau-LSP static analysis, RemoteEvent manifest validation, and a full `rojo build`. The same sequence executes automatically in GitHub Actions (`.github/workflows/luau-ci.yml`) on every push and pull request.

## 📋 Key Features

### ✅ Inventory System
- **Persistent Inventory**: Player inventories are saved to DataStore and persist across sessions
- **Multi-level Inventory**: Starts with 10 slots, can be upgraded
- **Drag-and-Drop**: Click-to-pick, click-to-drop system similar to Minecraft
- **Item Sprites**: High-resolution sprite sheet with 250px sprites and 10px padding
- **Visual Feedback**: Ghost item follows cursor while dragging

### ✅ Crafting System
- **80+ Recipes**: Full crafting system with recipes and materials
- **Recipe Browser**: Beautiful GUI to browse all available recipes (R key)
- **Crafting Menu**: Debug crafting menu with instant crafting (C key)
- **Material Checking**: Automatic validation of required materials
- **Result Sprites**: DIY recipe icons with 300px sprites

### ✅ Item Browser
- **494 Items**: Browse all items in a scrollable grid (B key)
- **Sprite Display**: Shows all items with their sprites from the sprite sheet
- **Add to Inventory**: Click any item to add it directly to your inventory
- **Visual Styling**: Matches the cream/beige theme of other GUIs

### ✅ GUI Management System
- **Exclusive Visibility**: Only one GUI can be visible at a time
- **Automatic Switching**: Opening a new GUI automatically hides the current one
- **ESC to Close**: Press ESC to close any open GUI
- **Unified Styling**: All GUIs use consistent cream/beige color scheme

### 🤖 AI Procedural Generation System
- **Self-Improving AI**: Generator learns from rejections, improving over time (50%→78% approval)
- **ACNH-Accurate Rules**: Follows real Animal Crossing placement rules (spacing, clustering, slopes)
- **Terrain Analysis**: Scans existing terrain with spatial grid for fast queries
- **AI Auditor**: Validates placements with 0-100 scoring system
- **Iterative Learning**: Tracks rejection reasons and adjusts future proposals
- **Test Interface**: 8 ready-to-use test functions via Server Command Bar
- **See**: `docs/AI_ISLAND_GENERATION_GUIDE.md` and `docs/TESTING_AI_GENERATION.md`

### 🎬 Cutscene & Loading Systems
- **Cutscene Manager**: Camera control, fade transitions, sequence orchestration
- **Loading Screen**: ACNH-style with rotating Nook Leaf, random tips, progress bar
- **Onboarding Flow**: Complete dialogue → island selection → loading → cutscene → spawn
- **See**: `docs/CUTSCENES_AND_LOADING_GUIDE.md`

## 🎮 Controls & Keybinds

| Key | Action | Description |
|-----|--------|-------------|
| **E** | Inventory | Open/close inventory |
| **R** | Recipes | Open recipe browser |
| **C** | Crafting | Open crafting menu |
| **B** | Item Browser | Open item browser (debug) |
| **G** | Debug GUI | Open debug manager |
| **ESC** | Close GUI | Close currently open GUI |

## 🧪 Testing AI Island Generation

**⚠️ IMPORTANT**: The Command Bar must be in **Server** context!

```lua
-- In Server Command Bar (change dropdown from "Client" to "Server"):
_G.testSystem.quickTest()           -- Generate 10 trees (quick test)
_G.testSystem.fullGeneration()      -- Full island generation (10 cycles)
_G.testSystem.watchLearning()       -- Watch AI improve (20 cycles)
_G.testSystem.clearAll()            -- Delete generated objects
```

**Alternative**: Edit `src/server/QuickTestRunner.server.luau` and press F5 to reload.

**Full Guide**: See `docs/TESTING_AI_GENERATION.md`

## 🏗️ Project Structure

```
src/
├── client/
│   ├── init.client.luau          # Client entry point
│   ├── InventoryClient.lua        # Main inventory logic
│   ├── KeybindManager.lua        # Centralized keybind system
│   └── Modules/
│       ├── GUIManager.luau       # Exclusive GUI visibility manager
│       ├── DebugInventoryGrid.lua # Item browser GUI
│       ├── DebugCraftingMenu.lua  # Crafting menu GUI
│       ├── RecipesInventoryGUI.luau # Recipe browser GUI
│       └── InventoryGuiSetup.lua  # GUI creation helpers
├── server/
│   ├── init.server.luau          # Server entry point
│   └── CraftingSetup.luau        # Crafting system setup
└── shared/
    ├── SpriteConfig.luau          # Sprite sheet configuration
    ├── SpriteManifest.luau        # Item-to-sprite mapping
    ├── ItemDataFetcher.luau      # Item and recipe data fetcher
    └── CraftingSystem.luau        # Core crafting logic
```

## 🎨 Sprite System

### Main Item Spritesheet
- **Asset ID**: `rbxassetid://79857338226248`
- **Grid**: 21 columns × 24 rows = 504 slots
- **Sprite Size**: 250px × 250px
- **Padding**: 10px between sprites and around edges
- **Outer Padding**: 10px

### DIY Recipe Icons Spritesheet
- **Asset ID**: `rbxassetid://97942095241212`
- **Grid**: 26 columns × 23 rows = 598 icons
- **Icon Size**: 300px × 300px
- **Padding**: 10px between icons

### Configuration
The sprite system uses fixed dimensions for accuracy:
```lua
SPRITE_SIZE = 250      -- Each sprite is 250px × 250px
PADDING = 10           -- Padding between sprites
OUTER_PADDING = 10     -- Padding around edges
```

## 🔧 Systems Overview

### GUIManager
Manages exclusive GUI visibility so only one GUI can be open at a time:
- Automatically hides current GUI when opening a new one
- Supports different GUI object types (Show/Hide, setInventoryVisible, etc.)
- Tracks currently visible GUI
- Provides unified toggle/show/hide methods

### KeybindManager
Centralized keybind system:
- All keybinds defined in one place
- Handles InputBegan and InputEnded events
- Error handling with pcall and stack traces
- Debug logging for key presses

### Inventory System
Client-server inventory management:
- Drag-and-drop with click-to-pick system
- Server-side validation and persistence
- Auto-saves every 30 seconds
- Saves on player leave and inventory changes
- Level-based slot limits

### Crafting System
Complete crafting implementation:
- Recipe validation
- Material consumption
- Item creation
- Instant crafting (debug mode)
- Material availability checking

## 🐛 Debug Features

### Item Browser (B key)
- Browse all 494 items from the sprite sheet
- See sprite indices and item names
- Click to add items directly to inventory
- Shows mapped and unmapped items

### Crafting Menu (C key)
- View all recipes in a grid
- See required materials and quantities
- Instant crafting (no wait time)
- Material icons with counts

### Debug Manager (G key)
- Tabbed interface for debug tools
- Centralized debug UI

## 💾 Data Persistence

### Player Inventory
- Saved to DataStore: `PlayerInventories`
- Auto-saves every 30 seconds
- Saves on player leave
- Saves after inventory modifications

### Data Structure
```lua
{
    level = 1,           -- Inventory level (determines slot count)
    slots = {            -- Array of slot states
        {itemId = "leaf", count = 5},
        -- ...
    }
}
```

## 🎨 Styling

All GUIs use a consistent cream/beige theme:
- **Main Background**: `Color3.fromRGB(255, 251, 231)` (Cream)
- **Title Bar**: `Color3.fromRGB(120, 100, 80)` (Brown)
- **Details Panel**: `Color3.fromRGB(231, 221, 185)` (Beige)
- **Accent Color**: `Color3.fromRGB(4, 175, 166)` (Teal/Green)

Rounded corners (8px radius) and consistent spacing throughout.

## 📝 Recent Updates

### GUI Management System
- Implemented GUIManager for exclusive GUI visibility
- All keybinds now properly switch between GUIs
- ESC key closes current GUI

### Sprite Configuration
- Updated to fixed dimensions approach
- Direct pixel values (250px sprites, 10px padding)
- Removed complex scaling calculations

### Debug Inventory
- Fixed visibility issues
- Enhanced Show/Toggle methods
- Proper ScreenGui enabling

### Keybind System
- Improved error handling
- Better debugging output
- Connection verification

## 🔮 Future Enhancements

- [ ] Tool wheel system (T key)
- [ ] Map/Navigation system (M key)
- [ ] Emote system (V key)
- [ ] Settings menu
- [ ] Inventory upgrades system
- [ ] Recipe discovery system
- [ ] Crafting stations

## 📚 Additional Documentation

- See `PROJECT_PLAN.md` for detailed project plans
- See `QUICK_REFERENCE.md` for quick command reference
- Check `gold mine of info/docs/` for comprehensive documentation

## 🤝 Contributing

This is a personal project, but feel free to fork and modify for your own use!

## 📄 License

This project is for educational purposes. Animal Crossing is a trademark of Nintendo Co., Ltd.

---

**Last Updated**: December 2024
