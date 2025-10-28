-- QuestTypes.luau - Quest system type definitions and constants

local QuestTypes = {}

-- Quest states
QuestTypes.QuestState = {
	PENDING = "pending",      -- Quest available but not started
	ACTIVE = "active",        -- Quest in progress
	COMPLETED = "completed",  -- Quest finished but rewards not claimed
	CLAIMED = "claimed",      -- Rewards collected
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

-- Quest data structure
QuestTypes.QuestData = {
	id = "",                          -- Unique quest ID
	name = "",                        -- Display name
	description = "",                 -- Quest description
	category = "tutorial",            -- Quest category
	difficulty = "easy",              -- Difficulty level
	icon = "📋",                      -- Quest icon emoji
	state = "pending",                -- Current state
	progress = 0,                     -- Current progress (0-100)
	target = 1,                       -- Target to complete
	rewards = {
		bells = 0,                    -- Bell reward
		miles = 0,                    -- Nook Miles reward
		items = {},                   -- Item rewards
	},
	createdAt = 0,                    -- When quest was created
	completedAt = nil,                -- When quest was completed
	claimedAt = nil,                  -- When rewards were claimed
}

-- Reward structure
QuestTypes.Reward = {
	bells = 0,
	miles = 0,
	items = {},  -- { { name = "item", quantity = 1 }, ... }
}

-- Predefined quests
QuestTypes.PredefinedQuests = {
	FISHING_TUTORIAL = {
		id = "fishing_tutorial",
		name = "Catch Your First Fish",
		description = "Head to the beach and catch 3 fish to complete your tutorial!",
		category = "tutorial",
		difficulty = "easy",
		icon = "🎣",
		target = 3,
		rewards = {
			bells = 500,
			miles = 50,
			items = {},
		},
	},
	DAILY_FISHING = {
		id = "daily_fishing",
		name = "Daily Fishing",
		description = "Catch 5 fish today",
		category = "daily",
		difficulty = "normal",
		icon = "🎣",
		target = 5,
		rewards = {
			bells = 1000,
			miles = 100,
		},
	},
	WEEKLY_EXPLORER = {
		id = "weekly_explorer",
		name = "Island Explorer",
		description = "Visit 5 different islands this week",
		category = "weekly",
		difficulty = "hard",
		icon = "🗺️",
		target = 5,
		rewards = {
			bells = 5000,
			miles = 500,
		},
	},
}

return QuestTypes
