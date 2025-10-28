local PlayerHomeService = {}
PlayerHomeService.__index = PlayerHomeService

-- Player Home Service manages house customization and furniture placement
-- Similar to Animal Crossing's home customization system

function PlayerHomeService.new(economyService, inventoryService)
	local self = setmetatable({}, PlayerHomeService)

	-- Dependencies
	self._economy = economyService
	self._inventory = inventoryService

	-- Player homes storage
	self._playerHomes = {} -- player -> home data
	self._homeUpgrades = {} -- player -> upgrade data

	-- Available furniture catalog
	self._furnitureCatalog = self:_initializeFurnitureCatalog()

	-- Home sizes and costs
	self._homeSizes = {
		Tent = { size = Vector3.new(8, 6, 8), cost = 0, rooms = 1 },
		House = { size = Vector3.new(12, 8, 12), cost = 5000, rooms = 2 },
		Expanded = { size = Vector3.new(16, 10, 16), cost = 15000, rooms = 3 },
		Deluxe = { size = Vector3.new(20, 12, 20), cost = 50000, rooms = 4 }
	}

	-- Count furniture properly for logging
	local furnitureCount = 0
	for _ in pairs(self._furnitureCatalog) do
		furnitureCount = furnitureCount + 1
	end

	print("[PlayerHomeService] Initialized with " .. tostring(furnitureCount) .. " furniture items")

	return self
end

function PlayerHomeService:_initializeFurnitureCatalog()
	-- Basic furniture catalog with placeholder data
	return {
		-- Living Room (5 items)
		["Wooden Chair"] = { category = "Seating", size = Vector3.new(2, 2, 2), cost = 800, description = "A simple wooden chair" },
		["Log Bench"] = { category = "Seating", size = Vector3.new(4, 1.5, 2), cost = 1200, description = "A rustic log bench" },
		["Wooden Table"] = { category = "Tables", size = Vector3.new(3, 2, 3), cost = 1500, description = "A sturdy wooden table" },
		["Rattan Sofa"] = { category = "Seating", size = Vector3.new(4, 2, 2), cost = 1600, description = "A comfortable rattan sofa" },
		["Coffee Table"] = { category = "Tables", size = Vector3.new(3, 1, 3), cost = 900, description = "A small coffee table" },

		-- Bedroom (6 items)
		["Simple Bed"] = { category = "Beds", size = Vector3.new(4, 2, 6), cost = 2000, description = "A basic single bed" },
		["Double Bed"] = { category = "Beds", size = Vector3.new(6, 2, 6), cost = 3500, description = "A comfortable double bed" },
		["Nightstand"] = { category = "Storage", size = Vector3.new(2, 2.5, 1.5), cost = 1100, description = "A wooden nightstand" },
		["Wooden Wardrobe"] = { category = "Storage", size = Vector3.new(3, 6, 2), cost = 1800, description = "A wooden storage wardrobe" },
		["Dresser"] = { category = "Storage", size = Vector3.new(3, 3, 1), cost = 1300, description = "A wooden dresser" },
		["Bookshelf"] = { category = "Storage", size = Vector3.new(2, 6, 1), cost = 1400, description = "A wooden bookshelf" },

		-- Kitchen (7 items)
		["Kitchen Counter"] = { category = "Kitchen", size = Vector3.new(4, 2, 2), cost = 2500, description = "Kitchen counter space" },
		["Refrigerator"] = { category = "Kitchen", size = Vector3.new(2, 5, 2), cost = 3000, description = "A modern refrigerator" },
		["Stove"] = { category = "Kitchen", size = Vector3.new(3, 3, 2), cost = 2800, description = "A functional stove" },
		["Dining Table"] = { category = "Tables", size = Vector3.new(4, 2, 3), cost = 2200, description = "A dining table for meals" },
		["Kitchen Sink"] = { category = "Kitchen", size = Vector3.new(2, 2, 2), cost = 1500, description = "A kitchen sink" },
		["Microwave"] = { category = "Kitchen", size = Vector3.new(2, 1.5, 1.5), cost = 900, description = "A compact microwave" },
		["Dining Chair"] = { category = "Seating", size = Vector3.new(2, 2, 2), cost = 700, description = "A dining chair" },

		-- Bathroom (5 items)
		["Bathtub"] = { category = "Bathroom", size = Vector3.new(3, 2, 5), cost = 3200, description = "A relaxing bathtub" },
		["Toilet"] = { category = "Bathroom", size = Vector3.new(1.5, 3, 1.5), cost = 1800, description = "A modern toilet" },
		["Bathroom Sink"] = { category = "Bathroom", size = Vector3.new(2, 2, 1.5), cost = 1400, description = "A bathroom sink" },
		["Towel Rack"] = { category = "Bathroom", size = Vector3.new(1, 2, 0.5), cost = 600, description = "A towel rack" },
		["Mirror"] = { category = "Bathroom", size = Vector3.new(2, 2.5, 0.2), cost = 1100, description = "A bathroom mirror" },

		-- Decorative (8 items)
		["House Plant"] = { category = "Decor", size = Vector3.new(1, 3, 1), cost = 600, description = "A decorative house plant" },
		["Wall Clock"] = { category = "Decor", size = Vector3.new(1, 1, 0.5), cost = 800, description = "A simple wall clock" },
		["Painting"] = { category = "Decor", size = Vector3.new(2, 1.5, 0.2), cost = 1200, description = "A beautiful painting" },
		["Rug"] = { category = "Decor", size = Vector3.new(4, 0.2, 4), cost = 1000, description = "A cozy area rug" },
		["Sculpture"] = { category = "Decor", size = Vector3.new(1.5, 2, 1.5), cost = 1500, description = "A decorative sculpture" },
		["Vase"] = { category = "Decor", size = Vector3.new(1, 2, 1), cost = 700, description = "A decorative vase" },
		["Picture Frame"] = { category = "Decor", size = Vector3.new(1, 1, 0.2), cost = 500, description = "A picture frame" },
		["Shelf"] = { category = "Storage", size = Vector3.new(3, 1, 1), cost = 1200, description = "A wall shelf" },

		-- Lighting (4 items)
		["Table Lamp"] = { category = "Lighting", size = Vector3.new(1, 2, 1), cost = 1000, description = "A cozy table lamp" },
		["Ceiling Light"] = { category = "Lighting", size = Vector3.new(2, 0.5, 2), cost = 1500, description = "A ceiling light fixture" },
		["Floor Lamp"] = { category = "Lighting", size = Vector3.new(1, 4, 1), cost = 900, description = "A standing floor lamp" },
		["Chandelier"] = { category = "Lighting", size = Vector3.new(3, 1, 3), cost = 2500, description = "An elegant chandelier" },

		-- Outdoor (4 items)
		["Garden Chair"] = { category = "Outdoor", size = Vector3.new(2, 2, 2), cost = 800, description = "A garden chair" },
		["Patio Table"] = { category = "Outdoor", size = Vector3.new(3, 1.5, 3), cost = 1300, description = "A patio table" },
		["Planter"] = { category = "Outdoor", size = Vector3.new(1.5, 1.5, 1.5), cost = 600, description = "A garden planter" },
		["Umbrella Stand"] = { category = "Outdoor", size = Vector3.new(1, 2, 1), cost = 700, description = "An umbrella stand" },
	}
end

function PlayerHomeService:CreatePlayerHome(player, islandPosition)
	-- Create a new home for a player
	local homeId = player.UserId .. "_home"
	local homeData = {
		owner = player,
		homeId = homeId,
		size = "Tent",
		rooms = 1,
		furniture = {},
		position = islandPosition or Vector3.new(-20, 5, 0), -- Default position near island edge
		created = os.time(),
		lastModified = os.time()
	}

	self._playerHomes[player] = homeData
	self:_buildHome(homeData)

	print("[PlayerHomeService] Created home for " .. player.Name .. " at " .. tostring(homeData.position))

	return homeData
end

function PlayerHomeService:_buildHome(homeData)
	-- Build the 3D house structure
	local building = Instance.new("Model")
	building.Name = homeData.homeId

	-- Main house structure based on size
	local homeSize = self._homeSizes[homeData.size]
	local housePart = Instance.new("Part")
	housePart.Name = "House"
	housePart.Size = homeSize.size
	housePart.Position = homeData.position
	housePart.Anchored = true
	housePart.CanCollide = true
	housePart.Material = Enum.Material.Wood
	housePart.Color = Color3.fromRGB(139, 69, 19) -- Brown wood
	housePart.Parent = building

	-- Add roof
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(homeSize.size.X + 2, 2, homeSize.size.Z + 2)
	roof.Position = homeData.position + Vector3.new(0, homeSize.size.Y / 2 + 1, 0)
	roof.Anchored = true
	roof.CanCollide = true
	roof.Material = Enum.Material.RoofShingles
	roof.Color = Color3.fromRGB(139, 0, 0) -- Dark red roof
	roof.Parent = building

	-- Add door
	local door = Instance.new("Part")
	door.Name = "Door"
	door.Size = Vector3.new(3, 6, 1)
	door.Position = homeData.position + Vector3.new(0, 3, homeSize.size.Z / 2 + 0.5)
	door.Anchored = true
	door.CanCollide = true
	door.Material = Enum.Material.Wood
	door.Color = Color3.fromRGB(101, 67, 33) -- Darker wood
	door.Parent = building

	-- Add windows
	for i = -1, 1, 2 do
		local window = Instance.new("Part")
		window.Name = "Window"
		window.Size = Vector3.new(2, 3, 1)
		window.Position = homeData.position + Vector3.new(i * 3, 4, homeSize.size.Z / 2 + 0.5)
		window.Anchored = true
		window.CanCollide = true
		window.Transparency = 0.5
		window.Material = Enum.Material.Glass
		window.Parent = building
	end

	-- Add house sign
	local sign = Instance.new("Part")
	sign.Name = "HomeSign"
	sign.Size = Vector3.new(6, 2, 1)
	sign.Position = homeData.position + Vector3.new(0, homeSize.size.Y / 2 + 3, homeSize.size.Z / 2 + 2)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Material = Enum.Material.Wood
	sign.Color = Color3.fromRGB(255, 255, 255)
	sign.Parent = building

	-- Add sign text (placeholder for now)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SignText"
	billboard.Size = UDim2.new(1, 0, 1, 0)
	billboard.Adornee = sign
	billboard.Parent = sign

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "🏠 " .. homeData.owner.Name .. "'s Home"
	textLabel.TextColor3 = Color3.fromRGB(139, 69, 19)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 16
	textLabel.Parent = billboard

	building.Parent = workspace
	homeData.building = building

	print("[PlayerHomeService] Built " .. homeData.size .. " for " .. homeData.owner.Name)
end

function PlayerHomeService:GetPlayerHome(player)
	return self._playerHomes[player]
end

function PlayerHomeService:GetFurnitureCatalog()
	return self._furnitureCatalog
end

function PlayerHomeService:CanAffordUpgrade(player, newSize)
	local homeData = self._playerHomes[player]
	if not homeData then return false end

	local currentSize = homeData.size
	local upgradeCost = self._homeSizes[newSize].cost

	if not self._economy or not self._economy.GetSnapshot then
		return false
	end

	local ok, snapshot = pcall(function()
		return self._economy:GetSnapshot(player)
	end)

	if not ok or not snapshot then
		return false
	end

	return snapshot.bells >= upgradeCost
end

function PlayerHomeService:UpgradeHome(player, newSize)
	local homeData = self._playerHomes[player]
	if not homeData then
		return { success = false, message = "No home found for player" }
	end

	if not self:CanAffordUpgrade(player, newSize) then
		return { success = false, message = "Cannot afford home upgrade" }
	end

	local upgradeCost = self._homeSizes[newSize].cost

	-- Process payment
	local success = pcall(function()
		self._economy:SpendBells(player, upgradeCost)
	end)

	if not success then
		return { success = false, message = "Upgrade payment failed" }
	end

	-- Upgrade home
	local oldSize = homeData.size
	homeData.size = newSize
	homeData.rooms = self._homeSizes[newSize].rooms
	homeData.lastModified = os.time()

	-- Rebuild house with new size
	if homeData.building then
		homeData.building:Destroy()
	end
	self:_buildHome(homeData)

	return {
		success = true,
		message = string.format("Upgraded from %s to %s for %d Bells! 🏠✨", oldSize, newSize, upgradeCost),
		data = {
			newSize = newSize,
			rooms = homeData.rooms,
			cost = upgradeCost
		}
	}
end

function PlayerHomeService:PlaceFurniture(player, furnitureName, position, rotation)
	local homeData = self._playerHomes[player]
	if not homeData then
		return { success = false, message = "No home found" }
	end

	local furniture = self._furnitureCatalog[furnitureName]
	if not furniture then
		return { success = false, message = "Furniture not found in catalog" }
	end

	-- Check if player owns this furniture
	if self._inventory and self._inventory.GetSnapshot then
		local ok, snapshot = pcall(function()
			return self._inventory:GetSnapshot(player)
		end)

		if ok and snapshot then
			local hasItem = false
			for _, item in ipairs(snapshot.items or {}) do
				if item.id == furnitureName or item.name == furnitureName then
					hasItem = true
					break
				end
			end

			if not hasItem then
				return { success = false, message = "You don't own this furniture" }
			end
		end
	end

	-- Create furniture in home
	local furniturePart = Instance.new("Part")
	furniturePart.Name = furnitureName
	furniturePart.Size = furniture.size
	furniturePart.Position = homeData.position + position
	furniturePart.Rotation = rotation or Vector3.new(0, 0, 0)
	furniturePart.Anchored = true
	furniturePart.CanCollide = true
	furniturePart.Material = Enum.Material.Wood
	furniturePart.Color = Color3.fromRGB(160, 82, 45) -- Furniture brown
	furniturePart.Parent = homeData.building

	-- Add to home furniture data
	table.insert(homeData.furniture, {
		name = furnitureName,
		position = position,
		rotation = rotation,
		placed = os.time(),
		part = furniturePart
	})

	homeData.lastModified = os.time()

	return {
		success = true,
		message = "Placed " .. furnitureName .. " in your home! 🪑",
		data = {
			furniture = furnitureName,
			position = position
		}
	}
end

function PlayerHomeService:RemoveFurniture(player, furnitureIndex)
	local homeData = self._playerHomes[player]
	if not homeData then
		return { success = false, message = "No home found" }
	end

	local furniture = homeData.furniture[furnitureIndex]
	if not furniture then
		return { success = false, message = "Furniture not found" }
	end

	-- Remove from 3D world
	if furniture.part then
		furniture.part:Destroy()
	end

	-- Remove from data
	table.remove(homeData.furniture, furnitureIndex)
	homeData.lastModified = os.time()

	return {
		success = true,
		message = "Removed " .. furniture.name .. " from your home! 🗑️"
	}
end

function PlayerHomeService:GetHomeStatus(player)
	local homeData = self._playerHomes[player]
	if not homeData then
		return { hasHome = false }
	end

	return {
		hasHome = true,
		size = homeData.size,
		rooms = homeData.rooms,
		furnitureCount = #homeData.furniture,
		lastModified = homeData.lastModified,
		position = homeData.position
	}
end

function PlayerHomeService:GetAvailableUpgrades(player)
	local homeData = self._playerHomes[player]
	if not homeData then return {} end

	local currentSize = homeData.size
	local upgrades = {}

	for sizeName, sizeData in pairs(self._homeSizes) do
		if sizeName ~= currentSize then
			local canAfford = self:CanAffordUpgrade(player, sizeName)
			table.insert(upgrades, {
				name = sizeName,
				cost = sizeData.cost,
				rooms = sizeData.rooms,
				size = sizeData.size,
				canAfford = canAfford
			})
		end
	end

	return upgrades
end

function PlayerHomeService:Destroy()
	-- Clean up all player homes
	for player, homeData in pairs(self._playerHomes) do
		if homeData.building then
			homeData.building:Destroy()
		end
	end
	self._playerHomes = {}
end

return PlayerHomeService
