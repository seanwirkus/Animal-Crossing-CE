--[[
	NookPlane.luau
	
	Cutscene system for Nook Inc. airplane flights
	- Player sits in invisible plane
	- Camera follows plane smoothly
	- Used for island travel, intro cutscenes, etc.
	
	Usage:
		local NookPlane = require(path.to.NookPlane)
		
		-- Start a flight cutscene
		NookPlane.startFlight({
			startPos = Vector3.new(0, 200, 0),
			endPos = Vector3.new(100, 50, 100),
			duration = 10,
			onComplete = function()
				print("Flight complete!")
			end
		})
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local NookPlane = {}

-- State
local _isFlying = false
local _plane = nil
local _camera = workspace.CurrentCamera
local _player = Players.LocalPlayer
local _originalCameraType = nil
local _renderConnection = nil

-- Plane settings
local PLANE_SPEED = 50  -- Studs per second
local CAMERA_OFFSET = Vector3.new(0, 10, 30)  -- Camera position relative to plane
local CAMERA_SMOOTHNESS = 0.05  -- Lower = smoother

--[[
	Create the floating plane model with pontoons
]]
local function createPlane()
	local plane = Instance.new("Model")
	plane.Name = "NookPlane"
	
	-- Main body (invisible but has collision for player)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(10, 5, 15)
	body.Transparency = 1  -- Invisible
	body.CanCollide = false
	body.Anchored = true  -- ANCHOR IT! No more floating!
	body.Parent = plane
	
	-- PONTOONS for floating! (Left pontoon)
	local leftPontoon = Instance.new("Part")
	leftPontoon.Name = "LeftPontoon"
	leftPontoon.Size = Vector3.new(2, 2, 12)
	leftPontoon.Position = body.Position + Vector3.new(-4, -3, 0)
	leftPontoon.Transparency = 0.3
	leftPontoon.Color = Color3.fromRGB(255, 200, 100)  -- Yellow-orange
	leftPontoon.Material = Enum.Material.SmoothPlastic
	leftPontoon.CanCollide = false
	leftPontoon.Anchored = false
	leftPontoon.Parent = plane
	
	-- Make pontoon rounded
	local pontoonMesh = Instance.new("SpecialMesh")
	pontoonMesh.MeshType = Enum.MeshType.Cylinder
	pontoonMesh.Parent = leftPontoon
	
	-- Rotate pontoon to align with plane
	leftPontoon.Orientation = Vector3.new(0, 0, 90)
	
	-- PONTOONS for floating! (Right pontoon)
	local rightPontoon = Instance.new("Part")
	rightPontoon.Name = "RightPontoon"
	rightPontoon.Size = Vector3.new(2, 2, 12)
	rightPontoon.Position = body.Position + Vector3.new(4, -3, 0)
	rightPontoon.Transparency = 0.3
	rightPontoon.Color = Color3.fromRGB(255, 200, 100)
	rightPontoon.Material = Enum.Material.SmoothPlastic
	rightPontoon.CanCollide = false
	rightPontoon.Anchored = false
	rightPontoon.Parent = plane
	
	local pontoonMesh2 = Instance.new("SpecialMesh")
	pontoonMesh2.MeshType = Enum.MeshType.Cylinder
	pontoonMesh2.Parent = rightPontoon
	
	rightPontoon.Orientation = Vector3.new(0, 0, 90)
	
	-- Weld pontoons to body
	local leftWeld = Instance.new("WeldConstraint")
	leftWeld.Part0 = body
	leftWeld.Part1 = leftPontoon
	leftWeld.Parent = body
	
	local rightWeld = Instance.new("WeldConstraint")
	rightWeld.Part0 = body
	rightWeld.Part1 = rightPontoon
	rightWeld.Parent = body
	
	-- Seat for player
	local seat = Instance.new("Seat")
	seat.Name = "PilotSeat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.Transparency = 1  -- Invisible
	seat.CanCollide = false
	seat.Anchored = false
	seat.Position = body.Position
	seat.Parent = plane
	
	-- Weld seat to body
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = body
	seatWeld.Part1 = seat
	seatWeld.Parent = body
	
	-- PrimaryPart for easy movement
	plane.PrimaryPart = body
	
	return plane
end

--[[
	Seat the player in the plane
]]
local function seatPlayer(plane)
	local character = _player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	local seat = plane:FindFirstChild("PilotSeat")
	if not seat then return false end
	
	-- Sit the player
	seat:Sit(humanoid)
	
	return true
end

--[[
	Setup camera for flight
]]
local function setupFlightCamera()
	_originalCameraType = _camera.CameraType
	_camera.CameraType = Enum.CameraType.Scriptable
	
	-- Disable player controls
	UserInputService.ModalEnabled = true
	
	-- Hide core GUI
	pcall(function()
		local StarterGui = game:GetService("StarterGui")
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
end

--[[
	Restore camera after flight
]]
local function restoreCamera()
	_camera.CameraType = _originalCameraType or Enum.CameraType.Custom
	
	-- Re-enable player controls
	UserInputService.ModalEnabled = false
	
	-- Restore core GUI
	pcall(function()
		local StarterGui = game:GetService("StarterGui")
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	end)
end

--[[
	Update camera to follow plane smoothly
]]
local function updateCamera()
	if not _plane or not _plane.PrimaryPart then return end
	
	local planeCFrame = _plane.PrimaryPart.CFrame
	local targetCameraPos = planeCFrame:PointToWorldSpace(CAMERA_OFFSET)
	local lookAtPos = planeCFrame.Position
	
	-- Smooth camera movement
	local currentPos = _camera.CFrame.Position
	local smoothPos = currentPos:Lerp(targetCameraPos, CAMERA_SMOOTHNESS)
	
	_camera.CFrame = CFrame.new(smoothPos, lookAtPos)
end

--[[
	Fly the plane along a path
	@param config Table with: startPos, endPos, duration, onComplete
]]
function NookPlane.startFlight(config)
	if _isFlying then
		warn("[NookPlane] Already flying!")
		return
	end
	
	local startPos = config.startPos or Vector3.new(0, 200, 0)
	local endPos = config.endPos or Vector3.new(100, 50, 100)
	local duration = config.duration or 10
	local onComplete = config.onComplete
	
	print("[NookPlane] ✈️ Starting flight cutscene...")
	_isFlying = true
	
	-- Create plane
	_plane = createPlane()
	_plane:SetPrimaryPartCFrame(CFrame.new(startPos))
	_plane.Parent = workspace
	
	-- Get the body
	local body = _plane.PrimaryPart
	
	-- Seat player
	task.wait(0.5)  -- Wait for plane to exist
	local seated = seatPlayer(_plane)
	if not seated then
		warn("[NookPlane] Failed to seat player")
	end
	
	-- Setup camera
	setupFlightCamera()
	
	-- Use simple tween for smooth movement (no physics!)
	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)
	
	local tween = TweenService:Create(body, tweenInfo, {
		CFrame = CFrame.new(endPos)
	})
	
	-- Start camera updates
	_renderConnection = RunService.RenderStepped:Connect(updateCamera)
	
	tween:Play()
	
	-- Wait for completion
	tween.Completed:Connect(function()
		print("[NookPlane] ✅ Flight complete")
		NookPlane.endFlight()
		
		if onComplete then
			onComplete()
		end
	end)
end

--[[
	Fly along multiple waypoints
	@param waypoints Array of Vector3 positions
	@param duration Total duration in seconds
	@param onComplete Callback when done
]]
function NookPlane.startWaypointFlight(waypoints, duration, onComplete)
	if _isFlying then
		warn("[NookPlane] Already flying!")
		return
	end
	
	if #waypoints < 2 then
		warn("[NookPlane] Need at least 2 waypoints")
		return
	end
	
	print("[NookPlane] ✈️ Starting waypoint flight with", #waypoints, "points...")
	_isFlying = true
	
	-- Create plane
	_plane = createPlane()
	_plane:SetPrimaryPartCFrame(CFrame.new(waypoints[1]))
	_plane.Parent = workspace
	
	-- Seat player
	task.wait(0.5)
	seatPlayer(_plane)
	
	-- Setup camera
	setupFlightCamera()
	
	-- Start camera updates
	_renderConnection = RunService.RenderStepped:Connect(updateCamera)
	
	-- Fly through waypoints
	local body = _plane.PrimaryPart
	local segmentDuration = duration / (#waypoints - 1)
	
	local function flyToNextWaypoint(index)
		if index > #waypoints then
			print("[NookPlane] ✅ Waypoint flight complete")
			NookPlane.endFlight()
			if onComplete then onComplete() end
			return
		end
		
		local targetPos = waypoints[index]
		local tweenInfo = TweenInfo.new(segmentDuration, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(body, tweenInfo, {
			CFrame = CFrame.new(targetPos)
		})
		
		tween:Play()
		tween.Completed:Wait()
		
		-- Move to next waypoint
		flyToNextWaypoint(index + 1)
	end
	
	-- Start flying
	task.spawn(function()
		flyToNextWaypoint(2)  -- Start from second waypoint (already at first)
	end)
end

--[[
	End the flight cutscene
]]
function NookPlane.endFlight()
	if not _isFlying then return end
	
	print("[NookPlane] 🛬 Landing...")
	
	_isFlying = false
	
	-- Stop camera updates
	if _renderConnection then
		_renderConnection:Disconnect()
		_renderConnection = nil
	end
	
	-- Restore camera
	restoreCamera()
	
	-- Remove plane
	if _plane then
		-- Unseat player first
		local seat = _plane:FindFirstChild("PilotSeat")
		if seat and seat.Occupant then
			seat.Occupant.Sit = false
		end
		
		_plane:Destroy()
		_plane = nil
	end
	
	print("[NookPlane] ✅ Flight ended")
end

--[[
	Check if currently in flight
]]
function NookPlane.isFlying()
	return _isFlying
end

--[[
	Emergency stop (skip cutscene)
]]
function NookPlane.skipCutscene()
	if not _isFlying then return end
	
	print("[NookPlane] ⏭️ Skipping cutscene...")
	NookPlane.endFlight()
end

return NookPlane
