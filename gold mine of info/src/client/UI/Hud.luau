--[[
	Hud - Simple HUD system for the game
	Basic HUD with health, money, and basic info
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Hud = {}
Hud.__index = Hud

function Hud.new()
	local self = setmetatable({}, Hud)
	self._gui = nil
	self._connections = {}
	
	self:_createGUI()

	return self
end

function Hud:_createGUI()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Create HUD GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HudGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Top bar for money and info
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 60)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	topBar.BackgroundTransparency = 0.3
	topBar.BorderSizePixel = 0
	topBar.Parent = screenGui
	
	-- Bells display
	local bellsLabel = Instance.new("TextLabel")
	bellsLabel.Size = UDim2.new(0, 100, 1, 0)
	bellsLabel.Position = UDim2.new(0, 10, 0, 0)
	bellsLabel.BackgroundTransparency = 1
	bellsLabel.Text = "🔔 1000"
	bellsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bellsLabel.TextScaled = true
	bellsLabel.Font = Enum.Font.GothamBold
	bellsLabel.Parent = topBar
	
	-- Miles display
	local milesLabel = Instance.new("TextLabel")
	milesLabel.Size = UDim2.new(0, 100, 1, 0)
	milesLabel.Position = UDim2.new(0, 120, 0, 0)
	milesLabel.BackgroundTransparency = 1
	milesLabel.Text = "✈️ 500"
	milesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	milesLabel.TextScaled = true
	milesLabel.Font = Enum.Font.GothamBold
	milesLabel.Parent = topBar
	
	-- Time display
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(0, 150, 1, 0)
	timeLabel.Position = UDim2.new(1, -160, 0, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "🕐 10:00 AM"
	timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timeLabel.TextScaled = true
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.Parent = topBar
	
	self._gui = screenGui
end

function Hud:Destroy()
	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end
	
	for _, connection in ipairs(self._connections) do
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(self._connections)
end

return Hud