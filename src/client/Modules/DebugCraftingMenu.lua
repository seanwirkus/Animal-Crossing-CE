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
    self.parent = parent
    self:createGui()
    self:switchTab("RECIPES") -- Default to recipes
    print("[CraftingMenu] ✅ Initialized for DebugManager")
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

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(238, 226, 204)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 2
    mainFrame.Parent = self.parent
    self.mainFrame = mainFrame
    print("[CraftingMenu] ✅ Created main frame")
    
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
    titleBar.BackgroundColor3 = Color3.fromRGB(120, 100, 80)
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Parent = self.mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = "🔨 Crafting Menu (Debug)"
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = titleBar
    
    -- Padding for title
    local titlePadding = Instance.new("UIPadding")
    titlePadding.PaddingLeft = UDim.new(0, 15)
    titlePadding.Parent = titleLabel
end

function CraftingMenu:createTabButtons()
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Color3.fromRGB(200, 180, 160)
    tabContainer.BorderSizePixel = 0
    tabContainer.ZIndex = 3
    tabContainer.Parent = self.mainFrame
    
    local recipesTab = Instance.new("TextButton")
    recipesTab.Name = "RecipesTab"
    recipesTab.Text = "📜 Recipes"
    recipesTab.Size = UDim2.new(0.5, -2, 1, 0)
    recipesTab.Position = UDim2.new(0, 0, 0, 0)
    recipesTab.BackgroundColor3 = Color3.fromRGB(139, 90, 43)
    recipesTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    recipesTab.TextSize = 14
    recipesTab.Font = Enum.Font.GothamBold
    recipesTab.BorderSizePixel = 0
    recipesTab.ZIndex = 4
    recipesTab.Parent = tabContainer
    
    local stationsTab = Instance.new("TextButton")
    stationsTab.Name = "StationsTab"
    stationsTab.Text = "🏗️ Stations"
    stationsTab.Size = UDim2.new(0.5, -2, 1, 0)
    stationsTab.Position = UDim2.new(0.5, 2, 0, 0)
    stationsTab.BackgroundColor3 = Color3.fromRGB(180, 160, 140)
    stationsTab.TextColor3 = Color3.fromRGB(80, 70, 60)
    stationsTab.TextSize = 14
    stationsTab.Font = Enum.Font.GothamBold
    stationsTab.BorderSizePixel = 0
    stationsTab.ZIndex = 4
    stationsTab.Parent = tabContainer
    
    recipesTab.MouseButton1Click:Connect(function()
        self:switchTab("RECIPES")
    end)
    
    stationsTab.MouseButton1Click:Connect(function()
        self:switchTab("STATIONS")
    end)
    
    self.recipesTab = recipesTab
    self.stationsTab = stationsTab
end

function CraftingMenu:createContentArea()
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -130)
    contentFrame.Position = UDim2.new(0, 10, 0, 90)
    contentFrame.BackgroundColor3 = Color3.fromRGB(250, 240, 220)
    contentFrame.BorderSizePixel = 2
    contentFrame.BorderColor3 = Color3.fromRGB(150, 140, 120)
    contentFrame.ScrollBarThickness = 8
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.ZIndex = 3
    contentFrame.Parent = self.mainFrame
    self.contentFrame = contentFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = contentFrame
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
end

function CraftingMenu:createInstructions()
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Text = "Click recipe to craft instantly (ignores materials)"
    instructions.Size = UDim2.new(1, -20, 0, 30)
    instructions.Position = UDim2.new(0, 10, 1, -40)
    instructions.BackgroundTransparency = 1
    instructions.TextColor3 = Color3.fromRGB(100, 90, 80)
    instructions.TextSize = 11
    instructions.Font = Enum.Font.Gotham
    instructions.TextWrapped = true
    instructions.ZIndex = 4
    instructions.Parent = self.mainFrame
end

function CraftingMenu:switchTab(tabName)
    self.currentTab = tabName
    
    if tabName == "RECIPES" then
        self.recipesTab.BackgroundColor3 = Color3.fromRGB(139, 90, 43)
        self.recipesTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.stationsTab.BackgroundColor3 = Color3.fromRGB(180, 160, 140)
        self.stationsTab.TextColor3 = Color3.fromRGB(80, 70, 60)
    else
        self.stationsTab.BackgroundColor3 = Color3.fromRGB(139, 90, 43)
        self.stationsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.recipesTab.BackgroundColor3 = Color3.fromRGB(180, 160, 140)
        self.recipesTab.TextColor3 = Color3.fromRGB(80, 70, 60)
    end
    
    self:renderContent()
end

function CraftingMenu:renderContent()
    -- Clear existing content
    for _, child in pairs(self.contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if self.currentTab == "RECIPES" then
        self:renderRecipes()
    else
        self:renderStations()
    end
end

function CraftingMenu:renderRecipes()
    for i, recipe in ipairs(self.allRecipes) do
        local recipeFrame = self:createRecipeCard(recipe, i)
        recipeFrame.Parent = self.contentFrame
    end
end

function CraftingMenu:createRecipeCard(recipe, index)
    local card = Instance.new("Frame")
    card.Name = "Recipe_" .. index
    card.Size = UDim2.new(1, -10, 0, 100)
    card.BackgroundColor3 = Color3.fromRGB(255, 250, 240)
    card.BorderSizePixel = 2
    card.BorderColor3 = Color3.fromRGB(180, 170, 150)
    card.LayoutOrder = index
    card.ZIndex = 4
    
    -- Item icon
    local itemData = self.itemDataFetcher.getItem(recipe.id)
    if itemData and itemData.spriteIndex then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 48, 0, 48)
        icon.Position = UDim2.new(0, 130, 0.5, -24)  -- Centered vertically
        icon.BackgroundTransparency = 1
        icon.ScaleType = Enum.ScaleType.Stretch
        icon.ZIndex = 5
        icon.Parent = card

        if not self.spriteConfig.applySprite(icon, itemData.spriteIndex) then
            icon.Image = ""
            icon.ImageRectOffset = Vector2.new(0, 0)
            icon.ImageRectSize = self.spriteConfig.DEFAULT_IMAGE_RECT_SIZE
        end
    end
    
    -- Station indicator
    local stationLabel = Instance.new("TextLabel")
    stationLabel.Name = "Station"
    stationLabel.Text = self:getStationIcon(recipe.station or "workbench") .. " " .. (recipe.station or "workbench")
    stationLabel.Size = UDim2.new(0, 120, 0, 20)
    stationLabel.Position = UDim2.new(0, 5, 0, 5)
    stationLabel.BackgroundColor3 = self:getStationColor(recipe.station or "workbench")
    stationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    stationLabel.TextSize = 10
    stationLabel.Font = Enum.Font.GothamBold
    stationLabel.TextXAlignment = Enum.TextXAlignment.Left
    stationLabel.ZIndex = 5
    stationLabel.Parent = card
    
    local stationPadding = Instance.new("UIPadding")
    stationPadding.PaddingLeft = UDim.new(0, 4)
    stationPadding.Parent = stationLabel
    
    -- Recipe name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Text = recipe.name or recipe.id or "Unknown Recipe"
    nameLabel.Size = UDim2.new(1, -190, 0, 25)
    nameLabel.Position = UDim2.new(0, 185, 0, 20)  -- Adjusted
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(40, 30, 20)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 5
    nameLabel.Parent = card
    
    -- Materials list
    local materialsFrame = Instance.new("Frame")
    materialsFrame.Name = "MaterialsFrame"
    materialsFrame.Size = UDim2.new(1, -190, 0, 30)
    materialsFrame.Position = UDim2.new(0, 185, 0, 50)
    materialsFrame.BackgroundTransparency = 1
    materialsFrame.ZIndex = 5
    materialsFrame.Parent = card
    
    local materialsLayout = Instance.new("UIListLayout")
    materialsLayout.FillDirection = Enum.FillDirection.Horizontal
    materialsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    materialsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    materialsLayout.Padding = UDim.new(0, 5)
    materialsLayout.Parent = materialsFrame
    
    if recipe.materials and #recipe.materials > 0 then
        for _, mat in ipairs(recipe.materials) do
            local matItem = self.itemDataFetcher.getItem(mat.itemId)
            if matItem then
                -- Material icon and quantity
                local matFrame = Instance.new("Frame")
                matFrame.Name = "Mat_" .. mat.itemId
                matFrame.Size = UDim2.new(0, 60, 0, 40)
                matFrame.BackgroundTransparency = 1
                matFrame.ZIndex = 6
                matFrame.Parent = materialsFrame
                
                -- Only show icon if sprite exists
                if matItem.spriteIndex then
                    local matIcon = Instance.new("ImageLabel")
                    matIcon.Name = "Icon"
                    matIcon.Size = UDim2.new(0, 24, 0, 24)
                    matIcon.Position = UDim2.new(0.5, -12, 0, 0)
                    matIcon.AnchorPoint = Vector2.new(0.5, 0)
                    matIcon.BackgroundTransparency = 1
                    matIcon.ScaleType = Enum.ScaleType.Stretch
                    matIcon.ZIndex = 7
                    matIcon.Parent = matFrame

                    if not self.spriteConfig.applySprite(matIcon, matItem.spriteIndex) then
                        matIcon.Image = ""
                        matIcon.ImageRectOffset = Vector2.new(0, 0)
                        matIcon.ImageRectSize = self.spriteConfig.DEFAULT_IMAGE_RECT_SIZE
                    end
                end
                
                -- Material name
                local matName = Instance.new("TextLabel")
                matName.Name = "Name"
                matName.Text = (matItem.displayName or matItem.name or mat.itemId)
                matName.Size = UDim2.new(1, 0, 0, 20)
                matName.Position = UDim2.new(0, 0, 0, 0)
                matName.BackgroundTransparency = 1
                matName.TextColor3 = Color3.fromRGB(80, 60, 40)
                matName.TextSize = 9
                matName.Font = Enum.Font.Gotham
                matName.TextXAlignment = Enum.TextXAlignment.Center
                matName.TextScaled = true
                matName.ZIndex = 7
                matName.Parent = matFrame
                
                local matQuantity = Instance.new("TextLabel")
                matQuantity.Name = "Quantity"
                matQuantity.Text = "x" .. (mat.count or 1)
                matQuantity.Size = UDim2.new(1, 0, 0, 12)
                matQuantity.Position = UDim2.new(0, 0, 1, -12)
                matQuantity.BackgroundTransparency = 1
                matQuantity.TextColor3 = Color3.fromRGB(120, 90, 60)
                matQuantity.TextSize = 10
                matQuantity.Font = Enum.Font.GothamBold
                matQuantity.TextXAlignment = Enum.TextXAlignment.Center
                matQuantity.ZIndex = 7
                matQuantity.Parent = matFrame
            end
        end
    else
        -- No materials
        local noMatsLabel = Instance.new("TextLabel")
        noMatsLabel.Name = "NoMaterials"
        noMatsLabel.Text = "No materials required"
        noMatsLabel.Size = UDim2.new(0, 150, 1, 0)
        noMatsLabel.BackgroundTransparency = 1
        noMatsLabel.TextColor3 = Color3.fromRGB(100, 80, 60)
        noMatsLabel.TextSize = 10
        noMatsLabel.Font = Enum.Font.Gotham
        noMatsLabel.TextXAlignment = Enum.TextXAlignment.Left
        noMatsLabel.ZIndex = 6
        noMatsLabel.Parent = materialsFrame
    end
    
    -- Craft button
    local craftBtn = Instance.new("TextButton")
    craftBtn.Name = "CraftButton"
    craftBtn.Text = "⚡ Craft"
    craftBtn.Size = UDim2.new(0, 100, 0, 60)
    craftBtn.Position = UDim2.new(1, -110, 0.5, -30)
    craftBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
    craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    craftBtn.TextSize = 14
    craftBtn.Font = Enum.Font.GothamBold
    craftBtn.BorderSizePixel = 0
    craftBtn.ZIndex = 5
    craftBtn.Parent = card
    
    craftBtn.MouseEnter:Connect(function()
        craftBtn.BackgroundColor3 = Color3.fromRGB(100, 220, 120)
    end)
    
    craftBtn.MouseLeave:Connect(function()
        craftBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
    end)
    
    craftBtn.MouseButton1Click:Connect(function()
        print("[CraftingMenu] Crafting:", recipe.id)
        -- Send craft request to server
        self.inventoryRemote:FireServer("craft_item", {
            itemId = recipe.id
        })
    end)
    
    return card
end

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
    card.BackgroundColor3 = Color3.fromRGB(255, 250, 240)
    card.BorderSizePixel = 2
    card.BorderColor3 = Color3.fromRGB(180, 170, 150)
    card.LayoutOrder = index
    card.ZIndex = 4
    
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
    
    -- Unlock button (for debug)
    local unlockBtn = Instance.new("TextButton")
    unlockBtn.Name = "UnlockButton"
    unlockBtn.Text = "🔓 Unlock"
    unlockBtn.Size = UDim2.new(0, 90, 0, 50)
    unlockBtn.Position = UDim2.new(1, -100, 0.5, -25)
    unlockBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
    unlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    unlockBtn.TextSize = 12
    unlockBtn.Font = Enum.Font.GothamBold
    unlockBtn.BorderSizePixel = 0
    unlockBtn.ZIndex = 5
    unlockBtn.Parent = card
    
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

    if not self.screenGui then
        warn("[CraftingMenu] ❌ Could not open crafting menu (no ScreenGui)")
        return
    end

    print("[CraftingMenu] Enabling ScreenGui and switching to recipes tab...")
    self.screenGui.Enabled = true
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

    if self.screenGui then
        self.screenGui.Enabled = false
    end

    self.isOpen = false
    print("[CraftingMenu] ✅ GUI closed")
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
