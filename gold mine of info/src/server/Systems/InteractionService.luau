--[[
	InteractionService - Handles clickable building interactions
	Detects when players click on buildings and routes to appropriate actions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Logger)

local InteractionService = {}
InteractionService.__index = InteractionService

-- Interaction types and their handlers
local INTERACTION_TYPES = {
	NOOKS_CRANNY = "NooksCranny",
	RESIDENT_SERVICES = "ResidentServices",
	PLAYER_HOME = "PlayerHome",
}

function InteractionService.new(remotes)
	local self = setmetatable({}, InteractionService)
	self._remotes = remotes
	self._cooldowns = {}  -- Prevent spam clicks
	self._activeInteractions = {}  -- Track active interactions per player
	
	Logger:Info("InteractionService", "Initializing")
	
	-- Listen for building click events
	local clickRemote = remotes:Get("BuildingClicked")
	if clickRemote then
		clickRemote.OnServerEvent:Connect(function(player, buildingName)
			self:HandleInteraction(player, buildingName)
		end)
	end
	
	return self
end

--[[
	Handle a building interaction
]]
function InteractionService:HandleInteraction(player, buildingName)
	local userId = player.UserId
	
	-- Check cooldown
	if self._cooldowns[userId] and (tick() - self._cooldowns[userId]) < 0.5 then
		return  -- Prevent spam
	end
	self._cooldowns[userId] = tick()
	
	-- Prevent duplicate interactions
	if self._activeInteractions[userId] then
		return
	end
	self._activeInteractions[userId] = buildingName
	
	Logger:Info("InteractionService", "Player interacting with building", { 
		playerId = userId, 
		building = buildingName 
	})
	
	-- Route to appropriate handler
	if buildingName == "NooksCranny" then
		self:HandleNooksCrannyClick(player)
	elseif buildingName == "ResidentServices" then
		self:HandleResidentServicesClick(player)
	elseif buildingName == "PlayerHome" then
		self:HandlePlayerHomeClick(player)
	end
	
	-- Clear active interaction
	task.wait(0.1)
	self._activeInteractions[userId] = nil
end

--[[
	Handle Nook's Cranny interaction
]]
function InteractionService:HandleNooksCrannyClick(player)
	local openShopRemote = self._remotes:Get("OpenShop")
	if openShopRemote then
		openShopRemote:FireClient(player, "nooks_cranny")
		Logger:Info("InteractionService", "Opened Nook's Cranny shop", { playerId = player.UserId })
	end
end

--[[
	Handle Resident Services interaction
]]
function InteractionService:HandleResidentServicesClick(player)
	Logger:Info("InteractionService", "Resident Services clicked", { playerId = player.UserId })
	-- TODO: Implement resident services interaction (house upgrade, etc.)
end

--[[
	Handle Player Home interaction
]]
function InteractionService:HandlePlayerHomeClick(player)
	local openHomeRemote = self._remotes:Get("OpenHome")
	if openHomeRemote then
		openHomeRemote:FireClient(player)
		Logger:Info("InteractionService", "Opened player home", { playerId = player.UserId })
	end
end

--[[
	Mark a building as clickable on the island
]]
function InteractionService:MarkBuildingClickable(model, buildingType)
	if not model then return end
	model:SetAttribute("Clickable", true)
	model:SetAttribute("BuildingType", buildingType)
	Logger:Debug("InteractionService", "Marked building clickable", { 
		building = model.Name, 
		type = buildingType 
	})
end

function InteractionService:Destroy()
	Logger:Info("InteractionService", "Destroying")
	self._cooldowns = {}
	self._activeInteractions = {}
end

return InteractionService
