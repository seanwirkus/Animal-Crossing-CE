# Animal Crossing CE - AI Coding Assistant Instructions

## Project Overview
Animal Crossing CE is a complete Animal Crossing: New Horizons-inspired game built in Roblox using Luau. It features inventory management, crafting, item browsing, and more with a focus on faithful recreation of ACNH mechanics and aesthetics.

## Architecture Overview

### Core Structure
- **Client-Server Model**: Traditional Roblox architecture with client-side UI/logic and server-side validation/persistence
- **Rojo Workflow**: Live development with `rojo serve` for instant sync between filesystem and Roblox Studio
- **Module-Based**: Clean separation with `src/client/`, `src/server/`, and `src/shared/` directories
- **Event-Driven**: RemoteEvents in ReplicatedStorage for client-server communication

### Key Components
- **Inventory System**: Drag-and-drop with DataStore persistence, level-based slot limits
- **Crafting System**: 80+ recipes with material validation and instant crafting (debug mode)
- **Sprite System**: Fixed-dimension sprite sheets (250px sprites, 10px padding) with grid-based indexing
- **GUI Management**: Exclusive visibility system - only one GUI visible at a time
- **Keybind System**: Centralized KeybindManager with error handling and debug logging

## Critical Developer Workflows

### Development Setup
```bash
# Start live development
rojo serve

# Build for production
rojo build -o "Animal Crossing CE.rbxlx"
```

### Testing in Studio
1. Open `Animal Crossing CE.rbxlx` in Roblox Studio
2. Run `rojo serve` in terminal for live sync
3. Test with keybinds: E (inventory), B (item browser), C (crafting), G (debug)

### Debug Systems
- **Item Browser (B)**: Browse all 494 items, click to add to inventory
- **Crafting Menu (C)**: Instant crafting with material validation
- **Debug GUI (G)**: Tabbed interface for debug tools
- **Recipes (R)**: Browse all crafting recipes

## Project-Specific Conventions

### Code Style
- **Luau with Types**: Use type annotations for function parameters and return values
- **Module Pattern**: Each file returns a table/object with methods
- **Error Handling**: Use `pcall` for external operations, extensive debug logging
- **Naming**: PascalCase for classes/modules, camelCase for functions/variables

### UI Design
- **ACNH Theme**: Cream/beige backgrounds (`Color3.fromRGB(255, 251, 231)`), brown titles (`Color3.fromRGB(120, 100, 80)`), teal accents (`Color3.fromRGB(4, 175, 166)`)
- **Rounded Corners**: 8px radius throughout
- **Exclusive GUI**: Only one GUI visible at a time via GUIManager
- **Responsive Layout**: UI adapts to different screen sizes

### Sprite System
```lua
-- Fixed dimensions (DO NOT change these values)
SPRITE_SIZE = 250      -- Each sprite is exactly 250px
PADDING = 10           -- 10px padding between sprites
OUTER_PADDING = 10     -- 10px padding around edges

-- Calculate sprite rect for index
local offset, size = SpriteConfig.getSpriteRect(spriteIndex)
imageObject.ImageRectOffset = offset
imageObject.ImageRectSize = size
```

### Keybind System
```lua
-- Register keybind in KeybindManager
keybindManager:registerBind("INVENTORY", function(inputState)
    if inputState == "began" then
        -- Handle key press
    end
end)

-- Key codes defined in KEYBINDS table
INVENTORY = Enum.KeyCode.E
ITEM_BROWSER = Enum.KeyCode.B
CRAFTING = Enum.KeyCode.C
```

## Integration Points & Data Flow

### External Dependencies
- **Nookipedia API**: Item data fetched from JSON files, cached locally
- **Sprite Assets**: Hosted on Roblox (`rbxassetid://79857338226248`)
- **DataStore**: Player inventory persistence with auto-save every 30 seconds

### Client-Server Communication
```lua
-- Server-side event handling
inventoryRemote.OnServerEvent:Connect(function(player, action, data)
    if action == "DropItem" then
        -- Validate and process
        syncInventoryToClient(player)
    end
end)

-- Client-side event firing
inventoryRemote:FireServer("DropItem", {
    itemId = "leaf",
    count = 5,
    worldPosition = position
})
```

### Data Persistence
- **Inventory**: Saved as `{slots: {[index]: {itemId, count}}}`
- **Auto-save**: Every 30 seconds + on player leave + after changes
- **Validation**: Server-side validation before any inventory modifications

## Common Patterns & Best Practices

### Error Handling
```lua
local success, result = pcall(function()
    return externalOperation()
end)
if not success then
    warn("[ModuleName] Failed:", result)
    return fallbackValue
end
```

### GUI Creation
```lua
-- Always create ScreenGui first
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MyGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10  -- Higher = on top
screenGui.Parent = playerGui

-- Register with GUIManager for exclusive visibility
guiManager:registerGUI("mygui", myGUIInstance)
```

### Sprite Application
```lua
-- Use SpriteConfig for consistent sprite application
local success = SpriteConfig.applySprite(imageLabel, spriteIndex)
if not success then
    warn("Failed to apply sprite:", spriteIndex)
end
```

### Inventory Operations
```lua
-- Always validate server-side, never trust client
if not hasCraftingMaterials(player, materials) then
    return -- Reject invalid requests
end

-- Update inventory, then sync to client
consumeCraftingMaterials(player, materials)
syncInventoryToClient(player)
savePlayerInventory(player) -- Auto-persist
```

## Debugging & Troubleshooting

### Common Issues
- **GUI not showing**: Check GUIManager registration and exclusive visibility
- **Sprites not loading**: Verify spriteIndex exists in SpriteManifest
- **Keybinds not working**: Check KeybindManager registration and connection status
- **Inventory desync**: Check server validation and client sync calls

### Debug Tools Available
- **Item Browser (B)**: Test sprite loading and inventory addition
- **Crafting Menu (C)**: Test material validation and crafting logic
- **Debug GUI (G)**: Access various debug utilities
- **Console Logging**: Extensive debug output for all systems

## File Organization Reference

### Key Directories
- `src/client/` - Client-side logic, UI, input handling
- `src/server/` - Server validation, persistence, game logic
- `src/shared/` - Common utilities, data structures, constants
- `docs/` - Documentation and guides
- `tools/` - Development utilities and scripts

### Important Files
- `src/client/init.client.luau` - Client entry point, module loading
- `src/server/init.server.luau` - Server entry point, inventory system
- `src/shared/SpriteConfig.luau` - Sprite sheet configuration
- `src/shared/SpriteManifest.luau` - Item-to-sprite mappings
- `src/client/KeybindManager.lua` - Centralized input handling

## Performance Considerations

### Client Optimizations
- **GUI Management**: Exclusive visibility prevents overlap/rendering multiple GUIs
- **Sprite Loading**: Pre-calculated rects, efficient ImageRect usage
- **Input Handling**: Centralized keybind system with error boundaries

### Server Optimizations
- **DataStore Batching**: Auto-save throttling prevents rate limits
- **Validation Caching**: Item data cached to reduce API calls
- **Inventory Operations**: Efficient slot-based storage and updates

## Testing Guidelines

### Manual Testing Checklist
- [ ] Inventory drag-and-drop works correctly
- [ ] Item browser displays all sprites properly
- [ ] Crafting validates materials and produces items
- [ ] Keybinds respond appropriately (E, B, C, G, R)
- [ ] GUI exclusive visibility works (only one GUI visible)
- [ ] Data persistence survives rejoins
- [ ] Error handling provides useful feedback

### Automated Testing
- Use Roblox's built-in testing framework for unit tests
- Integration tests for client-server communication
- Performance tests for GUI rendering and inventory operations

Remember: This is a faithful recreation of Animal Crossing mechanics. When in doubt, reference the real ACNH game for expected behavior and UI patterns.
