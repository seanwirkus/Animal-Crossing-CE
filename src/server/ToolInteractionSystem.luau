--[[
	ToolInteractionSystem.luau

	Handles tool interactions with resources:
	- Axe chopping trees
	- Pickaxe/shovel hitting rocks
	- Rewards resources to inventory
	- Integrates with ResourceSpawner for respawn
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ToolInteractionSystem = {}
ToolInteractionSystem.__index = ToolInteractionSystem

-- Configuration
local CONFIG = {
	AXE_RANGE = 10,
	PICKAXE_RANGE = 10,
	CHOPS_TO_FELL_TREE = 3, -- Number of hits to chop down a tree
	HITS_TO_BREAK_ROCK = 8, -- Number of hits to deplete a rock
}

-- Resources gained from interactions
local RESOURCE_DROPS = {
	tree = {
		{ itemId = "wood", minAmount = 3, maxAmount = 5 },
		{ itemId = "softwood", minAmount = 2, maxAmount = 4 },
	},
	rock = {
		{ itemId = "stone", minAmount = 2, maxAmount = 4 },
		{ itemId = "iron_nugget", minAmount = 1, maxAmount = 3 },
		{ itemId = "clay", minAmount = 1, maxAmount = 2 },
	},
}

function ToolInteractionSystem.new(resourceSpawner)
	local self = setmetatable({}, ToolInteractionSystem)

	self.resourceSpawner = resourceSpawner
	self.addItemToInventory = nil -- Will be set by server init

	-- Track hit counts for resources
	self.resourceHits = {} -- [resource] = hitCount

	print("[ToolInteractionSystem] ✅ Initialized")

	return self
end

function ToolInteractionSystem:setAddItemFunction(addItemFunc)
	self.addItemToInventory = addItemFunc
end

function ToolInteractionSystem:initialize()
	print("[ToolInteractionSystem] 🔨 Setting up tool interactions...")

	-- Setup remote events
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = ReplicatedStorage
	end

	local toolEvents = remoteEvents:FindFirstChild("ToolEvents")
	if not toolEvents then
		toolEvents = Instance.new("Folder")
		toolEvents.Name = "ToolEvents"
		toolEvents.Parent = remoteEvents
	end

	-- Tool use remote
	local toolUseRemote = toolEvents:FindFirstChild("ToolUse")
	if not toolUseRemote then
		toolUseRemote = Instance.new("RemoteEvent")
		toolUseRemote.Name = "ToolUse"
		toolUseRemote.Parent = toolEvents
	end

	-- Handle tool use
	toolUseRemote.OnServerEvent:Connect(function(player, data)
		self:handleToolUse(player, data)
	end)

	print("[ToolInteractionSystem] ✅ Tool interaction system ready")
end

--[[
	Handle tool use from client
]]
function ToolInteractionSystem:handleToolUse(player, data)
	if not player or not data then
		return
	end

	local toolType = data.toolType
	local action = data.action
	local position = data.position

	if not toolType or not action or not position then
		return
	end

	if toolType == "axe" and action == "chop" then
		self:handleAxeChop(player, position)
	elseif toolType == "pickaxe" and action == "hit" then
		self:handleRockHit(player, position)
	elseif toolType == "shovel" and action == "hit" then
		-- Shovel hits rocks only (no digging holes for now)
		self:handleRockHit(player, position)
	end
end

--[[
	Handle axe chopping trees
]]
function ToolInteractionSystem:handleAxeChop(player, position)
	-- Find nearest tree
	local tree = self:findNearestResource(position, "tree", CONFIG.AXE_RANGE)

	if not tree then
		print(string.format("[ToolInteractionSystem] 🪓 No tree in range for %s", player.Name))
		return
	end

	-- Increment hit count
	if not self.resourceHits[tree] then
		self.resourceHits[tree] = 0
	end

	self.resourceHits[tree] = self.resourceHits[tree] + 1

	-- Shake tree animation
	self:shakeResource(tree)

	-- Check if tree should be chopped down
	if self.resourceHits[tree] >= CONFIG.CHOPS_TO_FELL_TREE then
		-- Tree is chopped!
		self:chopDownTree(player, tree)
		self.resourceHits[tree] = nil
	else
		-- Just damaged, drop some resources
		local remainingHits = CONFIG.CHOPS_TO_FELL_TREE - self.resourceHits[tree]
		print(string.format(
			"[ToolInteractionSystem] 🪓 %s hit tree (%d more hits needed)",
			player.Name,
			remainingHits
		))

		-- Drop 1 wood piece
		self:giveResource(player, "wood", 1)
	end
end

--[[
	Handle shovel digging on ground (not rocks)
]]
function ToolInteractionSystem:handleShovelDig(player, position)
	print(string.format("[ToolInteractionSystem] 🪨 %s dug a hole!", player.Name))

	-- Create dig hole visual
	local hole = self:createDigHole(position)

	-- Hole disappears after 30 seconds
	task.delay(30, function()
		if hole and hole.Parent then
			hole:Destroy()
		end
	end)

	-- Small chance to find buried item (bells, fossils, etc.)
	if math.random() < 0.1 then -- 10% chance
		local bellAmount = math.random(100, 1000)
		self:spawnItemDrop(position, "bells", bellAmount)

		task.delay(1, function()
			-- Give bells through currency system
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			if remotes then
				local currencyRemote = remotes:FindFirstChild("CurrencyUpdate")
				if currencyRemote then
					currencyRemote:FireClient(player, "Grant", { bells = bellAmount })
					print(string.format("[ToolInteractionSystem] 💰 %s found %d bells!", player.Name, bellAmount))
				end
			end
		end)
	end
end

--[[
	Handle rock hitting
]]
function ToolInteractionSystem:handleRockHit(player, position)
	-- Find nearest rock
	local rock = self:findNearestResource(position, "rock", CONFIG.PICKAXE_RANGE)

	if not rock then
		print(string.format("[ToolInteractionSystem] ⛏️ No rock in range for %s", player.Name))
		return
	end

	-- Check if rock is depleted
	if rock:FindFirstChild("Depleted") then
		print(string.format("[ToolInteractionSystem] 🪨 Rock already depleted for %s", player.Name))
		return
	end

	-- Get rock position for item drops
	local rockPosition = rock.PrimaryPart and rock.PrimaryPart.Position or rock:GetPivot().Position

	-- Increment hit count
	if not self.resourceHits[rock] then
		self.resourceHits[rock] = 0
	end

	self.resourceHits[rock] = self.resourceHits[rock] + 1

	-- Shake rock animation
	self:shakeResource(rock)

	-- Drop resources with visual feedback
	local drops = self:selectRandomDrop(RESOURCE_DROPS.rock)
	for _, drop in ipairs(drops) do
		-- Spawn visual item drop (like trees)
		self:spawnItemDrop(rockPosition, drop.itemId, drop.amount)

		-- Give to inventory after delay (so player sees animation)
		task.delay(1, function()
			self:giveResource(player, drop.itemId, drop.amount)
		end)
	end

	-- Check if rock is depleted
	if self.resourceHits[rock] >= CONFIG.HITS_TO_BREAK_ROCK then
		-- Rock is depleted!
		self:depleteRock(rock)
		self.resourceHits[rock] = nil
	else
		local remainingHits = CONFIG.HITS_TO_BREAK_ROCK - self.resourceHits[rock]
		print(string.format(
			"[ToolInteractionSystem] ⛏️ %s hit rock (%d more hits possible)",
			player.Name,
			remainingHits
		))
	end
end

--[[
	Find nearest resource of type
]]
function ToolInteractionSystem:findNearestResource(position, resourceType, maxDistance)
	local nearest = nil
	local nearestDist = maxDistance

	-- Search in workspace
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local tag = obj:FindFirstChild("ResourceTag")
			if tag and tag.Value == resourceType then
				local resourcePos = obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetPivot().Position
				local dist = (resourcePos - position).Magnitude

				if dist < nearestDist then
					nearest = obj
					nearestDist = dist
				end
			end
		end
	end

	return nearest
end

--[[
	Chop down a tree
]]
function ToolInteractionSystem:chopDownTree(player, tree)
	print(string.format("[ToolInteractionSystem] 🌳 %s chopped down a tree!", player.Name))

	-- Get tree position before destroying
	local treePosition = tree.PrimaryPart and tree.PrimaryPart.Position or tree:GetPivot().Position

	-- Drop resources
	local drops = self:selectRandomDrop(RESOURCE_DROPS.tree)
	for _, drop in ipairs(drops) do
		-- Spawn visual item drop
		self:spawnItemDrop(treePosition, drop.itemId, drop.amount)

		-- Give to inventory after a delay (so player sees the drop animation)
		task.delay(1, function()
			self:giveResource(player, drop.itemId, drop.amount)
		end)
	end

	-- Make tree fall over with animation and glitchy separation
	self:animateTreeFall(tree)

	-- Find island name
	local islandName = self:findIslandName(tree)

	-- Actually destroy the tree after animation
	task.delay(2, function()
		-- Mark for respawn
		if self.resourceSpawner and islandName then
			self.resourceSpawner:markTreeChopped(tree, islandName)
		else
			-- Just destroy if no spawner
			tree:Destroy()
		end
	end)

	-- Fire quest event for tree chopping
	self:fireQuestEvent(player, "chop_tree", 1)
end

--[[
	Deplete a rock
]]
function ToolInteractionSystem:depleteRock(rock, player)
	print(string.format("[ToolInteractionSystem] 🪨 Rock depleted!"))

	-- Get rock position before making transparent
	local rockPosition = rock.PrimaryPart and rock.PrimaryPart.Position or rock:GetPivot().Position

	-- Fade out rock with animation
	self:animateRockBreak(rock)

	-- Find island name
	local islandName = self:findIslandName(rock)

	-- Mark for respawn (but don't destroy - just make transparent)
	if self.resourceSpawner and islandName then
		self.resourceSpawner:markRockBroken(rock, islandName)
	end
end

--[[
	Shake animation for resource
]]
function ToolInteractionSystem:shakeResource(resource)
	local primary = resource.PrimaryPart or resource:FindFirstChildWhichIsA("BasePart")
	if not primary then
		return
	end

	local originalCFrame = primary.CFrame

	-- Shake animation
	task.spawn(function()
		for i = 1, 4 do
			local offset = Vector3.new((math.random() - 0.5) * 1, 0, (math.random() - 0.5) * 1)
			primary.CFrame = originalCFrame * CFrame.new(offset)
			task.wait(0.05)
		end
		primary.CFrame = originalCFrame
	end)
end

--[[
	Select random drops from drop table
]]
function ToolInteractionSystem:selectRandomDrop(dropTable)
	local drops = {}

	for _, dropEntry in ipairs(dropTable) do
		-- Random chance for each drop
		if math.random() < 0.7 then -- 70% chance
			local amount = math.random(dropEntry.minAmount, dropEntry.maxAmount)
			table.insert(drops, {
				itemId = dropEntry.itemId,
				amount = amount,
			})
		end
	end

	return drops
end

--[[
	Give resource to player inventory
]]
function ToolInteractionSystem:giveResource(player, itemId, amount)
	if self.addItemToInventory then
		self.addItemToInventory(player, { itemId = itemId, count = amount })
		print(string.format("[ToolInteractionSystem] ✅ Gave %s x%d to %s", itemId, amount, player.Name))
	else
		warn("[ToolInteractionSystem] ⚠️ addItemToInventory function not set - cannot give resources")
	end
end

--[[
	Fire quest event for player actions
]]
function ToolInteractionSystem:fireQuestEvent(player, eventType, amount)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		return
	end

	local questEvent = remoteEvents:FindFirstChild("QuestEvent")
	if questEvent then
		questEvent:FireClient(player, "ProgressQuest", {
			eventType = eventType,
			amount = amount,
		})
	end
end

--[[
	Spawn visual item drop that floats up
]]
function ToolInteractionSystem:spawnItemDrop(position, itemId, amount)
	-- Create a visual representation of the dropped item
	local drop = Instance.new("Part")
	drop.Name = "ItemDrop"
	drop.Size = Vector3.new(1, 1, 1)
	drop.Position = position + Vector3.new(math.random(-2, 2), 2, math.random(-2, 2))
	drop.Anchored = true
	drop.CanCollide = false
	drop.Material = Enum.Material.Neon
	drop.BrickColor = BrickColor.new("Bright yellow")
	drop.Shape = Enum.PartType.Ball
	drop.Parent = Workspace

	-- Add label showing what it is
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = drop

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("%s x%d", itemId, amount)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	-- Float up animation
	task.spawn(function()
		local startPos = drop.Position
		for i = 1, 20 do
			drop.Position = startPos + Vector3.new(0, i * 0.1, 0)
			drop.Transparency = i / 20
			task.wait(0.05)
		end
		drop:Destroy()
	end)
end

--[[
	Animate tree falling over with glitchy separation effect
]]
function ToolInteractionSystem:animateTreeFall(tree)
	local primary = tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
	if not primary then
		return
	end

	-- Separate leaf parts and spheres for glitchy effect
	local leafParts = {}
	local sphereParts = {}
	local otherParts = {}

	for _, part in ipairs(tree:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Check if part name contains "Leaf" or "Sphere"
			local partName = part.Name:lower()
			if partName:find("leaf") then
				table.insert(leafParts, part)
			elseif partName:find("sphere") then
				table.insert(sphereParts, part)
			else
				table.insert(otherParts, part)
			end
		end
	end

	-- Unanchor all parts for falling animation
	for _, part in ipairs(tree:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end

	-- Apply glitchy separation to leaf parts
	for _, leafPart in ipairs(leafParts) do
		-- Apply random forces to make leaves fly off in different directions
		local randomDirection = Vector3.new(
			(math.random() - 0.5) * 2,
			math.random() * 2,
			(math.random() - 0.5) * 2
		).Unit
		leafPart:ApplyImpulse(randomDirection * leafPart.AssemblyMass * 30)
		leafPart:ApplyAngularImpulse(Vector3.new(
			math.random(-200, 200),
			math.random(-200, 200),
			math.random(-200, 200)
		))
	end

	-- Apply glitchy separation to sphere parts
	for _, spherePart in ipairs(sphereParts) do
		-- Apply random forces to make spheres fly off
		local randomDirection = Vector3.new(
			(math.random() - 0.5) * 2,
			math.random() * 1.5,
			(math.random() - 0.5) * 2
		).Unit
		spherePart:ApplyImpulse(randomDirection * spherePart.AssemblyMass * 25)
		spherePart:ApplyAngularImpulse(Vector3.new(
			math.random(-150, 150),
			math.random(-150, 150),
			math.random(-150, 150)
		))
	end

	-- Apply a random falling direction to the main tree trunk
	local direction = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
	primary:ApplyImpulse(direction * primary.AssemblyMass * 50 + Vector3.new(0, 20, 0))
	primary:ApplyAngularImpulse(Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))

	-- Add visual glitch effects
	for _, part in ipairs(leafParts) do
		-- Make leaves flicker and change transparency
		task.spawn(function()
			for i = 1, 10 do
				part.Transparency = math.random()
				task.wait(0.1)
			end
			part.Transparency = 0.5
		end)
	end

	for _, part in ipairs(sphereParts) do
		-- Make spheres flicker
		task.spawn(function()
			for i = 1, 8 do
				part.Transparency = math.random() * 0.7
				task.wait(0.15)
			end
			part.Transparency = 0.3
		end)
	end
end

--[[
	Animate rock breaking/fading out
]]
function ToolInteractionSystem:animateRockBreak(rock)
	-- Fade out animation
	task.spawn(function()
		for i = 1, 10 do
			for _, part in ipairs(rock:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = part.Transparency + 0.1
				end
			end
			task.wait(0.1)
		end

		-- Make completely invisible but don't destroy (for respawn)
		for _, part in ipairs(rock:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
				part.CanCollide = false
			end
		end
	end)
end

--[[
	Create dig hole visual
]]
function ToolInteractionSystem:createDigHole(position)
	local hole = Instance.new("Part")
	hole.Name = "DigHole"
	hole.Size = Vector3.new(2, 0.1, 2)
	hole.Position = position
	hole.Anchored = true
	hole.CanCollide = false
	hole.Material = Enum.Material.Ground
	hole.BrickColor = BrickColor.new("Dark orange")
	hole.Shape = Enum.PartType.Cylinder
	hole.Orientation = Vector3.new(0, 0, 90)
	hole.Parent = Workspace

	-- Add a decal to make it look like a hole
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/face.png" -- Placeholder, use actual hole texture if available
	decal.Face = Enum.NormalId.Top
	decal.Parent = hole

	return hole
end

--[[
	Find which island a resource belongs to
]]
function ToolInteractionSystem:findIslandName(resource)
	local current = resource.Parent

	while current and current ~= Workspace do
		-- Check if this is an island folder
		if current.Parent and (current.Parent.Name == "Islands" or current.Parent.Name == "PlayerIslands") then
			return current.Name
		end
		current = current.Parent
	end

	if resource.Parent and resource.Parent.Name == "Resources" then
		return "Resources"
	end

	return "Unknown"
end

return ToolInteractionSystem
