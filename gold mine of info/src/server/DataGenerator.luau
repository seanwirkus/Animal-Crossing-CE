--[[
	DataGenerator
	Utility script to fetch data from Nookipedia API and generate Luau data files
	Run this from the server console to populate game data automatically
	
	Usage in Roblox Studio Command Bar:
	local DataGenerator = require(game.ServerScriptService.DataGenerator)
	DataGenerator.GenerateAllData()
]]

local NookipediaService = require(script.Parent.Services.NookipediaService)

local DataGenerator = {}

-- Convert Nookipedia data to our game's data format
local function parseBirthday(rawBirthday: string?): (string, string)
	if not rawBirthday or rawBirthday == "" then
		return "Unknown", ""
	end

	local month, day = rawBirthday:match("^(%a+)%s+(%d+)$")
	if month and day then
		return month, day
	end

	local numericMonth, numericDay = rawBirthday:match("^(%d+)%-(%d+)$")
	if numericMonth and numericDay then
		return numericMonth, numericDay
	end

	return rawBirthday, ""
end

local function convertVillagerData(nookData)
	local source = nookData.source or {}
	local displayName = nookData.name or source.displayName or source.id or "Villager"
	local villagerId = displayName:lower():gsub("[^%w]+", "_")
	local birthdayMonth, birthdayDay = parseBirthday(nookData.birthday or source.birthday)
	local phrase = nookData.phrase or source.catchphrase or (source.dialogue and source.dialogue.catchphrases and source.dialogue.catchphrases[1]) or "Howdy"

	return {
		id = villagerId,
		displayName = displayName,
		personality = nookData.personality or source.personality or "Normal",
		species = nookData.species or source.species or "Unknown",
		birthday = string.format("%s %s", birthdayMonth, birthdayDay):gsub("%s+$", ""),
		catchphrase = phrase,
		favoriteItems = source.favoriteItems or {},
		dialogue = source.dialogue or {
			greetings = {
				"Hey there!",
				"What's up?"
			},
			daily = {
				"Having a good day?",
				"The weather is nice today."
			},
			catchphrases = { phrase },
			quests = {
				"Could you help me with something?"
			}
		},
		schedule = source.schedule or {
			{ activity = "Wander", startHour = 6, endHour = 22, locationTag = "Plaza" },
			{ activity = "Sleep", startHour = 22, endHour = 6, locationTag = "Home" },
		},
		homeModel = source.homeModel or displayName:gsub(" ", "") .. "House",
		themeColor = source.themeColor or { 0.5, 0.5, 0.5 },
	}
end

local function convertFishData(nookData)
	return {
		id = "fish_" .. nookData.name:lower():gsub(" ", "_"):gsub("-", "_"),
		name = nookData.name,
		category = "Fish",
		baseValue = nookData.sell_nook or 0,
		rarity = nookData.rarity or "Common",
		description = nookData["museum-phrase"] or "A fish caught in the waters.",
		location = nookData.location or "River",
		shadowSize = nookData.shadow_size or "Medium",
		catchDifficulty = nookData.difficulty or "Medium",
		timeWindows = {}, -- Would parse from time string
		seasonTags = {}, -- Would parse from north/south months
	}
end

local function convertBugData(nookData)
	return {
		id = "bug_" .. nookData.name:lower():gsub(" ", "_"):gsub("-", "_"),
		name = nookData.name,
		category = "Bug",
		baseValue = nookData.sell_nook or 0,
		rarity = nookData.rarity or "Common",
		description = nookData["museum-phrase"] or "A bug found on the island.",
		location = nookData.location or "Flying",
		catchDifficulty = nookData.rarity or "Medium",
		timeWindows = {}, -- Would parse from time string
		seasonTags = {}, -- Would parse from north/south months
	}
end

local function convertFurnitureData(nookData)
	return {
		id = "furniture_" .. nookData.name:lower():gsub(" ", "_"):gsub("-", "_"),
		name = nookData.name,
		category = "Furniture",
		baseValue = nookData.buy or 0,
		sellValue = nookData.sell or 0,
		rarity = "Common",
		description = nookData.description or "A piece of furniture.",
		size = nookData.size or "1x1",
		canBePlaced = true,
		themes = nookData.themes or {},
	}
end

local function convertToolData(nookData)
	return {
		id = "tool_" .. nookData.name:lower():gsub(" ", "_"):gsub("-", "_"),
		name = nookData.name,
		category = "Tool",
		baseValue = nookData.buy or 0,
		durability = nookData.uses or 30,
		description = nookData.variation or "A useful tool.",
		toolType = nookData.category or "Basic",
	}
end

-- Generate Villagers data
function DataGenerator.GenerateVillagers()
	print("[DataGenerator] Fetching villagers from Nookipedia...")
	
	local api = NookipediaService.new()
	
	-- Get villagers that appear in New Horizons
	local villagers = api:GetVillagers({
		game = {"NH"},
		excludedetails = "false"
	})
	
	if not villagers then
		warn("[DataGenerator] Failed to fetch villagers")
		return
	end
	
	print(string.format("[DataGenerator] Fetched %d villagers", #villagers))
	
	-- Convert to our format
	local convertedVillagers = {}
	for i, villager in ipairs(villagers) do
		if i <= 20 then  -- Limit to first 20 for testing
			local converted = convertVillagerData(villager)
			convertedVillagers[converted.id] = converted
			print(string.format("  - %s (%s, %s)", converted.displayName, converted.personality, converted.species))
		end
	end
	
	print("[DataGenerator] ✅ Villagers data ready!")
	return convertedVillagers
end

-- Generate Fish data
function DataGenerator.GenerateFish()
	print("[DataGenerator] Fetching fish from Nookipedia...")
	
	local api = NookipediaService.new()
	local fish = api:GetFish()
	
	if not fish then
		warn("[DataGenerator] Failed to fetch fish")
		return
	end
	
	print(string.format("[DataGenerator] Fetched %d fish", #fish))
	
	-- Convert to our format
	local convertedFish = {}
	for i, fishData in ipairs(fish) do
		if i <= 30 then  -- Limit to first 30
			local converted = convertFishData(fishData)
			convertedFish[converted.id] = converted
			print(string.format("  - %s ($%d, %s)", converted.name, converted.baseValue, converted.location))
		end
	end
	
	print("[DataGenerator] ✅ Fish data ready!")
	return convertedFish
end

-- Generate Bugs data
function DataGenerator.GenerateBugs()
	print("[DataGenerator] Fetching bugs from Nookipedia...")
	
	local api = NookipediaService.new()
	local bugs = api:GetBugs()
	
	if not bugs then
		warn("[DataGenerator] Failed to fetch bugs")
		return
	end
	
	print(string.format("[DataGenerator] Fetched %d bugs", #bugs))
	
	-- Convert to our format
	local convertedBugs = {}
	for i, bugData in ipairs(bugs) do
		if i <= 30 then  -- Limit to first 30
			local converted = convertBugData(bugData)
			convertedBugs[converted.id] = converted
			print(string.format("  - %s ($%d, %s)", converted.name, converted.baseValue, converted.location))
		end
	end
	
	print("[DataGenerator] ✅ Bugs data ready!")
	return convertedBugs
end

-- Generate Furniture data
function DataGenerator.GenerateFurniture()
	print("[DataGenerator] Fetching furniture from Nookipedia...")
	
	local api = NookipediaService.new()
	local furniture = api:GetFurniture()
	
	if not furniture then
		warn("[DataGenerator] Failed to fetch furniture")
		return
	end
	
	print(string.format("[DataGenerator] Fetched %d furniture items", #furniture))
	
	-- Convert to our format (limit to 50 items)
	local convertedFurniture = {}
	for i, furnitureData in ipairs(furniture) do
		if i <= 50 then
			local converted = convertFurnitureData(furnitureData)
			convertedFurniture[converted.id] = converted
			print(string.format("  - %s ($%d)", converted.name, converted.baseValue))
		end
	end
	
	print("[DataGenerator] ✅ Furniture data ready!")
	return convertedFurniture
end

-- Generate Tools data
function DataGenerator.GenerateTools()
	print("[DataGenerator] Fetching tools from Nookipedia...")
	
	local api = NookipediaService.new()
	local tools = api:GetTools()
	
	if not tools then
		warn("[DataGenerator] Failed to fetch tools")
		return
	end
	
	print(string.format("[DataGenerator] Fetched %d tools", #tools))
	
	-- Convert to our format
	local convertedTools = {}
	for i, toolData in ipairs(tools) do
		local converted = convertToolData(toolData)
		convertedTools[converted.id] = converted
		print(string.format("  - %s ($%d, %d uses)", converted.name, converted.baseValue, converted.durability))
	end
	
	print("[DataGenerator] ✅ Tools data ready!")
	return convertedTools
end

-- Generate ALL data at once
function DataGenerator.GenerateAllData()
	print(string.rep("=", 60))
	print("[DataGenerator] 🌟 Starting data generation from Nookipedia API")
	print(string.rep("=", 60))
	
	local startTime = tick()
	
	local results = {
		villagers = DataGenerator.GenerateVillagers(),
		fish = DataGenerator.GenerateFish(),
		bugs = DataGenerator.GenerateBugs(),
		furniture = DataGenerator.GenerateFurniture(),
		tools = DataGenerator.GenerateTools(),
	}
	
	local elapsed = tick() - startTime
	
	print(string.rep("=", 60))
	print(string.format("[DataGenerator] ✅ Complete! Generated in %.2f seconds", elapsed))
	print(string.rep("=", 60))
	print("\n📊 Data Summary:")
	print(string.format("  Villagers: %d", results.villagers and #results.villagers or 0))
	print(string.format("  Fish: %d", results.fish and #results.fish or 0))
	print(string.format("  Bugs: %d", results.bugs and #results.bugs or 0))
	print(string.format("  Furniture: %d", results.furniture and #results.furniture or 0))
	print(string.format("  Tools: %d", results.tools and #results.tools or 0))
	print("\n💡 Tip: Copy the results table to your Data modules!")
	
	return results
end

-- Quick test function
function DataGenerator.Test()
	print("[DataGenerator] Running API test...")
	
	local api = NookipediaService.new()
	
	-- Test villagers
	local villagers = api:GetVillagers({ name = "Raymond" })
	if villagers and #villagers > 0 then
		print("✅ Villagers API working - Found:", villagers[1].name)
	else
		warn("❌ Villagers API failed")
	end
	
	-- Test fish
	local fish = api:GetFishByName("Sea Bass")
	if fish then
		print("✅ Fish API working - Found:", fish.name)
	else
		warn("❌ Fish API failed")
	end
	
	-- Test bugs
	local bugs = api:GetBugByName("Common Butterfly")
	if bugs then
		print("✅ Bugs API working - Found:", bugs.name)
	else
		warn("❌ Bugs API failed")
	end
	
	print("[DataGenerator] Test complete!")
end

return DataGenerator
