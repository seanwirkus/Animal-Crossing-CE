-- Inventory GUI
-- Display player items with emoji icons, quantities, and item info
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local InventoryGUI = {}
InventoryGUI.__index = InventoryGUI

-- Track singleton instance
local _instance = nil

-- UI Colors
local COLORS = {
	BG_PRIMARY = Color3.fromRGB(250, 245, 235),
	BG_SECONDARY = Color3.fromRGB(255, 255, 255),
	ACCENT_BLUE = Color3.fromRGB(100, 150, 255),
	ACCENT_BROWN = Color3.fromRGB(139, 90, 43),
	TEXT_DARK = Color3.fromRGB(60, 50, 40),
	TEXT_LIGHT = Color3.fromRGB(255, 255, 255),
	QUANTITY_BG = Color3.fromRGB(255, 200, 50),
}

function InventoryGUI.new()
	-- Return existing instance if already created
	if _instance then
		print("[Inventory] ⚠️  Returning existing Inventory GUI instance")
		return _instance
	end
	
	local self = setmetatable({}, InventoryGUI)
	
	self._gui = nil
	self._visible = false
	self._initialized = false
	self._gridContainer = nil
	self._selectedItem = nil
	self._detailsEmoji = nil
	self._detailsName = nil
	self._detailsQuantity = nil
	self._detailsDescription = nil
	self._detailsSellPrice = nil
	
	self:_createGUI()
	
	_instance = self
	print("[Inventory] ✅ Inventory GUI created (singleton instance)")
	return self
end

-- Create main GUI
function InventoryGUI:_createGUI()
	if self._initialized then return end
	self._initialized = true
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = player:WaitForChild("PlayerGui")
	
	self._gui = screenGui
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0.8, 0, 0.75, 0)
	container.Position = UDim2.new(0.1, 0, 0.125, 0)
	container.BackgroundColor3 = COLORS.BG_PRIMARY
	container.BorderSizePixel = 0
	container.Parent = screenGui
	
	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0.02, 0)
	containerCorner.Parent = container
	
	-- Header
	self:_createHeader(container)
	
	-- Item slots grid
	self:_createItemGrid(container)
	
	-- Item details panel
	self:_createDetailsPanel(container)
	
	-- Close button
	self:_createCloseButton(container)
	
	-- Category filter tabs
	self:_createCategoryFilter(container)
end

-- Create header
function InventoryGUI:_createHeader(parent)
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0.1, 0)
	header.BackgroundColor3 = COLORS.ACCENT_BLUE
	header.BorderSizePixel = 0
	header.Parent = parent
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.02, 0)
	headerCorner.Parent = header
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.7, 0, 1, 0)
	title.Position = UDim2.new(0.02, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🎒 Inventory - Your Items"
	title.TextSize = 36
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = COLORS.TEXT_LIGHT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	-- Item count
	local itemCount = Instance.new("TextLabel")
	itemCount.Name = "ItemCount"
	itemCount.Size = UDim2.new(0.25, 0, 0.6, 0)
	itemCount.Position = UDim2.new(0.73, 0, 0.2, 0)
	itemCount.BackgroundColor3 = COLORS.BG_SECONDARY
	itemCount.Text = "📦 0 / 100"
	itemCount.TextSize = 20
	itemCount.Font = Enum.Font.GothamBold
	itemCount.TextColor3 = COLORS.TEXT_DARK
	itemCount.Parent = header
	
	local countCorner = Instance.new("UICorner")
	countCorner.CornerRadius = UDim.new(0.3, 0)
	countCorner.Parent = itemCount
	
	self._itemCountLabel = itemCount
end

-- Create category filter
function InventoryGUI:_createCategoryFilter(parent)
	local filterContainer = Instance.new("Frame")
	filterContainer.Name = "CategoryFilter"
	filterContainer.Size = UDim2.new(0.98, 0, 0.08, 0)
	filterContainer.Position = UDim2.new(0.01, 0, 0.11, 0)
	filterContainer.BackgroundTransparency = 1
	filterContainer.Parent = parent
	
	local filterLayout = Instance.new("UIListLayout")
	filterLayout.FillDirection = Enum.FillDirection.Horizontal
	filterLayout.Padding = UDim.new(0, 8)
	filterLayout.Parent = filterContainer
	
	local categories = {
		{name = "All", icon = "📦"},
		{name = "Tools", icon = "🔨"},
		{name = "Materials", icon = "🪵"},
		{name = "Fish", icon = "🐟"},
		{name = "Bugs", icon = "🐛"},
		{name = "Furniture", icon = "🪑"},
		{name = "Clothing", icon = "👕"},
	}
	
	for _, cat in ipairs(categories) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 120, 1, 0)
		button.BackgroundColor3 = COLORS.BG_SECONDARY
		button.Text = string.format("%s %s", cat.icon, cat.name)
		button.TextSize = 16
		button.Font = Enum.Font.GothamBold
		button.TextColor3 = COLORS.TEXT_DARK
		button.Parent = filterContainer
		
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0.2, 0)
		buttonCorner.Parent = button
		
		button.MouseButton1Click:Connect(function()
			self:_filterByCategory(cat.name)
		end)
	end
end

-- Create item grid
function InventoryGUI:_createItemGrid(parent)
	local gridContainer = Instance.new("ScrollingFrame")
	gridContainer.Name = "ItemGrid"
	gridContainer.Size = UDim2.new(0.63, 0, 0.68, 0)
	gridContainer.Position = UDim2.new(0.01, 0, 0.20, 0)
	gridContainer.BackgroundColor3 = COLORS.BG_SECONDARY
	gridContainer.BorderSizePixel = 0
	gridContainer.ScrollBarThickness = 8
	gridContainer.Parent = parent
	
	local gridCorner = Instance.new("UICorner")
	gridCorner.CornerRadius = UDim.new(0.02, 0)
	gridCorner.Parent = gridContainer
	
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
	gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	gridLayout.SortOrder = Enum.SortOrder.Name
	gridLayout.Parent = gridContainer
	
	local gridPadding = Instance.new("UIPadding")
	gridPadding.PaddingAll = UDim.new(0, 8)
	gridPadding.Parent = gridContainer
	
	self._gridContainer = gridContainer
end

-- Create details panel
function InventoryGUI:_createDetailsPanel(parent)
	local panel = Instance.new("Frame")
	panel.Name = "DetailsPanel"
	panel.Size = UDim2.new(0.35, 0, 0.68, 0)
	panel.Position = UDim2.new(0.65, 0, 0.20, 0)
	panel.BackgroundColor3 = COLORS.BG_SECONDARY
	panel.BorderSizePixel = 0
	panel.Parent = parent
	
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0.02, 0)
	panelCorner.Parent = panel
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0.08, 0)
	title.Position = UDim2.new(0, 10, 0.02, 0)
	title.BackgroundColor3 = COLORS.ACCENT_BROWN
	title.Text = "📋 Item Details"
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = COLORS.TEXT_LIGHT
	title.Parent = panel
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.2, 0)
	titleCorner.Parent = title
	
	-- Item emoji (large)
	local emoji = Instance.new("TextLabel")
	emoji.Name = "ItemEmoji"
	emoji.Size = UDim2.new(1, 0, 0.25, 0)
	emoji.Position = UDim2.new(0, 0, 0.12, 0)
	emoji.BackgroundTransparency = 1
	emoji.Text = "📦"
	emoji.TextSize = 80
	emoji.Parent = panel
	
	-- Item name
	local name = Instance.new("TextLabel")
	name.Name = "ItemName"
	name.Size = UDim2.new(1, -20, 0.1, 0)
	name.Position = UDim2.new(0, 10, 0.38, 0)
	name.BackgroundTransparency = 1
	name.Text = "Select an item"
	name.TextSize = 22
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = COLORS.TEXT_DARK
	name.TextWrapped = true
	name.Parent = panel
	
	-- Quantity
	local quantity = Instance.new("TextLabel")
	quantity.Name = "Quantity"
	quantity.Size = UDim2.new(0.4, 0, 0.08, 0)
	quantity.Position = UDim2.new(0.3, 0, 0.49, 0)
	quantity.BackgroundColor3 = COLORS.QUANTITY_BG
	quantity.Text = "x 0"
	quantity.TextSize = 24
	quantity.Font = Enum.Font.GothamBold
	quantity.TextColor3 = COLORS.TEXT_LIGHT
	quantity.Parent = panel
	
	local quantityCorner = Instance.new("UICorner")
	quantityCorner.CornerRadius = UDim.new(0.3, 0)
	quantityCorner.Parent = quantity
	
	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -20, 0.2, 0)
	description.Position = UDim2.new(0, 10, 0.59, 0)
	description.BackgroundTransparency = 1
	description.Text = "No item selected"
	description.TextSize = 16
	description.Font = Enum.Font.Gotham
	description.TextColor3 = COLORS.TEXT_DARK
	description.TextWrapped = true
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.Parent = panel
	
	-- Sell price
	local sellPrice = Instance.new("TextLabel")
	sellPrice.Name = "SellPrice"
	sellPrice.Size = UDim2.new(1, 0, 0.08, 0)
	sellPrice.Position = UDim2.new(0, 0, 0.80, 0)
	sellPrice.BackgroundTransparency = 1
	sellPrice.Text = "💰 Sell Value: 0"
	sellPrice.TextSize = 20
	sellPrice.Font = Enum.Font.GothamBold
	sellPrice.TextColor3 = COLORS.QUANTITY_BG
	sellPrice.Parent = panel
	
	-- Action buttons
	local useButton = Instance.new("TextButton")
	useButton.Name = "UseButton"
	useButton.Size = UDim2.new(0.45, 0, 0.09, 0)
	useButton.Position = UDim2.new(0.05, 0, 0.89, 0)
	useButton.BackgroundColor3 = COLORS.ACCENT_BLUE
	useButton.Text = "✨ Use"
	useButton.TextSize = 20
	useButton.Font = Enum.Font.GothamBold
	useButton.TextColor3 = COLORS.TEXT_LIGHT
	useButton.Parent = panel
	
	local useCorner = Instance.new("UICorner")
	useCorner.CornerRadius = UDim.new(0.2, 0)
	useCorner.Parent = useButton
	
	local dropButton = Instance.new("TextButton")
	dropButton.Name = "DropButton"
	dropButton.Size = UDim2.new(0.45, 0, 0.09, 0)
	dropButton.Position = UDim2.new(0.50, 0, 0.89, 0)
	dropButton.BackgroundColor3 = COLORS.ACCENT_BROWN
	dropButton.Text = "🗑️ Drop"
	dropButton.TextSize = 20
	dropButton.Font = Enum.Font.GothamBold
	dropButton.TextColor3 = COLORS.TEXT_LIGHT
	dropButton.Parent = panel
	
	local dropCorner = Instance.new("UICorner")
	dropCorner.CornerRadius = UDim.new(0.2, 0)
	dropCorner.Parent = dropButton
	
	self._detailsEmoji = emoji
	self._detailsName = name
	self._detailsQuantity = quantity
	self._detailsDescription = description
	self._detailsSellPrice = sellPrice
	self._useButton = useButton
	self._dropButton = dropButton
end

-- Create item grid (implementation moved to _createGUI)

-- Create close button
function InventoryGUI:_createCloseButton(parent)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -60, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
	closeButton.Text = "✕"
	closeButton.TextSize = 30
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = COLORS.TEXT_LIGHT
	closeButton.Parent = parent
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		self:Hide()
	end)
end

-- Filter by category
function InventoryGUI:_filterByCategory(category)
	print("[Inventory] Filter by:", category)
	self:RefreshInventory()
end

-- Load inventory from server
function InventoryGUI:RefreshInventory()
	-- Get inventory from server
	local getInventoryRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("GetPlayerInventory")
	if not getInventoryRemote then
		warn("[Inventory] GetPlayerInventory remote not found")
		return
	end
	
	local inventoryData = getInventoryRemote:InvokeServer()
	
	if not inventoryData then
		self:_showEmptyMessage()
		return
	end
	
	self._inventoryData = inventoryData
	
	-- Clear grid
	for _, child in pairs(self._gridContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- Create item slots
	local itemCount = 0
	for itemName, quantity in pairs(inventoryData.items or {}) do
		if quantity > 0 then
			self:_createItemSlot(itemName, quantity)
			itemCount = itemCount + 1
		end
	end
	
	-- Update item count
	self._itemCountLabel.Text = string.format("📦 %d / 100", itemCount)
	
	-- Update canvas size
	local layout = self._gridContainer:FindFirstChildOfClass("UIGridLayout")
	if layout then
		self._gridContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end
end

-- Create item slot
function InventoryGUI:_createItemSlot(itemName, quantity)
	local slot = Instance.new("TextButton")
	slot.Name = itemName
	slot.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	slot.BorderSizePixel = 0
	slot.AutoButtonColor = false
	slot.Parent = self._gridContainer
	
	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0.1, 0)
	slotCorner.Parent = slot
	
	-- Emoji (would get from ItemDB via remote)
	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(1, 0, 0.6, 0)
	emoji.BackgroundTransparency = 1
	emoji.Text = "📦"  -- Default, should query ItemDB
	emoji.TextSize = 48
	emoji.Parent = slot
	
	-- Quantity badge
	local quantityBadge = Instance.new("TextLabel")
	quantityBadge.Size = UDim2.new(0, 40, 0, 25)
	quantityBadge.Position = UDim2.new(1, -45, 0, 5)
	quantityBadge.BackgroundColor3 = COLORS.QUANTITY_BG
	quantityBadge.Text = "x" .. quantity
	quantityBadge.TextSize = 16
	quantityBadge.Font = Enum.Font.GothamBold
	quantityBadge.TextColor3 = COLORS.TEXT_LIGHT
	quantityBadge.Parent = slot
	
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0.3, 0)
	badgeCorner.Parent = quantityBadge
	
	-- Item name
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -10, 0.35, 0)
	name.Position = UDim2.new(0, 5, 0.62, 0)
	name.BackgroundTransparency = 1
	name.Text = itemName
	name.TextSize = 12
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = COLORS.TEXT_DARK
	name.TextWrapped = true
	name.TextScaled = true
	name.Parent = slot
	
	-- Click handler
	slot.MouseButton1Click:Connect(function()
		self:_selectItem(itemName, quantity)
	end)
	
	-- Hover effect
	slot.MouseEnter:Connect(function()
		slot.BackgroundColor3 = Color3.fromRGB(200, 220, 255)
	end)
	
	slot.MouseLeave:Connect(function()
		slot.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	end)
end

-- Show empty message
function InventoryGUI:_showEmptyMessage()
	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, 0, 0.3, 0)
	message.Position = UDim2.new(0, 0, 0.35, 0)
	message.BackgroundTransparency = 1
	message.Text = "🎒\n\nInventory is empty!\n\nCollect items by fishing, foraging, or shopping"
	message.TextSize = 24
	message.Font = Enum.Font.Gotham
	message.TextColor3 = COLORS.TEXT_DARK
	message.Parent = self._gridContainer
end

-- Select item
function InventoryGUI:_selectItem(itemName, quantity)
	self._selectedItem = {name = itemName, quantity = quantity}
	
	-- Update details panel (query ItemDB for full info)
	local getItemInfoRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("GetItemInfo")
	if getItemInfoRemote then
		local itemData = getItemInfoRemote:InvokeServer(itemName)
		if itemData then
			self._detailsEmoji.Text = itemData.emoji or "📦"
			self._detailsName.Text = itemData.name
			self._detailsQuantity.Text = "x " .. quantity
			self._detailsDescription.Text = itemData.description or "No description"
			self._detailsSellPrice.Text = string.format("💰 Sell Value: %d each", itemData.sell_price or 0)
		end
	end
	
	print("[Inventory] Selected:", itemName, "x", quantity)
end

-- Show GUI
function InventoryGUI:Show()
	self._gui.Enabled = true
	self:RefreshInventory()
	print("[Inventory] Opened")
end

-- Hide GUI
function InventoryGUI:Hide()
	self._gui.Enabled = false
	print("[Inventory] Closed")
end

-- Toggle GUI
function InventoryGUI:Toggle()
	if self._gui.Enabled then
		self:Hide()
	else
		self:Show()
	end
end

return InventoryGUI

