# 🎓 Tutorial & Quest System Setup Guide

**Created**: December 16, 2025
**Purpose**: Complete guide to implementing the tutorial and quest system

---

## 📋 System Overview

### What We Have
✅ **OnboardingFlow** - Cinematic intro (dialogue, island selection, cutscenes)
✅ **QuestData** - Predefined tutorial/daily/weekly/milestone quests
✅ **QuestService** - Server-side quest tracking and persistence
✅ **QuestGUI** - Client-side quest display
✅ **QuestHandlers** - Connects gameplay actions to quest progress
✅ **OnboardingService** - Server-side tutorial management
✅ **TutorialManager** (NEW!) - Step-by-step guided tutorial with quests

### How It Works Together

```
New Player Joins
      ↓
OnboardingService detects first-time player
      ↓
Fires StartOnboarding remote to client
      ↓
TutorialManager starts step-by-step tutorial
      ↓
Shows Tom Nook dialogue + assigns tutorial quests
      ↓
Player completes actions (fish, craft, etc.)
      ↓
QuestHandlers tracks progress
      ↓
Quest completes → rewards given → next tutorial step
      ↓
Tutorial complete → player gets starter rewards → free exploration
```

---

## 🔧 Implementation Steps

### Step 1: Enable TutorialManager in Client Init

**File**: `src/client/init.client.luau`

Add this code to initialize the tutorial system:

```lua
-- Load TutorialManager
local TutorialManager = require(script.Modules.TutorialManager)

-- Initialize tutorial system
local tutorialManager = TutorialManager.new()
print("[Client] ✅ TutorialManager initialized")
```

---

### Step 2: Update QuestService to Handle Tutorial Quests

**File**: `src/server/QuestService.luau`

Add this method to handle tutorial quest assignment:

```lua
-- Handle tutorial quest assignment
function QuestService:_handleClientRequest(player, action, data)
    if action == "AssignTutorialQuest" then
        local questId = data.questId
        self:assignTutorialQuest(player.UserId, questId)

    elseif action == "GetActiveQuests" then
        local quests = self:GetActiveQuests(player.UserId)
        self._remoteEvent:FireClient(player, "SyncQuests", quests)

    elseif action == "ClaimQuestReward" then
        local questId = data.questId
        self:claimQuestReward(player.UserId, questId)
    end
end

-- Assign a tutorial quest
function QuestService:assignTutorialQuest(userId, questId)
    local QuestData = require(game.ReplicatedStorage.Shared.QuestData)
    local questTemplate = QuestData.TUTORIAL_QUESTS[questId]

    if not questTemplate then
        warn("[QuestService] Unknown tutorial quest:", questId)
        return
    end

    -- Create quest from template
    local quest = {
        id = questTemplate.id,
        name = questTemplate.name,
        description = questTemplate.description,
        category = questTemplate.category,
        icon = questTemplate.icon,
        objectives = questTemplate.objectives,
        target = questTemplate.target,
        progress = 0,
        rewards = questTemplate.rewards,
        isActive = true,
        isCompleted = false,
    }

    -- Add to player's quests
    if not self._playerQuests[userId] then
        self._playerQuests[userId] = {}
    end

    self._playerQuests[userId][questId] = quest

    -- Sync to client
    local player = Players:GetPlayerByUserId(userId)
    if player then
        self:_syncToClient(player)
    end

    print(string.format("[QuestService] ✅ Assigned tutorial quest %s to user %d", questId, userId))
end
```

---

### Step 3: Connect FishingSystem to QuestHandlers

**File**: `src/server/FishingSystem.luau`

Find the section where fish are caught and add quest tracking:

```lua
-- After successfully catching a fish:
local QuestHandlers = require(script.Parent.QuestHandlers)
QuestHandlers.onFishCaught(player, {
    id = fishId,
    name = fishName,
    value = fishValue,
})
```

---

### Step 4: Connect CraftingSystem to QuestHandlers

**File**: `src/shared/CraftingSystem.luau` or wherever crafting is handled

Add quest tracking when item is crafted:

```lua
-- After successfully crafting an item:
local QuestHandlers = require(game.ServerScriptService.QuestHandlers)
QuestHandlers.onItemCrafted(player, itemId)
```

---

### Step 5: Update OnboardingService to Use TutorialManager

**File**: `src/server/OnboardingService.luau`

Ensure it fires the remote to start tutorial:

```lua
function OnboardingService:onPlayerJoined(player)
    -- Wait a moment for island to be created
    task.wait(2)

    -- Check if player needs tutorial
    if self.playerIslandService then
        local islandData = self.playerIslandService:getPlayerIsland(player.UserId)

        if islandData and not islandData.hasCompletedTutorial then
            print(string.format("[OnboardingService] Starting tutorial for %s", player.Name))
            self:startTutorial(player)
        end
    end
end

function OnboardingService:startTutorial(player)
    -- Fire client event to start tutorial UI
    if self.startOnboardingRemote then
        self.startOnboardingRemote:FireClient(player)
        print(string.format("[OnboardingService] Tutorial started for %s", player.Name))
    end
end
```

---

### Step 6: Give Starter Rewards on Tutorial Complete

**File**: `src/server/OnboardingService.luau`

Update the reward function:

```lua
function OnboardingService:giveStarterRewards(player)
    print(string.format("[OnboardingService] Giving starter rewards to %s", player.Name))

    -- Give bells and miles using CurrencyManager
    local CurrencyManager = require(script.Parent.CurrencyManager)
    CurrencyManager:addBells(player, 1000)
    CurrencyManager:addMiles(player, 500)

    print(string.format("[OnboardingService] ✅ Gave 1000 bells and 500 miles to %s", player.Name))
end
```

---

## 🎮 Testing Checklist

### Test Tutorial Flow

1. **Start Fresh**
   - Create new player account OR reset DataStore
   - Join game

2. **Verify Dialogue**
   - [ ] Tom Nook dialogue appears
   - [ ] Dialogue can be advanced by clicking
   - [ ] All dialogue steps show correctly

3. **Test Tutorial Steps**
   - [ ] Step 1: Welcome dialogue shows
   - [ ] Step 2: "Press E" hint appears
   - [ ] Step 3: Opening inventory progresses tutorial
   - [ ] Step 4: Fishing quest is assigned
   - [ ] Step 5: Quest shows in QuestGUI
   - [ ] Step 6: Catching 3 fish completes quest
   - [ ] Step 7: Quest completion triggers next step
   - [ ] Step 8: Crafting quest is assigned
   - [ ] Step 9: Crafting 1 item completes quest
   - [ ] Step 10: Tutorial completion message shows
   - [ ] Step 11: Rewards are given (1000 bells, 500 miles)

4. **Test Quest System**
   - [ ] Quest GUI opens with Q key (if implemented)
   - [ ] Active quests show correctly
   - [ ] Quest progress updates in real-time
   - [ ] Quest completion triggers reward
   - [ ] Completed quests are marked

5. **Test Persistence**
   - [ ] Complete tutorial, leave game, rejoin
   - [ ] Tutorial doesn't restart for returning players
   - [ ] Quest progress is saved
   - [ ] Completed quests stay completed

---

## 🐛 Common Issues & Solutions

### Issue: Tutorial doesn't start

**Solution**: Check these:
- Is `StartOnboarding` remote created in `ReplicatedStorage.Remotes`?
- Is OnboardingService initialized in server init?
- Is TutorialManager required in client init?
- Check output log for initialization messages

### Issue: Quests don't assign

**Solution**: Check these:
- Is `QuestEvent` remote created in `ReplicatedStorage.Remotes`?
- Is QuestService initialized and connected to handlers?
- Check output log for quest assignment messages
- Verify QuestData.TUTORIAL_QUESTS contains the quest

### Issue: Quest progress doesn't update

**Solution**: Check these:
- Is QuestHandlers connected to gameplay systems?
- Are quest handler functions being called? (add print statements)
- Is the objective type matching the handler? (e.g., "catch_fish")
- Check output log for progress messages

### Issue: Dialogue doesn't show

**Solution**: Check these:
- Is DialogueGUI module loading correctly?
- Are dialogue sequences formatted correctly?
- Is speaker name and text defined for each step?
- Check for errors in output log

---

## 📝 Tutorial Quest IDs

These are defined in `QuestData.TUTORIAL_QUESTS`:

- `fishing_tutorial` - Catch 3 fish (500 bells, 50 miles)
- `crafting_tutorial` - Craft 1 item (300 bells, 30 miles)
- `collect_fruit` - Collect 5 fruit (400 bells, 40 miles)

---

## 🎨 Customization

### Add More Tutorial Steps

Edit `TUTORIAL_STEPS` in `TutorialManager.luau`:

```lua
{
    name = "Explore the Island",
    dialogues = {
        {
            speaker = "Tom Nook",
            text = "Why don't you take a walk around your island?",
            duration = 3,
        },
    },
    questId = "explore_island", -- Create in QuestData
    waitForAction = "quest_completed",
},
```

### Add New Quest Types

1. Add to `QuestTypes.luau` (ObjectiveType enum)
2. Create handler in `QuestHandlers.luau`
3. Connect gameplay event to handler
4. Create quest template in `QuestData.luau`

### Customize Rewards

Edit quest rewards in `QuestData.luau`:

```lua
rewards = {
    bells = 1000,    -- Change bell amount
    miles = 100,     -- Change miles amount
    items = {        -- Add item rewards
        "tool_net",
        "furniture_chair",
    },
},
```

---

## 🚀 Next Steps

### After Tutorial is Working

1. **Add Daily Quests**
   - Auto-assign 3 random daily quests each day
   - Reset at midnight
   - Show in Quest GUI

2. **Add Quest Notifications**
   - Popup when quest is assigned
   - Popup when quest is completed
   - Sound effects

3. **Add Quest Rewards UI**
   - Show reward popup with animation
   - Display bells/miles earned
   - Show items received

4. **Add Achievement System**
   - Track lifetime stats
   - Award achievements for milestones
   - Display achievement popup

5. **Add Quest Markers**
   - Show markers on map for quest locations
   - Highlight quest-related NPCs
   - Add waypoints

---

## 📊 Success Metrics

### Tutorial Completion Rate
- **Target**: 80%+ of new players complete tutorial
- **Measure**: Track tutorial start vs. completion

### Quest Engagement
- **Target**: 60%+ of players complete at least 1 quest per day
- **Measure**: Track daily quest completions

### Retention
- **Target**: 40%+ Day 1 retention
- **Measure**: Players who return after completing tutorial

---

## ✅ Implementation Checklist

- [ ] TutorialManager created
- [ ] TutorialManager added to client init
- [ ] QuestService handles tutorial quest assignment
- [ ] FishingSystem connected to QuestHandlers
- [ ] CraftingSystem connected to QuestHandlers
- [ ] OnboardingService fires tutorial start
- [ ] Starter rewards given on completion
- [ ] Tested full tutorial flow
- [ ] Tested quest progress tracking
- [ ] Tested quest completion rewards
- [ ] Tested persistence across sessions
- [ ] Fixed any bugs found during testing

---

**Remember**: The tutorial is the player's first impression! Make sure it's smooth, clear, and rewarding. Test it thoroughly before launch! 🚀
