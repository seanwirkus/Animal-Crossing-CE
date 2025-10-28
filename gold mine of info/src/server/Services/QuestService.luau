-- QuestService.luau - Server-side quest management and tracking

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Logger)
local QuestTypes = require(ReplicatedStorage.QuestTypes)

local QuestService = {}
QuestService.__index = QuestService

function QuestService.new()
	local self = setmetatable({}, QuestService)
	self._playerQuests = {}  -- playerUserId -> { questId -> questData }
	self._questListeners = {}  -- playerUserId -> callbacks
	Logger:Info("QuestService", "Initializing")
	return self
end

-- Create a new quest for a player
function QuestService:CreateQuest(playerId, questTemplate)
	if not self._playerQuests[playerId] then
		self._playerQuests[playerId] = {}
	end
	
	-- Clone the quest template
	local quest = {
		id = questTemplate.id,
		name = questTemplate.name,
		description = questTemplate.description,
		category = questTemplate.category,
		difficulty = questTemplate.difficulty,
		icon = questTemplate.icon,
		state = QuestTypes.QuestState.ACTIVE,
		progress = 0,
		target = questTemplate.target,
		rewards = questTemplate.rewards,
		createdAt = os.time(),
		completedAt = nil,
		claimedAt = nil,
	}
	
	self._playerQuests[playerId][questTemplate.id] = quest
	Logger:Debug("QuestService", "Created quest for player", { playerId = playerId, questId = questTemplate.id })
	self:_notifyListeners(playerId, "quest_created", quest)
	
	return quest
end

-- Update quest progress
function QuestService:UpdateQuestProgress(playerId, questId, progress)
	if not self._playerQuests[playerId] or not self._playerQuests[playerId][questId] then
		return false
	end
	
	local quest = self._playerQuests[playerId][questId]
	quest.progress = math.min(progress, quest.target)
	
	-- Check if completed
	if quest.progress >= quest.target and quest.state == QuestTypes.QuestState.ACTIVE then
		quest.state = QuestTypes.QuestState.COMPLETED
		quest.completedAt = os.time()
		self:_notifyListeners(playerId, "quest_completed", quest)
		Logger:Info("QuestService", "Quest completed", { playerId = playerId, questId = questId })
	else
		self:_notifyListeners(playerId, "quest_progress", quest)
	end
	
	return true
end

-- Get quest for a player
function QuestService:GetQuest(playerId, questId)
	if self._playerQuests[playerId] then
		return self._playerQuests[playerId][questId]
	end
	return nil
end

-- Get all quests for a player
function QuestService:GetPlayerQuests(playerId)
	return self._playerQuests[playerId] or {}
end

-- Get active quest
function QuestService:GetActiveQuest(playerId)
	if not self._playerQuests[playerId] then
		return nil
	end
	
	for _, quest in pairs(self._playerQuests[playerId]) do
		if quest.state == QuestTypes.QuestState.ACTIVE then
			return quest
		end
	end
	return nil
end

-- Claim quest rewards
function QuestService:ClaimRewards(playerId, questId)
	if not self._playerQuests[playerId] or not self._playerQuests[playerId][questId] then
		return false
	end
	
	local quest = self._playerQuests[playerId][questId]
	if quest.state ~= QuestTypes.QuestState.COMPLETED then
		Logger:Warn("QuestService", "Attempted to claim rewards for incomplete quest", { playerId = playerId, questId = questId })
		return false
	end
	
	quest.state = QuestTypes.QuestState.CLAIMED
	quest.claimedAt = os.time()
	self:_notifyListeners(playerId, "quest_claimed", quest)
	
	Logger:Info("QuestService", "Quest rewards claimed", { playerId = playerId, questId = questId, rewards = quest.rewards })
	return true, quest.rewards
end

-- Cancel quest
function QuestService:CancelQuest(playerId, questId)
	if not self._playerQuests[playerId] or not self._playerQuests[playerId][questId] then
		return false
	end
	
	self._playerQuests[playerId][questId] = nil
	self:_notifyListeners(playerId, "quest_cancelled", { questId = questId })
	return true
end

-- Register listener for quest events
function QuestService:OnQuestEvent(playerId, callback)
	if not self._questListeners[playerId] then
		self._questListeners[playerId] = {}
	end
	table.insert(self._questListeners[playerId], callback)
end

-- Internal: Notify all listeners
function QuestService:_notifyListeners(playerId, eventType, data)
	if not self._questListeners[playerId] then
		return
	end
	
	for _, callback in pairs(self._questListeners[playerId]) do
		task.spawn(function()
			callback(eventType, data)
		end)
	end
end

-- Clear all quests for a player (on island reset, etc)
function QuestService:ClearPlayerQuests(playerId)
	self._playerQuests[playerId] = nil
end

return QuestService
