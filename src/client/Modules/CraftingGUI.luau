--[[
	CraftingGUI.luau
	
	Full-featured crafting interface for DIY Workbench.
	Shows recipes, materials needed, and handles crafting requests.
	Based on the gold mine DIYWorkbenchGUI but adapted for current system.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ItemDataFetcher = require(sharedFolder:WaitForChild("ItemDataFetcher"))
local SpriteConfig = require(sharedFolder:WaitForChild("SpriteConfig"))

local CraftingGUI = {}
CraftingGUI.__index = CraftingGUI

-- Singleton instance
local _instance = nil

-- UI Colors (Animal Crossing themed - enhanced)
local COLORS = {
    BG_PRIMARY = Color3.fromRGB(255, 251, 231), -- Cream
    BG_SECONDARY = Color3.fromRGB(255, 255, 255), -- White
    BG_RECIPE_ITEM = Color3.fromRGB(250, 245, 235),
    BG_SELECTED = Color3.fromRGB(255, 242, 217), -- Light orange tint
    ACCENT_ORANGE = Color3.fromRGB(255, 160, 100),
    ACCENT_BROWN = Color3.fromRGB(139, 90, 43),
    ACCENT_TEAL = Color3.fromRGB(4, 175, 166), -- ACNH teal
    TEXT_DARK = Color3.fromRGB(60, 50, 40),
    TEXT_LIGHT = Color3.fromRGB(255, 255, 255),
    TEXT_SUBTLE = Color3.fromRGB(120, 110, 100),
    CAN_CRAFT = Color3.fromRGB(100, 200, 100),
    CANNOT_CRAFT = Color3.fromRGB(200, 100, 100),
    BORDER = Color3.fromRGB(210, 180, 140),
    QUANTITY_BADGE = Color3.fromRGB(255, 193, 77), -- Bell gold
}

local function applySpriteSafe(imageLabel: Instance, spriteIndex: number?)
    if not imageLabel or (not imageLabel:IsA("ImageLabel") and not imageLabel:IsA("ImageButton")) then
        return
    end

    if not SpriteConfig.applySprite(imageLabel, spriteIndex) then
        imageLabel.Image = ""
        imageLabel.ImageRectOffset = Vector2.new(0, 0)
        imageLabel.ImageRectSize = Vector2.new(0, 0)
    end
end

local function create3DThumbnail(parent: Frame, assetId: number, size: UDim2?)
    size = size or UDim2.new(0, 120, 0, 120)

    -- Create ViewportFrame for 3D preview
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "ItemPreview3D"
    viewport.Size = size
    viewport.Position = UDim2.new(0, 10, 0, 10)
    viewport.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    viewport.BorderSizePixel = 0
    viewport.Parent = parent

    local viewportCorner = Instance.new("UICorner")
    viewportCorner.CornerRadius = UDim.new(0, 10)
    viewportCorner.Parent = viewport

    local viewportStroke = Instance.new("UIStroke")
    viewportStroke.Color = COLORS.BORDER
    viewportStroke.Thickness = 2
    viewportStroke.Parent = viewport

    -- Create camera
    local camera = Instance.new("Camera")
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    -- Load the 3D model
    local success, model = pcall(function()
        return game:GetObjects("rbxassetid://" .. assetId)[1]
    end)

    if success and model then
        model.Parent = viewport

        -- Calculate bounding box and position camera
        local function getCenterAndSize(obj)
            if obj:IsA("Model") then
                local cf, size = obj:GetBoundingBox()
                return cf.Position, size
            elseif obj:IsA("BasePart") then
                return obj.Position, obj.Size
            end
            return Vector3.new(0, 0, 0), Vector3.new(1, 1, 1)
        end

        local center, modelSize = getCenterAndSize(model)
        local maxDim = math.max(modelSize.X, modelSize.Y, modelSize.Z)
        local distance = maxDim * 2.5

        -- Position camera at an angle
        camera.CFrame = CFrame.new(center + Vector3.new(distance * 0.7, distance * 0.5, distance * 0.7))
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, center)

        -- Rotate the model slowly
        task.spawn(function()
            while viewport.Parent do
                if model and model.Parent then
                    if model:IsA("Model") then
                        model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.rad(0.5), 0))
                    elseif model:IsA("BasePart") then
                        model.CFrame = model.CFrame * CFrame.Angles(0, math.rad(0.5), 0)
                    end
                end
                task.wait(0.03)
            end
        end)

        return viewport
    else
        viewport:Destroy()
        return nil
    end
end

function CraftingGUI.new()
    -- Return existing instance if available
    if _instance then
        print("[CraftingGUI] Returning existing instance")
        return _instance
    end

    local self = setmetatable({}, CraftingGUI)

    self._gui = nil
    self._mainFrame = nil
    self._recipeListFrame = nil
    self._detailsFrame = nil
    self._selectedRecipe = nil
    self._allRecipes = {}
    self._playerInventory = {}
    self._isOpen = false

    -- Load all recipes
    self:loadRecipes()

    -- Create GUI
    self:createGUI()

    -- Listen for inventory updates
    self:setupInventoryListener()

    -- Listen for remote to open/close
    self:setupRemoteListener()

    _instance = self
    print("[CraftingGUI] ✅ Crafting GUI created with", #self._allRecipes, "recipes")

    return self
end

function CraftingGUI:loadRecipes()
    self._allRecipes = {}

    -- Pull the full recipe list (includes outputs that are not in item list yet)
    local craftable = ItemDataFetcher.getCraftableItems()

    for _, recipe in ipairs(craftable) do
        local result = recipe.result or {}
        local itemId = recipe.itemId or result.itemId
        local itemData = ItemDataFetcher.getItem(itemId)

        table.insert(self._allRecipes, {
            itemId = itemId,
            name = recipe.name or result.name or recipe.itemId,
            recipe = recipe,
            spriteIndex = result.spriteIndex or recipe.spriteIndex or 0,
            itemData = itemData,
        })
    end

    -- Sort recipes alphabetically
    table.sort(self._allRecipes, function(a, b)
        return a.name < b.name
    end)

    print("[CraftingGUI] Loaded", #self._allRecipes, "recipes")
end

function CraftingGUI:setupInventoryListener()
    -- Listen for inventory sync from server
    local inventoryRemote = ReplicatedStorage:FindFirstChild("InventoryEvent")
    if inventoryRemote then
        inventoryRemote.OnClientEvent:Connect(function(action, payload)
            if action == "Sync" or action == "SyncInventory" then
                self:updateInventory(payload)
            end
        end)
    end
end

function CraftingGUI:updateInventory(inventoryData)
    self._playerInventory = {}

    if inventoryData and inventoryData.slots then
        for _, slot in pairs(inventoryData.slots) do
            if slot.itemId then
                local count = slot.count or slot.quantity or 1
                self._playerInventory[slot.itemId] = (self._playerInventory[slot.itemId] or 0) + count
            end
        end
    end

    -- Refresh the recipe list if GUI is open
    if self._isOpen then
        self:refreshRecipeList()
    end
end

function CraftingGUI:setupRemoteListener()
    -- Wait for Remotes folder with timeout to avoid infinite yield
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
    if not remotes then
        warn("[CraftingGUI] ⚠️ Remotes folder not found in ReplicatedStorage - creating it")
        remotes = Instance.new("Folder")
        remotes.Name = "Remotes"
        remotes.Parent = ReplicatedStorage
    end

    local openCraftingRemote = remotes:WaitForChild("OpenCraftingGUI", 5)
    if not openCraftingRemote then
        print("[CraftingGUI] ℹ️ OpenCraftingGUI remote not found - will be created by server if needed")
        return
    end

    openCraftingRemote.OnClientEvent:Connect(function()
        self:toggle()
    end)
end

function CraftingGUI:createGUI()
    -- Create ScreenGui
    local screenGui = playerGui:FindFirstChild("CraftingGUI")
    if screenGui then
        screenGui:Destroy()
    end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CraftingGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    self._gui = screenGui

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.4
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = screenGui
    
    backdrop.Active = true
    backdrop.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:close()
        end
    end)

    -- Main frame (responsive with constraints)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.fromScale(0.75, 0.8) -- Larger for better layout
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.BackgroundColor3 = COLORS.BG_PRIMARY
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 2
    mainFrame.Parent = screenGui

    -- Size constraints
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(900, 600)
    sizeConstraint.MaxSize = Vector2.new(1400, 900)
    sizeConstraint.Parent = mainFrame

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = COLORS.BORDER
    mainStroke.Thickness = 3
    mainStroke.Transparency = 0.3
    mainStroke.Parent = mainFrame

    self._mainFrame = mainFrame

    -- Title bar
    self:createTitleBar()

    -- Left panel: Recipe list
    self:createRecipeListPanel()

    -- Right panel: Recipe details
    self:createDetailsPanel()

    -- Close with ESC
    self:setupCloseKeybind()
end

function CraftingGUI:createTitleBar()
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, -16, 0, 60)
    titleBar.Position = UDim2.fromOffset(8, 8)
    titleBar.BackgroundColor3 = COLORS.ACCENT_BROWN
    titleBar.BorderSizePixel = 0
    titleBar.Parent = self._mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(100, 70, 30)
    titleStroke.Thickness = 2
    titleStroke.Parent = titleBar

    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.Position = UDim2.fromOffset(20, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = COLORS.TEXT_LIGHT
    titleLabel.Text = "DIY Crafting (Workbench)"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Recipe count
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(0, 200, 1, 0)
    countLabel.Position = UDim2.new(1, -220, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextSize = 16
    countLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    countLabel.Text = #self._allRecipes .. " recipes"
    countLabel.TextXAlignment = Enum.TextXAlignment.Right
    countLabel.Parent = titleBar

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.fromOffset(40, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = COLORS.ACCENT_ORANGE
    closeButton.BorderSizePixel = 0
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 24
    closeButton.TextColor3 = COLORS.TEXT_LIGHT
    closeButton.Text = "X"
    closeButton.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        self:close()
    end)
    
    -- Hover effect
    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 180, 120)
    end)
    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundColor3 = COLORS.ACCENT_ORANGE
    end)
end

function CraftingGUI:createRecipeListPanel()
    local panel = Instance.new("Frame")
    panel.Name = "RecipeListPanel"
    panel.Size = UDim2.new(0.38, -12, 1, -80)
    panel.Position = UDim2.fromOffset(8, 76)
    panel.BackgroundColor3 = COLORS.BG_SECONDARY
    panel.BorderSizePixel = 0
    panel.Parent = self._mainFrame

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = COLORS.BORDER
    panelStroke.Thickness = 2
    panelStroke.Transparency = 0.5
    panelStroke.Parent = panel

    -- Add padding to panel
    local panelPadding = Instance.new("UIPadding")
    panelPadding.PaddingTop = UDim.new(0, 8)
    panelPadding.PaddingBottom = UDim.new(0, 8)
    panelPadding.PaddingLeft = UDim.new(0, 8)
    panelPadding.PaddingRight = UDim.new(0, 8)
    panelPadding.Parent = panel

    -- Search bar
    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "SearchFrame"
    searchFrame.Size = UDim2.new(1, 0, 0, 40)
    searchFrame.Position = UDim2.new(0, 0, 0, 0)
    searchFrame.BackgroundColor3 = COLORS.BG_PRIMARY
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = panel

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -16, 1, -8)
    searchBox.Position = UDim2.fromOffset(8, 4)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 16
    searchBox.TextColor3 = COLORS.TEXT_DARK
    searchBox.PlaceholderText = "🔍 Search recipes..."
    searchBox.PlaceholderColor3 = COLORS.TEXT_SUBTLE
    searchBox.Text = ""
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchFrame

    self._searchBox = searchBox

    -- Scrolling frame for recipes
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "RecipeScroll"
    scrollFrame.Size = UDim2.new(1, 0, 1, -48)
    scrollFrame.Position = UDim2.fromOffset(0, 48)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = COLORS.ACCENT_TEAL
    scrollFrame.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame

    self._recipeListFrame = scrollFrame

    -- Search functionality
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:filterRecipes(searchBox.Text)
    end)

    -- Populate recipes
    self:refreshRecipeList()
end

function CraftingGUI:refreshRecipeList()
    self:filterRecipes(self._searchBox and self._searchBox.Text or "")
end

function CraftingGUI:filterRecipes(searchText)
    -- Clear existing
    for _, child in ipairs(self._recipeListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Filter recipes
    local filtered = {}
    local searchLower = string.lower(searchText or "")
    
    for _, recipeData in ipairs(self._allRecipes) do
        if searchText == "" or string.find(string.lower(recipeData.name), searchLower, 1, true) then
            table.insert(filtered, recipeData)
        end
    end

    -- Add recipe items
    for i, recipeData in ipairs(filtered) do
        self:createRecipeItem(recipeData, i)
    end

    -- Update canvas size
    local listLayout = self._recipeListFrame:FindFirstChildOfClass("UIListLayout")
    if listLayout then
        self._recipeListFrame.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 10)
    end
end

function CraftingGUI:createRecipeItem(recipeData, index)
    local canCraft = self:canCraftRecipe(recipeData.recipe)
    local isSelected = self._selectedRecipe and self._selectedRecipe.itemId == recipeData.itemId

    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "RecipeItem" .. index
    itemFrame.Size = UDim2.new(1, 0, 0, 70)
    itemFrame.BackgroundColor3 = isSelected and COLORS.BG_SELECTED or COLORS.BG_RECIPE_ITEM
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = self._recipeListFrame

    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = itemFrame

    local itemStroke = Instance.new("UIStroke")
    itemStroke.Color = isSelected and COLORS.ACCENT_ORANGE or COLORS.BORDER
    itemStroke.Thickness = isSelected and 2 or 1
    itemStroke.Transparency = isSelected and 0 or 0.6
    itemStroke.Parent = itemFrame

    -- Sprite icon
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.fromOffset(56, 56)
    iconLabel.Position = UDim2.fromOffset(8, 7)
    iconLabel.BackgroundColor3 = COLORS.BG_SECONDARY
    iconLabel.BorderSizePixel = 0
    applySpriteSafe(iconLabel, recipeData.spriteIndex)
    iconLabel.Parent = itemFrame

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = iconLabel

    -- Recipe name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -140, 0, 32)
    nameLabel.Position = UDim2.fromOffset(72, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = COLORS.TEXT_DARK
    nameLabel.Text = recipeData.name
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = itemFrame

    -- Material count with quantity info
    local materialCount = #(recipeData.recipe.materials or {})
    local materialLabel = Instance.new("TextLabel")
    materialLabel.Name = "Materials"
    materialLabel.Size = UDim2.new(1, -140, 0, 22)
    materialLabel.Position = UDim2.fromOffset(72, 38)
    materialLabel.BackgroundTransparency = 1
    materialLabel.Font = Enum.Font.Gotham
    materialLabel.TextSize = 13
    materialLabel.TextColor3 = COLORS.TEXT_SUBTLE
    materialLabel.Text = string.format("📦 %d material%s", materialCount, materialCount == 1 and "" or "s")
    materialLabel.TextXAlignment = Enum.TextXAlignment.Left
    materialLabel.Parent = itemFrame

    -- Can craft indicator (larger, more visible)
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 8, 1, -12)
    indicator.Position = UDim2.new(1, -12, 0, 6)
    indicator.BackgroundColor3 = canCraft and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
    indicator.BorderSizePixel = 0
    indicator.Parent = itemFrame

    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = indicator

    -- Status text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.fromOffset(100, 18)
    statusLabel.Position = UDim2.new(1, -120, 0, 48)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextColor3 = canCraft and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
    statusLabel.Text = canCraft and "✓ Ready" or "✗ Missing"
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = itemFrame

    -- Click to select
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromScale(1, 1)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = itemFrame

    button.MouseButton1Click:Connect(function()
        self:selectRecipe(recipeData)
    end)

    -- Hover effect
    button.MouseEnter:Connect(function()
        if not isSelected then
            itemFrame.BackgroundColor3 = COLORS.BG_SELECTED
            itemStroke.Transparency = 0.3
        end
    end)

    button.MouseLeave:Connect(function()
        if not isSelected then
            itemFrame.BackgroundColor3 = COLORS.BG_RECIPE_ITEM
            itemStroke.Transparency = 0.6
        end
    end)
end

function CraftingGUI:createDetailsPanel()
    local panel = Instance.new("Frame")
    panel.Name = "DetailsPanel"
    panel.Size = UDim2.new(0.62, -12, 1, -80)
    panel.Position = UDim2.new(0.38, 4, 0, 76)
    panel.BackgroundColor3 = COLORS.BG_SECONDARY
    panel.BorderSizePixel = 0
    panel.Parent = self._mainFrame

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = COLORS.BORDER
    panelStroke.Thickness = 2
    panelStroke.Transparency = 0.5
    panelStroke.Parent = panel

    -- Add padding to details panel
    local detailsPadding = Instance.new("UIPadding")
    detailsPadding.PaddingTop = UDim.new(0, 12)
    detailsPadding.PaddingBottom = UDim.new(0, 12)
    detailsPadding.PaddingLeft = UDim.new(0, 12)
    detailsPadding.PaddingRight = UDim.new(0, 12)
    detailsPadding.Parent = panel

    -- Scrolling frame for details content
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "DetailsScroll"
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = COLORS.ACCENT_TEAL
    scrollFrame.Parent = panel

    self._detailsFrame = panel
    self._detailsScroll = scrollFrame

    -- Placeholder text
    local placeholder = Instance.new("TextLabel")
    placeholder.Name = "Placeholder"
    placeholder.Size = UDim2.new(1, 0, 1, 0)
    placeholder.BackgroundTransparency = 1
    placeholder.Font = Enum.Font.Gotham
    placeholder.TextSize = 20
    placeholder.TextColor3 = COLORS.TEXT_SUBTLE
    placeholder.Text = "👈 Select a recipe to view details"
    placeholder.Parent = scrollFrame
end

function CraftingGUI:selectRecipe(recipeData)
    self._selectedRecipe = recipeData

    -- Refresh recipe list to show selection
    self:refreshRecipeList()

    -- Clear details scroll frame
    for _, child in ipairs(self._detailsScroll:GetChildren()) do
        child:Destroy()
    end

    local recipe = recipeData.recipe
    local canCraft = self:canCraftRecipe(recipe)

    -- Recipe header section
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderFrame"
    headerFrame.Size = UDim2.new(1, 0, 0, 140)
    headerFrame.Position = UDim2.new(0, 0, 0, 0)
    headerFrame.BackgroundColor3 = COLORS.BG_RECIPE_ITEM
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = self._detailsScroll

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = headerFrame

    -- Large recipe icon (use 3D if available, otherwise sprite)
    local itemData = recipeData.itemData
    local assetId = itemData and itemData.assetId

    if assetId then
        -- Create 3D preview
        local viewport = create3DThumbnail(headerFrame, assetId, UDim2.new(0, 120, 0, 120))
        if not viewport then
            -- Fallback to sprite if 3D fails
            local iconLabel = Instance.new("ImageLabel")
            iconLabel.Name = "LargeIcon"
            iconLabel.Size = UDim2.new(0, 120, 0, 120)
            iconLabel.Position = UDim2.new(0, 10, 0, 10)
            iconLabel.BackgroundColor3 = COLORS.BG_SECONDARY
            iconLabel.BorderSizePixel = 0
            applySpriteSafe(iconLabel, recipeData.spriteIndex)
            iconLabel.ScaleType = Enum.ScaleType.Fit
            iconLabel.Parent = headerFrame

            local iconCorner = Instance.new("UICorner")
            iconCorner.CornerRadius = UDim.new(0, 10)
            iconCorner.Parent = iconLabel

            local iconStroke = Instance.new("UIStroke")
            iconStroke.Color = COLORS.BORDER
            iconStroke.Thickness = 2
            iconStroke.Parent = iconLabel
        end
    else
        -- Use sprite icon
        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Name = "LargeIcon"
        iconLabel.Size = UDim2.new(0, 120, 0, 120)
        iconLabel.Position = UDim2.new(0, 10, 0, 10)
        iconLabel.BackgroundColor3 = COLORS.BG_SECONDARY
        iconLabel.BorderSizePixel = 0
        applySpriteSafe(iconLabel, recipeData.spriteIndex)
        iconLabel.ScaleType = Enum.ScaleType.Fit
        iconLabel.Parent = headerFrame

        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 10)
        iconCorner.Parent = iconLabel

        local iconStroke = Instance.new("UIStroke")
        iconStroke.Color = COLORS.BORDER
        iconStroke.Thickness = 2
        iconStroke.Parent = iconLabel
    end

    -- Recipe title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "RecipeTitle"
    titleLabel.Size = UDim2.new(1, -140, 0, 50)
    titleLabel.Position = UDim2.new(0, 140, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 28
    titleLabel.TextColor3 = COLORS.TEXT_DARK
    titleLabel.Text = recipeData.name
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextWrapped = true
    titleLabel.Parent = headerFrame

    -- Craft status badge
    local statusBadge = Instance.new("Frame")
    statusBadge.Name = "StatusBadge"
    statusBadge.Size = UDim2.new(0, 180, 0, 35)
    statusBadge.Position = UDim2.new(0, 140, 0, 65)
    statusBadge.BackgroundColor3 = canCraft and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
    statusBadge.BorderSizePixel = 0
    statusBadge.Parent = headerFrame

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 8)
    badgeCorner.Parent = statusBadge

    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.GothamBold
    statusText.TextSize = 16
    statusText.TextColor3 = COLORS.TEXT_LIGHT
    statusText.Text = canCraft and "✓ Ready to Craft" or "✗ Missing Materials"
    statusText.Parent = statusBadge

    -- Materials section header
    local materialsHeader = Instance.new("TextLabel")
    materialsHeader.Name = "MaterialsHeader"
    materialsHeader.Size = UDim2.new(1, 0, 0, 40)
    materialsHeader.Position = UDim2.new(0, 0, 0, 160)
    materialsHeader.BackgroundTransparency = 1
    materialsHeader.Font = Enum.Font.GothamBold
    materialsHeader.TextSize = 20
    materialsHeader.TextColor3 = COLORS.TEXT_DARK
    materialsHeader.Text = "📦 Materials Required"
    materialsHeader.TextXAlignment = Enum.TextXAlignment.Left
    materialsHeader.Parent = self._detailsScroll

    -- Materials list
    local yOffset = 210
    local materialsContainer = Instance.new("Frame")
    materialsContainer.Name = "MaterialsContainer"
    materialsContainer.Size = UDim2.new(1, 0, 0, 0)
    materialsContainer.Position = UDim2.new(0, 0, 0, yOffset)
    materialsContainer.BackgroundTransparency = 1
    materialsContainer.Parent = self._detailsScroll

    local materialsLayout = Instance.new("UIListLayout")
    materialsLayout.Padding = UDim.new(0, 8)
    materialsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    materialsLayout.Parent = materialsContainer

    for i, material in ipairs(recipe.materials or {}) do
        local materialId = material.itemId or material[1]
        local required = material.count or material.quantity or material[2] or 1
        local owned = self._playerInventory[materialId] or 0
        local hasEnough = owned >= required

        local materialItem = ItemDataFetcher.getItem(materialId)
        local materialName = materialItem and materialItem.name or materialId
        local materialSprite = materialItem and materialItem.spriteIndex or 0

        -- Material frame
        local matFrame = Instance.new("Frame")
        matFrame.Name = "Material" .. i
        matFrame.Size = UDim2.new(1, 0, 0, 70)
        matFrame.BackgroundColor3 = hasEnough and Color3.fromRGB(240, 255, 240) or COLORS.BG_RECIPE_ITEM
        matFrame.BorderSizePixel = 0
        matFrame.LayoutOrder = i
        matFrame.Parent = materialsContainer

        local matCorner = Instance.new("UICorner")
        matCorner.CornerRadius = UDim.new(0, 8)
        matCorner.Parent = matFrame

        local matStroke = Instance.new("UIStroke")
        matStroke.Color = hasEnough and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
        matStroke.Thickness = 2
        matStroke.Transparency = hasEnough and 0.3 or 0.6
        matStroke.Parent = matFrame

        -- Material icon frame
        local iconFrame = Instance.new("Frame")
        iconFrame.Size = UDim2.new(0, 60, 0, 60)
        iconFrame.Position = UDim2.new(0, 8, 0, 5)
        iconFrame.BackgroundColor3 = COLORS.BG_SECONDARY
        iconFrame.BorderSizePixel = 0
        iconFrame.Parent = matFrame

        local iconFrameCorner = Instance.new("UICorner")
        iconFrameCorner.CornerRadius = UDim.new(0, 8)
        iconFrameCorner.Parent = iconFrame

        local matIcon = Instance.new("ImageLabel")
        matIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
        matIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
        matIcon.BackgroundTransparency = 1
        applySpriteSafe(matIcon, materialSprite)
        matIcon.Parent = iconFrame

        -- Quantity label on icon (top-right, black text)
        local iconQuantity = Instance.new("TextLabel")
        iconQuantity.Name = "IconQuantity"
        iconQuantity.Size = UDim2.new(0, 30, 0, 16)
        iconQuantity.Position = UDim2.new(1, -2, 0, 2)
        iconQuantity.AnchorPoint = Vector2.new(1, 0)
        iconQuantity.BackgroundTransparency = 1
        iconQuantity.Text = tostring(owned)
        iconQuantity.TextColor3 = Color3.fromRGB(0, 0, 0) -- Pure black
        iconQuantity.TextSize = 12
        iconQuantity.Font = Enum.Font.GothamBold
        iconQuantity.TextXAlignment = Enum.TextXAlignment.Right
        iconQuantity.TextYAlignment = Enum.TextYAlignment.Top
        iconQuantity.ZIndex = 10
        iconQuantity.Parent = iconFrame

        -- Material name
        local matName = Instance.new("TextLabel")
        matName.Size = UDim2.new(1, -200, 0, 30)
        matName.Position = UDim2.new(0, 80, 0, 8)
        matName.BackgroundTransparency = 1
        matName.Font = Enum.Font.GothamBold
        matName.TextSize = 16
        matName.TextColor3 = COLORS.TEXT_DARK
        matName.Text = materialName
        matName.TextXAlignment = Enum.TextXAlignment.Left
        matName.TextTruncate = Enum.TextTruncate.AtEnd
        matName.Parent = matFrame

        -- Quantity display with badges
        local quantityFrame = Instance.new("Frame")
        quantityFrame.Size = UDim2.new(0, 180, 0, 30)
        quantityFrame.Position = UDim2.new(1, -190, 0, 20)
        quantityFrame.BackgroundTransparency = 1
        quantityFrame.Parent = matFrame

        -- Owned quantity badge
        local ownedBadge = Instance.new("TextLabel")
        ownedBadge.Name = "OwnedBadge"
        ownedBadge.Size = UDim2.new(0, 70, 1, 0)
        ownedBadge.Position = UDim2.new(0, 0, 0, 0)
        ownedBadge.BackgroundColor3 = hasEnough and COLORS.CAN_CRAFT or Color3.fromRGB(200, 150, 150)
        ownedBadge.BorderSizePixel = 0
        ownedBadge.Font = Enum.Font.GothamBold
        ownedBadge.TextSize = 14
        ownedBadge.TextColor3 = COLORS.TEXT_LIGHT
        ownedBadge.Text = "Own: " .. owned
        ownedBadge.TextXAlignment = Enum.TextXAlignment.Center
        ownedBadge.Parent = quantityFrame

        local ownedCorner = Instance.new("UICorner")
        ownedCorner.CornerRadius = UDim.new(0, 6)
        ownedCorner.Parent = ownedBadge

        -- Required quantity badge
        local requiredBadge = Instance.new("TextLabel")
        requiredBadge.Name = "RequiredBadge"
        requiredBadge.Size = UDim2.new(0, 70, 1, 0)
        requiredBadge.Position = UDim2.new(0, 80, 0, 0)
        requiredBadge.BackgroundColor3 = COLORS.QUANTITY_BADGE
        requiredBadge.BorderSizePixel = 0
        requiredBadge.Font = Enum.Font.GothamBold
        requiredBadge.TextSize = 14
        requiredBadge.TextColor3 = COLORS.TEXT_LIGHT
        requiredBadge.Text = "Need: " .. required
        requiredBadge.TextXAlignment = Enum.TextXAlignment.Center
        requiredBadge.Parent = quantityFrame

        local requiredCorner = Instance.new("UICorner")
        requiredCorner.CornerRadius = UDim.new(0, 6)
        requiredCorner.Parent = requiredBadge
    end

    -- Update materials container size and craft button position
    task.wait()
    local materialsHeight = 0
    if materialsLayout then
        materialsHeight = materialsLayout.AbsoluteContentSize.Y
        materialsContainer.Size = UDim2.new(1, 0, 0, materialsHeight)
    end

    -- Craft button (fixed at bottom)
    local craftButton = Instance.new("TextButton")
    craftButton.Name = "CraftButton"
    craftButton.Size = UDim2.new(0, 250, 0, 60)
    craftButton.Position = UDim2.new(0.5, -125, 0, yOffset + materialsHeight + 30)
    craftButton.BackgroundColor3 = canCraft and COLORS.ACCENT_TEAL or COLORS.CANNOT_CRAFT
    craftButton.BorderSizePixel = 0
    craftButton.Font = Enum.Font.GothamBold
    craftButton.TextSize = 22
    craftButton.TextColor3 = COLORS.TEXT_LIGHT
    craftButton.Text = canCraft and "✓ Craft Item" or "✗ Missing Materials"
    craftButton.Parent = self._detailsScroll

    local craftCorner = Instance.new("UICorner")
    craftCorner.CornerRadius = UDim.new(0, 12)
    craftCorner.Parent = craftButton

    local craftStroke = Instance.new("UIStroke")
    craftStroke.Color = canCraft and Color3.fromRGB(0, 150, 140) or Color3.fromRGB(150, 50, 50)
    craftStroke.Thickness = 2
    craftStroke.Parent = craftButton

    if canCraft then
        craftButton.MouseButton1Click:Connect(function()
            self:craftItem(recipeData)
        end)
        
        craftButton.MouseEnter:Connect(function()
            craftButton.BackgroundColor3 = Color3.fromRGB(5, 195, 185)
        end)
        craftButton.MouseLeave:Connect(function()
            craftButton.BackgroundColor3 = COLORS.ACCENT_TEAL
        end)
    end

    -- Update scroll canvas size
    task.wait()
    local totalHeight = yOffset + materialsHeight + 120
    self._detailsScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

function CraftingGUI:canCraftRecipe(recipe)
    for _, material in ipairs(recipe.materials or {}) do
        local materialId = material.itemId or material[1]
        local required = material.count or material.quantity or material[2] or 1
        local owned = self._playerInventory[materialId] or 0

        if owned < required then
            return false
        end
    end

    return true
end

function CraftingGUI:craftItem(recipeData)
    print("[CraftingGUI] Requesting craft:", recipeData.itemId)

    -- Fire crafting request to server
    local craftingRemote = ReplicatedStorage:FindFirstChild("CraftingEvent")
    if craftingRemote then
        craftingRemote:FireServer("StartCrafting", {
            itemId = recipeData.itemId,
            quantity = 1,
        })
    end

    -- Refresh after a moment (server will sync inventory)
    task.wait(0.5)
    self:refreshRecipeList()
    if self._selectedRecipe then
        self:selectRecipe(self._selectedRecipe)
    end
end

function CraftingGUI:setupCloseKeybind()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == Enum.KeyCode.Escape and self._isOpen then
            self:close()
        end
    end)
end

function CraftingGUI:open()
    if self._isOpen then
        return
    end

    self._gui.Enabled = true
    self._isOpen = true

    -- Refresh recipe list
    self:refreshRecipeList()

    print("[CraftingGUI] Opened")
end

function CraftingGUI:close()
    if not self._isOpen then
        return
    end

    self._gui.Enabled = false
    self._isOpen = false

    print("[CraftingGUI] Closed")
end

function CraftingGUI:toggle()
    if self._isOpen then
        self:close()
    else
        self:open()
    end
end

return CraftingGUI
