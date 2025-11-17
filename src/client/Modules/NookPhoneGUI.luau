--[[
    NookPhoneGUI.luau
    Brand new NookPhone interface - 10x better with animations and helpful apps!
    
    Features:
    - Smooth animations (slide in/out, app transitions)
    - Multiple helpful apps to guide players
    - Modern ACNH-style design
    - App grid layout
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local NookPhoneGUI = {}
NookPhoneGUI.__index = NookPhoneGUI

-- Responsive sizing based on platform (using scale for proper responsiveness)
local function getPhoneSize()
    local screenSize = workspace.CurrentCamera.ViewportSize
    
    -- Detect platform
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local isTablet = UserInputService.TouchEnabled and UserInputService.KeyboardEnabled
    
    if isMobile then
        -- Mobile: Smaller icons with less padding to see all apps
        return {
            widthScale = 0.85,
            heightScale = 0.95,
            iconSize = 60, -- Reduced from 80
            iconSpacing = 6, -- Reduced from 10
            cols = 3
        }
    elseif isTablet then
        -- Tablet: Smaller icons with less padding
        return {
            widthScale = 0.7,
            heightScale = 0.9,
            iconSize = 70, -- Reduced from 100
            iconSpacing = 8, -- Reduced from 12
            cols = 3
        }
    else
        -- Desktop: Smaller icons with less padding
        local maxWidth = 500
        return {
            widthScale = math.min(0.5, maxWidth / screenSize.X),
            heightScale = 0.95,
            iconSize = 75, -- Reduced from 110
            iconSpacing = 8, -- Reduced from 12
            cols = 3
        }
    end
end

-- ACNH Color Palette
local COLORS = {
    PHONE_BG = Color3.fromRGB(45, 45, 50), -- Dark phone background
    SCREEN_BG = Color3.fromRGB(255, 251, 231), -- Cream screen
    APP_GRID_BG = Color3.fromRGB(245, 240, 230), -- Light cream
    APP_ICON_BG = Color3.fromRGB(255, 255, 255), -- White app icons
    ACCENT = Color3.fromRGB(4, 175, 166), -- Teal accent
    TEXT_PRIMARY = Color3.fromRGB(60, 50, 40), -- Dark text
    TEXT_SECONDARY = Color3.fromRGB(150, 140, 130), -- Gray text
    BUTTON_HOVER = Color3.fromRGB(235, 230, 220), -- Hover state
    BORDER = Color3.fromRGB(200, 190, 180), -- Light border
}

-- App definitions with icons and colors
local APPS = {
    {
        id = "guide",
        name = "Guide",
        icon = "📚",
        color = Color3.fromRGB(100, 150, 255),
        description = "Game tutorials & tips"
    },
    {
        id = "map",
        name = "Map",
        icon = "🗺️",
        color = Color3.fromRGB(76, 175, 80),
        description = "View island map"
    },
    {
        id = "inventory",
        name = "Inventory",
        icon = "🎒",
        color = Color3.fromRGB(255, 152, 0),
        description = "Manage items"
    },
    {
        id = "quests",
        name = "Quests",
        icon = "✅",
        color = Color3.fromRGB(156, 39, 176),
        description = "Active quests"
    },
    {
        id = "recipes",
        name = "Recipes",
        icon = "📖",
        color = Color3.fromRGB(244, 67, 54),
        description = "Crafting recipes"
    },
    {
        id = "tools",
        name = "Tools",
        icon = "🔧",
        color = Color3.fromRGB(121, 85, 72),
        description = "Equip tools"
    },
    {
        id = "nook_shopping",
        name = "Nook Shopping",
        icon = "🛒",
        color = Color3.fromRGB(4, 175, 166),
        description = "Shop items"
    },
    {
        id = "achievements",
        name = "Progress",
        icon = "🏆",
        color = Color3.fromRGB(255, 193, 7),
        description = "Your progress"
    },
    {
        id = "settings",
        name = "Settings",
        icon = "⚙️",
        color = Color3.fromRGB(158, 158, 158),
        description = "Game settings"
    },
    {
        id = "nook_home",
        name = "Nook Home",
        icon = "🏠",
        color = Color3.fromRGB(139, 90, 43), -- Brown/tan for home
        description = "Build & upgrade your home"
    },
}

function NookPhoneGUI.new()
    local self = setmetatable({}, NookPhoneGUI)
    
    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.visible = false
    self.currentApp = nil
    self.appModules = {} -- Store app module connections
    self.gui = nil
    self.animating = false
    self.guiManager = nil -- Will be set by init
    self.minimapModule = nil -- Will be set by init
    self.phoneSize = getPhoneSize()
    
    self:createGUI()
    self:setupConnections()
    
    print("[NookPhoneGUI] ✅ New NookPhone initialized (responsive)")
    return self
end

function NookPhoneGUI:init(guiManager, minimapModule)
    self.guiManager = guiManager
    self.minimapModule = minimapModule
    print("[NookPhoneGUI] ✅ Connected to GUIManager and Minimap")
end

function NookPhoneGUI:createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NookPhoneGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 100
    screenGui.Enabled = false
    screenGui.Parent = self.playerGui
    
    self.gui = screenGui
    
    -- Get responsive size
    local size = self.phoneSize
    
    -- Phone Container (slides in from bottom) - Responsive using scale
    local phoneContainer = Instance.new("Frame")
    phoneContainer.Name = "PhoneContainer"
    phoneContainer.Size = UDim2.new(size.widthScale, 0, size.heightScale, 0)
    phoneContainer.Position = UDim2.new(0.5, 0, 1, 0) -- Start off-screen bottom (centered)
    phoneContainer.AnchorPoint = Vector2.new(0.5, 1)
    phoneContainer.BackgroundColor3 = COLORS.PHONE_BG
    phoneContainer.BorderSizePixel = 0
    phoneContainer.ClipsDescendants = true
    phoneContainer.Parent = screenGui
    self.phoneContainer = phoneContainer
    
    local phoneCorner = Instance.new("UICorner")
    phoneCorner.CornerRadius = UDim.new(0, 40)
    phoneCorner.Parent = phoneContainer
    
    -- Phone border/bezel (adjusted for taller phone - less top/bottom padding)
    local phoneBezel = Instance.new("Frame")
    phoneBezel.Name = "Bezel"
    phoneBezel.Size = UDim2.new(1, -20, 1, -80) -- Reduced from -100 to -80 (more screen space)
    phoneBezel.Position = UDim2.new(0, 10, 0, 50) -- Reduced from 60 to 50 (less top padding)
    phoneBezel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    phoneBezel.BorderSizePixel = 0
    phoneBezel.Parent = phoneContainer
    
    local bezelCorner = Instance.new("UICorner")
    bezelCorner.CornerRadius = UDim.new(0, 30)
    bezelCorner.Parent = phoneBezel
    
    -- Screen (main content area) - adjusted for taller phone
    local screen = Instance.new("Frame")
    screen.Name = "Screen"
    screen.Size = UDim2.new(1, -30, 1, -90) -- Reduced from -110 to -90 (more content space)
    screen.Position = UDim2.new(0, 15, 0, 60) -- Reduced from 70 to 60 (less top padding)
    screen.BackgroundColor3 = COLORS.SCREEN_BG
    screen.BorderSizePixel = 0
    screen.Parent = phoneContainer
    
    local screenCorner = Instance.new("UICorner")
    screenCorner.CornerRadius = UDim.new(0, 25)
    screenCorner.Parent = screen
    
    -- Top bar (notch area)
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = COLORS.PHONE_BG
    topBar.BorderSizePixel = 0
    topBar.Parent = phoneContainer
    
    -- Time display
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(1, -40, 1, 0)
    timeLabel.Position = UDim2.new(0, 20, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "12:34 PM"
    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.Font = Enum.Font.GothamBold
    timeLabel.TextSize = 16
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = topBar
    
    -- Battery indicator
    local batteryLabel = Instance.new("TextLabel")
    batteryLabel.Name = "BatteryLabel"
    batteryLabel.Size = UDim2.new(0, 60, 1, 0)
    batteryLabel.Position = UDim2.new(1, -80, 0, 0)
    batteryLabel.BackgroundTransparency = 1
    batteryLabel.Text = "🔋 100%"
    batteryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    batteryLabel.Font = Enum.Font.Gotham
    batteryLabel.TextSize = 14
    batteryLabel.TextXAlignment = Enum.TextXAlignment.Right
    batteryLabel.Parent = topBar
    
    -- App Grid Container - adjusted for taller phone
    local appGridContainer = Instance.new("ScrollingFrame")
    appGridContainer.Name = "AppGrid"
    appGridContainer.Size = UDim2.new(1, -20, 1, -50) -- Reduced from -60 to -50 (more grid space)
    appGridContainer.Position = UDim2.new(0, 10, 0, 50) -- Keep same position
    appGridContainer.BackgroundTransparency = 1
    appGridContainer.BorderSizePixel = 0
    appGridContainer.ScrollBarThickness = 6
    appGridContainer.ScrollBarImageColor3 = COLORS.BORDER
    appGridContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    appGridContainer.Parent = screen
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, size.iconSize, 0, size.iconSize + 25) -- Reduced from +30 to +25 for tighter spacing
    gridLayout.CellPadding = UDim2.new(0, size.iconSpacing, 0, size.iconSpacing)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = appGridContainer
    
    local gridPadding = Instance.new("UIPadding")
    gridPadding.PaddingTop = UDim.new(0, 20)
    gridPadding.PaddingBottom = UDim.new(0, 20)
    gridPadding.PaddingLeft = UDim.new(0, 20)
    gridPadding.PaddingRight = UDim.new(0, 20)
    gridPadding.Parent = appGridContainer
    
    -- Create app icons
    for i, app in ipairs(APPS) do
        local appButton = self:createAppIcon(app, i)
        appButton.Parent = appGridContainer
    end
    
    -- Update canvas size (responsive)
    local numRows = math.ceil(#APPS / size.cols)
    local rowHeight = size.iconSize + 30 + size.iconSpacing
    appGridContainer.CanvasSize = UDim2.new(0, 0, 0, (numRows * rowHeight) + 40)
    
    -- Close button (swipe down or X button)
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 50, 0, 50)
    closeButton.Position = UDim2.new(0.5, -25, 1, -60)
    closeButton.BackgroundColor3 = COLORS.ACCENT
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 24
    closeButton.BorderSizePixel = 0
    closeButton.Parent = phoneContainer
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 25)
    closeCorner.Parent = closeButton
    
    -- App content container (for displaying app content)
    local appContentContainer = Instance.new("Frame")
    appContentContainer.Name = "AppContent"
    appContentContainer.Size = UDim2.new(1, 0, 1, 0)
    appContentContainer.Position = UDim2.new(1, 0, 0, 0) -- Start off-screen right
    appContentContainer.BackgroundColor3 = COLORS.SCREEN_BG
    appContentContainer.BorderSizePixel = 0
    appContentContainer.Visible = false
    appContentContainer.Parent = screen
    
    local appContentCorner = Instance.new("UICorner")
    appContentCorner.CornerRadius = UDim.new(0, 25)
    appContentCorner.Parent = appContentContainer
    
    -- App header (back button, title)
    local appHeader = Instance.new("Frame")
    appHeader.Name = "AppHeader"
    appHeader.Size = UDim2.new(1, 0, 0, 60)
    appHeader.Position = UDim2.new(0, 0, 0, 0)
    appHeader.BackgroundColor3 = COLORS.APP_GRID_BG
    appHeader.BorderSizePixel = 0
    appHeader.Parent = appContentContainer
    
    local headerStroke = Instance.new("UIStroke")
    headerStroke.Color = COLORS.BORDER
    headerStroke.Thickness = 2
    headerStroke.Parent = appHeader
    
    local backButton = Instance.new("TextButton")
    backButton.Name = "BackButton"
    backButton.Size = UDim2.new(0, 50, 0, 50)
    backButton.Position = UDim2.new(0, 10, 0, 5)
    backButton.BackgroundColor3 = COLORS.BUTTON_HOVER
    backButton.Text = "←"
    backButton.TextColor3 = COLORS.TEXT_PRIMARY
    backButton.Font = Enum.Font.GothamBold
    backButton.TextSize = 24
    backButton.BorderSizePixel = 0
    backButton.Parent = appHeader
    
    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 10)
    backCorner.Parent = backButton
    
    local appTitleLabel = Instance.new("TextLabel")
    appTitleLabel.Name = "AppTitle"
    appTitleLabel.Size = UDim2.new(1, -70, 1, 0)
    appTitleLabel.Position = UDim2.new(0, 70, 0, 0)
    appTitleLabel.BackgroundTransparency = 1
    appTitleLabel.Text = "App Name"
    appTitleLabel.TextColor3 = COLORS.TEXT_PRIMARY
    appTitleLabel.Font = Enum.Font.GothamBold
    appTitleLabel.TextSize = 22
    appTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    appTitleLabel.Parent = appHeader
    
    -- App content frame (scrollable)
    local appContentFrame = Instance.new("ScrollingFrame")
    appContentFrame.Name = "ContentFrame"
    appContentFrame.Size = UDim2.new(1, -20, 1, -70)
    appContentFrame.Position = UDim2.new(0, 10, 0, 70)
    appContentFrame.BackgroundTransparency = 1
    appContentFrame.BorderSizePixel = 0
    appContentFrame.ScrollBarThickness = 6
    appContentFrame.ScrollBarImageColor3 = COLORS.BORDER
    appContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    appContentFrame.Parent = appContentContainer
    
    self.phoneContainer = phoneContainer
    self.appGrid = appGridContainer
    self.appContentContainer = appContentContainer
    self.appHeader = appHeader
    self.appTitleLabel = appTitleLabel
    self.appContentFrame = appContentFrame
    self.closeButton = closeButton
    self.backButton = backButton
    self.timeLabel = timeLabel
    
    -- Store references for animations (responsive - using scale)
    self.phoneStartPos = UDim2.new(0.5, 0, 1, 0) -- Off-screen bottom
    self.phoneVisiblePos = UDim2.new(0.5, 0, 1, -20) -- 20px from bottom when visible (centered)
    
    -- Listen for screen size changes (mobile rotation, etc.)
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        self:updateResponsiveSize()
    end)
end

function NookPhoneGUI:updateResponsiveSize()
    if not self.phoneContainer then return end
    
    local size = getPhoneSize()
    self.phoneSize = size
    
    -- Update phone container size (using scale)
    self.phoneContainer.Size = UDim2.new(size.widthScale, 0, size.heightScale, 0)
    
    -- Update visible position (centered)
    self.phoneVisiblePos = UDim2.new(0.5, 0, 1, -20)
    
    -- If currently visible, update position
    if self.visible then
        self.phoneContainer.Position = self.phoneVisiblePos
    end
end

function NookPhoneGUI:createAppIcon(app, index)
    local size = self.phoneSize
    local iconSize = size.iconSize - 10 -- Reduced from -20 to make icons bigger relative to spacing
    
    local appButton = Instance.new("TextButton")
    appButton.Name = app.id
    appButton.LayoutOrder = index
    appButton.BackgroundTransparency = 1
    appButton.BorderSizePixel = 0
    appButton.Text = ""
    
    -- App icon background
    local iconBg = Instance.new("Frame")
    iconBg.Name = "IconBg"
    iconBg.Size = UDim2.new(0, iconSize, 0, iconSize)
    iconBg.Position = UDim2.new(0.5, -iconSize/2, 0, 0)
    iconBg.BackgroundColor3 = app.color
    iconBg.BorderSizePixel = 0
    iconBg.Parent = appButton
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 16)
    iconCorner.Parent = iconBg
    
    -- App icon emoji/text
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.Position = UDim2.new(0, 0, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = app.icon
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 36
    iconLabel.Parent = iconBg
    
    -- App name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, 0, 0, 20) -- Reduced from 30
    nameLabel.Position = UDim2.new(0, 0, 1, -20) -- Reduced from -30
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = app.name
    nameLabel.TextColor3 = COLORS.TEXT_PRIMARY
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 12 -- Reduced from 14
    nameLabel.TextWrapped = true
    nameLabel.Parent = appButton
    
    -- Hover effect (desktop only)
    if not UserInputService.TouchEnabled then
        appButton.MouseEnter:Connect(function()
            if not self.animating then
                local hoverSize = iconSize + 10
                local tween = TweenService:Create(
                    iconBg,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                    { Size = UDim2.new(0, hoverSize, 0, hoverSize), Position = UDim2.new(0.5, -hoverSize/2, 0, -5) }
                )
                tween:Play()
            end
        end)
        
        appButton.MouseLeave:Connect(function()
            if not self.animating then
                local tween = TweenService:Create(
                    iconBg,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                    { Size = UDim2.new(0, iconSize, 0, iconSize), Position = UDim2.new(0.5, -iconSize/2, 0, 0) }
                )
                tween:Play()
            end
        end)
    end
    
    -- Click handler
    appButton.MouseButton1Click:Connect(function()
        self:openApp(app.id)
    end)
    
    return appButton
end

function NookPhoneGUI:setupConnections()
    -- Close button
    self.closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)
    
    -- Back button
    self.backButton.MouseButton1Click:Connect(function()
        self:closeApp()
    end)
    
    -- ESC key to close
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
            if self.visible then
                if self.currentApp then
                    self:closeApp()
                else
                    self:hide()
                end
            end
        end
    end)
end

function NookPhoneGUI:openApp(appId)
    if self.animating then return end
    
    local app = nil
    for _, a in ipairs(APPS) do
        if a.id == appId then
            app = a
            break
        end
    end
    
    if not app then
        warn("[NookPhoneGUI] ⚠️ App not found:", appId)
        return
    end
    
    -- Handle external apps (open via GUIManager instead of showing in phone)
    if appId == "inventory" or appId == "quests" or appId == "recipes" or 
       appId == "tools" or appId == "nook_shopping" or appId == "settings" or 
       appId == "map" or appId == "nook_home" then
        self:hide() -- Close phone first
        
        -- Small delay to let phone close animation finish
        task.spawn(function()
            task.wait(0.2)
            if appId == "inventory" and self.guiManager then
                self.guiManager:showGUI("inventory")
            elseif appId == "quests" and self.guiManager then
                self.guiManager:showGUI("QuestGUI")
            elseif appId == "recipes" and self.guiManager then
                self.guiManager:showGUI("recipes")
            elseif appId == "tools" and self.guiManager then
                self.guiManager:showGUI("toolRing")
            elseif appId == "nook_shopping" and self.guiManager then
                self.guiManager:showGUI("nookShopping")
            elseif appId == "settings" and self.guiManager then
                self.guiManager:showGUI("settings")
            elseif appId == "nook_home" and self.guiManager then
                self.guiManager:showGUI("building") -- HomeBuildingGUI is registered as "building"
            elseif appId == "map" then
                -- Open minimap directly
                if self.minimapModule then
                    self.minimapModule:toggle()
                else
                    -- Fallback: try to require it
                    local success, minimap = pcall(function()
                        return require(self.playerGui:FindFirstChild("Client"):FindFirstChild("Modules"):FindFirstChild("Minimap"))
                    end)
                    if success and minimap then
                        minimap:toggle()
                    end
                end
            end
        end)
        return
    end
    
    -- Internal apps (Guide, Achievements) show in phone
    self.animating = true
    self.currentApp = appId
    
    -- Update app title
    self.appTitleLabel.Text = app.name
    
    -- Clear previous content
    self.appContentFrame:ClearAllChildren()
    
    -- Load app content
    self:loadAppContent(appId)
    
    -- Slide app content in from right
    self.appContentContainer.Visible = true
    self.appContentContainer.Position = UDim2.new(1, 0, 0, 0)
    
    local slideIn = TweenService:Create(
        self.appContentContainer,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 0, 0, 0) }
    )
    
    slideIn:Play()
    slideIn.Completed:Connect(function()
        self.animating = false
        self.appGrid.Visible = false
    end)
    
    print("[NookPhoneGUI] 📱 Opened app:", app.name)
end

function NookPhoneGUI:closeApp()
    if self.animating or not self.currentApp then return end
    
    self.animating = true
    
    -- Slide app content out to right
    local slideOut = TweenService:Create(
        self.appContentContainer,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(1, 0, 0, 0) }
    )
    
    slideOut:Play()
    slideOut.Completed:Connect(function()
        self.appContentContainer.Visible = false
        self.appGrid.Visible = true
        self.currentApp = nil
        self.animating = false
    end)
end

function NookPhoneGUI:loadAppContent(appId)
    local content = self.appContentFrame
    
    if appId == "guide" then
        self:loadGuideApp(content)
    elseif appId == "map" then
        self:loadMapApp(content)
    elseif appId == "inventory" then
        self:loadInventoryApp(content)
    elseif appId == "quests" then
        self:loadQuestsApp(content)
    elseif appId == "recipes" then
        self:loadRecipesApp(content)
    elseif appId == "tools" then
        self:loadToolsApp(content)
    elseif appId == "achievements" then
        self:loadAchievementsApp(content)
    elseif appId == "settings" then
        self:loadSettingsApp(content)
    else
        self:loadPlaceholderApp(content, appId)
    end
end

function NookPhoneGUI:loadGuideApp(content)
    local guideLabel = Instance.new("TextLabel")
    guideLabel.Size = UDim2.new(1, -40, 0, 40)
    guideLabel.Position = UDim2.new(0, 20, 0, 20)
    guideLabel.BackgroundTransparency = 1
    guideLabel.Text = "📚 Game Guide"
    guideLabel.TextColor3 = COLORS.TEXT_PRIMARY
    guideLabel.Font = Enum.Font.GothamBold
    guideLabel.TextSize = 28
    guideLabel.TextXAlignment = Enum.TextXAlignment.Left
    guideLabel.Parent = content
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 15)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 70)
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = content
    
    local guides = {
        { title = "🎣 Fishing", desc = "Equip a fishing rod and cast near water. Wait for the bobber to go under, then press E!" },
        { title = "🪓 Chopping Trees", desc = "Use an axe to chop trees. They'll drop wood and sometimes fruit!" },
        { title = "🕳️ Digging", desc = "Equip a shovel and right-click on the ground to dig holes. Find fossils and bells!" },
        { title = "🏠 Building", desc = "Press H to open build mode. Place furniture and decorations!" },
        { title = "💰 Bells", desc = "Sell items, complete quests, and find buried bells to earn currency." },
        { title = "🎒 Inventory", desc = "Press E to open your inventory. Manage items and tools here." },
        { title = "✅ Quests", desc = "Press J to view quests. Complete them for rewards!" },
        { title = "🔧 Crafting", desc = "Press C to craft items. Use resources you've collected." },
    }
    
    for i, guide in ipairs(guides) do
        local guideCard = self:createGuideCard(guide.title, guide.desc, i)
        guideCard.Parent = content
    end
    
    content.CanvasSize = UDim2.new(0, 0, 0, #guides * 120 + 100)
end

function NookPhoneGUI:createGuideCard(title, description, index)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 100)
    card.BackgroundColor3 = COLORS.APP_ICON_BG
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = COLORS.BORDER
    cardStroke.Thickness = 2
    cardStroke.Parent = card
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = COLORS.TEXT_PRIMARY
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = card
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 1, -50)
    descLabel.Position = UDim2.new(0, 10, 0, 40)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = COLORS.TEXT_SECONDARY
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 14
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = card
    
    return card
end

function NookPhoneGUI:loadMapApp(content)
    -- Map opens externally, but show nice info card in phone
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim2.new(0, 20)
    padding.PaddingLeft = UDim2.new(0, 20)
    padding.PaddingRight = UDim2.new(0, 20)
    padding.PaddingBottom = UDim2.new(0, 20)
    padding.Parent = content
    
    local card = self:createInfoCard("🗺️ Island Map", "Opening map...", {
        "Press M to view the full island map!",
        "",
        "Explore your island and discover:",
        "• Resource locations",
        "• Building sites",
        "• Special areas",
        "• Player homes"
    }, Color3.fromRGB(76, 175, 80))
    card.Parent = content
    
    content.CanvasSize = UDim2.new(0, 0, 0, 350)
end

function NookPhoneGUI:loadInventoryApp(content)
    -- Inventory opens externally, but show nice info card
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim2.new(0, 20)
    padding.PaddingLeft = UDim2.new(0, 20)
    padding.PaddingRight = UDim2.new(0, 20)
    padding.PaddingBottom = UDim2.new(0, 20)
    padding.Parent = content
    
    local card = self:createInfoCard("🎒 Inventory", "Opening inventory...", {
        "Press E to manage your items!",
        "",
        "Features:",
        "• Manage items and tools",
        "• Drag items to organize",
        "• Right-click for options",
        "• Expand inventory with upgrades"
    }, Color3.fromRGB(255, 152, 0))
    card.Parent = content
    
    content.CanvasSize = UDim2.new(0, 0, 0, 350)
end

function NookPhoneGUI:loadQuestsApp(content)
    -- Quests opens externally, but show nice info card
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim2.new(0, 20)
    padding.PaddingLeft = UDim2.new(0, 20)
    padding.PaddingRight = UDim2.new(0, 20)
    padding.PaddingBottom = UDim2.new(0, 20)
    padding.Parent = content
    
    local card = self:createInfoCard("✅ Quests", "Opening quests...", {
        "Press J to view all quests!",
        "",
        "Features:",
        "• Track your progress",
        "• Earn bells and items",
        "• Complete daily tasks",
        "• Unlock achievements"
    }, Color3.fromRGB(156, 39, 176))
    card.Parent = content
    
    content.CanvasSize = UDim2.new(0, 0, 0, 350)
end

function NookPhoneGUI:loadRecipesApp(content)
    -- Recipes opens externally, but show nice info card
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim2.new(0, 20)
    padding.PaddingLeft = UDim2.new(0, 20)
    padding.PaddingRight = UDim2.new(0, 20)
    padding.PaddingBottom = UDim2.new(0, 20)
    padding.Parent = content
    
    local card = self:createInfoCard("📖 Recipes", "Opening recipes...", {
        "Press C to open crafting!",
        "",
        "Features:",
        "• View all recipes",
        "• Craft items at workbench",
        "• Learn new recipes",
        "• Track materials needed"
    }, Color3.fromRGB(244, 67, 54))
    card.Parent = content
    
    content.CanvasSize = UDim2.new(0, 0, 0, 350)
end

function NookPhoneGUI:loadToolsApp(content)
    -- Tools opens externally, but show nice info card
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim2.new(0, 20)
    padding.PaddingLeft = UDim2.new(0, 20)
    padding.PaddingRight = UDim2.new(0, 20)
    padding.PaddingBottom = UDim2.new(0, 20)
    padding.Parent = content
    
    local card = self:createInfoCard("🔧 Tools", "Opening tool wheel...", {
        "Press T to open tool wheel!",
        "",
        "Available tools:",
        "• Fishing Rod - Catch fish",
        "• Shovel - Dig holes & trees",
        "• Axe - Chop trees",
        "• Net - Catch bugs",
        "• Slingshot - Pop balloons"
    }, Color3.fromRGB(121, 85, 72))
    card.Parent = content
    
    content.CanvasSize = UDim2.new(0, 0, 0, 400)
end

function NookPhoneGUI:loadAchievementsApp(content)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim2.new(0, 20)
    padding.PaddingLeft = UDim2.new(0, 20)
    padding.PaddingRight = UDim2.new(0, 20)
    padding.PaddingBottom = UDim2.new(0, 20)
    padding.Parent = content
    
    local card = self:createInfoCard("🏆 Your Progress", "Track your achievements", {
        "Coming soon!",
        "",
        "Track your progress:",
        "• Items collected",
        "• Quests completed",
        "• Buildings placed",
        "• Time played",
        "• Special milestones"
    }, Color3.fromRGB(255, 193, 7))
    card.Parent = content
    
    content.CanvasSize = UDim2.new(0, 0, 0, 400)
end

function NookPhoneGUI:loadSettingsApp(content)
    -- Settings opens externally, but show nice info card
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim2.new(0, 20)
    padding.PaddingLeft = UDim2.new(0, 20)
    padding.PaddingRight = UDim2.new(0, 20)
    padding.PaddingBottom = UDim2.new(0, 20)
    padding.Parent = content
    
    local card = self:createInfoCard("⚙️ Settings", "Opening settings...", {
        "Press ESC to open settings!",
        "",
        "Available options:",
        "• Graphics options",
        "• Audio settings",
        "• Controls & keybinds",
        "• Account settings"
    }, Color3.fromRGB(158, 158, 158))
    card.Parent = content
    
    content.CanvasSize = UDim2.new(0, 0, 0, 350)
end

function NookPhoneGUI:loadPlaceholderApp(content, appId)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim2.new(0, 20)
    padding.PaddingLeft = UDim2.new(0, 20)
    padding.PaddingRight = UDim2.new(0, 20)
    padding.PaddingBottom = UDim2.new(0, 20)
    padding.Parent = content
    
    local card = self:createInfoCard("📱 " .. appId, "Coming soon!", {
        "This app is under development.",
        "",
        "Check back later for updates!"
    }, Color3.fromRGB(158, 158, 158))
    card.Parent = content
    
    content.CanvasSize = UDim2.new(0, 0, 0, 250)
end

-- Helper function to create nice info cards
function NookPhoneGUI:createInfoCard(title, subtitle, lines, accentColor)
    accentColor = accentColor or COLORS.ACCENT
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.BackgroundColor3 = COLORS.APP_ICON_BG
    card.BorderSizePixel = 0
    card.AutomaticSize = Enum.AutomaticSize.Y
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 16)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = accentColor
    cardStroke.Thickness = 3
    cardStroke.Transparency = 0.3
    cardStroke.Parent = card
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 20)
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = card
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = card
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 35)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = COLORS.TEXT_PRIMARY
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 24
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.LayoutOrder = 1
    titleLabel.Parent = card
    
    -- Subtitle
    if subtitle and subtitle ~= "" then
        local subtitleLabel = Instance.new("TextLabel")
        subtitleLabel.Size = UDim2.new(1, 0, 0, 25)
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Text = subtitle
        subtitleLabel.TextColor3 = COLORS.TEXT_SECONDARY
        subtitleLabel.Font = Enum.Font.Gotham
        subtitleLabel.TextSize = 16
        subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        subtitleLabel.LayoutOrder = 2
        subtitleLabel.Parent = card
    end
    
    -- Lines
    if lines then
        for i, line in ipairs(lines) do
            local lineLabel = Instance.new("TextLabel")
            lineLabel.Size = UDim2.new(1, 0, 0, 20)
            lineLabel.BackgroundTransparency = 1
            lineLabel.Text = line
            lineLabel.TextColor3 = line == "" and Color3.new(0, 0, 0) or COLORS.TEXT_SECONDARY
            lineLabel.Font = Enum.Font.Gotham
            lineLabel.TextSize = 15
            lineLabel.TextXAlignment = Enum.TextXAlignment.Left
            lineLabel.LayoutOrder = 2 + i
            lineLabel.Parent = card
        end
    end
    
    return card
end

function NookPhoneGUI:updateTime()
    if not self.timeLabel then return end
    
    local time = os.date("*t", os.time())
    local hour = time.hour
    local minute = time.min
    local ampm = hour >= 12 and "PM" or "AM"
    hour = hour > 12 and hour - 12 or (hour == 0 and 12 or hour)
    
    local timeString = string.format("%d:%02d %s", hour, minute, ampm)
    self.timeLabel.Text = timeString
end

function NookPhoneGUI:show()
    if self.visible or self.animating then return end
    
    self.animating = true
    self.visible = true
    self.gui.Enabled = true
    
    -- Reset position
    self.phoneContainer.Position = self.phoneStartPos
    self.appGrid.Visible = true
    self.appContentContainer.Visible = false
    self.currentApp = nil
    
    -- Slide in from bottom
    local slideIn = TweenService:Create(
        self.phoneContainer,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = self.phoneVisiblePos }
    )
    
    slideIn:Play()
    slideIn.Completed:Connect(function()
        self.animating = false
        self:updateTime()
    end)
    
    -- Update time every minute
    task.spawn(function()
        while self.visible do
            self:updateTime()
            task.wait(60)
        end
    end)
    
    print("[NookPhoneGUI] 📱 NookPhone opened")
end

function NookPhoneGUI:hide()
    if not self.visible or self.animating then return end
    
    self.animating = true
    
    -- Close any open app first
    if self.currentApp then
        self:closeApp()
        task.wait(0.3)
    end
    
    -- Slide out to bottom
    local slideOut = TweenService:Create(
        self.phoneContainer,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = self.phoneStartPos }
    )
    
    slideOut:Play()
    slideOut.Completed:Connect(function()
        self.visible = false
        self.animating = false
        self.gui.Enabled = false
    end)
    
    print("[NookPhoneGUI] 📱 NookPhone closed")
end

function NookPhoneGUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function NookPhoneGUI:isVisible()
    return self.visible
end

-- Connect external modules
function NookPhoneGUI:connectApp(appId, module)
    self.appModules[appId] = module
end

function NookPhoneGUI:setShopGUI(shopGUI)
    self.appModules["nook_shopping"] = shopGUI
end

-- Alias methods for GUIManager compatibility
NookPhoneGUI.Show = NookPhoneGUI.show
NookPhoneGUI.Hide = NookPhoneGUI.hide
NookPhoneGUI.Toggle = NookPhoneGUI.toggle

return NookPhoneGUI