--[[
	ResourceService
	Manages spawning and collection of resources (fish, bugs, fruit, shells)
	Uses Nookipedia API data for accurate spawn parameters
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Server = script.Parent

local LocalContentRepository = require(Server.LocalContentRepository)
local Data = require(ReplicatedStorage.Data)

type RemoteRegistry = {
	Get: (RemoteRegistry, string) -> RemoteEvent | RemoteFunction,
}

local ResourceService = {}
ResourceService.__index = ResourceService

-- Spawn configuration
local SPAWN_CONFIG = {
	fish = {
		maxActive = 15,
		spawnRadius = 100,
		respawnTime = 30, -- seconds
		locations = {"River", "Pond", "Sea"}
	},
	bugs = {
		maxActive = 20,
		spawnRadius = 120,
		respawnTime = 45,
		locations = {"Flying", "Ground", "Tree", "Flowers"}
	},
	fruit = {
		maxActive = 10,
		spawnRadius = 80,
		respawnTime = 300, -- 5 minutes
	},
	shells = {
		maxActive = 8,
		spawnRadius = 60,
		respawnTime = 120, -- 2 minutes
	}
}

local RESOURCE_CATEGORY_FALLBACK = {
	fish = "Fish",
	bugs = "Bug",
	fruit = "Fruit",
	shells = "Shell",
}

local QUEST_OBJECTIVE_TYPES = {
	fish = "CatchFish",
	bugs = "CatchBug",
	fruit = "GatherItem",
	shells = "GatherItem",
}

function ResourceService.new(remotes: RemoteRegistry, clock, economy, inventory, fishingQuest, questService)
	local self = setmetatable({}, ResourceService)
	self._remotes = remotes
	self._clock = clock
	self._economy = economy
	self._inventory = inventory
        self._fishingQuest = fishingQuest
	self._questService = questService
	self._repository = LocalContentRepository.new()
        self._activeResources = {
                fish = {},
                bugs = {},
                fruit = {},
                shells = {}
	}
	self._spawnTasks = {}
	self._initialized = false
	self._resourcePools = {
		fish = {},
		bugs = {},
		fruit = {},
		shells = {}
	}
	
	self:_initialize()
	return self
end

function ResourceService:_initialize()
	-- Set up remote handlers
	local collectRemote = self._remotes:Get("CollectResource")
	collectRemote.OnServerEvent:Connect(function(player, resourceInstance, resourceType, resourceId)
		self:_handleCollection(player, resourceInstance, resourceType, resourceId)
	end)
	
	-- Load resource data from Nookipedia
	task.spawn(function()
		self:_loadResourceData()
	end)
	
	-- Start spawn loops
	task.spawn(function()
		self:_spawnLoop()
	end)
end

function ResourceService:_loadResourceData()
	print("[ResourceService] Loading resource data from local repository...")
	
	-- Build default resource pools with minimal data
	-- (Repository is unavailable, using fallback simple resources)
	
	self._resourcePools.fish = {
		{ id = "fish_salmon", name = "Salmon", type = "fish", value = 100, rarity = "common", location = "River", shadowSize = "Medium" },
		{ id = "fish_carp", name = "Carp", type = "fish", value = 150, rarity = "common", location = "River", shadowSize = "Large" },
		{ id = "fish_bass", name = "Bass", type = "fish", value = 200, rarity = "uncommon", location = "River", shadowSize = "Large" },
	}
	
	self._resourcePools.bugs = {
		{ id = "bug_butterfly", name = "Butterfly", type = "bugs", value = 50, rarity = "common", location = "Flying" },
		{ id = "bug_beetle", name = "Beetle", type = "bugs", value = 80, rarity = "uncommon", location = "Flying" },
	}
	
	self._resourcePools.fruit = {
		{ id = "fruit_apple", name = "Apple", type = "fruit", value = 30, rarity = "common", location = "Tree" },
		{ id = "fruit_orange", name = "Orange", type = "fruit", value = 30, rarity = "common", location = "Tree" },
	}
	
	self._resourcePools.shells = {
		{ id = "shell_conch", name = "Conch", type = "shells", value = 25, rarity = "common", location = "Beach" },
	}
	
	print("[ResourceService] ✅ Loaded fallback resource data (repository unavailable)")
end

function ResourceService:_buildResourcePool(resourceType: string, categories: { string }, converter)
	local pool = {}
	for _, category in ipairs(categories) do
		local items = self._repository:GetItemsByCategory(category)
		for _, item in ipairs(items) do
			local entry = converter(item)
			if entry and entry.id then
				pool[#pool + 1] = entry
			end
		end
	end

	self._resourcePools[resourceType] = pool
	print(string.format("[ResourceService] Loaded %d %s entries", #pool, resourceType))
end

function ResourceService:_convertRarity(nookRarity: string?): string
	if not nookRarity then return "Common" end
	
	local lower = nookRarity:lower()
	if lower:match("ultra") or lower:match("very rare") then
		return "UltraRare"
	elseif lower:match("rare") then
		return "Rare"
	elseif lower:match("uncommon") then
		return "Uncommon"
	else
		return "Common"
	end
end

function ResourceService:_spawnLoop()
	while true do
		-- Spawn fish
		self:_spawnResourceType("fish")
		
		-- Spawn bugs
		self:_spawnResourceType("bugs")
		
		-- Spawn fruit
		self:_spawnResourceType("fruit")
		
		-- Spawn shells
		self:_spawnResourceType("shells")
		
		task.wait(5) -- Check every 5 seconds
	end
end

function ResourceService:_spawnResourceType(resourceType: string)
	local config = SPAWN_CONFIG[resourceType]
	local activeCount = #self._activeResources[resourceType]
	
	if activeCount >= config.maxActive then
		return
	end
	
	-- Spawn new resources up to max
	local toSpawn = config.maxActive - activeCount
	for i = 1, toSpawn do
		self:_spawnResource(resourceType)
	end
end

function ResourceService:_spawnResource(resourceType: string)
	local config = SPAWN_CONFIG[resourceType]
	
	-- Get a random resource of this type
	local availableResources = self._resourcePools[resourceType] or {}
	
	-- Fall back to existing Data if Nookipedia data isn't loaded yet
	if #availableResources == 0 then
		local fallbackCategory = RESOURCE_CATEGORY_FALLBACK[resourceType]
		for id, item in pairs(Data.Items) do
			if fallbackCategory and item.category == fallbackCategory then
				table.insert(availableResources, {
					id = id,
					name = item.name or item.displayName,
					type = resourceType,
					value = item.baseValue or 100,
					rarity = item.rarity or "Common",
				})
			end
		end
	end
	
	if #availableResources == 0 then
		return
	end
	
	-- Weight by rarity
	local resource = self:_selectWeightedResource(availableResources)
	
	-- Find a spawn location
	local spawnPosition = self:_findSpawnLocation(resourceType, config)
	if not spawnPosition then
		return
	end
	
	-- Create the resource instance
	local resourceInstance = self:_createResourceInstance(resource, spawnPosition)
	if resourceInstance then
		table.insert(self._activeResources[resourceType], {
			instance = resourceInstance,
			data = resource,
			spawnTime = tick(),
		})
	end
end

function ResourceService:_selectWeightedResource(resources: {}): {}
	local weights = {
		Common = 50,
		Uncommon = 30,
		Rare = 15,
		UltraRare = 5,
	}
	
	local totalWeight = 0
	for _, resource in ipairs(resources) do
		totalWeight = totalWeight + (weights[resource.rarity] or 50)
	end
	
	local roll = math.random() * totalWeight
	local currentWeight = 0
	
	for _, resource in ipairs(resources) do
		currentWeight = currentWeight + (weights[resource.rarity] or 50)
		if roll <= currentWeight then
			return resource
		end
	end
	
	return resources[1]
end

function ResourceService:_findSpawnLocation(resourceType: string, config: {}): Vector3?
	local interactables = workspace:FindFirstChild("Interactables")
	if not interactables then
		interactables = Instance.new("Folder")
		interactables.Name = "Interactables"
		interactables.Parent = workspace
	end
	
	-- Random position within spawn radius
	local angle = math.random() * math.pi * 2
	local distance = math.random() * config.spawnRadius
	local x = math.cos(angle) * distance
	local z = math.sin(angle) * distance
	
	-- Find ground level
	local rayOrigin = Vector3.new(x, 100, z)
	local rayDirection = Vector3.new(0, -200, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {interactables}
	
	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position + Vector3.new(0, 2, 0)
	end
	
	return Vector3.new(x, 0, z)
end

function ResourceService:_createResourceInstance(resource: {}, position: Vector3): Model?
	-- Create a simple visual representation
	local model = Instance.new("Model")
	model.Name = resource.name
	
	local part = Instance.new("Part")
	part.Name = "Base"
	part.Size = Vector3.new(2, 2, 2)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	
	-- Color by type/rarity
	if resource.rarity == "UltraRare" then
		part.Color = Color3.fromRGB(255, 215, 0) -- Gold
	elseif resource.rarity == "Rare" then
		part.Color = Color3.fromRGB(138, 43, 226) -- Purple
	elseif resource.rarity == "Uncommon" then
		part.Color = Color3.fromRGB(65, 105, 225) -- Blue
	else
		part.Color = Color3.fromRGB(144, 238, 144) -- Light green
	end
	
	part.Material = Enum.Material.Neon
	part.Transparency = 0.3
	part.Parent = model
	
	-- Set the primary part BEFORE positioning the model
	model.PrimaryPart = part

	-- Add attributes for interaction
	model:SetAttribute("InteractionType", "Resource")
	model:SetAttribute("ResourceType", resource.type)
	model:SetAttribute("ResourceId", resource.id)
	
	-- Add to workspace
	local interactables = workspace:FindFirstChild("Interactables")
	model.Parent = interactables
	model:SetPrimaryPartCFrame(CFrame.new(position))
	
	return model
end

function ResourceService:_recordQuestProgress(player, resourceType, resourceData, amount)
        if not self._questService or not self._questService.RecordInteraction then
                return
        end

        local objectiveType = QUEST_OBJECTIVE_TYPES[resourceType]
        if not objectiveType then
                return
        end

        local count = amount or 1
        local targetId = resourceData and resourceData.id or nil
        for _ = 1, math.max(1, count) do
                self._questService:RecordInteraction(player, objectiveType, targetId)
        end
end

function ResourceService:_handleCollection(player: Player, resourceInstance: Instance, resourceType: string, resourceId: string)
	if not resourceInstance or not resourceInstance.Parent then
		return
	end
	
	-- AC-STYLE: Validate that player has correct tool
	local selectedTool = self:_getPlayerSelectedTool(player)
	if not self:_validateToolForResource(resourceType, selectedTool) then
		print(string.format("[ResourceService] %s tried to collect %s without proper tool", player.Name, resourceType))
		-- Could send a message to player here
		return
	end
	
	-- Validate resource exists in active list
	local resourceList = self._activeResources[resourceType]
	if not resourceList then
		return
	end
	
	local found = false
	local resourceData = nil
	
	for i, activeResource in ipairs(resourceList) do
		if activeResource.instance == resourceInstance then
			found = true
			resourceData = activeResource.data
			table.remove(resourceList, i)
			break
		end
	end
	
	if not found then
		warn("[ResourceService] Resource not found in active list")
		return
	end
	
	-- Remove from world
	resourceInstance:Destroy()
	
	-- Add to player inventory
	self._inventory:AddItem(player, resourceData.id, 1)
	
	-- Award bells - use API-enriched prices if available
	local bellsToAward = resourceData.value or 100
	
	self._economy:AddBells(player, bellsToAward)
	self:_recordQuestProgress(player, resourceType, resourceData, 1)
	
	print(string.format("[ResourceService] %s collected %s (+%d bells)", 
		player.Name, resourceData.name, bellsToAward))
	
	-- Notify fishing quest if fish was caught
	if resourceType == "fish" and self._fishingQuest then
		self._fishingQuest:OnFishCaught(player.UserId, resourceData.name)
	end
	
	-- Schedule respawn
	task.delay(SPAWN_CONFIG[resourceType].respawnTime, function()
		self:_spawnResource(resourceType)
	end)
end

--[[
	AC-STYLE: Get player's currently selected tool
]]
function ResourceService:_getPlayerSelectedTool(player: Player): string?
	-- Get from ToolService or PlayerData
	-- This would need integration with your ToolService
	-- For now, return nil if no tool is selected (hands)
	return nil
end

--[[
	AC-STYLE: Validate tool requirement for resource type
]]
function ResourceService:_validateToolForResource(resourceType: string, selectedTool: string?): boolean
	-- If using hands (no tool), some resources need tools
	if not selectedTool then
		-- Can collect fish, bugs with hands (in some AC games)
		-- But rocks/dig spots need a shovel
		if resourceType == "fish" or resourceType == "bugs" then
			return true
		end
		-- Rocks, dig spots need shovel
		if resourceType == "rocks" or resourceType == "fossils" or resourceType == "digspots" then
			return false
		end
		return true
	end
	
	-- With tool selected, validate it matches
	if resourceType == "fish" then
		return selectedTool == "tool_fishing_rod_basic" or selectedTool == "tool_fishing_rod"
	elseif resourceType == "bugs" then
		return selectedTool == "tool_bug_net_basic" or selectedTool == "tool_bug_net"
	elseif resourceType == "rocks" or resourceType == "fossils" or resourceType == "digspots" then
		return selectedTool == "tool_shovel_basic" or selectedTool == "tool_shovel"
	end
	
	return true
end

return ResourceService
