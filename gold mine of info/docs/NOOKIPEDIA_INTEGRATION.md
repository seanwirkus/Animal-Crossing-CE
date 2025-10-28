# Nookipedia API Integration Guide

## 🎯 Overview

The Nookipedia API integration allows you to **automatically fetch real Animal Crossing data** to populate your game, saving hundreds of hours of manual data entry. This includes villagers, fish, bugs, furniture, tools, recipes, and more!

## 📦 What's Included

### 1. **NookipediaService.luau**
Location: `src/server/Services/NookipediaService.luau`

A complete service for making API calls to Nookipedia with:
- ✅ Built-in caching to avoid repeated API calls
- ✅ Automatic request formatting and error handling
- ✅ API key and version management
- ✅ Type-safe methods for all endpoints

### 2. **DataGenerator.luau**
Location: `src/server/DataGenerator.luau`

A utility script for fetching and converting Nookipedia data into your game's format:
- ✅ Batch data generation for all content types
- ✅ Automatic format conversion
- ✅ Progress logging and statistics
- ✅ Built-in testing functions

## 🔑 API Key

**Your API Key:** `153cf201-7ca1-44d7-9f17-efd59e6c45e0`

This key is already configured in the NookipediaService. Keep it secure!

## 🚀 Quick Start

### Method 1: Generate Data from Studio

1. Open Roblox Studio
2. Start a test session (F5)
3. Open the command bar (View → Command Bar or Ctrl+')
4. Run this command:

```lua
local DataGenerator = require(game.ServerScriptService.DataGenerator)
DataGenerator.GenerateAllData()
```

5. Check the output window to see the generated data
6. Copy the data to your Data modules

### Method 2: Use the Service Directly

In any server script:

```lua
local NookipediaService = require(game.ServerScriptService.Services.NookipediaService)
local api = NookipediaService.new()

-- Get all villagers
local villagers = api:GetVillagers()

-- Get fish available in January
local januaryFish = api:GetFish("january")

-- Get a specific bug
local monarchButterfly = api:GetBugByName("Monarch Butterfly")
```

## 📋 Available Endpoints

### Villagers
```lua
-- Get all villagers
api:GetVillagers()

-- Filter by personality
api:GetVillagersByPersonality("lazy")

-- Filter by species
api:GetVillagersBySpecies("cat")

-- Get specific villager
api:GetVillager("Raymond")

-- Advanced filters
api:GetVillagers({
    personality = "cranky",
    species = "cat",
    game = {"NH"}
})
```

### Fish
```lua
-- Get all fish
api:GetFish()

-- Get fish available in current month
api:GetCurrentMonthFish()

-- Get fish available in specific month
api:GetFish("march")

-- Get specific fish
api:GetFishByName("Sea Bass")
```

### Bugs
```lua
-- Get all bugs
api:GetBugs()

-- Get bugs available in current month
api:GetCurrentMonthBugs()

-- Get bugs available in specific month
api:GetBugs("july")

-- Get specific bug
api:GetBugByName("Atlas Moth")
```

### Sea Creatures
```lua
-- Get all sea creatures
api:GetSeaCreatures()

-- Get sea creatures for specific month
api:GetSeaCreatures("august")

-- Get specific sea creature
api:GetSeaCreatureByName("Giant Isopod")
```

### Furniture
```lua
-- Get all furniture
api:GetFurniture()

-- Get specific furniture item
api:GetFurnitureByName("Wooden Chair")
```

### Tools
```lua
-- Get all tools
api:GetTools()

-- Get specific tool
api:GetToolByName("Stone Axe")
```

### Recipes
```lua
-- Get all recipes
api:GetRecipes()

-- Get specific recipe
api:GetRecipeByName("Wooden Chair")
```

### Events
```lua
-- Get all seasonal events
api:GetEvents()
```

## 💾 Caching System

The service automatically caches API responses to:
- ⚡ Speed up repeated requests
- 💰 Reduce API usage
- 🔌 Work offline after initial fetch

```lua
-- Clear cache (useful during development)
api:ClearCache()

-- Check what's cached
local stats = api:GetCacheStats()
print(stats)
-- Output: { villagers = "cached", fish = "cached", bugs = "empty", ... }
```

## 🎨 Data Conversion Examples

### Villager Data
Nookipedia gives you:
```lua
{
    name = "Raymond",
    personality = "Smug",
    species = "Cat",
    birthday_month = "October",
    birthday_day = "1",
    phrase = "crisp",
    -- + 20 more fields...
}
```

Our converter transforms it to:
```lua
{
    id = "raymond",
    displayName = "Raymond",
    personality = "Smug",
    species = "Cat",
    birthday = "October 1",
    catchphrase = "crisp",
    dialogue = { ... },
    schedule = { ... },
    -- Game-ready format
}
```

### Fish Data
Nookipedia gives you:
```lua
{
    name = "Sea Bass",
    sell_nook = 400,
    location = "Sea",
    shadow_size = "Large",
    time = "All day",
    -- + availability data
}
```

Converts to:
```lua
{
    id = "fish_sea_bass",
    name = "Sea Bass",
    category = "Fish",
    baseValue = 400,
    location = "Sea",
    shadowSize = "Large",
    catchDifficulty = "Easy",
    -- Game-ready format
}
```

## 🛠️ Development Workflow

### Step 1: Test API Connection
```lua
local DataGenerator = require(game.ServerScriptService.DataGenerator)
DataGenerator.Test()
```

Expected output:
```
[DataGenerator] Running API test...
✅ Villagers API working - Found: Raymond
✅ Fish API working - Found: Sea Bass
✅ Bugs API working - Found: Common Butterfly
[DataGenerator] Test complete!
```

### Step 2: Generate Specific Data Type
```lua
-- Generate only what you need
local villagers = DataGenerator.GenerateVillagers()
local fish = DataGenerator.GenerateFish()
local bugs = DataGenerator.GenerateBugs()
```

### Step 3: Generate Everything
```lua
local allData = DataGenerator.GenerateAllData()
```

Output:
```
============================================================
[DataGenerator] 🌟 Starting data generation from Nookipedia API
============================================================
[DataGenerator] Fetching villagers from Nookipedia...
[DataGenerator] Fetched 391 villagers
  - Raymond (Smug, Cat)
  - Marshal (Smug, Squirrel)
  - Maple (Normal, Bear Cub)
  ...
[DataGenerator] ✅ Villagers data ready!
[DataGenerator] Fetching fish from Nookipedia...
[DataGenerator] Fetched 80 fish
  - Sea Bass ($400, Sea)
  - Coelacanth ($15000, Sea)
  ...
============================================================
[DataGenerator] ✅ Complete! Generated in 3.45 seconds
============================================================

📊 Data Summary:
  Villagers: 20
  Fish: 30
  Bugs: 30
  Furniture: 50
  Tools: 15

💡 Tip: Copy the results table to your Data modules!
```

### Step 4: Copy to Your Data Files

Take the generated data and paste it into your data modules:
- `src/shared/Data/Villagers.luau`
- `src/shared/Data/Items.luau`
- etc.

## ⚡ Performance Tips

1. **Generate once, use many times**: Run DataGenerator once and save the results
2. **Use caching**: The service caches responses automatically
3. **Filter early**: Use API filters instead of fetching everything
4. **Limit results**: The DataGenerator limits results for testing (configurable)

## 🔧 Customization

### Modify Data Conversion

Edit the conversion functions in `DataGenerator.luau`:

```lua
local function convertVillagerData(nookData)
    return {
        id = nookData.name:lower():gsub(" ", "_"),
        displayName = nookData.name,
        -- Add your custom fields here
        myCustomField = calculateSomething(nookData),
    }
end
```

### Add New Endpoints

Add methods to `NookipediaService.luau`:

```lua
function NookipediaService:GetClothing(filters)
    return self:_makeRequest("/nh/clothing", filters)
end
```

## 📊 Available Data Fields

### Villagers (391 total)
- Name, personality, species, birthday
- Gender, hobby, sub-personality
- Catchphrase, quote
- Preferred styles and colors
- Home details (exterior, interior)
- Appearance in all games

### Fish (80 total)
- Name, image, render
- Sell price (Nook's and C.J.)
- Location, shadow size
- Time availability (hourly)
- Month availability (north/south)
- Rarity, difficulty

### Bugs (80 total)
- Name, image, render
- Sell price (Nook's and Flick)
- Location (flying, ground, etc.)
- Time availability
- Month availability
- Weather requirements

### Furniture (1000+ items)
- Name, category, series
- Buy/sell prices
- Size, can be placed outside
- Customization options
- Variations (colors)
- Themes and tags

### Tools (50+ items)
- Name, image
- Buy price, durability
- Tool type (net, rod, shovel, etc.)
- Recipe requirements
- Customization

## 🎯 Real-World Examples

### Populate Your Game with 20 Villagers
```lua
local api = NookipediaService.new()

-- Get 20 random villagers with different personalities
local personalities = {"lazy", "peppy", "cranky", "normal", "smug"}
local villagers = {}

for _, personality in ipairs(personalities) do
    local result = api:GetVillagersByPersonality(personality)
    for i = 1, 4 do  -- 4 of each personality
        table.insert(villagers, result[i])
    end
end

-- Now you have 20 villagers with diverse personalities!
```

### Get Fish Available Right Now
```lua
local currentFish = api:GetCurrentMonthFish()

-- Returns:
-- {
--     north = {...}, -- Fish in northern hemisphere
--     south = {...}  -- Fish in southern hemisphere
-- }
```

### Build a Furniture Catalog
```lua
local furniture = api:GetFurniture()

-- Filter to only tables
local tables = {}
for _, item in ipairs(furniture) do
    if item.category == "Housewares" and item.name:match("Table") then
        table.insert(tables, item)
    end
end
```

## 🐛 Troubleshooting

### "Request failed" Error
- **Check internet connection**: API requires HTTP requests to be enabled
- **Enable HTTP service**: Game Settings → Security → Allow HTTP Requests
- **Verify API key**: Make sure it's correct in NookipediaService.luau

### Empty Results
- **Check filters**: Some filter combinations return no results
- **API limits**: Some endpoints may have rate limits
- **Cache issue**: Try `api:ClearCache()` and retry

### Timeout Errors
- **Large requests**: Fetching all furniture (1000+ items) takes time
- **Use filters**: Narrow down what you need
- **Batch processing**: Generate data in smaller chunks

## 📚 Additional Resources

- **Nookipedia Wiki**: https://nookipedia.com
- **API Documentation**: https://api.nookipedia.com/doc
- **API Discord**: Join for support and updates

## ⚠️ Important Notes

1. **HTTP must be enabled**: In Studio, go to Game Settings → Security → Allow HTTP Requests ✅
2. **Server-side only**: NookipediaService only works on the server (not client)
3. **Rate limiting**: Be respectful of API usage, use caching
4. **API key security**: Don't expose your API key in public code
5. **Data accuracy**: Nookipedia data is community-maintained and constantly updated

## 🎉 Benefits

By using the Nookipedia API, you get:

✅ **1000+ hours saved** on manual data entry
✅ **Real Animal Crossing data** with accurate values
✅ **Constantly updated** as the wiki updates
✅ **Images included** for all items (URLs provided)
✅ **Complete information** on timing, rarity, locations
✅ **Easy maintenance** - just refresh the data periodically

---

## Next Steps

1. ✅ Enable HTTP requests in Game Settings
2. ✅ Test the API connection with `DataGenerator.Test()`
3. ✅ Generate data with `DataGenerator.GenerateAllData()`
4. ✅ Copy the generated data to your Data modules
5. ✅ Start building your game with real AC content!

Happy developing! 🌟
