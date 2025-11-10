-- DebugManager.lua
-- Manages a tabbed interface for various debug tools

local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local _UserInputService = game:GetService("UserInputService")

local DebugManager = {
    Client = {},
}

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local debugGui = Instance.new("ScreenGui")
debugGui.Name = "DebugGUIManager"
debugGui.Enabled = false
debugGui.ResetOnSpawn = false
debugGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 251, 231)  -- Cream background
mainFrame.BorderSizePixel = 0
mainFrame.Parent = debugGui

-- Add rounded corners
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(120, 100, 80)  -- Matching brown
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

-- Add corner to top bar
local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 8)
topBarCorner.Parent = topBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.Text = "Debug Menu"
titleLabel.Font = Enum.Font.GothamBold  -- Matching font
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
titleLabel.TextSize = 18
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, 0, 0, 30)
tabContainer.Position = UDim2.new(0, 0, 0, 40)
tabContainer.BackgroundColor3 = Color3.fromRGB(231, 221, 185)  -- Cream/beige matching
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabContainer

local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, 0, 1, -70)
contentContainer.Position = UDim2.new(0, 0, 0, 70)
contentContainer.BackgroundColor3 = Color3.fromRGB(255, 251, 231)  -- Cream background
contentContainer.BorderSizePixel = 0
contentContainer.Parent = mainFrame

local pages = {}
local tabs = {}

function DebugManager:CreateTab(title)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = title .. "Tab"
    tabButton.Size = UDim2.new(0, 100, 1, 0)
    tabButton.Text = title
    tabButton.Font = Enum.Font.GothamBold  -- Matching font
    tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text when active
    tabButton.TextSize = 14
    tabButton.BackgroundColor3 = Color3.fromRGB(139, 90, 43)  -- Brown when active
    tabButton.BorderSizePixel = 0
    tabButton.Parent = tabContainer
    
    -- Add rounded corners
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 4)
    tabCorner.Parent = tabButton

    local page = Instance.new("Frame")
    page.Name = title .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = contentContainer

    table.insert(pages, page)
    tabs[title] = { Button = tabButton, Page = page }

    tabButton.MouseButton1Click:Connect(function()
        self:SwitchToTab(title)
    end)

    return page
end

function DebugManager:SwitchToTab(title)
    for pageTitle, pageData in pairs(tabs) do
        local isVisible = (pageTitle == title)
        pageData.Page.Visible = isVisible
        if isVisible then
            pageData.Button.BackgroundColor3 = Color3.fromRGB(139, 90, 43)  -- Brown when active
            pageData.Button.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
        else
            pageData.Button.BackgroundColor3 = Color3.fromRGB(200, 180, 160)  -- Lighter when inactive
            pageData.Button.TextColor3 = Color3.fromRGB(80, 70, 60)  -- Darker text
        end
    end
end

function DebugManager:Toggle()
    debugGui.Enabled = not debugGui.Enabled
    if debugGui.Enabled then
        -- Select first tab by default if none are selected
        local firstTabTitle = next(tabs)
        if firstTabTitle then
            self:SwitchToTab(firstTabTitle)
        end
    end
    print("[DebugManager] Toggled visibility to:", debugGui.Enabled)
end

function DebugManager:Init(modules)
    print("[DebugManager] Initializing...")

    local itemBrowserPage = self:CreateTab("Item Browser")
    modules.DebugInventoryGrid:Init(itemBrowserPage)

    -- Create Season tab
    local seasonPage = self:CreateTab("Seasons")
    self:CreateSeasonControls(seasonPage)

    -- DebugCraftingMenu is now standalone (opened with C key), no longer nested in DebugManager

    -- Set a default tab
    local firstTabTitle = next(tabs)
    if firstTabTitle then
        self:SwitchToTab(firstTabTitle)
    end

    print("[DebugManager] ✅ Initialized")
end

function DebugManager:CreateSeasonControls(parentFrame)
    -- Create a scrolling frame for season controls
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = parentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "Season Controls"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(120, 100, 80)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.LayoutOrder = 1
    title.Parent = scrollFrame
    
    -- Description
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, 0, 0, 40)
    desc.Text = "Change the season to update visual effects and particle colors"
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextColor3 = Color3.fromRGB(80, 70, 60)
    desc.BackgroundTransparency = 1
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextWrapped = true
    desc.LayoutOrder = 2
    desc.Parent = scrollFrame
    
    -- Load VisualEffects module
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VisualEffects = require(script.Parent.VisualEffects)
    local ParticleEffects = require(script.Parent.ParticleEffects)
    
    -- Season buttons
    local seasons = {
        {name = "Spring", color = Color3.fromRGB(255, 200, 220), emoji = "🌸"},
        {name = "Summer", color = Color3.fromRGB(255, 230, 100), emoji = "☀️"},
        {name = "Fall", color = Color3.fromRGB(255, 150, 80), emoji = "🍂"},
        {name = "Winter", color = Color3.fromRGB(200, 230, 255), emoji = "❄️"}
    }
    
    for i, season in ipairs(seasons) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 50)
        button.Text = season.emoji .. " " .. season.name
        button.Font = Enum.Font.GothamBold
        button.TextSize = 18
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = season.color
        button.BorderSizePixel = 0
        button.LayoutOrder = 2 + i
        button.Parent = scrollFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            print("[DebugManager] Setting season to:", season.name)
            VisualEffects.setSeason(season.name:lower())
            ParticleEffects.setSeason(season.name:lower())
        end)
    end
    
    -- Current season display
    local currentLabel = Instance.new("TextLabel")
    currentLabel.Size = UDim2.new(1, 0, 0, 30)
    currentLabel.Text = "Current: Spring"
    currentLabel.Font = Enum.Font.GothamBold
    currentLabel.TextSize = 16
    currentLabel.TextColor3 = Color3.fromRGB(4, 175, 166)
    currentLabel.BackgroundTransparency = 1
    currentLabel.TextXAlignment = Enum.TextXAlignment.Left
    currentLabel.LayoutOrder = 10
    currentLabel.Parent = scrollFrame
    
    -- Update canvas size
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
end

return DebugManager
