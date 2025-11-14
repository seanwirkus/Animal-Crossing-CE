--[[
	HomeBuildingGUI.luau
	
	Client-side UI for home building and upgrades.
	Shows current home status, upgrade options, and costs.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HomeBuildingGUI = {}
HomeBuildingGUI.__index = HomeBuildingGUI

-- Singleton instance
local _instance = nil

-- UI Colors (Animal Crossing themed)
local COLORS = {
    BG_PRIMARY = Color3.fromRGB(250, 245, 235), -- Cream
    BG_SECONDARY = Color3.fromRGB(255, 255, 255), -- White
    ACCENT_ORANGE = Color3.fromRGB(255, 160, 100),
    ACCENT_BROWN = Color3.fromRGB(139, 90, 43),
    TEXT_DARK = Color3.fromRGB(60, 50, 40),
    TEXT_LIGHT = Color3.fromRGB(255, 255, 255),
    CAN_UPGRADE = Color3.fromRGB(100, 200, 100),
    CANNOT_UPGRADE = Color3.fromRGB(200, 100, 100),
    BORDER = Color3.fromRGB(210, 180, 140),
}

function HomeBuildingGUI.new()
    -- Return existing instance if available
    if _instance then
        return _instance
    end

    local self = setmetatable({}, HomeBuildingGUI)

    self._gui = nil
    self._mainFrame = nil
    self._isOpen = false
    self._currentHomeData = nil
    self._playerBells = 0

    -- Create GUI
    self:createGUI()

    -- Setup remote listeners
    self:setupRemoteListeners()

    -- Listen for currency updates
    self:setupCurrencyListener()

    _instance = self
    print("[HomeBuildingGUI] ✅ Home Building GUI created")

    return self
end

function HomeBuildingGUI:setupRemoteListeners()
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        warn("[HomeBuildingGUI] RemoteEvents folder not found")
        return
    end

    -- Listen for home data updates
    -- This would be sent from server when home is placed/upgraded
    -- For now, we'll request it when opening
end

function HomeBuildingGUI:setupCurrencyListener()
    local currencyRemote = ReplicatedStorage:FindFirstChild("CurrencyEvent")
    if currencyRemote then
        currencyRemote.OnClientEvent:Connect(function(action, payload)
            if action == "UpdateBells" or action == "UpdateAll" then
                self._playerBells = payload.bells or payload.bells or 0
                self:updateUpgradeButtons()
            end
        end)

        -- Request current currency
        currencyRemote:FireServer("GetCurrency")
    end
end

function HomeBuildingGUI:createGUI()
    -- Create ScreenGui
    local screenGui = playerGui:FindFirstChild("HomeBuildingGUI")
    if screenGui then
        screenGui:Destroy()
    end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HomeBuildingGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    self._gui = screenGui

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 600)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = COLORS.BG_PRIMARY
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 3
    mainStroke.Color = COLORS.BORDER
    mainStroke.Parent = mainFrame

    self._mainFrame = mainFrame

    -- Title bar
    self:createTitleBar()

    -- Content area
    self:createContentArea()

    -- Close with ESC
    self:setupCloseKeybind()
end

function HomeBuildingGUI:createTitleBar()
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = COLORS.ACCENT_BROWN
    titleBar.BorderSizePixel = 0
    titleBar.Parent = self._mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    -- Only round top corners
    local titleMask = Instance.new("UIGradient")
    titleMask.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.95, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    titleMask.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🏠 Home Building"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = COLORS.TEXT_LIGHT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 5)
    closeButton.BackgroundColor3 = COLORS.ACCENT_ORANGE
    closeButton.Text = "✕"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.TextColor3 = COLORS.TEXT_LIGHT
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        self:close()
    end)
end

function HomeBuildingGUI:createContentArea()
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -40, 1, -70)
    contentFrame.Position = UDim2.new(0, 20, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = self._mainFrame

    -- Current home info
    local homeInfoLabel = Instance.new("TextLabel")
    homeInfoLabel.Name = "HomeInfoLabel"
    homeInfoLabel.Size = UDim2.new(1, 0, 0, 30)
    homeInfoLabel.Position = UDim2.new(0, 0, 0, 0)
    homeInfoLabel.BackgroundTransparency = 1
    homeInfoLabel.Text = "Current Home: None"
    homeInfoLabel.Font = Enum.Font.GothamBold
    homeInfoLabel.TextSize = 18
    homeInfoLabel.TextColor3 = COLORS.TEXT_DARK
    homeInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    homeInfoLabel.Parent = contentFrame

    self._homeInfoLabel = homeInfoLabel

    -- Upgrade section
    local upgradeLabel = Instance.new("TextLabel")
    upgradeLabel.Name = "UpgradeLabel"
    upgradeLabel.Size = UDim2.new(1, 0, 0, 30)
    upgradeLabel.Position = UDim2.new(0, 0, 0, 50)
    upgradeLabel.BackgroundTransparency = 1
    upgradeLabel.Text = "Upgrades"
    upgradeLabel.Font = Enum.Font.GothamBold
    upgradeLabel.TextSize = 18
    upgradeLabel.TextColor3 = COLORS.TEXT_DARK
    upgradeLabel.TextXAlignment = Enum.TextXAlignment.Left
    upgradeLabel.Parent = contentFrame

    -- Upgrade buttons container
    local upgradeContainer = Instance.new("Frame")
    upgradeContainer.Name = "UpgradeContainer"
    upgradeContainer.Size = UDim2.new(1, 0, 0, 400)
    upgradeContainer.Position = UDim2.new(0, 0, 0, 90)
    upgradeContainer.BackgroundTransparency = 1
    upgradeContainer.Parent = contentFrame

    self._upgradeContainer = upgradeContainer

    -- Create upgrade buttons
    self:createUpgradeButtons()
end

function HomeBuildingGUI:createUpgradeButtons()
    -- Clear existing buttons
    for _, child in ipairs(self._upgradeContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local upgrades = {
        { from = "Tent", to = "SmallHouse", cost = 5000, name = "Small House" },
        { from = "SmallHouse", to = "LargeHouse", cost = 10000, name = "Large House" },
        { from = "LargeHouse", to = "Mansion", cost = 25000, name = "Mansion" },
    }

    local currentSize = self._currentHomeData and self._currentHomeData.size or "None"
    local yOffset = 0

    for i, upgrade in ipairs(upgrades) do
        if currentSize == upgrade.from or (currentSize == "None" and i == 1) then
            local buttonFrame = self:createUpgradeButton(upgrade, currentSize)
            buttonFrame.Position = UDim2.new(0, 0, 0, yOffset)
            buttonFrame.Parent = self._upgradeContainer
            yOffset = yOffset + 100
        end
    end
end

function HomeBuildingGUI:createUpgradeButton(upgrade, currentSize)
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = upgrade.to .. "Button"
    buttonFrame.Size = UDim2.new(1, 0, 0, 90)
    buttonFrame.BackgroundColor3 = COLORS.BG_SECONDARY
    buttonFrame.BorderSizePixel = 0

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = buttonFrame

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Thickness = 2
    buttonStroke.Color = COLORS.BORDER
    buttonStroke.Parent = buttonFrame

    -- Upgrade name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.6, 0, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = upgrade.name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = COLORS.TEXT_DARK
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = buttonFrame

    -- Cost label
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(0.6, 0, 0, 25)
    costLabel.Position = UDim2.new(0, 10, 0, 40)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = "💰 " .. upgrade.cost .. " Bells"
    costLabel.Font = Enum.Font.Gotham
    costLabel.TextSize = 14
    costLabel.TextColor3 = COLORS.TEXT_DARK
    costLabel.TextXAlignment = Enum.TextXAlignment.Left
    costLabel.Parent = buttonFrame

    -- Upgrade button
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Name = "UpgradeButton"
    upgradeButton.Size = UDim2.new(0, 120, 0, 40)
    upgradeButton.Position = UDim2.new(1, -130, 0, 25)
    upgradeButton.BackgroundColor3 = COLORS.CAN_UPGRADE
    upgradeButton.Text = "Upgrade"
    upgradeButton.Font = Enum.Font.GothamBold
    upgradeButton.TextSize = 16
    upgradeButton.TextColor3 = COLORS.TEXT_LIGHT
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Parent = buttonFrame

    local buttonCorner2 = Instance.new("UICorner")
    buttonCorner2.CornerRadius = UDim.new(0, 8)
    buttonCorner2.Parent = upgradeButton

    -- Check if player can afford
    local canAfford = self._playerBells >= upgrade.cost
    if not canAfford then
        upgradeButton.BackgroundColor3 = COLORS.CANNOT_UPGRADE
        upgradeButton.Text = "Need " .. upgrade.cost .. " Bells"
    end

    upgradeButton.MouseButton1Click:Connect(function()
        if canAfford then
            self:requestUpgrade()
        else
            -- Show message
            print("[HomeBuildingGUI] Not enough bells! Need", upgrade.cost, "but have", self._playerBells)
        end
    end)

    -- Store reference for updating
    buttonFrame:SetAttribute("UpgradeData", upgrade.to)
    buttonFrame:SetAttribute("Cost", upgrade.cost)

    return buttonFrame
end

function HomeBuildingGUI:updateUpgradeButtons()
    for _, child in ipairs(self._upgradeContainer:GetChildren()) do
        if child:IsA("Frame") and child:GetAttribute("Cost") then
            local cost = child:GetAttribute("Cost")
            local upgradeButton = child:FindFirstChild("UpgradeButton")
            if upgradeButton then
                local canAfford = self._playerBells >= cost
                if canAfford then
                    upgradeButton.BackgroundColor3 = COLORS.CAN_UPGRADE
                    upgradeButton.Text = "Upgrade"
                else
                    upgradeButton.BackgroundColor3 = COLORS.CANNOT_UPGRADE
                    upgradeButton.Text = "Need " .. cost .. " Bells"
                end
            end
        end
    end
end

function HomeBuildingGUI:requestUpgrade()
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        warn("[HomeBuildingGUI] RemoteEvents folder not found")
        return
    end

    local upgradeRemote = remoteEventsFolder:FindFirstChild("UpgradeHome")
    if upgradeRemote then
        upgradeRemote:FireServer()
        print("[HomeBuildingGUI] Requested home upgrade")
    else
        warn("[HomeBuildingGUI] UpgradeHome remote not found")
    end
end

function HomeBuildingGUI:updateHomeInfo(homeData)
    self._currentHomeData = homeData

    if self._homeInfoLabel then
        if homeData then
            self._homeInfoLabel.Text = "Current Home: " .. (homeData.size or "Unknown")
        else
            self._homeInfoLabel.Text = "Current Home: None"
        end
    end

    -- Recreate upgrade buttons
    self:createUpgradeButtons()
end

function HomeBuildingGUI:setupCloseKeybind()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == Enum.KeyCode.Escape and self._isOpen then
            self:close()
        end
    end)
end

function HomeBuildingGUI:open()
    if self._isOpen then
        return
    end

    if self._gui then
        self._gui.Enabled = true
        self._isOpen = true

        -- Request current home data from server
        -- For now, we'll just show the UI
        print("[HomeBuildingGUI] Opened")
    end
end

function HomeBuildingGUI:close()
    if not self._isOpen then
        return
    end

    if self._gui then
        self._gui.Enabled = false
        self._isOpen = false
        print("[HomeBuildingGUI] Closed")
    end
end

function HomeBuildingGUI:toggle()
    if self._isOpen then
        self:close()
    else
        self:open()
    end
end

-- Initialize singleton
HomeBuildingGUI.new()

return HomeBuildingGUI
