-- InventoryGuiSetup.lua
-- Creates the inventory GUI structure with responsive slot templates

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local InventoryGuiSetup = {}

function InventoryGuiSetup.createInventoryGui()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Look for existing InventoryGUI in Roblox (don't create it)
    local screenGui = playerGui:FindFirstChild("InventoryGUI")
    if not screenGui then
        warn("[InventoryGuiSetup] ❌ InventoryGUI not found in PlayerGui - make sure it exists in Roblox!")
        return nil
    end
    
    print("[InventoryGuiSetup] ✅ Found existing InventoryGUI in PlayerGui")
    
    -- Find InventoryFrame
    local inventoryFrame = screenGui:FindFirstChild("InventoryFrame")
    if not inventoryFrame then
        warn("[InventoryGuiSetup] ❌ InventoryFrame not found in InventoryGUI")
        return screenGui
    end
    
    print("[InventoryGuiSetup] ✅ Found InventoryFrame")
    
    -- Find or create InventoryItems ScrollingFrame
    local inventoryItems = inventoryFrame:FindFirstChild("InventoryItems")
    
    if not inventoryItems then
        warn("[InventoryGuiSetup] ⚠ InventoryItems not found, creating it...")
        inventoryItems = Instance.new("ScrollingFrame")
        inventoryItems.Name = "InventoryItems"
        inventoryItems.Size = UDim2.new(1, 0, 1, 0)
        inventoryItems.Position = UDim2.new(0, 0, 0, 0)
        inventoryItems.BackgroundTransparency = 0
        inventoryItems.BorderSizePixel = 0
        inventoryItems.ScrollBarThickness = 8
        inventoryItems.CanvasSize = UDim2.new(0, 0, 0, 0)
        inventoryItems.AutomaticCanvasSize = Enum.AutomaticSize.Y
        inventoryItems.Parent = inventoryFrame
    end
    
    -- Check for existing layout - if user added UIListLayout, use it; otherwise create UIGridLayout
    local existingListLayout = inventoryItems:FindFirstChildOfClass("UIListLayout")
    local existingGridLayout = inventoryItems:FindFirstChildOfClass("UIGridLayout")
    
    if existingListLayout then
        print("[InventoryGuiSetup] ✅ Found existing UIListLayout - using it")
        -- Ensure it's configured correctly
        if existingListLayout.SortOrder ~= Enum.SortOrder.LayoutOrder then
            existingListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        end
    elseif not existingGridLayout then
        -- Create UIGridLayout only if no layout exists
        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.FillDirection = Enum.FillDirection.Horizontal
        gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.CellSize = UDim2.new(0, 50, 0, 50)
        gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
        gridLayout.Parent = inventoryItems
        print("[InventoryGuiSetup] ✅ Created UIGridLayout for inventory slots")
    else
        print("[InventoryGuiSetup] ✅ Found existing UIGridLayout - using it")
    end
    
    print("[InventoryGuiSetup] ✅ InventoryItems ready")
    
    -- Find or create ItemSlotTemplate
    local slotTemplate = inventoryItems:FindFirstChild("ItemSlotTemplate")
    if not slotTemplate then
        print("[InventoryGuiSetup] Creating ItemSlotTemplate...")
        slotTemplate = InventoryGuiSetup.createSlotTemplate()
        slotTemplate.Name = "ItemSlotTemplate"
        slotTemplate.Visible = false
        slotTemplate.Parent = inventoryItems
    end
    
    print("[InventoryGuiSetup] ✅ Inventory GUI setup complete!")
    
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
        slotSize = math.floor(viewportSize.X * 0.08)  -- ~8% of screen width per slot
        slotSize = math.clamp(slotSize, 60, 80)
    end
    
    local slot = Instance.new("Frame")
    slot.Name = "ItemSlot"
    slot.Size = UDim2.new(0, slotSize, 0, slotSize)
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
    itemIcon.ImageRectSize = Vector2.new(36, 36)  -- Default sprite size from config
    itemIcon.Parent = slot
    
    -- Item count label
    local itemCount = Instance.new("TextLabel")
    itemCount.Name = "ItemCount"
    itemCount.Size = UDim2.new(0.4, 0, 0.25, 0)
    itemCount.Position = UDim2.new(0.58, 0, 0.73, 0)
    itemCount.AnchorPoint = Vector2.new(0, 0)
    itemCount.BackgroundTransparency = 1
    itemCount.Text = ""
    itemCount.TextColor3 = Color3.fromRGB(60, 50, 40)
    itemCount.TextSize = 12
    itemCount.Font = Enum.Font.GothamBold
    itemCount.TextXAlignment = Enum.TextXAlignment.Right
    itemCount.TextYAlignment = Enum.TextYAlignment.Bottom
    itemCount.Visible = false
    itemCount.Parent = slot
    
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
function InventoryGuiSetup.setupResponsiveLayout()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        -- Recreate GUIs with new responsive sizing
        local inventoryGui = playerGui:FindFirstChild("InventoryGUI")
        local debugGui = playerGui:FindFirstChild("DebugInventoryGUI")
        
        if inventoryGui then
            local wasVisible = inventoryGui:FindFirstChild("InventoryFrame") 
                and inventoryGui.InventoryFrame.Visible
            InventoryGuiSetup.createInventoryGui()
            if wasVisible and inventoryGui:FindFirstChild("InventoryFrame") then
                inventoryGui.InventoryFrame.Visible = true
            end
        end
        
        if debugGui then
            local wasVisible = debugGui:FindFirstChild("DebugInventoryFrame") 
                and debugGui.DebugInventoryFrame.Visible
            InventoryGuiSetup.createDebugInventoryGui()
            if wasVisible and debugGui:FindFirstChild("DebugInventoryFrame") then
                debugGui.DebugInventoryFrame.Visible = true
            end
        end
    end)
end

return InventoryGuiSetup
