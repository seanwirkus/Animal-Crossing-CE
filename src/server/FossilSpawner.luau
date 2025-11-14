--[[
	FossilSpawner.luau
	
	Spawns X markers (fossil dig spots) around the island
	Players can dig these with a shovel to find fossils
	X markers appear on the ground before digging (NoHole state)
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FossilSpawner = {}

-- Configuration
local X_MARKER_ASSET_ID = 95502544899864
local NUM_FOSSILS = 10 -- Number of fossil X markers to spawn
local SPAWN_RADIUS = 200 -- Spawn within this radius
local SPAWN_HEIGHT = 50 -- Start raycast from this height

-- Valid materials for fossils (can spawn on most ground materials)
local validFossilMaterials = {
    [Enum.Material.Grass] = true,
    [Enum.Material.Ground] = true, -- Dirt
    [Enum.Material.Sand] = true,
    [Enum.Material.Snow] = true,
    [Enum.Material.Mud] = true,
    -- NOT on Water, Rock, etc.
}

--[[
	Spawns an X marker (fossil dig spot) at a specific position
]]
local function spawnXMarker(position)
    -- Load X marker model from asset
    local success, xModel = pcall(function()
        return game:GetService("InsertService"):LoadAsset(X_MARKER_ASSET_ID)
    end)

    if not success or not xModel then
        warn("[FossilSpawner] ⚠️ Failed to load X marker asset")
        return nil
    end

    -- Get the first child (the actual model)
    local xMarker = xModel:GetChildren()[1]
    if not xMarker then
        xModel:Destroy()
        return nil
    end

    xMarker = xMarker:Clone()
    xModel:Destroy()

    -- Position the X marker ON TOP of terrain
    -- Get the bounding box to calculate proper positioning
    if xMarker:IsA("Model") and xMarker.PrimaryPart then
        -- Calculate the bottom of the model
        local primaryPart = xMarker.PrimaryPart
        local cf, size = primaryPart.CFrame, primaryPart.Size
        local bottomOffset = size.Y / 2

        -- Position so the bottom of the model sits on the terrain
        local adjustedPosition = position - Vector3.new(0, bottomOffset, 0) + Vector3.new(0, 0.05, 0)
        xMarker:MoveTo(adjustedPosition)
    elseif xMarker:IsA("BasePart") then
        -- For a single part, position it so bottom sits on terrain
        local bottomOffset = xMarker.Size.Y / 2
        xMarker.Position = position - Vector3.new(0, bottomOffset, 0) + Vector3.new(0, 0.05, 0)
    else
        -- For models without PrimaryPart, try to find the lowest part
        local lowestPart = nil
        local lowestY = math.huge
        for _, part in ipairs(xMarker:GetDescendants()) do
            if part:IsA("BasePart") then
                local partBottom = part.Position.Y - part.Size.Y / 2
                if partBottom < lowestY then
                    lowestY = partBottom
                    lowestPart = part
                end
            end
        end
        if lowestPart then
            local offset = position.Y - lowestY
            xMarker:PivotTo(CFrame.new(position - Vector3.new(0, offset, 0) + Vector3.new(0, 0.05, 0)))
        else
            xMarker:PivotTo(CFrame.new(position + Vector3.new(0, 0.05, 0)))
        end
    end

    -- Set properties
    xMarker.Name = "FossilXMarker"

    -- Add attribute to identify this as a fossil spot
    if xMarker:IsA("Model") then
        xMarker:SetAttribute("DigType", "fossil")
        xMarker:SetAttribute("ItemId", "fossil")
    else
        -- If it's a Part, we might need to create a model wrapper
        local wrapper = Instance.new("Model")
        wrapper.Name = "FossilXMarker"
        wrapper:SetAttribute("DigType", "fossil")
        wrapper:SetAttribute("ItemId", "fossil")
        xMarker.Parent = wrapper
        xMarker = wrapper
    end

    -- Parent to workspace
    local fossilsFolder = Workspace:FindFirstChild("Fossils")
    if not fossilsFolder then
        fossilsFolder = Instance.new("Folder")
        fossilsFolder.Name = "Fossils"
        fossilsFolder.Parent = Workspace
    end

    xMarker.Parent = fossilsFolder

    return xMarker
end

--[[
	Finds a valid ground position using raycast (not on water)
	Returns position ON TOP of terrain surface
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
        -- Check if material is valid for fossils (not water)
        local hitMaterial = rayResult.Material
        if hitMaterial == Enum.Material.Water then
            -- Skip water
            return nil
        end

        if not validFossilMaterials[hitMaterial] then
            -- Skip invalid materials
            return nil
        end

        -- Get the surface normal to position marker correctly
        local surfaceNormal = rayResult.Normal
        local hitPosition = rayResult.Position

        -- Position marker ON TOP of terrain (not inside)
        -- Add offset based on surface normal to ensure it sits on top
        local offset = surfaceNormal * 0.1 -- Small offset to sit on surface
        return hitPosition + offset
    end

    return nil
end

--[[
	Spawns X markers (fossil dig spots) randomly around the map
]]
function FossilSpawner.spawnFossils()
    print("[FossilSpawner] 🦴 Spawning fossil X markers...")

    -- Clear existing fossils
    local existingFossils = Workspace:FindFirstChild("Fossils")
    if existingFossils then
        existingFossils:ClearAllChildren()
    end

    local fossilsSpawned = 0
    local attempts = 0
    local maxAttempts = NUM_FOSSILS * 10

    while fossilsSpawned < NUM_FOSSILS and attempts < maxAttempts do
        attempts = attempts + 1

        -- Random position within radius
        local angle = math.random() * math.pi * 2
        local distance = math.random(20, SPAWN_RADIUS)
        local x = math.cos(angle) * distance
        local z = math.sin(angle) * distance

        -- Find valid ground (not on water)
        local position = findValidGroundPosition(x, z)

        if position then
            local xMarker = spawnXMarker(position)
            if xMarker then
                fossilsSpawned = fossilsSpawned + 1
                print("[FossilSpawner] ✅ Spawned fossil X marker", fossilsSpawned, "at", position)
            end
        end
    end

    print("[FossilSpawner] ✅ Spawned", fossilsSpawned, "fossil X markers")
end

--[[
	Initializes the fossil spawner
]]
function FossilSpawner.init()
    print("[FossilSpawner] 🦴 Initializing fossil spawner...")

    -- Spawn fossils after a short delay (let terrain load)
    task.wait(2)
    FossilSpawner.spawnFossils()

    print("[FossilSpawner] ✅ Fossil spawner initialized")
end

return FossilSpawner
