--[[
	ComponentManager - Manages GUI components in the Animal Crossing game
	Handles component lifecycle, updates, and interactions
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
local componentStates = {}

-- Component states
local ComponentStates = {
	VISIBLE = "visible",
	HIDDEN = "hidden",
	DISABLED = "disabled",
	ENABLED = "enabled"
}

function Local.RegisterComponent(name: string, component: Instance)
	activeComponents[name] = component
	componentStates[name] = ComponentStates.VISIBLE
	
	print(`[ComponentManager] Registered component: {name}`)
end

function Local.ShowComponent(name: string, animate: boolean?)
	if not activeComponents[name] then
		warn(`[ComponentManager] Component {name} not found`)
		return
	end
	
	local component = activeComponents[name]
	component.Enabled = true
	componentStates[name] = ComponentStates.VISIBLE
	
	if animate then
		Local.AnimateComponent(component, "fadeIn")
	end
	
	print(`[ComponentManager] Showing component: {name}`)
end

function Local.HideComponent(name: string, animate: boolean?)
	if not activeComponents[name] then
		warn(`[ComponentManager] Component {name} not found`)
		return
	end
	
	local component = activeComponents[name]
	componentStates[name] = ComponentStates.HIDDEN
	
	if animate then
		Local.AnimateComponent(component, "fadeOut")
	else
		component.Enabled = false
	end
	
	print(`[ComponentManager] Hiding component: {name}`)
end

function Local.ToggleComponent(name: string)
	if not activeComponents[name] then
		warn(`[ComponentManager] Component {name} not found`)
		return
	end
	
	local currentState = componentStates[name]
	if currentState == ComponentStates.VISIBLE then
		Local.HideComponent(name, true)
	else
		Local.ShowComponent(name, true)
	end
end

function Local.AnimateComponent(component: Instance, animationType: string)
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	
	if animationType == "fadeIn" then
		component.Enabled = true
		component.BackgroundTransparency = 1
		
		local tween = TweenService:Create(component, tweenInfo, {
			BackgroundTransparency = 0
		})
		tween:Play()
		
	elseif animationType == "fadeOut" then
		local tween = TweenService:Create(component, tweenInfo, {
			BackgroundTransparency = 1
		})
		tween:Play()
		
		tween.Completed:Connect(function()
			component.Enabled = false
		end)
	end
end

function Local.UpdateStatsComponent(bells: number, miles: number)
	local statsComponent = activeComponents["StatsGUI"]
	if not statsComponent then
		warn("[ComponentManager] Stats component not found")
		return
	end
	
	-- Update currency displays
	Local.UpdateCurrencyInComponent(statsComponent, bells, miles)
	
	print(`[ComponentManager] Updated stats: {bells} bells, {miles} miles`)
end

function Local.UpdateCurrencyInComponent(component: Instance, bells: number, miles: number)
	-- Find and update currency displays
	for _, child in component:GetDescendants() do
		if child:IsA("TextLabel") then
			local text = child.Text
			
			-- Update bells display
			if text:match("%d+,%d+") then
				child.Text = tostring(bells)
			elseif text == "0" or text == "" then
				child.Text = tostring(miles)
			end
		end
	end
end

function Local.SetupComponentInteractions()
	-- Handle component button clicks
	for name, component in activeComponents do
		Local.SetupComponentButtons(component, name)
	end
end

function Local.SetupComponentButtons(component: Instance, componentName: string)
	for _, child in component:GetDescendants() do
		if child:IsA("TextButton") then
			child.MouseButton1Click:Connect(function()
				Local.HandleComponentButtonClick(componentName, child.Name)
			end)
		end
	end
end

function Local.HandleComponentButtonClick(componentName: string, buttonName: string)
	print(`[ComponentManager] Button clicked: {buttonName} in {componentName}`)
	
	-- Handle different button types
	if buttonName:lower():find("stats") then
		Local.ToggleComponent("StatsGUI")
	elseif buttonName:lower():find("test") then
		Local.ToggleComponent("TestComponent")
	elseif buttonName:lower():find("close") then
		Local.HideComponent(componentName, true)
	end
end

function Local.SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Toggle stats with Tab key
		if input.KeyCode == Enum.KeyCode.Tab then
			Local.ToggleComponent("StatsGUI")
		end
		
		-- Toggle test component with T key
		if input.KeyCode == Enum.KeyCode.T then
			Local.ToggleComponent("TestComponent")
		end
	end)
end

function Local.CreateComponentFromFile(filePath: string, componentName: string)
	-- Load the component from ReplicatedStorage
	local success, components = pcall(function()
		local componentsFolder = ReplicatedStorage:WaitForChild("Components", 5)
		if componentsFolder then
			return require(componentsFolder)
		end
		return nil
	end)
	
	if success and components then
		-- Create instance of the component
		local instance = components.CreateComponent(componentName, PlayerGui)
		if instance then
			Local.RegisterComponent(componentName, instance._gui)
			return instance._gui
		end
	end
	
	-- Fallback: create a placeholder
	warn(`[ComponentManager] Could not load component {componentName}, using placeholder`)
	return Local.CreatePlaceholderComponent(componentName)
end

function Local.CreatePlaceholderComponent(componentName: string)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = componentName
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	-- Create a simple frame as placeholder
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 100)
	frame.Position = UDim2.new(0, 50, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.Parent = screenGui
	
	-- Add title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = componentName
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	
	-- Add close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 80, 0, 30)
	closeButton.Position = UDim2.new(1, -90, 1, -40)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	closeButton.Text = "Close"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.Gotham
	closeButton.Parent = frame
	
	Local.RegisterComponent(componentName, screenGui)
	return screenGui
end

function Local.SetupRemoteConnections()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if remotes then
		-- Component control remote
		local componentRemote = remotes:WaitForChild("ComponentControl", 5)
		if componentRemote then
			componentRemote.OnClientEvent:Connect(function(action, componentName, ...)
				if action == "show" then
					Local.ShowComponent(componentName, true)
				elseif action == "hide" then
					Local.HideComponent(componentName, true)
				elseif action == "lock" then
					-- TODO: Implement component locking
					print(`[ComponentManager] Component {componentName} locked: {...}`)
				end
			end)
		end
		
		-- Stats update remote
		local statsRemote = remotes:WaitForChild("UpdateStats", 5)
		if statsRemote then
			statsRemote.OnClientEvent:Connect(function(bells, miles)
				Local.UpdateStatsComponent(bells, miles)
			end)
		end
	end
end

function Shared.OnStart()
	print("[ComponentManager] Starting Animal Crossing ComponentManager...")
	
	-- Create components from your files
	Local.CreateComponentFromFile("hi.rbxmx", "StatsGUI")
	Local.CreateComponentFromFile("test.rbxm", "TestComponent")
	
	-- Setup interactions
	Local.SetupComponentInteractions()
	Local.SetupInputHandling()
	Local.SetupRemoteConnections()
	
	-- Update stats with sample data
	Local.UpdateStatsComponent(1000, 500)
	
	print("[ComponentManager] Component system ready!")
	print("  - Press Tab to toggle Stats GUI")
	print("  - Press T to toggle Test Component")
end

return Shared
