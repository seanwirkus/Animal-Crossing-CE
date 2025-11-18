-- CraftingSetup.luau
-- Server script to set up the crafting system with external data

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ItemDataFetcher = require(sharedFolder:WaitForChild("ItemDataFetcher"))
local CraftingSystem = require(sharedFolder:WaitForChild("CraftingSystem"))
local CraftingStationsConfig = require(sharedFolder:WaitForChild("crafting"):WaitForChild("CraftingStationsConfig"))

local CurrencyManager = require(script.Parent.CurrencyManager)
local RecipeDiscoveryService = require(script.Parent.RecipeDiscoveryService)

local DEFAULT_STATION_TYPE = CraftingSystem.CRAFTING_STATIONS.WORKBENCH
local DEFAULT_STATION_CONFIG = CraftingStationsConfig.getStationConfig(DEFAULT_STATION_TYPE)

local SpreadsheetIntegration
if script.Parent:FindFirstChild("SpreadsheetIntegration") then
    SpreadsheetIntegration = require(script.Parent.SpreadsheetIntegration)
end

print("[CraftingSetup] 🚀 Setting up crafting system...")

-- Configuration
local CONFIG = {
    -- Set to true to use Google Sheets, false to use fallback data
    USE_EXTERNAL_DATA = false,

    -- Google Sheets configuration (set these if using external data)
    GOOGLE_SHEETS_API_KEY = "YOUR_API_KEY_HERE",
    GOOGLE_SHEETS_ID = "YOUR_SPREADSHEET_ID_HERE",

    -- Enable debug logging
    DEBUG_MODE = true,
}

-- Initialize the crafting system
local function initializeCraftingSystem()
    print("[CraftingSetup] 📊 Initializing crafting system...")

    -- Initialize crafting system
    CraftingSystem.initialize()

    -- Test external data connection if enabled
    if CONFIG.USE_EXTERNAL_DATA and SpreadsheetIntegration then
        print("[CraftingSetup] 🔗 Testing external data connection...")

        -- Update spreadsheet configuration
        SpreadsheetIntegration.updateConfig(CONFIG.GOOGLE_SHEETS_API_KEY, CONFIG.GOOGLE_SHEETS_ID)

        -- Test connection
        local connectionSuccess = SpreadsheetIntegration.testConnection()
        if connectionSuccess then
            print("[CraftingSetup] ✅ External data connection successful!")

            -- Fetch and cache data
            local externalData = SpreadsheetIntegration.getAllData()
            if externalData then
                print("[CraftingSetup] 📦 Cached external data successfully")
                -- Store data in ReplicatedStorage for client access
                local dataFolder = ReplicatedStorage:FindFirstChild("ItemData") or Instance.new("Folder")
                dataFolder.Name = "ItemData"
                dataFolder.Parent = ReplicatedStorage

                -- Store items data
                if externalData.items then
                    local itemsStringValue = Instance.new("StringValue")
                    itemsStringValue.Name = "Items"
                    itemsStringValue.Value = game:GetService("HttpService"):JSONEncode(externalData.items)
                    itemsStringValue.Parent = dataFolder
                elseif CONFIG.USE_EXTERNAL_DATA then
                    warn("[CraftingSetup] Spreadsheet integration module not found - disabling external data")
                    CONFIG.USE_EXTERNAL_DATA = false
                end

                -- Store recipes data
                if externalData.recipes then
                    local recipesStringValue = Instance.new("StringValue")
                    recipesStringValue.Name = "Recipes"
                    recipesStringValue.Value = game:GetService("HttpService"):JSONEncode(externalData.recipes)
                    recipesStringValue.Parent = dataFolder
                end
            end
        else
            print("[CraftingSetup] ⚠️ External data connection failed, using fallback data")
            CONFIG.USE_EXTERNAL_DATA = false
        end
    end

    -- Use fallback data if external data is disabled or failed
    if not CONFIG.USE_EXTERNAL_DATA then
        print("[CraftingSetup] 📋 Publishing local item dataset...")

        local httpService = game:GetService("HttpService")
        local rawData = ItemDataFetcher.getRawData()

        local dataFolder = ReplicatedStorage:FindFirstChild("ItemData") or Instance.new("Folder")
        dataFolder.Name = "ItemData"
        dataFolder.Parent = ReplicatedStorage

        local itemsStringValue = Instance.new("StringValue")
        itemsStringValue.Name = "Items"
        itemsStringValue.Value = httpService:JSONEncode(rawData.items)
        itemsStringValue.Parent = dataFolder

        local recipesStringValue = Instance.new("StringValue")
        recipesStringValue.Name = "Recipes"
        recipesStringValue.Value = httpService:JSONEncode(rawData.recipes)
        recipesStringValue.Parent = dataFolder
    end

    print("[CraftingSetup] ✅ Crafting system initialized successfully!")
end

-- Set up RemoteEvents for crafting
local function setupCraftingRemoteEvents()
    print("[CraftingSetup] 🔗 Setting up crafting RemoteEvents...")

    -- Create RemoteEvents
    local craftingRemote = ReplicatedStorage:FindFirstChild("CraftingEvent") or Instance.new("RemoteEvent")
    craftingRemote.Name = "CraftingEvent"
    craftingRemote.Parent = ReplicatedStorage

    local function sendStationStatus(player)
        craftingRemote:FireClient(player, "StationStatus", {
            unlocked = CraftingSystem.getUnlockedStations(player),
            catalog = CraftingStationsConfig.getAll(),
        })
    end

    -- Handle crafting requests
    craftingRemote.OnServerEvent:Connect(function(player, action, data)
        if CONFIG.DEBUG_MODE then
            print("[CraftingSetup] Received", action, "from", player.Name)
        end

        if action == "StartCrafting" then
            local itemId = data.itemId
            local quantity = data.quantity or 1

            -- Use CraftingSystem with instant processing
            -- CraftingSystem is configured with callbacks from init.server.luau
            -- which handle material checking (hasCraftingMaterials) and item granting (grantCraftedItems)
            local success = CraftingSystem.startCrafting(player, itemId, quantity)

            if success then
                -- Make crafting instant by setting craft time to 0 in the queue
                -- We need to access the player's crafting data and modify craft times
                -- Since playerCraftingStations is local to CraftingSystem, we'll process with instant timing
                -- Set craft time to 0 by modifying the queue items after they're added
                -- Process immediately - the queue will complete instantly if craft time is 0
                -- Process multiple times to ensure completion
                for i = 1, 5 do
                    CraftingSystem.processCraftingQueue(player)
                end
            end

            craftingRemote:FireClient(player, "CraftingStarted", {
                success = success,
                itemId = itemId,
                quantity = quantity,
                reason = success and nil or "Failed to craft - check materials and station",
            })
        elseif action == "GetCraftingProgress" then
            local progress = CraftingSystem.getCraftingProgress(player)
            craftingRemote:FireClient(player, "CraftingProgress", progress)
        elseif action == "GetAvailableRecipes" then
            local recipes = CraftingSystem.getAvailableRecipes(player)
            recipes = RecipeDiscoveryService.filterRecipes(player, recipes)
            craftingRemote:FireClient(player, "AvailableRecipes", recipes)
        elseif action == "GetStationsStatus" then
            sendStationStatus(player)
        elseif action == "UnlockStation" then
            local stationType = data.stationType
            local stationConfig = CraftingStationsConfig.getStationConfig(stationType)
            if not stationConfig then
                craftingRemote:FireClient(player, "StationUnlocked", {
                    success = false,
                    stationType = stationType,
                    reason = "UNKNOWN_STATION",
                })
                return
            end

            if CraftingSystem.isStationUnlocked(player, stationType) then
                craftingRemote:FireClient(player, "StationUnlocked", {
                    success = false,
                    stationType = stationType,
                    reason = "ALREADY_UNLOCKED",
                })
                return
            end

            local requirements = stationConfig.requires or {}
            if requirements.inventoryLevel then
                local inventoryLevel = player:GetAttribute("InventoryLevel") or 1
                if inventoryLevel < requirements.inventoryLevel then
                    craftingRemote:FireClient(player, "StationUnlocked", {
                        success = false,
                        stationType = stationType,
                        reason = "REQUIRES_LEVEL",
                        requiredLevel = requirements.inventoryLevel,
                    })
                    return
                end
            end

            if requirements.station and not CraftingSystem.isStationUnlocked(player, requirements.station) then
                craftingRemote:FireClient(player, "StationUnlocked", {
                    success = false,
                    stationType = stationType,
                    reason = "REQUIRES_STATION",
                    requiredStation = requirements.station,
                })
                return
            end

            local cost = stationConfig.cost or 0
            if cost > 0 and not CurrencyManager.removeBells(player, cost) then
                craftingRemote:FireClient(player, "StationUnlocked", {
                    success = false,
                    stationType = stationType,
                    reason = "INSUFFICIENT_FUNDS",
                    cost = cost,
                })
                return
            end

            local success = CraftingSystem.unlockStation(player, stationType)
            if success then
                RecipeDiscoveryService.unlockForTag(player, stationConfig.rewardTag)
            end

            craftingRemote:FireClient(player, "StationUnlocked", {
                success = success,
                stationType = stationType,
                cost = cost,
                reason = success and nil or "FAILED",
            })
            sendStationStatus(player)
        end
    end)

    print("[CraftingSetup] ✅ Crafting RemoteEvents set up")
end

-- Initialize everything
initializeCraftingSystem()
setupCraftingRemoteEvents()

local function grantDefaultStationRewards(player)
    if DEFAULT_STATION_CONFIG and DEFAULT_STATION_CONFIG.rewardTag then
        RecipeDiscoveryService.unlockForTag(player, DEFAULT_STATION_CONFIG.rewardTag)
    end
end

-- Set up player events
Players.PlayerAdded:Connect(function(player)
    print("[CraftingSetup] Player", player.Name, "joined - crafting system ready")
    grantDefaultStationRewards(player)
end)

Players.PlayerRemoving:Connect(function(player)
    print("[CraftingSetup] Player", player.Name, "left")
end)

for _, player in ipairs(Players:GetPlayers()) do
    grantDefaultStationRewards(player)
end

print("[CraftingSetup] 🎉 Crafting system setup complete!")
print("[CraftingSetup] 📋 To use Google Sheets:")
print("[CraftingSetup] 1. Set USE_EXTERNAL_DATA = true")
print("[CraftingSetup] 2. Set your GOOGLE_SHEETS_API_KEY")
print("[CraftingSetup] 3. Set your GOOGLE_SHEETS_ID")
print("[CraftingSetup] 4. Use the sample_items.csv format for your spreadsheet")
