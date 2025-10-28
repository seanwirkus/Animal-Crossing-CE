--[[
	UnifiedOnboardingFlow.luau
	
	Consolidates the entire onboarding experience into one seamless flow:
	1. Tom Nook greeting and dialogue
	2. Island template selection
	3. Island name customization
	4. Island generation with loading screen
	5. Teleportation to new island
	
	This replaces multiple separate GUIs and remote handlers with a single
	orchestrated state machine.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- local Theme = require(ReplicatedStorage.Theme) -- Disabled for now
local OnboardingGUI = require(script.Parent.OnboardingGUI)
local DialogueSystem = require(script.Parent.DialogueSystem)

local UnifiedOnboardingFlow = {}
UnifiedOnboardingFlow.__index = UnifiedOnboardingFlow

-- State machine for tracking flow progress
local STATES = {
	IDLE = "idle",
	SHOWING_GREETING = "showing_greeting",
	SHOWING_SELECTION = "showing_selection",
	GENERATING = "generating",
	COMPLETE = "complete",
	CANCELLED = "cancelled",
	ERROR = "error",
}

function UnifiedOnboardingFlow.new(options)
	assert(options, "UnifiedOnboardingFlow requires options")
	assert(options.templates and #options.templates > 0, "UnifiedOnboardingFlow requires templates")
	assert(options.remotes, "UnifiedOnboardingFlow requires remotes")
	
	local self = setmetatable({}, UnifiedOnboardingFlow)
	
	self._player = Players.LocalPlayer
	self._playerGui = self._player:WaitForChild("PlayerGui")
	self._templates = options.templates
	self._remotes = options.remotes
	self._state = STATES.IDLE
	self._activeGuis = {}
	self._connections = {}
	
	return self
end

--[[
	Start the unified onboarding flow with Tom Nook greeting
]]
function UnifiedOnboardingFlow:Begin()
	if self._state ~= STATES.IDLE then
		warn("[UnifiedOnboardingFlow] Already in progress (state: " .. self._state .. ")")
		return
	end
	
	print("[UnifiedOnboardingFlow] Starting onboarding flow")
	self._state = STATES.SHOWING_GREETING
	
	-- Show Tom Nook greeting
	self:_showTomNookGreeting()
end

--[[
	Show the Tom Nook welcome dialogue
]]
function UnifiedOnboardingFlow:_showTomNookGreeting()
	DialogueSystem.ShowVillagerDialogue(
		self._playerGui,
		"Tom Nook",
		"Welcome! I'm Tom Nook, and I'm here to help you create your very own island paradise! Ready to get started?",
		self._player.Name,
		{ color = "light", continueButton = true, nameTagColor = "orange" }
	)
	
	-- Transition to selection after greeting completes
	task.wait(3)
	self:_showIslandSelection()
end

--[[
	Show the island template selection GUI
]]
function UnifiedOnboardingFlow:_showIslandSelection()
	if self._state ~= STATES.SHOWING_GREETING then
		return -- Flow was cancelled or errored
	end
	
	print("[UnifiedOnboardingFlow] Showing island selection")
	self._state = STATES.SHOWING_SELECTION
	
	local onboardingGui = OnboardingGUI.new({
		templates = self._templates,
		onConfirm = function(selection)
			self:_handleSelectionConfirm(selection)
		end,
		onCancel = function()
			self:_handleSelectionCancel()
		end,
	})
	
	table.insert(self._activeGuis, onboardingGui)
end

--[[
	Handle island selection confirmation
]]
function UnifiedOnboardingFlow:_handleSelectionConfirm(selection)
	if not selection or not selection.template or not selection.islandName then
		warn("[UnifiedOnboardingFlow] Invalid selection returned")
		self:_showError("Invalid island configuration")
		return
	end
	
	print("[UnifiedOnboardingFlow] Island selected:", selection.islandName)
	self._state = STATES.GENERATING
	
	-- Show loading screen
	self:_showGenerationScreen(selection.template, selection.islandName)
	
	-- Fire island generation to server
	task.wait(1) -- Brief pause for UX
	
	local generateIslandRemote = self._remotes:FindFirstChild("GeneratePlayerIsland")
	if not generateIslandRemote then
		self:_showError("Island generation service unavailable")
		return
	end
	
	local islandConfig = {
		templateId = selection.template.id,
		template = selection.template.id,
		islandName = selection.islandName,
		difficulty = selection.template.difficulty,
		biomeTags = selection.template.biomeTags,
		features = selection.template.features,
		startingBells = selection.template.startingBells or 1000,
		startingMiles = selection.template.startingMiles or 500,
	}
	
	generateIslandRemote:FireServer(selection.islandName, islandConfig)
	print("[UnifiedOnboardingFlow] Island generation requested")
	
	-- Listen for response
	self:_listenForGenerationResponse()
end

--[[
	Handle island selection cancellation
]]
function UnifiedOnboardingFlow:_handleSelectionCancel()
	print("[UnifiedOnboardingFlow] Onboarding cancelled")
	self._state = STATES.CANCELLED
	self:Destroy()
end

--[[
	Show island generation loading screen
]]
function UnifiedOnboardingFlow:_showGenerationScreen(template, islandName)
	-- Destroy any existing GUIs
	for _, gui in ipairs(self._activeGuis) do
		if gui and gui.Destroy then
			pcall(gui.Destroy, gui)
		end
	end
	table.clear(self._activeGuis)
	
	-- Create loading overlay
	local overlay = Instance.new("ScreenGui")
	overlay.Name = "IslandGenerationOverlay"
	overlay.ResetOnSpawn = false
	overlay.IgnoreGuiInset = true
	overlay.DisplayOrder = 100
	overlay.Parent = self._playerGui
	
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = Color3.new(0, 0, 0)
	background.BackgroundTransparency = 0.3
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = overlay
	
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.Size = UDim2.new(0, 520, 0, 260)
	container.BackgroundColor3 = Color3.fromRGB(255, 250, 240)
	container.Parent = background
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(139, 195, 74)
	stroke.Thickness = 3
	stroke.Transparency = 0.2
	stroke.Parent = container
	
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(1, 0, 0, 80)
	icon.Position = UDim2.new(0, 0, 0, 20)
	icon.Font = Enum.Font.GothamBlack
	icon.TextSize = 60
	icon.TextColor3 = Color3.fromRGB(72, 110, 72)
	icon.Text = "✈️"
	icon.Parent = container
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.Size = UDim2.new(1, -80, 0, 0)
	title.Position = UDim2.new(0, 40, 0, 110)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 28
	title.TextColor3 = Color3.fromRGB(62, 85, 58)
	title.TextWrapped = true
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Text = string.format("Preparing %s", islandName)
	title.Parent = container
	
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.AutomaticSize = Enum.AutomaticSize.Y
	subtitle.Size = UDim2.new(1, -80, 0, 0)
	subtitle.Position = UDim2.new(0, 40, 0, 160)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 18
	subtitle.TextColor3 = Color3.fromRGB(110, 126, 110)
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Text = template.tagline or "Tom Nook and Isabelle are getting everything ready."
	subtitle.Parent = container
	
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.AutomaticSize = Enum.AutomaticSize.Y
	status.Size = UDim2.new(1, -80, 0, 0)
	status.Position = UDim2.new(0, 40, 0, 210)
	status.Font = Enum.Font.GothamMedium
	status.TextSize = 16
	status.TextColor3 = Color3.fromRGB(120, 135, 120)
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Center
	status.Text = "The crew is loading supplies and charting your flight..."
	status.Parent = container
	
	table.insert(self._activeGuis, overlay)
	self._generationScreen = overlay
end

--[[
	Listen for island generation response from server
]]
function UnifiedOnboardingFlow:_listenForGenerationResponse()
	-- The server will teleport the player on success
	-- We check if player was teleported by monitoring position changes
	
	local startPos = self._player.Character and self._player.Character:FindFirstChild("HumanoidRootPart")
	if not startPos then
		self:_showError("Character not found")
		return
	end
	
	startPos = startPos.Position
	
	-- Wait for teleportation (max 10 seconds)
	local waitTime = 0
	while waitTime < 10 do
		task.wait(0.5)
		waitTime = waitTime + 0.5
		
		local currentPos = self._player.Character and self._player.Character:FindFirstChild("HumanoidRootPart")
		if currentPos then
			currentPos = currentPos.Position
			
			-- Check if player was teleported (moved more than 50 studs)
			if (currentPos - startPos).Magnitude > 50 then
				print("[UnifiedOnboardingFlow] Player teleported to island!")
				self._state = STATES.COMPLETE
				self:_completeOnboarding()
				return
			end
		end
	end
	
	-- Timeout - check if there's an error response
	self:_showError("Island generation timed out. Please try again.")
end

--[[
	Complete the onboarding flow
]]
function UnifiedOnboardingFlow:_completeOnboarding()
	print("[UnifiedOnboardingFlow] Onboarding completed successfully")
	
	-- Destroy loading screen
	if self._generationScreen then
		self._generationScreen:Destroy()
		self._generationScreen = nil
	end
	
	-- Show success message
	DialogueSystem.ShowVillagerDialogue(
		self._playerGui,
		"Isabelle",
		"Welcome to your island! I'm Isabelle, and I'll be helping you manage things around here. Have a wonderful time exploring your new home!",
		self._player.Name,
		{ color = "light", continueButton = true, nameTagColor = "yellow" }
	)
	
	task.wait(2)
	self:Destroy()
end

--[[
	Show error message and allow retry
]]
function UnifiedOnboardingFlow:_showError(message)
	print("[UnifiedOnboardingFlow] Error:", message)
	self._state = STATES.ERROR
	
	-- Destroy loading screen
	if self._generationScreen then
		self._generationScreen:Destroy()
		self._generationScreen = nil
	end
	
	-- Show error dialogue
	DialogueSystem.ShowVillagerDialogue(
		self._playerGui,
		"Tom Nook",
		message .. " Let's try setting up your island again, yeah?",
		self._player.Name,
		{ color = "light", continueButton = true, nameTagColor = "orange" }
	)
	
	task.wait(2)
	
	-- Reset to allow retry
	self._state = STATES.IDLE
end

--[[
	Clean up all resources
]]
function UnifiedOnboardingFlow:Destroy()
	print("[UnifiedOnboardingFlow] Destroying flow")
	
	-- Disconnect all connections
	for _, conn in ipairs(self._connections) do
		if conn and typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	table.clear(self._connections)
	
	-- Destroy all active GUIs
	for _, gui in ipairs(self._activeGuis) do
		if gui and gui.Destroy then
			pcall(gui.Destroy, gui)
		end
	end
	table.clear(self._activeGuis)
	
	-- Destroy generation screen
	if self._generationScreen then
		self._generationScreen:Destroy()
		self._generationScreen = nil
	end
end

return UnifiedOnboardingFlow
