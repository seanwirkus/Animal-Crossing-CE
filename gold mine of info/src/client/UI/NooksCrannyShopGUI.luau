-- Nook's Cranny Shop GUI - BULLETPROOF VERSION
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local NooksCrannyShopGUI = {}
NooksCrannyShopGUI.__index = NooksCrannyShopGUI

-- Track singleton instance
local _instance = nil

function NooksCrannyShopGUI.new()
	-- Return existing instance if already created
	if _instance then
		print("[NooksCranny] ⚠️  Returning existing Shop GUI instance")
		return _instance
	end
	
	local self = setmetatable({}, NooksCrannyShopGUI)
	
	self._gui = nil
	self._visible = false
	self._initialized = false
	
	self:_createGUI()
	
	_instance = self
	print("[NooksCranny] ✅ Shop GUI created (singleton instance)")
	return self
end

-- Helper: Create tooltip
local function createTooltip(parent, text)
	local tooltip = Instance.new("TextLabel")
	tooltip.Name = "Tooltip"
	tooltip.Size = UDim2.new(0, 200, 0, 50)
	tooltip.Position = UDim2.new(0.5, -100, -0.15, 0)
	tooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	tooltip.BackgroundTransparency = 0.2
	tooltip.BorderSizePixel = 1
	tooltip.BorderColor3 = Color3.fromRGB(255, 255, 255)
	tooltip.Text = text
	tooltip.TextSize = 12
	tooltip.Font = Enum.Font.GothamMedium
	tooltip.TextColor3 = Color3.new(1, 1, 1)
	tooltip.TextWrapped = true
	tooltip.Visible = false
	tooltip.ZIndex = 100
	tooltip.Parent = parent
	
	return tooltip
end

-- Helper: Add hover tooltip
local function addHoverTooltip(element, tooltipText)
	local tooltip = createTooltip(element, tooltipText)
	
	element.MouseEnter:Connect(function()
		tooltip.Visible = true
	end)
	
	element.MouseLeave:Connect(function()
		tooltip.Visible = false
	end)
end

-- Create simple rectangle GUI
function NooksCrannyShopGUI:_createGUI()
	if self._initialized then return end
	self._initialized = true
	
	-- Screen GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NooksCrannyShopGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = player:WaitForChild("PlayerGui")
	
	self._gui = screenGui
	
	-- Main container (simple rectangle)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0.4, 0, 0.6, 0)
	container.Position = UDim2.new(0.05, 0, 0.2, 0)
	container.BackgroundColor3 = Color3.fromRGB(250, 245, 235)
	container.BorderSizePixel = 2
	container.BorderColor3 = Color3.fromRGB(139, 90, 43)
	container.Parent = screenGui
	
	-- Add container tooltip
	addHoverTooltip(container, "Nook's Cranny Shop - Browse and buy items!")
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(150, 180, 140)
	title.BorderSizePixel = 0
	title.Text = "🏪 Nook's Cranny"
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = container
	
	-- Add title tooltip
	addHoverTooltip(title, "Shop Owner: Tom Nook")
	
	-- Info text
	local infoText = Instance.new("TextLabel")
	infoText.Name = "InfoText"
	infoText.Size = UDim2.new(1, -20, 0.7, 0)
	infoText.Position = UDim2.new(0, 10, 0.15, 10)
	infoText.BackgroundTransparency = 1
	infoText.Text = "Welcome to Nook's Cranny!\n\n💰 Buy and sell items\n🛍️ Fresh stock daily\n📦 Coming soon: Full inventory browser\n\nPress E to close"
	infoText.TextSize = 16
	infoText.Font = Enum.Font.Gotham
	infoText.TextColor3 = Color3.fromRGB(60, 50, 40)
	infoText.TextWrapped = true
	infoText.Parent = container
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(1, 0, 0.15, 0)
	closeButton.Position = UDim2.new(0, 0, 0.85, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "Close"
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Parent = container
	
	-- Add close button tooltip
	addHoverTooltip(closeButton, "Close the shop (or press E)")
	
	-- Close button click
	closeButton.MouseButton1Click:Connect(function()
		self:Toggle()
	end)
	
	print("[NooksCranny] ✅ Shop GUI initialized with tooltips")
end

-- Toggle visibility
function NooksCrannyShopGUI:Toggle()
	if not self._gui then 
		print("[NooksCranny] ⚠️  GUI not initialized!")
		return 
	end
	
	self._visible = not self._visible
	self._gui.Enabled = self._visible
	
	if self._visible then
		print("[NooksCranny] ✅ Shop opened (Press S to close)")
	else
		print("[NooksCranny] ✅ Shop closed")
	end
end

-- Show GUI
function NooksCrannyShopGUI:Show()
	if not self._visible then
		self:Toggle()
	end
end

-- Hide GUI
function NooksCrannyShopGUI:Hide()
	if self._visible then
		self:Toggle()
	end
end

return NooksCrannyShopGUI

