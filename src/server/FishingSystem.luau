--[[
    FishingSystem.luau
    Server-side fishing logic and validation
    
    TODO: PHASE 1 - DAY 2 PRIORITY
    - Handle fishing requests from client
    - Validate player has fishing rod
    - Generate random fish based on location/time
    - Award bells to player
    - Add fish to inventory
    - Track fishing statistics
    
    DEPENDS ON: FishData, CurrencyManager, InventorySystem
    CALLED BY: FishingController (client) via RemoteEvent
]]

local FishingSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")

local FishData = require(sharedFolder:WaitForChild("FishData"))
local CurrencyManager = require(script.Parent:WaitForChild("CurrencyManager"))
local InventoryModule = require(sharedFolder:WaitForChild("inventory"))

local DEFAULT_FISH_STACK = InventoryModule.Constants and InventoryModule.Constants.DEFAULT_MAX_STACK or 10

local fishingRemote = ReplicatedStorage:FindFirstChild("FishingEvent")
if not fishingRemote then
    fishingRemote = Instance.new("RemoteEvent")
    fishingRemote.Name = "FishingEvent"
    fishingRemote.Parent = ReplicatedStorage
end

local ATTEMPT_COOLDOWN = 1.5
local MAX_CAST_DISTANCE = 80

local lastAttempt = {}

local inventoryInterface = {
    enqueue = nil,
    defaultStack = DEFAULT_FISH_STACK,
}

local function isFishingTool(tool: Instance?): boolean
    if not tool or not tool:IsA("Tool") then
        return false
    end

    local toolType = tool:GetAttribute("ToolType")
    if toolType and string.find(string.lower(tostring(toolType)), "fish") then
        return true
    end

    local lowerName = string.lower(tool.Name)
    if string.find(lowerName, "fish") then
        return true
    end

    return false
end

local function hasFishingRodEquipped(player: Player): boolean
    if not player then
        return false
    end

    local equippedAttribute = player:GetAttribute("EquippedToolType")
    if equippedAttribute and string.find(string.lower(tostring(equippedAttribute)), "fish") then
        return true
    end

    local character = player.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            if isFishingTool(child) then
                return true
            end
        end
    end

    return false
end

local function normalizeLocationHint(locationHint: any): string?
    if typeof(locationHint) ~= "string" then
        return nil
    end

    local lower = string.lower(locationHint)
    if lower == "shore" then
        return "ocean"
    end

    if lower == "river" or lower == "ocean" or lower == "pond" then
        return lower
    end

    return nil
end

local function sanitizeHourHint(hourHint: any)
    if typeof(hourHint) == "number" then
        return hourHint % 24
    end

    if typeof(hourHint) == "string" then
        local numeric = tonumber(hourHint)
        if numeric then
            return numeric % 24
        end
        return hourHint
    end

    if typeof(hourHint) == "table" then
        if typeof(hourHint.hour) == "number" then
            return hourHint.hour % 24
        end
        if typeof(hourHint.Hour) == "number" then
            return hourHint.Hour % 24
        end
        if typeof(hourHint.hours) == "number" then
            return hourHint.hours % 24
        end
        return hourHint
    end

    return nil
end

function FishingSystem.configure(options)
    if not options then
        return
    end

    if options.enqueueInventoryItem then
        inventoryInterface.enqueue = options.enqueueInventoryItem
    elseif options.enqueueAdd then
        inventoryInterface.enqueue = options.enqueueAdd
    end

    if options.defaultStack and typeof(options.defaultStack) == "number" then
        inventoryInterface.defaultStack = math.max(1, math.floor(options.defaultStack))
    end
end

local function awardFishToInventory(player: Player, fishInfo, fishId: string)
    if not inventoryInterface.enqueue then
        warn("[FishingSystem] Inventory interface missing; cannot grant fish")
        return false, "Inventory unavailable"
    end

    local payload = {
        itemId = fishInfo.inventoryId or fishId,
        count = 1,
        maxStack = inventoryInterface.defaultStack or DEFAULT_FISH_STACK,
        metadata = {
            fishId = fishId,
            rarity = fishInfo.rarity,
            caughtAt = os.time(),
        },
    }

    local ok, success, err = pcall(function()
        return inventoryInterface.enqueue(player, payload)
    end)

    if not ok then
        warn("[FishingSystem] Failed to enqueue inventory addition:", success)
        return false, "Inventory error"
    end

    if success == nil then
        return true
    end

    if typeof(success) == "boolean" then
        return success, err
    end

    if typeof(success) == "table" then
        local succeeded = success.success
        if succeeded == nil then
            succeeded = true
        end
        return succeeded ~= false, success.message or err
    end

    if typeof(success) == "string" then
        return false, success
    end

    return true
end

function FishingSystem.handleCatch(player: Player, data: table): table?
    data = typeof(data) == "table" and data or {}

    if not hasFishingRodEquipped(player) then
        return {
            success = false,
            message = "You need to equip a fishing rod first.",
        }
    end

    local now = os.clock()
    local userId = player.UserId
    local previous = lastAttempt[userId]
    if previous and now - previous < ATTEMPT_COOLDOWN then
        local remaining = ATTEMPT_COOLDOWN - (now - previous)
        return {
            success = false,
            message = "Take a moment before trying again.",
            cooldown = remaining,
        }
    end

    local castPosition = data.position
    if typeof(castPosition) ~= "Vector3" then
        castPosition = nil
    end

    if castPosition then
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - castPosition).Magnitude > MAX_CAST_DISTANCE then
            return {
                success = false,
                message = "That cast was a little too far away.",
            }
        end
    end

    lastAttempt[userId] = now

    local locationHint = normalizeLocationHint(data.locationType) or "river"
    local timeHint = sanitizeHourHint(data.hour or data.time or data.timeOfDay)

    local fishId = FishData.getRandomFish(locationHint, timeHint)
    local fishInfo = FishData.getFishInfo(fishId)

    if not fishInfo then
        return {
            success = false,
            message = "Nothing seems to be biting right now.",
        }
    end

    local inventorySuccess, inventoryMessage = awardFishToInventory(player, fishInfo, fishId)

    if not inventorySuccess then
        return {
            success = false,
            fishId = fishId,
            fishName = fishInfo.name,
            rarity = fishInfo.rarity,
            spriteIndex = fishInfo.spriteIndex,
            message = inventoryMessage or "Your inventory is full!",
        }
    end

    local bellsEarned = 0
    local reward = tonumber(fishInfo.value) or 0
    if reward > 0 then
        if CurrencyManager.addBells(player, reward) then
            bellsEarned = reward
        end
    end

    return {
        success = true,
        fishId = fishId,
        fishName = fishInfo.name,
        rarity = fishInfo.rarity,
        spriteIndex = fishInfo.spriteIndex,
        bellsEarned = bellsEarned,
        itemId = fishInfo.inventoryId or fishId,
        message = string.format("You caught a %s!", fishInfo.name),
        location = locationHint,
    }
end

local remoteConnection

function FishingSystem.init()
    if remoteConnection then
        return
    end

    remoteConnection = fishingRemote.OnServerEvent:Connect(function(player, action, payload)
        if action == "Catch" then
            local result = FishingSystem.handleCatch(player, payload)
            fishingRemote:FireClient(player, "CatchResult", result)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        lastAttempt[player.UserId] = nil
    end)
end

return FishingSystem
