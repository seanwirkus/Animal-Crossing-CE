--[[
	IslandNPCManager - Manages NPC placement and patrol routes on player islands
	NPCs spawn in designated zones and walk patrol routes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Logger = require(ReplicatedStorage.Logger) -- Disabled for now
local NPCWalker = require(script.Parent.NPCWalker)

local IslandNPCManager = {}
IslandNPCManager.__index = IslandNPCManager

function IslandNPCManager.new()
	local self = setmetatable({}, IslandNPCManager)
	self._activeNPCs = {}  -- playerUserId -> { npcName -> NPCWalker }
	return self
end

--[[
	Spawn NPCs for a player's island
	islandFolder: The generated island folder
	playerUserId: Player ID for tracking
]]
function IslandNPCManager:SpawnIslandNPCs(islandFolder, playerUserId)
	Logger:Info("IslandNPCManager", "Spawning NPCs for island", { playerId = playerUserId })
	
	if not self._activeNPCs[playerUserId] then
		self._activeNPCs[playerUserId] = {}
	end
	
	-- Find NPC zones in the island
	local townSquare = islandFolder:FindFirstChild("NPCZone_TownSquare")
	local housingArea = islandFolder:FindFirstChild("NPCZone_Housing")
	local beachZone = islandFolder:FindFirstChild("NPCZone_Beach")
	
	-- Spawn NPCs in their zones (placeholder cubes for now)
	if townSquare then
		self:_spawnNPCInZone("Isabelle", townSquare, "center", playerUserId, islandFolder)
	end
	
	if housingArea then
		self:_spawnNPCInZone("TomNook", housingArea, "housing", playerUserId, islandFolder)
	end
	
	if beachZone then
		self:_spawnNPCInZone("Orville", beachZone, "beach", playerUserId, islandFolder)
	end
	
	Logger:Info("IslandNPCManager", "Island NPCs spawned successfully", { playerId = playerUserId })
end

--[[
	Spawn a single NPC in a designated zone
]]
function IslandNPCManager:_spawnNPCInZone(npcName, zone, zoneType, playerUserId, islandFolder)
	-- Create NPC model (placeholder cube)
	local npcModel = Instance.new("Model")
	npcModel.Name = npcName
	npcModel.Parent = islandFolder
	
	-- Create main body part
	local bodyPart = Instance.new("Part")
	bodyPart.Name = "HumanoidRootPart"
	bodyPart.Shape = Enum.PartType.Cylinder
	bodyPart.Size = Vector3.new(3, 4, 3)
	bodyPart.Color = self:_getNPCColor(npcName)
	bodyPart.Material = Enum.Material.Neon
	bodyPart.CanCollide = true
	bodyPart.Anchored = true
	bodyPart.TopSurface = Enum.SurfaceType.Smooth
	bodyPart.BottomSurface = Enum.SurfaceType.Smooth
	bodyPart.Parent = npcModel
	
	-- Spawn at zone center with slight randomization
	local zoneCenter = zone.Position
	local randomOffset = Vector3.new(
		math.random(-15, 15),
		0,
		math.random(-15, 15)
	)
	bodyPart.Position = zoneCenter + randomOffset
	
	-- Add name label above NPC
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = bodyPart
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.Parent = bodyPart
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npcName
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Parent = billboard
	
	-- Set as primary part
	npcModel.PrimaryPart = bodyPart
	
	-- Create patrol route for this NPC
	local waypoints = self:_generatePatrolRoute(zone, zoneType)
	
	-- Create walker and start patrol
	local walker = NPCWalker.new(npcModel, waypoints)
	walker:StartPatrol()
	
	-- Store reference
	self._activeNPCs[playerUserId][npcName] = {
		model = npcModel,
		walker = walker,
		zone = zone
	}
	
	Logger:Info("IslandNPCManager", "Spawned NPC", { npcName = npcName, zoneType = zoneType })
end

--[[
	Generate patrol waypoints for a zone
]]
function IslandNPCManager:_generatePatrolRoute(zone, zoneType)
	local center = zone.Position
	local size = zone.Size
	local waypoints = {}
	
	if zoneType == "center" then
		-- Town square: circular patrol
		local radius = 25
		for i = 0, 7 do
			local angle = (i / 8) * math.pi * 2
			table.insert(waypoints, center + Vector3.new(
				math.cos(angle) * radius,
				0,
				math.sin(angle) * radius
			))
		end
	elseif zoneType == "housing" then
		-- Housing area: back and forth
		local halfWidth = size.X / 2 - 10
		table.insert(waypoints, center + Vector3.new(-halfWidth, 0, 0))
		table.insert(waypoints, center + Vector3.new(-halfWidth, 0, 20))
		table.insert(waypoints, center + Vector3.new(halfWidth, 0, 20))
		table.insert(waypoints, center + Vector3.new(halfWidth, 0, 0))
	elseif zoneType == "beach" then
		-- Beach: along shore
		local radius = 30
		for i = 0, 5 do
			local angle = (i / 6) * math.pi
			table.insert(waypoints, center + Vector3.new(
				math.cos(angle) * radius,
				0,
				math.sin(angle) * radius
			))
		end
	end
	
	return waypoints
end

--[[
	Get NPC color based on name
]]
function IslandNPCManager:_getNPCColor(npcName)
	local colors = {
		Isabelle = Color3.fromRGB(255, 180, 100),  -- Orange/tan
		TomNook = Color3.fromRGB(120, 80, 60),     -- Brown
		Orville = Color3.fromRGB(100, 150, 200),   -- Blue
	}
	return colors[npcName] or Color3.fromRGB(100, 100, 100)
end

--[[
	Clean up NPCs for a player when they leave
]]
function IslandNPCManager:DespawnPlayerNPCs(playerUserId)
	if self._activeNPCs[playerUserId] then
		for npcName, npcData in pairs(self._activeNPCs[playerUserId]) do
			if npcData.walker then
				npcData.walker:StopPatrol()
			end
			if npcData.model then
				npcData.model:Destroy()
			end
		end
		self._activeNPCs[playerUserId] = nil
	end
	
	Logger:Info("IslandNPCManager", "Despawned NPCs", { playerId = playerUserId })
end

return IslandNPCManager
