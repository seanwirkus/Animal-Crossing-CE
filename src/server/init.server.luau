-- Server initialization script
-- Complete server-side inventory management

--[[
    TODO: GAME LAUNCH INTEGRATION CHECKLIST
    - [DAY 1] Integrate CurrencyManager.luau
    - [DAY 2] Integrate FishingSystem.luau
    - [DAY 3] Integrate BugSystem.luau (create file)
    - [DAY 4] Integrate ShopManager.luau (create file)
    - [DAY 6] Integrate TutorialManager.luau (create file)
    - [DAY 7] Integrate DailyRewardsSystem.luau (create file)
    - [DAY 8] Integrate GamePassManager.luau (create file)
    - [DAY 9] Integrate ProductPurchaseHandler.luau (create file)
    
    See GAME_LAUNCH_PLAN.md for full implementation timeline
]]

-- Roblox globals
local game = game
local workspace = game:GetService("Workspace")

-- Import services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

-- Create RemoteEvents folder and QuestEvent early (before client loads)
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
end

-- Create QuestEvent early so client can find it
local questEvent = remoteEventsFolder:FindFirstChild("QuestEvent")
if not questEvent then
    questEvent = Instance.new("RemoteEvent")
    questEvent.Name = "QuestEvent"
    questEvent.Parent = remoteEventsFolder
end

local AvatarKitFolder = ReplicatedStorage:FindFirstChild("AvatarKit")
if not AvatarKitFolder then
    AvatarKitFolder = Instance.new("Folder")
    AvatarKitFolder.Name = "AvatarKit"
    AvatarKitFolder.Parent = ReplicatedStorage
end

local DebugLogger = require(ReplicatedStorage.Shared.DebugLogger)
local LOG_MODULE = "ServerInit"

local function logInfo(message, context)
    DebugLogger.info(LOG_MODULE, message, context)
end

local function logDebug(message, context)
    DebugLogger.debug(LOG_MODULE, message, context)
end

local function logWarn(message, context)
    DebugLogger.warn(LOG_MODULE, message, context)
end

-- Load CurrencyManager module (it's a child of this script)
local CurrencyManager = require(script:WaitForChild("CurrencyManager"))
local FishingSystem = require(script:WaitForChild("FishingSystem"))
local BalloonSpawner = require(script:WaitForChild("BalloonSpawner"))
local NookPlaneService = require(script:WaitForChild("NookPlaneService"))
local DigMarkerSpawner = require(script:WaitForChild("DigMarkerSpawner"))
local ShovelSystem = require(script:WaitForChild("ShovelSystem"))
local TreeShakingSystem = require(script:WaitForChild("TreeShakingSystem"))
local PlayerSettingsService = require(script:WaitForChild("PlayerSettingsService"))
local DIYWorkBenchService = require(script:WaitForChild("DIYWorkBenchService"))
local _IslandSaveService = require(script:WaitForChild("IslandSaveService"))
local OnboardingService = require(script:WaitForChild("OnboardingService"))
local _HomeBuildingService = require(script:WaitForChild("HomeBuildingService"))
local PlayerIslandService = require(script:WaitForChild("PlayerIslandService"))
local BuildingService = require(script:WaitForChild("BuildingService"))
local NookConstructionService = require(script:WaitForChild("NookConstructionService"))
local QuestService = require(script:WaitForChild("QuestService"))
local QuestHandlers = require(script:WaitForChild("QuestHandlers"))
local DailyChallengeService = require(script:WaitForChild("DailyChallengeService"))
local ResourceSpawner = require(script:WaitForChild("ResourceSpawner"))
local ToolInteractionSystem = require(script:WaitForChild("ToolInteractionSystem"))
local CharacterAndToolFixes = require(ReplicatedStorage.Shared.CharacterAndToolFixes)

local questService = nil
local dailyChallengeService = nil

local toolUseRemote = nil
local toolFeedbackRemote = nil

local function ensureRemoteEvent(parent, name)
    local remote = parent:FindFirstChild(name)
    if remote and not remote:IsA("RemoteEvent") then
        remote:Destroy()
        remote = nil
    end

    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = parent
        logInfo(string.format("🔗 Created RemoteEvent '%s'", name))
    end

    return remote
end

local function fireToolFeedback(player, payload)
    if toolFeedbackRemote then
        toolFeedbackRemote:FireClient(player, payload)
    end
end

local function handleShovelDig(player, payload)
    local targetPosition = payload and payload.position
    local targetInstance = payload and payload.targetInstance
    local success, resultType, resultData, errorMessage = ShovelSystem.attemptDig(player, targetPosition, targetInstance)

    if success then
        if dailyChallengeService then
            dailyChallengeService:recordEvent(player, "dig_spot", 1)
        end
        fireToolFeedback(player, {
            toolType = "shovel",
            action = "dig_success",
            resultType = resultType or "empty",
            data = resultData,
        })
    else
        fireToolFeedback(player, {
            toolType = "shovel",
            action = "dig_failed",
            message = errorMessage or "Unable to dig here.",
        })
    end
end

local function handleFishingCast(player, payload)
    local position = payload.position
    if typeof(position) ~= "Vector3" then
        fireToolFeedback(player, {
            toolType = "fishing",
            action = "cast_failed",
            message = "Aim at water to cast.",
        })
        return
    end

    local castSuccess = FishingSystem.startCast(player, position)
    if not castSuccess then
        fireToolFeedback(player, {
            toolType = "fishing",
            action = "cast_failed",
            message = "You need to cast into water!",
        })
    end
end

local function handleFishingCatch(player)
    local caught, fishData = FishingSystem.attemptCatch(player)
    if not caught then
        fireToolFeedback(player, {
            toolType = "fishing",
            action = "catch_result",
            data = {
                success = false,
                reason = "Too early or no fish biting.",
            },
        })
    else
        if dailyChallengeService then
            dailyChallengeService:recordEvent(player, "catch_fish", 1)
        end

        -- Connect to quest system
        if QuestHandlers and fishData then
            QuestHandlers.onFishCaught(player, fishData)
        end
    end
end

local function handleAxeChop(player, payload)
    local character = player.Character
    if not character then
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    -- Find nearby tree
    local nearbyTree = nil
    local closestDistance = 15 -- Max distance to interact with tree
    local playerPosition = humanoidRootPart.Position
    
    -- Search for trees in workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local harvestType = tostring(obj:GetAttribute("HarvestType") or ""):lower()
            local resourceType = tostring(obj:GetAttribute("ResourceType") or ""):lower()
            if harvestType == "tree" or resourceType == "tree" or obj.Name:lower():find("tree") then
                local treePart = obj:FindFirstChildWhichIsA("BasePart")
                if treePart then
                    local distance = (treePart.Position - playerPosition).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        nearbyTree = obj
                    end
                end
            end
        end
    end
    
    if nearbyTree then
        -- Give wood (random amount 1-3)
        local woodCount = math.random(1, 3)
        local success, err = addItemToInventory(player, {
            itemId = "wood",
            count = woodCount,
        })
        
        if success then
            fireToolFeedback(player, {
                toolType = "axe",
                action = "chop_success",
                data = { wood = woodCount },
            })
            logInfo(string.format("🪓 %s chopped tree and got %d wood", player.Name, woodCount))
            if dailyChallengeService then
                dailyChallengeService:recordEvent(player, "chop_tree", 1)
            end
        else
            fireToolFeedback(player, {
                toolType = "axe",
                action = "chop_failed",
                message = err or "Inventory full.",
            })
        end
    else
        fireToolFeedback(player, {
            toolType = "axe",
            action = "chop_failed",
            message = "No tree nearby.",
        })
    end
end

local function handleNetSwing(player, payload)
    local character = player.Character
    if not character then
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    -- Find nearby bugs
    local nearbyBug = nil
    local closestDistance = 10 -- Max distance to catch bug
    local playerPosition = humanoidRootPart.Position
    
    -- Search for bugs in workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local harvestType = tostring(obj:GetAttribute("HarvestType") or ""):lower()
            local resourceType = tostring(obj:GetAttribute("ResourceType") or ""):lower()
            if harvestType == "bug" or resourceType == "bug" or obj.Name:lower():find("bug") then
                local bugPart = obj:FindFirstChildWhichIsA("BasePart")
                if bugPart then
                    local distance = (bugPart.Position - playerPosition).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        nearbyBug = obj
                    end
                end
            end
        end
    end
    
    if nearbyBug then
        -- Get bug ID from model (or use default)
        local bugId = nearbyBug:GetAttribute("ItemId") or "common_butterfly"
        local bugName = nearbyBug:GetAttribute("ItemName") or "Common Butterfly"
        
        -- Add bug to inventory
        local success, err = addItemToInventory(player, {
            itemId = bugId,
            count = 1,
        })
        
        if success then
            -- Remove bug from world
            nearbyBug:Destroy()

            fireToolFeedback(player, {
                toolType = "net",
                action = "catch_success",
                data = { bug = bugName },
            })
            logInfo(string.format("🦋 %s caught %s", player.Name, bugName))
            if dailyChallengeService then
                dailyChallengeService:recordEvent(player, "catch_bug", 1)
            end
        else
            fireToolFeedback(player, {
                toolType = "net",
                action = "catch_failed",
                message = err or "Inventory full.",
            })
        end
    else
        fireToolFeedback(player, {
            toolType = "net",
            action = "catch_failed",
            message = "No bug nearby.",
        })
    end
end

local function handleWateringCan(player, payload)
    local character = player.Character
    if not character then
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    -- Find nearby plants/flowers
    local nearbyPlant = nil
    local closestDistance = 8 -- Max distance to water plant
    local playerPosition = humanoidRootPart.Position
    
    -- Search for plants in workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local harvestType = tostring(obj:GetAttribute("HarvestType") or ""):lower()
            local resourceType = tostring(obj:GetAttribute("ResourceType") or ""):lower()
            if harvestType == "plant"
                or resourceType == "plant"
                or obj.Name:lower():find("flower")
                or obj.Name:lower():find("plant")
            then
                local plantPart = obj:FindFirstChildWhichIsA("BasePart")
                if plantPart then
                    local distance = (plantPart.Position - playerPosition).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        nearbyPlant = obj
                    end
                end
            end
        end
    end
    
    if nearbyPlant then
        -- Mark plant as watered
        nearbyPlant:SetAttribute("Watered", true)
        nearbyPlant:SetAttribute("WateredTime", tick())

        fireToolFeedback(player, {
            toolType = "watering_can",
            action = "water_success",
            data = { plant = nearbyPlant.Name },
        })
        logInfo(string.format("💧 %s watered %s", player.Name, nearbyPlant.Name))
        if dailyChallengeService then
            dailyChallengeService:recordEvent(player, "water_flower", 1)
        end
    else
        fireToolFeedback(player, {
            toolType = "watering_can",
            action = "water_failed",
            message = "No plant nearby.",
        })
    end
end

local function handleToolUseRequest(player, payload)
    if typeof(payload) ~= "table" then
        logWarn("Received malformed tool payload", { player = player and player.Name })
        return
    end

    local toolType = payload.toolType
    local action = payload.action

    if toolType == "shovel" and action == "dig" then
        handleShovelDig(player, payload)
    elseif toolType == "fishing" then
        if action == "cast" then
            handleFishingCast(player, payload)
        elseif action == "attempt_catch" then
            handleFishingCatch(player)
        end
    elseif toolType == "axe" and action == "chop" then
        handleAxeChop(player, payload)
    elseif toolType == "net" and action == "swing" then
        handleNetSwing(player, payload)
    elseif toolType == "watering_can" and action == "water" then
        handleWateringCan(player, payload)
    end
end

local function determineToolType(itemId: string?): string?
    if not itemId then
        return nil
    end

    local lowerId = string.lower(itemId)

    if string.find(lowerId, "shovel") then
        return "shovel"
    elseif string.find(lowerId, "fishing") or string.find(lowerId, "rod") then
        return "fishing"
    elseif string.find(lowerId, "slingshot") then
        return "slingshot"
    elseif string.find(lowerId, "axe") then
        return "axe"
    elseif string.find(lowerId, "net") then
        return "net"
    elseif string.find(lowerId, "watering") then
        return "watering_can"
    end

    return nil
end

-- Roblox types and enums
local Instance = Instance
local Enum = Enum
local Vector3 = Vector3
local Vector2 = Vector2
local CFrame = CFrame
local Color3 = Color3
local UDim2 = UDim2
local TweenInfo = TweenInfo
local tick = tick
local task = task

logInfo("✅ Animal Crossing server systems ready!")
logInfo("📊 ServerScriptService scripts will run automatically")

logInfo("🚀 Starting inventory system...")

-- Initialize digging systems (replaces HoleSpawner, FossilSpawner, BellSpawner)
DigMarkerSpawner.init()

-- Initialize shovel system (uses DigSpotManager internally)
ShovelSystem.init()

-- Connect inventory function to ShovelSystem for tree digging
ShovelSystem.setAddItemFunction(addItemToInventory)

-- Initialize character and tool fixes (scales characters, fixes tool anchoring)
logInfo("👤 Initializing character and tool fixes...")
CharacterAndToolFixes.init()

-- Initialize tree shaking system (uses Workspace.Apple template if present)
TreeShakingSystem.init(nil)

-- Initialize player settings persistence service
PlayerSettingsService.init()

-- Initialize DIY Workbench service
logInfo("🔨 Initializing DIY Workbench service...")
local workbenchService = DIYWorkBenchService.new()
workbenchService:initialize()

-- Initialize Player Island service
logInfo("🏝️ Initializing Player Island service...")
local islandService = PlayerIslandService.new()
islandService:initialize()

-- Connect HomeBuildingService to PlayerIslandService
logInfo("🏠 Connecting HomeBuildingService to PlayerIslandService...")
_HomeBuildingService:SetPlayerIslandService(islandService)
NookConstructionService:SetPlayerIslandService(islandService)

-- Connect HomeBuildingService to CurrencyManager
logInfo("🏠 Connecting HomeBuildingService to CurrencyManager...")
_HomeBuildingService:SetCurrencyManager(CurrencyManager)

-- Connect HomeBuildingService to Inventory system (will be done after functions are defined)

-- Initialize Onboarding/Tutorial service
logInfo("📚 Initializing Onboarding service...")
local onboardingService = OnboardingService.new()
onboardingService:initialize(islandService, _HomeBuildingService, nil, CurrencyManager)

-- Export to _G for OnboardingTrigger to access
_G.onboardingService = onboardingService

-- Create RemoteEvent
local inventoryRemote = ReplicatedStorage:FindFirstChild("InventoryEvent") or Instance.new("RemoteEvent")
inventoryRemote.Name = "InventoryEvent"
inventoryRemote.Parent = ReplicatedStorage

-- Create BalloonHit RemoteEvent for balloon popping
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
end

local balloonHitRemote = remoteEventsFolder:FindFirstChild("BalloonHit") or Instance.new("RemoteEvent")
balloonHitRemote.Name = "BalloonHit"
balloonHitRemote.Parent = remoteEventsFolder

local toolEventsFolder = remoteEventsFolder:FindFirstChild("ToolEvents")
if not toolEventsFolder then
    toolEventsFolder = Instance.new("Folder")
    toolEventsFolder.Name = "ToolEvents"
    toolEventsFolder.Parent = remoteEventsFolder
end

toolUseRemote = ensureRemoteEvent(toolEventsFolder, "ToolUse")
toolFeedbackRemote = ensureRemoteEvent(toolEventsFolder, "ToolFeedback")

if toolUseRemote then
    toolUseRemote.OnServerEvent:Connect(handleToolUseRequest)
end

FishingSystem.setFeedbackCallback(function(player, action, data)
    fireToolFeedback(player, {
        toolType = "fishing",
        action = action,
        data = data,
    })
end)

-- Create BindableEvent for balloon present drops
local balloonPresentDropped = Instance.new("BindableEvent")
balloonPresentDropped.Name = "BalloonPresentDropped"
balloonPresentDropped.Parent = ReplicatedStorage

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local SpriteConfig = require(sharedFolder:WaitForChild("SpriteConfig"))
local ItemDataFetcher = require(sharedFolder:WaitForChild("ItemDataFetcher"))
local CraftingSystem = require(sharedFolder:WaitForChild("CraftingSystem"))
local CraftingStationsConfig = require(sharedFolder:WaitForChild("crafting"):WaitForChild("CraftingStationsConfig"))
local InventoryDomain = require(sharedFolder:WaitForChild("inventory"))
local InventoryUpgrades = require(sharedFolder:WaitForChild("inventory"):WaitForChild("InventoryUpgrades"))

-- Safely require RecipeDiscoveryService with fallback
local RecipeDiscoveryServiceModule = script.Parent:FindFirstChild("RecipeDiscoveryService")
if not RecipeDiscoveryServiceModule then
    -- Try waiting with a timeout
    RecipeDiscoveryServiceModule = script.Parent:WaitForChild("RecipeDiscoveryService", 5)
end
local RecipeDiscoveryService = RecipeDiscoveryServiceModule and require(RecipeDiscoveryServiceModule) or nil
if not RecipeDiscoveryService then
    warn("[ServerInit] ⚠️ RecipeDiscoveryService not found - creating stub")
    RecipeDiscoveryService = {
        init = function() end,
        unlockForInventoryLevel = function() end,
        unlockForTag = function() end,
        filterRecipes = function(player, recipes) return recipes end,
    }
end

local ToolObjects = require(sharedFolder:WaitForChild("ToolObjects"))

local InventoryConstants = InventoryDomain.Constants
local InventorySchemas = InventoryDomain.Schemas
local InventoryValidation = InventoryDomain.Validation
local inventoryAdapterRegistry = InventoryDomain.newAdapterRegistry()
inventoryAdapterRegistry:registerLegacyAdapter(
    InventoryConstants.LEGACY_DATASET_ID,
    InventoryDomain.AdapterClass.defaultLegacyAdapter
)

-- Player inventory storage
local playerInventories = {}

-- DataStore for inventory persistence
local InventoryDataStore = DataStoreService:GetDataStore("PlayerInventories")

-- Player currency storage
local playerCurrencyStates = {}

RecipeDiscoveryService.init()

local function updateInventoryAttributes(player: Player?, inventory)
    if not player or not inventory then
        return
    end

    local level = inventory.inventoryLevel or STARTING_INVENTORY_LEVEL
    player:SetAttribute("InventoryLevel", level)
    player:SetAttribute("InventoryMaxSlots", inventory.maxSlots or InventoryConstants.getMaxSlotsFromLevel(level))
end
local lastInventorySave = 0

local CurrencyDataStore = DataStoreService:GetDataStore("PlayerCurrency")

local DEFAULT_CURRENCY_STATE = {
    bells = 1000,
    miles = 0,
    lifetimeEarned = 0,
    lifetimeSpent = 0,
}

local function createDefaultCurrencyState()
    return {
        bells = DEFAULT_CURRENCY_STATE.bells,
        miles = DEFAULT_CURRENCY_STATE.miles,
        lifetimeEarned = DEFAULT_CURRENCY_STATE.lifetimeEarned,
        lifetimeSpent = DEFAULT_CURRENCY_STATE.lifetimeSpent,
    }
end

local function sanitizeCurrencyState(state)
    local sanitized = createDefaultCurrencyState()
    if typeof(state) == "table" then
        if state.bells ~= nil then
            sanitized.bells = math.max(0, math.floor(tonumber(state.bells) or sanitized.bells))
        end
        if state.miles ~= nil then
            sanitized.miles = math.max(0, math.floor(tonumber(state.miles) or sanitized.miles))
        end
        if state.lifetimeEarned ~= nil then
            sanitized.lifetimeEarned =
                math.max(0, math.floor(tonumber(state.lifetimeEarned) or sanitized.lifetimeEarned))
        end
        if state.lifetimeSpent ~= nil then
            sanitized.lifetimeSpent = math.max(0, math.floor(tonumber(state.lifetimeSpent) or sanitized.lifetimeSpent))
        end
    end

    return sanitized
end

local function loadPlayerCurrency(player)
    local userId = player.UserId
    local success, data = pcall(function()
        return CurrencyDataStore:GetAsync(tostring(userId))
    end)

    if not success then
        warn("[Server] ❌ Failed to load currency for", player.Name, ":", data)
        return createDefaultCurrencyState()
    end

    if not data then
        return createDefaultCurrencyState()
    end

    return sanitizeCurrencyState(data)
end

local function savePlayerCurrency(player, state)
    if not player then
        return
    end

    local userId = player.UserId
    local currencyState = state or playerCurrencyStates[userId]
    if not currencyState then
        return
    end

    local payload = {
        bells = currencyState.bells or 0,
        miles = currencyState.miles or 0,
        lifetimeEarned = currencyState.lifetimeEarned or 0,
        lifetimeSpent = currencyState.lifetimeSpent or 0,
    }

    local success, err = pcall(function()
        CurrencyDataStore:SetAsync(tostring(userId), payload)
    end)

    if not success then
        warn("[Server] ❌ Failed to save currency for", player.Name, ":", err)
    end
end

CurrencyManager.configure({
    playerCurrencyTable = playerCurrencyStates,
    saveCallback = savePlayerCurrency,
    createDefaultState = createDefaultCurrencyState,
})

-- Start with level 1 inventory (10 slots)
local STARTING_INVENTORY_LEVEL = InventoryConstants.STARTING_INVENTORY_LEVEL
local MAX_SLOTS = InventoryConstants.getMaxSlotsFromLevel(STARTING_INVENTORY_LEVEL)
local DEFAULT_STATION_TYPE = CraftingSystem.CRAFTING_STATIONS.WORKBENCH
local DEFAULT_STATION_REWARD_TAG = (function()
    local config = CraftingStationsConfig.getStationConfig(DEFAULT_STATION_TYPE)
    return config and config.rewardTag or nil
end)()

-- World item storage - tracks all dropped items
local worldItems = {}
local nextItemId = 1

local ItemData = ItemDataFetcher.getFallbackData()
local DisplayItems = ItemDataFetcher.getDisplayItemMap()

-- Bell Bag system configuration (ACNH Nookipedia values)
-- Small Bell Bag: 1,000 bells
-- Bell Bag (Medium): 10,000 bells
-- Large Bell Bag: 99,000 bells
local BELL_BAG_VALUES = {
    small = 1000,   -- BellBagSmall contains 1,000 bells
    medium = 5000,  -- BellBagMedium contains 5,000 bells
    large = 10000,  -- BellBagLarge contains 10,000 bells
}

local BELL_BAG_THRESHOLDS = {
    small = 5000,   -- Items worth less than 5,000 bells = BellBagSmall
    medium = 50000, -- Items worth 5,000-50,000 bells = BellBagMedium
    -- Items worth more than 50,000 bells = BellBagLarge
}

local SPECIAL_BELL_BAG_ITEMS = {
    bell_bag_small = { value = BELL_BAG_VALUES.small, model = "BellBagSmall" },
    bell_bag_med = { value = BELL_BAG_VALUES.medium, model = "BellBagMedium" },
    bell_bag_medium = { value = BELL_BAG_VALUES.medium, model = "BellBagMedium" },
    bell_bag_large = { value = BELL_BAG_VALUES.large, model = "BellBagLarge" },
}

-- Get the appropriate bell bag model name based on item sell price
local function getBellBagModelName(itemSellPrice, itemCount)
    local totalValue = itemSellPrice * itemCount

    if totalValue < BELL_BAG_THRESHOLDS.small then
        return "BellBagSmall"
    elseif totalValue < BELL_BAG_THRESHOLDS.medium then
        return "BellBagMedium"
    else
        return "BellBagLarge"
    end
end

-- Get the fixed ACNH bell value for a bell bag type
local function getBellBagValue(bellBagModelName)
    if bellBagModelName == "BellBagSmall" then
        return BELL_BAG_VALUES.small -- 1,000 bells
    elseif bellBagModelName == "BellBagMedium" then
        return BELL_BAG_VALUES.medium -- 10,000 bells
    else
        return BELL_BAG_VALUES.large -- 99,000 bells
    end
end

-- Check if item should spawn as a bell bag
-- Returns: shouldSpawn (boolean), totalValue (number or nil), bellBagType (string or nil)
local function shouldSpawnAsBellBag(itemId, count)
    local quantity = math.max(1, count or 1)
    local specialBag = SPECIAL_BELL_BAG_ITEMS[itemId]
    if specialBag then
        return true, specialBag.value * quantity, specialBag.model
    end

    local item = ItemData[itemId]
    if not item then
        return false, nil, nil
    end

    -- Get sell price (try multiple field names)
    local sellPrice = item.sell or item.sell_price or item.sellPrice
    if not sellPrice or sellPrice <= 0 then
        return false, nil, nil
    end

    -- Calculate total value to determine bag type
    local totalValue = sellPrice * quantity
    local bellBagType = getBellBagModelName(sellPrice, count)

    -- Use fixed ACNH bell values instead of item sell price
    local fixedBellValue = getBellBagValue(bellBagType)

    return true, fixedBellValue, bellBagType
end

-- Load 3D model from ReplicatedStorage by itemId (checks various naming patterns)
local function loadItem3DModel(itemId)
    local workspaceRoot = game:GetService("Workspace")

    -- Convert itemId to various naming formats
    local function toCamelCase(str)
        -- Convert "bell_bag_small" -> "BellBagSmall"
        local parts = {}
        for part in str:gmatch("[^_]+") do
            table.insert(parts, part:sub(1, 1):upper() .. part:sub(2):lower())
        end
        return table.concat(parts)
    end

    -- Try exact match first
    local exactMatch = ReplicatedStorage:FindFirstChild(itemId)
    if exactMatch and exactMatch:IsA("Model") then
        logInfo("✅ Found 3D model (exact match)", { itemId = itemId })
        return exactMatch:Clone()
    end

    -- Try CamelCase version (e.g., "bell_bag_small" -> "BellBagSmall")
    local camelCaseName = toCamelCase(itemId)
    local camelMatch = ReplicatedStorage:FindFirstChild(camelCaseName)
    if camelMatch and camelMatch:IsA("Model") then
        logInfo("✅ Found 3D model (CamelCase)", { modelName = camelCaseName, itemId = itemId })
        return camelMatch:Clone()
    end

    -- Try case-insensitive search
    local lowerItemId = string.lower(itemId)
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("Model") and string.lower(child.Name) == lowerItemId then
            logInfo("✅ Found 3D model (case-insensitive)", { modelName = child.Name, itemId = itemId })
            return child:Clone()
        end
    end

    -- Try partial match (e.g., "bell_bag_small" matches "BellBagSmall")
    local itemIdParts = {}
    for part in itemId:gmatch("[^_]+") do
        table.insert(itemIdParts, string.lower(part))
    end

    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("Model") then
            local childLower = string.lower(child.Name)
            -- Check if all parts of itemId are found in model name
            local allPartsMatch = true
            for _, part in ipairs(itemIdParts) do
                if not childLower:find(part, 1, true) then
                    allPartsMatch = false
                    break
                end
            end
            if allPartsMatch and #itemIdParts > 0 then
                logInfo("✅ Found 3D model (partial match)", { modelName = child.Name, itemId = itemId })
                return child:Clone()
            end
        end
    end

    local workspaceMatch = workspaceRoot:FindFirstChild(itemId) or workspaceRoot:FindFirstChild(camelCaseName)
    if workspaceMatch then
        if workspaceMatch:IsA("Model") then
            logInfo("✅ Found 3D model in Workspace", { modelName = workspaceMatch.Name, itemId = itemId })
            return workspaceMatch:Clone()
        elseif workspaceMatch:IsA("BasePart") then
            local wrapper = Instance.new("Model")
            wrapper.Name = workspaceMatch.Name
            local partClone = workspaceMatch:Clone()
            partClone.Parent = wrapper
            wrapper.PrimaryPart = partClone
            logInfo("✅ Wrapped Workspace part as model", { modelName = workspaceMatch.Name, itemId = itemId })
            return wrapper
        end
    end

    return nil
end

-- Load bell bag model from ReplicatedStorage
local function loadBellBagModel(modelName)
    -- Try exact match first
    local bellBagAsset = ReplicatedStorage:FindFirstChild(modelName)
    if bellBagAsset and bellBagAsset:IsA("Model") then
        logInfo("✅ Found bell bag model", { modelName = modelName })
        return bellBagAsset:Clone()
    end

    -- Try case-insensitive search
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("Model") and string.lower(child.Name) == string.lower(modelName) then
            logInfo("✅ Found bell bag model (case-insensitive)", { modelName = child.Name })
            return child:Clone()
        end
    end

    -- Try partial match (e.g., "BellBagMed" -> "BellBagMedium")
    local lowerName = string.lower(modelName)
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("Model") then
            local childLower = string.lower(child.Name)
            -- Check if model name contains the search term or vice versa
            if childLower:find(lowerName, 1, true) or lowerName:find(childLower, 1, true) then
                if childLower:find("bell") and childLower:find("bag") then
                    logInfo("✅ Found bell bag model (partial match)", { modelName = child.Name, search = modelName })
                    return child:Clone()
                end
            end
        end
    end

    -- Try common variations
    local variations = {
        ["BellBagMed"] = { "BellBagMedium", "BellBag_Medium", "BellBagMedium_Model" },
        ["BellBagSmall"] = { "BellBag_Small", "BellBagSmall_Model", "SmallBellBag" },
        ["BellBagLarge"] = { "BellBag_Large", "BellBagLarge_Model", "LargeBellBag" },
    }

    if variations[modelName] then
        for _, variation in ipairs(variations[modelName]) do
            local variant = ReplicatedStorage:FindFirstChild(variation)
            if variant and variant:IsA("Model") then
                logInfo("✅ Found bell bag model (variation)", { modelName = variation, search = modelName })
                return variant:Clone()
            end
        end
    end

    logWarn("Bell bag model not found in ReplicatedStorage", { modelName = modelName })
    logWarn("Available models in ReplicatedStorage", { modelCount = #ReplicatedStorage:GetChildren() })
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("Model") then
            logWarn("Found model", { modelName = child.Name })
        end
    end
    return nil
end

local function getInventoryForPlayer(player)
    return playerInventories[player.UserId]
end

local function buildSnapshotFromState(slots, maxSlots)
    local snapshot = InventorySchemas.createSnapshot({
        maxSlots = maxSlots or MAX_SLOTS,
        source = "server-runtime",
    })

    if slots then
        for index = 1, snapshot.maxSlots do
            local slot = slots[index]
            if slot and slot.itemId and slot.count and slot.count > 0 then
                snapshot.slots[index] = InventorySchemas.createSlotFromStack(index, {
                    id = slot.itemId,
                    count = slot.count,
                })
            end
        end
    end

    return snapshot
end

-- Initialize player inventory
local function initializePlayerInventory(player)
    -- Start with empty inventory (use debug GUI to add items)
    local _starterItems = {}

    -- Start with level 1 inventory (10 slots)
    local inventoryLevel = STARTING_INVENTORY_LEVEL
    local maxSlots = InventoryConstants.getMaxSlotsFromLevel(inventoryLevel)

    local slots = {}
    for i = 1, maxSlots do
        slots[i] = nil
    end

    local snapshot = buildSnapshotFromState(slots, maxSlots)
    playerInventories[player.UserId] = {
        slots = slots,
        maxSlots = maxSlots,
        inventoryLevel = inventoryLevel,
        snapshot = snapshot,
        legacyPayload = inventoryAdapterRegistry:serializeForLegacy(InventoryConstants.LEGACY_DATASET_ID, snapshot),
    }

    logInfo("✅ Initialized empty inventory", { player = player.Name, level = inventoryLevel, slots = maxSlots })
    updateInventoryAttributes(player, playerInventories[player.UserId])
end

local function decodeLegacyPayload(payload)
    if typeof(payload) == "string" then
        local ok, result = pcall(function()
            return HttpService:JSONDecode(payload)
        end)
        if not ok then
            warn("[Server] Failed to decode legacy payload JSON:", result)
            return nil
        end
        return result
    end

    return payload
end

local function applySnapshotToInventory(inventory, snapshot)
    if not inventory or not snapshot then
        return
    end

    inventory.maxSlots = snapshot.maxSlots
    for index = 1, snapshot.maxSlots do
        local slot = snapshot.slots[index]
        local stack = slot and slot.stack
        if stack and stack.id ~= "" and stack.count and stack.count > 0 then
            inventory.slots[index] = {
                itemId = stack.id,
                count = stack.count,
                metadata = stack.metadata,
            }
        else
            inventory.slots[index] = nil
        end
    end

    if #inventory.slots > snapshot.maxSlots then
        for index = snapshot.maxSlots + 1, #inventory.slots do
            inventory.slots[index] = nil
        end
    end

    inventory.snapshot = snapshot
    inventory.legacyPayload =
        inventoryAdapterRegistry:serializeForLegacy(InventoryConstants.LEGACY_DATASET_ID, snapshot)
end

local function hydrateInventoryFromLegacy(inventory, payload, options)
    if not inventory or not payload then
        return
    end

    payload = decodeLegacyPayload(payload)
    if not payload then
        return
    end

    local success, snapshot = pcall(function()
        return inventoryAdapterRegistry:convertLegacySnapshot(InventoryConstants.LEGACY_DATASET_ID, payload, options)
    end)

    if not success then
        warn("[Server] Failed to hydrate inventory from legacy payload:", snapshot)
        return
    end

    applySnapshotToInventory(inventory, snapshot)
end

local function cloneSlots(slots, maxSlots)
    local snapshot = buildSnapshotFromState(slots, maxSlots)
    local ok, reason = InventoryValidation.validateSnapshot(snapshot)
    if not ok then
        warn("[Server] Inventory snapshot validation failed:", reason)
    end

    local serialized = {}
    -- Always include all slot indices to provide a full snapshot to clients.
    -- Use an empty table {} to represent an empty slot (nil keys are dropped over the wire).
    for index = 1, snapshot.maxSlots do
        local slot = snapshot.slots[index]
        local stack = slot and slot.stack
        if stack and stack.id and stack.count and stack.count > 0 then
            serialized[index] = {
                itemId = stack.id,
                count = stack.count,
            }
        else
            -- Represent empty slot with explicit shape so Luau typechecker and clients see a consistent shape.
            serialized[index] = {
                itemId = "",
                count = 0,
            }
        end
    end

    return serialized, snapshot
end

local function countFilledSlots(slots)
    local count = 0
    for index = 1, MAX_SLOTS do
        if slots[index] then
            count = count + 1
        end
    end
    return count
end

local function totalCountForItem(inventory, itemId)
    if not inventory or not itemId then
        return 0
    end

    local total = 0
    for index = 1, inventory.maxSlots or MAX_SLOTS do
        local slot = inventory.slots[index]
        if slot and slot.itemId == itemId then
            total = total + slot.count
        end
    end
    return total
end

-- Resolve an item's max stack size from slot metadata or item data.
-- Falls back to 99 if not specified.
local function getMaxStackForItem(itemId, slot)
    if slot and typeof(slot) == "table" and slot.maxStack then
        return slot.maxStack
    end
    local ok, itemData = pcall(function()
        return ItemDataFetcher.getItem(itemId)
    end)
    if ok and itemData then
        -- Support multiple possible field names in data
        return itemData.maxStack or itemData.stack or itemData.stackSize or InventoryConstants.DEFAULT_MAX_STACK
    end
    return InventoryConstants.DEFAULT_MAX_STACK
end

local function cloneMetadataTable(metadata)
    if typeof(metadata) ~= "table" then
        return nil
    end

    return table.clone(metadata)
end

-- Forward declarations
local syncInventoryToClient
local savePlayerInventory

local function addItemToInventory(player, payload, count, maxStack, metadata)
    if not player then
        return false, "invalid-player"
    end

    local inventory = getInventoryForPlayer(player)
    if not inventory then
        return false, "inventory-unavailable"
    end

    local itemId
    local options

    if typeof(payload) == "table" then
        options = payload
        itemId = options.itemId
        count = options.count
        maxStack = options.maxStack
        metadata = options.metadata
    else
        itemId = payload
    end

    if typeof(itemId) ~= "string" then
        return false, "invalid-item"
    end

    local itemData = ItemDataFetcher.getItem(itemId)
    if not itemData then
        return false, "unknown-item"
    end

    count = math.max(1, math.floor(tonumber(count) or 1))
    local resolvedMaxStack
    if typeof(maxStack) == "number" then
        resolvedMaxStack = math.max(1, math.floor(maxStack))
    else
        resolvedMaxStack = getMaxStackForItem(itemId)
    end

    local metadataTable = cloneMetadataTable(metadata)

    local slots = inventory.slots
    local remaining = count
    local added = false

    for index = 1, inventory.maxSlots or MAX_SLOTS do
        local slot = slots[index]
        if slot and slot.itemId == itemId then
            local slotMax = slot.maxStack or resolvedMaxStack
            local space = math.max(0, slotMax - slot.count)
            if space > 0 then
                local toAdd = math.min(space, remaining)
                slot.count = slot.count + toAdd
                slot.maxStack = slotMax
                if metadataTable then
                    slot.metadata = slot.metadata or {}
                    for key, value in pairs(metadataTable) do
                        slot.metadata[key] = value
                    end
                end
                remaining = remaining - toAdd
                added = true
                if remaining <= 0 then
                    break
                end
            end
        end
    end

    if remaining > 0 then
        for index = 1, inventory.maxSlots or MAX_SLOTS do
            if not slots[index] then
                local toAdd = math.min(resolvedMaxStack, remaining)
                local newSlot = {
                    itemId = itemId,
                    count = toAdd,
                    maxStack = resolvedMaxStack,
                }
                if metadataTable then
                    newSlot.metadata = cloneMetadataTable(metadataTable)
                end
                slots[index] = newSlot
                remaining = remaining - toAdd
                added = true
                if remaining <= 0 then
                    break
                end
            end
        end
    end

    if not added or remaining > 0 then
        return false, "inventory-full"
    end

    syncInventoryToClient(player)
    savePlayerInventory(player)

    return true
end

local STARTER_KIT_ITEM_IDS = {
    ["flimsy-axe"] = true,
    ["flimsy-shovel"] = true,
    ["flimsy-pickaxe"] = true,
    ["flimsy-net"] = true,
    ["flimsy-fishing-rod"] = true,
    axe = true,
    shovel = true,
    net = true,
    ["fishing-rod"] = true,
}

local function hasStarterKit(player)
    local inventory = playerInventories[player.UserId]
    if not inventory then
        return false
    end

    for _, slot in ipairs(inventory.slots or {}) do
        if slot and slot.itemId and STARTER_KIT_ITEM_IDS[slot.itemId] then
            return true
        end
    end

    return false
end

local function hasCraftingMaterials(player, materials, quantity)
    local inventory = getInventoryForPlayer(player)
    if not inventory then
        return false
    end

    quantity = quantity or 1

    for _, requirement in ipairs(materials or {}) do
        local needed = (requirement.count or 1) * quantity
        if totalCountForItem(inventory, requirement.itemId) < needed then
            return false
        end
    end

    return true
end

-- Save player inventory to DataStore
function savePlayerInventory(player)
    local userId = player.UserId
    local inventory = playerInventories[userId]
    if not inventory then
        return
    end

    -- Build serializable inventory data
    local serialized, _snapshot = cloneSlots(inventory.slots, inventory.maxSlots)
    local inventoryData = {
        slots = serialized,
        maxSlots = inventory.maxSlots,
        inventoryLevel = inventory.inventoryLevel or STARTING_INVENTORY_LEVEL,
        legacyPayload = inventory.legacyPayload,
    }

    -- Save to DataStore
    local success, err = pcall(function()
        InventoryDataStore:SetAsync(tostring(userId), inventoryData)
    end)

    if success then
        logInfo("✅ Saved inventory", { player = player.Name })
    else
        logWarn("Failed to save inventory", { player = player.Name, error = err })
    end
end

-- Load player inventory from DataStore
local function loadPlayerInventory(player)
    local userId = player.UserId

    local success, data = pcall(function()
        return InventoryDataStore:GetAsync(tostring(userId))
    end)

    if not success then
        warn("[Server] ❌ Failed to load inventory for", player.Name, ":", data)
        return nil
    end

    if not data then
        logInfo("No saved inventory found - starting fresh", { player = player.Name })
        return nil
    end

    logInfo("✅ Loaded saved inventory", { player = player.Name })
    return data
end

function syncInventoryToClient(player)
    local inventory = playerInventories[player.UserId]
    if not inventory then
        return
    end

    local serializedSlots, snapshot = cloneSlots(inventory.slots, inventory.maxSlots)
    inventory.snapshot = snapshot
    inventory.legacyPayload =
        inventoryAdapterRegistry:serializeForLegacy(InventoryConstants.LEGACY_DATASET_ID, snapshot)

    -- Calculate inventory level from maxSlots if not stored
    local inventoryLevel = inventory.inventoryLevel or InventoryConstants.getLevelFromMaxSlots(inventory.maxSlots)

    inventoryRemote:FireClient(player, "SyncInventory", {
        maxSlots = inventory.maxSlots or MAX_SLOTS,
        inventoryLevel = inventoryLevel,
        slots = serializedSlots,
    })

    updateInventoryAttributes(player, inventory)
end

local function consumeCraftingMaterials(player, materials, quantity)
    local inventory = getInventoryForPlayer(player)
    if not inventory then
        return false
    end

    quantity = quantity or 1

    if not hasCraftingMaterials(player, materials, quantity) then
        return false
    end

    for _, requirement in ipairs(materials or {}) do
        local remaining = (requirement.count or 1) * quantity
        for index = 1, inventory.maxSlots or MAX_SLOTS do
            local slot = inventory.slots[index]
            if slot and slot.itemId == requirement.itemId then
                local toRemove = math.min(slot.count, remaining)
                slot.count = slot.count - toRemove
                remaining = remaining - toRemove
                if slot.count <= 0 then
                    inventory.slots[index] = nil
                end
                if remaining <= 0 then
                    break
                end
            end
        end

        if remaining > 0 then
            return false
        end
    end

    syncInventoryToClient(player)
    -- Auto-save after inventory changes
    savePlayerInventory(player)
    return true
end

local function buildUpgradePayload(player: Player, inventory)
    local level = inventory.inventoryLevel or STARTING_INVENTORY_LEVEL
    local bells = CurrencyManager.getBells(player)
    return InventoryUpgrades.buildUpgradePayload(level, bells)
end

local function replayRecipeDiscoveries(player: Player, inventory, savedData)
    if not player or not inventory then
        return
    end

    local currentLevel = math.max(STARTING_INVENTORY_LEVEL, inventory.inventoryLevel or STARTING_INVENTORY_LEVEL)
    local maxConfigLevel = InventoryUpgrades.getMaxLevel()
    local levelCap = math.min(currentLevel, maxConfigLevel)
    for level = STARTING_INVENTORY_LEVEL + 1, levelCap do
        RecipeDiscoveryService.unlockForInventoryLevel(player, level)
    end

    if DEFAULT_STATION_REWARD_TAG then
        RecipeDiscoveryService.unlockForTag(player, DEFAULT_STATION_REWARD_TAG)
    end

    if savedData then
        local tags = nil
        if typeof(savedData.unlockedStationTags) == "table" then
            tags = savedData.unlockedStationTags
        elseif typeof(savedData.unlockedStations) == "table" then
            tags = {}
            for _, stationId in ipairs(savedData.unlockedStations) do
                if typeof(stationId) == "string" then
                    local config = CraftingStationsConfig.getStationConfig(stationId)
                    if config and config.rewardTag then
                        table.insert(tags, config.rewardTag)
                    end
                end
            end
        end

        if typeof(tags) == "table" then
            for _, tag in ipairs(tags) do
                if typeof(tag) == "string" then
                    RecipeDiscoveryService.unlockForTag(player, tag)
                end
            end
        end
    end
end

local function attemptInventoryUpgrade(player: Player, inventory)
    local currentLevel = inventory.inventoryLevel or STARTING_INVENTORY_LEVEL
    local nextConfig = InventoryUpgrades.getNextConfig(currentLevel)
    if not nextConfig then
        return false, buildUpgradePayload(player, inventory), "MAX_LEVEL"
    end

    local cost = nextConfig.cost or 0
    if cost > 0 then
        local success = CurrencyManager.removeBells(player, cost)
        if not success then
            return false, buildUpgradePayload(player, inventory), "INSUFFICIENT_FUNDS"
        end
    end

    inventory.inventoryLevel = nextConfig.level
    inventory.maxSlots = InventoryConstants.getMaxSlotsFromLevel(nextConfig.level)
    inventory.slots = inventory.slots or {}

    updateInventoryAttributes(player, inventory)
    RecipeDiscoveryService.unlockForInventoryLevel(player, nextConfig.level)

    return true, buildUpgradePayload(player, inventory), nil
end

local function grantCraftedItems(player, craftedItems)
    local inventory = getInventoryForPlayer(player)
    if not inventory then
        return
    end

    for _, itemId in ipairs(craftedItems or {}) do
        local added = false
        for index = 1, inventory.maxSlots or MAX_SLOTS do
            local slot = inventory.slots[index]
            if slot and slot.itemId == itemId then
                slot.count = slot.count + 1
                added = true
                break
            elseif not slot then
                inventory.slots[index] = { itemId = itemId, count = 1 }
                added = true
                break
            end
        end

        if not added then
            warn("[Server] Inventory full - crafted item", itemId, "could not be added")
        else
            -- Connect to quest system
            if QuestHandlers then
                QuestHandlers.onItemCrafted(player, itemId)
            end
        end
    end

    syncInventoryToClient(player)
end

CraftingSystem.configure({
    hasMaterials = hasCraftingMaterials,
    consumeMaterials = consumeCraftingMaterials,
    grantItems = grantCraftedItems,
})

-- Now connect HomeBuildingService to Inventory system (functions are now defined)
logInfo("🏠 Connecting HomeBuildingService to Inventory system...")
_HomeBuildingService:SetInventoryFunctions(hasCraftingMaterials, consumeCraftingMaterials)

-- Connect OnboardingService to Inventory system
logInfo("📚 Connecting OnboardingService to Inventory system...")
onboardingService:setAddItemFunction(addItemToInventory)
onboardingService:setStarterKitCheckFunction(hasStarterKit)
TreeShakingSystem.setAddItemFunction(addItemToInventory)

-- FishingSystem is ready to use (no init needed)

local _buildingService = BuildingService.new({
    hasMaterials = hasCraftingMaterials,
    consumeMaterials = consumeCraftingMaterials,
    currencyManager = CurrencyManager,
})

local function cleanupWorldItemConnections(connections)
    if not connections then
        return
    end

    for index = #connections, 1, -1 do
        local connection = connections[index]
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
        connections[index] = nil
    end
end

local function destroyWorldItem(worldItemId)
    local entry = worldItems[worldItemId]
    if not entry then
        return
    end

    if entry.disconnect then
        local success, err = pcall(entry.disconnect, entry)
        if not success then
            warn("[Server] Failed to run world item disconnect callback:", err)
        end
    end

    cleanupWorldItemConnections(entry.connections)

    if entry.model then
        entry.model:Destroy()
    end

    worldItems[worldItemId] = nil
end

-- Create dropped item as simple banner in front of player
local function createDroppedItem(player, itemId, count, worldPosition)
    if not ItemData[itemId] then
        warn("[Server] Unknown item:", itemId)
        return
    end

    local item = ItemData[itemId]
    local worldItemId = nextItemId
    nextItemId = nextItemId + 1

    local presentationConnections = {}
    local function trackConnection(connection)
        if connection then
            table.insert(presentationConnections, connection)
        end
        return connection
    end

    -- Check if this item should spawn as a bell bag
    local isBellBag, totalValue = shouldSpawnAsBellBag(itemId, count)
    local bellBagModel: Model? = nil
    local bellBagModelName: string? = nil

    -- For bell bag items, try to load 3D model first (BellBagSmall, BellBagMed, BellBagLarge)
    if isBellBag and totalValue then
        -- First, try to load 3D model directly by itemId (e.g., bell_bag_small -> BellBagSmall)
        bellBagModel = loadItem3DModel(itemId)
        if bellBagModel then
            -- Get the actual model name from the cloned model's parent (original name)
            -- Since we cloned it, we need to check what name pattern matched
            -- Try to find the original model in ReplicatedStorage to get its name
            local function toCamelCase(str)
                local parts = {}
                for part in str:gmatch("[^_]+") do
                    table.insert(parts, part:sub(1, 1):upper() .. part:sub(2):lower())
                end
                return table.concat(parts)
            end

            local camelCaseName = toCamelCase(itemId)
            local originalModel = ReplicatedStorage:FindFirstChild(camelCaseName)
            if originalModel and originalModel:IsA("Model") then
                bellBagModelName = originalModel.Name
            else
                -- Fallback: determine from itemId
                if itemId:find("large") then
                    bellBagModelName = "BellBagLarge"
                elseif itemId:find("med") or itemId:find("medium") then
                    bellBagModelName = "BellBagMedium"
                elseif itemId:find("small") then
                    bellBagModelName = "BellBagSmall"
                else
                    bellBagModelName = camelCaseName or "BellBag"
                end
            end
            logInfo(
                "💰 Found 3D model for bell bag item",
                { itemId = itemId, model = bellBagModelName, totalValue = totalValue }
            )
        else
            -- Fallback to old logic if 3D model not found
            bellBagModelName = getBellBagModelName(item.sell or item.sell_price or 0, count)
            if bellBagModelName then
                bellBagModel = loadBellBagModel(bellBagModelName)
                if bellBagModel then
                    logInfo(
                        "💰 Spawning bell bag model",
                        { model = bellBagModelName, item = item.name, totalValue = totalValue }
                    )
                end
            end
        end
    end

    local model = Instance.new("Model")
    if bellBagModel then
        local bellBagLabel = bellBagModelName or "BellBag"
        model.Name = "BellBag_" .. worldItemId .. "_" .. bellBagLabel
    else
        model.Name = "WorldItem_" .. worldItemId .. "_" .. item.name
    end
    model.Parent = workspace

    -- Physics part for gravity - heavier for bell bags
    local pivot = Instance.new("Part")
    pivot.Name = "Pivot"
    if bellBagModel then
        -- Larger, heavier pivot for bell bags
        pivot.Size = Vector3.new(3, 3, 3)
        pivot.Material = Enum.Material.Metal
        pivot.Massless = false
        pivot.CFrame = CFrame.new(worldPosition + Vector3.new(0, 4, 0)) -- Start higher
        pivot.AssemblyLinearVelocity = Vector3.new(0, -15, 0) -- Faster, heavier drop
    else
        pivot.Size = Vector3.new(2, 2, 2) -- Small collision box for regular items
        pivot.CFrame = CFrame.new(worldPosition + Vector3.new(0, 3, 0)) -- Start higher
        pivot.AssemblyLinearVelocity = Vector3.new(0, -8, 0) -- Drop down
    end
    pivot.Transparency = 1
    pivot.Anchored = false
    pivot.CanCollide = true
    pivot.Parent = model

    -- If we have a bell bag model, use it instead of the regular display
    if bellBagModel then
        bellBagModel.Name = "BellBag"
        bellBagModel.Parent = model

        -- Set up bell bag model
        -- First, try to find PrimaryPart
        local bellBagPart = bellBagModel.PrimaryPart

        -- If no PrimaryPart, try to find it or set it
        if not bellBagPart then
            -- Look for a part named "Handle" or "PrimaryPart" or largest part
            bellBagPart = bellBagModel:FindFirstChild("Handle")
            if not bellBagPart then
                bellBagPart = bellBagModel:FindFirstChild("PrimaryPart")
            end
            if not bellBagPart then
                bellBagPart = bellBagModel:FindFirstChildOfClass("BasePart")
            end

            -- Find largest part if still no part found
            if not bellBagPart then
                local largestPart = nil
                local largestSize = 0
                for _, descendant in ipairs(bellBagModel:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        local size = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
                        if size > largestSize then
                            largestSize = size
                            largestPart = descendant
                        end
                    end
                end
                bellBagPart = largestPart
            end

            -- Set PrimaryPart if we found one
            if bellBagPart then
                bellBagModel.PrimaryPart = bellBagPart
            end
        end

        if bellBagPart then
            -- Make bell bag heavy and realistic - NOT massless
            for _, descendant in ipairs(bellBagModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.CanCollide = true -- Allow collision for realistic physics
                    descendant.Anchored = false -- Will be anchored after landing
                    descendant.Massless = false -- Make it HEAVY for realistic drop
                    -- Make parts heavier based on bell bag size
                    if bellBagModelName == "BellBagLarge" then
                        descendant.Material = Enum.Material.Metal -- Heavier material
                    else
                        descendant.Material = Enum.Material.Plastic
                    end
                end
            end

            -- Position bell bag at drop position (higher for dramatic drop)
            local dropPosition = worldPosition + Vector3.new(0, 4, 0)
            bellBagModel:PivotTo(CFrame.new(dropPosition))

            -- Add initial velocity for realistic drop
            if bellBagPart then
                bellBagPart.AssemblyLinearVelocity = Vector3.new(
                    (math.random() - 0.5) * 2, -- Small random horizontal velocity
                    -12, -- Strong downward velocity for heavy drop
                    (math.random() - 0.5) * 2
                )
                -- Add slight rotation for realism
                bellBagPart.AssemblyAngularVelocity =
                    Vector3.new((math.random() - 0.5) * 5, (math.random() - 0.5) * 5, (math.random() - 0.5) * 5)
            end

            -- Make sure PrimaryPart is set
            if not bellBagModel.PrimaryPart then
                bellBagModel.PrimaryPart = bellBagPart
            end

            logInfo("✅ Bell bag model positioned", { position = dropPosition, primaryPart = bellBagPart.Name })
        else
            warn("[Server] ⚠️ No BasePart found in bell bag model:", bellBagModelName)
        end

        -- Store bell bag info in worldItems
        worldItems[worldItemId] = {
            itemId = itemId,
            count = count,
            position = worldPosition,
            droppedBy = player and player.UserId or nil,
            droppedAt = tick(),
            model = model,
            connections = presentationConnections,
            floatHeight = 1.5,
            isBellBag = true,
            bellsValue = totalValue,
            bellBagModelName = bellBagModelName,
        }

        -- Set up bell bag pickup system (will be added after landing)
        local pickupCooldown = 1 -- 1 second cooldown
        local lastPickupAttempt = tick()
        local hasLanded = false
        local floatConnection = nil
        local floatTime = 0

        -- Function to start floating animation - use RenderStepped for smoother animation
        local function startFloatingAnimation()
            if floatConnection then
                return -- Already floating
            end

            -- Use RenderStepped for smoother animation, but only update every other frame to reduce lag
            local frameSkip = 0
            floatConnection = RunService.RenderStepped:Connect(function()
                frameSkip = frameSkip + 1
                if frameSkip < 2 then
                    return
                end -- Skip every other frame
                frameSkip = 0

                if not model.Parent or not bellBagModel then
                    if floatConnection then
                        floatConnection:Disconnect()
                        floatConnection = nil
                    end
                    return
                end

                floatTime += 0.033 -- Approximate frame time (30fps)
                local floatHeight = math.sin(floatTime * 1.5) * 0.15 -- Gentle floating
                local primaryBellBagPart = bellBagModel
                    and (bellBagModel.PrimaryPart or bellBagModel:FindFirstChildOfClass("BasePart"))
                if primaryBellBagPart and pivot.Parent then
                    -- Float above the pivot position
                    local basePosition = pivot.Position + Vector3.new(0, 0.5, 0)
                    bellBagModel:PivotTo(CFrame.new(basePosition + Vector3.new(0, floatHeight, 0)))
                end
            end)
            trackConnection(floatConnection)
        end

        -- Wait for bell bag to land - use Stepped instead of Heartbeat for better performance
        local landingConnection
        landingConnection = RunService.Stepped:Connect(function()
            if not model.Parent or not pivot.Parent then
                if landingConnection then
                    landingConnection:Disconnect()
                end
                return
            end

            -- Check if landed (check both pivot and bell bag model velocity)
            local landingBellBagPart = bellBagModel
                and (bellBagModel.PrimaryPart or bellBagModel:FindFirstChildOfClass("BasePart"))
            local bellBagVelocity = landingBellBagPart and landingBellBagPart.AssemblyLinearVelocity
                or Vector3.new(0, 0, 0)
            local pivotVelocity = pivot.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
            local combinedVelocity = pivotVelocity.Magnitude + bellBagVelocity.Magnitude

            -- Check if on ground (raycast down)
            local isOnGround = false
            if landingBellBagPart then
                local rayOrigin = landingBellBagPart.Position
                local rayDirection = Vector3.new(0, -2, 0)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = { model }
                local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                isOnGround = rayResult ~= nil
            end

            if combinedVelocity < 0.3 and isOnGround and not hasLanded then
                hasLanded = true
                -- Anchor bell bag after landing
                if bellBagModel and landingBellBagPart then
                    -- Position bell bag on top of pivot (on the ground)
                    local groundPosition = pivot.Position + Vector3.new(0, 0.5, 0)
                    bellBagModel:PivotTo(CFrame.new(groundPosition))

                    -- Anchor all parts
                    for _, descendant in ipairs(bellBagModel:GetDescendants()) do
                        if descendant:IsA("BasePart") then
                            descendant.Anchored = true
                            descendant.CanCollide = false -- Keep non-collidable
                        end
                    end

                    logInfo("✅ Bell bag landed", { position = groundPosition })
                end
                pivot.Anchored = true
                pivot.CanCollide = false -- Make pivot non-collidable too

                -- Start floating animation
                startFloatingAnimation()

                -- Add ProximityPrompt for bell bag pickup
                local prompt = Instance.new("ProximityPrompt")
                prompt.Name = "PickupBellBag"
                prompt.ActionText = "Collect Bells"
                -- Format bell bag name (e.g., "BellBagSmall" -> "Small Bell Bag", "BellBagMedium" -> "Medium Bell Bag")
                local displayName = bellBagModelName or "Bell Bag"
                if bellBagModelName then
                    -- Remove "BellBag" prefix
                    displayName = bellBagModelName:gsub("^BellBag", "")
                    -- Handle empty result or format nicely
                    if displayName == "" then
                        displayName = "Bell Bag"
                    else
                        -- Capitalize first letter and add " Bell Bag" suffix
                        displayName = displayName:sub(1, 1):upper() .. displayName:sub(2):lower() .. " Bell Bag"
                    end
                end
                -- Format bells with commas
                local formattedBells = tostring(totalValue):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
                prompt.ObjectText = "💰 " .. formattedBells .. " Bells"
                prompt.HoldDuration = 0
                prompt.KeyboardKeyCode = Enum.KeyCode.E
                prompt.MaxActivationDistance = 8
                prompt.RequiresLineOfSight = false
                prompt.Style = Enum.ProximityPromptStyle.Custom -- Use custom style for special coloring
                prompt.Parent = pivot

                -- Add an attribute to mark this as a bell bag for custom UI styling
                prompt:SetAttribute("IsBellBag", true)
                prompt:SetAttribute("BellsValue", totalValue)

                -- Connect pickup
                prompt.Triggered:Connect(function(pickingPlayer)
                    local now = tick()
                    if now - lastPickupAttempt < pickupCooldown then
                        return
                    end
                    lastPickupAttempt = now

                    -- Check if player wants to collect as item or as bells
                    -- For now, default to bells, but we'll add UI choice later
                    local collectAsItem = false -- This will be set based on player choice

                    if collectAsItem then
                        -- Add bell bag as item to inventory
                        local bellBagItemId = "bell_bag_" .. string.lower(bellBagModelName:gsub("BellBag", ""))
                        local success, err = addItemToInventory(pickingPlayer, {
                            itemId = bellBagItemId,
                            count = 1,
                        })
                        if success then
                            logInfo(
                                "🎒 Bell bag picked up as item",
                                { player = pickingPlayer.Name, model = bellBagModelName, itemId = bellBagItemId }
                            )
                        else
                            warn("[Server] ❌ Failed to add bell bag item to inventory:", err)
                            -- Fallback to collecting as bells if inventory is full
                            if totalValue and totalValue > 0 then
                                local success = CurrencyManager.addBells(pickingPlayer, totalValue)
                                if success then
                                    logInfo(
                                        "💰 Bell bag picked up as bells (inventory full)",
                                        { player = pickingPlayer.Name, model = bellBagModelName, totalValue = totalValue }
                                    )
                                else
                                    warn("[Server] ❌ Failed to add bells to", pickingPlayer.Name)
                                end
                            end
                        end
                    else
                        -- Add bells to player (original behavior)
                        if totalValue and totalValue > 0 then
                            local success = CurrencyManager.addBells(pickingPlayer, totalValue)
                            if success then
                                logInfo(
                                    "💰 Bell bag picked up",
                                    { player = pickingPlayer.Name, model = bellBagModelName, totalValue = totalValue }
                                )
                            else
                                warn("[Server] ❌ Failed to add bells to", pickingPlayer.Name)
                            end
                        end
                    end

                            -- Play pickup animation
                            local character = pickingPlayer.Character
                            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                            if humanoidRootPart and bellBagModel then
                                local targetPosition = humanoidRootPart.Position + Vector3.new(0, 2, 0)

                                -- Animate bell bag flying to player
                                local pickupTween = TweenService:Create(
                                    pivot,
                                    TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                    {
                                        CFrame = CFrame.new(targetPosition),
                                    }
                                )

                                -- Scale down effect
                                local pickupBellBagPart = bellBagModel.PrimaryPart
                                    or bellBagModel:FindFirstChildOfClass("BasePart")
                                local scaleDownTween
                                if pickupBellBagPart then
                                    scaleDownTween = TweenService:Create(
                                        pickupBellBagPart,
                                        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                                        {
                                            Size = pickupBellBagPart.Size * 0.1,
                                            Transparency = 1,
                                        }
                                    )
                                end

                                pickupTween:Play()
                                if scaleDownTween then
                                    scaleDownTween:Play()
                                end

                                -- Clean up after animation
                                pickupTween.Completed:Wait()
                                destroyWorldItem(worldItemId)
                            else
                                -- No animation, just destroy
                                destroyWorldItem(worldItemId)
                            end
                        else
                            warn("[Server] ❌ Failed to add bells to", pickingPlayer.Name)
                        end
                    end
                end)

                if landingConnection then
                    landingConnection:Disconnect()
                end
            end
        end)
        trackConnection(landingConnection)

        -- Add enhanced glow and sparkle effects to bell bag (use PrimaryPart or first part)
        local glowPart = bellBagModel and (bellBagModel.PrimaryPart or bellBagModel:FindFirstChildOfClass("BasePart"))
        if glowPart then
            -- Remove existing effects if any
            local existingLight = glowPart:FindFirstChild("BellBagGlow")
            if existingLight then
                existingLight:Destroy()
            end
            local existingSparkle = glowPart:FindFirstChild("BellBagSparkle")
            if existingSparkle then
                existingSparkle:Destroy()
            end
            local existingGoldParticles = glowPart:FindFirstChild("BellBagGoldParticles")
            if existingGoldParticles then
                existingGoldParticles:Destroy()
            end

            -- Enhanced glow based on bell bag size (ACNH values)
            local glowRange = 12
            local glowBrightness = 2.0
            local sparkleRate = 8
            local goldParticleRate = 4
            if bellBagModelName == "BellBagLarge" then
                -- 99,000 bells - maximum sparkle!
                glowRange = 18
                glowBrightness = 3.0
                sparkleRate = 15
                goldParticleRate = 8
            elseif bellBagModelName == "BellBagMedium" then
                -- 10,000 bells
                glowRange = 15
                glowBrightness = 2.5
                sparkleRate = 12
                goldParticleRate = 6
            end
            -- Small = 1,000 bells (default values above)

            -- Main gold point light
            local pointLight = Instance.new("PointLight")
            pointLight.Name = "BellBagGlow"
            pointLight.Range = glowRange
            pointLight.Brightness = glowBrightness
            pointLight.Color = Color3.fromRGB(255, 215, 0) -- Gold color
            pointLight.Shadows = false
            pointLight.Parent = glowPart

            -- Sparkle particle emitter (white/gold sparkles floating up)
            local sparkleEmitter = Instance.new("ParticleEmitter")
            sparkleEmitter.Name = "BellBagSparkle"
            sparkleEmitter.Texture = "rbxassetid://6490035152" -- Star/sparkle texture
            sparkleEmitter.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 223, 100)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50)),
            })
            sparkleEmitter.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(0.5, 0.25),
                NumberSequenceKeypoint.new(1, 0),
            })
            sparkleEmitter.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.3),
                NumberSequenceKeypoint.new(0.7, 0.5),
                NumberSequenceKeypoint.new(1, 1),
            })
            sparkleEmitter.Lifetime = NumberRange.new(0.8, 1.5)
            sparkleEmitter.Rate = sparkleRate
            sparkleEmitter.Speed = NumberRange.new(0.5, 1.5)
            sparkleEmitter.SpreadAngle = Vector2.new(30, 30)
            sparkleEmitter.Rotation = NumberRange.new(0, 360)
            sparkleEmitter.RotSpeed = NumberRange.new(-180, 180)
            sparkleEmitter.LightEmission = 0.8
            sparkleEmitter.LightInfluence = 0.2
            sparkleEmitter.Parent = glowPart

            -- Gold coin/bell particles (larger, slower, more magical)
            local goldParticles = Instance.new("ParticleEmitter")
            goldParticles.Name = "BellBagGoldParticles"
            goldParticles.Texture = "rbxassetid://304846479" -- Circular particle
            goldParticles.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 160, 40)),
            })
            goldParticles.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.15),
                NumberSequenceKeypoint.new(0.3, 0.3),
                NumberSequenceKeypoint.new(1, 0.05),
            })
            goldParticles.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2),
                NumberSequenceKeypoint.new(0.8, 0.6),
                NumberSequenceKeypoint.new(1, 1),
            })
            goldParticles.Lifetime = NumberRange.new(1.2, 2.0)
            goldParticles.Rate = goldParticleRate
            goldParticles.Speed = NumberRange.new(0.3, 0.8)
            goldParticles.SpreadAngle = Vector2.new(45, 45)
            goldParticles.Drag = 2
            goldParticles.Acceleration = Vector3.new(0, -0.5, 0) -- Gentle float up then fall
            goldParticles.LightEmission = 0.6
            goldParticles.LightInfluence = 0.3
            goldParticles.Parent = glowPart

            -- Add subtle pulsing glow effect (optimized - only update every 10 frames)
            local pulseTime = 0
            local pulseConnection
            local pulseFrameSkip = 0
            pulseConnection = RunService.Heartbeat:Connect(function()
                pulseFrameSkip = pulseFrameSkip + 1
                if pulseFrameSkip < 10 then
                    return
                end -- Update every 10 frames (~0.16s at 60fps)
                pulseFrameSkip = 0

                if not model.Parent or not pointLight.Parent then
                    if pulseConnection then
                        pulseConnection:Disconnect()
                    end
                    return
                end

                pulseTime = pulseTime + 0.16
                local pulse = 0.3 * math.sin(pulseTime * 3) -- More noticeable pulse
                pointLight.Brightness = glowBrightness + pulse
            end)
            trackConnection(pulseConnection)

            logInfo("✅ Added enhanced glow and sparkle effects to bell bag", {
                model = bellBagModelName,
                bells = totalValue,
                sparkleRate = sparkleRate
            })
        else
            warn("[Server] ⚠️ Could not find part to add glow to bell bag model:", bellBagModelName)
        end

        model.PrimaryPart = pivot
        logInfo("✅ Created bell bag", { model = bellBagModelName, totalValue = totalValue, position = worldPosition })
        return -- Exit early, bell bag is set up
    end

    -- Check if this item has a 3D model in ReplicatedStorage (by itemId name)
    -- Skip if already handled as bell bag
    local displayModel = nil
    local has3DModel = false

    if not isBellBag then
        -- Only check for 3D models if not a bell bag (bell bags handled above)
        displayModel = loadItem3DModel(itemId)
        has3DModel = displayModel ~= nil

        -- If no direct model found, check ToolObjects (tools, etc.)
        if not has3DModel then
            has3DModel = ToolObjects.hasToolModel(itemId)
            if has3DModel then
                logInfo("🎨 Using tool 3D model", { itemId = itemId })
                displayModel = ToolObjects.getGroundDisplayModel(itemId)
                if not displayModel then
                    has3DModel = false -- Fallback to sprite if model failed to load
                end
            end
        else
            logInfo("🎨 Using 3D model from ReplicatedStorage", { itemId = itemId })
        end
    end

    if has3DModel and displayModel then
        -- Position the 3D model
        displayModel.Name = "Display3D"
        displayModel.Parent = model

        -- Find primary part or first BasePart for positioning
        local displayPart = displayModel.PrimaryPart or displayModel:FindFirstChildWhichIsA("BasePart")
        if displayPart then
            displayPart.CFrame = CFrame.new(worldPosition + Vector3.new(0, 2, 0))
            displayPart.Anchored = true
            displayPart.CanCollide = false

            -- Set all parts to non-collidable
            for _, part in ipairs(displayModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.Anchored = true
                end
            end
        end
    end

    -- If no 3D model, use sprite banner as fallback
    local banner
    if not has3DModel then
        logInfo("🖼️ Using sprite banner", { itemId = itemId })
        -- Simple flat banner sprite (make it anchored initially so it shows)
        banner = Instance.new("Part")
        banner.Name = "Banner"
        banner.Size = Vector3.new(4, 6, 0.1) -- Banner proportions (4 studs wide, 6 studs tall)
        banner.Material = Enum.Material.Neon
        banner.Transparency = 1
        banner.CanCollide = false
        banner.Anchored = true -- Start anchored so it's visible
        banner.CFrame = CFrame.new(worldPosition + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, 0) -- Start higher and upright
        banner.CastShadow = true
        banner.Parent = model

        -- Banner sprite
        local bannerGui = Instance.new("SurfaceGui")
        bannerGui.Face = Enum.NormalId.Front
        bannerGui.Parent = banner

        local bannerImage = Instance.new("ImageLabel")
        bannerImage.Size = UDim2.fromScale(1, 1)
        bannerImage.BackgroundTransparency = 1
        bannerImage.Image = SpriteConfig.SHEET_ASSET
        bannerImage.ImageTransparency = 0
        bannerImage.ScaleType = Enum.ScaleType.Fit -- Keep aspect ratio
        bannerImage.Parent = bannerGui

        -- Calculate sprite rect for this item
        local spriteOffset, spriteSize = SpriteConfig.getSpriteRect(item.index)
        if not spriteOffset or not spriteSize then
            spriteOffset = Vector2.new(0, 0)
            spriteSize = SpriteConfig.DEFAULT_IMAGE_RECT_SIZE
        end

        bannerImage.ImageRectOffset = spriteOffset
        bannerImage.ImageRectSize = spriteSize
    end

    -- Subtle glow (attach to banner or display model)
    local glowPart = banner or (displayModel and displayModel:FindFirstChildWhichIsA("BasePart")) or pivot
    local pointLight = Instance.new("PointLight")
    pointLight.Name = "ItemGlow"
    pointLight.Range = 5
    pointLight.Brightness = 0.8
    pointLight.Color = Color3.fromRGB(255, 250, 240)
    pointLight.Shadows = false
    pointLight.Parent = glowPart

    model.PrimaryPart = pivot

    worldItems[worldItemId] = {
        itemId = itemId,
        count = count,
        position = worldPosition,
        droppedBy = player and player.UserId or nil, -- Handle nil player
        droppedAt = tick(),
        model = model,
        connections = presentationConnections,
        floatHeight = 1.5, -- Initial float height
    }

    -- Add cooldown to prevent immediate pickup after drop
    local pickupCooldown = 1 -- 1 second cooldown
    local lastPickupAttempt = tick()

    -- Make banner always face camera (billboard effect) - only for sprite banners, not 3D models
    local billboardConnection
    local hasLandedBillboard = false
    if banner then -- Only apply billboard effect to sprite banners
        billboardConnection = RunService.Heartbeat:Connect(function()
            if not model.Parent or not pivot.Parent or not banner.Parent then
                if billboardConnection then
                    billboardConnection:Disconnect()
                    billboardConnection = nil
                end
                return
            end

            -- Check if banner has landed
            if not hasLandedBillboard and pivot.AssemblyLinearVelocity.Magnitude < 0.1 then
                hasLandedBillboard = true
            end

            -- Only apply billboard after landing
            if not hasLandedBillboard then
                return
            end

            -- Find nearest player's camera
            local nearestPlayer = nil
            local nearestDistance = math.huge
            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                local character = otherPlayer.Character
                local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local distance = (humanoidRootPart.Position - pivot.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = otherPlayer
                    end
                end
            end

            if nearestPlayer then
                local character = nearestPlayer.Character
                local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    -- Get float height from worldItems
                    local floatHeight = worldItems[worldItemId].floatHeight or 1.5

                    -- Position banner above pivot with billboard rotation (facing player upright)
                    local bannerPosition = pivot.Position + Vector3.new(0, floatHeight, 0)
                    local lookVector = (humanoidRootPart.Position - bannerPosition).Unit
                    -- Rotate to face player, and angle up 90 degrees so it's upright
                    banner.CFrame = CFrame.lookAt(bannerPosition, bannerPosition + lookVector)
                        * CFrame.Angles(0, 0, math.rad(90))

                    -- Ensure banner is anchored for stability
                    if not banner.Anchored then
                        banner.Anchored = true
                    end
                end
            end
        end)
        trackConnection(billboardConnection)
    elseif displayModel then
        -- For 3D models, apply floating effect to all parts
        billboardConnection = RunService.Heartbeat:Connect(function()
            if not model.Parent or not pivot.Parent or not displayModel.Parent then
                if billboardConnection then
                    billboardConnection:Disconnect()
                    billboardConnection = nil
                end
                return
            end

            -- Check if model has landed
            if not hasLandedBillboard and pivot.AssemblyLinearVelocity.Magnitude < 0.1 then
                hasLandedBillboard = true
            end

            if hasLandedBillboard then
                -- Get float height from worldItems
                local floatHeight = worldItems[worldItemId].floatHeight or 1.5

                -- Position 3D model above pivot
                local displayPart = displayModel.PrimaryPart or displayModel:FindFirstChildWhichIsA("BasePart")
                if displayPart then
                    local modelPosition = pivot.Position + Vector3.new(0, floatHeight, 0)
                    -- Slowly rotate the 3D model for visual interest
                    local rotation = tick() * 30 -- 30 degrees per second
                    displayPart.CFrame = CFrame.new(modelPosition) * CFrame.Angles(0, math.rad(rotation), 0)
                end
            end
        end)
        trackConnection(billboardConnection)
    end

    local function pickupItem(pickingPlayer)
        if not worldItems[worldItemId] then
            return
        end

        -- Check cooldown
        local now = tick()
        if now - lastPickupAttempt < pickupCooldown then
            return
        end
        lastPickupAttempt = now

        logInfo("Item picked up", { player = pickingPlayer.Name, item = item.name, count = count })

        -- Get player position for animation
        local character = pickingPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local targetPosition = humanoidRootPart and humanoidRootPart.Position or worldPosition

        -- Anchor the pivot for smooth animation
        pivot.Anchored = true

        -- Create simple pickup animation for pivot
        local pickupTween =
            TweenService:Create(pivot, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                CFrame = CFrame.new(targetPosition + Vector3.new(0, 2, 0)),
            })

        -- Scale down effect - handle both banner and 3D model
        local scaleDownTween
        if banner then
            scaleDownTween =
                TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = Vector3.new(0.1, 0.1, 0.1),
                })
        elseif displayModel then
            -- For 3D models, tween the primary part's size
            local displayPart = displayModel.PrimaryPart or displayModel:FindFirstChildWhichIsA("BasePart")
            if displayPart then
                scaleDownTween = TweenService:Create(
                    displayPart,
                    TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                    {
                        Size = displayPart.Size * 0.1,
                        Transparency = 1,
                    }
                )
            end
        end

        -- Start animations
        pickupTween:Play()
        if scaleDownTween then
            scaleDownTween:Play()
        end

        -- Wait for animation to complete before adding to inventory
        pickupTween.Completed:Connect(function()
            logInfo("🎬 Animation completed, adding to inventory", { player = player.Name })

            local inventory = playerInventories[pickingPlayer.UserId]
            if inventory then
                local slots = inventory.slots
                local existingIndex
                for index = 1, inventory.maxSlots or MAX_SLOTS do
                    local slot = slots[index]
                    if slot and slot.itemId == itemId then
                        existingIndex = index
                        break
                    end
                end

                if existingIndex then
                    slots[existingIndex].count = slots[existingIndex].count + count
                else
                    local emptyIndex
                    for index = 1, inventory.maxSlots or MAX_SLOTS do
                        if not slots[index] then
                            emptyIndex = index
                            break
                        end
                    end

                    if emptyIndex then
                        slots[emptyIndex] = { itemId = itemId, count = count }
                    else
                        warn("[Server]", pickingPlayer.Name, "has no space to pick up", item.name)
                        return
                    end
                end

                syncInventoryToClient(pickingPlayer)

                -- Update quest progress
                if questService then
                    QuestHandlers.onItemCollected(pickingPlayer, itemId, count)
                end
            end

            destroyWorldItem(worldItemId)
        end)
    end

    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20 -- Increased from 12 to 20
    clickDetector.Parent = pivot
    clickDetector.MouseClick:Connect(pickupItem)

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PickupItem"
    prompt.ActionText = "Pick Up"
    if count and count > 1 then
        prompt.ObjectText = string.format("%s x%d", item.name, count)
    else
        prompt.ObjectText = item.name
    end
    prompt.HoldDuration = 0
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Parent = pivot
    prompt.Triggered:Connect(pickupItem)

    -- Add floating effect after landing
    local floatConnection
    local floatTime = 0
    local hasLanded = false
    local displayPart = banner
        or (displayModel and (displayModel.PrimaryPart or displayModel:FindFirstChildWhichIsA("BasePart")))

    floatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not model.Parent or not pivot.Parent or not displayPart or not displayPart.Parent then
            if floatConnection then
                floatConnection:Disconnect()
                floatConnection = nil
            end
            return
        end

        -- Check if item has landed (use velocity to detect)
        if not hasLanded and pivot.AssemblyLinearVelocity.Magnitude < 0.1 then
            hasLanded = true
        end

        if hasLanded then
            -- Item has landed, add floating effect
            floatTime = floatTime + deltaTime
            local floatAmount = math.sin(floatTime * 2) * 0.5 -- Gentle 0.5 stud float
            worldItems[worldItemId].floatHeight = 1.5 + floatAmount
        end
    end)
    trackConnection(floatConnection)

    logInfo("✅ Created dropped banner", { item = item.name, count = count, position = worldPosition })
end

-- Get all world items (for debugging/admin)
local function getAllWorldItems()
    local items = {}
    for id, item in pairs(worldItems) do
        if item.model and item.model.Parent then
            table.insert(items, {
                id = id,
                itemId = item.itemId,
                count = item.count,
                position = item.position,
                droppedBy = item.droppedBy,
                droppedAt = item.droppedAt,
            })
        end
    end
    return items
end

-- Handle inventory requests
inventoryRemote.OnServerEvent:Connect(function(player, action, data)
    logInfo("Received action", { action = action, player = player.Name })
    local inventory = playerInventories[player.UserId]

    -- Initialize inventory if it doesn't exist (race condition fix)
    if not inventory then
        warn("[Server] Player inventory not found:", player.Name, "- initializing now...")
        initializePlayerInventory(player)
        inventory = playerInventories[player.UserId]
        if not inventory then
            warn("[Server] ❌ Failed to initialize inventory for", player.Name)
            return
        end
    end

    if action == "RequestInventory" then
        logInfo("Sending inventory to player", { player = player.Name, items = countFilledSlots(inventory.slots) })
        syncInventoryToClient(player)
        inventoryRemote:FireClient(player, "InventoryUpgradeInfo", buildUpgradePayload(player, inventory))
    elseif action == "GetInventoryUpgradeInfo" then
        inventoryRemote:FireClient(player, "InventoryUpgradeInfo", buildUpgradePayload(player, inventory))
    elseif action == "UpgradeInventory" then
        local success, payload, errorCode = attemptInventoryUpgrade(player, inventory)
        inventoryRemote:FireClient(player, "InventoryUpgradeResult", {
            success = success,
            error = errorCode,
            state = payload,
        })

        if success then
            syncInventoryToClient(player)
            savePlayerInventory(player)
        end
    elseif action == "ImportLegacyInventory" and data then
        logInfo("Importing legacy inventory payload", { player = player.Name })
        hydrateInventoryFromLegacy(inventory, data.payload, data.options)
        syncInventoryToClient(player)
    elseif action == "DropItem" and data then
        local itemId = data.itemId
        local count = data.count or 1
        local slotIndex = data.slotIndex

        -- Calculate position next to player instead of using worldPosition
        local character = player.Character
        local dropPosition = Vector3.new(0, 5, 0) -- Default fallback

        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                -- Drop item 3 studs in front of player
                local lookDirection = rootPart.CFrame.LookVector
                dropPosition = rootPart.Position + lookDirection * 3 + Vector3.new(0, 2, 0)
            end
        end

        local display = DisplayItems[itemId]
        logInfo("Drop item request", {
            player = player.Name,
            item = display and display.name or itemId,
            count = count,
            position = dropPosition,
        })

        local slots = inventory.slots
        local function removeFromSlot(index)
            local slot = slots[index]
            if slot and slot.itemId == itemId and slot.count >= count then
                slot.count = slot.count - count
                if slot.count <= 0 then
                    slots[index] = nil
                end
                return true
            end
            return false
        end

        local removed = false
        if slotIndex and slotIndex >= 1 and slotIndex <= (inventory.maxSlots or MAX_SLOTS) then
            removed = removeFromSlot(slotIndex)
        end

        if not removed then
            for index = 1, inventory.maxSlots or MAX_SLOTS do
                if removeFromSlot(index) then
                    removed = true
                    break
                end
            end
        end

        if removed then
            createDroppedItem(player, itemId, count, dropPosition)
            syncInventoryToClient(player)
            savePlayerInventory(player)
            return
        end

        warn("[Server]", player.Name, "tried to drop item they don't have:", itemId)
    elseif action == "DeleteItem" and data then
        -- Delete item from inventory (no drop)
        local itemId = data.itemId
        local count = data.count or 1

        local display = DisplayItems[itemId]
        logInfo("Delete item request", {
            player = player.Name,
            item = display and display.name or itemId,
            count = count,
        })

        local slots = inventory.slots
        local function removeFromSlot(index)
            local slot = slots[index]
            if slot and slot.itemId == itemId and slot.count >= count then
                slot.count = slot.count - count
                if slot.count <= 0 then
                    slots[index] = nil
                end
                return true
            end
            return false
        end

        local removed = false
        for index = 1, inventory.maxSlots or MAX_SLOTS do
            if removeFromSlot(index) then
                removed = true
                break
            end
        end

        if removed then
            logInfo("Successfully deleted item", {
                player = player.Name,
                item = display and display.name or itemId,
            })
            syncInventoryToClient(player)
            savePlayerInventory(player)
            return
        end

        warn("[Server]", player.Name, "tried to delete item they don't have:", itemId)
    elseif action == "EquipItem" and data then
        -- Equip wearable item (placeholder for character clothing system)
        local itemId = data.itemId
        local display = DisplayItems[itemId]
        logInfo("Equip item request", {
            player = player.Name,
            item = display and display.name or itemId,
        })

        -- TODO: Integrate with character clothing/equipping system
        -- For now, just acknowledge the action
        if display then
            logInfo("Item equipped", { item = display.name })
        else
            logWarn("Item not found in DisplayItems", { itemId = itemId })
        end

        -- Track equipped tool so other systems (shovel/fishing) can verify equipment
        player:SetAttribute("EquippedToolId", itemId)
        player:SetAttribute("EquippedToolType", determineToolType(itemId))
    elseif action == "MoveItem" and data then
        local fromIndex = data.fromIndex
        local toIndex = data.toIndex
        local swap = data.swap == true

        if type(fromIndex) ~= "number" or type(toIndex) ~= "number" then
            return
        end

        if fromIndex == toIndex then
            -- Nothing to do
            return
        end

        if fromIndex < 1 or fromIndex > (inventory.maxSlots or MAX_SLOTS) then
            return
        end

        if toIndex < 1 or toIndex > (inventory.maxSlots or MAX_SLOTS) then
            return
        end

        local slots = inventory.slots
        local fromSlot = slots[fromIndex]
        if not fromSlot then
            return
        end

        local toSlot = slots[toIndex]
        local itemId = fromSlot.itemId

        -- Case 1: moving into empty slot
        if not toSlot then
            -- Move entire stack by reference
            slots[toIndex] = fromSlot
            slots[fromIndex] = nil
            syncInventoryToClient(player)
            savePlayerInventory(player)
            return
        end

        -- Case 2: same itemId -> merge stacks up to maxStack
        if toSlot.itemId == itemId then
            local maxStack = getMaxStackForItem(itemId, toSlot)
            local fromCount = math.max(0, tonumber(fromSlot.count) or 0)
            local toCount = math.max(0, tonumber(toSlot.count) or 0)
            local space = math.max(0, maxStack - toCount)

            if space > 0 then
                -- Merge what we can
                local toAdd = math.min(space, fromCount)
                toSlot.count = toCount + toAdd
                local remaining = fromCount - toAdd
                if remaining > 0 then
                    fromSlot.count = remaining
                else
                    slots[fromIndex] = nil
                end
                toSlot.maxStack = maxStack
                syncInventoryToClient(player)
                savePlayerInventory(player)
                return
            end
            -- If no space and swap=true, fall through to swap
        end

        -- Case 3: different items or full stacks of same item -> swap
        if swap then
            slots[fromIndex], slots[toIndex] = toSlot, fromSlot
            syncInventoryToClient(player)
            savePlayerInventory(player)
            return
        end

        -- Otherwise, reject
        warn("[Server] MoveItem rejected: target occupied and swap not requested; from:", fromIndex, "to:", toIndex)
        return
    elseif action == "add_item" and data then
        local success, err = addItemToInventory(player, data)
        if success then
            logDebug(
                "Added item to inventory",
                { player = player.Name, item = (type(data) == "table" and data.itemId) or data }
            )

            -- Update quest progress for item collection
            if questService and type(data) == "table" and data.itemId then
                QuestHandlers.onItemCollected(player, data.itemId, data.count or 1)
            end
        else
            warn("[Server] Debug: Failed to add item:", err)
        end
    elseif action == "craft_item" and data then
        local itemId = data.itemId
        local recipe = ItemDataFetcher.getCraftingRecipe(itemId)
        if not recipe then
            warn("[Server] Craft failed: No recipe for", itemId)
            return
        end

        -- Check if player has all required materials
        local slots = inventory.slots
        local hasMaterials = true
        local materialsToRemove = {}

        for _, mat in ipairs(recipe.materials or {}) do
            local needed = mat.count or 1
            local found = 0

            for _, slot in pairs(slots) do
                if slot and slot.itemId == mat.itemId then
                    found = found + slot.count
                end
            end

            if found < needed then
                hasMaterials = false
                break
            end

            -- Record what to remove
            materialsToRemove[mat.itemId] = needed
        end

        if not hasMaterials then
            warn("[Server] Craft failed: Insufficient materials for", itemId)
            return
        end

        -- Remove materials
        for matId, needed in pairs(materialsToRemove) do
            local remaining = needed
            for slotIndex = 1, inventory.maxSlots or MAX_SLOTS do
                local slot = slots[slotIndex]
                if slot and slot.itemId == matId then
                    if slot.count >= remaining then
                        slot.count = slot.count - remaining
                        if slot.count <= 0 then
                            slots[slotIndex] = nil
                        end
                        break
                    else
                        remaining = remaining - slot.count
                        slots[slotIndex] = nil
                    end
                end
            end
        end

        -- Add crafted item
        local success, err = addItemToInventory(player, {
            itemId = itemId,
            count = 1,
        })

        if success then
            logInfo("Crafted item", { itemId = itemId, player = player.Name })

            -- Update quest progress
            if questService then
                QuestHandlers.onItemCrafted(player, itemId)
            end
        else
            warn("[Server] Craft failed: Inventory full for", itemId, err)
        end
    elseif action == "GetWorldItems" then
        -- Debug command to see all world items
        local worldItemsList = getAllWorldItems()
        logDebug("World items count", { count = #worldItemsList })
        for _, item in ipairs(worldItemsList) do
            logDebug("World item data", {
                id = item.id,
                itemId = item.itemId,
                count = item.count,
                position = item.position,
            })
        end
        inventoryRemote:FireClient(player, "WorldItemsList", worldItemsList)
    end
end)

-- Handle fishing requests
local fishingRemote = ReplicatedStorage:FindFirstChild("FishingEvent")
if not fishingRemote then
    fishingRemote = Instance.new("RemoteEvent")
    fishingRemote.Name = "FishingEvent"
    fishingRemote.Parent = ReplicatedStorage
end

fishingRemote.OnServerEvent:Connect(function(player, action, data)
    logInfo("Fishing event received", { action = action, player = player.Name })

    if action == "StartCast" and data and data.position then
        local success = FishingSystem.startCast(player, data.position)
        if not success then
            fishingRemote:FireClient(player, "CastFailed", { message = "Not in water!" })
        end
    elseif action == "AttemptCatch" then
        -- Get the fish data BEFORE attempting catch (since attemptCatch clears it)
        local castData = FishingSystem.activeCasts[player.UserId]
        local success = FishingSystem.attemptCatch(player)

        if success and castData and castData.fishData then
            -- Add fish to inventory
            local fishItem = {
                itemId = castData.fishData.id,
                count = 1,
            }
            local addSuccess = addItemToInventory(player, fishItem)

            if addSuccess then
                logInfo("✅ Added caught fish to inventory", { player = player.Name, fish = castData.fishData.name })

                -- Update quest progress
                if questService then
                    QuestHandlers.onFishCaught(player, castData.fishData)
                end
            else
                warn("[FishingSystem Server] ⚠️ Failed to add fish to inventory")
            end
        end
    end
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
    logInfo("Player added", { player = player.Name })

    local currencyState = loadPlayerCurrency(player)
    playerCurrencyStates[player.UserId] = currencyState
    CurrencyManager.registerPlayer(player, currencyState)

    -- Try to load saved inventory first
    local savedData = loadPlayerInventory(player)

    if savedData then
        -- Initialize with saved data
        local inventoryLevel = savedData.inventoryLevel or STARTING_INVENTORY_LEVEL
        local maxSlots = savedData.maxSlots or InventoryConstants.getMaxSlotsFromLevel(inventoryLevel)

        local slots = {}
        for index = 1, maxSlots do
            local slotData = savedData.slots[index]
            if slotData and slotData.itemId and slotData.itemId ~= "" and slotData.count and slotData.count > 0 then
                slots[index] = {
                    itemId = slotData.itemId,
                    count = slotData.count,
                }
            else
                slots[index] = nil
            end
        end

        local snapshot = buildSnapshotFromState(slots, maxSlots)
        playerInventories[player.UserId] = {
            slots = slots,
            maxSlots = maxSlots,
            inventoryLevel = inventoryLevel,
            snapshot = snapshot,
            legacyPayload = savedData.legacyPayload
                or inventoryAdapterRegistry:serializeForLegacy(InventoryConstants.LEGACY_DATASET_ID, snapshot),
        }

        logInfo("✅ Restored inventory", { player = player.Name, items = countFilledSlots(slots) })
        updateInventoryAttributes(player, playerInventories[player.UserId])
    else
        -- Initialize empty inventory
        logInfo("Initializing new inventory", { player = player.Name })
        initializePlayerInventory(player)
    end

    if onboardingService then
        onboardingService:giveStarterKit(player, CurrencyManager)
    end

    local inventory = playerInventories[player.UserId]
    replayRecipeDiscoveries(player, inventory, savedData)
    local legacyAttribute = player:GetAttribute("LegacyInventoryPayload")
    if legacyAttribute then
        logInfo("Found legacy payload attribute", { player = player.Name })
        hydrateInventoryFromLegacy(inventory, legacyAttribute, {
            source = "player-attribute",
            dataset = InventoryConstants.LEGACY_DATASET_ID,
        })
        syncInventoryToClient(player)
    end

    player.CharacterAdded:Connect(function()
        logInfo("Character added", { player = player.Name })

        -- Send initial inventory to client when character spawns
        local currentInventory = playerInventories[player.UserId]
        CurrencyManager.registerPlayer(player, playerCurrencyStates[player.UserId])
        if currentInventory then
            logInfo(
                "Sending initial inventory",
                { player = player.Name, items = countFilledSlots(currentInventory.slots) }
            )
            syncInventoryToClient(player)
        else
            warn("[Server] No inventory found for", player.Name)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Save inventory before player leaves
    savePlayerInventory(player)
    playerInventories[player.UserId] = nil
    logInfo("Cleaned up inventory", { player = player.Name })

    savePlayerCurrency(player)
    CurrencyManager.unregisterPlayer(player)
    playerCurrencyStates[player.UserId] = nil
end)

-- Auto-save inventory periodically (every 30 seconds)
RunService.Heartbeat:Connect(function()
    -- Throttle saves to avoid rate limits (save every 30 seconds)
    local currentTime = tick()
    if currentTime - lastInventorySave < 30 then
        return
    end

    lastInventorySave = currentTime
    for _, player in pairs(Players:GetPlayers()) do
        if playerInventories[player.UserId] then
            savePlayerInventory(player)
        end
        if playerCurrencyStates[player.UserId] then
            savePlayerCurrency(player)
        end
    end
end)

logInfo("✅ Inventory system loaded and ready!")

local currencyDebugEvent
if RunService:IsStudio() then
    currencyDebugEvent = Instance.new("RemoteEvent")
    currencyDebugEvent.Name = "CurrencyDebugEvent"
    currencyDebugEvent.Parent = ReplicatedStorage

    currencyDebugEvent.OnServerEvent:Connect(function(player, action, amount)
        if action == "AwardBells" then
            CurrencyManager.addBells(player, tonumber(amount) or 0)
        elseif action == "AwardMiles" then
            CurrencyManager.addMiles(player, tonumber(amount) or 0)
        end
    end)
end

-- Debug item test event
local testItemEvent = Instance.new("RemoteEvent")
testItemEvent.Name = "TestItemEvent"
testItemEvent.Parent = ReplicatedStorage

testItemEvent.OnServerEvent:Connect(function(player, x, y)
    logDebug("Test item event", { player = player.Name, x = x, y = y })

    -- Create a test item at the player's position
    local character = player.Character
    if not character then
        return
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end

    local worldPosition = humanoidRootPart.Position + Vector3.new(0, 2, 0)

    -- Create test item with specified coordinates
    local testItemId = "test_" .. x .. "_" .. y .. "_" .. os.time()

    -- Use the same dropItem logic but with custom coordinates
    local model = Instance.new("Model")
    model.Name = "TestItem_" .. testItemId
    model.Parent = workspace

    -- Create the main sprite part
    local spritePart = Instance.new("Part")
    spritePart.Name = "SpritePart"
    spritePart.Size = Vector3.new(4, 0.1, 4)
    spritePart.Material = Enum.Material.Neon
    spritePart.Color = Color3.new(0, 0, 0)
    spritePart.Transparency = 1
    spritePart.CanCollide = false
    spritePart.Anchored = true
    spritePart.CFrame = CFrame.new(worldPosition)
    spritePart.CastShadow = false
    spritePart.Parent = model

    -- Create surface GUI for the sprite
    local spriteGui = Instance.new("SurfaceGui")
    spriteGui.Face = Enum.NormalId.Top
    spriteGui.Parent = spritePart

    local spriteImage = Instance.new("ImageLabel")
    spriteImage.Size = UDim2.fromScale(1, 1)
    spriteImage.BackgroundTransparency = 1
    spriteImage.Image = SpriteConfig.SHEET_ASSET
    spriteImage.ImageTransparency = 0
    spriteImage.ScaleType = Enum.ScaleType.Stretch
    spriteImage.Parent = spriteGui

    -- Apply the specified sprite coordinates
    local spriteIndex = SpriteConfig.getIndexFromGrid(x, y)
    local offset, size = SpriteConfig.getSpriteRect(spriteIndex)
    if offset and size then
        spriteImage.ImageRectOffset = offset
        spriteImage.ImageRectSize = size
    else
        spriteImage.ImageRectOffset = Vector2.new(0, 0)
        spriteImage.ImageRectSize = SpriteConfig.DEFAULT_IMAGE_RECT_SIZE
    end

    -- Add click detector for pickup
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = spritePart

    clickDetector.MouseClick:Connect(function(clickingPlayer)
        if clickingPlayer == player then
            logDebug("Test item picked up", { player = player.Name })
            model:Destroy()
        end
    end)

    logDebug("Test item created", { player = player.Name, position = worldPosition, spriteX = x, spriteY = y })
end)

-- Connect balloon present drop event
balloonPresentDropped.Event:Connect(function(itemId, count, position)
    logInfo("🎁 Balloon present dropped", { itemId = itemId, count = count, position = position })

    -- Create the dropped item at the present's position
    -- We need to find the nearest player or just spawn it for anyone to pick up
    -- For now, create it without a specific player (anyone can pick it up)
    createDroppedItem(nil, itemId, count, position)
end)

-- Start balloon spawner system
logInfo("🎈 Starting balloon spawner system...")
task.spawn(function()
    BalloonSpawner.start()
end)

-- Handle balloon hit events from client
balloonHitRemote.OnServerEvent:Connect(function(player, balloonName)
    logInfo("🎈 Balloon hit received", { player = player.Name, balloonName = balloonName })

    -- Extract balloon ID from name (e.g., "Balloon_5" -> 5)
    local balloonId = tonumber(string.match(balloonName, "%d+"))
    if balloonId then
        -- Call the balloon hit handler
        BalloonSpawner.onBalloonHit(balloonId, nil)
        logInfo("✅ Balloon popped", { balloonId = balloonId })
        if dailyChallengeService then
            dailyChallengeService:recordEvent(player, "balloon_pop", 1)
        end
    else
        warn("[Server] ⚠️ Invalid balloon name:", balloonName)
    end
end)

-- Initialize Product Purchase Handler for Robux monetization
local ProductPurchaseHandler = require(script.ProductPurchaseHandler)
ProductPurchaseHandler.init()
logInfo("✅ ProductPurchaseHandler initialized")

-- Initialize Daily Challenge Service
logInfo("📅 Initializing Daily Challenge Service...")
dailyChallengeService = DailyChallengeService.new()
dailyChallengeService:initialize()
logInfo("✅ Daily Challenge Service initialized")

-- Initialize Quest System
logInfo("📋 Initializing Quest System...")
local QuestData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestData"))

questService = QuestService.new()
questService:initialize()
QuestHandlers.initialize(questService)

-- Hook quest handlers into game systems
-- Note: Fishing system already has a handler above, we'll update it to include quest tracking

-- Give new players tutorial quests
Players.PlayerAdded:Connect(function(player)
    task.wait(2) -- Wait for player to fully load

    -- Check if player has any quests
    local existingQuests = questService:GetPlayerQuests(player.UserId)
    if not existingQuests or next(existingQuests) == nil then
        -- New player - give tutorial quests
        logInfo("🎯 Giving tutorial quests", { player = player.Name })
        questService:CreateQuest(player.UserId, QuestData.TUTORIAL_QUESTS.fishing_tutorial)
        questService:CreateQuest(player.UserId, QuestData.TUTORIAL_QUESTS.crafting_tutorial)
        questService:CreateQuest(player.UserId, QuestData.TUTORIAL_QUESTS.collect_fruit)
        questService:CreateQuest(player.UserId, QuestData.TUTORIAL_QUESTS.chop_trees)
        questService:CreateQuest(player.UserId, QuestData.TUTORIAL_QUESTS.gather_stone)

        -- Give a random daily quest
        local dailyQuest = QuestData.getRandomDailyQuest()
        if dailyQuest then
            questService:CreateQuest(player.UserId, dailyQuest)
        end
    end
end)

logInfo("✅ Quest System initialized!")

-- Initialize Resource Spawner
logInfo("🌳 Initializing Resource Spawner...")
local resourceSpawner = ResourceSpawner.new()
resourceSpawner:initialize()
logInfo("✅ Resource Spawner initialized")

-- Initialize Tool Interaction System
logInfo("🔨 Initializing Tool Interaction System...")
local toolInteractionSystem = ToolInteractionSystem.new(resourceSpawner)
toolInteractionSystem:initialize()
toolInteractionSystem:setAddItemFunction(addItemToInventory)
logInfo("✅ Tool Interaction System initialized")

-- Initialize NookPlane Delivery Service
logInfo("✈️ Initializing NookPlane Delivery Service...")
NookPlaneService.initialize(remoteEventsFolder, addItemToInventory)
logInfo("✅ NookPlane Delivery Service initialized")

-- Initialize Shop Transaction Handler for Nook Shopping purchases
logInfo("🛒 Initializing Shop Transaction Handler...")
local shopTransactionRemote = ensureRemoteEvent(remoteEventsFolder, "ShopTransaction")
local shopFeedbackRemote = ensureRemoteEvent(remoteEventsFolder, "ShopFeedback")

-- Player pending deliveries (items waiting to be delivered via mail)
local playerPendingDeliveries = {} -- [playerId] = { {itemId, count, orderedAt}, ... }

shopTransactionRemote.OnServerEvent:Connect(function(player, action, data)
    print(string.format("[ShopTransaction] 📦 Received: player=%s action=%s", player and player.Name or "nil", tostring(action)))

    if not player or not action or not data then
        print("[ShopTransaction] ⚠️ Missing player, action, or data")
        return
    end

    if action == "BuyItem" then
        local itemId = data.itemId
        local price = data.price or 0
        local count = data.count or 1
        local deliveryMethod = data.deliveryMethod or "instant"

        print(string.format("[ShopTransaction] 🛒 BuyItem: %s x%d for %d bells (delivery: %s)",
            tostring(itemId), count, price, deliveryMethod))

        if not itemId then
            shopFeedbackRemote:FireClient(player, "PurchaseFailed", {
                reason = "Invalid item",
            })
            return
        end

        -- Check if player has enough bells
        local currentBells = CurrencyManager.getBells(player)
        if currentBells < price then
            shopFeedbackRemote:FireClient(player, "PurchaseFailed", {
                reason = "Not enough bells",
                required = price,
                current = currentBells,
            })
            return
        end

        -- Deduct bells
        local deductSuccess = CurrencyManager.removeBells(player, price)
        if not deductSuccess then
            shopFeedbackRemote:FireClient(player, "PurchaseFailed", {
                reason = "Failed to process payment",
            })
            return
        end

        if deliveryMethod == "instant" then
            -- Add item directly to inventory
            local success, err = addItemToInventory(player, {
                itemId = itemId,
                count = count,
            })

            if success then
                logInfo("🛒 Player purchased item (instant)", {
                    player = player.Name,
                    item = itemId,
                    price = price,
                })

                shopFeedbackRemote:FireClient(player, "PurchaseSuccess", {
                    itemId = itemId,
                    count = count,
                    price = price,
                    deliveryMethod = "instant",
                })

                -- Track for quests/challenges
                if dailyChallengeService then
                    dailyChallengeService:recordEvent(player, "shop_purchase", 1)
                end
            else
                -- Refund bells if inventory add failed
                CurrencyManager.addBells(player, price)
                shopFeedbackRemote:FireClient(player, "PurchaseFailed", {
                    reason = "Inventory full",
                    error = err,
                })
            end
        elseif deliveryMethod == "nookplane" then
            -- NookPlane delivery - plane flies over and drops package
            print(string.format("[ShopTransaction] ✈️ Queueing NookPlane delivery for %s: %s x%d", player.Name, itemId, count))
            local success = NookPlaneService.queueDelivery(player, itemId, count)
            print(string.format("[ShopTransaction] ✈️ Queue result: %s", tostring(success)))

            if success then
                logInfo("✈️ Player purchased item (NookPlane delivery)", {
                    player = player.Name,
                    item = itemId,
                    price = price,
                })

                shopFeedbackRemote:FireClient(player, "PurchaseSuccess", {
                    itemId = itemId,
                    count = count,
                    price = price,
                    deliveryMethod = "nookplane",
                    message = "The DAL plane will deliver your package shortly!",
                })

                -- Track for quests/challenges
                if dailyChallengeService then
                    dailyChallengeService:recordEvent(player, "shop_purchase", 1)
                end
            else
                -- Refund if queue failed
                CurrencyManager.addBells(player, price)
                shopFeedbackRemote:FireClient(player, "PurchaseFailed", {
                    reason = "Delivery service unavailable",
                })
            end
        else
            -- Mail delivery (for Nook Shopping next-day delivery) - fallback
            local playerId = player.UserId
            if not playerPendingDeliveries[playerId] then
                playerPendingDeliveries[playerId] = {}
            end

            table.insert(playerPendingDeliveries[playerId], {
                itemId = itemId,
                count = count,
                orderedAt = os.time(),
                deliveryTime = os.time() + 60, -- 1 minute for testing (in real game: 86400 for 24 hours)
            })

            logInfo("🛒 Player purchased item (mail delivery)", {
                player = player.Name,
                item = itemId,
                price = price,
            })

            shopFeedbackRemote:FireClient(player, "PurchaseSuccess", {
                itemId = itemId,
                count = count,
                price = price,
                deliveryMethod = "mail",
                message = "Your order will be delivered shortly!",
            })
        end
    elseif action == "CheckDeliveries" then
        -- Check if player has any pending deliveries ready
        local playerId = player.UserId
        local deliveries = playerPendingDeliveries[playerId]

        if not deliveries or #deliveries == 0 then
            shopFeedbackRemote:FireClient(player, "DeliveryStatus", {
                pending = {},
                ready = {},
            })
            return
        end

        local now = os.time()
        local pending = {}
        local ready = {}

        for i = #deliveries, 1, -1 do
            local delivery = deliveries[i]
            if now >= delivery.deliveryTime then
                -- Ready for delivery
                table.insert(ready, delivery)
                table.remove(deliveries, i)

                -- Add to inventory
                local success = addItemToInventory(player, {
                    itemId = delivery.itemId,
                    count = delivery.count,
                })

                if success then
                    logInfo("📬 Delivered item to player", {
                        player = player.Name,
                        item = delivery.itemId,
                    })
                end
            else
                table.insert(pending, {
                    itemId = delivery.itemId,
                    count = delivery.count,
                    timeRemaining = delivery.deliveryTime - now,
                })
            end
        end

        shopFeedbackRemote:FireClient(player, "DeliveryStatus", {
            pending = pending,
            ready = ready,
        })
    elseif action == "SellItem" then
        -- Sell item from player inventory for bells
        local itemId = data.itemId
        local count = data.count or 1
        local slotIndex = data.slotIndex

        if not itemId then
            shopFeedbackRemote:FireClient(player, "SellFailed", {
                reason = "Invalid item",
            })
            return
        end

        -- Get sell price for item
        local sellPrice = 100 -- Default fallback

        -- Check resource items first (from ACNH data)
        local resourcePrices = {
            ["softwood"] = 60, ["wood"] = 60, ["hardwood"] = 60,
            ["bamboo-piece"] = 80, ["young-spring-bamboo"] = 200,
            ["iron-nugget"] = 375, ["gold-nugget"] = 10000,
            ["clay"] = 100, ["stone"] = 75,
            ["tree-branch"] = 5, ["weeds"] = 10, ["coconut"] = 250,
            ["conch"] = 700, ["coral"] = 500, ["giant-clam"] = 900,
            ["sand-dollar"] = 120, ["sea-snail"] = 180, ["venus-comb"] = 300,
            ["cowrie"] = 60, ["summer-shell"] = 600,
            ["star-fragment"] = 250, ["large-star-fragment"] = 500,
            ["snowflake"] = 200, ["large-snowflake"] = 2500,
            ["maple-leaf"] = 200, ["cherry-blossom-petal"] = 200,
            ["acorn"] = 200, ["pine-cone"] = 200, ["mushroom"] = 200,
            ["wasp-nest"] = 300,
            ["flimsy-axe"] = 200, ["flimsy-fishing-rod"] = 100,
            ["flimsy-net"] = 100, ["flimsy-shovel"] = 200,
            ["flimsy-watering-can"] = 100, ["ladder"] = 500, ["vaulting-pole"] = 500,
        }

        if resourcePrices[itemId] then
            sellPrice = resourcePrices[itemId]
        end

        -- Try to remove item from inventory
        local removed = false
        local playerId = player.UserId
        local playerInventory = inventories[playerId]

        if playerInventory then
            for i, slot in ipairs(playerInventory) do
                if slot and slot.itemId == itemId then
                    local amountToRemove = math.min(count, slot.count or 1)
                    slot.count = (slot.count or 1) - amountToRemove

                    if slot.count <= 0 then
                        playerInventory[i] = nil
                    end

                    -- Calculate total bells earned
                    local bellsEarned = sellPrice * amountToRemove

                    -- Add bells to player
                    CurrencyManager.addBells(player, bellsEarned)

                    logInfo("💰 Player sold item", {
                        player = player.Name,
                        item = itemId,
                        count = amountToRemove,
                        bells = bellsEarned,
                    })

                    -- Sync inventory
                    syncInventory(player)

                    shopFeedbackRemote:FireClient(player, "SellSuccess", {
                        itemId = itemId,
                        count = amountToRemove,
                        bells = bellsEarned,
                    })

                    removed = true
                    break
                end
            end
        end

        if not removed then
            shopFeedbackRemote:FireClient(player, "SellFailed", {
                reason = "Item not found in inventory",
            })
        end
    end
end)

logInfo("✅ Shop Transaction Handler initialized")

logInfo("✅ All systems initialized!")
