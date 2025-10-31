-- Crafting Debug Menu
-- Shows crafting stations, recipes, and allows quick crafting (C key to toggle)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CraftingMenu = {}
CraftingMenu.__index = CraftingMenu
CraftingMenu._instance = nil

function CraftingMenu.new()
    local self = setmetatable({}, CraftingMenu)
    
    print("[CraftingMenu] Creating new instance...")
    
    self.player = Players.LocalPlayer
    print("[CraftingMenu] LocalPlayer:", self.player)
    
    self.gui = self.player:FindFirstChild("PlayerGui") or self.player:WaitForChild("PlayerGui", 3)
    if not self.gui then
        warn("[CraftingMenu] Could not find PlayerGui!")
        return nil
    end
    print("[CraftingMenu] ✅ Found PlayerGui")
    
    self.sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
    print("[CraftingMenu] ✅ Found Shared folder")
    
    self.itemDataFetcher = require(self.sharedFolder:WaitForChild("ItemDataFetcher", 5))
    print("[CraftingMenu] ✅ Loaded ItemDataFetcher")
    
    self.spriteConfig = require(self.sharedFolder:WaitForChild("SpriteConfig", 5))
    print("[CraftingMenu] ✅ Loaded SpriteConfig")
    
    self.craftingSystem = require(self.sharedFolder:WaitForChild("CraftingSystem", 5))
    print("[CraftingMenu] ✅ Loaded CraftingSystem")
    
    self.inventoryRemote = ReplicatedStorage:WaitForChild("InventoryEvent", 5)
    print("[CraftingMenu] ✅ Found InventoryEvent")
    
    self.screenGui = nil
    self.mainFrame = nil
    self.isOpen = false
    self.currentTab = "RECIPES"  -- RECIPES or STATIONS
    
    -- Get all craftable recipes
    self:loadRecipes()
    
    print("[CraftingMenu] ✅ Loaded with " .. #self.allRecipes .. " recipes")
    
    return self
end

function CraftingMenu:Init(parent)
    -- Parent should be a ScreenGui (from init.client.luau)
    if parent and parent:IsA("ScreenGui") then
        self.screenGui = parent
    end
    self:createGui()
    self:switchTab("RECIPES") -- Default to recipes
    print("[CraftingMenu] ✅ Initialized standalone")
end

function CraftingMenu:loadRecipes()
    self.allRecipes = self.itemDataFetcher.getCraftableItems() or {}
    
    -- Sort by station type, then by name
    table.sort(self.allRecipes, function(a, b)
        local stationA = a.station or "workbench"
        local stationB = b.station or "workbench"
        if stationA ~= stationB then
            return stationA < stationB
        end
        return (a.name or a.id) < (b.name or b.id)
    end)
end

function CraftingMenu:getStationIcon(stationType)
    -- Return emoji-style icons for different stations
    local icons = {
        workbench = "🔨",
        forge = "⚒️",
        cooking = "🍳",
        sewing = "🧵",
        alchemy = "⚗️",
    }
    return icons[stationType] or "🔧"
end

function CraftingMenu:getStationColor(stationType)
    local colors = {
        workbench = Color3.fromRGB(139, 90, 43),
        forge = Color3.fromRGB(255, 100, 50),
        cooking = Color3.fromRGB(255, 200, 80),
        sewing = Color3.fromRGB(200, 100, 255),
        alchemy = Color3.fromRGB(100, 255, 150),
    }
    return colors[stationType] or Color3.fromRGB(150, 150, 150)
end

function CraftingMenu:createGui()
    if self.mainFrame then
        print("[CraftingMenu] GUI already exists, returning early")
        return
    end

    print("[CraftingMenu] Creating GUI from scratch...")

    -- Use existing ScreenGui if set, otherwise create one
    if not self.screenGui then
        local playerGui = self.player:WaitForChild("PlayerGui")
        self.screenGui = playerGui:FindFirstChild("CraftingMenuGUI")
        if not self.screenGui then
            self.screenGui = Instance.new("ScreenGui")
            self.screenGui.Name = "CraftingMenuGUI"
            self.screenGui.ResetOnSpawn = false
            self.screenGui.DisplayOrder = 11
            self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            self.screenGui.Enabled = false
            self.screenGui.Parent = playerGui
        end
    end

    -- Main frame - smaller and centered, cream background
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.85, 0, 0.8, 0)  -- 85% width, 80% height
    mainFrame.Position = UDim2.new(0.075, 0, 0.1, 0)  -- Centered
    mainFrame.AnchorPoint = Vector2.new(0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(255, 251, 231)  -- Cream background
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 2
    mainFrame.Visible = false  -- Start hidden
    mainFrame.Parent = self.screenGui
    self.mainFrame = mainFrame
    print("[CraftingMenu] ✅ Created main frame")
    
    -- Add rounded corners
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame
    
    -- Prevent clicks from passing through
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Consume the input
        end
    end)
    
    -- Title bar
    print("[CraftingMenu] Creating title bar...")
    self:createTitleBar()
    print("[CraftingMenu] ✅ Title bar created")
    
    -- Tab buttons
    print("[CraftingMenu] Creating tab buttons...")
    self:createTabButtons()
    print("[CraftingMenu] ✅ Tab buttons created")
    
    -- Content area
    print("[CraftingMenu] Creating content area...")
    self:createContentArea()
    print("[CraftingMenu] ✅ Content area created")
    
    -- Instructions at bottom
    print("[CraftingMenu] Creating instructions...")
    self:createInstructions()
    print("[CraftingMenu] ✅ Instructions created")
    
    print("[CraftingMenu] 🎉 GUI creation complete!")
end

function CraftingMenu:createTitleBar()
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(120, 100, 80)  -- Matching brown
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Parent = self.mainFrame
    
    -- Add corner to title bar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = "🔨 Crafting Menu"
    titleLabel.Size = UDim2.new(1, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = titleBar
end

function CraftingMenu:createTabButtons()
    -- No tabs needed - always show all recipes in debug mode
    -- Keep the container for visual consistency but make it thinner
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 5)  -- Very thin, just for spacing
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ZIndex = 3
    tabContainer.Parent = self.mainFrame
end

function CraftingMenu:createContentArea()
    -- Split interface: Recipe list on left (40%), preview on right (60%)
    
    -- Left side: Recipe list scroll
    local recipeListFrame = Instance.new("ScrollingFrame")
    recipeListFrame.Name = "RecipeListFrame"
    recipeListFrame.Size = UDim2.new(0.4, -15, 1, -55)  -- 40% width
    recipeListFrame.Position = UDim2.new(0, 10, 0, 45)
    recipeListFrame.BackgroundColor3 = Color3.fromRGB(255, 251, 231)  -- Cream background
    recipeListFrame.BorderSizePixel = 0
    recipeListFrame.ScrollBarThickness = 6
    recipeListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    recipeListFrame.ZIndex = 3
    recipeListFrame.Parent = self.mainFrame
    self.recipeListFrame = recipeListFrame
    
    -- List layout for recipe items
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = recipeListFrame
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        recipeListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Right side: Recipe preview panel
    local previewPanel = Instance.new("Frame")
    previewPanel.Name = "PreviewPanel"
    previewPanel.Size = UDim2.new(0.6, -15, 1, -55)  -- 60% width
    previewPanel.Position = UDim2.new(0.4, 5, 0, 45)
    previewPanel.BackgroundColor3 = Color3.fromRGB(231, 221, 185)  -- Beige background
    previewPanel.BorderSizePixel = 0
    previewPanel.ZIndex = 3
    previewPanel.Parent = self.mainFrame
    self.previewPanel = previewPanel
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 8)
    previewCorner.Parent = previewPanel
    
    -- Store reference
    self.selectedRecipe = nil
    
    -- Show placeholder initially
    self:showPreviewPlaceholder()
end

function CraftingMenu:createInstructions()
    -- Removed - no instructions needed, recipes are bigger and clearer
end

function CraftingMenu:switchTab(tabName)
    -- Always show recipes - no tabs needed for debug GUI
    self.currentTab = "RECIPES"
    self:renderContent()
end

function CraftingMenu:showPreviewPlaceholder()
    -- Clear existing content
    for _, child in pairs(self.previewPanel:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    local placeholder = Instance.new("TextLabel")
    placeholder.Name = "Placeholder"
    placeholder.Size = UDim2.new(1, -40, 1, -40)
    placeholder.Position = UDim2.new(0, 20, 0, 20)
    placeholder.BackgroundTransparency = 1
    placeholder.Text = "Select a recipe to view details"
    placeholder.TextColor3 = Color3.fromRGB(60, 50, 40)
    placeholder.TextSize = 16
    placeholder.Font = Enum.Font.Gotham
    placeholder.TextWrapped = true
    placeholder.ZIndex = 4
    placeholder.Parent = self.previewPanel
end

function CraftingMenu:renderContent()
    -- Clear existing content
    for _, child in pairs(self.recipeListFrame:GetChildren()) do
        if child.Name ~= "UIListLayout" then
            child:Destroy()
        end
    end
    
    -- Render all recipes as list items
    self:renderRecipeList()
end

function CraftingMenu:renderRecipeList()
    for i, recipe in ipairs(self.allRecipes) do
        local listItem = self:createRecipeListItem(recipe, i)
        listItem.LayoutOrder = i
        listItem.Parent = self.recipeListFrame
    end
end

function CraftingMenu:createRecipeListItem(recipe, index)
    -- Compact list item (like Animal Crossing recipe list)
    local item = Instance.new("TextButton")
    item.Name = "RecipeItem_" .. index
    item.Size = UDim2.new(1, -10, 0, 50)  -- Compact list item
    item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)  -- White
    item.BorderSizePixel = 1
    item.BorderColor3 = Color3.fromRGB(200, 180, 160)
    item.AutoButtonColor = false
    item.Text = ""
    item.ZIndex = 4
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 6)
    itemCorner.Parent = item
    
    -- DIY icon index in top-left
    if recipe.diyIconIndex then
        local indexLabel = Instance.new("TextLabel")
        indexLabel.Name = "IndexLabel"
        indexLabel.Text = tostring(recipe.diyIconIndex)
        indexLabel.Size = UDim2.new(0, 20, 0, 12)
        indexLabel.Position = UDim2.new(0, 3, 0, 3)
        indexLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        indexLabel.BackgroundTransparency = 0.3
        indexLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        indexLabel.TextSize = 8
        indexLabel.Font = Enum.Font.GothamBold
        indexLabel.TextXAlignment = Enum.TextXAlignment.Center
        indexLabel.ZIndex = 6
        indexLabel.Parent = item
        
        local indexCorner = Instance.new("UICorner")
        indexCorner.CornerRadius = UDim.new(0, 3)
        indexCorner.Parent = indexLabel
    end
    
    -- Small icon on left
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "IconFrame"
    iconFrame.Size = UDim2.new(0, 40, 0, 40)
    iconFrame.Position = UDim2.new(0, 5, 0.5, -20)
    iconFrame.BackgroundTransparency = 1
    iconFrame.ZIndex = 5
    iconFrame.Parent = item
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.ImageTransparency = 0
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 5
    icon.Parent = iconFrame
    
    -- Try DIY icon first, fall back to item sprite
    local itemData = self.itemDataFetcher.getItem(recipe.id or recipe.itemId)
    local spriteIndex = itemData and itemData.spriteIndex or (recipe.result and recipe.result.spriteIndex)
    local success = false
    if recipe.diyIconIndex then
        success = self.spriteConfig.applyDIYIcon(icon, recipe.diyIconIndex)
    elseif spriteIndex then
        success = self.spriteConfig.applySprite(icon, spriteIndex)
    end
    
    if not success then
        icon.Image = ""
        icon.ImageRectOffset = Vector2.new(0, 0)
        icon.ImageRectSize = Vector2.new(0, 0)
    end
    
    -- Recipe name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Text = recipe.name or recipe.id or "Unknown Recipe"
    nameLabel.Size = UDim2.new(1, -55, 0, 20)
    nameLabel.Position = UDim2.new(0, 50, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(60, 50, 40)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 5
    nameLabel.Parent = item
    
    -- Station type below name
    local stationLabel = Instance.new("TextLabel")
    stationLabel.Name = "Station"
    stationLabel.Text = self:getStationIcon(recipe.station or "workbench") .. " " .. (recipe.station or "workbench")
    stationLabel.Size = UDim2.new(1, -55, 0, 16)
    stationLabel.Position = UDim2.new(0, 50, 0, 28)
    stationLabel.BackgroundTransparency = 1
    stationLabel.TextColor3 = Color3.fromRGB(100, 80, 60)
    stationLabel.TextSize = 9
    stationLabel.Font = Enum.Font.Gotham
    stationLabel.TextXAlignment = Enum.TextXAlignment.Left
    stationLabel.ZIndex = 5
    stationLabel.Parent = item
    
    -- Hover effect
    item.MouseEnter:Connect(function()
        item.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    end)
    
    item.MouseLeave:Connect(function()
        if self.selectedRecipe == recipe then
            item.BackgroundColor3 = Color3.fromRGB(220, 240, 255)  -- Selected color
        else
            item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
    
    -- Click to show preview
    item.MouseButton1Click:Connect(function()
        self:showRecipePreview(recipe, item)
    end)
    
    return item
end

function CraftingMenu:showRecipePreview(recipe, selectedListItem)
    self.selectedRecipe = recipe
    
    -- Update all list items to show selection
    for _, child in pairs(self.recipeListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            if child == selectedListItem then
                child.BackgroundColor3 = Color3.fromRGB(220, 240, 255)  -- Selected
            else
                child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)  -- Normal
            end
        end
    end
    
    -- Clear preview panel
    for _, child in pairs(self.previewPanel:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Scroll frame for preview content
    local previewScroll = Instance.new("ScrollingFrame")
    previewScroll.Name = "PreviewScroll"
    previewScroll.Size = UDim2.new(1, -20, 1, -20)
    previewScroll.Position = UDim2.new(0, 10, 0, 10)
    previewScroll.BackgroundTransparency = 1
    previewScroll.BorderSizePixel = 0
    previewScroll.ScrollBarThickness = 6
    previewScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    previewScroll.ZIndex = 4
    previewScroll.Parent = self.previewPanel
    
    local yOffset = 0
    
    -- Recipe name at top
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "RecipeName"
    nameLabel.Text = recipe.name or recipe.id or "Unknown Recipe"
    nameLabel.Size = UDim2.new(1, 0, 0, 40)
    nameLabel.Position = UDim2.new(0, 0, 0, yOffset)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(60, 50, 40)
    nameLabel.TextSize = 20
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextWrapped = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 5
    nameLabel.Parent = previewScroll
    yOffset = yOffset + 45
    
    -- Large DIY icon in center
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "LargeIcon"
    iconFrame.Size = UDim2.new(0, 120, 0, 120)
    iconFrame.Position = UDim2.new(0.5, -60, 0, yOffset)
    iconFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    iconFrame.BorderSizePixel = 2
    iconFrame.BorderColor3 = Color3.fromRGB(200, 180, 160)
    iconFrame.ZIndex = 5
    iconFrame.Parent = previewScroll
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = iconFrame
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.85, 0, 0.85, 0)
    icon.Position = UDim2.new(0.075, 0, 0.075, 0)
    icon.BackgroundTransparency = 1
    icon.ImageTransparency = 0
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 6
    icon.Parent = iconFrame
    
    -- Apply DIY icon or item sprite
    local itemData = self.itemDataFetcher.getItem(recipe.id or recipe.itemId)
    local spriteIndex = itemData and itemData.spriteIndex or (recipe.result and recipe.result.spriteIndex)
    local success = false
    if recipe.diyIconIndex then
        success = self.spriteConfig.applyDIYIcon(icon, recipe.diyIconIndex)
    elseif spriteIndex then
        success = self.spriteConfig.applySprite(icon, spriteIndex)
    end
    
    if not success then
        icon.Image = ""
        icon.ImageRectOffset = Vector2.new(0, 0)
        icon.ImageRectSize = Vector2.new(0, 0)
    end
    
    -- DIY icon index label
    if recipe.diyIconIndex then
        local indexLabel = Instance.new("TextLabel")
        indexLabel.Name = "IndexLabel"
        indexLabel.Text = "DIY Icon: " .. tostring(recipe.diyIconIndex)
        indexLabel.Size = UDim2.new(0, 100, 0, 14)
        indexLabel.Position = UDim2.new(0, 2, 0, 2)
        indexLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        indexLabel.BackgroundTransparency = 0.3
        indexLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        indexLabel.TextSize = 9
        indexLabel.Font = Enum.Font.GothamBold
        indexLabel.TextXAlignment = Enum.TextXAlignment.Center
        indexLabel.ZIndex = 7
        indexLabel.Parent = iconFrame
        
        local indexCorner = Instance.new("UICorner")
        indexCorner.CornerRadius = UDim.new(0, 3)
        indexCorner.Parent = indexLabel
    end
    
    yOffset = yOffset + 130
    
    -- Materials header
    local materialsHeader = Instance.new("TextLabel")
    materialsHeader.Name = "MaterialsHeader"
    materialsHeader.Text = "📦 Materials Required:"
    materialsHeader.Size = UDim2.new(1, 0, 0, 25)
    materialsHeader.Position = UDim2.new(0, 0, 0, yOffset)
    materialsHeader.BackgroundTransparency = 1
    materialsHeader.TextColor3 = Color3.fromRGB(60, 50, 40)
    materialsHeader.TextSize = 14
    materialsHeader.Font = Enum.Font.GothamBold
    materialsHeader.TextXAlignment = Enum.TextXAlignment.Left
    materialsHeader.ZIndex = 5
    materialsHeader.Parent = previewScroll
    yOffset = yOffset + 30
    
    -- Materials list (properly aligned)
    if recipe.materials and #recipe.materials > 0 then
        for _, mat in ipairs(recipe.materials) do
            local matItem = self.itemDataFetcher.getItem(mat.itemId)
            if matItem then
                -- Material row container
                local matRow = Instance.new("Frame")
                matRow.Name = "MaterialRow"
                matRow.Size = UDim2.new(1, 0, 0, 50)
                matRow.Position = UDim2.new(0, 0, 0, yOffset)
                matRow.BackgroundColor3 = Color3.fromRGB(250, 209, 43)  -- Golden
                matRow.BorderSizePixel = 0
                matRow.ZIndex = 5
                matRow.Parent = previewScroll
                
                local matCorner = Instance.new("UICorner")
                matCorner.CornerRadius = UDim.new(0, 6)
                matCorner.Parent = matRow
                
                -- Material icon on left
                local matIconFrame = Instance.new("Frame")
                matIconFrame.Name = "IconFrame"
                matIconFrame.Size = UDim2.new(0, 40, 0, 40)
                matIconFrame.Position = UDim2.new(0, 5, 0, 5)
                matIconFrame.BackgroundTransparency = 1
                matIconFrame.ZIndex = 6
                matIconFrame.Parent = matRow
                
                local matIcon = Instance.new("ImageLabel")
                matIcon.Name = "Icon"
                matIcon.Size = UDim2.new(1, 0, 1, 0)
                matIcon.BackgroundTransparency = 1
                matIcon.ImageTransparency = 0
                matIcon.ScaleType = Enum.ScaleType.Fit
                matIcon.ZIndex = 6
                matIcon.Parent = matIconFrame
                
                if matItem.spriteIndex then
                    self.spriteConfig.applySprite(matIcon, matItem.spriteIndex)
                end
                
                -- Material name
                local matName = Instance.new("TextLabel")
                matName.Name = "Name"
                matName.Text = matItem.displayName or matItem.name or mat.itemId
                matName.Size = UDim2.new(1, -100, 0, 25)
                matName.Position = UDim2.new(0, 50, 0, 8)
                matName.BackgroundTransparency = 1
                matName.TextColor3 = Color3.fromRGB(60, 50, 40)
                matName.TextSize = 12
                matName.Font = Enum.Font.GothamBold
                matName.TextXAlignment = Enum.TextXAlignment.Left
                matName.TextTruncate = Enum.TextTruncate.AtEnd
                matName.ZIndex = 6
                matName.Parent = matRow
                
                -- Quantity on right
                local matQuantity = Instance.new("TextLabel")
                matQuantity.Name = "Quantity"
                matQuantity.Text = "x" .. (mat.count or 1)
                matQuantity.Size = UDim2.new(0, 50, 0, 50)
                matQuantity.Position = UDim2.new(1, -55, 0, 0)
                matQuantity.BackgroundTransparency = 1
                matQuantity.TextColor3 = Color3.fromRGB(80, 60, 40)
                matQuantity.TextSize = 16
                matQuantity.Font = Enum.Font.GothamBold
                matQuantity.TextXAlignment = Enum.TextXAlignment.Center
                matQuantity.ZIndex = 6
                matQuantity.Parent = matRow
                
                yOffset = yOffset + 55
            end
        end
    else
        local noMaterials = Instance.new("TextLabel")
        noMaterials.Name = "NoMaterials"
        noMaterials.Text = "No materials required"
        noMaterials.Size = UDim2.new(1, 0, 0, 25)
        noMaterials.Position = UDim2.new(0, 0, 0, yOffset)
        noMaterials.BackgroundTransparency = 1
        noMaterials.TextColor3 = Color3.fromRGB(100, 80, 60)
        noMaterials.TextSize = 11
        noMaterials.Font = Enum.Font.Gotham
        noMaterials.TextXAlignment = Enum.TextXAlignment.Left
        noMaterials.ZIndex = 5
        noMaterials.Parent = previewScroll
        
        yOffset = yOffset + 30
    end
    
    yOffset = yOffset + 10
    
    -- Craft button at bottom
    local craftButton = Instance.new("TextButton")
    craftButton.Name = "CraftButton"
    craftButton.Text = "⚡ Craft Now"
    craftButton.Size = UDim2.new(1, 0, 0, 45)
    craftButton.Position = UDim2.new(0, 0, 0, yOffset)
    craftButton.BackgroundColor3 = Color3.fromRGB(4, 175, 166)  -- Teal
    craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    craftButton.TextSize = 14
    craftButton.Font = Enum.Font.GothamBold
    craftButton.BorderSizePixel = 0
    craftButton.AutoButtonColor = false
    craftButton.ZIndex = 5
    craftButton.Parent = previewScroll
    
    local craftCorner = Instance.new("UICorner")
    craftCorner.CornerRadius = UDim.new(0, 8)
    craftCorner.Parent = craftButton
    
    craftButton.MouseEnter:Connect(function()
        craftButton.BackgroundColor3 = Color3.fromRGB(5, 200, 190)
    end)
    
    craftButton.MouseLeave:Connect(function()
        craftButton.BackgroundColor3 = Color3.fromRGB(4, 175, 166)
    end)
    
    craftButton.MouseButton1Click:Connect(function()
        local craftItemId = recipe.itemId or recipe.id
        print("[DebugCraftingMenu] Crafting:", craftItemId)
        self.inventoryRemote:FireServer("craft_item", {
            itemId = craftItemId
        })
    end)
    
    yOffset = yOffset + 55
    
    -- Update canvas size
    previewScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

--[[
    OLD GRID-BASED RECIPE CARD (REPLACED WITH LIST + PREVIEW INTERFACE)
    Keeping for reference but no longer used
--]]
--[[ DEPRECATED
function CraftingMenu:createRecipeCard(recipe, index)
    -- Properly sized card for grid layout (120x180)
    local card = Instance.new("Frame")
    card.Name = "Recipe_" .. index
    card.Size = UDim2.new(0, 120, 0, 180)  -- Much more reasonable size
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)  -- White card background
    card.BorderSizePixel = 1
    card.BorderColor3 = Color3.fromRGB(200, 180, 160)
    card.LayoutOrder = index
    card.ZIndex = 4
    
    -- Add rounded corners
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Station indicator at top
    local stationLabel = Instance.new("TextLabel")
    stationLabel.Name = "Station"
    stationLabel.Text = self:getStationIcon(recipe.station or "workbench") .. " " .. (recipe.station or "workbench")
    stationLabel.Size = UDim2.new(1, -8, 0, 20)  -- Smaller station label
    stationLabel.Position = UDim2.new(0, 4, 0, 4)
    stationLabel.BackgroundColor3 = self:getStationColor(recipe.station or "workbench")
    stationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    stationLabel.TextSize = 9  -- Smaller text
    stationLabel.Font = Enum.Font.GothamBold
    stationLabel.TextXAlignment = Enum.TextXAlignment.Left
    stationLabel.ZIndex = 5
    stationLabel.Parent = card
    
    local stationCorner = Instance.new("UICorner")
    stationCorner.CornerRadius = UDim.new(0, 4)
    stationCorner.Parent = stationLabel
    
    local stationPadding = Instance.new("UIPadding")
    stationPadding.PaddingLeft = UDim.new(0, 4)
    stationPadding.Parent = stationLabel
    
    -- Result item icon in center - properly sized
    local itemData = self.itemDataFetcher.getItem(recipe.id or recipe.itemId)
    local spriteIndex = itemData and itemData.spriteIndex or (recipe.result and recipe.result.spriteIndex)
    if spriteIndex or recipe.diyIconIndex then
        local iconFrame = Instance.new("Frame")
        iconFrame.Name = "IconFrame"
        iconFrame.Size = UDim2.new(0, 70, 0, 70)  -- Reasonable 70px icon
        iconFrame.Position = UDim2.new(0.5, -35, 0, 28)  -- Centered below station
        iconFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        iconFrame.BorderSizePixel = 0
        iconFrame.ZIndex = 5
        iconFrame.Parent = card
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 8)
        iconCorner.Parent = iconFrame
        
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0.8, 0, 0.8, 0)
        icon.Position = UDim2.new(0.1, 0, 0.1, 0)
        icon.BackgroundTransparency = 1
        icon.ImageTransparency = 0
        icon.ScaleType = Enum.ScaleType.Fit
        icon.ZIndex = 6
        icon.Parent = iconFrame

        -- Try DIY icon first, fall back to item sprite
        local success = false
        if recipe.diyIconIndex then
            success = self.spriteConfig.applyDIYIcon(icon, recipe.diyIconIndex)
        elseif spriteIndex then
            success = self.spriteConfig.applySprite(icon, spriteIndex)
        end
        
        if not success then
            icon.Image = ""
            icon.ImageRectOffset = Vector2.new(0, 0)
            icon.ImageRectSize = Vector2.new(0, 0)
            warn("[DebugCraftingMenu] Failed to apply sprite for recipe", recipe.id or recipe.itemId)
        end
        
        -- DIY icon index number (top-left corner for debugging)
        if recipe.diyIconIndex then
            local indexLabel = Instance.new("TextLabel")
            indexLabel.Name = "IndexLabel"
            indexLabel.Text = tostring(recipe.diyIconIndex)
            indexLabel.Size = UDim2.new(0, 24, 0, 14)
            indexLabel.Position = UDim2.new(0, 2, 0, 2)
            indexLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            indexLabel.BackgroundTransparency = 0.3
            indexLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            indexLabel.TextSize = 9
            indexLabel.Font = Enum.Font.GothamBold
            indexLabel.TextXAlignment = Enum.TextXAlignment.Center
            indexLabel.ZIndex = 7
            indexLabel.Parent = iconFrame
            
            local indexCorner = Instance.new("UICorner")
            indexCorner.CornerRadius = UDim.new(0, 3)
            indexCorner.Parent = indexLabel
        end
    end
    
    -- Recipe name below icon
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Text = recipe.name or recipe.id or "Unknown Recipe"
    nameLabel.Size = UDim2.new(1, -8, 0, 24)  -- Adjusted for smaller card
    nameLabel.Position = UDim2.new(0, 4, 0, 100)  -- Below icon
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(60, 50, 40)
    nameLabel.TextSize = 10  -- Smaller text
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextWrapped = true
    nameLabel.ZIndex = 5
    nameLabel.Parent = card
    
    -- Materials section - adjusted for smaller card
    local materialsLabel = Instance.new("TextLabel")
    materialsLabel.Name = "MaterialsLabel"
    materialsLabel.Text = "Materials:"
    materialsLabel.Size = UDim2.new(1, -8, 0, 12)
    materialsLabel.Position = UDim2.new(0, 4, 0, 126)
    materialsLabel.BackgroundTransparency = 1
    materialsLabel.TextColor3 = Color3.fromRGB(100, 80, 60)
    materialsLabel.TextSize = 8
    materialsLabel.Font = Enum.Font.Gotham
    materialsLabel.TextXAlignment = Enum.TextXAlignment.Left
    materialsLabel.ZIndex = 5
    materialsLabel.Parent = card
    
    local materialsFrame = Instance.new("Frame")
    materialsFrame.Name = "MaterialsFrame"
    materialsFrame.Size = UDim2.new(1, -8, 0, 20)  -- Smaller materials area
    materialsFrame.Position = UDim2.new(0, 4, 0, 139)
    materialsFrame.BackgroundTransparency = 1
    materialsFrame.ZIndex = 5
    materialsFrame.Parent = card
    
    local materialsLayout = Instance.new("UIListLayout")
    materialsLayout.FillDirection = Enum.FillDirection.Horizontal
    materialsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    materialsLayout.Padding = UDim.new(0, 3)  -- Tighter padding
    materialsLayout.Parent = materialsFrame
    
    -- Store reference to self for material click handlers
    local selfRef = self
    
    if recipe.materials and #recipe.materials > 0 then
        for _, mat in ipairs(recipe.materials) do
            local matItem = self.itemDataFetcher.getItem(mat.itemId)
            if matItem then
                -- Clickable material button - smaller size
                local matButton = Instance.new("TextButton")
                matButton.Name = "Mat_" .. mat.itemId
                matButton.Size = UDim2.new(0, 36, 0, 28)  -- Reduced from 40x30
                matButton.BackgroundColor3 = Color3.fromRGB(250, 209, 43)  -- Golden material slot
                matButton.BorderSizePixel = 0
                matButton.Text = ""
                matButton.ZIndex = 6
                matButton.Parent = materialsFrame
                
                local matCorner = Instance.new("UICorner")
                matCorner.CornerRadius = UDim.new(0, 4)
                matCorner.Parent = matButton
                
                -- Material icon - smaller size
                if matItem.spriteIndex then
                    local matIcon = Instance.new("ImageLabel")
                    matIcon.Name = "Icon"
                    matIcon.Size = UDim2.new(0, 20, 0, 20)  -- Reduced from 24x24
                    matIcon.Position = UDim2.new(0.5, -10, 0, 1)  -- Adjusted position
                    matIcon.AnchorPoint = Vector2.new(0.5, 0)
                    matIcon.BackgroundTransparency = 1
                    matIcon.ImageTransparency = 0
                    matIcon.ScaleType = Enum.ScaleType.Fit
                    matIcon.ZIndex = 7
                    matIcon.Parent = matButton

                    local success = self.spriteConfig.applySprite(matIcon, matItem.spriteIndex)
                    if not success then
                        matIcon.Image = ""
                        matIcon.ImageRectOffset = Vector2.new(0, 0)
                        matIcon.ImageRectSize = Vector2.new(0, 0)
                    end
                end
                
                -- Material quantity - smaller text
                local matQuantity = Instance.new("TextLabel")
                matQuantity.Name = "Quantity"
                matQuantity.Text = "x" .. (mat.count or 1)
                matQuantity.Size = UDim2.new(1, 0, 0, 7)  -- Smaller height
                matQuantity.Position = UDim2.new(0, 0, 1, -7)  -- Adjusted position
                matQuantity.BackgroundTransparency = 1
                matQuantity.TextColor3 = Color3.fromRGB(100, 80, 60)
                matQuantity.TextSize = 8  -- Smaller text
                matQuantity.Font = Enum.Font.GothamBold
                matQuantity.TextXAlignment = Enum.TextXAlignment.Center
                matQuantity.ZIndex = 7
                matQuantity.Parent = matButton
                
                -- Click handler: navigate to recipe if it exists
                matButton.MouseButton1Click:Connect(function()
                    -- Check if this material has a recipe
                    local materialRecipe = selfRef.itemDataFetcher.getCraftingRecipe(mat.itemId)
                    if materialRecipe then
                        -- Scroll to and highlight the recipe
                        print("[DebugCraftingMenu] Material", mat.itemId, "has recipe, scrolling...")
                        -- TODO: Implement scroll-to-recipe functionality
                    else
                        print("[DebugCraftingMenu] Material", mat.itemId, "has no recipe")
                    end
                end)
                
                matButton.MouseEnter:Connect(function()
                    matButton.BackgroundColor3 = Color3.fromRGB(255, 220, 60)
                end)
                
                matButton.MouseLeave:Connect(function()
                    matButton.BackgroundColor3 = Color3.fromRGB(250, 209, 43)
                end)
            end
        end
    end
    
    -- Craft button at bottom - adjusted for smaller card
    local craftBtn = Instance.new("TextButton")
    craftBtn.Name = "CraftButton"
    craftBtn.Text = "⚡ Craft"
    craftBtn.Size = UDim2.new(1, -8, 0, 24)  -- Smaller button for smaller card
    craftBtn.Position = UDim2.new(0, 4, 0, 152)  -- Adjusted position for 120x180 card
    craftBtn.BackgroundColor3 = Color3.fromRGB(4, 175, 166)  -- Teal accent
    craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    craftBtn.TextSize = 10  -- Smaller text
    craftBtn.Font = Enum.Font.GothamBold
    craftBtn.BorderSizePixel = 0
    craftBtn.ZIndex = 5
    craftBtn.Parent = card
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = craftBtn
    
    craftBtn.MouseEnter:Connect(function()
        craftBtn.BackgroundColor3 = Color3.fromRGB(5, 200, 190)
    end)
    
    craftBtn.MouseLeave:Connect(function()
        craftBtn.BackgroundColor3 = Color3.fromRGB(4, 175, 166)
    end)
    
    craftBtn.MouseButton1Click:Connect(function()
        local craftItemId = recipe.itemId or recipe.id
        print("[DebugCraftingMenu] Crafting:", craftItemId)
        self.inventoryRemote:FireServer("craft_item", {
            itemId = craftItemId
        })
    end)
    
    return card
end
--]]  -- END DEPRECATED createRecipeCard

function CraftingMenu:renderStations()
    local stations = {
        {id = "workbench", name = "Workbench", desc = "Basic crafting station"},
        {id = "forge", name = "Forge", desc = "For metalworking and weapons"},
        {id = "cooking", name = "Cooking Station", desc = "Prepare meals and recipes"},
        {id = "sewing", name = "Sewing Station", desc = "Create clothing and fabrics"},
        {id = "alchemy", name = "Alchemy Lab", desc = "Brew potions and elixirs"},
    }
    
    for i, station in ipairs(stations) do
        local stationFrame = self:createStationCard(station, i)
        stationFrame.Parent = self.contentFrame
    end
end

function CraftingMenu:createStationCard(station, index)
    local card = Instance.new("Frame")
    card.Name = "Station_" .. station.id
    card.Size = UDim2.new(1, -10, 0, 70)
    card.BackgroundColor3 = Color3.fromRGB(255, 250, 240)  -- Cream card
    card.BorderSizePixel = 1  -- Subtle border
    card.BorderColor3 = Color3.fromRGB(200, 180, 160)  -- Lighter border
    card.LayoutOrder = index
    card.ZIndex = 4
    
    -- Add rounded corners
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 4)
    cardCorner.Parent = card
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Text = self:getStationIcon(station.id)
    iconLabel.Size = UDim2.new(0, 50, 0, 50)
    iconLabel.Position = UDim2.new(0, 10, 0.5, -25)
    iconLabel.BackgroundColor3 = self:getStationColor(station.id)
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextSize = 30
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.BorderSizePixel = 0
    iconLabel.ZIndex = 5
    iconLabel.Parent = card
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Text = station.name
    nameLabel.Size = UDim2.new(1, -180, 0, 25)
    nameLabel.Position = UDim2.new(0, 70, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(40, 30, 20)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 5
    nameLabel.Parent = card
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Text = station.desc
    descLabel.Size = UDim2.new(1, -180, 0, 20)
    descLabel.Position = UDim2.new(0, 70, 0, 38)
    descLabel.BackgroundTransparency = 1
    descLabel.TextColor3 = Color3.fromRGB(100, 80, 60)
    descLabel.TextSize = 11
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.ZIndex = 5
    descLabel.Parent = card
    
    -- Unlock button (for debug) - matching theme
    local unlockBtn = Instance.new("TextButton")
    unlockBtn.Name = "UnlockButton"
    unlockBtn.Text = "🔓 Unlock"
    unlockBtn.Size = UDim2.new(0, 90, 0, 50)
    unlockBtn.Position = UDim2.new(1, -100, 0.5, -25)
    unlockBtn.BackgroundColor3 = Color3.fromRGB(120, 100, 80)  -- Matching brown
    unlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    unlockBtn.TextSize = 12
    unlockBtn.Font = Enum.Font.GothamBold
    unlockBtn.BorderSizePixel = 0
    unlockBtn.ZIndex = 5
    unlockBtn.Parent = card
    
    -- Add rounded corners
    local unlockCorner = Instance.new("UICorner")
    unlockCorner.CornerRadius = UDim.new(0, 4)
    unlockCorner.Parent = unlockBtn
    
    unlockBtn.MouseButton1Click:Connect(function()
        print("[CraftingMenu] Debug unlock station:", station.id)
        -- Could add server-side station unlocking here
    end)
    
    return card
end

function CraftingMenu:attachInput()
    if self.inputConnection then
        self.inputConnection:Disconnect()
        self.inputConnection = nil
    end

    self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == Enum.KeyCode.Escape then
            self:close()
        end
    end)
end

function CraftingMenu:toggle()
    print("[CraftingMenu] toggle() called - current isOpen state:", self.isOpen)
    if self.isOpen then
        self:close()
    else
        self:open()
    end
end

function CraftingMenu:open()
    print("[CraftingMenu] open() called")
    if self.isOpen then
        print("[CraftingMenu] Already open, returning early")
        return
    end

    print("[CraftingMenu] Creating GUI...")
    self:createGui()

    if not self.screenGui or not self.mainFrame then
        warn("[CraftingMenu] ❌ Could not open crafting menu (no ScreenGui or mainFrame)")
        return
    end

    print("[CraftingMenu] Enabling ScreenGui and switching to recipes tab...")
    self.screenGui.Enabled = true
    self.mainFrame.Visible = true
    self:switchTab("RECIPES")
    self:attachInput()

    self.isOpen = true
    print("[CraftingMenu] ✅ GUI opened successfully")
end

function CraftingMenu:close()
    if not self.isOpen then
        return
    end

    if self.inputConnection then
        self.inputConnection:Disconnect()
        self.inputConnection = nil
    end

    if self.mainFrame then
        self.mainFrame.Visible = false
    end
    
    if self.screenGui then
        self.screenGui.Enabled = false
    end

    self.isOpen = false
    print("[CraftingMenu] ✅ GUI closed")
end

function CraftingMenu:Toggle()
    self:toggle()
end

function CraftingMenu:Hide()
    self:close()
end

function CraftingMenu:Show()
    self:open()
end

function CraftingMenu.getOrCreate()
    if CraftingMenu._instance and CraftingMenu._instance.player == Players.LocalPlayer then
        return CraftingMenu._instance
    end

    local instance = CraftingMenu.new()
    if instance then
        CraftingMenu._instance = instance
    end

    return CraftingMenu._instance
end

function CraftingMenu.toggleGlobal()
    local instance = CraftingMenu.getOrCreate()
    if not instance then
        warn("[CraftingMenu] ❌ Failed to toggle crafting menu (instance unavailable)")
        return
    end

    _G.CraftingMenuInstance = instance
    instance:toggle()
end

function CraftingMenu.destroySingleton()
    if not CraftingMenu._instance then
        return
    end

    CraftingMenu._instance:close()

    if CraftingMenu._instance.screenGui then
        CraftingMenu._instance.screenGui:Destroy()
        CraftingMenu._instance.screenGui = nil
    end

    CraftingMenu._instance = nil
end

return CraftingMenu
