--[[
	TutorialManager.luau

	Manages the step-by-step tutorial for new players
	Integrates OnboardingFlow + QuestSystem for guided gameplay
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OnboardingFlow = require(script.Parent.OnboardingFlow)
-- local DialogueGUI = require(script.Parent.DialogueGUI) -- DISABLED: DialogueGUI removed
local QuestGUI = require(script.Parent.QuestGUI)

local TutorialManager = {}
TutorialManager.__index = TutorialManager

-- Tutorial steps - simplified for a smooth experience
-- Tools are given at the START so players can explore right away
local TUTORIAL_STEPS = {
	{
		name = "Welcome",
		dialogues = {
			{
				speaker = "Tom Nook",
				text = "Welcome to your island! I've given you starter tools to help you get started.",
				duration = 4,
			},
		},
		quest = nil, -- No quest, just intro
	},
	{
		name = "Open Inventory",
		dialogues = {
			{
				speaker = "Tom Nook",
				text = "Press 'E' to open your inventory and see your tools!",
				duration = 4,
			},
		},
		keybindHint = "E",
		waitForAction = "inventory_opened",
	},
	{
		name = "Tutorial Complete",
		dialogues = {
			{
				speaker = "Tom Nook",
				text = "You're all set! Explore, gather resources, and have fun!",
				duration = 3,
			},
		},
		onComplete = "tutorial_finished",
	},
}

function TutorialManager.new()
	local self = setmetatable({}, TutorialManager)

	self.player = Players.LocalPlayer
	self.currentStep = 1
	self.isActive = false
	self.questRemote = nil
	self.tutorialRemote = nil

	-- Setup remotes
	self:_setupRemotes()

	print("[TutorialManager] ✅ Initialized")
	return self
end

function TutorialManager:_setupRemotes()
	-- Wait for remotes
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then
		warn("[TutorialManager] ⚠️ Remotes folder not found")
		return
	end

	-- Quest remote for assigning quests (check RemoteEvents folder too)
	self.questRemote = remotes:FindFirstChild("QuestEvent")
	if not self.questRemote then
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remoteEvents then
			self.questRemote = remoteEvents:FindFirstChild("QuestEvent")
		end
	end

	-- Tutorial remote for server communication
	self.tutorialRemote = remotes:FindFirstChild("StartOnboarding")

	if self.tutorialRemote then
		-- Listen for server telling us to start tutorial
		self.tutorialRemote.OnClientEvent:Connect(function()
			print("[TutorialManager] 🎬 Server requested tutorial start")
			self:startTutorial()
		end)
	end
end

--[[
	Start the tutorial sequence
]]
function TutorialManager:startTutorial()
	if self.isActive then
		return
	end

	print("[TutorialManager] 🎬 Starting tutorial...")
	self.isActive = true
	self.currentStep = 1

	-- Start with first step
	self:_runStep(1)
end

--[[
	Run a specific tutorial step
]]
function TutorialManager:_runStep(stepIndex)
	if stepIndex > #TUTORIAL_STEPS then
		-- Tutorial complete!
		self:_completeTutorial()
		return
	end

	local step = TUTORIAL_STEPS[stepIndex]
	print(string.format("[TutorialManager] 📖 Step %d: %s", stepIndex, step.name))

	-- Show dialogues first (DISABLED - DialogueGUI removed)
	-- Skip dialogues and go straight to action since DialogueGUI was removed
	self:_handleStepAction(step, stepIndex)
end

--[[
	Handle step actions (quests, keybinds, etc.)
]]
function TutorialManager:_handleStepAction(step, stepIndex)
	-- Keybind hint disabled - we have a permanent keybind hint in the corner instead
	-- if step.keybindHint then
	-- 	self:_showKeybindHint(step.keybindHint)
	-- end

	-- Assign quest if specified
	if step.questId then
		self:_assignTutorialQuest(step.questId)
	end

	-- Wait for action completion
	if step.waitForAction == "inventory_opened" then
		self:_waitForInventoryOpen(function()
			self:_nextStep(stepIndex)
		end)
	elseif step.waitForAction == "quest_completed" then
		self:_waitForQuestComplete(step.questId, function()
			self:_nextStep(stepIndex)
		end)
	elseif step.onComplete == "tutorial_finished" then
		-- Tutorial is done
		task.wait(2)
		self:_completeTutorial()
	else
		-- No wait condition, proceed immediately
		task.wait(1)
		self:_nextStep(stepIndex)
	end
end

--[[
	Move to next step
]]
function TutorialManager:_nextStep(currentIndex)
	self.currentStep = currentIndex + 1
	self:_runStep(self.currentStep)
end

--[[
	Show keybind hint overlay
]]
function TutorialManager:_showKeybindHint(key)
	local playerGui = self.player:WaitForChild("PlayerGui")

	-- Create hint GUI
	local hintGui = Instance.new("ScreenGui")
	hintGui.Name = "KeybindHint"
	hintGui.DisplayOrder = 150
	hintGui.Parent = playerGui

	-- Background
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0, 200, 0, 80)
	bg.Position = UDim2.new(0.5, -100, 0.8, -40)
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel = 0
	bg.Parent = hintGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = bg

	-- Key display
	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(1, 0, 0.5, 0)
	keyLabel.Position = UDim2.new(0, 0, 0, 10)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = "[" .. key .. "]"
	keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyLabel.TextSize = 32
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.Parent = bg

	-- Instruction
	local instruction = Instance.new("TextLabel")
	instruction.Size = UDim2.new(1, 0, 0.5, 0)
	instruction.Position = UDim2.new(0, 0, 0.5, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = "Press this key"
	instruction.TextColor3 = Color3.fromRGB(200, 200, 200)
	instruction.TextSize = 16
	instruction.Font = Enum.Font.Gotham
	instruction.Parent = bg

	-- Store reference to remove later
	self.currentHint = hintGui
end

--[[
	Remove keybind hint
]]
function TutorialManager:_removeKeybindHint()
	if self.currentHint then
		self.currentHint:Destroy()
		self.currentHint = nil
	end
end

--[[
	Assign a tutorial quest to the player
]]
function TutorialManager:_assignTutorialQuest(questId)
	if not self.questRemote then
		warn("[TutorialManager] ⚠️ No quest remote - can't assign quest")
		return
	end

	print(string.format("[TutorialManager] 📋 Assigning quest: %s", questId))

	-- Request server to create quest
	self.questRemote:FireServer("AssignTutorialQuest", { questId = questId })

	-- Open quest GUI to show the new quest
	task.wait(0.5)
	local questGUI = QuestGUI.new()
	questGUI:show()

	-- Auto-hide after 5 seconds
	task.delay(5, function()
		questGUI:hide()
	end)
end

--[[
	Wait for inventory to be opened
]]
function TutorialManager:_waitForInventoryOpen(callback)
	local playerGui = self.player:WaitForChild("PlayerGui")
	local RunService = game:GetService("RunService")

	-- Function to check if inventory is visible
	local function checkInventoryVisible()
		local inventoryGui = playerGui:FindFirstChild("InventoryGUI")
		if inventoryGui then
			local inventoryFrame = inventoryGui:FindFirstChild("InventoryFrame")
			if inventoryFrame and inventoryFrame.Visible then
				return true
			end
		end
		return false
	end

	-- Check immediately
	if checkInventoryVisible() then
		print("[TutorialManager] ✅ Inventory already open!")
		self:_removeKeybindHint()
		callback()
		return
	end

	-- Monitor until inventory becomes visible
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if checkInventoryVisible() then
			print("[TutorialManager] ✅ Inventory opened!")
			connection:Disconnect()
			self:_removeKeybindHint()
			callback()
		end
	end)

	-- Safety timeout after 60 seconds
	task.delay(60, function()
		if connection then
			connection:Disconnect()
			warn("[TutorialManager] ⚠️ Inventory open timeout - proceeding anyway")
			self:_removeKeybindHint()
			callback()
		end
	end)
end

--[[
	Wait for a quest to be completed
]]
function TutorialManager:_waitForQuestComplete(questId, callback)
	if not self.questRemote then
		warn("[TutorialManager] ⚠️ No quest remote - can't wait for quest")
		callback() -- Skip waiting
		return
	end

	print(string.format("[TutorialManager] ⏳ Waiting for quest completion: %s", questId))

	-- Listen for quest completion event
	local connection
	connection = self.questRemote.OnClientEvent:Connect(function(action, data)
		if action == "QuestCompleted" and data.questId == questId then
			print(string.format("[TutorialManager] ✅ Quest completed: %s", questId))
			connection:Disconnect()
			callback()
		end
	end)
end

--[[
	Complete the tutorial
]]
function TutorialManager:_completeTutorial()
	print("[TutorialManager] 🎉 Tutorial complete!")
	self.isActive = false
	self:_removeKeybindHint()

	-- Notify server
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local tutorialCompleteRemote = remotes:FindFirstChild("TutorialComplete")
		if tutorialCompleteRemote then
			tutorialCompleteRemote:FireServer()
		end
	end

	-- Show completion message
	self:_showCompletionMessage()
end

--[[
	Show tutorial completion message
]]
function TutorialManager:_showCompletionMessage()
	local playerGui = self.player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TutorialComplete"
	screenGui.DisplayOrder = 200
	screenGui.Parent = playerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Message container
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 500, 0, 300)
	container.Position = UDim2.new(0.5, -250, 0.5, -150)
	container.BackgroundColor3 = Color3.fromRGB(255, 251, 231)
	container.BorderSizePixel = 0
	container.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = container

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "🎉 Tutorial Complete!"
	title.TextColor3 = Color3.fromRGB(76, 174, 72)
	title.TextSize = 36
	title.Font = Enum.Font.GothamBold
	title.Parent = container

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -40, 0, 80)
	subtitle.Position = UDim2.new(0, 20, 0, 90)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "You've learned the basics!\n\nExplore your island and complete quests to earn bells and miles!"
	subtitle.TextColor3 = Color3.fromRGB(60, 60, 60)
	subtitle.TextSize = 18
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextWrapped = true
	subtitle.TextYAlignment = Enum.TextYAlignment.Top
	subtitle.Parent = container

	-- Rewards
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, -40, 0, 40)
	rewardLabel.Position = UDim2.new(0, 20, 0, 180)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = "🎁 Rewards: 1000 Bells + 500 Nook Miles"
	rewardLabel.TextColor3 = Color3.fromRGB(255, 193, 7)
	rewardLabel.TextSize = 20
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.Parent = container

	-- Continue button
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 200, 0, 50)
	button.Position = UDim2.new(0.5, -100, 1, -70)
	button.BackgroundColor3 = Color3.fromRGB(76, 174, 72)
	button.Text = "Start Playing!"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.Font = Enum.Font.GothamBold
	button.BorderSizePixel = 0
	button.Parent = container

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 12)
	buttonCorner.Parent = button

	button.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	-- Auto-close after 10 seconds
	task.delay(10, function()
		if screenGui and screenGui.Parent then
			screenGui:Destroy()
		end
	end)
end

return TutorialManager
