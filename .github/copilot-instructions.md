# Animal Crossing CE - Copilot Instructions

## Project Overview
This is a production-ready Animal Crossing: New Horizons-inspired Roblox game built with **Rojo 7.6.0** for live script syncing. The project features island generation, NPC systems, inventory management, and an onboarding flow with persistent player data.

## Architecture & Data Flow

### Core Structure
- **Rojo-based**: Use `rojo serve` for live sync, never build unless deploying
- **Client-Server**: Strict separation via `src/client/`, `src/server/`, `src/shared/`
- **Service Pattern**: Server services auto-load via `init.server.luau`, client controllers via `init.client.luau`
- **Data-Driven**: Nookipedia JSON integration (~7k items, 500 characters) in `data/` folder

### Key Services & Systems
- **PlayerDataService**: Handles bells/miles currency, island data, inventory with DataStore persistence
- **IslandService**: Procedural terrain generation with deterministic seeding (1000 studs apart)
- **NPCManager**: Tom Nook, Isabelle, Orville + 2-5 random villagers per island
- **AssetManager**: Centralized asset lookup system supporting theme/sprite overrides
- **InventoryService**: Item management with sprite sheet system (21×24 grid, 290 items)

## Development Workflows

### Testing in Studio
1. Open `Place.rbxl` or main place file in Roblox Studio
2. Run `rojo serve` in terminal for live sync
3. Test onboarding: Walk to Tom Nook (yellow cube) → Press E → Complete island creation flow
4. Key test bindings: E (inventory), G (item browser), B (quest board), T (tools)

### Building & Deployment
```bash
# Development (live sync)
rojo serve

# Production build
rojo build -o "Animal Crossing CE.rbxlx"
```

### Data Management
- Upload `nookipedia_items.json` and `nookipedia_characters.json` to ReplicatedStorage/data/
- Sprite mappings in `SpriteManifest.luau` with 36.6px tiles, 6px inner spacing
- Asset overrides via `AssetManager` - supports folder-based and manifest-based theming

## Project-Specific Conventions

### Module Patterns
- **Services**: Use dependency injection, single responsibility, Logger integration
- **Remote Events**: All client-server communication via RemoteEvents (no RemoteFunctions)
- **Error Handling**: Structured 5-level logging with exponential backoff retry logic
- **Type Safety**: Luau types defined in `GameTypes.luau` for major systems

### File Extensions
- `.luau` for new files (preferred)
- `.lua` for legacy client files (maintain consistency within file)

### GUI Systems
- **ResponsiveGUI**: Component-based UI system for scalable interfaces
- **Animal Crossing Theme**: Cream backgrounds (`#FFFBE7`), brown accents (`#786450`), 8px corner radius
- **Currency Display**: Bells (🔔), Miles (✈️), Nook Miles icons in HUD

### NPC & Interaction Patterns
- **ProximityPrompts**: All NPC interactions use Proximity Prompts with E key
- **Spawner System**: Separate spawners for major NPCs (TomNookSpawner, IslandNPCManager)
- **Patrol Routes**: NPCWalker system with zone-specific movement patterns
- **Dialogue Flow**: Tom Nook onboarding → Island selection → Name entry → Generation → Teleport

## Data Integration

### Nookipedia System
- **ItemDataFetcher**: Sorts items by sprite index, handles ID variations and aliases
- **Character Data**: 499 characters with dialogue, schedules, and spawn locations
- **Asset Pipeline**: Sprite sheet `rbxassetid://74324628581851` with indexed positions

### Island Generation
- **3-tier islands**: Rivers, ponds, waterfalls, beaches, rocks, flowers
- **Deterministic seeding**: Based on player data for consistent regeneration
- **CollectionService tags**: For villager schedules, quest locations, resource nodes

## Common Debugging Patterns

### Infinite Yield Issues
Check `RemoteEvents` existence before `:WaitForChild()` - use timeout parameters or validate in server first.

### Asset Loading
Use `AssetManager:GetModel()`, `GetSprite()`, `GetAudio()` instead of direct asset IDs for theme support.

### Data Persistence
DataStore operations handled by `PlayerDataService` with auto-save every 30 seconds and proper error handling.

## Performance Considerations
- **Module Loading**: Use `ModuleLoader.luau` for clean dependency management
- **Sprite System**: Single sprite sheet for all items to minimize texture loading
- **Island Positioning**: 1000 stud separation prevents overlap in multiplayer
- **Caching**: TTL cache in ApiService for external API calls with 3-retry logic

## Key Documentation
Reference `gold mine of info/docs/` for detailed guides:
- `COMPLETE_PROJECT_STATUS.md` - Full system overview
- `GAME_STRUCTURE_AND_FLOW.md` - Hub/island design
- `ITEM_SYSTEM_COMPLETE.md` - Inventory and crafting details