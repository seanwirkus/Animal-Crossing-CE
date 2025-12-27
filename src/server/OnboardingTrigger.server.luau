--[[
	OnboardingTrigger.server.luau

	Triggers onboarding/tutorial for new players.
	Only starts tutorial if player hasn't completed it (checks DataStore via PlayerIslandService).

	NOTE: OnboardingService.onPlayerJoined ALSO handles starting tutorials, so this script
	primarily handles the TutorialComplete remote event. The actual tutorial start logic
	is delegated to OnboardingService to prevent duplicate starter item grants.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[OnboardingTrigger] Initializing...")

-- Wait for remotes folder
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

-- Create TutorialComplete remote if it doesn't exist
local tutorialCompleteRemote = remotes:FindFirstChild("TutorialComplete")
if not tutorialCompleteRemote then
	tutorialCompleteRemote = Instance.new("RemoteEvent")
	tutorialCompleteRemote.Name = "TutorialComplete"
	tutorialCompleteRemote.Parent = remotes
end

-- Listen for tutorial completion
tutorialCompleteRemote.OnServerEvent:Connect(function(player)
	print(string.format("[OnboardingTrigger] %s completed tutorial!", player.Name))
	-- OnboardingService handles the actual completion logic via its own listener
end)

print("[OnboardingTrigger] Initialized")
