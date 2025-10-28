--[[
	ToolSelector - Simple tool selection system
	Basic tool selector for the game
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ToolSelector = {}
ToolSelector.__index = ToolSelector

function ToolSelector.new()
	local self = setmetatable({}, ToolSelector)
	self._gui = nil
	self._connections = {}
	
	self:_createGUI()
	
	return self
end

function ToolSelector:_createGUI()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Create tool selector GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ToolSelectorGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Tool bar at bottom
	local toolBar = Instance.new("Frame")
	toolBar.Size = UDim2.new(0, 300, 0, 60)
	toolBar.Position = UDim2.new(0.5, -150, 1, -80)
	toolBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	toolBar.BackgroundTransparency = 0.3
	toolBar.BorderSizePixel = 0
	toolBar.Parent = screenGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toolBar
	
	-- Tool buttons
	local tools = {"🪓 Axe", "🪣 Watering Can", "🎣 Fishing Rod", "🕸️ Net", "⛏️ Shovel"}
	
	for i, tool in ipairs(tools) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 50, 1, -10)
		button.Position = UDim2.new(0, 10 + (i-1) * 55, 0, 5)
		button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		button.Text = tool
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Font = Enum.Font.Gotham
		button.Parent = toolBar
		
		-- Add corner rounding
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 4)
		buttonCorner.Parent = button
		
		-- Button click handler
		button.MouseButton1Click:Connect(function()
			print("Selected tool:", tool)
		end)
	end
	
	self._gui = screenGui
end

function ToolSelector:Destroy()
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

return ToolSelector