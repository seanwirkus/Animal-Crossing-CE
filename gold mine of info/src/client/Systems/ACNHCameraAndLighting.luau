-- Animal Crossing Camera & Lighting System
-- Recreates the warm, dreamy, cozy AC:NH visual style
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ACNHCameraAndLighting = {}
ACNHCameraAndLighting.__index = ACNHCameraAndLighting

-- Animal Crossing visual config
local ACNH_CONFIG = {
	-- Camera settings
	CAMERA_FOV = 70,  -- AC:NH has a slightly wider FOV for that cozy feel
	CAMERA_DISTANCE = 15,  -- Closer camera for intimacy
	CAMERA_ANGLE = 25,  -- Slight top-down angle (degrees)
	
	-- Lighting (warm, dreamy tones)
	AMBIENT_DAY = Color3.fromRGB(150, 170, 180),  -- Soft blue ambient
	AMBIENT_SUNSET = Color3.fromRGB(255, 180, 120),  -- Warm orange
	AMBIENT_NIGHT = Color3.fromRGB(80, 90, 120),  -- Cool night blue
	
	OUTDOOR_AMBIENT_DAY = Color3.fromRGB(180, 200, 210),  -- Bright warm day
	OUTDOOR_AMBIENT_SUNSET = Color3.fromRGB(255, 160, 100),  -- Golden hour
	OUTDOOR_AMBIENT_NIGHT = Color3.fromRGB(60, 70, 100),  -- Dark night
	
	-- Brightness & Exposure
	BRIGHTNESS_DAY = 2.5,  -- Bright and cheerful
	BRIGHTNESS_SUNSET = 2,
	BRIGHTNESS_NIGHT = 0.8,
	EXPOSURE_COMPENSATION = 0.2,  -- Slight overexposure for dreamy feel
	
	-- Sun
	SUN_INTENSITY_DAY = 1.5,
	SUN_INTENSITY_SUNSET = 1.2,
	SUN_INTENSITY_NIGHT = 0,
	
	-- Atmosphere (bloom, color correction)
	BLOOM_INTENSITY = 1,  -- Soft glow
	BLOOM_SIZE = 24,
	BLOOM_THRESHOLD = 0.8,
	
	-- Color correction (warm tones)
	SATURATION = 0.2,  -- Slightly more saturated
	CONTRAST = 0.1,  -- Soft contrast
	TINT_COLOR = Color3.fromRGB(255, 250, 240),  -- Warm cream tint
	
	-- Depth of field (dreamy blur)
	DOF_ENABLED = true,
	DOF_FOCUS_DISTANCE = 20,
	DOF_BLUR_SIZE = 15,
	
	-- Time of day settings
	TIME_MULTIPLIER = 0.5,  -- Slower day/night cycle
}

function ACNHCameraAndLighting.new()
	local self = setmetatable({}, ACNHCameraAndLighting)
	
	self._player = Players.LocalPlayer
	self._camera = Workspace.CurrentCamera
	self._currentTimeOfDay = "day"
	
	self:_setupLighting()
	self:_setupCamera()
	self:_setupAtmosphere()
	self:_startDynamicLighting()
	
	print("[ACNHCamera] ✅ Animal Crossing visual style applied!")
	
	return self
end

-- Setup lighting for AC:NH warm, dreamy feel
function ACNHCameraAndLighting:_setupLighting()
	-- Basic lighting properties
	Lighting.Ambient = ACNH_CONFIG.AMBIENT_DAY
	Lighting.OutdoorAmbient = ACNH_CONFIG.OUTDOOR_AMBIENT_DAY
	Lighting.Brightness = ACNH_CONFIG.BRIGHTNESS_DAY
	Lighting.ColorShift_Bottom = Color3.fromRGB(200, 180, 160)  -- Warm ground reflection
	Lighting.ColorShift_Top = Color3.fromRGB(200, 220, 255)  -- Cool sky
	Lighting.EnvironmentDiffuseScale = 0.8
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ExposureCompensation = ACNH_CONFIG.EXPOSURE_COMPENSATION
	
	-- Sunrays for dreamy effect
	Lighting.GlobalShadows = true
	Lighting.Technology = Enum.Technology.ShadowMap  -- Softer shadows like AC
	Lighting.ShadowSoftness = 0.5  -- Very soft shadows
	
	-- Clock time (afternoon for warm light)
	Lighting.ClockTime = 14  -- 2 PM - perfect golden light
	Lighting.GeographicLatitude = 0  -- Tropical island feel
	
	print("[ACNHCamera] Lighting configured (warm, dreamy tones)")
end

-- Setup camera for AC:NH style
function ACNHCameraAndLighting:_setupCamera()
	self._player.CameraMaxZoomDistance = ACNH_CONFIG.CAMERA_DISTANCE
	self._player.CameraMinZoomDistance = ACNH_CONFIG.CAMERA_DISTANCE / 2
	
	-- Set FOV
	self._camera.FieldOfView = ACNH_CONFIG.CAMERA_FOV
	
	-- Camera type (following player with slight offset)
	self._camera.CameraType = Enum.CameraType.Custom
	
	-- Apply slight angle when character loads
	self._player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		self:_applyCameraAngle(character)
	end)
	
	if self._player.Character then
		self:_applyCameraAngle(self._player.Character)
	end
	
	print("[ACNHCamera] Camera configured (FOV: 70, Distance: 15)")
end

-- Apply slight top-down camera angle (AC:NH style)
function ACNHCameraAndLighting:_applyCameraAngle(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Adjust camera offset for slight top-down view
	humanoid.CameraOffset = Vector3.new(0, 2, 0)  -- Slightly higher view
	
	print("[ACNHCamera] Camera angle applied")
end

-- Setup atmospheric effects (bloom, color correction, DOF)
function ACNHCameraAndLighting:_setupAtmosphere()
	-- Clear existing effects
	for _, effect in pairs(Lighting:GetChildren()) do
		if effect:IsA("PostEffect") then
			effect:Destroy()
		end
	end
	
	-- Bloom (soft glow on bright objects)
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "ACNHBloom"
	bloom.Intensity = ACNH_CONFIG.BLOOM_INTENSITY
	bloom.Size = ACNH_CONFIG.BLOOM_SIZE
	bloom.Threshold = ACNH_CONFIG.BLOOM_THRESHOLD
	bloom.Enabled = true
	bloom.Parent = Lighting
	
	-- Color Correction (warm tones)
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ACNHColorCorrection"
	colorCorrection.Saturation = ACNH_CONFIG.SATURATION
	colorCorrection.Contrast = ACNH_CONFIG.CONTRAST
	colorCorrection.TintColor = ACNH_CONFIG.TINT_COLOR
	colorCorrection.Brightness = 0.05  -- Slightly brighter
	colorCorrection.Enabled = true
	colorCorrection.Parent = Lighting
	
	-- Depth of Field (dreamy blur)
	if ACNH_CONFIG.DOF_ENABLED then
		local depthOfField = Instance.new("DepthOfFieldEffect")
		depthOfField.Name = "ACNHDepthOfField"
		depthOfField.FocusDistance = ACNH_CONFIG.DOF_FOCUS_DISTANCE
		depthOfField.InFocusRadius = 15
		depthOfField.NearIntensity = 0.3
		depthOfField.FarIntensity = 0.5
		depthOfField.Enabled = true
		depthOfField.Parent = Lighting
	end
	
	-- Sun Rays (god rays through trees)
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "ACNHSunRays"
	sunRays.Intensity = 0.15  -- Subtle
	sunRays.Spread = 0.1
	sunRays.Enabled = true
	sunRays.Parent = Lighting
	
	-- Atmosphere (sky, horizon)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "ACNHAtmosphere"
	atmosphere.Density = 0.3  -- Light atmosphere
	atmosphere.Offset = 0.5  -- Higher sun position
	atmosphere.Color = Color3.fromRGB(199, 220, 255)  -- Light blue
	atmosphere.Decay = Color3.fromRGB(106, 142, 192)  -- Soft blue decay
	atmosphere.Glare = 0.5  -- Some glare for dreamy effect
	atmosphere.Haze = 1.5  -- Soft horizon haze
	atmosphere.Parent = Lighting
	
	-- Sky (if not already present)
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.Name = "ACNHSky"
		sky.SkyboxBk = "rbxasset://sky/sky512_bk.tex"  -- Default Roblox sky (or custom)
		sky.SkyboxDn = "rbxasset://sky/sky512_dn.tex"
		sky.SkyboxFt = "rbxasset://sky/sky512_ft.tex"
		sky.SkyboxLf = "rbxasset://sky/sky512_lf.tex"
		sky.SkyboxRt = "rbxasset://sky/sky512_rt.tex"
		sky.SkyboxUp = "rbxasset://sky/sky512_up.tex"
		sky.SunAngularSize = 15  -- Larger sun
		sky.MoonAngularSize = 11
		sky.CelestialBodiesShown = true
		sky.Parent = Lighting
	end
	
	print("[ACNHCamera] Atmospheric effects applied (bloom, color correction, DOF, sun rays)")
end

-- Start dynamic lighting based on time of day
function ACNHCameraAndLighting:_startDynamicLighting()
	-- Listen for time changes from server
	local remotesFolder = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
	-- local clockRemote = remotesFolder:FindFirstChild("ClockSync") -- Disabled for now
	
	-- Disabled for now - using static lighting
	-- if clockRemote then
	--	clockRemote.OnClientEvent:Connect(function(clockState)
	--		if clockState and clockState.clockTime then
	--			self:_updateLightingForTime(clockState.clockTime, clockState.isDay)
	--		end
	--	end)
	-- end
	
	-- Use static lighting instead
	self:_updateLightingForTime(12, true)
	
	-- Also run a local update loop for smooth transitions
	RunService.RenderStepped:Connect(function()
		self:_updateDynamicEffects()
	end)
	
	print("[ACNHCamera] Dynamic lighting enabled")
end

-- Update lighting based on time
function ACNHCameraAndLighting:_updateLightingForTime(clockTime, isDay)
	local timeOfDay = "day"
	
	-- Determine time of day
	if clockTime >= 5 and clockTime < 7 then
		timeOfDay = "sunrise"
	elseif clockTime >= 7 and clockTime < 17 then
		timeOfDay = "day"
	elseif clockTime >= 17 and clockTime < 19 then
		timeOfDay = "sunset"
	else
		timeOfDay = "night"
	end
	
	if timeOfDay == self._currentTimeOfDay then
		return
	end
	
	self._currentTimeOfDay = timeOfDay
	
	-- Tween lighting changes for smooth transitions
	local tweenInfo = TweenInfo.new(
		2,  -- 2 second transition
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)
	
	-- Set colors based on time
	local ambient, outdoor, brightness, sunIntensity
	
	if timeOfDay == "sunrise" or timeOfDay == "sunset" then
		ambient = ACNH_CONFIG.AMBIENT_SUNSET
		outdoor = ACNH_CONFIG.OUTDOOR_AMBIENT_SUNSET
		brightness = ACNH_CONFIG.BRIGHTNESS_SUNSET
		sunIntensity = ACNH_CONFIG.SUN_INTENSITY_SUNSET
	elseif timeOfDay == "day" then
		ambient = ACNH_CONFIG.AMBIENT_DAY
		outdoor = ACNH_CONFIG.OUTDOOR_AMBIENT_DAY
		brightness = ACNH_CONFIG.BRIGHTNESS_DAY
		sunIntensity = ACNH_CONFIG.SUN_INTENSITY_DAY
	else  -- night
		ambient = ACNH_CONFIG.AMBIENT_NIGHT
		outdoor = ACNH_CONFIG.OUTDOOR_AMBIENT_NIGHT
		brightness = ACNH_CONFIG.BRIGHTNESS_NIGHT
		sunIntensity = ACNH_CONFIG.SUN_INTENSITY_NIGHT
	end
	
	-- Apply with tweens
	local lightingTween = TweenService:Create(Lighting, tweenInfo, {
		Ambient = ambient,
		OutdoorAmbient = outdoor,
		Brightness = brightness,
	})
	lightingTween:Play()
	
	-- Update sun rays
	local sunRays = Lighting:FindFirstChild("ACNHSunRays")
	if sunRays then
		sunRays.Intensity = sunIntensity * 0.15
	end
	
	print(string.format("[ACNHCamera] Lighting updated for %s (%s)", timeOfDay, tostring(clockTime)))
end

-- Update dynamic effects every frame
function ACNHCameraAndLighting:_updateDynamicEffects()
	-- Subtle camera sway (very gentle, like AC:NH)
	if self._camera and self._camera.CameraType == Enum.CameraType.Custom then
		local time = tick()
		local swayX = math.sin(time * 0.5) * 0.02
		local swayY = math.cos(time * 0.3) * 0.02
		
		-- Apply very subtle sway
		-- (This is optional - remove if too much motion)
	end
end

return ACNHCameraAndLighting

