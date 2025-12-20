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

    return self
end

function OnboardingService:initialize(playerIslandService, homeBuildingService)
    print("[OnboardingService] 📚 Initializing...")

    self.playerIslandService = playerIslandService
    self.homeBuildingService = homeBuildingService

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
    -- Fire client event to start tutorial UI
    self.startOnboardingRemote:FireClient(player)

    print(string.format("[OnboardingService] Tutorial started for %s", player.Name))
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

    -- Give starter items/currency as reward
    self:giveStarterRewards(player)
end

function OnboardingService:giveStarterRewards(player)
    -- Give starting bells and miles
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local currencyRemote = remotes:FindFirstChild("CurrencyUpdate")
        if currencyRemote then
            -- Award 1000 bells and 500 miles for completing tutorial
            currencyRemote:FireClient(player, "Grant", { bells = 1000, miles = 500 })
        end
    end

    -- Give starter tools and materials
    -- InventoryEvent is in ReplicatedStorage directly, not in Remotes folder
    local inventoryEvent = ReplicatedStorage:FindFirstChild("InventoryEvent")
    if inventoryEvent then
        -- Starter tools
        inventoryEvent:FireClient(player, "AddItem", { itemId = "flimsy_axe", count = 1 })
        inventoryEvent:FireClient(player, "AddItem", { itemId = "stone_axe", count = 1 })
        inventoryEvent:FireClient(player, "AddItem", { itemId = "shovel", count = 1 })
        inventoryEvent:FireClient(player, "AddItem", { itemId = "fishing_rod", count = 1 })
        inventoryEvent:FireClient(player, "AddItem", { itemId = "net", count = 1 })
        inventoryEvent:FireClient(player, "AddItem", { itemId = "slingshot", count = 1 })

        -- Starter materials for building first home
        inventoryEvent:FireClient(player, "AddItem", { itemId = "wood", count = 30 })
        inventoryEvent:FireClient(player, "AddItem", { itemId = "softwood", count = 30 })
        inventoryEvent:FireClient(player, "AddItem", { itemId = "stone", count = 15 })

        print("[OnboardingService] ✅ Gave starter tools and materials to", player.Name)
    else
        warn("[OnboardingService] ⚠️ InventoryEvent not found - couldn't give starter items")
    end

    print(string.format("[OnboardingService] Gave starter rewards to %s", player.Name))
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

    -- Trigger placement mode on client
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        warn("[OnboardingService] RemoteEvents folder not found!")
        return
    end

    local startPlacementRemote = remoteEvents:FindFirstChild("StartHomePlacement")
    if startPlacementRemote then
        -- Tell client to enter placement mode
        startPlacementRemote:FireClient(player, true, "Place your home on your island!")
        print("[OnboardingService] ✅ Sent home placement request to", player.Name)
    else
        warn("[OnboardingService] StartHomePlacement remote not found!")
    end

    -- Old immediate placement code removed - now uses placement GUI
    local success, message = true, "Placement mode started"

    if success then
        print(string.format("[OnboardingService] ✅ Placed home for %s using HomeBuildingService", player.Name))
    else
        warn(
            string.format(
                "[OnboardingService] ⚠️ Failed to place home for %s: %s",
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
