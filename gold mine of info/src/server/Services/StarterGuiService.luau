--[[
	StarterGuiService - Server-side control of StarterGui buttons
	Can manipulate buttons across ALL players in the game
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Local = {}
local Shared = {}

-- Button manipulation functions
function Local.EnableAllButtons(enabled: boolean)
	print(`[StarterGuiService] {'Enabling' if enabled else 'Disabling'} all buttons for all players`)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local buttonRemote = remotes:WaitForChild("ManipulateButtons", 5)
		if buttonRemote then
			for _, player in Players:GetPlayers() do
				buttonRemote:FireClient(player, "enable", {enabled = enabled})
			end
		end
	end
end

function Local.ShowAllButtons(visible: boolean)
	print(`[StarterGuiService] {'Showing' if visible else 'Hiding'} all buttons for all players`)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local buttonRemote = remotes:WaitForChild("ManipulateButtons", 5)
		if buttonRemote then
			for _, player in Players:GetPlayers() do
				buttonRemote:FireClient(player, "visible", {visible = visible})
			end
		end
	end
end

function Local.LockAllButtons(locked: boolean)
	print(`[StarterGuiService] {'Locking' if locked else 'Unlocking'} all buttons for all players`)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local buttonRemote = remotes:WaitForChild("ManipulateButtons", 5)
		if buttonRemote then
			for _, player in Players:GetPlayers() do
				buttonRemote:FireClient(player, "lock", {locked = locked})
			end
		end
	end
end

function Local.AddButtonToAllPlayers(name: string, icon: string)
	print(`[StarterGuiService] Adding button '{name}' to all players`)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local buttonRemote = remotes:WaitForChild("ManipulateButtons", 5)
		if buttonRemote then
			for _, player in Players:GetPlayers() do
				buttonRemote:FireClient(player, "add", {name = name, icon = icon})
			end
		end
	end
end

function Local.RemoveButtonFromAllPlayers(name: string)
	print(`[StarterGuiService] Removing button '{name}' from all players`)
	
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local buttonRemote = remotes:WaitForChild("ManipulateButtons", 5)
		if buttonRemote then
			for _, player in Players:GetPlayers() do
				buttonRemote:FireClient(player, "remove", {name = name})
			end
		end
	end
end

-- Game state management
function Local.OnGameStart()
	print("[StarterGuiService] Game started - enabling all buttons")
	Local.EnableAllButtons(true)
	Local.ShowAllButtons(true)
	Local.LockAllButtons(false)
end

function Local.OnGamePause()
	print("[StarterGuiService] Game paused - disabling all buttons")
	Local.EnableAllButtons(false)
end

function Local.OnGameResume()
	print("[StarterGuiService] Game resumed - enabling all buttons")
	Local.EnableAllButtons(true)
end

function Local.OnPlayerJoin(player: Player)
	print(`[StarterGuiService] Player {player.Name} joined - setting up buttons`)
	
	-- Wait a moment for player to load
	task.wait(2)
	
	-- Enable buttons for new player
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local buttonRemote = remotes:WaitForChild("ManipulateButtons", 5)
		if buttonRemote then
			buttonRemote:FireClient(player, "enable", {enabled = true})
			buttonRemote:FireClient(player, "visible", {visible = true})
			buttonRemote:FireClient(player, "lock", {locked = false})
		end
	end
end

function Local.OnPlayerLeave(player: Player)
	print(`[StarterGuiService] Player {player.Name} left`)
	-- No action needed - buttons are automatically cleaned up
end

function Shared.OnStart()
	print("[StarterGuiService] Starting Animal Crossing StarterGuiService...")
	
	-- Connect to player events
	Players.PlayerAdded:Connect(Local.OnPlayerJoin)
	Players.PlayerRemoving:Connect(Local.OnPlayerLeave)
	
	-- Set up initial game state
	Local.OnGameStart()
	
	-- Example: Add custom buttons after 5 seconds
	task.delay(5, function()
		Local.AddButtonToAllPlayers("Custom Button", "⭐")
	end)
	
	-- Example: Remove a button after 10 seconds
	task.delay(10, function()
		Local.RemoveButtonFromAllPlayers("Custom Button")
	end)
	
	-- Example: Lock all buttons during special events
	task.delay(15, function()
		Local.LockAllButtons(true)
		print("[StarterGuiService] All buttons locked for special event!")
		
		-- Unlock after 5 seconds
		task.delay(5, function()
			Local.LockAllButtons(false)
			print("[StarterGuiService] All buttons unlocked!")
		end)
	end)
end

return Shared
