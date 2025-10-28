local NooksCranny = {}
NooksCranny.__index = NooksCranny

-- Nook's Cranny is the main shop on the island
-- Run by Timmy and Tommy Nook

function NooksCranny.new(economyService, inventoryService)
	local self = setmetatable({}, NooksCranny)

	-- Dependencies
	self._economy = economyService
	self._inventory = inventoryService

	-- Shop state
	self._building = nil
	self._timmy = nil
	self._tommy = nil

	-- Shop hours (8 AM - 10 PM)
	self._openTime = 8
	self._closeTime = 22

	-- Daily stock rotation
	self._currentStock = {}
	self._lastStockRefresh = nil

	-- Shop inventory categories
	self._categories = {
		Tools = {
			"Flimsy Fishing Rod",
			"Flimsy Net",
			"Flimsy Axe",
			"Flimsy Shovel",
			"Slingshot",
			"Watering Can"
		},
		Furniture = {
			"Wooden Chair",
			"Log Bench",
			"Simple Bed",
			"Wooden Table",
			"Wooden Wardrobe",
			"Log Stool"
		},
		Materials = {
			"Wood",
			"Softwood",
			"Hardwood",
			"Stone",
			"Iron Nugget",
			"Clay"
		},
		Seeds = {
			"Tree Sapling",
			"Flower Seeds",
			"Pumpkin Seeds",
			"Wheat Seeds"
		}
	}

	-- Initialize shop
	self:_createBuilding()
	self:_refreshStock()

	return self
end

function NooksCranny:_createBuilding()
	-- Create Nook's Cranny building
	local building = Instance.new("Model")
	building.Name = "NooksCranny"

	-- Main shop structure
	local shop = Instance.new("Part")
	shop.Name = "Shop"
	shop.Size = Vector3.new(35, 18, 25)
	shop.Position = Vector3.new(25, 9, 25) -- Near Resident Services
	shop.Anchored = true
	shop.CanCollide = true
	shop.Material = Enum.Material.Wood
	shop.Color = Color3.fromRGB(139, 69, 19) -- Brown wood
	shop.Parent = building

	-- Add roof
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(37, 2, 27)
	roof.Position = Vector3.new(25, 19, 25)
	roof.Anchored = true
	roof.CanCollide = true
	roof.Material = Enum.Material.RoofShingles
	roof.Color = Color3.fromRGB(139, 0, 0) -- Dark red roof
	roof.Parent = building

	-- Add shop entrance
	local entrance = Instance.new("Part")
	entrance.Name = "Entrance"
	entrance.Size = Vector3.new(8, 12, 2)
	entrance.Position = Vector3.new(25, 6, 15) -- Front of shop
	entrance.Anchored = true
	entrance.CanCollide = true
	entrance.Material = Enum.Material.Wood
	entrance.Color = Color3.fromRGB(101, 67, 33) -- Darker wood
	entrance.Parent = building

	-- Add windows (shop front)
	for i = -2, 2 do
		local window = Instance.new("Part")
		window.Name = "Window"
		window.Size = Vector3.new(3, 5, 1)
		window.Position = Vector3.new(25 + i * 6, 12, 15)
		window.Anchored = true
		window.CanCollide = true
		window.Transparency = 0.3
		window.Material = Enum.Material.Glass
		window.Parent = building
	end

	-- Add shop sign
	local sign = Instance.new("Part")
	sign.Name = "NooksCrannySign"
	sign.Size = Vector3.new(14, 5, 1)
	sign.Position = Vector3.new(25, 16, 10)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Material = Enum.Material.Wood
	sign.Color = Color3.fromRGB(255, 255, 255)
	sign.Parent = building

	-- Add sign text
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SignText"
	billboard.Size = UDim2.new(1, 0, 1, 0)
	billboard.Adornee = sign
	billboard.Parent = sign

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "🏪 Nook's Cranny"
	textLabel.TextColor3 = Color3.fromRGB(139, 69, 19)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 28
	textLabel.Parent = billboard

	building.Parent = workspace
	self._building = building

	print("[NooksCranny] Shop building created")
end

function NooksCranny:_refreshStock()
	-- Refresh daily stock based on current day
	local currentDay = os.date("%Y%m%d")
	if self._lastStockRefresh == currentDay then
		return -- Already refreshed today
	end

	self._lastStockRefresh = currentDay
	self._currentStock = {}

	-- Select random items for each category
	for category, items in pairs(self._categories) do
		local numItems = math.random(2, 4)
		local selectedItems = {}

		for i = 1, numItems do
			local item = items[math.random(1, #items)]
			if not selectedItems[item] then
				selectedItems[item] = true
				table.insert(self._currentStock, {
					name = item,
					category = category,
					buyPrice = math.random(100, 2000), -- Random buy price
					sellPrice = math.random(50, 1000),  -- Random sell price
					stock = math.random(1, 5)           -- Limited stock
				})
			end
		end
	end

	print("[NooksCranny] Stock refreshed for today with " .. #self._currentStock .. " items")
end

function NooksCranny:GetBuilding()
	return self._building
end

function NooksCranny:GetStock()
	self:_refreshStock()
	return self._currentStock
end

function NooksCranny:GetStatus()
	local hour = os.date("!%H")
	local isOpen = self:IsOpen(hour)

	return {
		isOpen = isOpen,
		currentHour = hour,
		openTime = self._openTime,
		closeTime = self._closeTime,
		nextChange = isOpen and self._closeTime or self._openTime,
		stockCount = #self._currentStock
	}
end

function NooksCranny:IsOpen(currentHour)
	return currentHour >= self._openTime and currentHour < self._closeTime
end

-- Shopping functions
function NooksCranny:BuyItem(player, itemName, quantity)
	quantity = quantity or 1

	local hour = os.date("!%H")
	if not self:IsOpen(hour) then
		return {
			success = false,
			message = "Nook's Cranny is closed. Opens at 8:00 AM."
		}
	end

	-- Find item in stock
	local item = nil
	for _, stockItem in ipairs(self._currentStock) do
		if stockItem.name == itemName and stockItem.stock >= quantity then
			item = stockItem
			break
		end
	end

	if not item then
		return {
			success = false,
			message = "Item not available or out of stock."
		}
	end

	-- Check if player can afford it
	if not self._economy or not self._economy.GetSnapshot then
		return {
			success = false,
			message = "Economy service unavailable."
		}
	end

	local totalCost = item.buyPrice * quantity
	local ok, snapshot = pcall(function()
		return self._economy:GetSnapshot(player)
	end)

	if not ok or not snapshot then
		return {
			success = false,
			message = "Unable to check player balance."
		}
	end

	if snapshot.bells < totalCost then
		return {
			success = false,
			message = string.format("Not enough Bells! Need %d Bells, you have %d.", totalCost, snapshot.bells)
		}
	end

	-- Process purchase
	local success = pcall(function()
		self._economy:SpendBells(player, totalCost)
	end)

	if not success then
		return {
			success = false,
			message = "Purchase failed. Please try again."
		}
	end

	-- Add item to inventory
	if self._inventory and self._inventory.AddItem then
		for i = 1, quantity do
			self._inventory:AddItem(player, itemName)
		end
	end

	-- Update stock
	item.stock = item.stock - quantity

	return {
		success = true,
		message = string.format("Purchased %d x %s for %d Bells! 🛒", quantity, itemName, totalCost),
		data = {
			item = itemName,
			quantity = quantity,
			cost = totalCost,
			remainingStock = item.stock
		}
	}
end

function NooksCranny:SellItem(player, itemName, quantity)
	quantity = quantity or 1

	local hour = os.date("!%H")
	if not self:IsOpen(hour) then
		return {
			success = false,
			message = "Nook's Cranny is closed. Opens at 8:00 AM."
		}
	end

	-- Check if player has the item
	if not self._inventory or not self._inventory.GetSnapshot then
		return {
			success = false,
			message = "Inventory service unavailable."
		}
	end

	local ok, snapshot = pcall(function()
		return self._inventory:GetSnapshot(player)
	end)

	if not ok or not snapshot then
		return {
			success = false,
			message = "Unable to check inventory."
		}
	end

	local playerItem = nil
	for _, item in ipairs(snapshot.items or {}) do
		if item.id == itemName or item.name == itemName then
			playerItem = item
			break
		end
	end

	if not playerItem or playerItem.quantity < quantity then
		return {
			success = false,
			message = "You don't have enough of this item to sell."
		}
	end

	-- Find item value (use sell price from our stock or default)
	local sellPrice = 50 -- Default sell price
	for _, stockItem in ipairs(self._currentStock) do
		if stockItem.name == itemName then
			sellPrice = stockItem.sellPrice
			break
		end
	end

	local totalEarnings = sellPrice * quantity

	-- Process sale
	local success = pcall(function()
		self._economy:EarnBells(player, totalEarnings)
	end)

	if not success then
		return {
			success = false,
			message = "Sale failed. Please try again."
		}
	end

	-- Remove from inventory
	if self._inventory and self._inventory.RemoveItem then
		self._inventory:RemoveItem(player, itemName, quantity)
	end

	return {
		success = true,
		message = string.format("Sold %d x %s for %d Bells! 💰", quantity, itemName, totalEarnings),
		data = {
			item = itemName,
			quantity = quantity,
			earnings = totalEarnings
		}
	}
end

function NooksCranny:GetCategories()
	return self._categories
end

function NooksCranny:GetShopInfo()
	return {
		name = "Nook's Cranny",
		owners = "Timmy & Tommy",
		specialty = "Tools, Furniture, Materials",
		hours = string.format("%d:00 AM - %d:00 PM", self._openTime, self._closeTime),
		dailySpecial = self:_getDailySpecial()
	}
end

function NooksCranny:_getDailySpecial()
	-- Return a random daily special
	local specials = {
		"20% off all tools today!",
		"Buy 2 furniture items, get 1 material free!",
		"Special discount on seeds - perfect for gardening!",
		"Tree saplings half price!",
		"Double bells for selling materials today!"
	}
	return specials[math.random(1, #specials)]
end

function NooksCranny:Destroy()
	if self._building then
		self._building:Destroy()
	end
	if self._timmy then
		self._timmy:Destroy()
	end
	if self._tommy then
		self._tommy:Destroy()
	end
end

return NooksCranny
