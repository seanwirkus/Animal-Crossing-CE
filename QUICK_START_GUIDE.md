# Quick Start Guide - Complete Systems

## 🎮 For Players

### Using the DIYWorkBench

1. **Find a Workbench**
   - Look for a workbench model in your island
   - New players get one automatically during onboarding
   - You can place more using the building system (coming soon)

2. **Interact with Workbench**
   - Walk up to the workbench
   - Press **E** when prompted
   - Crafting GUI will open

3. **Craft Items**
   - Browse recipes on the left
   - Select a recipe to see materials needed
   - Green indicator = you can craft it
   - Red indicator = missing materials
   - Click "Craft Item" to craft

### New Player Onboarding

1. **First Time Joining**
   - System automatically detects you're new
   - Island generation starts automatically
   - Wait for generation to complete (~10-30 seconds)

2. **Starter Kit**
   - You'll receive:
     - Flimsy Shovel
     - Flimsy Axe
     - Flimsy Fishing Rod
     - 10 Wood
     - 5 Stone
     - 3 Iron Nuggets
   - Workbench is unlocked automatically

3. **Your Island**
   - Your island is saved automatically
   - When you return, your island loads automatically
   - All progress is saved

---

## 🛠️ For Developers

### Adding a DIYWorkBench Model

1. **Create Model in Studio**
   - Model name: `DIYWorkBench`
   - Place in: `ReplicatedStorage/Models/`
   - Add attribute: `CraftingStation = "DIYWorkBench"`

2. **Place in World**
   - Place model in `Workspace/CraftingStations/`
   - Or use `DIYWorkBenchService:PlaceStarterWorkbench(player, position)`

### Adding Recipes

Recipes are managed in `data/items.json`:
```json
{
  "itemId": "example_item",
  "craftable": true,
  "materials": [
    {"itemId": "wood", "count": 5},
    {"itemId": "stone", "count": 2}
  ],
  "station": "workbench"
}
```

### Customizing Onboarding

Edit `src/server/OnboardingService.luau`:
- Modify `_giveStarterKit()` to change starter items
- Modify `_generatePlayerIsland()` to change island generation
- Modify `_placeStarterHome()` to change home placement

### Island Saving

Islands are saved to DataStore automatically:
- **Key:** `ACNH_Islands` (production) or `ACNH_Islands_Dev` (Studio)
- **Format:** JSON with island data structure
- **Auto-save:** On player leave
- **Auto-load:** On player join

### Home Building

Homes are managed by `HomeBuildingService`:
- **Place Home:** `HomeBuildingService:PlaceHome(player, position)`
- **Upgrade Home:** `HomeBuildingService:UpgradeHome(player)`
- **Get Home:** `HomeBuildingService:GetPlayerHome(player)`

---

## 📋 Model Organization

### ReplicatedStorage (Templates)
- `Models/OakTree` - Tree template
- `Models/DIYWorkBench` - Workbench template
- `Models/Tent` - Tent template
- `Models/House` - House template
- `Models/ToolModels/` - Tool templates

### Workspace (Active Instances)
- `CraftingStations/` - Placed workbenches
- `PlayerHomes/` - Player homes
- `SavedIslands/[PlayerName]/` - Saved island objects
- `GeneratedObjects/` - Procedurally generated objects

---

## 🔧 Troubleshooting

### Workbench Not Working
- Check if model has `CraftingStation` attribute set to `"DIYWorkBench"`
- Check if ProximityPrompt exists on workbench
- Check server console for errors

### Recipes Not Loading
- Check if `CraftingSystem` is initialized
- Check if `CraftingEvent` RemoteEvent exists
- Check server console for recipe loading errors

### Island Not Saving
- Check DataStore permissions
- Check server console for DataStore errors
- Verify `IslandSaveService` is initialized

### Onboarding Not Starting
- Check if player already has island data
- Check server console for onboarding errors
- Verify `OnboardingService` is initialized

---

## 📚 API Reference

### DIYWorkBenchService
```lua
DIYWorkBenchService:PlaceStarterWorkbench(player, position)
DIYWorkBenchService:GetPlayerWorkbenches(player)
```

### IslandSaveService
```lua
IslandSaveService:SavePlayerIsland(player)
IslandSaveService:LoadPlayerIsland(player)
IslandSaveService:HasIsland(player)
```

### OnboardingService
```lua
OnboardingService:StartOnboarding(player)
OnboardingService:CompleteOnboarding(player)
OnboardingService:IsOnboardingComplete(player)
```

### HomeBuildingService
```lua
HomeBuildingService:PlaceHome(player, position)
HomeBuildingService:UpgradeHome(player)
HomeBuildingService:GetPlayerHome(player)
HomeBuildingService:HasHome(player)
```

---

## 🎯 Next Steps

1. Add actual model files to ReplicatedStorage
2. Test complete flow end-to-end
3. Add visual feedback and polish
4. Add sound effects and particles
5. Create user tutorials

---

## 📞 Support

For issues or questions:
1. Check server/client console for errors
2. Verify all services are initialized
3. Check RemoteEvents are created
4. Verify models are in correct locations

