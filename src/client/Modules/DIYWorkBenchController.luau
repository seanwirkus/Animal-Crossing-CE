-- DIYWorkBench Controller
-- Handles interaction with DIYWorkBench models in the world
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local DIYWorkbenchGUI = require(script.Parent.DIYWorkbenchGUI)

local DIYWorkBenchController = {}
DIYWorkBenchController.__index = DIYWorkBenchController

local _instance = nil

function DIYWorkBenchController.new()
	if _instance then
		return _instance
	end
	
	local self = setmetatable({}, DIYWorkBenchController)
	
	self._workbenchGUI = nil
	self._currentWorkbench = nil
	self._connections = {}
	
	-- Initialize GUI
	self._workbenchGUI = DIYWorkbenchGUI.new()
	
	-- Listen for workbench proximity prompts
	self:_setupWorkbenchListeners()
	
	_instance = self
	print("[DIYWorkBenchController] ✅ Initialized")
	return self
end

function DIYWorkBenchController:_setupWorkbenchListeners()
	-- Find all existing workbenches
	self:_scanForWorkbenches()
	
	-- Listen for new workbenches being added
	local workspace = game:GetService("Workspace")
	
	-- Check CraftingStations folder
	local craftingStationsFolder = workspace:FindFirstChild("CraftingStations")
	if craftingStationsFolder then
		craftingStationsFolder.ChildAdded:Connect(function(child)
			if child:IsA("Model") and child:GetAttribute("CraftingStation") == "DIYWorkBench" then
				self:_setupWorkbenchProximityPrompt(child)
			end
		end)
	end
	
	-- Also check for workbenches directly in workspace
	workspace.ChildAdded:Connect(function(child)
		if child:IsA("Model") and child:GetAttribute("CraftingStation") == "DIYWorkBench" then
			self:_setupWorkbenchProximityPrompt(child)
		end
	end)
end

function DIYWorkBenchController:_scanForWorkbenches()
	local workspace = game:GetService("Workspace")
	
	-- Check CraftingStations folder
	local craftingStationsFolder = workspace:FindFirstChild("CraftingStations")
	if craftingStationsFolder then
		for _, child in ipairs(craftingStationsFolder:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("CraftingStation") == "DIYWorkBench" then
				self:_setupWorkbenchProximityPrompt(child)
			end
		end
	end
	
	-- Also scan workspace directly
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("CraftingStation") == "DIYWorkBench" then
			self:_setupWorkbenchProximityPrompt(child)
		end
	end
end

function DIYWorkBenchController:_setupWorkbenchProximityPrompt(workbench)
	-- Check if it already has a proximity prompt
	local existingPrompt = workbench:FindFirstChildOfClass("ProximityPrompt")
	if existingPrompt then
		-- Connect to existing prompt
		existingPrompt.Triggered:Connect(function()
			self:_onWorkbenchInteracted(workbench)
		end)
		print("[DIYWorkBenchController] ✅ Connected to existing ProximityPrompt on", workbench.Name)
		return
	end
	
	-- Create ProximityPrompt if it doesn't exist
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WorkbenchPrompt"
	prompt.ActionText = "Use Workbench"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = workbench:FindFirstChildOfClass("BasePart") or workbench
	
	prompt.Triggered:Connect(function()
		self:_onWorkbenchInteracted(workbench)
	end)
	
	print("[DIYWorkBenchController] ✅ Created ProximityPrompt for", workbench.Name)
end

function DIYWorkBenchController:_onWorkbenchInteracted(workbench)
	print("[DIYWorkBenchController] 🔨 Player interacted with workbench:", workbench.Name)
	
	-- Notify server that player is using workbench
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEventsFolder then
		local useWorkbenchRemote = remoteEventsFolder:FindFirstChild("UseWorkbench")
		if useWorkbenchRemote then
			useWorkbenchRemote:FireServer(workbench)
		end
	end
	
	-- Open crafting GUI
	if self._workbenchGUI then
		self._currentWorkbench = workbench
		self._workbenchGUI:Show()
	end
end

function DIYWorkBenchController:GetCurrentWorkbench()
	return self._currentWorkbench
end

function DIYWorkBenchController:Cleanup()
	for _, connection in ipairs(self._connections) do
		if connection and connection.Disconnect then
			connection:Disconnect()
		end
	end
	self._connections = {}
end

-- Initialize on client load
local controller = DIYWorkBenchController.new()

return DIYWorkBenchController

