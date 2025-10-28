local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarKit = ReplicatedStorage:FindFirstChild("AvatarKit")

local function newFallbackAvatarBuilder()
	return {
		applyProfile = function() end,
	}
end

local function loadAvatarBuilder()
	if AvatarKit then
		local module = AvatarKit:FindFirstChild("AvatarBuilder")
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module)
			if ok then
				return result
			else
				warn(string.format("[SpawnApply] Failed to require AvatarKit/AvatarBuilder: %s", tostring(result)))
			end
		end
	end

	warn("[SpawnApply] AvatarKit/AvatarBuilder missing; applying a fallback that leaves characters unmodified.")
	return newFallbackAvatarBuilder()
end

local AvatarBuilder = loadAvatarBuilder()
local profileStore = require(script.Parent:WaitForChild("AvatarProfileStore"))

local function applyProfileToCharacter(player: Player, character: Model)
	local profile = profileStore.loadProfile(player)
	local ok, err = pcall(function()
		AvatarBuilder.applyProfile(character, profile)
	end)
	if not ok then
		warn(string.format("[SpawnApply] Failed to apply avatar profile for %s: %s", player.Name, tostring(err)))
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		if not character then
			return
		end
		applyProfileToCharacter(player, character)
	end)
end)
