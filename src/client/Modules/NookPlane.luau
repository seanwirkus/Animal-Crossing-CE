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
local WATER_SURFACE_CLEARANCE = 0.75 -- How far the floats sit above the water surface
local LIFT_COEFFICIENT = 45 -- Upward force gained from throttle while flying
local CLIMB_RATE = 35 -- Additional climb rate when pressing the climb key
local DESCEND_RATE = 40 -- Additional sink rate when pressing the descend key
local MAX_BANK_ANGLE = math.rad(18) -- Maximum roll of the plane while turning
local MAX_PITCH_ANGLE = math.rad(12) -- Maximum pitch (nose up/down)
local AIR_TURN_RATE = math.rad(35) -- How fast the plane yaws while airborne
local WATER_TURN_RATE = math.rad(60) -- How fast the plane yaws while on water
local TAXI_SPEED = 28 -- Default taxi speed when throttle is applied on the water
local TAXI_REVERSE_SPEED = 12 -- Reverse speed while on the water
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
        self._modelHeight = nil
        self._floatWaterlineOffset = nil
        self._orientationCFrame = nil
        self._currentPitch = 0
        self._currentYaw = 0
        self._currentRoll = 0
        self._flying = false
        self._inputConnections = {}
        self._flightConnection = nil
        self._propellerConnection = nil
        self._hudUpdateConnection = nil
        self._hudElements = {}
        self._proximityUpdateConnection = nil
        self._playerWeld = nil
        self._playerMotor = nil
        self._engineSound = nil
        self._takeoffStartTime = nil
        self._isOnWater = false
        self._orientationCFrame = nil
        self._currentPitch = 0
        self._currentRoll = 0
        self._currentYaw = 0

        -- Flight controls state (WASD for plane, Spacebar for throttle)
        self.CONTROLS = {
                forward = false,
                backward = false,
                left = false,
                right = false,
                throttle = false, -- Spacebar for throttle
                ascend = false, -- R key
                descend = false, -- F key
        }
        self._currentSpeedMultiplier = 0.25 -- Current speed multiplier (0.0 to 1.0)
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

                                if not self._planeModel.PrimaryPart then
                                        local ok, err = pcall(function()
                                                self._planeModel.PrimaryPart = self._planeBody
                                        end)
                                        if not ok then
                                                warn("[NookPlane] ⚠️ Failed to set PrimaryPart:", err)
                                        end
                                end

                                local ok, _, modelSize = pcall(function()
                                        return self._planeModel:GetBoundingBox()
                                end)
                                if ok and modelSize then
                                        self._modelHeight = modelSize.Y
                                else
                                        self._modelHeight = self._planeBody.Size.Y
                                end

                                if self._floatPart then
                                        local floatBottomWorld = self._floatPart.Position.Y - (self._floatPart.Size.Y / 2)
                                        self._floatWaterlineOffset = self._planeBody.Position.Y - floatBottomWorld
                                elseif self._modelHeight then
                                        self._floatWaterlineOffset = self._modelHeight / 2
                                else
                                        self._floatWaterlineOffset = self._planeBody.Size.Y / 2
                                end

                                if self._floatWaterlineOffset and self._floatWaterlineOffset < 1 then
                                        self._floatWaterlineOffset = math.max(self._planeBody.Size.Y / 2, 6)
                                end

                                local pitch, yaw, roll = self._planeBody.CFrame:ToOrientation()
                                self._currentPitch = pitch
                                self._currentYaw = yaw
                                self._currentRoll = roll
                                self._orientationCFrame = self._planeBody.CFrame

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

        local bodyVelocity = self._planeBody and self._planeBody:FindFirstChild("BodyVelocity")
        local bodyAngularVelocity = self._planeBody and self._planeBody:FindFirstChild("BodyAngularVelocity")
        local bodyPosition = self._planeBody and self._planeBody:FindFirstChild("BodyPosition")

        if not bodyPosition then
                bodyPosition = Instance.new("BodyPosition")
                bodyPosition.Name = "BodyPosition"
                bodyPosition.MaxForce = Vector3.new(0, 0, 0)
                bodyPosition.P = 500
                bodyPosition.D = 100
                bodyPosition.Position = self._planeBody.Position
                bodyPosition.Parent = self._planeBody
        end

        if not bodyVelocity or not bodyAngularVelocity then
                warn("[NookPlane] ❌ Missing BodyVelocity or BodyAngularVelocity!")
                return
        end

        self._planeBody.Anchored = false
        bodyAngularVelocity.MaxTorque = Vector3.new(0, 0, 0)
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)

        local pitch, yaw, roll = self._planeBody.CFrame:ToOrientation()
        self._currentPitch = pitch
        self._currentYaw = yaw
        self._currentRoll = roll
        self._orientationCFrame = self._planeBody.CFrame

        self._flightConnection = RunService.Heartbeat:Connect(function(deltaTime)
                if not self._planeBody or not self._planeBody.Parent then
                        self:TurnOff()
                        return
                end

                deltaTime = math.clamp(deltaTime, 0, 0.1)

                local camera = workspace.CurrentCamera
                if camera and camera.CameraType == Enum.CameraType.Scriptable then
                        local planeCFrame = self._planeBody.CFrame
                        local planePos = planeCFrame.Position
                        local forward = planeCFrame.LookVector
                        local right = planeCFrame.RightVector
                        local cameraDistance = 25
                        local cameraHeight = 10
                        local cameraSideOffset = 3
                        local targetPos = planePos + (forward * -cameraDistance) + Vector3.new(0, cameraHeight, 0) + (right * cameraSideOffset)
                        local currentPos = camera.CFrame.Position
                        local lerpAlpha = math.min(deltaTime * 8, 1)
                        local smoothPos = currentPos:Lerp(targetPos, lerpAlpha)
                        local lookTarget = planePos + (forward * 10)
                        camera.CFrame = CFrame.lookAt(smoothPos, lookTarget)
                end

                local throttleChange = 0.6
                if self.CONTROLS.throttle then
                        self._targetSpeedMultiplier = math.min(self._targetSpeedMultiplier + (throttleChange * deltaTime), 1)
                else
                        self._targetSpeedMultiplier = math.max(self._targetSpeedMultiplier - (throttleChange * deltaTime), 0)
                end

                local speedDiff = self._targetSpeedMultiplier - self._currentSpeedMultiplier
                self._currentSpeedMultiplier = self._currentSpeedMultiplier + (speedDiff * math.min(deltaTime * 3, 1))
                local throttle = math.clamp(self._currentSpeedMultiplier, 0, 1)

                local planePos = self._planeBody.Position
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.IgnoreWater = false
                if self._planeModel then
                        raycastParams.FilterDescendantsInstances = {self._planeModel}
                end

                local primaryCast = Workspace:Raycast(planePos, Vector3.new(0, -200, 0), raycastParams)
                local isOnWater = false
                local waterSurfaceY

                if primaryCast and primaryCast.Material == Enum.Material.Water then
                        isOnWater = true
                        waterSurfaceY = primaryCast.Position.Y
                else
                        local offsets = {
                                Vector3.new(6, 0, 0),
                                Vector3.new(-6, 0, 0),
                                Vector3.new(0, 0, 6),
                                Vector3.new(0, 0, -6),
                        }
                        for _, offset in ipairs(offsets) do
                                local sample = Workspace:Raycast(planePos + offset, Vector3.new(0, -200, 0), raycastParams)
                                if sample and sample.Material == Enum.Material.Water then
                                        isOnWater = true
                                        waterSurfaceY = sample.Position.Y
                                        break
                                end
                        end
                end

                self._isOnWater = isOnWater
                self._planeBody.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                local yawInput = 0
                if self.CONTROLS.left then
                        yawInput += 1
                end
                if self.CONTROLS.right then
                        yawInput -= 1
                end

                local climbCommand = 0
                if self.CONTROLS.ascend then
                        climbCommand += 1
                end
                if self.CONTROLS.descend then
                        climbCommand -= 1
                end

                if isOnWater and waterSurfaceY then
                        if bodyPosition then
                                local heightOffset = self._floatWaterlineOffset or (self._modelHeight and (self._modelHeight / 2)) or (self._planeBody.Size.Y / 2)
                                local desiredCenterY = waterSurfaceY + heightOffset + WATER_SURFACE_CLEARANCE
                                bodyPosition.MaxForce = Vector3.new(0, 400000, 0)
                                bodyPosition.P = 6000
                                bodyPosition.D = 1200
                                bodyPosition.Position = Vector3.new(planePos.X, desiredCenterY, planePos.Z)
                        end

                        local decay = math.min(deltaTime * 5, 1)
                        self._currentPitch += (-self._currentPitch * decay)
                        self._currentRoll += (-self._currentRoll * decay)
                        self._currentYaw += yawInput * WATER_TURN_RATE * deltaTime

                        local orientation = CFrame.fromOrientation(self._currentPitch, self._currentYaw, self._currentRoll)
                        self._orientationCFrame = CFrame.new(self._planeBody.Position) * orientation
                        self._planeBody.CFrame = self._orientationCFrame

                        local forward = self._orientationCFrame.LookVector
                        local right = self._orientationCFrame.RightVector

                        local taxiVelocity = Vector3.zero
                        if self.CONTROLS.forward then
                                taxiVelocity += forward * (TAXI_SPEED + (FLIGHT_SPEED * throttle * 0.5))
                        elseif self.CONTROLS.backward then
                                taxiVelocity -= forward * TAXI_REVERSE_SPEED
                        end
                        if yawInput ~= 0 then
                                taxiVelocity += right * (yawInput * 6)
                        end

                        bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
                        bodyVelocity.Velocity = Vector3.new(taxiVelocity.X, 0, taxiVelocity.Z)
                else
                        if bodyPosition then
                                bodyPosition.MaxForce = Vector3.new(0, 0, 0)
                        end

                        self._currentYaw += yawInput * AIR_TURN_RATE * deltaTime

                        local rollTarget = math.clamp(yawInput, -1, 1) * MAX_BANK_ANGLE
                        local pitchTarget = math.clamp(climbCommand, -1, 1) * MAX_PITCH_ANGLE

                        local rollLerp = math.min(deltaTime * 3, 1)
                        local pitchLerp = math.min(deltaTime * 3, 1)

                        self._currentRoll += (rollTarget - self._currentRoll) * rollLerp
                        self._currentPitch += (pitchTarget - self._currentPitch) * pitchLerp

                        local orientation = CFrame.fromOrientation(self._currentPitch, self._currentYaw, self._currentRoll)
                        self._orientationCFrame = CFrame.new(self._planeBody.Position) * orientation
                        self._planeBody.CFrame = self._orientationCFrame

                        local forward = self._orientationCFrame.LookVector
                        local right = self._orientationCFrame.RightVector
                        local up = self._orientationCFrame.UpVector

                        local forwardSpeed = FLIGHT_SPEED * throttle
                        if self.CONTROLS.forward then
                                forwardSpeed += 20
                        end
                        if self.CONTROLS.backward then
                                forwardSpeed -= 15
                        end
                        forwardSpeed = math.clamp(forwardSpeed, -FLIGHT_SPEED * 0.4, FLIGHT_SPEED * 1.4)

                        local targetVelocity = forward * forwardSpeed
                        targetVelocity += right * (self._currentRoll / MAX_BANK_ANGLE) * 12

                        local lift = (throttle ^ 1.2) * LIFT_COEFFICIENT
                        lift += climbCommand * CLIMB_RATE
                        if not self.CONTROLS.throttle then
                                lift -= DESCEND_RATE * 0.5
                        end
                        if self.CONTROLS.backward then
                                lift -= DESCEND_RATE * 0.6
                        end
                        local verticalVelocity = math.clamp(lift, -DESCEND_RATE * 2, CLIMB_RATE * 2)
                        targetVelocity += up * verticalVelocity

                        local currentVelocity = self._planeBody.AssemblyLinearVelocity
                        local smoothing = math.min(deltaTime * 4, 1)
                        local blendedVelocity = currentVelocity:Lerp(targetVelocity, smoothing)

                        bodyVelocity.MaxForce = Vector3.new(120000, 120000, 120000)
                        bodyVelocity.Velocity = blendedVelocity
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
        self._orientationCFrame = nil
        self._currentPitch = 0
        self._currentRoll = 0
        self._currentYaw = 0
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
                elseif input.KeyCode == Enum.KeyCode.R then
                        self.CONTROLS.ascend = true
                elseif input.KeyCode == Enum.KeyCode.F then
                        self.CONTROLS.descend = true
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
                elseif input.KeyCode == Enum.KeyCode.R then
                        self.CONTROLS.ascend = false
                elseif input.KeyCode == Enum.KeyCode.F then
                        self.CONTROLS.descend = false
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
        self._currentSpeedMultiplier = 0.25
        self._targetSpeedMultiplier = 0

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

        for key in pairs(self.CONTROLS) do
                self.CONTROLS[key] = false
        end

        print("[NookPlane] ✅ Plane turned OFF")
end

-- Check if plane is flying
function NookPlane:IsFlying()
	return self._flying
end

-- Create flight HUD
function NookPlane:_createFlightHUD()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")

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
        hudFrame.Size = UDim2.new(0, 320, 0, 220)
        hudFrame.Position = UDim2.new(0, 20, 1, -240)
        hudFrame.BackgroundColor3 = Color3.fromRGB(24, 34, 48)
        hudFrame.BackgroundTransparency = 0.1
        hudFrame.BorderSizePixel = 0
        hudFrame.Parent = screenGui

        local hudCorner = Instance.new("UICorner")
        hudCorner.CornerRadius = UDim.new(0, 14)
        hudCorner.Parent = hudFrame

        local hudStroke = Instance.new("UIStroke")
        hudStroke.Thickness = 2
        hudStroke.Color = Color3.fromRGB(80, 160, 220)
        hudStroke.Transparency = 0.3
        hudStroke.Parent = hudFrame

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 26, 38)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 48, 68)),
        })
        gradient.Rotation = 90
        gradient.Parent = hudFrame

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 14)
        padding.PaddingBottom = UDim.new(0, 14)
        padding.PaddingLeft = UDim.new(0, 16)
        padding.PaddingRight = UDim.new(0, 16)
        padding.Parent = hudFrame

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 24)
        title.BackgroundTransparency = 1
        title.Text = "✈️ Nook Airlines Flight Deck"
        title.TextColor3 = Color3.fromRGB(230, 240, 255)
        title.TextSize = 20
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = hudFrame

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(1, 0, 0, 20)
        statusLabel.Position = UDim2.new(0, 0, 0, 28)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "Systems Initializing..."
        statusLabel.TextColor3 = Color3.fromRGB(115, 190, 255)
        statusLabel.TextSize = 14
        statusLabel.Font = Enum.Font.GothamMedium
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.Parent = hudFrame

        local modeLabel = Instance.new("TextLabel")
        modeLabel.Name = "ModeLabel"
        modeLabel.Size = UDim2.new(1, 0, 0, 18)
        modeLabel.Position = UDim2.new(0, 0, 0, 50)
        modeLabel.BackgroundTransparency = 1
        modeLabel.Text = "Mode: --"
        modeLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
        modeLabel.TextSize = 13
        modeLabel.Font = Enum.Font.Gotham
        modeLabel.TextXAlignment = Enum.TextXAlignment.Left
        modeLabel.Parent = hudFrame

        local statsFrame = Instance.new("Frame")
        statsFrame.Name = "Stats"
        statsFrame.Size = UDim2.new(1, -8, 0, 96)
        statsFrame.Position = UDim2.new(0, 0, 0, 74)
        statsFrame.BackgroundTransparency = 1
        statsFrame.Parent = hudFrame

        local statsList = Instance.new("UIListLayout")
        statsList.FillDirection = Enum.FillDirection.Vertical
        statsList.HorizontalAlignment = Enum.HorizontalAlignment.Left
        statsList.SortOrder = Enum.SortOrder.LayoutOrder
        statsList.Padding = UDim.new(0, 6)
        statsList.Parent = statsFrame

        local function createStatLabel(name)
                local label = Instance.new("TextLabel")
                label.Name = name .. "Label"
                label.Size = UDim2.new(1, 0, 0, 26)
                label.BackgroundTransparency = 1
                label.Text = name .. ": --"
                label.TextColor3 = Color3.fromRGB(235, 240, 255)
                label.TextSize = 16
                label.Font = Enum.Font.Gotham
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = statsFrame
                return label
        end

        local speedLabel = createStatLabel("Speed")
        local altitudeLabel = createStatLabel("Altitude")

        local throttleFrame = Instance.new("Frame")
        throttleFrame.Name = "ThrottleFrame"
        throttleFrame.Size = UDim2.new(1, -4, 0, 42)
        throttleFrame.Position = UDim2.new(0, 0, 0, 176)
        throttleFrame.BackgroundColor3 = Color3.fromRGB(18, 26, 38)
        throttleFrame.BackgroundTransparency = 0.1
        throttleFrame.BorderSizePixel = 0
        throttleFrame.Parent = hudFrame

        local throttleCorner = Instance.new("UICorner")
        throttleCorner.CornerRadius = UDim.new(0, 10)
        throttleCorner.Parent = throttleFrame

        local throttleStroke = Instance.new("UIStroke")
        throttleStroke.Thickness = 1
        throttleStroke.Color = Color3.fromRGB(80, 120, 160)
        throttleStroke.Transparency = 0.4
        throttleStroke.Parent = throttleFrame

        local throttleLabel = Instance.new("TextLabel")
        throttleLabel.Name = "ThrottleValue"
        throttleLabel.Size = UDim2.new(1, 0, 0, 20)
        throttleLabel.Position = UDim2.new(0, 0, 0, 4)
        throttleLabel.BackgroundTransparency = 1
        throttleLabel.Text = "Throttle 0%"
        throttleLabel.TextColor3 = Color3.fromRGB(230, 240, 255)
        throttleLabel.TextSize = 14
        throttleLabel.Font = Enum.Font.GothamMedium
        throttleLabel.TextXAlignment = Enum.TextXAlignment.Left
        throttleLabel.Parent = throttleFrame

        local throttleBar = Instance.new("Frame")
        throttleBar.Name = "ThrottleBar"
        throttleBar.Size = UDim2.new(1, 0, 0, 10)
        throttleBar.Position = UDim2.new(0, 0, 1, -14)
        throttleBar.BackgroundColor3 = Color3.fromRGB(50, 60, 75)
        throttleBar.BorderSizePixel = 0
        throttleBar.Parent = throttleFrame

        local throttleBarCorner = Instance.new("UICorner")
        throttleBarCorner.CornerRadius = UDim.new(1, 0)
        throttleBarCorner.Parent = throttleBar

        local throttleFill = Instance.new("Frame")
        throttleFill.Name = "Fill"
        throttleFill.Size = UDim2.new(0, 0, 1, 0)
        throttleFill.BackgroundColor3 = Color3.fromRGB(255, 120, 90)
        throttleFill.BorderSizePixel = 0
        throttleFill.Parent = throttleBar

        local throttleFillCorner = Instance.new("UICorner")
        throttleFillCorner.CornerRadius = UDim.new(1, 0)
        throttleFillCorner.Parent = throttleFill

        local controlsLabel = Instance.new("TextLabel")
        controlsLabel.Name = "ControlsLabel"
        controlsLabel.Size = UDim2.new(1, 0, 0, 34)
        controlsLabel.Position = UDim2.new(0, 0, 1, -34)
        controlsLabel.BackgroundTransparency = 1
        controlsLabel.Text = "Controls: W/S Taxi • A/D Turn • Space Throttle\nR Climb • F Descend • P Exit"
        controlsLabel.TextColor3 = Color3.fromRGB(190, 205, 235)
        controlsLabel.TextSize = 12
        controlsLabel.Font = Enum.Font.Gotham
        controlsLabel.TextXAlignment = Enum.TextXAlignment.Left
        controlsLabel.TextWrapped = true
        controlsLabel.Parent = hudFrame

        self._hudElements = {
                speed = speedLabel,
                altitude = altitudeLabel,
                throttleValue = throttleLabel,
                throttleFill = throttleFill,
                status = statusLabel,
                mode = modeLabel,
        }

        if self._hudUpdateConnection then
                self._hudUpdateConnection:Disconnect()
        end

        self._hudUpdateConnection = RunService.Heartbeat:Connect(function()
                if not self._planeBody or not self._planeBody.Parent then
                        self:_removeFlightHUD()
                        return
                end

                local elements = self._hudElements
                if not elements or not elements.speed then
                        return
                end

                local velocity = self._planeBody.AssemblyLinearVelocity
                local speed = math.floor(velocity.Magnitude + 0.5)
                local altitude = math.floor(self._planeBody.Position.Y + 0.5)
                local throttlePercent = math.floor(math.clamp(self._currentSpeedMultiplier, 0, 1) * 100)

                elements.speed.Text = string.format("Speed: %d studs/s", speed)

                if self._isOnWater then
                        elements.altitude.Text = "Altitude: 🌊 Sea Level"
                        elements.altitude.TextColor3 = Color3.fromRGB(110, 200, 255)
                        elements.mode.Text = string.format("Mode: 🌊 Taxi | Speed %d", speed)
                        elements.status.Text = "Taxi Systems Ready"
                        elements.status.TextColor3 = Color3.fromRGB(115, 190, 255)
                else
                        elements.altitude.Text = string.format("Altitude: %d studs", altitude)
                        if altitude < 25 then
                                elements.altitude.TextColor3 = Color3.fromRGB(255, 140, 105)
                        elseif altitude < 80 then
                                elements.altitude.TextColor3 = Color3.fromRGB(255, 220, 120)
                        else
                                elements.altitude.TextColor3 = Color3.fromRGB(160, 250, 160)
                        end
                        elements.mode.Text = string.format("Mode: ✈️ Cruise | Alt %d", altitude)
                        elements.status.Text = "Flight Controls Active"
                        elements.status.TextColor3 = Color3.fromRGB(156, 255, 180)
                end

                elements.throttleValue.Text = string.format("Throttle %d%%", throttlePercent)
                local fillRatio = math.clamp(throttlePercent / 100, 0, 1)
                elements.throttleFill.Size = UDim2.new(fillRatio, 0, 1, 0)
                if throttlePercent < 30 then
                        elements.throttleFill.BackgroundColor3 = Color3.fromRGB(255, 120, 90)
                elseif throttlePercent < 70 then
                        elements.throttleFill.BackgroundColor3 = Color3.fromRGB(255, 205, 100)
                else
                        elements.throttleFill.BackgroundColor3 = Color3.fromRGB(110, 225, 140)
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

        self._hudElements = {}
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
