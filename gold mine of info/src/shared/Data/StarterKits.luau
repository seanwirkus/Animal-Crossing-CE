-- export type KitItem = { id: string, amount: number }
-- export type StarterKit = {
--     tools: { KitItem },
--     resources: { KitItem },
--     bonusBells: number?,
--     bonusMiles: number?,
--     quests: { string }?,
-- }

local DEFAULT_KIT = {
    tools = {},
    resources = {},
    bonusBells = 0,
    bonusMiles = 0,
    quests = {},
}

local STARTER_KITS = {
    coral_cove = {
        tools = {
            { id = "tool_fishing_rod_basic", amount = 1 },
            { id = "tool_bug_net_basic", amount = 1 },
        },
        resources = {
            { id = "fruit_orange", amount = 6 },
            { id = "shell_pink", amount = 2 },
            { id = "fish_perch", amount = 1 },
        },
        bonusBells = 500,
        bonusMiles = 100,
        quests = { "daily_fish_round", "daily_shell_collection" },
    },
    forest_glade = {
        tools = {
            { id = "tool_flimsy_axe", amount = 1 },
            { id = "tool_watering_can_basic", amount = 1 },
        },
        resources = {
            { id = "crafting_softwood", amount = 12 },
            { id = "fruit_pear", amount = 4 },
            { id = "bug_firefly", amount = 1 },
        },
        bonusBells = 300,
        bonusMiles = 200,
        quests = { "daily_resource_fruit", "daily_cleanup" },
    },
    highland_spring = {
        tools = {
            { id = "tool_shovel_basic", amount = 1 },
            { id = "tool_bug_net_basic", amount = 1 },
        },
        resources = {
            { id = "crafting_hardwood", amount = 10 },
            { id = "fish_koi", amount = 1 },
            { id = "bug_tiger_beetle", amount = 1 },
        },
        bonusBells = 400,
        bonusMiles = 150,
        quests = { "daily_bug_round", "daily_crafting_order" },
    },
}

local function cloneKit(kit)
    if not kit then
        return {
            tools = {},
            resources = {},
            bonusBells = DEFAULT_KIT.bonusBells or 0,
            bonusMiles = DEFAULT_KIT.bonusMiles or 0,
            quests = {},
        }
    end

    local cloned = {
        tools = {},
        resources = {},
        bonusBells = kit.bonusBells or 0,
        bonusMiles = kit.bonusMiles or 0,
        quests = {},
    }

    for _, entry in ipairs(kit.tools or {}) do
        table.insert(cloned.tools, { id = entry.id, amount = entry.amount })
    end

    for _, entry in ipairs(kit.resources or {}) do
        table.insert(cloned.resources, { id = entry.id, amount = entry.amount })
    end

    for _, questId in ipairs(kit.quests or {}) do
        table.insert(cloned.quests, questId)
    end

    return cloned
end

local StarterKits = {}

function StarterKits.get(templateId)
    if not templateId then
        return cloneKit(DEFAULT_KIT)
    end

    return cloneKit(STARTER_KITS[templateId] or DEFAULT_KIT)
end

function StarterKits.all()
    return STARTER_KITS
end

return StarterKits
