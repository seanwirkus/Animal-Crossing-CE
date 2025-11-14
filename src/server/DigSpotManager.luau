--[[
	DigSpotManager.luau

	Core service for managing digging mechanics in Animal Crossing CE.
	Handles dig spots, active markers, and dug holes with proper persistence.

	This replaces the old HoleSpawner, FossilSpawner, and BellSpawner systems
	with a unified, logical digging system that matches ACNH mechanics.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")
local _DataStoreService = game:GetService("DataStoreService")

local DigSpotManager = {}

-- Types
export type DigSpot = {
    id: string,
    position: Vector3,
    spotType: "fossil" | "bell" | "empty",
    itemId: string?, -- For fossils/bells
    bellAmount: number?, -- For bell spots
    isActive: boolean, -- Whether marker is visible
    lastDug: number?, -- Timestamp when last dug
    cooldownUntil: number?, -- When marker can respawn
}

export type PlayerDigData = {
    digSpots: { [string]: DigSpot },
    activeMarkers: { [string]: boolean }, -- spotId -> isVisible
    dugHoles: { [string]: boolean }, -- spotId -> hasHole
    lastActivity: number,
}

-- Constants
local MARKER_RESPAWN_TIME = 300 -- 5 minutes in seconds
local HOLE_FILL_TIME = 1800 -- 30 minutes in seconds
local MAX_ACTIVE_MARKERS = 20 -- Maximum visible markers at once

-- Data storage
local playerDigData = {} -- [playerId] = PlayerDigData
local digSpots = {} -- [spotId] = DigSpot (global spots)

-- Events (lazy-loaded to avoid infinite yield)
local function getDigEvent()
    return ReplicatedStorage:FindFirstChild("ShovelDig")
end

--[[
	Generates a unique ID for a dig spot based on position
]]
local function generateSpotId(position: Vector3): string
    return string.format("%.0f_%.0f_%.0f", position.X, position.Y, position.Z)
end

--[[
	Creates a new dig spot at the given position
]]
function DigSpotManager.createDigSpot(position: Vector3, spotType: "fossil" | "bell" | "empty", itemData: any?): DigSpot
    local spotId = generateSpotId(position)

    local digSpot: DigSpot = {
        id = spotId,
        position = position,
        spotType = spotType,
        isActive = false,
        lastDug = nil,
        cooldownUntil = nil,
    }

    -- Set item data based on type
    if spotType == "fossil" and itemData then
        digSpot.itemId = itemData.itemId
    elseif spotType == "bell" and itemData then
        digSpot.bellAmount = itemData.amount
    end

    digSpots[spotId] = digSpot
    return digSpot
end

--[[
	Gets a dig spot by ID
]]
function DigSpotManager.getDigSpot(spotId: string): DigSpot?
    return digSpots[spotId]
end

--[[
	Gets all active markers for a player
]]
function DigSpotManager.getActiveMarkers(player: Player): { [string]: DigSpot }
    local playerId = tostring(player.UserId)
    local data = playerDigData[playerId]
    if not data then
        return {}
    end

    local activeSpots = {}
    for spotId, isActive in pairs(data.activeMarkers) do
        if isActive then
            local spot = digSpots[spotId]
            if spot then
                activeSpots[spotId] = spot
            end
        end
    end

    return activeSpots
end

--[[
	Activates a marker for a player (makes it visible)
]]
function DigSpotManager.activateMarker(player: Player, spotId: string): boolean
    local playerId = tostring(player.UserId)
    local data = playerDigData[playerId]
    if not data then
        return false
    end

    local spot = digSpots[spotId]
    if not spot then
        return false
    end

    -- Check if already active
    if data.activeMarkers[spotId] then
        return true
    end

    -- Check cooldown
    if spot.cooldownUntil and os.time() < spot.cooldownUntil then
        return false
    end

    -- Check max active markers
    local activeCount = 0
    for _, isActive in pairs(data.activeMarkers) do
        if isActive then
            activeCount = activeCount + 1
        end
    end

    if activeCount >= MAX_ACTIVE_MARKERS then
        return false
    end

    -- Activate marker
    data.activeMarkers[spotId] = true
    spot.isActive = true

    print(string.format("[DigSpotManager] ✅ Activated marker %s for %s", spotId, player.Name))
    return true
end

--[[
	Activates a marker for all players (used when spawning new markers)
]]
function DigSpotManager.activateMarkerForAllPlayers(spotId: string): boolean
    local spot = digSpots[spotId]
    if not spot then
        warn(string.format("[DigSpotManager] ❌ Cannot activate marker %s: spot not found", spotId))
        return false
    end

    -- Activate for all players
    for _, player in ipairs(_Players:GetPlayers()) do
        local playerId = tostring(player.UserId)
        local data = playerDigData[playerId]
        if data then
            data.activeMarkers[spotId] = true
        end
    end

    spot.isActive = true
    print(string.format("[DigSpotManager] ✅ Activated marker %s for all players", spotId))
    return true
end

--[[
	Deactivates a marker for a player (hides it)
]]
function DigSpotManager.deactivateMarker(player: Player, spotId: string): boolean
    local playerId = tostring(player.UserId)
    local data = playerDigData[playerId]
    if not data then
        return false
    end

    if not data.activeMarkers[spotId] then
        return true
    end

    data.activeMarkers[spotId] = false
    local spot = digSpots[spotId]
    if spot then
        spot.isActive = false
    end

    print(string.format("[DigSpotManager] ✅ Deactivated marker %s for %s", spotId, player.Name))
    return true
end

--[[
	Handles digging at a position
	Returns: success, resultType, resultData
]]
function DigSpotManager.handleDig(player: Player, position: Vector3): (boolean, string?, any?)
    local playerId = tostring(player.UserId)
    local data = playerDigData[playerId]
    if not data then
        return false
    end

    local spotId = generateSpotId(position)
    local spot = digSpots[spotId]

    -- Check if there's an active marker here
    if not data.activeMarkers[spotId] or not spot then
        -- No marker, but create a hole anyway (empty dig)
        data.dugHoles[spotId] = true
        print(string.format("[DigSpotManager] 🕳️ Created empty hole at %s for %s", spotId, player.Name))
        return true, "empty", nil
    end

    -- There is a marker - dig it up!
    local resultType = spot.spotType
    local resultData = nil

    if spot.spotType == "fossil" then
        resultData = { itemId = spot.itemId }
    elseif spot.spotType == "bell" then
        resultData = { amount = spot.bellAmount }
    end

    -- Mark as dug and set cooldown
    spot.lastDug = os.time()
    spot.cooldownUntil = os.time() + MARKER_RESPAWN_TIME
    data.dugHoles[spotId] = true
    data.activeMarkers[spotId] = false
    spot.isActive = false

    print(string.format("[DigSpotManager] 🎉 Dug up %s at %s for %s", resultType, spotId, player.Name))
    return true, resultType, resultData
end

--[[
	Checks if a position has a dug hole
]]
function DigSpotManager.hasDugHole(player: Player, position: Vector3): boolean
    local playerId = tostring(player.UserId)
    local data = playerDigData[playerId]
    if not data then
        return false
    end

    local spotId = generateSpotId(position)
    return data.dugHoles[spotId] == true
end

--[[
	Fills a hole at the given position (removes it)
]]
function DigSpotManager.fillHole(player: Player, position: Vector3): boolean
    local playerId = tostring(player.UserId)
    local data = playerDigData[playerId]
    if not data then
        return false
    end

    local spotId = generateSpotId(position)
    if not data.dugHoles[spotId] then
        return false
    end

    data.dugHoles[spotId] = false
    print(string.format("[DigSpotManager] ✅ Filled hole at %s for %s", spotId, player.Name))
    return true
end

--[[
	Updates markers for a player (handles respawning, cleanup)
]]
function DigSpotManager.updateMarkers(player: Player)
    local playerId = tostring(player.UserId)
    local data = playerDigData[playerId]
    if not data then
        return
    end

    local currentTime = os.time()

    -- Check for markers that can respawn
    for spotId, spot in pairs(digSpots) do
        if spot.cooldownUntil and currentTime >= spot.cooldownUntil then
            -- Cooldown expired, can potentially respawn
            if not data.activeMarkers[spotId] then
                -- Try to activate it
                DigSpotManager.activateMarker(player, spotId)
            end
        end
    end

    -- Fill holes that have been around long enough
    for spotId, hasHole in pairs(data.dugHoles) do
        if hasHole then
            local spot = digSpots[spotId]
            if spot and spot.lastDug then
                local timeSinceDug = currentTime - spot.lastDug
                if timeSinceDug >= HOLE_FILL_TIME then
                    DigSpotManager.fillHole(player, spot.position)
                end
            end
        end
    end
end

--[[
	Initializes player data
]]
function DigSpotManager.initPlayer(player: Player)
    local playerId = tostring(player.UserId)

    playerDigData[playerId] = {
        digSpots = {},
        activeMarkers = {},
        dugHoles = {},
        lastActivity = os.time(),
    }

    print(string.format("[DigSpotManager] ✅ Initialized data for %s", player.Name))
end

--[[
	Cleans up player data
]]
function DigSpotManager.cleanupPlayer(player: Player)
    local playerId = tostring(player.UserId)
    playerDigData[playerId] = nil
    print(string.format("[DigSpotManager] ✅ Cleaned up data for %s", player.Name))
end

--[[
	Initializes the DigSpotManager
]]
function DigSpotManager.init()
    print("[DigSpotManager] 🕳️ Initializing DigSpotManager...")

    -- Connect to player events
    _Players.PlayerAdded:Connect(function(player)
        DigSpotManager.initPlayer(player)
    end)

    _Players.PlayerRemoving:Connect(function(player)
        DigSpotManager.cleanupPlayer(player)
    end)

    -- Initialize existing players
    for _, player in ipairs(_Players:GetPlayers()) do
        DigSpotManager.initPlayer(player)
    end

    -- Set up periodic updates
    task.spawn(function()
        while true do
            for _, player in ipairs(_Players:GetPlayers()) do
                DigSpotManager.updateMarkers(player)
            end
            task.wait(60) -- Update every minute
        end
    end)

    print("[DigSpotManager] ✅ DigSpotManager initialized")
end

return DigSpotManager
