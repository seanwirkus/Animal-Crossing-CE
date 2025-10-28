# Quick API Test Commands

Copy and paste these commands into the **Command Bar** in Roblox Studio (View → Command Bar)

## 1. Enable HTTP First!
Before running any commands, enable HTTP:
- Home → Game Settings → Security → ✅ Allow HTTP Requests

## 2. Test API Connection (Quick)
```lua
local service = require(game.ServerScriptService.Server.Services.NookipediaService).new()
local villagers = service:GetVillagers({species = "cat", limit = 3})
if villagers then print("✅ API Works! Found " .. #villagers .. " villagers") else warn("❌ API Failed") end
```

## 3. Generate All Data
```lua
local gen = require(game.ServerScriptService.Server.DataGenerator)
gen.GenerateAllData()
```

## 4. Quick Test (Built-in)
```lua
require(game.ServerScriptService.Server.DataGenerator).Test()
```

## 5. Check Specific Data

### Get Fish Data
```lua
local service = require(game.ServerScriptService.Server.Services.NookipediaService).new()
local fish = service:GetFish()
print("Fish count:", fish and #fish or "ERROR")
for i = 1, math.min(5, fish and #fish or 0) do print("  -", fish[i].name, fish[i].sell_nook .. " bells") end
```

### Get Bug Data
```lua
local service = require(game.ServerScriptService.Server.Services.NookipediaService).new()
local bugs = service:GetBugs()
print("Bug count:", bugs and #bugs or "ERROR")
for i = 1, math.min(5, bugs and #bugs or 0) do print("  -", bugs[i].name, bugs[i].sell_nook .. " bells") end
```

### Get Villager Data
```lua
local service = require(game.ServerScriptService.Server.Services.NookipediaService).new()
local villagers = service:GetVillagers({limit = 10})
print("Villager count:", villagers and #villagers or "ERROR")
for i = 1, math.min(5, villagers and #villagers or 0) do print("  -", villagers[i].name, "(" .. villagers[i].species .. ")") end
```

## 6. Clear Cache (If needed)
```lua
require(game.ServerScriptService.Server.Services.NookipediaService).new():ClearCache()
print("Cache cleared!")
```

## 7. Test Resource Service (After data generation)
```lua
local service = require(game.ServerScriptService.Server.Services.ResourceService)
service:Start()
print("ResourceService started! Resources should spawn now.")
```

## Expected Output

After running **Generate All Data** (command #3), you should see:

```
============================================================
[DataGenerator] 🌟 Starting data generation from Nookipedia API
============================================================
[NookipediaService] Fetching villagers...
[NookipediaService] ✓ Found 391 villagers
[NookipediaService] Fetching fish...
[NookipediaService] ✓ Found 80 fish
[NookipediaService] Fetching bugs...
[NookipediaService] ✓ Found 80 bugs
[NookipediaService] Fetching furniture...
[NookipediaService] ✓ Found 500+ furniture items
[NookipediaService] Fetching tools...
[NookipediaService] ✓ Found 15 tools
============================================================
[DataGenerator] ✅ Complete! Generated in 3.24 seconds
============================================================

📊 Data Summary:
  Villagers: 391
  Fish: 80
  Bugs: 80
  Furniture: 500+
  Tools: 15

💡 Tip: Copy the results table to your Data modules!
```

## Troubleshooting

### "Undefined global 'game'"
**Solution**: You're trying to run the command in a script editor. Use the **Command Bar** instead!

### "HTTP 403 (Forbidden)"
**Solution**: Enable HTTP requests in Game Settings

### "Module not found"
**Solution**: Make sure your file structure matches:
```
ServerScriptService/
  Server/
    Services/
      NookipediaService.luau
    DataGenerator.luau
```

### "Nothing spawning in game"
**Steps**:
1. Generate data first (command #3)
2. Start ResourceService (command #7)
3. Play the game (F5)
4. Look for colored parts (fish/bugs/shells)

## Visual Confirmation

After resources spawn, you should see:
- 🟢 **Green parts** = Common resources (fish/bugs)
- 🔵 **Blue parts** = Uncommon resources
- 🟣 **Purple parts** = Rare resources
- 🟡 **Gold parts** = Ultra Rare resources

Walk up to them and press `E` to collect!

---

**Pro Tip**: Create a bookmark/script in Studio with command #3 so you can quickly regenerate data after server restarts.
