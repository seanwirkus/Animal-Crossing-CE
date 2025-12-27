--[[
	OnboardingService.luau
	
	Server-side onboarding/tutorial management.
	Tracks player tutorial progress and handles home building.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OnboardingService = {}
OnboardingService.__index = OnboardingService

function OnboardingService.new()
    local self = setmetatable({}, OnboardingService)

    self.playerIslandService = nil -- Will be set during init
    self.homeBuildingService = nil -- Will be set during init
    self.playersWhoReceivedRewards = {} -- Track who got tutorial rewards to prevent duplicates
    self.playersWithActiveReward = {} -- Track in-progress grants to avoid double work
    self.playerRetryAttempts = {} -- Track retry attempts per player to prevent spam

    return self
end

function OnboardingService:initialize(playerIslandService, homeBuildingService, addItemFunc, currencyManager)
    print("[OnboardingService] 📚 Initializing...")

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

    print("[OnboardingService] ✅ Initialized")
end

function OnboardingService:setAddItemFunction(addItemFunc)
    self.addItemToInventory = addItemFunc
end

function OnboardingService:onPlayerJoined(player)
    -- Wait a moment for island to be created
    task.wait(2)

    -- Check if player needs tutorial
    if self.playerIslandService then
        local islandData = self.playerIslandService:getPlayerIsland(player.UserId)

        if islandData and not islandData.hasCompletedTutorial then
            print(string.format("[OnboardingService] Starting tutorial for %s", player.Name))
            self:startTutorial(player)
        elseif not islandData then
            -- New player without island data - still start tutorial
            print(string.format("[OnboardingService] New player detected: %s - starting tutorial anyway", player.Name))
            self:startTutorial(player)
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
        if self.addItemToInventory and hasInventoryAttributes then
            return true
        end

        task.wait(0.5)
        waited += 0.5
    end

    return false
end

function OnboardingService:_waitForAddItemFunction()
    -- Wait up to 10 seconds for the addItemToInventory function to be set
    local maxWait = 100
    local waited = 0

    while not self.addItemToInventory and waited < maxWait do
        task.wait(0.1)
        waited = waited + 1
    end

    return self.addItemToInventory ~= nil
end

function OnboardingService:_grantStarterItems(player)
    print(string.format("[OnboardingService] 🛠️ _grantStarterItems called for %s", player.Name))
    print(string.format("[OnboardingService] Debug: addItemToInventory is nil: %s", tostring(self.addItemToInventory == nil)))

    -- Wait for the addItemToInventory function to be set (if not already set)
    if not self.addItemToInventory then
        print("[OnboardingService] ⏳ Waiting for addItemToInventory function to be set...")
        local ready = self:_waitForAddItemFunction()
        if not ready then
            warn("[OnboardingService] ⚠️ addItemToInventory function not set after waiting - items cannot be granted")
            return false
        end
        print("[OnboardingService] ✅ addItemToInventory function is now available")
    end

    local starterItems = {
        { itemId = "flimsy-axe", count = 1 },
        { itemId = "axe", count = 1 },
        { itemId = "flimsy-shovel", count = 1 },
        { itemId = "colorful-fishing-rod", count = 1 },
        { itemId = "net", count = 1 },
        { itemId = "slingshot", count = 1 },
    }

    for _, item in ipairs(starterItems) do
        local success, err = self.addItemToInventory(player, item)
        if not success then
            warn(string.format("[OnboardingService] ⚠️ Failed to add %s: %s", item.itemId, tostring(err)))
            return false
        end
    end

    return true
end

function OnboardingService:giveStarterKit(player, currencyManager)
    -- Check if player already received starter kit
    if self.playersWhoReceivedRewards[player.UserId] then
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
    if self.playerRetryAttempts[player.UserId] >= 3 then
        warn("[OnboardingService] ⚠️ Max retries reached for starter kit for", player.Name, "- giving up")
        self.playersWhoReceivedRewards[player.UserId] = true
        self.playersWithActiveReward[player.UserId] = nil
        return
    end

    self.playersWithActiveReward[player.UserId] = true
    self.playerRetryAttempts[player.UserId] = self.playerRetryAttempts[player.UserId] + 1

    print(string.format("[OnboardingService] 🎁 Starting starter kit grant for %s (attempt %d)", player.Name, self.playerRetryAttempts[player.UserId]))

    local ready = self:_waitForInventory(player)
    if not ready then
        self.playersWithActiveReward[player.UserId] = nil
        if self.playerRetryAttempts[player.UserId] < 3 then
            task.delay(2, function()
                if player and player.Parent and not self.playersWhoReceivedRewards[player.UserId] then
                    self:giveStarterKit(player, currencyManager)
                end
            end)
        end
        return
    end

    -- Give starter tools so player can gather resources
    local gaveItems = self:_grantStarterItems(player)

    if not gaveItems then
        self.playersWithActiveReward[player.UserId] = nil
        if self.playerRetryAttempts[player.UserId] < 3 then
            task.delay(2, function()
                if player and player.Parent and not self.playersWhoReceivedRewards[player.UserId] then
                    self:giveStarterKit(player, currencyManager)
                end
            end)
        end
        return
    end

    print("[OnboardingService] ✅ Gave starter tools to", player.Name)

    -- Give starting bells and miles DIRECTLY via CurrencyManager
    if currencyManager then
        local bellsSuccess = currencyManager.addBells(player, 1000)
        local milesSuccess = currencyManager.addMiles(player, 500)

        if bellsSuccess and milesSuccess then
            print("[OnboardingService] ✅ Gave 1000 bells and 500 miles to", player.Name)
        else
            warn("[OnboardingService] ⚠️ Currency grant partially failed")
        end
    end

    -- Mark as completed AFTER all items are given
    self.playersWhoReceivedRewards[player.UserId] = true
    self.playersWithActiveReward[player.UserId] = nil
    self.playerRetryAttempts[player.UserId] = nil
end

function OnboardingService:onTutorialComplete(player)
    print(string.format("[OnboardingService] Tutorial completed by %s", player.Name))

    -- Mark tutorial as complete in island data
    if self.playerIslandService then
        local islandData = self.playerIslandService:getPlayerIsland(player.UserId)

        if islandData then
            islandData.hasCompletedTutorial = true
            self.playerIslandService:saveIsland(player.UserId, islandData)
        end
    end

    -- Starter kit is already given at tutorial START, so just log completion
    print(string.format("[OnboardingService] ✅ %s finished tutorial!", player.Name))
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
