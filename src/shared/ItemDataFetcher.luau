-- ItemDataFetcher.luau
-- Fetches and processes item data from external APIs for crafting system

local HttpService = game:GetService("HttpService")

local ItemDataFetcher = {}

-- Configuration for different data sources
local DATA_SOURCES = {
	-- Google Sheets API
	GOOGLE_SHEETS = {
		baseUrl = "https://sheets.googleapis.com/v4/spreadsheets",
		apiKey = "", -- Set your API key here
		spreadsheetId = "", -- Set your spreadsheet ID here
		sheetName = "Items" -- Name of the sheet containing item data
	},
	
	-- Custom API endpoints
	CUSTOM_API = {
		baseUrl = "https://your-api.com/api",
		endpoints = {
			items = "/items",
			recipes = "/recipes",
			materials = "/materials"
		}
	},
	
	-- Fallback local data
	LOCAL_DATA = {
		enabled = true,
		fallbackFile = "ItemDataFallback.json"
	}
}

-- Item data structure for crafting
local ItemDataStructure = {
	-- Basic item info
	id = "", -- Unique identifier
	name = "", -- Display name
	description = "", -- Item description
	category = "", -- Item category (tools, materials, furniture, etc.)
	rarity = "", -- Common, uncommon, rare, epic, legendary
	
	-- Visual properties
	spriteIndex = 0, -- Index in sprite sheet
	color = Color3.new(1, 1, 1), -- Item color
	
	-- Gameplay properties
	stackSize = 1, -- Maximum stack size
	sellPrice = 0, -- Base sell price
	buyPrice = 0, -- Base buy price
	
	-- Crafting properties
	craftable = false, -- Can this item be crafted?
	craftingMaterials = {}, -- Required materials for crafting
	craftingStation = "", -- Required crafting station
	craftingTime = 0, -- Time to craft in seconds
	
	-- Usage properties
	usable = false, -- Can this item be used?
	useEffect = "", -- Effect when used
	durability = 0, -- Item durability (0 = infinite)
	
	-- Seasonal properties
	season = "", -- Spring, Summer, Fall, Winter
	month = 0, -- Specific month (1-12)
	timeOfDay = "", -- Morning, Afternoon, Evening, Night
	weather = "", -- Sunny, Rainy, Snowy, etc.
}

-- Fetch data from Google Sheets
local function fetchFromGoogleSheets()
	local config = DATA_SOURCES.GOOGLE_SHEETS
	
	if not config.apiKey or not config.spreadsheetId then
		warn("[ItemDataFetcher] Google Sheets API not configured")
		return nil
	end
	
	local url = string.format("%s/%s/values/%s?key=%s", 
		config.baseUrl, 
		config.spreadsheetId, 
		config.sheetName, 
		config.apiKey
	)
	
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)
	
	if success then
		local data = HttpService:JSONDecode(response)
		return data.values -- Google Sheets returns data in values array
	else
		warn("[ItemDataFetcher] Failed to fetch from Google Sheets:", response)
		return nil
	end
end

-- Fetch data from custom API
local function fetchFromCustomAPI()
	local config = DATA_SOURCES.CUSTOM_API
	
	-- Fetch items
	local itemsUrl = config.baseUrl .. config.endpoints.items
	local success, response = pcall(function()
		return HttpService:GetAsync(itemsUrl)
	end)
	
	if success then
		local itemsData = HttpService:JSONDecode(response)
		
		-- Fetch recipes
		local recipesUrl = config.baseUrl .. config.endpoints.recipes
		local recipesSuccess, recipesResponse = pcall(function()
			return HttpService:GetAsync(recipesUrl)
		end)
		
		if recipesSuccess then
			local recipesData = HttpService:JSONDecode(recipesResponse)
			return {
				items = itemsData,
				recipes = recipesData
			}
		end
		
		return { items = itemsData }
	else
		warn("[ItemDataFetcher] Failed to fetch from custom API:", response)
		return nil
	end
end

-- Parse CSV data into structured format
local function parseCSVData(csvData)
	local items = {}
	local headers = csvData[1] -- First row contains headers
	
	for i = 2, #csvData do
		local row = csvData[i]
		local item = {}
		
		for j = 1, #headers do
			local header = headers[j]:lower():gsub(" ", "_")
			local value = row[j] or ""
			
			-- Convert string values to appropriate types
			if header == "sprite_index" or header == "stack_size" or header == "sell_price" or header == "buy_price" or header == "crafting_time" or header == "durability" or header == "month" then
				item[header] = tonumber(value) or 0
			elseif header == "craftable" or header == "usable" then
				item[header] = value:lower() == "true" or value:lower() == "yes"
			elseif header == "color" then
				-- Parse color from hex or RGB
				if value:match("^#") then
					item[header] = Color3.fromHex(value)
				else
					item[header] = Color3.new(1, 1, 1) -- Default white
				end
			elseif header == "crafting_materials" then
				-- Parse materials from comma-separated string
				item[header] = {}
				if value ~= "" then
					for material in value:gmatch("([^,]+)") do
						table.insert(item[header], material:match("^%s*(.-)%s*$")) -- Trim whitespace
					end
				end
			else
				item[header] = value
			end
		end
		
		table.insert(items, item)
	end
	
	return items
end

-- Main function to fetch and process item data
function ItemDataFetcher.fetchItemData()
	print("[ItemDataFetcher] 🚀 Fetching item data...")
	
	-- Try Google Sheets first
	local data = fetchFromGoogleSheets()
	if data then
		print("[ItemDataFetcher] ✅ Successfully fetched from Google Sheets")
		return parseCSVData(data)
	end
	
	-- Try custom API
	data = fetchFromCustomAPI()
	if data then
		print("[ItemDataFetcher] ✅ Successfully fetched from custom API")
		return data
	end
	
	-- Fallback to local data
	if DATA_SOURCES.LOCAL_DATA.enabled then
		print("[ItemDataFetcher] ⚠️ Using fallback local data")
		return ItemDataFetcher.getFallbackData()
	end
	
	warn("[ItemDataFetcher] ❌ Failed to fetch item data from any source")
	return nil
end

-- Fallback data for when APIs are unavailable
function ItemDataFetcher.getFallbackData()
	return {
		-- Basic tools
		{
			id = "shovel",
			name = "Shovel",
			description = "A basic shovel for digging",
			category = "tools",
			rarity = "common",
			spriteIndex = 2,
			stackSize = 1,
			sellPrice = 100,
			craftable = true,
			craftingMaterials = {"wood", "iron_nugget"},
			craftingStation = "workbench",
			craftingTime = 30,
			usable = true,
			durability = 100
		},
		
		-- Basic materials
		{
			id = "wood",
			name = "Wood",
			description = "Basic wood material",
			category = "materials",
			rarity = "common",
			spriteIndex = 1,
			stackSize = 30,
			sellPrice = 10,
			craftable = false,
			usable = false
		},
		
		{
			id = "iron_nugget",
			name = "Iron Nugget",
			description = "A nugget of iron",
			category = "materials",
			rarity = "uncommon",
			spriteIndex = 3,
			stackSize = 30,
			sellPrice = 25,
			craftable = false,
			usable = false
		}
	}
end

-- Get crafting recipes for a specific item
function ItemDataFetcher.getCraftingRecipe(itemId)
	local itemData = ItemDataFetcher.fetchItemData()
	if not itemData then return nil end
	
	for _, item in ipairs(itemData) do
		if item.id == itemId and item.craftable then
			return {
				materials = item.craftingMaterials,
				station = item.craftingStation,
				time = item.craftingTime
			}
		end
	end
	
	return nil
end

-- Get all craftable items
function ItemDataFetcher.getCraftableItems()
	local itemData = ItemDataFetcher.fetchItemData()
	if not itemData then return {} end
	
	local craftableItems = {}
	for _, item in ipairs(itemData) do
		if item.craftable then
			table.insert(craftableItems, item)
		end
	end
	
	return craftableItems
end

-- Search items by category
function ItemDataFetcher.getItemsByCategory(category)
	local itemData = ItemDataFetcher.fetchItemData()
	if not itemData then return {} end
	
	local categoryItems = {}
	for _, item in ipairs(itemData) do
		if item.category == category then
			table.insert(categoryItems, item)
		end
	end
	
	return categoryItems
end

-- Update configuration
function ItemDataFetcher.updateConfig(source, key, value)
	if DATA_SOURCES[source] and DATA_SOURCES[source][key] ~= nil then
		DATA_SOURCES[source][key] = value
		print("[ItemDataFetcher] Updated", source, key, "to", value)
	else
		warn("[ItemDataFetcher] Invalid config update:", source, key)
	end
end

return ItemDataFetcher
