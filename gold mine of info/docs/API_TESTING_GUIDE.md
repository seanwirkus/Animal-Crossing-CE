# How to Test Nookipedia API & Generate Data

## Quick Start

### Step 1: Enable HTTP Requests in Roblox Studio

1. Open your game in Roblox Studio
2. Go to **Home** → **Game Settings** (or press Alt+S)
3. Navigate to **Security** tab
4. Check ✅ **Allow HTTP Requests**
5. Click **Save**

### Step 2: Run the Test Script

**Option A: Using Command Bar (Fastest)**

1. Open the Command Bar in Studio (View → Command Bar)
2. Paste this code:

```lua
require(game.ServerScriptService.Server.DataGenerator).Test()
```

3. Press Enter

**Option B: Using Server Script**

1. Insert a new Script in ServerScriptService
2. Paste the code from `TestNookipediaAPI.luau`
3. Run the game (F5)
4. Check the Output window for results

### Step 3: Verify Data Generation

You should see output like:

```
===========================================
🌴 NOOKIPEDIA API TEST
===========================================
✅ HTTP Requests are enabled
📡 Testing API connection...
✅ API connection successful!
   Found 5 villagers
   Example villager: Ankha
🎨 Generating game data from API...
✅ Data generation complete!

📊 Generated Data Summary:
   🦝 Villagers: 391
   🐟 Fish: 80
   🐛 Bugs: 80
   🪑 Furniture: 500+
   🔨 Tools: 15

📝 Data cached and ready to use!
===========================================
```

## Checking Generated Resources

After data generation, resources should spawn in your game:

### Fish Spawning
- **Location**: Near water/beach areas
- **Color**: Green (Common), Blue (Uncommon), Purple (Rare), Gold (Ultra Rare)
- **Max Active**: 15 fish
- **Respawn Time**: 30 seconds

### Bug Spawning
- **Location**: Throughout the island
- **Color**: Green (Common), Blue (Uncommon), Purple (Rare), Gold (Ultra Rare)
- **Max Active**: 20 bugs
- **Respawn Time**: 45 seconds

### Fruit Spawning
- **Location**: Near trees
- **Max Active**: 10 fruit
- **Respawn Time**: 5 minutes

### Shell Spawning
- **Location**: Beach areas
- **Max Active**: 8 shells
- **Respawn Time**: 2 minutes

## Troubleshooting

### ❌ "HTTP Requests are DISABLED"
**Solution**: Enable HTTP requests in Game Settings → Security

### ❌ "API connection failed"
**Possible Issues**:
1. **Invalid API Key**: Check that the API key in `NookipediaService.luau` is correct
   - Current key: `153cf201-7ca1-44d7-9f17-efd59e6c45e0`
2. **Network blocked**: Check if your network/firewall blocks Nookipedia
3. **API rate limit**: Wait a minute and try again

### ❌ "No resources spawning"
**Checks**:
1. Is ResourceService started on the server?
2. Check Output window for errors
3. Verify data was generated (run test script again)
4. Check if SpawnLocations exist in workspace

### ℹ️ "Data not persisting"
**This is normal!** The API cache clears every 5 minutes to stay updated. On server restart, data is re-fetched from Nookipedia.

## Manual Data Check

To check what data is cached, run this in Command Bar:

```lua
local service = require(game.ServerScriptService.Server.Services.NookipediaService)
print("Fish data:", service:GetFish())
print("Bug data:", service:GetBugs())
print("Villagers:", service:GetVillagers())
```

## API Data Examples

### Fish Data Structure
```lua
{
    name = "Sea Bass",
    sell_nook = 400,  -- Bells value
    rarity = "Common",
    shadow_size = "Large",
    time = "All day",
    months_northern = "Jan|Feb|Mar|...",
    image = "https://..."
}
```

### Bug Data Structure
```lua
{
    name = "Common Butterfly",
    sell_nook = 160,
    rarity = "Common",
    time = "4am - 7pm",
    months_northern = "Sep|Oct|Nov|...",
    image = "https://..."
}
```

### Villager Data Structure
```lua
{
    name = "Raymond",
    species = "Cat",
    personality = "Smug",
    gender = "Male",
    birthday_month = "October",
    birthday_day = "1",
    image = "https://..."
}
```

## Next Steps

After confirming API data works:

1. **Test Resource Collection**:
   - Walk up to a spawned resource
   - Press `E` to collect
   - Check your inventory and bells

2. **Test Villager Data**:
   - Villagers should use real ACNH data
   - Check their names, personalities, birthdays

3. **Build More Features**:
   - Fishing minigame using fish data
   - Bug catching mechanics
   - Furniture catalog
   - Recipe crafting

## Performance Notes

- **First Load**: May take 5-10 seconds to fetch all data
- **Subsequent Loads**: Instant (uses cache)
- **Cache Duration**: 5 minutes (300 seconds)
- **API Rate Limits**: Nookipedia allows reasonable usage

## Support

If you encounter issues:
1. Check the Output window for error messages
2. Verify HTTP is enabled
3. Test with the simple Command Bar code first
4. Check network connectivity

---

**API Key**: `153cf201-7ca1-44d7-9f17-efd59e6c45e0`  
**API Docs**: https://api.nookipedia.com/doc  
**Last Updated**: January 2025
