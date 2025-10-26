-- Server initialization script
-- Complete server-side inventory management

print("✅ Animal Crossing server systems ready!")
print("📊 ServerScriptService scripts will run automatically")

-- Import services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[Server] 🚀 Starting inventory system...")

-- Create RemoteEvent
local inventoryRemote = ReplicatedStorage:FindFirstChild("InventoryEvent") or Instance.new("RemoteEvent")
inventoryRemote.Name = "InventoryEvent"
inventoryRemote.Parent = ReplicatedStorage

-- Player inventory storage
local playerInventories = {}

-- World item storage - tracks all dropped items
local worldItems = {}
local nextItemId = 1

-- ItemData for server
local ItemData = {
	-- Row 1: Tools (indices 1-21) - ACTUAL ORDER FROM SPRITE SHEET
	leaf = { index = 1, name = "Leaf" },
	shovel = { index = 2, name = "Shovel" },
	net = { index = 3, name = "Net" },
	slingshot = { index = 4, name = "Slingshot" },
	fishing_rod = { index = 5, name = "Fishing Rod" },
	watering_can = { index = 6, name = "Watering Can" },
	axe = { index = 7, name = "Axe" },
	stone_axe = { index = 8, name = "Stone Axe" },
	shovel_2 = { index = 9, name = "Shovel" }, -- Another shovel variant
	pole_vault = { index = 10, name = "Vaulting Pole" },
	ladder = { index = 11, name = "Ladder" },
	flute = { index = 12, name = "Pan Flute" },
	flute_2 = { index = 13, name = "Flute" }, -- Another flute variant
	tambourine = { index = 14, name = "Tambourine" },
	golden_axe = { index = 15, name = "Golden Axe" },
	golden_net = { index = 16, name = "Golden Net" },
	golden_shovel = { index = 17, name = "Golden Shovel" },
	golden_can = { index = 18, name = "Golden Can" },
	golden_slingshot = { index = 19, name = "Golden Slingshot" },
	golden_fishing_rod = { index = 20, name = "Golden Fishing Rod" },
	golden_ladder = { index = 21, name = "Golden Ladder" },
	
	-- Row 2: Clothing/Items (indices 22-42)
	glasses_red = { index = 22, name = "Red Glasses" },
	shirt_striped = { index = 23, name = "Striped Shirt" },
	shirt_blue = { index = 24, name = "Blue Shirt" },
	bag_blue = { index = 25, name = "Bag (Blue)" },
	socks = { index = 26, name = "Socks" },
	shoes_yellow = { index = 27, name = "Shoes (Yellow)" },
	shoes_black = { index = 28, name = "Shoes (Black)" },
	umbrella_red = { index = 29, name = "Red Umbrella" },
	purse_pink = { index = 30, name = "Purse (Pink)" },
	egg_purple = { index = 31, name = "Purple Egg" },
	egg_orange = { index = 32, name = "Orange Egg" },
	egg_yellow = { index = 33, name = "Yellow Egg" },
	egg_green = { index = 34, name = "Green Egg" },
	bell_bag_small = { index = 35, name = "Small Bell Bag" },
	bell_bag_med = { index = 36, name = "Bell Bag" },
	bell_bag_large = { index = 37, name = "Large Bell Bag" },
	bottle_message = { index = 38, name = "Message Bottle" },
	recipe_card = { index = 39, name = "DIY Recipe Card" },
	paper_gift = { index = 40, name = "Gift Bag" },
	leaf_fossil = { index = 41, name = "Fossil Leaf" },
	
	-- Row 3: Flowers (indices 43-63)
	rose_red = { index = 43, name = "Red Rose" },
	rose_white = { index = 44, name = "White Rose" },
	rose_pink = { index = 45, name = "Pink Rose" },
	rose_yellow = { index = 46, name = "Yellow Rose" },
	tulip_red = { index = 47, name = "Red Tulip" },
	tulip_white = { index = 48, name = "White Tulip" },
	tulip_orange = { index = 49, name = "Orange Tulip" },
	lily_pink = { index = 50, name = "Pink Lily" },
	lily_yellow = { index = 51, name = "Yellow Lily" },
	lily_white = { index = 52, name = "White Lily" },
	mum_purple = { index = 53, name = "Purple Mum" },
	mum_red = { index = 54, name = "Red Mum" },
	mum_white = { index = 55, name = "White Mum" },
	hyacinth_blue = { index = 56, name = "Blue Hyacinth" },
	hyacinth_pink = { index = 57, name = "Pink Hyacinth" },
	hyacinth_orange = { index = 58, name = "Orange Hyacinth" },
	hyacinth_white = { index = 59, name = "White Hyacinth" },
	cosmos_red = { index = 60, name = "Red Cosmos" },
	cosmos_yellow = { index = 61, name = "Yellow Cosmos" },
	cosmos_white = { index = 62, name = "White Cosmos" },
	
	-- Row 4: Fish (indices 64-84)
	fish_betta = { index = 64, name = "Betta" },
	fish_clown = { index = 65, name = "Clownfish" },
	fish_puffer = { index = 66, name = "Pufferfish" },
	fish_tuna = { index = 67, name = "Tuna" },
	fish_bass = { index = 68, name = "Black Bass" },
	fish_snapper = { index = 69, name = "Red Snapper" },
	fish_goldfish = { index = 70, name = "Goldfish" },
	fish_koi = { index = 71, name = "Koi" },
	fish_loach = { index = 72, name = "Loach" },
	fish_seahorse = { index = 73, name = "Seahorse" },
	
	-- Row 5: Bugs (indices 85-105)
	bug_butterfly = { index = 85, name = "Common Butterfly" },
	bug_moth = { index = 86, name = "Moth" },
	bug_ladybug = { index = 87, name = "Ladybug" },
	bug_beetle = { index = 88, name = "Stag Beetle" },
	bug_dragonfly = { index = 89, name = "Dragonfly" },
	bug_firefly = { index = 90, name = "Firefly" },
	bug_spider = { index = 91, name = "Spider" },
	bug_scorpion = { index = 92, name = "Scorpion" },
	bug_tar = { index = 93, name = "Tarantula" },
	bug_cicada = { index = 94, name = "Cicada" },
	
	-- Row 6: Seasonal (indices 106-126)
	snowflake = { index = 106, name = "Snowflake" },
	ornament_red = { index = 107, name = "Red Ornament" },
	ornament_blue = { index = 108, name = "Blue Ornament" },
	ornament_gold = { index = 109, name = "Gold Ornament" },
	pumpkin_orange = { index = 110, name = "Orange Pumpkin" },
	pumpkin_white = { index = 111, name = "White Pumpkin" },
	pumpkin_yellow = { index = 112, name = "Yellow Pumpkin" },
	pumpkin_green = { index = 113, name = "Green Pumpkin" },
	heart_pink = { index = 114, name = "Heart Crystal" },
}

-- Initialize player inventory
local function initializePlayerInventory(player)
	playerInventories[player.UserId] = {
		items = {
			-- Essential Tools
			{ itemId = "shovel", count = 1 },
			{ itemId = "net", count = 1 },
			{ itemId = "fishing_rod", count = 1 },
			{ itemId = "watering_can", count = 1 },
			{ itemId = "axe", count = 1 },
			{ itemId = "slingshot", count = 1 },
			{ itemId = "ladder", count = 1 },
			
			-- Starting Currency
			{ itemId = "bell_bag_small", count = 5 },
			{ itemId = "bell_bag_med", count = 2 },
			
			-- Sample Flowers
			{ itemId = "rose_red", count = 3 },
			{ itemId = "rose_white", count = 2 },
			{ itemId = "tulip_red", count = 2 },
			
			-- Sample Fish
			{ itemId = "fish_betta", count = 1 },
			{ itemId = "fish_goldfish", count = 1 },
			
			-- Sample Bugs
			{ itemId = "bug_butterfly", count = 2 },
			{ itemId = "bug_ladybug", count = 1 },
			
			-- Basic Materials (using items that exist in our mapping)
			{ itemId = "egg_purple", count = 3 },
			{ itemId = "egg_orange", count = 2 },
			{ itemId = "leaf_fossil", count = 1 },
		}
	}
	
	print("[Server] ✅ Initialized inventory for", player.Name, "with 20 starter items")
end

-- Create dropped item in the world with 3D sprite and proper tracking
local function createDroppedItem(player, itemId, count, worldPosition)
	if not ItemData[itemId] then
		warn("[Server] Unknown item:", itemId)
		return
	end
	
	local item = ItemData[itemId]
	local worldItemId = nextItemId
	nextItemId = nextItemId + 1
	
	-- Store in world items tracking
	worldItems[worldItemId] = {
		itemId = itemId,
		count = count,
		position = worldPosition,
		droppedBy = player.UserId,
		droppedAt = tick(),
		part = nil -- Will be set after part creation
	}
	
	-- Create the main part
	local part = Instance.new("Part")
	part.Name = "WorldItem_" .. worldItemId .. "_" .. item.name
	part.Size = Vector3.new(1, 1, 1)
	part.Position = worldPosition
	part.Material = Enum.Material.Neon
	part.Color = Color3.new(1, 1, 1) -- White base, sprite will show through
	part.Shape = Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.Parent = workspace
	
	-- Store part reference in world items
	worldItems[worldItemId].part = part
	
	-- Create SurfaceGui for sprite
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.Parent = part
	
	-- Create ImageLabel for sprite
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Size = UDim2.new(1, 0, 1, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "rbxassetid://74324628581851" -- Sprite sheet
	
	-- Calculate sprite position
	local offset, size = Vector2.new(0, 0), Vector2.new(36, 36) -- Default
	if item.index then
		local i0 = item.index - 1
		local col = i0 % 21
		local row = math.floor(i0 / 21)
		local x = math.floor(4 + col * (36.6 + 6) + 0.5)
		local y = math.floor(4 + row * (36.6 + 6) + 0.5)
		local spriteSize = math.floor(36.6 - 0.5 + 0.5)
		offset = Vector2.new(x + 0.25, y + 0.25)
		size = Vector2.new(spriteSize, spriteSize)
	end
	
	imageLabel.ImageRectOffset = offset
	imageLabel.ImageRectSize = size
	imageLabel.Parent = surfaceGui
	
	-- Create BillboardGui for item name
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 100, 0, 20)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.Parent = part
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name .. " x" .. count
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboardGui
	
	-- Add subtle glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.new(1, 1, 1) -- White glow to not interfere with sprite colors
	pointLight.Brightness = 0.3
	pointLight.Range = 3
	pointLight.Parent = part
	
	-- Add Region3 for automatic pickup
	local regionSize = Vector3.new(3, 3, 3)
	local regionMin = worldPosition - regionSize/2
	local regionMax = worldPosition + regionSize/2
	
	-- Function to handle pickup (anyone can pick up)
	local function pickupItem(pickingPlayer)
		print("[Server]", pickingPlayer.Name, "picked up", count, "x", item.name)
		
		-- Add item to picking player's inventory
		local inventory = playerInventories[pickingPlayer.UserId]
		if inventory then
			-- Check if player already has this item
			local found = false
			for _, invItem in ipairs(inventory.items) do
				if invItem.itemId == itemId then
					invItem.count = invItem.count + count
					found = true
					break
				end
			end
			
			if not found then
				table.insert(inventory.items, {
					itemId = itemId,
					count = count
				})
			end
			
			-- Sync inventory
			inventoryRemote:FireClient(pickingPlayer, "SyncInventory", inventory.items)
		end
		
		-- Remove from world tracking
		worldItems[worldItemId] = nil
		
		-- Remove the dropped item
		part:Destroy()
	end
	
	-- Add click detector for manual pickup
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = part
	clickDetector.MouseClick:Connect(pickupItem)
	
	-- Automatic pickup when walking over (any player)
	local RunService = game:GetService("RunService")
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not part.Parent then
			connection:Disconnect()
			return
		end
		
		-- Check if any player is nearby
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			local character = otherPlayer.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local playerPosition = character.HumanoidRootPart.Position
				local distance = (playerPosition - worldPosition).Magnitude
				
				if distance <= 3 then -- 3 stud pickup range
					pickupItem(otherPlayer)
					break -- Only one player can pick up at a time
				end
			end
		end
	end)
	
	print("[Server] ✅ Created 3D dropped item:", item.name, "x", count, "at", worldPosition)
end

-- Get all world items (for debugging/admin)
local function getAllWorldItems()
	local items = {}
	for id, item in pairs(worldItems) do
		if item.part and item.part.Parent then
			table.insert(items, {
				id = id,
				itemId = item.itemId,
				count = item.count,
				position = item.position,
				droppedBy = item.droppedBy,
				droppedAt = item.droppedAt
			})
		end
	end
	return items
end

-- Handle inventory requests
inventoryRemote.OnServerEvent:Connect(function(player, action, data)
	print("[Server] Received", action, "from", player.Name)
	local inventory = playerInventories[player.UserId]
	if not inventory then
		warn("[Server] Player inventory not found:", player.Name)
		return
	end
	
	if action == "RequestInventory" then
		print("[Server] Sending inventory to", player.Name, "with", #inventory.items, "items")
		inventoryRemote:FireClient(player, "SyncInventory", inventory.items)
		
	elseif action == "DropItem" and data then
		-- Handle item dropping
		local itemId = data.itemId
		local count = data.count
		local worldPosition = data.worldPosition or Vector3.new(0, 10, 0)
		
		print("[Server]", player.Name, "dropped", count, "x", ItemData[itemId] and ItemData[itemId].name or itemId, "at world position", worldPosition)
		
		-- Find and remove item from inventory
		for i, item in ipairs(inventory.items) do
			if item.itemId == itemId and item.count >= count then
				item.count = item.count - count
				if item.count <= 0 then
					table.remove(inventory.items, i)
				end
				
				-- Create 3D dropped item in the world
				createDroppedItem(player, itemId, count, worldPosition)
				
				-- Sync inventory to client
				inventoryRemote:FireClient(player, "SyncInventory", inventory.items)
				return
			end
		end
		
		warn("[Server]", player.Name, "tried to drop item they don't have:", itemId)
		
	elseif action == "GetWorldItems" then
		-- Debug command to see all world items
		local worldItemsList = getAllWorldItems()
		print("[Server] World items count:", #worldItemsList)
		for _, item in ipairs(worldItemsList) do
			print("[Server] - Item", item.id, ":", item.itemId, "x", item.count, "at", item.position)
		end
		inventoryRemote:FireClient(player, "WorldItemsList", worldItemsList)
	end
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
	print("[Server] Player added:", player.Name)
	player.CharacterAdded:Connect(function(character)
		print("[Server] Character added for:", player.Name)
		task.wait(1)
		print("[Server] Initializing inventory for:", player.Name)
		initializePlayerInventory(player)
		
		-- Send initial inventory to client
		local inventory = playerInventories[player.UserId]
		if inventory then
			print("[Server] Sending initial inventory to", player.Name, "with", #inventory.items, "items")
			inventoryRemote:FireClient(player, "SyncInventory", inventory.items)
		else
			warn("[Server] No inventory found for", player.Name)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerInventories[player.UserId] = nil
	print("[Server] Cleaned up inventory for", player.Name)
end)

print("[Server] ✅ Inventory system loaded and ready!")