--[[
	NookPlane.luau

	Cinematic flight cutscene for the Dodo Airlines seaplane.
	Loads the high fidelity plane asset, flies it along an arc,
	and keeps the camera locked with an Animal Crossing style framing.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local NOOK_PLANE_ASSET_ID = "rbxassetid://120092408090390"
local FALLBACK_PONTOON_COLOR = Color3.fromRGB(255, 200, 100)

local DEFAULT_DURATION = 12
local DEFAULT_ARC_HEIGHT = 40
local DEFAULT_BANK_ANGLE = 12
local DEFAULT_BOB_HEIGHT = 1.8
local DEFAULT_BOB_FREQUENCY = 1.25
local DEFAULT_CAMERA_OFFSET = Vector3.new(-12, 20, 46) -- (Right, Up, Back)
local DEFAULT_LOOK_AHEAD_DISTANCE = 24
local CAMERA_LERP_ALPHA = 0.15
local WAYPOINT_SAMPLE_EPSILON = 0.025

local NookPlane = {}

local _player = Players.LocalPlayer
local _camera = workspace.CurrentCamera

local _isFlying = false
local _plane = nil
local _flightPath = nil
local _flightDuration = DEFAULT_DURATION
local _flightStartTime = 0
local _arcHeight = DEFAULT_ARC_HEIGHT
local _bankAngle = DEFAULT_BANK_ANGLE
local _bobHeight = DEFAULT_BOB_HEIGHT
local _bobFrequency = DEFAULT_BOB_FREQUENCY
local _cameraOffset = DEFAULT_CAMERA_OFFSET
local _lookAheadDistance = DEFAULT_LOOK_AHEAD_DISTANCE
local _completionCallback = nil
local _completionSignaled = false

local _renderConnection = nil
local _originalCameraType = nil
local _originalCameraSubject = nil
local _previousModalState = false
local _coreGuiWasHidden = false

local function cloneVectorPath(path)
    local cloned = {}
    for i = 1, #path do
        cloned[i] = path[i]
    end
    return cloned
end

local function ensurePrimaryPart(model)
    if model.PrimaryPart then
        return model.PrimaryPart
    end

    local primary = model:FindFirstChildWhichIsA("BasePart", true)
    if primary then
        model.PrimaryPart = primary
    end

    return primary
end

local function ensurePilotSeat(model)
    local seat = model:FindFirstChildWhichIsA("Seat", true)
    if not seat then
        local primary = ensurePrimaryPart(model)
        if not primary then
            return nil
        end

        seat = Instance.new("Seat")
        seat.Name = "PilotSeat"
        seat.Size = Vector3.new(2, 1, 2)
        seat.Transparency = 1
        seat.CanCollide = false
        seat.Anchored = false
        seat.CFrame = primary.CFrame * CFrame.new(0, 1.5, 0)
        seat.Parent = model

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = primary
        weld.Part1 = seat
        weld.Parent = seat
    end

    seat.Name = "PilotSeat"
    seat.CanCollide = false
    seat.Anchored = false

    if model.PrimaryPart then
        local hasWeld = false

        for _, descendant in ipairs(seat:GetDescendants()) do
            if descendant:IsA("WeldConstraint") then
                if descendant.Part0 == model.PrimaryPart or descendant.Part1 == model.PrimaryPart then
                    hasWeld = true
                    break
                end
            end
        end

        if not hasWeld then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = model.PrimaryPart
            weld.Part1 = seat
            weld.Parent = seat
        end
    end

    return seat
end

local function createFallbackPlane()
    local plane = Instance.new("Model")
    plane.Name = "NookPlane"

    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(10, 5, 15)
    body.Transparency = 1
    body.CanCollide = false
    body.Anchored = true
    body.Parent = plane

    local function createPontoon(name, offset)
        local pontoon = Instance.new("Part")
        pontoon.Name = name
        pontoon.Size = Vector3.new(2, 2, 12)
        pontoon.Transparency = 0.25
        pontoon.Color = FALLBACK_PONTOON_COLOR
        pontoon.Material = Enum.Material.SmoothPlastic
        pontoon.CanCollide = false
        pontoon.Anchored = false
        pontoon.CFrame = body.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        pontoon.Parent = plane

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Cylinder
        mesh.Parent = pontoon

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = body
        weld.Part1 = pontoon
        weld.Parent = pontoon
    end

    createPontoon("LeftPontoon", Vector3.new(-4, -3, 0))
    createPontoon("RightPontoon", Vector3.new(4, -3, 0))

    local seat = Instance.new("Seat")
    seat.Name = "PilotSeat"
    seat.Size = Vector3.new(2, 1, 2)
    seat.Transparency = 1
    seat.CanCollide = false
    seat.Anchored = false
    seat.CFrame = body.CFrame
    seat.Parent = plane

    local seatWeld = Instance.new("WeldConstraint")
    seatWeld.Part0 = body
    seatWeld.Part1 = seat
    seatWeld.Parent = seat

    plane.PrimaryPart = body
    return plane
end

local function loadPlaneModel()
    local success, objects = pcall(function()
        return game:GetObjects(NOOK_PLANE_ASSET_ID)
    end)

    if success and objects and #objects > 0 then
        local planeCandidate = nil

        for _, object in ipairs(objects) do
            if not planeCandidate and object:IsA("Model") then
                planeCandidate = object
            else
                object:Destroy()
            end
        end

        if planeCandidate then
            planeCandidate.Name = "NookPlane"

            for _, descendant in ipairs(planeCandidate:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Anchored = true
                    descendant.CanCollide = false
                end
            end

            ensurePrimaryPart(planeCandidate)
            ensurePilotSeat(planeCandidate)

            return planeCandidate
        end
    end

    warn("[NookPlane] ⚠️ Unable to load asset ", NOOK_PLANE_ASSET_ID, " - falling back to simple plane")
    return createFallbackPlane()
end

local function seatPlayer(plane)
    local character = _player.Character or _player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    local seat = ensurePilotSeat(plane)
    if not seat then
        return false
    end

    if seat.Occupant ~= humanoid then
        seat:Sit(humanoid)
    end

    return true
end

local function setupFlightCamera()
    _originalCameraType = _camera.CameraType
    _originalCameraSubject = _camera.CameraSubject
    _previousModalState = UserInputService.ModalEnabled

    _camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.ModalEnabled = true

    _coreGuiWasHidden = pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    end)
end

local function restoreCamera()
    if _camera then
        _camera.CameraType = _originalCameraType or Enum.CameraType.Custom

        if _originalCameraSubject then
            _camera.CameraSubject = _originalCameraSubject
        else
            local character = _player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    _camera.CameraSubject = humanoid
                end
            end
        end
    end

    UserInputService.ModalEnabled = _previousModalState

    if _coreGuiWasHidden then
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)
    end
end

local function updateCamera(planeCFrame, deltaTime)
    if not _camera then
        return
    end

    local offsetWorld = planeCFrame.RightVector * _cameraOffset.X
        + planeCFrame.UpVector * _cameraOffset.Y
        - planeCFrame.LookVector * _cameraOffset.Z

    local targetPosition = planeCFrame.Position + offsetWorld
    local lookTarget = planeCFrame.Position + planeCFrame.LookVector * _lookAheadDistance

    local currentCFrame = _camera.CFrame
    local lerpAlpha = CAMERA_LERP_ALPHA

    if deltaTime and deltaTime > 0 then
        lerpAlpha = 1 - math.pow(1 - CAMERA_LERP_ALPHA, deltaTime * 60)
    end

    lerpAlpha = math.clamp(lerpAlpha, 0, 1)

    local newPosition = targetPosition
    if currentCFrame then
        newPosition = currentCFrame.Position:Lerp(targetPosition, lerpAlpha)
    end

    _camera.CFrame = CFrame.new(newPosition, lookTarget)
end

local function computePlaneCFrame(elapsed)
    if not _flightPath or #_flightPath < 2 then
        local origin = _flightPath and _flightPath[1] or Vector3.new(0, 0, 0)
        return CFrame.new(origin), 1
    end

    local totalDuration = math.max(_flightDuration, 0.001)
    local overallProgress = math.clamp(elapsed / totalDuration, 0, 1)

    local segmentCount = #_flightPath - 1
    local segmentDuration = totalDuration / segmentCount
    local currentSegment = math.clamp(math.floor(elapsed / segmentDuration) + 1, 1, segmentCount)
    local segmentElapsed = elapsed - (currentSegment - 1) * segmentDuration
    local segmentAlpha = math.clamp(segmentElapsed / segmentDuration, 0, 1)

    local segmentStart = _flightPath[currentSegment]
    local segmentEnd = _flightPath[currentSegment + 1]

    local basePosition = segmentStart:Lerp(segmentEnd, segmentAlpha)
    local arcOffset = math.sin(segmentAlpha * math.pi) * _arcHeight
    basePosition = basePosition + Vector3.new(0, arcOffset, 0)

    if _bobHeight ~= 0 then
        local bobOffset = math.sin(elapsed * _bobFrequency * math.pi * 2) * _bobHeight
        basePosition = basePosition + Vector3.new(0, bobOffset, 0)
    end

    local sampleAlpha = math.clamp(segmentAlpha + WAYPOINT_SAMPLE_EPSILON, 0, 1)
    local samplePosition = segmentStart:Lerp(segmentEnd, sampleAlpha)
    samplePosition = samplePosition + Vector3.new(0, math.sin(sampleAlpha * math.pi) * _arcHeight, 0)

    local forward = samplePosition - basePosition
    if forward.Magnitude < 1e-4 then
        forward = segmentEnd - segmentStart
    end
    if forward.Magnitude < 1e-4 then
        forward = Vector3.new(0, 0, -1)
    end
    forward = forward.Unit

    local up = Vector3.new(0, 1, 0)
    if math.abs(up:Dot(forward)) > 0.95 then
        up = Vector3.new(0, 0, 1)
    end

    local right = forward:Cross(up).Unit
    up = right:Cross(forward).Unit

    local planeCFrame = CFrame.fromMatrix(basePosition, right, up)

    if _bankAngle ~= 0 then
        planeCFrame = planeCFrame * CFrame.Angles(0, 0, math.rad(_bankAngle) * math.sin(segmentAlpha * math.pi))
    end

    return planeCFrame, overallProgress
end

local function updateFlight(deltaTime)
    if not (_plane and _plane.Parent) then
        return
    end

    local elapsed = tick() - _flightStartTime
    local planeCFrame, progress = computePlaneCFrame(elapsed)

    _plane:PivotTo(planeCFrame)
    updateCamera(planeCFrame, deltaTime)

    if progress >= 1 and not _completionSignaled then
        _completionSignaled = true
        local callback = _completionCallback
        task.defer(function()
            NookPlane.endFlight()
            if callback then
                callback()
            end
        end)
    end
end

local function beginFlight(path, config)
    if _isFlying then
        warn("[NookPlane] Already flying!")
        return
    end

    if #path < 2 then
        warn("[NookPlane] Need at least two waypoints to start flight")
        return
    end

    _isFlying = true
    _completionSignaled = false
    _completionCallback = config.onComplete

    _flightPath = cloneVectorPath(path)
    _flightDuration = config.duration or DEFAULT_DURATION
    _arcHeight = config.arcHeight or DEFAULT_ARC_HEIGHT
    _bankAngle = config.bankAngle or DEFAULT_BANK_ANGLE
    _bobHeight = config.bobHeight or DEFAULT_BOB_HEIGHT
    _bobFrequency = config.bobFrequency or DEFAULT_BOB_FREQUENCY
    _cameraOffset = config.cameraOffset or DEFAULT_CAMERA_OFFSET
    _lookAheadDistance = config.lookAheadDistance or DEFAULT_LOOK_AHEAD_DISTANCE

    _plane = loadPlaneModel()
    _plane:PivotTo(CFrame.new(_flightPath[1]))
    _plane.Parent = workspace

    task.defer(function()
        if not seatPlayer(_plane) then
            warn("[NookPlane] ⚠️ Unable to seat player for flight cutscene")
        end
    end)

    setupFlightCamera()

    _flightStartTime = tick()
    if _renderConnection then
        _renderConnection:Disconnect()
    end
    _renderConnection = RunService.RenderStepped:Connect(updateFlight)

    print("[NookPlane] ✈️ Flight sequence started with", #path, "waypoint(s)")
end

function NookPlane.startFlight(config)
    config = config or {}

    local startPos = config.startPos or Vector3.new(0, 200, 0)
    local endPos = config.endPos or Vector3.new(120, 80, 140)
    local duration = config.duration or DEFAULT_DURATION

    beginFlight({ startPos, endPos }, {
        duration = duration,
        onComplete = config.onComplete,
        arcHeight = config.arcHeight,
        bankAngle = config.bankAngle,
        bobHeight = config.bobHeight,
        bobFrequency = config.bobFrequency,
        cameraOffset = config.cameraOffset,
        lookAheadDistance = config.lookAheadDistance,
    })
end

function NookPlane.startWaypointFlight(waypoints, duration, onComplete)
    if type(waypoints) ~= "table" or #waypoints < 2 then
        warn("[NookPlane] Need at least two waypoints to start waypoint flight")
        return
    end

    beginFlight(waypoints, {
        duration = duration or DEFAULT_DURATION,
        onComplete = onComplete,
    })
end

function NookPlane.endFlight()
    if not _isFlying then
        return
    end

    print("[NookPlane] 🛬 Landing...")
    _isFlying = false

    if _renderConnection then
        _renderConnection:Disconnect()
        _renderConnection = nil
    end

    restoreCamera()

    if _plane then
        local seat = _plane:FindFirstChildWhichIsA("Seat", true)
        if seat and seat.Occupant then
            seat.Occupant.Sit = false
        end

        _plane:Destroy()
        _plane = nil
    end

    _flightPath = nil
    _completionCallback = nil

    print("[NookPlane] ✅ Flight ended")
end

function NookPlane.isFlying()
    return _isFlying
end

function NookPlane.skipCutscene()
    if not _isFlying then
        return
    end

    print("[NookPlane] ⏭️ Skipping cutscene...")
    NookPlane.endFlight()
end

return NookPlane
