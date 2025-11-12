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

-- UI Colors (Animal Crossing themed)
local COLORS = {
	BG_PRIMARY = Color3.fromRGB(250, 245, 235), -- Cream
	BG_SECONDARY = Color3.fromRGB(255, 255, 255), -- White
	BG_RECIPE_ITEM = Color3.fromRGB(245, 240, 230),
	ACCENT_ORANGE = Color3.fromRGB(255, 160, 100),
	ACCENT_BROWN = Color3.fromRGB(139, 90, 43),
	TEXT_DARK = Color3.fromRGB(60, 50, 40),
	TEXT_LIGHT = Color3.fromRGB(255, 255, 255),
	CAN_CRAFT = Color3.fromRGB(100, 200, 100),
	CANNOT_CRAFT = Color3.fromRGB(200, 100, 100),
	BORDER = Color3.fromRGB(210, 180, 140),
}

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
	
	-- Get all craftable items from ItemDataFetcher
	local allItems = ItemDataFetcher.getAllItems()
	
	for itemId, itemData in pairs(allItems) do
		local recipe = ItemDataFetcher.getCraftingRecipe(itemId)
		
		if recipe and recipe.materials and #recipe.materials > 0 then
			table.insert(self._allRecipes, {
				itemId = itemId,
				name = itemData.name or itemId,
				recipe = recipe,
				spriteIndex = itemData.spriteIndex or 0,
			})
		end
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
			if action == "Sync" then
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
				self._playerInventory[slot.itemId] = (self._playerInventory[slot.itemId] or 0) + (slot.quantity or 1)
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
	
	-- Main frame (centered, 80% screen size)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
	mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
	mainFrame.BackgroundColor3 = COLORS.BG_PRIMARY
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame
	
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
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = COLORS.ACCENT_BROWN
	titleBar.BorderSizePixel = 0
	titleBar.Parent = self._mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar
	
	-- Title fix: Cover bottom corners
	local titleFix = Instance.new("Frame")
	titleFix.Size = UDim2.new(1, 0, 0, 12)
	titleFix.Position = UDim2.new(0, 0, 1, -12)
	titleFix.BackgroundColor3 = COLORS.ACCENT_BROWN
	titleFix.BorderSizePixel = 0
	titleFix.Parent = titleBar
	
	-- Title text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = COLORS.TEXT_LIGHT
	titleLabel.Text = "🔨 DIY Crafting"
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = COLORS.ACCENT_ORANGE
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 20
	closeButton.TextColor3 = COLORS.TEXT_LIGHT
	closeButton.Text = "✕"
	closeButton.Parent = titleBar
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		self:close()
	end)
end

function CraftingGUI:createRecipeListPanel()
	local panel = Instance.new("Frame")
	panel.Name = "RecipeListPanel"
	panel.Size = UDim2.new(0.35, -10, 1, -70)
	panel.Position = UDim2.new(0, 10, 0, 60)
	panel.BackgroundColor3 = COLORS.BG_SECONDARY
	panel.BorderSizePixel = 0
	panel.Parent = self._mainFrame
	
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 8)
	panelCorner.Parent = panel
	
	-- Scrolling frame for recipes
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "RecipeScroll"
	scrollFrame.Size = UDim2.new(1, -10, 1, -10)
	scrollFrame.Position = UDim2.new(0, 5, 0, 5)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = panel
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame
	
	self._recipeListFrame = scrollFrame
	
	-- Populate recipes
	self:refreshRecipeList()
end

function CraftingGUI:refreshRecipeList()
	-- Clear existing
	for _, child in ipairs(self._recipeListFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Add recipe items
	for i, recipeData in ipairs(self._allRecipes) do
		self:createRecipeItem(recipeData, i)
	end
	
	-- Update canvas size
	local listLayout = self._recipeListFrame:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		self._recipeListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end
end

function CraftingGUI:createRecipeItem(recipeData, index)
	local canCraft = self:canCraftRecipe(recipeData.recipe)
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "RecipeItem" .. index
	itemFrame.Size = UDim2.new(1, -10, 0, 60)
	itemFrame.BackgroundColor3 = COLORS.BG_RECIPE_ITEM
	itemFrame.BorderSizePixel = 0
	itemFrame.Parent = self._recipeListFrame
	
	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 6)
	itemCorner.Parent = itemFrame
	
	-- Sprite icon
	local iconLabel = Instance.new("ImageLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 50, 0, 50)
	iconLabel.Position = UDim2.new(0, 5, 0, 5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Image = SpriteConfig.SPRITE_SHEET_ID
	iconLabel.ImageRectSize = Vector2.new(SpriteConfig.ITEM_SIZE, SpriteConfig.ITEM_SIZE)
	
	local row, col = SpriteConfig.getSpritePosition(recipeData.spriteIndex)
	iconLabel.ImageRectOffset = Vector2.new(col * SpriteConfig.ITEM_SIZE, row * SpriteConfig.ITEM_SIZE)
	iconLabel.Parent = itemFrame
	
	-- Recipe name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -70, 0, 30)
	nameLabel.Position = UDim2.new(0, 60, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = COLORS.TEXT_DARK
	nameLabel.Text = recipeData.name
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = itemFrame
	
	-- Material count
	local materialCount = #(recipeData.recipe.materials or {})
	local materialLabel = Instance.new("TextLabel")
	materialLabel.Name = "Materials"
	materialLabel.Size = UDim2.new(1, -70, 0, 20)
	materialLabel.Position = UDim2.new(0, 60, 0, 35)
	materialLabel.BackgroundTransparency = 1
	materialLabel.Font = Enum.Font.Gotham
	materialLabel.TextSize = 12
	materialLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
	materialLabel.Text = string.format("📦 %d materials", materialCount)
	materialLabel.TextXAlignment = Enum.TextXAlignment.Left
	materialLabel.Parent = itemFrame
	
	-- Can craft indicator
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 8, 1, -10)
	indicator.Position = UDim2.new(1, -12, 0, 5)
	indicator.BackgroundColor3 = canCraft and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
	indicator.BorderSizePixel = 0
	indicator.Parent = itemFrame
	
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = indicator
	
	-- Click to select
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = itemFrame
	
	button.MouseButton1Click:Connect(function()
		self:selectRecipe(recipeData)
	end)
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		itemFrame.BackgroundColor3 = COLORS.ACCENT_ORANGE:Lerp(Color3.new(1, 1, 1), 0.7)
	end)
	
	button.MouseLeave:Connect(function()
		itemFrame.BackgroundColor3 = COLORS.BG_RECIPE_ITEM
	end)
end

function CraftingGUI:createDetailsPanel()
	local panel = Instance.new("Frame")
	panel.Name = "DetailsPanel"
	panel.Size = UDim2.new(0.65, -20, 1, -70)
	panel.Position = UDim2.new(0.35, 10, 0, 60)
	panel.BackgroundColor3 = COLORS.BG_SECONDARY
	panel.BorderSizePixel = 0
	panel.Parent = self._mainFrame
	
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 8)
	panelCorner.Parent = panel
	
	self._detailsFrame = panel
	
	-- Placeholder text
	local placeholder = Instance.new("TextLabel")
	placeholder.Name = "Placeholder"
	placeholder.Size = UDim2.new(1, 0, 1, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.Font = Enum.Font.Gotham
	placeholder.TextSize = 18
	placeholder.TextColor3 = Color3.fromRGB(150, 150, 150)
	placeholder.Text = "Select a recipe to view details"
	placeholder.Parent = panel
end

function CraftingGUI:selectRecipe(recipeData)
	self._selectedRecipe = recipeData
	
	-- Clear details panel
	for _, child in ipairs(self._detailsFrame:GetChildren()) do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end
	
	-- Recipe title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "RecipeTitle"
	titleLabel.Size = UDim2.new(1, -20, 0, 40)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = COLORS.TEXT_DARK
	titleLabel.Text = recipeData.name
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = self._detailsFrame
	
	-- Large recipe icon
	local iconLabel = Instance.new("ImageLabel")
	iconLabel.Name = "LargeIcon"
	iconLabel.Size = UDim2.new(0, 100, 0, 100)
	iconLabel.Position = UDim2.new(0, 10, 0, 60)
	iconLabel.BackgroundColor3 = COLORS.BG_RECIPE_ITEM
	iconLabel.Image = SpriteConfig.SPRITE_SHEET_ID
	iconLabel.ImageRectSize = Vector2.new(SpriteConfig.ITEM_SIZE, SpriteConfig.ITEM_SIZE)
	iconLabel.ScaleType = Enum.ScaleType.Fit
	
	local row, col = SpriteConfig.getSpritePosition(recipeData.spriteIndex)
	iconLabel.ImageRectOffset = Vector2.new(col * SpriteConfig.ITEM_SIZE, row * SpriteConfig.ITEM_SIZE)
	iconLabel.Parent = self._detailsFrame
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconLabel
	
	-- Materials section
	local materialsLabel = Instance.new("TextLabel")
	materialsLabel.Name = "MaterialsLabel"
	materialsLabel.Size = UDim2.new(1, -20, 0, 30)
	materialsLabel.Position = UDim2.new(0, 10, 0, 180)
	materialsLabel.BackgroundTransparency = 1
	materialsLabel.Font = Enum.Font.GothamBold
	materialsLabel.TextSize = 18
	materialsLabel.TextColor3 = COLORS.TEXT_DARK
	materialsLabel.Text = "📦 Materials Required:"
	materialsLabel.TextXAlignment = Enum.TextXAlignment.Left
	materialsLabel.Parent = self._detailsFrame
	
	-- Materials list
	local yOffset = 220
	local recipe = recipeData.recipe
	
	for i, material in ipairs(recipe.materials or {}) do
		local materialId = material.itemId or material[1]
		local required = material.quantity or material[2] or 1
		local owned = self._playerInventory[materialId] or 0
		local hasEnough = owned >= required
		
		local materialItem = ItemDataFetcher.getItemById(materialId)
		local materialName = materialItem and materialItem.name or materialId
		local materialSprite = materialItem and materialItem.spriteIndex or 0
		
		-- Material frame
		local matFrame = Instance.new("Frame")
		matFrame.Name = "Material" .. i
		matFrame.Size = UDim2.new(1, -20, 0, 50)
		matFrame.Position = UDim2.new(0, 10, 0, yOffset)
		matFrame.BackgroundColor3 = COLORS.BG_RECIPE_ITEM
		matFrame.BorderSizePixel = 0
		matFrame.Parent = self._detailsFrame
		
		local matCorner = Instance.new("UICorner")
		matCorner.CornerRadius = UDim.new(0, 6)
		matCorner.Parent = matFrame
		
		-- Material icon
		local matIcon = Instance.new("ImageLabel")
		matIcon.Size = UDim2.new(0, 40, 0, 40)
		matIcon.Position = UDim2.new(0, 5, 0, 5)
		matIcon.BackgroundTransparency = 1
		matIcon.Image = SpriteConfig.SPRITE_SHEET_ID
		matIcon.ImageRectSize = Vector2.new(SpriteConfig.ITEM_SIZE, SpriteConfig.ITEM_SIZE)
		
		local matRow, matCol = SpriteConfig.getSpritePosition(materialSprite)
		matIcon.ImageRectOffset = Vector2.new(matCol * SpriteConfig.ITEM_SIZE, matRow * SpriteConfig.ITEM_SIZE)
		matIcon.Parent = matFrame
		
		-- Material name
		local matName = Instance.new("TextLabel")
		matName.Size = UDim2.new(1, -120, 0, 25)
		matName.Position = UDim2.new(0, 50, 0, 5)
		matName.BackgroundTransparency = 1
		matName.Font = Enum.Font.Gotham
		matName.TextSize = 14
		matName.TextColor3 = COLORS.TEXT_DARK
		matName.Text = materialName
		matName.TextXAlignment = Enum.TextXAlignment.Left
		matName.TextTruncate = Enum.TextTruncate.AtEnd
		matName.Parent = matFrame
		
		-- Quantity label
		local quantityLabel = Instance.new("TextLabel")
		quantityLabel.Size = UDim2.new(1, -50, 0, 20)
		quantityLabel.Position = UDim2.new(0, 50, 0, 25)
		quantityLabel.BackgroundTransparency = 1
		quantityLabel.Font = Enum.Font.Gotham
		quantityLabel.TextSize = 12
		quantityLabel.TextColor3 = hasEnough and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
		quantityLabel.Text = string.format("%d / %d", owned, required)
		quantityLabel.TextXAlignment = Enum.TextXAlignment.Left
		quantityLabel.Parent = matFrame
		
		yOffset = yOffset + 55
	end
	
	-- Craft button
	local canCraft = self:canCraftRecipe(recipe)
	
	local craftButton = Instance.new("TextButton")
	craftButton.Name = "CraftButton"
	craftButton.Size = UDim2.new(0, 200, 0, 50)
	craftButton.Position = UDim2.new(0.5, -100, 1, -60)
	craftButton.BackgroundColor3 = canCraft and COLORS.CAN_CRAFT or COLORS.CANNOT_CRAFT
	craftButton.BorderSizePixel = 0
	craftButton.Font = Enum.Font.GothamBold
	craftButton.TextSize = 20
	craftButton.TextColor3 = COLORS.TEXT_LIGHT
	craftButton.Text = canCraft and "✓ Craft" or "✗ Missing Materials"
	craftButton.Parent = self._detailsFrame
	
	local craftCorner = Instance.new("UICorner")
	craftCorner.CornerRadius = UDim.new(0, 8)
	craftCorner.Parent = craftButton
	
	if canCraft then
		craftButton.MouseButton1Click:Connect(function()
			self:craftItem(recipeData)
		end)
	end
end

function CraftingGUI:canCraftRecipe(recipe)
	for _, material in ipairs(recipe.materials or {}) do
		local materialId = material.itemId or material[1]
		local required = material.quantity or material[2] or 1
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
			quantity = 1
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
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.Escape and self._isOpen then
			self:close()
		end
	end)
end

function CraftingGUI:open()
	if self._isOpen then return end
	
	self._gui.Enabled = true
	self._isOpen = true
	
	-- Refresh recipe list
	self:refreshRecipeList()
	
	print("[CraftingGUI] Opened")
end

function CraftingGUI:close()
	if not self._isOpen then return end
	
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

