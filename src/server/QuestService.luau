-- QuestService.luau - Server-side quest management and tracking

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local QuestTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestTypes"))

local QuestService = {}
QuestService.__index = QuestService

-- DataStore for quest persistence
local QuestDataStore = DataStoreService:GetDataStore("PlayerQuests_v1")

function QuestService.new()
    local self = setmetatable({}, QuestService)
    self._playerQuests = {} -- playerUserId -> { questId -> questData }
    self._questListeners = {} -- playerUserId -> callbacks
    self._remoteEvent = nil
    print("[QuestService] ✅ Initializing")
    return self
end

function QuestService:initialize()
    -- Use existing RemoteEvent (created early in server init)
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = ReplicatedStorage
    end

    self._remoteEvent = remoteEventsFolder:FindFirstChild("QuestEvent")
    if not self._remoteEvent then
        -- Fallback: create if it doesn't exist (shouldn't happen if server init runs first)
        self._remoteEvent = Instance.new("RemoteEvent")
        self._remoteEvent.Name = "QuestEvent"
        self._remoteEvent.Parent = remoteEventsFolder
    end

    -- Handle client requests
    self._remoteEvent.OnServerEvent:Connect(function(player, action, data)
        self:_handleClientRequest(player, action, data)
    end)

    -- Load quests for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:loadPlayerQuests(player)
    end

    -- Connect player events
    Players.PlayerAdded:Connect(function(player)
        self:loadPlayerQuests(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:savePlayerQuests(player)
    end)

    print("[QuestService] ✅ Initialized")
end

-- Load quests from DataStore
function QuestService:loadPlayerQuests(player)
    local userId = player.UserId
    local success, data = pcall(function()
        return QuestDataStore:GetAsync(tostring(userId))
    end)

    if success and data then
        self._playerQuests[userId] = data
        print("[QuestService] ✅ Loaded quests for", player.Name)
        self:_syncToClient(player)
    else
        self._playerQuests[userId] = {}
        print("[QuestService] No saved quests for", player.Name)
    end
end

-- Save quests to DataStore
function QuestService:savePlayerQuests(player)
    local userId = player.UserId
    if not self._playerQuests[userId] then
        return
    end

    local success, err = pcall(function()
        QuestDataStore:SetAsync(tostring(userId), self._playerQuests[userId])
    end)

    if success then
        print("[QuestService] ✅ Saved quests for", player.Name)
    else
        warn("[QuestService] ❌ Failed to save quests for", player.Name, ":", err)
    end
end

-- Create a new quest for a player
function QuestService:CreateQuest(playerId, questTemplate)
    if not self._playerQuests[playerId] then
        self._playerQuests[playerId] = {}
    end

    -- Check if quest already exists
    if self._playerQuests[playerId][questTemplate.id] then
        warn("[QuestService] Quest already exists:", questTemplate.id)
        return self._playerQuests[playerId][questTemplate.id]
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
        objectives = questTemplate.objectives or {},
        rewards = questTemplate.rewards or {},
        createdAt = os.time(),
        completedAt = nil,
        claimedAt = nil,
    }

    self._playerQuests[playerId][questTemplate.id] = quest
    print("[QuestService] ✅ Created quest:", questTemplate.id, "for player", playerId)
    self:_notifyListeners(playerId, "quest_created", quest)
    self:_syncToClient(Players:GetPlayerByUserId(playerId))

    return quest
end

-- Update quest progress
function QuestService:UpdateQuestProgress(playerId, questId, progress)
    if not self._playerQuests[playerId] or not self._playerQuests[playerId][questId] then
        return false
    end

    local quest = self._playerQuests[playerId][questId]
    if quest.state ~= QuestTypes.QuestState.ACTIVE then
        return false
    end

    quest.progress = math.min(progress, quest.target)

    -- Check if completed
    if quest.progress >= quest.target then
        quest.state = QuestTypes.QuestState.COMPLETED
        quest.completedAt = os.time()
        self:_notifyListeners(playerId, "quest_completed", quest)
        print("[QuestService] ✅ Quest completed:", questId, "for player", playerId)
    else
        self:_notifyListeners(playerId, "quest_progress", quest)
    end

    self:_syncToClient(Players:GetPlayerByUserId(playerId))
    return true
end

-- Increment quest progress by amount
function QuestService:IncrementQuestProgress(playerId, questId, amount)
    amount = amount or 1
    if not self._playerQuests[playerId] or not self._playerQuests[playerId][questId] then
        return false
    end

    local quest = self._playerQuests[playerId][questId]
    if quest.state ~= QuestTypes.QuestState.ACTIVE then
        return false
    end

    return self:UpdateQuestProgress(playerId, questId, quest.progress + amount)
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

-- Get active quests
function QuestService:GetActiveQuests(playerId)
    if not self._playerQuests[playerId] then
        return {}
    end

    local active = {}
    for _, quest in pairs(self._playerQuests[playerId]) do
        if quest.state == QuestTypes.QuestState.ACTIVE then
            table.insert(active, quest)
        end
    end
    return active
end

-- Get completed quests
function QuestService:GetCompletedQuests(playerId)
    if not self._playerQuests[playerId] then
        return {}
    end

    local completed = {}
    for _, quest in pairs(self._playerQuests[playerId]) do
        if quest.state == QuestTypes.QuestState.COMPLETED then
            table.insert(completed, quest)
        end
    end
    return completed
end

-- Claim quest rewards
function QuestService:ClaimRewards(playerId, questId)
    if not self._playerQuests[playerId] or not self._playerQuests[playerId][questId] then
        return false
    end

    local quest = self._playerQuests[playerId][questId]
    if quest.state ~= QuestTypes.QuestState.COMPLETED then
        warn("[QuestService] Attempted to claim rewards for incomplete quest:", questId)
        return false
    end

    quest.state = QuestTypes.QuestState.CLAIMED
    quest.claimedAt = os.time()
    self:_notifyListeners(playerId, "quest_claimed", quest)

    print("[QuestService] ✅ Quest rewards claimed:", questId, "for player", playerId)
    self:_syncToClient(Players:GetPlayerByUserId(playerId))
    return true, quest.rewards
end

-- Cancel quest
function QuestService:CancelQuest(playerId, questId)
    if not self._playerQuests[playerId] or not self._playerQuests[playerId][questId] then
        return false
    end

    self._playerQuests[playerId][questId] = nil
    self:_notifyListeners(playerId, "quest_cancelled", { questId = questId })
    self:_syncToClient(Players:GetPlayerByUserId(playerId))
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

-- Sync quests to client
function QuestService:_syncToClient(player)
    if not player or not self._remoteEvent then
        return
    end

    local userId = player.UserId
    local quests = self._playerQuests[userId] or {}

    -- Convert to array for client
    local questArray = {}
    for _, quest in pairs(quests) do
        table.insert(questArray, quest)
    end

    self._remoteEvent:FireClient(player, "SyncQuests", questArray)
end

-- Handle client requests
function QuestService:_handleClientRequest(player, action, data)
    if action == "RequestQuests" then
        self:_syncToClient(player)
    elseif action == "ClaimRewards" and data and data.questId then
        local success, rewards = self:ClaimRewards(player.UserId, data.questId)
        if success and rewards then
            -- Grant rewards (handled by caller)
            self._remoteEvent:FireClient(player, "RewardsClaimed", {
                questId = data.questId,
                rewards = rewards,
            })
        end
    end
end

-- Clear all quests for a player (on island reset, etc)
function QuestService:ClearPlayerQuests(playerId)
    self._playerQuests[playerId] = nil
    local player = Players:GetPlayerByUserId(playerId)
    if player then
        self:_syncToClient(player)
    end
end

return QuestService
