-- HomeBuildingService
-- Handles player home placement, upgrades, and management
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local HomeBuildingService = {}
HomeBuildingService.__index = HomeBuildingService

local _instance = nil

function HomeBuildingService.new()
	if _instance then
		return _instance
	end
	
	local self = setmetatable({}, HomeBuildingService)
	
	self._playerHomes = {} -- [userId] = homeData
	self._homeModels = {} -- [userId] = Model
	
	-- Setup RemoteEvents
	self:_setupRemoteEvents()
	
	-- Load existing homes
	self:_loadExistingHomes()
	
	_instance = self
	print("[HomeBuildingService] ✅ Initialized")
	return self
end

function HomeBuildingService:_setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end
	
	-- PlaceHome RemoteEvent
	local placeHomeRemote = remoteEventsFolder:FindFirstChild("PlaceHome")
	if not placeHomeRemote then
		placeHomeRemote = Instance.new("RemoteEvent")
		placeHomeRemote.Name = "PlaceHome"
		placeHomeRemote.Parent = remoteEventsFolder
	end
	
	placeHomeRemote.OnServerEvent:Connect(function(player, position)
		self:PlaceHome(player, position)
	end)
	
	-- UpgradeHome RemoteEvent
	local upgradeHomeRemote = remoteEventsFolder:FindFirstChild("UpgradeHome")
	if not upgradeHomeRemote then
		upgradeHomeRemote = Instance.new("RemoteEvent")
		upgradeHomeRemote.Name = "UpgradeHome"
		upgradeHomeRemote.Parent = remoteEventsFolder
	end
	
	upgradeHomeRemote.OnServerEvent:Connect(function(player)
		self:UpgradeHome(player)
	end)
end

function HomeBuildingService:_loadExistingHomes()
	local playerHomesFolder = Workspace:FindFirstChild("PlayerHomes")
	if not playerHomesFolder then
		playerHomesFolder = Instance.new("Folder")
		playerHomesFolder.Name = "PlayerHomes"
		playerHomesFolder.Parent = Workspace
	end
	
	-- Load existing homes
	for _, home in ipairs(playerHomesFolder:GetChildren()) do
		if home:IsA("Model") and home:GetAttribute("HomeOwner") then
			local ownerId = home:GetAttribute("HomeOwner")
			self._homeModels[ownerId] = home
			
			-- Reconstruct home data
			local homeData = {
				owner = ownerId,
				position = home:GetPivot().Position,
				size = home:GetAttribute("HomeSize") or "Tent",
				rooms = home:GetAttribute("Rooms") or 1,
				created = home:GetAttribute("Created") or os.time(),
			}
			
			self._playerHomes[ownerId] = homeData
		end
	end
	
	print("[HomeBuildingService] ✅ Loaded", #self._homeModels, "existing homes")
end

function HomeBuildingService:PlaceHome(player, position)
	local userId = player.UserId
	
	-- Check if player already has a home
	if self._playerHomes[userId] then
		warn("[HomeBuildingService] Player", player.Name, "already has a home")
		return false
	end
	
	-- Validate position
	if not position or typeof(position) ~= "Vector3" then
		warn("[HomeBuildingService] Invalid position provided")
		return false
	end
	
	-- Check if position is valid (flat ground, not too close to other homes, etc.)
	if not self:_validateHomePosition(position, player) then
		warn("[HomeBuildingService] Invalid home position")
		return false
	end
	
	-- Create home model
	local homeModel = self:_createHomeModel(player, position, "Tent")
	if not homeModel then
		warn("[HomeBuildingService] Failed to create home model")
		return false
	end
	
	-- Store home data
	local homeData = {
		owner = userId,
		position = position,
		size = "Tent",
		rooms = 1,
		created = os.time(),
		lastModified = os.time()
	}
	
	self._playerHomes[userId] = homeData
	self._homeModels[userId] = homeModel
	
	print("[HomeBuildingService] ✅ Placed home for", player.Name, "at", position)
	return true
end

function HomeBuildingService:_validateHomePosition(position, player)
	-- Check if position is on flat ground
	local rayOrigin = Vector3.new(position.X, position.Y + 50, position.Z)
	local rayDirection = Vector3.new(0, -100, 0)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {Workspace.Terrain}
	
	local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if not rayResult then
		return false
	end
	
	-- Check distance from other homes (minimum 20 studs)
	local playerHomesFolder = Workspace:FindFirstChild("PlayerHomes")
	if playerHomesFolder then
		for _, home in ipairs(playerHomesFolder:GetChildren()) do
			if home:IsA("Model") and home ~= self._homeModels[player.UserId] then
				local homePosition = home:GetPivot().Position
				local distance = (position - homePosition).Magnitude
				if distance < 20 then
					return false
				end
			end
		end
	end
	
	return true
end

function HomeBuildingService:_createHomeModel(player, position, size)
	-- Get home template
	local template = self:_getHomeTemplate(size)
	if not template then
		-- Create fallback tent
		return self:_createFallbackTent(player, position)
	end
	
	-- Clone template
	local home = template:Clone()
	home.Name = "Home_" .. player.Name
	
	-- Set attributes
	home:SetAttribute("HomeOwner", player.UserId)
	home:SetAttribute("HomeSize", size)
	home:SetAttribute("Rooms", 1)
	home:SetAttribute("Created", os.time())
	
	-- Position home
	local homePart = home:FindFirstChildOfClass("BasePart")
	if homePart then
		homePart.CFrame = CFrame.new(position)
	else
		home:SetPrimaryPartCFrame(CFrame.new(position))
	end
	
	-- Parent to PlayerHomes folder
	local playerHomesFolder = Workspace:FindFirstChild("PlayerHomes")
	if not playerHomesFolder then
		playerHomesFolder = Instance.new("Folder")
		playerHomesFolder.Name = "PlayerHomes"
		playerHomesFolder.Parent = Workspace
	end
	
	home.Parent = playerHomesFolder
	
	return home
end

function HomeBuildingService:_getHomeTemplate(size)
	-- Try to find template in ReplicatedStorage
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if modelsFolder then
		local templateName = size == "Tent" and "Tent" or "House"
		local template = modelsFolder:FindFirstChild(templateName)
		if template and template:IsA("Model") then
			return template
		end
	end
	
	return nil
end

function HomeBuildingService:_createFallbackTent(player, position)
	-- Create a simple tent model as fallback
	local tent = Instance.new("Model")
	tent.Name = "Tent_" .. player.Name
	
	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 0.2, 4)
	base.Material = Enum.Material.Fabric
	base.BrickColor = BrickColor.new("Brown")
	base.Anchored = true
	base.CFrame = CFrame.new(position)
	base.Parent = tent
	
	-- Tent body (triangular)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3.5, 2, 3.5)
	body.Material = Enum.Material.Fabric
	body.BrickColor = BrickColor.new("Brown")
	body.Anchored = true
	body.Shape = Enum.PartType.Ball
	body.CFrame = base.CFrame + Vector3.new(0, 1.2, 0)
	body.Parent = tent
	
	-- Tent pole
	local pole = Instance.new("Part")
	pole.Name = "Pole"
	pole.Size = Vector3.new(0.2, 3, 0.2)
	pole.Material = Enum.Material.Wood
	pole.BrickColor = BrickColor.new("Brown")
	pole.Anchored = true
	pole.CFrame = base.CFrame + Vector3.new(0, 1.5, 0)
	pole.Parent = tent
	
	tent.PrimaryPart = base
	
	-- Set attributes
	tent:SetAttribute("HomeOwner", player.UserId)
	tent:SetAttribute("HomeSize", "Tent")
	tent:SetAttribute("Rooms", 1)
	tent:SetAttribute("Created", os.time())
	
	-- Parent to PlayerHomes folder
	local playerHomesFolder = Workspace:FindFirstChild("PlayerHomes")
	if not playerHomesFolder then
		playerHomesFolder = Instance.new("Folder")
		playerHomesFolder.Name = "PlayerHomes"
		playerHomesFolder.Parent = Workspace
	end
	
	tent.Parent = playerHomesFolder
	
	print("[HomeBuildingService] ⚠️ Created fallback tent for", player.Name)
	return tent
end

function HomeBuildingService:UpgradeHome(player)
	local userId = player.UserId
	local homeData = self._playerHomes[userId]
	
	if not homeData then
		warn("[HomeBuildingService] Player", player.Name, "doesn't have a home")
		return false
	end
	
	-- Upgrade logic (Tent -> Small House -> Large House, etc.)
	local currentSize = homeData.size
	local newSize = nil
	
	if currentSize == "Tent" then
		newSize = "SmallHouse"
	elseif currentSize == "SmallHouse" then
		newSize = "LargeHouse"
	else
		warn("[HomeBuildingService] Home already at max size")
		return false
	end
	
	-- TODO: Check if player has required resources/bells
	
	-- Upgrade home model
	local homeModel = self._homeModels[userId]
	if homeModel then
		local position = homeModel:GetPivot().Position
		homeModel:Destroy()
		
		local newHome = self:_createHomeModel(player, position, newSize)
		if newHome then
			homeData.size = newSize
			homeData.rooms = homeData.rooms + 1
			homeData.lastModified = os.time()
			
			self._homeModels[userId] = newHome
			
			print("[HomeBuildingService] ✅ Upgraded home for", player.Name, "to", newSize)
			return true
		end
	end
	
	return false
end

function HomeBuildingService:GetPlayerHome(player)
	local userId = player.UserId
	return self._playerHomes[userId]
end

function HomeBuildingService:GetPlayerHomeModel(player)
	local userId = player.UserId
	return self._homeModels[userId]
end

function HomeBuildingService:HasHome(player)
	local userId = player.UserId
	return self._playerHomes[userId] ~= nil
end

-- Initialize service
local service = HomeBuildingService.new()

return HomeBuildingService

