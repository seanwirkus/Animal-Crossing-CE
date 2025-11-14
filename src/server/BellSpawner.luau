--[[
	BellSpawner.luau
	
	Spawns bell markers (dig spots with bells) around the island
	Players can dig these with a shovel to find bells
	These are similar to X markers but specifically for bells
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BellSpawner = {}

-- Configuration
local BELL_MARKER_ASSET_ID = 95502544899864 -- Can use same X marker or create a bell-specific marker
local NUM_BELLS = 15 -- Number of bell markers to spawn
local SPAWN_RADIUS = 200 -- Spawn within this radius
local SPAWN_HEIGHT = 50 -- Start raycast from this height

-- Bell value range
local BELL_MIN = 100
local BELL_MAX = 1000

-- Valid materials for bells (can spawn on most ground materials, not water)
local validBellMaterials = {
    [Enum.Material.Grass] = true,
    [Enum.Material.Ground] = true, -- Dirt
    [Enum.Material.Sand] = true,
    [Enum.Material.Snow] = true,
    [Enum.Material.Mud] = true,
    -- NOT on Water
}

--[[
	Spawns a bell marker (dig spot) at a specific position
]]
local function spawnBellMarker(position, bellAmount)
    -- Load marker model from asset (can use X marker or create bell-specific)
    local success, markerModel = pcall(function()
        return game:GetService("InsertService"):LoadAsset(BELL_MARKER_ASSET_ID)
    end)

    if not success or not markerModel then
        warn("[BellSpawner] ⚠️ Failed to load bell marker asset")
        return nil
    end

    -- Get the first child (the actual model)
    local bellMarker = markerModel:GetChildren()[1]
    if not bellMarker then
        markerModel:Destroy()
        return nil
    end

    bellMarker = bellMarker:Clone()
    markerModel:Destroy()

    -- Position the bell marker slightly above ground
    if bellMarker:IsA("Model") and bellMarker.PrimaryPart then
        bellMarker:MoveTo(position + Vector3.new(0, 0.1, 0))
    elseif bellMarker:IsA("BasePart") then
        bellMarker.Position = position + Vector3.new(0, 0.1, 0)
    end

    -- Set properties
    bellMarker.Name = "BellMarker"

    -- Add attributes to identify this as a bell spot
    if bellMarker:IsA("Model") then
        bellMarker:SetAttribute("DigType", "bells")
        bellMarker:SetAttribute("ItemId", "bells")
        bellMarker:SetAttribute("BellAmount", bellAmount)
    else
        -- If it's a Part, create a model wrapper
        local wrapper = Instance.new("Model")
        wrapper.Name = "BellMarker"
        wrapper:SetAttribute("DigType", "bells")
        wrapper:SetAttribute("ItemId", "bells")
        wrapper:SetAttribute("BellAmount", bellAmount)
        bellMarker.Parent = wrapper
        bellMarker = wrapper
    end

    -- Add a PointLight to make it glow (golden color for bells)
    local markerPart = bellMarker:IsA("Model")
            and (bellMarker.PrimaryPart or bellMarker:FindFirstChildWhichIsA("BasePart"))
        or bellMarker
    if markerPart and markerPart:IsA("BasePart") then
        local pointLight = Instance.new("PointLight")
        pointLight.Name = "BellGlow"
        pointLight.Range = 5
        pointLight.Brightness = 1.0
        pointLight.Color = Color3.fromRGB(255, 215, 0) -- Gold color
        pointLight.Shadows = false
        pointLight.Parent = markerPart
    end

    -- Parent to workspace
    local bellsFolder = Workspace:FindFirstChild("Bells")
    if not bellsFolder then
        bellsFolder = Instance.new("Folder")
        bellsFolder.Name = "Bells"
        bellsFolder.Parent = Workspace
    end

    bellMarker.Parent = bellsFolder

    return bellMarker
end

--[[
	Finds a valid ground position using raycast (not on water)
]]
local function findValidGroundPosition(x, z)
    local rayOrigin = Vector3.new(x, SPAWN_HEIGHT, z)
    local rayDirection = Vector3.new(0, -200, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { Workspace.Terrain }
    raycastParams.IgnoreWater = false -- We want to detect water

    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if rayResult then
        -- Check if material is valid for bells (not water)
        local hitMaterial = rayResult.Material
        if hitMaterial == Enum.Material.Water then
            -- Skip water
            return nil
        end

        if not validBellMaterials[hitMaterial] then
            -- Skip invalid materials
            return nil
        end

        return rayResult.Position
    end

    return nil
end

--[[
	Spawns bell markers randomly around the map
]]
function BellSpawner.spawnBells()
    print("[BellSpawner] 💰 Spawning bell markers...")

    -- Clear existing bells
    local existingBells = Workspace:FindFirstChild("Bells")
    if existingBells then
        existingBells:ClearAllChildren()
    end

    local bellsSpawned = 0
    local attempts = 0
    local maxAttempts = NUM_BELLS * 10

    while bellsSpawned < NUM_BELLS and attempts < maxAttempts do
        attempts = attempts + 1

        -- Random position within radius
        local angle = math.random() * math.pi * 2
        local distance = math.random(20, SPAWN_RADIUS)
        local x = math.cos(angle) * distance
        local z = math.sin(angle) * distance

        -- Find valid ground (not on water)
        local position = findValidGroundPosition(x, z)

        if position then
            -- Random bell amount
            local bellAmount = math.random(BELL_MIN, BELL_MAX)

            local bellMarker = spawnBellMarker(position, bellAmount)
            if bellMarker then
                bellsSpawned = bellsSpawned + 1
                print(
                    "[BellSpawner] ✅ Spawned bell marker",
                    bellsSpawned,
                    "at",
                    position,
                    "worth",
                    bellAmount,
                    "bells"
                )
            end
        end
    end

    print("[BellSpawner] ✅ Spawned", bellsSpawned, "bell markers")
end

--[[
	Initializes the bell spawner
]]
function BellSpawner.init()
    print("[BellSpawner] 💰 Initializing bell spawner...")

    -- Spawn bells after a short delay (let terrain load)
    task.wait(2)
    BellSpawner.spawnBells()

    print("[BellSpawner] ✅ Bell spawner initialized")
end

return BellSpawner
