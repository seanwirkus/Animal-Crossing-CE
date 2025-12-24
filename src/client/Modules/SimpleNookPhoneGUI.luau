--[[
	SimpleNookPhoneGUI.luau
	A clean, simple NookPhone interface

	Features:
	- Compact phone design (smaller than before)
	- Simple 2x3 app grid
	- Quick access to core features
	- Smooth animations
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SimpleNookPhoneGUI = {}
SimpleNookPhoneGUI.__index = SimpleNookPhoneGUI

-- Smaller, more compact design
local PHONE_SIZE = UDim2.fromOffset(280, 420)
local APP_SIZE = UDim2.fromOffset(80, 80)

-- Core apps only - keep it simple
local APPS = {
	{ name = "Map", icon = "🗺️", color = Color3.fromRGB(100, 180, 100) },
	{ name = "Quests", icon = "📋", color = Color3.fromRGB(255, 180, 80) },
	{ name = "Shop", icon = "🛒", color = Color3.fromRGB(180, 140, 255) },
	{ name = "Crafting", icon = "🔨", color = Color3.fromRGB(200, 150, 100) },
	{ name = "Settings", icon = "⚙️", color = Color3.fromRGB(160, 160, 160) },
	{ name = "Close", icon = "✕", color = Color3.fromRGB(200, 100, 100) },
}

local _instance = nil

function SimpleNookPhoneGUI.new()
	if _instance then
		return _instance
	end

	local self = setmetatable({}, SimpleNookPhoneGUI)

	self.isOpen = false
	self.screenGui = nil
	self.phoneFrame = nil
	self.appCallbacks = {}

	self:_createGUI()
	self:_setupDefaultCallbacks()

	_instance = self
	print("[SimpleNookPhone] ✅ Initialized")
	return self
end

function SimpleNookPhoneGUI:_createGUI()
	-- Remove old GUI if exists
	local oldGui = playerGui:FindFirstChild("SimpleNookPhoneGUI")
	if oldGui then
		oldGui:Destroy()
	end

	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SimpleNookPhoneGUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	self.screenGui = screenGui

	-- Phone frame
	local phoneFrame = Instance.new("Frame")
	phoneFrame.Name = "PhoneFrame"
	phoneFrame.Size = PHONE_SIZE
	phoneFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	phoneFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	phoneFrame.BackgroundColor3 = Color3.fromRGB(250, 245, 230) -- Warm cream
	phoneFrame.BorderSizePixel = 0
	phoneFrame.Visible = false
	phoneFrame.Parent = screenGui

	-- Phone border
	local phoneStroke = Instance.new("UIStroke")
	phoneStroke.Color = Color3.fromRGB(139, 90, 43)
	phoneStroke.Thickness = 3
	phoneStroke.Parent = phoneFrame

	local phoneCorner = Instance.new("UICorner")
	phoneCorner.CornerRadius = UDim.new(0, 24)
	phoneCorner.Parent = phoneFrame

	self.phoneFrame = phoneFrame

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = Color3.fromRGB(101, 180, 73)
	header.BorderSizePixel = 0
	header.Parent = phoneFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 24)
	headerCorner.Parent = header

	-- Fix header bottom corners
	local headerFix = Instance.new("Frame")
	headerFix.Size = UDim2.new(1, 0, 0, 24)
	headerFix.Position = UDim2.new(0, 0, 1, -24)
	headerFix.BackgroundColor3 = header.BackgroundColor3
	headerFix.BorderSizePixel = 0
	headerFix.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = "📱 NookPhone"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.Parent = header

	-- App grid container
	local gridContainer = Instance.new("Frame")
	gridContainer.Name = "GridContainer"
	gridContainer.Size = UDim2.new(1, -30, 1, -80)
	gridContainer.Position = UDim2.fromOffset(15, 60)
	gridContainer.BackgroundTransparency = 1
	gridContainer.Parent = phoneFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = APP_SIZE
	gridLayout.CellPadding = UDim2.fromOffset(12, 12)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = gridContainer

	-- Create app buttons
	for i, app in ipairs(APPS) do
		self:_createAppButton(gridContainer, app, i)
	end

	-- Time display at bottom
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, 0, 0, 25)
	timeLabel.Position = UDim2.new(0, 0, 1, -30)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "🕐 " .. os.date("%I:%M %p")
	timeLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextSize = 14
	timeLabel.Parent = phoneFrame

	-- Update time every minute
	task.spawn(function()
		while self.screenGui and self.screenGui.Parent do
			task.wait(60)
			if timeLabel and timeLabel.Parent then
				timeLabel.Text = "🕐 " .. os.date("%I:%M %p")
			end
		end
	end)
end

function SimpleNookPhoneGUI:_createAppButton(parent, appData, index)
	local button = Instance.new("TextButton")
	button.Name = appData.name
	button.LayoutOrder = index
	button.BackgroundColor3 = appData.color
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = parent

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 12)
	buttonCorner.Parent = button

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.55, 0)
	icon.Position = UDim2.fromOffset(0, 5)
	icon.BackgroundTransparency = 1
	icon.Text = appData.icon
	icon.TextSize = 28
	icon.Parent = button

	-- Label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.35, 0)
	label.Position = UDim2.new(0, 0, 0.6, 0)
	label.BackgroundTransparency = 1
	label.Text = appData.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextStrokeTransparency = 0.7
	label.Parent = button

	-- Hover effect
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = appData.color:Lerp(Color3.new(1, 1, 1), 0.3),
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = appData.color,
		}):Play()
	end)

	-- Click
	button.MouseButton1Click:Connect(function()
		self:_onAppClick(appData.name)
	end)
end

function SimpleNookPhoneGUI:_setupDefaultCallbacks()
	-- Default app callbacks
	self.appCallbacks["Close"] = function()
		self:Hide()
	end

	self.appCallbacks["Map"] = function()
		self:Hide()
		-- Try to open minimap directly
		local success, Minimap = pcall(function()
			return require(script.Parent.Minimap)
		end)
		if success and Minimap and Minimap.toggle then
			Minimap:toggle()
		end
	end

	self.appCallbacks["Quests"] = function()
		self:Hide()
		local GUIManager = self:_getGUIManager()
		if GUIManager then
			GUIManager:toggleGUI("QuestGUI")
		end
	end

	self.appCallbacks["Shop"] = function()
		self:Hide()
		local GUIManager = self:_getGUIManager()
		if GUIManager then
			GUIManager:toggleGUI("nookShopping")
		end
	end

	self.appCallbacks["Crafting"] = function()
		self:Hide()
		local GUIManager = self:_getGUIManager()
		if GUIManager then
			GUIManager:toggleGUI("crafting")
		end
	end

	self.appCallbacks["Settings"] = function()
		self:Hide()
		-- Access settings via SettingsController
		local success, SettingsController = pcall(function()
			return require(script.Parent.SettingsController)
		end)
		if success and SettingsController and SettingsController.toggle then
			SettingsController.toggle()
		end
	end
end

function SimpleNookPhoneGUI:_getGUIManager()
	-- Get the global GUIManager instance
	return _G.GUIManager
end

function SimpleNookPhoneGUI:_onAppClick(appName)
	print("[SimpleNookPhone] 📱 App: " .. appName)

	local callback = self.appCallbacks[appName]
	if callback then
		callback()
	end
end

function SimpleNookPhoneGUI:setAppCallback(appName, callback)
	self.appCallbacks[appName] = callback
end

function SimpleNookPhoneGUI:Show()
	if self.isOpen then
		return
	end

	self.isOpen = true
	self.phoneFrame.Visible = true

	-- Slide up animation
	self.phoneFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
	TweenService:Create(self.phoneFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()

	print("[SimpleNookPhone] 📱 Opened")
end

function SimpleNookPhoneGUI:Hide()
	if not self.isOpen then
		return
	end

	self.isOpen = false

	local tween = TweenService:Create(self.phoneFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.5, 0),
	})

	tween.Completed:Connect(function()
		self.phoneFrame.Visible = false
	end)

	tween:Play()
	print("[SimpleNookPhone] 📱 Closed")
end

function SimpleNookPhoneGUI:Toggle()
	if self.isOpen then
		self:Hide()
	else
		self:Show()
	end
end

function SimpleNookPhoneGUI:IsOpen()
	return self.isOpen
end

-- GUIManager compatibility
function SimpleNookPhoneGUI:show()
	self:Show()
end

function SimpleNookPhoneGUI:hide()
	self:Hide()
end

function SimpleNookPhoneGUI:toggle()
	self:Toggle()
end

return SimpleNookPhoneGUI
