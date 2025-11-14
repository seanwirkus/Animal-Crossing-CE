--[[
    NookShoppingGUI.luau
    Brand new Nook Shopping GUI built from scratch
    Clean, minimal design with ACNH styling
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NookShoppingGUI = {}
NookShoppingGUI.__index = NookShoppingGUI

-- ACNH Color Palette
local COLORS = {
    BG_PRIMARY = Color3.fromRGB(255, 251, 231), -- Cream
    BG_SECONDARY = Color3.fromRGB(255, 255, 255), -- White
    BORDER_DARK = Color3.fromRGB(100, 80, 60), -- Brown
    TEXT_DARK = Color3.fromRGB(60, 50, 40), -- Dark brown
    TEXT_LIGHT = Color3.fromRGB(255, 255, 255), -- White
    ACCENT = Color3.fromRGB(4, 175, 166), -- Teal
    ACCENT_HOVER = Color3.fromRGB(5, 195, 185), -- Teal hover
    PRICE = Color3.fromRGB(255, 193, 77), -- Bell gold
    SLOT_BG = Color3.fromRGB(245, 240, 230), -- Light cream
    SLOT_HOVER = Color3.fromRGB(235, 230, 220), -- Hover cream
}

local ITEM_SLOT_SIZE = 120
local GRID_PADDING = 12
local GRID_COLS = 4

function NookShoppingGUI.new()
    local self = setmetatable({}, NookShoppingGUI)

    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.gui = nil
    self.visible = false
    self.bells = 0
    self.items = {}

    -- Load dependencies
    local shared = ReplicatedStorage:WaitForChild("Shared")
    self.spriteConfig = require(shared:WaitForChild("SpriteConfig"))
    self.shopData = require(shared:WaitForChild("ShopData"))

    -- Currency remote
    self.currencyRemote = ReplicatedStorage:WaitForChild("CurrencyEvent")

    -- Shop remote
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEventsFolder then
        self.shopRemote = remoteEventsFolder:FindFirstChild("ShopTransaction")
        if not self.shopRemote then
            self.shopRemote = Instance.new("RemoteEvent")
            self.shopRemote.Name = "ShopTransaction"
            self.shopRemote.Parent = remoteEventsFolder
        end
    end

    self:buildGui()
    self:connectToServer()

    print("[NookShoppingGUI] ✅ Initialized")
    return self
end

function NookShoppingGUI:buildGui()
    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NookShoppingGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 50
    screenGui.Enabled = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = self.playerGui
    self.gui = screenGui

    -- Backdrop (semi-transparent overlay)
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = screenGui

    backdrop.Active = true
    backdrop.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:hide()
        end
    end)

    -- Main container
    local container = Instance.new("Frame")
    container.Name = "ShopContainer"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Size = UDim2.new(0, 800, 0, 600)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.BackgroundColor3 = COLORS.BG_PRIMARY
    container.BorderSizePixel = 0
    container.ZIndex = 2
    container.Parent = screenGui

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 20)
    containerCorner.Parent = container

    local containerStroke = Instance.new("UIStroke")
    containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    containerStroke.Thickness = 3
    containerStroke.Color = COLORS.BORDER_DARK
    containerStroke.Parent = container

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = COLORS.BG_SECONDARY
    header.BorderSizePixel = 0
    header.ZIndex = 3
    header.Parent = container

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 20)
    headerCorner.Parent = header

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0, 300, 0, 50)
    titleLabel.Position = UDim2.new(0, 24, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 32
    titleLabel.TextColor3 = COLORS.TEXT_DARK
    titleLabel.Text = "🛒 Nook Shopping"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = header

    -- Bells display
    local bellsFrame = Instance.new("Frame")
    bellsFrame.Name = "BellsFrame"
    bellsFrame.Size = UDim2.new(0, 180, 0, 40)
    bellsFrame.Position = UDim2.new(1, -220, 0, 20)
    bellsFrame.BackgroundColor3 = COLORS.ACCENT
    bellsFrame.BorderSizePixel = 0
    bellsFrame.ZIndex = 4
    bellsFrame.Parent = header

    local bellsCorner = Instance.new("UICorner")
    bellsCorner.CornerRadius = UDim.new(0, 12)
    bellsCorner.Parent = bellsFrame

    local bellsLabel = Instance.new("TextLabel")
    bellsLabel.Name = "BellsLabel"
    bellsLabel.Size = UDim2.fromScale(1, 1)
    bellsLabel.BackgroundTransparency = 1
    bellsLabel.Font = Enum.Font.GothamBold
    bellsLabel.TextSize = 18
    bellsLabel.TextColor3 = COLORS.TEXT_LIGHT
    bellsLabel.Text = "💰 0 Bells"
    bellsLabel.ZIndex = 5
    bellsLabel.Parent = bellsFrame
    self.bellsLabel = bellsLabel

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 20)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
    closeButton.TextColor3 = COLORS.TEXT_LIGHT
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 24
    closeButton.Text = "✕"
    closeButton.ZIndex = 4
    closeButton.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 12)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)

    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(240, 120, 120)
    end)

    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
    end)

    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -48, 1, -100)
    contentFrame.Position = UDim2.new(0, 24, 0, 100)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ZIndex = 3
    contentFrame.Parent = container

    -- Scrolling frame for items
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemScrollFrame"
    scrollFrame.Size = UDim2.fromScale(1, 1)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = COLORS.BORDER_DARK
    scrollFrame.ZIndex = 4
    scrollFrame.Parent = contentFrame

    local listLayout = Instance.new("UIGridLayout")
    listLayout.CellSize = UDim2.new(0, ITEM_SLOT_SIZE, 0, ITEM_SLOT_SIZE + 50)
    listLayout.CellPadding = UDim2.new(0, GRID_PADDING, 0, GRID_PADDING)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = scrollFrame

    self.scrollFrame = scrollFrame
    self.listLayout = listLayout
end

function NookShoppingGUI:createItemSlot(shopItem, index)
    local slot = Instance.new("Frame")
    slot.Name = "ItemSlot_" .. shopItem.id
    slot.Size = UDim2.new(0, ITEM_SLOT_SIZE, 0, ITEM_SLOT_SIZE + 50)
    slot.BackgroundColor3 = COLORS.SLOT_BG
    slot.BorderSizePixel = 0
    slot.ZIndex = 5
    slot.LayoutOrder = index
    slot.Parent = self.scrollFrame

    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(0, 12)
    slotCorner.Parent = slot

    local slotStroke = Instance.new("UIStroke")
    slotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    slotStroke.Thickness = 2
    slotStroke.Color = COLORS.BORDER_DARK
    slotStroke.Transparency = 0.3
    slotStroke.Parent = slot

    -- Item icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "ItemIcon"
    icon.Size = UDim2.new(0, ITEM_SLOT_SIZE - 16, 0, ITEM_SLOT_SIZE - 16)
    icon.Position = UDim2.new(0, 8, 0, 8)
    icon.BackgroundColor3 = COLORS.BG_SECONDARY
    icon.BorderSizePixel = 0
    icon.ZIndex = 6
    icon.Parent = slot

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = icon

    if shopItem.spriteIndex then
        self.spriteConfig.applySprite(icon, shopItem.spriteIndex)
    end

    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ItemName"
    nameLabel.Size = UDim2.new(1, -8, 0, 24)
    nameLabel.Position = UDim2.new(0, 4, 0, ITEM_SLOT_SIZE - 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = COLORS.TEXT_DARK
    nameLabel.Text = shopItem.name or shopItem.id
    nameLabel.TextWrapped = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.ZIndex = 6
    nameLabel.Parent = slot

    -- Price label
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Size = UDim2.new(1, -8, 0, 20)
    priceLabel.Position = UDim2.new(0, 4, 0, ITEM_SLOT_SIZE + 16)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 16
    priceLabel.TextColor3 = COLORS.PRICE
    priceLabel.Text = tostring(shopItem.buyPrice or 0) .. " 🔔"
    priceLabel.TextXAlignment = Enum.TextXAlignment.Center
    priceLabel.ZIndex = 6
    priceLabel.Parent = slot

    -- Buy button
    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(1, -8, 0, 28)
    buyButton.Position = UDim2.new(0, 4, 0, ITEM_SLOT_SIZE + 38)
    buyButton.BackgroundColor3 = COLORS.ACCENT
    buyButton.TextColor3 = COLORS.TEXT_LIGHT
    buyButton.Font = Enum.Font.GothamBold
    buyButton.TextSize = 14
    buyButton.Text = "Buy"
    buyButton.ZIndex = 6
    buyButton.Parent = slot

    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 8)
    buyCorner.Parent = buyButton

    -- Hover effects
    local originalBg = COLORS.SLOT_BG
    local hoverBg = COLORS.SLOT_HOVER

    slot.MouseEnter:Connect(function()
        slot.BackgroundColor3 = hoverBg
        buyButton.BackgroundColor3 = COLORS.ACCENT_HOVER
    end)

    slot.MouseLeave:Connect(function()
        slot.BackgroundColor3 = originalBg
        buyButton.BackgroundColor3 = COLORS.ACCENT
    end)

    -- Buy functionality
    buyButton.MouseButton1Click:Connect(function()
        self:buyItem(shopItem)
    end)

    return slot
end

function NookShoppingGUI:populateItems()
    if not self.scrollFrame then
        return
    end

    -- Clear existing items
    for _, child in ipairs(self.scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("ItemSlot_") then
            child:Destroy()
        end
    end

    -- Get shop items
    local allShopItems = self.shopData.getAllItems()

    if #allShopItems == 0 then
        warn("[NookShoppingGUI] ⚠️ No items found in ShopData")
        return
    end

    print("[NookShoppingGUI] 🛒 Loading", #allShopItems, "items...")

    -- Create slots
    for i, shopItem in ipairs(allShopItems) do
        self:createItemSlot(shopItem, i)
    end

    -- Update canvas size
    local rows = math.ceil(#allShopItems / GRID_COLS)
    local totalHeight = rows * (ITEM_SLOT_SIZE + 50 + GRID_PADDING) + GRID_PADDING
    self.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

    print("[NookShoppingGUI] ✅ Populated", #allShopItems, "items")
end

function NookShoppingGUI:buyItem(shopItem)
    if not shopItem then
        return
    end

    local price = shopItem.buyPrice or 0

    if self.bells < price then
        warn("[NookShoppingGUI] ⚠️ Not enough bells! Need", price, "have", self.bells)
        -- TODO: Show error message
        return
    end

    print("[NookShoppingGUI] 💳 Buying:", shopItem.name, "for", price, "bells")

    if self.shopRemote then
        self.shopRemote:FireServer("BuyItem", {
            itemId = shopItem.id,
            price = price,
            count = 1,
        })
    end
end

function NookShoppingGUI:updateBells(bells)
    self.bells = bells
    if self.bellsLabel then
        self.bellsLabel.Text = "💰 " .. tostring(bells) .. " Bells"
    end
end

function NookShoppingGUI:connectToServer()
    -- Listen for currency updates
    if self.currencyRemote then
        self.currencyConnection = self.currencyRemote.OnClientEvent:Connect(function(action, data)
            if action == "UpdateAll" or action == "UpdateBells" then
                local bells = data.bells or data.amount or 0
                self:updateBells(bells)
            end
        end)
    end

    -- Request initial currency
    if self.currencyRemote then
        self.currencyRemote:FireServer("GetCurrency")
    end
end

function NookShoppingGUI:show()
    if self.visible then
        return
    end

    if not self.gui then
        warn("[NookShoppingGUI] ❌ Cannot show - gui is nil")
        return
    end

    self.visible = true
    self.gui.Enabled = true

    -- Populate items when showing
    self:populateItems()

    -- Request currency update
    if self.currencyRemote then
        self.currencyRemote:FireServer("GetCurrency")
    end

    print("[NookShoppingGUI] 🛒 Nook Shopping opened")
end

function NookShoppingGUI:hide()
    if not self.visible then
        return
    end

    if not self.gui then
        return
    end

    self.visible = false
    self.gui.Enabled = false

    print("[NookShoppingGUI] 🛒 Nook Shopping closed")
end

function NookShoppingGUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function NookShoppingGUI:isVisible()
    return self.visible and (self.gui and self.gui.Enabled == true)
end

function NookShoppingGUI:cleanup()
    if self.currencyConnection then
        self.currencyConnection:Disconnect()
        self.currencyConnection = nil
    end
    self:hide()
end

-- Alias methods for GUIManager compatibility
NookShoppingGUI.Show = NookShoppingGUI.show
NookShoppingGUI.Hide = NookShoppingGUI.hide
NookShoppingGUI.Toggle = NookShoppingGUI.toggle

return NookShoppingGUI
