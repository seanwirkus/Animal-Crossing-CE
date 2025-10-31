-- Item Browser Modal
-- Shows all items in a scrollable grid without pagination

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemBrowser = {}
ItemBrowser.__index = ItemBrowser

function ItemBrowser.new()
    local self = setmetatable({}, ItemBrowser)
    
    self.player = Players.LocalPlayer
    
    self.sharedFolder = ReplicatedStorage:WaitForChild("Shared")
    self.itemDataFetcher = require(self.sharedFolder:WaitForChild("ItemDataFetcher"))
    self.spriteConfig = require(self.sharedFolder:WaitForChild("SpriteConfig"))
    
    -- Try to load InventoryConstants (may be in different locations)
    local inventoryConstantsPath = self.sharedFolder:FindFirstChild("inventory")
    if inventoryConstantsPath then
        self.inventoryConstants = require(inventoryConstantsPath:WaitForChild("InventoryConstants"))
    else
        -- Fallback: try direct path or create a simple local function
        self.inventoryConstants = nil
    end
    
    self.inventoryRemote = ReplicatedStorage:WaitForChild("InventoryEvent")
    
    self.mainFrame = nil
    self.itemsPerRow = 10  -- 10 items per row (matches inventory level slots)
    
    -- Get reference to InventoryClient to check current level
    self.inventoryClient = nil
    
    self:loadAllItems()
    
    print("[ItemBrowser] ✅ Loaded with", #self.allItems, "total items")
    
    return self
end

function ItemBrowser:Init(parent)
    -- Parent should be a ScreenGui (from init.client.luau)
    if parent and parent:IsA("ScreenGui") then
        self.screenGui = parent
    end
    self:createGui()
    print("[ItemBrowser] ✅ Initialized standalone")
end

function ItemBrowser:Toggle()
    -- Ensure GUI is created
    if not self.mainFrame then
        self:createGui()
    end
    
    if self.mainFrame and self.screenGui then
        local isVisible = not self.mainFrame.Visible
        self.mainFrame.Visible = isVisible
        self.screenGui.Enabled = true  -- Ensure ScreenGui is enabled
        print("[ItemBrowser] Toggled visibility to:", isVisible)
    end
end

function ItemBrowser:Show()
    -- Ensure GUI is created
    if not self.mainFrame then
        self:createGui()
    end
    
    if self.mainFrame and self.screenGui then
        self.mainFrame.Visible = true
        self.screenGui.Enabled = true  -- Ensure ScreenGui is enabled
        print("[ItemBrowser] Showing GUI")
    else
        warn("[ItemBrowser] Cannot show - mainFrame or screenGui is missing")
    end
end

function ItemBrowser:Hide()
    if self.mainFrame then
        self.mainFrame.Visible = false
        print("[ItemBrowser] Hiding GUI")
    end
end

function ItemBrowser:loadAllItems()
    local allItems = self.itemDataFetcher.getAllItems()
    
    -- Create a map of items by spriteIndex and also by id for quick lookup
    local itemsBySpriteIndex = {}
    local itemsById = {}
    for _, item in ipairs(allItems) do
        if item.spriteIndex then
            itemsBySpriteIndex[item.spriteIndex] = item
        end
        if item.id then
            itemsById[item.id] = item
        end
    end
    
    -- Store itemsById for validation
    self.itemsById = itemsById
    
    -- Generate items for sprite positions (1-494, excluding 495-504 which are null)
    local itemsWithSprites = {}
    local maxSprites = 494  -- Exclude sprites 495-504 (they're null on spritesheet)
    
    for spriteIndex = 1, maxSprites do
        local item = itemsBySpriteIndex[spriteIndex]
        if item then
            -- Use mapped item
            table.insert(itemsWithSprites, item)
        else
            -- Create placeholder for unmapped sprite (for display only)
            table.insert(itemsWithSprites, {
                id = "sprite_" .. spriteIndex,
                name = "Sprite " .. spriteIndex,
                spriteIndex = spriteIndex,
                category = "unmapped",
                isPlaceholder = true  -- Mark as placeholder so we can prevent adding it
            })
        end
    end
    
    -- Already sorted by spriteIndex (1-494)
    self.allItems = itemsWithSprites
    
    print("[ItemBrowser] Loaded", #itemsWithSprites, "total sprite positions (", #itemsBySpriteIndex, "mapped,", #itemsWithSprites - #itemsBySpriteIndex, "unmapped)")
end


function ItemBrowser:createGui()
    if self.mainFrame then
        return
    end

    -- Use existing ScreenGui if set, otherwise create one
    if not self.screenGui then
        local playerGui = self.player:WaitForChild("PlayerGui")
        self.screenGui = playerGui:FindFirstChild("ItemBrowserGUI")
        if not self.screenGui then
            self.screenGui = Instance.new("ScreenGui")
            self.screenGui.Name = "ItemBrowserGUI"
            self.screenGui.ResetOnSpawn = false
            self.screenGui.DisplayOrder = 9
            self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            self.screenGui.Enabled = true
            self.screenGui.Parent = playerGui
        end
    end

    -- Main frame with cream background - matching your AC theme
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.85, 0, 0.8, 0)  -- Matching existing GUI sizes
    mainFrame.Position = UDim2.new(0.075, 0, 0.1, 0)  -- Centered
    mainFrame.BackgroundColor3 = Color3.fromRGB(255, 251, 231)  -- CREAM - your defined color
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 2
    mainFrame.Visible = false  -- Start hidden
    mainFrame.Parent = self.screenGui
    self.mainFrame = mainFrame
    
    -- Make sure screenGui is enabled
    if self.screenGui then
        self.screenGui.Enabled = true
    end
    
    -- Add UICorner for rounded corners (your standard 8px)
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame
    
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(120, 100, 80)  -- BROWN - your defined color
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Parent = mainFrame
    
    -- Add corner to title bar (top only)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Text = "🎮 Item Browser"
    titleText.Size = UDim2.new(1, -40, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = 4
    titleText.Parent = titleBar
    
    local itemCount = Instance.new("TextLabel")
    itemCount.Name = "ItemCount"
    itemCount.Text = "Showing " .. #self.allItems .. " items"
    itemCount.Size = UDim2.new(1, 0, 0, 25)
    itemCount.Position = UDim2.new(0, 0, 0, 40)
    itemCount.BackgroundColor3 = Color3.fromRGB(231, 221, 185)  -- BEIGE - your defined color
    itemCount.BorderSizePixel = 0
    itemCount.TextColor3 = Color3.fromRGB(60, 50, 40)  -- DARK - your defined color
    itemCount.TextSize = 12
    itemCount.Font = Enum.Font.Gotham
    itemCount.ZIndex = 3
    itemCount.Parent = mainFrame
    self.itemCount = itemCount
    
    -- Add close button with AC styling
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Text = "✕"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(4, 175, 166)  -- TEAL - your defined accent color
    closeButton.BorderSizePixel = 0
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- WHITE
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamBold
    closeButton.ZIndex = 5
    closeButton.Parent = titleBar
    
    -- Add corner to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        self:Hide()
    end)
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemsScroll"
    scrollFrame.Size = UDim2.new(1, -4, 1, -65)
    scrollFrame.Position = UDim2.new(0, 2, 0, 65)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(255, 251, 231)  -- CREAM - your defined color
    scrollFrame.BorderColor3 = Color3.fromRGB(200, 180, 160)
    scrollFrame.BorderSizePixel = 0  -- No border for cleaner look
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 300)
    scrollFrame.ScrollingEnabled = true
    scrollFrame.ZIndex = 3
    scrollFrame.Parent = mainFrame
    self.scrollFrame = scrollFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.CellSize = UDim2.new(0, 65, 0, 65)
    gridLayout.CellPadding = UDim2.new(0, 3, 0, 3)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    self.gridLayout = gridLayout
    
    -- Auto-update canvas size when grid layout changes
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y)
    end)

    self:renderAllItems()
end

function ItemBrowser:renderAllItems()
    if not self.scrollFrame then return end
    
    -- Clear existing items
    for _, child in pairs(self.scrollFrame:GetChildren()) do
        if child.Name ~= "UIGridLayout" then
            child:Destroy()
        end
    end
    
    -- Render all items
    for i, item in ipairs(self.allItems) do
        local button = self:createItemButton(item)
        button.LayoutOrder = i
        button.Parent = self.scrollFrame
    end
    
    -- Update item count display
    if self.itemCount then
        self.itemCount.Text = "Showing all " .. #self.allItems .. " items"
    end
end

function ItemBrowser:createItemButton(item)
    local button = Instance.new("TextButton")
    button.Name = item.id or "unknown"
    button.Size = UDim2.new(0, 70, 0, 70)
    -- Use your defined slot colors from InventoryStyling
    button.BackgroundColor3 = Color3.fromRGB(200, 200, 200)  -- Default slot color
    button.BackgroundTransparency = 0.2
    button.BorderColor3 = Color3.fromRGB(100, 100, 100)
    button.BorderSizePixel = 1
    button.AutoButtonColor = false
    button.Text = ""
    button.ZIndex = 5
    
    -- Add UICorner for rounded corners (4px to match inventory)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    if item.spriteIndex then
        local spriteImage = Instance.new("ImageLabel")
        spriteImage.Name = "Sprite"
        spriteImage.Size = UDim2.new(0.85, 0, 0.7, 0)
        spriteImage.Position = UDim2.new(0.075, 0, 0.05, 0)
        spriteImage.BackgroundTransparency = 1
        spriteImage.ImageTransparency = 0  -- Ensure visible
        spriteImage.ScaleType = Enum.ScaleType.Fit
        spriteImage.ZIndex = 6

        -- Use the SpriteConfig to apply the sprite properly
        local success = self.spriteConfig.applySprite(spriteImage, item.spriteIndex)
        if not success then
            -- Clear sprite if application failed
            spriteImage.Image = ""
            spriteImage.ImageRectOffset = Vector2.new(0, 0)
            spriteImage.ImageRectSize = Vector2.new(0, 0)
            warn("[DebugInventoryGrid] Failed to apply sprite", item.spriteIndex, "for item", item.id)
        end
        
        spriteImage.Parent = button
    end
    
    local indexLabel = Instance.new("TextLabel")
    indexLabel.Name = "Index"
    indexLabel.Text = tostring(item.spriteIndex or "?")
    indexLabel.Size = UDim2.new(0.4, 0, 0.25, 0)
    indexLabel.Position = UDim2.new(0.55, 0, 0.02, 0)
    indexLabel.BackgroundTransparency = 1
    indexLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    indexLabel.TextSize = 14  -- Increased from 8
    indexLabel.Font = Enum.Font.GothamBold
    indexLabel.ZIndex = 6
    indexLabel.Parent = button
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Text = item.name or item.id or "Unknown"
    nameLabel.Size = UDim2.new(1, -2, 0.28, 0)
    nameLabel.Position = UDim2.new(0, 1, 0.7, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(60, 50, 40)  -- DARK - your defined color
    nameLabel.TextSize = 10  -- Increased from 6
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextWrapped = true
    nameLabel.ZIndex = 6
    nameLabel.Parent = button
    
    button.MouseEnter:Connect(function()
        -- Use your defined TEAL accent color for hover
        button.BackgroundColor3 = Color3.fromRGB(4, 175, 166)  -- TEAL - your defined color
        button.BackgroundTransparency = 0.1
        indexLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- WHITE
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- WHITE
    end)
    
    button.MouseLeave:Connect(function()
        -- Return to default slot styling
        button.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        button.BackgroundTransparency = 0.2
        indexLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        nameLabel.TextColor3 = Color3.fromRGB(60, 50, 40)  -- DARK
    end)
    
    button.MouseButton1Click:Connect(function()
        -- Prevent adding unmapped/placeholder sprites only
        if item.isPlaceholder then
            print("[ItemBrowser] ❌ Cannot add unmapped sprite:", item.id)
            return
        end
        
        -- If item is not a placeholder, it came from getAllItems() and should be valid
        -- All mapped items should be addable
        print("[ItemBrowser] Adding:", item.id, "-", item.name)
        local itemData = {
            itemId = item.id,
            count = 1,
            maxStack = 99
        }
        self.inventoryRemote:FireServer("add_item", itemData)
    end)
    
    return button
end

-- Method to refresh when inventory level changes
function ItemBrowser:refresh()
    self:renderAllItems()
end

return ItemBrowser
