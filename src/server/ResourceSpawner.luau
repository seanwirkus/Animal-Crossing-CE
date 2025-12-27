--[[
	ResourceSpawner.luau

	Manages spawning and respawning of natural resources:
	- Trees (for wood and fruit)
	- Rocks (for stone, iron, clay)
	- Maintains resource count on islands
	- Handles respawn timers
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ResourceSpawner = {}
ResourceSpawner.__index = ResourceSpawner

-- Configuration
local CONFIG = {
	TREE_RESPAWN_TIME = 300, -- 5 minutes
	ROCK_RESPAWN_TIME = 300, -- 5 minutes
	MIN_TREES_PER_ISLAND = 15,
	MAX_TREES_PER_ISLAND = 25,
	MIN_ROCKS_PER_ISLAND = 6,
	MAX_ROCKS_PER_ISLAND = 12,
}

function ResourceSpawner.new()
	local self = setmetatable({}, ResourceSpawner)

	-- Track resources per island
	self.islandResources = {} -- [islandName] = {trees = {}, rocks = {}}
	self.respawnQueue = {} -- Resources waiting to respawn

	print("[ResourceSpawner] ✅ Initialized")

	return self
end

function ResourceSpawner:initialize()
	print("[ResourceSpawner] 🌳 Starting resource management...")

	-- Start respawn loop
	task.spawn(function()
		self:respawnLoop()
	end)

	-- Scan existing islands
	self:scanExistingIslands()

	-- Auto-populate terrain with initial resources
	task.spawn(function()
		task.wait(3) -- Wait for terrain to load
		self:populateTerrainResources()
	end)

	print("[ResourceSpawner] ✅ Resource spawner ready")
end

--[[
	Scan workspace for existing islands and catalog their resources
]]
function ResourceSpawner:scanExistingIslands()
	local islands = Workspace:FindFirstChild("Islands")
	if not islands then
		return
	end

	for _, islandFolder in ipairs(islands:GetChildren()) do
		if islandFolder:IsA("Folder") or islandFolder:IsA("Model") then
			self:scanIsland(islandFolder)
		end
	end
end

--[[
	Scan a single island for resources
]]
function ResourceSpawner:scanIsland(islandFolder)
	local islandName = islandFolder.Name

	if not self.islandResources[islandName] then
		self.islandResources[islandName] = {
			trees = {},
			rocks = {},
		}
	end

	local resources = self.islandResources[islandName]

	-- Find trees
	for _, obj in ipairs(islandFolder:GetDescendants()) do
		if obj:IsA("Model") and (obj.Name:lower():find("tree") or obj:FindFirstChild("TreeTag")) then
			table.insert(resources.trees, obj)

			-- Tag for easy identification
			if not obj:FindFirstChild("ResourceTag") then
				local tag = Instance.new("StringValue")
				tag.Name = "ResourceTag"
				tag.Value = "tree"
				tag.Parent = obj
			end
		elseif obj:IsA("Model") and (obj.Name:lower():find("rock") or obj:FindFirstChild("RockTag")) then
			table.insert(resources.rocks, obj)

			-- Tag for easy identification
			if not obj:FindFirstChild("ResourceTag") then
				local tag = Instance.new("StringValue")
				tag.Name = "ResourceTag"
				tag.Value = "rock"
				tag.Parent = obj
			end
		end
	end

	print(string.format(
		"[ResourceSpawner] 📊 Island '%s': %d trees, %d rocks",
		islandName,
		#resources.trees,
		#resources.rocks
	))

	-- Spawn more if needed
	self:ensureMinimumResources(islandName, islandFolder)
end

--[[
	Ensure island has minimum resources
]]
function ResourceSpawner:ensureMinimumResources(islandName, islandFolder)
	local resources = self.islandResources[islandName]
	if not resources then
		return
	end

	-- Count active trees and rocks
	local activeTrees = 0
	local activeRocks = 0

	for _, tree in ipairs(resources.trees) do
		if tree and tree.Parent then
			activeTrees = activeTrees + 1
		end
	end

	for _, rock in ipairs(resources.rocks) do
		if rock and rock.Parent then
			activeRocks = activeRocks + 1
		end
	end

	-- Spawn more if below minimum
	local treesToSpawn = math.max(0, CONFIG.MIN_TREES_PER_ISLAND - activeTrees)
	local rocksToSpawn = math.max(0, CONFIG.MIN_ROCKS_PER_ISLAND - activeRocks)

	if treesToSpawn > 0 then
		print(string.format("[ResourceSpawner] 🌳 Spawning %d trees on island '%s'", treesToSpawn, islandName))
		for i = 1, treesToSpawn do
			local position = self:findSpawnPosition(islandFolder)
			if position then
				self:spawnTree(islandFolder, position)
			end
		end
	end

	if rocksToSpawn > 0 then
		print(string.format("[ResourceSpawner] 🪨 Spawning %d rocks on island '%s'", rocksToSpawn, islandName))
		for i = 1, rocksToSpawn do
			local position = self:findSpawnPosition(islandFolder)
			if position then
				self:spawnRock(islandFolder, position)
			end
		end
	end
end

--[[
	Find a valid spawn position on an island
]]
function ResourceSpawner:findSpawnPosition(islandFolder)
	-- Try to find a ground position within the island
	local origin = islandFolder:FindFirstChild("SpawnLocation")
	local basePosition = if origin then origin.Position else Vector3.new(0, 50, 0)

	-- Try random positions around the island center
	for _ = 1, 10 do
		local offsetX = math.random(-80, 80)
		local offsetZ = math.random(-80, 80)
		local testPosition = Vector3.new(basePosition.X + offsetX, 100, basePosition.Z + offsetZ)

		-- Raycast down to find ground
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

		local result = Workspace:Raycast(testPosition, Vector3.new(0, -200, 0), raycastParams)

		if result and result.Position.Y > 5 then
			return result.Position
		end
	end

	-- Fallback: return a position near base
	return basePosition + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
end

--[[
	Mark a tree as chopped (removed)
]]
function ResourceSpawner:markTreeChopped(tree, islandName)
	if not tree or not islandName then
		return
	end

	-- Queue for respawn
	table.insert(self.respawnQueue, {
		resourceType = "tree",
		islandName = islandName,
		originalPosition = tree.PrimaryPart and tree.PrimaryPart.Position or tree:GetPivot().Position,
		respawnTime = tick() + CONFIG.TREE_RESPAWN_TIME,
	})

	-- Remove tree
	tree:Destroy()

	print(string.format(
		"[ResourceSpawner] 🪓 Tree chopped on '%s', will respawn in %d seconds",
		islandName,
		CONFIG.TREE_RESPAWN_TIME
	))
end

--[[
	Mark a rock as broken
]]
function ResourceSpawner:markRockBroken(rock, islandName)
	if not rock or not islandName then
		return
	end

	-- Queue for respawn
	table.insert(self.respawnQueue, {
		resourceType = "rock",
		islandName = islandName,
		originalPosition = rock.PrimaryPart and rock.PrimaryPart.Position or rock:GetPivot().Position,
		respawnTime = tick() + CONFIG.ROCK_RESPAWN_TIME,
	})

	-- Don't destroy rock, just mark as depleted
	-- Add a visual indicator
	local depleted = Instance.new("BoolValue")
	depleted.Name = "Depleted"
	depleted.Parent = rock

	-- Make rock semi-transparent
	for _, part in ipairs(rock:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0.5
		end
	end

	print(string.format(
		"[ResourceSpawner] ⛏️ Rock depleted on '%s', will respawn in %d seconds",
		islandName,
		CONFIG.ROCK_RESPAWN_TIME
	))
end

--[[
	Respawn loop - checks queue and respawns resources
]]
function ResourceSpawner:respawnLoop()
	while true do
		task.wait(10) -- Check every 10 seconds

		local now = tick()
		local newQueue = {}

		for _, entry in ipairs(self.respawnQueue) do
			if now >= entry.respawnTime then
				-- Time to respawn!
				self:respawnResource(entry)
			else
				-- Not ready yet, keep in queue
				table.insert(newQueue, entry)
			end
		end

		self.respawnQueue = newQueue
	end
end

--[[
	Respawn a resource
]]
function ResourceSpawner:respawnResource(entry)
	local islands = Workspace:FindFirstChild("Islands")
	if not islands then
		return
	end

	local islandFolder = islands:FindFirstChild(entry.islandName)
	if not islandFolder then
		return
	end

	if entry.resourceType == "tree" then
		self:spawnTree(islandFolder, entry.originalPosition)
	elseif entry.resourceType == "rock" then
		self:respawnRock(islandFolder, entry.originalPosition)
	end
end

--[[
	Spawn a new tree at position
]]
function ResourceSpawner:spawnTree(islandFolder, position)
	-- Create simple tree model
	local tree = Instance.new("Model")
	tree.Name = "Tree"

	-- Tree trunk
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2, 8, 2)
	trunk.Position = position + Vector3.new(0, 4, 0)
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.BrickColor = BrickColor.new("Brown")
	trunk.Parent = tree

	-- Tree foliage
	local foliage = Instance.new("Part")
	foliage.Name = "Foliage"
	foliage.Size = Vector3.new(6, 6, 6)
	foliage.Position = position + Vector3.new(0, 10, 0)
	foliage.Anchored = true
	foliage.Material = Enum.Material.Grass
	foliage.BrickColor = BrickColor.new("Dark green")
	foliage.Shape = Enum.PartType.Ball
	foliage.Parent = tree

	tree.PrimaryPart = trunk

	-- Add resource tag
	local tag = Instance.new("StringValue")
	tag.Name = "ResourceTag"
	tag.Value = "tree"
	tag.Parent = tree

	-- Add tree tag for identification
	local treeTag = Instance.new("BoolValue")
	treeTag.Name = "TreeTag"
	treeTag.Parent = tree

	tree.Parent = islandFolder

	-- Add to resources list
	local islandName = islandFolder.Name
	if self.islandResources[islandName] then
		table.insert(self.islandResources[islandName].trees, tree)
	end

	print(string.format("[ResourceSpawner] 🌳 Tree spawned on '%s'", islandName))
end

--[[
	Respawn a rock (restore depleted one)
]]
function ResourceSpawner:respawnRock(islandFolder, position)
	-- Find depleted rock at this position
	for _, obj in ipairs(islandFolder:GetDescendants()) do
		if obj:IsA("Model") and obj:FindFirstChild("Depleted") then
			local rockPos = obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetPivot().Position
			if (rockPos - position).Magnitude < 5 then
				-- This is our rock, restore it
				obj.Depleted:Destroy()

				-- Restore transparency
				for _, part in ipairs(obj:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 0
					end
				end

				print(string.format("[ResourceSpawner] 🪨 Rock respawned on '%s'", islandFolder.Name))
				return
			end
		end
	end

	-- If no depleted rock found, spawn a new one
	self:spawnRock(islandFolder, position)
end

--[[
	Spawn a new rock at position
]]
function ResourceSpawner:spawnRock(islandFolder, position)
	local rock = Instance.new("Model")
	rock.Name = "Rock"

	-- Main rock part
	local rockPart = Instance.new("Part")
	rockPart.Name = "RockPart"
	rockPart.Size = Vector3.new(3, 2, 3)
	rockPart.Position = position + Vector3.new(0, 1, 0)
	rockPart.Anchored = true
	rockPart.Material = Enum.Material.Rock
	rockPart.BrickColor = BrickColor.new("Medium stone grey")
	rockPart.Parent = rock

	rock.PrimaryPart = rockPart

	-- Add resource tag
	local tag = Instance.new("StringValue")
	tag.Name = "ResourceTag"
	tag.Value = "rock"
	tag.Parent = rock

	-- Add rock tag
	local rockTag = Instance.new("BoolValue")
	rockTag.Name = "RockTag"
	rockTag.Parent = rock

	rock.Parent = islandFolder

	-- Add to resources list
	local islandName = islandFolder.Name
	if self.islandResources[islandName] then
		table.insert(self.islandResources[islandName].rocks, rock)
	end

	print(string.format("[ResourceSpawner] 🪨 Rock spawned on '%s'", islandName))
end

--[[
	Populate terrain with initial trees and rocks
]]
function ResourceSpawner:populateTerrainResources()
	print("[ResourceSpawner] 🌍 Populating terrain with resources...")

	local terrain = Workspace.Terrain
	if not terrain then
		warn("[ResourceSpawner] No terrain found!")
		return
	end

	-- Create a resources folder
	local resourcesFolder = Workspace:FindFirstChild("Resources")
	if not resourcesFolder then
		resourcesFolder = Instance.new("Folder")
		resourcesFolder.Name = "Resources"
		resourcesFolder.Parent = Workspace
	end

	-- Spawn trees in a grid pattern
	local treeCount = 0
	local rockCount = 0

	for x = -200, 200, 20 do
		for z = -200, 200, 20 do
			-- Random chance to spawn tree or rock
			local rand = math.random()

			if rand < 0.15 then -- 15% chance for tree
				local position = Vector3.new(x, 100, z)

				-- Raycast down to find ground
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { terrain }

				local result = Workspace:Raycast(position, Vector3.new(0, -200, 0), raycastParams)

				if result and result.Position.Y > 0 then
					-- Spawn tree here
					local tree = self:createSimpleTree(result.Position)
					tree.Parent = resourcesFolder
					treeCount = treeCount + 1
				end
			elseif rand < 0.22 then -- 7% chance for rock
				local position = Vector3.new(x, 100, z)

				-- Raycast down to find ground
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { terrain }

				local result = Workspace:Raycast(position, Vector3.new(0, -200, 0), raycastParams)

				if result and result.Position.Y > 0 then
					-- Spawn rock here
					local rock = self:createSimpleRock(result.Position)
					rock.Parent = resourcesFolder
					rockCount = rockCount + 1
				end
			end
		end
	end

	print(string.format("[ResourceSpawner] ✅ Spawned %d trees and %d rocks on terrain", treeCount, rockCount))
end

--[[
	Find template tree model in workspace
]]
function ResourceSpawner:findTreeTemplate()
	-- Look for tree template in workspace
	local locations = {
		Workspace:FindFirstChild("TreeTemplate"),
		Workspace:FindFirstChild("Templates") and Workspace.Templates:FindFirstChild("Tree"),
		ReplicatedStorage:FindFirstChild("TreeTemplate"),
		ReplicatedStorage:FindFirstChild("Trees") and ReplicatedStorage.Trees:FindFirstChild("Tree"),
		ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("Tree"),
	}

	for _, location in ipairs(locations) do
		if location and location:IsA("Model") then
			print(string.format("[ResourceSpawner] ✅ Found tree template: %s", location:GetFullName()))
			return location
		end
	end

	-- If no template found, look for any tree in workspace (not under Resources folder)
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:lower():find("tree") and obj.Name ~= "Resources" then
			-- Make sure it's not a spawned resource
			if not obj.Parent or obj.Parent.Name ~= "Resources" then
				print(string.format("[ResourceSpawner] ✅ Found tree example: %s", obj.Name))
				return obj
			end
		end
	end

	warn("[ResourceSpawner] ⚠️ No tree template found, will use simple placeholder trees")
	return nil
end

--[[
	Create a tree model for terrain population
]]
function ResourceSpawner:createSimpleTree(position)
	-- Try to use existing tree template if available
	local template = self:findTreeTemplate()

	if template then
		local tree = template:Clone()

		-- Offset the tree down by 0.5 studs so it sits into the ground
		local offsetPosition = position + Vector3.new(0, -0.5, 0)

		-- Position the tree at the spawn location
		if tree.PrimaryPart then
			tree:SetPrimaryPartCFrame(CFrame.new(offsetPosition))
		else
			tree:MoveTo(offsetPosition)
		end

		-- Ensure all parts are anchored
		for _, part in ipairs(tree:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end

		-- Add resource tags if not already present
		if not tree:FindFirstChild("ResourceTag") then
			local tag = Instance.new("StringValue")
			tag.Name = "ResourceTag"
			tag.Value = "tree"
			tag.Parent = tree
		end

		if not tree:FindFirstChild("TreeTag") then
			local treeTag = Instance.new("BoolValue")
			treeTag.Name = "TreeTag"
			treeTag.Parent = tree
		end

		return tree
	end

	-- Fallback: Create simple tree model
	local tree = Instance.new("Model")
	tree.Name = "Tree"

	-- Tree trunk
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2, 8, 2)
	trunk.Position = position + Vector3.new(0, 4, 0)
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.BrickColor = BrickColor.new("Brown")
	trunk.Parent = tree

	-- Tree foliage
	local foliage = Instance.new("Part")
	foliage.Name = "Foliage"
	foliage.Size = Vector3.new(6, 6, 6)
	foliage.Position = position + Vector3.new(0, 10, 0)
	foliage.Anchored = true
	foliage.Material = Enum.Material.Grass
	foliage.BrickColor = BrickColor.new("Dark green")
	foliage.Shape = Enum.PartType.Ball
	foliage.Parent = tree

	tree.PrimaryPart = trunk

	-- Add resource tag
	local tag = Instance.new("StringValue")
	tag.Name = "ResourceTag"
	tag.Value = "tree"
	tag.Parent = tree

	-- Add tree tag for identification
	local treeTag = Instance.new("BoolValue")
	treeTag.Name = "TreeTag"
	treeTag.Parent = tree

	return tree
end

--[[
	Create a simple rock model for terrain population
]]
function ResourceSpawner:createSimpleRock(position)
	local rock = Instance.new("Model")
	rock.Name = "Rock"

	-- Main rock part
	local rockPart = Instance.new("Part")
	rockPart.Name = "RockPart"
	rockPart.Size = Vector3.new(3, 2, 3)
	rockPart.Position = position + Vector3.new(0, 1, 0)
	rockPart.Anchored = true
	rockPart.Material = Enum.Material.Rock
	rockPart.BrickColor = BrickColor.new("Medium stone grey")
	rockPart.Parent = rock

	rock.PrimaryPart = rockPart

	-- Add resource tag
	local tag = Instance.new("StringValue")
	tag.Name = "ResourceTag"
	tag.Value = "rock"
	tag.Parent = rock

	-- Add rock tag
	local rockTag = Instance.new("BoolValue")
	rockTag.Name = "RockTag"
	rockTag.Parent = rock

	return rock
end

return ResourceSpawner
