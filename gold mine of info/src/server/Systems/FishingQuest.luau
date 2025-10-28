-- FishingQuest.luau - Fishing tutorial quest handler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Logger)
local QuestTypes = require(ReplicatedStorage.QuestTypes)

local FishingQuest = {}
FishingQuest.__index = FishingQuest

function FishingQuest.new(questService)
	local self = setmetatable({}, FishingQuest)
	self._questService = questService
	self._playerFishCounts = {}  -- playerUserId -> count
	self._connections = {}
	Logger:Info("FishingQuest", "Initializing")
	return self
end

-- Start the fishing quest for a player
function FishingQuest:StartFishingQuest(playerId)
	-- Create the quest
	local quest = self._questService:CreateQuest(playerId, QuestTypes.PredefinedQuests.FISHING_TUTORIAL)
	self._playerFishCounts[playerId] = 0
	
	Logger:Info("FishingQuest", "Started fishing quest for player", { playerId = playerId })
	return quest
end

-- Register a fish catch event (call this when a fish is caught)
function FishingQuest:OnFishCaught(playerId, fishName)
	if not self._questService:GetQuest(playerId, "fishing_tutorial") then
		return  -- Player doesn't have the quest
	end
	
	if not self._playerFishCounts[playerId] then
		self._playerFishCounts[playerId] = 0
	end
	
	self._playerFishCounts[playerId] = self._playerFishCounts[playerId] + 1
	local count = self._playerFishCounts[playerId]
	
	-- Update quest progress
	self._questService:UpdateQuestProgress(playerId, "fishing_tutorial", count)
	
	Logger:Debug("FishingQuest", "Fish caught", { 
		playerId = playerId, 
		fishName = fishName, 
		count = count,
		target = 3 
	})
	
	-- Check if quest is complete
	if count >= 3 then
		Logger:Info("FishingQuest", "Fishing quest completed", { playerId = playerId, totalFish = count })
	end
end

-- Get current progress for a player
function FishingQuest:GetProgress(playerId)
	return self._playerFishCounts[playerId] or 0
end

-- Reset quest for a player (for new islands, etc)
function FishingQuest:ResetQuest(playerId)
	self._playerFishCounts[playerId] = nil
end

return FishingQuest
