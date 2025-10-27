-- Client initialization script
-- Clean client-side inventory system

print("Loading Animal Crossing client systems...")

-- ============================================================================
-- GUI REQUIREMENTS AND NOTES FOR DEVELOPER
-- ============================================================================
-- This script handles LOGIC ONLY for the inventory system.
-- You must create the following GUI elements in Roblox Studio:
--
-- 1. INVENTORY STRUCTURE (REQUIRED):
--    - InventoryGUI (ScreenGui)
--      - InventoryFrame (Frame)
--        - InventoryItems (ScrollingFrame or Frame)
--          - ItemSlotTemplate (Frame) - A template slot with these children:
--            * ItemIcon (ImageLabel)
--            * ItemCount (TextLabel) 
--            * ItemName (TextLabel)
--
-- 2. STATUS/HEALTH SYSTEM (TO BE CREATED):
--    - Create a StatusBar or HealthBar GUI in your InventoryGUI
--    - Add attributes: "MaxHealth", "CurrentHealth"
--    - This script will call methods to update it (placeholder for future)
--    - TODO: Reference it as: inventoryGui:FindFirstChild("StatusBar") or similar
--
-- 3. STATUS EFFECTS DISPLAY (TO BE CREATED):
--    - Create a StatusEffectsContainer Frame in InventoryGUI
--    - This will show active buffs/debuffs on the player
--    - TODO: Implement rendering logic when container exists
--
-- 4. EQUIPMENT SLOTS (OPTIONAL):
--    - Create EquipmentFrame in InventoryGUI if you want equipment system
--    - Add slots for: Head, Body, Hands, Feet, Accessories
--    - TODO: Logic ready, awaiting GUI implementation
--
-- The script will search for these in PlayerGui automatically.
-- If any required GUI element is missing, it will print a warning and disable that feature.
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

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

-- Visual ambience helpers
local function ensureLightingPalette()
    local function ensureEffect(className, name)
        local effect = Lighting:FindFirstChild(name)
        if not effect then
            effect = Instance.new(className)
            effect.Name = name
            effect.Parent = Lighting
        end
        return effect
    end

    Lighting.Brightness = 3
    Lighting.EnvironmentDiffuseScale = 0.7
    Lighting.EnvironmentSpecularScale = 0.85
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 180, 220)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 235, 200)

    local colorCorrection = ensureEffect("ColorCorrectionEffect", "InventoryColorCorrection")
    colorCorrection.Brightness = 0.1
    colorCorrection.Contrast = 0.08
    colorCorrection.Saturation = 0.35
    colorCorrection.TintColor = Color3.fromRGB(248, 244, 224)

    local bloom = ensureEffect("BloomEffect", "InventoryBloom")
    bloom.Intensity = 0.7
    bloom.Size = 25
    bloom.Threshold = 1.8

    local sunRays = ensureEffect("SunRaysEffect", "InventorySunRays")
    sunRays.Intensity = 0.3
    sunRays.Spread = 1

    local depthOfField = ensureEffect("DepthOfFieldEffect", "InventoryDepthOfField")
    depthOfField.FarIntensity = 0.35
    depthOfField.FocusDistance = 35
    depthOfField.InFocusRadius = 30
    depthOfField.NearIntensity = 0.1
end

ensureLightingPalette()

-- State variables
local visible = false
local inventoryGui, inventoryFrame, inventoryItems, template
local dragLayer
local blurEffect
local slotsByIndex = {}
local slotState = {}
local maxSlots = 0
local dragInfo = nil

local refreshSlot
local beginDrag
local finishDrag



-- ============================================================================
-- STATUS BAR / HEALTH BAR SYSTEM (TO BE IMPLEMENTED IN ROBLOX STUDIO)
-- ============================================================================
-- TODO: The following functions expect you to create a StatusBar GUI in Roblox Studio
-- Located at: PlayerGui > InventoryGUI > StatusBar
-- The StatusBar should contain a Fill frame and support these attributes:
--   - MaxHealth (Number)
--   - CurrentHealth (Number)
--
-- Once you create the StatusBar GUI, uncomment the functions below and they will
-- automatically update when player health changes.
-- ============================================================================

local function updateHealthBar(currentHealth, maxHealth)
	-- LOGIC READY: This function is called when player health changes
	-- Create StatusBar GUI in Roblox Studio with a Fill frame to use this
	-- Example structure: InventoryGUI > StatusBar > Fill
	if not inventoryGui then
		return
	end
	
	local statusBar = inventoryGui:FindFirstChild("StatusBar")
	if statusBar then
		local fillFrame = statusBar:FindFirstChild("Fill")
		if fillFrame then
			local healthPercent = currentHealth / maxHealth
			-- Animate the fill frame to the correct size
			TweenService:Create(fillFrame, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Size = UDim2.new(healthPercent, 0, 1, 0)
			}):Play()
		end
		
		local healthText = statusBar:FindFirstChild("HealthText")
		if healthText then
			healthText.Text = math.floor(currentHealth) .. " / " .. maxHealth
		end
	end
end

local function updateStatusEffects(effectsList)
	-- LOGIC READY: This function is called when status effects change
	-- Create StatusEffectsContainer GUI in Roblox Studio to use this
	-- effectsList is a table: { {name="Buff1", duration=5}, {name="Debuff1", duration=3} }
	-- You'll need to render icons for each effect
	if not inventoryGui then
		return
	end
	
	local effectsContainer = inventoryGui:FindFirstChild("StatusEffectsContainer")
	if effectsContainer then
		-- Clear existing effects display
		for _, child in ipairs(effectsContainer:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "UIGridLayout" then
				child:Destroy()
			end
		end
		
		-- TODO: Create and add effect icons based on effectsList
		-- This awaits proper GUI setup in Roblox Studio
	end
end

local function ensureBlurEffect()
    if blurEffect and blurEffect.Parent then
        return blurEffect
    end

    blurEffect = Lighting:FindFirstChild("InventoryBlur")
    if not blurEffect then
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Name = "InventoryBlur"
        blurEffect.Size = 0
        blurEffect.Enabled = false
        blurEffect.Parent = Lighting
    end

    return blurEffect
end

local function ensureDragLayer()
	if not inventoryGui then
		return nil
	end

    if dragLayer and dragLayer.Parent then
        return dragLayer
    end

    dragLayer = inventoryGui:FindFirstChild("InventoryDragLayer")
    if not dragLayer then
        dragLayer = Instance.new("Frame")
        dragLayer.Name = "InventoryDragLayer"
        dragLayer.Size = UDim2.fromScale(1, 1)
        dragLayer.BackgroundTransparency = 1
        dragLayer.BorderSizePixel = 0
        dragLayer.ZIndex = 200
        dragLayer.Parent = inventoryGui
    end

	return dragLayer
end

local function setItemNameLabelText(label, text)
	if not label or not label:IsA("TextLabel") then
		return
	end

	local baseWidthOffset = label:GetAttribute("AutoWidthBaseOffset")
	local baseWidthScale = label:GetAttribute("AutoWidthBaseScale")
	if baseWidthOffset == nil or baseWidthScale == nil then
		baseWidthOffset = label.Size.X.Offset
		baseWidthScale = label.Size.X.Scale
		label:SetAttribute("AutoWidthBaseOffset", baseWidthOffset)
		label:SetAttribute("AutoWidthBaseScale", baseWidthScale)
		label:SetAttribute("AutoHeightOffset", label.Size.Y.Offset)
		label:SetAttribute("AutoHeightScale", label.Size.Y.Scale)
	end

	local padding = label:GetAttribute("AutoWidthPadding")
	if padding == nil then
		padding = 24
		label:SetAttribute("AutoWidthPadding", padding)
	end

	local minWidth = label:GetAttribute("AutoWidthMin")
	if minWidth == nil then
		if baseWidthScale ~= 0 then
			minWidth = math.max(baseWidthOffset, 0)
		else
			minWidth = math.max(baseWidthOffset, 60)
		end
		label:SetAttribute("AutoWidthMin", minWidth)
	end

	local displayText = text ~= "" and text or " "
	local textSize = label.TextSize > 0 and label.TextSize or 14
	local measured = TextService:GetTextSize(displayText, textSize, label.Font, Vector2.new(1000, textSize))
	local widthOffset = math.max(measured.X + padding, minWidth)

	local heightScale = label:GetAttribute("AutoHeightScale") or label.Size.Y.Scale
	local heightOffset = label:GetAttribute("AutoHeightOffset") or label.Size.Y.Offset

	if baseWidthScale == 0 then
		label.Size = UDim2.new(0, widthOffset, heightScale, heightOffset)
	else
		label.Size = UDim2.new(baseWidthScale, baseWidthOffset, heightScale, heightOffset)
	end

	label.Text = text
end

local function setInventoryVisible(shouldShow)
        if not inventoryFrame then
                return
        end

        visible = shouldShow
        
        -- Ensure GUI is enabled when showing inventory
        if shouldShow and inventoryGui then
                inventoryGui.Enabled = true
        end
        
        inventoryFrame.Visible = visible

        if not visible and dragInfo then
                finishDrag(UserInputService:GetMouseLocation(), true)
        end
end

local function copySlotData(data)
    if not data then
        return nil
    end

    return {
        itemId = data.itemId,
        count = data.count,
    }
end

-- ============================================================================
-- INVENTORY STYLING MODULE (Embedded)
-- ============================================================================
-- Central place to customize all inventory visual styling
local InventoryStyling = {}

InventoryStyling.Slot = {
	DefaultBackgroundColor = Color3.fromRGB(200, 200, 200),
	DefaultBackgroundTransparency = 0.2,
	HoverBackgroundColor = Color3.fromRGB(4, 175, 166),      -- Teal/cyan
	HoverBackgroundTransparency = 0.1,
	BorderColor = Color3.fromRGB(100, 100, 100),
	BorderSizePixel = 1,
}

InventoryStyling.ItemIcon = {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
}

InventoryStyling.ItemCount = {
	TextColor = Color3.fromRGB(255, 255, 255),
	BackgroundColor = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.3,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Visible = true,
}

InventoryStyling.ItemName = {
	TextColor = Color3.fromRGB(0, 0, 0),
	BackgroundColor = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.5,
	TextSize = 14,
	Font = Enum.Font.Gotham,
	Visible = false,
}

InventoryStyling.GhostItem = {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 250,
	Size = UDim2.new(0, 64, 0, 64),
	AnchorPoint = Vector2.new(0.5, 0.5),
}

InventoryStyling.InventoryFrame = {
	BackgroundColor = Color3.fromRGB(220, 220, 220),
	BackgroundTransparency = 0.05,
	BorderColor = Color3.fromRGB(100, 100, 100),
	BorderSizePixel = 1,
}

InventoryStyling.DragLayer = {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 200,
}

InventoryStyling.Animation = {
	HoverDuration = 0,
	DragDuration = 0,
	DropDuration = 0,
	EasingStyle = Enum.EasingStyle.Sine,
	EasingDirection = Enum.EasingDirection.Out,
}

function InventoryStyling.ApplySlotStyling(slot)
	if not slot then return end
	slot.BackgroundColor3 = InventoryStyling.Slot.DefaultBackgroundColor
	slot.BackgroundTransparency = InventoryStyling.Slot.DefaultBackgroundTransparency
	slot.BorderColor3 = InventoryStyling.Slot.BorderColor
	slot.BorderSizePixel = InventoryStyling.Slot.BorderSizePixel
end

function InventoryStyling.ApplyHoverStyling(slot)
	if not slot then return end
	slot.BackgroundColor3 = InventoryStyling.Slot.HoverBackgroundColor
	slot.BackgroundTransparency = InventoryStyling.Slot.HoverBackgroundTransparency
end

function InventoryStyling.ResetSlotStyling(slot)
	if not slot then return end
	slot.BackgroundColor3 = InventoryStyling.Slot.DefaultBackgroundColor
	slot.BackgroundTransparency = InventoryStyling.Slot.DefaultBackgroundTransparency
end

function InventoryStyling.ApplyItemCountStyling(itemCountLabel)
	if not itemCountLabel then return end
	itemCountLabel.TextColor3 = InventoryStyling.ItemCount.TextColor
	itemCountLabel.BackgroundColor3 = InventoryStyling.ItemCount.BackgroundColor
	itemCountLabel.BackgroundTransparency = InventoryStyling.ItemCount.BackgroundTransparency
	itemCountLabel.TextSize = InventoryStyling.ItemCount.TextSize
	itemCountLabel.Font = InventoryStyling.ItemCount.Font
end

function InventoryStyling.ApplyItemNameStyling(itemNameLabel)
	if not itemNameLabel then return end
	itemNameLabel.TextColor3 = InventoryStyling.ItemName.TextColor
	itemNameLabel.BackgroundColor3 = InventoryStyling.ItemName.BackgroundColor
	itemNameLabel.BackgroundTransparency = InventoryStyling.ItemName.BackgroundTransparency
	itemNameLabel.TextSize = InventoryStyling.ItemName.TextSize
	itemNameLabel.Font = InventoryStyling.ItemName.Font
end

function InventoryStyling.HexToRGB(hexColor)
	local hex = hexColor:gsub("#", "")
	return Color3.fromRGB(
		tonumber(hex:sub(1, 2), 16),
		tonumber(hex:sub(3, 4), 16),
		tonumber(hex:sub(5, 6), 16)
	)
end

function InventoryStyling.CreateTweenInfo(duration)
	duration = duration or InventoryStyling.Animation.HoverDuration
	return TweenInfo.new(
		duration,
		InventoryStyling.Animation.EasingStyle,
		InventoryStyling.Animation.EasingDirection
	)
end

local function updateSlotAppearance(slot, state, options)
    if not slot then
        return
    end

    local icon = slot:FindFirstChild("ItemIcon")
    local itemCountLabel = slot:FindFirstChild("ItemCount")
    local itemNameLabel = slot:FindFirstChild("ItemName")
    
    if state and state.itemId and ItemData[state.itemId] then
        local item = ItemData[state.itemId]
        if icon then
            local offset, size = SpriteConfig.GetSpriteRect(item.index)
            icon.Image = SpriteConfig.SHEET_ASSET
            icon.ImageRectOffset = offset
            icon.ImageRectSize = size
        end

        if itemCountLabel then
            if state.count and state.count > 1 then
                itemCountLabel.Text = tostring(state.count)
                itemCountLabel.Visible = true
            else
                itemCountLabel.Text = ""
                itemCountLabel.Visible = false
            end
        end
        
        -- Set item name for hover display (do NOT style it, just set text)
        if itemNameLabel then
            itemNameLabel.Text = item.name
            itemNameLabel.Visible = false  -- Keep hidden until hover
        end
    else
        if icon then
            icon.Image = ""
        end
        if itemCountLabel then
            itemCountLabel.Text = ""
            itemCountLabel.Visible = false
        end
        if itemNameLabel then
            itemNameLabel.Text = ""
            itemNameLabel.Visible = false  -- Hide name label for empty slots
        end
    end
end

local function configureSlotFrame(slot, slotIndex)
	slot:SetAttribute("SlotIndex", slotIndex)
	if slot:GetAttribute("Configured") then
		return
	end

	slot:SetAttribute("Configured", true)

	local clickButton = Instance.new("TextButton")
	clickButton.Name = "ClickButton"
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.ZIndex = slot.ZIndex + 1
	clickButton.Parent = slot

	-- Hover effects - NO background color changes, just show item name
	clickButton.MouseEnter:Connect(function()
		-- Show item name on hover ONLY if slot has an item
		local itemNameLabel = slot:FindFirstChild("ItemName")
		if itemNameLabel and itemNameLabel.Text ~= "" then
			itemNameLabel.Visible = true
		end
	end)

	clickButton.MouseLeave:Connect(function()
		-- Hide item name when not hovering
		local itemNameLabel = slot:FindFirstChild("ItemName")
		if itemNameLabel then
			itemNameLabel.Visible = false
		end
	end)

	clickButton.MouseButton1Down:Connect(function()
		if dragInfo then
			-- Already holding an item - try to drop it here
			finishDrag(UserInputService:GetMouseLocation(), false)
		else
			-- Pick up the item
			local state = slotState[slotIndex]
			if not state then
				return
			end
			beginDrag(slotIndex)
		end
	end)
end

local function ensureSlot(slotIndex)
    if not inventoryItems or not template then
        return nil
    end

    local slot = slotsByIndex[slotIndex]
    if slot and slot.Parent then
        slot.Visible = true
        configureSlotFrame(slot, slotIndex)
        return slot
    end

    slot = template:Clone()
    slot.Name = "Slot_" .. slotIndex
    slot.Visible = true
    slot.Parent = inventoryItems
    slotsByIndex[slotIndex] = slot
    configureSlotFrame(slot, slotIndex)
    return slot
end

function refreshSlot(slotIndex)
    local slot = ensureSlot(slotIndex)
    if not slot then
        return
    end

    slot.Size = UDim2.new(0, 64, 0, 64)
    local state = slotState[slotIndex]
    updateSlotAppearance(slot, state, { placeholder = false })
end

local function getSlotUnderPoint(point, excludeIndex)
    if not inventoryItems then
        return nil
    end

    -- Only check slots that have items (with non-empty state)
    local validSlots = {}
    for index, slot in pairs(slotsByIndex) do
        if slot and slot.Parent and index ~= excludeIndex then
            table.insert(validSlots, index)
        end
    end

    -- Only return a slot if cursor is directly over it (strict bounds checking)
    for _, index in ipairs(validSlots) do
        local slot = slotsByIndex[index]
        local pos = slot.AbsolutePosition
        local size = slot.AbsoluteSize
        
        -- Check if point is strictly within slot bounds (no tolerance, no fallback)
        if point.X >= pos.X and point.X < pos.X + size.X and 
           point.Y >= pos.Y and point.Y < pos.Y + size.Y then
            return index
        end
    end

    -- If not directly over any slot, return nil (don't fallback to closest)
    return nil
end

-- Helper function to handle dropping items to ground
local function dropItemToGround(info, mousePosition)
    slotState[info.slotIndex] = nil
    refreshSlot(info.slotIndex)

    local camera = workspace.CurrentCamera
    local screenPos = Vector2.new(mousePosition.X, mousePosition.Y)
    local unitRay = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = { camera }

    local character = player.Character
    if character then
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("BasePart") then
                table.insert(raycastParams.FilterDescendantsInstances, descendant)
            end
        end
    end

    -- Primary raycast from camera through mouse position
    local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
    local worldPosition = Vector3.new(0, 1, 0)
    
    if raycastResult then
        worldPosition = raycastResult.Position + Vector3.new(0, 0.5, 0)
    else
        -- Fallback: find ground below camera
        local cameraPos = camera.CFrame.Position
        local groundRaycast = workspace:Raycast(cameraPos, Vector3.new(0, -500, 0), raycastParams)
        if groundRaycast then
            worldPosition = groundRaycast.Position + Vector3.new(0, 0.5, 0)
        else
            -- Last resort: drop slightly in front of camera
            local lookDir = camera.CFrame.LookVector
            worldPosition = cameraPos + lookDir * 10 + Vector3.new(0, -2, 0)
        end
    end

    inventoryRemote:FireServer("DropItem", {
        itemId = info.state.itemId,
        count = info.state.count,
        slotIndex = info.slotIndex,
        screenPosition = screenPos,
        worldPosition = worldPosition,
    })
end

function beginDrag(slotIndex)
    if dragInfo then
        finishDrag(UserInputService:GetMouseLocation(), true)
    end

    local slot = slotsByIndex[slotIndex]
    local state = slotState[slotIndex]
    if not slot or not state then
        return
    end

    -- Create simple ghost item (just clone the slot)
    local ghost = template:Clone()
    ghost.Name = "DragGhost"
    ghost.Visible = true
    ghost.AnchorPoint = Vector2.new(0.5, 0.5)
    ghost.Size = UDim2.new(0, 64, 0, 64)
    ghost.BackgroundTransparency = 0.3  -- Make it slightly transparent so you can see through
    ghost.BackgroundColor3 = Color3.fromRGB(200, 200, 200)  -- Light gray background
    ghost.BorderSizePixel = 2
    ghost.BorderColor3 = Color3.fromRGB(100, 100, 100)
    ghost.ZIndex = 250

    -- Remove interactive elements from ghost
    for _, child in ipairs(ghost:GetChildren()) do
        if child.Name == "ClickButton" or child.Name == "HoverButton" or child.Name == "DragButton" then
            child:Destroy()
        end
    end

    ghost.Parent = ensureDragLayer()
    updateSlotAppearance(ghost, state, { isGhost = true })

    dragInfo = {
        slotIndex = slotIndex,
        state = copySlotData(state),
        ghost = ghost,
        mouseConnection = nil,
    }

    -- Track mouse and follow cursor
    dragInfo.mouseConnection = RunService.RenderStepped:Connect(function()
        if not dragInfo or not dragInfo.ghost or not dragInfo.ghost.Parent then
            return
        end

        local mousePos = UserInputService:GetMouseLocation()
        
        if dragInfo.ghost.Parent and inventoryGui then
            dragInfo.ghost.Position = UDim2.fromOffset(
                mousePos.X - inventoryGui.AbsolutePosition.X,
                mousePos.Y - inventoryGui.AbsolutePosition.Y
            )
        end
    end)
end

function finishDrag(mousePos, cancelled)
    local info = dragInfo
    if not info then
        return
    end

    if info.mouseConnection then
        info.mouseConnection:Disconnect()
        info.mouseConnection = nil
    end

    -- Instantly destroy ghost
    if info.ghost then
        info.ghost:Destroy()
    end

    -- If cancelled, restore item to original slot
    if cancelled then
        slotState[info.slotIndex] = copySlotData(info.state)
        refreshSlot(info.slotIndex)
        dragInfo = nil
        return
    end

    local mousePosition = mousePos or UserInputService:GetMouseLocation()
    
    -- Allow swap even with minimal movement - user just needs to click and it attaches to cursor
    -- No minimum drag distance requirement

    -- Check if dropping in inventory area
    local insideInventorySlots = false
    if inventoryItems then
        local invPos = inventoryItems.AbsolutePosition
        local invSize = inventoryItems.AbsoluteSize
        local margin = 32
        if mousePosition.X >= invPos.X - margin and mousePosition.X <= invPos.X + invSize.X + margin and mousePosition.Y >= invPos.Y - margin and mousePosition.Y <= invPos.Y + invSize.Y + margin then
            insideInventorySlots = true
        end
    end

    if insideInventorySlots then
        -- Dropping within inventory - swap or move
        local targetIndex = getSlotUnderPoint(mousePosition, info.slotIndex)
        
        -- Only perform swap if we found a valid target that's different from source
        if targetIndex and targetIndex ~= info.slotIndex then
            -- Extra safeguard: make sure cursor is actually over the target slot
            local targetSlot = slotsByIndex[targetIndex]
            if targetSlot and targetSlot.Parent then
                local targetPos = targetSlot.AbsolutePosition
                local targetSize = targetSlot.AbsoluteSize
                
                -- Check if cursor is actually within target slot bounds (with 5px tolerance)
                local tolerance = 5
                local isOverTarget = mousePosition.X >= targetPos.X - tolerance and 
                                     mousePosition.X < targetPos.X + targetSize.X + tolerance and 
                                     mousePosition.Y >= targetPos.Y - tolerance and 
                                     mousePosition.Y < targetPos.Y + targetSize.Y + tolerance
                
                if isOverTarget then
                    local targetState = slotState[targetIndex]
                    
                    if targetState then
                        -- Swap items
                        local originalTarget = copySlotData(targetState)
                        slotState[targetIndex] = copySlotData(info.state)
                        slotState[info.slotIndex] = originalTarget
                        
                        refreshSlot(targetIndex)
                        refreshSlot(info.slotIndex)
                        
                        inventoryRemote:FireServer("MoveItem", {
                            fromIndex = info.slotIndex,
                            toIndex = targetIndex,
                            swap = true,
                        })
                    else
                        -- Empty slot - just move
                        slotState[info.slotIndex] = nil
                        slotState[targetIndex] = copySlotData(info.state)
                        refreshSlot(info.slotIndex)
                        refreshSlot(targetIndex)
                        
                        inventoryRemote:FireServer("MoveItem", {
                            fromIndex = info.slotIndex,
                            toIndex = targetIndex,
                            swap = false,
                        })
                    end
                else
                    -- Mouse not actually over target slot, restore item to original
                    slotState[info.slotIndex] = copySlotData(info.state)
                    refreshSlot(info.slotIndex)
                end
            end
        else
            -- Dropped in inventory area but not on a slot - drop to ground
            dropItemToGround(info, mousePosition)
        end
    else
        -- Dropped outside inventory - drop to ground
        dropItemToGround(info, mousePosition)
    end

    dragInfo = nil
end

-- Helper function to handle dropping items to ground
local function dropItemToGround(info, mousePosition)
    slotState[info.slotIndex] = nil
    refreshSlot(info.slotIndex)

    local camera = workspace.CurrentCamera
    local screenPos = Vector2.new(mousePosition.X, mousePosition.Y)
    local unitRay = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = { camera }

    local character = player.Character
    if character then
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("BasePart") then
                table.insert(raycastParams.FilterDescendantsInstances, descendant)
            end
        end
    end

    -- Primary raycast from camera through mouse position
    local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
    local worldPosition = Vector3.new(0, 1, 0)
    
    if raycastResult then
        worldPosition = raycastResult.Position + Vector3.new(0, 0.5, 0)
    else
        -- Fallback: find ground below camera
        local cameraPos = camera.CFrame.Position
        local groundRaycast = workspace:Raycast(cameraPos, Vector3.new(0, -500, 0), raycastParams)
        if groundRaycast then
            worldPosition = groundRaycast.Position + Vector3.new(0, 0.5, 0)
        else
            -- Last resort: drop slightly in front of camera
            local lookDir = camera.CFrame.LookVector
            worldPosition = cameraPos + lookDir * 10 + Vector3.new(0, -2, 0)
        end
    end

    inventoryRemote:FireServer("DropItem", {
        itemId = info.state.itemId,
        count = info.state.count,
        slotIndex = info.slotIndex,
        screenPosition = screenPos,
        worldPosition = worldPosition,
    })
end

UserInputService.InputEnded:Connect(function(input)
    -- In two-click mode, allow mouse release to drop item to ground if not clicking on a slot
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragInfo then
        -- Mouse released while holding item - drop it to ground
        local mousePosition = UserInputService:GetMouseLocation()
        finishDrag(mousePosition)
    end
end)

-- Populate inventory with server data
local function populateInventory()
        if not inventoryItems or not template then
                print("[Debug] ❌ Cannot populate - GUI not ready")
                return
        end

        template.Visible = false

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
                print("[Debug] ❌ Cannot populate - GUI not ready, will retry when GUI is available")
                -- Store the data to populate later when GUI is ready
                if inventoryData then
                        _G.pendingInventoryData = inventoryData
                end
                return
        end

        template.Visible = false

        if dragInfo then
                finishDrag(UserInputService:GetMouseLocation(), true)
        end

        local receivedSlots = {}
        local newMaxSlots = 20

        if typeof(inventoryData) == "table" then
                if inventoryData.maxSlots then
                        newMaxSlots = inventoryData.maxSlots
                end

                if inventoryData.slots then
                        for index, slot in pairs(inventoryData.slots) do
                                receivedSlots[index] = slot
                        end
                else
                        for index, slot in ipairs(inventoryData) do
                                receivedSlots[index] = slot
                        end
                        if #inventoryData > newMaxSlots then
                                newMaxSlots = #inventoryData
                        end
                end
        end

        maxSlots = newMaxSlots

        local filled = 0
        for index = 1, maxSlots do
                local slotData = receivedSlots[index]
                if slotData and slotData.itemId and slotData.count and slotData.count > 0 then
                        slotState[index] = {
                                itemId = slotData.itemId,
                                count = slotData.count,
                        }
                        filled = filled + 1
                else
                        slotState[index] = nil
                end

                refreshSlot(index)
        end

        for index, slot in pairs(slotsByIndex) do
                if index > maxSlots then
                        slot.Visible = false
                        slotState[index] = nil
                end
        end

        print("[Debug] ✅ Populated inventory with", filled, "items and", maxSlots - filled, "empty slots")
end

-- Initialize everything when player loads
local function initializeInventorySystem()
	print("[Debug] 🚀 Initializing inventory system...")

	-- Find your existing inventory GUI
	inventoryGui = gui:FindFirstChild("InventoryGUI")
	if not inventoryGui then
		warn("[Debug] ❌ Could not find InventoryGUI in PlayerGui - create it in Roblox Studio")
		return false
	end

	print("[Debug] ✅ Found inventory GUI:", inventoryGui.Name)

	-- Find inventory frame
	inventoryFrame = inventoryGui:FindFirstChild("InventoryFrame")
	if not inventoryFrame then
		warn("[Debug] ❌ Could not find InventoryFrame in", inventoryGui.Name)
		return false
	end

	print("[Debug] ✅ Found InventoryFrame")
	-- Find inventory items
	inventoryItems = inventoryFrame:FindFirstChild("InventoryItems")
	if not inventoryItems then
		warn("[Debug] ❌ Could not find InventoryItems in InventoryFrame")
		return false
	end
	
	print("[Debug] ✅ Found InventoryItems")
	
	-- Find template
	template = inventoryItems:FindFirstChild("ItemSlotTemplate")
	if not template then
		warn("[Debug] ❌ Could not find ItemSlotTemplate in InventoryItems")
		return false
	end
	
	print("[Debug] ✅ Found ItemSlotTemplate")
	
	-- Ensure the GUI is enabled (in case it was disabled in Studio)
	inventoryGui.Enabled = true
	print("[Debug] ✅ Inventory GUI enabled")
	
	-- Hide inventory initially
	setInventoryVisible(false)
	print("[Debug] ✅ Inventory GUI hidden initially")
	
	-- Auto-populate inventory
	autoPopulateInventory()
	
	-- Check for pending inventory data from server
	if _G.pendingInventoryData then
		print("[Debug] 📦 Found pending inventory data, populating now...")
		populateInventoryFromServer(_G.pendingInventoryData)
		_G.pendingInventoryData = nil
	end
	
	print("[Debug] ✅ Inventory system fully initialized!")
	return true
end

-- Initialize the inventory system when the script loads
initializeInventorySystem()

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
							setInventoryVisible(false)
							print("[Debug] ✅ Inventory GUI hidden initially")
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
		if not visible then
			setInventoryVisible(true)
			print("[Debug] 📦 Inventory opened")
			populateInventory()
		else
			setInventoryVisible(false)
			print("[Debug] 📦 Inventory closed")
		end
	end
end)

-- Remote event handlers
inventoryRemote.OnClientEvent:Connect(function(action, data)
        print("[Debug] Received remote event:", action, "Data type:", type(data))
        if action == "SyncInventory" then
                local count = 0
                if typeof(data) == "table" then
                        if data.slots then
                                for index, slot in pairs(data.slots) do
                                        if slot and slot.itemId and slot.count and slot.count > 0 then
                                                count = count + 1
                                                print("[Debug] Item", index, ":", slot.itemId, "x", slot.count)
                                        end
                                end
                        else
                                for index, slot in ipairs(data) do
                                        if slot and slot.itemId and slot.count and slot.count > 0 then
                                                count = count + 1
                                                print("[Debug] Item", index, ":", slot.itemId, "x", slot.count)
                                        end
                                end
                        end
                end

                print("[Debug] ✅ Inventory synced with", count, "items")
                print("[Debug] Refreshing inventory display...")
                populateInventoryFromServer(data)
	end
end)

print("[Debug] ✅ InventoryClient ready!")
print("[Debug] 🎮 Press E to toggle inventory")

print("✅ Animal Crossing client systems loaded!")