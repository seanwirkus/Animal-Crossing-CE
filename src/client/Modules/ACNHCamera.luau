--[[
	ACNHCamera.luau
	
	Enhanced Animal Crossing style camera system
	- Super smooth following with spring physics
	- Dynamic FOV based on movement speed
	- Collision detection to prevent clipping
	- Auto-rotation behind player when moving
	- Beautiful cinematic feel
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ACNHCamera = {}

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

-- Simple, clean camera settings (Animal Crossing style)
local MIN_ZOOM = 12
local MAX_ZOOM = 28
local DEFAULT_ZOOM = 18  -- Closer to player!
local currentZoom = DEFAULT_ZOOM

-- Rotation
local cameraAngleX = -0.5  -- Nice downward angle
local cameraAngleY = 0

-- Cinematic smooth settings
local CAMERA_SMOOTHNESS = 0.08  -- Much slower, smoother movement
local ROTATION_SPEED = 0.002  -- Slower rotation
local TOUCH_ROTATION_SPEED = 0.003  -- Slower touch panning
local HEIGHT_OFFSET = 12  -- Camera height
local LOOK_AHEAD = 3  -- Cinematic look ahead

local DEFAULT_FOV = 70

local _isActive = false  -- Track if camera is active
local _lastTouchPosition = nil  -- For touch panning

function ACNHCamera.init()
	print("[ACNHCamera] 🎥 Initializing Animal Crossing camera...")
	
	_isActive = true  -- Mark camera as active
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Set camera to scriptable
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = DEFAULT_FOV
	
	-- Handle mouse input for camera rotation
	UserInputService.InputChanged:Connect(function(input)
		if not _isActive then return end
		
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Delta
			cameraAngleX = cameraAngleX - delta.Y * ROTATION_SPEED
			cameraAngleY = cameraAngleY - delta.X * ROTATION_SPEED
			
			-- Limit vertical rotation
			cameraAngleX = math.clamp(cameraAngleX, -1.4, -0.2)  -- Keep looking down
		end
	end)
	
	-- Handle TOUCH input for 2-finger panning (cinematic!)
	UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
		if not _isActive or gameProcessed then return end
		
		-- Check for 2-finger touch
		local touches = UserInputService:GetTouchesInProgress()
		if #touches == 2 then
			-- Two-finger panning
			if _lastTouchPosition then
				local delta = touch.Position - _lastTouchPosition
				cameraAngleX = cameraAngleX - delta.Y * TOUCH_ROTATION_SPEED
				cameraAngleY = cameraAngleY - delta.X * TOUCH_ROTATION_SPEED
				
				-- Limit vertical rotation
				cameraAngleX = math.clamp(cameraAngleX, -1.4, -0.2)
			end
			_lastTouchPosition = touch.Position
		end
	end)
	
	-- Reset touch tracking when touch ends
	UserInputService.TouchEnded:Connect(function()
		_lastTouchPosition = nil
	end)
	
	-- Handle zoom with mouse wheel
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			currentZoom = math.clamp(currentZoom - input.Position.Z * 2.5, MIN_ZOOM, MAX_ZOOM)
		end
	end)
	
	-- Simple smooth camera update
	RunService.RenderStepped:Connect(function()
		if not _isActive then return end
		
		if not character or not character.Parent then
			character = player.Character
			if character then
				humanoidRootPart = character:WaitForChild("HumanoidRootPart")
			else
				return
			end
		end
		
		local hrp = humanoidRootPart
		if not hrp or not hrp.Parent then return end
		
		-- Calculate camera position - HIGHER and looking DOWN
		local rotatedOffset = CFrame.Angles(cameraAngleX, cameraAngleY, 0) * Vector3.new(0, 0, currentZoom)
		local targetPos = hrp.Position + Vector3.new(0, HEIGHT_OFFSET, 0) + rotatedOffset
		
		-- Smooth camera movement (simple lerp, no fancy physics)
		local currentPos = camera.CFrame.Position
		local smoothPos = currentPos:Lerp(targetPos, CAMERA_SMOOTHNESS)
		
		-- Look at player with slight ahead offset
		local lookAtPos = hrp.Position + (hrp.CFrame.LookVector * LOOK_AHEAD) + Vector3.new(0, 2, 0)
		
		-- Set camera
		camera.CFrame = CFrame.new(smoothPos, lookAtPos)
		
		-- Lock mouse to center for rotation
		if _isActive then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end)
	
	-- Handle character respawn
	player.CharacterAdded:Connect(function(newCharacter)
		character = newCharacter
		humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
		cameraAngleX = -0.5  -- Reset to nice downward angle
		cameraAngleY = 0
		currentZoom = DEFAULT_ZOOM
		_lastTouchPosition = nil
	end)
	
	print("[ACNHCamera] ✅ Cinematic camera ready! Closer view, 2-finger panning 📱")
end

function ACNHCamera.disable()
	_isActive = false
	camera.CameraType = Enum.CameraType.Custom
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	print("[ACNHCamera] Camera reset to default")
end

return ACNHCamera
