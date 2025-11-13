--[[
	GameMenu.luau
	
	Comprehensive game menu system similar to professional Roblox games.
	Accessible via backtick (`) key or a dedicated menu button.
	
	Features:
	- Inventory management
	- Settings & Graphics
	- Player stats
	- Debug tools (if enabled)
	- Game controls
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LOCAL_PLAYER = Players.LocalPlayer

local GameMenu = {}

local UIComponents = require(script.Parent.UIComponents)
local KeybindManagerModule = require(script.Parent.Parent.KeybindManager)
local KeybindDescriptions = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KeybindDescriptions"))

-- State
local _screenGui = nil
local _mainFrame = nil
local _contentFrame = nil
local _sidebarFrame = nil
local _isOpen = false
local _currentTab = "inventory"
local _guiManager = nil
local _settingsController = nil
local _inventoryClient = nil
local _escapeConnection = nil -- Track escape key connection

-- Colors matching Animal Crossing theme
local COLORS = {
	background = Color3.fromRGB(255, 251, 231), -- Cream
	sidebar = Color3.fromRGB(231, 221, 185), -- Beige
	accent = Color3.fromRGB(120, 100, 80), -- Brown
	text = Color3.fromRGB(80, 70, 60), -- Dark brown
	selected = Color3.fromRGB(4, 175, 166), -- Teal
	selectedText = Color3.fromRGB(255, 255, 247), -- Off-white
}

-- Tab definitions
local TABS = {
	{id = "inventory", title = "Inventory", icon = "🎒", keybind = "E"},
	{id = "settings", title = "Settings", icon = "⚙️", keybind = "ESC"},
	{id = "graphics", title = "Graphics", icon = "🎨", keybind = nil},
	{id = "controls", title = "Controls", icon = "🎮", keybind = nil},
	{id = "player", title = "Player", icon = "👤", keybind = nil},
	{id = "debug", title = "Debug", icon = "🔧", keybind = "G", debugOnly = true},
}

local NORMAL_KEYBIND_ORDER = {
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

local DEBUG_KEYBIND_ORDER = {
	"DEBUG_GUI",
	"ITEM_BROWSER",
	"DEBUG_DELETE",
	"TEST_PLANE",
	"QUEST_BOARD",
	"START_ONBOARDING",
}

local function createGUI()
        local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")

        -- Main ScreenGui
        _screenGui = Instance.new("ScreenGui")
	_screenGui.Name = "GameMenuGUI"
	_screenGui.ResetOnSpawn = false
	_screenGui.Enabled = false
	_screenGui.IgnoreGuiInset = true
	_screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_screenGui.Parent = playerGui
	
	-- Background layer (no darkener per request; fully transparent but still captures clicks to close)
	local darkener = Instance.new("Frame")
	darkener.Name = "Darkener"
	darkener.Size = UDim2.fromScale(1, 1)
	darkener.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	darkener.BackgroundTransparency = 1
	darkener.BorderSizePixel = 0
	darkener.Parent = _screenGui

        -- Main container - Smaller size to avoid Roblox player GUI in top-left
        _mainFrame = Instance.new("Frame")
        _mainFrame.Name = "MainFrame"
        _mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        -- Smaller size: 70% width, 70% height (was 85%, 80%)
        _mainFrame.Size = UDim2.fromScale(0.7, 0.7)
        -- Offset down and right to avoid top-left corner (Roblox player GUI)
        _mainFrame.Position = UDim2.new(0.5, 0, 0.55, 0) -- Slightly lower than center
        _mainFrame.BackgroundColor3 = COLORS.background
        _mainFrame.BorderSizePixel = 0
        _mainFrame.Parent = darkener

        local sizeConstraint = Instance.new("UISizeConstraint")
        sizeConstraint.MinSize = Vector2.new(600, 400)
        sizeConstraint.MaxSize = Vector2.new(900, 650)
        sizeConstraint.Parent = _mainFrame

        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 12)
        mainCorner.Parent = _mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = COLORS.accent
	mainStroke.Thickness = 2
	mainStroke.Parent = _mainFrame
	
	-- Title bar
        local titleHeight = 56

        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, titleHeight)
        titleBar.BackgroundColor3 = COLORS.accent
        titleBar.BorderSizePixel = 0
        titleBar.Parent = _mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar
	
	-- Fix corner clipping
	local titleFix = Instance.new("Frame")
	titleFix.Size = UDim2.new(1, 0, 0, 12)
	titleFix.Position = UDim2.new(0, 0, 1, -12)
	titleFix.BackgroundColor3 = COLORS.accent
	titleFix.BorderSizePixel = 0
	titleFix.Parent = titleBar
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -100, 1, 0)
	titleLabel.Position = UDim2.new(0, 20, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Game Menu"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0.5, -20)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
	closeButton.Text = "✕"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 20
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BorderSizePixel = 0
	closeButton.Parent = titleBar
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeButton

        -- Body container for sidebar + content
        local bodyFrame = Instance.new("Frame")
        bodyFrame.Name = "Body"
        bodyFrame.BackgroundTransparency = 1
        bodyFrame.Size = UDim2.new(1, 0, 1, -titleHeight)
        bodyFrame.Position = UDim2.new(0, 0, 0, titleHeight)
        bodyFrame.Parent = _mainFrame

        local bodyPadding = Instance.new("UIPadding")
        bodyPadding.PaddingTop = UDim.new(0, 16)
        bodyPadding.PaddingBottom = UDim.new(0, 16)
        bodyPadding.PaddingLeft = UDim.new(0, 16)
        bodyPadding.PaddingRight = UDim.new(0, 16)
        bodyPadding.Parent = bodyFrame

        local bodyLayout = Instance.new("UIListLayout")
        bodyLayout.FillDirection = Enum.FillDirection.Horizontal
        bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        -- VerticalAlignment not needed for Horizontal FillDirection
        bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
        bodyLayout.Padding = UDim.new(0, 16)
        bodyLayout.Parent = bodyFrame

        -- Sidebar for tabs
        _sidebarFrame = Instance.new("Frame")
        _sidebarFrame.Name = "Sidebar"
        _sidebarFrame.Size = UDim2.new(0.3, 0, 1, 0)
        _sidebarFrame.BackgroundColor3 = COLORS.sidebar
        _sidebarFrame.BorderSizePixel = 0
        _sidebarFrame.LayoutOrder = 1
        _sidebarFrame.Parent = bodyFrame

        local sidebarCorner = Instance.new("UICorner")
        sidebarCorner.CornerRadius = UDim.new(0, 0)
        sidebarCorner.Parent = _sidebarFrame

        -- Content area
        _contentFrame = Instance.new("ScrollingFrame")
        _contentFrame.Name = "Content"
        _contentFrame.Size = UDim2.new(0.7, -16, 1, 0)
        _contentFrame.BackgroundTransparency = 1
        _contentFrame.BorderSizePixel = 0
        _contentFrame.ScrollBarThickness = 8
        _contentFrame.ScrollBarImageColor3 = COLORS.accent
        _contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        _contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        _contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        _contentFrame.LayoutOrder = 2
        _contentFrame.Parent = bodyFrame
	
	-- Close button functionality
	closeButton.MouseButton1Click:Connect(function()
		GameMenu.hide()
	end)
	
	-- Close on Escape key
	local UserInputService = game:GetService("UserInputService")
	
	-- Close on background click (using InputBegan for Frame)
	darkener.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			GameMenu.hide()
		end
	end)
	
	-- Prevent closing when clicking main frame
	_mainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Intentionally empty; Roblox InputObject has no Handled property. We just ignore the click.
		end
	end)
	
	-- Handle Escape key - connect when menu opens, disconnect when closed
	local function setupEscapeHandler()
		if _screenGui.Enabled then
			-- Connect Escape key when menu opens
			if _escapeConnection then
				_escapeConnection:Disconnect()
			end
			_escapeConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape and _isOpen then
					GameMenu.hide()
				end
			end)
		else
			-- Disconnect when menu closes
			if _escapeConnection then
				_escapeConnection:Disconnect()
				_escapeConnection = nil
			end
		end
	end
	
	-- Set up escape handler when enabled state changes
	_screenGui:GetPropertyChangedSignal("Enabled"):Connect(setupEscapeHandler)
	
	-- Also set up initially if already enabled
	if _screenGui.Enabled then
		setupEscapeHandler()
	end
end

local function createTabButtons()
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = _sidebarFrame
	
	local padding = Instance.new("UIPadding")
	-- UIPadding does not support PaddingAll; set all sides explicitly.
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = _sidebarFrame
	
	for i, tab in ipairs(TABS) do
		-- Skip debug tabs if debug mode is off
		if tab.debugOnly and not (_G.KeybindManager and _G.KeybindManager:isDebugMode()) then
			continue
		end
		
		local tabButton = Instance.new("TextButton")
		tabButton.Name = tab.id .. "Tab"
		tabButton.Size = UDim2.new(1, 0, 0, 50)
		tabButton.BackgroundColor3 = _currentTab == tab.id and COLORS.selected or Color3.fromRGB(200, 190, 170)
		tabButton.BorderSizePixel = 0
		tabButton.LayoutOrder = i
		tabButton.Parent = _sidebarFrame
		
		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 8)
		tabCorner.Parent = tabButton
		
		-- Tab content
		local tabLayout = Instance.new("UIListLayout")
		tabLayout.FillDirection = Enum.FillDirection.Horizontal
		tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		tabLayout.Padding = UDim.new(0, 10)
		tabLayout.Parent = tabButton
		
		local tabPadding = Instance.new("UIPadding")
		tabPadding.PaddingLeft = UDim.new(0, 15)
		tabPadding.Parent = tabButton
		
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 30, 0, 30)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = tab.icon
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.TextSize = 20
		iconLabel.TextColor3 = _currentTab == tab.id and COLORS.selectedText or COLORS.text
		iconLabel.Parent = tabButton
		
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, -40, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = tab.title
		textLabel.Font = Enum.Font.GothamBold -- GothamSemibold not available; use GothamBold for emphasis
		textLabel.TextSize = 16
		textLabel.TextColor3 = _currentTab == tab.id and COLORS.selectedText or COLORS.text
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Parent = tabButton
		
		-- Keybind indicator
		if tab.keybind then
			local keybindLabel = Instance.new("TextLabel")
			keybindLabel.Size = UDim2.new(0, 40, 0, 20)
			keybindLabel.Position = UDim2.new(1, -50, 0, 5)
			keybindLabel.BackgroundColor3 = COLORS.text
			keybindLabel.Text = tab.keybind
			keybindLabel.Font = Enum.Font.GothamBold
			keybindLabel.TextSize = 10
			keybindLabel.TextColor3 = COLORS.background
			keybindLabel.TextScaled = true
			keybindLabel.Parent = tabButton
			
			local keybindCorner = Instance.new("UICorner")
			keybindCorner.CornerRadius = UDim.new(0, 4)
			keybindCorner.Parent = keybindLabel
		end
		
		-- Click handler
		tabButton.MouseButton1Click:Connect(function()
			GameMenu.switchTab(tab.id)
		end)
		
		-- Hover effects
		tabButton.MouseEnter:Connect(function()
			if _currentTab ~= tab.id then
				TweenService:Create(tabButton, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(210, 200, 180)
				}):Play()
			end
		end)
		
		tabButton.MouseLeave:Connect(function()
			if _currentTab ~= tab.id then
				TweenService:Create(tabButton, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(200, 190, 170)
				}):Play()
			end
		end)
	end
end

local function createInventoryContent()
        _contentFrame:ClearAllChildren()
        _contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 12)
        padding.PaddingBottom = UDim.new(0, 12)
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.Parent = _contentFrame

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 12)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Stretch
        layout.Parent = _contentFrame

        -- Title
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🎒 Inventory"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = COLORS.accent
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.LayoutOrder = 1
	titleLabel.Parent = _contentFrame
	
        -- Inventory grid container
        local gridContainer = Instance.new("Frame")
        gridContainer.Name = "InventoryGrid"
        gridContainer.Size = UDim2.new(1, 0, 0, 0)
        gridContainer.AutomaticSize = Enum.AutomaticSize.Y
        gridContainer.BackgroundTransparency = 1
        gridContainer.LayoutOrder = 2
        gridContainer.Parent = _contentFrame

        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0, 96, 0, 96)
        gridLayout.CellPadding = UDim2.new(0, 12, 0, 12)
        gridLayout.FillDirectionMaxCells = 5
        gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = gridContainer

        -- Create inventory slots
        local function createInventorySlot(slotIndex, itemData)
                local slot = Instance.new("Frame")
                slot.Name = "Slot_" .. slotIndex
                slot.Size = UDim2.new(0, 96, 0, 96)
                slot.BackgroundColor3 = itemData and Color3.fromRGB(240, 235, 215) or Color3.fromRGB(220, 210, 190)
                slot.BorderSizePixel = 0
                slot.LayoutOrder = slotIndex
                slot.Parent = gridContainer
		
		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 8)
		slotCorner.Parent = slot
		
		local slotStroke = Instance.new("UIStroke")
		slotStroke.Color = COLORS.accent
		slotStroke.Thickness = itemData and 2 or 1
		slotStroke.Transparency = itemData and 0 or 0.5
		slotStroke.Parent = slot
		
                if itemData then
                        -- Item icon (using sprite if available)
                        local icon = Instance.new("ImageLabel")
                        icon.Name = "Icon"
                        icon.Size = UDim2.new(0.8, 0, 0.8, 0)
                        icon.Position = UDim2.new(0.1, 0, 0.1, 0)
                        icon.ScaleType = Enum.ScaleType.Fit
                        icon.BackgroundTransparency = 1
                        icon.Parent = slot

                        -- Try to get sprite from item definition
                        local itemDefinition = nil
                        if _inventoryClient then
                                if _inventoryClient.itemDataFetcher and _inventoryClient.itemDataFetcher.getItemData then
                                        itemDefinition = _inventoryClient.itemDataFetcher.getItemData(itemData.itemId)
                                elseif typeof(_inventoryClient.getItemDefinition) == "function" then
                                        itemDefinition = _inventoryClient:getItemDefinition(itemData.itemId)
                                end
                        end

                        local spriteApplied = false
                        if itemDefinition and itemDefinition.spriteIndex and _inventoryClient and _inventoryClient.spriteConfig then
                                spriteApplied = _inventoryClient.spriteConfig.applySprite(icon, itemDefinition.spriteIndex)
                        elseif itemData.spriteIndex and _inventoryClient and _inventoryClient.spriteConfig then
                                spriteApplied = _inventoryClient.spriteConfig.applySprite(icon, itemData.spriteIndex)
                        end

                        if not spriteApplied then
                                icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
                                icon.ImageRectOffset = Vector2.new()
                                icon.ImageRectSize = Vector2.new()
                        end

                        -- Item count
                        if itemData.count > 1 then
                                local countLabel = Instance.new("TextLabel")
                                countLabel.Size = UDim2.new(0, 30, 0, 20)
				countLabel.Position = UDim2.new(1, -35, 1, -25)
				countLabel.BackgroundColor3 = COLORS.selected
				countLabel.Text = tostring(itemData.count)
				countLabel.Font = Enum.Font.GothamBold
				countLabel.TextSize = 14
				countLabel.TextColor3 = COLORS.selectedText
				countLabel.TextScaled = true
				countLabel.Parent = slot
				
				local countCorner = Instance.new("UICorner")
				countCorner.CornerRadius = UDim.new(0, 4)
				countCorner.Parent = countLabel
			end

                        -- Item name tooltip
                        local itemName = itemData.itemId
                        if itemDefinition then
                                itemName = itemDefinition.name or itemData.itemId
                        end

                        slot:SetAttribute("ItemName", itemName)
                        slot:SetAttribute("ItemId", itemData.itemId)
                        slot:SetAttribute("Count", itemData.count)
		else
			-- Empty slot indicator
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 1, 0)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = ""
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.TextSize = 12
			emptyLabel.TextColor3 = Color3.fromRGB(180, 170, 150)
			emptyLabel.Parent = slot
		end
		
		return slot
	end
	
	-- Get inventory data from InventoryClient
	if _inventoryClient and _inventoryClient.slotState then
		local maxSlots = _inventoryClient.maxSlots or 10
		local itemCount = 0
		
		for i = 1, maxSlots do
			local itemData = _inventoryClient.slotState[i]
			createInventorySlot(i, itemData)
			if itemData then
				itemCount = itemCount + 1
			end
		end
		
		-- Stats label
		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(1, 0, 0, 30)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Text = string.format("📦 %d / %d items", itemCount, maxSlots)
		statsLabel.Font = Enum.Font.GothamBold -- Replace unavailable GothamSemibold
		statsLabel.TextSize = 16
		statsLabel.TextColor3 = COLORS.text
                statsLabel.TextXAlignment = Enum.TextXAlignment.Left
                statsLabel.LayoutOrder = 3
                statsLabel.Parent = _contentFrame
        else
                -- Fallback if inventory client not available
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 0, 120)
                label.BackgroundTransparency = 1
                label.Text = "🎒 Inventory System\n\nPress E to open your inventory.\n\nYour items, tools, and resources are managed through the inventory system."
                label.Font = Enum.Font.Gotham
                label.TextSize = 16
                label.TextColor3 = COLORS.text
                label.TextWrapped = true
                label.TextYAlignment = Enum.TextYAlignment.Top
                label.LayoutOrder = 2
                label.Parent = _contentFrame
        end
end

local function createSettingsContent()
	_contentFrame:ClearAllChildren()
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 60)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = "⚙️ Game Settings\n\nGeneral game settings and preferences."
	label.Font = Enum.Font.Gotham
	label.TextSize = 16
	label.TextColor3 = COLORS.text
	label.TextWrapped = true
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = _contentFrame
	
	-- Settings categories
	local categories = {
		{name = "Camera Settings", desc = "Sensitivity, invert Y-axis, blur effects"},
		{name = "Audio Settings", desc = "Music, sound effects, voice volume"},
		{name = "Gameplay Settings", desc = "Difficulty, auto-save, tutorials"},
	}
	
	for i, category in ipairs(categories) do
		local categoryFrame = Instance.new("Frame")
		categoryFrame.Size = UDim2.new(1, -20, 0, 80)
		categoryFrame.Position = UDim2.new(0, 10, 0, 70 + (i-1) * 90)
		categoryFrame.BackgroundColor3 = Color3.fromRGB(240, 235, 215)
		categoryFrame.BorderSizePixel = 0
		categoryFrame.Parent = _contentFrame
		
		local catCorner = Instance.new("UICorner")
		catCorner.CornerRadius = UDim.new(0, 8)
		catCorner.Parent = categoryFrame
		
		local catTitle = Instance.new("TextLabel")
		catTitle.Size = UDim2.new(1, -20, 0, 30)
		catTitle.Position = UDim2.new(0, 10, 0, 10)
		catTitle.BackgroundTransparency = 1
		catTitle.Text = category.name
		catTitle.Font = Enum.Font.GothamBold
		catTitle.TextSize = 18
		catTitle.TextColor3 = COLORS.accent
		catTitle.TextXAlignment = Enum.TextXAlignment.Left
		catTitle.Parent = categoryFrame
		
		local catDesc = Instance.new("TextLabel")
		catDesc.Size = UDim2.new(1, -20, 0, 30)
		catDesc.Position = UDim2.new(0, 10, 0, 40)
		catDesc.BackgroundTransparency = 1
		catDesc.Text = category.desc
		catDesc.Font = Enum.Font.Gotham
		catDesc.TextSize = 14
		catDesc.TextColor3 = COLORS.text
		catDesc.TextXAlignment = Enum.TextXAlignment.Left
		catDesc.Parent = categoryFrame
	end
	
	_contentFrame.CanvasSize = UDim2.new(0, 0, 0, 100 + (#categories * 90))
end

local function createGraphicsContent()
	_contentFrame:ClearAllChildren()
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 80)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = "🎨 Graphics & Visual Settings\n\nAdjust visual quality for performance or aesthetics.\nPress Escape → Graphics tab for detailed settings."
	label.Font = Enum.Font.Gotham
	label.TextSize = 16
	label.TextColor3 = COLORS.text
	label.TextWrapped = true
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = _contentFrame
	
	-- Quick graphics presets
	local presets = {"Low", "Medium", "High", "Ultra"}
	
	for i, preset in ipairs(presets) do
		local presetBtn = Instance.new("TextButton")
		presetBtn.Size = UDim2.new(0, 150, 0, 40)
		presetBtn.Position = UDim2.new(0, 10 + (i-1) * 160, 0, 100)
		presetBtn.BackgroundColor3 = COLORS.selected
		presetBtn.Text = preset .. " Quality"
		presetBtn.Font = Enum.Font.GothamBold
		presetBtn.TextSize = 14
		presetBtn.TextColor3 = COLORS.selectedText
		presetBtn.BorderSizePixel = 0
		presetBtn.Parent = _contentFrame
		
		local presetCorner = Instance.new("UICorner")
		presetCorner.CornerRadius = UDim.new(0, 8)
		presetCorner.Parent = presetBtn
		
		presetBtn.MouseButton1Click:Connect(function()
			-- Apply preset via settings controller
			if _settingsController then
				local presetValues = {
					Low = 0.3, Medium = 0.6, High = 0.8, Ultra = 1.0
				}
				local value = presetValues[preset]
				if value then
					_settingsController.setSetting("shaderQuality", value)
					_settingsController.setSetting("waterQuality", value)
					_settingsController.setSetting("grassQuality", value)
					_settingsController.setSetting("particleDensity", value)
					_settingsController.setSetting("atmosphereQuality", value)
				end
			end
		end)
	end
	
	-- Open detailed settings button
	local detailedBtn = Instance.new("TextButton")
	detailedBtn.Size = UDim2.new(0, 200, 0, 50)
	detailedBtn.Position = UDim2.new(0, 10, 0, 160)
	detailedBtn.BackgroundColor3 = COLORS.accent
	detailedBtn.Text = "⚙️ Detailed Graphics Settings"
	detailedBtn.Font = Enum.Font.GothamBold
	detailedBtn.TextSize = 16
	detailedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	detailedBtn.BorderSizePixel = 0
	detailedBtn.Parent = _contentFrame
	
	local detailedCorner = Instance.new("UICorner")
	detailedCorner.CornerRadius = UDim.new(0, 8)
	detailedCorner.Parent = detailedBtn
	
	detailedBtn.MouseButton1Click:Connect(function()
		if _settingsController then
			_settingsController.toggle(true)
		end
	end)
	
	_contentFrame.CanvasSize = UDim2.new(0, 0, 0, 240)
end

local function createControlsContent()
	_contentFrame:ClearAllChildren()

	local header = Instance.new("TextLabel")
	header.Name = "ControlsHeader"
	header.Size = UDim2.new(1, -20, 0, 70)
	header.Position = UDim2.new(0, 10, 0, 10)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.Gotham
	header.TextSize = 16
	header.TextColor3 = COLORS.text
	header.TextWrapped = true
	header.TextYAlignment = Enum.TextYAlignment.Top
	header.Text = "🎮 Controls & Keybinds\nQuick reference for default controls. Enable Debug Mode from the Debug tab to activate debug-only shortcuts."
	header.Parent = _contentFrame

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ControlsScroll"
	scrollFrame.Size = UDim2.new(1, -20, 1, -100)
	scrollFrame.Position = UDim2.new(0, 10, 0, 90)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = _contentFrame

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingTop = UDim.new(0, 4)
	scrollPadding.PaddingBottom = UDim.new(0, 10)
	scrollPadding.Parent = scrollFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scrollFrame

	local keybindManagerInstance = _G.KeybindManager or KeybindManagerModule.new()
	local debugModeEnabled = keybindManagerInstance:isDebugMode()

	local function addSection(titleText, descriptionText)
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, 0, 0, 24)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 18
		titleLabel.TextColor3 = COLORS.accent
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Text = titleText
		titleLabel.LayoutOrder = #scrollFrame:GetChildren() + 1
		titleLabel.Parent = scrollFrame

		if descriptionText then
			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, 0, 0, 32)
			descLabel.BackgroundTransparency = 1
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextSize = 14
			descLabel.TextColor3 = COLORS.text
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.TextYAlignment = Enum.TextYAlignment.Top
			descLabel.TextWrapped = true
			descLabel.Text = descriptionText
			descLabel.LayoutOrder = #scrollFrame:GetChildren() + 1
			descLabel.Parent = scrollFrame
		end
	end

	local function addKeybindEntry(parent, bindName, description, keybindTable, options)
		if not keybindTable[bindName] then
			return
		end

		local tooltip = UIComponents.createKeybindTooltip(parent, bindName, description, keybindTable, options)
		tooltip.LayoutOrder = #parent:GetChildren() + 1
	end

	addSection("Normal Keybinds", "Default controls for all players.")

	for _, bindName in ipairs(NORMAL_KEYBIND_ORDER) do
		local description = KeybindDescriptions.NORMAL[bindName]
		if not description then
			description = ("Trigger action: %s"):format(bindName:gsub("_", " "):gsub("^%l", string.upper))
		end

		local tooltipOptions = {
			fillWidth = true,
			height = 58,
			statusText = "Default",
			statusColor = Color3.fromRGB(136, 122, 102),
		}

		addKeybindEntry(scrollFrame, bindName, description, KeybindManagerModule.KEYBINDS, tooltipOptions)
	end

	addSection("Debug Keybinds", "Available when Debug Mode is enabled. Toggle debug mode from the Debug tab.")

	for _, bindName in ipairs(DEBUG_KEYBIND_ORDER) do
		local description = KeybindDescriptions.DEBUG[bindName] or ("Debug action: %s"):format(bindName:gsub("_", " "):gsub("^%l", string.upper))

		local tooltipOptions = {
			fillWidth = true,
			height = 58,
			statusText = debugModeEnabled and "Debug Mode ON" or "Debug Mode OFF",
			statusColor = debugModeEnabled and Color3.fromRGB(4, 175, 166) or Color3.fromRGB(185, 165, 135),
			backgroundTransparency = debugModeEnabled and 0 or 0.2,
		}

		addKeybindEntry(scrollFrame, bindName, description, KeybindManagerModule.DEBUG_KEYBINDS, tooltipOptions)
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end

local function createPlayerContent()
	_contentFrame:ClearAllChildren()
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 80)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = "👤 Player Information\n\nView your character stats, progress, and achievements."
	label.Font = Enum.Font.Gotham
	label.TextSize = 16
	label.TextColor3 = COLORS.text
	label.TextWrapped = true
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = _contentFrame
	
	-- Player stats
	local statsFrame = Instance.new("Frame")
	statsFrame.Size = UDim2.new(1, -20, 0, 200)
	statsFrame.Position = UDim2.new(0, 10, 0, 100)
	statsFrame.BackgroundColor3 = Color3.fromRGB(240, 235, 215)
	statsFrame.BorderSizePixel = 0
	statsFrame.Parent = _contentFrame
	
	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 8)
	statsCorner.Parent = statsFrame
	
	local statsTitle = Instance.new("TextLabel")
	statsTitle.Size = UDim2.new(1, -20, 0, 30)
	statsTitle.Position = UDim2.new(0, 10, 0, 10)
	statsTitle.BackgroundTransparency = 1
	statsTitle.Text = "Player Stats"
	statsTitle.Font = Enum.Font.GothamBold
	statsTitle.TextSize = 18
	statsTitle.TextColor3 = COLORS.accent
	statsTitle.TextXAlignment = Enum.TextXAlignment.Left
	statsTitle.Parent = statsFrame
	
	local stats = {
		{name = "Username", value = LOCAL_PLAYER.Name},
		{name = "Bells", value = "1,000"},
		{name = "Nook Miles", value = "0"},
		{name = "Play Time", value = "Session: " .. math.floor(tick()) .. "s"},
		{name = "Items Collected", value = "Varies by save"},
	}
	
	for i, stat in ipairs(stats) do
		local statLabel = Instance.new("TextLabel")
		statLabel.Size = UDim2.new(0.5, -10, 0, 25)
		statLabel.Position = UDim2.new(0, 10, 0, 40 + (i-1) * 30)
		statLabel.BackgroundTransparency = 1
		statLabel.Text = stat.name .. ":"
		statLabel.Font = Enum.Font.GothamBold -- Replace unavailable GothamSemibold
		statLabel.TextSize = 14
		statLabel.TextColor3 = COLORS.text
		statLabel.TextXAlignment = Enum.TextXAlignment.Left
		statLabel.Parent = statsFrame
		
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0.5, -10, 0, 25)
		valueLabel.Position = UDim2.new(0.5, 0, 0, 40 + (i-1) * 30)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = stat.value
		valueLabel.Font = Enum.Font.Gotham
		valueLabel.TextSize = 14
		valueLabel.TextColor3 = COLORS.accent
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.Parent = statsFrame
	end
	
	_contentFrame.CanvasSize = UDim2.new(0, 0, 0, 320)
end

local function createDebugContent()
	_contentFrame:ClearAllChildren()
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 80)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = "🔧 Debug Tools\n\nDeveloper and debug utilities. Only visible when debug mode is enabled."
	label.Font = Enum.Font.Gotham
	label.TextSize = 16
	label.TextColor3 = COLORS.text
	label.TextWrapped = true
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = _contentFrame
	
	-- Debug buttons
	local debugButtons = {
		{text = "🔧 Open Debug Manager (G)", desc = "Comprehensive debug interface"},
		{text = "📦 Item Browser (B)", desc = "Browse all game items"},
		{text = "❌ Debug Delete (X)", desc = "Delete first inventory item"},
		{text = "🏝️ Island Generation", desc = "AI island generation tools"},
	}
	
	for i, button in ipairs(debugButtons) do
		local btnFrame = Instance.new("Frame")
		btnFrame.Size = UDim2.new(1, -20, 0, 80)
		btnFrame.Position = UDim2.new(0, 10, 0, 90 + (i-1) * 90)
		btnFrame.BackgroundColor3 = Color3.fromRGB(240, 235, 215)
		btnFrame.BorderSizePixel = 0
		btnFrame.Parent = _contentFrame
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btnFrame
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -20, 0, 40)
		btn.Position = UDim2.new(0, 10, 0, 10)
		btn.BackgroundColor3 = COLORS.selected
		btn.Text = button.text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.TextColor3 = COLORS.selectedText
		btn.BorderSizePixel = 0
		btn.Parent = btnFrame
		
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = btn
		
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -20, 0, 20)
		desc.Position = UDim2.new(0, 10, 0, 55)
		desc.BackgroundTransparency = 1
		desc.Text = button.desc
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 12
		desc.TextColor3 = COLORS.text
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = btnFrame
		
		-- Button functionality
		if i == 1 then -- Debug Manager
			btn.MouseButton1Click:Connect(function()
				if _guiManager then
					_guiManager:toggleGUI("debug")
				end
			end)
		elseif i == 2 then -- Item Browser
			btn.MouseButton1Click:Connect(function()
				if _guiManager then
					_guiManager:toggleGUI("itemBrowser")
				end
			end)
		end
	end
	
	_contentFrame.CanvasSize = UDim2.new(0, 0, 0, 120 + (#debugButtons * 90))
end

function GameMenu.switchTab(tabId)
	_currentTab = tabId
	
	-- Update sidebar button appearance (check if sidebar exists)
	if not _sidebarFrame then
		warn("[GameMenu] switchTab called before GUI created")
		return
	end
	
	for _, child in ipairs(_sidebarFrame:GetChildren()) do
		if child:IsA("TextButton") then
			local isSelected = child.Name:find(tabId)
			child.BackgroundColor3 = isSelected and COLORS.selected or Color3.fromRGB(200, 190, 170)
			
			for _, subchild in ipairs(child:GetChildren()) do
				if subchild:IsA("TextLabel") then
					subchild.TextColor3 = isSelected and COLORS.selectedText or COLORS.text
				end
			end
		end
	end
	
	-- Refresh inventory data if switching to inventory tab
	if tabId == "inventory" and _inventoryClient then
		_inventoryClient:requestInventory()
	end
	
	-- Load content for selected tab
	if tabId == "inventory" then
		createInventoryContent()
	elseif tabId == "settings" then
		createSettingsContent()
	elseif tabId == "graphics" then
		createGraphicsContent()
	elseif tabId == "controls" then
		createControlsContent()
	elseif tabId == "player" then
		createPlayerContent()
	elseif tabId == "debug" then
		createDebugContent()
	end
end

function GameMenu.show()
	if _isOpen then return end
	
	if not _screenGui then
		createGUI()
		createTabButtons()
	end
	
	_isOpen = true
	_screenGui.Enabled = true
	
	-- Refresh inventory if on inventory tab
	if _currentTab == "inventory" and _inventoryClient then
		_inventoryClient:requestInventory()
	end
	
	-- Load current tab content
	GameMenu.switchTab(_currentTab)
	
	-- Animation - use scale-based sizing
	local targetSize = UDim2.fromScale(0.7, 0.7)
	local targetPosition = UDim2.new(0.5, 0, 0.55, 0)
	
	_mainFrame.Size = UDim2.new(0, 50, 0, 50)
	_mainFrame.Position = UDim2.new(0.5, -25, 0.55, -25)
	
	TweenService:Create(_mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = targetSize,
		Position = targetPosition
	}):Play()
	
	print("[GameMenu] 📱 Game menu opened")
end

function GameMenu.hide()
	if not _isOpen then return end
	
	_isOpen = false
	
	-- Disconnect escape handler
	if _escapeConnection then
		_escapeConnection:Disconnect()
		_escapeConnection = nil
	end
	
	TweenService:Create(_mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(0.5, -25, 0.55, -25)
	}):Play()
	
	task.wait(0.2)
	_screenGui.Enabled = false
	
	print("[GameMenu] 📱 Game menu closed")
end

function GameMenu.toggle()
	if _isOpen then
		GameMenu.hide()
	else
		GameMenu.show()
	end
end

function GameMenu.openToTab(tabId)
	if not tabId then
		return
	end
	_currentTab = tabId
	if _isOpen then
		GameMenu.switchTab(tabId)
	else
		GameMenu.show()
	end
end

function GameMenu.init(guiManager, settingsController, inventoryClient)
	_guiManager = guiManager
	_settingsController = settingsController
	_inventoryClient = inventoryClient
	
	print("[GameMenu] ✅ Game menu system initialized (` key to open)")
end

return GameMenu
