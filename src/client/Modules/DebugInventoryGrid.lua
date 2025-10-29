-- Item Browser Modal
-- Shows all items with pagination

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
    
    self.inventoryRemote = ReplicatedStorage:WaitForChild("InventoryEvent")
    
    self.mainFrame = nil
    self.currentPage = 1
    self.itemsPerPage = 20  -- 5 columns x 4 rows
    self.itemsPerRow = 5
    
    self:loadAllItems()
    
    print("[ItemBrowser] ✅ Loaded with", #self.allItems, "items")
    
    return self
end

function ItemBrowser:Init(parent)
    self.parent = parent
    self:createGui()
    print("[ItemBrowser] ✅ Initialized for DebugManager")
end

function ItemBrowser:loadAllItems()
    local allItems = self.itemDataFetcher.getAllItems()
    
    local itemsWithSprites = {}
    for _, item in ipairs(allItems) do
        if item.spriteIndex then
            table.insert(itemsWithSprites, item)
        end
    end
    
    table.sort(itemsWithSprites, function(a, b)
        local indexA = a.spriteIndex or 999
        local indexB = b.spriteIndex or 999
        return indexA < indexB
    end)
    
    self.allItems = itemsWithSprites
end

function ItemBrowser:getTotalPages()
    return math.ceil(#self.allItems / self.itemsPerPage)
end

function ItemBrowser:getCurrentPageItems()
    local startIdx = (self.currentPage - 1) * self.itemsPerPage + 1
    local endIdx = math.min(startIdx + self.itemsPerPage - 1, #self.allItems)
    
    local pageItems = {}
    for i = startIdx, endIdx do
        table.insert(pageItems, self.allItems[i])
    end
    return pageItems
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
    
    local pageInfo = Instance.new("TextLabel")
    pageInfo.Name = "PageInfo"
    pageInfo.Text = "Page " .. self.currentPage .. " of " .. self:getTotalPages()
    pageInfo.Size = UDim2.new(1, 0, 0, 25)
    pageInfo.Position = UDim2.new(0, 0, 0, 40)
    pageInfo.BackgroundColor3 = Color3.fromRGB(200, 180, 160)
    pageInfo.BorderSizePixel = 0
    pageInfo.TextColor3 = Color3.fromRGB(60, 50, 40)
    pageInfo.TextSize = 12
    pageInfo.Font = Enum.Font.Gotham
    pageInfo.ZIndex = 3
    pageInfo.Parent = mainFrame
    self.pageInfo = pageInfo
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemsScroll"
    scrollFrame.Size = UDim2.new(1, -4, 1, -105)
    scrollFrame.Position = UDim2.new(0, 2, 0, 65)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(220, 208, 190)
    scrollFrame.BorderColor3 = Color3.fromRGB(70, 70, 70)
    scrollFrame.BorderSizePixel = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 300)
    scrollFrame.ZIndex = 3
    scrollFrame.Parent = mainFrame
    self.scrollFrame = scrollFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.CellSize = UDim2.new(0, 65, 0, 65)
    gridLayout.CellPadding = UDim2.new(0, 3, 0, 3)
    gridLayout.Parent = scrollFrame
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.new(1, 0, 0, 45)
    controlsFrame.Position = UDim2.new(0, 0, 1, -45)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(120, 100, 80)
    controlsFrame.BorderSizePixel = 0
    controlsFrame.ZIndex = 3
    controlsFrame.Parent = mainFrame
    
    local prevBtn = Instance.new("TextButton")
    prevBtn.Name = "PrevButton"
    prevBtn.Text = "◀ Previous"
    prevBtn.Size = UDim2.new(0, 100, 0, 35)
    prevBtn.Position = UDim2.new(0, 10, 0.5, -17)
    prevBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 160)
    prevBtn.TextColor3 = Color3.fromRGB(60, 50, 40)
    prevBtn.TextSize = 12
    prevBtn.Font = Enum.Font.GothamBold
    prevBtn.BorderSizePixel = 0
    prevBtn.ZIndex = 4
    prevBtn.Parent = controlsFrame
    
    prevBtn.MouseButton1Click:Connect(function()
        self:previousPage()
    end)
    
    local nextBtn = Instance.new("TextButton")
    nextBtn.Name = "NextButton"
    nextBtn.Text = "Next ▶"
    nextBtn.Size = UDim2.new(0, 100, 0, 35)
    nextBtn.Position = UDim2.new(1, -110, 0.5, -17)
    nextBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 150)
    nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    nextBtn.TextSize = 12
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.BorderSizePixel = 0
    nextBtn.ZIndex = 4
    nextBtn.Parent = controlsFrame
    
    nextBtn.MouseButton1Click:Connect(function()
        self:nextPage()
    end)
    
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Text = "Click item to add to inventory"
    instructions.Size = UDim2.new(1, -220, 0, 35)
    instructions.Position = UDim2.new(0, 120, 0.5, -17)
    instructions.BackgroundTransparency = 1
    instructions.TextColor3 = Color3.fromRGB(220, 220, 220)
    instructions.TextSize = 11
    instructions.Font = Enum.Font.Gotham
    instructions.TextWrapped = true
    instructions.ZIndex = 4
    instructions.Parent = controlsFrame

    self:renderPage()
end

function ItemBrowser:renderPage()
    if not self.scrollFrame then return end
    
    for _, child in pairs(self.scrollFrame:GetChildren()) do
        if child.Name ~= "UIGridLayout" then
            child:Destroy()
        end
    end
    
    local pageItems = self:getCurrentPageItems()
    
    for i, item in ipairs(pageItems) do
        local button = self:createItemButton(item)
        button.Parent = self.scrollFrame
    end
    
    if self.pageInfo then
        self.pageInfo.Text = "Page " .. self.currentPage .. " of " .. self:getTotalPages() .. 
                             " (" .. #self.allItems .. " total items)"
    end
end

function ItemBrowser:createItemButton(item)
    local button = Instance.new("TextButton")
    button.Name = item.id or "unknown"
    button.Size = UDim2.new(0, 65, 0, 65)
    button.BackgroundColor3 = Color3.fromRGB(238, 226, 204)
    button.BorderColor3 = Color3.fromRGB(150, 130, 110)
    button.BorderSizePixel = 1
    button.AutoButtonColor = false
    button.Text = ""
    button.ZIndex = 5
    
    if item.spriteIndex then
        local spriteImage = Instance.new("ImageLabel")
        spriteImage.Name = "Sprite"
        spriteImage.Size = UDim2.new(0.8, 0, 0.65, 0)
        spriteImage.Position = UDim2.new(0.1, 0, 0.05, 0)
        spriteImage.BackgroundTransparency = 1
        spriteImage.ScaleType = Enum.ScaleType.Stretch
        spriteImage.ZIndex = 6

        if not self.spriteConfig.applySprite(spriteImage, item.spriteIndex) then
            spriteImage.Image = ""
            spriteImage.ImageRectOffset = Vector2.new(0, 0)
            spriteImage.ImageRectSize = self.spriteConfig.DEFAULT_IMAGE_RECT_SIZE
        end

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

function ItemBrowser:nextPage()
    local maxPage = self:getTotalPages()
    if self.currentPage < maxPage then
        self.currentPage = self.currentPage + 1
        self:renderPage()
    end
end

function ItemBrowser:previousPage()
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:renderPage()
    end
end

return ItemBrowser
