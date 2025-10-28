-- Item Database - Manages all 7,025+ New Horizons items from Nookipedia
-- Loads from pre-fetched JSON file (no HTTP requests needed at runtime)
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local EmojiMap = require(ReplicatedStorage:WaitForChild("EmojiMap"))

-- Fallback emoji function (if EmojiMap not found)
local function getEmoji(itemName, category, itemType)
	local emojiMap = {
		furniture = "🪑",
		clothing = "👕",
		tools = "🔨",
		interior = "🏠",
		fish = "🐠",
		bugs = "🦋",
		sea_creatures = "🐙",
		fossils = "🦴",
		art = "🖼️",
		items = "📦",
		recipes = "📋",
		photos = "📷",
		gyroids = "🔊",
	}
	return emojiMap[category] or "📦"
end

local ItemDatabase = {}
ItemDatabase.__index = ItemDatabase

function ItemDatabase.new()
	local self = setmetatable({}, ItemDatabase)
	self._items = {
		furniture = {},
		clothing = {},
		tools = {},
		interior = {},
		fish = {},
		bugs = {},
		sea_creatures = {},
		fossils = {},
		art = {},
		items = {}, -- Misc items (materials, fruits, etc.)
		recipes = {},
		photos = {},
		gyroids = {},
	}
	self._itemsByName = {} -- Quick lookup by name
	self._loaded = false
	return self
end

function ItemDatabase:LoadFromJSON(jsonString)
	if type(jsonString) ~= "string" then
		warn("[ItemDatabase] Invalid JSON string provided")
		return false
	end
	
	local success, itemData = pcall(function()
		return HttpService:JSONDecode(jsonString)
	end)
	
	if not success or type(itemData) ~= "table" then
		warn("[ItemDatabase] Failed to parse item JSON")
		return false
	end
	
	-- Load each category
	local totalCount = 0
	for category, items in pairs(itemData) do
		if type(items) == "table" then
			self._items[category] = items
			
			-- Index by name for quick lookup
			for _, item in ipairs(items) do
				local itemName = item.name
				if itemName then
					self._itemsByName[itemName] = {
						data = item,
						category = category
					}
					totalCount = totalCount + 1
				end
			end
		end
	end
	
	self._loaded = true
	print(string.format("[ItemDatabase] ✅ Loaded %d items from JSON", totalCount))
	return true
end

-- Get item by name
function ItemDatabase:GetItem(itemName)
	if not itemName then return nil end
	local entry = self._itemsByName[itemName]
	if entry then
		return entry.data, entry.category
	end
	return nil, nil
end

-- Get all items in a category
function ItemDatabase:GetItemsByCategory(category)
	return self._items[category] or {}
end

-- Get item count
function ItemDatabase:GetItemCount()
	local count = 0
	for name, _ in pairs(self._itemsByName) do
		count = count + 1
	end
	return count
end

-- Get item with emoji
function ItemDatabase:GetItemWithEmoji(itemName)
	local item, category = self:GetItem(itemName)
	if not item then return nil end
	
	local emoji = getEmoji(itemName, category, item.type or item.category)
	
	return {
		name = item.name,
		category = category,
		emoji = emoji,
		sell_price = item.sell or item.sell_price or 0,
		buy_price = item.buy or item.buy_price or 0,
		description = item.description or "",
		size = item.size or "1x1",
		variants = item.variations or item.variation or {},
		diy = item.diy ~= nil,
		raw = item
	}
end

-- Search items by name
function ItemDatabase:SearchItems(query, maxResults)
	if not query or query == "" then return {} end
	
	local results = {}
	local lowerQuery = string.lower(query)
	local count = 0
	local limit = maxResults or 20
	
	for name, entry in pairs(self._itemsByName) do
		if string.find(string.lower(name), lowerQuery) then
			table.insert(results, {
				name = name,
				category = entry.category,
				emoji = getEmoji(name, entry.category)
			})
			count = count + 1
			if count >= limit then
				break
			end
		end
	end
	
	return results
end

-- Get all craftable recipes
function ItemDatabase:GetCraftableRecipes()
	return self._items.recipes or {}
end

-- Get recipe for an item
function ItemDatabase:GetRecipe(itemName)
	local recipes = self._items.recipes
	if not recipes then return nil end
	
	for _, recipe in ipairs(recipes) do
		if recipe.name == itemName or recipe.result == itemName then
			return recipe
		end
	end
	
	return nil
end

-- Get items by tag/filter
function ItemDatabase:GetItemsByFilter(filterFunc)
	local results = {}
	
	for name, entry in pairs(self._itemsByName) do
		if filterFunc(entry.data, entry.category) then
			table.insert(results, {
				name = name,
				category = entry.category,
				data = entry.data
			})
		end
	end
	
	return results
end

-- Get sellable items only
function ItemDatabase:GetSellableItems()
	return self:GetItemsByFilter(function(item, category)
		local price = item.sell or item.sell_price
		return price and price > 0
	end)
end

-- Get DIY-craftable items only
function ItemDatabase:GetDIYItems()
	return self:GetItemsByFilter(function(item, category)
		return item.diy == true or item.recipe ~= nil
	end)
end

-- Check if item exists
function ItemDatabase:HasItem(itemName)
	return self._itemsByName[itemName] ~= nil
end

-- Get random item from category
function ItemDatabase:GetRandomItem(category)
	local items = self:GetItemsByCategory(category)
	if #items == 0 then return nil end
	
	local randomItem = items[math.random(#items)]
	return self:GetItemWithEmoji(randomItem.name)
end

-- Get category stats
function ItemDatabase:GetCategoryStats()
	local stats = {}
	for category, items in pairs(self._items) do
		stats[category] = {
			count = type(items) == "table" and #items or 0,
			emoji = getEmoji(nil, category) -- Assuming category emoji is the same as category emoji
		}
	end
	return stats
end

-- Get all categories
function ItemDatabase:GetCategories()
	local categories = {}
	for category, _ in pairs(self._items) do
		table.insert(categories, category)
	end
	return categories
end

function ItemDatabase:IsLoaded()
	return self._loaded
end

return ItemDatabase

