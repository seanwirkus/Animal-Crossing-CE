-- Client initialization script
-- Clean client-side inventory system

print("Loading Animal Crossing client systems...")

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
        inventoryFrame.Visible = visible

        if not visible and dragInfo then
                finishDrag(UserInputService:GetMouseLocation(), true)
        end

        local blur = ensureBlurEffect()
        blur.Enabled = true

        local targetSize = visible and 12 or 0
        local blurTween = TweenService:Create(blur, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = targetSize,
        })
        blurTween:Play()

        if not visible then
                blurTween.Completed:Connect(function()
                        if not visible then
                                blur.Enabled = false
                        end
                end)
        end

        if visible then
                inventoryFrame.BackgroundTransparency = 0.3
                TweenService:Create(inventoryFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.05,
                }):Play()
        else
                TweenService:Create(inventoryFrame, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.3,
                }):Play()
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

local function updateSlotAppearance(slot, state, options)
    if not slot then
        return
    end

    options = options or {}
    local isGhost = options.isGhost
    local isPlaceholder = options.placeholder

    local icon = slot:FindFirstChild("ItemIcon")
    local itemCountLabel = slot:FindFirstChild("ItemCount")
    local itemNameLabel = slot:FindFirstChild("ItemName")
    local stroke = slot:FindFirstChild("HighlightStroke")
    if not stroke then
        for _, child in ipairs(slot:GetChildren()) do
            if child:IsA("UIStroke") then
                stroke = child
                break
            end
        end
    end

    if stroke then
        stroke.Enabled = isPlaceholder and true or false
    end

    if state and state.itemId and ItemData[state.itemId] then
        local item = ItemData[state.itemId]
        if icon then
            local offset, size = SpriteConfig.GetSpriteRect(item.index)
            icon.Image = SpriteConfig.SHEET_ASSET
            icon.ImageRectOffset = offset
            icon.ImageRectSize = size
            icon.ImageTransparency = isPlaceholder and 1 or 0
        end

        if itemCountLabel then
            if state.count and state.count > 1 then
                itemCountLabel.Text = tostring(state.count)
                itemCountLabel.Visible = true
            else
                itemCountLabel.Text = isGhost and "1" or ""
                itemCountLabel.Visible = isGhost and true or false
            end
            itemCountLabel.TextTransparency = isPlaceholder and 0.35 or 0
        end

		if itemNameLabel then
			setItemNameLabelText(itemNameLabel, item.name)
			itemNameLabel.TextTransparency = isPlaceholder and 0.4 or 1
			itemNameLabel.BackgroundTransparency = 1
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
			setItemNameLabelText(itemNameLabel, "Empty Slot")
			itemNameLabel.TextTransparency = 0.4
			itemNameLabel.BackgroundTransparency = 1
		end
    end
end

local function configureSlotFrame(slot, slotIndex)
	slot:SetAttribute("SlotIndex", slotIndex)
	if slot:GetAttribute("Configured") then
		return
	end

	slot:SetAttribute("Configured", true)

	local highlight = Instance.new("UIStroke")
	highlight.Name = "HighlightStroke"
	highlight.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	highlight.Thickness = 2
	highlight.Color = Color3.fromRGB(255, 226, 158)
	highlight.Transparency = 0.1
	highlight.Enabled = false
	highlight.Parent = slot

	local hoverButton = Instance.new("TextButton")
	hoverButton.Name = "HoverButton"
	hoverButton.Size = UDim2.new(1, 0, 1, 0)
	hoverButton.BackgroundTransparency = 1
	hoverButton.Text = ""
	hoverButton.ZIndex = slot.ZIndex + 1
	hoverButton.Parent = slot

	hoverButton.MouseEnter:Connect(function()
		TweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 70, 0, 70),
		}):Play()
		
		local itemNameLabel = slot:FindFirstChild("ItemName")
		if itemNameLabel then
			TweenService:Create(itemNameLabel, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				TextTransparency = 0,
				BackgroundTransparency = 0.2
			}):Play()
		end
	end)

	hoverButton.MouseLeave:Connect(function()
		TweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 64, 0, 64),
		}):Play()
		
		local itemNameLabel = slot:FindFirstChild("ItemName")
		if itemNameLabel then
			TweenService:Create(itemNameLabel, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				TextTransparency = 1,
				BackgroundTransparency = 1
			}):Play()
		end
	end)

	local dragButton = Instance.new("TextButton")
	dragButton.Name = "DragButton"
	dragButton.Size = UDim2.new(1, 0, 1, 0)
	dragButton.BackgroundTransparency = 1
	dragButton.Text = ""
	dragButton.ZIndex = hoverButton.ZIndex + 1
	dragButton.Parent = slot

	dragButton.MouseButton1Down:Connect(function()
		local state = slotState[slotIndex]
		if not state then
			return
		end
		beginDrag(slotIndex)
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

local function getSlotUnderPoint(point)
    if not inventoryItems then
        return nil
    end

    for index, slot in pairs(slotsByIndex) do
        if slot and slot.Parent then
            local pos = slot.AbsolutePosition
            local size = slot.AbsoluteSize
            if point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y then
                return index
            end
        end
    end

    return nil
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

    local ghost = template:Clone()
    ghost.Name = "DragGhost"
    ghost.Visible = true
    ghost.AnchorPoint = Vector2.new(0.5, 0.5)
    ghost.Size = UDim2.new(0, 80, 0, 80)
    ghost.BackgroundTransparency = 0.05
    ghost.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ghost.BorderSizePixel = 0
    ghost.ZIndex = 250

    local ghostStroke = ghost:FindFirstChildOfClass("UIStroke")
    if ghostStroke then
        ghostStroke.Color = Color3.fromRGB(255, 244, 194)
        ghostStroke.Thickness = 3
        ghostStroke.Enabled = true
    end

    local ghostDrag = ghost:FindFirstChild("DragButton")
    if ghostDrag then
        ghostDrag:Destroy()
    end

    local ghostHover = ghost:FindFirstChild("HoverButton")
    if ghostHover then
        ghostHover:Destroy()
    end

    ghost.Parent = ensureDragLayer()
    updateSlotAppearance(ghost, state, { isGhost = true })

    slot:SetAttribute("DragActive", true)
    updateSlotAppearance(slot, state, { placeholder = true })

    dragInfo = {
        slotIndex = slotIndex,
        state = copySlotData(state),
        ghost = ghost,
        mouseConnection = nil,
    }

    dragInfo.mouseConnection = RunService.RenderStepped:Connect(function()
        if not dragInfo then
            return
        end

        local mousePos = UserInputService:GetMouseLocation()
        if ghost.Parent and inventoryGui then
            ghost.Position = UDim2.fromOffset(mousePos.X - inventoryGui.AbsolutePosition.X, mousePos.Y - inventoryGui.AbsolutePosition.Y)
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

    local slot = slotsByIndex[info.slotIndex]
    if slot then
        slot:SetAttribute("DragActive", false)
    end

    if info.ghost then
        info.ghost:Destroy()
    end

    local mousePosition = mousePos or UserInputService:GetMouseLocation()
    local insideInventorySlots = false
    if inventoryItems then
        local invPos = inventoryItems.AbsolutePosition
        local invSize = inventoryItems.AbsoluteSize
        local margin = 24
        if mousePosition.X >= invPos.X - margin and mousePosition.X <= invPos.X + invSize.X + margin and mousePosition.Y >= invPos.Y - margin and mousePosition.Y <= invPos.Y + invSize.Y + margin then
            insideInventorySlots = true
        end
    end

    if cancelled then
        slotState[info.slotIndex] = copySlotData(info.state)
        refreshSlot(info.slotIndex)
        dragInfo = nil
        return
    end

    if insideInventorySlots then
        local targetIndex = getSlotUnderPoint(mousePosition)
        if targetIndex and targetIndex ~= info.slotIndex then
            local targetState = slotState[targetIndex]
            if targetState then
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
            -- If dragging within inventory area but not over a slot, drop the item
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

            local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
            local worldPosition = Vector3.new(0, 1, 0) -- Start closer to ground
            if raycastResult then
                worldPosition = raycastResult.Position + Vector3.new(0, 0.5, 0)
            else
                -- If no raycast hit, try to find ground below camera
                local camera = workspace.CurrentCamera
                local cameraPos = camera.CFrame.Position
                local groundRaycast = workspace:Raycast(cameraPos, Vector3.new(0, -100, 0), raycastParams)
                if groundRaycast then
                    worldPosition = groundRaycast.Position + Vector3.new(0, 0.5, 0)
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
    else
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

        local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
        local worldPosition = Vector3.new(0, 1, 0) -- Start closer to ground
        if raycastResult then
            worldPosition = raycastResult.Position + Vector3.new(0, 0.5, 0)
        else
            -- If no raycast hit, try to find ground below camera
            local camera = workspace.CurrentCamera
            local cameraPos = camera.CFrame.Position
            local groundRaycast = workspace:Raycast(cameraPos, Vector3.new(0, -100, 0), raycastParams)
            if groundRaycast then
                worldPosition = groundRaycast.Position + Vector3.new(0, 0.5, 0)
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

    dragInfo = nil
end

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragInfo then
        finishDrag(UserInputService:GetMouseLocation())
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
                        filled += 1
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
		warn("[Debug] ❌ Could not find inventory GUI. Available GUIs:")
		for _, child in ipairs(gui:GetChildren()) do
			print("[Debug]   -", child.Name)
		end
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

-- Debug GUI variable (declare at top level scope)
local debugGui

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
	
	-- Debug: List world items with W key
	if input.KeyCode == Enum.KeyCode.W then
		print("[Debug] 🌍 Requesting world items...")
		inventoryRemote:FireServer("GetWorldItems")
	end
	
	-- Debug: Toggle debug GUI with G key
	if input.KeyCode == Enum.KeyCode.G then
		print("[Debug] G key pressed! Toggling debug GUI...")
		print("[Debug] 🔧 Debug GUI exists:", debugGui ~= nil)
		if debugGui then
			print("[Debug] 🔧 Debug GUI current state:", debugGui.Enabled)
			print("[Debug] 🔧 Debug GUI parent:", debugGui.Parent and debugGui.Parent.Name or "nil")
			print("[Debug] 🔧 Debug GUI children count:", #debugGui:GetChildren())
		end
		debugGui.Enabled = not debugGui.Enabled
		if debugGui.Enabled then
			print("[Debug] 🔧 Debug GUI opened")
		else
			print("[Debug] 🔧 Debug GUI closed")
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
                                                count += 1
                                                print("[Debug] Item", index, ":", slot.itemId, "x", slot.count)
                                        end
                                end
                        else
                                for index, slot in ipairs(data) do
                                        if slot and slot.itemId and slot.count and slot.count > 0 then
                                                count += 1
                                                print("[Debug] Item", index, ":", slot.itemId, "x", slot.count)
                                        end
                                end
                        end
                end

                print("[Debug] ✅ Inventory synced with", count, "items")
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
print("[Debug] 🎮 Press W to list world items")
print("[Debug] 🎮 Press G to toggle debug GUI")

-- Debug GUI (create before input handler)
debugGui = Instance.new("ScreenGui")
debugGui.Name = "DebugGUI"
debugGui.ResetOnSpawn = false
debugGui.Enabled = false  -- Start hidden, will be toggled with G key
debugGui.Parent = playerGui

print("[Debug] 🔧 Debug GUI created:", debugGui.Name, "Parent:", debugGui.Parent.Name)

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 800, 0, 600)
mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = debugGui

-- Corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Item Sprite Debugger"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeButton

-- Coordinate input section
local coordFrame = Instance.new("Frame")
coordFrame.Name = "CoordFrame"
coordFrame.Size = UDim2.new(1, -20, 0, 80)
coordFrame.Position = UDim2.new(0, 10, 0, 50)
coordFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
coordFrame.BorderSizePixel = 0
coordFrame.Parent = mainFrame

local coordCorner = Instance.new("UICorner")
coordCorner.CornerRadius = UDim.new(0, 6)
coordCorner.Parent = coordFrame

-- X coordinate input
local xLabel = Instance.new("TextLabel")
xLabel.Name = "XLabel"
xLabel.Size = UDim2.new(0, 20, 0, 30)
xLabel.Position = UDim2.new(0, 10, 0, 10)
xLabel.BackgroundTransparency = 1
xLabel.Text = "X:"
xLabel.TextColor3 = Color3.new(1, 1, 1)
xLabel.TextSize = 16
xLabel.Font = Enum.Font.Gotham
xLabel.Parent = coordFrame

local xInput = Instance.new("TextBox")
xInput.Name = "XInput"
xInput.Size = UDim2.new(0, 80, 0, 30)
xInput.Position = UDim2.new(0, 35, 0, 10)
xInput.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
xInput.BorderSizePixel = 0
xInput.Text = "0"
xInput.TextColor3 = Color3.new(1, 1, 1)
xInput.TextSize = 16
xInput.Font = Enum.Font.Gotham
xInput.PlaceholderText = "X coord"
xInput.Parent = coordFrame

local xCorner = Instance.new("UICorner")
xCorner.CornerRadius = UDim.new(0, 4)
xCorner.Parent = xInput

-- Y coordinate input
local yLabel = Instance.new("TextLabel")
yLabel.Name = "YLabel"
yLabel.Size = UDim2.new(0, 20, 0, 30)
yLabel.Position = UDim2.new(0, 130, 0, 10)
yLabel.BackgroundTransparency = 1
yLabel.Text = "Y:"
yLabel.TextColor3 = Color3.new(1, 1, 1)
yLabel.TextSize = 16
yLabel.Font = Enum.Font.Gotham
yLabel.Parent = coordFrame

local yInput = Instance.new("TextBox")
yInput.Name = "YInput"
yInput.Size = UDim2.new(0, 80, 0, 30)
yInput.Position = UDim2.new(0, 155, 0, 10)
yInput.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
yInput.BorderSizePixel = 0
yInput.Text = "0"
yInput.TextColor3 = Color3.new(1, 1, 1)
yInput.TextSize = 16
yInput.Font = Enum.Font.Gotham
yInput.PlaceholderText = "Y coord"
yInput.Parent = coordFrame

local yCorner = Instance.new("UICorner")
yCorner.CornerRadius = UDim.new(0, 4)
yCorner.Parent = yInput

-- Test button
local testButton = Instance.new("TextButton")
testButton.Name = "TestButton"
testButton.Size = UDim2.new(0, 100, 0, 30)
testButton.Position = UDim2.new(0, 250, 0, 10)
testButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
testButton.BorderSizePixel = 0
testButton.Text = "Test Item"
testButton.TextColor3 = Color3.new(1, 1, 1)
testButton.TextSize = 16
testButton.Font = Enum.Font.GothamBold
testButton.Parent = coordFrame

local testCorner = Instance.new("UICorner")
testCorner.CornerRadius = UDim.new(0, 4)
testCorner.Parent = testButton

-- Item info display
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, -20, 0, 30)
infoLabel.Position = UDim2.new(0, 10, 0, 50)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Enter coordinates to test an item sprite"
infoLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
infoLabel.TextSize = 14
infoLabel.Font = Enum.Font.Gotham
infoLabel.Parent = coordFrame

-- Sprite grid
local gridFrame = Instance.new("ScrollingFrame")
gridFrame.Name = "GridFrame"
gridFrame.Size = UDim2.new(1, -20, 1, -140)
gridFrame.Position = UDim2.new(0, 10, 0, 140)
gridFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
gridFrame.BorderSizePixel = 0
gridFrame.ScrollBarThickness = 8
gridFrame.Parent = mainFrame

local gridCorner = Instance.new("UICorner")
gridCorner.CornerRadius = UDim.new(0, 6)
gridCorner.Parent = gridFrame

-- Grid layout
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 60, 0, 60)
gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
gridLayout.Parent = gridFrame

-- Sprite sheet asset
local SPRITE_SHEET = "rbxassetid://94665697594550"

-- Create sprite grid
local function createSpriteGrid()
    local gridSize = 20 -- 20x20 grid
    local totalSprites = gridSize * gridSize
    
    for i = 0, totalSprites - 1 do
        local x = i % gridSize
        local y = math.floor(i / gridSize)
        
        local spriteFrame = Instance.new("Frame")
        spriteFrame.Name = "Sprite_" .. x .. "_" .. y
        spriteFrame.Size = UDim2.new(0, 60, 0, 60)
        spriteFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        spriteFrame.BorderSizePixel = 0
        spriteFrame.Parent = gridFrame
        
        local spriteCorner = Instance.new("UICorner")
        spriteCorner.CornerRadius = UDim.new(0, 4)
        spriteCorner.Parent = spriteFrame
        
        local spriteImage = Instance.new("ImageLabel")
        spriteImage.Name = "SpriteImage"
        spriteImage.Size = UDim2.new(1, -4, 1, -4)
        spriteImage.Position = UDim2.new(0, 2, 0, 2)
        spriteImage.BackgroundTransparency = 1
        spriteImage.Image = SPRITE_SHEET
        spriteImage.ImageRectOffset = Vector2.new(x * 32, y * 32)
        spriteImage.ImageRectSize = Vector2.new(32, 32)
        spriteImage.ScaleType = Enum.ScaleType.Stretch
        spriteImage.Parent = spriteFrame
        
        -- Coordinate label
        local coordLabel = Instance.new("TextLabel")
        coordLabel.Name = "CoordLabel"
        coordLabel.Size = UDim2.new(1, 0, 0, 12)
        coordLabel.Position = UDim2.new(0, 0, 1, -12)
        coordLabel.BackgroundTransparency = 1
        coordLabel.Text = x .. "," .. y
        coordLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
        coordLabel.TextSize = 10
        coordLabel.Font = Enum.Font.Gotham
        coordLabel.Parent = spriteFrame
        
        -- Click to test
        spriteFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                xInput.Text = tostring(x)
                yInput.Text = tostring(y)
                infoLabel.Text = "Selected: " .. x .. ", " .. y .. " - Click Test Item to spawn"
            end
        end)
    end
    
    gridFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(totalSprites / 10) * 65)
end

-- Test item function
local function testItem()
    local x = tonumber(xInput.Text) or 0
    local y = tonumber(yInput.Text) or 0
    
    if x < 0 or x >= 20 or y < 0 or y >= 20 then
        infoLabel.Text = "Invalid coordinates! Use 0-19 for both X and Y"
        return
    end
    
    -- Send test request to server
    local testEvent = ReplicatedStorage:FindFirstChild("TestItemEvent")
    if not testEvent then
        testEvent = Instance.new("RemoteEvent")
        testEvent.Name = "TestItemEvent"
        testEvent.Parent = ReplicatedStorage
    end
    
    testEvent:FireServer(x, y)
    infoLabel.Text = "Testing item at " .. x .. ", " .. y .. " - Check the world!"
end

-- Event connections
closeButton.MouseButton1Click:Connect(function()
    debugGui.Enabled = false
end)

testButton.MouseButton1Click:Connect(testItem)

-- Create the sprite grid
createSpriteGrid()

print("Debug GUI created! Press G to toggle, or find it in PlayerGui")

print("✅ Animal Crossing client systems loaded!")
