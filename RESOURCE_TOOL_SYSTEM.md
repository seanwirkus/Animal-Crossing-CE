# Resource and Tool Interaction System

## Overview

The Resource and Tool Interaction System manages natural resources (trees and rocks) on the island and handles player interactions with tools (axe, shovel, net, etc.).

## Architecture

### Server-Side Systems

#### 1. ResourceSpawner (`src/server/ResourceSpawner.luau`)

Manages spawning and respawning of natural resources.

**Features:**
- Spawns trees and rocks on terrain and islands
- Tracks resource counts per island
- Handles resource respawn timers (5 minutes by default)
- Maintains minimum resource counts on each island
- Automatically populates terrain with resources on startup

**Configuration:**
```lua
local CONFIG = {
    TREE_RESPAWN_TIME = 300, -- 5 minutes
    ROCK_RESPAWN_TIME = 300, -- 5 minutes
    MIN_TREES_PER_ISLAND = 15,
    MAX_TREES_PER_ISLAND = 25,
    MIN_ROCKS_PER_ISLAND = 6,
    MAX_ROCKS_PER_ISLAND = 12,
}
```

**Key Methods:**
- `ResourceSpawner.new()` - Creates new instance
- `ResourceSpawner:initialize()` - Starts resource management
- `ResourceSpawner:markTreeChopped(tree, islandName)` - Queue tree for respawn
- `ResourceSpawner:markRockBroken(rock, islandName)` - Queue rock for respawn
- `ResourceSpawner:populateTerrainResources()` - Populates terrain with initial resources

#### 2. ToolInteractionSystem (`src/server/ToolInteractionSystem.luau`)

Handles tool interactions with resources and rewards players.

**Features:**
- Processes axe chopping (3 hits to fell a tree)
- Processes rock hitting with shovel (8 hits to deplete)
- Drops resources into player inventory
- Integrates with ResourceSpawner for respawn
- Fires quest events for player actions

**Configuration:**
```lua
local CONFIG = {
    AXE_RANGE = 10,
    PICKAXE_RANGE = 10,
    CHOPS_TO_FELL_TREE = 3,
    HITS_TO_BREAK_ROCK = 8,
}
```

**Resource Drops:**
```lua
-- Trees drop:
- wood: 3-5 pieces
- softwood: 2-4 pieces

-- Rocks drop:
- stone: 2-4 pieces
- iron_nugget: 1-3 pieces
- clay: 1-2 pieces
```

**Key Methods:**
- `ToolInteractionSystem.new(resourceSpawner)` - Creates new instance
- `ToolInteractionSystem:initialize()` - Sets up remote events
- `ToolInteractionSystem:setAddItemFunction(addItemFunc)` - Connects to inventory system
- `ToolInteractionSystem:handleToolUse(player, data)` - Processes tool use requests

### Client-Side Systems

#### 1. ToolController (`src/client/Modules/ToolController.luau`)

Manages tool activation and sends requests to server.

**Features:**
- Monitors equipped tools
- Handles left-click and right-click tool activation
- Sends tool use requests to server
- Supports: axe, shovel, net, watering can

**Supported Tools:**
- **Axe**: Chop trees (left-click or right-click)
- **Shovel**: Hit rocks (left-click or right-click)
- **Net**: Catch bugs (left-click or right-click)
- **Watering Can**: Water plants (left-click or right-click)

**Tool Request Format:**
```lua
{
    toolType = "axe" | "pickaxe" | "net" | "watering_can",
    action = "chop" | "hit" | "swing" | "water",
    toolId = player:GetAttribute("EquippedToolId"),
    position = humanoidRootPart.Position,
}
```

#### 2. ToolObjects (`src/shared/ToolObjects.luau`)

Creates and equips tool models on the character.

**Features:**
- Creates custom 3D tool models
- Handles tool equipping/unequipping
- Sets `EquippedToolType` attribute on player
- Prevents character sitting while tool equipped

**Supported Tool Types:**
```lua
- axe, flimsy_axe, stone_axe, golden_axe
- shovel, flimsy_shovel, stone_shovel, golden_shovel
- net, flimsy_net, stone_net, golden_net
- fishing_rod, flimsy_rod
- watering_can
- slingshot
```

## Integration

### Server Initialization (`src/server/init.server.luau`)

```lua
-- Initialize Resource Spawner
local resourceSpawner = ResourceSpawner.new()
resourceSpawner:initialize()

-- Initialize Tool Interaction System
local toolInteractionSystem = ToolInteractionSystem.new(resourceSpawner)
toolInteractionSystem:initialize()
toolInteractionSystem:setAddItemFunction(addItemToInventory)
```

### Client Initialization (`src/client/Client.luau`)

```lua
-- Initialize ToolController
local ToolController = require(script.Modules.ToolController)
ToolController.init()
```

## Usage

### As a Player

1. **Equip a tool**: Press `T` to open tool wheel, select a tool
2. **Use the tool**:
   - **Axe**: Stand near a tree, left-click or right-click (3 hits to chop down)
   - **Shovel**: Stand near a rock, left-click or right-click (8 hits to deplete)
3. **Collect resources**: Resources automatically go to your inventory
4. **Wait for respawn**: Trees and rocks respawn after 5 minutes

### Resource Tagging

All resources have a `ResourceTag` StringValue:
- Trees: `ResourceTag.Value = "tree"`
- Rocks: `ResourceTag.Value = "rock"`

Additionally, each resource has:
- Trees: `TreeTag` BoolValue
- Rocks: `RockTag` BoolValue

### Adding Custom Resources

To add custom tree/rock models to your island:

1. Create a Model in the workspace
2. Add a `ResourceTag` StringValue with value "tree" or "rock"
3. Add a `TreeTag` or `RockTag` BoolValue
4. Place it under your island folder in `Workspace/Islands/[IslandName]`

The ResourceSpawner will automatically detect and manage it.

## Remote Events

### ToolEvents Folder

Located in `ReplicatedStorage/RemoteEvents/ToolEvents/`

**ToolUse** - Client to Server
```lua
-- Client sends:
toolUseRemote:FireServer({
    toolType = "axe",
    action = "chop",
    position = Vector3.new(x, y, z),
})
```

## Testing

### In Roblox Studio:

1. Press F5 to start the game
2. Press `T` to open tool wheel
3. Select an axe or shovel
4. Right-click near a tree or rock
5. Check console for debug logs:
   - `[ToolController] 🪓 Axe chop requested`
   - `[ToolInteractionSystem] 🪓 Player hit tree`
   - `[ToolInteractionSystem] ✅ Gave wood x3 to Player`

### Debug Commands:

Check resource counts:
```lua
-- Server console
print(resourceSpawner.islandResources)
```

Manually spawn resources:
```lua
-- Server console
local position = Vector3.new(0, 20, 0)
resourceSpawner:spawnTree(workspace, position)
resourceSpawner:spawnRock(workspace, position)
```

## Known Issues

### Fixed:
- ✅ EquippedToolType attribute now set for all tools (not just shovels)
- ✅ ToolController now supports shovel for rock hitting
- ✅ Tool activation properly connected to ToolInteractionSystem

### Outstanding:
- Resource models are simple primitives (need better models)
- No visual feedback for tool durability
- No animations for chopping/hitting

## Future Enhancements

1. **Fruit Trees**: Trees that can be shaken for fruit
2. **Tree Types**: Different tree species (oak, pine, palm)
3. **Rock Types**: Different rock types (normal, gold, gem)
4. **Tool Durability**: Tools break after certain uses
5. **Visual Effects**: Particles, shake animations
6. **Rare Spawns**: Special resources with better drops
7. **Seasonal Changes**: Different resources by season

## Related Documentation

- [ToolObjects Guide](./docs/TOOL_OBJECTS_GUIDE.md)
- [Inventory System](./INVENTORY_SYSTEM.md)
- [Quest System](./QUEST_SYSTEM.md)
- [Onboarding Tutorial](./ONBOARDING_GUIDE.md)
