local CraftingSystem = require(script.Parent.Parent.CraftingSystem)

local CraftingStationsConfig = {}

local stations = {
    [CraftingSystem.CRAFTING_STATIONS.WORKBENCH] = {
        id = CraftingSystem.CRAFTING_STATIONS.WORKBENCH,
        name = "DIY Workbench",
        description = "Default station for wood, tools, and early furniture.",
        cost = 0,
        icon = "🪵",
        requires = {},
        rewardTag = "station_workbench",
    },
    [CraftingSystem.CRAFTING_STATIONS.FORGE] = {
        id = CraftingSystem.CRAFTING_STATIONS.FORGE,
        name = "Forge",
        description = "Unlocks metal tools, bells furniture, and higher durability gear.",
        cost = 25000,
        icon = "🔥",
        requires = { inventoryLevel = 2 },
        rewardTag = "station_forge",
    },
    [CraftingSystem.CRAFTING_STATIONS.COOKING] = {
        id = CraftingSystem.CRAFTING_STATIONS.COOKING,
        name = "Cooking Stove",
        description = "Lets you prepare dishes that boost stamina for terraforming.",
        cost = 15000,
        icon = "🍳",
        requires = { station = CraftingSystem.CRAFTING_STATIONS.FORGE },
        rewardTag = "station_cooking",
    },
    [CraftingSystem.CRAFTING_STATIONS.SEWING] = {
        id = CraftingSystem.CRAFTING_STATIONS.SEWING,
        name = "Sewing Table",
        description = "Craft clothing and fabric wallpapers for villager gifts.",
        cost = 18000,
        icon = "🧵",
        requires = { inventoryLevel = 3 },
        rewardTag = "station_sewing",
    },
    [CraftingSystem.CRAFTING_STATIONS.ALCHEMY] = {
        id = CraftingSystem.CRAFTING_STATIONS.ALCHEMY,
        name = "Potion Bench",
        description = "Prototype station for weather charms and rare dyes.",
        cost = 32000,
        icon = "✨",
        requires = { station = CraftingSystem.CRAFTING_STATIONS.COOKING },
        rewardTag = "station_alchemy",
    },
}

function CraftingStationsConfig.getStationConfig(id: string)
    return stations[id]
end

function CraftingStationsConfig.getAll()
    local result = {}
    for _, config in pairs(stations) do
        table.insert(result, config)
    end
    table.sort(result, function(a, b)
        return (a.cost or 0) < (b.cost or 0)
    end)
    return result
end

return CraftingStationsConfig
