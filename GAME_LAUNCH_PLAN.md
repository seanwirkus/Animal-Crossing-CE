# 🎮 Animal Crossing CE - Fast Launch Plan

**Goal**: Turn this into a playable, monetizable game in **7-14 days**

## 📊 Current State Assessment

### ✅ What's Working
- Inventory system (persistent, drag-and-drop)
- Crafting system (80+ recipes)
- Item browser (494 items with sprites)
- GUI management (exclusive visibility)
- DataStore persistence
- Tool ring (needs keybind fix)
- Beautiful ACNH aesthetic

### ❌ What's Missing (Critical)
- **No gameplay loop** - Players can browse items but can't DO anything
- **No currency system** - No Bells or Nook Miles
- **No earning mechanics** - Can't fish, catch bugs, or gather resources
- **No shop** - Can't buy/sell items
- **No progression** - No goals or achievements
- **No tutorial** - New players are lost
- **No mobile optimization** - Most Roblox players are on mobile

---

## 🚀 Phase 1: Core Gameplay (Days 1-3) - CRITICAL

### Day 1: Currency System
**Goal**: Add Bells and Nook Miles that persist

**Tasks**:
1. Create `src/shared/CurrencyManager.luau`
   ```lua
   -- Manage Bells (main) and Miles (premium)
   -- Functions: addBells(), removeBells(), getMiles(), etc.
   ```

2. Create `src/client/Modules/CurrencyDisplay.luau`
   ```lua
   -- HUD showing Bells and Miles in top-right
   -- Auto-updates when currency changes
   ```

3. Update server DataStore to save currency
   ```lua
   PlayerData = {
       inventory = {...},
       bells = 1000,      -- Starting bells
       miles = 0,         -- Starting miles
       level = 1
   }
   ```

**Success Criteria**:
- [ ] Bells display in top-right HUD
- [ ] Bells persist across sessions
- [ ] Can add/remove bells via commands

**Time**: 3-4 hours

---

### Day 2: Fishing System (Main Activity)
**Goal**: Players can fish to earn Bells

**Tasks**:
1. Create `src/shared/FishingSystem.luau`
   ```lua
   -- Fish data (20+ fish types)
   -- Rarity system (common, uncommon, rare)
   -- Value system (each fish worth X bells)
   ```

2. Create `src/client/Modules/FishingController.luau`
   ```lua
   -- When tool_ring fishing rod equipped:
   --   Click water → cast line
   --   Wait for bite (random 2-5 seconds)
   --   Press E when "!" appears
   --   Catch fish or miss
   ```

3. Add fish to inventory system
   ```lua
   -- fish_bass = {name = "Bass", value = 400}
   -- fish_tuna = {name = "Tuna", value = 7000}
   ```

4. Create sell system
   ```lua
   -- Right-click fish in inventory → "Sell" option
   -- Sells for bell value
   ```

**Success Criteria**:
- [ ] Can equip fishing rod from tool ring
- [ ] Can cast into water
- [ ] Can catch fish after bite
- [ ] Fish appear in inventory
- [ ] Can sell fish for bells

**Time**: 6-8 hours

---

### Day 3: Bug Catching System
**Goal**: Second earning activity

**Tasks**:
1. Create `src/shared/BugSystem.luau`
   ```lua
   -- Bug data (20+ bug types)
   -- Spawn bugs randomly in world
   -- Value system
   ```

2. Create `src/client/Modules/BugController.luau`
   ```lua
   -- When net equipped:
   --   Click near bug → catch animation
   --   Success/fail based on timing
   --   Bug added to inventory
   ```

3. Spawn bugs in world
   ```lua
   -- Butterflies, beetles, etc.
   -- Random positions
   -- Respawn after caught
   ```

**Success Criteria**:
- [ ] 5+ bug types spawn in world
- [ ] Can catch bugs with net
- [ ] Bugs appear in inventory
- [ ] Can sell bugs for bells

**Time**: 6-8 hours

---

## 💰 Phase 2: Economy & Shop (Days 4-5)

### Day 4: Tom Nook's Shop
**Goal**: Players can spend bells

**Tasks**:
1. Create `src/client/Modules/ShopGUI.luau`
   ```lua
   -- Shop categories:
   --   Tools (fishing rod, net, shovel, axe)
   --   Furniture (10-20 items)
   --   DIY Recipes
   --   Inventory Upgrades
   ```

2. Create NPC interaction
   ```lua
   -- Tom Nook NPC in world
   -- Press E near him → opens shop
   ```

3. Purchase system
   ```lua
   -- Click item → "Buy for 500 Bells?"
   -- Deduct bells, add to inventory
   -- Server validation
   ```

**Shop Items** (Start Simple):
```lua
{
    {id = "fishing_rod", price = 500},
    {id = "net", price = 500},
    {id = "shovel", price = 800},
    {id = "axe", price = 1000},
    {id = "inventory_upgrade_20", price = 5000},
    {id = "furniture_chair", price = 2000},
    -- Add 10-15 more items
}
```

**Success Criteria**:
- [ ] Tom Nook NPC exists in world
- [ ] Press E to open shop
- [ ] Can browse items
- [ ] Can purchase items with bells
- [ ] Items added to inventory
- [ ] Bells deducted

**Time**: 5-6 hours

---

### Day 5: Selling System
**Goal**: Players can sell items to Tom Nook

**Tasks**:
1. Add "Sell" tab to shop GUI
2. Show player's inventory items
3. Click item → sell for value
4. Special "Sell All Fish" and "Sell All Bugs" buttons

**Success Criteria**:
- [ ] Can open shop sell tab
- [ ] Can sell individual items
- [ ] Can bulk-sell fish/bugs
- [ ] Bells added correctly

**Time**: 2-3 hours

---

## 🎯 Phase 3: Progression & Polish (Days 6-7)

### Day 6: Tutorial & Onboarding

**Tasks**:
1. Create `src/client/Modules/TutorialManager.luau`
   ```lua
   -- First-time player flow:
   --   1. Welcome message from Tom Nook
   --   2. "Press E to open inventory"
   --   3. "Visit shop to buy fishing rod"
   --   4. "Go fishing to earn bells!"
   --   5. Tutorial complete → 500 bells reward
   ```

2. Add hints system
   ```lua
   -- Tooltips for first-time actions
   -- "Press T to open tool ring"
   -- "Right-click items for options"
   ```

**Success Criteria**:
- [ ] New players see welcome message
- [ ] Step-by-step tutorial guides first session
- [ ] Hints appear for new actions
- [ ] Tutorial rewards 500 bells

**Time**: 4-5 hours

---

### Day 7: Daily Rewards & Achievements

**Tasks**:
1. Create `src/server/DailyRewardsSystem.luau`
   ```lua
   -- Day 1: 500 bells
   -- Day 3: 1000 bells
   -- Day 7: 5000 bells + special item
   -- Day 30: 20000 bells + exclusive item
   ```

2. Create basic achievements
   ```lua
   Achievements = {
       {id = "first_fish", reward = 100},
       {id = "catch_10_fish", reward = 500},
       {id = "catch_50_fish", reward = 2000},
       {id = "first_bug", reward = 100},
       {id = "earn_10000_bells", reward = 1000 miles},
       {id = "buy_10_items", reward = 500 miles}
   }
   ```

3. Create `src/client/Modules/AchievementPopup.luau`
   ```lua
   -- Shows popup when achievement unlocked
   ```

**Success Criteria**:
- [ ] Daily rewards work
- [ ] Achievements track progress
- [ ] Popup shows when unlocked
- [ ] Rewards granted correctly

**Time**: 4-5 hours

---

## 💎 Phase 4: Monetization (Days 8-9)

### Day 8: Game Passes

**Create in Roblox Creator Dashboard**:
1. **VIP Pass** (199 Robux)
   - 2x Bells earning
   - Special VIP tag
   - Exclusive items
   - 5 free inventory slots

2. **Premium Inventory** (299 Robux)
   - Start with 40 slots
   - Special inventory skin
   - Auto-sort feature

3. **Master Crafter** (149 Robux)
   - Instant crafting
   - All recipes unlocked
   - Batch crafting

**Implementation**:
```lua
-- src/server/GamePassManager.luau
local MarketplaceService = game:GetService("MarketplaceService")

local GAME_PASSES = {
    VIP = 0,  -- Replace with actual IDs
    PremiumInventory = 0,
    MasterCrafter = 0
}

function hasGamePass(player, passName)
    local passId = GAME_PASSES[passName]
    local success, hasPass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
    end)
    return success and hasPass
end

-- Apply benefits
function applyVIPBenefits(player)
    -- 2x bells multiplier
    -- VIP chat tag
    -- Exclusive items in shop
end
```

**Success Criteria**:
- [ ] 3 Game Passes created on Roblox
- [ ] Game detects ownership
- [ ] Benefits applied correctly
- [ ] Purchase prompts work

**Time**: 3-4 hours

---

### Day 9: Developer Products (Consumables)

**Create Products**:
1. **Bells Bundle Small** (49 Robux) → 5,000 Bells
2. **Bells Bundle Medium** (99 Robux) → 12,000 Bells
3. **Bells Bundle Large** (249 Robux) → 35,000 Bells
4. **Nook Miles Pack** (149 Robux) → 500 Miles

**Implementation**:
```lua
-- src/client/Modules/ShopGUI.luau (add Robux tab)
-- src/server/ProductPurchaseHandler.luau

MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    
    if PRODUCTS[receiptInfo.ProductId] then
        local product = PRODUCTS[receiptInfo.ProductId]
        
        -- Grant currency
        CurrencyManager.addBells(player, product.bells)
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    return Enum.ProductPurchaseDecision.NotProcessedYet
end
```

**Success Criteria**:
- [ ] Products created on Roblox
- [ ] Shop has "Robux" tab
- [ ] Purchase prompts work
- [ ] Currency granted instantly

**Time**: 2-3 hours

---

## 🎨 Phase 5: Polish & Launch Prep (Days 10-12)

### Day 10: Mobile Optimization

**Tasks**:
1. Add mobile controls
   ```lua
   -- On-screen buttons for fishing/catching
   -- Larger tap targets
   -- Responsive UI scaling
   ```

2. Test on mobile
   - iPhone
   - iPad
   - Android phone
   - Android tablet

3. Optimize performance
   ```lua
   -- Reduce part count
   -- LOD for distant objects
   -- Efficient loops
   ```

**Success Criteria**:
- [ ] All features work on mobile
- [ ] UI scales properly
- [ ] Performance 60 FPS on mobile
- [ ] Touch controls feel good

**Time**: 5-6 hours

---

### Day 11: Sound & Visual Polish

**Tasks**:
1. Add sound effects (from Roblox library)
   ```lua
   -- Coin sound when earning bells
   -- Pop sound when catching fish
   -- UI click sounds
   -- Crafting sounds
   ```

2. Add particle effects
   ```lua
   -- Sparkles when crafting
   -- Water splash when fishing
   -- Bell icons floating up when earned
   ```

3. Add animations
   ```lua
   -- Character fishing animation
   -- Net swinging animation
   -- Tom Nook waving
   ```

**Success Criteria**:
- [ ] 10+ sound effects added
- [ ] Key actions have particles
- [ ] Game feels juicy and responsive

**Time**: 4-5 hours

---

### Day 12: Final Testing & Bug Fixes

**Tasks**:
1. Playtest entire game flow
2. Fix critical bugs
3. Test DataStore edge cases
4. Test multiplayer scenarios
5. Get feedback from friends

**Critical Tests**:
- [ ] New player can complete tutorial
- [ ] Can earn bells through fishing
- [ ] Can buy items from shop
- [ ] Inventory persists
- [ ] Game Passes work
- [ ] No console errors
- [ ] Mobile works smoothly

**Time**: Full day

---

## 🚀 Phase 6: Launch (Days 13-14)

### Day 13: Marketing Assets

**Create**:
1. **Game Icon** (512x512)
   - Tom Nook or island scene
   - Bright, eye-catching
   - Animal Crossing aesthetic

2. **Thumbnails** (1920x1080)
   - Thumbnail 1: Fishing scene
   - Thumbnail 2: Shop/inventory
   - Thumbnail 3: "New Update!" template

3. **Game Description**
```
🏝️ ANIMAL CROSSING IN ROBLOX! 🏝️

Create your dream island paradise! Fish, catch bugs, craft items, 
and build your collection in this faithful Animal Crossing recreation!

✨ FEATURES:
🎣 Fishing system with 20+ fish types
🦋 Bug catching with rare spawns
🛠️ 80+ crafting recipes
📦 494+ collectible items
💰 Earn Bells and build your fortune
🏪 Shop with Tom Nook
📱 Mobile friendly!

🎮 EASY TO PLAY:
E - Inventory | T - Tools | R - Recipes

Join thousands of players building their islands! 🌴
Updates every week! 🎉

🌟 Premium Features:
VIP Pass, Premium Inventory, Master Crafter

START YOUR ISLAND ADVENTURE TODAY! 🏝️
```

4. **Social Media**
   - Twitter/X post
   - Discord announcement
   - YouTube thumbnail template

**Time**: 4-5 hours

---

### Day 14: LAUNCH DAY 🎉

**Morning**:
1. Final testing pass
2. Enable game in Roblox settings
3. Set to Public
4. Verify Game Passes/Products work

**Afternoon**:
1. Post on social media
2. Share in Roblox groups
3. Tell friends to play/share
4. Monitor for bugs

**Evening**:
1. Watch analytics
2. Respond to feedback
3. Fix critical bugs immediately
4. Plan first content update

---

## 📊 Success Metrics

### Week 1 Goals:
- 100+ concurrent players
- 1,000+ total visits
- 20%+ Day 1 retention
- 1-2 Game Pass purchases
- No critical bugs

### Week 2-4 Goals:
- 500+ concurrent players
- 10,000+ total visits
- 30%+ Day 1 retention
- $50-200 revenue
- 4.0+ star rating

---

## 🎯 MVP Feature Checklist

### Must Have for Launch:
- [x] Inventory system
- [x] Tool system
- [x] Crafting system
- [ ] Currency system (Bells)
- [ ] Fishing mechanic
- [ ] Bug catching mechanic
- [ ] Tom Nook shop (buy/sell)
- [ ] Tutorial
- [ ] Daily rewards
- [ ] 3 Game Passes
- [ ] Mobile controls
- [ ] Sound effects

### Nice to Have (Post-Launch):
- [ ] Friend islands
- [ ] Trading system
- [ ] Seasonal events
- [ ] More fish/bugs
- [ ] Furniture placement
- [ ] Customization
- [ ] Leaderboards

---

## 🛠️ Development Tips

### Workflow:
1. **Use Rojo**: `rojo serve` for live sync
2. **Test Often**: Test after every feature
3. **Commit Often**: Git commit every 1-2 hours
4. **Mobile First**: Test on mobile frequently
5. **Get Feedback**: Show friends early and often

### Code Organization:
```
src/
├── client/
│   └── Modules/
│       ├── FishingController.luau     [NEW]
│       ├── BugController.luau         [NEW]
│       ├── CurrencyDisplay.luau       [NEW]
│       ├── ShopGUI.luau               [NEW]
│       ├── TutorialManager.luau       [NEW]
│       ├── AchievementPopup.luau      [NEW]
│       └── ... (existing files)
├── server/
│   ├── CurrencyManager.luau           [NEW]
│   ├── FishingSystem.luau             [NEW]
│   ├── BugSystem.luau                 [NEW]
│   ├── ShopManager.luau               [NEW]
│   ├── GamePassManager.luau           [NEW]
│   ├── DailyRewardsSystem.luau        [NEW]
│   └── ... (existing files)
└── shared/
    ├── FishData.luau                  [NEW]
    ├── BugData.luau                   [NEW]
    ├── ShopData.luau                  [NEW]
    └── ... (existing files)
```

---

## 🚨 Critical Path (If Short on Time)

### Minimum 3-Day Launch:
**Day 1**: Currency + Fishing
**Day 2**: Shop + Selling
**Day 3**: Tutorial + Game Passes + Launch

### Skip for Initial Launch:
- Bug catching (add Week 2)
- Daily rewards (add Week 2)
- Achievements (add Week 2)
- Advanced polish (add Week 2)

---

## 💡 Post-Launch Content Plan

### Week 2 Update:
- Bug catching system
- 5 new fish types
- Daily rewards
- Performance improvements

### Week 3 Update:
- Achievements
- Seasonal event (Halloween/Christmas)
- New shop items

### Week 4 Update:
- Friend island visiting
- Trading system
- Leaderboards

---

## 🎯 Ready to Start?

**Next Steps:**
1. Review this plan
2. Decide: Full 14-day or Quick 3-day?
3. Start with Day 1: Currency System
4. Ask me for help implementing any module!

**I can help you create:**
- Any of the new modules listed
- Game Pass integration code
- Shop GUI and logic
- Fishing/bug catching systems
- Tutorial flow
- Marketing copy

**Just say**: "Let's start with [feature name]" and I'll create the code! 🚀
