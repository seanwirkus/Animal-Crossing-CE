-- DailyChallengeService
-- Rotates flavorful daily challenges, tracks player progress, and hands out rewards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local DailyChallenges = require(ReplicatedStorage.Shared.DailyChallenges)
local CurrencyManager = require(script.Parent.CurrencyManager)

local DailyChallengeService = {}
DailyChallengeService.__index = DailyChallengeService

local DATASTORE_NAME = "DailyChallenges_v2"
local ChallengeDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local DEFAULT_CHALLENGE_COUNT = 5
local DEFAULT_VILLAGER_TIP_COUNT = 3

local function getTodayKey()
    local dateTable = DailyChallenges.getDateKey()
    return string.format("%04d-%03d", dateTable.year, dateTable.yday)
end

local function ensureRemoteEvent()
    local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "RemoteEvents"
        folder.Parent = ReplicatedStorage
    end

    local remote = folder:FindFirstChild("DailyChallengeEvent")
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = "DailyChallengeEvent"
        remote.Parent = folder
    end

    return remote
end

local function buildDefaultChallenges(todayKey, featuredVillager)
    local challenges = {}
    for _, template in ipairs(DailyChallenges.getDailyLineup(DEFAULT_CHALLENGE_COUNT, todayKey)) do
        local idHash = 0
        for index = 1, #template.id do
            idHash += string.byte(template.id, index)
        end
        table.insert(challenges, DailyChallenges.hydrateTemplate(template, {
            featuredVillager = featuredVillager,
            today = todayKey,
            seed = os.time() + idHash + #challenges,
        }))
    end
    return challenges
end

local function applyRewards(player, challenge)
    if challenge.rewardBells and challenge.rewardBells > 0 then
        CurrencyManager.addBells(player, challenge.rewardBells)
    end
    if challenge.rewardMiles and challenge.rewardMiles > 0 then
        CurrencyManager.addMiles(player, challenge.rewardMiles)
    end
end

local function hydrateSavedChallenge(challenge, featuredVillager)
    challenge.progress = challenge.progress or 0
    challenge.state = challenge.state or "active"
    challenge.featuredVillager = challenge.featuredVillager or featuredVillager
    if not challenge.openingMessage and challenge.villagerMessages and #challenge.villagerMessages > 0 then
        challenge.openingMessage = challenge.villagerMessages[1]
    end
    return challenge
end

local function buildVillagerTips(challenges, featuredVillager)
    local tips = {}
    for _, challenge in ipairs(challenges) do
        local message = DailyChallenges.decorateMessage(challenge, challenge.progress)
        if featuredVillager then
            message = string.format("%s 🎤 %s", featuredVillager, message)
        end
        table.insert(tips, message)
        if #tips >= DEFAULT_VILLAGER_TIP_COUNT then
            break
        end
    end
    return tips
end

function DailyChallengeService.new()
    local self = setmetatable({}, DailyChallengeService)
    self._playerData = {}
    self._remoteEvent = ensureRemoteEvent()
    self._lastSave = {}
    self._recentEventTimestamps = {}
    return self
end

function DailyChallengeService:_sync(player)
    local payload = self._playerData[player.UserId]
    if payload then
        self._remoteEvent:FireClient(player, "sync", payload)
    end
end

function DailyChallengeService:_resetForNewDay(player, todayKey)
    local featuredVillager = DailyChallenges.getFeaturedVillager(todayKey)
    local challenges = buildDefaultChallenges(todayKey, featuredVillager)
    self._playerData[player.UserId] = {
        dayKey = todayKey,
        challenges = challenges,
        villagerTips = buildVillagerTips(challenges, featuredVillager),
        featuredVillager = featuredVillager,
        streak = 0,
    }
end

function DailyChallengeService:_hydrateProfile(player, todayKey, saved)
    if not saved then
        self:_resetForNewDay(player, todayKey)
        return
    end

    if saved.dayKey ~= todayKey then
        self:_resetForNewDay(player, todayKey)
        return
    end

    local featuredVillager = saved.featuredVillager or DailyChallenges.getFeaturedVillager(todayKey)
    saved.featuredVillager = featuredVillager
    for _, challenge in ipairs(saved.challenges) do
        hydrateSavedChallenge(challenge, featuredVillager)
    end
    saved.villagerTips = saved.villagerTips or buildVillagerTips(saved.challenges, featuredVillager)
    saved.streak = saved.streak or 0
    self._playerData[player.UserId] = saved
end

function DailyChallengeService:load(player)
    local todayKey = getTodayKey()
    local success, data = pcall(function()
        return ChallengeDataStore:GetAsync(tostring(player.UserId))
    end)

    if success then
        self:_hydrateProfile(player, todayKey, data)
    else
        warn("[DailyChallengeService] Failed to load challenges for", player.Name)
        self:_resetForNewDay(player, todayKey)
    end

    self:_sync(player)
end

function DailyChallengeService:save(player)
    local data = self._playerData[player.UserId]
    if not data then
        return
    end

    local now = os.clock()
    if self._lastSave[player.UserId] and now - self._lastSave[player.UserId] < 15 then
        return
    end

    self._lastSave[player.UserId] = now

    local success, err = pcall(function()
        ChallengeDataStore:SetAsync(tostring(player.UserId), data)
    end)

    if not success then
        warn("[DailyChallengeService] Failed to save challenges for", player.Name, err)
    end
end

local function hasEventCooldown(self, playerId, eventName)
    local now = os.clock()
    self._recentEventTimestamps[playerId] = self._recentEventTimestamps[playerId] or {}
    local last = self._recentEventTimestamps[playerId][eventName]
    if last and now - last < 0.4 then
        return true
    end
    self._recentEventTimestamps[playerId][eventName] = now
    return false
end

function DailyChallengeService:_broadcastVillagerTip(player, challenge)
    local profile = self._playerData[player.UserId]
    if not profile then
        return
    end

    local message = DailyChallenges.decorateMessage(challenge, challenge.progress)
    self._remoteEvent:FireClient(player, "villager_tip", {
        message = message,
        villager = profile.featuredVillager,
        challengeId = challenge.id,
    })
end

function DailyChallengeService:_updateStreak(player, profile)
    local allClaimed = true
    for _, challenge in ipairs(profile.challenges) do
        if challenge.state ~= "claimed" then
            allClaimed = false
            break
        end
    end

    if not allClaimed then
        return
    end

    if profile.streakAwardedForDay == profile.dayKey then
        return
    end

    profile.streak = (profile.streak or 0) + 1
    profile.streakUpdatedAt = os.time()
    profile.streakAwardedForDay = profile.dayKey
    self._remoteEvent:FireClient(player, "streak", { streak = profile.streak })
end

function DailyChallengeService:recordEvent(player, eventName, amount)
    local profile = self._playerData[player.UserId]
    if not profile or hasEventCooldown(self, player.UserId, eventName) then
        return
    end

    local changed = false
    local completedNow = {}
    for _, challenge in ipairs(profile.challenges) do
        if challenge.event == eventName and challenge.state == "active" then
            challenge.progress = math.min(challenge.progress + (amount or 1), challenge.target)
            changed = true
            self:_broadcastVillagerTip(player, challenge)

            if challenge.progress >= challenge.target then
                challenge.state = "completed"
                challenge.completedAt = os.time()
                applyRewards(player, challenge)
                table.insert(completedNow, challenge.id)
            end
        end
    end

    if changed then
        self:_sync(player)
        self:save(player)
    end

    if #completedNow > 0 then
        self._remoteEvent:FireClient(player, "completed", {
            challengeIds = completedNow,
        })
    end
end

function DailyChallengeService:markClaimed(player, challengeId)
    local profile = self._playerData[player.UserId]
    if not profile then
        return
    end

    for _, challenge in ipairs(profile.challenges) do
        if challenge.id == challengeId then
            if challenge.state ~= "completed" and challenge.state ~= "claimed" then
                return
            end

            challenge.state = "claimed"
            challenge.claimedAt = os.time()
            break
        end
    end

    self:_updateStreak(player, profile)
    self:_sync(player)
    self:save(player)
end

local function selectRerollTemplate(profile, todayKey)
    local lineup = DailyChallenges.getDailyLineup(DEFAULT_CHALLENGE_COUNT * 2, todayKey)
    local usedIds = {}
    for _, existing in ipairs(profile.challenges) do
        usedIds[existing.id] = true
    end

    for _, template in ipairs(lineup) do
        if not usedIds[template.id] then
            return template
        end
    end

    return lineup[1]
end

function DailyChallengeService:_rerollSingle(player, challengeId)
    local profile = self._playerData[player.UserId]
    if not profile then
        return
    end

    local todayKey = getTodayKey()
    local featuredVillager = profile.featuredVillager or DailyChallenges.getFeaturedVillager(todayKey)
    for index, challenge in ipairs(profile.challenges) do
        if challenge.id == challengeId then
            if challenge.state ~= "active" then
                return
            end

            local replacementTemplate = selectRerollTemplate(profile, todayKey)
            profile.challenges[index] = DailyChallenges.hydrateTemplate(replacementTemplate, {
                featuredVillager = featuredVillager,
                today = todayKey,
                seed = os.time() + index + #profile.challenges,
            })
            profile.villagerTips = buildVillagerTips(profile.challenges, featuredVillager)
            break
        end
    end

    self:_sync(player)
    self:save(player)
end

function DailyChallengeService:_handleRemote(player, action, data)
    if action == "request_sync" then
        self:_sync(player)
    elseif action == "claim_challenge" and data and data.id then
        self:markClaimed(player, data.id)
    elseif action == "request_tip" and data and data.id then
        local profile = self._playerData[player.UserId]
        if profile then
            for _, challenge in ipairs(profile.challenges) do
                if challenge.id == data.id then
                    self:_broadcastVillagerTip(player, challenge)
                    break
                end
            end
        end
    elseif action == "reroll_challenge" and data and data.id then
        self:_rerollSingle(player, data.id)
    end
end

function DailyChallengeService:initialize()
    Players.PlayerAdded:Connect(function(player)
        self:load(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:save(player)
    end)

    self._remoteEvent.OnServerEvent:Connect(function(player, action, data)
        self:_handleRemote(player, action, data)
    end)

    task.spawn(function()
        while true do
            task.wait(120)
            for _, player in ipairs(Players:GetPlayers()) do
                self:save(player)
            end
        end
    end)
end

return DailyChallengeService
