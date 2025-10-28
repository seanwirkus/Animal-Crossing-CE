--[[
	ComponentService - Server-side component management
	Controls components across all players in the Animal Crossing game
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Local = {}
local Shared = {}

-- Component control functions
function Local.ShowComponentForAllPlayers(componentName: string)
	print(`[ComponentService] Showing {componentName} for all players`)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local componentRemote = remotes:WaitForChild("ComponentControl", 5)
		if componentRemote then
			for _, player in Players:GetPlayers() do
				componentRemote:FireClient(player, "show", componentName)
			end
		end
	end
end

function Local.HideComponentForAllPlayers(componentName: string)
	print(`[ComponentService] Hiding {componentName} for all players`)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local componentRemote = remotes:WaitForChild("ComponentControl", 5)
		if componentRemote then
			for _, player in Players:GetPlayers() do
				componentRemote:FireClient(player, "hide", componentName)
			end
		end
	end
end

function Local.UpdateStatsForAllPlayers(bells: number, miles: number)
	print(`[ComponentService] Updating stats for all players: {bells} bells, {miles} miles`)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local statsRemote = remotes:WaitForChild("UpdateStats", 5)
		if statsRemote then
			for _, player in Players:GetPlayers() do
				statsRemote:FireClient(player, bells, miles)
			end
		end
	end
end

function Local.LockComponentForAllPlayers(componentName: string, locked: boolean)
	print(`[ComponentService] {'Locking' if locked else 'Unlocking'} {componentName} for all players`)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local componentRemote = remotes:WaitForChild("ComponentControl", 5)
		if componentRemote then
			for _, player in Players:GetPlayers() do
				componentRemote:FireClient(player, "lock", componentName, locked)
			end
		end
	end
end

-- Game state management
function Local.OnGameStart()
	print("[ComponentService] Game started - showing default components")
	Local.ShowComponentForAllPlayers("StatsGUI")
	Local.UpdateStatsForAllPlayers(1000, 500)
end

function Local.OnGamePause()
	print("[ComponentService] Game paused - hiding components")
	Local.HideComponentForAllPlayers("StatsGUI")
	Local.HideComponentForAllPlayers("TestComponent")
end

function Local.OnGameResume()
	print("[ComponentService] Game resumed - showing components")
	Local.ShowComponentForAllPlayers("StatsGUI")
end

function Local.OnSpecialEvent()
	print("[ComponentService] Special event - locking components")
	Local.LockComponentForAllPlayers("StatsGUI", true)
	
	-- Unlock after 10 seconds
	task.delay(10, function()
		Local.LockComponentForAllPlayers("StatsGUI", false)
		print("[ComponentService] Components unlocked after special event")
	end)
end

function Local.OnPlayerJoin(player: Player)
	print(`[ComponentService] Player {player.Name} joined - setting up components`)
	
	-- Wait for player to load
	task.wait(2)
	
	-- Show default components for new player
	Local.ShowComponentForAllPlayers("StatsGUI")
	Local.UpdateStatsForAllPlayers(1000, 500)
end

function Local.OnPlayerLeave(player: Player)
	print(`[ComponentService] Player {player.Name} left`)
	-- Components are automatically cleaned up
end

function Shared.OnStart()
	print("[ComponentService] Starting Animal Crossing ComponentService...")
	
	-- Connect to player events
	Players.PlayerAdded:Connect(Local.OnPlayerJoin)
	Players.PlayerRemoving:Connect(Local.OnPlayerLeave)
	
	-- Set up initial game state
	Local.OnGameStart()
	
	-- Example: Update stats every 30 seconds
	task.spawn(function()
		while true do
			task.wait(30)
			Local.UpdateStatsForAllPlayers(math.random(1000, 5000), math.random(500, 2000))
		end
	end)
	
	-- Example: Special event after 20 seconds
	task.delay(20, function()
		Local.OnSpecialEvent()
	end)
	
	-- Example: Game pause/resume simulation
	task.delay(40, function()
		Local.OnGamePause()
		task.delay(5, function()
			Local.OnGameResume()
		end)
	end)
end

return Shared
