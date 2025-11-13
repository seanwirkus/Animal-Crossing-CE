local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ItemDataFetcher = require(sharedFolder:WaitForChild("ItemDataFetcher"))

local BuildingCatalog = {}
BuildingCatalog.__index = BuildingCatalog

export type MaterialRequirement = {
    itemId: string,
    count: number,
}

export type RewardDefinition = {
    bells: number?,
    items: { string }?,
}

export type ProjectDefinition = {
    id: string,
    name: string,
    category: string,
    scope: "island" | "home-exterior" | "home-interior",
    description: string,
    itemId: string?,
    requirements: {
        materials: { MaterialRequirement }?,
        deliveries: number?,
    }?,
    rewards: RewardDefinition?,
    repeatable: boolean?,
    requires: { string }?,
}

local CATEGORY_METADATA = {
    {
        id = "community",
        name = "Island Projects",
        description = "Fundamental structures unlocked for everyone.",
        scope = "island",
    },
    {
        id = "infrastructure",
        name = "Infrastructure",
        description = "Bridges, inclines, and utilities for travel.",
        scope = "island",
    },
    {
        id = "home-exterior",
        name = "House Exterior",
        description = "Upgrade plots and spruce up your yard.",
        scope = "home-exterior",
    },
    {
        id = "home-interior",
        name = "Interior Décor",
        description = "Finishings that make a house a home.",
        scope = "home-interior",
    },
}

local PROJECTS: { ProjectDefinition } = {
    {
        id = "island-bonfire",
        name = "Plaza Bonfire",
        category = "community",
        scope = "island",
        description = "A welcoming bonfire for new residents. Required before larger projects unlock.",
        itemId = "bonfire",
        requirements = {
            materials = {
                { itemId = "wood", count = 10 },
                { itemId = "softwood", count = 4 },
            },
            deliveries = 1,
        },
        rewards = {
            bells = 750,
        },
        repeatable = false,
    },
    {
        id = "log-bridge",
        name = "Log Bridge",
        category = "infrastructure",
        scope = "island",
        description = "Lay a rustic bridge to connect the starter river banks.",
        itemId = "bridge-construction-kit",
        requirements = {
            materials = {
                { itemId = "log-stakes", count = 4 },
                { itemId = "wood", count = 10 },
                { itemId = "iron-nugget", count = 4 },
            },
            deliveries = 2,
        },
        rewards = {
            bells = 1250,
        },
        repeatable = false,
        requires = { "island-bonfire" },
    },
    {
        id = "resident-services-upgrade",
        name = "Resident Services Upgrade",
        category = "community",
        scope = "island",
        description = "Expand Resident Services with a proper building.",
        itemId = "abd",
        requirements = {
            materials = {
                { itemId = "wood", count = 15 },
                { itemId = "softwood", count = 15 },
                { itemId = "hardwood", count = 15 },
                { itemId = "iron-nugget", count = 10 },
            },
            deliveries = 3,
        },
        rewards = {
            bells = 2500,
        },
        repeatable = false,
        requires = { "log-bridge" },
    },
    {
        id = "home-plot-expansion",
        name = "Expand Home Plot",
        category = "home-exterior",
        scope = "home-exterior",
        description = "Stake out more yard space and prep utilities for a personal home.",
        itemId = "log-stakes",
        requirements = {
            materials = {
                { itemId = "log-stakes", count = 2 },
                { itemId = "wood", count = 8 },
            },
            deliveries = 1,
        },
        rewards = {
            bells = 600,
        },
        repeatable = false,
        requires = { "island-bonfire" },
    },
    {
        id = "home-exterior-kit",
        name = "Custom Exterior Kit",
        category = "home-exterior",
        scope = "home-exterior",
        description = "Craft siding, roofing, and trim for your personal house.",
        itemId = "campfire",
        requirements = {
            materials = {
                { itemId = "wood", count = 6 },
                { itemId = "softwood", count = 6 },
                { itemId = "iron-nugget", count = 2 },
            },
            deliveries = 1,
        },
        rewards = {
            bells = 450,
        },
        repeatable = true,
        requires = { "home-plot-expansion" },
    },
    {
        id = "interior-decor-pack",
        name = "Interior Décor Pack",
        category = "home-interior",
        scope = "home-interior",
        description = "Deliver crafted furniture to personalize your interior space.",
        itemId = "1-up-mushroom",
        requirements = {
            materials = {
                { itemId = "wood", count = 4 },
                { itemId = "softwood", count = 4 },
            },
            deliveries = 1,
        },
        rewards = {
            bells = 350,
        },
        repeatable = true,
        requires = { "home-plot-expansion" },
    },
}

local projectById: { [string]: ProjectDefinition } = {}
for _, project in ipairs(PROJECTS) do
    projectById[project.id] = project
end

local function cloneArray(array)
    local result = {}
    for index, value in ipairs(array or {}) do
        result[index] = value
    end
    return result
end

local function cloneMaterials(materials)
    local result = {}
    for index, material in ipairs(materials or {}) do
        result[index] = {
            itemId = material.itemId,
            count = material.count,
        }
    end
    return result
end

local function cloneProject(project: ProjectDefinition): ProjectDefinition
    local copy = table.clone(project)
    if project.requirements then
        copy.requirements = {
            deliveries = project.requirements.deliveries,
            materials = cloneMaterials(project.requirements.materials),
        }
    end
    if project.rewards then
        copy.rewards = table.clone(project.rewards)
        if project.rewards.items then
            copy.rewards.items = cloneArray(project.rewards.items)
        end
    end
    if project.requires then
        copy.requires = cloneArray(project.requires)
    end
    return copy
end

function BuildingCatalog.getCategories()
    local result = {}
    for index, category in ipairs(CATEGORY_METADATA) do
        result[index] = table.clone(category)
    end
    return result
end

function BuildingCatalog.getProjectsForCategory(categoryId: string)
    local results = {}
    for _, project in ipairs(PROJECTS) do
        if project.category == categoryId then
            table.insert(results, cloneProject(project))
        end
    end
    table.sort(results, function(a, b)
        return a.name < b.name
    end)
    return results
end

function BuildingCatalog.getProject(projectId: string): ProjectDefinition?
    return projectById[projectId]
end

local function resolveItemInfo(project: ProjectDefinition)
    if not project then
        return nil
    end

    if project.itemId then
        local item = ItemDataFetcher.getItem(project.itemId)
        if item then
            return {
                spriteIndex = item.spriteIndex,
                name = item.displayName or item.name,
            }
        end
    end

    return nil
end

function BuildingCatalog.getDisplayEntry(projectId: string)
    local project = projectById[projectId]
    if not project then
        return nil
    end

    local entry = cloneProject(project)
    entry.itemInfo = resolveItemInfo(project)
    return entry
end

function BuildingCatalog.getAllProjects()
    local results = {}
    for index, project in ipairs(PROJECTS) do
        results[index] = cloneProject(project)
    end
    return results
end

return BuildingCatalog
