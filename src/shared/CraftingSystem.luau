
-- CraftingSystem.luau
-- Handles crafting logic using external item data

local ItemDataFetcher = require(script.Parent.ItemDataFetcher)

local CraftingSystem = {}

-- Player crafting stations
local playerCraftingStations = {}

-- Crafting station types
local CRAFTING_STATIONS = {
	WORKBENCH = "workbench",
	FORGE = "forge",
	COOKING = "cooking",
	SEWING = "sewing",
	ALCHEMY = "alchemy"
}

-- Initialize player crafting data
local function initializePlayerCrafting(player)
	playerCraftingStations[player.UserId] = {
		unlockedStations = {CRAFTING_STATIONS.WORKBENCH}, -- Start with workbench
		activeCrafts = {}, -- Currently crafting items
		craftingQueue = {} -- Queue of items to craft
	}
	
	print("[CraftingSystem] Initialized crafting for", player.Name)
end

-- Check if player has required materials
local function hasRequiredMaterials(player, materials)
	local inventory = game.ReplicatedStorage:FindFirstChild("InventoryEvent")
	if not inventory then return false end
	
	-- This would need to be implemented with actual inventory checking
	-- For now, return true as placeholder
	return true
end

-- Check if player has required crafting station
local function hasCraftingStation(player, stationType)
	local playerData = playerCraftingStations[player.UserId]
	if not playerData then return false end
	
	for _, station in ipairs(playerData.unlockedStations) do
		if station == stationType then
			return true
		end
	end
	
	return false
end

-- Start crafting an item
function CraftingSystem.startCrafting(player, itemId, quantity)
	local recipe = ItemDataFetcher.getCraftingRecipe(itemId)
	if not recipe then
		warn("[CraftingSystem] No recipe found for", itemId)
		return false
	end
	
	-- Check if player has required station
	if not hasCraftingStation(player, recipe.station) then
		warn("[CraftingSystem] Player", player.Name, "doesn't have", recipe.station)
		return false
	end
	
	-- Check if player has required materials
	if not hasRequiredMaterials(player, recipe.materials) then
		warn("[CraftingSystem] Player", player.Name, "doesn't have required materials")
		return false
	end
	
	local playerData = playerCraftingStations[player.UserId]
	if not playerData then
		initializePlayerCrafting(player)
		playerData = playerCraftingStations[player.UserId]
	end
	
	-- Add to crafting queue
	for i = 1, quantity do
		table.insert(playerData.craftingQueue, {
			itemId = itemId,
			startTime = tick(),
			craftingTime = recipe.time,
			completed = false
		})
	end
	
	print("[CraftingSystem] Started crafting", quantity, "x", itemId, "for", player.Name)
	return true
end

-- Process crafting queue
function CraftingSystem.processCraftingQueue(player)
	local playerData = playerCraftingStations[player.UserId]
	if not playerData then return end
	
	local completedItems = {}
	
	-- Check each item in queue
	for i = #playerData.craftingQueue, 1, -1 do
		local craft = playerData.craftingQueue[i]
		local elapsedTime = tick() - craft.startTime
		
		if elapsedTime >= craft.craftingTime and not craft.completed then
			-- Crafting completed
			craft.completed = true
			table.insert(completedItems, craft.itemId)
			table.remove(playerData.craftingQueue, i)
			
			print("[CraftingSystem] Completed crafting", craft.itemId, "for", player.Name)
		end
	end
	
	-- Give completed items to player
	if #completedItems > 0 then
		CraftingSystem.giveItemsToPlayer(player, completedItems)
	end
end

-- Give items to player (placeholder - would integrate with inventory system)
function CraftingSystem.giveItemsToPlayer(player, items)
	-- This would integrate with your existing inventory system
	-- For now, just log the items
	for _, itemId in ipairs(items) do
		print("[CraftingSystem] Giving", itemId, "to", player.Name)
	end
end

-- Get player's crafting progress
function CraftingSystem.getCraftingProgress(player)
	local playerData = playerCraftingStations[player.UserId]
	if not playerData then return {} end
	
	local progress = {}
	for _, craft in ipairs(playerData.craftingQueue) do
		local elapsedTime = tick() - craft.startTime
		local progressPercent = math.min(elapsedTime / craft.craftingTime, 1)
		
		table.insert(progress, {
			itemId = craft.itemId,
			progress = progressPercent,
			timeRemaining = math.max(craft.craftingTime - elapsedTime, 0),
			completed = craft.completed
		})
	end
	
	return progress
end

-- Unlock crafting station for player
function CraftingSystem.unlockStation(player, stationType)
	local playerData = playerCraftingStations[player.UserId]
	if not playerData then
		initializePlayerCrafting(player)
		playerData = playerCraftingStations[player.UserId]
	end
	
	-- Check if already unlocked
	for _, station in ipairs(playerData.unlockedStations) do
		if station == stationType then
			return false -- Already unlocked
		end
	end
	
	table.insert(playerData.unlockedStations, stationType)
	print("[CraftingSystem] Unlocked", stationType, "for", player.Name)
	return true
end

-- Get all available recipes for player
function CraftingSystem.getAvailableRecipes(player)
	local playerData = playerCraftingStations[player.UserId]
	if not playerData then return {} end
	
	local availableRecipes = {}
	local allRecipes = ItemDataFetcher.getCraftableItems()
	
	for _, recipe in ipairs(allRecipes) do
		-- Check if player has required station
		if hasCraftingStation(player, recipe.craftingStation) then
			table.insert(availableRecipes, recipe)
		end
	end
	
	return availableRecipes
end

-- Process all players' crafting queues (call this in a loop)
function CraftingSystem.processAllCrafting()
	for _, player in ipairs(game.Players:GetPlayers()) do
		CraftingSystem.processCraftingQueue(player)
	end
end

-- Initialize crafting system
function CraftingSystem.initialize()
	print("[CraftingSystem] 🚀 Initializing crafting system...")
	
	-- Initialize existing players
	for _, player in ipairs(game.Players:GetPlayers()) do
		initializePlayerCrafting(player)
	end
	
	-- Set up player added/removing events
	game.Players.PlayerAdded:Connect(initializePlayerCrafting)
	game.Players.PlayerRemoving:Connect(function(player)
		playerCraftingStations[player.UserId] = nil
	end)
	
	-- Start crafting processing loop
	game.RunService.Heartbeat:Connect(function()
		CraftingSystem.processAllCrafting()
	end)
	
	print("[CraftingSystem] ✅ Crafting system initialized")
end

return CraftingSystem
