--[[
	DigMarkerSpawner.luau

	Manages the spawning and respawning of X markers for digging spots.
	Replaces FossilSpawner and BellSpawner with unified marker management.

	This system creates markers that appear and disappear based on time,
	matching ACNH mechanics where markers respawn periodically.
]]

local _Workspace = game:GetService("Workspace")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")

local DigMarkerSpawner = {}

-- Configuration
local _X_MARKER_ASSET_ID = 98139431900134 -- Same as hole asset for now, TODO: create proper X marker
local FOSSIL_SPAWN_COUNT = 10
local BELL_SPAWN_COUNT = 15
local _MARKER_RESPAWN_TIME = 300 -- 5 minutes
local MARKER_VISIBLE_TIME = 180 -- 3 minutes visible before disappearing

-- Data storage
local activeMarkers = {} -- [markerId] = {model, spotId, spawnTime, despawnTime}
local _markerSpots = {} -- [spotId] = position

-- Import DigSpotManager
local DigSpotManager = require(script.Parent.DigSpotManager)

--[[
	Spawns an X marker at the given position
]]
local function spawnXMarker(position: Vector3, spotId: string)
    -- Load marker model from asset
    local success, markerModel = pcall(function()
        return game:GetService("InsertService"):LoadAsset(_X_MARKER_ASSET_ID)
    end)

    if not success or not markerModel then
        warn("[DigMarkerSpawner] Failed to load X marker asset")
        return nil
    end

    -- Get the first child (the actual model)
    local marker = markerModel:GetChildren()[1]
    if not marker then
        markerModel:Destroy()
        return nil
    end

    marker = marker:Clone()
    markerModel:Destroy()

    -- Position the marker
    if marker:IsA("Model") and marker.PrimaryPart then
        marker:MoveTo(position)
    elseif marker:IsA("BasePart") then
        marker.Position = position
    else
        marker:PivotTo(CFrame.new(position))
    end

    -- Set properties
    marker.Name = "DigMarker_" .. spotId

    -- Parent to workspace
    local markersFolder = _Workspace:FindFirstChild("DigMarkers")
    if not markersFolder then
        markersFolder = Instance.new("Folder")
        markersFolder.Name = "DigMarkers"
        markersFolder.Parent = _Workspace
    end

    marker.Parent = markersFolder

    return marker
end

--[[
	Despawns a marker
]]
local function despawnMarker(markerId: string)
    local markerData = activeMarkers[markerId]
    if not markerData then
        return
    end

    if markerData.model then
        markerData.model:Destroy()
    end

    activeMarkers[markerId] = nil
    print(string.format("[DigMarkerSpawner] ✅ Despawned marker %s", markerId))
end

--[[
	Spawns markers for fossil spots
]]
function DigMarkerSpawner.spawnFossilMarkers()
    print("[DigMarkerSpawner] 🦴 Spawning fossil X markers...")

    local spawned = 0
    local attempts = 0
    local maxAttempts = FOSSIL_SPAWN_COUNT * 3

    while spawned < FOSSIL_SPAWN_COUNT and attempts < maxAttempts do
        attempts = attempts + 1

        -- Random position within radius
        local angle = math.random() * math.pi * 2
        local distance = math.random(20, 200)
        local x = math.cos(angle) * distance
        local z = math.sin(angle) * distance
        local position = Vector3.new(x, 20, z)

        -- Create dig spot
        local _spotId = "fossil_" .. spawned + 1
        local fossilData = { itemId = "random_fossil" } -- TODO: implement fossil selection
        local digSpot = DigSpotManager.createDigSpot(position, "fossil", fossilData)

        -- Spawn marker
        local marker = spawnXMarker(position, digSpot.id)
        if marker then
            local markerId = "fossil_" .. spawned + 1
            local spawnTime = os.time()
            local despawnTime = spawnTime + MARKER_VISIBLE_TIME

            activeMarkers[markerId] = {
                model = marker,
                spotId = digSpot.id,
                spawnTime = spawnTime,
                despawnTime = despawnTime,
            }

            -- Activate marker for all players
            DigSpotManager.activateMarkerForAllPlayers(digSpot.id)

            spawned = spawned + 1
            print(string.format("[DigMarkerSpawner] ✅ Spawned fossil X marker %d at %s", spawned, tostring(position)))
        end
    end

    print(string.format("[DigMarkerSpawner] ✅ Spawned %d fossil X markers", spawned))
end

--[[
	Spawns markers for bell spots
]]
function DigMarkerSpawner.spawnBellMarkers()
    print("[DigMarkerSpawner] 💰 Spawning bell markers...")

    local spawned = 0
    local attempts = 0
    local maxAttempts = BELL_SPAWN_COUNT * 3

    while spawned < BELL_SPAWN_COUNT and attempts < maxAttempts do
        attempts = attempts + 1

        -- Random position within radius
        local angle = math.random() * math.pi * 2
        local distance = math.random(20, 200)
        local x = math.cos(angle) * distance
        local z = math.sin(angle) * distance
        local position = Vector3.new(x, 20, z)

        -- Random bell amount (similar to ACNH)
        local bellAmounts = { 140, 189, 266, 361, 394, 507, 560, 694, 750, 856, 955, 967, 971 }
        local bellAmount = bellAmounts[math.random(1, #bellAmounts)]

        -- Create dig spot
        local _spotId = "bell_" .. spawned + 1
        local bellData = { amount = bellAmount }
        local digSpot = DigSpotManager.createDigSpot(position, "bell", bellData)

        -- Spawn marker
        local marker = spawnXMarker(position, digSpot.id)
        if marker then
            local markerId = "bell_" .. spawned + 1
            local spawnTime = os.time()
            local despawnTime = spawnTime + MARKER_VISIBLE_TIME

            activeMarkers[markerId] = {
                model = marker,
                spotId = digSpot.id,
                spawnTime = spawnTime,
                despawnTime = despawnTime,
            }

            -- Activate marker for all players
            DigSpotManager.activateMarkerForAllPlayers(digSpot.id)

            spawned = spawned + 1
            print(
                string.format(
                    "[DigMarkerSpawner] ✅ Spawned bell marker %d at %s worth %d bells",
                    spawned,
                    tostring(position),
                    bellAmount
                )
            )
        end
    end

    print(string.format("[DigMarkerSpawner] ✅ Spawned %d bell markers", spawned))
end

--[[
	Updates markers (handles despawning and respawning)
]]
function DigMarkerSpawner.updateMarkers()
    local currentTime = os.time()

    -- Check for markers that need to despawn
    for markerId, markerData in pairs(activeMarkers) do
        if currentTime >= markerData.despawnTime then
            despawnMarker(markerId)
        end
    end

    -- TODO: Implement respawning logic based on DigSpotManager cooldowns
    -- This will check DigSpotManager for spots that are ready to respawn
end

--[[
	Creates some initial dig spots for testing
]]
function DigMarkerSpawner.createInitialDigSpots()
    print("[DigMarkerSpawner] 🏗️ Creating initial dig spots...")

    -- Create some test fossil spots
    local fossilPositions = {
        Vector3.new(50, 20, 50),
        Vector3.new(-50, 20, 50),
        Vector3.new(50, 20, -50),
        Vector3.new(-50, 20, -50),
    }

    for i, pos in ipairs(fossilPositions) do
        local fossilData = { itemId = "test_fossil_" .. i }
        DigSpotManager.createDigSpot(pos, "fossil", fossilData)
    end

    -- Create some test bell spots
    local bellPositions = {
        Vector3.new(25, 20, 25),
        Vector3.new(-25, 20, 25),
        Vector3.new(25, 20, -25),
        Vector3.new(-25, 20, -25),
        Vector3.new(0, 20, 75),
    }

    for i, pos in ipairs(bellPositions) do
        local bellAmounts = { 500, 1000, 1500, 2000, 2500 }
        local bellData = { amount = bellAmounts[i] or 1000 }
        DigSpotManager.createDigSpot(pos, "bell", bellData)
    end

    print(
        string.format(
            "[DigMarkerSpawner] ✅ Created %d fossil spots and %d bell spots",
            #fossilPositions,
            #bellPositions
        )
    )
end

--[[
	Clears all markers
]]
function DigMarkerSpawner.clearAllMarkers()
    print("[DigMarkerSpawner] 🧹 Clearing all markers...")

    for markerId, _ in pairs(activeMarkers) do
        despawnMarker(markerId)
    end

    local markersFolder = _Workspace:FindFirstChild("DigMarkers")
    if markersFolder then
        markersFolder:ClearAllChildren()
    end

    print("[DigMarkerSpawner] ✅ All markers cleared")
end

--[[
	Initializes the DigMarkerSpawner
]]
function DigMarkerSpawner.init()
    print("[DigMarkerSpawner] 🎯 Initializing DigMarkerSpawner...")

    -- Clear any existing markers
    DigMarkerSpawner.clearAllMarkers()

    -- Create some initial dig spots for testing
    DigMarkerSpawner.createInitialDigSpots()

    -- Spawn initial markers
    DigMarkerSpawner.spawnFossilMarkers()
    DigMarkerSpawner.spawnBellMarkers()

    -- Set up periodic updates
    task.spawn(function()
        while true do
            DigMarkerSpawner.updateMarkers()
            task.wait(30) -- Update every 30 seconds
        end
    end)

    print("[DigMarkerSpawner] ✅ DigMarkerSpawner initialized")
end

return DigMarkerSpawner
