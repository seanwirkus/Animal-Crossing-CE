--[[
	OnboardingService.luau

	Server-side onboarding/tutorial management.
	Tracks player tutorial progress and handles home building.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OnboardingService = {}
OnboardingService.__index = OnboardingService

local MAX_STARTER_KIT_RETRIES = 3
local BASE_RETRY_DELAY = 2

function OnboardingService.new()
    local self = setmetatable({}, OnboardingService)

    self.playerIslandService = nil -- Will be set during init
    self.homeBuildingService = nil -- Will be set during init
    self.playersWhoReceivedRewards = {} -- Track who got tutorial rewards to prevent duplicates (session-based)
    self.playersWithActiveReward = {} -- Track in-progress grants to avoid double work
    self.playerRetryAttempts = {} -- Track retry attempts per player to prevent spam
    self.hasStarterKit = nil -- Optional inventory check callback

    return self
end

function OnboardingService:initialize(playerIslandService, homeBuildingService, addItemFunc, currencyManager)
    print("[OnboardingService] Initializing...")

    self.playerIslandService = playerIslandService
    self.homeBuildingService = homeBuildingService
    self.currencyManager = currencyManager
    if addItemFunc then
        self.addItemToInventory = addItemFunc
    end

    -- Setup remotes
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "Remotes"
        remotes.Parent = ReplicatedStorage
    end

    -- Start onboarding remote (server -> client)
    local startOnboardingRemote = remotes:FindFirstChild("StartOnboarding")
    if not startOnboardingRemote then
        startOnboardingRemote = Instance.new("RemoteEvent")
        startOnboardingRemote.Name = "StartOnboarding"
        startOnboardingRemote.Parent = remotes
    end
    self.startOnboardingRemote = startOnboardingRemote

    -- Tutorial complete remote (client -> server)
    local tutorialCompleteRemote = remotes:FindFirstChild("TutorialComplete")
    if not tutorialCompleteRemote then
        tutorialCompleteRemote = Instance.new("RemoteEvent")
        tutorialCompleteRemote.Name = "TutorialComplete"
        tutorialCompleteRemote.Parent = remotes
    end

    tutorialCompleteRemote.OnServerEvent:Connect(function(player)
        self:onTutorialComplete(player)
    end)

    -- Build home remote (client -> server)
    local buildHomeRemote = remotes:FindFirstChild("BuildPlayerHome")
    if not buildHomeRemote then
        buildHomeRemote = Instance.new("RemoteEvent")
        buildHomeRemote.Name = "BuildPlayerHome"
        buildHomeRemote.Parent = remotes
    end

    buildHomeRemote.OnServerEvent:Connect(function(player)
        self:buildPlayerHome(player)
    end)

    -- Listen for new players
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoined(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        local userId = player.UserId
        self.playersWithActiveReward[userId] = nil
        self.playerRetryAttempts[userId] = nil
    end)

    print("[OnboardingService] Initialized")
end

function OnboardingService:setAddItemFunction(addItemFunc)
    self.addItemToInventory = addItemFunc
end

function OnboardingService:setStarterKitCheckFunction(checkFunc)
    self.hasStarterKit = checkFunc
end

function OnboardingService:_hasReceivedStarterKit(player)
    if self.hasStarterKit then
        local ok, hasKit = pcall(self.hasStarterKit, player)
        if ok and not hasKit then
            return false
        end
    end

    -- Check session-based tracking first
    if self.playersWhoReceivedRewards[player.UserId] then
        return true
    end

    -- Check DataStore-based tracking via PlayerIslandService
    if self.playerIslandService then
        local islandData = self.playerIslandService:getPlayerIsland(player.UserId)
        if islandData and islandData.hasReceivedStarterKit then
            -- Sync session state with DataStore state
            self.playersWhoReceivedRewards[player.UserId] = true
            return true
        end
    end

    return false
end

function OnboardingService:onPlayerJoined(player)
    -- Wait a moment for island to be created
    task.wait(2)

    -- Check if player needs tutorial
    if self.playerIslandService then
        local islandData = self.playerIslandService:getPlayerIsland(player.UserId)

        if islandData and not islandData.hasCompletedTutorial then
            self:startTutorial(player)
        elseif not islandData then
            -- New player without island data - still start tutorial
            self:startTutorial(player)
        elseif islandData and not islandData.hasReceivedStarterKit then
            -- Tutorial already complete but kit missing; grant without restarting onboarding UI.
            task.spawn(function()
                self:giveStarterKit(player, self.currencyManager)
            end)
        end
    end
end

function OnboardingService:startTutorial(player)
    -- Give starter kit in background (waits for inventory system to be ready)
    task.spawn(function()
        self:giveStarterKit(player, self.currencyManager)
    end)

    -- Fire client event to start tutorial UI
    self.startOnboardingRemote:FireClient(player)

    print(string.format("[OnboardingService] Tutorial started for %s", player.Name))
end

function OnboardingService:_waitForInventory(player)
    local maxWait = 20
    local waited = 0

    while player and player.Parent and waited < maxWait do
        local hasInventoryAttributes = player:GetAttribute("InventoryMaxSlots") ~= nil
            or player:GetAttribute("InventoryLevel") ~= nil
        if hasInventoryAttributes then
            return true
        end

        task.wait(0.5)
        waited += 0.5
    end

    return false
end

function OnboardingService:_waitForAddItemFunction()
    -- Wait up to 30 seconds for the addItemToInventory function to be set
    local maxWait = 300
    local waited = 0

    while not self.addItemToInventory and waited < maxWait do
        task.wait(0.1)
        waited = waited + 1
    end

    return self.addItemToInventory ~= nil
end

function OnboardingService:_scheduleStarterKitRetry(player, currencyManager)
    local userId = player.UserId
    self.playersWithActiveReward[userId] = nil

    if self.playerRetryAttempts[userId] >= MAX_STARTER_KIT_RETRIES then
        warn("[OnboardingService] Max retries reached for starter kit for", player.Name)
        return
    end

    local delaySeconds = BASE_RETRY_DELAY * (2 ^ (self.playerRetryAttempts[userId] - 1))
    task.delay(delaySeconds, function()
        if player and player.Parent and not self:_hasReceivedStarterKit(player) then
            self:giveStarterKit(player, currencyManager)
        end
    end)
end

function OnboardingService:_grantStarterItems(player)
    -- Wait for the addItemToInventory function to be set (if not already set)
    if not self.addItemToInventory then
        local ready = self:_waitForAddItemFunction()
        if not ready then
            warn("[OnboardingService] addItemToInventory function not set - items cannot be granted")
            return false
        end
    end

    local starterItems = {
        -- Flimsy tools (starter tier)
        { itemId = "flimsy-axe", count = 1 },
        { itemId = "flimsy-shovel", count = 1 },
        { itemId = "flimsy-pickaxe", count = 1 },
        { itemId = "flimsy-net", count = 1 },
        { itemId = "flimsy-fishing-rod", count = 1 },
        -- Upgraded tools
        { itemId = "axe", count = 1 },
        { itemId = "shovel", count = 1 },
        { itemId = "net", count = 1 },
        { itemId = "fishing-rod", count = 1 },
    }

    local anySuccess = false
    for _, item in ipairs(starterItems) do
        local success, err = self.addItemToInventory(player, item)
        if success then
            anySuccess = true
        else
            warn(string.format("[OnboardingService] Failed to add %s: %s", item.itemId, tostring(err)))
        end
    end

    if anySuccess then
        print(string.format("[OnboardingService] Gave starter tools to %s", player.Name))
    end

    return anySuccess
end

function OnboardingService:giveStarterKit(player, currencyManager)
    -- Check if player already received starter kit (checks both session and DataStore)
    if self:_hasReceivedStarterKit(player) then
        return
    end

    if self.playersWithActiveReward[player.UserId] then
        return
    end

    -- Initialize retry counter if not already set
    if not self.playerRetryAttempts[player.UserId] then
        self.playerRetryAttempts[player.UserId] = 0
    end

    -- Max 3 retries to prevent infinite spam
    if self.playerRetryAttempts[player.UserId] >= MAX_STARTER_KIT_RETRIES then
        warn("[OnboardingService] Max retries reached for starter kit for", player.Name)
        self.playersWithActiveReward[player.UserId] = nil
        return
    end

    self.playersWithActiveReward[player.UserId] = true
    self.playerRetryAttempts[player.UserId] = self.playerRetryAttempts[player.UserId] + 1

    local ready = self:_waitForInventory(player)
    if not ready then
        self:_scheduleStarterKitRetry(player, currencyManager)
        return
    end

    -- Give starter tools so player can gather resources
    local gaveItems = self:_grantStarterItems(player)

    if not gaveItems then
        self:_scheduleStarterKitRetry(player, currencyManager)
        return
    end

    -- Give starting bells and miles via CurrencyManager
    if currencyManager then
        local bellsSuccess = currencyManager.addBells(player, 1000)
        local milesSuccess = currencyManager.addMiles(player, 500)

        if bellsSuccess and milesSuccess then
            print(string.format("[OnboardingService] Gave currency to %s", player.Name))
        else
            warn("[OnboardingService] Currency grant partially failed")
        end
    else
        warn("[OnboardingService] CurrencyManager is nil - cannot grant currency")
    end

    -- Mark as completed in session
    self.playersWhoReceivedRewards[player.UserId] = true
    self.playersWithActiveReward[player.UserId] = nil
    self.playerRetryAttempts[player.UserId] = nil

    -- Persist to DataStore via PlayerIslandService
    if self.playerIslandService then
        local islandData = self.playerIslandService:getPlayerIsland(player.UserId)
        if islandData then
            islandData.hasReceivedStarterKit = true
            self.playerIslandService:saveIsland(player.UserId, islandData)
        end
    end
end

function OnboardingService:onTutorialComplete(player)
    -- Mark tutorial as complete in island data
    if self.playerIslandService then
        local islandData = self.playerIslandService:getPlayerIsland(player.UserId)

        if islandData then
            islandData.hasCompletedTutorial = true
            self.playerIslandService:saveIsland(player.UserId, islandData)
        end
    end

    print(string.format("[OnboardingService] %s finished tutorial", player.Name))
end

function OnboardingService:buildPlayerHome(player)
    print(string.format("[OnboardingService] Starting home placement for %s", player.Name))

    if not self.playerIslandService then
        warn("[OnboardingService] PlayerIslandService not available")
        return
    end

    local islandData = self.playerIslandService:getPlayerIsland(player.UserId)
    if not islandData then
        print(string.format("[OnboardingService] No island data for %s yet - skipping home build", player.Name))
        return
    end

    -- Note: hasBuiltHome check removed from here - HomeBuildingService will validate when player confirms placement
    -- This allows the placement GUI to open and show proper error messages if already built

    if not self.homeBuildingService then
        warn("[OnboardingService] HomeBuildingService not available")
        return
    end

    local success, message = self.homeBuildingService:RequestPlacement(player)

    if success then
        print(string.format("[OnboardingService] ✅ Placement mode started for %s", player.Name))
    else
        warn(
            string.format(
                "[OnboardingService] ⚠️ Home placement blocked for %s: %s",
                player.Name,
                message or "Unknown error"
            )
        )
    end
    self.playerIslandService:saveIsland(player.UserId, islandData)
end

function OnboardingService:createSimpleTent(position)
    local tent = Instance.new("Model")
    tent.Name = "TentHouse"

    -- Tent body (triangular prism shape)
    local body = Instance.new("WedgePart")
    body.Name = "TentBody"
    body.Size = Vector3.new(8, 6, 6)
    body.Position = position + Vector3.new(0, 3, 0)
    body.Orientation = Vector3.new(0, 0, 0)
    body.Anchored = true
    body.Material = Enum.Material.Fabric
    body.BrickColor = BrickColor.new("Bright red")
    body.Parent = tent

    -- Floor
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(8, 0.5, 6)
    floor.Position = position
    floor.Anchored = true
    floor.Material = Enum.Material.Wood
    floor.BrickColor = BrickColor.new("Brown")
    floor.Parent = tent

    -- Door (entrance)
    local door = Instance.new("Part")
    door.Name = "Door"
    door.Size = Vector3.new(2, 4, 0.2)
    door.Position = position + Vector3.new(0, 2, -3)
    door.Anchored = true
    door.Material = Enum.Material.Fabric
    door.BrickColor = BrickColor.new("Dark orange")
    door.Parent = tent

    tent.PrimaryPart = floor

    return tent
end

return OnboardingService
