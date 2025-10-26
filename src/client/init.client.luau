-- Client initialization script
-- Clean client-side inventory system

print("Loading Animal Crossing client systems...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

print("[Debug] Starting InventoryClient...")

-- Embedded modules
local SpriteConfig = {}
SpriteConfig.SHEET_ASSET = "rbxassetid://74324628581851"
SpriteConfig.COLUMNS = 21
SpriteConfig.ROWS = 24
SpriteConfig.TILE = 36.6
SpriteConfig.INNER = Vector2.new(6, 6)
SpriteConfig.OUTER = Vector2.new(4, 4)
SpriteConfig.BLEED_FIX = 0.25

function SpriteConfig.GetSpriteRect(index)
	local i0 = index - 1
	local col = i0 % SpriteConfig.COLUMNS
	local row = math.floor(i0 / SpriteConfig.COLUMNS)
	local x = math.floor(SpriteConfig.OUTER.X + col * (SpriteConfig.TILE + SpriteConfig.INNER.X) + 0.5)
	local y = math.floor(SpriteConfig.OUTER.Y + row * (SpriteConfig.TILE + SpriteConfig.INNER.Y) + 0.5)
	local size = math.floor(SpriteConfig.TILE - SpriteConfig.BLEED_FIX * 2 + 0.5)
	return Vector2.new(x + SpriteConfig.BLEED_FIX, y + SpriteConfig.BLEED_FIX), Vector2.new(size, size)
end

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

print("[Debug] ✅ Modules loaded successfully")

-- Get remote event
local inventoryRemote = ReplicatedStorage:FindFirstChild("InventoryEvent")
if not inventoryRemote then
	print("[Debug] Creating InventoryEvent RemoteEvent...")
	inventoryRemote = Instance.new("RemoteEvent")
	inventoryRemote.Name = "InventoryEvent"
	inventoryRemote.Parent = ReplicatedStorage
end

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- State variables
local visible = false
local inventoryGui, inventoryFrame, inventoryItems, template

-- Clear all item slots
local function clearSlots()
	if not inventoryItems then return end
	for _, child in ipairs(inventoryItems:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Slot_") then
			child:Destroy()
		end
	end
end

-- Create empty slot template
local function createEmptySlot(slotIndex)
	if not inventoryItems or not template then return end
	
	local slot = template:Clone()
	slot.Name = "Slot_" .. slotIndex
	slot.Visible = true
	slot.Parent = inventoryItems
	
	-- Store empty slot data
	slot:SetAttribute("ItemId", nil)
	slot:SetAttribute("ItemCount", 0)
	slot:SetAttribute("SlotIndex", slotIndex)
	slot:SetAttribute("IsEmpty", true)
	
	local icon = slot:FindFirstChild("ItemIcon")
	local itemCount = slot:FindFirstChild("ItemCount")
	local itemName = slot:FindFirstChild("ItemName")
	
	-- Clear empty slot appearance (keep original styling)
	if icon then
		icon.Image = ""
	end
	
	if itemCount then
		itemCount.Text = ""
		itemCount.Visible = false
	end
	
	if itemName then
		itemName.Text = "Empty Slot"
	end
	
	-- Add subtle hover effect for empty slots
	local hoverButton = Instance.new("TextButton")
	hoverButton.Name = "HoverButton"
	hoverButton.Size = UDim2.new(1, 0, 1, 0)
	hoverButton.BackgroundTransparency = 1
	hoverButton.Text = ""
	hoverButton.Parent = slot
	
	-- Hover effects (scale only, no color changes)
	hoverButton.MouseEnter:Connect(function()
		local tweenService = game:GetService("TweenService")
		tweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 68, 0, 68) -- Slightly larger
		}):Play()
	end)
	
	hoverButton.MouseLeave:Connect(function()
		local tweenService = game:GetService("TweenService")
		tweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 64, 0, 64) -- Back to normal
		}):Play()
	end)
	
	return slot
end

-- Drag and drop variables
local draggedItem = nil
local dragConnection = nil
local originalParent = nil
local originalPosition = nil
local isDragging = false
local dragOffset = Vector2.new(0, 0)
local dragStartTime = 0

-- Tween tracking
local activeTweens = {}

-- Create an item slot with drag-and-drop functionality
local function createSlot(slotIndex, itemId, count)
	if not inventoryItems or not template then return end
	
	local slot = template:Clone()
	slot.Name = "Slot_" .. slotIndex
	slot.Visible = true
	slot.Parent = inventoryItems
	
	-- Store item data in slot
	slot:SetAttribute("ItemId", itemId)
	slot:SetAttribute("ItemCount", count)
	slot:SetAttribute("SlotIndex", slotIndex)
	slot:SetAttribute("IsEmpty", false)
	
	local icon = slot:FindFirstChild("ItemIcon")
	local itemCount = slot:FindFirstChild("ItemCount")
	local itemName = slot:FindFirstChild("ItemName")
	
	-- Set up icon with sprite
	if icon and itemId and ItemData[itemId] then
		local item = ItemData[itemId]
		local offset, size = SpriteConfig.GetSpriteRect(item.index)
		icon.Image = SpriteConfig.SHEET_ASSET
		icon.ImageRectOffset = offset
		icon.ImageRectSize = size
		icon.BackgroundTransparency = 1
		print("[Debug] 🎨 Created slot for", item.name, "at index", item.index)
	elseif icon then
		-- Clear icon for empty slots
		icon.Image = ""
	end
	
	-- Set up item count and name
	if itemCount then
		if count and count > 0 then
			itemCount.Text = tostring(count)
			itemCount.Visible = true
		else
			itemCount.Text = ""
			itemCount.Visible = false
		end
	end
	
	if itemName then
		if ItemData[itemId] then
			itemName.Text = ItemData[itemId].name
		else
			itemName.Text = "Empty Slot"
		end
	end
	
	-- Add drag-and-drop functionality using TextButton
	local dragButton = Instance.new("TextButton")
	dragButton.Name = "DragButton"
	dragButton.Size = UDim2.new(1, 0, 1, 0)
	dragButton.BackgroundTransparency = 1
	dragButton.Text = ""
	dragButton.Parent = slot
	
	-- Drag start on mouse down (only for filled slots)
	dragButton.MouseButton1Down:Connect(function()
		-- Only allow dragging if slot has an item
		if not itemId or not count or count <= 0 then
			print("[Debug] 🖱️ Cannot drag empty slot")
			return
		end
		
		print("[Debug] 🖱️ MouseButton1Down detected for", ItemData[itemId] and ItemData[itemId].name or "Unknown Item")
		
		-- Stop any existing drag
		if isDragging and draggedItem and draggedItem ~= slot then
			print("[Debug] 🖱️ Stopping previous drag")
			if dragConnection then
				dragConnection:Disconnect()
				dragConnection = nil
			end
			-- Reset previous dragged item
			if draggedItem then
				draggedItem.ZIndex = 1
				draggedItem.BackgroundTransparency = 1
				draggedItem.Position = originalPosition
				draggedItem.Size = UDim2.new(0, 64, 0, 64) -- Reset size
			end
		end
		
		isDragging = true
		draggedItem = slot
		originalParent = slot.Parent
		originalPosition = slot.Position
		dragStartTime = tick()
		
		-- Calculate offset from mouse to slot center
		local mousePos = UserInputService:GetMouseLocation()
		local slotPos = slot.AbsolutePosition
		local slotSize = slot.AbsoluteSize
		dragOffset = Vector2.new(
			mousePos.X - (slotPos.X + slotSize.X/2),
			mousePos.Y - (slotPos.Y + slotSize.Y/2)
		)
		
		-- Simple visual feedback
		slot.ZIndex = 10
		
		print("[Debug] 🖱️ Started dragging", ItemData[itemId] and ItemData[itemId].name or "Unknown Item")
		
		-- Connect mouse movement using RunService for smoother tracking
		local RunService = game:GetService("RunService")
		dragConnection = RunService.Heartbeat:Connect(function()
			if draggedItem == slot and isDragging then
				local mousePos = UserInputService:GetMouseLocation()
				local guiPos = inventoryGui.AbsolutePosition
				
				-- Apply offset for smooth dragging
				local targetPos = Vector2.new(
					mousePos.X - guiPos.X - dragOffset.X,
					mousePos.Y - guiPos.Y - dragOffset.Y
				)
				
				-- Smooth interpolation for better feel
				local currentPos = slot.Position
				local newPos = UDim2.new(0, targetPos.X, 0, targetPos.Y)
				
				-- Lerp for smooth movement
				local lerpFactor = 0.3
				slot.Position = UDim2.new(
					0, currentPos.X.Offset + (targetPos.X - currentPos.X.Offset) * lerpFactor,
					0, currentPos.Y.Offset + (targetPos.Y - currentPos.Y.Offset) * lerpFactor
				)
			end
		end)
	end)
	
	-- Drag end on mouse up - use UserInputService for better detection
	local dragEndConnection
	dragEndConnection = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging and draggedItem == slot then
			print("[Debug] 🖱️ MouseButton1Up detected for", ItemData[itemId] and ItemData[itemId].name or "Unknown Item")
			
			isDragging = false
			local mousePos = UserInputService:GetMouseLocation()
			
			-- Enhanced inventory detection with margin
			local inventoryPos = inventoryItems.AbsolutePosition
			local inventorySize = inventoryItems.AbsoluteSize
			local margin = 20 -- Extra margin for easier dropping
			
			local insideInventory = (mousePos.X >= inventoryPos.X - margin and mousePos.X <= inventoryPos.X + inventorySize.X + margin and
									mousePos.Y >= inventoryPos.Y - margin and mousePos.Y <= inventoryPos.Y + inventorySize.Y + margin)
			
			print("[Debug] 🖱️ Inside inventory:", insideInventory, "Mouse:", mousePos, "Inventory:", inventoryPos, inventorySize)
			
			-- Clean up visual effects
			local glow = slot:FindFirstChild("GlowEffect")
			if glow then
				glow:Destroy()
			end
			
			local shadow = slot:FindFirstChild("ShadowEffect")
			if shadow then
				shadow:Destroy()
			end
			
			-- Stop all active tweens for this slot
			if activeTweens[slot] then
				for _, tween in ipairs(activeTweens[slot]) do
					tween:Cancel()
				end
				activeTweens[slot] = nil
			end
			
			-- Simple cleanup
			slot.ZIndex = 1
			
			if insideInventory then
				-- Return to original position
				slot.Position = originalPosition
				print("[Debug] 📦 Returned", ItemData[itemId] and ItemData[itemId].name or "Unknown Item", "to inventory")
			else
				-- Drop item on ground with animation
				print("[Debug] 🌍 Dropped", ItemData[itemId] and ItemData[itemId].name or "Unknown Item", "on ground")
				
				-- Convert screen position to world position for ground placement
				local camera = workspace.CurrentCamera
				local screenPos = Vector2.new(mousePos.X, mousePos.Y)
				
				-- Raycast to find ground position
				local unitRay = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
				raycastParams.FilterDescendantsInstances = {camera}
				
				local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
				local worldPosition = Vector3.new(0, 10, 0) -- Default position
				
				if raycastResult then
					worldPosition = raycastResult.Position + Vector3.new(0, 1, 0)
					print("[Debug] 🌍 Ground position found:", worldPosition)
				else
					print("[Debug] 🌍 No ground found, using default position")
				end
				
				-- Send drop event to server with world position
				inventoryRemote:FireServer("DropItem", {
					itemId = itemId,
					count = count,
					screenPosition = mousePos,
					worldPosition = worldPosition
				})
				
				-- Animate item flying out
				local tweenService = game:GetService("TweenService")
				local flyTween = tweenService:Create(slot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(0, mousePos.X - inventoryGui.AbsolutePosition.X, 0, mousePos.Y - inventoryGui.AbsolutePosition.Y),
					Size = UDim2.new(0, 32, 0, 32),
					BackgroundTransparency = 0.8
				})
				flyTween:Play()
				
				-- Remove item after animation
				flyTween.Completed:Connect(function()
					slot:Destroy()
				end)
			end
			
			draggedItem = nil
			if dragConnection then
				dragConnection:Disconnect()
				dragConnection = nil
			end
			
			-- Disconnect this specific connection
			if dragEndConnection then
				dragEndConnection:Disconnect()
			end
		end
	end)
	
	-- Right-click functionality removed - focusing on crafting system
end

-- Populate inventory with server data
local function populateInventory()
	if not inventoryItems or not template then 
		print("[Debug] ❌ Cannot populate - GUI not ready")
		return 
	end
	
	template.Visible = false
	clearSlots()
	
	-- Request current inventory from server
	print("[Debug] Requesting inventory from server...")
	inventoryRemote:FireServer("RequestInventory")
end

-- Auto-populate inventory when GUI is ready
local function autoPopulateInventory()
	if inventoryItems and template then
		print("[Debug] 🚀 Auto-populating inventory...")
		populateInventory()
	end
end

-- Populate inventory with server data
local function populateInventoryFromServer(inventoryData)
	if not inventoryItems or not template then 
		print("[Debug] ❌ Cannot populate - GUI not ready")
		return 
	end
	
	template.Visible = false
	clearSlots()
	
	-- Create a full inventory grid (e.g., 5x4 = 20 slots)
	local maxSlots = 20
	local serverItems = inventoryData or {}
	
	-- Create all slots (filled and empty)
	for i = 1, maxSlots do
		local item = serverItems[i]
		if item and item.itemId and item.count and item.count > 0 then
			-- Create filled slot
			createSlot(i, item.itemId, item.count)
		else
			-- Create empty slot
			createEmptySlot(i)
		end
	end
	
	print("[Debug] ✅ Populated inventory with", #serverItems, "items and", maxSlots - #serverItems, "empty slots")
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.E then
		print("[Debug] E key pressed! Toggling inventory...")
		
		-- Try to find GUI if not found yet
		if not inventoryGui then
			inventoryGui = gui:FindFirstChild("PlayerInventoryGUI") or gui:FindFirstChild("InventoryGUI") or gui:FindFirstChild("InventoryFullGUI")
			if inventoryGui then
				print("[Debug] ✅ Found inventory GUI:", inventoryGui.Name)
				inventoryFrame = inventoryGui:FindFirstChild("InventoryFrame")
				if inventoryFrame then
					print("[Debug] ✅ Found InventoryFrame")
					inventoryItems = inventoryFrame:FindFirstChild("InventoryItems")
					if inventoryItems then
						print("[Debug] ✅ Found InventoryItems")
						template = inventoryItems:FindFirstChild("ItemSlotTemplate")
						if template then
							print("[Debug] ✅ Found ItemSlotTemplate")
							-- Hide inventory initially
							inventoryFrame.Visible = false
							print("[Debug] ✅ Inventory GUI hidden initially")
							-- Auto-populate inventory now that GUI is ready
							autoPopulateInventory()
						else
							warn("[Debug] ❌ Could not find ItemSlotTemplate")
							return
						end
					else
						warn("[Debug] ❌ Could not find InventoryItems")
						return
					end
				else
					warn("[Debug] ❌ Could not find InventoryFrame")
					return
				end
			else
				warn("[Debug] ❌ Could not find inventory GUI. Available GUIs:")
				for _, child in ipairs(gui:GetChildren()) do
					print("[Debug]   -", child.Name)
				end
				return
			end
		end
		
		-- Toggle inventory
		visible = not visible
		inventoryFrame.Visible = visible
		if visible then 
			print("[Debug] 📦 Inventory opened")
		else
			print("[Debug] 📦 Inventory closed")
		end
	end
	
	-- Debug: List world items with W key
	if input.KeyCode == Enum.KeyCode.W then
		print("[Debug] 🌍 Requesting world items...")
		inventoryRemote:FireServer("GetWorldItems")
	end
end)

-- Remote event handlers
inventoryRemote.OnClientEvent:Connect(function(action, data)
	print("[Debug] Received remote event:", action, "Data type:", type(data))
	if action == "SyncInventory" then
		print("[Debug] ✅ Inventory synced with", #data, "items")
		for i, item in ipairs(data) do
			print("[Debug] Item", i, ":", item.itemId, "x", item.count)
		end
		-- Refresh the inventory display with server data
		print("[Debug] Refreshing inventory display...")
		populateInventoryFromServer(data)
		
	elseif action == "WorldItemsList" then
		print("[Debug] 🌍 World items received:", #data, "items")
		for _, item in ipairs(data) do
			print("[Debug] - World Item", item.id, ":", item.itemId, "x", item.count, "at", item.position)
		end
	else
		print("[Debug] Unknown action:", action)
	end
end)

print("[Debug] ✅ InventoryClient ready!")
print("[Debug] 🎮 Press E to toggle inventory")

print("✅ Animal Crossing client systems loaded!")