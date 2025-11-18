-- Recipes Inventory GUI
-- Beautiful recipe browser based on Figma design with recipe cards, material display, and crafting

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RecipesInventoryGUI = {}
RecipesInventoryGUI.__index = RecipesInventoryGUI

-- Design colors from Figma
local COLORS = {
    BG_MAIN = Color3.fromRGB(255, 251, 231), -- Cream/beige background
    BG_RECIPE_INFO = Color3.fromRGB(231, 221, 185), -- Recipe info background
    BG_CARD = Color3.fromRGB(255, 255, 255), -- White recipe cards
    BG_MATERIAL = Color3.fromRGB(250, 209, 43), -- Golden/yellow material slots
    TEXT_BROWN = Color3.fromRGB(133, 90, 37), -- Brown text
    TEXT_DARK = Color3.fromRGB(60, 50, 40), -- Dark text
    CAN_CRAFT = Color3.fromRGB(100, 200, 100), -- Green for craftable
    CANNOT_CRAFT = Color3.fromRGB(200, 100, 100), -- Red for uncraftable
    BORDER = Color3.fromRGB(100, 100, 100), -- Border color
}

function RecipesInventoryGUI.new()
    local self = setmetatable({}, RecipesInventoryGUI)

    self.player = Players.LocalPlayer

    self.sharedFolder = ReplicatedStorage:WaitForChild("Shared")
    self.itemDataFetcher = require(self.sharedFolder:WaitForChild("ItemDataFetcher"))
    self.spriteConfig = require(self.sharedFolder:WaitForChild("SpriteConfig"))

    self.inventoryRemote = ReplicatedStorage:WaitForChild("InventoryEvent")
    self.craftingRemote = ReplicatedStorage:FindFirstChild("CraftingEvent")
    self.discoveryRemote = ReplicatedStorage:FindFirstChild("RecipeDiscoveryEvent")

    -- Track player inventory for material checking
    self.playerInventory = {} -- itemId -> count
    self.discoveredRecipes = {}
    self.discoveryLoaded = false

    -- GUI elements
    self.mainFrame = nil
    self.recipeCardsScroll = nil
    self.detailsPanel = nil
    self.selectedRecipe = nil

    -- Load recipes
    self:loadRecipes()

    -- Listen for inventory updates
    self:setupInventoryListener()

    -- Listen for crafting responses
    self:setupCraftingListener()

    -- Track recipe discovery progress
    self:setupDiscoveryListener()

    print("[RecipesInventoryGUI] ✅ Initialized with", #self.allRecipes, "recipes")

    return self
end

function RecipesInventoryGUI:Init(parent)
    self.parent = parent
    self:createGui()
    print("[RecipesInventoryGUI] ✅ GUI created")
end

function RecipesInventoryGUI:loadRecipes()
    self.allRecipes = self.itemDataFetcher.getCraftableItems() or {}
    print("[RecipesInventoryGUI] Loaded", #self.allRecipes, "recipes")
end

function RecipesInventoryGUI:setupInventoryListener()
    -- Listen for inventory syncs to update material availability
    self.inventoryRemote.OnClientEvent:Connect(function(action, data)
        if action == "SyncInventory" then
            self.playerInventory = {}
            if data and data.items then
                for slotIndex, slotData in pairs(data.items) do
                    if slotData and slotData.itemId then
                        local current = self.playerInventory[slotData.itemId] or 0
                        self.playerInventory[slotData.itemId] = current + (slotData.count or 1)
                    end
                end
            end
            -- Refresh recipe cards to update craftable status
            if self.recipeCardsScroll then
                self:refreshRecipeCards()
            end
            -- Update details panel if a recipe is selected
            if self.selectedRecipe then
                self:showRecipeDetails(self.selectedRecipe)
            end
        end
    end)
end

function RecipesInventoryGUI:setupCraftingListener()
    -- Listen for crafting responses
    if self.craftingRemote then
        self.craftingRemote.OnClientEvent:Connect(function(action, data)
            if action == "CraftingStarted" then
                if data.success then
                    print("[RecipesInventoryGUI] ✅ Crafting started:", data.itemId)
                    -- Refresh inventory to update material counts
                    -- The inventory sync will automatically refresh the UI
                else
                    warn("[RecipesInventoryGUI] ❌ Failed to start crafting:", data.itemId)
                end
            end
        end)
    end
end

function RecipesInventoryGUI:setupDiscoveryListener()
    if not self.discoveryRemote then
        return
    end

    self.discoveryRemote.OnClientEvent:Connect(function(action, data)
        if action == "DiscoveredRecipes" and data and data.recipes then
            self.discoveryLoaded = true
            table.clear(self.discoveredRecipes)
            for _, recipeId in ipairs(data.recipes) do
                self.discoveredRecipes[recipeId] = true
            end
            self:refreshRecipeCards()
        elseif action == "RecipesUnlocked" then
            self.discoveryRemote:FireServer("RequestDiscovered")
        end
    end)

    self.discoveryRemote:FireServer("RequestDiscovered")
end

function RecipesInventoryGUI:createGui()
    if self.mainFrame then
        return
    end

    -- Main frame with cream background - smaller size, positioned to avoid top-left corner
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "RecipesInventoryFrame"
    mainFrame.Size = UDim2.new(0.7, 0, 0.65, 0) -- Smaller: 70% width, 65% height
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.55, 0) -- Lower than center to avoid top-left
    mainFrame.BackgroundColor3 = COLORS.BG_MAIN
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 2
    mainFrame.Visible = false -- Start hidden
    mainFrame.Parent = self.parent
    self.mainFrame = mainFrame

    -- Add rounded corners
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 6) -- Reduced from 8
    mainCorner.Parent = mainFrame

    -- Title bar - smaller
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, -8, 0, 30) -- Reduced height from 40 to 30
    titleBar.Position = UDim2.new(0, 4, 0, 4) -- Small padding from edges
    titleBar.BackgroundColor3 = Color3.fromRGB(120, 100, 80)
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 4) -- Reduced from 8
    titleCorner.Parent = titleBar

    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Text = "📋 DIY Recipes"
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.Position = UDim2.new(0, 5, 0, 0) -- Reduced padding from 10
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 16 -- Reduced from 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = 4
    titleText.Parent = titleBar

    -- Two-panel layout - with reduced padding
    -- Left: Recipe cards scroll
    local cardsContainer = Instance.new("Frame")
    cardsContainer.Name = "CardsContainer"
    cardsContainer.Size = UDim2.new(0.55, -6, 1, -38) -- Adjusted for title bar (30px) + padding (8px)
    cardsContainer.Position = UDim2.new(0, 4, 0, 38) -- Start after title bar + padding
    cardsContainer.BackgroundTransparency = 1
    cardsContainer.ZIndex = 3
    cardsContainer.Parent = mainFrame

    local recipeCardsScroll = Instance.new("ScrollingFrame")
    recipeCardsScroll.Name = "RecipeCardsScroll"
    recipeCardsScroll.Size = UDim2.new(1, -8, 1, -8) -- Small padding inside container
    recipeCardsScroll.Position = UDim2.new(0, 4, 0, 4)
    recipeCardsScroll.BackgroundTransparency = 1
    recipeCardsScroll.BorderSizePixel = 0
    recipeCardsScroll.ScrollBarThickness = 6 -- Reduced from 8
    recipeCardsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    recipeCardsScroll.ScrollingEnabled = true
    recipeCardsScroll.ZIndex = 3
    recipeCardsScroll.Parent = cardsContainer
    self.recipeCardsScroll = recipeCardsScroll

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.CellSize = UDim2.new(0, 65, 0, 100) -- Reduced from 70, 110
    gridLayout.CellPadding = UDim2.new(0, 6, 0, 6) -- Reduced from 10, 10
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = recipeCardsScroll

    -- Auto-update canvas size
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        recipeCardsScroll.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 8) -- Reduced from 20
    end)

    -- Right: Recipe details panel
    local detailsPanel = Instance.new("Frame")
    detailsPanel.Name = "DetailsPanel"
    detailsPanel.Size = UDim2.new(0.45, -6, 1, -38) -- Adjusted for title bar (30px) + padding (8px)
    detailsPanel.Position = UDim2.new(0.55, 2, 0, 38) -- Start after title bar + padding, gap from left panel
    detailsPanel.BackgroundColor3 = COLORS.BG_RECIPE_INFO
    detailsPanel.BackgroundTransparency = 0.5
    detailsPanel.BorderSizePixel = 0
    detailsPanel.ZIndex = 3
    detailsPanel.Parent = mainFrame
    self.detailsPanel = detailsPanel

    local detailsCorner = Instance.new("UICorner")
    detailsCorner.CornerRadius = UDim.new(0, 6) -- Reduced from 27
    detailsCorner.Parent = detailsPanel

    -- Initially show placeholder
    self:showPlaceholderDetails()

    -- Render recipe cards
    self:renderRecipeCards()
end

function RecipesInventoryGUI:showPlaceholderDetails()
    -- Clear existing content
    for _, child in pairs(self.detailsPanel:GetChildren()) do
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
    placeholder.TextColor3 = COLORS.TEXT_DARK
    placeholder.TextSize = 18
    placeholder.Font = Enum.Font.Gotham
    placeholder.TextWrapped = true
    placeholder.ZIndex = 4
    placeholder.Parent = self.detailsPanel
end

function RecipesInventoryGUI:renderRecipeCards()
    if not self.recipeCardsScroll then
        return
    end

    -- Clear existing cards
    for _, child in pairs(self.recipeCardsScroll:GetChildren()) do
        if child.Name ~= "UIGridLayout" then
            child:Destroy()
        end
    end

    -- Create cards for each recipe
    local recipes = self:getVisibleRecipes()
    for i, recipe in ipairs(recipes) do
        local card = self:createRecipeCard(recipe)
        card.LayoutOrder = i
        card.Parent = self.recipeCardsScroll
    end
end

function RecipesInventoryGUI:getVisibleRecipes()
    if not self.discoveryLoaded or not self.discoveredRecipes or next(self.discoveredRecipes) == nil then
        return self.allRecipes
    end

    local filtered = {}
    for _, recipe in ipairs(self.allRecipes) do
        local recipeId = recipe.itemId or recipe.id
        if not recipeId or self.discoveredRecipes[recipeId] then
            table.insert(filtered, recipe)
        end
    end

    return filtered
end

function RecipesInventoryGUI:refreshRecipeCards()
    -- Re-render cards to update craftable status
    if self.recipeCardsScroll then
        self:renderRecipeCards()
    end
end

function RecipesInventoryGUI:checkCanCraft(recipe)
    if not recipe or not recipe.materials then
        return false
    end

    for _, material in ipairs(recipe.materials) do
        local owned = self.playerInventory[material.itemId] or 0
        if owned < (material.count or 1) then
            return false
        end
    end

    return true
end

function RecipesInventoryGUI:createRecipeCard(recipe)
    local canCraft = self:checkCanCraft(recipe)

    -- Card frame - properly sized for clean display
    local card = Instance.new("TextButton")
    card.Name = recipe.id or recipe.itemId or "RecipeCard"
    card.Size = UDim2.new(0, 70, 0, 110) -- Matches grid cell size
    card.BackgroundColor3 = COLORS.BG_CARD
    card.BorderColor3 = canCraft and COLORS.CAN_CRAFT or COLORS.BORDER
    card.BorderSizePixel = 2
    card.AutoButtonColor = false
    card.Text = ""
    card.ZIndex = 5

    -- Rounded corners
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    -- Shadow effect (subtle border)
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(200, 200, 200)
    shadow.Transparency = 0.7
    shadow.Thickness = 1
    shadow.Parent = card

    -- Result item sprite (top portion) - sized appropriately
    local spriteFrame = Instance.new("Frame")
    spriteFrame.Name = "SpriteFrame"
    spriteFrame.Size = UDim2.new(1, -12, 0.6, 0) -- 60% for sprite area
    spriteFrame.Position = UDim2.new(0, 6, 0, 6) -- Balanced padding
    spriteFrame.BackgroundTransparency = 1
    spriteFrame.ZIndex = 6
    spriteFrame.Parent = card

    local spriteImage = Instance.new("ImageLabel")
    spriteImage.Name = "Sprite"
    spriteImage.Size = UDim2.new(0.85, 0, 0.85, 0) -- Properly sized within frame
    spriteImage.Position = UDim2.new(0.075, 0, 0.075, 0) -- Centered
    spriteImage.BackgroundTransparency = 1
    spriteImage.ImageTransparency = 0 -- Ensure visible
    spriteImage.ScaleType = Enum.ScaleType.Fit
    spriteImage.ZIndex = 6

    -- Try DIY icon first, fall back to item sprite
    local success = false
    if recipe.diyIconIndex then
        success = self.spriteConfig.applyDIYIcon(spriteImage, recipe.diyIconIndex)
    elseif recipe.result and recipe.result.spriteIndex then
        success = self.spriteConfig.applySprite(spriteImage, recipe.result.spriteIndex)
    end

    if not success then
        -- Clear sprite if application failed
        spriteImage.Image = ""
        spriteImage.ImageRectOffset = Vector2.new(0, 0)
        spriteImage.ImageRectSize = Vector2.new(0, 0)
        warn("[RecipesInventoryGUI] Failed to apply sprite for recipe", recipe.itemId)
    end

    spriteImage.Parent = spriteFrame

    -- DIY icon index number (top-left corner for debugging)
    if recipe.diyIconIndex then
        local indexLabel = Instance.new("TextLabel")
        indexLabel.Name = "IndexLabel"
        indexLabel.Text = tostring(recipe.diyIconIndex)
        indexLabel.Size = UDim2.new(0, 20, 0, 12)
        indexLabel.Position = UDim2.new(0, 2, 0, 2)
        indexLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        indexLabel.BackgroundTransparency = 0.3
        indexLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        indexLabel.TextSize = 8
        indexLabel.Font = Enum.Font.GothamBold
        indexLabel.TextXAlignment = Enum.TextXAlignment.Center
        indexLabel.ZIndex = 8
        indexLabel.Parent = card

        local indexCorner = Instance.new("UICorner")
        indexCorner.CornerRadius = UDim.new(0, 3)
        indexCorner.Parent = indexLabel
    end

    -- Recipe name (bottom portion) - properly sized
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "RecipeName"
    nameLabel.Text = recipe.name or recipe.result.name or "Unknown Recipe"
    nameLabel.Size = UDim2.new(1, -12, 0.35, 0) -- 35% for name area
    nameLabel.Position = UDim2.new(0, 6, 0.62, 0) -- Just below sprite
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = COLORS.TEXT_BROWN
    nameLabel.TextSize = 9 -- Readable but compact
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextWrapped = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextYAlignment = Enum.TextYAlignment.Top
    nameLabel.ZIndex = 6
    nameLabel.Parent = card

    -- Craftable indicator (small dot or icon) - properly positioned
    if canCraft then
        local indicator = Instance.new("Frame")
        indicator.Name = "CraftableIndicator"
        indicator.Size = UDim2.new(0, 6, 0, 6) -- Small indicator
        indicator.Position = UDim2.new(1, -10, 0, 4) -- Top-right corner
        indicator.BackgroundColor3 = COLORS.CAN_CRAFT
        indicator.BorderSizePixel = 0
        indicator.ZIndex = 7
        indicator.Parent = card

        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0, 3) -- Circular
        indicatorCorner.Parent = indicator
    end

    -- Hover effect
    card.MouseEnter:Connect(function()
        card.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        card.BorderColor3 = canCraft and COLORS.CAN_CRAFT or Color3.fromRGB(150, 150, 150)
    end)

    card.MouseLeave:Connect(function()
        card.BackgroundColor3 = COLORS.BG_CARD
        card.BorderColor3 = canCraft and COLORS.CAN_CRAFT or COLORS.BORDER
    end)

    -- Click handler
    card.MouseButton1Click:Connect(function()
        self:showRecipeDetails(recipe)
    end)

    return card
end

function RecipesInventoryGUI:showRecipeDetails(recipe)
    self.selectedRecipe = recipe

    -- Clear existing content
    for _, child in pairs(self.detailsPanel:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    -- Scroll frame for details content - with padding
    local detailsScroll = Instance.new("ScrollingFrame")
    detailsScroll.Name = "DetailsScroll"
    detailsScroll.Size = UDim2.new(1, -8, 1, -8) -- Small padding inside panel
    detailsScroll.Position = UDim2.new(0, 4, 0, 4)
    detailsScroll.BackgroundTransparency = 1
    detailsScroll.BorderSizePixel = 0
    detailsScroll.ScrollBarThickness = 5 -- Reduced from 6
    detailsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    detailsScroll.ZIndex = 4
    detailsScroll.Parent = self.detailsPanel

    -- Recipe name - smaller
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "RecipeName"
    nameLabel.Text = recipe.name or recipe.result.name or "Unknown Recipe"
    nameLabel.Size = UDim2.new(1, 0, 0, 40) -- Reduced from 50
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = COLORS.TEXT_BROWN
    nameLabel.TextSize = 20 -- Reduced from 24
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextWrapped = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 5
    nameLabel.Parent = detailsScroll

    local yOffset = 45 -- Reduced from 60

    -- Result item sprite - smaller
    if recipe.result and recipe.result.spriteIndex then
        local resultSpriteFrame = Instance.new("Frame")
        resultSpriteFrame.Name = "ResultSprite"
        resultSpriteFrame.Size = UDim2.new(0, 50, 0, 50) -- Reduced from 60, 60
        resultSpriteFrame.Position = UDim2.new(0, 0, 0, yOffset)
        resultSpriteFrame.BackgroundTransparency = 1
        resultSpriteFrame.ZIndex = 5
        resultSpriteFrame.Parent = detailsScroll

        local resultSprite = Instance.new("ImageLabel")
        resultSprite.Name = "Sprite"
        resultSprite.Size = UDim2.new(1, 0, 1, 0)
        resultSprite.BackgroundTransparency = 1
        resultSprite.ImageTransparency = 0 -- Ensure visible
        resultSprite.ScaleType = Enum.ScaleType.Fit
        resultSprite.ZIndex = 5
        resultSprite.Parent = resultSpriteFrame

        -- Try DIY icon first, fall back to item sprite
        local success = false
        if recipe.diyIconIndex then
            success = self.spriteConfig.applyDIYIcon(resultSprite, recipe.diyIconIndex)
        else
            success = self.spriteConfig.applySprite(resultSprite, recipe.result.spriteIndex)
        end

        if not success then
            -- Clear sprite if application failed
            resultSprite.Image = ""
            resultSprite.ImageRectOffset = Vector2.new(0, 0)
            resultSprite.ImageRectSize = Vector2.new(0, 0)
            warn("[RecipesInventoryGUI] Failed to apply sprite for recipe", recipe.itemId)
        end

        yOffset = yOffset + 55 -- Tighter spacing
    end

    -- Materials section header - smaller
    local materialsHeader = Instance.new("TextLabel")
    materialsHeader.Name = "MaterialsHeader"
    materialsHeader.Text = "Materials Required:"
    materialsHeader.Size = UDim2.new(1, 0, 0, 25) -- Reduced from 30
    materialsHeader.Position = UDim2.new(0, 0, 0, yOffset)
    materialsHeader.BackgroundTransparency = 1
    materialsHeader.TextColor3 = COLORS.TEXT_DARK
    materialsHeader.TextSize = 16 -- Reduced from 18
    materialsHeader.Font = Enum.Font.GothamBold
    materialsHeader.TextXAlignment = Enum.TextXAlignment.Left
    materialsHeader.ZIndex = 5
    materialsHeader.Parent = detailsScroll

    yOffset = yOffset + 35 -- Reduced from 40

    -- Materials list
    local canCraft = true
    if recipe.materials and #recipe.materials > 0 then
        for _, material in ipairs(recipe.materials) do
            local _materialSlot = self:createMaterialSlot(material, detailsScroll, yOffset)
            local owned = self.playerInventory[material.itemId] or 0
            local required = material.count or 1
            if owned < required then
                canCraft = false
            end
            yOffset = yOffset + 52 -- Tighter spacing for materials
        end
    else
        -- No materials required
        local noMaterials = Instance.new("TextLabel")
        noMaterials.Name = "NoMaterials"
        noMaterials.Text = "No materials required"
        noMaterials.Size = UDim2.new(1, 0, 0, 30)
        noMaterials.Position = UDim2.new(0, 0, 0, yOffset)
        noMaterials.BackgroundTransparency = 1
        noMaterials.TextColor3 = COLORS.TEXT_DARK
        noMaterials.TextSize = 14
        noMaterials.Font = Enum.Font.Gotham
        noMaterials.TextXAlignment = Enum.TextXAlignment.Left
        noMaterials.ZIndex = 5
        noMaterials.Parent = detailsScroll

        yOffset = yOffset + 40
    end

    -- Craft button - smaller
    local craftButton = Instance.new("TextButton")
    craftButton.Name = "CraftButton"
    craftButton.Size = UDim2.new(1, 0, 0, 40) -- Reduced from 50
    craftButton.Position = UDim2.new(0, 0, 0, yOffset)
    craftButton.BackgroundColor3 = canCraft and COLORS.CAN_CRAFT or Color3.fromRGB(150, 150, 150)
    craftButton.BorderSizePixel = 0
    craftButton.Text = canCraft and "Craft" or "Missing Materials"
    craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    craftButton.TextSize = 16 -- Reduced from 18
    craftButton.Font = Enum.Font.GothamBold
    craftButton.AutoButtonColor = false
    craftButton.Active = canCraft
    craftButton.ZIndex = 5
    craftButton.Parent = detailsScroll

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = craftButton

    -- Button hover effect
    craftButton.MouseEnter:Connect(function()
        if canCraft then
            craftButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        end
    end)

    craftButton.MouseLeave:Connect(function()
        if canCraft then
            craftButton.BackgroundColor3 = COLORS.CAN_CRAFT
        end
    end)

    -- Craft button click handler
    craftButton.MouseButton1Click:Connect(function()
        if canCraft and recipe.itemId and self.craftingRemote then
            print("[RecipesInventoryGUI] Crafting:", recipe.name)
            -- Send crafting request to server
            self.craftingRemote:FireServer("StartCrafting", {
                itemId = recipe.itemId,
                quantity = 1,
            })
            print("[RecipesInventoryGUI] ✅ Crafting request sent")
        elseif not self.craftingRemote then
            warn("[RecipesInventoryGUI] ❌ CraftingEvent remote not found")
        end
    end)

    yOffset = yOffset + 50 -- Reduced from 60

    -- Update canvas size
    detailsScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function RecipesInventoryGUI:createMaterialSlot(material, parent, yPosition)
    local owned = self.playerInventory[material.itemId] or 0
    local required = material.count or 1
    local hasEnough = owned >= required

    -- Material slot container - compact for details panel
    local slotContainer = Instance.new("Frame")
    slotContainer.Name = "MaterialSlot"
    slotContainer.Size = UDim2.new(1, 0, 0, 50) -- Compact 50px height
    slotContainer.Position = UDim2.new(0, 0, 0, yPosition)
    slotContainer.BackgroundTransparency = 1
    slotContainer.ZIndex = 5
    slotContainer.Parent = parent

    -- Golden background for sprite - properly sized
    local spriteFrame = Instance.new("Frame")
    spriteFrame.Name = "SpriteFrame"
    spriteFrame.Size = UDim2.new(0, 45, 0, 45) -- Balanced size
    spriteFrame.Position = UDim2.new(0, 0, 0, 2) -- Slight offset for alignment
    spriteFrame.BackgroundColor3 = COLORS.BG_MATERIAL
    spriteFrame.BorderSizePixel = 0
    spriteFrame.ZIndex = 5
    spriteFrame.Parent = slotContainer

    local spriteCorner = Instance.new("UICorner")
    spriteCorner.CornerRadius = UDim.new(0, 8)
    spriteCorner.Parent = spriteFrame

    -- Material sprite
    local spriteImage = Instance.new("ImageLabel")
    spriteImage.Name = "MaterialSprite"
    spriteImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    spriteImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    spriteImage.BackgroundTransparency = 1
    spriteImage.ImageTransparency = 0 -- Ensure visible
    spriteImage.ScaleType = Enum.ScaleType.Fit
    spriteImage.ZIndex = 6
    spriteImage.Parent = spriteFrame

    if material.spriteIndex then
        local success = self.spriteConfig.applySprite(spriteImage, material.spriteIndex)
        if not success then
            -- Clear sprite if application failed
            spriteImage.Image = ""
            spriteImage.ImageRectOffset = Vector2.new(0, 0)
            spriteImage.ImageRectSize = Vector2.new(0, 0)
            warn("[RecipesInventoryGUI] Failed to apply sprite", material.spriteIndex, "for material", material.itemId)
        end
    end

    -- Material name and count - adjusted for compact size
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, -55, 1, 0) -- Adjusted for 45px sprite
    infoFrame.Position = UDim2.new(0, 55, 0, 0) -- Adjusted position
    infoFrame.BackgroundTransparency = 1
    infoFrame.ZIndex = 5
    infoFrame.Parent = slotContainer

    local materialName = Instance.new("TextLabel")
    materialName.Name = "MaterialName"
    materialName.Text = material.name or material.itemId or "Unknown"
    materialName.Size = UDim2.new(1, 0, 0.5, 0)
    materialName.Position = UDim2.new(0, 6, 0, 0) -- Compact padding
    materialName.BackgroundTransparency = 1
    materialName.TextColor3 = hasEnough and COLORS.TEXT_DARK or Color3.fromRGB(150, 150, 150)
    materialName.TextSize = 11 -- Readable compact size
    materialName.Font = Enum.Font.Gotham
    materialName.TextXAlignment = Enum.TextXAlignment.Left
    materialName.TextWrapped = true
    materialName.ZIndex = 5
    materialName.Parent = infoFrame

    local materialCount = Instance.new("TextLabel")
    materialCount.Name = "MaterialCount"
    materialCount.Text = string.format("%d / %d", owned, required)
    materialCount.Size = UDim2.new(1, 0, 0.5, 0)
    materialCount.Position = UDim2.new(0, 6, 0.5, 0) -- Compact padding
    materialCount.BackgroundTransparency = 1
    materialCount.TextColor3 = hasEnough and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
    materialCount.TextSize = 13 -- Slightly smaller
    materialCount.Font = Enum.Font.GothamBold
    materialCount.TextXAlignment = Enum.TextXAlignment.Left
    materialCount.ZIndex = 5
    materialCount.Parent = infoFrame

    -- Visual feedback for insufficient materials
    if not hasEnough then
        spriteFrame.BackgroundTransparency = 0.5
        spriteImage.ImageTransparency = 0.5
    end

    return slotContainer
end

function RecipesInventoryGUI:Toggle()
    if not self.mainFrame then
        return
    end

    self.mainFrame.Visible = not self.mainFrame.Visible

    if self.mainFrame.Visible then
        -- Refresh recipes when opened
        self:refreshRecipeCards()
    end
end

function RecipesInventoryGUI:Show()
    if self.mainFrame then
        self.mainFrame.Visible = true
        self:refreshRecipeCards()
    end
end

function RecipesInventoryGUI:Hide()
    if self.mainFrame then
        self.mainFrame.Visible = false
    end
end

return RecipesInventoryGUI
