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
local TreeShakingSystem = require(script.Parent:WaitForChild("TreeShakingSystem"))

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
	RESOURCE_MAINTENANCE_INTERVAL = 120, -- Periodic check to repopulate resources
	TREE_CLEARANCE = 20,
}

local OAK_TREE_TEMPLATE_NAME = "OakTree"

local TREE_GROUND_OFFSET = -1.5
local TREE_TARGET_HEIGHT = 32 -- Target height (studs) for tree models

local function getModelScale(model)
	local ok, scale = pcall(function()
		return model:GetScale()
	end)
	if ok and type(scale) == "number" and scale > 0 then
		return scale
	end
	return 1
end

local function getGroundPosition(position)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { Workspace.Terrain }
	raycastParams.IgnoreWater = false

	local rayOrigin = Vector3.new(position.X, position.Y + 150, position.Z)
	local rayDirection = Vector3.new(0, -300, 0)
	local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if not result then
		return nil
	end

	if result.Material == Enum.Material.Water or result.Position.Y <= 5 then
		return nil
	end

	return result.Position
end

local function isSpawnAreaClear(position)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}
	params.RespectCanCollide = false

	local parts = Workspace:GetPartBoundsInRadius(position, CONFIG.TREE_CLEARANCE, params)
	return #parts == 0
end

local function ensureTreeShakePrompt(tree)
	local rootPart = tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart", true)
	if not rootPart then
		return
	end

	local existingPrompt = tree:FindFirstChild("ShakeTree", true)
	if existingPrompt then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShakeTree"
	prompt.ActionText = "Shake Tree"
	prompt.ObjectText = "Tree"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = rootPart

	prompt.Triggered:Connect(function(player)
		TreeShakingSystem.shakeTree(player, tree)
	end)
end

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

	-- Spawn trees once on init (no repeated maintenance)
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
	local islands = {
		Workspace:FindFirstChild("Islands"),
		Workspace:FindFirstChild("PlayerIslands"),
		Workspace:FindFirstChild("Resources"),
	}

	for _, islandsFolder in ipairs(islands) do
		if islandsFolder then
			if islandsFolder.Name == "Resources" then
				self:scanIsland(islandsFolder)
			else
				for _, islandFolder in ipairs(islandsFolder:GetChildren()) do
					if islandFolder:IsA("Folder") or islandFolder:IsA("Model") then
						self:scanIsland(islandFolder)
					end
				end
			end
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
	resources.trees = {}
	resources.rocks = {}

	-- Find trees
	for _, obj in ipairs(islandFolder:GetDescendants()) do
		if obj:IsA("Model") and (obj.Name:lower():find("tree") or obj:FindFirstChild("TreeTag")) then
			table.insert(resources.trees, obj)

			local originalLowest = getLowestTreePointY(obj)
			scaleTreeToTargetHeight(obj, TREE_TARGET_HEIGHT)
			local newLowest = getLowestTreePointY(obj)
			if originalLowest < math.huge and newLowest < math.huge then
				obj:PivotTo(obj:GetPivot() + Vector3.new(0, originalLowest - newLowest, 0))
			end

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
	if islandName == "Resources" then
		return
	end
	if islandFolder and islandFolder.Parent and islandFolder.Parent.Name == "PlayerIslands" then
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
	for _ = 1, 20 do
		local offsetX = math.random(-80, 80)
		local offsetZ = math.random(-80, 80)
		local testPosition = Vector3.new(basePosition.X + offsetX, basePosition.Y, basePosition.Z + offsetZ)

		local groundPosition = getGroundPosition(testPosition)
		if groundPosition and isSpawnAreaClear(groundPosition) then
			return groundPosition
		end
	end

	return nil
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
	local islandFolder = nil
	local islands = Workspace:FindFirstChild("Islands")
	if islands then
		islandFolder = islands:FindFirstChild(entry.islandName)
	end

	if not islandFolder then
		local playerIslands = Workspace:FindFirstChild("PlayerIslands")
		if playerIslands then
			islandFolder = playerIslands:FindFirstChild(entry.islandName)
		end
	end

	if not islandFolder and entry.islandName == "Resources" then
		islandFolder = Workspace:FindFirstChild("Resources")
	end

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
	local spawnPosition = position and getGroundPosition(position)
	if not spawnPosition or not isSpawnAreaClear(spawnPosition) then
		spawnPosition = self:findSpawnPosition(islandFolder)
	end
	if not spawnPosition then
		warn("[ResourceSpawner] ⚠️ No valid tree spawn position found")
		return
	end

	local tree = self:createOakTree(spawnPosition)
	if not tree then
		warn("[ResourceSpawner] ⚠️ Failed to create tree")
		return
	end

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

	local playerIslands = Workspace:FindFirstChild("PlayerIslands")
	if playerIslands then
		print("[ResourceSpawner] ✅ Player islands detected, skipping terrain resources")
		return
	end

	-- Create a resources folder
	local resourcesFolder = Workspace:FindFirstChild("Resources")
	if not resourcesFolder then
		resourcesFolder = Instance.new("Folder")
		resourcesFolder.Name = "Resources"
		resourcesFolder.Parent = Workspace
	elseif resourcesFolder:GetAttribute("Populated") then
		print("[ResourceSpawner] ✅ Resources already populated, skipping re-run")
		return
	end

	-- Spawn trees in a grid pattern
	local treeCount = 0
	local rockCount = 0
	local treePositions = {}
	local rockPositions = {}

	local function isFarEnough(candidate: Vector3, existing: { Vector3 }, minDistance: number)
		local minDistSq = minDistance * minDistance
		for _, pos in ipairs(existing) do
			if (candidate - pos).Magnitude ^ 2 < minDistSq then
				return false
			end
		end
		return true
	end

	for x = -200, 200, 24 do
		for z = -200, 200, 24 do
			-- Random chance to spawn tree or rock
			local rand = math.random()

			if rand < 0.18 then -- 18% chance for tree
				local position = Vector3.new(x, 100, z)

				-- Raycast down to find ground
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { terrain }

				local result = Workspace:Raycast(position, Vector3.new(0, -200, 0), raycastParams)

				if result and result.Position.Y > 0 and isFarEnough(result.Position, treePositions, 22) then
					-- Spawn tree here
					local tree = self:createOakTree(result.Position)
					tree.Parent = resourcesFolder
					treeCount = treeCount + 1
					table.insert(treePositions, result.Position)
				end
			elseif rand < 0.25 then -- ~7% chance for rock (after tree chance)
				local position = Vector3.new(x, 100, z)

				-- Raycast down to find ground
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { terrain }

				local result = Workspace:Raycast(position, Vector3.new(0, -200, 0), raycastParams)

				if result and result.Position.Y > 0 and isFarEnough(result.Position, rockPositions, 16) then
					-- Spawn rock here
					local rock = self:createSimpleRock(result.Position)
					rock.Parent = resourcesFolder
					rockCount = rockCount + 1
					table.insert(rockPositions, result.Position)
				end
			end
		end
	end

	print(string.format("[ResourceSpawner] ✅ Spawned %d trees and %d rocks on terrain", treeCount, rockCount))
	resourcesFolder:SetAttribute("Populated", true)
end

--[[
	Find template tree model in workspace
]]
function ResourceSpawner:findOakTreeTemplate()
	local candidates = {
		Workspace:FindFirstChild(OAK_TREE_TEMPLATE_NAME),
		Workspace:FindFirstChild("Trees") and Workspace.Trees:FindFirstChild(OAK_TREE_TEMPLATE_NAME),
		ReplicatedStorage:FindFirstChild(OAK_TREE_TEMPLATE_NAME),
		ReplicatedStorage:FindFirstChild("Templates") and ReplicatedStorage.Templates:FindFirstChild(OAK_TREE_TEMPLATE_NAME),
		ReplicatedStorage:FindFirstChild("Trees") and ReplicatedStorage.Trees:FindFirstChild(OAK_TREE_TEMPLATE_NAME),
		ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild(OAK_TREE_TEMPLATE_NAME),
	}

	for _, candidate in ipairs(candidates) do
		if candidate and candidate:IsA("Model") then
			print(string.format("[ResourceSpawner] ✅ Found OakTree template: %s", candidate:GetFullName()))
			return candidate
		end
	end

	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child.Name:lower():find("oak") then
			print(string.format("[ResourceSpawner] ✅ Using oak example: %s", child.Name))
			return child
		end
	end

	warn("[ResourceSpawner] ⚠️ No OakTree template found")
	return nil
end

--[[
	Create a tree model for terrain population
]]
local function anchorTreeParts(tree)
	for _, descendant in ipairs(tree:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
end

local function disableLeafCollisions(tree)
	local leavesContainer = tree:FindFirstChild("LeavesModel")
		or tree:FindFirstChild("Leaves model")
		or tree:FindFirstChild("Leaves")

	if not leavesContainer then
		for _, desc in ipairs(tree:GetDescendants()) do
			if (desc:IsA("Model") or desc:IsA("Folder")) and desc.Name:lower():find("leaves") then
				leavesContainer = desc
				break
			end
		end
	end

	if leavesContainer then
		for _, desc in ipairs(leavesContainer:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.CanCollide = false
			end
		end
		if leavesContainer:IsA("BasePart") then
			leavesContainer.CanCollide = false
		end
	else
		for _, desc in ipairs(tree:GetDescendants()) do
			if desc:IsA("BasePart") then
				local name = desc.Name:lower()
				if name:find("leaf") or name:find("foliage") then
					desc.CanCollide = false
				end
			end
		end
	end
end

local function getLowestTreePointY(tree)
	local lowestPoint = math.huge
	for _, descendant in ipairs(tree:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local partBottomY = (descendant.CFrame.Position - (descendant.CFrame.UpVector * (descendant.Size.Y * 0.5))).Y
			if partBottomY < lowestPoint then
				lowestPoint = partBottomY
			end
		end
	end
	return lowestPoint
end

local function scaleTreeToTargetHeight(tree, targetHeight)
	local ok, extents = pcall(function()
		return tree:GetExtentsSize()
	end)
	if not ok or not extents then
		return
	end

	local currentScale = getModelScale(tree)
	local baseHeight = extents.Y / currentScale
	if baseHeight <= 0 then
		return
	end

	local targetScale = targetHeight / baseHeight
	if math.abs(targetScale - currentScale) < 0.01 then
		tree:SetAttribute("TreeTargetHeight", targetHeight)
		return
	end

	local scaled = pcall(function()
		tree:ScaleTo(targetScale)
	end)

	if scaled then
		tree:SetAttribute("TreeTargetHeight", targetHeight)
		return
	end

	warn("[ResourceSpawner] 🌳 ScaleTo failed for tree:", tree.Name)
end

local function alignTreeToGround(tree, position)
	local lowestPoint = getLowestTreePointY(tree)
	if lowestPoint < math.huge then
		local deltaY = position.Y - lowestPoint + TREE_GROUND_OFFSET
		tree:PivotTo(tree:GetPivot() + Vector3.new(0, deltaY, 0))
	end
end

function ResourceSpawner:createFallbackTree(position)
	local tree = Instance.new("Model")
	tree.Name = "Tree"

	local groundedPosition = position + Vector3.new(0, TREE_GROUND_OFFSET, 0)

	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2, 8, 2)
	trunk.Position = groundedPosition + Vector3.new(0, 4, 0)
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.BrickColor = BrickColor.new("Brown")
	trunk.Parent = tree

	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Size = Vector3.new(6, 6, 6)
	leaves.Position = groundedPosition + Vector3.new(0, 10, 0)
	leaves.Anchored = true
	leaves.CanCollide = false
	leaves.Material = Enum.Material.Grass
	leaves.BrickColor = BrickColor.new("Dark green")
	leaves.Shape = Enum.PartType.Ball
	leaves.Parent = tree

	tree.PrimaryPart = trunk
	anchorTreeParts(tree)
	disableLeafCollisions(tree)

	local tag = Instance.new("StringValue")
	tag.Name = "ResourceTag"
	tag.Value = "tree"
	tag.Parent = tree

	local treeTag = Instance.new("BoolValue")
	treeTag.Name = "TreeTag"
	treeTag.Parent = tree

	tree:SetAttribute("HarvestType", "tree")
	tree:SetAttribute("ResourceType", "tree")

	return tree
end

function ResourceSpawner:createOakTree(position)
	local template = self:findOakTreeTemplate()
	if not template then
		return self:createFallbackTree(position)
	end

	local tree = template:Clone()
	tree.Name = OAK_TREE_TEMPLATE_NAME

	local primaryPart = tree.PrimaryPart
	if primaryPart and not primaryPart:IsA("BasePart") then
		tree.PrimaryPart = nil
		primaryPart = nil
	end

	if not primaryPart then
		local preferredRoot = tree:FindFirstChild("TreeRoot t", true)
			or tree:FindFirstChild("Root", true)
			or tree:FindFirstChildWhichIsA("BasePart", true)
		if preferredRoot and preferredRoot:IsA("BasePart") then
			tree.PrimaryPart = preferredRoot
		end
	end

	scaleTreeToTargetHeight(tree, TREE_TARGET_HEIGHT)

	tree:PivotTo(CFrame.new(position))
	alignTreeToGround(tree, position)
	anchorTreeParts(tree)
	disableLeafCollisions(tree)

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

	tree:SetAttribute("HarvestType", "tree")
	tree:SetAttribute("ResourceType", "tree")
	ensureTreeShakePrompt(tree)

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
