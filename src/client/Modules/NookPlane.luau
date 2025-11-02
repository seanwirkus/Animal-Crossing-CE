--[[
	NookPlane.luau
	Client-side plane controls and interaction
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Constants
local FLIGHT_SPEED = 80 -- Forward speed
local ROTATION_SPEED = 2 -- Turn speed
-- Removed unused constants

local NookPlane = {}
NookPlane.__index = NookPlane

function NookPlane.new()
	local self = setmetatable({}, NookPlane)
	
	self._planeModel = nil
	self._planeBody = nil
	self._propeller = nil
	self._seatPart = nil
	self._lightsPart = nil
	self._bodyMesh = nil
	self._floatPart = nil  -- New float part for buoyancy
	self._lightFlashConnection = nil
	self._lightsWeld = nil
	self._bodyWeld = nil
	self._floatWeld = nil  -- Weld for float part
	self._flying = false
	self._inputConnections = {}
	self._flightConnection = nil
	self._propellerConnection = nil
	self._hudUpdateConnection = nil
	self._proximityUpdateConnection = nil
	self._playerWeld = nil
	self._playerMotor = nil
	self._engineSound = nil
	self._takeoffStartTime = nil
	self._isOnWater = false
	
	-- Flight controls state (WASD for plane, Spacebar for throttle)
	self.CONTROLS = {
		forward = false,
		backward = false,
		left = false,
		right = false,
		throttle = false, -- Spacebar for throttle
	}
	self._currentSpeedMultiplier = 1.0 -- Current speed multiplier (0.0 to 1.0)
	self._targetSpeedMultiplier = 0.0 -- Target speed (0 when not throttling)
	self._cameraConnection = nil
	self._cameraCFrame = nil
	self._originalCameraType = nil
	self._originalCameraSubject = nil
	
	print("[NookPlane] ✅ NookPlane client instance created")
	return self
end

-- Find the plane model (loaded by server)
function NookPlane:_createOrFindPlane()
	if self._planeModel and self._planeModel.Parent then
		print("[NookPlane] ✅ Using existing plane model")
		return true
	end

	-- Wait for the plane to be created by the server (with timeout)
	local maxWaitTime = 5
	local elapsed = 0
	local waitInterval = 0.1
	
	print("[NookPlane] 🔍 Looking for NookPlane in workspace...")
	
	while elapsed < maxWaitTime do
		local existingPlane = Workspace:FindFirstChild("NookPlane")
		if existingPlane then
			print("[NookPlane] ✅ Found NookPlane in workspace")
			self._planeModel = existingPlane
			self._planeBody = existingPlane:FindFirstChild("PlaneBody")
			
			-- Try alternative names if PlaneBody not found
			if not self._planeBody then
				self._planeBody = existingPlane:FindFirstChild("RootPart")
			end
			if not self._planeBody then
				self._planeBody = existingPlane:FindFirstChild("Bdy_low__mPlane")
			end
			if not self._planeBody then
				-- Try to find largest part
				local largestPart = nil
				local largestVolume = 0
				for _, descendant in pairs(existingPlane:GetDescendants()) do
					if descendant:IsA("BasePart") then
						local volume = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
						if volume > largestVolume then
							largestVolume = volume
							largestPart = descendant
						end
					end
				end
				if largestPart then
					self._planeBody = largestPart
					largestPart.Name = "PlaneBody"
					print("[NookPlane] ✅ Found largest part and set as PlaneBody:", largestPart.Name)
				end
			end
			
			self._propeller = existingPlane:FindFirstChild("Propeller")
			
			-- Find Lights and Body meshes
			self._lightsPart = existingPlane:FindFirstChild("Lights")
			self._bodyMesh = existingPlane:FindFirstChild("Body")
			self._floatPart = existingPlane:FindFirstChild("Float")  -- New float part for buoyancy
			
			if self._lightsPart then
				print("[NookPlane] ✅ Found Lights part")
			end
			if self._bodyMesh then
				print("[NookPlane] ✅ Found Body mesh")
			end
			if self._bodyMesh then
				print("[NookPlane] ✅ Found Body mesh")
			end
			
			if self._planeBody then
				print("[NookPlane] ✅ Connected to PlaneBody at position:", self._planeBody.Position)
				
				-- Ensure BodyVelocity and BodyAngularVelocity exist
				if not self._planeBody:FindFirstChild("BodyVelocity") then
					warn("[NookPlane] ⚠️ BodyVelocity missing on PlaneBody - creating it")
					local bv = Instance.new("BodyVelocity")
					bv.Name = "BodyVelocity"
					bv.MaxForce = Vector3.new(10000, 10000, 10000)
					bv.P = 1250
					bv.Velocity = Vector3.new(0, 0, 0)
					bv.Parent = self._planeBody
				end
				if not self._planeBody:FindFirstChild("BodyAngularVelocity") then
					warn("[NookPlane] ⚠️ BodyAngularVelocity missing on PlaneBody - creating it")
					local bav = Instance.new("BodyAngularVelocity")
					bav.Name = "BodyAngularVelocity"
					bav.MaxTorque = Vector3.new(10000, 10000, 10000)
					bav.AngularVelocity = Vector3.new(0, 0, 0)
					bav.Parent = self._planeBody
				end
				if not self._planeBody:FindFirstChild("BodyPosition") then
					print("[NookPlane] ℹ️ BodyPosition missing - will be created when needed")
				end
				
				-- Find or create interior seat
				self._seatPart = existingPlane:FindFirstChild("InteriorSeat")
				if not self._seatPart then
					print("[NookPlane] ℹ️ InteriorSeat not found, will use PlaneBody for seating")
					self._seatPart = self._planeBody
				end
				
				self:_createProximityUI()
				return true
			else
				warn("[NookPlane] ⚠️ NookPlane exists but PlaneBody not found!")
				local children = {}
				for _, child in pairs(existingPlane:GetChildren()) do
					table.insert(children, child.Name)
				end
				warn("[NookPlane] Available children:", table.concat(children, ", "))
				return false
			end
		end
		
		task.wait(waitInterval)
		elapsed = elapsed + waitInterval
	end

	warn("[NookPlane] ❌ NookPlane not found in workspace after", maxWaitTime, "seconds")
	warn("[NookPlane] ℹ️ Make sure the server-side NookPlaneSetup script is running")
	return false
end

-- Start propeller animation (DISABLED - no propeller logic)
function NookPlane:_startPropeller()
	-- Propeller logic disabled
	print("[NookPlane] ℹ️ Propeller animation disabled")
end

-- Stop propeller animation (DISABLED)
function NookPlane:_stopPropeller()
	-- Propeller logic disabled
end

-- Start light flashing animation
function NookPlane:_startLightFlash()
	if self._lightFlashConnection then
		return
	end
	
	if not self._lightsPart then
		print("[NookPlane] ℹ️ No Lights part found for flashing")
		return
	end
	
	print("[NookPlane] ✨ Starting light flash animation")
	
	local flashSpeed = 0.5 -- Flash every 0.5 seconds
	
	self._lightFlashConnection = RunService.Heartbeat:Connect(function()
		if not self._lightsPart or not self._lightsPart.Parent then
			self:_stopLightFlash()
			return
		end
		
		local currentTime = tick()
		local isFlashing = math.sin(currentTime * math.pi * 2 / flashSpeed) > 0
		
		-- Flash using PointLight if present
		local light = self._lightsPart:FindFirstChildOfClass("PointLight")
		if light then
			if isFlashing then
				light.Brightness = 2 -- Bright when flashing
			else
				light.Brightness = 0.3 -- Dim when off
			end
		else
			-- Create PointLight if it doesn't exist
			if self._lightsPart:IsA("BasePart") then
				light = Instance.new("PointLight")
				light.Brightness = 0
				light.Color = Color3.fromRGB(255, 255, 200)
				light.Range = 10
				light.Shadows = false
				light.Parent = self._lightsPart
				if isFlashing then
					light.Brightness = 2
				end
			end
		end
		
		-- Flash using SurfaceGui with TextLabel if present
		for _, gui in pairs(self._lightsPart:GetDescendants()) do
			if gui:IsA("SurfaceGui") or gui:IsA("BillboardGui") then
				for _, label in pairs(gui:GetDescendants()) do
					if label:IsA("TextLabel") or label:IsA("ImageLabel") then
						if isFlashing then
							label.Visible = true
							if label:IsA("ImageLabel") then
								label.ImageTransparency = 0
							end
						else
							label.Visible = false
							if label:IsA("ImageLabel") then
								label.ImageTransparency = 1
							end
						end
					end
				end
			end
		end
		
		-- Flash using part transparency/color as fallback
		if self._lightsPart:IsA("BasePart") then
			local pointLight = self._lightsPart:FindFirstChildOfClass("PointLight")
			if pointLight then
				pointLight.Brightness = isFlashing and 2 or 0
			end
		end
	end)
end

-- Stop light flashing animation
function NookPlane:_stopLightFlash()
	if self._lightFlashConnection then
		self._lightFlashConnection:Disconnect()
		self._lightFlashConnection = nil
		print("[NookPlane] ✅ Stopped light flash animation")
	end
	
	-- Reset lights to normal state
	if self._lightsPart and self._lightsPart:IsA("BasePart") then
		local light = self._lightsPart:FindFirstChildOfClass("PointLight")
		if light then
			light.Brightness = 0.5 -- Keep dim light when off
		end
	end
end

-- Start engine sound (DISABLED - sound asset not working)
function NookPlane:_startEngineSound()
	-- Engine sound disabled - asset was incorrect type
	-- TODO: Add proper engine sound asset ID later
	print("[NookPlane] ℹ️ Engine sound disabled (asset not available)")
end

-- Stop engine sound
function NookPlane:_stopEngineSound()
	if self._engineSound then
		-- Fade out then destroy
		TweenService:Create(self._engineSound, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Volume = 0}):Play()
		task.wait(0.6)
		self._engineSound:Destroy()
		self._engineSound = nil
		print("[NookPlane] ✅ Engine sound stopped")
	end
end

-- Removed all water physics functions - plane is now pure flight only

-- Start flight physics with cartoon takeoff and water floating
function NookPlane:_startFlight()
	if self._flightConnection then
		print("[NookPlane] ⚠️ Flight already started")
		return
	end

	print("[NookPlane] ✈️ Starting sea plane flight")
	
	local bodyVelocity = self._planeBody:FindFirstChild("BodyVelocity")
	local bodyAngularVelocity = self._planeBody:FindFirstChild("BodyAngularVelocity")
	local bodyPosition = self._planeBody:FindFirstChild("BodyPosition")
	
	-- Add BodyPosition for water floating if it doesn't exist
	if not bodyPosition then
		bodyPosition = Instance.new("BodyPosition")
		bodyPosition.Name = "BodyPosition"
		bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
		bodyPosition.P = 500
		bodyPosition.D = 100
		bodyPosition.Position = self._planeBody.Position
		bodyPosition.Parent = self._planeBody
	end
	
	if not bodyVelocity or not bodyAngularVelocity then
		warn("[NookPlane] ❌ Missing BodyVelocity or BodyAngularVelocity!")
		return
	end

	self._flightConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not self._planeBody or not self._planeBody.Parent then
			self:TurnOff()
			return
		end

		-- ============================================================
		-- CAMERA FOLLOW - External view behind plane (FIXED)
		-- ============================================================
		if self._planeBody then
			local camera = workspace.CurrentCamera
			if camera.CameraType == Enum.CameraType.Scriptable then
				local planePos = self._planeBody.Position
				local planeCFrame = self._planeBody.CFrame
				local planeForward = planeCFrame.LookVector
				local planeRight = planeCFrame.RightVector
				
				-- Camera position: behind, above, and slightly to the side for better view
				local cameraDistance = 25 -- Studs behind plane
				local cameraHeight = 10 -- Studs above plane
				local cameraSideOffset = 3 -- Slightly to the side
				
				-- Calculate camera position behind and to the right
				local cameraOffset = (planeForward * -cameraDistance) + (Vector3.new(0, cameraHeight, 0)) + (planeRight * cameraSideOffset)
				local targetCameraPos = planePos + cameraOffset
				
				-- Smooth camera movement
				local currentCamPos = camera.CFrame.Position
				local lerpAlpha = math.min(deltaTime * 10, 1) -- Smooth following
				local smoothCamPos = currentCamPos:Lerp(targetCameraPos, lerpAlpha)
				
				-- Look at plane (slightly ahead)
				local lookTarget = planePos + (planeForward * 8)
				local cameraCFrame = CFrame.lookAt(smoothCamPos, lookTarget)
				
				camera.CFrame = cameraCFrame
			end
		end

	-- Flight physics - no water physics, just pure flight
		
		-- Calculate movement based on controls
		local cf = self._planeBody.CFrame
		local targetVelocity = Vector3.new(0, 0, 0)
		
		-- THROTTLE: Spacebar controls speed (gradual increase/decrease)
		local throttleSpeedChange = 0.5 -- How fast throttle changes (per second)
		if self.CONTROLS.throttle then
			-- Spacebar held: Gradually increase throttle (target = 1.0)
			self._targetSpeedMultiplier = math.min(self._targetSpeedMultiplier + (throttleSpeedChange * deltaTime), 1.0)
		else
			-- Spacebar released: Gradually decrease throttle (target = 0.0)
			self._targetSpeedMultiplier = math.max(self._targetSpeedMultiplier - (throttleSpeedChange * deltaTime), 0.0)
		end
		
		-- Smooth current speed towards target
		local speedDiff = self._targetSpeedMultiplier - self._currentSpeedMultiplier
		self._currentSpeedMultiplier = self._currentSpeedMultiplier + (speedDiff * math.min(deltaTime * 2, 1))
		
		-- Forward/backward movement (works everywhere - taxi, takeoff, flight)
		-- Speed is multiplied by throttle
		if self.CONTROLS.forward then
			local speed = FLIGHT_SPEED * math.max(self._currentSpeedMultiplier, 0.5) -- Minimum 50% speed even without throttle
			targetVelocity = targetVelocity + (cf.LookVector * speed)
		end
		if self.CONTROLS.backward then
			local speed = FLIGHT_SPEED * 0.5 * math.max(self._currentSpeedMultiplier, 0.3)
			targetVelocity = targetVelocity - (cf.LookVector * speed) -- Slower reverse
		end
		
		-- Left/right turning
		local targetAngularVelocity = Vector3.new(0, 0, 0)
		if self.CONTROLS.left then
			targetAngularVelocity = Vector3.new(0, ROTATION_SPEED, 0)
		elseif self.CONTROLS.right then
			targetAngularVelocity = Vector3.new(0, -ROTATION_SPEED, 0)
		end
		
		-- ============================================================
		-- WATER DETECTION & FLOATING PHYSICS
		-- ============================================================
		
		-- Detect water below plane using raycast
		local planePos = self._planeBody.Position
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.IgnoreWater = false
		if self._planeModel then
			raycastParams.FilterDescendantsInstances = {self._planeModel}
		end
		
		-- Cast ray downward to find water
		local waterRaycast = Workspace:Raycast(planePos, Vector3.new(0, -200, 0), raycastParams)
		local isOnWater = false
		local waterSurfaceY = nil
		
		if waterRaycast and waterRaycast.Material == Enum.Material.Water then
			isOnWater = true
			waterSurfaceY = waterRaycast.Position.Y
		end
		
		-- Also check if plane is near water (within 10 studs)
		if not isOnWater then
			-- Check multiple points around plane
			local checkOffsets = {
				Vector3.new(0, 0, 0),
				Vector3.new(5, 0, 0),
				Vector3.new(-5, 0, 0),
				Vector3.new(0, 0, 5),
				Vector3.new(0, 0, -5),
			}
			
			for _, offset in ipairs(checkOffsets) do
				local checkPos = planePos + offset
				local checkRay = Workspace:Raycast(checkPos, Vector3.new(0, -50, 0), raycastParams)
				if checkRay and checkRay.Material == Enum.Material.Water then
					local checkWaterY = checkRay.Position.Y
					-- If plane is within 10 studs of water surface, consider it on water
					if math.abs(planePos.Y - checkWaterY) < 10 then
						isOnWater = true
						waterSurfaceY = checkWaterY
						break
					end
				end
			end
		end
		
		if isOnWater and waterSurfaceY then
			-- ============================================================
			-- ON WATER: RELIABLE FLOATING USING BODYPOSITION
			-- ============================================================
			
			-- Get plane's actual bounding box for accurate height calculation
			local planeSizeY = self._planeBody.Size.Y
			local _modelCFrame, modelSize = nil, nil
			if self._planeModel and self._planeModel.PrimaryPart then
				_modelCFrame, modelSize = self._planeModel:GetBoundingBox()
			end
			
			-- Use full model height if available
			local totalHeight = modelSize and modelSize.Y or planeSizeY
			
			-- Calculate float height: plane bottom should be 10 studs above water
			local floatOffset = 10 -- Studs above water for plane bottom
			local desiredBottomY = waterSurfaceY + floatOffset
			local desiredCenterY = desiredBottomY + (totalHeight / 2)
			
			-- Safety: ensure minimum height (20 studs above water for center)
			if desiredCenterY < waterSurfaceY + 20 then
				desiredCenterY = waterSurfaceY + 20
			end
			
			-- Get or create BodyPosition for floating
			if not bodyPosition then
				bodyPosition = Instance.new("BodyPosition")
				bodyPosition.Name = "BodyPosition"
				bodyPosition.Parent = self._planeBody
			end
			
			-- Calculate level rotation (yaw only, no pitch/roll)
			local currentLook = cf.LookVector
			local horizontalLook = Vector3.new(currentLook.X, 0, currentLook.Z)
			if horizontalLook.Magnitude < 0.001 then
				horizontalLook = Vector3.new(0, 0, -1)
			else
				horizontalLook = horizontalLook.Unit
			end
			
			local yawAngle = math.atan2(-horizontalLook.X, -horizontalLook.Z)
			
			-- Apply turning
			if self.CONTROLS.left then
				yawAngle = yawAngle + (ROTATION_SPEED * deltaTime)
			elseif self.CONTROLS.right then
				yawAngle = yawAngle - (ROTATION_SPEED * deltaTime)
			end
			
			-- Calculate target position (horizontal movement)
			local targetPosition = Vector3.new(planePos.X, desiredCenterY, planePos.Z)
			
			-- Handle forward/backward movement
			if self.CONTROLS.forward then
				local moveSpeed = FLIGHT_SPEED * 0.5 * deltaTime
				targetPosition = targetPosition + (horizontalLook * moveSpeed)
			elseif self.CONTROLS.backward then
				local moveSpeed = FLIGHT_SPEED * 0.25 * deltaTime
				targetPosition = targetPosition - (horizontalLook * moveSpeed)
			end
			
			-- UNANCHOR for BodyPosition to work (BodyPosition needs unanchored parts)
			if self._planeBody.Anchored then
				self._planeBody.Anchored = false
			end
			
			-- Use BodyPosition to maintain float height
			bodyPosition.Position = targetPosition
			bodyPosition.MaxForce = Vector3.new(40000, 40000, 40000) -- Strong force in all directions
			bodyPosition.P = 10000 -- High responsiveness
			bodyPosition.D = 2000 -- Strong damping
			
			-- Apply level rotation using BodyAngularVelocity
			bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0) -- Reset first
			
			-- Apply level CFrame EVERY FRAME (BodyPosition handles position, CFrame handles rotation)
			local currentY = self._planeBody.Position.Y
			local levelCFrame = CFrame.new(targetPosition.X, currentY, targetPosition.Z) * CFrame.Angles(0, yawAngle, 0)
			self._planeBody.CFrame = levelCFrame
			
			-- Zero velocities (BodyPosition handles position, CFrame handles rotation)
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
			bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
			
		else
			-- ============================================================
			-- IN AIR: Normal flight physics
			-- ============================================================
			
			-- Remove AlignPosition and AlignOrientation when not on water
			local alignPosition = self._planeBody:FindFirstChild("AlignPosition")
			if alignPosition then
				alignPosition.MaxForce = 0 -- Disable but keep it
			end
			
			local alignOrientation = self._planeBody:FindFirstChild("AlignOrientation")
			if alignOrientation then
				alignOrientation.MaxTorque = 0 -- Disable but keep it
			end
			
			-- Ensure unanchored for flight
			if self._planeBody.Anchored then
				self._planeBody.Anchored = false
			end
			
			-- Unanchor sub-parts
			if self._lightsPart and self._lightsPart.Anchored then
				self._lightsPart.Anchored = false
			end
			if self._bodyMesh and self._bodyMesh.Anchored then
				self._bodyMesh.Anchored = false
			end
			
			-- Disable BodyPosition
			if bodyPosition then
				bodyPosition.MaxForce = Vector3.new(0, 0, 0)
			end
			
			-- Apply flight velocities
			bodyVelocity.Velocity = targetVelocity
			bodyAngularVelocity.AngularVelocity = targetAngularVelocity
			
			-- Natural lift from forward movement
			if self.CONTROLS.forward then
				local liftForce = 10 -- Base lift force
				bodyVelocity.Velocity = bodyVelocity.Velocity + Vector3.new(0, liftForce, 0)
			end
		end
	end)
end

-- Stop flight physics
function NookPlane:_stopFlight()
	if self._flightConnection then
		self._flightConnection:Disconnect()
		self._flightConnection = nil
		print("[NookPlane] ✅ Flight stopped")
	end

	-- Reset velocities
	if self._planeBody then
		local bodyVelocity = self._planeBody:FindFirstChild("BodyVelocity")
		local bodyAngularVelocity = self._planeBody:FindFirstChild("BodyAngularVelocity")
		local bodyPosition = self._planeBody:FindFirstChild("BodyPosition")
		
		if bodyVelocity then
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		end
		if bodyAngularVelocity then
			bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
		end
		if bodyPosition then
			bodyPosition.MaxForce = Vector3.new(0, 0, 0)
		end
	end
	
	self._takeoffStartTime = nil
	self._isOnWater = false
end

-- Setup camera for flight (SIMPLIFIED - just make it follow plane externally)
function NookPlane:_setupCamera()
	print("[NookPlane] 📷 Setting up flight camera")
	local camera = workspace.CurrentCamera
	
	if not camera then
		warn("[NookPlane] ❌ Camera not found")
		return
	end
	
	-- Store original camera type
	self._originalCameraType = camera.CameraType
	self._originalCameraSubject = camera.CameraSubject
	
	-- Set camera to Scriptable so we can control it manually
	camera.CameraType = Enum.CameraType.Scriptable
	
	print("[NookPlane] ✅ Camera set to Scriptable mode")
end

-- Restore camera
function NookPlane:_restoreCamera()
	if self._cameraConnection then
		self._cameraConnection:Disconnect()
		self._cameraConnection = nil
	end
	
	local camera = workspace.CurrentCamera
	if camera then
		if self._originalCameraType then
			camera.CameraType = self._originalCameraType
		end
		if self._originalCameraSubject then
			camera.CameraSubject = self._originalCameraSubject
		end
	end
	
	print("[NookPlane] ✅ Camera restored")
end

-- Setup input controls
function NookPlane:_setupInput()
	print("[NookPlane] ⌨️ Setting up flight controls")
	
	-- Clear existing connections
	for _, conn in pairs(self._inputConnections) do
		if conn then
			conn:Disconnect()
		end
	end
	self._inputConnections = {}
	
	-- Input began
	table.insert(self._inputConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.W then
			self.CONTROLS.forward = true
		elseif input.KeyCode == Enum.KeyCode.S then
			self.CONTROLS.backward = true
		elseif input.KeyCode == Enum.KeyCode.A then
			self.CONTROLS.left = true
		elseif input.KeyCode == Enum.KeyCode.D then
			self.CONTROLS.right = true
		elseif input.KeyCode == Enum.KeyCode.Space then
			self.CONTROLS.throttle = true
		end
	end))
	
	-- Input ended
	table.insert(self._inputConnections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.W then
			self.CONTROLS.forward = false
		elseif input.KeyCode == Enum.KeyCode.S then
			self.CONTROLS.backward = false
		elseif input.KeyCode == Enum.KeyCode.A then
			self.CONTROLS.left = false
		elseif input.KeyCode == Enum.KeyCode.D then
			self.CONTROLS.right = false
		elseif input.KeyCode == Enum.KeyCode.Space then
			self.CONTROLS.throttle = false
		end
	end))
end

-- Turn on the plane
function NookPlane:TurnOn()
	if self._flying then
		print("[NookPlane] ⚠️ Already flying")
		return
	end

	-- Find the plane if we haven't already
	if not self._planeModel or not self._planeModel.Parent then
		local success = self:_createOrFindPlane()
		if not success then
			warn("[NookPlane] ❌ Cannot turn on - plane not found!")
			return
		end
	end

	print("[NookPlane] 🚀 Turning on plane")
	self._flying = true

	-- Seat the player properly
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		
		if humanoidRootPart then
			-- Disable humanoid to prevent physics conflicts
			if humanoid then
				humanoid.Sit = true
				humanoid.PlatformStand = true
				print("[NookPlane] ✅ Set humanoid to sit mode")
			end
			
			-- Position player inside the plane (ROTATED 90 DEGREES RIGHT)
			local seatCFrame = (self._seatPart or self._planeBody).CFrame
			-- Position behind seat, then rotate 90 degrees RIGHT (around Y axis)
			local playerPosition = seatCFrame.Position + (seatCFrame.LookVector * -1.5) -- Behind seat
			-- Rotate player CFrame 90 degrees RIGHT from plane's forward direction
			local rotatedCFrame = seatCFrame * CFrame.Angles(0, math.rad(-90), 0) -- -90 degrees = 90 degrees RIGHT
			humanoidRootPart.CFrame = CFrame.new(playerPosition) * (rotatedCFrame - rotatedCFrame.Position)
			
			-- Wait a frame for positioning to take effect
			task.wait(0.1)
			
			-- Weld player to seat with stronger attachment
			if self._playerWeld then
				self._playerWeld:Destroy()
			end
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = self._seatPart or self._planeBody
			weld.Part1 = humanoidRootPart
			weld.Parent = humanoidRootPart
			self._playerWeld = weld
			print("[NookPlane] ✅ Player welded to plane seat")
			
			-- Also create a Motor6D for more stable attachment (ROTATED 90 DEGREES RIGHT)
			local motor = Instance.new("Motor6D")
			motor.Name = "PlaneSeatMotor"
			motor.Part0 = self._seatPart or self._planeBody
			motor.Part1 = humanoidRootPart
			-- C0: Offset from plane (behind and below seat), ROTATE 90 DEGREES RIGHT around Y axis
			motor.C0 = CFrame.new(0, -1.5, -1.5) * CFrame.Angles(0, math.rad(-90), 0) -- -90 = 90 degrees RIGHT
			-- C1: Player's local offset (none)
			motor.C1 = CFrame.new(0, 0, 0)
			motor.Parent = humanoidRootPart
			self._playerMotor = motor
			print("[NookPlane] ✅ Added Motor6D for stable attachment (rotated 90 degrees RIGHT)")
			
			-- Make player invisible
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 1
				end
			end
			print("[NookPlane] ✅ Player made invisible")
			
			-- Anchor the humanoid root part to prevent physics from moving it
			humanoidRootPart.Anchored = false -- Don't anchor, use constraints
		end
	end

	-- Start engine sound
	self:_startEngineSound()
	
	-- Setup controls
	self:_setupInput()
	
	-- Setup camera (free 3D view, follows plane externally)
	self:_setupCamera()
	
	-- DON'T unanchor yet - let flight loop handle it based on water detection
	-- This prevents the plane from falling before we check if it's on water
	print("[NookPlane] ✅ Plane ready - flight loop will manage anchoring")
	
	-- Create HUD
	self:_createFlightHUD()
	
	-- Start propeller (disabled)
	self:_startPropeller()
	
	-- Start flight
	self:_startFlight()
	
	-- Start light flashing animation
	self:_startLightFlash()
	
	print("[NookPlane] ✅ Plane is now ON - WASD to control, Spacebar to throttle, free camera")
end

-- Turn off the plane
function NookPlane:TurnOff()
	if not self._flying then
		print("[NookPlane] ℹ️ Plane already off")
		return
	end

	print("[NookPlane] 🛬 Turning off plane")
	self._flying = false

	-- Stop flight
	self:_stopFlight()
	
	-- Stop propeller
	self:_stopPropeller()
	
	-- Stop engine sound
	self:_stopEngineSound()
	
	-- Stop light flashing
	self:_stopLightFlash()
	
	-- Remove HUD
	self:_removeFlightHUD()
	
	-- Restore camera
	self:_restoreCamera()
	
	-- Unweld and unmotor player
	if self._playerWeld then
		self._playerWeld:Destroy()
		self._playerWeld = nil
	end
	
	if self._playerMotor then
		self._playerMotor:Destroy()
		self._playerMotor = nil
	end
	
	-- Keep welds for Lights and Body (they stay attached to plane)
	-- Don't destroy them - they're permanent
	
	-- Re-enable humanoid
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = false
			humanoid.PlatformStand = false
		end
		print("[NookPlane] ✅ Player controls restored")
	end
	
	-- Make player visible again
	local character = LocalPlayer.Character
	if character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 0
			end
		end
		print("[NookPlane] ✅ Player made visible")
	end
	
	-- Clear input connections
	for _, conn in pairs(self._inputConnections) do
		if conn then
			conn:Disconnect()
		end
	end
	self._inputConnections = {}
	
	print("[NookPlane] ✅ Plane turned OFF")
end

-- Check if plane is flying
function NookPlane:IsFlying()
	return self._flying
end

-- Create flight HUD
function NookPlane:_createFlightHUD()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	
	-- Remove existing HUD if present
	local existingHUD = playerGui:FindFirstChild("PlaneHUD")
	if existingHUD then
		existingHUD:Destroy()
	end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PlaneHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	local hudFrame = Instance.new("Frame")
	hudFrame.Name = "HUDFrame"
	hudFrame.Size = UDim2.new(0, 300, 0, 180)
	hudFrame.Position = UDim2.new(0.5, -150, 0, 20)
	hudFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	hudFrame.BackgroundTransparency = 0.3
	hudFrame.BorderSizePixel = 0
	hudFrame.Parent = screenGui
	
	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = hudFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "✈️ NOOK AIRLINES"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = hudFrame
	
	-- Speed Label
	local speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "SpeedLabel"
	speedLabel.Size = UDim2.new(1, -20, 0, 25)
	speedLabel.Position = UDim2.new(0, 10, 0, 40)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Speed: 0"
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedLabel.TextSize = 16
	speedLabel.Font = Enum.Font.Gotham
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.Parent = hudFrame
	
	-- Altitude Label
	local altitudeLabel = Instance.new("TextLabel")
	altitudeLabel.Name = "AltitudeLabel"
	altitudeLabel.Size = UDim2.new(1, -20, 0, 25)
	altitudeLabel.Position = UDim2.new(0, 10, 0, 70)
	altitudeLabel.BackgroundTransparency = 1
	altitudeLabel.Text = "Altitude: 0"
	altitudeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	altitudeLabel.TextSize = 16
	altitudeLabel.Font = Enum.Font.Gotham
	altitudeLabel.TextXAlignment = Enum.TextXAlignment.Left
	altitudeLabel.Parent = hudFrame
	
	-- Throttle Label
	local throttleLabel = Instance.new("TextLabel")
	throttleLabel.Name = "ThrottleLabel"
	throttleLabel.Size = UDim2.new(1, -20, 0, 25)
	throttleLabel.Position = UDim2.new(0, 10, 0, 100)
	throttleLabel.BackgroundTransparency = 1
	throttleLabel.Text = "Throttle: 0%"
	throttleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	throttleLabel.TextSize = 16
	throttleLabel.Font = Enum.Font.Gotham
	throttleLabel.TextXAlignment = Enum.TextXAlignment.Left
	throttleLabel.Parent = hudFrame
	
	-- Controls Label
	local controlsLabel = Instance.new("TextLabel")
	controlsLabel.Name = "ControlsLabel"
	controlsLabel.Size = UDim2.new(1, -20, 0, 40)
	controlsLabel.Position = UDim2.new(0, 10, 0, 130)
	controlsLabel.BackgroundTransparency = 1
	controlsLabel.Text = "WASD: Controls | Spacebar: Throttle\nP: Exit | Camera: Free 3D View"
	controlsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	controlsLabel.TextSize = 12
	controlsLabel.Font = Enum.Font.Gotham
	controlsLabel.TextXAlignment = Enum.TextXAlignment.Left
	controlsLabel.TextWrapped = true
	controlsLabel.Parent = hudFrame
	
	-- Update speed and altitude in real-time
	self._hudUpdateConnection = RunService.Heartbeat:Connect(function()
		if not self._planeBody or not self._planeBody.Parent then
			self:_removeFlightHUD()
			return
		end
		
		local velocity = self._planeBody.AssemblyLinearVelocity
		local speed = math.floor(velocity.Magnitude)
		local altitude = math.floor(self._planeBody.Position.Y)
		local throttlePercent = math.floor(self._currentSpeedMultiplier * 100)
		
		speedLabel.Text = "Speed: " .. speed .. " studs/s"
		altitudeLabel.Text = "Altitude: " .. altitude .. " studs"
		
		-- Update throttle label
		local throttleLabel = hudFrame:FindFirstChild("ThrottleLabel")
		if throttleLabel then
			throttleLabel.Text = "Throttle: " .. throttlePercent .. "%"
			-- Color based on throttle level
			if throttlePercent < 30 then
				throttleLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red (low)
			elseif throttlePercent < 70 then
				throttleLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow (medium)
			else
				throttleLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green (high)
			end
		end
		
		-- Show water status
		local isOnWater = self._isOnWater or false
		if isOnWater then
			altitudeLabel.Text = "🌊 On Water - Float Mode"
			altitudeLabel.TextColor3 = Color3.fromRGB(100, 200, 255) -- Blue (water)
		else
			-- Color altitude label based on height
			if altitude < 20 then
				altitudeLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red (low)
			elseif altitude < 50 then
				altitudeLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow (medium)
			else
				altitudeLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green (high)
			end
		end
		
		-- Show speed and mode
		local speed = self._planeBody.AssemblyLinearVelocity.Magnitude
		if isOnWater then
			speedLabel.Text = "🌊 TAXI MODE | Speed: " .. math.floor(speed) .. " | Press W to takeoff"
		else
			speedLabel.Text = "✈️ FLIGHT MODE | Speed: " .. math.floor(speed) .. " | Altitude: " .. math.floor(altitude)
		end
	end)
	
	print("[NookPlane] ✅ Flight HUD created")
end

-- Remove flight HUD
function NookPlane:_removeFlightHUD()
	if self._hudUpdateConnection then
		self._hudUpdateConnection:Disconnect()
		self._hudUpdateConnection = nil
	end
	
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local hud = playerGui:FindFirstChild("PlaneHUD")
		if hud then
			hud:Destroy()
			print("[NookPlane] ✅ Flight HUD removed")
		end
	end
end

-- Check if player is near the plane
function NookPlane:_isPlayerNearPlane()
	if not self._planeBody or not self._planeBody.Parent then
		return false
	end
	
	local character = LocalPlayer.Character
	if not character then
		return false
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return false
	end
	
	local distance = (humanoidRootPart.Position - self._planeBody.Position).Magnitude
	return distance <= 15 -- 15 studs proximity
end

-- Create proximity UI
function NookPlane:_createProximityUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	
	-- Remove existing proximity UI if present
	local existingUI = playerGui:FindFirstChild("PlaneProximityUI")
	if existingUI then
		existingUI:Destroy()
	end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PlaneProximityUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	local promptFrame = Instance.new("Frame")
	promptFrame.Name = "PromptFrame"
	promptFrame.Size = UDim2.new(0, 200, 0, 50)
	promptFrame.Position = UDim2.new(0.5, -100, 0.8, 0)
	promptFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	promptFrame.BackgroundTransparency = 0.2
	promptFrame.BorderSizePixel = 0
	promptFrame.Visible = false -- Start hidden
	promptFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = promptFrame
	
	local promptLabel = Instance.new("TextLabel")
	promptLabel.Name = "PromptLabel"
	promptLabel.Size = UDim2.new(1, 0, 1, 0)
	promptLabel.BackgroundTransparency = 1
	promptLabel.Text = "[E] Enter Plane"
	promptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptLabel.TextSize = 18
	promptLabel.Font = Enum.Font.GothamBold
	promptLabel.Parent = promptFrame
	
	-- Update visibility based on proximity
	self._proximityUpdateConnection = RunService.Heartbeat:Connect(function()
		if not self._planeBody or not self._planeBody.Parent then
			if promptFrame then
				promptFrame.Visible = false
			end
			return
		end
		
		local isNear = self:_isPlayerNearPlane()
		local isFlying = self:IsFlying()
		
		promptFrame.Visible = isNear and not isFlying
	end)
	
	print("[NookPlane] ✅ Proximity UI created")
end

-- Remove proximity UI
function NookPlane:_removeProximityUI()
	if self._proximityUpdateConnection then
		self._proximityUpdateConnection:Disconnect()
		self._proximityUpdateConnection = nil
	end
	
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local proximityUI = playerGui:FindFirstChild("PlaneProximityUI")
		if proximityUI then
			proximityUI:Destroy()
			print("[NookPlane] ✅ Proximity UI removed")
		end
	end
end

-- Try to enter the plane (called by E key)
function NookPlane:TryEnter()
	if self:IsFlying() then
		print("[NookPlane] Already flying, exiting...")
		self:TurnOff()
		return
	end
	
	if self:_isPlayerNearPlane() then
		print("[NookPlane] Player is near plane, entering...")
		self:TurnOn()
	else
		print("[NookPlane] Player is not near the plane")
	end
end

-- Cleanup
function NookPlane:Destroy()
	self:TurnOff()
	self:_removeProximityUI()
	
	for _, conn in pairs(self._inputConnections) do
		if conn then
			conn:Disconnect()
		end
	end
	self._inputConnections = {}
	
	print("[NookPlane] ✅ NookPlane instance destroyed")
end

return NookPlane
