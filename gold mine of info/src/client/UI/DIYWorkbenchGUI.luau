-- DIY Workbench GUI
-- Craft items using recipes from ItemDB with emoji icons for materials
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local DIYWorkbenchGUI = {}
DIYWorkbenchGUI.__index = DIYWorkbenchGUI

-- Track singleton instance
local _instance = nil

-- UI Colors
local COLORS = {
	BG_PRIMARY = Color3.fromRGB(250, 245, 235),
	BG_SECONDARY = Color3.fromRGB(255, 255, 255),
	ACCENT_ORANGE = Color3.fromRGB(255, 160, 100),
	ACCENT_BROWN = Color3.fromRGB(139, 90, 43),
	TEXT_DARK = Color3.fromRGB(60, 50, 40),
	TEXT_LIGHT = Color3.fromRGB(255, 255, 255),
	CAN_CRAFT = Color3.fromRGB(100, 200, 100),
	CANNOT_CRAFT = Color3.fromRGB(200, 100, 100),
}

function DIYWorkbenchGUI.new()
	-- Return existing instance if already created
	if _instance then
		print("[DIYWorkbench] ⚠️  Returning existing Crafting GUI instance")
		return _instance
	end
	
	local self = setmetatable({}, DIYWorkbenchGUI)
	
	self._gui = nil
	self._selectedRecipe = nil
	self._playerMaterials = {}
	self._initialized = false
	
	self:_createGUI()
	
	_instance = self
	print("[DIYWorkbench] ✅ Crafting GUI created (singleton instance)")
	return self
end

-- Create main GUI
function DIYWorkbenchGUI:_createGUI()
	if self._initialized then return end
	self._initialized = true
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DIYWorkbenchGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = player:WaitForChild("PlayerGui")
	
	self._gui = screenGui
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0.85, 0, 0.8, 0)
	container.Position = UDim2.new(0.075, 0, 0.1, 0)
	container.BackgroundColor3 = COLORS.BG_PRIMARY
	container.BorderSizePixel = 0
	container.Parent = screenGui
	
	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0.02, 0)
	containerCorner.Parent = container
	
	-- Header
	self:_createHeader(container)
	
	-- Recipe list (left side)
	self:_createRecipeList(container)
	
	-- Recipe details (right side)
	self:_createRecipeDetails(container)
	
	-- Close button
	self:_createCloseButton(container)
end

-- Create header
function DIYWorkbenchGUI:_createHeader(parent)
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0.1, 0)
	header.BackgroundColor3 = COLORS.ACCENT_ORANGE
	header.BorderSizePixel = 0
	header.Parent = parent
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.02, 0)
	headerCorner.Parent = header
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.9, 0, 1, 0)
	title.Position = UDim2.new(0.02, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🔨 DIY Workbench - Craft Items"
	title.TextSize = 36
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = COLORS.TEXT_LIGHT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	-- Recipe count
	local recipeCount = Instance.new("TextLabel")
	recipeCount.Name = "RecipeCount"
	recipeCount.Size = UDim2.new(0.2, 0, 0.6, 0)
	recipeCount.Position = UDim2.new(0.78, 0, 0.2, 0)
	recipeCount.BackgroundColor3 = COLORS.BG_SECONDARY
	recipeCount.Text = "📋 0 Recipes"
	recipeCount.TextSize = 20
	recipeCount.Font = Enum.Font.GothamBold
	recipeCount.TextColor3 = COLORS.TEXT_DARK
	recipeCount.Parent = header
	
	local countCorner = Instance.new("UICorner")
	countCorner.CornerRadius = UDim.new(0.3, 0)
	countCorner.Parent = recipeCount
	
	self._recipeCountLabel = recipeCount
end

-- Create recipe list
function DIYWorkbenchGUI:_createRecipeList(parent)
	local listContainer = Instance.new("ScrollingFrame")
	listContainer.Name = "RecipeList"
	listContainer.Size = UDim2.new(0.48, 0, 0.85, 0)
	listContainer.Position = UDim2.new(0.01, 0, 0.12, 0)
	listContainer.BackgroundColor3 = COLORS.BG_SECONDARY
	listContainer.BorderSizePixel = 0
	listContainer.ScrollBarThickness = 8
	listContainer.Parent = parent
	
	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0.02, 0)
	listCorner.Parent = listContainer
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Parent = listContainer
	
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 10)
	listPadding.PaddingBottom = UDim.new(0, 10)
	listPadding.PaddingLeft = UDim.new(0, 10)
	listPadding.PaddingRight = UDim.new(0, 10)
	listPadding.Parent = listContainer
	
	self._recipeListContainer = listContainer
end

-- Create recipe details panel
function DIYWorkbenchGUI:_createRecipeDetails(parent)
	local detailsPanel = Instance.new("Frame")
	detailsPanel.Name = "RecipeDetails"
	detailsPanel.Size = UDim2.new(0.49, 0, 0.85, 0)
	detailsPanel.Position = UDim2.new(0.50, 0, 0.12, 0)
	detailsPanel.BackgroundColor3 = COLORS.BG_SECONDARY
	detailsPanel.BorderSizePixel = 0
	detailsPanel.Parent = parent
	
	local detailsCorner = Instance.new("UICorner")
	detailsCorner.CornerRadius = UDim.new(0.02, 0)
	detailsCorner.Parent = detailsPanel
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0.08, 0)
	title.Position = UDim2.new(0, 10, 0.02, 0)
	title.BackgroundColor3 = COLORS.ACCENT_BROWN
	title.Text = "📋 Recipe Details"
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = COLORS.TEXT_LIGHT
	title.Parent = detailsPanel
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.2, 0)
	titleCorner.Parent = title
	
	-- Result item display
	local resultContainer = Instance.new("Frame")
	resultContainer.Name = "ResultContainer"
	resultContainer.Size = UDim2.new(0.9, 0, 0.3, 0)
	resultContainer.Position = UDim2.new(0.05, 0, 0.12, 0)
	resultContainer.BackgroundTransparency = 1
	resultContainer.Parent = detailsPanel
	
	local resultEmoji = Instance.new("TextLabel")
	resultEmoji.Name = "ResultEmoji"
	resultEmoji.Size = UDim2.new(1, 0, 0.6, 0)
	resultEmoji.BackgroundTransparency = 1
	resultEmoji.Text = "🔨"
	resultEmoji.TextSize = 100
	resultEmoji.Parent = resultContainer
	
	local resultName = Instance.new("TextLabel")
	resultName.Name = "ResultName"
	resultName.Size = UDim2.new(1, 0, 0.4, 0)
	resultName.Position = UDim2.new(0, 0, 0.6, 0)
	resultName.BackgroundTransparency = 1
	resultName.Text = "Select a recipe"
	resultName.TextSize = 22
	resultName.Font = Enum.Font.GothamBold
	resultName.TextColor3 = COLORS.TEXT_DARK
	resultName.TextWrapped = true
	resultName.Parent = resultContainer
	
	-- Materials required section
	local materialsLabel = Instance.new("TextLabel")
	materialsLabel.Size = UDim2.new(0.9, 0, 0.08, 0)
	materialsLabel.Position = UDim2.new(0.05, 0, 0.44, 0)
	materialsLabel.BackgroundTransparency = 1
	materialsLabel.Text = "📦 Materials Required:"
	materialsLabel.TextSize = 20
	materialsLabel.Font = Enum.Font.GothamBold
	materialsLabel.TextColor3 = COLORS.TEXT_DARK
	materialsLabel.TextXAlignment = Enum.TextXAlignment.Left
	materialsLabel.Parent = detailsPanel
	
	-- Materials list
	local materialsContainer = Instance.new("ScrollingFrame")
	materialsContainer.Name = "MaterialsContainer"
	materialsContainer.Size = UDim2.new(0.9, 0, 0.35, 0)
	materialsContainer.Position = UDim2.new(0.05, 0, 0.53, 0)
	materialsContainer.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	materialsContainer.BorderSizePixel = 0
	materialsContainer.ScrollBarThickness = 6
	materialsContainer.Parent = detailsPanel
	
	local materialsCorner = Instance.new("UICorner")
	materialsCorner.CornerRadius = UDim.new(0.05, 0)
	materialsCorner.Parent = materialsContainer
	
	local materialsLayout = Instance.new("UIListLayout")
	materialsLayout.Padding = UDim.new(0, 5)
	materialsLayout.Parent = materialsContainer
	
	self._materialsContainer = materialsContainer
	
	-- Craft button
	local craftButton = Instance.new("TextButton")
	craftButton.Name = "CraftButton"
	craftButton.Size = UDim2.new(0.9, 0, 0.1, 0)
	craftButton.Position = UDim2.new(0.05, 0, 0.89, 0)
	craftButton.BackgroundColor3 = COLORS.CAN_CRAFT
	craftButton.Text = "🔨 Craft Item"
	craftButton.TextSize = 28
	craftButton.Font = Enum.Font.GothamBold
	craftButton.TextColor3 = COLORS.TEXT_LIGHT
	craftButton.Parent = detailsPanel
	
	local craftCorner = Instance.new("UICorner")
	craftCorner.CornerRadius = UDim.new(0.2, 0)
	craftCorner.Parent = craftButton
	
	craftButton.MouseButton1Click:Connect(function()
		self:_craftSelectedRecipe()
	end)
	
	self._craftButton = craftButton
	self._resultEmoji = resultEmoji
	self._resultName = resultName
end

-- Create close button
function DIYWorkbenchGUI:_createCloseButton(parent)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -60, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
	closeButton.Text = "✕"
	closeButton.TextSize = 30
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = COLORS.TEXT_LIGHT
	closeButton.Parent = parent
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		self:Hide()
	end)
end

-- Load recipes
function DIYWorkbenchGUI:LoadRecipes()
	-- Get recipes from server
	local getRecipesRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("GetDIYRecipes")
	if not getRecipesRemote then
		warn("[DIYWorkbench] GetDIYRecipes remote not found")
		return
	end
	
	local recipes = getRecipesRemote:InvokeServer()
	
	if not recipes or #recipes == 0 then
		self:_showNoRecipesMessage()
		return
	end
	
	self._recipeCountLabel.Text = string.format("📋 %d Recipes", #recipes)
	
	-- Clear existing
	for _, child in pairs(self._recipeListContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- Create recipe cards
	for _, recipe in ipairs(recipes) do
		self:_createRecipeCard(recipe)
	end
	
	-- Update canvas size
	local layout = self._recipeListContainer:FindFirstChildOfClass("UIListLayout")
	if layout then
		self._recipeListContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end
end

-- Create recipe card
function DIYWorkbenchGUI:_createRecipeCard(recipe)
	local card = Instance.new("TextButton")
	card.Name = recipe.name
	card.Size = UDim2.new(1, 0, 0, 80)
	card.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.Parent = self._recipeListContainer
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0.1, 0)
	cardCorner.Parent = card
	
	-- Emoji icon
	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(0, 60, 0, 60)
	emoji.Position = UDim2.new(0, 10, 0, 10)
	emoji.BackgroundTransparency = 1
	emoji.Text = recipe.emoji or "🔨"
	emoji.TextSize = 48
	emoji.Parent = card
	
	-- Recipe name
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -150, 0.5, 0)
	name.Position = UDim2.new(0, 80, 0, 10)
	name.BackgroundTransparency = 1
	name.Text = recipe.name
	name.TextSize = 18
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = COLORS.TEXT_DARK
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextWrapped = true
	name.Parent = card
	
	-- Material count
	local matCount = Instance.new("TextLabel")
	matCount.Size = UDim2.new(1, -150, 0.4, 0)
	matCount.Position = UDim2.new(0, 80, 0.5, 0)
	matCount.BackgroundTransparency = 1
	matCount.Text = string.format("📦 %d materials", recipe.materialCount or 0)
	matCount.TextSize = 14
	matCount.Font = Enum.Font.Gotham
	matCount.TextColor3 = COLORS.TEXT_DARK
	matCount.TextXAlignment = Enum.TextXAlignment.Left
	matCount.Parent = card
	
	-- Can craft indicator
	local canCraft = recipe.canCraft or false
	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 12, 0, 12)
	indicator.Position = UDim2.new(1, -25, 0, 10)
	indicator.BackgroundColor3 = canCraft and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
	indicator.BorderSizePixel = 0
	indicator.Parent = card
	
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = indicator
	
	-- Click handler
	card.MouseButton1Click:Connect(function()
		self:_selectRecipe(recipe)
	end)
	
	-- Hover effect
	card.MouseEnter:Connect(function()
		card.BackgroundColor3 = Color3.fromRGB(220, 255, 220)
	end)
	
	card.MouseLeave:Connect(function()
		card.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	end)
end

-- Create recipe details display (implementation moved to _createGUI)

-- Select recipe
function DIYWorkbenchGUI:_selectRecipe(recipe)
	self._selectedRecipe = recipe
	
	-- Update result display
	self._resultEmoji.Text = recipe.emoji or "🔨"
	self._resultName.Text = recipe.name
	
	-- Clear materials container
	for _, child in pairs(self._materialsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Display materials
	if recipe.materials then
		for material, quantity in pairs(recipe.materials) do
			self:_createMaterialRow(material, quantity, recipe.playerHas and recipe.playerHas[material] or 0)
		end
	end
	
	-- Update canvas size
	local layout = self._materialsContainer:FindFirstChildOfClass("UIListLayout")
	if layout then
		self._materialsContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end
	
	-- Update craft button
	local canCraft = recipe.canCraft or false
	self._craftButton.BackgroundColor3 = canCraft and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
	self._craftButton.Text = canCraft and "🔨 Craft Item" or "❌ Missing Materials"
	
	print("[DIYWorkbench] Selected recipe:", recipe.name)
end

-- Create material requirement row
function DIYWorkbenchGUI:_createMaterialRow(materialName, required, owned)
	local row = Instance.new("Frame")
	row.Name = materialName
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
	row.BorderSizePixel = 0
	row.Parent = self._materialsContainer
	
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0.1, 0)
	rowCorner.Parent = row
	
	-- Material emoji (would get from ItemDB)
	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(0, 40, 0, 40)
	emoji.Position = UDim2.new(0, 5, 0, 5)
	emoji.BackgroundTransparency = 1
	emoji.Text = "🪵"  -- Default, should get from ItemDB
	emoji.TextSize = 32
	emoji.Parent = row
	
	-- Material name
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -130, 1, 0)
	name.Position = UDim2.new(0, 50, 0, 0)
	name.BackgroundTransparency = 1
	name.Text = materialName
	name.TextSize = 16
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = COLORS.TEXT_DARK
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = row
	
	-- Quantity (owned/required)
	local hasEnough = owned >= required
	local quantity = Instance.new("TextLabel")
	quantity.Size = UDim2.new(0, 80, 0.7, 0)
	quantity.Position = UDim2.new(1, -90, 0.15, 0)
	quantity.BackgroundColor3 = hasEnough and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
	quantity.Text = string.format("%d / %d", owned, required)
	quantity.TextSize = 18
	quantity.Font = Enum.Font.GothamBold
	quantity.TextColor3 = COLORS.TEXT_LIGHT
	quantity.Parent = row
	
	local quantityCorner = Instance.new("UICorner")
	quantityCorner.CornerRadius = UDim.new(0.3, 0)
	quantityCorner.Parent = quantity
end

-- Show no recipes message
function DIYWorkbenchGUI:_showNoRecipesMessage()
	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, 0, 0.3, 0)
	message.Position = UDim2.new(0, 0, 0.35, 0)
	message.BackgroundTransparency = 1
	message.Text = "📋\n\nNo DIY recipes yet!\n\nLearn recipes from villagers and special characters"
	message.TextSize = 24
	message.Font = Enum.Font.Gotham
	message.TextColor3 = COLORS.TEXT_DARK
	message.Parent = self._recipeListContainer
end

-- Craft selected recipe
function DIYWorkbenchGUI:_craftSelectedRecipe()
	if not self._selectedRecipe then
		warn("[DIYWorkbench] No recipe selected")
		return
	end
	
	if not self._selectedRecipe.canCraft then
		print("[DIYWorkbench] Cannot craft - missing materials")
		return
	end
	
	-- Send craft request to server
	local craftRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("CraftDIYItem")
	if craftRemote then
		craftRemote:FireServer(self._selectedRecipe.name)
		print("[DIYWorkbench] Crafting:", self._selectedRecipe.name)
	end
end

-- Show GUI
function DIYWorkbenchGUI:Show()
	self._gui.Enabled = true
	self:LoadRecipes()
	print("[DIYWorkbench] Opened")
end

-- Hide GUI
function DIYWorkbenchGUI:Hide()
	self._gui.Enabled = false
	print("[DIYWorkbench] Closed")
end

-- Toggle GUI
function DIYWorkbenchGUI:Toggle()
	if self._gui.Enabled then
		self:Hide()
	else
		self:Show()
	end
end

return DIYWorkbenchGUI

