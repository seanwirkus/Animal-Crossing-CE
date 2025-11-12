-- DebugManager.lua
-- Manages a tabbed interface for various debug tools

local TweenService = game:GetService("TweenService")
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

    -- Keybinds tab
    local keybindsPage = self:CreateTab("Keybinds")
    self:CreateKeybindsTab(keybindsPage)

    -- Item Browser tab
    local itemBrowserPage = self:CreateTab("Items")
    modules.DebugInventoryGrid:Init(itemBrowserPage)

    -- Systems tab
    local systemsPage = self:CreateTab("Systems")
    self:CreateSystemsTab(systemsPage)

    -- Graphics tab
    local graphicsPage = self:CreateTab("Graphics")
    self:CreateGraphicsTab(graphicsPage)

    -- Whiteboard tab
    local whiteboardPage = self:CreateTab("Whiteboard")
    self:CreateWhiteboardTab(whiteboardPage)

    -- Inventory tab
    local inventoryPage = self:CreateTab("Inventory")
    self:CreateInventoryTab(inventoryPage)

    -- Crafting tab
    local craftingPage = self:CreateTab("Crafting")
    self:CreateCraftingTab(craftingPage)

    -- Seasons tab
    local seasonPage = self:CreateTab("Seasons")
    self:CreateSeasonControls(seasonPage)

    -- Set a default tab
    local firstTabTitle = next(tabs)
    if firstTabTitle then
        self:SwitchToTab(firstTabTitle)
    end

    print("[DebugManager] ✅ Initialized")
end

function DebugManager:CreateKeybindsTab(parentFrame)
    local UIComponents = require(script.Parent.UIComponents)
    local KeybindManagerModule = require(script.Parent.Parent.KeybindManager)
	local KeybindDescriptions = require(_ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KeybindDescriptions"))
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = parentFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = scrollFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    -- Get the actual KeybindManager instance (should be created in init.client)
    local keybindManagerInstance = _G.KeybindManager or KeybindManagerModule.new()
	local debugModeEnabled = keybindManagerInstance:isDebugMode()

	local function addSection(titleText, descriptionText)
		local sectionTitle = Instance.new("TextLabel")
		sectionTitle.Size = UDim2.new(1, 0, 0, 24)
		sectionTitle.BackgroundTransparency = 1
		sectionTitle.Font = Enum.Font.GothamBold
		sectionTitle.TextSize = 18
		sectionTitle.TextColor3 = Color3.fromRGB(120, 100, 80)
		sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
		sectionTitle.Text = titleText
		sectionTitle.LayoutOrder = #scrollFrame:GetChildren() + 1
		sectionTitle.Parent = scrollFrame

		if descriptionText then
			local sectionDesc = Instance.new("TextLabel")
			sectionDesc.Size = UDim2.new(1, 0, 0, 30)
			sectionDesc.BackgroundTransparency = 1
			sectionDesc.Font = Enum.Font.Gotham
			sectionDesc.TextSize = 14
			sectionDesc.TextColor3 = Color3.fromRGB(80, 70, 60)
			sectionDesc.TextWrapped = true
			sectionDesc.TextXAlignment = Enum.TextXAlignment.Left
			sectionDesc.TextYAlignment = Enum.TextYAlignment.Top
			sectionDesc.Text = descriptionText
			sectionDesc.LayoutOrder = #scrollFrame:GetChildren() + 1
			sectionDesc.Parent = scrollFrame
		end
	end

	local function addKeybindTooltip(bindName, description, keybindTable, options)
		if not keybindTable[bindName] then
			return
		end
		local tooltip = UIComponents.createKeybindTooltip(scrollFrame, bindName, description, keybindTable, options)
		tooltip.LayoutOrder = #scrollFrame:GetChildren() + 1
	end
    
    -- Debug mode toggle
    local debugToggle = Instance.new("TextButton")
    debugToggle.Size = UDim2.new(1, 0, 0, 50)
	debugToggle.Text = ""
	debugToggle.AutoButtonColor = false
	debugToggle.Font = Enum.Font.GothamBold
	debugToggle.TextSize = 18
	debugToggle.TextColor3 = Color3.fromRGB(138, 123, 102)
	debugToggle.BackgroundColor3 = Color3.fromRGB(247, 248, 230)
    debugToggle.LayoutOrder = 1
    debugToggle.Parent = scrollFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = debugToggle

	local toggleLabel = Instance.new("TextLabel")
	toggleLabel.Size = UDim2.new(1, -20, 1, 0)
	toggleLabel.Position = UDim2.new(0, 10, 0, 0)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Font = Enum.Font.GothamBold
	toggleLabel.TextSize = 18
	toggleLabel.TextColor3 = Color3.fromRGB(138, 123, 102)
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.Text = "Debug Mode: " .. (debugModeEnabled and "ON" or "OFF")
	toggleLabel.Parent = debugToggle

	local toggleHint = Instance.new("TextLabel")
	toggleHint.Size = UDim2.new(0, 200, 0, 18)
	toggleHint.Position = UDim2.new(1, -210, 0.5, -9)
	toggleHint.AnchorPoint = Vector2.new(0, 0)
	toggleHint.BackgroundTransparency = 1
	toggleHint.Font = Enum.Font.Gotham
	toggleHint.TextSize = 13
	toggleHint.TextColor3 = Color3.fromRGB(136, 122, 102)
	toggleHint.TextXAlignment = Enum.TextXAlignment.Right
	toggleHint.Text = "Requires developer access"
	toggleHint.Parent = debugToggle

	local function updateToggleVisual(state)
		debugModeEnabled = state
		toggleLabel.Text = "Debug Mode: " .. (state and "ON" or "OFF")
		debugToggle.BackgroundColor3 = state and Color3.fromRGB(4, 175, 166) or Color3.fromRGB(247, 248, 230)
		toggleLabel.TextColor3 = state and Color3.fromRGB(255, 255, 247) or Color3.fromRGB(138, 123, 102)
		toggleHint.TextColor3 = state and Color3.fromRGB(255, 255, 247) or Color3.fromRGB(136, 122, 102)
	end

	updateToggleVisual(debugModeEnabled)

	local hoverTweenIn = TweenService:Create(debugToggle, TweenInfo.new(0.2), {BackgroundTransparency = 0.05})
	local hoverTweenOut = TweenService:Create(debugToggle, TweenInfo.new(0.2), {BackgroundTransparency = 0})

    debugToggle.MouseButton1Click:Connect(function()
		local newState = not keybindManagerInstance:isDebugMode()
        keybindManagerInstance:setDebugMode(newState)
		updateToggleVisual(newState)
    end)

	debugToggle.MouseEnter:Connect(function()
		hoverTweenOut:Cancel()
		hoverTweenIn:Play()
	end)

	debugToggle.MouseLeave:Connect(function()
		hoverTweenIn:Cancel()
		hoverTweenOut:Play()
	end)
    
    -- Normal keybinds
	addSection("Normal Keybinds", "Default controls that are always available.")

	for _, bindName in ipairs({
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
	}) do
		local description = KeybindDescriptions.NORMAL[bindName] or ("Action: %s"):format(bindName:gsub("_", " "))
		addKeybindTooltip(bindName, description, KeybindManagerModule.KEYBINDS, {
			fillWidth = true,
			height = 58,
			statusText = "Default",
			statusColor = Color3.fromRGB(136, 122, 102),
		})
    end
    
    -- Debug keybinds
	addSection("Debug Keybinds", "Active only when debug mode is enabled.")

	for _, bindName in ipairs({
		"DEBUG_GUI",
		"ITEM_BROWSER",
		"DEBUG_DELETE",
		"TEST_PLANE",
		"QUEST_BOARD",
		"START_ONBOARDING",
	}) do
		local description = KeybindDescriptions.DEBUG[bindName] or ("Debug action: %s"):format(bindName:gsub("_", " "))
		addKeybindTooltip(bindName, description, KeybindManagerModule.DEBUG_KEYBINDS, {
			fillWidth = true,
			height = 58,
			statusText = debugModeEnabled and "Debug Mode ON" or "Debug Mode OFF",
			statusColor = debugModeEnabled and Color3.fromRGB(4, 175, 166) or Color3.fromRGB(185, 165, 135),
			backgroundTransparency = debugModeEnabled and 0 or 0.2,
		})
    end
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
end

function DebugManager:CreateSystemsTab(parentFrame)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = parentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    -- System status display
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 100)
    statusLabel.Text = "System Status:\n- Inventory: Active\n- Crafting: Active\n- Whiteboard: Active\n- Graphics: Active"
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.TextColor3 = Color3.fromRGB(80, 70, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextWrapped = true
    statusLabel.LayoutOrder = 1
    statusLabel.Parent = scrollFrame
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
end

function DebugManager:CreateGraphicsTab(parentFrame)
    -- Graphics settings are handled by SettingsController
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -20)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.Text = "Graphics settings are available in the Settings menu (Escape key)"
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(80, 70, 60)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.Parent = parentFrame
end

function DebugManager:CreateWhiteboardTab(parentFrame)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -20)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.Text = "Whiteboard Controls:\n- Pick up markers from workspace\n- Draw on whiteboard with equipped marker\n- Shift+C to clear\n- Shift+S to save"
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(80, 70, 60)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.Parent = parentFrame
end

function DebugManager:CreateInventoryTab(parentFrame)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -20)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.Text = "Inventory Debug:\n- Press E to open inventory\n- Use Item Browser (B key) to browse all items\n- Items can be added/removed via server"
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(80, 70, 60)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.Parent = parentFrame
end

function DebugManager:CreateCraftingTab(parentFrame)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -20)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.Text = "Crafting Debug:\n- Press C to open crafting menu\n- Browse recipes and craft items\n- Recipes are loaded from data/items.json"
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(80, 70, 60)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.Parent = parentFrame
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
