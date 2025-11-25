t-- InventoryGuiSetup.lua
-- Creates the inventory GUI structure with responsive slot templates

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ThemeProvider = require(script.Parent.ThemeProvider)
local GUIContentManager = require(script.Parent.GUIContentManager)
local LayoutLint = require(script.Parent.LayoutLint)

local InventoryGuiSetup = {}

local _inventoryGuiInitialized = false

-- Bells and miles appendages removed as requested
-- Only keeping basic labels as specified

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
        print("[InventoryGuiSetup] ♻️ Refreshed existing InventoryFrame")
    end

    local contentContainer = ensureContentContainer(inventoryFrame)
    local inventoryItems = ensureInventoryItems(contentContainer, layout, {
        layoutOrder = 1,
    })
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
    -- Light gray background (removed brown background as requested)
    slot.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    slot.BorderSizePixel = 0

    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(1, 0) -- Circular as in reference
    slotCorner.Parent = slot

    -- Item icon (sprite)
    local itemIcon = Instance.new("ImageLabel")
    itemIcon.Name = "ItemIcon"
    itemIcon.Size = UDim2.new(1, 0, 1, 0)
    itemIcon.Position = UDim2.new(0, 0, 0, 0)
    itemIcon.AnchorPoint = Vector2.new(0, 0)
    itemIcon.BackgroundTransparency = 1
    itemIcon.Image = ""
    itemIcon.ScaleType = Enum.ScaleType.Fit
    itemIcon.ImageRectSize = Vector2.new(36, 36) -- Default sprite size from config
    itemIcon.Parent = slot

    -- Item count label (top-right, matches reference styling)
    local itemCount = Instance.new("TextLabel")
    itemCount.Name = "ItemCount"
    itemCount.Size = UDim2.new(0.2, 0, 0.2, 0)
    itemCount.Position = UDim2.new(1, 0, 1, 0)
    itemCount.AnchorPoint = Vector2.new(0.5, 0.5)
    itemCount.BackgroundTransparency = 1
    itemCount.Text = "00"
    itemCount.TextColor3 = Color3.fromRGB(0, 0, 0) -- Black text as in reference
    itemCount.TextSize = 14
    itemCount.Font = Enum.Font.SourceSans
    itemCount.TextXAlignment = Enum.TextXAlignment.Right
    itemCount.TextYAlignment = Enum.TextYAlignment.Bottom
    itemCount.TextScaled = true
    itemCount.TextWrapped = true
    itemCount.Visible = true
    itemCount.ZIndex = 15
    itemCount.Parent = slot

    -- Item name label (bottom as in reference)
    local itemName = Instance.new("TextLabel")
    itemName.Name = "ItemName"
    itemName.Size = UDim2.new(0.75, 0, 0.75, 0)
    itemName.Position = UDim2.new(0.5, 0, 1, 0)
    itemName.AnchorPoint = Vector2.new(0.5, 0) -- Centered horizontally at bottom
    itemName.BackgroundColor3 = Color3.fromRGB(130, 213, 187) -- Teal green as in reference
    itemName.BackgroundTransparency = 0
    itemName.Text = "Item Name"
    itemName.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text as in reference
    itemName.TextSize = 14
    itemName.Font = Enum.Font.SourceSans
    itemName.TextWrapped = true
    itemName.TextXAlignment = Enum.TextXAlignment.Center
    itemName.TextYAlignment = Enum.TextYAlignment.Center
    itemName.Visible = true
    itemName.ZIndex = 15
    itemName.Parent = slot

    -- Add rounded corners to item name as in reference
    local nameCorner = Instance.new("UICorner")
    nameCorner.CornerRadius = UDim.new(0, 8) -- Rounded corners as in reference
    nameCorner.Parent = itemName

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
