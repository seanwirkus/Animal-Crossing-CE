--[[
    Island Generation Interface
    Provides GUI controls in NooksTent for AI island generation
    Allows p
    layers to generate, preview, and save island layouts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Get modules
local IslandAnalyzer = require(ServerScriptService.IslandGeneration.IslandAnalyzer)
local IslandGenerator = require(ServerScriptService.IslandGeneration.IslandGenerator)
local IslandAuditor = require(ServerScriptService.IslandGeneration.IslandAuditor)
local ProceduralIslandSystem = require(ServerScriptService.IslandGeneration.ProceduralIslandSystem)

-- Create RemoteEvents for client-server communication
local remoteFolder = ReplicatedStorage:FindFirstChild("IslandGenRemotes") or Instance.new("Folder")
remoteFolder.Name = "IslandGenRemotes"
remoteFolder.Parent = ReplicatedStorage

local generateIslandRemote = remoteFolder:FindFirstChild("GenerateIsland") or Instance.new("RemoteEvent")
generateIslandRemote.Name = "GenerateIsland"
generateIslandRemote.Parent = remoteFolder

local saveIslandRemote = remoteFolder:FindFirstChild("SaveIsland") or Instance.new("RemoteEvent")
saveIslandRemote.Name = "SaveIsland"
saveIslandRemote.Parent = remoteFolder

local clearIslandRemote = remoteFolder:FindFirstChild("ClearIsland") or Instance.new("RemoteEvent")
clearIslandRemote.Name = "ClearIsland"
clearIslandRemote.Parent = remoteFolder

local updateProgressRemote = remoteFolder:FindFirstChild("UpdateProgress") or Instance.new("RemoteEvent")
updateProgressRemote.Name = "UpdateProgress"
updateProgressRemote.Parent = remoteFolder

-- Store player generation states
local playerGenerationStates = {}

-- Island generation configuration
local GENERATION_CONFIG = {
    trees = {
        proposalCount = 100,  -- Generate 100 tree proposals
        targetCount = 30,     -- Try to place 30 trees
        minQuality = 60       -- Minimum quality score
    },
    rocks = {
        proposalCount = 50,
        targetCount = 10,
        minQuality = 70
    },
    flowers = {
        proposalCount = 80,
        targetCount = 25,
        minQuality = 50
    }
}

--[[
    Generate island with progress updates
]]
local function generateIsland(player: Player)
    print("[IslandGenInterface] Starting generation for:", player.Name)
    
    -- Initialize state
    playerGenerationStates[player.UserId] = {
        isGenerating = true,
        objects = {}
    }
    
    local state = playerGenerationStates[player.UserId]
    
    -- Step 1: Analyze terrain
    updateProgressRemote:FireClient(player, {
        step = "analyzing",
        progress = 0,
        message = "Analyzing island terrain..."
    })
    
    task.wait(0.1)
    local terrainData = IslandAnalyzer.analyze()
    
    if not terrainData then
        warn("[IslandGenInterface] ❌ Terrain analysis failed")
        updateProgressRemote:FireClient(player, {
            step = "error",
            message = "Failed to analyze terrain"
        })
        state.isGenerating = false
        return
    end
    
    print("[IslandGenInterface] ✅ Terrain analyzed")
    
    -- Step 2: Generate trees
    updateProgressRemote:FireClient(player, {
        step = "generating_trees",
        progress = 25,
        message = "Planting trees..."
    })
    
    task.wait(0.1)
    local treeProposals = IslandGenerator.generateTreeProposals(
        terrainData,
        GENERATION_CONFIG.trees.proposalCount
    )
    
    local approvedTrees = IslandAuditor.auditProposals(treeProposals, terrainData)
    
    -- Filter by quality and apply
    local qualityTrees = {}
    for _, proposal in ipairs(approvedTrees) do
        if proposal.quality >= GENERATION_CONFIG.trees.minQuality then
            table.insert(qualityTrees, proposal)
        end
    end
    
    -- Take top N trees
    local treesToPlace = {}
    for i = 1, math.min(#qualityTrees, GENERATION_CONFIG.trees.targetCount) do
        table.insert(treesToPlace, qualityTrees[i])
    end
    
    local treeObjects = ProceduralIslandSystem.applyProposals(treesToPlace, "trees")
    for _, obj in ipairs(treeObjects) do
        table.insert(state.objects, obj)
    end
    
    print("[IslandGenInterface] ✅ Placed", #treeObjects, "trees")
    
    -- Step 3: Generate rocks
    updateProgressRemote:FireClient(player, {
        step = "generating_rocks",
        progress = 50,
        message = "Placing rocks..."
    })
    
    task.wait(0.1)
    local rockProposals = IslandGenerator.generateRockProposals(
        terrainData,
        GENERATION_CONFIG.rocks.proposalCount
    )
    
    local approvedRocks = IslandAuditor.auditProposals(rockProposals, terrainData)
    
    local qualityRocks = {}
    for _, proposal in ipairs(approvedRocks) do
        if proposal.quality >= GENERATION_CONFIG.rocks.minQuality then
            table.insert(qualityRocks, proposal)
        end
    end
    
    local rocksToPlace = {}
    for i = 1, math.min(#qualityRocks, GENERATION_CONFIG.rocks.targetCount) do
        table.insert(rocksToPlace, qualityRocks[i])
    end
    
    local rockObjects = ProceduralIslandSystem.applyProposals(rocksToPlace, "rocks")
    for _, obj in ipairs(rockObjects) do
        table.insert(state.objects, obj)
    end
    
    print("[IslandGenInterface] ✅ Placed", #rockObjects, "rocks")
    
    -- Step 4: Generate flowers
    updateProgressRemote:FireClient(player, {
        step = "generating_flowers",
        progress = 75,
        message = "Planting flowers..."
    })
    
    task.wait(0.1)
    local flowerProposals = IslandGenerator.generateFlowerProposals(
        terrainData,
        GENERATION_CONFIG.flowers.proposalCount
    )
    
    local approvedFlowers = IslandAuditor.auditProposals(flowerProposals, terrainData)
    
    local qualityFlowers = {}
    for _, proposal in ipairs(approvedFlowers) do
        if proposal.quality >= GENERATION_CONFIG.flowers.minQuality then
            table.insert(qualityFlowers, proposal)
        end
    end
    
    local flowersToPlace = {}
    for i = 1, math.min(#qualityFlowers, GENERATION_CONFIG.flowers.targetCount) do
        table.insert(flowersToPlace, qualityFlowers[i])
    end
    
    local flowerObjects = ProceduralIslandSystem.applyProposals(flowersToPlace, "flowers")
    for _, obj in ipairs(flowerObjects) do
        table.insert(state.objects, obj)
    end
    
    print("[IslandGenInterface] ✅ Placed", #flowerObjects, "flowers")
    
    -- Complete
    updateProgressRemote:FireClient(player, {
        step = "complete",
        progress = 100,
        message = "Island generation complete!",
        stats = {
            trees = #treeObjects,
            rocks = #rockObjects,
            flowers = #flowerObjects
        }
    })
    
    state.isGenerating = false
    
    print("[IslandGenInterface] 🎉 Generation complete for", player.Name)
    print("  Trees:", #treeObjects)
    print("  Rocks:", #rockObjects)
    print("  Flowers:", #flowerObjects)
end

--[[
    Clear generated objects for a player
]]
local function clearIsland(player: Player)
    local state = playerGenerationStates[player.UserId]
    if not state then return end
    
    print("[IslandGenInterface] Clearing island for:", player.Name)
    
    for _, obj in ipairs(state.objects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    
    state.objects = {}
    
    updateProgressRemote:FireClient(player, {
        step = "cleared",
        message = "Island cleared"
    })
end

--[[
    Save generated island layout
]]
local function saveIsland(player: Player)
    local state = playerGenerationStates[player.UserId]
    if not state then
        warn("[IslandGenInterface] No generation state for:", player.Name)
        return
    end
    
    print("[IslandGenInterface] Saving island for:", player.Name)
    
    -- Create permanent folder in Workspace
    local savedIslands = Workspace:FindFirstChild("SavedIslands") or Instance.new("Folder")
    savedIslands.Name = "SavedIslands"
    savedIslands.Parent = Workspace
    
    local playerIsland = savedIslands:FindFirstChild(player.Name) or Instance.new("Folder")
    playerIsland.Name = player.Name
    playerIsland.Parent = savedIslands
    
    -- Clear existing saved objects
    playerIsland:ClearAllChildren()
    
    -- Move generated objects to saved folder
    local savedCount = 0
    for _, obj in ipairs(state.objects) do
        if obj and obj.Parent then
            obj.Parent = playerIsland
            savedCount = savedCount + 1
        end
    end
    
    -- Clear state
    state.objects = {}
    
    print("[IslandGenInterface] ✅ Saved", savedCount, "objects for", player.Name)
    
    updateProgressRemote:FireClient(player, {
        step = "saved",
        message = "Island saved successfully!",
        count = savedCount
    })
end

-- Remote event handlers
generateIslandRemote.OnServerEvent:Connect(function(player)
    local state = playerGenerationStates[player.UserId]
    
    -- Prevent multiple generations at once
    if state and state.isGenerating then
        warn("[IslandGenInterface] Generation already in progress for:", player.Name)
        return
    end
    
    -- Generate in separate thread
    task.spawn(function()
        local success, err = pcall(function()
            generateIsland(player)
        end)
        
        if not success then
            warn("[IslandGenInterface] ❌ Generation error:", err)
            updateProgressRemote:FireClient(player, {
                step = "error",
                message = "Generation failed: " .. tostring(err)
            })
            
            if playerGenerationStates[player.UserId] then
                playerGenerationStates[player.UserId].isGenerating = false
            end
        end
    end)
end)

clearIslandRemote.OnServerEvent:Connect(function(player)
    local success, err = pcall(function()
        clearIsland(player)
    end)
    
    if not success then
        warn("[IslandGenInterface] ❌ Clear error:", err)
    end
end)

saveIslandRemote.OnServerEvent:Connect(function(player)
    local success, err = pcall(function()
        saveIsland(player)
    end)
    
    if not success then
        warn("[IslandGenInterface] ❌ Save error:", err)
        updateProgressRemote:FireClient(player, {
            step = "error",
            message = "Save failed: " .. tostring(err)
        })
    end
end)

-- Cleanup on player leave
game.Players.PlayerRemoving:Connect(function(player)
    playerGenerationStates[player.UserId] = nil
end)

print("[IslandGenInterface] ✅ Interface ready!")