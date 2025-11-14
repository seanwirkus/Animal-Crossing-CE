-- QuestTypes.luau - Quest system type definitions and constants

local QuestTypes = {}

-- Quest states
QuestTypes.QuestState = {
    PENDING = "pending", -- Quest available but not started
    ACTIVE = "active", -- Quest in progress
    COMPLETED = "completed", -- Quest finished but rewards not claimed
    CLAIMED = "claimed", -- Rewards collected
}

-- Quest categories
QuestTypes.QuestCategory = {
    TUTORIAL = "tutorial",
    DAILY = "daily",
    WEEKLY = "weekly",
    STORY = "story",
    MILESTONE = "milestone",
}

-- Quest difficulty
QuestTypes.QuestDifficulty = {
    EASY = "easy",
    NORMAL = "normal",
    HARD = "hard",
}

-- Objective types
QuestTypes.ObjectiveType = {
    CATCH_FISH = "catch_fish",
    CATCH_BUG = "catch_bug",
    COLLECT_ITEM = "collect_item",
    CRAFT_ITEM = "craft_item",
    TALK_TO_VILLAGER = "talk_to_villager",
    SPEND_BELLS = "spend_bells",
    EARN_MILES = "earn_miles",
    PLACE_FURNITURE = "place_furniture",
    DIG_FOSSIL = "dig_fossil",
    SHAKE_TREE = "shake_tree",
}

-- Quest data structure
QuestTypes.QuestData = {
    id = "", -- Unique quest ID
    name = "", -- Display name
    description = "", -- Quest description
    category = "tutorial", -- Quest category
    difficulty = "easy", -- Difficulty level
    icon = "📋", -- Quest icon emoji
    state = "pending", -- Current state
    progress = 0, -- Current progress (0-target)
    target = 1, -- Target to complete
    objectives = {}, -- Array of objectives
    rewards = {
        bells = 0, -- Bell reward
        miles = 0, -- Nook Miles reward
        items = {}, -- Item rewards { {itemId = "", count = 1}, ... }
    },
    createdAt = 0, -- When quest was created
    completedAt = nil, -- When quest was completed
    claimedAt = nil, -- When rewards were claimed
}

-- Objective structure
QuestTypes.Objective = {
    type = "", -- ObjectiveType
    targetId = nil, -- Optional: specific item/fish/bug ID
    amount = 1, -- Amount needed
    hint = "", -- Hint text for player
}

-- Reward structure
QuestTypes.Reward = {
    bells = 0,
    miles = 0,
    items = {}, -- { { itemId = "item", count = 1 }, ... }
}

return QuestTypes
