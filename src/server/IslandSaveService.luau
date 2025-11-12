-- IslandSaveService
-- Handles saving and loading island data to/from DataStore
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local IslandSaveService = {}
IslandSaveService.__index = IslandSaveService

local _instance = nil

-- DataStore configuration
local DATASTORE_NAME = "ACNH_Islands"
local RunService = game:GetService("RunService")

if RunService:IsStudio() then
	DATASTORE_NAME = "ACNH_Islands_Dev"
end

function IslandSaveService.new()
	if _instance then
		return _instance
	end
	
	local self = setmetatable({}, IslandSaveService)
	
	self._datastore = DataStoreService:GetDataStore(DATASTORE_NAME)
	self._playerIslands = {} -- [userId] = islandData
	
	-- Setup RemoteEvents
	self:_setupRemoteEvents()
	
	_instance = self
	print("[IslandSaveService] ✅ Initialized")
	return self
end

function IslandSaveService:_setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end
	
	-- SaveIsland RemoteEvent
	local saveIslandRemote = remoteEventsFolder:FindFirstChild("SaveIsland")
	if not saveIslandRemote then
		saveIslandRemote = Instance.new("RemoteEvent")
		saveIslandRemote.Name = "SaveIsland"
		saveIslandRemote.Parent = remoteEventsFolder
	end
	
	saveIslandRemote.OnServerEvent:Connect(function(player)
		self:SavePlayerIsland(player)
	end)
	
	-- LoadIsland RemoteEvent
	local loadIslandRemote = remoteEventsFolder:FindFirstChild("LoadIsland")
	if not loadIslandRemote then
		loadIslandRemote = Instance.new("RemoteEvent")
		loadIslandRemote.Name = "LoadIsland"
		loadIslandRemote.Parent = remoteEventsFolder
	end
	
	loadIslandRemote.OnServerEvent:Connect(function(player)
		self:LoadPlayerIsland(player)
	end)
end

--[[
	Island Data Structure:
	{
		owner = userId,
		name = "Island Name",
		center = {x, y, z},
		size = {x, y, z},
		terrain = {
			-- Terrain modification data
		},
		objects = {
			trees = {...},
			rocks = {...},
			flowers = {...}
		},
		buildings = {
			-- Building positions and data
		},
		generated = timestamp,
		lastModified = timestamp
	}
]]

function IslandSaveService:SavePlayerIsland(player)
	local userId = player.UserId
	
	print("[IslandSaveService] 💾 Saving island for", player.Name)
	
	-- Get island data from workspace
	local islandData = self:_collectIslandData(player)
	if not islandData then
		warn("[IslandSaveService] No island data to save for", player.Name)
		return false
	end
	
	-- Save to DataStore
	local success, err = pcall(function()
		self._datastore:SetAsync(tostring(userId), islandData)
	end)
	
	if success then
		self._playerIslands[userId] = islandData
		print("[IslandSaveService] ✅ Saved island for", player.Name)
		return true
	else
		warn("[IslandSaveService] ❌ Failed to save island for", player.Name, ":", err)
		return false
	end
end

function IslandSaveService:_collectIslandData(player)
	local userId = player.UserId
	
	-- Check for saved island folder
	local savedIslandsFolder = Workspace:FindFirstChild("SavedIslands")
	if not savedIslandsFolder then
		return nil
	end
	
	local playerFolder = savedIslandsFolder:FindFirstChild(player.Name)
	if not playerFolder then
		return nil
	end
	
	-- Collect object data
	local objects = {
		trees = {},
		rocks = {},
		flowers = {}
	}
	
	for _, obj in ipairs(playerFolder:GetChildren()) do
		if obj:IsA("Model") then
			local objData = {
				name = obj.Name,
				position = obj:GetPivot().Position,
				rotation = obj:GetPivot().Rotation,
			}
			
			if obj.Name:find("Tree") then
				table.insert(objects.trees, objData)
			elseif obj.Name:find("Rock") then
				table.insert(objects.rocks, objData)
			elseif obj.Name:find("Flower") then
				table.insert(objects.flowers, objData)
			end
		end
	end
	
	-- Get island center and size from folder attributes or default
	local center = playerFolder:GetAttribute("Center") or Vector3.new(200, 0, 0)
	local size = playerFolder:GetAttribute("Size") or Vector3.new(150, 50, 150)
	
	local islandData = {
		owner = userId,
		name = playerFolder:GetAttribute("Name") or player.Name .. "'s Island",
		center = {center.X, center.Y, center.Z},
		size = {size.X, size.Y, size.Z},
		objects = objects,
		buildings = {}, -- TODO: Collect building data
		generated = playerFolder:GetAttribute("Generated") or os.time(),
		lastModified = os.time()
	}
	
	return islandData
end

function IslandSaveService:LoadPlayerIsland(player)
	local userId = player.UserId
	
	print("[IslandSaveService] 📂 Loading island for", player.Name)
	
	-- Try to get from cache first
	if self._playerIslands[userId] then
		print("[IslandSaveService] ✅ Loaded island from cache")
		return self._playerIslands[userId]
	end
	
	-- Load from DataStore
	local success, islandData = pcall(function()
		return self._datastore:GetAsync(tostring(userId))
	end)
	
	if success and islandData then
		self._playerIslands[userId] = islandData
		print("[IslandSaveService] ✅ Loaded island from DataStore")
		
		-- Reconstruct island in workspace
		self:_reconstructIsland(player, islandData)
		
		return islandData
	else
		print("[IslandSaveService] No saved island found for", player.Name)
		return nil
	end
end

function IslandSaveService:_reconstructIsland(player, islandData)
	-- Create saved islands folder structure
	local savedIslandsFolder = Workspace:FindFirstChild("SavedIslands")
	if not savedIslandsFolder then
		savedIslandsFolder = Instance.new("Folder")
		savedIslandsFolder.Name = "SavedIslands"
		savedIslandsFolder.Parent = Workspace
	end
	
	local playerFolder = savedIslandsFolder:FindFirstChild(player.Name)
	if playerFolder then
		-- Clear existing
		playerFolder:ClearAllChildren()
	else
		playerFolder = Instance.new("Folder")
		playerFolder.Name = player.Name
		playerFolder.Parent = savedIslandsFolder
	end
	
	-- Set attributes
	playerFolder:SetAttribute("Name", islandData.name)
	playerFolder:SetAttribute("Center", Vector3.new(unpack(islandData.center)))
	playerFolder:SetAttribute("Size", Vector3.new(unpack(islandData.size)))
	playerFolder:SetAttribute("Generated", islandData.generated)
	
	-- Reconstruct objects (trees, rocks, flowers)
	-- Note: This is a simplified version - full reconstruction would need
	-- to use the ProceduralIslandSystem to recreate models
	
	print("[IslandSaveService] ✅ Reconstructed island structure for", player.Name)
	print("[IslandSaveService]   - Trees:", #islandData.objects.trees)
	print("[IslandSaveService]   - Rocks:", #islandData.objects.rocks)
	print("[IslandSaveService]   - Flowers:", #islandData.objects.flowers)
end

function IslandSaveService:GetPlayerIsland(player)
	local userId = player.UserId
	return self._playerIslands[userId]
end

function IslandSaveService:HasIsland(player)
	local islandData = self:GetPlayerIsland(player)
	if islandData then
		return true
	end
	
	-- Also check DataStore
	local success, data = pcall(function()
		return self._datastore:GetAsync(tostring(player.UserId))
	end)
	
	return success and data ~= nil
end

-- Auto-save on player leaving
Players.PlayerRemoving:Connect(function(player)
	local service = IslandSaveService.new()
	service:SavePlayerIsland(player)
end)

-- Initialize service
local service = IslandSaveService.new()

return IslandSaveService

