local Workspace = game:GetService("Workspace")

-- Fish data with rarity tiers
local FISH_DATA = {
    { id = "fish_sea_bass", name = "Sea Bass", rarity = "common", value = 400 },
    { id = "fish_dace", name = "Dace", rarity = "common", value = 240 },
    { id = "fish_carp", name = "Carp", rarity = "common", value = 300 },
    { id = "fish_koi", name = "Koi", rarity = "common", value = 4000 },
    { id = "fish_goldfish", name = "Goldfish", rarity = "common", value = 1300 },
    { id = "fish_red_snapper", name = "Red Snapper", rarity = "uncommon", value = 3000 },
    { id = "fish_barred_knifejaw", name = "Barred Knifejaw", rarity = "uncommon", value = 5000 },
    { id = "fish_loach", name = "Loach", rarity = "uncommon", value = 400 },
    { id = "fish_tuna", name = "Tuna", rarity = "rare", value = 7000 },
    { id = "fish_blue_marlin", name = "Blue Marlin", rarity = "rare", value = 10000 },
    { id = "fish_oarfish", name = "Oarfish", rarity = "ultra_rare", value = 9000 },
    { id = "fish_coelacanth", name = "Coelacanth", rarity = "ultra_rare", value = 15000 },
}

local FishingSystem = {}
FishingSystem.activeCasts = {}

local feedbackCallback = nil

local function emitFeedback(player, action, data)
    if feedbackCallback then
        feedbackCallback(player, action, data)
    end
end

function FishingSystem.setFeedbackCallback(callback)
    feedbackCallback = callback
end

function FishingSystem.getRandomFish()
    local roll = math.random(1, 100)
    local rarityPool

    if roll <= 70 then
        rarityPool = "common"
    elseif roll <= 90 then
        rarityPool = "uncommon"
    elseif roll <= 98 then
        rarityPool = "rare"
    else
        rarityPool = "ultra_rare"
    end

    local validFish = {}
    for _, fish in ipairs(FISH_DATA) do
        if fish.rarity == rarityPool then
            table.insert(validFish, fish)
        end
    end

    return #validFish > 0 and validFish[math.random(1, #validFish)] or FISH_DATA[1]
end

function FishingSystem.isInWater(position)
    local region = Region3.new(position - Vector3.new(2, 2, 2), position + Vector3.new(2, 2, 2))
    local terrain = Workspace.Terrain
    local materials, sizes = terrain:ReadVoxels(region, 4)
    local size = materials.Size

    for x = 1, size.X do
        for y = 1, size.Y do
            for z = 1, size.Z do
                if materials[x][y][z] == Enum.Material.Water then
                    return true
                end
            end
        end
    end
    return false
end

function FishingSystem.startCast(player, bobberPosition)
    print("[FishingSystem] Cast for", player.Name)

    if not FishingSystem.isInWater(bobberPosition) then
        warn("[FishingSystem] Not in water!")
        return false
    end

    if FishingSystem.activeCasts[player.UserId] then
        FishingSystem.cancelCast(player.UserId)
    end

    local fishData = FishingSystem.getRandomFish()
    local biteDelay = math.random(20, 60) / 10

    FishingSystem.activeCasts[player.UserId] = {
        player = player,
        bobberPosition = bobberPosition,
        fishData = fishData,
        biteTime = tick() + biteDelay,
        hasBit = false,
        catchWindow = nil,
    }

    print("[FishingSystem] Fish:", fishData.name, "Bite in:", biteDelay)

    task.delay(biteDelay, function()
        FishingSystem.triggerBite(player.UserId)
    end)

    return true
end

function FishingSystem.triggerBite(userId)
    local castData = FishingSystem.activeCasts[userId]
    if not castData then
        return
    end

    castData.hasBit = true
    castData.catchWindow = tick() + 3

    print("[FishingSystem] BITE!")

    emitFeedback(castData.player, "bite", {
        fishId = castData.fishData.id,
        fishName = castData.fishData.name,
    })

    task.delay(3, function()
        if FishingSystem.activeCasts[userId] and FishingSystem.activeCasts[userId].hasBit then
            FishingSystem.cancelCast(userId)
        end
    end)
end

function FishingSystem.attemptCatch(player)
    local castData = FishingSystem.activeCasts[player.UserId]
    if not castData then
        return false
    end
    if not castData.hasBit then
        return false
    end
    if tick() > castData.catchWindow then
        FishingSystem.cancelCast(player.UserId)
        return false
    end

    local fishData = castData.fishData
    print("[FishingSystem] CAUGHT:", fishData.name)

    emitFeedback(player, "catch_result", {
        success = true,
        fishId = fishData.id,
        fishName = fishData.name,
        value = fishData.value,
        rarity = fishData.rarity,
    })

    FishingSystem.activeCasts[player.UserId] = nil
    return true
end

function FishingSystem.cancelCast(userId)
    FishingSystem.activeCasts[userId] = nil
end

return FishingSystem
