--[[
	HomeScreen.luau

	Animal Crossing-inspired homescreen overlay that appears after the loading
	screen finishes. Provides a welcome moment, quick access to primary systems,
	and adapts to different device sizes.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LOCAL_PLAYER = Players.LocalPlayer

local HomeScreen = {}

-- Module state references
local deps = {} :: { guiManager: any?, gameMenu: any?, settingsController: any?, onStart: (() -> ())? }
local refs = {
    screenGui = nil :: ScreenGui?,
    overlay = nil :: Frame?,
    panel = nil :: Frame?,
    panelPadding = nil :: UIPadding?,
    layout = nil :: UIListLayout?,
    leftColumn = nil :: Frame?,
    rightColumn = nil :: Frame?,
    startButton = nil :: TextButton?,
    tipLabel = nil :: TextLabel?,
    quickActions = nil :: Frame?,
    heroImage = nil :: ImageLabel?,
    newsFrame = nil :: Frame?,
    newsDescription = nil :: TextLabel?,
}

local isInitialized = false
local isVisible = false
local started = false
local onStartCallback: (() -> ())? = nil

local executeStartSequence: ((() -> ())?) -> () = function() end -- forward declaration

local COLORS = {
    overlayBase = Color3.fromRGB(28, 48, 66),
    overlayGradientTop = Color3.fromRGB(62, 105, 133),
    overlayGradientMid = Color3.fromRGB(89, 147, 141),
    overlayGradientBottom = Color3.fromRGB(51, 77, 100),

    panelBackground = Color3.fromRGB(247, 242, 222),
    panelStroke = Color3.fromRGB(146, 128, 98),

    titleText = Color3.fromRGB(85, 62, 40),
    subtitleText = Color3.fromRGB(118, 95, 67),
    bodyText = Color3.fromRGB(96, 75, 54),

    startButtonDefault = Color3.fromRGB(56, 168, 118),
    startButtonHover = Color3.fromRGB(44, 149, 104),
    startButtonStroke = Color3.fromRGB(255, 255, 255),

    quickBackground = Color3.fromRGB(234, 227, 204),
    quickHover = Color3.fromRGB(240, 233, 212),
    quickStroke = Color3.fromRGB(186, 166, 130),
    quickTitle = Color3.fromRGB(93, 72, 50),
    quickDescription = Color3.fromRGB(125, 104, 84),

    newsBackground = Color3.fromRGB(231, 216, 181),
    newsStroke = Color3.fromRGB(189, 159, 115),
    newsTitle = Color3.fromRGB(117, 92, 60),
    newsBody = Color3.fromRGB(106, 84, 55),
}

local ANIMATION = {
    overlayIn = 0.35,
    popupIn = 0.4,
    exitDuration = 0.25,
}

local BREAKPOINTS = {
    mobile = 760,
    tablet = 1180,
}

local HERO_IMAGE_ASSET = "rbxassetid://114347612099449"

local WELCOME_TIPS = {
    "🌿 Chat with villagers daily to unlock new surprises.",
    "🎣 Fish at dawn and dusk for rare catches.",
    "🛠️ Press T to open your tool wheel and swap quickly.",
    "🍃 Daily tasks award Nook Miles—check in often!",
    "🎒 Press E to open your inventory anywhere, anytime.",
    "⚙️ Use the Game Menu (`) to tweak graphics and controls.",
    "📱 Tap the Nook Phone (P) for quests and shopping.",
}

local NEWS_LINES = {
    "• Fishing tours are live near the pier—bring a rod!",
    "• Tom Nook stocked fresh DIY recipes at Resident Services.",
    "• Enable Debug Mode for dev tools in Game Menu → Debug.",
}

local LAYOUT_PRESETS = {
    mobile = {
        panelWidthScale = 0.96,
        panelMaxWidth = 620,
        layoutDirection = Enum.FillDirection.Vertical,
        layoutPadding = 16,
        panelPadding = { top = 20, bottom = 24, sides = 22 },
        leftWidthScale = 1,
        rightWidthScale = 1,
        showHero = false,
        showNews = true,
        startButtonSize = UDim2.new(1, 0, 0, 58),
        startButtonTextSize = 22,
        titleSize = 38,
        subtitleSize = 18,
        tipSize = 16,
        quickTitleSize = 16,
        quickDescSize = 14,
        newsTitleSize = 18,
        newsBodySize = 15,
    },
    tablet = {
        panelWidthScale = 0.88,
        panelMaxWidth = 780,
        layoutDirection = Enum.FillDirection.Vertical,
        layoutPadding = 20,
        panelPadding = { top = 24, bottom = 26, sides = 28 },
        leftWidthScale = 1,
        rightWidthScale = 1,
        showHero = true,
        showNews = true,
        startButtonSize = UDim2.new(0, 320, 0, 62),
        startButtonTextSize = 24,
        titleSize = 42,
        subtitleSize = 19,
        tipSize = 17,
        quickTitleSize = 17,
        quickDescSize = 15,
        newsTitleSize = 19,
        newsBodySize = 16,
    },
    desktop = {
        panelWidthScale = 0.7,
        panelMaxWidth = 940,
        layoutDirection = Enum.FillDirection.Horizontal,
        layoutPadding = 22,
        panelPadding = { top = 28, bottom = 28, sides = 32 },
        leftWidthScale = 0.55,
        rightWidthScale = 0.45,
        showHero = true,
        showNews = true,
        startButtonSize = UDim2.new(0, 300, 0, 64),
        startButtonTextSize = 26,
        titleSize = 46,
        subtitleSize = 20,
        tipSize = 18,
        quickTitleSize = 18,
        quickDescSize = 15,
        newsTitleSize = 20,
        newsBodySize = 17,
    },
}

local function pickRandomTip(): string
    return WELCOME_TIPS[math.random(1, #WELCOME_TIPS)]
end

local function getQuickActions()
    return {
        {
            label = "🍃 Game Menu (`)",
            description = "Browse controls, settings, and debug tools.",
            onSelected = function()
                if deps.gameMenu then
                    deps.gameMenu.openToTab("controls")
                end
            end,
        },
        {
            label = "🎒 Inventory (E)",
            description = "Check your pockets and equip tools.",
            onSelected = function()
                if deps.guiManager then
                    deps.guiManager:showGUI("inventory")
                end
            end,
        },
        {
            label = "⚙️ Settings (ESC)",
            description = "Adjust graphics, audio, and accessibility.",
            onSelected = function()
                local settings = deps.settingsController
                if settings and settings.toggle then
                    settings.toggle(true)
                end
            end,
        },
    }
end

local function getViewportSize(): Vector2
    local gui = refs.screenGui
    if gui and gui.AbsoluteSize.X > 0 and gui.AbsoluteSize.Y > 0 then
        return gui.AbsoluteSize
    end

    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end

    return Vector2.new(1920, 1080)
end

local function getBreakpoint(): "mobile" | "tablet" | "desktop"
    local width = getViewportSize().X
    if width <= BREAKPOINTS.mobile then
        return "mobile"
    elseif width <= BREAKPOINTS.tablet then
        return "tablet"
    else
        return "desktop"
    end
end

local function createStartButton(parent: Instance): TextButton
    local button = Instance.new("TextButton")
    button.Name = "StartButton"
    button.BackgroundColor3 = COLORS.startButtonDefault
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamBold
    button.Text = "Start Island Day!"
    button.TextSize = 24
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Size = UDim2.new(0, 300, 0, 64)
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.startButtonStroke
    stroke.Transparency = 0.25
    stroke.Thickness = 2
    stroke.Parent = button

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 1, 10)
    shadow.Size = UDim2.new(1, 8, 1, 8)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.82
    shadow.BorderSizePixel = 0
    shadow.ZIndex = -1
    shadow.Parent = button

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 16)
    shadowCorner.Parent = shadow

    button.MouseEnter:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = COLORS.startButtonHover }
        ):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = COLORS.startButtonDefault }
        ):Play()
    end)

    button.MouseButton1Click:Connect(function()
        executeStartSequence()
    end)

    return button
end

local function createQuickActionEntry(parent: Instance, action)
    local container = Instance.new("Frame")
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Size = UDim2.new(1, -10, 0, 62)
    container.BackgroundColor3 = COLORS.quickBackground
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.quickStroke
    stroke.Transparency = 0.45
    stroke.Thickness = 1
    stroke.Parent = container

    local button = Instance.new("TextButton")
    button.Name = "ActionButton"
    button.Size = UDim2.fromScale(1, 1)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = container

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 14)
    padding.PaddingRight = UDim.new(0, 14)
    padding.Parent = container

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 18
    title.TextColor3 = COLORS.quickTitle
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = action.label
    title.Parent = container

    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Position = UDim2.new(0, 0, 0, 26)
    description.Size = UDim2.new(1, 0, 0, 24)
    description.BackgroundTransparency = 1
    description.Font = Enum.Font.Gotham
    description.TextSize = 15
    description.TextColor3 = COLORS.quickDescription
    description.TextTransparency = 0.12
    description.TextWrapped = true
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Text = action.description
    description.Parent = container

    button.MouseEnter:Connect(function()
        TweenService:Create(
            container,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = COLORS.quickHover }
        ):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(
            container,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = COLORS.quickBackground }
        ):Play()
    end)

    button.MouseButton1Click:Connect(function()
        executeStartSequence(action.onSelected)
    end)
end

local function createQuickActions(parent: Instance)
    local section = Instance.new("Frame")
    section.Name = "QuickActions"
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Size = UDim2.new(1, 0, 0, 0)
    section.BackgroundTransparency = 1
    section.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 10)
    layout.Parent = section

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 20
    label.TextColor3 = COLORS.subtitleText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "Quick actions"
    label.Parent = section

    for _, info in ipairs(getQuickActions()) do
        createQuickActionEntry(section, info)
    end

    return section
end

local function createLeftColumn(parent: Instance)
    local column = Instance.new("Frame")
    column.Name = "LeftColumn"
    column.Size = UDim2.new(0.5, 0, 0, 0)
    column.AutomaticSize = Enum.AutomaticSize.Y
    column.BackgroundTransparency = 1
    column.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 16)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = column

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 80)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 46
    title.TextColor3 = COLORS.titleText
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Bottom
    title.Text = "🍃 Welcome back!"
    title.Parent = column

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 28)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 20
    subtitle.TextColor3 = COLORS.subtitleText
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = "Your island adventures await."
    subtitle.Parent = column

    local tipLabel = Instance.new("TextLabel")
    tipLabel.Name = "TipLabel"
    tipLabel.Size = UDim2.new(1, 0, 0, 80)
    tipLabel.BackgroundTransparency = 1
    tipLabel.Font = Enum.Font.Gotham
    tipLabel.TextSize = 18
    tipLabel.TextColor3 = COLORS.bodyText
    tipLabel.TextWrapped = true
    tipLabel.TextXAlignment = Enum.TextXAlignment.Left
    tipLabel.TextYAlignment = Enum.TextYAlignment.Top
    tipLabel.Text = pickRandomTip()
    tipLabel.Parent = column
    refs.tipLabel = tipLabel

    refs.startButton = createStartButton(column)
    refs.quickActions = createQuickActions(column)

    return column
end

local function createRightColumn(parent: Instance)
    local column = Instance.new("Frame")
    column.Name = "RightColumn"
    column.Size = UDim2.new(0.5, 0, 0, 0)
    column.AutomaticSize = Enum.AutomaticSize.Y
    column.BackgroundTransparency = 1
    column.Parent = parent

    local heroImage = Instance.new("ImageLabel")
    heroImage.Name = "HeroImage"
    heroImage.Size = UDim2.new(1, 0, 0, 260)
    heroImage.BackgroundTransparency = 1
    heroImage.Image = HERO_IMAGE_ASSET
    heroImage.ScaleType = Enum.ScaleType.Fit
    heroImage.Parent = column
    refs.heroImage = heroImage

    local heroCorner = Instance.new("UICorner")
    heroCorner.CornerRadius = UDim.new(0, 16)
    heroCorner.Parent = heroImage

    local heroStroke = Instance.new("UIStroke")
    heroStroke.Color = Color3.fromRGB(255, 255, 255)
    heroStroke.Transparency = 0.35
    heroStroke.Thickness = 2
    heroStroke.Parent = heroImage

    local heroGradient = Instance.new("UIGradient")
    heroGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 245, 245)),
    })
    heroGradient.Rotation = 120
    heroGradient.Parent = heroImage

    local newsFrame = Instance.new("Frame")
    newsFrame.Name = "NewsFrame"
    newsFrame.AutomaticSize = Enum.AutomaticSize.Y
    newsFrame.Size = UDim2.new(1, 0, 0, 0)
    newsFrame.Position = UDim2.new(0, 0, 0, 16)
    newsFrame.BackgroundColor3 = COLORS.newsBackground
    newsFrame.BorderSizePixel = 0
    newsFrame.Parent = column
    refs.newsFrame = newsFrame

    local newsCorner = Instance.new("UICorner")
    newsCorner.CornerRadius = UDim.new(0, 14)
    newsCorner.Parent = newsFrame

    local newsStroke = Instance.new("UIStroke")
    newsStroke.Color = COLORS.newsStroke
    newsStroke.Transparency = 0.4
    newsStroke.Parent = newsFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 16)
    padding.PaddingBottom = UDim.new(0, 16)
    padding.PaddingLeft = UDim.new(0, 18)
    padding.PaddingRight = UDim.new(0, 18)
    padding.Parent = newsFrame

    local newsTitle = Instance.new("TextLabel")
    newsTitle.Name = "NewsTitle"
    newsTitle.Size = UDim2.new(1, 0, 0, 26)
    newsTitle.BackgroundTransparency = 1
    newsTitle.Font = Enum.Font.GothamSemibold
    newsTitle.TextSize = 20
    newsTitle.TextXAlignment = Enum.TextXAlignment.Left
    newsTitle.TextColor3 = COLORS.newsTitle
    newsTitle.Text = "Island Briefing 🍂"
    newsTitle.Parent = newsFrame

    local newsDescription = Instance.new("TextLabel")
    newsDescription.Name = "NewsDescription"
    newsDescription.Size = UDim2.new(1, 0, 1, -30)
    newsDescription.Position = UDim2.new(0, 0, 0, 30)
    newsDescription.BackgroundTransparency = 1
    newsDescription.Font = Enum.Font.Gotham
    newsDescription.TextSize = 17
    newsDescription.TextColor3 = COLORS.newsBody
    newsDescription.TextWrapped = true
    newsDescription.TextXAlignment = Enum.TextXAlignment.Left
    newsDescription.TextYAlignment = Enum.TextYAlignment.Top
    newsDescription.Text = table.concat(NEWS_LINES, "\n")
    newsDescription.Parent = newsFrame
    refs.newsDescription = newsDescription

    return column
end

local function refreshDynamicContent()
    if refs.tipLabel then
        refs.tipLabel.Text = pickRandomTip()
    end

    if refs.newsDescription then
        refs.newsDescription.Text = table.concat(NEWS_LINES, "\n")
    end
end

local function buildGui()
    local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HomeScreenGUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 450
    screenGui.Enabled = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    refs.screenGui = screenGui

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = COLORS.overlayBase
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui
    refs.overlay = overlay

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.overlayGradientTop),
        ColorSequenceKeypoint.new(0.5, COLORS.overlayGradientMid),
        ColorSequenceKeypoint.new(1, COLORS.overlayGradientBottom),
    })
    gradient.Rotation = 90
    gradient.Parent = overlay

    local panel = Instance.new("Frame")
    panel.Name = "MainPanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(0, 860, 0, 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.BackgroundColor3 = COLORS.panelBackground
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = overlay
    refs.panel = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.panelStroke
    stroke.Thickness = 2
    stroke.Transparency = 0.12
    stroke.Parent = panel

    local panelPadding = Instance.new("UIPadding")
    panelPadding.PaddingTop = UDim.new(0, 26)
    panelPadding.PaddingBottom = UDim.new(0, 26)
    panelPadding.PaddingLeft = UDim.new(0, 30)
    panelPadding.PaddingRight = UDim.new(0, 30)
    panelPadding.Parent = panel
    refs.panelPadding = panelPadding

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 22)
    layout.Parent = panel
    refs.layout = layout

    refs.leftColumn = createLeftColumn(panel)
    refs.rightColumn = createRightColumn(panel)

    refreshDynamicContent()

    screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        task.defer(function()
            if refs.screenGui then
                HomeScreen._applyResponsiveLayout()
            end
        end)
    end)

    HomeScreen._applyResponsiveLayout()
end

local function ensureGui()
    if refs.screenGui then
        return
    end

    buildGui()
end

local function playEntranceAnimation()
    if not refs.overlay or not refs.panel then
        return
    end

    refs.overlay.BackgroundTransparency = 1
    refs.panel.Visible = true
    refs.panel.Size = UDim2.new(0, math.max(520, refs.panel.Size.X.Offset), 0, 320)

    TweenService:Create(
        refs.overlay,
        TweenInfo.new(ANIMATION.overlayIn, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.1 }
    ):Play()

    TweenService:Create(
        refs.panel,
        TweenInfo.new(ANIMATION.popupIn, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(refs.panel.Size.X.Scale, refs.panel.Size.X.Offset, 0, refs.panel.AbsoluteSize.Y) }
    ):Play()
end

local function playExitAnimation()
    if not refs.overlay or not refs.panel then
        return
    end

    local overlayTween = TweenService:Create(
        refs.overlay,
        TweenInfo.new(ANIMATION.exitDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )

    local panelTween = TweenService:Create(
        refs.panel,
        TweenInfo.new(ANIMATION.exitDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(refs.panel.Size.X.Scale, 480, 0, 320),
            BackgroundTransparency = 1,
        }
    )

    overlayTween:Play()
    panelTween:Play()

    panelTween.Completed:Connect(function()
        if refs.panel then
            refs.panel.Visible = false
        end
        if refs.screenGui then
            refs.screenGui.Enabled = false
        end
    end)
end

executeStartSequence = function(extraAction: (() -> ())?)
    if started then
        return
    end

    started = true
    playExitAnimation()

    if deps.guiManager then
        deps.guiManager:hideAll()
        -- Suppress noisy post-load auto-popups briefly (e.g., settings/keybind guide)
        local suppressList = { "settings", "keybindGuide" }
        local ok, err = pcall(function()
            deps.guiManager:suppress(suppressList, 8)
        end)
        if not ok then
            warn("[HomeScreen] Suppression failed:", err)
        end
    end

    task.delay(0.3, function()
        local callback = onStartCallback or deps.onStart
        if typeof(callback) == "function" then
            callback()
        end

        if typeof(extraAction) == "function" then
            extraAction()
        end
    end)
end

function HomeScreen._applyResponsiveLayout()
    if not refs.panel or not refs.layout or not refs.panelPadding or not refs.leftColumn or not refs.rightColumn then
        return
    end

    local breakpoint = getBreakpoint()
    local preset = LAYOUT_PRESETS[breakpoint]
    local viewport = getViewportSize()
    local targetWidth = math.clamp(math.floor(viewport.X * preset.panelWidthScale), 420, preset.panelMaxWidth)

    refs.panel.Size = UDim2.new(0, targetWidth, 0, 0)
    refs.panelPadding.PaddingTop = UDim.new(0, preset.panelPadding.top)
    refs.panelPadding.PaddingBottom = UDim.new(0, preset.panelPadding.bottom)
    refs.panelPadding.PaddingLeft = UDim.new(0, preset.panelPadding.sides)
    refs.panelPadding.PaddingRight = UDim.new(0, preset.panelPadding.sides)

    refs.layout.FillDirection = preset.layoutDirection
    refs.layout.Padding = UDim.new(0, preset.layoutPadding)
    refs.layout.VerticalAlignment = preset.layoutDirection == Enum.FillDirection.Horizontal
            and Enum.VerticalAlignment.Center
        or Enum.VerticalAlignment.Top

    refs.leftColumn.Size = UDim2.new(preset.leftWidthScale, 0, 0, 0)
    refs.rightColumn.Size = UDim2.new(preset.rightWidthScale, 0, 0, 0)
    refs.rightColumn.Visible = preset.showHero or preset.showNews

    if refs.startButton then
        refs.startButton.Size = preset.startButtonSize
        refs.startButton.TextSize = preset.startButtonTextSize
    end

    if refs.tipLabel then
        refs.tipLabel.TextSize = preset.tipSize
    end

    local titleLabel = refs.leftColumn:FindFirstChild("Title") :: TextLabel?
    if titleLabel then
        titleLabel.TextSize = preset.titleSize
    end

    local subtitleLabel = refs.leftColumn:FindFirstChild("Subtitle") :: TextLabel?
    if subtitleLabel then
        subtitleLabel.TextSize = preset.subtitleSize
    end

    if refs.quickActions then
        for _, child in ipairs(refs.quickActions:GetChildren()) do
            if child:IsA("Frame") then
                local title = child:FindFirstChild("Title")
                if title and title:IsA("TextLabel") then
                    title.TextSize = preset.quickTitleSize
                end

                local desc = child:FindFirstChild("Description")
                if desc and desc:IsA("TextLabel") then
                    desc.TextSize = preset.quickDescSize
                end
            end
        end
    end

    if refs.heroImage then
        refs.heroImage.Visible = preset.showHero
        if preset.showHero then
            local heroHeight = breakpoint == "desktop" and 260 or 220
            refs.heroImage.Size = UDim2.new(1, 0, 0, heroHeight)
        end
    end

    if refs.newsFrame then
        refs.newsFrame.Visible = preset.showNews
    end

    if refs.newsDescription then
        refs.newsDescription.TextSize = preset.newsBodySize
    end

    if refs.newsFrame then
        local newsTitle = refs.newsFrame:FindFirstChild("NewsTitle")
        if newsTitle and newsTitle:IsA("TextLabel") then
            newsTitle.TextSize = preset.newsTitleSize
        end
    end
end

function HomeScreen.initialize(options)
    if isInitialized then
        return
    end

    deps = options or {}
    ensureGui()
    isInitialized = true
    print("[HomeScreen] ✅ Homescreen initialized")
end

function HomeScreen.setDependencies(options)
    deps = options or {}
end

function HomeScreen.show(options)
    if not isInitialized then
        HomeScreen.initialize(options)
    end

    if isVisible then
        return
    end

    started = false
    isVisible = true
    onStartCallback = options and options.onStart or nil

    ensureGui()
    refreshDynamicContent()
    HomeScreen._applyResponsiveLayout()

    if refs.screenGui then
        refs.screenGui.Enabled = true
    end

    if refs.overlay then
        refs.overlay.BackgroundTransparency = 1
    end

    if refs.panel then
        refs.panel.Visible = true
        refs.panel.BackgroundTransparency = 0.05
    end

    playEntranceAnimation()
end

function HomeScreen.hide()
    if not isVisible then
        return
    end

    isVisible = false
    executeStartSequence()
end

function HomeScreen.isVisible()
    return isVisible
end

return HomeScreen
