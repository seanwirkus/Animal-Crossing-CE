--[[
	SimpleComponentManager - Simple component system for Animal Crossing
	Creates and manages GUI components without complex dependencies
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Local = {}
local Shared = {}

-- Component references
local activeComponents = {}

function Local.CreateStatsGUI()
	-- Create stats GUI (based on your hi.rbxmx)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StatsGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	-- Main frame with golden styling
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 300, 0, 100)
	mainFrame.Position = UDim2.new(1, -320, 0, 20)
	mainFrame.BackgroundColor3 = Color3.fromRGB(0.745, 0.655, 0.271) -- Golden color
	mainFrame.BackgroundTransparency = 0
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame
	
	-- Add padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = mainFrame
	
	-- Bells display
	local bellsFrame = Instance.new("Frame")
	bellsFrame.Name = "BellsFrame"
	bellsFrame.Size = UDim2.new(0, 120, 1, 0)
	bellsFrame.Position = UDim2.new(0, 0, 0, 0)
	bellsFrame.BackgroundTransparency = 1
	bellsFrame.Parent = mainFrame
	
	local bellsIcon = Instance.new("TextLabel")
	bellsIcon.Name = "BellsIcon"
	bellsIcon.Size = UDim2.new(0, 30, 1, 0)
	bellsIcon.Position = UDim2.new(0, 0, 0, 0)
	bellsIcon.BackgroundTransparency = 1
	bellsIcon.Text = "🔔"
	bellsIcon.TextColor3 = Color3.fromRGB(255, 255, 0)
	bellsIcon.TextScaled = true
	bellsIcon.Font = Enum.Font.GothamBold
	bellsIcon.Parent = bellsFrame
	
	local bellsLabel = Instance.new("TextLabel")
	bellsLabel.Name = "BellsLabel"
	bellsLabel.Size = UDim2.new(1, -40, 1, 0)
	bellsLabel.Position = UDim2.new(0, 35, 0, 0)
	bellsLabel.BackgroundTransparency = 1
	bellsLabel.Text = "1,000"
	bellsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bellsLabel.TextScaled = true
	bellsLabel.Font = Enum.Font.GothamBold
	bellsLabel.TextXAlignment = Enum.TextXAlignment.Left
	bellsLabel.Parent = bellsFrame
	
	-- Miles display
	local milesFrame = Instance.new("Frame")
	milesFrame.Name = "MilesFrame"
	milesFrame.Size = UDim2.new(0, 120, 1, 0)
	milesFrame.Position = UDim2.new(0, 130, 0, 0)
	milesFrame.BackgroundTransparency = 1
	milesFrame.Parent = mainFrame
	
	local milesIcon = Instance.new("TextLabel")
	milesIcon.Name = "MilesIcon"
	milesIcon.Size = UDim2.new(0, 30, 1, 0)
	milesIcon.Position = UDim2.new(0, 0, 0, 0)
	milesIcon.BackgroundTransparency = 1
	milesIcon.Text = "✈️"
	milesIcon.TextColor3 = Color3.fromRGB(0, 150, 255)
	milesIcon.TextScaled = true
	milesIcon.Font = Enum.Font.GothamBold
	milesIcon.Parent = milesFrame
	
	local milesLabel = Instance.new("TextLabel")
	milesLabel.Name = "MilesLabel"
	milesLabel.Size = UDim2.new(1, -40, 1, 0)
	milesLabel.Position = UDim2.new(0, 35, 0, 0)
	milesLabel.BackgroundTransparency = 1
	milesLabel.Text = "500"
	milesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	milesLabel.TextScaled = true
	milesLabel.Font = Enum.Font.GothamBold
	milesLabel.TextXAlignment = Enum.TextXAlignment.Left
	milesLabel.Parent = milesFrame
	
	activeComponents["StatsGUI"] = screenGui
	print("[SimpleComponentManager] Stats GUI created with golden styling")
end

function Local.CreateInventoryGUI()
	-- Create inventory GUI with your buttons
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	-- Main inventory frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	mainFrame.BackgroundColor3 = Color3.fromRGB(0.2, 0.2, 0.2)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🎒 Inventory"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Create inventory buttons grid
	local buttonSize = UDim2.new(0, 60, 0, 60)
	local buttonSpacing = 70
	local startX = 20
	local startY = 70
	
	-- Create 4x4 grid of inventory slots
	for row = 0, 3 do
		for col = 0, 3 do
			local slotNumber = row * 4 + col + 1
			
			-- Create slot frame
			local slotFrame = Instance.new("Frame")
			slotFrame.Name = "Slot" .. slotNumber
			slotFrame.Size = buttonSize
			slotFrame.Position = UDim2.new(0, startX + col * buttonSpacing, 0, startY + row * buttonSpacing)
			slotFrame.BackgroundColor3 = Color3.fromRGB(0.3, 0.3, 0.3)
			slotFrame.BorderSizePixel = 0
			slotFrame.Parent = mainFrame
			
			-- Add corner rounding to slot
			local slotCorner = Instance.new("UICorner")
			slotCorner.CornerRadius = UDim.new(0, 8)
			slotCorner.Parent = slotFrame
			
			-- Add slot number
			local slotNumberLabel = Instance.new("TextLabel")
			slotNumberLabel.Name = "SlotNumber"
			slotNumberLabel.Size = UDim2.new(1, 0, 0, 20)
			slotNumberLabel.Position = UDim2.new(0, 0, 0, 0)
			slotNumberLabel.BackgroundTransparency = 1
			slotNumberLabel.Text = tostring(slotNumber)
			slotNumberLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			slotNumberLabel.TextScaled = true
			slotNumberLabel.Font = Enum.Font.Gotham
			slotNumberLabel.Parent = slotFrame
			
			-- Add item icon (placeholder)
			local itemIcon = Instance.new("TextLabel")
			itemIcon.Name = "ItemIcon"
			itemIcon.Size = UDim2.new(0, 30, 0, 30)
			itemIcon.Position = UDim2.new(0.5, -15, 0.5, -15)
			itemIcon.BackgroundTransparency = 1
			itemIcon.Text = "📦"
			itemIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemIcon.TextScaled = true
			itemIcon.Font = Enum.Font.GothamBold
			itemIcon.Parent = slotFrame
		end
	end
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 100, 0, 40)
	closeButton.Position = UDim2.new(0.5, -50, 1, -50)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	closeButton.Text = "Close"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame
	
	-- Add corner rounding to button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = closeButton
	
	-- Button click handler
	closeButton.MouseButton1Click:Connect(function()
		Local.HideComponent("InventoryGUI")
	end)
	
	activeComponents["InventoryGUI"] = screenGui
	print("[SimpleComponentManager] Inventory GUI created with 16 slots")
end

function Local.CreateTestComponent()
	-- Create test component
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TestComponent"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 300, 0, 200)
	mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
	mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	mainFrame.BackgroundTransparency = 0.3
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Test Component"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 80, 0, 30)
	closeButton.Position = UDim2.new(0.5, -40, 1, -40)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	closeButton.Text = "Close"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.Gotham
	closeButton.Parent = mainFrame
	
	-- Add corner rounding to button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = closeButton
	
	-- Button click handler
	closeButton.MouseButton1Click:Connect(function()
		Local.HideComponent("TestComponent")
	end)
	
	activeComponents["TestComponent"] = screenGui
	print("[SimpleComponentManager] Test component created")
end

function Local.ShowComponent(name: string)
	if not activeComponents[name] then
		warn(`[SimpleComponentManager] Component {name} not found`)
		return
	end
	
	activeComponents[name].Enabled = true
	print(`[SimpleComponentManager] Showing component: {name}`)
end

function Local.HideComponent(name: string)
	if not activeComponents[name] then
		warn(`[SimpleComponentManager] Component {name} not found`)
		return
	end
	
	activeComponents[name].Enabled = false
	print(`[SimpleComponentManager] Hiding component: {name}`)
end

function Local.ToggleComponent(name: string)
	if not activeComponents[name] then
		warn(`[SimpleComponentManager] Component {name} not found`)
		return
	end
	
	local isEnabled = activeComponents[name].Enabled
	activeComponents[name].Enabled = not isEnabled
	print(`[SimpleComponentManager] Toggled component {name}: {not isEnabled}`)
end

function Local.SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Tab key to toggle stats GUI
		if input.KeyCode == Enum.KeyCode.Tab then
			Local.ToggleComponent("StatsGUI")
		end
		
		-- I key to toggle inventory
		if input.KeyCode == Enum.KeyCode.I then
			Local.ToggleComponent("InventoryGUI")
		end
		
		-- T key to toggle test component
		if input.KeyCode == Enum.KeyCode.T then
			Local.ToggleComponent("TestComponent")
		end
	end)
end

function Shared.OnStart()
	print("[SimpleComponentManager] Starting Animal Crossing SimpleComponentManager...")
	
	-- Create components
	Local.CreateStatsGUI()
	Local.CreateInventoryGUI()
	Local.CreateTestComponent()
	
	-- Show stats GUI immediately
	Local.ShowComponent("StatsGUI")
	
	-- Setup input handling
	Local.SetupInputHandling()
	
	print("[SimpleComponentManager] Component system ready!")
	print("  - Stats GUI is now visible on screen!")
	print("  - Press Tab to toggle Stats GUI")
	print("  - Press I to toggle Inventory GUI")
	print("  - Press T to toggle Test Component")
end

return Shared
