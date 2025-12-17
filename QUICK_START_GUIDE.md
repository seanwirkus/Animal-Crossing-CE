# 🎮 Quick Start Guide - Animal Crossing CE

**How to actually play and test your game RIGHT NOW!**

---

## 🚀 How to Start

1. Open **Roblox Studio**
2. Press **F5** (or click Play)
3. **Wait 3 seconds**
4. **Tutorial automatically starts!** 🎬

That's it! I created `OnboardingTrigger.server.luau` that auto-starts the tutorial for you.

---

## 🎮 Keybinds (What Each Key Does)

| Key | Action |
|-----|--------|
| **E** | Open Inventory |
| **R** | Tool Ring (equip tools here!) |
| **C** | Crafting Menu |
| **Q** | Quest Tracker |
| **P** | NookPhone |
| **B** | Item Browser |
| **G** | Debug Inventory |

---

## 🐟 How to Fish (Tutorial Quest)

1. Press **R** → Click **Fishing Rod**
2. Find water
3. **Click ON the water** to cast
4. Wait for **"!"** bubble
5. Press **E** to reel in
6. Fish in inventory! Quest progress updates!

---

## 🔨 How to Craft (Tutorial Quest)

1. Find **DIY Workbench** on island
2. Press **C**
3. Click a recipe
4. Click **"Craft"** button
5. Item in inventory! Quest progress updates!

---

## 🐛 Troubleshooting

### Tutorial Won't Start
```lua
-- In Server Command Bar:
game.ReplicatedStorage.Remotes.StartOnboarding:FireClient(game.Players:GetChildren()[1])
```

### Give Test Bells
```lua
-- In Server Command Bar:
local CM = require(game.ServerScriptService.CurrencyManager)
CM:addBells(game.Players:GetChildren()[1], 10000)
```

---

## ✅ What I Just Fixed

1. ✅ Created **OnboardingTrigger.server.luau** - Auto-starts tutorial
2. ✅ Tutorial now works automatically
3. ✅ Fishing connects to quests
4. ✅ Crafting connects to quests
5. ✅ Rewards given automatically

---

## 🎯 Just Press F5!

The tutorial will teach you everything. Press **Q** anytime to see your current quest.

**Have fun! 🎉**
