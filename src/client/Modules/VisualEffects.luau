--[[
	VisualEffects.luau
	
	Creates beautiful visual effects for Animal Crossing CE including:
	- Bloom and blur effects
	- Color correction for ACNH-style colors
	- Depth of field blur
	- Atmospheric effects
	- Sun rays and lighting enhancements
	- Vignette effects
	
	Usage:
		local VisualEffects = require(script.Parent.VisualEffects)
		VisualEffects.initialize()
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local VisualEffects = {}

-- Configuration
local CONFIG = {
	-- Bloom settings (soft glow)
	bloom = {
		enabled = true,
		intensity = 0.4,
		size = 24,
		threshold = 0.8
	},
	
	-- Blur settings
	blur = {
		enabled = true,
		size = 0  -- Disabled - just using other effects
	},
	
	-- Color correction (ACNH warm, cozy colors)
	colorCorrection = {
		enabled = true,
		brightness = 0.05,
		contrast = 0.1,
		saturation = 0.15,
		tintColor = Color3.fromRGB(255, 248, 240)  -- Warm cream tint
	},
	
	-- Depth of field (focus blur)
	depthOfField = {
		enabled = false,  -- Disabled - can cause blindness effect
		focusDistance = 30,
		nearIntensity = 0.3,
		farIntensity = 0.5,
		inFocusRadius = 20
	},
	
	-- Sun rays
	sunRays = {
		enabled = true,
		intensity = 0.15,
		spread = 0.5
	},
	
	-- Atmospheric effects
	atmosphere = {
		enabled = true,
		density = 0.3,
		offset = 0.25,
		color = Color3.fromRGB(199, 220, 255),  -- Light blue
		decay = Color3.fromRGB(106, 171, 255),  -- Sky blue
		glare = 0.4,
		haze = 1.5
	},
	
	-- Sky settings
	sky = {
		enabled = true,
		celestialBodiesShown = true,
		moonAngularSize = 11,
		starCount = 3000
	},
	
	-- Seasonal color grading
	seasons = {
		spring = {
			tint = Color3.fromRGB(255, 250, 240),  -- Warm peachy
			saturation = 0.2,
			brightness = 0.08,
			sunRaysIntensity = 0.18
		},
		summer = {
			tint = Color3.fromRGB(255, 252, 235),  -- Bright sunny
			saturation = 0.25,
			brightness = 0.12,
			sunRaysIntensity = 0.25
		},
		fall = {
			tint = Color3.fromRGB(255, 235, 210),  -- Orange/amber
			saturation = 0.3,
			brightness = 0.05,
			sunRaysIntensity = 0.15
		},
		winter = {
			tint = Color3.fromRGB(240, 245, 255),  -- Cool blue
			saturation = 0.1,
			brightness = 0.15,
			sunRaysIntensity = 0.2
		}
	},
	
	currentSeason = "spring"  -- Default season
}

--[[
	Creates and configures the Bloom effect
	Adds a soft glow to bright areas
]]
local function createBloom()
	if not CONFIG.bloom.enabled then return nil end
	
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "ACNHBloom"
	bloom.Intensity = CONFIG.bloom.intensity
	bloom.Size = CONFIG.bloom.size
	bloom.Threshold = CONFIG.bloom.threshold
	bloom.Parent = Lighting
	
	print("[VisualEffects] ✨ Bloom effect created")
	return bloom
end

--[[
	Creates and configures the Blur effect
	Adds subtle depth blur
]]
local function createBlur()
	if not CONFIG.blur.enabled then return nil end
	
	local blur = Instance.new("BlurEffect")
	blur.Name = "ACNHBlur"
	blur.Size = CONFIG.blur.size
	blur.Parent = Lighting
	
	print("[VisualEffects] 🌫️ Blur effect created")
	return blur
end

--[[
	Creates and configures Color Correction
	Applies ACNH warm, cozy color grading
]]
local function createColorCorrection()
	if not CONFIG.colorCorrection.enabled then return nil end
	
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ACNHColorCorrection"
	colorCorrection.Brightness = CONFIG.colorCorrection.brightness
	colorCorrection.Contrast = CONFIG.colorCorrection.contrast
	colorCorrection.Saturation = CONFIG.colorCorrection.saturation
	colorCorrection.TintColor = CONFIG.colorCorrection.tintColor
	colorCorrection.Parent = Lighting
	
	print("[VisualEffects] 🎨 Color correction created")
	return colorCorrection
end

--[[
	Creates and configures Depth of Field
	Blurs objects based on distance from camera
]]
local function createDepthOfField()
	if not CONFIG.depthOfField.enabled then return nil end
	
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "ACNHDepthOfField"
	dof.FocusDistance = CONFIG.depthOfField.focusDistance
	dof.NearIntensity = CONFIG.depthOfField.nearIntensity
	dof.FarIntensity = CONFIG.depthOfField.farIntensity
	dof.InFocusRadius = CONFIG.depthOfField.inFocusRadius
	dof.Parent = Lighting
	
	print("[VisualEffects] 📷 Depth of field created")
	return dof
end

--[[
	Creates and configures Sun Rays
	Adds volumetric light rays
]]
local function createSunRays()
	if not CONFIG.sunRays.enabled then return nil end
	
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "ACNHSunRays"
	sunRays.Intensity = CONFIG.sunRays.intensity
	sunRays.Spread = CONFIG.sunRays.spread
	sunRays.Parent = Lighting
	
	print("[VisualEffects] ☀️ Sun rays created")
	return sunRays
end

--[[
	Creates and configures Atmosphere
	Adds atmospheric scattering and haze
]]
local function createAtmosphere()
	if not CONFIG.atmosphere.enabled then return nil end
	
	-- Check if Atmosphere already exists
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	
	atmosphere.Density = CONFIG.atmosphere.density
	atmosphere.Offset = CONFIG.atmosphere.offset
	atmosphere.Color = CONFIG.atmosphere.color
	atmosphere.Decay = CONFIG.atmosphere.decay
	atmosphere.Glare = CONFIG.atmosphere.glare
	atmosphere.Haze = CONFIG.atmosphere.haze
	
	print("[VisualEffects] 🌤️ Atmosphere configured")
	return atmosphere
end

--[[
	Configures enhanced Sky settings with better shadows
]]
local function configureSky()
	if not CONFIG.sky.enabled then return end
	
	Lighting.ClockTime = 14  -- Afternoon
	Lighting.Brightness = 2.5  -- Brighter overall
	Lighting.Ambient = Color3.fromRGB(150, 150, 150)
	Lighting.OutdoorAmbient = Color3.fromRGB(127, 140, 160)
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 245, 220)
	
	-- Enhanced shadow settings
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.2  -- Soft, natural shadows
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	
	-- Technology settings - try to set, but don't error if it fails
	pcall(function()
		Lighting.Technology = Enum.Technology.ShadowMap
	end)
	
	print("[VisualEffects] 🌅 Sky configured with enhanced shadows")
end

--[[
	Creates a vignette effect using a ScreenGui
	(Subtle darkening around edges)
]]
local function createVignette(player)
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Check if vignette already exists
	if playerGui:FindFirstChild("VignetteEffect") then
		return
	end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VignetteEffect"
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Radial gradient vignette
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.Position = UDim2.new(0, 0, 0, 0)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxasset://textures/ui/VignetteOverlay.png"
	vignette.ImageTransparency = 0.7  -- Subtle effect
	vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
	vignette.ScaleType = Enum.ScaleType.Stretch
	vignette.Parent = screenGui
	
	print("[VisualEffects] 🎭 Vignette created for", player.Name)
end

--[[
	Animates time of day for dynamic lighting
	Optional: Call this to cycle through day/night
]]
function VisualEffects.animateDayNightCycle(duration)
	duration = duration or 300  -- 5 minutes default
	
	local startTime = Lighting.ClockTime
	local endTime = startTime + 24
	
	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.InOut,
		-1,  -- Repeat forever
		false,
		0
	)
	
	local tween = TweenService:Create(Lighting, tweenInfo, {
		ClockTime = endTime
	})
	
	tween:Play()
	print("[VisualEffects] 🌙 Day/night cycle started")
end

--[[
	Dynamically adjusts blur based on player speed
	Creates motion blur effect
]]
function VisualEffects.enableDynamicBlur(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local blur = Lighting:FindFirstChild("ACNHBlur")
	
	if not blur then
		warn("[VisualEffects] Blur effect not found")
		return
	end
	
	local baseBlurSize = CONFIG.blur.size
	local maxBlurSize = 20
	local maxSpeed = 50
	
	game:GetService("RunService").RenderStepped:Connect(function()
		local velocity = humanoidRootPart.AssemblyLinearVelocity.Magnitude
		local speedRatio = math.clamp(velocity / maxSpeed, 0, 1)
		local targetBlur = baseBlurSize + (speedRatio * (maxBlurSize - baseBlurSize))
		
		-- Smooth transition
		blur.Size = blur.Size + (targetBlur - blur.Size) * 0.1
	end)
	
	print("[VisualEffects] 💨 Dynamic blur enabled for", player.Name)
end

--[[
	Adjusts focus distance for depth of field based on camera target
]]
function VisualEffects.enableDynamicFocus(player)
	local camera = workspace.CurrentCamera
	local dof = Lighting:FindFirstChild("ACNHDepthOfField")
	
	if not dof then
		warn("[VisualEffects] Depth of field not found")
		return
	end
	
	game:GetService("RunService").RenderStepped:Connect(function()
		if camera.CameraType == Enum.CameraType.Scriptable then
			-- Calculate focus distance based on camera focus
			local focusDistance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
			dof.FocusDistance = focusDistance
		end
	end)
	
	print("[VisualEffects] 🎯 Dynamic focus enabled for", player.Name)
end

--[[
	Main initialization function
	Sets up all visual effects
]]
function VisualEffects.initialize(player)
	print("[VisualEffects] 🎨 Initializing visual effects...")
	
	-- Create post-processing effects
	createBloom()
	createBlur()
	createColorCorrection()
	createDepthOfField()
	createSunRays()
	createAtmosphere()
	
	-- Configure lighting
	configureSky()
	
	-- Create player-specific effects
	if player then
		task.spawn(function()
			createVignette(player)
		end)
	end
	
	print("[VisualEffects] ✅ Visual effects initialized!")
	
	return VisualEffects
end

--[[
	Changes the season and updates color grading
	@param season string - "spring", "summer", "fall", "winter"
]]
function VisualEffects.setSeason(season)
	season = season:lower()
	
	if not CONFIG.seasons[season] then
		warn("[VisualEffects] Invalid season:", season)
		return
	end
	
	CONFIG.currentSeason = season
	local seasonConfig = CONFIG.seasons[season]
	
	-- Update color correction
	local colorCorrection = Lighting:FindFirstChild("ACNHColorCorrection")
	if colorCorrection then
		colorCorrection.TintColor = seasonConfig.tint
		colorCorrection.Saturation = seasonConfig.saturation
		colorCorrection.Brightness = seasonConfig.brightness
	end
	
	-- Update sun rays
	local sunRays = Lighting:FindFirstChild("ACNHSunRays")
	if sunRays then
		sunRays.Intensity = seasonConfig.sunRaysIntensity
	end
	
	print("[VisualEffects] 🍂 Season changed to:", season)
end

--[[
	Gets the current season
	@return string - Current season name
]]
function VisualEffects.getCurrentSeason()
	return CONFIG.currentSeason
end

--[[
	Removes all visual effects
	Useful for performance testing or disabling effects
]]
function VisualEffects.disable()
	print("[VisualEffects] 🔇 Disabling visual effects...")
	
	-- Remove all effects
	for _, effect in ipairs(Lighting:GetChildren()) do
		if effect.Name:match("ACNH") then
			effect:Destroy()
		end
	end
	
	-- Remove vignettes
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			local vignette = playerGui:FindFirstChild("VignetteEffect")
			if vignette then
				vignette:Destroy()
			end
		end
	end
	
	print("[VisualEffects] ❌ Visual effects disabled")
end

--[[
	Adjusts effect intensity
	@param effectName string - Name of effect to adjust
	@param intensity number - New intensity value (0-1)
]]
function VisualEffects.setIntensity(effectName, intensity)
	local effect = Lighting:FindFirstChild("ACNH" .. effectName)
	if effect and effect:IsA("PostEffect") then
		if effect:FindFirstChild("Intensity") then
			effect.Intensity = intensity
			print("[VisualEffects] 📊 Set", effectName, "intensity to", intensity)
		end
	end
end

return VisualEffects
