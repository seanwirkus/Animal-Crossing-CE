# 🎮 Roblox Studio Setup Guide - Complete Walkthrough

## Overview

This guide will walk you through setting up your Animal Crossing: New Horizons Roblox game from scratch. You'll drag and drop files, create folders, and configure everything step-by-step.

---

## Prerequisites

### What You Need
- ✅ Roblox Studio installed
- ✅ This project folder open
- ✅ Basic understanding of Studio interface

### Project Files Location
All files are in: `/Users/sean/Desktop/ACNH Roblox/`

---

## Part 1: Create the Project Structure

### Step 1: Open Roblox Studio
1. Open **Roblox Studio**
2. Click **New** → **Baseplate** (or open your existing place)
3. Save your place: **File** → **Save to Roblox As** → Name it "ACNH Roblox"

### Step 2: Enable HTTP Requests (IMPORTANT!)
1. Go to **Home** tab → **Game Settings** (gear icon)
2. Click **Security** on the left
3. Enable **"Allow HTTP Requests"** ✅
4. Click **Save**

> ⚠️ **This is required for the game to load Nookipedia data!**

---

## Part 2: Set Up the Workspace

### Step 3: Create Main Folders

In **Explorer** panel (right side), organize your workspace:

1. **ReplicatedStorage** (already exists)
   - Right-click ReplicatedStorage → **Insert Object** → **Folder**
   - Name it: `data`

2. **ServerScriptService** (already exists)
   - This is where your server code will go

3. **StarterPlayer** → **StarterPlayerScripts** (already exists)
   - This is where client code will go

Your structure should look like:
```
Workspace
  ├─ Baseplate (or your terrain)
  └─ (your spawn location)
  
ReplicatedStorage
  └─ data (Folder) ← YOU JUST CREATED THIS

ServerScriptService
  └─ (server scripts will go here)

StarterPlayer
  └─ StarterPlayerScripts
      └─ (client scripts will go here)
```

---

## Part 3: Upload Character Data (499 Characters)

### Step 4: Prepare Character JSON

1. **On your computer**, navigate to:
   ```
   /Users/sean/Desktop/ACNH Roblox/data/nookipedia_characters.json
   ```

2. **Open it** with a text editor (TextEdit, VS Code, etc.)

3. **Select All** (Cmd+A) and **Copy** (Cmd+C)
   - ⚠️ This file is ~5MB, it might take a few seconds to copy

### Step 5: Create StringValue for Characters

1. In **Roblox Studio Explorer**, find **ReplicatedStorage** → **data**

2. Right-click on **data** folder → **Insert Object** → Type "**StringValue**"

3. **Rename it** to: `nookipedia_characters` (exactly, no spaces)

4. Click on the **nookipedia_characters** StringValue

5. In **Properties** panel (bottom-right):
   - Find the **"Value"** property
   - Click in the text box
   - **Paste** (Cmd+V) your copied JSON
   - Wait for it to finish pasting (might take a few seconds)

6. ✅ You should see the JSON text in the Value property

---

## Part 4: Upload Item Data (7,025 Items)

### Step 6: Prepare Item JSON

1. **On your computer**, navigate to:
   ```
   /Users/sean/Desktop/ACNH Roblox/data/nookipedia_items.json
   ```

2. **Open it** with a text editor
   - ⚠️ This file is **~15MB** and very large (450,000+ lines)
   - It might take a moment to open

3. **Select All** (Cmd+A) and **Copy** (Cmd+C)
   - ⚠️ This will take 10-30 seconds to copy, be patient!

### Step 7: Create StringValue for Items

1. In **Roblox Studio Explorer**, right-click on **ReplicatedStorage** → **data**

2. **Insert Object** → Type "**StringValue**"

3. **Rename it** to: `nookipedia_items` (exactly, no spaces)

4. Click on the **nookipedia_items** StringValue

5. In **Properties** panel:
   - Find the **"Value"** property
   - Click in the text box
   - **Paste** (Cmd+V) your copied JSON
   - ⚠️ **This will take 30-60 seconds to paste!** Don't close Studio!

6. ✅ You should see the massive JSON text in the Value property

Your **ReplicatedStorage** → **data** should now have:
```
ReplicatedStorage
  └─ data (Folder)
      ├─ nookipedia_characters (StringValue with JSON)
      └─ nookipedia_items (StringValue with JSON)
```

---

## Part 5: Set Up Server Scripts

### Step 8: Drag Shared Modules to ReplicatedStorage

1. In **VS Code** (or file explorer), open:
   ```
   /Users/sean/Desktop/ACNH Roblox/src/shared/
   ```

2. You should see files like:
   - `EmojiMap.luau`
   - `GameTypes.luau`
   - `ErrorHandler.luau`
   - etc.

3. **In Roblox Studio:**
   - Right-click **ReplicatedStorage** → **Insert Object** → **ModuleScript**
   - Rename it to match the file (e.g., "EmojiMap")
   - Double-click to open the script
   - **Delete** all the default code
   - **In VS Code**, open the matching file
   - **Copy all the code** (Cmd+A, Cmd+C)
   - **Paste** into Studio script (Cmd+V)
   - Close the script tab

4. **Repeat for each file in `/src/shared/`:**
   - `EmojiMap.luau` → ModuleScript named "EmojiMap"
   - `GameTypes.luau` → ModuleScript named "GameTypes"
   - `ErrorHandler.luau` → ModuleScript named "ErrorHandler"
   - `Logger.luau` → ModuleScript named "Logger"

> 💡 **Tip:** You can also use **Rojo** to sync files automatically, but manual is fine for setup!

### Step 9: Set Up Server Folder Structure

1. In **ServerScriptService**, create this structure:
   ```
   ServerScriptService
     ├─ init.server (Script) ← MAIN SERVER SCRIPT
     ├─ Services (Folder)
     ├─ Systems (Folder)
     └─ Data (Folder)
   ```

2. **Create folders:**
   - Right-click **ServerScriptService** → **Insert Object** → **Folder**
   - Name it "Services"
   - Repeat for "Systems" and "Data"

### Step 10: Upload Server Code

Now you need to copy all the server code. Here's the structure:

**In `/src/server/init.server.luau`:**
1. Right-click **ServerScriptService** → **Insert Object** → **Script**
2. Rename it to "init.server"
3. Open the script, delete default code
4. Copy from `/Users/sean/Desktop/ACNH Roblox/src/server/init.server.luau`
5. Paste into Studio

**In `/src/server/Data/` folder:**
Copy these as ModuleScripts into **ServerScriptService** → **Data**:
- `CharacterDatabase.luau` → ModuleScript "CharacterDatabase"
- `ItemDatabase.luau` → ModuleScript "ItemDatabase"

**In `/src/server/Services/` folder:**
Copy these as ModuleScripts into **ServerScriptService** → **Services**:
- `RemoteRegistry.luau` → "RemoteRegistry"
- `EconomyService.luau` → "EconomyService"
- `InventoryService.luau` → "InventoryService"
- `PlayerIslandService.luau` → "PlayerIslandService"
- `QuestService.luau` → "QuestService"
- `ResourceService.luau` → "ResourceService"
- `NPCServiceManager.luau` → "NPCServiceManager"
- (and all other services...)

**In `/src/server/Systems/` folder:**
Copy these as ModuleScripts into **ServerScriptService** → **Systems**:
- `PlayerInitiationOrchestrator.luau` → "PlayerInitiationOrchestrator"
- `HubService.luau` → "HubService"
- `IslandClock.luau` → "IslandClock"
- `TomNookSpawner.luau` → "TomNookSpawner"
- `TomNookRealSpawner.luau` → "TomNookRealSpawner"
- `IslandNPCManager.luau` → "IslandNPCManager"
- `NPCWalker.luau` → "NPCWalker"
- (and all other systems...)

**In `/src/server/config.luau`:**
1. Copy as ModuleScript into **ServerScriptService** → "config"

> 📝 **Note:** This is tedious! Consider using **Rojo** for automatic syncing in the future.

---

## Part 6: Set Up Client Scripts

### Step 11: Create Client Structure

1. Go to **StarterPlayer** → **StarterPlayerScripts**

2. Create this structure:
   ```
   StarterPlayerScripts
     ├─ init.client (LocalScript) ← MAIN CLIENT SCRIPT
     ├─ UI (Folder)
     └─ Controllers (Folder)
   ```

### Step 12: Upload Client Code

**In `/src/client/init.client.luau`:**
1. Insert **LocalScript** into **StarterPlayerScripts**
2. Rename to "init.client"
3. Copy from `/Users/sean/Desktop/ACNH Roblox/src/client/init.client.luau`
4. Paste into Studio

**In `/src/client/UI/` folder:**
Copy these as ModuleScripts into **StarterPlayerScripts** → **UI**:
- `IslandManagementGUI.luau` → "IslandManagementGUI"
- `HudV2.luau` → "HudV2"
- `QuestTrackerGUI.luau` → "QuestTrackerGUI"
- (and all other UI modules...)

---

## Part 7: Configure ReplicatedStorage

### Step 13: Add SharedModules

Make sure **ReplicatedStorage** has all shared modules:

```
ReplicatedStorage
  ├─ data (Folder)
  │   ├─ nookipedia_characters (StringValue)
  │   └─ nookipedia_items (StringValue)
  ├─ EmojiMap (ModuleScript)
  ├─ GameTypes (ModuleScript)
  ├─ Logger (ModuleScript)
  ├─ ErrorHandler (ModuleScript)
  └─ (other shared modules)
```

Copy from `/src/shared/` to ReplicatedStorage as ModuleScripts.

---

## Part 8: Test Your Setup

### Step 14: First Test Run

1. Click **Play** (F5) in Roblox Studio

2. **Check Output Console** (View → Output)

3. You should see:
   ```
   [Server] ═══════════════════════════════════════════════════════
   [Server] 🦝 Loading character data from JSON...
   [Server] ═══════════════════════════════════════════════════════
   [Server] ✅ Character database loaded!
   [Server] 📚 499 characters available (486 villagers + 13 special)
   [Server] ═══════════════════════════════════════════════════════
   [Server] 📦 Loading item database from JSON...
   [Server] ═══════════════════════════════════════════════════════
   [Server] ✅ Item database loaded!
   [Server] 📦 7025 total items across 13 categories
   [Server] 📊 Category breakdown:
   [Server]   🪑 furniture: 1997 items
   [Server]   👕 clothing: 1487 items
   ...
   ```

4. ✅ **Success!** If you see this, your data loaded correctly!

### Step 15: Test Character & Item Access

1. Stop the game (press Stop button)

2. In **ServerScriptService**, create a new **Script** called "TestScript"

3. Paste this code:
   ```lua
   wait(3) -- Wait for databases to load
   
   -- Test character database
   local characterDB = _G.CharacterDB
   if characterDB then
       print("✅ CharacterDB found!")
       print("Total characters:", characterDB:GetCharacterCount())
       
       local tomNook = characterDB:GetCharacterInfo("Tom Nook")
       print("Tom Nook:", tomNook.name, tomNook.species, tomNook.personality)
   else
       warn("❌ CharacterDB not found!")
   end
   
   -- Test item database
   local itemDB = _G.ItemDB
   if itemDB then
       print("✅ ItemDB found!")
       print("Total items:", itemDB:GetItemCount())
       
       local chair = itemDB:GetItemWithEmoji("Wooden Chair")
       print("Wooden Chair:", chair.emoji, chair.name, chair.sell_price)
   else
       warn("❌ ItemDB not found!")
   end
   
   -- Test NPC services
   local npcServices = _G.NPCServices
   if npcServices then
       print("✅ NPCServices found!")
       print("Tom Nook services available!")
   else
       warn("❌ NPCServices not found!")
   end
   
   print("🎉 All systems operational!")
   ```

4. **Run the game** again (F5)

5. **Check Output** - You should see:
   ```
   ✅ CharacterDB found!
   Total characters: 499
   Tom Nook: Tom Nook Tanuki Smug
   ✅ ItemDB found!
   Total items: 7025
   Wooden Chair: 🪑 Wooden Chair 400
   ✅ NPCServices found!
   Tom Nook services available!
   🎉 All systems operational!
   ```

6. ✅ **Everything works!** Delete the TestScript when done.

---

## Part 9: Build Your World

### Step 16: Create Spawn Location

1. In **Workspace**, find or create a **SpawnLocation**
   - Insert → **SpawnLocation**
   - Position it at the center of your world (e.g., 0, 5, 0)

2. Set properties:
   - Duration: 0
   - Neutral: ✅ (checked)

### Step 17: Create Hub Platform

Your game needs a hub where players spawn and meet Tom Nook/Isabelle:

1. Insert a **Part** into Workspace
2. Resize it: 100 x 1 x 100 (large platform)
3. Position it at: 0, 50, 0 (50 studs up in the air)
4. Make it **Anchored** ✅
5. Change color to something nice (grass green?)
6. Name it "HubPlatform"

### Step 18: Test NPC Spawning

1. **Run the game** (F5)

2. Wait 3-5 seconds

3. Look around the hub platform - you should see:
   - **Isabelle** spawned at the center (if TomNookSpawner is active)
   - **Tom Nook** spawned to the left (if TomNookRealSpawner is active)

4. Walk up to them and you should see **ProximityPrompts** appear!

---

## Part 10: Configure Island Generation

### Step 19: Set Up Island Spawn Area

Your game generates personal islands far away from the hub:

1. The system uses coordinates like (10000, 0, 10000) for islands
2. Each player gets an island at a unique position
3. You don't need to build anything - islands generate automatically!

### Step 20: Test Island Creation

1. **Run the game** (F5)

2. **Walk up to Tom Nook** at the hub

3. **Press E** (or click) to interact

4. You should see:
   - Island Management GUI opens
   - "Create Island" button appears

5. Click **"Create Island"**

6. Wait 5-10 seconds...

7. You should be **teleported** to your new island!

8. ✅ **Success!** Your island is generated with terrain!

---

## Part 11: Configure Remote Events

### Step 21: Verify RemoteRegistry

The RemoteRegistry automatically creates all remote events. Check it loaded:

1. While game is running, check **ReplicatedStorage**
2. You should see a **Folder** called "Remotes" with many RemoteEvents inside
3. If not, check Output for errors

---

## Part 12: Troubleshooting

### Common Issues

#### ❌ "Infinite yield possible on 'ReplicatedStorage:WaitForChild("data")'"
**Fix:**
- Make sure you created the "data" folder in ReplicatedStorage
- Make sure it's named exactly "data" (lowercase)

#### ❌ "CharacterDB not found!"
**Fix:**
- Check ReplicatedStorage → data → nookipedia_characters exists
- Check that JSON was pasted correctly into the Value property
- Make sure HTTP Requests are enabled in Game Settings

#### ❌ "ItemDB not found!"
**Fix:**
- Check ReplicatedStorage → data → nookipedia_items exists
- Make sure the 15MB JSON file was fully pasted
- This file is huge - it takes time to paste!

#### ❌ No NPCs spawning
**Fix:**
- Check that HubService is initialized (look in Output)
- Check that TomNookSpawner and TomNookRealSpawner are in ServerScriptService/Systems
- Make sure the hub platform exists at Y=50

#### ❌ Can't create island
**Fix:**
- Check that PlayerIslandService loaded
- Check that IslandNPCManager loaded
- Look for errors in Output console

---

## Part 13: Optional Enhancements

### Step 22: Add Skybox (Optional)

1. Insert **Sky** into **Lighting**
2. Set nice skybox IDs for day/night cycle

### Step 23: Add Music (Optional)

1. Insert **Sound** into **Workspace**
2. Set SoundId to a calm AC-style music
3. Set Looped: ✅
4. Set Playing: ✅

### Step 24: Add Lighting Effects

1. Go to **Lighting**
2. Set:
   - Ambient: Light blue/green tint
   - Brightness: 2-3
   - OutdoorAmbient: Warm color
   - ClockTime: 14 (2 PM, nice lighting)

---

## Part 14: Next Steps

### You're Done! 🎉

You now have:
- ✅ 499 characters loaded
- ✅ 7,025 items with emojis
- ✅ 13 NPC services ready
- ✅ 11-stage player initiation system
- ✅ Island generation working
- ✅ Tom Nook & Isabelle spawning at hub

### What to Build Next:

1. **Shop GUI** - Display items from ItemDB with buy/sell
2. **Inventory UI** - Show player items with emoji icons
3. **Crafting System** - Use recipe data from ItemDB
4. **Museum** - Let players donate fish/bugs/art to Blathers
5. **Quest System** - Connect fishing quest to initiation
6. **Home Decorator** - Let players place furniture
7. **Villager Invites** - Spawn random villagers on islands

---

## Quick Reference

### File Locations
```
Project Root: /Users/sean/Desktop/ACNH Roblox/

Data Files:
  - data/nookipedia_characters.json → ReplicatedStorage/data/nookipedia_characters
  - data/nookipedia_items.json → ReplicatedStorage/data/nookipedia_items

Server Code:
  - src/server/ → ServerScriptService/
  - src/server/init.server.luau → ServerScriptService/init.server

Client Code:
  - src/client/ → StarterPlayerScripts/
  - src/client/init.client.luau → StarterPlayerScripts/init.client

Shared Code:
  - src/shared/ → ReplicatedStorage/
```

### Global Access in Scripts
```lua
_G.CharacterDB  -- Character database (499 characters)
_G.ItemDB       -- Item database (7,025 items)
_G.NPCServices  -- NPC service manager
_G.PlayerInitiation -- Player initiation orchestrator
```

### Important Settings
- ✅ **HTTP Requests Enabled** (Game Settings → Security)
- ✅ **Hub Platform at Y=50**
- ✅ **SpawnLocation in Workspace**

---

## Help & Documentation

- **NOOKIPEDIA_PREFETCH_COMPLETE.md** - Character system details
- **ITEM_SYSTEM_COMPLETE.md** - Item system and emojis
- **PLAYER_INITIATION_SYSTEM_COMPLETE.md** - NPC services
- **COMPLETE_NOOKIPEDIA_INTEGRATION.md** - Full overview

---

**Good luck building your Animal Crossing experience! 🏝️**

