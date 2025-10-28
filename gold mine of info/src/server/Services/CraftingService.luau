-- Crafting Service
-- Handles DIY recipe management and crafting using ItemDB
local CraftingService = {}
CraftingService.__index = CraftingService

function CraftingService.new(remotes, itemDB, inventory)
	local self = setmetatable({}, CraftingService)
	self._remotes = remotes
	self._itemDB = itemDB or _G.ItemDB
	self._inventory = inventory
	self._playerRecipes = {}  -- Track learned recipes per player
	
	self:_setupRemotes()
	
	print("[CraftingService] Initialized with ItemDB")
	return self
end

-- Setup remote functions
function CraftingService:_setupRemotes()
	-- Get DIY recipes
	local getRecipesRemote = self._remotes:Get("GetDIYRecipes")
	if getRecipesRemote and getRecipesRemote:IsA("RemoteFunction") then
		getRecipesRemote.OnServerInvoke = function(player)
			return self:GetPlayerRecipes(player)
		end
	end
	
	-- Craft item
	local craftRemote = self._remotes:Get("CraftDIYItem")
	if craftRemote then
		craftRemote.OnServerEvent:Connect(function(player, recipeName)
			self:CraftItem(player, recipeName)
		end)
	end
	
	-- Learn recipe
	local learnRemote = self._remotes:Get("LearnDIYRecipe")
	if learnRemote then
		learnRemote.OnServerEvent:Connect(function(player, recipeName)
			self:LearnRecipe(player.UserId, recipeName)
		end)
	end
end

-- Get player's learned recipes
function CraftingService:GetPlayerRecipes(player)
	if not self._itemDB then
		warn("[CraftingService] ItemDB not available")
		return {}
	end
	
	local userId = player.UserId
	local learnedRecipes = self._playerRecipes[userId] or {}
	
	-- Get all recipes from ItemDB
	local allRecipes = self._itemDB:GetCraftableRecipes()
	local playerRecipeList = {}
	
	for _, recipe in ipairs(allRecipes) do
		-- Check if player has learned this recipe (or give all for now)
		local hasLearned = learnedRecipes[recipe.name] or true  -- TODO: Implement learning system
		
		if hasLearned then
			-- Get item data with emoji
			local itemData = self._itemDB:GetItemWithEmoji(recipe.name)
			
			-- Check if player has materials
			local materials = recipe.materials or recipe.material or {}
			local canCraft = true
			local playerHas = {}
			
			for material, quantity in pairs(materials) do
				local owned = self._inventory and self._inventory:GetItemCount(userId, material) or 0
				playerHas[material] = owned
				
				if owned < quantity then
					canCraft = false
				end
			end
			
			-- Add to list
			table.insert(playerRecipeList, {
				name = recipe.name,
				emoji = itemData and itemData.emoji or "🔨",
				description = recipe.description or "A DIY recipe",
				materials = materials,
				materialCount = self:_countMaterials(materials),
				canCraft = canCraft,
				playerHas = playerHas,
				category = recipe.category or "misc"
			})
		end
	end
	
	print(string.format("[CraftingService] Returning %d recipes for %s", #playerRecipeList, player.Name))
	return playerRecipeList
end

-- Count total materials in recipe
function CraftingService:_countMaterials(materials)
	local count = 0
	for _, _ in pairs(materials) do
		count = count + 1
	end
	return count
end

-- Craft item
function CraftingService:CraftItem(player, recipeName)
	if not self._itemDB or not self._inventory then
		warn("[CraftingService] ItemDB or Inventory not available")
		return false
	end
	
	local userId = player.UserId
	
	-- Get recipe
	local recipe = self._itemDB:GetRecipe(recipeName)
	if not recipe then
		warn("[CraftingService] Recipe not found:", recipeName)
		return false
	end
	
	-- Check materials
	local materials = recipe.materials or recipe.material or {}
	for material, quantity in pairs(materials) do
		local owned = self._inventory:GetItemCount(userId, material)
		if owned < quantity then
			print(string.format("[CraftingService] %s missing %s (need %d, has %d)", 
				player.Name, material, quantity, owned))
			return false
		end
	end
	
	-- Remove materials
	for material, quantity in pairs(materials) do
		self._inventory:RemoveItem(userId, material, quantity)
	end
	
	-- Add crafted item
	self._inventory:AddItem(userId, recipeName, 1)
	
	print(string.format("[CraftingService] %s crafted %s", player.Name, recipeName))
	return true
end

-- Learn recipe
function CraftingService:LearnRecipe(userId, recipeName)
	if not self._playerRecipes[userId] then
		self._playerRecipes[userId] = {}
	end
	
	self._playerRecipes[userId][recipeName] = true
	print(string.format("[CraftingService] Player %d learned recipe: %s", userId, recipeName))
end

-- Give starter recipes
function CraftingService:GiveStarterRecipes(userId)
	local starterRecipes = {
		"Fishing Rod",
		"Net",
		"Axe",
		"Shovel",
		"Watering Can",
		"Wooden Chair",
		"Wooden Table",
		"Campfire",
	}
	
	for _, recipeName in ipairs(starterRecipes) do
		self:LearnRecipe(userId, recipeName)
	end
	
	print(string.format("[CraftingService] Gave %d starter recipes to player %d", #starterRecipes, userId))
end

return CraftingService

