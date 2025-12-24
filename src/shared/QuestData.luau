-- QuestData.luau - Predefined quests using Nookipedia data

local QuestData = {}

-- Tutorial Quests
QuestData.TUTORIAL_QUESTS = {
    gather_resources_tutorial = {
        id = "gather_resources_tutorial",
        name = "Gather Resources",
        description = "Gather materials for building your home! Chop trees and hit rocks.",
        category = "tutorial",
        difficulty = "easy",
        icon = "🪓",
        target = 1, -- Simplified - just complete the task
        objectives = {
            {
                type = "gather_materials",
                amount = 1,
                hint = "Use your Axe to chop trees and Shovel to hit rocks!",
            },
        },
        rewards = {
            bells = 300,
            miles = 30,
            items = {},
        },
    },
    fishing_tutorial = {
        id = "fishing_tutorial",
        name = "Catch Your First Fish",
        description = "Head to the beach or river and catch 3 fish to complete your tutorial!",
        category = "tutorial",
        difficulty = "easy",
        icon = "🎣",
        target = 3,
        objectives = {
            {
                type = "catch_fish",
                amount = 3,
                hint = "Find water and cast your fishing rod. Wait for the bobber to go under!",
            },
        },
        rewards = {
            bells = 500,
            miles = 50,
            items = {},
        },
    },
    crafting_tutorial = {
        id = "crafting_tutorial",
        name = "First Craft",
        description = "Craft your first item at a DIY workbench!",
        category = "tutorial",
        difficulty = "easy",
        icon = "🔨",
        target = 1,
        objectives = {
            {
                type = "craft_item",
                amount = 1,
                hint = "Find a DIY workbench and craft any item!",
            },
        },
        rewards = {
            bells = 300,
            miles = 30,
            items = {},
        },
    },
    collect_fruit = {
        id = "collect_fruit",
        name = "Fruit Collector",
        description = "Collect 5 pieces of fruit from trees around your island.",
        category = "tutorial",
        difficulty = "easy",
        icon = "🍎",
        target = 5,
        objectives = {
            {
                type = "collect_item",
                amount = 5,
                hint = "Shake trees to get fruit! Apples, oranges, cherries, and more.",
            },
        },
        rewards = {
            bells = 400,
            miles = 40,
            items = {},
        },
    },
    chop_trees = {
        id = "chop_trees",
        name = "Lumberjack Training",
        description = "Chop down 3 trees to gather wood for crafting!",
        category = "tutorial",
        difficulty = "easy",
        icon = "🪓",
        target = 3,
        objectives = {
            {
                type = "chop_tree",
                amount = 3,
                hint = "Equip your axe and chop trees! Each tree takes 3 hits.",
            },
        },
        rewards = {
            bells = 500,
            miles = 50,
            items = {},
        },
    },
    gather_stone = {
        id = "gather_stone",
        name = "Rock Solid",
        description = "Hit rocks to collect 10 pieces of stone!",
        category = "tutorial",
        difficulty = "easy",
        icon = "🪨",
        target = 10,
        objectives = {
            {
                type = "collect_stone",
                amount = 10,
                hint = "Hit rocks with your shovel or pickaxe to gather materials!",
            },
        },
        rewards = {
            bells = 600,
            miles = 60,
            items = {},
        },
    },
}

-- Daily Quests
QuestData.DAILY_QUESTS = {
    daily_fishing = {
        id = "daily_fishing",
        name = "Daily Fishing",
        description = "Catch 5 fish today to earn rewards!",
        category = "daily",
        difficulty = "normal",
        icon = "🎣",
        target = 5,
        objectives = {
            {
                type = "catch_fish",
                amount = 5,
                hint = "Try different locations - rivers, ocean, and ponds!",
            },
        },
        rewards = {
            bells = 1000,
            miles = 100,
            items = {},
        },
    },
    daily_catch_rare_fish = {
        id = "daily_catch_rare_fish",
        name = "Rare Catch",
        description = "Catch a rare fish (worth 5000+ bells) for Blathers!",
        category = "daily",
        difficulty = "normal",
        icon = "🐟",
        target = 1,
        objectives = {
            {
                type = "catch_fish",
                targetId = "rare", -- Special flag for rare fish
                amount = 1,
                hint = "Look for large shadows in the ocean or river!",
            },
        },
        rewards = {
            bells = 2000,
            miles = 200,
            items = {},
        },
    },
    daily_bug_catching = {
        id = "daily_bug_catching",
        name = "Bug Collector",
        description = "Catch 4 bugs for the museum collection.",
        category = "daily",
        difficulty = "normal",
        icon = "🐛",
        target = 4,
        objectives = {
            {
                type = "catch_bug",
                amount = 4,
                hint = "Use your net to catch bugs on trees, flowers, and the ground!",
            },
        },
        rewards = {
            bells = 800,
            miles = 120,
            items = {},
        },
    },
    daily_crafting = {
        id = "daily_crafting",
        name = "Craft Order",
        description = "Craft 2 pieces of furniture for the island shop.",
        category = "daily",
        difficulty = "normal",
        icon = "🪑",
        target = 2,
        objectives = {
            {
                type = "craft_item",
                amount = 2,
                hint = "Any furniture crafted at the workbench counts!",
            },
        },
        rewards = {
            bells = 800,
            miles = 140,
            items = {},
        },
    },
    daily_collect_shells = {
        id = "daily_collect_shells",
        name = "Beachcomber",
        description = "Collect 3 shells washed ashore after the tide.",
        category = "daily",
        difficulty = "easy",
        icon = "🐚",
        target = 3,
        objectives = {
            {
                type = "collect_item",
                amount = 3,
                hint = "Check both beaches for sparkling shells!",
            },
        },
        rewards = {
            bells = 450,
            miles = 90,
            items = {},
        },
    },
    daily_dig_fossils = {
        id = "daily_dig_fossils",
        name = "Fossil Hunter",
        description = "Dig up 2 fossils for the museum!",
        category = "daily",
        difficulty = "normal",
        icon = "🦴",
        target = 2,
        objectives = {
            {
                type = "dig_fossil",
                amount = 2,
                hint = "Look for star-shaped cracks in the ground!",
            },
        },
        rewards = {
            bells = 600,
            miles = 110,
            items = {},
        },
    },
}

-- Weekly Quests
QuestData.WEEKLY_QUESTS = {
    weekly_fishing_master = {
        id = "weekly_fishing_master",
        name = "Fishing Master",
        description = "Catch 20 fish this week to become a fishing master!",
        category = "weekly",
        difficulty = "hard",
        icon = "🎣",
        target = 20,
        objectives = {
            {
                type = "catch_fish",
                amount = 20,
                hint = "Keep fishing throughout the week!",
            },
        },
        rewards = {
            bells = 5000,
            miles = 500,
            items = {},
        },
    },
    weekly_crafting_master = {
        id = "weekly_crafting_master",
        name = "Master Crafter",
        description = "Craft 10 different items this week!",
        category = "weekly",
        difficulty = "hard",
        icon = "🔨",
        target = 10,
        objectives = {
            {
                type = "craft_item",
                amount = 10,
                hint = "Try crafting different types of items!",
            },
        },
        rewards = {
            bells = 4000,
            miles = 400,
            items = {},
        },
    },
    weekly_collector = {
        id = "weekly_collector",
        name = "Island Collector",
        description = "Collect 50 different items this week!",
        category = "weekly",
        difficulty = "hard",
        icon = "📦",
        target = 50,
        objectives = {
            {
                type = "collect_item",
                amount = 50,
                hint = "Fish, bugs, fruit, shells - everything counts!",
            },
        },
        rewards = {
            bells = 6000,
            miles = 600,
            items = {},
        },
    },
    weekly_rare_fish = {
        id = "weekly_rare_fish",
        name = "Rare Fish Hunter",
        description = "Catch 3 rare fish (worth 5000+ bells) this week!",
        category = "weekly",
        difficulty = "hard",
        icon = "🐟",
        target = 3,
        objectives = {
            {
                type = "catch_fish",
                targetId = "rare",
                amount = 3,
                hint = "Look for large shadows and try different times of day!",
            },
        },
        rewards = {
            bells = 8000,
            miles = 800,
            items = {},
        },
    },
}

-- Milestone Quests
QuestData.MILESTONE_QUESTS = {
    milestone_fish_collection = {
        id = "milestone_fish_collection",
        name = "Fish Collection",
        description = "Catch 25 different fish species for the museum!",
        category = "milestone",
        difficulty = "hard",
        icon = "🐠",
        target = 25,
        objectives = {
            {
                type = "catch_fish",
                amount = 25,
                hint = "Try different locations, times, and seasons!",
            },
        },
        rewards = {
            bells = 10000,
            miles = 1000,
            items = {},
        },
    },
    milestone_crafting_master = {
        id = "milestone_crafting_master",
        name = "Crafting Master",
        description = "Craft 50 different items to become a crafting master!",
        category = "milestone",
        difficulty = "hard",
        icon = "🛠️",
        target = 50,
        objectives = {
            {
                type = "craft_item",
                amount = 50,
                hint = "Explore all the recipes available!",
            },
        },
        rewards = {
            bells = 12000,
            miles = 1200,
            items = {},
        },
    },
    milestone_bell_collector = {
        id = "milestone_bell_collector",
        name = "Bell Collector",
        description = "Earn 50,000 bells through selling items!",
        category = "milestone",
        difficulty = "hard",
        icon = "💰",
        target = 50000,
        objectives = {
            {
                type = "spend_bells",
                amount = 50000,
                hint = "Sell fish, bugs, and items to earn bells!",
            },
        },
        rewards = {
            bells = 5000,
            miles = 2000,
            items = {},
        },
    },
}

-- Get all quests
function QuestData.getAllQuests()
    local all = {}

    for _, quest in pairs(QuestData.TUTORIAL_QUESTS) do
        table.insert(all, quest)
    end
    for _, quest in pairs(QuestData.DAILY_QUESTS) do
        table.insert(all, quest)
    end
    for _, quest in pairs(QuestData.WEEKLY_QUESTS) do
        table.insert(all, quest)
    end
    for _, quest in pairs(QuestData.MILESTONE_QUESTS) do
        table.insert(all, quest)
    end

    return all
end

-- Get random daily quest
function QuestData.getRandomDailyQuest()
    local dailies = QuestData.DAILY_QUESTS
    local keys = {}
    for key, _ in pairs(dailies) do
        table.insert(keys, key)
    end
    if #keys > 0 then
        return dailies[keys[math.random(1, #keys)]]
    end
    return nil
end

-- Get random weekly quest
function QuestData.getRandomWeeklyQuest()
    local weeklies = QuestData.WEEKLY_QUESTS
    local keys = {}
    for key, _ in pairs(weeklies) do
        table.insert(keys, key)
    end
    if #keys > 0 then
        return weeklies[keys[math.random(1, #keys)]]
    end
    return nil
end

return QuestData
