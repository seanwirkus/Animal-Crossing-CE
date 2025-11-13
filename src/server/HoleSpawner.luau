--[[
	HoleSpawner.luau
	
	Spawns hole models around the island
	Holes can be dug with a shovel to find items/bells
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HoleSpawner = {}

-- Configuration
local HOLE_ASSET_ID = 98139431900134
local NUM_HOLES = 15  -- Number of holes to spawn
local SPAWN_RADIUS = 200  -- Spawn within this radius
local SPAWN_HEIGHT = 50  -- Start raycast from this height

--[[
	Spawns a hole at a specific position
]]
local function spawnHole(position)
	-- Load hole model from asset
	local success, holeModel = pcall(function()
		return game:GetService("InsertService"):LoadAsset(HOLE_ASSET_ID)
	end)
	
	if not success or not holeModel then
		warn("[HoleSpawner] Failed to load hole asset")
		return nil
	end
	
	-- Get the first child (the actual model)
	local hole = holeModel:GetChildren()[1]
	if not hole then
		holeModel:Destroy()
		return nil
	end
	
	hole = hole:Clone()
	holeModel:Destroy()
	
	-- Position the hole ON TOP of terrain
	-- Get the bounding box to calculate proper positioning
	if hole:IsA("Model") and hole.PrimaryPart then
		-- Calculate the bottom of the model
		local primaryPart = hole.PrimaryPart
		local cf, size = primaryPart.CFrame, primaryPart.Size
		local bottomOffset = size.Y / 2
		
		-- Position so the bottom of the model sits on the terrain
		local adjustedPosition = position - Vector3.new(0, bottomOffset, 0)
		hole:MoveTo(adjustedPosition)
	elseif hole:IsA("BasePart") then
		-- For a single part, position it so bottom sits on terrain
		local bottomOffset = hole.Size.Y / 2
		hole.Position = position - Vector3.new(0, bottomOffset, 0)
	else
		-- For models without PrimaryPart, try to find the lowest part
		local lowestPart = nil
		local lowestY = math.huge
		for _, part in ipairs(hole:GetDescendants()) do
			if part:IsA("BasePart") then
				local partBottom = part.Position.Y - part.Size.Y / 2
				if partBottom < lowestY then
					lowestY = partBottom
					lowestPart = part
				end
			end
		end
		if lowestPart then
			local offset = position.Y - lowestY
			hole:PivotTo(CFrame.new(position - Vector3.new(0, offset, 0)))
		else
			hole:PivotTo(CFrame.new(position))
		end
	end
	
	-- Set properties
	hole.Name = "DigHole"
	
	-- Parent to workspace
	local holesFolder = Workspace:FindFirstChild("Holes")
	if not holesFolder then
		holesFolder = Instance.new("Folder")
		holesFolder.Name = "Holes"
		holesFolder.Parent = Workspace
	end
	
	hole.Parent = holesFolder
	
	return hole
end

--[[
	Finds a valid ground position using raycast
	Returns position ON TOP of terrain surface
]]
local function findGroundPosition(x, z)
	local rayOrigin = Vector3.new(x, SPAWN_HEIGHT, z)
	local rayDirection = Vector3.new(0, -200, 0)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {Workspace.Terrain}
	
	local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if rayResult then
		-- Get the surface normal to position hole correctly
		local surfaceNormal = rayResult.Normal
		local hitPosition = rayResult.Position
		
		-- Position hole ON TOP of terrain (not inside)
		-- Add offset based on surface normal to ensure it sits on top
		local offset = surfaceNormal * 0.2  -- Small offset to sit on surface
		return hitPosition + offset
	end
	
	return nil
end

--[[
	Spawns holes randomly around the map
]]
function HoleSpawner.spawnHoles()
	print("[HoleSpawner] 🕳️ Spawning holes...")
	
	-- Clear existing holes
	local existingHoles = Workspace:FindFirstChild("Holes")
	if existingHoles then
		existingHoles:ClearAllChildren()
	end
	
	local holesSpawned = 0
	local attempts = 0
	local maxAttempts = NUM_HOLES * 3
	
	while holesSpawned < NUM_HOLES and attempts < maxAttempts do
		attempts = attempts + 1
		
		-- Random position within radius
		local angle = math.random() * math.pi * 2
		local distance = math.random(20, SPAWN_RADIUS)
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		
		-- Find ground
		local position = findGroundPosition(x, z)
		
		if position then
			local hole = spawnHole(position)
			if hole then
				holesSpawned = holesSpawned + 1
				print("[HoleSpawner] Spawned hole", holesSpawned, "at", position)
			end
		end
	end
	
	print("[HoleSpawner] ✅ Spawned", holesSpawned, "holes")
end

--[[
	Initializes the hole spawner
	NOTE: Holes are NOT spawned automatically - they only appear when players dig with a shovel
]]
function HoleSpawner.init()
	print("[HoleSpawner] 🕳️ Initializing hole spawner...")
	print("[HoleSpawner] ℹ️ Holes will only appear when players dig with a shovel")
	
	-- Do NOT spawn holes automatically - they should only appear when dug
	-- Holes are created by ShovelSystem when players dig
	
	print("[HoleSpawner] ✅ Hole spawner initialized")
end

return HoleSpawner
