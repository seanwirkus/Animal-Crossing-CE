-- CraftingSetup.luau
-- Server script to set up the crafting system with external data

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import our modules
local ItemDataFetcher = require(script.Parent.ItemDataFetcher)
local CraftingSystem = require(script.Parent.CraftingSystem)
local SpreadsheetIntegration = require(script.Parent.SpreadsheetIntegration)

print("[CraftingSetup] 🚀 Setting up crafting system...")

-- Configuration
local CONFIG = {
	-- Set to true to use Google Sheets, false to use fallback data
	USE_EXTERNAL_DATA = false,
	
	-- Google Sheets configuration (set these if using external data)
	GOOGLE_SHEETS_API_KEY = "YOUR_API_KEY_HERE",
	GOOGLE_SHEETS_ID = "YOUR_SPREADSHEET_ID_HERE",
	
	-- Enable debug logging
	DEBUG_MODE = true
}

-- Initialize the crafting system
local function initializeCraftingSystem()
	print("[CraftingSetup] 📊 Initializing crafting system...")
	
	-- Initialize crafting system
	CraftingSystem.initialize()
	
	-- Test external data connection if enabled
	if CONFIG.USE_EXTERNAL_DATA then
		print("[CraftingSetup] 🔗 Testing external data connection...")
		
		-- Update spreadsheet configuration
		SpreadsheetIntegration.updateConfig(CONFIG.GOOGLE_SHEETS_API_KEY, CONFIG.GOOGLE_SHEETS_ID)
		
		-- Test connection
		local connectionSuccess = SpreadsheetIntegration.testConnection()
		if connectionSuccess then
			print("[CraftingSetup] ✅ External data connection successful!")
			
			-- Fetch and cache data
			local externalData = SpreadsheetIntegration.getAllData()
			if externalData then
				print("[CraftingSetup] 📦 Cached external data successfully")
				-- Store data in ReplicatedStorage for client access
				local dataFolder = ReplicatedStorage:FindFirstChild("ItemData") or Instance.new("Folder")
				dataFolder.Name = "ItemData"
				dataFolder.Parent = ReplicatedStorage
				
				-- Store items data
				if externalData.items then
					local itemsStringValue = Instance.new("StringValue")
					itemsStringValue.Name = "Items"
					itemsStringValue.Value = game:GetService("HttpService"):JSONEncode(externalData.items)
					itemsStringValue.Parent = dataFolder
				end
				
				-- Store recipes data
				if externalData.recipes then
					local recipesStringValue = Instance.new("StringValue")
					recipesStringValue.Name = "Recipes"
					recipesStringValue.Value = game:GetService("HttpService"):JSONEncode(externalData.recipes)
					recipesStringValue.Parent = dataFolder
				end
			end
		else
			print("[CraftingSetup] ⚠️ External data connection failed, using fallback data")
			CONFIG.USE_EXTERNAL_DATA = false
		end
	end
	
	-- Use fallback data if external data is disabled or failed
	if not CONFIG.USE_EXTERNAL_DATA then
		print("[CraftingSetup] 📋 Using fallback item data...")
		local fallbackData = ItemDataFetcher.getFallbackData()
		
		-- Store fallback data
		local dataFolder = ReplicatedStorage:FindFirstChild("ItemData") or Instance.new("Folder")
		dataFolder.Name = "ItemData"
		dataFolder.Parent = ReplicatedStorage
		
		local itemsStringValue = Instance.new("StringValue")
		itemsStringValue.Name = "Items"
		itemsStringValue.Value = game:GetService("HttpService"):JSONEncode(fallbackData)
		itemsStringValue.Parent = dataFolder
	end
	
	print("[CraftingSetup] ✅ Crafting system initialized successfully!")
end

-- Set up RemoteEvents for crafting
local function setupCraftingRemoteEvents()
	print("[CraftingSetup] 🔗 Setting up crafting RemoteEvents...")
	
	-- Create RemoteEvents
	local craftingRemote = ReplicatedStorage:FindFirstChild("CraftingEvent") or Instance.new("RemoteEvent")
	craftingRemote.Name = "CraftingEvent"
	craftingRemote.Parent = ReplicatedStorage
	
	-- Handle crafting requests
	craftingRemote.OnServerEvent:Connect(function(player, action, data)
		if CONFIG.DEBUG_MODE then
			print("[CraftingSetup] Received", action, "from", player.Name)
		end
		
		if action == "StartCrafting" then
			local itemId = data.itemId
			local quantity = data.quantity or 1
			
			local success = CraftingSystem.startCrafting(player, itemId, quantity)
			craftingRemote:FireClient(player, "CraftingStarted", {
				success = success,
				itemId = itemId,
				quantity = quantity
			})
			
		elseif action == "GetCraftingProgress" then
			local progress = CraftingSystem.getCraftingProgress(player)
			craftingRemote:FireClient(player, "CraftingProgress", progress)
			
		elseif action == "GetAvailableRecipes" then
			local recipes = CraftingSystem.getAvailableRecipes(player)
			craftingRemote:FireClient(player, "AvailableRecipes", recipes)
			
		elseif action == "UnlockStation" then
			local stationType = data.stationType
			local success = CraftingSystem.unlockStation(player, stationType)
			craftingRemote:FireClient(player, "StationUnlocked", {
				success = success,
				stationType = stationType
			})
		end
	end)
	
	print("[CraftingSetup] ✅ Crafting RemoteEvents set up")
end

-- Initialize everything
initializeCraftingSystem()
setupCraftingRemoteEvents()

-- Set up player events
Players.PlayerAdded:Connect(function(player)
	print("[CraftingSetup] Player", player.Name, "joined - crafting system ready")
end)

Players.PlayerRemoving:Connect(function(player)
	print("[CraftingSetup] Player", player.Name, "left")
end)

print("[CraftingSetup] 🎉 Crafting system setup complete!")
print("[CraftingSetup] 📋 To use Google Sheets:")
print("[CraftingSetup] 1. Set USE_EXTERNAL_DATA = true")
print("[CraftingSetup] 2. Set your GOOGLE_SHEETS_API_KEY")
print("[CraftingSetup] 3. Set your GOOGLE_SHEETS_ID")
print("[CraftingSetup] 4. Use the sample_items.csv format for your spreadsheet")
