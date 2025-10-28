--[[
	Onboarding - Simple onboarding system
	Creates a basic onboarding GUI for new players
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Onboarding = {}
Onboarding.__index = Onboarding

function Onboarding.new(payload, onComplete)
	local self = setmetatable({}, Onboarding)
	self._payload = payload
	self._onComplete = onComplete
	self._gui = nil
	
	self:_createGUI()
	
	return self
end

function Onboarding:_createGUI()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Create simple onboarding GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OnboardingGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 400, 0, 300)
	frame.Position = UDim2.new(0.5, -200, 0.5, -150)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Welcome to Your Island!"
	title.TextColor3 = Color3.fromRGB(0, 0, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	
	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -20, 0, 100)
	desc.Position = UDim2.new(0, 10, 0, 60)
	desc.BackgroundTransparency = 1
	desc.Text = "Welcome to your new island! I'm Tom Nook, and I'll be helping you get settled. Let's start by choosing your perfect island paradise!"
	desc.TextColor3 = Color3.fromRGB(0, 0, 0)
	desc.TextWrapped = true
	desc.Font = Enum.Font.Gotham
	desc.Parent = frame
	
	-- Continue button
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 120, 0, 40)
	button.Position = UDim2.new(0.5, -60, 1, -60)
	button.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	button.Text = "Continue"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.Parent = frame
	
	-- Add corner rounding to button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button
	
	-- Button click handler
	button.MouseButton1Click:Connect(function()
		if self._onComplete then
			self._onComplete()
		end
		self:Destroy()
	end)
	
	self._gui = screenGui
	
	-- Auto-complete after 5 seconds
	task.delay(5, function()
		if self._gui and self._gui.Parent then
			if self._onComplete then
				self._onComplete()
			end
			self:Destroy()
		end
	end)
end

function Onboarding:Destroy()
	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end
end

return Onboarding