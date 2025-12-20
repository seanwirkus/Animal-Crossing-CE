-- HomeBuildingService
-- Handles player home placement, upgrades, and management
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local HomeBuildingService = {}
HomeBuildingService.__index = HomeBuildingService

-- Will be set during initialization
local CurrencyManager = nil
local InventoryCheckFunction = nil
local InventoryConsumeFunction = nil

local _instance = nil

-- Home upgrade costs (in bells)
local HOME_COSTS = {
    Tent = 0, -- No bells required for tent
    SmallHouse = 5000,
    LargeHouse = 10000,
    Mansion = 25000,
}

-- Home upgrade materials (REQUIRED for building)
local HOME_MATERIALS = {
    Tent = {
        { itemId = "wood", count = 30 },
        { itemId = "softwood", count = 30 },
        { itemId = "stone", count = 15 },
    },
    SmallHouse = {
        { itemId = "wood", count = 50 },
        { itemId = "hardwood", count = 30 },
        { itemId = "iron_nugget", count = 20 },
        { itemId = "stone", count = 30 },
    },
    LargeHouse = {
        { itemId = "wood", count = 80 },
        { itemId = "hardwood", count = 50 },
        { itemId = "iron_nugget", count = 40 },
        { itemId = "clay", count = 30 },
    },
    Mansion = {
        { itemId = "wood", count = 150 },
        { itemId = "hardwood", count = 100 },
        { itemId = "iron_nugget", count = 80 },
        { itemId = "gold_nugget", count = 10 },
    },
}

function HomeBuildingService.new()
    if _instance then
        return _instance
    end

    local self = setmetatable({}, HomeBuildingService)

    self._playerHomes = {} -- [userId] = homeData
    self._homeModels = {} -- [userId] = Model
    self._playerIslandService = nil -- Will be set by init
    self._startPlacementRemote = nil

    -- Setup RemoteEvents
    self:_setupRemoteEvents()

    -- Load existing homes
    self:_loadExistingHomes()

    _instance = self
    print("[HomeBuildingService] ✅ Initialized")
    return self
end

-- Set PlayerIslandService reference (called from init.server)
function HomeBuildingService:SetPlayerIslandService(service)
    self._playerIslandService = service
    print("[HomeBuildingService] ✅ Connected to PlayerIslandService")
end

-- Set CurrencyManager reference (called from init.server)
function HomeBuildingService:SetCurrencyManager(manager)
    CurrencyManager = manager
    print("[HomeBuildingService] ✅ Connected to CurrencyManager")
end

-- Set inventory functions (called from init.server)
function HomeBuildingService:SetInventoryFunctions(hasMaterialsFunc, consumeMaterialsFunc)
    InventoryCheckFunction = hasMaterialsFunc
    InventoryConsumeFunction = consumeMaterialsFunc
    print("[HomeBuildingService] ✅ Connected to Inventory system")
end

local function formatMaterials(materials)
    local formatted = {}
    for _, material in ipairs(materials or {}) do
        table.insert(formatted, string.format("%dx %s", material.count, material.itemId))
    end
    return table.concat(formatted, ", ")
end

function HomeBuildingService:_validatePlacementPrerequisites(player, materials)
    if not player or not player.Parent then
        return false, "Player not available", materials
    end

    if self:HasHome(player) then
        return false, "You already have a home placed.", materials
    end

    if self._playerIslandService then
        local islandData = self._playerIslandService:getPlayerIsland(player.UserId)
        if not islandData then
            return false, "Finish onboarding to generate your island before placing a home.", materials
        end
    end

    if not InventoryCheckFunction then
        return false, "Resource checks are offline until the inventory/resource systems finish loading.", materials
    end

    local hasMaterials, missingItem = InventoryCheckFunction(player, materials)
    if not hasMaterials then
        local missingText = missingItem or formatMaterials(materials)
        return false, "Gather materials first: " .. missingText, materials
    end

    return true, "Ready to place your home!", materials
end

function HomeBuildingService:RequestPlacement(player, homeSize)
    local materials = HOME_MATERIALS[homeSize or "Tent"] or HOME_MATERIALS.Tent
    local success, message = self:_validatePlacementPrerequisites(player, materials)

    if self._startPlacementRemote then
        self._startPlacementRemote:FireClient(player, success, message, materials)
    else
        warn("[HomeBuildingService] StartHomePlacement remote missing while handling placement request")
    end

    return success, message, materials
end

function HomeBuildingService:_setupRemoteEvents()
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = ReplicatedStorage
    end

    -- PlaceHome RemoteEvent
    local placeHomeRemote = remoteEventsFolder:FindFirstChild("PlaceHome")
    if not placeHomeRemote then
        placeHomeRemote = Instance.new("RemoteEvent")
        placeHomeRemote.Name = "PlaceHome"
        placeHomeRemote.Parent = remoteEventsFolder
    end

    placeHomeRemote.OnServerEvent:Connect(function(player, position)
        local success, message = self:PlaceHome(player, position)
        if success then
            -- Send home data update to client
            self:_sendHomeDataUpdate(player)
        end
    end)

    -- StartHomePlacement RemoteEvent (opens placement GUI)
    local startPlacementRemote = remoteEventsFolder:FindFirstChild("StartHomePlacement")
    if not startPlacementRemote then
        startPlacementRemote = Instance.new("RemoteEvent")
        startPlacementRemote.Name = "StartHomePlacement"
        startPlacementRemote.Parent = remoteEventsFolder
    end

    self._startPlacementRemote = startPlacementRemote

    startPlacementRemote.OnServerEvent:Connect(function(player)
        self:RequestPlacement(player)
    end)

    -- UpgradeHome RemoteEvent
    local upgradeHomeRemote = remoteEventsFolder:FindFirstChild("UpgradeHome")
    if not upgradeHomeRemote then
        upgradeHomeRemote = Instance.new("RemoteEvent")
        upgradeHomeRemote.Name = "UpgradeHome"
        upgradeHomeRemote.Parent = remoteEventsFolder
    end

    upgradeHomeRemote.OnServerEvent:Connect(function(player)
        local success, message = self:UpgradeHome(player)
        
        -- Send upgrade result to client
        local upgradeResultRemote = remoteEventsFolder:FindFirstChild("HomeUpgradeResult")
        if not upgradeResultRemote then
            upgradeResultRemote = Instance.new("RemoteEvent")
            upgradeResultRemote.Name = "HomeUpgradeResult"
            upgradeResultRemote.Parent = remoteEventsFolder
        end
        upgradeResultRemote:FireClient(player, success, message)
        
        if success then
            -- Send updated home data
            self:_sendHomeDataUpdate(player)
        end
    end)

    -- RequestHomeData RemoteEvent
    local requestHomeDataRemote = remoteEventsFolder:FindFirstChild("RequestHomeData")
    if not requestHomeDataRemote then
        requestHomeDataRemote = Instance.new("RemoteEvent")
        requestHomeDataRemote.Name = "RequestHomeData"
        requestHomeDataRemote.Parent = remoteEventsFolder
    end

    requestHomeDataRemote.OnServerEvent:Connect(function(player)
        self:_sendHomeDataUpdate(player)
    end)
end

function HomeBuildingService:_sendHomeDataUpdate(player)
    local userId = player.UserId
    local homeData = self._playerHomes[userId]
    
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        return
    end

    local homeDataUpdateRemote = remoteEventsFolder:FindFirstChild("HomeDataUpdate")
    if not homeDataUpdateRemote then
        homeDataUpdateRemote = Instance.new("RemoteEvent")
        homeDataUpdateRemote.Name = "HomeDataUpdate"
        homeDataUpdateRemote.Parent = remoteEventsFolder
    end

    -- Send home data to client (or nil if no home)
    homeDataUpdateRemote:FireClient(player, homeData)
end

function HomeBuildingService:_loadExistingHomes()
    local playerHomesFolder = Workspace:FindFirstChild("PlayerHomes")
    if not playerHomesFolder then
        playerHomesFolder = Instance.new("Folder")
        playerHomesFolder.Name = "PlayerHomes"
        playerHomesFolder.Parent = Workspace
    end

    -- Load existing homes
    for _, home in ipairs(playerHomesFolder:GetChildren()) do
        if home:IsA("Model") and home:GetAttribute("HomeOwner") then
            local ownerId = home:GetAttribute("HomeOwner")
            self._homeModels[ownerId] = home

            -- Reconstruct home data
            local homeData = {
                owner = ownerId,
                position = home:GetPivot().Position,
                size = home:GetAttribute("HomeSize") or "Tent",
                rooms = home:GetAttribute("Rooms") or 1,
                created = home:GetAttribute("Created") or os.time(),
            }

            self._playerHomes[ownerId] = homeData
        end
    end

    print("[HomeBuildingService] ✅ Loaded", #self._homeModels, "existing homes")
end

function HomeBuildingService:PlaceHome(player, position, homeSize)
    local userId = player.UserId
    homeSize = homeSize or "Tent"

    -- Check if player already has a home
    if self._playerHomes[userId] then
        warn("[HomeBuildingService] Player", player.Name, "already has a home")
        return false, "You already have a home!"
    end

    -- Validate position
    if not position or typeof(position) ~= "Vector3" then
        warn("[HomeBuildingService] Invalid position provided")
        return false, "Invalid position"
    end

    -- Check materials FIRST
    local materials = HOME_MATERIALS[homeSize] or HOME_MATERIALS.Tent
    if materials and #materials > 0 then
        -- Check if inventory system is connected
        if not InventoryCheckFunction or not InventoryConsumeFunction then
            warn("[HomeBuildingService] Inventory system not connected!")
            return false, "System error - inventory not available"
        end

        -- Check if player has all required materials
        local hasMaterials, missingItem = InventoryCheckFunction(player, materials)
        if not hasMaterials then
            warn("[HomeBuildingService] Player missing materials:", missingItem)
            return false, "Missing materials: " .. (missingItem or "unknown")
        end

        -- Consume materials
        local consumed = InventoryConsumeFunction(player, materials)
        if not consumed then
            warn("[HomeBuildingService] Failed to consume materials")
            return false, "Failed to consume materials"
        end

        print("[HomeBuildingService] ✅ Consumed materials for", homeSize)
    end

    -- Check if position is valid (flat ground, not too close to other homes, etc.)
    local isValid, reason = self:_validateHomePosition(position, player)
    if not isValid then
        warn("[HomeBuildingService] Invalid home position:", reason)
        -- Refund materials if placement failed
        if materials and #materials > 0 and InventoryCheckFunction then
            -- TODO: Add refund logic
        end
        return false, reason or "Invalid home position"
    end

    -- Create home model
    local homeModel = self:_createHomeModel(player, position, homeSize)
    if not homeModel then
        warn("[HomeBuildingService] Failed to create home model")
        return false, "Failed to create home"
    end

    -- Store home data
    local homeData = {
        owner = userId,
        position = {
            X = position.X,
            Y = position.Y,
            Z = position.Z,
        },
        size = "Tent",
        rooms = 1,
        created = os.time(),
        lastModified = os.time(),
    }

    self._playerHomes[userId] = homeData
    self._homeModels[userId] = homeModel

    -- Save to island data if PlayerIslandService is available
    if self._playerIslandService then
        local islandData = self._playerIslandService:getPlayerIsland(userId)
        if islandData then
            islandData.hasBuiltHome = true
            islandData.home = homeData
            self._playerIslandService:saveIsland(userId)
        end
    end

    print("[HomeBuildingService] ✅ Placed home for", player.Name, "at", position)
    return true, "Home placed successfully!"
end

function HomeBuildingService:_validateHomePosition(position, player)
    -- Check if position is on flat ground (not in the air)
    local rayOrigin = Vector3.new(position.X, position.Y + 5, position.Z)
    local rayDirection = Vector3.new(0, -10, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if not rayResult then
        return false, "Home must be placed on solid ground (not in the air)"
    end

    -- Check if ground is reasonably flat
    local groundY = rayResult.Position.Y
    if math.abs(position.Y - groundY) > 3 then
        return false, "Ground is too steep here"
    end

    -- Check for obstacles/objects in the placement area (10x10 stud area)
    local homeSize = Vector3.new(10, 8, 10) -- Approximate tent size
    local region = Region3.new(
        position - homeSize / 2,
        position + homeSize / 2
    ):ExpandToGrid(4)

    -- Check for parts that would block placement
    local partsInRegion = Workspace:FindPartsInRegion3(region, nil, 100)
    for _, part in ipairs(partsInRegion) do
        -- Ignore terrain and small decorative parts
        if part:IsA("BasePart") and part.Parent then
            local partName = part.Name:lower()
            local parentName = part.Parent.Name:lower()

            -- Allow terrain and ground
            if part.Parent == Workspace.Terrain or partName == "terrain" then
                continue
            end

            -- Block placement near homes, buildings, large rocks, trees
            if parentName:find("home") or parentName:find("building") or
               parentName:find("rock") or parentName:find("tree") or
               parentName:find("tent") or part:GetAttribute("IsObstacle") then
                return false, "Too close to " .. (parentName or "an object")
            end

            -- Check size - if part is large, it's probably an obstacle
            if part.Size.Magnitude > 5 then
                return false, "Area blocked by object: " .. (parentName or part.Name)
            end
        end
    end

    -- Check if on player's island (if PlayerIslandService available)
    if self._playerIslandService then
        local islandData = self._playerIslandService:getPlayerIsland(player.UserId)
        if islandData then
            local islandCenter = Vector3.new(islandData.center.X, islandData.center.Y, islandData.center.Z)
            local islandSize = Vector3.new(islandData.size.X, islandData.size.Y, islandData.size.Z)
            local distanceFromCenter = (position - islandCenter)
            distanceFromCenter = Vector3.new(distanceFromCenter.X, 0, distanceFromCenter.Z)

            -- Check if within island bounds (with some margin)
            local maxDistance = math.min(islandSize.X, islandSize.Z) * 0.9
            if distanceFromCenter.Magnitude > maxDistance then
                return false, "Home must be placed on your island"
            end
        end
    end

    -- Check distance from other homes (minimum 20 studs)
    local playerHomesFolder = Workspace:FindFirstChild("PlayerHomes")
    if playerHomesFolder then
        for _, home in ipairs(playerHomesFolder:GetChildren()) do
            if home:IsA("Model") and home ~= self._homeModels[player.UserId] then
                local homePosition = home:GetPivot().Position
                local distance = (position - homePosition).Magnitude
                if distance < 20 then
                    return false, "Too close to another home (minimum 20 studs)"
                end
            end
        end
    end

    return true, nil
end

function HomeBuildingService:_createHomeModel(player, position, size)
    -- Get home template
    local template = self:_getHomeTemplate(size)
    if not template then
        -- Create fallback tent
        return self:_createFallbackTent(player, position)
    end

    -- Clone template
    local home = template:Clone()
    home.Name = "Home_" .. player.Name

    -- Set attributes
    home:SetAttribute("HomeOwner", player.UserId)
    home:SetAttribute("HomeSize", size)
    home:SetAttribute("Rooms", 1)
    home:SetAttribute("Created", os.time())
    home:SetAttribute("Clickable", true)
    home:SetAttribute("BuildingType", "PlayerHome")

    -- Position home using PivotTo (works with or without PrimaryPart)
    home:PivotTo(CFrame.new(position))

    -- Parent to island folder if PlayerIslandService available, otherwise PlayerHomes
    local parentFolder = nil
    if self._playerIslandService then
        local islandFolder = self._playerIslandService:getPlayerIslandFolder(player.UserId)
        if islandFolder then
            local buildingsFolder = islandFolder:FindFirstChild("Buildings")
            if not buildingsFolder then
                buildingsFolder = Instance.new("Folder")
                buildingsFolder.Name = "Buildings"
                buildingsFolder.Parent = islandFolder
            end
            parentFolder = buildingsFolder
        end
    end

    -- Fallback to PlayerHomes folder
    if not parentFolder then
        parentFolder = Workspace:FindFirstChild("PlayerHomes")
        if not parentFolder then
            parentFolder = Instance.new("Folder")
            parentFolder.Name = "PlayerHomes"
            parentFolder.Parent = Workspace
        end
    end

    home.Parent = parentFolder

    return home
end

function HomeBuildingService:_getHomeTemplate(size)
    -- First, try to find PlayerHome in ReplicatedStorage (user added this)
    local playerHome = ReplicatedStorage:FindFirstChild("PlayerHome")
    if playerHome and playerHome:IsA("Model") then
        print("[HomeBuildingService] ✅ Found PlayerHome model in ReplicatedStorage")
        return playerHome
    end

    -- Fallback: Try to find template in ReplicatedStorage/Models
    local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
    if modelsFolder then
        local templateName = size == "Tent" and "Tent" or "House"
        local template = modelsFolder:FindFirstChild(templateName)
        if template and template:IsA("Model") then
            print("[HomeBuildingService] ✅ Found template:", templateName, "in Models folder")
            return template
        end
    end

    print("[HomeBuildingService] ⚠️ No home template found, will use fallback tent")
    return nil
end

function HomeBuildingService:_createFallbackTent(player, position)
    -- Create a simple tent model as fallback
    local tent = Instance.new("Model")
    tent.Name = "Tent_" .. player.Name

    -- Base
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(4, 0.2, 4)
    base.Material = Enum.Material.Fabric
    base.BrickColor = BrickColor.new("Brown")
    base.Anchored = true
    base.CFrame = CFrame.new(position)
    base.Parent = tent

    -- Tent body (triangular)
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(3.5, 2, 3.5)
    body.Material = Enum.Material.Fabric
    body.BrickColor = BrickColor.new("Brown")
    body.Anchored = true
    body.Shape = Enum.PartType.Ball
    body.CFrame = base.CFrame + Vector3.new(0, 1.2, 0)
    body.Parent = tent

    -- Tent pole
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.2, 3, 0.2)
    pole.Material = Enum.Material.Wood
    pole.BrickColor = BrickColor.new("Brown")
    pole.Anchored = true
    pole.CFrame = base.CFrame + Vector3.new(0, 1.5, 0)
    pole.Parent = tent

    tent.PrimaryPart = base

    -- Set attributes
    tent:SetAttribute("HomeOwner", player.UserId)
    tent:SetAttribute("HomeSize", "Tent")
    tent:SetAttribute("Rooms", 1)
    tent:SetAttribute("Created", os.time())

    -- Parent to PlayerHomes folder
    local playerHomesFolder = Workspace:FindFirstChild("PlayerHomes")
    if not playerHomesFolder then
        playerHomesFolder = Instance.new("Folder")
        playerHomesFolder.Name = "PlayerHomes"
        playerHomesFolder.Parent = Workspace
    end

    tent.Parent = playerHomesFolder

    print("[HomeBuildingService] ⚠️ Created fallback tent for", player.Name)
    return tent
end

function HomeBuildingService:UpgradeHome(player)
    local userId = player.UserId
    local homeData = self._playerHomes[userId]

    if not homeData then
        warn("[HomeBuildingService] Player", player.Name, "doesn't have a home")
        return false, "You don't have a home to upgrade"
    end

    -- Upgrade logic (Tent -> Small House -> Large House, etc.)
    local currentSize = homeData.size
    local newSize = nil

    if currentSize == "Tent" then
        newSize = "SmallHouse"
    elseif currentSize == "SmallHouse" then
        newSize = "LargeHouse"
    elseif currentSize == "LargeHouse" then
        newSize = "Mansion"
    else
        warn("[HomeBuildingService] Home already at max size")
        return false, "Home is already at maximum size"
    end

    -- Check if player has required bells
    local cost = HOME_COSTS[newSize] or 0
    if cost > 0 then
        if CurrencyManager then
            local currentBells = CurrencyManager.getBells(player)
            if currentBells < cost then
                return false,
                    string.format("Not enough bells! You need %d bells, but only have %d.", cost, currentBells)
            end
        else
            warn("[HomeBuildingService] ⚠️ CurrencyManager not available - skipping cost check")
        end
    end

    -- Check if player has required materials
    local materials = HOME_MATERIALS[newSize] or {}
    if #materials > 0 then
        if InventoryCheckFunction then
            if not InventoryCheckFunction(player, materials, 1) then
                local missingMaterials = {}
                for _, material in ipairs(materials) do
                    table.insert(missingMaterials, material.count .. "x " .. material.itemId)
                end
                return false, "Missing required materials: " .. table.concat(missingMaterials, ", ")
            end
        else
            warn("[HomeBuildingService] ⚠️ Inventory check function not available - skipping material check")
        end
    end

    -- Charge bells
    if cost > 0 and CurrencyManager then
        local success = CurrencyManager.removeBells(player, cost)
        if not success then
            return false, "Failed to charge bells. Please try again."
        end
        print("[HomeBuildingService] 💰 Charged", cost, "bells for home upgrade")
    end

    -- Consume materials
    if #materials > 0 and InventoryConsumeFunction then
        local success = InventoryConsumeFunction(player, materials, 1)
        if not success then
            -- Refund bells if material consumption failed
            if cost > 0 and CurrencyManager then
                CurrencyManager.addBells(player, cost)
            end
            return false, "Failed to consume materials. Please try again."
        end
        print("[HomeBuildingService] 📦 Consumed materials for home upgrade")
    end

    -- Upgrade home model
    local homeModel = self._homeModels[userId]
    if homeModel then
        local position = homeModel:GetPivot().Position
        homeModel:Destroy()

        local newHome = self:_createHomeModel(player, position, newSize)
        if newHome then
            homeData.size = newSize
            homeData.rooms = homeData.rooms + 1
            homeData.lastModified = os.time()

            -- Update position in case it changed
            homeData.position = {
                X = position.X,
                Y = position.Y,
                Z = position.Z,
            }

            self._homeModels[userId] = newHome

            -- Save to island data if PlayerIslandService is available
            if self._playerIslandService then
                local islandData = self._playerIslandService:getPlayerIsland(userId)
                if islandData then
                    islandData.home = homeData
                    self._playerIslandService:saveIsland(userId)
                end
            end

            print("[HomeBuildingService] ✅ Upgraded home for", player.Name, "to", newSize)
            return true, "Home upgraded to " .. newSize .. "!"
        end
    end

    return false, "Failed to upgrade home"
end

-- Get upgrade cost for a home size
function HomeBuildingService:GetUpgradeCost(currentSize)
    local newSize = nil
    if currentSize == "Tent" then
        newSize = "SmallHouse"
    elseif currentSize == "SmallHouse" then
        newSize = "LargeHouse"
    elseif currentSize == "LargeHouse" then
        newSize = "Mansion"
    end

    if newSize then
        return HOME_COSTS[newSize] or 0, HOME_MATERIALS[newSize] or {}
    end

    return nil, nil
end

function HomeBuildingService:GetPlayerHome(player)
    local userId = player.UserId
    return self._playerHomes[userId]
end

function HomeBuildingService:GetPlayerHomeModel(player)
    local userId = player.UserId
    return self._homeModels[userId]
end

function HomeBuildingService:HasHome(player)
    local userId = player.UserId
    return self._playerHomes[userId] ~= nil
end

-- Initialize service
local service = HomeBuildingService.new()

return service
