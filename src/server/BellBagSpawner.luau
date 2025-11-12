--[[
	BellBagSpawner.luau
	
	Spawns a BellBag model next to players when they join the game.
	The BellBag model should exist in ReplicatedStorage.
	
	Usage:
		local BellBagSpawner = require(script.Parent.BellBagSpawner)
		BellBagSpawner.init()
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BellBagSpawner = {}

-- Configuration
local SPAWN_OFFSET = Vector3.new(3, 0, 0) -- Spawn 3 studs to the right of player
local SPAWN_HEIGHT_OFFSET = 2 -- Spawn 2 studs above ground to prevent clipping

--[[
	Spawn a BellBag next to the player
]]
local function spawnBellBag(player: Player)
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
	
	if not humanoidRootPart then
		warn("[BellBagSpawner] ⚠️ Could not find HumanoidRootPart for", player.Name)
		return
	end
	
	-- Get BellBag from ReplicatedStorage
	local bellBagTemplate = ReplicatedStorage:FindFirstChild("BellBag")
	
	if not bellBagTemplate then
		warn("[BellBagSpawner] ⚠️ BellBag model not found in ReplicatedStorage")
		return
	end
	
	-- Clone and position the BellBag
	local bellBag = bellBagTemplate:Clone()
	
	-- Calculate spawn position (next to player)
	local spawnPosition = humanoidRootPart.Position + SPAWN_OFFSET + Vector3.new(0, SPAWN_HEIGHT_OFFSET, 0)
	
	-- Set primary part if exists, otherwise find the main part
	local mainPart = bellBag.PrimaryPart or bellBag:FindFirstChildWhichIsA("BasePart")
	
	if mainPart then
		bellBag:PivotTo(CFrame.new(spawnPosition))
	else
		warn("[BellBagSpawner] ⚠️ BellBag has no PrimaryPart or BasePart")
		bellBag:Destroy()
		return
	end
	
	-- Parent to workspace
	bellBag.Parent = workspace
	
	print("[BellBagSpawner] ✅ Spawned BellBag for", player.Name, "at", spawnPosition)
end

--[[
	Initialize the BellBag spawner
]]
function BellBagSpawner.init()
	print("[BellBagSpawner] 🎒 Initializing BellBag spawner...")
	
	-- Spawn for existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			spawnBellBag(player)
		end)
	end
	
	-- Spawn for new players
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5) -- Small delay to ensure character is fully loaded
			spawnBellBag(player)
		end)
		
		-- Also spawn for their current character if it exists
		if player.Character then
			task.wait(0.5)
			spawnBellBag(player)
		end
	end)
	
	print("[BellBagSpawner] ✅ BellBag spawner initialized")
end

return BellBagSpawner
