--[[
	PlayerIslandService.luau
	
	Manages per-player islands with individual terrain, trees, rocks, and structures.
	Each player gets their own island at a unique location in the world.
	Handles island generation, persistence, and player spawning.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProceduralIslandSystem = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProceduralIslandSystem"))
local IsabelleVillagerManager = require(script.Parent:WaitForChild("IsabelleVillagerManager"))

local PlayerIslandService = {}
PlayerIslandService.__index = PlayerIslandService

-- Configuration
local ISLAND_SPACING = 1000 -- Studs between islands
local ISLAND_SIZE = Vector3.new(200, 50, 200) -- Size of each island
local SEA_LEVEL = 50

-- DataStore
local IslandDataStore = DataStoreService:GetDataStore("PlayerIslands_v1")

function PlayerIslandService.new()
	local self = setmetatable({}, PlayerIslandService)
	
	self.playerIslands = {} -- [userId] = islandData
	self.islandFolders = {} -- [userId] = folder in workspace
	self.nextIslandSlot = 0 -- Counter for island positions
	self.isabelleManager = nil
	
	return self
end

function PlayerIslandService:initialize()
	print("[PlayerIslandService] 🏝️ Initializing...")
	
	-- Create islands folder in workspace
	local islandsFolder = workspace:FindFirstChild("PlayerIslands")
	if not islandsFolder then
		islandsFolder = Instance.new("Folder")
		islandsFolder.Name = "PlayerIslands"
		islandsFolder.Parent = workspace
	end
	self.islandsFolder = islandsFolder
	self.isabelleManager = IsabelleVillagerManager.new()
	
	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerJoined(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerLeaving(player)
	end)
	
	print("[PlayerIslandService] ✅ Initialized")
end

function PlayerIslandService:onPlayerJoined(player)
	print(string.format("[PlayerIslandService] Player %s joined, loading island...", player.Name))
	
	-- Load or create island for this player
	local islandData = self:loadIsland(player.UserId)
	
	if not islandData then
		-- New player - create island
		islandData = self:createNewIsland(player.UserId)
	end
	
	self.playerIslands[player.UserId] = islandData
	
	-- Generate/regenerate island in world
	self:generateIslandInWorld(player.UserId, islandData)
	
	-- Spawn player on their island
	self:spawnPlayerOnIsland(player, islandData)
end

function PlayerIslandService:onPlayerLeaving(player)
	print(string.format("[PlayerIslandService] Player %s leaving, saving island...", player.Name))
	
	-- Save island data
	self:saveIsland(player.UserId)

	if self.isabelleManager then
		self.isabelleManager:despawnForIsland(player.UserId)
	end
	
	-- Clean up (optionally keep island in world for others to visit)
	-- For now, we'll keep islands loaded
	
	self.playerIslands[player.UserId] = nil
end

function PlayerIslandService:createNewIsland(userId)
	print(string.format("[PlayerIslandService] Creating new island for user %d", userId))
	
	-- Assign island position
	local islandCenter = self:getNextIslandPosition()
	
	local islandData = {
		userId = userId,
		center = {
			X = islandCenter.X,
			Y = islandCenter.Y,
			Z = islandCenter.Z,
		},
		size = {
			X = ISLAND_SIZE.X,
			Y = ISLAND_SIZE.Y,
			Z = ISLAND_SIZE.Z,
		},
		createdAt = os.time(),
		lastVisited = os.time(),
		
		-- Island features
		trees = {}, -- Positions of trees
		rocks = {}, -- Positions of rocks
		holes = {}, -- Positions of holes
		buildings = {}, -- Placed buildings
		
		-- Player progress
		hasCompletedTutorial = false,
		hasBuiltHome = false,
	}
	
	-- Save immediately
	self:saveIsland(userId, islandData)
	
	return islandData
end

function PlayerIslandService:getNextIslandPosition()
	-- Arrange islands in a grid pattern
	local row = math.floor(self.nextIslandSlot / 10)
	local col = self.nextIslandSlot % 10
	
	self.nextIslandSlot = self.nextIslandSlot + 1
	
	return Vector3.new(
		col * ISLAND_SPACING,
		SEA_LEVEL,
		row * ISLAND_SPACING
	)
end

function PlayerIslandService:generateIslandInWorld(userId, islandData)
	print(string.format("[PlayerIslandService] Generating island in world for user %d", userId))

	if self.isabelleManager then
		self.isabelleManager:despawnForIsland(userId)
	end
	
	-- Create island folder
	local islandFolder = self.islandsFolder:FindFirstChild("Island_" .. userId)
	if islandFolder then
		islandFolder:Destroy()
	end
	
	islandFolder = Instance.new("Folder")
	islandFolder.Name = "Island_" .. userId
	islandFolder.Parent = self.islandsFolder
	self.islandFolders[userId] = islandFolder
	
	local center = Vector3.new(islandData.center.X, islandData.center.Y, islandData.center.Z)
	local size = Vector3.new(islandData.size.X, islandData.size.Y, islandData.size.Z)
	
	-- Generate terrain
	self:generateIslandTerrain(center, size)
	
	-- Generate trees
	if #islandData.trees == 0 then
		-- First time - generate initial trees
		self:generateInitialTrees(userId, center, size)
	else
		-- Place saved trees
		for _, treeData in ipairs(islandData.trees) do
			self:placeTree(islandFolder, Vector3.new(treeData.X, treeData.Y, treeData.Z), treeData.type)
		end
	end
	
	-- Generate rocks
	if #islandData.rocks == 0 then
		self:generateInitialRocks(userId, center, size)
	else
		for _, rockData in ipairs(islandData.rocks) do
			self:placeRock(islandFolder, Vector3.new(rockData.X, rockData.Y, rockData.Z))
		end
	end
	
	-- Generate holes (if any)
	for _, holeData in ipairs(islandData.holes) do
		self:placeHole(islandFolder, Vector3.new(holeData.X, holeData.Y, holeData.Z))
	end
	
	-- Place buildings
	for _, buildingData in ipairs(islandData.buildings) do
		self:placeBuilding(islandFolder, buildingData)
	end
	
	-- Place starter workbench if new player
	if not islandData.hasCompletedTutorial then
		self:placeStarterWorkbench(islandFolder, center)
	end
	
	print(string.format("[PlayerIslandService] ✅ Island generated at %s", tostring(center)))

	if self.isabelleManager then
		self.isabelleManager:spawnForIsland(userId, islandFolder, center)
	end
end

function PlayerIslandService:generateIslandTerrain(center, size)
	local terrain = workspace.Terrain
	
	print(string.format("[PlayerIslandService] Generating terrain at %s", tostring(center)))
	
	-- Create island shape with grass
	for x = -size.X, size.X, 4 do
		for z = -size.Z, size.Z, 4 do
			local worldPos = center + Vector3.new(x, 0, z)
			
			-- Calculate distance from center for island shape
			local distanceFromCenter = math.sqrt(x^2 + z^2)
			local maxDistance = math.min(size.X, size.Z)
			
			-- Only generate within island radius
			if distanceFromCenter <= maxDistance then
				-- Height based on distance (higher in center, lower at edges)
				local heightMultiplier = 1 - (distanceFromCenter / maxDistance)
				local baseHeight = 20 * heightMultiplier
				
				-- Add noise for natural variation
				local noise = math.noise(x / 20, z / 20) * 5
				local height = math.max(1, baseHeight + noise)
				
				-- Fill terrain
				terrain:FillBlock(
					CFrame.new(worldPos.X, center.Y + height / 2, worldPos.Z),
					Vector3.new(4, height, 4),
					Enum.Material.Grass
				)
			end
		end
	end
	
	-- Add beach sand around edges
	for x = -size.X, size.X, 4 do
		for z = -size.Z, size.Z, 4 do
			local worldPos = center + Vector3.new(x, 0, z)
			local distanceFromCenter = math.sqrt(x^2 + z^2)
			local maxDistance = math.min(size.X, size.Z)
			
			-- Beach zone
			if distanceFromCenter > maxDistance * 0.8 and distanceFromCenter <= maxDistance then
				terrain:FillBlock(
					CFrame.new(worldPos.X, center.Y + 1, worldPos.Z),
					Vector3.new(4, 2, 4),
					Enum.Material.Sand
				)
			end
		end
	end
end

function PlayerIslandService:generateInitialTrees(userId, center, size)
	local islandData = self.playerIslands[userId]
	if not islandData then return end
	
	-- Generate 10-20 trees randomly placed
	local treeCount = math.random(10, 20)
	local islandFolder = self.islandFolders[userId]
	
	for i = 1, treeCount do
		-- Random position within island (avoiding center plaza)
		local angle = math.random() * math.pi * 2
		local distance = math.random(30, size.X * 0.7)
		
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		local pos = center + Vector3.new(x, 20, z)
		
		-- Raycast to find terrain surface
		local ray = workspace:Raycast(pos + Vector3.new(0, 100, 0), Vector3.new(0, -200, 0))
		if ray then
			pos = ray.Position
		end
		
		-- Place tree
		self:placeTree(islandFolder, pos, "Oak")
		
		-- Save to island data
		table.insert(islandData.trees, {
			X = pos.X,
			Y = pos.Y,
			Z = pos.Z,
			type = "Oak"
		})
	end
end

function PlayerIslandService:generateInitialRocks(userId, center, size)
	local islandData = self.playerIslands[userId]
	if not islandData then return end
	
	-- Generate 5-8 rocks
	local rockCount = math.random(5, 8)
	local islandFolder = self.islandFolders[userId]
	
	for i = 1, rockCount do
		local angle = math.random() * math.pi * 2
		local distance = math.random(25, size.X * 0.6)
		
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		local pos = center + Vector3.new(x, 20, z)
		
		-- Raycast to terrain
		local ray = workspace:Raycast(pos + Vector3.new(0, 100, 0), Vector3.new(0, -200, 0))
		if ray then
			pos = ray.Position
		end
		
		self:placeRock(islandFolder, pos)
		
		table.insert(islandData.rocks, {
			X = pos.X,
			Y = pos.Y,
			Z = pos.Z,
		})
	end
end

function PlayerIslandService:placeTree(folder, position, treeType)
	-- Try to get tree from ReplicatedStorage
	local treeTemplate = ReplicatedStorage:FindFirstChild("OakTree")
	
	if treeTemplate and treeTemplate:IsA("Model") then
		local tree = treeTemplate:Clone()
		tree:SetPrimaryPartCFrame(CFrame.new(position))
		
		-- Anchor all parts
		for _, part in ipairs(tree:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
		
		tree.Parent = folder
	else
		-- Fallback simple tree
		local tree = Instance.new("Model")
		tree.Name = "Tree"
		
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Size = Vector3.new(2, 8, 2)
		trunk.Position = position + Vector3.new(0, 4, 0)
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.BrickColor = BrickColor.new("Brown")
		trunk.Parent = tree
		
		local leaves = Instance.new("Part")
		leaves.Name = "Leaves"
		leaves.Size = Vector3.new(6, 6, 6)
		leaves.Position = position + Vector3.new(0, 9, 0)
		leaves.Anchored = true
		leaves.Material = Enum.Material.Grass
		leaves.BrickColor = BrickColor.new("Dark green")
		leaves.Shape = Enum.PartType.Ball
		leaves.Parent = tree
		
		tree.PrimaryPart = trunk
		tree.Parent = folder
	end
end

function PlayerIslandService:placeRock(folder, position)
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Size = Vector3.new(3, 2, 3)
	rock.Position = position + Vector3.new(0, 1, 0)
	rock.Anchored = true
	rock.Material = Enum.Material.Rock
	rock.BrickColor = BrickColor.new("Medium stone grey")
	rock.Shape = Enum.PartType.Ball
	rock.Parent = folder
end

function PlayerIslandService:placeHole(folder, position)
	local hole = Instance.new("Part")
	hole.Name = "Hole"
	hole.Size = Vector3.new(2, 0.5, 2)
	hole.Position = position
	hole.Anchored = true
	hole.Material = Enum.Material.Ground
	hole.BrickColor = BrickColor.new("Dark stone grey")
	hole.Shape = Enum.PartType.Cylinder
	hole.Orientation = Vector3.new(0, 0, 90)
	hole.Parent = folder
end

function PlayerIslandService:placeBuilding(folder, buildingData)
	-- TODO: Implement building placement
	print("[PlayerIslandService] Building placement not yet implemented")
end

function PlayerIslandService:placeStarterWorkbench(folder, center)
	-- Place a DIY workbench near the center of the island
	local workbenchPos = center + Vector3.new(10, 20, 0)
	
	-- Raycast to find terrain
	local ray = workspace:Raycast(workbenchPos + Vector3.new(0, 100, 0), Vector3.new(0, -200, 0))
	if ray then
		workbenchPos = ray.Position + Vector3.new(0, 1.5, 0)
	end
	
	-- Get DIYWorkbenchService to place it
	local DIYWorkBenchService = require(script.Parent.DIYWorkBenchService)
	if DIYWorkBenchService.placeWorkbench then
		-- This will be called by the service singleton
		print("[PlayerIslandService] Workbench placement handled by DIYWorkBenchService")
	else
		-- Create simple workbench directly
		local workbench = Instance.new("Model")
		workbench.Name = "DIYWorkBench"
		
		local table = Instance.new("Part")
		table.Name = "Table"
		table.Size = Vector3.new(4, 0.5, 3)
		table.Position = workbenchPos
		table.Anchored = true
		table.Material = Enum.Material.Wood
		table.BrickColor = BrickColor.new("Brown")
		table.Parent = workbench
		
		workbench.PrimaryPart = table
		workbench.Parent = folder
	end
end

function PlayerIslandService:spawnPlayerOnIsland(player, islandData)
	local center = Vector3.new(islandData.center.X, islandData.center.Y, islandData.center.Z)
	
	-- Spawn slightly above island center
	local spawnPosition = center + Vector3.new(0, 25, 0)
	
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	humanoidRootPart.CFrame = CFrame.new(spawnPosition)
	
	print(string.format("[PlayerIslandService] Spawned %s at %s", player.Name, tostring(spawnPosition)))
end

function PlayerIslandService:loadIsland(userId)
	local success, data = pcall(function()
		return IslandDataStore:GetAsync("Island_" .. userId)
	end)
	
	if not success then
		warn(string.format("[PlayerIslandService] Failed to load island for user %d: %s", userId, tostring(data)))
		return nil
	end
	
	if data then
		print(string.format("[PlayerIslandService] Loaded island for user %d", userId))
		data.lastVisited = os.time()
	end
	
	return data
end

function PlayerIslandService:saveIsland(userId, islandData)
	islandData = islandData or self.playerIslands[userId]
	
	if not islandData then
		return
	end
	
	-- Update timestamp
	islandData.lastVisited = os.time()
	
	local success, err = pcall(function()
		IslandDataStore:SetAsync("Island_" .. userId, islandData)
	end)
	
	if success then
		print(string.format("[PlayerIslandService] ✅ Saved island for user %d", userId))
	else
		warn(string.format("[PlayerIslandService] ❌ Failed to save island for user %d: %s", userId, tostring(err)))
	end
end

function PlayerIslandService:getPlayerIsland(userId)
	return self.playerIslands[userId]
end

function PlayerIslandService:getPlayerIslandFolder(userId)
	return self.islandFolders[userId]
end

-- Add a tree to a player's island
function PlayerIslandService:addTreeToIsland(userId, position, treeType)
	local islandData = self.playerIslands[userId]
	if not islandData then return end
	
	local folder = self.islandFolders[userId]
	if not folder then return end
	
	self:placeTree(folder, position, treeType)
	
	table.insert(islandData.trees, {
		X = position.X,
		Y = position.Y,
		Z = position.Z,
		type = treeType or "Oak"
	})
	
	self:saveIsland(userId)
end

-- Add a hole to a player's island
function PlayerIslandService:addHoleToIsland(userId, position)
	local islandData = self.playerIslands[userId]
	if not islandData then return end
	
	local folder = self.islandFolders[userId]
	if not folder then return end
	
	self:placeHole(folder, position)
	
	table.insert(islandData.holes, {
		X = position.X,
		Y = position.Y,
		Z = position.Z,
	})
	
	self:saveIsland(userId)
end

return PlayerIslandService

