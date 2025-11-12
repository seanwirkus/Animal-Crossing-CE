--[[
	WhiteboardController.luau
	
	Client-side controller that attaches to Workspace.Whiteboard and Workspace.WhiteboardMarkers.
	Features:
	- Marker pickup using proximity prompts (equippable tools)
	- Drawing on the whiteboard surface with the equipped marker color
	- Real-time sync across clients through WhiteboardService remotes
	- Clear (Shift + C) and Save (Shift + S) shortcuts
	- Automatic recreation of existing drawings from the server
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer
local REMOTE_FOLDER_NAME = "WhiteboardRemotes"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local WhiteboardConstants = require(sharedFolder:WaitForChild("WhiteboardConstants"))
local CANVAS_SIZE = WhiteboardConstants.CANVAS_SIZE
local DEFAULT_THICKNESS = WhiteboardConstants.DEFAULT_THICKNESS
local MARKER_COLORS = WhiteboardConstants.MARKER_COLORS

local WhiteboardController = {}
WhiteboardController.__index = WhiteboardController

local ROOT_SERVICE_LOOKUP = {
	Workspace = Workspace,
}

local findInstanceByPath
local makeSurfaceKey

local function computeInstancePath(instance: Instance): string
	local segments = {}
	local current = instance
	while current and current ~= game do
		table.insert(segments, 1, current.Name)
		current = current.Parent
	end
	return table.concat(segments, "/")
end

function WhiteboardController:_resolvePart(surfaceId: string?): BasePart?
	if not surfaceId then
		return self.boardPart
	end

	local existing = self._surfaceIdToPart[surfaceId]
	if existing and existing.Parent then
		return existing
	end

	local instance = findInstanceByPath(surfaceId)
	if instance and instance:IsA("BasePart") then
		self._surfaceIdToPart[surfaceId] = instance
		return instance
	end

	return nil
end

function WhiteboardController:_ensureSurface(surfaceId: string?, faceName: string?)
	local targetPart = self:_resolvePart(surfaceId)
	if not targetPart then
		return nil
	end

	local faceEnum = Enum.NormalId[faceName or self._defaultFaceName or "Front"]
	if not faceEnum then
		faceEnum = Enum.NormalId.Front
	end

	local key = makeSurfaceKey(surfaceId, faceName or faceEnum.Name)
	local existing = self._surfaces[key]
	if existing and existing.surfaceGui and existing.canvas then
		return existing
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "MarkerSurface_" .. faceEnum.Name
	surfaceGui.Face = faceEnum
	surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surfaceGui.CanvasSize = CANVAS_SIZE
	surfaceGui.AlwaysOnTop = false
	surfaceGui.LightInfluence = 0
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	local boardSize = math.max(targetPart.Size.X, targetPart.Size.Y)
	if boardSize <= 0 then
		boardSize = 1
	end
	surfaceGui.PixelsPerStud = CANVAS_SIZE.X / boardSize
	surfaceGui.Parent = targetPart

	local canvasFrame = Instance.new("Frame")
	canvasFrame.Name = "DrawingCanvas"
	canvasFrame.Size = UDim2.fromScale(1, 1)
	canvasFrame.BackgroundTransparency = 1
	canvasFrame.BorderSizePixel = 0
	canvasFrame.ClipsDescendants = true
	canvasFrame.Parent = surfaceGui

	local info = {
		part = targetPart,
		surfaceId = surfaceId or computeInstancePath(targetPart),
		face = faceEnum,
		faceName = faceEnum.Name,
		surfaceGui = surfaceGui,
		canvas = canvasFrame,
	}

	self._surfaces[key] = info
	self._surfaceIdToPart[info.surfaceId] = targetPart

	return info
end

function WhiteboardController:_getSurface(surfaceId: string?, faceName: string?)
	local key = makeSurfaceKey(surfaceId or self._defaultSurfaceId, faceName or self._defaultFaceName)
	local surface = self._surfaces[key]
	if surface then
		return surface
	end
	return self:_ensureSurface(surfaceId or self._defaultSurfaceId, faceName or self._defaultFaceName)
end

function WhiteboardController:_clearAllCanvases()
	for _, info in pairs(self._surfaces) do
		if info.canvas then
			info.canvas:ClearAllChildren()
		end
	end

	self._strokeStateBySource = {}
	self._lastLocalPointBySurface = {}
	self._activeSurfaceKey = nil
	self._currentStrokeId = nil
	self._pendingStrokeReset = false
end

local function createStrokeDot(entry)
	local dot = Instance.new("Frame")
	dot.Name = "StrokeDot"
	dot.BackgroundColor3 = Color3.new(entry.color.r, entry.color.g, entry.color.b)
	dot.BorderSizePixel = 0
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.new(0, entry.thickness, 0, entry.thickness)
	dot.Position = UDim2.fromScale(entry.x, entry.y)
	dot.BackgroundTransparency = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot

	return dot
end

local function createStrokeSegment(fromPoint: Vector2, toPoint: Vector2, entry)
	local delta = toPoint - fromPoint
	local distance = delta.Magnitude
	if distance <= 0 then
		return nil
	end

	local angle = math.deg(math.atan2(delta.Y, delta.X))
	local midpoint = (fromPoint + toPoint) * 0.5

	local frame = Instance.new("Frame")
	frame.Name = "StrokeSegment"
	frame.BackgroundColor3 = Color3.new(entry.color.r, entry.color.g, entry.color.b)
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.new(distance, 0, 0, entry.thickness)
	frame.Position = UDim2.fromScale(midpoint.X, midpoint.Y)
	frame.Rotation = -angle

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	return frame
end

findInstanceByPath = function(path: string): Instance?
	if not path or path == "" then
		return nil
	end

	local segments = string.split(path, "/")
	local current: Instance = game

	for _, segment in ipairs(segments) do
		if segment == "" or segment == "game" then
			continue
		end

		local service = ROOT_SERVICE_LOOKUP[segment]
		if service then
			current = service
		else
			if not current then
				return nil
			end
			current = current:FindFirstChild(segment)
		end

		if not current then
			return nil
		end
	end

	return current
end

makeSurfaceKey = function(surfaceId: string?, faceName: string?): string
	return string.format("%s::%s", surfaceId or "unknown", faceName or "Front")
end

local FACE_NORMALS = {
	Front = Vector3.new(0, 0, -1),
	Back = Vector3.new(0, 0, 1),
	Right = Vector3.new(1, 0, 0),
	Left = Vector3.new(-1, 0, 0),
	Top = Vector3.new(0, 1, 0),
	Bottom = Vector3.new(0, -1, 0),
}

local FACE_OFFSETS = {
	Front = Vector3.new(0, 0, -0.5),
	Back = Vector3.new(0, 0, 0.5),
	Right = Vector3.new(0.5, 0, 0),
	Left = Vector3.new(-0.5, 0, 0),
	Top = Vector3.new(0, 0.5, 0),
	Bottom = Vector3.new(0, -0.5, 0),
}

local function findLargestPart(model)
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

function WhiteboardController.new()
	local self = setmetatable({}, WhiteboardController)

	self.player = LOCAL_PLAYER
	self.mouse = self.player:GetMouse()

	self.boardModel = Workspace:FindFirstChild("Whiteboard")
	self.markersModel = Workspace:FindFirstChild("WhiteboardMarkers")

	if not self.boardModel or not self.boardModel:IsA("Model") then
		warn("[WhiteboardController] ❌ Workspace.Whiteboard model not found")
		return self
	end

	self.boardPart = findLargestPart(self.boardModel)
	if not self.boardPart then
		warn("[WhiteboardController] ❌ Failed to locate a drawing surface within Workspace.Whiteboard")
		return self
	end

	self.currentColor = nil
	self.isDrawing = false

	self.surfaceGui = nil
	self.canvasFrame = nil
	self.selectionBox = nil

	self._activeTool = nil
	self._toolConnections = {}
	self._containerConnections = {}
	self._indicatorGui = nil
	self._indicatorFrame = nil
	self._indicatorSwatch = nil

	self._surfaces = {}
	self._surfaceIdToPart = {}
	self._strokeStateBySource = {}
	self._lastLocalPointBySurface = {}
	self._strokeCounter = 0
	self._currentStrokeId = nil
	self._pendingStrokeReset = false
	self._defaultSurfaceId = nil
	self._defaultFaceName = nil
	self._defaultSurfaceKey = nil
	self._activeSurfaceKey = nil

	self.remotesFolder = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME, 5)
	if not self.remotesFolder then
		warn("[WhiteboardController] ❌ Whiteboard remotes folder missing in ReplicatedStorage")
		return self
	end

	self.drawEvent = self.remotesFolder:FindFirstChild("Draw")
	self.clearEvent = self.remotesFolder:FindFirstChild("Clear")
	self.saveEvent = self.remotesFolder:FindFirstChild("Save")
	self.syncFunction = self.remotesFolder:FindFirstChild("Sync")

	if not (self.drawEvent and self.clearEvent and self.saveEvent and self.syncFunction) then
		warn("[WhiteboardController] ❌ One or more Whiteboard remotes are missing")
		return self
	end

	self:_setupSurfaceGui()
	self:_setupSelectionHighlight()
	self:_setupInputHandlers()
	self:_connectRemotes()
	self:_trackMarkerTools()
	self:_createMarkerIndicator()
	self:_requestInitialSync()

	print("[WhiteboardController] ✅ Ready")

	return self
end

function WhiteboardController:_setupSurfaceGui()
	-- Check if board part name indicates which face to use
	local partNameLower = self.boardPart.Name:lower()
	local useBackFace = partNameLower == "back"
	
	local existing = self.boardPart:FindFirstChildOfClass("SurfaceGui")
	if existing then
		self.surfaceGui = existing
		-- Update face if needed
		if useBackFace and self.surfaceGui.Face ~= Enum.NormalId.Back then
			self.surfaceGui.Face = Enum.NormalId.Back
		elseif not useBackFace and self.surfaceGui.Face ~= Enum.NormalId.Front then
			self.surfaceGui.Face = Enum.NormalId.Front
		end
	else
		self.surfaceGui = Instance.new("SurfaceGui")
		self.surfaceGui.Face = useBackFace and Enum.NormalId.Back or Enum.NormalId.Front
		self.surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		self.surfaceGui.CanvasSize = CANVAS_SIZE
		self.surfaceGui.AlwaysOnTop = false
		self.surfaceGui.LightInfluence = 0
		self.surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		-- Use the larger dimension for better quality
		local boardSize = math.max(self.boardPart.Size.X, self.boardPart.Size.Y)
		self.surfaceGui.PixelsPerStud = CANVAS_SIZE.X / boardSize
		self.surfaceGui.Parent = self.boardPart
	end

	local existingCanvas = self.surfaceGui:FindFirstChild("DrawingCanvas")
	if existingCanvas and existingCanvas:IsA("Frame") then
		self.canvasFrame = existingCanvas
	else
		self.canvasFrame = Instance.new("Frame")
		self.canvasFrame.Name = "DrawingCanvas"
		self.canvasFrame.Size = UDim2.fromScale(1, 1)
		self.canvasFrame.BackgroundTransparency = 1
		self.canvasFrame.BorderSizePixel = 0
		self.canvasFrame.ClipsDescendants = true
		self.canvasFrame.Parent = self.surfaceGui
	end

	local surfaceId = computeInstancePath(self.boardPart)
	local faceName = self.surfaceGui.Face.Name
	local surfaceKey = makeSurfaceKey(surfaceId, faceName)

	self._defaultSurfaceId = surfaceId
	self._defaultFaceName = faceName
	self._defaultSurfaceKey = surfaceKey

	self._surfaceIdToPart[surfaceId] = self.boardPart
	self._surfaces[surfaceKey] = {
		part = self.boardPart,
		surfaceId = surfaceId,
		face = self.surfaceGui.Face,
		faceName = faceName,
		surfaceGui = self.surfaceGui,
		canvas = self.canvasFrame,
	}
end

function WhiteboardController:_setupSelectionHighlight()
	if not self.markersModel then
		warn("[WhiteboardController] ⚠️ Workspace.WhiteboardMarkers not found - markers will still work but world highlight is disabled")
		return
	end

	self.selectionBox = Instance.new("SelectionBox")
	self.selectionBox.LineThickness = 0.1
	self.selectionBox.Color3 = Color3.fromRGB(255, 255, 255)
	self.selectionBox.Visible = false
	self.selectionBox.Parent = self.markersModel
end

function WhiteboardController:_hasActiveTool(): boolean
	return self._activeTool ~= nil and self.currentColor ~= nil
end

function WhiteboardController:_updateSelectionHighlight(markerName: string?)
	if not self.selectionBox then
		return
	end

	if not markerName or not self.markersModel then
		self.selectionBox.Visible = false
		self.selectionBox.Adornee = nil
		return
	end

	local markerPart = self.markersModel:FindFirstChild(markerName, true)
	if markerPart and markerPart:IsA("BasePart") then
		self.selectionBox.Adornee = markerPart
		self.selectionBox.Visible = true
	else
		self.selectionBox.Visible = false
		self.selectionBox.Adornee = nil
	end
end

function WhiteboardController:_updateIndicator(color: Color3?)
	if not self._indicatorFrame or not self._indicatorSwatch then
		return
	end

	if not color then
		self._indicatorFrame.Visible = false
		return
	end

	self._indicatorSwatch.BackgroundColor3 = color
	self._indicatorFrame.Visible = true
end

function WhiteboardController:_setActiveTool(tool, fallbackColor: Color3?)
	if self._activeTool == tool then
		return
	end

	local finalColor = fallbackColor
	local handle = tool and tool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		finalColor = handle.Color
	end
	if not finalColor then
		finalColor = MARKER_COLORS[tool.Name] or Color3.new(1, 1, 1)
	end

	self._activeTool = tool
	self.currentColor = finalColor
	self:_updateSelectionHighlight(tool and tool.Name or nil)
	self:_updateIndicator(finalColor)

	-- Don't filter mouse target - we want to hit the board, not the marker
	if self.mouse then
		self.mouse.TargetFilter = nil
	end
end

function WhiteboardController:_clearActiveTool(tool)
	if tool and tool ~= self._activeTool then
		return
	end

	self:_stopDrawing()
	self._activeTool = nil
	self.currentColor = nil
	self:_updateSelectionHighlight(nil)
	self:_updateIndicator(nil)

	if self.mouse then
		self.mouse.TargetFilter = nil
	end
end

function WhiteboardController:_startDrawing()
	if not self:_hasActiveTool() then
		return
	end

	self.isDrawing = true
	self._pendingStrokeReset = true
	self._strokeCounter += 1
	self._currentStrokeId = string.format("%d-%d", self.player.UserId, self._strokeCounter)
	self:_emitCurrentPoint()
end

function WhiteboardController:_stopDrawing()
	self.isDrawing = false
	self._pendingStrokeReset = false
	self._currentStrokeId = nil
	self._activeSurfaceKey = nil
	self._lastLocalPointBySurface = {}
end

function WhiteboardController:_registerTool(tool: Instance)
	if not tool:IsA("Tool") then
		return
	end

	local fallbackColor = MARKER_COLORS[tool.Name]

	if self._toolConnections[tool] then
		return
	end

	local connections = {}

	connections[#connections + 1] = tool.Equipped:Connect(function()
		self:_setActiveTool(tool, fallbackColor)
	end)

	connections[#connections + 1] = tool.Unequipped:Connect(function()
		self:_clearActiveTool(tool)
	end)

	connections[#connections + 1] = tool.Destroying:Connect(function()
		self:_disconnectTool(tool)
	end)

	connections[#connections + 1] = tool.Activated:Connect(function()
		self:_startDrawing()
	end)

	connections[#connections + 1] = tool.Deactivated:Connect(function()
		self:_stopDrawing()
	end)

	connections[#connections + 1] = tool.ChildAdded:Connect(function(child)
		if tool == self._activeTool and child.Name == "Handle" and child:IsA("BasePart") then
			self:_setActiveTool(tool, fallbackColor)
		end
	end)

	self._toolConnections[tool] = connections

	if tool.Parent == self.player.Character then
		self:_setActiveTool(tool, fallbackColor)
	end
end

function WhiteboardController:_disconnectTool(tool)
	local connections = self._toolConnections[tool]
	if connections then
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
		self._toolConnections[tool] = nil
	end

	if self._activeTool == tool then
		self:_clearActiveTool(tool)
	end
end

function WhiteboardController:_observeToolContainer(container: Instance)
	if self._containerConnections[container] then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		self:_registerTool(child)
	end

	local addedConn = container.ChildAdded:Connect(function(child)
		self:_registerTool(child)
	end)

	local ancestryConn
	ancestryConn = container.AncestryChanged:Connect(function(_, parent)
		if not parent then
			addedConn:Disconnect()
			if ancestryConn then
				ancestryConn:Disconnect()
			end
			self._containerConnections[container] = nil
		end
	end)

	self._containerConnections[container] = {addedConn, ancestryConn}
end

function WhiteboardController:_trackMarkerTools()
	local backpack = self.player:WaitForChild("Backpack")
	self:_observeToolContainer(backpack)

	local function onCharacter(character)
		self:_observeToolContainer(character)
	end

	if self.player.Character then
		onCharacter(self.player.Character)
	end

	self.player.CharacterAdded:Connect(onCharacter)
end

function WhiteboardController:_setupInputHandlers()
	self.mouse.Button1Down:Connect(function()
		if not self:_hasActiveTool() then
			return
		end

		-- Allow drawing anywhere - no board check needed
		self:_startDrawing()
	end)

	self.mouse.Button1Up:Connect(function()
		self:_stopDrawing()
	end)

	RunService.RenderStepped:Connect(function()
		if self.isDrawing and self:_hasActiveTool() then
			self:_emitCurrentPoint()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.C and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			self:_requestClear()
		elseif input.KeyCode == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			self:_requestSave()
		end
	end)
end

function WhiteboardController:_isMouseOverBoard(): boolean
	local target = self.mouse.Target
	if not target then
		return false
	end

	if target == self.boardPart then
		return true
	end

	return target:IsDescendantOf(self.boardModel)
end

function WhiteboardController:_worldToCanvas(part: BasePart, face: Enum.NormalId, hitPosition: Vector3): Vector2?
	if not part or not face then
		return nil
	end

	-- Convert world position to object space relative to the board part
	local relative = part.CFrame:PointToObjectSpace(hitPosition)

	local halfX = part.Size.X / 2
	local halfY = part.Size.Y / 2
	local halfZ = part.Size.Z / 2

	local u, v

	if face == Enum.NormalId.Front then
		u = 1 - ((relative.X / halfX + 1) * 0.5)
		v = 1 - ((relative.Y / halfY + 1) * 0.5)
	elseif face == Enum.NormalId.Back then
		u = (relative.X / halfX + 1) * 0.5
		v = 1 - ((relative.Y / halfY + 1) * 0.5)
	elseif face == Enum.NormalId.Right then
		u = 1 - ((relative.Z / halfZ + 1) * 0.5)
		v = 1 - ((relative.Y / halfY + 1) * 0.5)
	elseif face == Enum.NormalId.Left then
		u = (relative.Z / halfZ + 1) * 0.5
		v = 1 - ((relative.Y / halfY + 1) * 0.5)
	elseif face == Enum.NormalId.Top then
		u = 1 - ((relative.X / halfX + 1) * 0.5)
		v = (relative.Z / halfZ + 1) * 0.5
	elseif face == Enum.NormalId.Bottom then
		u = 1 - ((relative.X / halfX + 1) * 0.5)
		v = 1 - ((relative.Z / halfZ + 1) * 0.5)
	else
		u = 1 - ((relative.X / halfX + 1) * 0.5)
		v = 1 - ((relative.Y / halfY + 1) * 0.5)
	end

	-- Clamp to valid range
	u = math.clamp(u, 0, 1)
	v = math.clamp(v, 0, 1)

	return Vector2.new(u, v)
end

function WhiteboardController:_emitCurrentPoint()
	if not self:_hasActiveTool() or not self.currentColor then
		return
	end

	local unitRay = self.mouse.UnitRay
	if not unitRay then
		return
	end

	local rayOrigin = unitRay.Origin
	local rayDirection = unitRay.Direction
	if rayDirection.Magnitude < 1e-6 then
		return
	end
	rayDirection = rayDirection.Unit

	local targetPart = self.mouse.Target
	local targetFace = self.mouse.TargetSurface

	if not targetPart or not targetPart:IsA("BasePart") then
		targetPart = self.boardPart
	end

	if not targetFace then
		if targetPart == self.boardPart and self.surfaceGui then
			targetFace = self.surfaceGui.Face
		else
			targetFace = Enum.NormalId.Front
		end
	end

	local faceName = targetFace.Name
	local surfaceId = computeInstancePath(targetPart)
	local surfaceInfo = self:_getSurface(surfaceId, faceName)
	if not surfaceInfo then
		return
	end

	local normalLocal = FACE_NORMALS[faceName] or FACE_NORMALS.Front
	local offsetLocal = FACE_OFFSETS[faceName] or FACE_OFFSETS.Front
	local faceNormal = surfaceInfo.part.CFrame:VectorToWorldSpace(normalLocal)
	local faceCenter = surfaceInfo.part.CFrame:PointToWorldSpace(Vector3.new(
		offsetLocal.X * surfaceInfo.part.Size.X,
		offsetLocal.Y * surfaceInfo.part.Size.Y,
		offsetLocal.Z * surfaceInfo.part.Size.Z
	))

	local toPlane = faceCenter - rayOrigin
	local denom = rayDirection:Dot(faceNormal)

	local projectedPosition
	if math.abs(denom) > 0.001 then
		local t = toPlane:Dot(faceNormal) / denom
		if t >= 0 then
			projectedPosition = rayOrigin + rayDirection * t
		else
			local offset = (rayOrigin - faceCenter):Dot(faceNormal)
			projectedPosition = rayOrigin - faceNormal * offset
		end
	else
		local offset = (rayOrigin - faceCenter):Dot(faceNormal)
		projectedPosition = rayOrigin - faceNormal * offset
	end

	local canvasCoord = self:_worldToCanvas(surfaceInfo.part, surfaceInfo.face, projectedPosition)
	if not canvasCoord then
		return
	end

	local surfaceKey = makeSurfaceKey(surfaceInfo.surfaceId, surfaceInfo.faceName)
	local lastLocal = self._lastLocalPointBySurface[surfaceKey]
	local isStart = false

	if self._pendingStrokeReset or self._activeSurfaceKey ~= surfaceKey then
		isStart = true
		self._pendingStrokeReset = false
		self._activeSurfaceKey = surfaceKey
		self._lastLocalPointBySurface[surfaceKey] = nil
		lastLocal = nil
	end

	if lastLocal then
		local deltaFromLast = (canvasCoord - lastLocal).Magnitude
		if deltaFromLast < 0.002 then
			return
		end
	else
		isStart = true
	end

	self._lastLocalPointBySurface[surfaceKey] = canvasCoord

	if not self._currentStrokeId then
		self._strokeCounter += 1
		self._currentStrokeId = string.format("%d-%d", self.player.UserId, self._strokeCounter)
		isStart = true
	end

	local payload = {
		x = canvasCoord.X,
		y = canvasCoord.Y,
		thickness = DEFAULT_THICKNESS,
		color = {
			r = self.currentColor.R,
			g = self.currentColor.G,
			b = self.currentColor.B,
		},
		surfaceId = surfaceInfo.surfaceId,
		face = surfaceInfo.faceName,
		strokeId = self._currentStrokeId,
		newStroke = isStart,
	}

	self:_renderPoint(payload, "local")
	self.drawEvent:FireServer(payload)
end
function WhiteboardController:_renderPoint(entry, sourceKey: string?)
	sourceKey = sourceKey or "shared"

	if type(entry) ~= "table" or not entry.x or not entry.y then
		return
	end

	local surfaceInfo = self:_getSurface(entry.surfaceId, entry.face)
	if not surfaceInfo or not surfaceInfo.canvas then
		return
	end

	local state = self._strokeStateBySource[sourceKey]
	if not state then
		state = {
			strokeId = nil,
			lastPoint = nil,
		}
		self._strokeStateBySource[sourceKey] = state
	end

	local strokeId = entry.strokeId or ""
	if entry.newStroke or state.strokeId ~= strokeId then
		state.strokeId = strokeId
		state.lastPoint = nil
	end

	local currentPoint = Vector2.new(entry.x, entry.y)

	if state.lastPoint then
		local segment = createStrokeSegment(state.lastPoint, currentPoint, entry)
		if segment then
			segment.Parent = surfaceInfo.canvas
		end
	else
		local dot = createStrokeDot(entry)
		dot.Parent = surfaceInfo.canvas
	end

	state.lastPoint = currentPoint

	-- Ensure a dot at the current position to avoid gaps at stroke endpoints
	local endDot = createStrokeDot(entry)
	endDot.Parent = surfaceInfo.canvas
end

function WhiteboardController:_requestClear()
	if not self:_hasActiveTool() then
		return
	end

	self:_clearAllCanvases()
	self.clearEvent:FireServer()
end

function WhiteboardController:_requestSave()
	self.saveEvent:FireServer()
end

function WhiteboardController:_connectRemotes()
	self.drawEvent.OnClientEvent:Connect(function(sourcePlayer, payload)
		if sourcePlayer == self.player then
			return
		end
		local sourceKey = "remote"
		if typeof(sourcePlayer) == "Instance" and sourcePlayer:IsA("Player") then
			sourceKey = string.format("player_%d", sourcePlayer.UserId)
		end
		self:_renderPoint(payload, sourceKey)
	end)

	self.clearEvent.OnClientEvent:Connect(function()
		self:_clearAllCanvases()
	end)
end

function WhiteboardController:_requestInitialSync()
	local success, data = pcall(function()
		return self.syncFunction:InvokeServer()
	end)

	if success and data and type(data.points) == "table" then
		self:_clearAllCanvases()
		for _, entry in ipairs(data.points) do
			if type(entry) == "table" then
				entry.surfaceId = entry.surfaceId or self._defaultSurfaceId
				entry.face = entry.face or self._defaultFaceName
				self:_renderPoint(entry, "sync")
			end
		end
	else
		if not success then
			warn("[WhiteboardController] ⚠️ Failed to sync drawing:", data)
		end
	end
end

function WhiteboardController:_createMarkerIndicator()
	local playerGui = self.player:WaitForChild("PlayerGui")
	local screen = Instance.new("ScreenGui")
	screen.Name = "MarkerHUD"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Enabled = true
	screen.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "MarkerIndicator"
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.Position = UDim2.new(0, 24, 1, -24)
	frame.Size = UDim2.new(0, 120, 0, 48)
	frame.BackgroundColor3 = Color3.fromRGB(33, 37, 42)
	frame.BackgroundTransparency = 0.05
	frame.Visible = false
	frame.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 160, 255)
	stroke.Thickness = 1
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 12, 0, 4)
	label.Size = UDim2.new(1, -24, 0, 18)
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(210, 225, 255)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "Marker"
	label.Parent = frame

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.Size = UDim2.new(0, 30, 0, 30)
	swatch.Position = UDim2.new(0, 12, 0, 12)
	swatch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	swatch.BackgroundTransparency = 0
	swatch.Parent = frame

	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(1, 0)
	swatchCorner.Parent = swatch

	self._indicatorGui = screen
	self._indicatorFrame = frame
	self._indicatorSwatch = swatch

	self:_updateIndicator(nil)
end

function WhiteboardController.init()
	return WhiteboardController.new()
end

return WhiteboardController

