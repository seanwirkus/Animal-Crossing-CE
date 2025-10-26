-- SpreadsheetIntegration.luau
-- Example of how to integrate with Google Sheets for item data

local HttpService = game:GetService("HttpService")

local SpreadsheetIntegration = {}

-- Example Google Sheets configuration
local SHEETS_CONFIG = {
	-- Your Google Sheets API key (get from Google Cloud Console)
	API_KEY = "YOUR_API_KEY_HERE",
	
	-- Your spreadsheet ID (from the URL)
	SPREADSHEET_ID = "YOUR_SPREADSHEET_ID_HERE",
	
	-- Sheet names containing different data
	SHEETS = {
		ITEMS = "Items",
		RECIPES = "Recipes", 
		MATERIALS = "Materials",
		CATEGORIES = "Categories"
	}
}

-- Sample spreadsheet structure for Items sheet:
-- | id | name | description | category | rarity | sprite_index | stack_size | sell_price | buy_price | craftable | crafting_materials | crafting_station | crafting_time | usable | durability | season | month | time_of_day | weather |
-- | shovel | Shovel | A basic shovel for digging | tools | common | 2 | 1 | 100 | 150 | true | wood,iron_nugget | workbench | 30 | true | 100 | spring | 3 | morning | sunny |
-- | net | Net | A bug catching net | tools | common | 3 | 1 | 120 | 180 | true | wood,string | workbench | 25 | true | 80 | spring | 4 | afternoon | sunny |
-- | wood | Wood | Basic wood material | materials | common | 1 | 30 | 10 | 15 | false | | | 0 | false | 0 | all | 0 | all | all |

-- Fetch data from Google Sheets
function SpreadsheetIntegration.fetchSheetData(sheetName)
	local url = string.format(
		"https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?key=%s",
		SHEETS_CONFIG.SPREADSHEET_ID,
		sheetName,
		SHEETS_CONFIG.API_KEY
	)
	
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)
	
	if success then
		local data = HttpService:JSONDecode(response)
		return data.values
	else
		warn("[SpreadsheetIntegration] Failed to fetch", sheetName, ":", response)
		return nil
	end
end

-- Parse items data from spreadsheet
function SpreadsheetIntegration.parseItemsData()
	local rawData = SpreadsheetIntegration.fetchSheetData(SHEETS_CONFIG.SHEETS.ITEMS)
	if not rawData then return nil end
	
	local items = {}
	local headers = rawData[1] -- First row contains headers
	
	-- Convert headers to lowercase with underscores
	for i, header in ipairs(headers) do
		headers[i] = header:lower():gsub(" ", "_")
	end
	
	-- Parse each row
	for rowIndex = 2, #rawData do
		local row = rawData[rowIndex]
		local item = {}
		
		for colIndex = 1, #headers do
			local header = headers[colIndex]
			local value = row[colIndex] or ""
			
			-- Convert values based on header type
			if header == "sprite_index" or header == "stack_size" or header == "sell_price" or header == "buy_price" or header == "crafting_time" or header == "durability" or header == "month" then
				item[header] = tonumber(value) or 0
			elseif header == "craftable" or header == "usable" then
				item[header] = value:lower() == "true" or value:lower() == "yes"
			elseif header == "crafting_materials" then
				-- Parse comma-separated materials
				item[header] = {}
				if value ~= "" then
					for material in value:gmatch("([^,]+)") do
						table.insert(item[header], material:match("^%s*(.-)%s*$"))
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

-- Parse recipes data from spreadsheet
function SpreadsheetIntegration.parseRecipesData()
	local rawData = SpreadsheetIntegration.fetchSheetData(SHEETS_CONFIG.SHEETS.RECIPES)
	if not rawData then return nil end
	
	local recipes = {}
	local headers = rawData[1]
	
	for i, header in ipairs(headers) do
		headers[i] = header:lower():gsub(" ", "_")
	end
	
	for rowIndex = 2, #rawData do
		local row = rawData[rowIndex]
		local recipe = {}
		
		for colIndex = 1, #headers do
			local header = headers[colIndex]
			local value = row[colIndex] or ""
			
			if header == "quantity" or header == "crafting_time" then
				recipe[header] = tonumber(value) or 1
			elseif header == "materials" then
				-- Parse materials with quantities (format: "wood:5,iron:2")
				recipe[header] = {}
				if value ~= "" then
					for materialData in value:gmatch("([^,]+)") do
						local material, quantity = materialData:match("([^:]+):?(%d*)")
						table.insert(recipe[header], {
							id = material:match("^%s*(.-)%s*$"),
							quantity = tonumber(quantity) or 1
						})
					end
				end
			else
				recipe[header] = value
			end
		end
		
		table.insert(recipes, recipe)
	end
	
	return recipes
end

-- Get all data from spreadsheet
function SpreadsheetIntegration.getAllData()
	print("[SpreadsheetIntegration] 📊 Fetching all data from spreadsheet...")
	
	local data = {
		items = SpreadsheetIntegration.parseItemsData(),
		recipes = SpreadsheetIntegration.parseRecipesData(),
		materials = SpreadsheetIntegration.fetchSheetData(SHEETS_CONFIG.SHEETS.MATERIALS),
		categories = SpreadsheetIntegration.fetchSheetData(SHEETS_CONFIG.SHEETS.CATEGORIES)
	}
	
	-- Log results
	if data.items then
		print("[SpreadsheetIntegration] ✅ Fetched", #data.items, "items")
	end
	if data.recipes then
		print("[SpreadsheetIntegration] ✅ Fetched", #data.recipes, "recipes")
	end
	
	return data
end

-- Update configuration
function SpreadsheetIntegration.updateConfig(apiKey, spreadsheetId)
	SHEETS_CONFIG.API_KEY = apiKey
	SHEETS_CONFIG.SPREADSHEET_ID = spreadsheetId
	print("[SpreadsheetIntegration] Updated configuration")
end

-- Test connection to spreadsheet
function SpreadsheetIntegration.testConnection()
	print("[SpreadsheetIntegration] 🔍 Testing connection to spreadsheet...")
	
	local testData = SpreadsheetIntegration.fetchSheetData(SHEETS_CONFIG.SHEETS.ITEMS)
	if testData then
		print("[SpreadsheetIntegration] ✅ Connection successful!")
		print("[SpreadsheetIntegration] Found", #testData - 1, "data rows")
		return true
	else
		print("[SpreadsheetIntegration] ❌ Connection failed!")
		return false
	end
end

return SpreadsheetIntegration
