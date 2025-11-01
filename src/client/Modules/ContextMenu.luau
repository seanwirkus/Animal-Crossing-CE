-- Context Menu System for Inventory Items
-- Right-click popup menu with Drop, Delete, and Equip options
-- Styled with Animal Crossing theme (CREAM background, rounded corners)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ContextMenu = {}
ContextMenu.__index = ContextMenu

-- AC Theme Colors
local CREAM = Color3.fromRGB(255, 251, 231)      -- #FFFBE7
local BROWN = Color3.fromRGB(120, 100, 80)       -- #786450
local DARK = Color3.fromRGB(60, 50, 40)
local WHITE = Color3.fromRGB(255, 255, 255)

-- Menu styling constants
local MENU_WIDTH = 160
local MENU_ITEM_HEIGHT = 40
local CORNER_RADIUS = UDim.new(0, 8)
local PADDING = 8

function ContextMenu.new(screenGui, inventoryRemote, itemDataFetcher)
    local self = setmetatable({}, ContextMenu)
    
    self.screenGui = screenGui  -- Can be nil, will be set later
    self.inventoryRemote = inventoryRemote
    self.itemDataFetcher = itemDataFetcher
    
    self.menuFrame = nil
    self.isOpen = false
    self.currentItem = nil
    self.closeConnection = nil
    
    print("[ContextMenu] ✅ Initialized with screenGui:", screenGui)
    return self
end

--- Create menu items with their actions
function ContextMenu:createMenuItems()
    local items = {}
    
    if not self.currentItem then
        return items
    end
    
    -- EQUIP option (if item is a tool or wearable)
    if self:isTool(self.currentItem) or self:isWearable(self.currentItem) then
        table.insert(items, {
            label = "⚒️ Equip",
            action = function(item)
                self:equipItem(item)
            end,
            color = CREAM,
            hoverColor = Color3.fromRGB(200, 240, 230)
        })
    end
    
    -- DROP option
    table.insert(items, {
        label = "📦 Drop",
        action = function(item)
            self:dropItem(item)
        end,
        color = CREAM,
        hoverColor = Color3.fromRGB(240, 230, 200)
    })
    
    -- DELETE option
    table.insert(items, {
        label = "🗑️ Delete",
        action = function(item)
            self:deleteItem(item)
        end,
        color = Color3.fromRGB(255, 200, 200),  -- Light red
        hoverColor = Color3.fromRGB(255, 100, 100)  -- Darker red on hover
    })
    
    return items
end

--- Check if item is wearable (clothing, hats, etc.)
function ContextMenu:isWearable(item)
    -- Check item categories that are wearable
    local wearableCategories = {
        "Clothing",
        "Accessories",
        "Hats",
        "Shoes",
        "Bags",
        "Belts",
    }
    
    if item.category then
        for _, category in ipairs(wearableCategories) do
            if string.find(item.category, category, 1, true) then
                return true
            end
        end
    end
    
    -- Additional check for common wearable item names
    local wearableKeywords = {"hat", "shirt", "shoes", "dress", "helmet", "glasses", "coat", "jacket", "gloves", "scarf"}
    local itemName = string.lower(item.name or "")
    for _, keyword in ipairs(wearableKeywords) do
        if string.find(itemName, keyword, 1, true) then
            return true
        end
    end
    
    return false
end

--- Check if item is a tool (equipable)
function ContextMenu:isTool(item)
    local itemId = string.lower(item.id or "")
    local itemName = string.lower(item.name or "")
    
    -- List of tool keywords
    local toolKeywords = {
        "shovel", "net", "fishing", "rod", "axe", "watering", "can", 
        "slingshot", "pole", "vault", "ladder", "flute", "tambourine"
    }
    
    -- Check item ID
    for _, keyword in ipairs(toolKeywords) do
        if string.find(itemId, keyword, 1, true) then
            return true
        end
    end
    
    -- Check item name
    for _, keyword in ipairs(toolKeywords) do
        if string.find(itemName, keyword, 1, true) then
            return true
        end
    end
    
    return false
end

--- Show context menu at mouse position
function ContextMenu:show(item, mousePos)
    if not item or not item.id then
        warn("[ContextMenu] Invalid item provided to show()")
        return
    end
    
    -- Don't log every context menu show (too verbose)
    
    if not self.screenGui then
        warn("[ContextMenu] ERROR: screenGui is nil!")
        return
    end
    
    -- Create menu frame if it doesn't exist
    if not self.menuFrame then
        self:createMenu()
    end
    
    if not self.menuFrame then
        warn("[ContextMenu] ERROR: Failed to create menuFrame!")
        return
    end
    
    self.currentItem = item
    self.isOpen = true
    
    -- Get menu items
    local menuItems = self:createMenuItems()
    
    if #menuItems == 0 then
        warn("[ContextMenu] No menu items to show!")
        return
    end
    
    -- Update menu items
    self:updateMenuItems(menuItems)
    
    -- Calculate menu height
    local menuHeight = (#menuItems * MENU_ITEM_HEIGHT) + (PADDING * 2)
    self.menuFrame.Size = UDim2.new(0, MENU_WIDTH, 0, menuHeight)
    
    -- Handle mouse position (can be Vector2 or have .X/.Y properties)
    local x, y
    if typeof(mousePos) == "Vector2" then
        x = mousePos.X
        y = mousePos.Y
    elseif mousePos.X and mousePos.Y then
        x = mousePos.X
        y = mousePos.Y
    else
        -- Fallback: try to get mouse position
        local mouse = Players.LocalPlayer:GetMouse()
        x = mouse.X
        y = mouse.Y
    end
    
    -- Clamp position to screen bounds
    local screenSize = self.screenGui.AbsoluteSize
    x = math.max(0, math.min(x, screenSize.X - MENU_WIDTH))
    y = math.max(0, math.min(y, screenSize.Y - menuHeight))
    
    -- Position at mouse
    self.menuFrame.Position = UDim2.new(0, x, 0, y)
    
    -- Make visible
    self.menuFrame.Visible = true
    
    -- Close on escape or click elsewhere
    if self.closeConnection then
        self.closeConnection:Disconnect()
    end
    
    self.closeConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.Escape then
            self:close()
        end
    end)
    
    print("[ContextMenu] ===== SHOW COMPLETE =====")
end

--- Create the menu frame UI
function ContextMenu:createMenu()
    print("[ContextMenu] ===== CREATE MENU CALLED =====")
    print("[ContextMenu] screenGui:", self.screenGui)
    
    if not self.screenGui then
        warn("[ContextMenu] ERROR: Cannot create menu - screenGui is nil")
        return
    end
    
    print("[ContextMenu] Creating Frame...")
    self.menuFrame = Instance.new("Frame")
    self.menuFrame.Name = "ContextMenuFrame"
    self.menuFrame.BackgroundColor3 = CREAM
    self.menuFrame.BorderSizePixel = 0
    self.menuFrame.ZIndex = 51
    print("[ContextMenu] Frame created, setting parent to screenGui...")
    
    self.menuFrame.Parent = self.screenGui
    print("[ContextMenu] Frame parent set")
    print("[ContextMenu] Frame.Parent is screenGui:", self.menuFrame.Parent == self.screenGui)
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CORNER_RADIUS
    corner.Parent = self.menuFrame
    print("[ContextMenu] UICorner added")
    
    -- Add border
    local stroke = Instance.new("UIStroke")
    stroke.Color = BROWN
    stroke.Thickness = 2
    stroke.Parent = self.menuFrame
    print("[ContextMenu] UIStroke added")
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, PADDING / 2)
    padding.PaddingRight = UDim.new(0, PADDING / 2)
    padding.PaddingTop = UDim.new(0, PADDING / 2)
    padding.PaddingBottom = UDim.new(0, PADDING / 2)
    padding.Parent = self.menuFrame
    print("[ContextMenu] UIPadding added")
    
    -- Add list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.menuFrame
    print("[ContextMenu] UIListLayout added")
    
    print("[ContextMenu] ===== CREATE MENU COMPLETE =====")
end

--- Update menu with current items
function ContextMenu:updateMenuItems(menuItems)
    -- Clear existing buttons
    for _, child in pairs(self.menuFrame:GetChildren()) do
        if child.Name == "MenuItem" then
            child:Destroy()
        end
    end
    
    -- Create buttons for each item
    for index, itemData in ipairs(menuItems) do
        self:createMenuItem(itemData, index)
    end
end

--- Create individual menu item button
function ContextMenu:createMenuItem(itemData, layoutOrder)
    local button = Instance.new("TextButton")
    button.Name = "MenuItem"
    button.Text = itemData.label
    button.Size = UDim2.new(1, 0, 0, MENU_ITEM_HEIGHT)
    button.BackgroundColor3 = itemData.color
    button.TextColor3 = DARK
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.LayoutOrder = layoutOrder
    button.ZIndex = 52
    
    -- Add rounded corners to button
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = itemData.hoverColor
        button.TextColor3 = WHITE
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = itemData.color
        button.TextColor3 = DARK
    end)
    
    -- Click action
    button.MouseButton1Click:Connect(function()
        itemData.action(self.currentItem)
        self:close()
    end)
    
    button.Parent = self.menuFrame
end

--- Drop item to world
function ContextMenu:dropItem(item)
    print("[ContextMenu] Dropping item:", item.id)
    
    local player = Players.LocalPlayer
    local character = player.Character
    
    if not character then
        warn("[ContextMenu] No character found")
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        warn("[ContextMenu] No HumanoidRootPart found")
        return
    end
    
    local camera = workspace.CurrentCamera
    if not camera then
        warn("[ContextMenu] No camera found")
        return
    end
    
    -- Drop 3 studs in front of player
    local forwardDirection = humanoidRootPart.CFrame.LookVector
    local worldPosition = humanoidRootPart.Position + forwardDirection * 3
    
    -- Fire drop event to server
    self.inventoryRemote:FireServer("DropItem", {
        itemId = item.id,
        count = item.count or 1,
        position = worldPosition,
    })
    
    print("[ContextMenu] ✅ Fired DropItem to server")
end

--- Delete item from inventory
function ContextMenu:deleteItem(item)
    print("[ContextMenu] Deleting item:", item.id)
    
    -- Fire delete event to server
    self.inventoryRemote:FireServer("DeleteItem", {
        itemId = item.id,
        count = item.count or 1,
    })
    
    print("[ContextMenu] ✅ Fired DeleteItem to server")
end

--- Equip wearable item
function ContextMenu:equipItem(item)
    print("[ContextMenu] Equipping item:", item.id)
    
    -- Fire equip event to server
    -- This will be handled by the character clothing system
    self.inventoryRemote:FireServer("EquipItem", {
        itemId = item.id,
    })
    
    print("[ContextMenu] ✅ Fired EquipItem to server")
end

--- Close menu
function ContextMenu:close()
    if not self.isOpen then return end
    
    self.isOpen = false
    self.currentItem = nil
    
    if self.menuFrame then
        self.menuFrame.Visible = false
    end
    
    if self.closeConnection then
        self.closeConnection:Disconnect()
        self.closeConnection = nil
    end
    
    print("[ContextMenu] Closed")
end

--- Toggle menu visibility
function ContextMenu:toggle(item, mousePos)
    if self.isOpen then
        self:close()
    else
        self:show(item, mousePos)
    end
end

return ContextMenu
