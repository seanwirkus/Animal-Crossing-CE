--[[
	IslandService - Handles island creation and management
	Manages player islands and island data
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local Local = {}
local Shared = {}

-- Island data store
local IslandDataStore = DataStoreService:GetDataStore("ACNH_Islands")

-- Track player islands
local playerIslands = {}

-- Island templates
local ISLAND_TEMPLATES = {
	{
		name = "Natural Paradise",
		description = "A peaceful island with rolling hills and natural beauty",
		theme = "natural",
		features = {"hills", "rivers", "forests"}
	},
	{
		name = "Tropical Resort",
		description = "A sunny island perfect for relaxation and fun",
		theme = "tropical",
		features = {"beaches", "palm_trees", "coral_reefs"}
	},
	{
		name = "Mountain Retreat",
		description = "A high-altitude island with stunning mountain views",
		theme = "mountain",
		features = {"peaks", "valleys", "waterfalls"}
	}
}

function Local.CreateIsland(player: Player, templateIndex: number, islandName: string)
	print(`[IslandService] Creating island for {player.Name}: {islandName}`)
	
	local template = ISLAND_TEMPLATES[templateIndex]
	if not template then
		warn(`[IslandService] Invalid template index: {templateIndex}`)
		return false
	end
	
	local islandData = {
		owner = player.UserId,
		name = islandName,
		template = template,
		created = os.time(),
		level = 1,
		buildings = {},
		residents = {},
		items = {}
	}
	
	-- Save to DataStore
	local success, error = pcall(function()
		IslandDataStore:SetAsync(`Island_{player.UserId}`, islandData)
	end)
	
	if not success then
		warn(`[IslandService] Failed to save island for {player.Name}: {error}`)
		return false
	end
	
	playerIslands[player.UserId] = islandData
	
	-- Fire remote to client
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local createRemote = remotes:WaitForChild("CreateIsland", 5)
		if createRemote then
			createRemote:FireClient(player, islandData)
		end
	end
	
	print(`[IslandService] Island created successfully for {player.Name}`)
	return true
end

function Local.GetPlayerIsland(player: Player)
	return playerIslands[player.UserId]
end

function Local.LoadPlayerIsland(player: Player)
	print(`[IslandService] Loading island for {player.Name}`)
	
	local success, islandData = pcall(function()
		return IslandDataStore:GetAsync(`Island_{player.UserId}`)
	end)
	
	if success and islandData then
		playerIslands[player.UserId] = islandData
		print(`[IslandService] Loaded existing island for {player.Name}`)
		return islandData
	else
		print(`[IslandService] No existing island for {player.Name}`)
		return nil
	end
end

function Shared.OnStart()
	print("[IslandService] Starting Animal Crossing IslandService...")
	
	-- Connect to remotes
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if remotes then
		-- Create island
		local createRemote = remotes:WaitForChild("CreateIsland", 5)
		if createRemote then
			createRemote.OnServerEvent:Connect(function(player, templateIndex, islandName)
				Local.CreateIsland(player, templateIndex, islandName)
			end)
		end
	end
	
	-- Load islands for existing players
	Players.PlayerAdded:Connect(function(player)
		Local.LoadPlayerIsland(player)
	end)
	
	-- Clean up when players leave
	Players.PlayerRemoving:Connect(function(player)
		playerIslands[player.UserId] = nil
	end)
end

return Shared