--[[
	IslandVillagerSpawner - Spawns random villagers on player islands
	Villagers patrol around the island to make it feel alive and populated
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Logger = require(ReplicatedStorage.Logger) -- Disabled for now
local NPCWalker = require(script.Parent.NPCWalker)

local IslandVillagerSpawner = {}
IslandVillagerSpawner.__index = IslandVillagerSpawner

-- Villager types with unique characteristics
local VILLAGER_TYPES = {
	{ name = "Fauna", color = Color3.fromRGB(139, 100, 80), icon = "🦌" },
	{ name = "Maple", color = Color3.fromRGB(180, 80, 60), icon = "🐻" },
	{ name = "Tom", color = Color3.fromRGB(255, 150, 100), icon = "🐱" },
	{ name = "Merengue", color = Color3.fromRGB(255, 200, 220), icon = "🐏" },
	{ name = "Marshal", color = Color3.fromRGB(200, 200, 255), icon = "🐿️" },
	{ name = "Beau", color = Color3.fromRGB(100, 150, 100), icon = "🦌" },
	{ name = "Apollo", color = Color3.fromRGB(150, 100, 80), icon = "🦅" },
	{ name = "Crescent", color = Color3.fromRGB(200, 150, 255), icon = "🐰" },
}

-- Patrol zone names
local PATROL_ZONES = {
	"center",      -- Town square
	"forest",      -- Trees and rocks
	"beach",       -- Shore
	"meadow",      -- Open grass
}

function IslandVillagerSpawner.new()
	local self = setmetatable({}, IslandVillagerSpawner)
	self._activeVillagers = {}  -- playerUserId -> { villagerName -> { model, walker } }
	return self
end

--[[
	Spawn random villagers on a player's island
	islandFolder: The generated island folder
	playerUserId: Player ID for tracking
]]
function IslandVillagerSpawner:SpawnVillagersOnIsland(islandFolder, playerUserId)
        Logger:Info("IslandVillagerSpawner", "Spawning villagers for island", { playerId = playerUserId })

        if not self._activeVillagers[playerUserId] then
                self._activeVillagers[playerUserId] = {}
        end

        local islandOrigin = islandFolder:GetAttribute("IslandOrigin")
        local spawnPlatform = islandFolder:FindFirstChild("PlayerSpawnPlatform")
        local basePosition

        if typeof(islandOrigin) == "Vector3" then
                basePosition = islandOrigin + Vector3.new(0, 5, 0)
        elseif spawnPlatform and spawnPlatform:IsA("BasePart") then
                basePosition = spawnPlatform.Position
        else
                basePosition = Vector3.new(0, 5, 0)
        end

        -- Spawn 2-5 random villagers
        local villagerCount = math.random(2, 5)

        for i = 1, villagerCount do
                local villagerType = VILLAGER_TYPES[math.random(1, #VILLAGER_TYPES)]
                local zoneType = PATROL_ZONES[math.random(1, #PATROL_ZONES)]

                self:_spawnVillager(villagerType, zoneType, playerUserId, islandFolder, i, basePosition)
        end

        Logger:Info("IslandVillagerSpawner", "Villagers spawned successfully", {
                playerId = playerUserId,
                villagerCount = villagerCount
	})
end

--[[
	Spawn a single villager
]]
function IslandVillagerSpawner:_spawnVillager(villagerType, zoneType, playerUserId, islandFolder, index, basePosition)
	-- Create villager model
	local villagerModel = Instance.new("Model")
	villagerModel.Name = villagerType.name .. "_" .. index
	villagerModel.Parent = islandFolder
	
	-- Create body part
	local bodyPart = Instance.new("Part")
	bodyPart.Name = "HumanoidRootPart"
	bodyPart.Shape = Enum.PartType.Cylinder
	bodyPart.Size = Vector3.new(2, 3, 2)
	bodyPart.Color = villagerType.color
	bodyPart.Material = Enum.Material.Neon
	bodyPart.CanCollide = true
	bodyPart.Anchored = true
	bodyPart.TopSurface = Enum.SurfaceType.Smooth
	bodyPart.BottomSurface = Enum.SurfaceType.Smooth
	bodyPart.Parent = villagerModel
	
	-- Spawn at random location on island (ground level, Tier 1)
        local spawnX = math.random(-200, 200)
        local spawnZ = math.random(-200, 200)
        local baseSpawn = basePosition or Vector3.new(0, 5, 0)
        bodyPart.Position = baseSpawn + Vector3.new(spawnX, 0, spawnZ)
	
	-- Add name label above villager
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = bodyPart
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = bodyPart
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = villagerType.icon .. " " .. villagerType.name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Parent = billboard
	
	-- Set as primary part
	villagerModel.PrimaryPart = bodyPart
	
	-- Generate patrol route
	local waypoints = self:_generatePatrolRoute(zoneType, bodyPart.Position)
	
	-- Create walker and start patrol
	local walker = NPCWalker.new(villagerModel, waypoints)
	walker:StartPatrol()
	
	-- Store reference
	self._activeVillagers[playerUserId][villagerType.name .. "_" .. index] = {
		model = villagerModel,
		walker = walker,
		type = villagerType,
		zone = zoneType
	}
	
	Logger:Info("IslandVillagerSpawner", "Spawned villager", { 
		villagerName = villagerType.name,
		zone = zoneType
	})
end

--[[
	Generate patrol waypoints for a villager
]]
function IslandVillagerSpawner:_generatePatrolRoute(zoneType, startPosition)
	local waypoints = {}
	
	if zoneType == "center" then
		-- Circular patrol in town square area
		local radius = 40
		for i = 0, 7 do
			local angle = (i / 8) * math.pi * 2
			table.insert(waypoints, startPosition + Vector3.new(
				math.cos(angle) * radius,
				0,
				math.sin(angle) * radius
			))
		end
		
	elseif zoneType == "forest" then
		-- Wander through forest area
		for i = 1, 6 do
			table.insert(waypoints, startPosition + Vector3.new(
				math.random(-50, 50),
				0,
				math.random(-50, 50)
			))
		end
		
	elseif zoneType == "beach" then
		-- Linear patrol along shore
		local distance = 60
		for i = 0, 5 do
			local offset = (i / 5) * distance - distance / 2
			table.insert(waypoints, startPosition + Vector3.new(offset, 0, 40))
		end
		
	elseif zoneType == "meadow" then
		-- Random wandering pattern
		for i = 1, 8 do
			table.insert(waypoints, startPosition + Vector3.new(
				math.random(-80, 80),
				0,
				math.random(-80, 80)
			))
		end
	end
	
	return waypoints
end

--[[
	Clean up villagers when player leaves
]]
function IslandVillagerSpawner:DespawnIslandVillagers(playerUserId)
	if self._activeVillagers[playerUserId] then
		for villagerName, villagerData in pairs(self._activeVillagers[playerUserId]) do
			if villagerData.walker then
				villagerData.walker:StopPatrol()
			end
			if villagerData.model then
				villagerData.model:Destroy()
			end
		end
		self._activeVillagers[playerUserId] = nil
	end
	
	Logger:Info("IslandVillagerSpawner", "Despawned island villagers", { playerId = playerUserId })
end

return IslandVillagerSpawner
