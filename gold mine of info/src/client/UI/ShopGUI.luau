--[[
	ShopGUI - Nook's Cranny Shop Interface
	Displays inventory for buying and selling items
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ShopGUI = {}
ShopGUI.__index = ShopGUI

local COLORS = {
	BG = Color3.fromRGB(200, 220, 180),  -- Light green
	PANEL = Color3.fromRGB(255, 250, 240),  -- Cream
	ACCENT = Color3.fromRGB(190, 167, 69),  -- Golden
	TEXT = Color3.fromRGB(100, 100, 100),  -- Dark gray
}

function ShopGUI.new(screenGui, shopType)
	local self = setmetatable({}, ShopGUI)
	self._screenGui = screenGui
	self._shopType = shopType or "nooks_cranny"
	self._player = Players.LocalPlayer
	self._playerGui = self._player:WaitForChild("PlayerGui")
	
	self:Create()
	return self
end

--[[
	Create the shop GUI
]]
function ShopGUI:Create()
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "ShopGUI"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = COLORS.BG
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = self._playerGui
	
	-- Semi-transparent backdrop
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = mainFrame
	
	-- Close on backdrop click
	backdrop.MouseButton1Click:Connect(function()
		self:Close()
	end)
	
	-- Shop panel
	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.Size = UDim2.new(0, 600, 0, 500)
	panel.Position = UDim2.new(0.5, -300, 0.5, -250)
	panel.BackgroundColor3 = COLORS.PANEL
	panel.BorderSizePixel = 0
	panel.Parent = mainFrame
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = panel
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 60)
	title.BackgroundColor3 = COLORS.ACCENT
	title.BorderSizePixel = 0
	title.Text = "🏪 Nook's Cranny"
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = panel
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = title
	
	-- Shop content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -90)
	content.Position = UDim2.new(0, 10, 0, 70)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Parent = panel
	
	-- Info text (placeholder for items)
	local infoText = Instance.new("TextLabel")
	infoText.Name = "Info"
	infoText.Size = UDim2.new(1, 0, 1, 0)
	infoText.BackgroundTransparency = 1
	infoText.Text = "🛒 Coming Soon!\n\nShop inventory will display here.\nBuy and sell items with Tom Nook!"
	infoText.TextSize = 20
	infoText.Font = Enum.Font.Gotham
	infoText.TextColor3 = COLORS.TEXT
	infoText.TextWrapped = true
	infoText.Parent = content
	
	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(1, -20, 0, 40)
	closeBtn.Position = UDim2.new(0, 10, 1, -50)
	closeBtn.BackgroundColor3 = COLORS.ACCENT
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "Close"
	closeBtn.TextSize = 18
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Parent = panel
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn
	
	closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end)
	
	self._mainFrame = mainFrame
	self._panel = panel
	
	-- Animate in
	panel.Position = UDim2.new(0.5, -300, 0.5, -250)
	panel.Size = UDim2.new(0, 0, 0, 0)
	
	local tween = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 600, 0, 500),
		Position = UDim2.new(0.5, -300, 0.5, -250)
	})
	tween:Play()
end

--[[
	Close the shop GUI
]]
function ShopGUI:Close()
	if self._mainFrame then
		local tween = TweenService:Create(self._panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		})
		tween:Play()
		tween.Completed:Connect(function()
			self._mainFrame:Destroy()
		end)
	end
end

return ShopGUI
