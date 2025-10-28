--[[
	ComponentLoader - Loads and reuses .rbxmx files as components
	Allows you to use your GUI files as reusable components
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")

local Local = {}
local Shared = {}

-- Component cache
local componentCache = {}

-- Component registry
local ComponentRegistry = {
	["hi.rbxmx"] = {
		name = "StatsGUI",
		description = "Currency and stats display",
		category = "UI",
		author = "ACNH Team"
	},
	["test.rbxm"] = {
		name = "TestComponent", 
		description = "Test component for development",
		category = "Test",
		author = "ACNH Team"
	}
}

function Local.LoadComponent(componentPath: string)
	-- Check cache first
	if componentCache[componentPath] then
		return componentCache[componentPath]
	end
	
	print(`[ComponentLoader] Loading component: {componentPath}`)
	
	-- Load the component
	local success, component = pcall(function()
		return InsertService:LoadAsset(componentPath)
	end)
	
	if not success then
		warn(`[ComponentLoader] Failed to load component {componentPath}: {component}`)
		return nil
	end
	
	-- Cache the component
	componentCache[componentPath] = component
	print(`[ComponentLoader] Successfully loaded component: {componentPath}`)
	
	return component
end

function Local.CreateComponentInstance(componentPath: string, parent: Instance?)
	local component = Local.LoadComponent(componentPath)
	if not component then
		return nil
	end
	
	-- Clone the component
	local instance = component:Clone()
	
	-- Set parent if provided
	if parent then
		instance.Parent = parent
	end
	
	-- Get component info
	local info = ComponentRegistry[componentPath]
	if info then
		instance:SetAttribute("ComponentName", info.name)
		instance:SetAttribute("ComponentCategory", info.category)
		instance:SetAttribute("ComponentAuthor", info.author)
	end
	
	print(`[ComponentLoader] Created instance of {componentPath}`)
	return instance
end

function Local.GetComponentInfo(componentPath: string)
	return ComponentRegistry[componentPath]
end

function Local.ListAvailableComponents()
	print("[ComponentLoader] Available components:")
	for path, info in ComponentRegistry do
		print(`  - {path}: {info.name} ({info.category})`)
	end
end

function Local.CreateStatsGUI(player: Player)
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create stats GUI using hi.rbxmx component
	local statsGUI = Local.CreateComponentInstance("hi.rbxmx", playerGui)
	if statsGUI then
		-- Customize for Animal Crossing
		statsGUI.Name = "ACNH_StatsGUI"
		statsGUI.ResetOnSpawn = false
		
		-- Update currency display
		Local.UpdateCurrencyDisplay(statsGUI, 1000, 500)
		
		print(`[ComponentLoader] Created stats GUI for {player.Name}`)
		return statsGUI
	end
	
	return nil
end

function Local.UpdateCurrencyDisplay(statsGUI: Instance, bells: number, miles: number)
	-- Find and update currency displays
	local function updateTextInDescendants(parent: Instance, searchText: string, newText: string)
		for _, child in parent:GetDescendants() do
			if child:IsA("TextLabel") and child.Text == searchText then
				child.Text = newText
			end
		end
	end
	
	-- Update bells display
	updateTextInDescendants(statsGUI, "24,239", tostring(bells))
	
	-- Update miles display if found
	updateTextInDescendants(statsGUI, "0", tostring(miles))
end

function Local.CreateTestComponent(player: Player)
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create test component using test.rbxm
	local testComponent = Local.CreateComponentInstance("test.rbxm", playerGui)
	if testComponent then
		testComponent.Name = "ACNH_TestComponent"
		testComponent.ResetOnSpawn = false
		
		print(`[ComponentLoader] Created test component for {player.Name}`)
		return testComponent
	end
	
	return nil
end

function Local.SetupComponentForPlayer(player: Player)
	print(`[ComponentLoader] Setting up components for {player.Name}`)
	
	-- Create stats GUI
	Local.CreateStatsGUI(player)
	
	-- Create test component (for development)
	Local.CreateTestComponent(player)
end

function Shared.OnStart()
	print("[ComponentLoader] Starting Animal Crossing ComponentLoader...")
	
	-- List available components
	Local.ListAvailableComponents()
	
	-- Setup components for existing players
	for _, player in Players:GetPlayers() do
		Local.SetupComponentForPlayer(player)
	end
	
	-- Setup components for new players
	Players.PlayerAdded:Connect(Local.SetupComponentForPlayer)
	
	-- Clean up when players leave
	Players.PlayerRemoving:Connect(function(player)
		print(`[ComponentLoader] Cleaning up components for {player.Name}`)
	end)
end

return Shared
