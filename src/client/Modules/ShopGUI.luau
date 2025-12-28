--[[
    ShopGUI.luau
    Client-side shop interface for buying/selling items
    Integrated with NookShopping GUI (Tom Nook's store)
    
    Features:
    - Buy tab: Browse shop items, view prices, purchase
    - Sell tab: Browse inventory, view sell prices, sell items
    - Currency display: Show current Bells
    - Item grid: Display items with sprites and prices
    
    DEPENDS ON: ShopData, CurrencyManager, ItemDataFetcher, SpriteConfig
    CALLS: ShopManager (server) via RemoteEvent
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _TweenService = game:GetService("TweenService")

local ShopGUI = {}
ShopGUI.__index = ShopGUI

-- ACNH Color Palette
local COLORS = {
    BG_PRIMARY = Color3.fromRGB(255, 251, 231), -- Cream
    BG_SECONDARY = Color3.fromRGB(255, 255, 255), -- White
    BORDER_DARK = Color3.fromRGB(100, 80, 60), -- Brown
    TEXT_DARK = Color3.fromRGB(60, 50, 40), -- Dark brown
    TEXT_LIGHT = Color3.fromRGB(255, 255, 255), -- White
    ACCENT = Color3.fromRGB(4, 175, 166), -- Teal
    PRICE_POSITIVE = Color3.fromRGB(100, 180, 100), -- Green
    PRICE_NEGATIVE = Color3.fromRGB(200, 100, 100), -- Red
}

local _GRID_COLS = 3
local ITEM_SLOT_SIZE = 100
local ITEM_GRID_PADDING = 10

function ShopGUI.new()
    local self = setmetatable({}, ShopGUI)

    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.gui = nil
    self.visible = false
    self.currentTab = "Buy"
    self.bells = 0

    -- Load dependencies
    local shared = ReplicatedStorage:WaitForChild("Shared")
    self.spriteConfig = require(shared:WaitForChild("SpriteConfig"))
    self.itemDataFetcher = require(shared:WaitForChild("ItemDataFetcher"))
    self.shopData = require(shared:WaitForChild("ShopData"))

    -- Currency remote
    self.currencyRemote = ReplicatedStorage:WaitForChild("CurrencyEvent")

    -- Shop remote (for buying/selling)
    local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
    if remoteEventsFolder then
        self.shopRemote = remoteEventsFolder:WaitForChild("ShopTransaction", 10)
        if not self.shopRemote then
            warn("[ShopGUI] ShopTransaction remote not found")
        end
    else
        warn("[ShopGUI] RemoteEvents folder not found")
    end

    self:buildGui()
    self:connectToServer()

    print("[ShopGUI] ✅ Initialized")
    return self
end

function ShopGUI:buildGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NookShoppingGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 40
    screenGui.Enabled = false
    screenGui.Parent = self.playerGui
    self.gui = screenGui

    -- Main container - smaller and positioned to avoid top-left corner
    local container = Instance.new("Frame")
    container.Name = "ShopContainer"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Size = UDim2.new(0, 720, 0, 540) -- Smaller: 720x540 (was 800x600)
    container.Position = UDim2.new(0.5, 0, 0.55, 0) -- Lower than center to avoid top-left
    container.BackgroundColor3 = COLORS.BG_PRIMARY
    container.BorderSizePixel = 0
    container.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 3
    stroke.Color = COLORS.BORDER_DARK
    stroke.Parent = container

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = COLORS.BG_SECONDARY
    header.BorderSizePixel = 0
    header.Parent = container

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 32
    titleLabel.TextColor3 = COLORS.BORDER_DARK
    titleLabel.Text = "🌟 Nook's Cranny"
    titleLabel.Parent = header

    local bellsLabel = Instance.new("TextLabel")
    bellsLabel.Name = "BellsLabel"
    bellsLabel.Size = UDim2.new(0.25, 0, 0.5, 0)
    bellsLabel.Position = UDim2.new(0.65, 0, 0.25, 0)
    bellsLabel.BackgroundTransparency = 1
    bellsLabel.Font = Enum.Font.GothamBold
    bellsLabel.TextSize = 16
    bellsLabel.TextColor3 = COLORS.TEXT_DARK
    bellsLabel.Text = "💰 Bells: 0"
    bellsLabel.Parent = header
    self.bellsLabel = bellsLabel

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = COLORS.ACCENT
    closeButton.TextColor3 = COLORS.TEXT_LIGHT
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.Text = "X"
    closeButton.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)

    -- Tab buttons
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "TabFrame"
    tabFrame.Size = UDim2.new(1, 0, 0, 50)
    tabFrame.Position = UDim2.new(0, 0, 0, 80)
    tabFrame.BackgroundColor3 = COLORS.BG_PRIMARY
    tabFrame.BorderSizePixel = 0
    tabFrame.Parent = container

    self.tabs = {}
    for i, tabName in ipairs({ "Buy", "Sell" }) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(0, 150, 1, 0)
        tabButton.Position = UDim2.new(0, (i - 1) * 160, 0, 0)
        tabButton.BackgroundColor3 = COLORS.BG_SECONDARY
        tabButton.TextColor3 = COLORS.TEXT_DARK
        tabButton.Font = Enum.Font.GothamBold
        tabButton.TextSize = 18
        tabButton.Text = tabName
        tabButton.Parent = tabFrame

        tabButton.MouseButton1Click:Connect(function()
            self:switchTab(tabName)
        end)

        self.tabs[tabName] = tabButton
    end

    -- Content area (ScrollingFrame)
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -150)
    contentFrame.Position = UDim2.new(0, 10, 0, 130)
    contentFrame.BackgroundColor3 = COLORS.BG_PRIMARY
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 10
    contentFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    contentFrame.Parent = container

    local listLayout = Instance.new("UIGridLayout")
    listLayout.CellSize = UDim2.new(0, ITEM_SLOT_SIZE, 0, ITEM_SLOT_SIZE + 40)
    listLayout.CellPadding = UDim2.new(0, ITEM_GRID_PADDING, 0, ITEM_GRID_PADDING)
    listLayout.Parent = contentFrame

    self.contentFrame = contentFrame
    self.listLayout = listLayout
end

function ShopGUI:switchTab(tabName: string)
    self.currentTab = tabName

    -- Update tab button colors
    for name, button in pairs(self.tabs) do
        if name == tabName then
            button.BackgroundColor3 = COLORS.ACCENT
            button.TextColor3 = COLORS.TEXT_LIGHT
        else
            button.BackgroundColor3 = COLORS.BG_SECONDARY
            button.TextColor3 = COLORS.TEXT_DARK
        end
    end

    -- Clear content
    for _, child in ipairs(self.contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    if tabName == "Buy" then
        self:populateBuyTab()
    elseif tabName == "Sell" then
        self:populateSellTab()
    end
end

function ShopGUI:populateBuyTab()
    local itemIds = {}
    for itemId in pairs(self.shopData.Items) do
        table.insert(itemIds, itemId)
    end

    for _, itemId in ipairs(itemIds) do
        local shopItem = self.shopData.Items[itemId]
        if shopItem then
            self:createShopSlot(itemId, shopItem, "Buy")
        end
    end
end

function ShopGUI:populateSellTab()
    -- TODO: Implement sell tab with inventory items
    local placeholder = Instance.new("TextLabel")
    placeholder.Size = UDim2.new(0, 200, 0, 30)
    placeholder.BackgroundTransparency = 1
    placeholder.Font = Enum.Font.Gotham
    placeholder.TextColor3 = COLORS.TEXT_DARK
    placeholder.Text = "Sell functionality coming soon"
    placeholder.Parent = self.contentFrame
end

function ShopGUI:createShopSlot(itemId: string, shopItem, mode: string)
    local slotFrame = Instance.new("Frame")
    slotFrame.Name = itemId .. "Slot"
    slotFrame.Size = UDim2.new(0, ITEM_SLOT_SIZE, 0, ITEM_SLOT_SIZE)
    slotFrame.BackgroundColor3 = COLORS.BG_SECONDARY
    slotFrame.BorderSizePixel = 0
    slotFrame.Parent = self.contentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = slotFrame

    -- Sprite
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, ITEM_SLOT_SIZE - 10, 0, ITEM_SLOT_SIZE - 10)
    iconLabel.Position = UDim2.new(0, 5, 0, 5)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Parent = slotFrame

    if shopItem.spriteIndex then
        self.spriteConfig.applySprite(iconLabel, shopItem.spriteIndex)
    end

    -- Price label (below slot)
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Size = UDim2.new(0, 120, 0, 20)
    priceLabel.Position = UDim2.new(0.5, -60, 1, 5)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 14
    priceLabel.TextColor3 = COLORS.PRICE_POSITIVE
    priceLabel.Text = string.format("%d 🔔", shopItem.buyPrice or 0)
    priceLabel.Parent = slotFrame.Parent

    -- Buy button
    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(0, 120, 0, 24)
    buyButton.Position = UDim2.new(0.5, -60, 1, 30)
    buyButton.BackgroundColor3 = COLORS.ACCENT
    buyButton.TextColor3 = COLORS.TEXT_LIGHT
    buyButton.Font = Enum.Font.GothamBold
    buyButton.TextSize = 12
    buyButton.Text = "Buy"
    buyButton.Parent = slotFrame.Parent

    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 6)
    buyCorner.Parent = buyButton

    buyButton.MouseButton1Click:Connect(function()
        self:buyItem(itemId, shopItem)
    end)
end

function ShopGUI:buyItem(itemId: string, shopItem)
    if self.bells < shopItem.buyPrice then
        print("[ShopGUI] ❌ Not enough Bells!")
        return
    end

    print("[ShopGUI] 💳 Purchasing", itemId, "for", shopItem.buyPrice, "Bells")

    if self.shopRemote then
        self.shopRemote:FireServer("BuyItem", {
            itemId = itemId,
            price = shopItem.buyPrice,
        })
    end
end

function ShopGUI:connectToServer()
    -- Listen for currency updates
    if self.currencyRemote then
        self.currencyRemote.OnClientEvent:Connect(function(action, data)
            if action == "UpdateBells" or action == "UpdateAll" then
                self.bells = data.bells or 0
                if self.bellsLabel then
                    self.bellsLabel.Text = string.format("💰 Bells: %d", self.bells)
                end
            end
        end)
    end
end

function ShopGUI:show()
    if self.visible then
        return
    end
    self.visible = true
    self.gui.Enabled = true
    self:switchTab("Buy")
    print("[ShopGUI] 🏪 Shop opened")
end

function ShopGUI:hide()
    if not self.visible then
        return
    end
    self.visible = false
    self.gui.Enabled = false
    print("[ShopGUI] 🏪 Shop closed")
end

function ShopGUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function ShopGUI:isVisible()
    return self.visible
end

return ShopGUI
