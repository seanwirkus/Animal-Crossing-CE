-- SaveSlotManager.luau
-- Manages multiple save slots for players with unlimited slots support
-- Saves ALL game data: inventory, currency, quests, island, home, settings

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SaveSlotManager = {}
SaveSlotManager.__index = SaveSlotManager

local _instance = nil

-- DataStore configuration
local DATASTORE_NAME = "ACNH_SaveSlots"
if RunService:IsStudio() then
    DATASTORE_NAME = "ACNH_SaveSlots_Dev"
end

function SaveSlotManager.new()
    if _instance then
        return _instance
    end

    local self = setmetatable({}, SaveSlotManager)

    self._datastore = DataStoreService:GetDataStore(DATASTORE_NAME)
    self._playerSlots = {} -- [userId] = {slots = {...}}

    -- References to other services (set these after initialization)
    self._currencyManager = nil
    self._playerIslandService = nil
    self._questService = nil
    self._homeBuildingService = nil
    self._playerSettingsService = nil

    -- Setup RemoteEvents
    self:_setupRemoteEvents()

    _instance = self
    print("[SaveSlotManager] ✅ Initialized with unlimited save slots support")
    return self
end

function SaveSlotManager:SetServices(services)
    -- Set references to other game services
    self._currencyManager = services.currencyManager
    self._playerIslandService = services.playerIslandService
    self._questService = services.questService
    self._homeBuildingService = services.homeBuildingService
    self._playerSettingsService = services.playerSettingsService
    print("[SaveSlotManager] ✅ Services configured")
end

function SaveSlotManager:_setupRemoteEvents()
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = ReplicatedStorage
    end

    -- GetSaveSlots - Request all save slots for a player
    local getSaveSlotsRemote = Instance.new("RemoteEvent")
    getSaveSlotsRemote.Name = "GetSaveSlots"
    getSaveSlotsRemote.Parent = remoteEventsFolder

    getSaveSlotsRemote.OnServerEvent:Connect(function(player)
        self:getSaveSlots(player)
    end)

    -- SaveSlotsResult - Send save slots data to client
    local saveSlotsResultRemote = Instance.new("RemoteEvent")
    saveSlotsResultRemote.Name = "SaveSlotsResult"
    saveSlotsResultRemote.Parent = remoteEventsFolder

    -- SaveToSlot - Save current game state to a slot
    local saveToSlotRemote = Instance.new("RemoteEvent")
    saveToSlotRemote.Name = "SaveToSlot"
    saveToSlotRemote.Parent = remoteEventsFolder

    saveToSlotRemote.OnServerEvent:Connect(function(player, slotIndex, clientData)
        self:saveToSlot(player, slotIndex, clientData)
    end)

    -- LoadFromSlot - Load game state from a slot
    local loadFromSlotRemote = Instance.new("RemoteEvent")
    loadFromSlotRemote.Name = "LoadFromSlot"
    loadFromSlotRemote.Parent = remoteEventsFolder

    loadFromSlotRemote.OnServerEvent:Connect(function(player, slotIndex)
        self:loadFromSlot(player, slotIndex)
    end)

    -- DeleteSaveSlot - Delete a save slot
    local deleteSlotRemote = Instance.new("RemoteEvent")
    deleteSlotRemote.Name = "DeleteSaveSlot"
    deleteSlotRemote.Parent = remoteEventsFolder

    deleteSlotRemote.OnServerEvent:Connect(function(player, slotIndex)
        self:deleteSlot(player, slotIndex)
    end)

    print("[SaveSlotManager] ✅ Remote events created")
end

--[[
    Save Slot Data Structure:
    {
        slots = {
            [1] = {
                name = "Save 12/28 14:30",
                timestamp = "2025-12-28 14:30:45",

                -- Currency
                bells = number,
                miles = number,

                -- Inventory
                inventorySnapshot = {...}, -- Full inventory snapshot
                inventoryCount = number,

                -- Quests
                questsData = {...},
                questsActive = {...},
                questsCompleted = number,
                questsCount = number,

                -- Island
                islandData = {...},

                -- Home
                homeData = {...},
                homeType = "Tent|SmallHouse|etc",

                -- Player Settings
                playerSettings = {...},

                -- Player Position
                playerPosition = {X, Y, Z},
            },
            [2] = {...},
            ...
        }
    }
]]

function SaveSlotManager:getSaveSlots(player)
    local userId = player.UserId

    -- Try to load from cache first
    if self._playerSlots[userId] then
        self:_sendSlotsToClient(player, self._playerSlots[userId].slots or {})
        return
    end

    -- Load from DataStore
    local success, result = pcall(function()
        return self._datastore:GetAsync(tostring(userId))
    end)

    if success and result then
        self._playerSlots[userId] = result
        self:_sendSlotsToClient(player, result.slots or {})
        print("[SaveSlotManager] ✅ Loaded", #(result.slots or {}), "slots for", player.Name)
    else
        -- No save data yet, send empty array
        self._playerSlots[userId] = {slots = {}}
        self:_sendSlotsToClient(player, {})
        print("[SaveSlotManager] ℹ️ No save slots found for", player.Name)
    end
end

function SaveSlotManager:_sendSlotsToClient(player, slots)
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then return end

    local saveSlotsResultRemote = remoteEventsFolder:FindFirstChild("SaveSlotsResult")
    if saveSlotsResultRemote then
        saveSlotsResultRemote:FireClient(player, slots)
    end
end

function SaveSlotManager:saveToSlot(player, slotIndex, clientData)
    local userId = player.UserId

    -- Collect all game data from various services
    local saveData = {
        name = clientData.name or ("Save " .. os.date("%m/%d %H:%M")),
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),

        -- Currency (from CurrencyManager)
        bells = 0,
        miles = 0,

        -- Inventory
        inventorySnapshot = nil,
        inventoryCount = 0,

        -- Quests
        questsData = {},
        questsActive = {},
        questsCompleted = 0,
        questsCount = 0,

        -- Island
        islandData = nil,

        -- Home
        homeData = nil,
        homeType = "None",

        -- Player Settings
        playerSettings = nil,

        -- Player Position
        playerPosition = clientData.playerPosition or {X = 0, Y = 0, Z = 0},
    }

    -- Collect currency data
    if self._currencyManager then
        local currencyState = self._currencyManager:GetPlayerState(player)
        if currencyState then
            saveData.bells = currencyState.bells or 0
            saveData.miles = currencyState.miles or 0
        end
    end

    -- Collect inventory data
    local inventoryStateStore = require(game:GetService("ReplicatedStorage").Shared.inventory.InventoryStateStore)
    if inventoryStateStore then
        local snapshot = inventoryStateStore.getSnapshot(player.UserId)
        if snapshot then
            saveData.inventorySnapshot = snapshot
            saveData.inventoryCount = #(snapshot.slots or {})
        end
    end

    -- Collect quest data
    if self._questService then
        local playerQuests = self._questService:GetPlayerQuests(player)
        if playerQuests then
            saveData.questsData = playerQuests
            local activeCount = 0
            local completedCount = 0
            for _, quest in pairs(playerQuests) do
                if quest.state == "ACTIVE" then
                    activeCount = activeCount + 1
                    table.insert(saveData.questsActive, quest)
                elseif quest.state == "COMPLETED" or quest.state == "CLAIMED" then
                    completedCount = completedCount + 1
                end
            end
            saveData.questsCompleted = completedCount
            saveData.questsCount = activeCount + completedCount
        end
    end

    -- Collect island data
    if self._playerIslandService then
        local islandData = self._playerIslandService:getPlayerIsland(userId)
        if islandData then
            saveData.islandData = islandData
        end
    end

    -- Collect home data
    if self._homeBuildingService then
        local homeData = self._homeBuildingService:GetPlayerHome(player)
        if homeData then
            saveData.homeData = homeData
            saveData.homeType = homeData.size or "None"
        end
    end

    -- Collect player settings
    if self._playerSettingsService then
        local settings = self._playerSettingsService:GetSettings(player)
        if settings then
            saveData.playerSettings = settings
        end
    end

    -- Load existing slots data
    if not self._playerSlots[userId] then
        self._playerSlots[userId] = {slots = {}}
    end

    local slots = self._playerSlots[userId].slots or {}

    -- If slotIndex is nil, create a new slot
    if slotIndex == nil then
        table.insert(slots, saveData)
        slotIndex = #slots
    else
        -- Update existing slot
        slots[slotIndex] = saveData
    end

    self._playerSlots[userId].slots = slots

    -- Save to DataStore
    local success, err = pcall(function()
        self._datastore:SetAsync(tostring(userId), self._playerSlots[userId])
    end)

    if success then
        print("[SaveSlotManager] ✅ Saved slot", slotIndex, "for", player.Name)
        -- Refresh client view
        self:getSaveSlots(player)
    else
        warn("[SaveSlotManager] ❌ Failed to save slot for", player.Name, ":", err)
    end
end

function SaveSlotManager:loadFromSlot(player, slotIndex)
    local userId = player.UserId

    -- Load slots from DataStore if not cached
    if not self._playerSlots[userId] then
        local success, result = pcall(function()
            return self._datastore:GetAsync(tostring(userId))
        end)

        if success and result then
            self._playerSlots[userId] = result
        else
            warn("[SaveSlotManager] ❌ No save data found for", player.Name)
            return
        end
    end

    local slots = self._playerSlots[userId].slots or {}
    local saveData = slots[slotIndex]

    if not saveData then
        warn("[SaveSlotManager] ❌ Slot", slotIndex, "not found for", player.Name)
        return
    end

    print("[SaveSlotManager] 📂 Loading slot", slotIndex, "for", player.Name)

    -- Restore currency
    if self._currencyManager and saveData.bells and saveData.miles then
        self._currencyManager:SetPlayerState(player, {
            bells = saveData.bells,
            miles = saveData.miles,
            lifetimeEarned = 0,
            lifetimeSpent = 0,
        })
    end

    -- Restore inventory
    if saveData.inventorySnapshot then
        local inventoryStateStore = require(game:GetService("ReplicatedStorage").Shared.inventory.InventoryStateStore)
        if inventoryStateStore then
            inventoryStateStore.loadSnapshot(player.UserId, saveData.inventorySnapshot)
        end
    end

    -- Restore quests
    if self._questService and saveData.questsData then
        self._questService:RestorePlayerQuests(player, saveData.questsData)
    end

    -- Restore island
    if self._playerIslandService and saveData.islandData then
        self._playerIslandService:loadIsland(userId, saveData.islandData)
    end

    -- Restore home
    if self._homeBuildingService and saveData.homeData then
        self._homeBuildingService:RestorePlayerHome(player, saveData.homeData)
    end

    -- Restore player settings
    if self._playerSettingsService and saveData.playerSettings then
        self._playerSettingsService:LoadSettings(player, saveData.playerSettings)
    end

    -- Restore player position
    if saveData.playerPosition and player.Character then
        local character = player.Character
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(
                saveData.playerPosition.X,
                saveData.playerPosition.Y,
                saveData.playerPosition.Z
            )
        end
    end

    print("[SaveSlotManager] ✅ Loaded all data from slot", slotIndex, "for", player.Name)
end

function SaveSlotManager:deleteSlot(player, slotIndex)
    local userId = player.UserId

    if not self._playerSlots[userId] then
        return
    end

    local slots = self._playerSlots[userId].slots or {}
    table.remove(slots, slotIndex)
    self._playerSlots[userId].slots = slots

    -- Save to DataStore
    local success = pcall(function()
        self._datastore:SetAsync(tostring(userId), self._playerSlots[userId])
    end)

    if success then
        print("[SaveSlotManager] 🗑️ Deleted slot", slotIndex, "for", player.Name)
        -- Refresh client view
        self:getSaveSlots(player)
    end
end

return SaveSlotManager
