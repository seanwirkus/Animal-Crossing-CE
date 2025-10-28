local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
        ALCHEMY = "alchemy",
}

CraftingSystem.CRAFTING_STATIONS = CRAFTING_STATIONS

local inventoryCallbacks = {
        hasMaterials = nil,
        consumeMaterials = nil,
        grantItems = nil,
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
local function hasRequiredMaterials(player, materials, quantity)
        if #materials == 0 then
                return true
        end

        if inventoryCallbacks.hasMaterials then
                local success, result = pcall(inventoryCallbacks.hasMaterials, player, materials, quantity)
                if not success then
                        warn("[CraftingSystem] Material check failed:", result)
                        return false
                end
                return result and true or false
        end

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
        quantity = math.max(1, quantity or 1)

        local recipe = ItemDataFetcher.getCraftingRecipe(itemId)
        if not recipe then
                warn("[CraftingSystem] No recipe found for", itemId)
                return false
        end

        local station = recipe.station or CRAFTING_STATIONS.WORKBENCH

        -- Check if player has required station
        if not hasCraftingStation(player, station) then
                warn("[CraftingSystem] Player", player.Name, "doesn't have", station)
                return false
        end
	
        -- Check if player has required materials
        if not hasRequiredMaterials(player, recipe.materials, quantity) then
                warn("[CraftingSystem] Player", player.Name, "doesn't have required materials")
                return false
        end

        if inventoryCallbacks.consumeMaterials then
                local success, result = pcall(inventoryCallbacks.consumeMaterials, player, recipe.materials, quantity)
                if not success then
                        warn("[CraftingSystem] Failed to consume materials:", result)
                        return false
                end
                if result == false then
                        return false
                end
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
                        recipe = recipe,
                        startTime = tick(),
                        craftingTime = recipe.time or 6,
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
        if inventoryCallbacks.grantItems then
                local success, result = pcall(inventoryCallbacks.grantItems, player, items)
                if not success then
                        warn("[CraftingSystem] Failed to grant crafted items:", result)
                end
        else
                for _, itemId in ipairs(items) do
                        print("[CraftingSystem] Giving", itemId, "to", player.Name)
                end
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
                if hasCraftingStation(player, recipe.station or CRAFTING_STATIONS.WORKBENCH) then
                        table.insert(availableRecipes, recipe)
                end
        end

        return availableRecipes
end

function CraftingSystem.configure(options: any)
        if typeof(options) ~= "table" then
                return
        end

        if options.hasMaterials then
                inventoryCallbacks.hasMaterials = options.hasMaterials
        end

        if options.consumeMaterials then
                inventoryCallbacks.consumeMaterials = options.consumeMaterials
        end

        if options.grantItems then
                inventoryCallbacks.grantItems = options.grantItems
        end
end

-- Process all players' crafting queues (call this in a loop)
function CraftingSystem.processAllCrafting()
        for _, player in ipairs(Players:GetPlayers()) do
                CraftingSystem.processCraftingQueue(player)
        end
end

-- Initialize crafting system
function CraftingSystem.initialize()
        print("[CraftingSystem] 🚀 Initializing crafting system...")

        -- Initialize existing players
        for _, player in ipairs(Players:GetPlayers()) do
                initializePlayerCrafting(player)
        end

        -- Set up player added/removing events
        Players.PlayerAdded:Connect(initializePlayerCrafting)
        Players.PlayerRemoving:Connect(function(player)
                playerCraftingStations[player.UserId] = nil
        end)

        -- Start crafting processing loop
        RunService.Heartbeat:Connect(function()
                CraftingSystem.processAllCrafting()
        end)
	
	print("[CraftingSystem] ✅ Crafting system initialized")
end

return CraftingSystem
