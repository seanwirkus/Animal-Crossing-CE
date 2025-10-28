--[[
	OnboardingService - Handles player onboarding flow
	Manages the initial player experience
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Local = {}
local Shared = {}

-- Track onboarding state
local onboardingPlayers = {}

function Local.StartOnboarding(player: Player)
	print(`[OnboardingService] Starting onboarding for {player.Name}`)
	
	onboardingPlayers[player.UserId] = true
	
	-- Fire remote to client
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local startRemote = remotes:WaitForChild("StartOnboarding", 5)
		if startRemote then
			startRemote:FireClient(player)
		end
	end
end

function Local.CompleteOnboarding(player: Player)
	print(`[OnboardingService] Completing onboarding for {player.Name}`)
	
	onboardingPlayers[player.UserId] = nil
	
	-- Give starting items/currency
	-- This would be handled by other services
	print(`[OnboardingService] {player.Name} has completed onboarding!`)
end

function Local.IsPlayerOnboarding(player: Player): boolean
	return onboardingPlayers[player.UserId] == true
end

function Shared.OnStart()
	print("[OnboardingService] Starting Animal Crossing OnboardingService...")
	
	-- Connect to remotes
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if remotes then
		-- Complete onboarding
		local completeRemote = remotes:WaitForChild("CompleteOnboarding", 5)
		if completeRemote then
			completeRemote.OnServerEvent:Connect(Local.CompleteOnboarding)
		end
	end
	
	-- Auto-start onboarding for new players
	Players.PlayerAdded:Connect(function(player)
		task.wait(2) -- Wait for player to load
		Local.StartOnboarding(player)
	end)
	
	-- Clean up when players leave
	Players.PlayerRemoving:Connect(function(player)
		onboardingPlayers[player.UserId] = nil
	end)
end

return Shared