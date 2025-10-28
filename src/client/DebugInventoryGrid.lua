-- Item Browser Modal
-- Shows all items with pagination (G key to toggle)
-- Separate from inventory - doesn't interfere with E key inventory

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemBrowser = {}
ItemBrowser.__index = ItemBrowser
ItemBrowser._instance = nil

function ItemBrowser.new()
    local self = setmetatable({}, ItemBrowser)
    
    self.player = Players.LocalPlayer
    self.gui = self.player:FindFirstChild("PlayerGui") or self.player:FindFirstChild("PlayerGui", true)
    if not self.gui then
        self.gui = self.player:WaitForChild("PlayerGui", 3)
    end
    if not self.gui then
        warn("[ItemBrowser] Could not find PlayerGui!")
        return nil
    end
    
    self.sharedFolder = ReplicatedStorage:WaitForChild("Shared")
    self.itemDataFetcher = require(self.sharedFolder:WaitForChild("ItemDataFetcher"))
    self.spriteConfig = require(self.sharedFolder:WaitForChild("SpriteConfig"))
    
    self.inventoryRemote = ReplicatedStorage:WaitForChild("InventoryEvent")
    
    self.screenGui = nil
    self.mainFrame = nil
    self.isOpen = false
    self.currentPage = 1
    self.itemsPerPage = 20  -- 5 columns x 4 rows
    self.itemsPerRow = 5
    
    -- Get all items sorted by sprite index
    self:loadAllItems()
    
    print("[ItemBrowser] ✅ Loaded with", #self.allItems, "items")
    
    return self
end

function ItemBrowser:loadAllItems()
    local allItems = self.itemDataFetcher.getAllItems()
    
    -- Filter out items without spriteIndex and sort by sprite index
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
    if self.screenGui then
        return
    end

    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ItemBrowser"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 200
    screenGui.Parent = self.gui
    self.screenGui = screenGui
    
    -- Modal background (semi-transparent)
    local modalBg = Instance.new("Frame")
    modalBg.Name = "ModalBackground"
    modalBg.Size = UDim2.new(1, 0, 1, 0)
    modalBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    modalBg.BackgroundTransparency = 0.5
    modalBg.BorderSizePixel = 0
    modalBg.ZIndex = 1
    modalBg.Parent = screenGui
    
    -- Main window frame (700x500 centered - fits better on screen)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderColor3 = Color3.fromRGB(100, 150, 200)
    mainFrame.BorderSizePixel = 2
    mainFrame.ZIndex = 2
    mainFrame.Parent = screenGui
    self.mainFrame = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(120, 100, 80)  -- Warm brown
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Parent = mainFrame
    
    -- Title text
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
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Text = "✕"
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -37, 0, 2)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 4
    closeBtn.Parent = titleBar
    
    closeBtn.MouseButton1Click:Connect(function()
        self:close()
    end)
    
    -- Page info
    local pageInfo = Instance.new("TextLabel")
    pageInfo.Name = "PageInfo"
    pageInfo.Text = "Page " .. self.currentPage .. " of " .. self:getTotalPages()
    pageInfo.Size = UDim2.new(1, 0, 0, 25)
    pageInfo.Position = UDim2.new(0, 0, 0, 40)
    pageInfo.BackgroundColor3 = Color3.fromRGB(200, 180, 160)  -- Lighter warm tone
    pageInfo.BorderSizePixel = 0
    pageInfo.TextColor3 = Color3.fromRGB(60, 50, 40)  -- Dark brown text
    pageInfo.TextSize = 12
    pageInfo.Font = Enum.Font.Gotham
    pageInfo.ZIndex = 3
    pageInfo.Parent = mainFrame
    self.pageInfo = pageInfo
    
    -- Items scroll frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemsScroll"
    scrollFrame.Size = UDim2.new(1, -4, 1, -105)
    scrollFrame.Position = UDim2.new(0, 2, 0, 65)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(220, 208, 190)  -- Light warm background
    scrollFrame.BorderColor3 = Color3.fromRGB(70, 70, 70)
    scrollFrame.BorderSizePixel = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 300)
    scrollFrame.ZIndex = 3
    scrollFrame.Parent = mainFrame
    self.scrollFrame = scrollFrame
    
    -- Grid layout for items (smaller cells for 700px width)
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.CellSize = UDim2.new(0, 65, 0, 65)
    gridLayout.CellPadding = UDim2.new(0, 3, 0, 3)
    gridLayout.Parent = scrollFrame
    
    -- Bottom controls
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.new(1, 0, 0, 45)
    controlsFrame.Position = UDim2.new(0, 0, 1, -45)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(120, 100, 80)  -- Match title bar
    controlsFrame.BorderSizePixel = 0
    controlsFrame.ZIndex = 3
    controlsFrame.Parent = mainFrame
    
    -- Previous button
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
    
    -- Next button
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
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Text = "← → or Click buttons to browse | Click item to add | ESC or G to close"
    instructions.Size = UDim2.new(1, -220, 0, 35)
    instructions.Position = UDim2.new(0, 120, 0.5, -17)
    instructions.BackgroundTransparency = 1
    instructions.TextColor3 = Color3.fromRGB(150, 150, 150)
    instructions.TextSize = 11
    instructions.Font = Enum.Font.Gotham
    instructions.TextWrapped = true
    instructions.ZIndex = 4
    instructions.Parent = controlsFrame
end

function ItemBrowser:attachInput()
    if self.inputConnection then
        self.inputConnection:Disconnect()
        self.inputConnection = nil
    end

    self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == Enum.KeyCode.Left then
            self:previousPage()
        elseif input.KeyCode == Enum.KeyCode.Right then
            self:nextPage()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            self:close()
        end
    end)
end

function ItemBrowser:renderPage()
    -- Clear existing items
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
    
    -- Update page info
    if self.pageInfo then
        self.pageInfo.Text = "Page " .. self.currentPage .. " of " .. self:getTotalPages() .. 
                             " (" .. #self.allItems .. " total items)"
    end
end

function ItemBrowser:createItemButton(item)
    local button = Instance.new("TextButton")
    button.Name = item.id or "unknown"
    button.Size = UDim2.new(0, 65, 0, 65)
    button.BackgroundColor3 = Color3.fromRGB(238, 226, 204)  -- Match inventory slot color
    button.BorderColor3 = Color3.fromRGB(150, 130, 110)
    button.BorderSizePixel = 1
    button.AutoButtonColor = false
    button.Text = ""
    button.ZIndex = 5
    
    -- Sprite image
    if item.spriteIndex then
        local spriteImage = Instance.new("ImageLabel")
        spriteImage.Name = "Sprite"
        spriteImage.Size = UDim2.new(0.8, 0, 0.65, 0)
        spriteImage.Position = UDim2.new(0.1, 0, 0.05, 0)
        spriteImage.BackgroundTransparency = 1
        spriteImage.Image = self.spriteConfig.SHEET_ASSET
        spriteImage.ImageRectSize = Vector2.new(36, 36)
        spriteImage.ZIndex = 6
        
        -- Calculate sprite position
        local zeroBased = item.spriteIndex - 1
        local col = zeroBased % self.spriteConfig.COLUMNS
        local row = math.floor(zeroBased / self.spriteConfig.COLUMNS)
        local offsetX = self.spriteConfig.OUTER.X + col * (self.spriteConfig.TILE + self.spriteConfig.INNER.X)
        local offsetY = self.spriteConfig.OUTER.Y + row * (self.spriteConfig.TILE + self.spriteConfig.INNER.Y)
        
        spriteImage.ImageRectOffset = Vector2.new(math.floor(offsetX + 0.5), math.floor(offsetY + 0.5))
        spriteImage.Parent = button
    end
    
    -- Index label (smaller for 65px cells)
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
    
    -- Name label (smaller text)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Text = item.name or item.id or "Unknown"
    nameLabel.Size = UDim2.new(1, -2, 0.28, 0)
    nameLabel.Position = UDim2.new(0, 1, 0.7, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(60, 50, 40)  -- Dark brown text
    nameLabel.TextSize = 6
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextWrapped = true
    nameLabel.ZIndex = 6
    nameLabel.Parent = button
    
    -- Hover effects - match inventory style
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromHex("#04AFA6")  -- Teal hover (same as inventory)
        indexLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(238, 226, 204)  -- Back to default
        indexLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        nameLabel.TextColor3 = Color3.fromRGB(60, 50, 40)
    end)
    
    -- Click handler with stack size limits
    button.MouseButton1Click:Connect(function()
        print("[ItemBrowser] Adding:", item.id, "-", item.name)
        -- Send item data with stack parameters
        local itemData = {
            itemId = item.id,
            count = 1,
            maxStack = 99  -- Default stack size limit
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

function ItemBrowser:toggle()
    if self.isOpen then
        self:close()
    else
        self:open()
    end
end

function ItemBrowser:open()
    if self.isOpen then
        return
    end

    self:createGui()

    if not self.screenGui then
        warn("[ItemBrowser] ❌ Could not open item browser (no ScreenGui)")
        return
    end

    self.screenGui.Enabled = true
    self:renderPage()
    self:attachInput()

    self.isOpen = true
    print("[ItemBrowser] ✅ GUI opened")
end

function ItemBrowser:close()
    if not self.isOpen then
        return
    end

    if self.inputConnection then
        self.inputConnection:Disconnect()
        self.inputConnection = nil
    end

    if self.screenGui then
        self.screenGui.Enabled = false
    end

    self.isOpen = false
    print("[ItemBrowser] ✅ GUI closed")
end

function ItemBrowser.getOrCreate()
    if ItemBrowser._instance and ItemBrowser._instance.player == Players.LocalPlayer then
        return ItemBrowser._instance
    end

    local instance = ItemBrowser.new()
    if instance then
        ItemBrowser._instance = instance
    end

    return ItemBrowser._instance
end

function ItemBrowser.toggleGlobal()
    local instance = ItemBrowser.getOrCreate()
    if not instance then
        warn("[ItemBrowser] ❌ Failed to toggle item browser (instance unavailable)")
        return
    end

    _G.ItemBrowserInstance = instance
    instance:toggle()
end

function ItemBrowser.destroySingleton()
    if not ItemBrowser._instance then
        return
    end

    ItemBrowser._instance:close()

    if ItemBrowser._instance.screenGui then
        ItemBrowser._instance.screenGui:Destroy()
        ItemBrowser._instance.screenGui = nil
    end

    ItemBrowser._instance = nil
end

return ItemBrowser
