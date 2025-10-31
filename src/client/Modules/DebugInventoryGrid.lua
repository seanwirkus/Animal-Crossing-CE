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
    self.parent = parent
    
    self:createGui()
    print("[ItemBrowser] ✅ Initialized for DebugManager")
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

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 2
    mainFrame.Parent = self.parent
    self.mainFrame = mainFrame
    
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(120, 100, 80)
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Parent = mainFrame
    
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
    itemCount.BackgroundColor3 = Color3.fromRGB(200, 180, 160)
    itemCount.BorderSizePixel = 0
    itemCount.TextColor3 = Color3.fromRGB(60, 50, 40)
    itemCount.TextSize = 12
    itemCount.Font = Enum.Font.Gotham
    itemCount.ZIndex = 3
    itemCount.Parent = mainFrame
    self.itemCount = itemCount
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemsScroll"
    scrollFrame.Size = UDim2.new(1, -4, 1, -65)
    scrollFrame.Position = UDim2.new(0, 2, 0, 65)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(220, 208, 190)
    scrollFrame.BorderColor3 = Color3.fromRGB(70, 70, 70)
    scrollFrame.BorderSizePixel = 1
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
    button.BackgroundColor3 = Color3.fromRGB(238, 226, 204)
    button.BorderColor3 = Color3.fromRGB(150, 130, 110)
    button.BorderSizePixel = 1
    button.AutoButtonColor = false
    button.Text = ""
    button.ZIndex = 5
    
    if item.spriteIndex then
        local spriteImage = Instance.new("ImageLabel")
        spriteImage.Name = "Sprite"
        spriteImage.Size = UDim2.new(0.85, 0, 0.7, 0)
        spriteImage.Position = UDim2.new(0.075, 0, 0.05, 0)
        spriteImage.BackgroundTransparency = 1
        spriteImage.ScaleType = Enum.ScaleType.Fit
        spriteImage.ZIndex = 6

        -- Use the SpriteConfig to apply the sprite properly
        self.spriteConfig.applySprite(spriteImage, item.spriteIndex)
        
        spriteImage.Parent = button
    end
    
    local indexLabel = Instance.new("TextLabel")
    indexLabel.Name = "Index"
    indexLabel.Text = tostring(item.spriteIndex or "?")
    indexLabel.Size = UDim2.new(0.4, 0, 0.2, 0)
    indexLabel.Position = UDim2.new(0.55, 0, 0.02, 0)
    indexLabel.BackgroundTransparency = 1
    indexLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    indexLabel.TextSize = 8
    indexLabel.Font = Enum.Font.GothamBold
    indexLabel.ZIndex = 6
    indexLabel.Parent = button
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Text = item.name or item.id or "Unknown"
    nameLabel.Size = UDim2.new(1, -2, 0.28, 0)
    nameLabel.Position = UDim2.new(0, 1, 0.7, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(60, 50, 40)
    nameLabel.TextSize = 6
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextWrapped = true
    nameLabel.ZIndex = 6
    nameLabel.Parent = button
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromHex("#04AFA6")
        indexLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(238, 226, 204)
        indexLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        nameLabel.TextColor3 = Color3.fromRGB(60, 50, 40)
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
