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
	local ok, asset = pcall(function()
		return InsertService:LoadAsset(ASSET_ID)
	end)

	if not ok or not asset then
		warn(string.format("[IsabelleVillagerManager] ⚠️ Failed to load asset %d: %s", ASSET_ID, tostring(asset)))
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
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local waypoints = record.waypoints
	if #waypoints == 0 then
		return
	end

	record.currentWaypoint = (record.currentWaypoint % #waypoints) + 1
	local target = waypoints[record.currentWaypoint]
	record.lastMoveStart = os.clock()
	humanoid:MoveTo(target)
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

		if not record.lastMoveStart then
			return
		end

		if os.clock() - record.lastMoveStart > MOVE_TIMEOUT then
			self:_queueNextMove(record)
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
	end

	local spawnPosition = findGroundPosition(islandCenter + Vector3.new(6, 0, 0), { model })
	model:PivotTo(CFrame.new(spawnPosition))

	local waypoints = createWaypointSet(spawnPosition, { model })

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
	self:_queueNextMove(record)

	print(string.format("[IsabelleVillagerManager] ✅ Spawned Isabelle for player %d", playerUserId))
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

