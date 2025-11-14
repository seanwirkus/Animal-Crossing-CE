--[[
	PlayerSettingsService.luau
	
	Stores per-player client settings (camera sensitivity, invert look, blur intensity).
	Provides remotes for clients to load and save settings and writes them to a DataStore.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local SETTINGS_DATASTORE_NAME = "ACNH_PlayerSettings"
local REMOTE_FOLDER_NAME = "PlayerSettingsRemotes"
local GET_SETTINGS_FUNCTION = "GetSettings"
local SAVE_SETTINGS_EVENT = "SaveSettings"

local DEFAULT_SETTINGS = {
    cameraSensitivity = 1, -- Multiplier applied to Roblox camera sensitivity
    invertVertical = false,
    blurIntensity = 0.25, -- 0 → no blur, 1 → max blur defined by client
    -- Graphics quality settings
    shaderQuality = 1.0, -- 0-1, controls bloom intensity, sun rays intensity
    waterQuality = 1.0, -- 0-1, controls water effects and transparency
    grassQuality = 1.0, -- 0-1, controls particle effects like sakura, fireflies, dust
    particleDensity = 1.0, -- 0-1, controls particle emission rates
    atmosphereQuality = 1.0, -- 0-1, controls atmosphere density and haze
    bloomIntensity = 0.4, -- 0-1, separate bloom control
    colorCorrectionIntensity = 1.0, -- 0-1, controls color correction strength
}

local PlayerSettingsService = {}
PlayerSettingsService.__index = PlayerSettingsService

local function cloneDefaults()
    local clone = {}
    for key, value in pairs(DEFAULT_SETTINGS) do
        clone[key] = value
    end
    return clone
end

local function mergeSettings(candidate)
    local merged = cloneDefaults()
    if type(candidate) ~= "table" then
        return merged
    end

    for key, defaultValue in pairs(DEFAULT_SETTINGS) do
        local newValue = candidate[key]
        if typeof(newValue) == typeof(defaultValue) then
            merged[key] = newValue
        end
    end

    return merged
end

local function getOrCreateRemote(folder, className, name)
    local instance = folder:FindFirstChild(name)
    if instance and instance:IsA(className) then
        return instance
    end

    instance = Instance.new(className)
    instance.Name = name
    instance.Parent = folder
    return instance
end

function PlayerSettingsService.new()
    local self = setmetatable({}, PlayerSettingsService)

    self._datastore = DataStoreService:GetDataStore(SETTINGS_DATASTORE_NAME)
    self._playerSettings = {}

    self:_setupRemotes()
    self:_connectPlayers()

    print("[PlayerSettingsService] ✅ Initialized and ready")

    return self
end

function PlayerSettingsService:_setupRemotes()
    local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = REMOTE_FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end

    self._getSettingsFn = getOrCreateRemote(folder, "RemoteFunction", GET_SETTINGS_FUNCTION)
    self._saveSettingsEvent = getOrCreateRemote(folder, "RemoteEvent", SAVE_SETTINGS_EVENT)

    self._getSettingsFn.OnServerInvoke = function(player)
        return self:_getSettingsForPlayer(player)
    end

    self._saveSettingsEvent.OnServerEvent:Connect(function(player, payload)
        self:_handleSaveRequest(player, payload)
    end)
end

function PlayerSettingsService:_connectPlayers()
    Players.PlayerAdded:Connect(function(player)
        self:_getSettingsForPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_persistPlayerSettings(player.UserId)
        self._playerSettings[player.UserId] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:_getSettingsForPlayer(player)
    end
end

function PlayerSettingsService:_getSettingsForPlayer(player)
    local userId = player.UserId

    if self._playerSettings[userId] then
        return self._playerSettings[userId]
    end

    local success, data = pcall(function()
        return self._datastore:GetAsync(`PlayerSettings_{userId}`)
    end)

    if not success then
        warn(
            string.format(
                "[PlayerSettingsService] ⚠️ Failed to load settings for %s: %s",
                player.Name,
                tostring(data)
            )
        )
        data = nil
    end

    local merged = mergeSettings(data)
    self._playerSettings[userId] = merged

    return merged
end

function PlayerSettingsService:_persistPlayerSettings(userId)
    local settings = self._playerSettings[userId]
    if not settings then
        return
    end

    local success, err = pcall(function()
        self._datastore:SetAsync(`PlayerSettings_{userId}`, settings)
    end)

    if not success then
        warn(
            string.format(
                "[PlayerSettingsService] ⚠️ Failed to save settings for user %d: %s",
                userId,
                tostring(err)
            )
        )
    end
end

function PlayerSettingsService:_handleSaveRequest(player, payload)
    if type(payload) ~= "table" then
        return
    end

    local userId = player.UserId
    local merged = mergeSettings(payload)
    self._playerSettings[userId] = merged

    self:_persistPlayerSettings(userId)
end

local serviceSingleton

function PlayerSettingsService.init()
    if not serviceSingleton then
        serviceSingleton = PlayerSettingsService.new()
    end

    return serviceSingleton
end

return PlayerSettingsService
