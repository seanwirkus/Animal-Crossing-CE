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
	
	-- Generate many more trees for full island coverage (distributed across entire island)
	local treeCount = math.random(60, 100) -- Increased to 60-100 for full island coverage
	local islandFolder = self.islandFolders[userId]
	
	local treesPlaced = 0
	local attempts = 0
	local maxAttempts = treeCount * 50 -- Increased attempts for better distribution across entire island
	
	-- Minimum spacing between trees (INCREASED for better distribution)
	local MIN_TREE_SPACING = 10 -- Increased from 2 to 10 studs
	
	-- Grid-based distribution to ensure even spread across island
	local gridCellSize = 25 -- Grid cell size in studs
	local treesPerCell = 1 -- Max 1 tree per grid cell
	local usedGridCells = {} -- Track which grid cells have trees
	
	-- Function to get grid cell key for position
	local function getGridKey(position)
		local gridX = math.floor(position.X / gridCellSize)
		local gridZ = math.floor(position.Z / gridCellSize)
		return gridX .. "," .. gridZ
	end
	
	-- Function to check if position is in a used grid cell
	local function isGridCellUsed(position)
		local key = getGridKey(position)
		return usedGridCells[key] and usedGridCells[key] >= treesPerCell
	end
	
	-- Function to mark grid cell as used
	local function markGridCellUsed(position)
		local key = getGridKey(position)
		usedGridCells[key] = (usedGridCells[key] or 0) + 1
	end
	
	-- Valid materials for trees (prioritize Grass)
	local validTreeMaterials = {
		[Enum.Material.Grass] = 3, -- Grass is 3x more likely
		[Enum.Material.Ground] = 1,
		[Enum.Material.Sand] = 1,
		[Enum.Material.Snow] = 1,
		[Enum.Material.Mud] = 1,
	}
	
	-- Collect all potential tree positions across the island using RANDOM sampling instead of grid
	local candidatePositions = {}
	local islandRadius = math.min(size.X, size.Z) * 0.95 -- Use 95% of island size (cover more area)
	local minDistanceFromCenter = 15 -- Reduced from 20 to allow trees closer to center
	
	-- Generate random candidate positions instead of grid pattern to prevent lines
	local numCandidates = treeCount * 8 -- Generate 8x more candidates for better distribution
	for i = 1, numCandidates do
		-- Random angle and distance for better distribution
		local angle = math.random() * math.pi * 2 -- Random angle in radians
		local distance = math.random(minDistanceFromCenter, islandRadius) -- Random distance from center
		
		-- Convert to X/Z coordinates
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		
		-- Add some random variation to break up patterns
		x = x + (math.random() - 0.5) * 10 -- ±5 studs variation
		z = z + (math.random() - 0.5) * 10 -- ±5 studs variation
		
		local pos = center + Vector3.new(x, 20, z)
		table.insert(candidatePositions, pos)
	end
	
	-- Shuffle candidate positions for additional randomization
	for i = #candidatePositions, 2, -1 do
		local j = math.random(i)
		candidatePositions[i], candidatePositions[j] = candidatePositions[j], candidatePositions[i]
	end
	
	-- Try placing trees with even distribution
	local placedTreePositions = {} -- Track placed tree positions for spacing check
	
	-- Use random sampling instead of sequential iteration to prevent line patterns
	local shuffledIndices = {}
	for i = 1, #candidatePositions do
		table.insert(shuffledIndices, i)
	end
	-- Shuffle indices for random access
	for i = #shuffledIndices, 2, -1 do
		local j = math.random(i)
		shuffledIndices[i], shuffledIndices[j] = shuffledIndices[j], shuffledIndices[i]
	end
	
	for _, index in ipairs(shuffledIndices) do
		if treesPlaced >= treeCount then
			break
		end
		
		attempts = attempts + 1
		if attempts >= maxAttempts then
			break
		end
		
		local candidatePos = candidatePositions[index]
		if not candidatePos then
			-- Skip invalid index
		else
			-- Check if grid cell is already used
			if not isGridCellUsed(candidatePos) then
				-- Raycast to find terrain surface and check material
				local rayOrigin = candidatePos + Vector3.new(0, 100, 0)
				local rayDirection = Vector3.new(0, -200, 0)
				
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = {workspace.Terrain}
				raycastParams.IgnoreWater = false -- We want to detect water
				
				local ray = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
				if ray then
					-- Check if material is valid for trees (not water)
					local hitMaterial = ray.Material
					if hitMaterial ~= Enum.Material.Water then
						-- Check if material is valid (prioritize Grass)
						local materialWeight = validTreeMaterials[hitMaterial]
						if materialWeight then
							-- Prefer grass material (but allow others with lower probability)
							local shouldPlace = true
							if hitMaterial ~= Enum.Material.Grass and math.random() > 0.3 then
								-- 70% chance to skip non-grass materials (prioritize grass)
								shouldPlace = false
							end
							
							if shouldPlace then
								local pos = ray.Position
								
								-- Check spacing from already placed trees (INCREASED spacing)
								local tooClose = false
								for _, placedPos in ipairs(placedTreePositions) do
									local distance = (pos - placedPos).Magnitude
									if distance < MIN_TREE_SPACING then
										tooClose = true
										break
									end
								end
								
								-- Also check spacing from existing trees in workspace
								if not tooClose then
									local treeFolder = islandFolder:FindFirstChild("Trees")
									if treeFolder then
										for _, existingTree in ipairs(treeFolder:GetChildren()) do
											if existingTree:IsA("Model") and existingTree.PrimaryPart then
												local treePos = existingTree.PrimaryPart.Position
												local distance = (pos - treePos).Magnitude
												if distance < MIN_TREE_SPACING then
													tooClose = true
													break
												end
											end
										end
									end
								end
								
								if not tooClose then
									-- Place tree
									self:placeTree(islandFolder, pos, "Oak")
									
									-- Save to island data
									table.insert(islandData.trees, {
										X = pos.X,
										Y = pos.Y,
										Z = pos.Z,
										type = "Oak"
									})
									
									-- Track placed position
									table.insert(placedTreePositions, pos)
									markGridCellUsed(pos)
									treesPlaced = treesPlaced + 1
								end
							end
						end
					end
				end
			end
		end
	end
	
	print("[PlayerIslandService] ✅ Placed", treesPlaced, "trees across island with", MIN_TREE_SPACING, "stud spacing (attempts:", attempts, ")")
end

function PlayerIslandService:generateInitialRocks(userId, center, size)
	local islandData = self.playerIslands[userId]
	if not islandData then return end
	
	-- Generate 5-8 rocks (RockPatch should only spawn on Sand and Ground/dirt)
	local rockCount = math.random(5, 8)
	local islandFolder = self.islandFolders[userId]
	
	local rocksPlaced = 0
	local attempts = 0
	local maxAttempts = rockCount * 20 -- Prevent infinite loop
	
	-- Valid materials for rocks (only Sand and Ground/dirt, and Rock material)
	local validRockMaterials = {
		[Enum.Material.Sand] = true,
		[Enum.Material.Ground] = true,  -- Dirt
		[Enum.Material.Rock] = true,    -- Rock material
	}
	
	while rocksPlaced < rockCount and attempts < maxAttempts do
		attempts = attempts + 1
		
		local angle = math.random() * math.pi * 2
		local distance = math.random(25, size.X * 0.6)
		
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		local pos = center + Vector3.new(x, 20, z)
		
		-- Raycast to terrain and check material
		local rayOrigin = pos + Vector3.new(0, 100, 0)
		local rayDirection = Vector3.new(0, -200, 0)
		
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = {workspace.Terrain}
		raycastParams.IgnoreWater = false
		
		local ray = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		if ray then
			-- Check if material is valid for rocks (only Sand and Ground/dirt)
			local hitMaterial = ray.Material
			if not validRockMaterials[hitMaterial] then
				-- Skip invalid materials (like Grass, Water, etc.)
				continue
			end
			
			pos = ray.Position
		else
			-- No terrain found - skip
			continue
		end
		
		self:placeRock(islandFolder, pos)
		
		table.insert(islandData.rocks, {
			X = pos.X,
			Y = pos.Y,
			Z = pos.Z,
		})
		
		rocksPlaced = rocksPlaced + 1
	end
	
	print("[PlayerIslandService] ✅ Placed", rocksPlaced, "rocks on sand/dirt (attempts:", attempts, ")")
end

function PlayerIslandService:placeTree(folder, position, treeType)
	-- Try to get tree from ReplicatedStorage
	local treeTemplate = ReplicatedStorage:FindFirstChild("OakTree")
	local tree = nil
	
	if treeTemplate and treeTemplate:IsA("Model") then
		tree = treeTemplate:Clone()
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
		tree = Instance.new("Model")
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
	
	-- Add ProximityPrompt for tree shaking
	if tree then
		local rootPart = tree.PrimaryPart or tree:FindFirstChildOfClass("BasePart")
		if rootPart then
			-- Set attribute for tree identification
			tree:SetAttribute("HarvestType", "tree")
			tree:SetAttribute("ResourceType", "tree")
			
			-- Add ProximityPrompt
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "ShakeTree"
			prompt.ActionText = "Shake Tree"
			prompt.ObjectText = "Tree"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Parent = rootPart
			
			-- Connect to tree shaking system
			local TreeShakingSystem = require(script.Parent:WaitForChild("TreeShakingSystem"))
			prompt.Triggered:Connect(function(player)
				TreeShakingSystem.shakeTree(player, tree)
			end)
		end
	end
	
	return tree
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

