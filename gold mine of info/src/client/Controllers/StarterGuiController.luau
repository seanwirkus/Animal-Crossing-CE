--[[
	StarterGuiController - Manages StarterGui buttons across the entire game
	Can manipulate, add, remove, and modify buttons for all players
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Local = {}
local Shared = {}

-- GUI References
local mainUI = nil
local buttonContainer = nil

-- Button states
local buttonStates = {
	enabled = true,
	visible = true,
	locked = false
}

function Local.CreateMainUI()
	if mainUI then return end
	
	-- Create main UI from StarterGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 300, 0, 200)
	mainFrame.Position = UDim2.new(1, -320, 0, 20)
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
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Animal Crossing Controls"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Button container
	buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, -20, 1, -40)
	buttonContainer.Position = UDim2.new(0, 10, 0, 40)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = mainFrame
	
	-- Add layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = buttonContainer
	
	mainUI = screenGui
	
	-- Create default buttons
	Local.CreateDefaultButtons()
	
	print("[StarterGuiController] Main UI created with button container")
end

function Local.CreateDefaultButtons()
	-- Inventory Button
	Local.CreateButton("Inventory", "📦", function()
		print("[StarterGuiController] Inventory button clicked!")
		Local.OpenInventory()
	end)
	
	-- Shop Button
	Local.CreateButton("Shop", "🛒", function()
		print("[StarterGuiController] Shop button clicked!")
		Local.OpenShop()
	end)
	
	-- Map Button
	Local.CreateButton("Map", "🗺️", function()
		print("[StarterGuiController] Map button clicked!")
		Local.OpenMap()
	end)
	
	-- Settings Button
	Local.CreateButton("Settings", "⚙️", function()
		print("[StarterGuiController] Settings button clicked!")
		Local.OpenSettings()
	end)
	
	-- Tools Button
	Local.CreateButton("Tools", "🛠️", function()
		print("[StarterGuiController] Tools button clicked!")
		Local.OpenTools()
	end)
end

function Local.CreateButton(name: string, icon: string, callback: () -> ())
	local button = Instance.new("TextButton")
	button.Name = name .. "Button"
	button.Size = UDim2.new(1, 0, 0, 35)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.Text = icon .. " " .. name
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.Gotham
	button.Parent = buttonContainer
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	
	-- Button click handler
	button.MouseButton1Click:Connect(function()
		if buttonStates.enabled and not buttonStates.locked then
			callback()
		end
	end)
	
	-- Hover effects
	button.MouseEnter:Connect(function()
		if buttonStates.enabled then
			local tween = TweenService:Create(button, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			})
			tween:Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		if buttonStates.enabled then
			local tween = TweenService:Create(button, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			})
			tween:Play()
		end
	end)
	
	print(`[StarterGuiController] Created button: {name}`)
	return button
end

function Local.OpenInventory()
	-- TODO: Implement inventory system
	print("[StarterGuiController] Opening inventory...")
end

function Local.OpenShop()
	-- TODO: Implement shop system
	print("[StarterGuiController] Opening shop...")
end

function Local.OpenMap()
	-- TODO: Implement map system
	print("[StarterGuiController] Opening map...")
end

function Local.OpenSettings()
	-- TODO: Implement settings system
	print("[StarterGuiController] Opening settings...")
end

function Local.OpenTools()
	-- TODO: Implement tools system
	print("[StarterGuiController] Opening tools...")
end

-- Button manipulation functions
function Local.SetAllButtonsEnabled(enabled: boolean)
	buttonStates.enabled = enabled
	print(`[StarterGuiController] All buttons {'enabled' if enabled else 'disabled'}`)
end

function Local.SetAllButtonsVisible(visible: boolean)
	buttonStates.visible = visible
	if mainUI then
		mainUI.Enabled = visible
	end
	print(`[StarterGuiController] All buttons {'visible' if visible else 'hidden'}`)
end

function Local.LockAllButtons(locked: boolean)
	buttonStates.locked = locked
	print(`[StarterGuiController] All buttons {'locked' if locked else 'unlocked'}`)
end

function Local.AddCustomButton(name: string, icon: string, callback: () -> ())
	if buttonContainer then
		Local.CreateButton(name, icon, callback)
		print(`[StarterGuiController] Added custom button: {name}`)
	end
end

function Local.RemoveButton(buttonName: string)
	if buttonContainer then
		local button = buttonContainer:FindFirstChild(buttonName .. "Button")
		if button then
			button:Destroy()
			print(`[StarterGuiController] Removed button: {buttonName}`)
		end
	end
end

-- Handle input
function Local.SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Toggle UI with Tab key
		if input.KeyCode == Enum.KeyCode.Tab then
			Local.SetAllButtonsVisible(not buttonStates.visible)
		end
		
		-- Lock/unlock with L key
		if input.KeyCode == Enum.KeyCode.L then
			Local.LockAllButtons(not buttonStates.locked)
		end
	end)
end

function Shared.OnStart()
	print("[StarterGuiController] Starting Animal Crossing StarterGuiController...")
	
	-- Create the main UI
	Local.CreateMainUI()
	
	-- Setup input handling
	Local.SetupInputHandling()
	
	-- Connect to remotes for server-side button manipulation
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if remotes then
		-- Server can manipulate buttons via remotes
		local buttonRemote = remotes:WaitForChild("ManipulateButtons", 5)
		if buttonRemote then
			buttonRemote.OnClientEvent:Connect(function(action, data)
				if action == "enable" then
					Local.SetAllButtonsEnabled(data.enabled)
				elseif action == "visible" then
					Local.SetAllButtonsVisible(data.visible)
				elseif action == "lock" then
					Local.LockAllButtons(data.locked)
				elseif action == "add" then
					Local.AddCustomButton(data.name, data.icon, function() end)
				elseif action == "remove" then
					Local.RemoveButton(data.name)
				end
			end)
		end
	end
end

return Shared
