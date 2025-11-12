--[[
	IslandGenerationInterface.server.luau
	
	Server-side interface for the Island Generation GUI system.
	Handles generation requests from players via RemoteEvents.
	
	Features:
	- Generate complete island layouts (trees, rocks, flowers)
	- Clear preview objects
	- Save approved layouts permanently
	- Progress tracking and client updates
	- Per-player state management
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Import island generation modules
local ProceduralIslandSystem = require(ReplicatedStorage.Shared.ProceduralIslandSystem)

-- Create RemoteEvents folder
local remoteFolder = ReplicatedStorage:FindFirstChild("IslandGenRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "IslandGenRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local function createRemoteEvent(name: string): RemoteEvent
	local remote = remoteFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteFolder
	end
	return remote
end

local generateRemote = createRemoteEvent("GenerateIsland")
local saveRemote = createRemoteEvent("SaveIsland")
local clearRemote = createRemoteEvent("ClearIsland")
local progressRemote = createRemoteEvent("UpdateProgress")

-- Player generation states
local playerGenerationStates = {} -- [userId] = {isGenerating: boolean, objects: {}, system: ProceduralIslandSystem}

print("[IslandGenerationInterface] ✅ Server interface loaded")

--[[
	Update progress for a specific player
	@param player The player to update
	@param step Current step name
	@param progress Progress percentage (0-100)
	@param stats Object counts {trees, rocks, flowers}
]]
local function updateProgress(player: Player, step: string, progress: number, stats: {trees: number, rocks: number, flowers: number})
	progressRemote:FireClient(player, {
		step = step,
		progress = progress,
		stats = stats
	})
end



--[[
	Generate island layout for a player
	@param player The player requesting generation
]]
local function generateIsland(player: Player)
	local userId = player.UserId
	
	-- Check if already generating
	if playerGenerationStates[userId] and playerGenerationStates[userId].isGenerating then
		warn("[IslandGenerationInterface] Player", player.Name, "already generating")
		return
	end
	
	print("[IslandGenerationInterface] 🏝️ Starting island generation for", player.Name)
	
	-- Initialize state
	playerGenerationStates[userId] = {
		isGenerating = true,
		objects = {},
		system = nil
	}
	
	-- Define NEW island location: 200 studs away from main island
	local NEW_ISLAND_CENTER = Vector3.new(200, 0, 0) -- 200 studs on X axis
	local ISLAND_SIZE = Vector3.new(150, 50, 150) -- 300x300 island (150 radius)
	local SEA_LEVEL = 0 -- Adjust this to match your main island's sea level
	
	-- Wrap in pcall for error handling
	local success, result = pcall(function()
		-- STEP 1: Create terrain for new island (0-20%)
		updateProgress(player, "Creating new island terrain...", 0, {trees = 0, rocks = 0, flowers = 0})
		
		print("[IslandGenerationInterface] 🏝️ Generating terrain at", NEW_ISLAND_CENTER)
		
		-- Generate island terrain using noise
		local terrain = workspace.Terrain
		-- NOTE: Not clearing terrain to preserve user's existing island
		
		-- Create island terrain with grass
		for x = -ISLAND_SIZE.X, ISLAND_SIZE.X, 4 do
			for z = -ISLAND_SIZE.Z, ISLAND_SIZE.Z, 4 do
				local worldPos = NEW_ISLAND_CENTER + Vector3.new(x, 0, z)
				
				-- Calculate distance from center for island shape
				local distanceFromCenter = math.sqrt(x^2 + z^2)
				local maxDistance = math.min(ISLAND_SIZE.X, ISLAND_SIZE.Z)
				
				-- Only generate terrain within island radius
				if distanceFromCenter <= maxDistance then
					-- Height based on distance (higher in center, lower at edges)
					local heightMultiplier = 1 - (distanceFromCenter / maxDistance)
					local height = SEA_LEVEL + (20 * heightMultiplier) -- 20 studs max height
					
					-- Add some noise for natural variation
					local noise = math.noise(x / 20, z / 20) * 5
					height = height + noise
					
					-- Fill terrain from sea level to calculated height
					if height > SEA_LEVEL then
						terrain:FillBlock(
							CFrame.new(worldPos.X, SEA_LEVEL + height / 2, worldPos.Z),
							Vector3.new(4, height, 4),
							Enum.Material.Grass
						)
					end
				end
			end
		end
		
		updateProgress(player, "Terrain created!", 20, {trees = 0, rocks = 0, flowers = 0})
		task.wait(0.5)
		
		-- STEP 2: Initialize AI system with NEW island bounds (20-30%)
		updateProgress(player, "Analyzing new island...", 20, {trees = 0, rocks = 0, flowers = 0})
		
		local system = ProceduralIslandSystem.new()

		-- Override analyzer bounds to only scan NEW island area
		local customBounds = Region3.new(
			NEW_ISLAND_CENTER - ISLAND_SIZE,
			NEW_ISLAND_CENTER + ISLAND_SIZE
		)

		-- Custom initialization replicating ProceduralIslandSystem:initialize but with custom bounds
		system.analyzer = require(ReplicatedStorage.Shared.IslandAnalyzer).new(terrain, customBounds)
		system.analyzer:analyzeIsland()
		system.generator = require(ReplicatedStorage.Shared.IslandGenerator).new(system.analyzer)
		system.auditor = require(ReplicatedStorage.Shared.IslandAuditor).new(system.analyzer)
		system.initialized = true -- mark initialized to silence warnings

		playerGenerationStates[userId].system = system
		
		updateProgress(player, "Analysis complete!", 30, {trees = 0, rocks = 0, flowers = 0})
		task.wait(0.5)
		
		-- STEP 3: Generate trees (30-60%)
		updateProgress(player, "Generating trees...", 30, {trees = 0, rocks = 0, flowers = 0})
		
		-- Run tree generation cycle
		system:runGenerationCycle({
			trees = true,
			rocks = false,
			flowers = false,
			furniture = false
		})
		
		-- Apply tree proposals with validation
		local treesGenerated = 0
		local treeFolder = workspace:FindFirstChild("GeneratedObjects") and workspace.GeneratedObjects:FindFirstChild("trees")
		local beforeTreeCount = treeFolder and #treeFolder:GetChildren() or 0
		
		print("[IslandGenerationInterface] Starting tree generation...")
		
		for _, proposal in ipairs(system.pendingChanges.trees) do
			if treesGenerated >= 30 then break end -- Limit to 30 trees
			
			print(string.format("[IslandGenerationInterface] Applying tree at %s", tostring(proposal.position)))
			local success = system:applyProposal(proposal, "trees")
			if success then
				treesGenerated = treesGenerated + 1
				print(string.format("[IslandGenerationInterface] ✅ Tree %d created", treesGenerated))
			else
				warn("[IslandGenerationInterface] ❌ Failed to create tree")
			end
		end
		
		print(string.format("[IslandGenerationInterface] Tree generation complete: %d trees", treesGenerated))
		
		-- Track newly created trees
		if treeFolder then
			local afterTreeCount = #treeFolder:GetChildren()
			for i = beforeTreeCount + 1, afterTreeCount do
				local tree = treeFolder:GetChildren()[i]
				if tree then
					table.insert(playerGenerationStates[userId].objects, tree)
				end
			end
		end
		
		updateProgress(player, "Generating trees...", 50, {trees = treesGenerated, rocks = 0, flowers = 0})
		task.wait(0.5)
		
		-- STEP 3: Generate rocks (50-75%)
		updateProgress(player, "Generating rocks...", 50, {trees = treesGenerated, rocks = 0, flowers = 0})
		
		-- Run rock generation cycle
		system:runGenerationCycle({
			trees = false,
			rocks = true,
			flowers = false,
			furniture = false
		})
		
		-- Apply rock proposals
		local rocksGenerated = 0
		local rockFolder = workspace:FindFirstChild("GeneratedObjects") and workspace.GeneratedObjects:FindFirstChild("rocks")
		local beforeRockCount = rockFolder and #rockFolder:GetChildren() or 0
		
		for _, proposal in ipairs(system.pendingChanges.rocks) do
			if rocksGenerated >= 10 then break end -- Limit to 10 rocks
			
			local success = system:applyProposal(proposal, "rocks")
			if success then
				rocksGenerated = rocksGenerated + 1
			end
		end
		
		-- Track newly created rocks
		if rockFolder then
			local afterRockCount = #rockFolder:GetChildren()
			for i = beforeRockCount + 1, afterRockCount do
				local rock = rockFolder:GetChildren()[i]
				if rock then
					table.insert(playerGenerationStates[userId].objects, rock)
				end
			end
		end
		
		updateProgress(player, "Generating rocks...", 75, {trees = treesGenerated, rocks = rocksGenerated, flowers = 0})
		task.wait(0.5)
		
		-- STEP 4: Generate flowers (75-100%)
		updateProgress(player, "Generating flowers...", 75, {trees = treesGenerated, rocks = rocksGenerated, flowers = 0})
		
		-- Run flower generation cycle
		system:runGenerationCycle({
			trees = false,
			rocks = false,
			flowers = true,
			furniture = false
		})
		
		-- Apply flower proposals
		local flowersGenerated = 0
		local flowerFolder = workspace:FindFirstChild("GeneratedObjects") and workspace.GeneratedObjects:FindFirstChild("flowers")
		local beforeFlowerCount = flowerFolder and #flowerFolder:GetChildren() or 0
		
		for _, proposal in ipairs(system.pendingChanges.flowers) do
			if flowersGenerated >= 25 then break end -- Limit to 25 flowers
			
			local success = system:applyProposal(proposal, "flowers")
			if success then
				flowersGenerated = flowersGenerated + 1
			end
		end
		
		-- Track newly created flowers
		if flowerFolder then
			local afterFlowerCount = #flowerFolder:GetChildren()
			for i = beforeFlowerCount + 1, afterFlowerCount do
				local flower = flowerFolder:GetChildren()[i]
				if flower then
					table.insert(playerGenerationStates[userId].objects, flower)
				end
			end
		end
		
		updateProgress(player, "Complete! ✅", 100, {trees = treesGenerated, rocks = rocksGenerated, flowers = flowersGenerated})
		
		print("[IslandGenerationInterface] ✅ Generation complete:", treesGenerated, "trees,", rocksGenerated, "rocks,", flowersGenerated, "flowers")
	end)
	
	-- Handle errors
	if not success then
		warn("[IslandGenerationInterface] ❌ Generation failed:", result)
		updateProgress(player, "Error: " .. tostring(result), 0, {trees = 0, rocks = 0, flowers = 0})
	end
	
	-- Mark as no longer generating
	if playerGenerationStates[userId] then
		playerGenerationStates[userId].isGenerating = false
	end
end

--[[
	Clear preview objects for a player
	@param player The player requesting clear
]]
local function clearIsland(player: Player)
	local userId = player.UserId
	
	print("[IslandGenerationInterface] 🧹 Clearing preview for", player.Name)
	
	-- Check if player has state
	if not playerGenerationStates[userId] then
		warn("[IslandGenerationInterface] No preview to clear for", player.Name)
		return
	end
	
	-- Remove all preview objects
	local removed = 0
	for _, object in ipairs(playerGenerationStates[userId].objects) do
		if object and object.Parent then
			object:Destroy()
			removed = removed + 1
		end
	end
	
	-- Clear state
	playerGenerationStates[userId].objects = {}
	
	-- Update client
	updateProgress(player, "Preview cleared", 0, {trees = 0, rocks = 0, flowers = 0})
	
	print("[IslandGenerationInterface] ✅ Cleared", removed, "preview objects")
end

--[[
	Save island layout permanently for a player
	@param player The player requesting save
]]
local function saveIsland(player: Player)
	local userId = player.UserId
	
	print("[IslandGenerationInterface] 💾 Saving island for", player.Name)
	
	-- Check if player has state
	if not playerGenerationStates[userId] or #playerGenerationStates[userId].objects == 0 then
		warn("[IslandGenerationInterface] No preview to save for", player.Name)
		updateProgress(player, "Nothing to save", 0, {trees = 0, rocks = 0, flowers = 0})
		return
	end
	
	-- Create save folder structure
	local savedFolder = Workspace:FindFirstChild("SavedIslands")
	if not savedFolder then
		savedFolder = Instance.new("Folder")
		savedFolder.Name = "SavedIslands"
		savedFolder.Parent = Workspace
	end
	
	local playerFolder = savedFolder:FindFirstChild(player.Name)
	if not playerFolder then
		playerFolder = Instance.new("Folder")
		playerFolder.Name = player.Name
		playerFolder.Parent = savedFolder
	else
		-- Clear existing saved island
		playerFolder:ClearAllChildren()
	end
	
	-- Move objects to save folder
	local saved = 0
	for _, object in ipairs(playerGenerationStates[userId].objects) do
		if object and object.Parent then
			object.Parent = playerFolder
			saved = saved + 1
		end
	end
	
	-- Clear preview state
	playerGenerationStates[userId].objects = {}
	
	print("[IslandGenerationInterface] ✅ Saved", saved, "objects to", playerFolder:GetFullName())
	
	-- Count saved objects by category
	local trees = 0
	local rocks = 0
	local flowers = 0
	
	for _, object in ipairs(playerFolder:GetChildren()) do
		if object.Name:find("Tree") then
			trees = trees + 1
		elseif object.Name:find("Rock") then
			rocks = rocks + 1
		elseif object.Name:find("Flower") then
			flowers = flowers + 1
		end
	end
	
	updateProgress(player, "Island saved! ✅", 100, {trees = trees, rocks = rocks, flowers = flowers})
end

--[[
	Clean up player state when they leave
]]
local function cleanupPlayer(player: Player)
	local userId = player.UserId
	
	if playerGenerationStates[userId] then
		-- Remove any preview objects
		for _, object in ipairs(playerGenerationStates[userId].objects) do
			if object and object.Parent then
				object:Destroy()
			end
		end
		
		-- Clear state
		playerGenerationStates[userId] = nil
		
		print("[IslandGenerationInterface] 🧹 Cleaned up state for", player.Name)
	end
end

-- Connect RemoteEvents
generateRemote.OnServerEvent:Connect(function(player)
	generateIsland(player)
end)

saveRemote.OnServerEvent:Connect(function(player)
	saveIsland(player)
end)

clearRemote.OnServerEvent:Connect(function(player)
	clearIsland(player)
end)

-- Clean up on player leave
Players.PlayerRemoving:Connect(cleanupPlayer)

print("[IslandGenerationInterface] 🎮 All RemoteEvents connected and ready")
