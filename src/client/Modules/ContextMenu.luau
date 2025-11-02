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
    -- If no screenGui provided, create one and parent to PlayerGui
    if not screenGui then
        local player = Players.LocalPlayer
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then
            playerGui = player:WaitForChild("PlayerGui")
        end
        local existing = playerGui:FindFirstChild("ContextMenuScreen")
        if existing then
            self.screenGui = existing
        else
            local gui = Instance.new("ScreenGui")
            gui.Name = "ContextMenuScreen"
            gui.IgnoreGuiInset = true
            gui.DisplayOrder = 9999
            gui.ResetOnSpawn = false
            gui.Parent = playerGui
            self.screenGui = gui
        end
    else
        self.screenGui = screenGui
    end
    self.inventoryRemote = inventoryRemote
    self.itemDataFetcher = itemDataFetcher
    self.menuFrame = nil
    self.isOpen = false
    self.currentItem = nil
    self.closeConnection = nil
    print("[ContextMenu] ✅ Initialized with screenGui:", self.screenGui)
    return self
end

--- Allow moving menu to another ScreenGui (such as when inventory GUI loads)
function ContextMenu:setScreenGui(newScreenGui)
    if not newScreenGui then return end
    self.screenGui = newScreenGui
    -- If the menu is open, re-parent the menuFrame
    if self.menuFrame and self.menuFrame.Parent ~= newScreenGui then
        self.menuFrame.Parent = newScreenGui
    end
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
    print("[ContextMenu] ===== SHOW CALLED =====")
    print("[ContextMenu] Item:", item and item.id or "nil")
    print("[ContextMenu] MousePos:", mousePos)
    
    if not item or not item.id then
        warn("[ContextMenu] Invalid item provided to show()")
        return
    end
    
    -- Ensure screenGui exists
    if not self.screenGui then
        warn("[ContextMenu] ERROR: screenGui is nil! Creating one...")
        local player = Players.LocalPlayer
        local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        local gui = Instance.new("ScreenGui")
        gui.Name = "ContextMenuScreen"
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 9999
        gui.ResetOnSpawn = false
        gui.Enabled = true
        gui.Parent = playerGui
        self.screenGui = gui
        print("[ContextMenu] Created new screenGui")
    end
    
    -- Ensure screenGui is enabled
    if not self.screenGui.Enabled then
        self.screenGui.Enabled = true
    end
    
    -- Ensure screenGui has a parent
    if not self.screenGui.Parent then
        local player = Players.LocalPlayer
        local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        self.screenGui.Parent = playerGui
    end
    
    -- Create menu frame if it doesn't exist
    if not self.menuFrame then
        print("[ContextMenu] Creating menu frame...")
        self:createMenu()
    end
    
    if not self.menuFrame then
        warn("[ContextMenu] ERROR: Failed to create menuFrame!")
        return
    end
    
    -- Ensure menuFrame has a parent
    if not self.menuFrame.Parent then
        self.menuFrame.Parent = self.screenGui
        print("[ContextMenu] Re-parented menuFrame to screenGui")
    end
    
    self.currentItem = item
    self.isOpen = true
    
    -- Get menu items
    local menuItems = self:createMenuItems()
    print("[ContextMenu] Created", #menuItems, "menu items")
    
    if #menuItems == 0 then
        warn("[ContextMenu] No menu items to show!")
        return
    end
    
    -- Update menu items
    self:updateMenuItems(menuItems)
    
    -- Calculate menu height
    local menuHeight = (#menuItems * MENU_ITEM_HEIGHT) + (PADDING * 2)
    self.menuFrame.Size = UDim2.new(0, MENU_WIDTH, 0, menuHeight)
    print("[ContextMenu] Menu size:", MENU_WIDTH, "x", menuHeight)
    
    -- Handle mouse position (can be Vector2 or have .X/.Y properties)
    local x, y
    if typeof(mousePos) == "Vector2" then
        x = mousePos.X
        y = mousePos.Y
    elseif mousePos and mousePos.X and mousePos.Y then
        x = mousePos.X
        y = mousePos.Y
    else
        -- Fallback: try to get mouse position
        local mouse = Players.LocalPlayer:GetMouse()
        x = mouse.X
        y = mouse.Y
    end
    
    print("[ContextMenu] Mouse position:", x, y)
    
    -- Clamp position to screen bounds
    local screenSize = self.screenGui.AbsoluteSize
    print("[ContextMenu] Screen size:", screenSize.X, screenSize.Y)
    x = math.max(10, math.min(x, screenSize.X - MENU_WIDTH - 10))
    y = math.max(10, math.min(y, screenSize.Y - menuHeight - 10))
    
    -- Position at mouse
    self.menuFrame.Position = UDim2.new(0, x, 0, y)
    print("[ContextMenu] Menu positioned at:", x, y)
    
    -- Make sure everything is visible
    self.menuFrame.Visible = true
    self.menuFrame.BackgroundTransparency = 0
    
    -- Ensure high ZIndex
    self.menuFrame.ZIndex = 10000
    
    -- Force screenGui to be on top
    self.screenGui.DisplayOrder = 9999
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    print("[ContextMenu] Menu visible:", self.menuFrame.Visible)
    print("[ContextMenu] Menu parent:", self.menuFrame.Parent)
    print("[ContextMenu] Menu ZIndex:", self.menuFrame.ZIndex)
    print("[ContextMenu] ScreenGui enabled:", self.screenGui.Enabled)
    print("[ContextMenu] ScreenGui DisplayOrder:", self.screenGui.DisplayOrder)
    print("[ContextMenu] ScreenGui parent:", self.screenGui.Parent)
    
    -- Print menu frame size for debugging
    print("[ContextMenu] Menu size:", self.menuFrame.Size)
    print("[ContextMenu] Menu position:", self.menuFrame.Position)
    print("[ContextMenu] Menu AbsoluteSize:", self.menuFrame.AbsoluteSize)
    print("[ContextMenu] Menu AbsolutePosition:", self.menuFrame.AbsolutePosition)
    
    -- Close on escape or click elsewhere  
    if self.closeConnection then
        self.closeConnection:Disconnect()
    end
    
    -- Use task.spawn to avoid blocking the show() function
    task.spawn(function()
        task.wait(0.1)  -- Small delay to prevent immediate closing
        
        self.closeConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.Escape then
                -- Check if the click was on the menu itself
                if input.UserInputType == Enum.UserInputType.MouseButton1 and self.menuFrame then
                    local mouse = Players.LocalPlayer:GetMouse()
                    local mousePos = Vector2.new(mouse.X, mouse.Y)
                    local menuPos = self.menuFrame.AbsolutePosition
                    local menuSize = self.menuFrame.AbsoluteSize
                    
                    -- Don't close if clicking on the menu
                    if mousePos.X >= menuPos.X and mousePos.X <= menuPos.X + menuSize.X and
                       mousePos.Y >= menuPos.Y and mousePos.Y <= menuPos.Y + menuSize.Y then
                        return
                    end
                end
                
                self:close()
            end
        end)
    end)
    
    print("[ContextMenu] ===== SHOW COMPLETE =====")
end

--- Create the menu frame UI
function ContextMenu:createMenu()
    print("[ContextMenu] ===== CREATE MENU CALLED =====")
    
    if not self.screenGui then
        warn("[ContextMenu] ERROR: Cannot create menu - screenGui is nil")
        return
    end
    
    -- Destroy old menu if it exists
    if self.menuFrame then
        self.menuFrame:Destroy()
    end
    
    print("[ContextMenu] Creating Frame...")
    self.menuFrame = Instance.new("Frame")
    self.menuFrame.Name = "ContextMenuFrame"
    self.menuFrame.BackgroundColor3 = CREAM
    self.menuFrame.BorderSizePixel = 0
    self.menuFrame.ZIndex = 10000  -- Very high ZIndex to ensure it's on top
    self.menuFrame.Visible = false  -- Start hidden, will be shown in show()
    self.menuFrame.Size = UDim2.new(0, MENU_WIDTH, 0, 100)  -- Initial size
    
    -- Set parent immediately
    self.menuFrame.Parent = self.screenGui
    print("[ContextMenu] Frame parent set to:", self.screenGui.Name)
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CORNER_RADIUS
    corner.Parent = self.menuFrame
    
    -- Add border
    local stroke = Instance.new("UIStroke")
    stroke.Color = BROWN
    stroke.Thickness = 2
    stroke.Parent = self.menuFrame
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, PADDING)
    padding.PaddingRight = UDim.new(0, PADDING)
    padding.PaddingTop = UDim.new(0, PADDING)
    padding.PaddingBottom = UDim.new(0, PADDING)
    padding.Parent = self.menuFrame
    
    -- Add list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.menuFrame
    
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
    button.Size = UDim2.new(1, -PADDING * 2, 0, MENU_ITEM_HEIGHT)
    button.BackgroundColor3 = itemData.color
    button.TextColor3 = DARK
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.LayoutOrder = layoutOrder
    button.ZIndex = 10001  -- Higher than menu frame
    button.BackgroundTransparency = 0
    button.TextTruncate = Enum.TextTruncate.AtEnd
    
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
        print("[ContextMenu] 🖱️ BUTTON CLICKED:", itemData.label)
        print("[ContextMenu] Current item:", self.currentItem and self.currentItem.id or "nil")
        print("[ContextMenu] Action function:", type(itemData.action))
        
        if itemData.action and self.currentItem then
            pcall(function()
                itemData.action(self.currentItem)
            end)
        else
            warn("[ContextMenu] ❌ No action or current item!")
        end
    end)
    
    button.Parent = self.menuFrame
end

--- Drop item to world
function ContextMenu:dropItem(item)
    print("[ContextMenu] 🔥 DROP ITEM CALLED:", item.id)
    
    if not self.inventoryRemote then
        warn("[ContextMenu] ❌ No inventoryRemote available!")
        return
    end
    
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
    
    -- Drop 3 studs in front of player
    local forwardDirection = humanoidRootPart.CFrame.LookVector
    local worldPosition = humanoidRootPart.Position + forwardDirection * 3
    
    print("[ContextMenu] Calling inventoryRemote:FireServer with DropItem...")
    print("[ContextMenu] ItemId:", item.id)
    print("[ContextMenu] Count:", item.count or 1)
    print("[ContextMenu] Position:", worldPosition)
    
    -- Fire drop event to server
    self.inventoryRemote:FireServer("DropItem", {
        itemId = item.id,
        count = item.count or 1,
        position = worldPosition,
    })
    
    print("[ContextMenu] ✅ Fired DropItem to server")
    self:close()  -- Close menu after action
end

--- Delete item from inventory
function ContextMenu:deleteItem(item)
    print("[ContextMenu] 🗑️ DELETE ITEM CALLED:", item.id)
    
    if not self.inventoryRemote then
        warn("[ContextMenu] ❌ No inventoryRemote available!")
        return
    end
    
    print("[ContextMenu] Calling inventoryRemote:FireServer with DeleteItem...")
    print("[ContextMenu] ItemId:", item.id)
    print("[ContextMenu] Count:", item.count or 1)
    
    -- Fire delete event to server
    self.inventoryRemote:FireServer("DeleteItem", {
        itemId = item.id,
        count = item.count or 1,
    })
    
    print("[ContextMenu] ✅ Fired DeleteItem to server")
    self:close()  -- Close menu after action
end

--- Equip wearable item
function ContextMenu:equipItem(item)
    print("[ContextMenu] ⚒️ EQUIP ITEM CALLED:", item.id)
    
    if not self.inventoryRemote then
        warn("[ContextMenu] ❌ No inventoryRemote available!")
        return
    end
    
    print("[ContextMenu] Calling inventoryRemote:FireServer with EquipItem...")
    print("[ContextMenu] ItemId:", item.id)
    
    -- Fire equip event to server
    self.inventoryRemote:FireServer("EquipItem", {
        itemId = item.id,
    })
    
    print("[ContextMenu] ✅ Fired EquipItem to server")
    self:close()  -- Close menu after action
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
