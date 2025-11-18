local InventoryConstants = require(script.Parent.InventoryConstants)

local InventoryUpgrades = {}

local LEVELS = {
    {
        level = 1,
        label = "Starter Pockets",
        slots = InventoryConstants.getMaxSlotsFromLevel(1),
        cost = 0,
        description = "Enough space for the basics while you learn the ropes.",
        rewardTag = "starter",
    },
    {
        level = 2,
        label = "Handy Satchel",
        slots = InventoryConstants.getMaxSlotsFromLevel(2),
        cost = 5000,
        description = "Adds a second row so you can gather wood, stone, and shells without running home.",
        rewardTag = "inventory_level_2",
    },
    {
        level = 3,
        label = "Field Backpack",
        slots = InventoryConstants.getMaxSlotsFromLevel(3),
        cost = 20000,
        description = "Doubles crafting throughput and prepares you for fishing/bug streaks.",
        rewardTag = "inventory_level_3",
    },
    {
        level = 4,
        label = "Pro Organizer",
        slots = InventoryConstants.getMaxSlotsFromLevel(4),
        cost = 50000,
        description = "Maximum carry capacity for late-game decorating and terraforming.",
        rewardTag = "inventory_level_4",
    },
}

local LEVEL_LOOKUP = {}
for _, levelConfig in ipairs(LEVELS) do
    LEVEL_LOOKUP[levelConfig.level] = levelConfig
end

function InventoryUpgrades.getConfig(level: number)
    return LEVEL_LOOKUP[level]
end

function InventoryUpgrades.getNextConfig(currentLevel: number)
    local index = math.clamp(currentLevel or 1, 1, #LEVELS)
    if index >= #LEVELS then
        return nil
    end
    return LEVELS[index + 1]
end

function InventoryUpgrades.getMaxLevel()
    return #LEVELS
end

function InventoryUpgrades.describe(level: number)
    local config = InventoryUpgrades.getConfig(level)
    if not config then
        return nil
    end

    return {
        level = config.level,
        label = config.label,
        slots = config.slots,
        cost = config.cost,
        description = config.description,
    }
end

function InventoryUpgrades.buildUpgradePayload(currentLevel: number, bells: number)
    local currentConfig = InventoryUpgrades.getConfig(currentLevel) or LEVELS[1]
    local nextConfig = InventoryUpgrades.getNextConfig(currentLevel)

    return {
        level = currentConfig.level,
        label = currentConfig.label,
        maxSlots = currentConfig.slots,
        nextLevel = nextConfig and nextConfig.level or nil,
        nextSlots = nextConfig and nextConfig.slots or nil,
        cost = nextConfig and nextConfig.cost or 0,
        canUpgrade = nextConfig and bells >= (nextConfig.cost or 0) or false,
        reachedMax = nextConfig == nil,
        description = currentConfig.description,
        rewardTag = nextConfig and nextConfig.rewardTag or nil,
    }
end

return InventoryUpgrades
