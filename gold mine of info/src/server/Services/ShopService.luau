-- Shop Service
-- Handles shop transactions and item browsing using ItemDB
local ShopService = {}
ShopService.__index = ShopService

function ShopService.new(remotes, itemDB, economy, inventory)
	local self = setmetatable({}, ShopService)
	self._remotes = remotes
	self._itemDB = itemDB or _G.ItemDB
	self._economy = economy
	self._inventory = inventory
	
	self:_setupRemotes()
	
	print("[ShopService] Initialized with ItemDB")
	return self
end

-- Setup remote functions
function ShopService:_setupRemotes()
	-- Get shop items (browsing)
	local getItemsRemote = self._remotes:Get("GetShopItems")
	if getItemsRemote and getItemsRemote:IsA("RemoteFunction") then
		getItemsRemote.OnServerInvoke = function(player, category, searchQuery, page, itemsPerPage)
			return self:GetShopItems(category, searchQuery, page, itemsPerPage)
		end
	end
	
	-- Buy item
	local buyItemRemote = self._remotes:Get("BuyShopItem")
	if buyItemRemote then
		buyItemRemote.OnServerEvent:Connect(function(player, itemName, quantity)
			self:BuyItem(player, itemName, quantity)
		end)
	end
	
	-- Sell item
	local sellItemRemote = self._remotes:Get("SellShopItem")
	if sellItemRemote then
		sellItemRemote.OnServerEvent:Connect(function(player, itemName, quantity)
			self:SellItem(player, itemName, quantity)
		end)
	end
end

-- Get items for shop browsing
function ShopService:GetShopItems(category, searchQuery, page, itemsPerPage)
	if not self._itemDB then
		warn("[ShopService] ItemDB not available")
		return {}
	end
	
	local allItems = {}
	
	-- Get items by category or search
	if searchQuery and searchQuery ~= "" then
		-- Search across all items
		local searchResults = self._itemDB:SearchItems(searchQuery, 100)
		for _, result in ipairs(searchResults) do
			local itemData = self._itemDB:GetItemWithEmoji(result.name)
			if itemData then
				table.insert(allItems, itemData)
			end
		end
	else
		-- Get by category
		local categoryItems = self._itemDB:GetItemsByCategory(category)
		for _, item in ipairs(categoryItems) do
			local itemData = self._itemDB:GetItemWithEmoji(item.name)
			if itemData then
				table.insert(allItems, itemData)
			end
		end
	end
	
	-- Pagination
	page = page or 1
	itemsPerPage = itemsPerPage or 12
	local startIndex = (page - 1) * itemsPerPage + 1
	local endIndex = math.min(startIndex + itemsPerPage - 1, #allItems)
	
	local paginatedItems = {}
	for i = startIndex, endIndex do
		if allItems[i] then
			table.insert(paginatedItems, allItems[i])
		end
	end
	
	print(string.format("[ShopService] Returning %d items (category: %s, page: %d)", #paginatedItems, category, page))
	return paginatedItems
end

-- Buy item
function ShopService:BuyItem(player, itemName, quantity)
	quantity = quantity or 1
	
	local itemData = self._itemDB:GetItemWithEmoji(itemName)
	if not itemData then
		warn("[ShopService] Item not found:", itemName)
		return false
	end
	
	local totalCost = itemData.buy_price * quantity
	
	-- Check if player has enough bells
	if not self._economy then
		warn("[ShopService] Economy service not available")
		return false
	end
	
	local snapshot = self._economy:GetSnapshot(player)
	if not snapshot or snapshot.bells < totalCost then
		print(string.format("[ShopService] %s cannot afford %s (needs %d, has %d)", 
			player.Name, itemName, totalCost, snapshot and snapshot.bells or 0))
		return false
	end
	
	-- Deduct bells
	local success = self._economy:RemoveBells(player.UserId, totalCost)
	if not success then
		return false
	end
	
	-- Add item to inventory
	if self._inventory then
		self._inventory:AddItem(player.UserId, itemName, quantity)
	end
	
	print(string.format("[ShopService] %s bought %d x %s for %d bells", 
		player.Name, quantity, itemName, totalCost))
	
	return true
end

-- Sell item
function ShopService:SellItem(player, itemName, quantity)
	quantity = quantity or 1
	
	local itemData = self._itemDB:GetItemWithEmoji(itemName)
	if not itemData then
		warn("[ShopService] Item not found:", itemName)
		return false
	end
	
	-- Check if player has item
	if not self._inventory then
		warn("[ShopService] Inventory service not available")
		return false
	end
	
	local hasItem = self._inventory:HasItem(player.UserId, itemName, quantity)
	if not hasItem then
		print(string.format("[ShopService] %s doesn't have %d x %s to sell", 
			player.Name, quantity, itemName))
		return false
	end
	
	-- Remove from inventory
	local success = self._inventory:RemoveItem(player.UserId, itemName, quantity)
	if not success then
		return false
	end
	
	-- Add bells
	local totalEarned = itemData.sell_price * quantity
	if self._economy then
		self._economy:AddBells(player.UserId, totalEarned)
	end
	
	print(string.format("[ShopService] %s sold %d x %s for %d bells", 
		player.Name, quantity, itemName, totalEarned))
	
	return true
end

-- Get hot item of the day (2x sell price)
function ShopService:GetHotItem()
	if not self._itemDB then return nil end
	
	-- Random hot item from furniture
	local furniture = self._itemDB:GetItemsByCategory("furniture")
	if #furniture > 0 then
		local randomItem = furniture[math.random(#furniture)]
		return self._itemDB:GetItemWithEmoji(randomItem.name)
	end
	
	return nil
end

return ShopService

