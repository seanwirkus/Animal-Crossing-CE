-- ============================================================================
-- INVENTORY STYLING MODULE
-- ============================================================================
-- Central place to customize all inventory visual styling
-- Change colors, transparency, and effects here - no need to dig through code!
-- ============================================================================

local InventoryStyling = {}

-- ============================================================================
-- SLOT COLORS
-- ============================================================================
InventoryStyling.Slot = {
	DefaultBackgroundColor = Color3.fromRGB(200, 200, 200),
	DefaultBackgroundTransparency = 0.2,
	HoverBackgroundColor = Color3.fromRGB(4, 175, 166),      -- Teal/cyan
	HoverBackgroundTransparency = 0.1,
	BorderColor = Color3.fromRGB(100, 100, 100),
	BorderSizePixel = 1,
}

-- ============================================================================
-- ITEM ICON STYLING
-- ============================================================================
InventoryStyling.ItemIcon = {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
}

-- ============================================================================
-- ITEM COUNT BADGE STYLING
-- ============================================================================
InventoryStyling.ItemCount = {
	TextColor = Color3.fromRGB(255, 255, 255),
	BackgroundColor = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.3,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Visible = true,
}

-- ============================================================================
-- ITEM NAME LABEL STYLING
-- ============================================================================
InventoryStyling.ItemName = {
	TextColor = Color3.fromRGB(0, 0, 0),
	BackgroundColor = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.5,
	TextSize = 14,
	Font = Enum.Font.Gotham,
	Visible = false,  -- Hidden by default on hover
}

-- ============================================================================
-- GHOST ITEM STYLING (During Drag)
-- ============================================================================
InventoryStyling.GhostItem = {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 250,
	Size = UDim2.new(0, 64, 0, 64),
	AnchorPoint = Vector2.new(0.5, 0.5),
}

-- ============================================================================
-- INVENTORY FRAME STYLING
-- ============================================================================
InventoryStyling.InventoryFrame = {
	BackgroundColor = Color3.fromRGB(220, 220, 220),
	BackgroundTransparency = 0.05,
	BorderColor = Color3.fromRGB(100, 100, 100),
	BorderSizePixel = 1,
}

-- ============================================================================
-- DRAG LAYER STYLING
-- ============================================================================
InventoryStyling.DragLayer = {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 200,
}

-- ============================================================================
-- ANIMATION SETTINGS
-- ============================================================================
InventoryStyling.Animation = {
	-- Set to 0 for instant, increase for slower animations
	HoverDuration = 0,           -- Duration of hover effect tween
	DragDuration = 0,            -- Duration of drag appearance tween
	DropDuration = 0,            -- Duration of drop animation
	EasingStyle = Enum.EasingStyle.Sine,
	EasingDirection = Enum.EasingDirection.Out,
}

-- ============================================================================
-- HELPER FUNCTION: Apply Slot Styling
-- ============================================================================
function InventoryStyling.ApplySlotStyling(slot)
	if not slot then return end
	
	slot.BackgroundColor3 = InventoryStyling.Slot.DefaultBackgroundColor
	slot.BackgroundTransparency = InventoryStyling.Slot.DefaultBackgroundTransparency
	slot.BorderColor3 = InventoryStyling.Slot.BorderColor
	slot.BorderSizePixel = InventoryStyling.Slot.BorderSizePixel
end

-- ============================================================================
-- HELPER FUNCTION: Apply Hover Styling
-- ============================================================================
function InventoryStyling.ApplyHoverStyling(slot)
	if not slot then return end
	
	slot.BackgroundColor3 = InventoryStyling.Slot.HoverBackgroundColor
	slot.BackgroundTransparency = InventoryStyling.Slot.HoverBackgroundTransparency
end

-- ============================================================================
-- HELPER FUNCTION: Reset Slot Styling (Remove Hover)
-- ============================================================================
function InventoryStyling.ResetSlotStyling(slot)
	if not slot then return end
	
	slot.BackgroundColor3 = InventoryStyling.Slot.DefaultBackgroundColor
	slot.BackgroundTransparency = InventoryStyling.Slot.DefaultBackgroundTransparency
end

-- ============================================================================
-- HELPER FUNCTION: Apply Item Count Styling
-- ============================================================================
function InventoryStyling.ApplyItemCountStyling(itemCountLabel)
	if not itemCountLabel then return end
	
	itemCountLabel.TextColor3 = InventoryStyling.ItemCount.TextColor
	itemCountLabel.BackgroundColor3 = InventoryStyling.ItemCount.BackgroundColor
	itemCountLabel.BackgroundTransparency = InventoryStyling.ItemCount.BackgroundTransparency
	itemCountLabel.TextSize = InventoryStyling.ItemCount.TextSize
	itemCountLabel.Font = InventoryStyling.ItemCount.Font
end

-- ============================================================================
-- HELPER FUNCTION: Apply Item Name Styling
-- ============================================================================
function InventoryStyling.ApplyItemNameStyling(itemNameLabel)
	if not itemNameLabel then return end
	
	itemNameLabel.TextColor3 = InventoryStyling.ItemName.TextColor
	itemNameLabel.BackgroundColor3 = InventoryStyling.ItemName.BackgroundColor
	itemNameLabel.BackgroundTransparency = InventoryStyling.ItemName.BackgroundTransparency
	itemNameLabel.TextSize = InventoryStyling.ItemName.TextSize
	itemNameLabel.Font = InventoryStyling.ItemName.Font
end

-- ============================================================================
-- HELPER FUNCTION: Convert Hex to RGB
-- Usage: InventoryStyling.HexToRGB("04AFA6")
-- ============================================================================
function InventoryStyling.HexToRGB(hexColor)
	local hex = hexColor:gsub("#", "")
	return Color3.fromRGB(
		tonumber(hex:sub(1, 2), 16),
		tonumber(hex:sub(3, 4), 16),
		tonumber(hex:sub(5, 6), 16)
	)
end

-- ============================================================================
-- HELPER FUNCTION: Create TweenInfo with Styling Settings
-- ============================================================================
function InventoryStyling.CreateTweenInfo(duration)
	duration = duration or InventoryStyling.Animation.HoverDuration
	return TweenInfo.new(
		duration,
		InventoryStyling.Animation.EasingStyle,
		InventoryStyling.Animation.EasingDirection
	)
end

return InventoryStyling
