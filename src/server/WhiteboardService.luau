--[[
	WhiteboardService.luau

	Server-side manager for the Workspace Whiteboard setup.
	Responsibilities:
	- Maintain RemoteEvents/RemoteFunctions for drawing, clearing and saving.
	- Relay drawing updates to all clients in real time.
	- Persist drawings to DataStore when requested.
	- Provide existing drawings to clients when they connect.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
type Player = typeof(Players.LocalPlayer)

local REMOTE_FOLDER_NAME = "WhiteboardRemotes"
local DRAW_EVENT_NAME = "Draw"
local CLEAR_EVENT_NAME = "Clear"
local SAVE_EVENT_NAME = "Save"
local SYNC_FUNCTION_NAME = "Sync"

local DATASTORE_NAME = "WhiteboardDrawings"
local DATASTORE_KEY = "GlobalBoard"

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local WhiteboardConstants = require(sharedFolder:WaitForChild("WhiteboardConstants"))
local MAX_POINTS = WhiteboardConstants.MAX_POINTS
local MARKER_PROMPT_NAME = "PickupMarkerPrompt"
local MARKER_COLORS = WhiteboardConstants.MARKER_COLORS

local WhiteboardService = {}
WhiteboardService.__index = WhiteboardService

local function getOrCreateRemote(container, className, name)
	local existing = container:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = container
	return instance
end

local function computeInstancePath(instance: Instance?): string?
	if not instance then
		return nil
	end

	local segments = {}
	local current = instance
	while current and current ~= game do
		table.insert(segments, 1, current.Name)
		current = current.Parent
	end
	return table.concat(segments, "/")
end

local function findLargestPart(model: Model?): BasePart?
	if not model then
		return nil
	end

	local chosen: BasePart? = nil
	local bestScore = -math.huge

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local nameLower = descendant.Name:lower()
			local preferred = 0
			if nameLower == "front" or nameLower == "back" then
				preferred = 3
			elseif nameLower:find("board") then
				preferred = 2
			elseif nameLower:find("stand") then
				preferred = -1
			end

			local area = descendant.Size.X * descendant.Size.Y
			local score = preferred * 1e6 + area

			if score > bestScore then
				chosen = descendant
				bestScore = score
			end
		end
	end

	return chosen
end

function WhiteboardService.new()
	local self = setmetatable({}, WhiteboardService)

	self._remotesFolder = getOrCreateRemote(ReplicatedStorage, "Folder", REMOTE_FOLDER_NAME)
	self._drawEvent = getOrCreateRemote(self._remotesFolder, "RemoteEvent", DRAW_EVENT_NAME)
	self._clearEvent = getOrCreateRemote(self._remotesFolder, "RemoteEvent", CLEAR_EVENT_NAME)
	self._saveEvent = getOrCreateRemote(self._remotesFolder, "RemoteEvent", SAVE_EVENT_NAME)
	self._syncFunction = getOrCreateRemote(self._remotesFolder, "RemoteFunction", SYNC_FUNCTION_NAME)

	self._datastore = DataStoreService:GetDataStore(DATASTORE_NAME)
	self._boardState = {
		points = {},
		lastSaved = 0,
	}
	self._markerTools = {}
	self._configuredParts = {} -- Tracks parts already wired with prompts
	self._markerToolsFolder = ReplicatedStorage:FindFirstChild("WhiteboardMarkerTools")
	if not self._markerToolsFolder then
		self._markerToolsFolder = Instance.new("Folder")
		self._markerToolsFolder.Name = "WhiteboardMarkerTools"
		self._markerToolsFolder.Parent = ReplicatedStorage
	end
	
	-- Marker spawning system
	self._spawnedMarkers = {} -- Track spawned marker models
	self._markerSpawnPositions = {} -- Store original spawn positions
	self._respawnTimers = {} -- Track respawn timers for each marker

	self:_loadPersistedState()
	self:_connectRemotes()
	self:_setupMarkers()
	self:_initializeMarkerSpawning()

	self._boardModel = Workspace:FindFirstChild("Whiteboard")
	self._boardPart = nil
	if self._boardModel and self._boardModel:IsA("Model") then
		self._boardPart = findLargestPart(self._boardModel)
	end
	self._defaultSurfaceId = computeInstancePath(self._boardPart)
	self._defaultFaceName = "Front"

	print("[WhiteboardService] ✅ Initialized")

	return self
end

function WhiteboardService:_loadPersistedState()
	local success, encoded = pcall(function()
		return self._datastore:GetAsync(DATASTORE_KEY)
	end)

	if success and encoded and type(encoded) == "string" then
		local decodedSuccess, decoded = pcall(function()
			return HttpService:JSONDecode(encoded)
		end)
		if decodedSuccess and type(decoded) == "table" then
			self._boardState.points = decoded.points or {}
			self._boardState.lastSaved = decoded.lastSaved or 0
			print(string.format("[WhiteboardService] ♻️ Loaded %d saved points", #self._boardState.points))
		end
	elseif not success then
		warn("[WhiteboardService] ⚠️ Failed to load persisted drawings:", encoded)
	end
end

function WhiteboardService:_connectRemotes()
	self._drawEvent.OnServerEvent:Connect(function(player, payload)
		self:_handleDraw(player, payload)
	end)

	self._clearEvent.OnServerEvent:Connect(function(player)
		self:_handleClear(player)
	end)

	self._saveEvent.OnServerEvent:Connect(function(player)
		self:_handleSave(player)
	end)

	self._syncFunction.OnServerInvoke = function(player)
		return {
			points = self._boardState.points,
			lastSaved = self._boardState.lastSaved,
		}
	end
end

function WhiteboardService:_validatePayload(payload)
	if type(payload) ~= "table" then
		return false
	end

	if type(payload.x) ~= "number" or type(payload.y) ~= "number" then
		return false
	end

	if type(payload.thickness) ~= "number" then
		return false
	end

	if type(payload.color) ~= "table" then
		return false
	end

	local c = payload.color
	if type(c.r) ~= "number" or type(c.g) ~= "number" or type(c.b) ~= "number" then
		return false
	end

	if payload.surfaceId ~= nil and type(payload.surfaceId) ~= "string" then
		return false
	end

	if payload.face ~= nil and type(payload.face) ~= "string" then
		return false
	end

	if payload.strokeId ~= nil then
		local strokeType = type(payload.strokeId)
		if strokeType ~= "string" and strokeType ~= "number" then
			return false
		end
	end

	if payload.newStroke ~= nil and type(payload.newStroke) ~= "boolean" then
		return false
	end

	return true
end

function WhiteboardService:_handleDraw(player, payload)
	if not self:_validatePayload(payload) then
		warn(string.format("[WhiteboardService] ❌ Invalid draw payload from %s", player.Name))
		return
	end

	local points = self._boardState.points
	if #points >= MAX_POINTS then
		table.remove(points, 1)
	end

	local strokeId = ""
	if payload.strokeId ~= nil then
		strokeId = tostring(payload.strokeId)
	end

	local surfaceId = payload.surfaceId or self._defaultSurfaceId
	if not surfaceId then
		surfaceId = "Workspace"
	end

	local faceName = payload.face or self._defaultFaceName or "Front"

	local entry = {
		x = payload.x,
		y = payload.y,
		thickness = math.clamp(payload.thickness, 1, 12),
		color = {
			r = math.clamp(payload.color.r, 0, 1),
			g = math.clamp(payload.color.g, 0, 1),
			b = math.clamp(payload.color.b, 0, 1),
		},
		surfaceId = surfaceId,
		face = faceName,
		strokeId = strokeId,
		newStroke = payload.newStroke == true,
	}

	table.insert(points, entry)

	self._drawEvent:FireAllClients(player, entry)
end

function WhiteboardService:_handleClear(player)
	print(string.format("[WhiteboardService] 🧹 Clear requested by %s", player.Name))
	self._boardState.points = {}
	self._clearEvent:FireAllClients(player)
end

function WhiteboardService:_handleSave(player)
	print(string.format("[WhiteboardService] 💾 Save requested by %s", player.Name))

	self._boardState.lastSaved = os.time()

	local success, err = pcall(function()
		local payload = HttpService:JSONEncode(self._boardState)
		self._datastore:SetAsync(DATASTORE_KEY, payload)
	end)

	if success then
		print("[WhiteboardService] ✅ Drawing saved")
	else
		warn("[WhiteboardService] ❌ Failed to save drawing:", err)
	end
end

function WhiteboardService:_setupMarkers()
	local markerFolder = Workspace:FindFirstChild("WhiteboardMarkers")
	if not markerFolder then
		warn("[WhiteboardService] ⚠️ Workspace.WhiteboardMarkers not found - marker pickup disabled")
		Workspace.ChildAdded:Connect(function(child)
			if child.Name == "WhiteboardMarkers" then
				task.defer(function()
					self:_setupMarkers()
				end)
			end
		end)
		return
	end

	self._markerFolder = markerFolder

	local function resolveMarkerContext(instance)
		local current = instance
		while current and current ~= markerFolder do
			if MARKER_COLORS[current.Name] then
				return current.Name, current
			end
			current = current.Parent
		end
		return nil
	end

	local function configureFromInstance(instance)
		local markerName, markerModel = resolveMarkerContext(instance)
		if not markerName then
			return
		end

		local basePart: BasePart? = nil
		if instance:IsA("BasePart") then
			basePart = instance
		elseif markerModel and markerModel:IsA("Model") then
			basePart = markerModel.PrimaryPart or markerModel:FindFirstChildWhichIsA("BasePart", true)
		elseif markerModel and markerModel:IsA("BasePart") then
			basePart = markerModel
		end

		if not basePart then
			return
		end

		if self._configuredParts[basePart] then
			return
		end

		self._configuredParts[basePart] = true

		self:_ensureToolTemplate(markerName, basePart, MARKER_COLORS[markerName])
		self:_configureMarkerPart(basePart, markerName)
	end

	for _, descendant in ipairs(markerFolder:GetDescendants()) do
		configureFromInstance(descendant)
	end

	markerFolder.DescendantAdded:Connect(function(descendant)
		configureFromInstance(descendant)
	end)

	markerFolder.ChildAdded:Connect(function(child)
		configureFromInstance(child)
		if child:IsA("Model") then
			child.DescendantAdded:Connect(function(desc)
				configureFromInstance(desc)
			end)
		end
	end)
end

function WhiteboardService:_ensureToolTemplate(markerName: string, sourcePart: BasePart?, color: Color3)
	if self._markerTools[markerName] then
		return self._markerTools[markerName]
	end

	if self._markerToolsFolder then
		local existing = self._markerToolsFolder:FindFirstChild(markerName)
		if existing and existing:IsA("Tool") then
			self._markerTools[markerName] = existing
			return existing
		end
	end

	local tool = Instance.new("Tool")
	tool.Name = markerName
	tool.RequiresHandle = true
	tool.CanBeDropped = true
	tool.ToolTip = markerName:gsub("Marker", "") .. " Marker"

	local handle: BasePart
	if sourcePart then
		local cloned = sourcePart:Clone()
		cloned.Name = "Handle"
		for _, descendant in ipairs(cloned:GetDescendants()) do
			if descendant:IsA("ProximityPrompt") then
				descendant:Destroy()
			elseif descendant:IsA("BasePart") then
				descendant.Anchored = false
				descendant.CanCollide = false
				descendant.Massless = true
			end
		end
		cloned.Anchored = false
		cloned.CanCollide = false
		cloned.Massless = true
		handle = cloned
	else
		local part = Instance.new("Part")
		part.Name = "Handle"
		part.Size = Vector3.new(0.25, 0.25, 1.3)
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Shape = Enum.PartType.Cylinder
		part.Anchored = false
		part.CanCollide = false
		part.Massless = true
		handle = part
	end

	handle.Parent = tool

	tool.Grip = CFrame.new(0, -handle.Size.Y * 0.4, 0) * CFrame.Angles(math.rad(90), 0, 0)

	if self._markerToolsFolder then
		tool.Parent = self._markerToolsFolder
	end

	self._markerTools[markerName] = tool

	return tool
end

function WhiteboardService:_configureMarkerPart(part: BasePart, markerName: string)
	if not part then
		return
	end

	part.Anchored = true
	part.CanCollide = true

	local prompt = part:FindFirstChild(MARKER_PROMPT_NAME)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = MARKER_PROMPT_NAME
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.Parent = part
	end

	prompt.ActionText = "Pick Up"
	prompt.ObjectText = markerName:gsub("Marker", "") .. " Marker"

	prompt.Triggered:Connect(function(player)
		self:_handleMarkerPickup(player, markerName)
	end)
end

function WhiteboardService:_handleMarkerPickup(player: Player, markerName: string)
	if type(markerName) ~= "string" or not MARKER_COLORS[markerName] then
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	self:_removeExistingMarkers(player, markerName)

	local existingTool = (player.Character and player.Character:FindFirstChild(markerName)) or backpack:FindFirstChild(markerName)
	if existingTool then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and existingTool.Parent == backpack then
			humanoid:EquipTool(existingTool)
		end
		return
	end

	-- Hide the marker model when picked up
	self:_hideMarker(markerName)
	
	-- Start respawn timer
	self:_startRespawnTimer(markerName)

	local template = self:_ensureToolTemplate(markerName, self:_findMarkerPart(markerName), MARKER_COLORS[markerName])
	if not template then
		return
	end

	local tool = template:Clone()
	tool.Parent = backpack

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		task.defer(function()
			if tool.Parent == backpack or tool.Parent == player.Character then
				humanoid:EquipTool(tool)
			end
		end)
	end
end

function WhiteboardService:_findMarkerPart(markerName: string): BasePart?
	if not self._markerFolder then
		return nil
	end

	local marker = self._markerFolder:FindFirstChild(markerName, true)
	if marker and marker:IsA("BasePart") then
		return marker
	end

	return nil
end

function WhiteboardService:_removeExistingMarkers(player: Player, keepName: string?)
	local function purge(container)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and MARKER_COLORS[child.Name] and child.Name ~= keepName then
				child:Destroy()
			end
		end
	end

	purge(player.Character)
	purge(player:FindFirstChildOfClass("Backpack"))
end

function WhiteboardService:_initializeMarkerSpawning()
	-- Find existing markers in workspace or create spawn points
	if self._markerFolder then
		-- Use existing markers from workspace
		for markerName, _ in pairs(MARKER_COLORS) do
			local markerPart = self._markerFolder:FindFirstChild(markerName, true)
			if markerPart and markerPart:IsA("BasePart") then
				self._markerSpawnPositions[markerName] = markerPart.Position
				self._spawnedMarkers[markerName] = markerPart
			elseif markerPart and markerPart:IsA("Model") then
				local basePart = markerPart.PrimaryPart or markerPart:FindFirstChildWhichIsA("BasePart", true)
				if basePart then
					self._markerSpawnPositions[markerName] = basePart.Position
					self._spawnedMarkers[markerName] = markerPart
				end
			end
		end
	else
		-- Create markers at default spawn points
		for markerName, spawnPos in pairs(WhiteboardConstants.MARKER_SPAWN_POINTS) do
			self:_spawnMarker(markerName, spawnPos)
		end
	end
end

function WhiteboardService:_spawnMarker(markerName: string, position: Vector3)
	if not MARKER_COLORS[markerName] then
		return
	end
	
	local color = MARKER_COLORS[markerName]
	
	-- Create marker model (simple cylinder for now, can be replaced with custom model)
	local markerModel = Instance.new("Model")
	markerModel.Name = markerName
	
	local markerPart = Instance.new("Part")
	markerPart.Name = markerName
	markerPart.Size = Vector3.new(0.3, 0.3, 1.2)
	markerPart.Shape = Enum.PartType.Cylinder
	markerPart.Color = color
	markerPart.Material = Enum.Material.SmoothPlastic
	markerPart.Anchored = true
	markerPart.CanCollide = true
	markerPart.Position = position
	markerPart.Parent = markerModel
	
	markerModel.PrimaryPart = markerPart
	markerModel.Parent = self._markerFolder or Workspace
	
	-- Configure pickup prompt
	self:_configureMarkerPart(markerPart, markerName)
	
	self._spawnedMarkers[markerName] = markerModel
	self._markerSpawnPositions[markerName] = position
	
	print(string.format("[WhiteboardService] ✅ Spawned %s at %s", markerName, tostring(position)))
end

function WhiteboardService:_hideMarker(markerName: string)
	local marker = self._spawnedMarkers[markerName]
	if marker then
		marker:Destroy()
		self._spawnedMarkers[markerName] = nil
	end
end

function WhiteboardService:_startRespawnTimer(markerName: string)
	-- Cancel existing timer if any
	if self._respawnTimers[markerName] then
		task.cancel(self._respawnTimers[markerName])
	end
	
	local RESPAWN_TIME = WhiteboardConstants.MARKER_RESPAWN_TIME
	local spawnPos = self._markerSpawnPositions[markerName]
	
	if not spawnPos then
		warn(string.format("[WhiteboardService] ⚠️ No spawn position for %s", markerName))
		return
	end
	
	self._respawnTimers[markerName] = task.delay(RESPAWN_TIME, function()
		self._respawnTimers[markerName] = nil
		if not self._spawnedMarkers[markerName] then
			self:_spawnMarker(markerName, spawnPos)
		end
	end)
end

function WhiteboardService.init()
	if not ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME) then
		-- new folder gets created inside constructor
	end

	WhiteboardService.new()
end

return WhiteboardService

