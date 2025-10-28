--[[
	CampsiteService - Manages campsite area and Tom Nook NPC
	Handles initial onboarding dialogue and player first-spawn experience
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Logger)

local CampsiteService = {}
CampsiteService.__index = CampsiteService

-- Campsite configuration
local CAMPSITE_CONFIG = {
	CENTER = Vector3.new(0, 10, 0),  -- Campsite center position
	NOOK_SPAWN = Vector3.new(5, 11, 0),  -- Tom Nook position (near tent)
	CAMPSITE_SIZE = 50,  -- Radius of campsite area
	WELCOME_MESSAGE = "Welcome to your island! Press T for tools, I for inventory. Explore and have fun!",
}

function CampsiteService.new(remotes)
	local self = setmetatable({}, CampsiteService)
	self._remotes = remotes
	self._playerStates = {}  -- Track which players have met Tom Nook
	
	Logger:Info("CampsiteService", "Initializing (Tom Nook handled by TomNookSpawner)")
	
	return self
end

--[[
	Greet a player on first island spawn
	Shows a brief welcome message
]]
function CampsiteService:GreetPlayer(player)
	if self._playerStates[player.UserId] then
		return  -- Already greeted this session
	end
	
	self._playerStates[player.UserId] = true
	
	-- Send brief welcome message
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		task.spawn(function()
			task.wait(0.5)  -- Brief delay for player to load
			dialogueRemote:FireClient(player, {
				villagerName = "Tom Nook",
				text = CAMPSITE_CONFIG.WELCOME_MESSAGE,
				color = "light",
				nameTagColor = "blue",
				continueButton = false
			})
		end)
	end
	
	Logger:Info("CampsiteService", "Greeted player", { playerId = player.UserId })
end

--[[
	Get campsite center position
]]
function CampsiteService:GetCampsiteCenter()
	return CAMPSITE_CONFIG.CENTER
end

--[[
	Get Tom Nook spawn position
]]
function CampsiteService:GetTomNookSpawn()
	return CAMPSITE_CONFIG.NOOK_SPAWN
end

--[[
	Check if position is within campsite bounds
]]
function CampsiteService:IsInCampsite(position)
	local distance = (position - CAMPSITE_CONFIG.CENTER).Magnitude
	return distance <= CAMPSITE_CONFIG.CAMPSITE_SIZE
end

function CampsiteService:Destroy()
	Logger:Info("CampsiteService", "Destroying")
	self._playerStates = {}
end

return CampsiteService
