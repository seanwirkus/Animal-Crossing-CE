local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Logger)
local LocalContentRepository = require(script.Parent.LocalContentRepository)

local NookipediaService = {}
NookipediaService.__index = NookipediaService

local CATEGORY_ALIASES = {
	fish = { "Fish" },
	bugs = { "Bug" },
	furniture = { "Furniture", "Housewares", "WallMounted" },
	tools = { "Tool" },
	sea = { "Sea Creature" },
}

local function shallowCopy<T>(source: T): T
	if type(source) ~= "table" then
		return source
	end

	local clone = {}
	for key, value in pairs(source :: any) do
		clone[key] = value
	end
	return clone :: any
end

local function normalizeKey(value: string?): string
	if not value or value == "" then
		return ""
	end
	return string.lower(value):gsub("[^%w]+", "_")
end

local function resolvePrice(item: {}): number?
	return item.baseValue or item.sellValue or item.price
end

local function buildFishEntry(item: {})
	return {
		id = item.id,
		name = item.name or item.id,
		sell_nook = resolvePrice(item),
		location = item.location or item.spawnLocation or "Sea",
		rarity = item.rarity or "Common",
		shadow_size = item.shadow or item.shadowSize or "Medium",
		image_url = item.imageUrl or item.image_url,
		icon_url = item.iconUrl or item.icon_url,
	}
end

local function buildBugEntry(item: {})
	return {
		id = item.id,
		name = item.name or item.id,
		sell_nook = resolvePrice(item),
		location = item.location or item.spawnLocation or "Ground",
		rarity = item.rarity or "Common",
		image_url = item.imageUrl or item.image_url,
		icon_url = item.iconUrl or item.icon_url,
	}
end

local function buildFurnitureEntry(item: {})
	return {
		id = item.id,
		name = item.name or item.id,
		buy = item.baseValue or item.buyValue or item.price or 0,
		sell = item.sellValue or math.floor((item.baseValue or 0) / 4),
		rarity = item.rarity or "Common",
		description = item.description,
		size = item.size or "1x1",
		themes = shallowCopy(item.themes or {}),
		image_url = item.imageUrl or item.image_url,
		icon_url = item.iconUrl or item.icon_url,
	}
end

local function buildToolEntry(item: {})
	return {
		id = item.id,
		name = item.name or item.id,
		buy = item.baseValue or item.buyValue or 0,
		sell = item.sellValue or math.floor((item.baseValue or 0) / 4),
		description = item.description,
		uses = item.durability or item.uses,
		category = item.toolType or "Basic",
	}
end

function NookipediaService.new()
	local self = setmetatable({}, NookipediaService)
	self._repository = LocalContentRepository.new()
	self._cache = {}
	return self
end

function NookipediaService:_resolveItem(name: string?, categories: { string }?)
	if not name then
		return nil
	end

	local item = self._repository:GetItemById(name)
	if not item then
		item = self._repository:GetItemByName(name)
	end
	if not item then
		return nil
	end

	if categories and #categories > 0 then
		local itemCategory = string.lower(item.category or "")
		for _, category in ipairs(categories) do
			if itemCategory == string.lower(category) then
				return item
			end
		end
	end

	return item
end

function NookipediaService:_cacheLookup(key: string, resolver: () -> { }?)
	local cached = self._cache[key]
	if cached ~= nil then
		if cached == false then
			return nil
		end
		return cached
	end

	local result = resolver()
	if not result then
		self._cache[key] = false
		return nil
	end

	self._cache[key] = result
	return result
end

function NookipediaService:GetVillagers(filters: { [string]: any }?)
	return self:_cacheLookup("villagers_" .. (filters and normalizeKey(filters.name or "") or "all"), function()
		local villagers = self._repository:GetVillagers(filters)
		local results = {}

		for _, villager in ipairs(villagers) do
			table.insert(results, {
				id = villager.id,
				name = villager.displayName or villager.id,
				personality = villager.personality or "Normal",
				species = villager.species or "Unknown",
				birthday = villager.birthday,
				phrase = villager.catchphrase or (villager.dialogue and villager.dialogue.catchphrases and villager.dialogue.catchphrases[1]),
				image_url = villager.nookipediaImageUrl,
				icon_url = villager.nookipediaIconUrl,
				source = shallowCopy(villager),
			})
		end

		Logger:Debug("NookipediaService", "Resolved villagers from local cache", { count = #results })
		return results
	end)
end

function NookipediaService:GetVillager(name: string?)
	if not name then
		return nil
	end

	local list = self:GetVillagers({ name = name })
	if list and #list > 0 then
		return list[1]
	end
	return nil
end

function NookipediaService:GetVillagersByPersonality(personality: string)
	return self:GetVillagers({ personality = personality })
end

function NookipediaService:GetVillagersBySpecies(species: string)
	return self:GetVillagers({ species = species })
end

function NookipediaService:_gatherItems(aliasKey: string)
	local categories = CATEGORY_ALIASES[aliasKey]
	if not categories then
		return {}
	end

	local collected = {}
	for _, category in ipairs(categories) do
		for _, item in ipairs(self._repository:GetItemsByCategory(category)) do
			table.insert(collected, item)
		end
	end
	return collected
end

function NookipediaService:GetFish(_month: string?)
	return self:_cacheLookup("fish_all", function()
		local items = self:_gatherItems("fish")
		local results = {}
		for _, item in ipairs(items) do
			table.insert(results, buildFishEntry(item))
		end
		return results
	end)
end

function NookipediaService:GetFishByName(name: string)
	local item = self:_resolveItem(name, CATEGORY_ALIASES.fish)
	if not item then
		return nil
	end

	return buildFishEntry(item)
end

function NookipediaService:GetCurrentMonthFish()
	return self:GetFish()
end

function NookipediaService:GetBugs(_month: string?)
	return self:_cacheLookup("bugs_all", function()
		local items = self:_gatherItems("bugs")
		local results = {}
		for _, item in ipairs(items) do
			table.insert(results, buildBugEntry(item))
		end
		return results
	end)
end

function NookipediaService:GetBugByName(name: string)
	local item = self:_resolveItem(name, CATEGORY_ALIASES.bugs)
	if not item then
		return nil
	end

	return buildBugEntry(item)
end

function NookipediaService:GetCurrentMonthBugs()
	return self:GetBugs()
end

function NookipediaService:GetSeaCreatures(_month: string?)
	return {}
end

function NookipediaService:GetSeaCreatureByName(_name: string)
	return nil
end

function NookipediaService:GetFurniture(filters: { [string]: any }?)
	return self:_cacheLookup("furniture_all", function()
		local items = self:_gatherItems("furniture")
		local results = {}
		for _, item in ipairs(items) do
			table.insert(results, buildFurnitureEntry(item))
		end
		return results
	end)
end

function NookipediaService:GetFurnitureByName(name: string)
	local item = self:_resolveItem(name, CATEGORY_ALIASES.furniture)
	if not item then
		return nil
	end

	return buildFurnitureEntry(item)
end

function NookipediaService:GetTools()
	return self:_cacheLookup("tools_all", function()
		local items = self:_gatherItems("tools")
		local results = {}
		for _, item in ipairs(items) do
			table.insert(results, buildToolEntry(item))
		end
		return results
	end)
end

function NookipediaService:GetToolByName(name: string)
	local item = self:_resolveItem(name, CATEGORY_ALIASES.tools)
	if not item then
		return nil
	end

	return buildToolEntry(item)
end

function NookipediaService:GetRecipes()
	return {}
end

function NookipediaService:GetRecipeByName(_name: string)
	return nil
end

function NookipediaService:GetEvents()
	return self:_cacheLookup("events_all", function()
		return {
			{
				name = "Bug-Off",
				season = "Summer",
				description = "Catch bugs for Flick and earn prizes.",
			},
			{
				name = "Fishing Tourney",
				season = "Spring",
				description = "Compete to catch the most fish for C.J.",
			},
		}
	end)
end

function NookipediaService:ClearCache()
	table.clear(self._cache)
	Logger:Info("NookipediaService", "Local cache cleared")
end

function NookipediaService:GetCacheStats()
	local entryCount = 0
	for _ in pairs(self._cache) do
		entryCount += 1
	end

	return {
		entries = entryCount,
		keys = table.concat((function()
			local keys = {}
			for key in pairs(self._cache) do
				table.insert(keys, key)
			end
			return keys
		end)(), ", "),
	}
end

return NookipediaService

