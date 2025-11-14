--[[
    PremiumShopGUI.luau
    Premium shop for Robux purchases (Bells, Nook Miles, etc.)
    Monetization screen for the game
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local PremiumShopGUI = {}
PremiumShopGUI.__index = PremiumShopGUI

-- Premium product definitions
local PREMIUM_PRODUCTS = {
    {
        id = "bells_small",
        name = "Bells Bundle (Small)",
        description = "5,000 Bells",
        robuxPrice = 49,
        productId = 0, -- Set this to your actual product ID
        reward = { bells = 5000, miles = 0 },
        icon = "💰",
    },
    {
        id = "bells_medium",
        name = "Bells Bundle (Medium)",
        description = "12,000 Bells",
        robuxPrice = 99,
        productId = 0, -- Set this to your actual product ID
        reward = { bells = 12000, miles = 0 },
        icon = "💰",
    },
    {
        id = "bells_large",
        name = "Bells Bundle (Large)",
        description = "35,000 Bells",
        robuxPrice = 249,
        productId = 0, -- Set this to your actual product ID
        reward = { bells = 35000, miles = 0 },
        icon = "💰",
    },
    {
        id = "miles_pack",
        name = "Nook Miles Pack",
        description = "500 Nook Miles",
        robuxPrice = 149,
        productId = 0, -- Set this to your actual product ID
        reward = { bells = 0, miles = 500 },
        icon = "✈️",
    },
    {
        id = "bells_mega",
        name = "Bells Bundle (Mega)",
        description = "100,000 Bells + 1,000 Miles",
        robuxPrice = 499,
        productId = 0, -- Set this to your actual product ID
        reward = { bells = 100000, miles = 1000 },
        icon = "💎",
    },
}

function PremiumShopGUI.new()
    local self = setmetatable({}, PremiumShopGUI)

    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.visible = false
    self.gui = nil

    self:createGUI()
    self:connectToServer()

    print("[PremiumShopGUI] ✅ Initialized")
    return self
end

function PremiumShopGUI:createGUI()
    -- Create ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "PremiumShopGUI"
    self.gui.DisplayOrder = 100 -- Very high to be on top
    self.gui.ResetOnSpawn = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui.Enabled = false
    self.gui.Parent = self.playerGui

    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 800, 0, 600)
    container.Position = UDim2.new(0.5, 0, 0.55, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    container.BorderSizePixel = 0
    container.Parent = self.gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = container

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = container

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "💎 Premium Shop"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 28
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 24
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)

    -- Scrollable content area
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, -40, 1, -100)
    scrollFrame.Position = UDim2.new(0, 20, 0, 80)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = container

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 20)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame

    -- Create product cards
    for i, product in ipairs(PREMIUM_PRODUCTS) do
        local card = self:createProductCard(product, i)
        card.Parent = scrollFrame
    end

    -- Update canvas size
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)

    self.container = container
    self.scrollFrame = scrollFrame
end

function PremiumShopGUI:createProductCard(product, index)
    local card = Instance.new("Frame")
    card.Name = product.id
    card.Size = UDim2.new(1, -20, 0, 120)
    card.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    card.BorderSizePixel = 0
    card.LayoutOrder = index

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 80, 0, 80)
    iconLabel.Position = UDim2.new(0, 20, 0.5, 0)
    iconLabel.AnchorPoint = Vector2.new(0, 0.5)
    iconLabel.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
    iconLabel.Text = product.icon
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextSize = 48
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.BorderSizePixel = 0
    iconLabel.Parent = card

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = iconLabel

    -- Product info
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -280, 0, 30)
    nameLabel.Position = UDim2.new(0, 120, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = product.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 20
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -280, 0, 25)
    descLabel.Position = UDim2.new(0, 120, 0, 50)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = product.description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextSize = 16
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = card

    -- Price and buy button
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "Price"
    priceLabel.Size = UDim2.new(0, 100, 0, 30)
    priceLabel.Position = UDim2.new(1, -180, 0, 20)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = product.robuxPrice .. " R$"
    priceLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
    priceLabel.TextSize = 22
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextXAlignment = Enum.TextXAlignment.Right
    priceLabel.Parent = card

    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(0, 120, 0, 40)
    buyButton.Position = UDim2.new(1, -140, 0, 60)
    buyButton.AnchorPoint = Vector2.new(1, 0)
    buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    buyButton.Text = "Purchase"
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.TextSize = 18
    buyButton.Font = Enum.Font.GothamBold
    buyButton.BorderSizePixel = 0
    buyButton.Parent = card

    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 8)
    buyCorner.Parent = buyButton

    -- Purchase handler
    buyButton.MouseButton1Click:Connect(function()
        self:purchaseProduct(product)
    end)

    -- Hover effects
    buyButton.MouseEnter:Connect(function()
        local tween = TweenService:Create(buyButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(0, 230, 120),
        })
        tween:Play()
    end)

    buyButton.MouseLeave:Connect(function()
        local tween = TweenService:Create(buyButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(0, 200, 100),
        })
        tween:Play()
    end)

    return card
end

function PremiumShopGUI:purchaseProduct(product)
    if product.productId == 0 then
        warn("[PremiumShopGUI] ⚠️ Product ID not set for:", product.name)
        warn("   Please set product.productId to your Roblox Developer Product ID")
        return
    end

    print("[PremiumShopGUI] 💳 Purchasing:", product.name, "for", product.robuxPrice, "Robux")

    -- Prompt purchase
    MarketplaceService:PromptProductPurchase(self.player, product.productId)
end

function PremiumShopGUI:connectToServer()
    -- Listen for purchase confirmations from server
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEventsFolder then
        local purchaseRemote = remoteEventsFolder:FindFirstChild("PremiumPurchase")
        if purchaseRemote then
            purchaseRemote.OnClientEvent:Connect(function(success, productId, message)
                if success then
                    print("[PremiumShopGUI] ✅ Purchase successful:", message)
                else
                    warn("[PremiumShopGUI] ❌ Purchase failed:", message)
                end
            end)
        end
    end
end

function PremiumShopGUI:show()
    if self.visible then
        return
    end
    self.visible = true
    self.gui.Enabled = true

    -- Animate in
    self.container.Size = UDim2.new(0, 0, 0, 0)
    local tween = TweenService:Create(self.container, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 800, 0, 600),
    })
    tween:Play()

    print("[PremiumShopGUI] 💎 Premium shop opened")
end

function PremiumShopGUI:hide()
    if not self.visible then
        return
    end
    self.visible = false

    -- Animate out
    local tween = TweenService:Create(self.container, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 0, 0, 0),
    })
    tween:Play()

    tween.Completed:Connect(function()
        self.gui.Enabled = false
    end)

    print("[PremiumShopGUI] 💎 Premium shop closed")
end

function PremiumShopGUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function PremiumShopGUI:isVisible()
    return self.visible
end

-- Alias methods for GUIManager compatibility
PremiumShopGUI.Show = PremiumShopGUI.show
PremiumShopGUI.Hide = PremiumShopGUI.hide
PremiumShopGUI.Toggle = PremiumShopGUI.toggle

return PremiumShopGUI
