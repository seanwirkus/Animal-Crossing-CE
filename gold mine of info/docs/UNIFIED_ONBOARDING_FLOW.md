# 🏝️ Unified Onboarding Flow - Complete Documentation

**Status**: ✅ **COMPLETE & CONSOLIDATED**  
**Date**: October 22, 2025  
**Architecture**: Single-file orchestrated state machine

---

## 📋 Overview

The onboarding flow has been completely unified into **ONE seamless orchestrated experience**. Instead of multiple separate GUIs and remote handlers that could create duplicate interactions, everything now flows through a single `UnifiedOnboardingFlow` module.

### The Old Way (Fragmented)
```
Tom Nook Interaction
    ↓
Multiple Remote Listeners
    ↓
IslandSelection GUI + OnboardingGUI (separate files)
    ↓
Island Generation Remote
    ↓
Teleport (if successful) or Error
```

### The New Way (Unified)
```
Tom Nook Interaction (ProximityPrompt)
    ↓
OpenOnboardingGUI Remote
    ↓
UnifiedOnboardingFlow.new() → Begin()
    ├─ Tom Nook Greeting Dialogue
    ├─ Island Template Selection
    ├─ Island Name Customization
    ├─ Generation Loading Screen
    ├─ Fire GeneratePlayerIsland to Server
    └─ Monitor Teleport → Complete
```

---

## 🏗️ Architecture

### Core Components

| Component | Location | Purpose |
|-----------|----------|---------|
| **UnifiedOnboardingFlow** | `src/client/UI/UnifiedOnboardingFlow.luau` | Orchestrates entire flow via state machine |
| **OpenOnboardingGUI Remote** | `src/server/Services/RemoteRegistry.luau` | Fired by TomNookSpawner to start flow |
| **GeneratePlayerIsland Remote** | `src/server/init.server.luau:1025` | Server-side island creation handler |
| **TomNookSpawner** | `src/server/Systems/TomNookSpawner.luau` | Spawns Tom Nook and triggers interaction |
| **Init.client.luau** | Lines 964-996 | Listens for OpenOnboardingGUI and creates UnifiedOnboardingFlow |

### State Machine

```
IDLE
  ↓ (Begin() called)
SHOWING_GREETING (Tom Nook dialogue)
  ↓ (After 3 seconds)
SHOWING_SELECTION (Island template picker)
  ↓ (Player confirms selection)
GENERATING (Loading screen shown)
  ↓ (GeneratePlayerIsland fires to server)
COMPLETE (Success - Isabelle greeting shown)
  ↓ (Flow destroyed)
IDLE (ready for next flow)

Alternative paths:
CANCELLED (Player clicked cancel during selection)
ERROR (Something failed - retries allowed)
```

---

## 🔄 Complete Flow Walkthrough

### **Stage 1: Tom Nook Interaction**
```lua
-- Player presses E near Tom Nook at hub
TomNookSpawner._connections.promptTriggered:Connect(function(player)
    self:HandleInteraction(player)  -- Line 157
end)

-- TomNookSpawner:HandleInteraction(player)
-- Checks if player has island
-- If no: fires OpenOnboardingGUI remote
openGuiRemote:FireClient(player)
```

**Server Code**: ```183:225:src/server/Systems/TomNookSpawner.luau```

### **Stage 2: Client Receives OpenOnboardingGUI Remote**
```lua
openOnboardingRemote.OnClientEvent:Connect(function()
    -- Line 964-996 in init.client.luau
    
    local templates = buildUiTemplates()
    activeOnboardingFlow = UnifiedOnboardingFlow.new({
        templates = templates,
        remotes = RemotesFolder,
    })
    
    activeOnboardingFlow:Begin()
end)
```

**Client Code**: ```964:996:src/client/init.client.luau```

### **Stage 3: Unified Flow Begins**
```lua
function UnifiedOnboardingFlow:Begin()
    self._state = STATES.SHOWING_GREETING
    self:_showTomNookGreeting()
end

function UnifiedOnboardingFlow:_showTomNookGreeting()
    DialogueSystem.ShowVillagerDialogue(...)
    task.wait(3)
    self:_showIslandSelection()
end
```

**Flow Code**: ```52:72:src/client/UI/UnifiedOnboardingFlow.luau```

### **Stage 4: Island Selection GUI**
```lua
function UnifiedOnboardingFlow:_showIslandSelection()
    local onboardingGui = OnboardingGUI.new({
        templates = self._templates,
        onConfirm = function(selection)
            self:_handleSelectionConfirm(selection)
        end,
    })
end
```

**Flow Code**: ```106:124:src/client/UI/UnifiedOnboardingFlow.luau```

### **Stage 5: Island Generation**
```lua
function UnifiedOnboardingFlow:_handleSelectionConfirm(selection)
    self:_showGenerationScreen(selection.template, selection.islandName)
    task.wait(1)
    
    generateIslandRemote:FireServer(selection.islandName, islandConfig)
    self:_listenForGenerationResponse()
end
```

**Flow Code**: ```126:179:src/client/UI/UnifiedOnboardingFlow.luau```

### **Stage 6: Server-Side Island Generation**
```lua
generatePlayerIslandRemote.OnServerEvent:Connect(function(player, islandName, islandConfig)
    -- 1. Create island data in DataStore
    local success, islandData = playerIslandService:CreateIsland(player, islandName)
    
    -- 2. Generate terrain
    local islandFolder = playerIslandService:GenerateIslandTerrain(player, islandData)
    
    -- 3. Spawn NPCs (with delay to prevent race condition)
    islandNPCManager:SpawnIslandNPCs(islandFolder, player.UserId)
    task.wait(0.5)
    islandVillagerSpawner:SpawnVillagersOnIsland(islandFolder, player.UserId)
    
    -- 4. Teleport player
    playerIslandService:TeleportToIsland(player, player.UserId)
end)
```

**Server Code**: ```1025:1094:src/server/init.server.luau```

### **Stage 7: Client Detects Teleport & Completes**
```lua
function UnifiedOnboardingFlow:_listenForGenerationResponse()
    local startPos = startPos.Position
    
    while waitTime < 10 do
        local currentPos = currentPos.Position
        if (currentPos - startPos).Magnitude > 50 then
            -- Player was teleported!
            self:_completeOnboarding()
            return
        end
        task.wait(0.5)
    end
end

function UnifiedOnboardingFlow:_completeOnboarding()
    -- Show success message from Isabelle
    DialogueSystem.ShowVillagerDialogue(...)
    self:Destroy()
end
```

**Flow Code**: ```181:242:src/client/UI/UnifiedOnboardingFlow.luau```

---

## 🛡️ Error Recovery

### Server-Side Error Responses
If island creation fails on the server, a `CreateIslandResponse` remote is fired:

```lua
if not success then
    local createIslandResponseRemote = remotes:Get("CreateIslandResponse")
    createIslandResponseRemote:FireClient(player, false, errorMessage)
    return
end
```

### Client-Side Error Handling
```lua
function UnifiedOnboardingFlow:_showError(message)
    self._state = STATES.ERROR
    
    -- Destroy loading screen
    if self._generationScreen then
        self._generationScreen:Destroy()
    end
    
    -- Show error dialogue
    DialogueSystem.ShowVillagerDialogue(...)
    
    -- Allow retry
    self._state = STATES.IDLE
end
```

---

## 🧪 Testing Checklist

- [ ] Player joins and sees Tom Nook at hub
- [ ] Pressing E on Tom Nook opens OnboardingGUI directly (no separate selection)
- [ ] Island template selection shows 3+ options
- [ ] Entering island name validates (3-14 chars, alphanumeric + spaces/hyphens)
- [ ] "Creating..." screen appears after confirmation
- [ ] Server successfully generates island terrain
- [ ] NPCs spawn on island (Isabelle, Tom Nook, Orville)
- [ ] Random villagers spawn (2-5) after a 0.5s delay
- [ ] Player teleports to island automatically
- [ ] Isabelle greeting shown on arrival
- [ ] No duplicate GUI windows appear
- [ ] Error handling works if island generation fails
- [ ] Player can retry on error without duplicates

---

## 📊 Key Improvements

### Before Consolidation
- ❌ Multiple remote listeners for same event
- ❌ Separate IslandSelection and OnboardingGUI files
- ❌ Complex nested callbacks difficult to follow
- ❌ Potential for duplicate GUI spawns (as seen in logs)
- ❌ Hard to track state across multiple files

### After Consolidation
- ✅ **Single entry point**: `OpenOnboardingGUI` → `UnifiedOnboardingFlow`
- ✅ **Single state machine**: Clear progression through stages
- ✅ **Single orchestrator**: All logic in one file for easy correlation
- ✅ **Duplicate prevention**: `activeOnboardingFlow` guard prevents multiple flows
- ✅ **Better maintainability**: One place to modify entire flow
- ✅ **Clear error recovery**: Timeout and error states with retries

---

## 🔧 Disabled Systems

The following duplicate/legacy systems are intentionally disabled:

| System | File | Reason |
|--------|------|--------|
| **TomNookRealSpawner** | `src/server/Systems/TomNookRealSpawner.luau` | Merged into TomNookSpawner |
| **OrvilleSpawner** | `src/server/Systems/OrvilleSpawner.luau` | Orville only spawns on islands |
| **Old IslandSelection listener** | `src/client/init.client.luau:965-1026 (old)` | Replaced by UnifiedOnboardingFlow |

---

## 📝 File References

**Client-side orchestration**:
- ```52:72:src/client/UI/UnifiedOnboardingFlow.luau``` - Begin greeting
- ```106:124:src/client/UI/UnifiedOnboardingFlow.luau``` - Show selection
- ```126:179:src/client/UI/UnifiedOnboardingFlow.luau``` - Handle confirmation
- ```181:242:src/client/UI/UnifiedOnboardingFlow.luau``` - Listen for response

**Server-side orchestration**:
- ```1025:1094:src/server/init.server.luau``` - GeneratePlayerIsland handler
- ```1054:1069:src/server/init.server.luau``` - NPC spawning with race condition fix

**Remote registration**:
- ```75:76:src/server/Services/RemoteRegistry.luau``` - GeneratePlayerIsland remote
- ```76:76:src/server/Services/RemoteRegistry.luau``` - CreateIslandResponse remote

---

## 🚀 Future Enhancements

1. **Add progress animation** during island generation
2. **Show real-time status updates** ("Planting trees", "Spawning villagers", etc.)
3. **Allow island customization** (difficulty, size, biome) before generation
4. **Implement rollback** if generation fails partway through
5. **Add skip option** for experienced players creating alt accounts

---

**Created**: October 22, 2025  
**Last Updated**: October 22, 2025
