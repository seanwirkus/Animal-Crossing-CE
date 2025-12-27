--[[
	OnboardingTrigger.server.luau

	Simple script to trigger onboarding/tutorial for testing
	Automatically starts tutorial for all new players
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[OnboardingTrigger] 🎬 Initializing...")

-- Get OnboardingService instance from _G (set by init.server)
-- Define this early so we can use it in startTutorialForPlayer
local function getOnboardingService()
	-- Wait up to 5 seconds for the service to become available
	local attempts = 0
	while not _G.onboardingService and attempts < 50 do
		task.wait(0.1)
		attempts = attempts + 1
	end
	return _G.onboardingService
end

-- Wait for remotes folder
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotes then
	warn("[OnboardingTrigger] ⚠️ Remotes folder not found! Creating...")
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

-- Create StartOnboarding remote if it doesn't exist
local startOnboardingRemote = remotes:FindFirstChild("StartOnboarding")
if not startOnboardingRemote then
	startOnboardingRemote = Instance.new("RemoteEvent")
	startOnboardingRemote.Name = "StartOnboarding"
	startOnboardingRemote.Parent = remotes
	print("[OnboardingTrigger] ✅ Created StartOnboarding RemoteEvent")
end

-- Create TutorialComplete remote if it doesn't exist
local tutorialCompleteRemote = remotes:FindFirstChild("TutorialComplete")
if not tutorialCompleteRemote then
	tutorialCompleteRemote = Instance.new("RemoteEvent")
	tutorialCompleteRemote.Name = "TutorialComplete"
	tutorialCompleteRemote.Parent = remotes
	print("[OnboardingTrigger] ✅ Created TutorialComplete RemoteEvent")
end

-- Track which players have seen tutorial (in this session)
local playersWithTutorial = {}

-- Function to start tutorial for a player
local function startTutorialForPlayer(player)
	if playersWithTutorial[player.UserId] then
		print(string.format("[OnboardingTrigger] %s already has tutorial active", player.Name))
		return
	end

	-- Mark as having tutorial
	playersWithTutorial[player.UserId] = true

	-- Wait a moment for servers to load
	task.wait(3)

	-- Call the server-side OnboardingService to start tutorial (which gives starter kit, etc.)
	local onboardingService = getOnboardingService()
	if onboardingService then
		print(string.format("[OnboardingTrigger] 🎬 Starting tutorial for %s (via OnboardingService)", player.Name))
		onboardingService:startTutorial(player)
	else
		-- Fallback: just fire to client
		print(string.format("[OnboardingTrigger] ⚠️ OnboardingService not available, using client fallback for %s", player.Name))
		startOnboardingRemote:FireClient(player)
	end
end

-- Listen for tutorial completion
tutorialCompleteRemote.OnServerEvent:Connect(function(player)
	print(string.format("[OnboardingTrigger] ✅ %s completed tutorial!", player.Name))

	-- Call OnboardingService if available (it will give tools + currency)
	-- The OnboardingService already listens to TutorialComplete remote,
	-- so this is redundant - just log it here
	print(string.format("[OnboardingTrigger] 💡 OnboardingService should handle rewards automatically", player.Name))
end)

-- Start tutorial for players when they join
Players.PlayerAdded:Connect(function(player)
	print(string.format("[OnboardingTrigger] 👤 %s joined", player.Name))

	-- Auto-start tutorial after a delay
	-- TODO: Check if player has completed tutorial before (DataStore)
	-- For now, just start it for everyone for testing
	task.spawn(function()
		startTutorialForPlayer(player)
	end)
end)

-- Start tutorial for existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		startTutorialForPlayer(player)
	end)
end

print("[OnboardingTrigger] ✅ Ready! Tutorial will auto-start for all players.")
print("[OnboardingTrigger] 💡 To manually trigger: game.ReplicatedStorage.Remotes.StartOnboarding:FireClient(player)")
