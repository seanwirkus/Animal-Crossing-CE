--[[
	TravelGUI - Dodo Airlines Travel Interface
	Allows players to fly to their island, visit friends, or return to hub
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TravelGUI = {}
TravelGUI.__index = TravelGUI

local COLORS = {
	BG = Color3.fromRGB(135, 206, 235),  -- Sky blue
	PANEL = Color3.fromRGB(255, 250, 240),  -- Cream
	ACCENT = Color3.fromRGB(64, 164, 223),  -- Bright blue (airline theme)
	TEXT = Color3.fromRGB(100, 100, 100),  -- Dark gray
	BUTTON_HOVER = Color3.fromRGB(84, 184, 243),  -- Lighter blue on hover
}

function TravelGUI.new()
	local self = setmetatable({}, TravelGUI)
	self._player = Players.LocalPlayer
	self._playerGui = self._player:WaitForChild("PlayerGui")
	self._remotes = ReplicatedStorage:WaitForChild("Remotes")
	
	self:Create()
	return self
end

--[[
	Create the travel GUI
]]
function TravelGUI:Create()
	-- Main screen GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TravelGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true  -- Use full screen
	screenGui.Parent = self._playerGui
	
	-- Semi-transparent backdrop
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 1
	backdrop.Parent = screenGui
	
	-- Close on backdrop click
	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:Close()
		end
	end)
	
	-- Main panel
	local panel = Instance.new("Frame")
	panel.Name = "TravelPanel"
	panel.Size = UDim2.new(0, 400, 0, 450)
	panel.Position = UDim2.new(0.5, -200, 0.5, -225)
	panel.BackgroundColor3 = COLORS.PANEL
	panel.BorderSizePixel = 0
	panel.ZIndex = 2
	panel.Parent = screenGui
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = panel
	
	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 70)
	titleBar.BackgroundColor3 = COLORS.ACCENT
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 3
	titleBar.Parent = panel
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar
	
	-- Title text
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -70, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "✈️ Dodo Airlines"
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 4
	title.Parent = titleBar
	
	-- Close button (X in title bar)
	local closeButtonTop = Instance.new("TextButton")
	closeButtonTop.Name = "CloseButtonTop"
	closeButtonTop.Size = UDim2.new(0, 50, 0, 50)
	closeButtonTop.Position = UDim2.new(1, -60, 0, 10)
	closeButtonTop.BackgroundColor3 = Color3.fromRGB(244, 67, 54)  -- Red
	closeButtonTop.BorderSizePixel = 0
	closeButtonTop.Text = "✕"
	closeButtonTop.TextSize = 28
	closeButtonTop.Font = Enum.Font.GothamBold
	closeButtonTop.TextColor3 = Color3.new(1, 1, 1)
	closeButtonTop.ZIndex = 5
	closeButtonTop.Parent = titleBar
	
	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeButtonTop
	
	-- Close button hover effect
	closeButtonTop.MouseEnter:Connect(function()
		TweenService:Create(closeButtonTop, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(234, 57, 44)
		}):Play()
	end)
	
	closeButtonTop.MouseLeave:Connect(function()
		TweenService:Create(closeButtonTop, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(244, 67, 54)
		}):Play()
	end)
	
	closeButtonTop.MouseButton1Click:Connect(function()
		self:Close()
	end)
	
	-- Content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -40, 1, -110)
	content.Position = UDim2.new(0, 20, 0, 80)
	content.BackgroundTransparency = 1
	content.ZIndex = 3
	content.Parent = panel
	
	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0, 30)
	subtitle.Position = UDim2.new(0, 0, 0, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Where would you like to go?"
	subtitle.TextSize = 18
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextColor3 = COLORS.TEXT
	subtitle.ZIndex = 4
	subtitle.Parent = content
	
	-- Fly to My Island button
	local myIslandBtn = self:_createButton("MyIslandButton", "🏝️ Fly to My Island", UDim2.new(0, 0, 0, 50), content)
	myIslandBtn.MouseButton1Click:Connect(function()
		self:_onFlyToMyIsland()
	end)
	
	-- Visit Friend's Island button
	local friendIslandBtn = self:_createButton("FriendIslandButton", "🌐 Visit Friend's Island", UDim2.new(0, 0, 0, 130), content)
	friendIslandBtn.MouseButton1Click:Connect(function()
		self:_onVisitFriend()
	end)
	
	-- Return to Hub button
	local hubBtn = self:_createButton("HubButton", "🏠 Return to Hub", UDim2.new(0, 0, 0, 210), content)
	hubBtn.MouseButton1Click:Connect(function()
		self:_onReturnToHub()
	end)
	
	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(1, -40, 0, 50)
	closeBtn.Position = UDim2.new(0, 20, 0, 290)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "Close"
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = COLORS.TEXT
	closeBtn.ZIndex = 4
	closeBtn.Parent = content
	
	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 12)
	closeBtnCorner.Parent = closeBtn
	
	closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end)
	
	self._screenGui = screenGui
	self._panel = panel
	
	-- Animate in
	panel.Position = UDim2.new(0.5, -200, 0.5, -225)
	panel.Size = UDim2.new(0, 0, 0, 0)
	
	local tween = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400, 0, 450),
		Position = UDim2.new(0.5, -200, 0.5, -225)
	})
	tween:Play()
end

--[[
	Create a styled button
]]
function TravelGUI:_createButton(name, text, position, parent)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 60)
	button.Position = position
	button.BackgroundColor3 = COLORS.ACCENT
	button.BorderSizePixel = 0
	button.Text = text
	button.TextSize = 22
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.ZIndex = 4
	button.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.BUTTON_HOVER
		}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.ACCENT
		}):Play()
	end)
	
	return button
end

--[[
	Handle flying to player's own island
]]
function TravelGUI:_onFlyToMyIsland()
	print("[TravelGUI] Flying to player's island")
	
	-- Show loading screen
	self:_showFlyingAnimation(self._player.UserId, "your island")
	
	-- Fire remote to server
	local teleportRemote = self._remotes:FindFirstChild("TeleportToIsland")
	if teleportRemote then
		teleportRemote:FireServer(self._player.UserId)
	end
	
	-- Close GUI
	task.delay(2, function()
		self:Close()
	end)
end

--[[
	Handle visiting a friend's island
]]
function TravelGUI:_onVisitFriend()
	print("[TravelGUI] Visit friend feature - TODO")
	
	-- TODO: Implement friend selection UI
	-- For now, just show a message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, 0, 0, 40)
	messageLabel.Position = UDim2.new(0, 0, 1, -40)
	messageLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
	messageLabel.BorderSizePixel = 0
	messageLabel.Text = "Coming Soon! 🚧"
	messageLabel.TextSize = 18
	messageLabel.Font = Enum.Font.GothamBold
	messageLabel.TextColor3 = COLORS.TEXT
	messageLabel.ZIndex = 5
	messageLabel.Parent = self._panel
	
	task.delay(2, function()
		if messageLabel then
			messageLabel:Destroy()
		end
	end)
end

--[[
	Handle returning to hub
]]
function TravelGUI:_onReturnToHub()
	print("[TravelGUI] Returning to hub")
	
	-- Show loading screen
	self:_showFlyingAnimation(nil, "the hub")
	
	-- Fire remote to server
	local hubRemote = self._remotes:FindFirstChild("TeleportToHub")
	if hubRemote then
		hubRemote:FireServer()
	end
	
	-- Close GUI
	task.delay(2, function()
		self:Close()
	end)
end

--[[
	Show flying animation
]]
function TravelGUI:_showFlyingAnimation(targetUserId, destinationName)
	local flyScreen = Instance.new("ScreenGui")
	flyScreen.Name = "FlyingScreen"
	flyScreen.ResetOnSpawn = false
	flyScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	flyScreen.Parent = self._playerGui
	
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = COLORS.BG
	bg.BorderSizePixel = 0
	bg.ZIndex = 10
	bg.Parent = flyScreen
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.3, 0)
	label.Position = UDim2.new(0, 0, 0.35, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("✈️\n\nFlying to %s...\n\n🏝️", destinationName)
	label.TextSize = 60
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.ZIndex = 11
	label.Parent = flyScreen
	
	-- Auto-remove after 3 seconds
	task.delay(3, function()
		if flyScreen then
			flyScreen:Destroy()
		end
	end)
end

--[[
	Close the travel GUI
]]
function TravelGUI:Close()
	if self._screenGui then
		local tween = TweenService:Create(self._panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		})
		tween:Play()
		tween.Completed:Connect(function()
			if self._screenGui then
				self._screenGui:Destroy()
			end
		end)
	end
end

return TravelGUI

