-- InventoryGuiSetup.lua
-- Creates the inventory GUI structure with responsive slot templates

local Players = game:GetService("Players")

local ThemeProvider = require(script.Parent.ThemeProvider)
local GUIContentManager = require(script.Parent.GUIContentManager)
local LayoutLint = require(script.Parent.LayoutLint)

local InventoryGuiSetup = {}

local _inventoryGuiInitialized = false

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
        cornerRadius = layout.cornerRadius and UDim.new(0, layout.cornerRadius) or "xlarge",
        strokeColor = "lightBrown",
        strokeThickness = 2,
        shadow = "large",
    })

    local padding = frame:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, layout.padding.top or 24)
    padding.PaddingBottom = UDim.new(0, layout.padding.bottom or 24)
    padding.PaddingLeft = UDim.new(0, layout.padding.left or 24)
    padding.PaddingRight = UDim.new(0, layout.padding.right or 24)
    padding.Parent = frame
end

local function createHeader(frame, layout)
    local header = frame:FindFirstChild("InventoryHeader")
    if header and header:IsA("Frame") then
        return header
    end

    header = Instance.new("Frame")
    header.Name = "InventoryHeader"
    header.Size = UDim2.new(1, 0, 0, layout.headerHeight or 48)
    header.BackgroundTransparency = 1
    header.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = GUIContentManager.Inventory.title
    titleLabel.Font = ThemeProvider.getFont("bold")
    titleLabel.TextSize = ThemeProvider.getTextSize("xxlarge")
    titleLabel.TextColor3 = ThemeProvider.getColor("buttonBrown")
    titleLabel.Parent = header

    local closeButton = ThemeProvider.createCloseButton(header, {
        onClick = function()
            local inventoryFrame = header:FindFirstAncestor("InventoryFrame")
            if inventoryFrame then
                inventoryFrame.Visible = false
            end
        end,
    })
    closeButton.Name = "CloseButton"
    closeButton.Text = GUIContentManager.Inventory.buttons.close

    return header
end

local function createActionRow(frame, layout)
    local actionRow = frame:FindFirstChild("InventoryActions")
    if actionRow and actionRow:IsA("Frame") then
        return actionRow
    end

    actionRow = Instance.new("Frame")
    actionRow.Name = "InventoryActions"
    actionRow.Size = UDim2.new(1, 0, 0, layout.searchHeight or 36)
    actionRow.BackgroundTransparency = 1
    actionRow.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Padding = UDim.new(0, 12)
    listLayout.Parent = actionRow

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -150, 1, 0)
    searchBox.BackgroundColor3 = ThemeProvider.getColor("eggshell")
    searchBox.TextColor3 = ThemeProvider.getColor("textPrimary")
    searchBox.Font = ThemeProvider.getFont("primary")
    searchBox.TextSize = ThemeProvider.getTextSize("medium")
    searchBox.PlaceholderText = GUIContentManager.Inventory.buttons.search
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Text = ""
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = actionRow

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = ThemeProvider.getRadius("medium")
    searchCorner.Parent = searchBox

    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color = ThemeProvider.getColor("lightBrown")
    searchStroke.Thickness = 1
    searchStroke.Parent = searchBox

    local sortButton = ThemeProvider.createSecondaryButton(actionRow, GUIContentManager.Inventory.buttons.sort, {
        size = UDim2.new(0, 120, 1, 0),
    })
    sortButton.Name = "SortButton"
    sortButton.AutoButtonColor = true

    return actionRow
end

local function ensureInventoryItems(frame, layout)
    local inventoryItems = frame:FindFirstChild("InventoryItems")
    if not inventoryItems or not inventoryItems:IsA("ScrollingFrame") then
        inventoryItems = Instance.new("ScrollingFrame")
        inventoryItems.Name = "InventoryItems"
        inventoryItems.BackgroundTransparency = 1
        inventoryItems.BorderSizePixel = 0
        inventoryItems.ScrollBarThickness = 6
        inventoryItems.ScrollingDirection = Enum.ScrollingDirection.Y
        inventoryItems.CanvasSize = UDim2.new(0, 0, 0, 0)
        inventoryItems.AutomaticCanvasSize = Enum.AutomaticSize.Y
        inventoryItems.Parent = frame
    end

    local padding = inventoryItems:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, layout.footerHeight or 24)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = inventoryItems

    local existingGrid = inventoryItems:FindFirstChildOfClass("UIGridLayout")
    if not existingGrid then
        existingGrid = Instance.new("UIGridLayout")
        existingGrid.FillDirection = Enum.FillDirection.Horizontal
        existingGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
        existingGrid.VerticalAlignment = Enum.VerticalAlignment.Top
        existingGrid.SortOrder = Enum.SortOrder.LayoutOrder
        existingGrid.Parent = inventoryItems
    end

    local slotLayout = layout.slot or {}
    existingGrid.CellSize = slotLayout.size or UDim2.new(0, 60, 0, 60)
    local paddingValue = 8
    if slotLayout.padding then
        paddingValue = slotLayout.padding.Offset ~= 0 and slotLayout.padding.Offset or paddingValue
    end
    existingGrid.CellPadding = UDim2.new(0, paddingValue, 0, paddingValue)

    return inventoryItems
end

local function createFooter(frame, layout)
    local footer = frame:FindFirstChild("InventoryFooter")
    if footer and footer:IsA("TextLabel") then
        return footer
    end

    footer = Instance.new("TextLabel")
    footer.Name = "InventoryFooter"
    footer.Size = UDim2.new(1, 0, 0, layout.footerHeight or 24)
    footer.BackgroundTransparency = 1
    footer.Position = UDim2.new(0, 0, 1, -((layout.footerHeight or 24)))
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.Text = GUIContentManager.Inventory.messages.empty
    footer.Font = ThemeProvider.getFont("secondary")
    footer.TextSize = ThemeProvider.getTextSize("small")
    footer.TextColor3 = ThemeProvider.getColor("textSecondary")
    footer.Parent = frame

    return footer
end

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
    createHeader(frame, layout)
    createActionRow(frame, layout)
    ensureInventoryItems(frame, layout)
    createFooter(frame, layout)

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
        createHeader(inventoryFrame, layout)
        createActionRow(inventoryFrame, layout)
        ensureInventoryItems(inventoryFrame, layout)
        createFooter(inventoryFrame, layout)
        print("[InventoryGuiSetup] ♻️ Refreshed existing InventoryFrame")
    end

    local inventoryItems = ensureInventoryItems(inventoryFrame, layout)
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
    local viewportSize = workspace.CurrentCamera.ViewportSize
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

    -- Create debug inventory frame
    local debugFrame = Instance.new("Frame")
    debugFrame.Name = "DebugInventoryFrame"
    debugFrame.Size = UDim2.new(0.85, 0, 0.8, 0)
    debugFrame.Position = UDim2.new(0.075, 0, 0.1, 0)
    debugFrame.AnchorPoint = Vector2.new(0, 0)
    debugFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    debugFrame.BorderSizePixel = 0
    debugFrame.Visible = false
    debugFrame.Parent = screenGui

    -- Add UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = debugFrame

    -- Add UIPadding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = debugFrame

    -- Create scrolling frame for debug items
    local debugItems = Instance.new("ScrollingFrame")
    debugItems.Name = "DebugInventoryItems"
    debugItems.Size = UDim2.new(1, 0, 1, 0)
    debugItems.Position = UDim2.new(0, 0, 0, 0)
    debugItems.BackgroundTransparency = 1
    debugItems.BorderSizePixel = 0
    debugItems.ScrollBarThickness = 10
    debugItems.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    debugItems.CanvasSize = UDim2.new(0, 0, 0, 0)
    debugItems.AutomaticCanvasSize = Enum.AutomaticSize.Y
    debugItems.Parent = debugFrame

    -- Add UIGridLayout for responsive grid
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.CellSize = UDim2.new(0, 65, 0, 65)
    gridLayout.CellPadding = UDim2.new(0, 3, 0, 3)
    gridLayout.Parent = debugItems

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

    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
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
