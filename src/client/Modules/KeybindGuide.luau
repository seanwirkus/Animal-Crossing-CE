local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIComponents = require(script.Parent.UIComponents)
local KeybindManagerModule = require(script.Parent.Parent.KeybindManager)
local KeybindDescriptions = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KeybindDescriptions"))

local LOCAL_PLAYER = Players.LocalPlayer

local KeybindGuide = {}

local _guiManager = nil
local _keybindManager = nil
local _gameMenuModule = nil
local _settingsController = nil

local _screenGui = nil
local _background = nil
local _guideFrame = nil
local _scrollFrame = nil
local _headerSubtitle = nil
local _quickActionsFrame = nil

local _initialized = false
local _onboardingShown = false

local NORMAL_ORDER = {
    "INVENTORY",
    "DROP_ITEM",
    "REACTION",
    "CRAFTING",
    "TOOL_WHEEL",
    "NOOK_PHONE",
    "MAP",
    "SETTINGS",
    "GAME_MENU",
    "KEYBIND_GUIDE",
    "EMOTE",
}

local DEBUG_ORDER = {
    "DEBUG_GUI",
    "ITEM_BROWSER",
    "DEBUG_DELETE",
    "TEST_PLANE",
    "QUEST_BOARD",
    "START_ONBOARDING",
}

local function getKeybindManager()
    if _keybindManager then
        return _keybindManager
    end
    return _G.KeybindManager or KeybindManagerModule.new()
end

local function clearFrameContents(frame)
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

local function createQuickActionButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Name = text
    button.Size = UDim2.new(0, 220, 0, 44)
    button.BackgroundColor3 = Color3.fromRGB(4, 175, 166)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(255, 255, 247)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 16
    button.Text = text
    button.AutoButtonColor = false
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local hoverTweenIn = TweenService:Create(button, TweenInfo.new(0.18), {
        BackgroundColor3 = Color3.fromRGB(12, 185, 176),
    })
    local hoverTweenOut = TweenService:Create(button, TweenInfo.new(0.18), {
        BackgroundColor3 = Color3.fromRGB(4, 175, 166),
    })

    button.MouseEnter:Connect(function()
        hoverTweenOut:Cancel()
        hoverTweenIn:Play()
    end)

    button.MouseLeave:Connect(function()
        hoverTweenIn:Cancel()
        hoverTweenOut:Play()
    end)

    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    return button
end

local function ensureGui()
    if _screenGui then
        return
    end

    local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")

    _screenGui = Instance.new("ScreenGui")
    _screenGui.Name = "KeybindGuide"
    _screenGui.ResetOnSpawn = false
    _screenGui.Enabled = false
    _screenGui.DisplayOrder = 1000 -- VERY HIGH - above Roblox CoreGui
    _screenGui.IgnoreGuiInset = true
    _screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _screenGui.Parent = playerGui

    _background = Instance.new("Frame")
    _background.Name = "Background"
    _background.Size = UDim2.fromScale(1, 1)
    _background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    _background.BackgroundTransparency = 1
    _background.Visible = true
    _background.Parent = _screenGui

    _guideFrame = Instance.new("Frame")
    _guideFrame.Name = "GuideFrame"
    -- Smaller size to avoid Roblox player GUI in top-left
    _guideFrame.Size = UDim2.new(0, 800, 0, 500)
    -- Position lower to avoid top-left corner
    _guideFrame.Position = UDim2.new(0.5, -400, 0.55, -250)
    _guideFrame.BackgroundColor3 = Color3.fromRGB(255, 251, 231)
    _guideFrame.BorderSizePixel = 0
    _guideFrame.Parent = _background

    local guideCorner = Instance.new("UICorner")
    guideCorner.CornerRadius = UDim.new(0, 12)
    guideCorner.Parent = _guideFrame

    local guideStroke = Instance.new("UIStroke")
    guideStroke.Color = Color3.fromRGB(120, 100, 80)
    guideStroke.Thickness = 2
    guideStroke.Parent = _guideFrame

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = Color3.fromRGB(120, 100, 80)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = _guideFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local cornerFix = Instance.new("Frame")
    cornerFix.Size = UDim2.new(1, 0, 0, 12)
    cornerFix.Position = UDim2.new(0, 0, 1, -12)
    cornerFix.BackgroundColor3 = Color3.fromRGB(120, 100, 80)
    cornerFix.BorderSizePixel = 0
    cornerFix.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 24, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 28
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "Keybind Guide"
    titleLabel.Parent = titleBar

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 44, 0, 44)
    closeButton.Position = UDim2.new(1, -54, 0.5, -22)
    closeButton.AnchorPoint = Vector2.new(0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 251, 231)
    closeButton.TextColor3 = Color3.fromRGB(120, 100, 80)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.Text = "✕"
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        if _guiManager then
            _guiManager:hideGUI("keybindGuide")
        else
            KeybindGuide:Hide()
        end
    end)

    local closeHoverIn =
        TweenService:Create(closeButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(238, 233, 210) })
    local closeHoverOut =
        TweenService:Create(closeButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(255, 251, 231) })

    closeButton.MouseEnter:Connect(function()
        closeHoverOut:Cancel()
        closeHoverIn:Play()
    end)

    closeButton.MouseLeave:Connect(function()
        closeHoverIn:Cancel()
        closeHoverOut:Play()
    end)

    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "Body"
    bodyFrame.Size = UDim2.new(1, -32, 1, -84)
    bodyFrame.Position = UDim2.new(0, 16, 0, 68)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.Parent = _guideFrame

    _headerSubtitle = Instance.new("TextLabel")
    _headerSubtitle.Name = "Subtitle"
    _headerSubtitle.Size = UDim2.new(1, 0, 0, 46)
    _headerSubtitle.BackgroundTransparency = 1
    _headerSubtitle.Font = Enum.Font.Gotham
    _headerSubtitle.TextSize = 16
    _headerSubtitle.TextColor3 = Color3.fromRGB(80, 70, 60)
    _headerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    _headerSubtitle.TextYAlignment = Enum.TextYAlignment.Top
    _headerSubtitle.TextWrapped = true
    _headerSubtitle.Text =
        "Welcome! Press F1 anytime to reopen this guide. Use the quick actions below to jump straight into settings or adjust graphics."
    _headerSubtitle.Parent = bodyFrame

    _quickActionsFrame = Instance.new("Frame")
    _quickActionsFrame.Name = "QuickActions"
    _quickActionsFrame.Size = UDim2.new(1, 0, 0, 56)
    _quickActionsFrame.Position = UDim2.new(0, 0, 0, 54)
    _quickActionsFrame.BackgroundTransparency = 1
    _quickActionsFrame.Parent = bodyFrame

    local quickLayout = Instance.new("UIListLayout")
    quickLayout.FillDirection = Enum.FillDirection.Horizontal
    quickLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    quickLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    quickLayout.Padding = UDim.new(0, 12)
    quickLayout.Parent = _quickActionsFrame

    local quickPadding = Instance.new("UIPadding")
    quickPadding.PaddingBottom = UDim.new(0, 6)
    quickPadding.Parent = _quickActionsFrame

    _scrollFrame = Instance.new("ScrollingFrame")
    _scrollFrame.Name = "KeybindList"
    _scrollFrame.Size = UDim2.new(1, 0, 1, -120)
    _scrollFrame.Position = UDim2.new(0, 0, 0, 120)
    _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    _scrollFrame.BackgroundTransparency = 1
    _scrollFrame.BorderSizePixel = 0
    _scrollFrame.ScrollBarThickness = 6
    _scrollFrame.Parent = bodyFrame

    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.Padding = UDim.new(0, 8)
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scrollLayout.Parent = _scrollFrame

    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingTop = UDim.new(0, 4)
    scrollPadding.PaddingBottom = UDim.new(0, 12)
    scrollPadding.Parent = _scrollFrame

    scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 20)
    end)
end

local function addSectionHeader(parent, titleText, descriptionText)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 26)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = Color3.fromRGB(120, 100, 80)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = titleText
    titleLabel.Parent = parent

    if descriptionText and descriptionText ~= "" then
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, 0, 0, 34)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 14
        descLabel.TextColor3 = Color3.fromRGB(80, 70, 60)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextWrapped = true
        descLabel.Text = descriptionText
        descLabel.Parent = parent
    end
end

local function addTooltipEntry(parent, bindName, description, keybindTable, options)
    if not keybindTable or not keybindTable[bindName] then
        return
    end

    local tooltip = UIComponents.createKeybindTooltip(parent, bindName, description, keybindTable, options)
end

local function buildKeybindList()
    if not _scrollFrame then
        return
    end

    -- Type assertions for nil-safety
    local scrollFrame = _scrollFrame :: ScrollingFrame

    clearFrameContents(_scrollFrame)

    local keybindManager = getKeybindManager()
    local debugModeEnabled = keybindManager:isDebugMode()

    -- Guard against KeybindDescriptions being nil
    local normalDescriptions = KeybindDescriptions and KeybindDescriptions.NORMAL or {}
    local debugDescriptions = KeybindDescriptions and KeybindDescriptions.DEBUG or {}

    addSectionHeader(
        _scrollFrame,
        "Normal Keybinds",
        "Default controls for every player. Customize them in settings (Esc)."
    )

    for _, bindName in ipairs(NORMAL_ORDER) do
        local description = normalDescriptions[bindName]
        if not description then
            description = ("Action: %s"):format(bindName:gsub("_", " "):gsub("^%l", string.upper))
        end

        addTooltipEntry(_scrollFrame, bindName, description, KeybindManagerModule.KEYBINDS, {
            fillWidth = true,
            height = 60,
            statusText = "Default",
            statusColor = Color3.fromRGB(136, 122, 102),
        })
    end

    addSectionHeader(
        _scrollFrame,
        "Debug Keybinds",
        "Enable debug mode from the Debug tab to activate these developer shortcuts."
    )

    for _, bindName in ipairs(DEBUG_ORDER) do
        local description = debugDescriptions[bindName]
            or ("Debug action: %s"):format(bindName:gsub("_", " "):gsub("^%l", string.upper))

        addTooltipEntry(_scrollFrame, bindName, description, KeybindManagerModule.DEBUG_KEYBINDS, {
            fillWidth = true,
            height = 60,
            statusText = debugModeEnabled and "Debug Mode ON" or "Debug Mode OFF",
            statusColor = debugModeEnabled and Color3.fromRGB(4, 175, 166) or Color3.fromRGB(185, 165, 135),
            backgroundTransparency = debugModeEnabled and 0 or 0.2,
        })
    end
end

local function buildQuickActions()
    if not _quickActionsFrame then
        return
    end

    -- Type assertions for nil-safety
    local quickActionsFrame = _quickActionsFrame :: Frame

    clearFrameContents(_quickActionsFrame)

    createQuickActionButton(_quickActionsFrame, "Open Settings (Esc)", function()
        if _gameMenuModule and _gameMenuModule.openToTab then
            _gameMenuModule.openToTab("settings")
        elseif _settingsController and _settingsController.toggle then
            _settingsController.toggle(true)
        end
    end)

    createQuickActionButton(_quickActionsFrame, "Open Game Menu (`)", function()
        if _gameMenuModule and (_gameMenuModule.open or _gameMenuModule.openToTab) then
            if _gameMenuModule.open then
                _gameMenuModule.open()
            else
                _gameMenuModule.openToTab("controls")
            end
        end
    end)

    createQuickActionButton(_quickActionsFrame, "Graphics Presets", function()
        if _gameMenuModule and _gameMenuModule.openToTab then
            _gameMenuModule.openToTab("graphics")
        end
    end)

    createQuickActionButton(_quickActionsFrame, "Controls Overview", function()
        if _gameMenuModule and _gameMenuModule.openToTab then
            _gameMenuModule.openToTab("controls")
        end
    end)
end

local function refreshGuide()
    if not _screenGui then
        return
    end

    buildQuickActions()
    buildKeybindList()

    -- Type assertion for nil-safety
    local headerSubtitle = _headerSubtitle :: TextLabel

    if _headerSubtitle then
        _headerSubtitle.Text =
            "Welcome! Press F1 anytime to reopen this guide. Use the quick actions below to jump straight into settings or adjust graphics."
    end
end

function KeybindGuide:Show()
    ensureGui()
    refreshGuide()
    _onboardingShown = true

    local sg = _screenGui :: ScreenGui
    local bg = _background :: Frame
    local gf = _guideFrame :: Frame

    sg.Enabled = true
    bg.BackgroundTransparency = 0.5

    gf.Size = UDim2.new(0, 820, 0, 520)
    gf.Position = UDim2.new(0.5, -410, 0.5, -260)

    TweenService:Create(gf, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 900, 0, 540),
        Position = UDim2.new(0.5, -450, 0.5, -270),
    }):Play()
end

function KeybindGuide:Hide()
    if not _screenGui or not _screenGui.Enabled then
        return
    end

    TweenService:Create(_guideFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 820, 0, 520),
        Position = UDim2.new(0.5, -410, 0.5, -260),
    }):Play()

    task.delay(0.18, function()
        if _screenGui then
            _screenGui.Enabled = false
        end
    end)
end

function KeybindGuide.toggle()
    if not _guiManager then
        if _screenGui and _screenGui.Enabled then
            KeybindGuide:Hide()
        else
            KeybindGuide:Show()
        end
        return
    end

    _guiManager:toggleGUI("keybindGuide")
end

function KeybindGuide.showOnboardingPrompt()
    if _onboardingShown then
        return
    end

    -- Skip onboarding if pre-start flow already completed
    if _G.PreStartCompleted == true then
        return
    end

    if _guiManager and _guiManager:getCurrentVisible() then
        task.delay(5, KeybindGuide.showOnboardingPrompt)
        return
    end

    _onboardingShown = true

    if _guiManager then
        _guiManager:showGUI("keybindGuide")
    else
        KeybindGuide:Show()
    end
end

function KeybindGuide.init(guiManager, keybindManager, gameMenuModule, settingsController)
    if _initialized then
        return
    end
    _initialized = true

    _guiManager = guiManager
    _keybindManager = keybindManager or getKeybindManager()
    _gameMenuModule = gameMenuModule
    _settingsController = settingsController

    ensureGui()

    if _guiManager then
        _guiManager:registerGUI("keybindGuide", KeybindGuide)
    end

    -- Delayed onboarding prompt (guarded by pre-start completion flag)
    task.delay(6, function()
        if _G.PreStartCompleted == true then
            return
        end
        if not _onboardingShown then
            KeybindGuide.showOnboardingPrompt()
        end
    end)

    print("[KeybindGuide] ✅ Keybind guide initialized (F1 to open)")
end

return KeybindGuide
