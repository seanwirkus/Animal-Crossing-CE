--[[
	OnboardingFlow.luau
	
	Complete onboarding flow integrating:
	- DialogueGUI (Tom Nook dialogue)
	- CutsceneManager (camera control, transitions)
	- LoadingScreen (island loading)
	- Island selection and spawn
	
	This shows the complete flow:
	1. Dialogue with Tom Nook ✅ (already working)
	2. Island selection screen
	3. Loading screen with progress
	4. Cutscene: Camera pan over island
	5. Player spawn on island
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local DialogueGUI = require(script.Parent.DialogueGUI)
local CutsceneManager = require(script.Parent.CutsceneManager)
local LoadingScreen = require(script.Parent.LoadingScreen)

local OnboardingFlow = {}

-- Sample dialogue sequence (Tom Nook welcome)
local ONBOARDING_DIALOGUE = {
	{
		speaker = "Tom Nook",
		text = "Ah, welcome, welcome! So glad you could make it!",
		duration = 3
	},
	{
		speaker = "Tom Nook",
		text = "I'm Tom Nook, and I'll be helping you get settled on your very own island getaway!",
		duration = 4
	},
	{
		speaker = "Tom Nook",
		text = "Now then, let's pick out the perfect island for you, yes yes!",
		duration = 3
	}
}

-- Sample island options
local ISLAND_OPTIONS = {
	{name = "Coral Cove", theme = "Beach", description = "Sandy shores and palm trees"},
	{name = "Forest Glen", theme = "Forest", description = "Lush trees and hidden streams"},
	{name = "Mountain Peak", theme = "Mountain", description = "Elevated views and waterfalls"},
	{name = "Flower Fields", theme = "Meadow", description = "Blooming flowers everywhere"}
}

--[[
	Start the complete onboarding flow
]]
function OnboardingFlow.start()
	print("[OnboardingFlow] 🎬 Starting onboarding sequence...")
	
	-- Step 1: Show Tom Nook dialogue
	OnboardingFlow.showDialogue(function()
		-- Step 2: After dialogue, show island selection
		OnboardingFlow.showIslandSelection(function(selectedIsland)
			-- Step 3: Load the island with loading screen
			OnboardingFlow.loadIsland(selectedIsland, function()
				-- Step 4: Play arrival cutscene
				OnboardingFlow.playArrivalCutscene(function()
					-- Step 5: Give player control
					OnboardingFlow.completeOnboarding()
				end)
			end)
		end)
	end)
end

--[[
	Step 1: Show Tom Nook dialogue sequence
]]
function OnboardingFlow.showDialogue(onComplete: () -> ())
	print("[OnboardingFlow] 💬 Showing Tom Nook dialogue...")
	
	-- Use existing DialogueGUI module
	local dialogue = DialogueGUI.new()
	
	-- Show dialogue sequence
	dialogue:showDialogueSequence(ONBOARDING_DIALOGUE, function()
		print("[OnboardingFlow] ✅ Dialogue complete")
		onComplete()
	end)
end

--[[
	Step 2: Show island selection screen
	TODO: Create island selection GUI
]]
function OnboardingFlow.showIslandSelection(onComplete: (island: {name: string, theme: string}) -> ())
	print("[OnboardingFlow] 🏝️ Showing island selection...")
	
	-- TODO: Create island selection GUI in Studio
	-- For now, auto-select first island
	task.wait(1)
	
	local selectedIsland = ISLAND_OPTIONS[1]
	print(string.format("[OnboardingFlow] ✅ Island selected: %s", selectedIsland.name))
	
	onComplete(selectedIsland)
end

--[[
	Step 3: Load the island with loading screen
]]
function OnboardingFlow.loadIsland(island: {name: string, theme: string}, onComplete: () -> ())
	print(string.format("[OnboardingFlow] 📦 Loading island: %s", island.name))
	
	-- Show loading screen with progress bar
	LoadingScreen.show(string.format("Loading %s...", island.name), true)
	
	-- Simulate island loading with progress updates
	task.spawn(function()
		-- Load terrain
		task.wait(0.5)
		LoadingScreen.setProgress(0.2)
		LoadingScreen.setStatus("Generating terrain...")
		
		-- Load vegetation
		task.wait(0.5)
		LoadingScreen.setProgress(0.4)
		LoadingScreen.setStatus("Planting trees...")
		
		-- Load buildings
		task.wait(0.5)
		LoadingScreen.setProgress(0.6)
		LoadingScreen.setStatus("Building structures...")
		
		-- Load wildlife
		task.wait(0.5)
		LoadingScreen.setProgress(0.8)
		LoadingScreen.setStatus("Adding wildlife...")
		
		-- Finalize
		task.wait(0.5)
		LoadingScreen.setProgress(1.0)
		LoadingScreen.setStatus("Almost ready...")
		
		task.wait(0.5)
		
		-- Hide loading screen
		LoadingScreen.hide()
		
		print("[OnboardingFlow] ✅ Island loaded")
		onComplete()
	end)
end

--[[
	Step 4: Play arrival cutscene (camera pan, fade in)
]]
function OnboardingFlow.playArrivalCutscene(onComplete: () -> ())
	print("[OnboardingFlow] 🎥 Playing arrival cutscene...")
	
	local cutscene = CutsceneManager.new()
	
	-- Find a nice spot to show (e.g., spawn location or Town Square)
	local spawnLocation = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("TownSquare")
	
	if not spawnLocation then
		warn("[OnboardingFlow] ⚠️ No spawn location found - skipping cutscene")
		onComplete()
		return
	end
	
	-- Cutscene sequence:
	-- 1. Fade from black
	-- 2. Pan camera over island
	-- 3. Focus on player spawn
	-- 4. Fade out and reset camera
	cutscene:startSequence({
		{type = "fade", direction = "out", duration = 1.5}, -- Fade from black
		{type = "camera", target = spawnLocation, duration = 3, offset = CFrame.new(0, 10, 20)}, -- High angle view
		{type = "wait", duration = 2}, -- Hold for a moment
		{type = "camera", target = spawnLocation, duration = 2, offset = CFrame.new(0, 2, 5)}, -- Lower to player level
		{type = "wait", duration = 1},
		{type = "reset"} -- Give control back to player
	}, function()
		print("[OnboardingFlow] ✅ Cutscene complete")
		onComplete()
	end)
end

--[[
	Step 5: Complete onboarding and give player control
]]
function OnboardingFlow.completeOnboarding()
	print("[OnboardingFlow] 🎉 Onboarding complete! Welcome to your island!")
	
	-- TODO: Set player spawn position
	-- TODO: Enable player movement
	-- TODO: Show HUD/inventory
	-- TODO: Play welcome music
	
	-- Fire remote to server to mark onboarding complete
	local onboardingRemote = ReplicatedStorage:FindFirstChild("RemoteEvents")
		and ReplicatedStorage.RemoteEvents:FindFirstChild("OnboardingComplete")
	
	if onboardingRemote then
		onboardingRemote:FireServer()
		print("[OnboardingFlow] ✅ Server notified of onboarding completion")
	end
end

--[[
	Example: Quick test of loading screen
]]
function OnboardingFlow.testLoadingScreen()
	LoadingScreen.show("Testing loading screen...", true)
	
	task.spawn(function()
		for i = 0, 10 do
			task.wait(0.3)
			LoadingScreen.setProgress(i / 10)
		end
		task.wait(1)
		LoadingScreen.hide()
	end)
end

--[[
	Example: Quick test of cutscene
]]
function OnboardingFlow.testCutscene()
	local cutscene = CutsceneManager.new()
	
	-- Find player's character
	local player = Players.LocalPlayer
	local character = player.Character
	
	if not character then
		warn("[OnboardingFlow] ⚠️ No character found")
		return
	end
	
	cutscene:startSequence({
		{type = "fade", direction = "in", duration = 1},
		{type = "camera", target = character.Head, duration = 2, offset = CFrame.new(5, 3, 5)},
		{type = "wait", duration = 2},
		{type = "fade", direction = "out", duration = 1},
		{type = "reset"}
	})
end

return OnboardingFlow
