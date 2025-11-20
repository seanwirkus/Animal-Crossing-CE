-- InventoryGuiSetup.lua
-- Creates the inventory GUI structure with responsive slot templates

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ThemeProvider = require(script.Parent.ThemeProvider)
local GUIContentManager = require(script.Parent.GUIContentManager)
local LayoutLint = require(script.Parent.LayoutLint)

local InventoryGuiSetup = {}

local _inventoryGuiInitialized = false

local STATS_CARD_CONFIG = {
    {
        name = "BellsCard",
        iconName = "BellsIcon",
        labelName = "BellsLabel",
        assetId = "",
        colorKey = "warmYellow",
        layoutOrder = 1,
        rotation = -2,
    },
    {
        name = "MilesCard",
        iconName = "MilesIcon",
        labelName = "MilesLabel",
        assetId = "",
        colorKey = "teal",
        layoutOrder = 2,
        rotation = 3,
    },
}

local function ensureStatsBar(parent)
    local statsBar = parent:FindFirstChild("StatsBar")
    if not statsBar or not statsBar:IsA("Frame") then
        if statsBar then
            statsBar:Destroy()
        end
        statsBar = Instance.new("Frame")
        statsBar.Name = "StatsBar"
        statsBar.BackgroundTransparency = 1
        statsBar.Size = UDim2.new(1, 0, 0, 140)
        statsBar.LayoutOrder = 2
        statsBar.Parent = parent

        local layout = Instance.new("UIListLayout")
        layout.Name = "StatsLayout"
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Padding = UDim.new(0, 20)
        layout.Parent = statsBar
    end

    for _, config in STATS_CARD_CONFIG do
        local card = statsBar:FindFirstChild(config.name)
        if not card or not card:IsA("Frame") then
            if card then
                card:Destroy()
            end
            card = Instance.new("Frame")
            card.Name = config.name
            card.Size = UDim2.fromOffset(180, 80)
            card.BackgroundColor3 = ThemeProvider.getColor(config.colorKey)
            card.BorderSizePixel = 0
            card.LayoutOrder = config.layoutOrder
            card.AnchorPoint = Vector2.new(0.5, 0.5)
            card.Rotation = config.rotation or 0
            card.Parent = statsBar

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = card

            local stroke = Instance.new("UIStroke")
            stroke.Color = ThemeProvider.getColor("textLight")
            stroke.Thickness = 3
            stroke.Parent = card
        else
            card.BackgroundColor3 = ThemeProvider.getColor(config.colorKey)
            card.LayoutOrder = config.layoutOrder
            card.Rotation = config.rotation or 0
        end

        local icon = card:FindFirstChild(config.iconName)
        if not icon or not icon:IsA("ImageLabel") then
            if icon then
                icon:Destroy()
            end
            icon = Instance.new("ImageLabel")
            icon.Name = config.iconName
            icon.BackgroundTransparency = 1
            icon.Size = UDim2.fromOffset(50, 50)
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
            icon.Position = UDim2.new(0, 35, 0.5, 0)
            icon.Parent = card
        end
        icon.Image = config.assetId
        icon.ZIndex = card.ZIndex + 1

        local label = card:FindFirstChild(config.labelName)
        if not label or not label:IsA("TextLabel") then
            if label then
                label:Destroy()
            end
            label = Instance.new("TextLabel")
            label.Name = config.labelName
            label.BackgroundTransparency = 1
            label.TextScaled = true
            label.Font = Enum.Font.GothamBlack
            label.AnchorPoint = Vector2.new(0, 0.5)
            label.Size = UDim2.new(0.6, 0, 0.7, 0)
            label.Position = UDim2.new(0.35, 0, 0.5, 0)
            label.TextXAlignment = Enum.TextXAlignment.Right
            label.Parent = card

            local sizeConstraint = Instance.new("UITextSizeConstraint")
            sizeConstraint.MaxTextSize = 36
            sizeConstraint.MinTextSize = 12
            sizeConstraint.Parent = label

            local scale = Instance.new("UIScale")
            scale.Parent = label
        end

        label.Text = "00,000"
        label.TextColor3 = ThemeProvider.getColor("textLight")
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 1
    end

    return statsBar
end

local function ensureContentContainer(frame)
    local container = frame:FindFirstChild("ContentContainer")
    if not container or not container:IsA("Frame") then
        if container then
            container:Destroy()
        end
        container = Instance.new("Frame")
        container.Name = "ContentContainer"
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(1, 0, 1, -12)
        container.Position = UDim2.new(0, 0, 0, 0)
        container.Parent = frame

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 24)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container
    end

    return container
end

local function ensureScreenGui(playerGui)
    local existing = playerGui:FindFirstChild("InventoryGUI")
    if existing and existing:IsA("ScreenGui") then
        return existing
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 25
    screenGui.IgnoreGuiInset = true
    screenGui.Enabled = true
    screenGui.Parent = playerGui

    print("[InventoryGuiSetup] ✨ Created default InventoryGUI container")
    return screenGui
end

local function applyFrameStyling(frame, layout)
    ThemeProvider.styleFrame(frame, {
        backgroundColor = "cream",
        cornerRadius = layout.cornerRadius and UDim.new(0, layout.cornerRadius) or UDim.new(0.25, 0),
        shadow = "large",
    })
    frame.ClipsDescendants = false

    local padding = frame:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, layout.padding.top or 24)
    padding.PaddingBottom = UDim.new(0, layout.padding.bottom or 24)
    padding.PaddingLeft = UDim.new(0, layout.padding.left or 24)
    padding.PaddingRight = UDim.new(0, layout.padding.right or 24)
    padding.Parent = frame
end

local function ensureInventoryItems(parent, layout, options)
    options = options or {}
    local name = options.name or "InventoryItems"
    local useScrolling = options.scrolling or false
    local desiredClass = useScrolling and "ScrollingFrame" or "Frame"

    local inventoryItems = parent:FindFirstChild(name)
    if not inventoryItems or not inventoryItems:IsA(desiredClass) then
        if inventoryItems then
            inventoryItems:Destroy()
        end
        inventoryItems = Instance.new(desiredClass)
        inventoryItems.Name = name
        inventoryItems.BackgroundTransparency = 1
        inventoryItems.BorderSizePixel = 0
        inventoryItems.LayoutOrder = options.layoutOrder or 1
        if useScrolling then
            inventoryItems.ScrollBarThickness = 6
            inventoryItems.ScrollingDirection = Enum.ScrollingDirection.Y
            inventoryItems.CanvasSize = UDim2.new(0, 0, 0, 0)
            inventoryItems.AutomaticCanvasSize = Enum.AutomaticSize.Y
            inventoryItems.Size = options.size or UDim2.new(1, 0, 1, -120)
        else
            inventoryItems.AutomaticSize = Enum.AutomaticSize.XY
            inventoryItems.Size = options.size or UDim2.new(1, 0, 0, 0)
        end
        inventoryItems.Parent = parent
    else
        inventoryItems.LayoutOrder = options.layoutOrder or inventoryItems.LayoutOrder
    end

    local padding = inventoryItems:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
    local paddingScale = options.paddingScale or 0.15
    padding.PaddingTop = UDim.new(paddingScale, 0)
    padding.PaddingBottom = UDim.new(paddingScale, 0)
    padding.PaddingLeft = UDim.new(paddingScale, 0)
    padding.PaddingRight = UDim.new(paddingScale, 0)
    padding.Parent = inventoryItems

    local grid = inventoryItems:FindFirstChildOfClass("UIGridLayout")
    if not grid then
        grid = Instance.new("UIGridLayout")
        grid.FillDirection = Enum.FillDirection.Horizontal
        grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
        grid.VerticalAlignment = Enum.VerticalAlignment.Center
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.StartCorner = Enum.StartCorner.TopLeft
        grid.Parent = inventoryItems
    end

    local slotLayout = layout.slot or {}
    grid.CellSize = slotLayout.size or UDim2.new(0, 64, 0, 64)
    grid.CellPadding = options.cellPadding or UDim2.new(0, 25, 0, 25)
    grid.FillDirectionMaxCells = slotLayout.maxColumns or 10

    return inventoryItems
end

-- Footer removed to prevent overlay issues
-- local function createFooter(_frame, _layout)
--     return nil
-- end

local function buildInventoryFrame(screenGui, layout)
    local frame = Instance.new("Frame")
    frame.Name = "InventoryFrame"
    frame.AnchorPoint = layout.anchorPoint or Vector2.new(0.5, 1)
    frame.Position = layout.position or UDim2.new(0.5, 0, 1, -40)
    frame.Size = layout.size or UDim2.new(0, 720, 0, 360)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = screenGui

    applyFrameStyling(frame, layout)
    local contentContainer = ensureContentContainer(frame)
    ensureInventoryItems(contentContainer, layout, {
        layoutOrder = 1,
    })
    ensureStatsBar(contentContainer)
    -- createFooter(frame, layout) -- Removed

    print("[InventoryGuiSetup] ✨ Created InventoryFrame with responsive layout")
    return frame
end

function InventoryGuiSetup.createInventoryGui()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local layout = LayoutLint.validate("Inventory", GUIContentManager.getLayoutConfig("Inventory"), {
        "anchorPoint",
        "position",
        "size",
    })

    local screenGui = ensureScreenGui(playerGui)
    if not screenGui then
        return nil
    end

    if not _inventoryGuiInitialized then
        _inventoryGuiInitialized = true
    end

    local inventoryFrame = screenGui:FindFirstChild("InventoryFrame")
    if not inventoryFrame or not inventoryFrame:IsA("Frame") then
        inventoryFrame = buildInventoryFrame(screenGui, layout)
    else
        applyFrameStyling(inventoryFrame, layout)
        local contentContainer = ensureContentContainer(inventoryFrame)
        ensureInventoryItems(contentContainer, layout, {
            layoutOrder = 1,
        })
        ensureStatsBar(contentContainer)
        -- createFooter(inventoryFrame, layout) -- Removed
        print("[InventoryGuiSetup] ♻️ Refreshed existing InventoryFrame")
    end

    local contentContainer = ensureContentContainer(inventoryFrame)
    local inventoryItems = ensureInventoryItems(contentContainer, layout, {
        layoutOrder = 1,
    })
    ensureStatsBar(contentContainer)
    local slotTemplate = inventoryItems:FindFirstChild("ItemSlotTemplate")
    if not slotTemplate then
        slotTemplate = InventoryGuiSetup.createSlotTemplate()
        slotTemplate.Name = "ItemSlotTemplate"
        slotTemplate.Visible = false
        slotTemplate.Parent = inventoryItems
    end

    print("[InventoryGuiSetup] ✅ Inventory GUI ready")
    return screenGui
end

function InventoryGuiSetup.createSlotTemplate()
    -- Determine slot size based on screen size (responsive)
    local camera = Workspace.CurrentCamera
    local viewportSize = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local isDesktop = viewportSize.X > 1000

    -- Desktop: 10 items per row (matches inventory level system), Mobile: 5 items per row
    local slotsPerRow = isDesktop and 10 or 5
    local slotSize = math.floor((viewportSize.X * 0.8 - 100) / slotsPerRow)
    slotSize = math.clamp(slotSize, 50, 80)

    -- Ensure slots are sized consistently for the 10-per-row layout
    if isDesktop then
        slotSize = math.floor(viewportSize.X * 0.08) -- ~8% of screen width per slot
        slotSize = math.clamp(slotSize, 60, 80)
    end

    local slot = Instance.new("Frame")
    slot.Name = "ItemSlot"
    local slotLayout = GUIContentManager.getLayoutConfig("Inventory")
    local slotSizeOverride = slotLayout and slotLayout.slot and slotLayout.slot.size
    slot.Size = slotSizeOverride or UDim2.new(0, slotSize, 0, slotSize)
    slot.BackgroundColor3 = Color3.fromRGB(255, 250, 240)
    slot.BorderSizePixel = 2
    slot.BorderColor3 = Color3.fromRGB(180, 170, 150)

    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(0, 4)
    slotCorner.Parent = slot

    -- Item icon (sprite)
    local itemIcon = Instance.new("ImageLabel")
    itemIcon.Name = "ItemIcon"
    itemIcon.Size = UDim2.new(0.8, 0, 0.7, 0)
    itemIcon.Position = UDim2.new(0.1, 0, 0.05, 0)
    itemIcon.AnchorPoint = Vector2.new(0, 0)
    itemIcon.BackgroundTransparency = 1
    itemIcon.Image = ""
    itemIcon.ScaleType = Enum.ScaleType.Fit
    itemIcon.ImageRectSize = Vector2.new(36, 36) -- Default sprite size from config
    itemIcon.Parent = slot

    -- Item count label (top-right, always visible black text with stroke)
    local itemCount = Instance.new("TextLabel")
    itemCount.Name = "ItemCount"
    itemCount.Size = UDim2.new(0, 40, 0, 20)
    itemCount.Position = UDim2.new(1, -2, 0, 2)
    itemCount.AnchorPoint = Vector2.new(1, 0)
    itemCount.BackgroundTransparency = 1
    itemCount.Text = ""
    itemCount.TextColor3 = Color3.fromRGB(0, 0, 0) -- Pure black
    itemCount.TextSize = 14
    itemCount.Font = Enum.Font.GothamBold
    itemCount.TextXAlignment = Enum.TextXAlignment.Right
    itemCount.TextYAlignment = Enum.TextYAlignment.Top
    itemCount.TextWrapped = false
    itemCount.Visible = true -- Always visible, will show/hide based on count
    itemCount.ZIndex = 15 -- Higher z-index to ensure it's on top
    itemCount.Parent = slot
    
    -- Add text stroke for visibility on any background
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(255, 255, 255) -- White outline
    textStroke.Thickness = 2
    textStroke.Transparency = 0.3
    textStroke.Parent = itemCount

    -- Item name label (shown on hover)
    local itemName = Instance.new("TextLabel")
    itemName.Name = "ItemName"
    itemName.Size = UDim2.new(1, 0, 0.3, 0)
    itemName.Position = UDim2.new(0, 0, 0.7, 0)
    itemName.BackgroundTransparency = 0.3
    itemName.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    itemName.Text = ""
    itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemName.TextSize = 10
    itemName.Font = Enum.Font.Gotham
    itemName.TextWrapped = true
    itemName.TextScaled = true
    itemName.Visible = false
    itemName.Parent = slot

    return slot
end

function InventoryGuiSetup.createDebugInventoryGui()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Remove existing if present
    local existing = playerGui:FindFirstChild("DebugInventoryGUI")
    if existing then
        existing:Destroy()
    end

    -- Create main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DebugInventoryGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 15
    screenGui.Enabled = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local layout = GUIContentManager.getLayoutConfig("Inventory")

    -- Create debug inventory frame
    local debugFrame = Instance.new("Frame")
    debugFrame.Name = "DebugInventoryFrame"
    debugFrame.Size = UDim2.new(0.85, 0, 0.8, 0)
    debugFrame.Position = UDim2.new(0.075, 0, 0.1, 0)
    debugFrame.AnchorPoint = Vector2.new(0, 0)
    debugFrame.BorderSizePixel = 0
    debugFrame.Visible = false
    debugFrame.Parent = screenGui
    applyFrameStyling(debugFrame, layout)

    local contentContainer = ensureContentContainer(debugFrame)
    local debugItems = ensureInventoryItems(contentContainer, layout, {
        name = "DebugInventoryItems",
        layoutOrder = 1,
        scrolling = true,
        paddingScale = 0.05,
        size = UDim2.new(1, 0, 1, 0),
        cellPadding = UDim2.new(0, 18, 0, 18),
    })
    debugItems.ScrollBarThickness = 8
    debugItems.ScrollBarImageColor3 = Color3.fromRGB(180, 170, 150)

    -- Create debug item slot template
    local debugSlotTemplate = InventoryGuiSetup.createSlotTemplate()
    debugSlotTemplate.Name = "DebugItemSlotTemplate"
    debugSlotTemplate.Visible = false
    debugSlotTemplate.Parent = debugItems

    print("[InventoryGuiSetup] ✅ Created DebugInventoryGUI")
    return screenGui
end

-- Auto-detect screen size changes and update layouts
local _responsiveSetupDone = false
function InventoryGuiSetup.setupResponsiveLayout()
    if _responsiveSetupDone then
        return -- Only setup once
    end
    _responsiveSetupDone = true

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Debounce to prevent rapid-fire calls
    local lastUpdate = 0
    local debounceTime = 0.5 -- 500ms debounce

    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        local now = tick()
        if now - lastUpdate < debounceTime then
            return -- Debounce
        end
        lastUpdate = now

        -- Recreate GUIs with new responsive sizing
        local inventoryGui = playerGui:FindFirstChild("InventoryGUI")
        local debugGui = playerGui:FindFirstChild("DebugInventoryGUI")

        if inventoryGui then
            local wasVisible = inventoryGui:FindFirstChild("InventoryFrame") and inventoryGui.InventoryFrame.Visible
            InventoryGuiSetup.createInventoryGui()
            if wasVisible and inventoryGui:FindFirstChild("InventoryFrame") then
                inventoryGui.InventoryFrame.Visible = true
            end
        end

        if debugGui then
            local wasVisible = debugGui:FindFirstChild("DebugInventoryFrame") and debugGui.DebugInventoryFrame.Visible
            InventoryGuiSetup.createDebugInventoryGui()
            if wasVisible and debugGui:FindFirstChild("DebugInventoryFrame") then
                debugGui.DebugInventoryFrame.Visible = true
            end
        end
    end)
end

return InventoryGuiSetup
