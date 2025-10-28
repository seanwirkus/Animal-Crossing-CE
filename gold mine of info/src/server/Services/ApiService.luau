local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Logger)
local LocalContentRepository = require(script.Parent.LocalContentRepository)

local ApiService = {}
ApiService.__index = ApiService

local LOCAL_SONGS = {
	kk_cruisin = {
		id = "kk_cruisin",
		name = "K.K. Cruisin'",
		composer = "K.K. Slider",
		genre = "Soul",
		price = 3200,
		lengthSeconds = 191,
		image_url = nil,
		icon_url = nil,
	},
	kk_rally = {
		id = "kk_rally",
		name = "K.K. Rally",
		composer = "K.K. Slider",
		genre = "March",
		price = 3200,
		lengthSeconds = 178,
		image_url = nil,
		icon_url = nil,
	},
}

local function shallowCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end

	local result = {}
	for key, item in pairs(value :: any) do
		result[key] = item
	end

	return result :: any
end

local function normalizeKey(value: string?): string
	if not value or value == "" then
		return ""
	end

	local lowered = string.lower(value)
	return lowered:gsub("[^%w]+", "_")
end

local function resolvePrice(itemData: {}): number?
	return itemData.baseValue or itemData.sellValue or itemData.price
end

local function resolveLocation(itemData: {}, defaultLocation: string): string
	return itemData.location or itemData.spawnLocation or defaultLocation
end

function ApiService.new()
	local self = setmetatable({}, ApiService)
	self._repository = LocalContentRepository.new()
	self._cache = {}
	return self
end

function ApiService:_cacheLookup(cacheKey: string, resolver: () -> {}?)
	local cached = self._cache[cacheKey]
	if cached ~= nil then
		if cached == false then
			return nil
		end
		return shallowCopy(cached)
	end

	local resolved = resolver()
	if resolved == nil then
		self._cache[cacheKey] = false
		return nil
	end

	local stored = shallowCopy(resolved)
	self._cache[cacheKey] = stored
	return shallowCopy(stored)
end

function ApiService:_resolveItem(rawName: string?, categories: { string }?)
	if not rawName or rawName == "" then
		return nil
	end

	local item = self._repository:GetItemById(rawName)
	if not item then
		item = self._repository:GetItemByName(rawName)
	end
	if not item then
		return nil
	end

	if not categories or #categories == 0 then
		return item
	end

	local target = string.lower(item.category or "")
	for _, category in ipairs(categories) do
		if target == string.lower(category) then
			return item
		end
	end

	return item
end

function ApiService:GetVillagerInfo(name: string?)
	local cacheKey = "villager_" .. (string.lower(name or "unknown"))
	return self:_cacheLookup(cacheKey, function()
		local villager = self._repository:GetVillagerByName(name or "")
		if villager then
			Logger:Debug("ApiService", "Resolved villager from local data", { name = villager.displayName or villager.id })
			return {
				name = villager.displayName or villager.id,
				personality = villager.personality,
				species = villager.species,
				birthday = villager.birthday,
				image_url = villager.nookipediaImageUrl,
				icon_url = villager.nookipediaIconUrl,
				phrase = villager.catchphrase or (villager.dialogue and villager.dialogue.catchphrases and villager.dialogue.catchphrases[1]),
			}
		end

		Logger:Debug("ApiService", "Fallback villager info used", { name = name })
		return {
			name = name or "Unknown",
			personality = "Normal",
			species = "Villager",
			birthday = "1-1",
			image_url = nil,
			icon_url = nil,
			phrase = "Howdy!",
		}
	end)
end

function ApiService:GetFishInfo(name: string?)
	local cacheKey = "fish_" .. (string.lower(name or "unknown"))
	return self:_cacheLookup(cacheKey, function()
		local item = self:_resolveItem(name, { "Fish" })
		if not item then
			return nil
		end

		return {
			id = item.id,
			name = item.name or item.id,
			price = resolvePrice(item),
			location = resolveLocation(item, "Sea"),
			shadow = item.shadow or item.shadowSize or "Medium",
			rarity = item.rarity or "Common",
			image_url = item.imageUrl or item.image_url,
			icon_url = item.iconUrl or item.icon_url,
		}
	end)
end

function ApiService:GetBugInfo(name: string?)
	local cacheKey = "bug_" .. (string.lower(name or "unknown"))
	return self:_cacheLookup(cacheKey, function()
		local item = self:_resolveItem(name, { "Bug" })
		if not item then
			return nil
		end

		return {
			id = item.id,
			name = item.name or item.id,
			price = resolvePrice(item),
			location = resolveLocation(item, "Ground"),
			rarity = item.rarity or "Common",
			image_url = item.imageUrl or item.image_url,
			icon_url = item.iconUrl or item.icon_url,
		}
	end)
end

function ApiService:GetSongInfo(songName: string?)
	if not songName then
		return nil
	end

	local key = normalizeKey(songName)
	local song = LOCAL_SONGS[key]
	if not song then
		return nil
	end

	return shallowCopy(song)
end

function ApiService:GetAllSongs()
	local results = {}
	for _, data in pairs(LOCAL_SONGS) do
		table.insert(results, shallowCopy(data))
	end
	return results
end

function ApiService:GetItemInfo(itemName: string?)
	if not itemName then
		return nil
	end

	local item = self:_resolveItem(itemName)
	if not item then
		return nil
	end

	return shallowCopy(item)
end

function ApiService:GetFurnitureInfo(furnitureName: string?)
	if not furnitureName then
		return nil
	end

	local item = self:_resolveItem(furnitureName, { "Furniture", "Housewares", "WallMounted", "Misc" })
	if not item then
		return nil
	end

	return shallowCopy(item)
end

function ApiService:EnrichVillagerData(villagerData: {})
	if not villagerData then
		return nil
	end

	local info = self:GetVillagerInfo(villagerData.displayName or villagerData.id)
	if not info then
		return villagerData
	end

	villagerData.species = info.species or villagerData.species
	villagerData.personality = info.personality or villagerData.personality
	villagerData.birthday = info.birthday or villagerData.birthday
	villagerData.catchphrase = info.phrase or villagerData.catchphrase
	villagerData.nookipediaImageUrl = info.image_url or villagerData.nookipediaImageUrl
	villagerData.nookipediaIconUrl = info.icon_url or villagerData.nookipediaIconUrl

	return villagerData
end

function ApiService:EnrichFishData(fishData: {})
	if not fishData then
		return nil
	end

	local info = self:GetFishInfo(fishData.name or fishData.id)
	if not info then
		return fishData
	end

	fishData.price = info.price or fishData.price
	fishData.location = info.location or fishData.location
	fishData.shadow = info.shadow or fishData.shadow
	fishData.rarity = info.rarity or fishData.rarity
	fishData.imageUrl = info.image_url or fishData.imageUrl
	fishData.iconUrl = info.icon_url or fishData.iconUrl

	return fishData
end

function ApiService:EnrichBugData(bugData: {})
	if not bugData then
		return nil
	end

	local info = self:GetBugInfo(bugData.name or bugData.id)
	if not info then
		return bugData
	end

	bugData.price = info.price or bugData.price
	bugData.location = info.location or bugData.location
	bugData.rarity = info.rarity or bugData.rarity
	bugData.imageUrl = info.image_url or bugData.imageUrl
	bugData.iconUrl = info.icon_url or bugData.iconUrl

	return bugData
end

return ApiService
