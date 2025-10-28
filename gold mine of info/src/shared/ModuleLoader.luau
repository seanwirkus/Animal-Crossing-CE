--[[
	ModuleLoader - Proper module loading system for Animal Crossing game
	Based on the Roblox Game Template structure
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local IsServer = RunService:IsServer()
local RootDirectory = if IsServer then ServerScriptService else Players.LocalPlayer:WaitForChild("PlayerScripts")
local ModuleDirectory = if IsServer then RootDirectory:WaitForChild("Services") else RootDirectory:WaitForChild("Controllers")

local function RequireModule(module: ModuleScript)
	if not module:IsA("ModuleScript") then
		return
	end

	local success, result = pcall(function()
		return require(module)
	end)

	if not success then
		warn(`[ModuleLoader] Failed to load {module.Name}: {result}`)
		return
	end

	local onStart = result.OnStart
	if onStart then
		task.spawn(onStart)
	end
end

return function()
	print("[ModuleLoader] Starting module loading...")
	
	for _, descendant: ModuleScript in ModuleDirectory:GetDescendants() do
		RequireModule(descendant)
	end

	if not IsServer then
		ModuleDirectory.DescendantAdded:Connect(function(descendant: ModuleScript)
			RequireModule(descendant)
		end)
	end
	
	print("[ModuleLoader] Module loading complete!")
end