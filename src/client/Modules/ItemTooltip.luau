--[[
	ItemTooltip.luau
	
	Tooltip system for displaying item information when hovering over inventory slots.
	Shows item name, description, category, sell price, and other details.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ItemTooltip = {}

-- Color constants matching ACNH style
local COLORS = {
    background = Color3.fromRGB(247, 248, 230), -- Light beige
    border = Color3.fromRGB(138, 123, 102), -- Brown
    text = Color3.fromRGB(60, 50, 40), -- Dark brown
    accent = Color3.fromRGB(4, 175, 166), -- Teal
    price = Color3.fromRGB(100, 150, 100), -- Green for prices
}

local _tooltipGui = nil
local _tooltipFrame = nil
local _currentSlot = nil
local _isVisible = false
local _visibilityConnection = nil

local function isGuiBlockingTooltips(): boolean
    -- Tooltips are allowed even when other GUIs are open, so never block.
    return false
end

--[[
	Initialize the tooltip GUI
]]
local function createTooltipGUI()
    if _tooltipGui then
        return
    end

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Main ScreenGui
    _tooltipGui = Instance.new("ScreenGui")
    _tooltipGui.Name = "ItemTooltip"
    _tooltipGui.DisplayOrder = 1000 -- Above everything
    _tooltipGui.ResetOnSpawn = false
    _tooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _tooltipGui.IgnoreGuiInset = true
    _tooltipGui.Parent = playerGui

    -- Main frame
    _tooltipFrame = Instance.new("Frame")
    _tooltipFrame.Name = "TooltipFrame"
    _tooltipFrame.Size = UDim2.new(0, 280, 0, 0) -- Auto-size height
    _tooltipFrame.BackgroundColor3 = COLORS.background
    _tooltipFrame.BackgroundTransparency = 0
    _tooltipFrame.BorderSizePixel = 0
    _tooltipFrame.Visible = false
    _tooltipFrame.AutomaticSize = Enum.AutomaticSize.Y
    _tooltipFrame.Parent = _tooltipGui

    -- Border
    local border = Instance.new("UIStroke")
    border.Color = COLORS.border
    border.Thickness = 2
    border.Transparency = 0.2
    border.Parent = _tooltipFrame

    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = _tooltipFrame

    -- Padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = _tooltipFrame

    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = _tooltipFrame

    -- Item name (bold, larger)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ItemName"
    nameLabel.Size = UDim2.new(1, 0, 0, 0)
    nameLabel.AutomaticSize = Enum.AutomaticSize.Y
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = COLORS.text
    nameLabel.TextWrapped = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.LayoutOrder = 1
    nameLabel.Parent = _tooltipFrame

    -- Category (smaller, teal)
    local categoryLabel = Instance.new("TextLabel")
    categoryLabel.Name = "Category"
    categoryLabel.Size = UDim2.new(1, 0, 0, 0)
    categoryLabel.AutomaticSize = Enum.AutomaticSize.Y
    categoryLabel.BackgroundTransparency = 1
    categoryLabel.Font = Enum.Font.GothamMedium
    categoryLabel.TextSize = 12
    categoryLabel.TextColor3 = COLORS.accent
    categoryLabel.TextWrapped = true
    categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    categoryLabel.LayoutOrder = 2
    categoryLabel.Parent = _tooltipFrame

    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, 0, 0, 0)
    descLabel.AutomaticSize = Enum.AutomaticSize.Y
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 14
    descLabel.TextColor3 = COLORS.text
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.LayoutOrder = 3
    descLabel.Parent = _tooltipFrame

    -- Separator line
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, 0, 0, 1)
    separator.BackgroundColor3 = COLORS.border
    separator.BackgroundTransparency = 0.7
    separator.BorderSizePixel = 0
    separator.LayoutOrder = 4
    separator.Parent = _tooltipFrame

    -- Price section
    local priceFrame = Instance.new("Frame")
    priceFrame.Name = "PriceFrame"
    priceFrame.Size = UDim2.new(1, 0, 0, 20)
    priceFrame.BackgroundTransparency = 1
    priceFrame.LayoutOrder = 5
    priceFrame.Parent = _tooltipFrame

    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "Price"
    priceLabel.Size = UDim2.new(1, 0, 1, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.GothamSemibold
    priceLabel.TextSize = 14
    priceLabel.TextColor3 = COLORS.price
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.Parent = priceFrame

    print("[ItemTooltip] ✅ Tooltip GUI created")
end

--[[
	Show tooltip for an item
	@param itemData table - Item data from ItemDataFetcher
	@param slotGui GuiObject - The slot GUI element (for positioning)
	@param itemCount number - Optional item count
]]
function ItemTooltip.show(itemData, slotGui, itemCount)
    if not itemData then
        return
    end

    createTooltipGUI()

    if not _tooltipFrame then
        warn("[ItemTooltip] Tooltip frame not created")
        return
    end

    _currentSlot = slotGui
    _isVisible = true

    -- Update content
    local nameLabel = _tooltipFrame:FindFirstChild("ItemName")
    local categoryLabel = _tooltipFrame:FindFirstChild("Category")
    local descLabel = _tooltipFrame:FindFirstChild("Description")
    local priceLabel = _tooltipFrame:FindFirstChild("PriceFrame"):FindFirstChild("Price")

    if nameLabel then
        local name = itemData.name or itemData.displayName or itemData.id or "Unknown Item"
        if itemCount and itemCount > 1 then
            name = name .. " (x" .. itemCount .. ")"
        end
        nameLabel.Text = name
    end

    if categoryLabel then
        local category = itemData.category or "Misc"
        categoryLabel.Text = string.upper(category)
        categoryLabel.Visible = category ~= "Misc" and category ~= "legacy"
    end

    if descLabel then
        local desc = itemData.description or itemData.flavorText or itemData.flavor_text or ""
        if desc == "" then
            desc = "A useful item for your island adventures."
        end
        descLabel.Text = desc
        descLabel.Visible = true
    end

    if priceLabel then
        local sellPrice = itemData.sellPrice or itemData.sell_price or itemData.sell or 0
        if sellPrice and sellPrice > 0 then
            priceLabel.Text = "💰 Sell Value: " .. sellPrice .. " Bells"
            priceLabel.Visible = true
        else
            priceLabel.Visible = false
        end
    end

    -- Position tooltip near mouse/slot
    updatePosition()

    -- Show with fade-in
    _tooltipFrame.Visible = true
    _tooltipFrame.BackgroundTransparency = 1
    TweenService:Create(_tooltipFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 0,
    }):Play()

    if not _visibilityConnection then
        _visibilityConnection = RunService.RenderStepped:Connect(function()
            if _isVisible and isGuiBlockingTooltips() then
                ItemTooltip.hide()
            end
        end)
    end
end

--[[
	Hide the tooltip
]]
function ItemTooltip.hide()
    if not _tooltipFrame or not _isVisible then
        return
    end

    _isVisible = false
    _currentSlot = nil

    -- Fade out
    TweenService:Create(_tooltipFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1,
    }):Play()

    -- Hide after fade
    task.wait(0.15)
    if _tooltipFrame then
        _tooltipFrame.Visible = false
    end

    if _visibilityConnection then
        _visibilityConnection:Disconnect()
        _visibilityConnection = nil
    end
end

--[[
	Update tooltip position based on mouse
]]
function updatePosition()
    if not _tooltipFrame or not _isVisible then
        return
    end
    if isGuiBlockingTooltips() then
        ItemTooltip.hide()
        return
    end

    local mouse = Players.LocalPlayer:GetMouse()
    local viewportSize = workspace.CurrentCamera.ViewportSize

    -- Position near mouse cursor
    local offsetX = 20
    local offsetY = 20

    -- Try to position relative to slot if available
    if _currentSlot and _currentSlot.AbsolutePosition then
        local slotPos = _currentSlot.AbsolutePosition
        local slotSize = _currentSlot.AbsoluteSize

        -- Position to the right of slot
        offsetX = slotPos.X + slotSize.X + 10
        offsetY = slotPos.Y

        -- If tooltip would go off screen, position to the left
        if offsetX + _tooltipFrame.AbsoluteSize.X > viewportSize.X then
            offsetX = slotPos.X - _tooltipFrame.AbsoluteSize.X - 10
        end

        -- If still off screen, use mouse position
        if offsetX < 0 then
            offsetX = mouse.X + 15
            offsetY = mouse.Y + 15
        end
    else
        -- Fallback to mouse position
        offsetX = mouse.X + 15
        offsetY = mouse.Y + 15
    end

    -- Keep tooltip on screen
    local tooltipSize = _tooltipFrame.AbsoluteSize
    if offsetX + tooltipSize.X > viewportSize.X then
        offsetX = viewportSize.X - tooltipSize.X - 10
    end
    if offsetY + tooltipSize.Y > viewportSize.Y then
        offsetY = viewportSize.Y - tooltipSize.Y - 10
    end
    if offsetX < 10 then
        offsetX = 10
    end
    if offsetY < 10 then
        offsetY = 10
    end

    _tooltipFrame.Position = UDim2.new(0, offsetX, 0, offsetY)
end

--[[
	Update position on mouse move
]]
local mouseMoveConnection = nil
function ItemTooltip._startTracking()
    if mouseMoveConnection then
        return
    end

    mouseMoveConnection = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updatePosition()
        end
    end)
end

function ItemTooltip._stopTracking()
    if mouseMoveConnection then
        mouseMoveConnection:Disconnect()
        mouseMoveConnection = nil
    end
end

return ItemTooltip
