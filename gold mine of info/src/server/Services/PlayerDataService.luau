--[[
	PlayerDataService - Animal Crossing player data management
	Handles player data loading, saving, and synchronization
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- local DataStoreService = game:GetService("DataStoreService") -- Disabled for now

local PlayerData = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerData"))

local DATASTORE_NAME = "ACNH_Production"

if RunService:IsStudio() then
	DATASTORE_NAME = "ACNH_Development"
end

type Profiles = {
	[number]: any
}

local Profiles: Profiles = {}

local Local = {}
local Shared = {}

-- Create DataStore
local PlayerDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- Default player data
local function getDefaultPlayerData(): PlayerData.PlayerData
	return {
		balance = {
			bells = 1000,
			miles = 500,
			nook_miles = 0,
		},
		island = {
			name = "",
			theme = "natural",
			resident_services = false,
			museum = false,
			shop = false,
		},
		inventory = {},
		level = 1,
		experience = 0,
		last_login = os.time(),
	}
end

function Local.SetupLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local bells = Instance.new("NumberValue", leaderstats)
	bells.Name = "Bells"
	bells.Value = 1000

	local miles = Instance.new("NumberValue", leaderstats)
	miles.Name = "Miles"
	miles.Value = 500

	-- Update leaderstats when data changes
	local connection
	connection = player.AncestryChanged:Connect(function()
		if not player.Parent then
			connection:Disconnect()
		end
	end)
end

function Local.CreateProfile(player: Player)
	print(`[PlayerDataService] Creating profile for {player.Name}`)
	
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(`Player_{player.UserId}`)
	end)
	
	if not success then
		warn(`[PlayerDataService] Failed to load data for {player.Name}: {data}`)
		data = getDefaultPlayerData()
	elseif not data then
		print(`[PlayerDataService] No existing data for {player.Name}, using defaults`)
		data = getDefaultPlayerData()
	else
		print(`[PlayerDataService] Loaded existing data for {player.Name}`)
		-- Update last login
		data.last_login = os.time()
	end
	
	Profiles[player.UserId] = data
	Local.SetupLeaderstats(player)
	
	-- Fire remote to client with player data
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local playerDataRemote = remotes:WaitForChild("PlayerDataLoaded", 5)
		if playerDataRemote then
			playerDataRemote:FireClient(player, data)
		end
	end
end

function Local.RemoveProfile(player: Player)
	print(`[PlayerDataService] Removing profile for {player.Name}`)
	
	local data = Profiles[player.UserId]
	if data then
		-- Save data before removing
		local success, error = pcall(function()
			PlayerDataStore:SetAsync(`Player_{player.UserId}`, data)
		end)
		
		if success then
			print(`[PlayerDataService] Saved data for {player.Name}`)
		else
			warn(`[PlayerDataService] Failed to save data for {player.Name}: {error}`)
		end
		
		Profiles[player.UserId] = nil
	end
end

function Shared.OnStart()
	print("[PlayerDataService] Starting Animal Crossing PlayerDataService...")
	
	Players.PlayerAdded:Connect(Local.CreateProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)

	-- Load data for players already in game
	for _, player in Players:GetPlayers() do
		Local.CreateProfile(player)
	end
	
	-- Auto-save every 30 seconds
	task.spawn(function()
		while true do
			task.wait(30)
			for userId, data in Profiles do
				local success, error = pcall(function()
					PlayerDataStore:SetAsync(`Player_{userId}`, data)
				end)
				if not success then
					warn(`[PlayerDataService] Auto-save failed for user {userId}: {error}`)
				end
			end
		end
	end)
end

return Shared
