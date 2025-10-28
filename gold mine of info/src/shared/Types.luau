-- Types removed for Roblox Studio compatibility
-- The project used Luau `export type` annotations during development.
-- Roblox Studio (and the runtime environment used for serving) does not accept Luau type declarations
-- inside ModuleScripts that are loaded at runtime, so we keep a commented summary here.

-- Rarity: "Common" | "Uncommon" | "Rare" | "UltraRare"
-- ItemCategory: "Fruit", "Fish", "Bug", "Shell", "Crafting", "Furniture", "Tool"

-- TimeWindow: { startHour, endHour }

-- ItemDefinition: {
--   id, name, category, baseValue, rarity, description,
--   seasonTags?, timeWindows?, requirements?
-- }

-- IslandDifficulty: "Calm" | "Balanced" | "Spirited"

-- IslandTemplate: {
--   id, displayName, tagline, difficulty, biomeTags, startingVillagers,
--   startingResources, description, thumbnail?, order?
-- }

-- VillagerPersonality: "Lazy" | "Normal" | "Peppy" | "Cranky" | "Snooty" | "Jock"

-- VillagerScheduleEntry: { activity, startHour, endHour, locationTag }

-- DialoguePool: { greetings, daily, catchphrases, quests }

-- VillagerDefinition: {
--   id, displayName, personality, favoriteItems, dialogue, schedule,
--   homeModel?, themeColor -- (RGB table)
-- }

-- QuestObjectiveType: "GatherItem" | "CatchFish" | "CatchBug" | "TalkToVillager" |
--                     "DeliverGift" | "DecorateArea"

-- QuestObjective: { objectiveType, targetId?, amount?, hint? }

export type QuestDefinition = {
	id: string,
	title: string,
	description: string,
	category: "Daily" | "Weekly" | "Milestone",
	personalityBias: string?,
	objectives: { { objectiveType: string, targetId: string?, amount: number?, hint: string? } },
	rewards: { bells: number?, miles: number?, items: { string }? }
}

-- WeatherPreset: "Sunny"|"Overcast"|"Rainy"|"Stormy"|"Snowy"

-- SpawnTableEntry: { itemId, weight, weatherWhitelist? }

-- No runtime definitions are needed; keep an empty module to satisfy requires.
return {}
