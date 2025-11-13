--[[
	IsabelleVillagerManager.luau

	Loads the rigged Isabelle asset and spawns a walking villager on player islands.
	Handles waypoint generation and idle wander behaviour to keep the island lively.
]]

local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local IsabelleVillagerManager = {}
IsabelleVillagerManager.__index = IsabelleVillagerManager

local ASSET_ID = 77893066933188
local WALK_RADIUS = 48
local WAYPOINT_COUNT = 8
local WALK_SPEED = 10
local IDLE_DELAY_RANGE = { 1.5, 3.5 }
local MOVE_TIMEOUT = 6

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function mapIndexToAngle(index)
	return (index / WAYPOINT_COUNT) * (math.pi * 2)
end

local function randomIdleDelay()
	return lerp(IDLE_DELAY_RANGE[1], IDLE_DELAY_RANGE[2], math.random())
end

local function createRaycastParams(ignoreList)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList or {}
	return params
end

local function findHumanoidAndRoot(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model.PrimaryPart

	if humanoid and not rootPart then
		rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso")
	end

	if rootPart and not model.PrimaryPart then
		model.PrimaryPart = rootPart
	end

	return humanoid, rootPart
end

local function createFallbackModel()
	local model = Instance.new("Model")
	model.Name = "IsabelleFallback"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 3, 2)
	root.Shape = Enum.PartType.Cylinder
	root.Color = Color3.fromRGB(255, 218, 165)
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = false
	root.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.Parent = model

	model.PrimaryPart = root
	return model
end

local function loadIsabelleTemplate()
	-- First, try to find the model in workspace (user may have placed it there)
	local workspaceModel = Workspace:FindFirstChild("sza")
	if workspaceModel and workspaceModel:IsA("Model") then
		print("[IsabelleVillagerManager] ✅ Found Isabelle model 'sza' in workspace")
		local model = workspaceModel:Clone()
		model.Name = "Isabelle"
		
		-- Ensure Humanoid exists and is configured
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			warn("[IsabelleVillagerManager] ⚠️ Workspace model 'sza' has no Humanoid; creating one.")
			humanoid = Instance.new("Humanoid")
			humanoid.Parent = model
		end
		
		humanoid.WalkSpeed = WALK_SPEED
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		
		-- Ensure AnimationController exists for animations
		if not model:FindFirstChildOfClass("AnimationController") then
			local animController = Instance.new("AnimationController")
			animController.Parent = model
			print("[IsabelleVillagerManager] ✅ Added AnimationController to Isabelle model")
		end
		
		-- Set PrimaryPart if needed
		local rootPart = model:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			rootPart = model.PrimaryPart
		end
		if not rootPart then
			rootPart = model:FindFirstChildWhichIsA("BasePart")
		end
		if rootPart and not model.PrimaryPart then
			model.PrimaryPart = rootPart
		end
		
		-- Make sure all parts are unanchored for movement
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end
		
		print("[IsabelleVillagerManager] ✅ Configured Isabelle model from workspace")
		return model
	end
	
	-- Fallback: Try to load from asset ID
	local ok, asset = pcall(function()
		return InsertService:LoadAsset(ASSET_ID)
	end)

	if not ok or not asset then
		warn(string.format("[IsabelleVillagerManager] ⚠️ Failed to load asset %d and no 'sza' model in workspace: %s", ASSET_ID, tostring(asset)))
		return createFallbackModel()
	end

	local model = asset:FindFirstChildWhichIsA("Model") or asset
	if model == asset then
		model.Name = "Isabelle"
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("[IsabelleVillagerManager] ⚠️ Loaded asset has no Humanoid; using fallback model for movement support.")
		model:Destroy()
		return createFallbackModel()
	end

	humanoid.WalkSpeed = WALK_SPEED
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	
	-- Ensure AnimationController exists
	if not model:FindFirstChildOfClass("AnimationController") then
		local animController = Instance.new("AnimationController")
		animController.Parent = model
	end

	local rootPart = model:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		rootPart = model.PrimaryPart
	end

	if not rootPart then
		rootPart = model:FindFirstChildWhichIsA("BasePart")
	end

	if rootPart then
		model.PrimaryPart = rootPart
	end
	
	-- Make sure all parts are unanchored
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end

	asset:Destroy()

	return model
end

local function findGroundPosition(origin, ignoreList)
	local rayOrigin = origin + Vector3.new(0, 80, 0)
	local rayDirection = Vector3.new(0, -200, 0)
	local result = Workspace:Raycast(rayOrigin, rayDirection, createRaycastParams(ignoreList))

	if result then
		return result.Position + Vector3.new(0, 0.2, 0)
	end

	return origin
end

local function createWaypointSet(center, ignoreList)
	local waypoints = {}

	for index = 0, WAYPOINT_COUNT - 1 do
		local angle = mapIndexToAngle(index)
		local radius = WALK_RADIUS * (0.7 + math.random() * 0.3)

		local offset = Vector3.new(
			math.cos(angle) * radius,
			0,
			math.sin(angle) * radius
		)

		local candidate = center + offset
		table.insert(waypoints, findGroundPosition(candidate, ignoreList))
	end

	return waypoints
end

function IsabelleVillagerManager.new()
	local self = setmetatable({}, IsabelleVillagerManager)

	self._template = loadIsabelleTemplate()
	self._villagers = {}

	return self
end

function IsabelleVillagerManager:_getOrCreateNPCFolder(islandFolder)
	local npcFolder = islandFolder:FindFirstChild("NPCs")
	if not npcFolder then
		npcFolder = Instance.new("Folder")
		npcFolder.Name = "NPCs"
		npcFolder.Parent = islandFolder
	end
	return npcFolder
end

function IsabelleVillagerManager:_queueNextMove(record)
	local humanoid = record.humanoid
	local rootPart = record.rootPart
	
	if not humanoid or humanoid.Health <= 0 then
		warn("[IsabelleVillagerManager] ⚠️ Cannot move - humanoid missing or dead")
		return
	end
	
	if not rootPart then
		warn("[IsabelleVillagerManager] ⚠️ Cannot move - rootPart missing")
		return
	end

	local waypoints = record.waypoints
	if #waypoints == 0 then
		warn("[IsabelleVillagerManager] ⚠️ No waypoints available")
		return
	end

	record.currentWaypoint = (record.currentWaypoint % #waypoints) + 1
	local target = waypoints[record.currentWaypoint]
	
	if not target then
		warn("[IsabelleVillagerManager] ⚠️ Invalid waypoint target")
		return
	end
	
	-- Make sure rootPart is not anchored
	if rootPart.Anchored then
		warn("[IsabelleVillagerManager] ⚠️ RootPart is anchored - unanchoring now")
		rootPart.Anchored = false
	end
	
	-- Ensure humanoid is ready
	if humanoid.Health <= 0 then
		humanoid.Health = humanoid.MaxHealth
	end
	
	-- Make sure humanoid can move
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.JumpPower = 0  -- Prevent jumping
	
	record.lastMoveStart = os.clock()
	
	-- Debug: Log current position and target
	print(string.format("[IsabelleVillagerManager] 🎯 Current position: %s, Target: %s, Distance: %.2f", 
		tostring(rootPart.Position), tostring(target), (rootPart.Position - target).Magnitude))
	
	-- Move to target
	local success, err = pcall(function()
		humanoid:MoveTo(target)
	end)
	
	if success then
		print(string.format("[IsabelleVillagerManager] 🚶 Isabelle moving to waypoint %d/%d at %s", 
			record.currentWaypoint, #waypoints, tostring(target)))
		
		-- Verify movement started
		task.wait(0.5)
		local state = humanoid:GetState()
		if state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.Walking then
			warn(string.format("[IsabelleVillagerManager] ⚠️ Humanoid state is %s, expected Running/Walking", tostring(state)))
		end
	else
		warn(string.format("[IsabelleVillagerManager] ❌ Failed to move Isabelle: %s", tostring(err)))
	end
end

function IsabelleVillagerManager:_attachMovementHandlers(playerUserId, record)
	if record.moveFinishedConn then
		record.moveFinishedConn:Disconnect()
	end

	if record.heartbeatConn then
		record.heartbeatConn:Disconnect()
	end

	local humanoid = record.humanoid
	if not humanoid then
		return
	end

	record.moveFinishedConn = humanoid.MoveToFinished:Connect(function()
		if not self._villagers[playerUserId] then
			return
		end

		task.delay(randomIdleDelay(), function()
			if self._villagers[playerUserId] then
				self:_queueNextMove(record)
			end
		end)
	end)

	record.heartbeatConn = RunService.Heartbeat:Connect(function()
		if not self._villagers[playerUserId] then
			return
		end

		local humanoid = record.humanoid
		local rootPart = record.rootPart
		
		if not humanoid or not rootPart then
			return
		end
		
		-- Check if humanoid is stuck (hasn't moved for too long)
		if record.lastMoveStart then
			local timeSinceMove = os.clock() - record.lastMoveStart
			if timeSinceMove > MOVE_TIMEOUT then
				-- Humanoid might be stuck, try next waypoint
				warn(string.format("[IsabelleVillagerManager] ⚠️ Isabelle stuck? Time since move: %.2fs, forcing next waypoint", timeSinceMove))
				self:_queueNextMove(record)
			end
		else
			-- No move started yet, start one
			self:_queueNextMove(record)
		end
		
		-- Debug: Log humanoid state periodically
		if math.random() < 0.01 then  -- 1% chance per frame (roughly once per second)
			local state = humanoid:GetState()
			local target = record.waypoints[record.currentWaypoint]
			local distance = target and (rootPart.Position - target).Magnitude or 0
			print(string.format("[IsabelleVillagerManager] 🔍 Isabelle state: %s, Position: %s, Distance to target: %.2f", 
				tostring(state), tostring(rootPart.Position), distance))
		end
		
		-- Force movement if stuck in idle for too long
		if record.lastMoveStart then
			local state = humanoid:GetState()
			local timeSinceMove = os.clock() - record.lastMoveStart
			if (state == Enum.HumanoidStateType.Idle or state == Enum.HumanoidStateType.Physics) and timeSinceMove > 2 then
				-- Been idle for 2+ seconds after starting move, might be stuck
				print(string.format("[IsabelleVillagerManager] ⚠️ Isabelle stuck in %s state for %.2fs, forcing next waypoint", 
					tostring(state), timeSinceMove))
				record.lastMoveStart = os.clock() - MOVE_TIMEOUT  -- Force timeout
			end
		end
	end)
	
	-- Also monitor humanoid state changes
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.FallingDown then
			-- Isabelle is falling, wait for landing
			print("[IsabelleVillagerManager] ⚠️ Isabelle is falling, waiting for landing...")
		elseif newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
			print("[IsabelleVillagerManager] ✅ Isabelle is running!")
		elseif newState == Enum.HumanoidStateType.Walking or newState == Enum.HumanoidStateType.WalkingNoPhysics then
			print("[IsabelleVillagerManager] ✅ Isabelle is walking!")
		elseif newState == Enum.HumanoidStateType.Idle or newState == Enum.HumanoidStateType.Physics then
			-- Check if we should be moving
			if record.lastMoveStart and os.clock() - record.lastMoveStart < 1 then
				print("[IsabelleVillagerManager] ⚠️ Isabelle is idle but should be moving")
			end
		end
	end)
end

function IsabelleVillagerManager:spawnForIsland(playerUserId, islandFolder, islandCenter)
	if not self._template or not islandFolder then
		return
	end

	self:despawnForIsland(playerUserId)

	local npcFolder = self:_getOrCreateNPCFolder(islandFolder)
	local model = self._template:Clone()
	model.Name = "Isabelle"
	model.Parent = npcFolder

	local humanoid, rootPart = findHumanoidAndRoot(model)

	if not rootPart then
		rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.Anchored = false
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.CFrame = CFrame.new(islandCenter + Vector3.new(4, 4, 0))
		rootPart.Parent = model
		model.PrimaryPart = rootPart
	end

	if humanoid then
		humanoid.WalkSpeed = WALK_SPEED
		humanoid.AutoRotate = true
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		-- Ensure animations are enabled (rigged models should have animations)
		-- The AnimationController should already exist from loadIsabelleTemplate
		local animController = model:FindFirstChildOfClass("AnimationController")
		if animController then
			local animator = animController:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = animController
			end
			print("[IsabelleVillagerManager] ✅ Animation system ready for Isabelle")
		end
	end

	-- Make sure ALL parts are unanchored (critical for movement!)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = true  -- Allow collision for movement
		end
	end
	
	-- Make sure rootPart exists and is properly set up
	if rootPart then
		rootPart.Anchored = false
		rootPart.CanCollide = true
		if not model.PrimaryPart then
			model.PrimaryPart = rootPart
		end
	end

	local spawnPosition = findGroundPosition(islandCenter + Vector3.new(6, 0, 0), { model })
	if rootPart then
		rootPart.CFrame = CFrame.new(spawnPosition)
	else
		model:PivotTo(CFrame.new(spawnPosition))
	end

	local waypoints = createWaypointSet(spawnPosition, { model })
	
	-- Debug: print waypoints
	print(string.format("[IsabelleVillagerManager] 📍 Generated %d waypoints for Isabelle", #waypoints))
	if #waypoints > 0 then
		print(string.format("[IsabelleVillagerManager] First waypoint: %s", tostring(waypoints[1])))
	end

	if not humanoid then
		warn("[IsabelleVillagerManager] ⚠️ No Humanoid found on Isabelle model - movement will not work!")
		return
	end
	
	-- Verify humanoid is ready
	if humanoid.Health <= 0 then
		humanoid.Health = humanoid.MaxHealth
	end

	local record = {
		playerUserId = playerUserId,
		model = model,
		humanoid = humanoid,
		rootPart = rootPart,
		waypoints = waypoints,
		currentWaypoint = 0,
		lastMoveStart = nil,
		moveFinishedConn = nil,
		heartbeatConn = nil,
	}

	self._villagers[playerUserId] = record

	self:_attachMovementHandlers(playerUserId, record)
	
	-- Start movement immediately (no delay - humanoid should be ready)
	-- Set initial move start time so heartbeat can work
	record.lastMoveStart = os.clock() - MOVE_TIMEOUT  -- Set to expired so it triggers immediately
	
	-- Verify setup before starting movement
	print(string.format("[IsabelleVillagerManager] 🔍 Setup check - Humanoid: %s, RootPart: %s, Waypoints: %d", 
		tostring(humanoid), tostring(rootPart), #waypoints))
	if rootPart then
		print(string.format("[IsabelleVillagerManager] 🔍 RootPart - Anchored: %s, CanCollide: %s, Position: %s", 
			tostring(rootPart.Anchored), tostring(rootPart.CanCollide), tostring(rootPart.Position)))
	end
	
	-- Start first move
	task.spawn(function()
		task.wait(0.5)  -- Give model time to settle and physics to initialize
		print("[IsabelleVillagerManager] 🚀 Starting first movement...")
		self:_queueNextMove(record)
	end)

	print(string.format("[IsabelleVillagerManager] ✅ Spawned Isabelle for player %d at %s with %d waypoints", 
		playerUserId, tostring(spawnPosition), #waypoints))
end

function IsabelleVillagerManager:despawnForIsland(playerUserId)
	local record = self._villagers[playerUserId]
	if not record then
		return
	end

	if record.moveFinishedConn then
		record.moveFinishedConn:Disconnect()
		record.moveFinishedConn = nil
	end

	if record.heartbeatConn then
		record.heartbeatConn:Disconnect()
		record.heartbeatConn = nil
	end

	if record.model then
		record.model:Destroy()
	end

	self._villagers[playerUserId] = nil

	print(string.format("[IsabelleVillagerManager] 🧹 Despawned Isabelle for player %d", playerUserId))
end

function IsabelleVillagerManager:despawnAll()
	for userId in pairs(self._villagers) do
		self:despawnForIsland(userId)
	end
end

return IsabelleVillagerManager

