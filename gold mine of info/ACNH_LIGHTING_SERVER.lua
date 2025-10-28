--[[
	🏝️ ANIMAL CROSSING: NEW HORIZONS LIGHTING SCRIPT (SERVER)
	
	HOW TO USE:
	1. In Roblox Studio, insert a Script into ServerScriptService
	2. Name it "ACNHLighting"
	3. Copy this ENTIRE script
	4. Paste into the Script
	5. Run the game!
	
	This handles all LIGHTING effects (server-side only)
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

print("🏝️ Setting up Animal Crossing lighting (server)...")

-- ============================================================================
-- LIGHTING SETUP (Warm, Dreamy, Cozy)
-- ============================================================================

-- Ambient lighting (soft, warm)
Lighting.Ambient = Color3.fromRGB(150, 170, 180)  -- Soft blue-gray
Lighting.OutdoorAmbient = Color3.fromRGB(200, 210, 220)  -- Bright warm outdoor
Lighting.Brightness = 2.5  -- Cheerful and bright
Lighting.ColorShift_Bottom = Color3.fromRGB(200, 180, 160)  -- Warm ground reflection
Lighting.ColorShift_Top = Color3.fromRGB(200, 220, 255)  -- Cool sky tint

-- Exposure (slightly overexposed for dreamy feel)
Lighting.ExposureCompensation = 0.3

-- Shadows (soft like AC:NH)
Lighting.GlobalShadows = true
Lighting.Technology = Enum.Technology.ShadowMap
Lighting.ShadowSoftness = 0.5  -- Very soft shadows

-- Environment
Lighting.EnvironmentDiffuseScale = 0.8
Lighting.EnvironmentSpecularScale = 0.6

-- Time of day (afternoon for best light)
Lighting.ClockTime = 14  -- 2 PM
Lighting.GeographicLatitude = 0  -- Tropical

print("✅ Lighting: Warm tones, soft shadows, bright")

-- ============================================================================
-- ATMOSPHERIC EFFECTS (Bloom, Color Correction, Atmosphere)
-- ============================================================================

-- Clear existing effects
for _, effect in pairs(Lighting:GetChildren()) do
	if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") then
		effect:Destroy()
	end
end

-- 1. BLOOM (Soft glow on bright objects)
local bloom = Instance.new("BloomEffect")
bloom.Name = "ACNHBloom"
bloom.Intensity = 1  -- Soft glow
bloom.Size = 24  -- Wide spread
bloom.Threshold = 0.8  -- Only bright objects
bloom.Enabled = true
bloom.Parent = Lighting

print("✅ Bloom: Soft glow enabled")

-- 2. COLOR CORRECTION (Warm, saturated tones)
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "ACNHColorCorrection"
colorCorrection.Saturation = 0.2  -- Slightly more vivid colors
colorCorrection.Contrast = 0.1  -- Soft contrast
colorCorrection.TintColor = Color3.fromRGB(255, 250, 245)  -- Warm cream tint
colorCorrection.Brightness = 0.1  -- Slightly brighter
colorCorrection.Enabled = true
colorCorrection.Parent = Lighting

print("✅ Color Correction: Warm, dreamy tones")

-- 3. SUN RAYS (God rays through trees)
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "ACNHSunRays"
sunRays.Intensity = 0.2  -- Subtle rays
sunRays.Spread = 0.1  -- Tight spread
sunRays.Enabled = true
sunRays.Parent = Lighting

print("✅ Sun Rays: Dreamy god rays")

-- 4. DEPTH OF FIELD (Cinematic blur)
local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.Name = "ACNHDepthOfField"
depthOfField.FocusDistance = 25  -- Focus on nearby objects
depthOfField.InFocusRadius = 20  -- Large in-focus area
depthOfField.NearIntensity = 0.2  -- Subtle near blur
depthOfField.FarIntensity = 0.4  -- Soft far blur
depthOfField.Enabled = true
depthOfField.Parent = Lighting

print("✅ Depth of Field: Cinematic blur")

-- 5. ATMOSPHERE (Sky gradient, horizon haze)
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "ACNHAtmosphere"
atmosphere.Density = 0.3  -- Light, airy atmosphere
atmosphere.Offset = 0.5  -- Sun higher in sky
atmosphere.Color = Color3.fromRGB(199, 220, 255)  -- Light blue sky
atmosphere.Decay = Color3.fromRGB(106, 142, 192)  -- Soft blue horizon
atmosphere.Glare = 0.5  -- Some glare for warmth
atmosphere.Haze = 1.5  -- Soft horizon haze
atmosphere.Parent = Lighting

print("✅ Atmosphere: Soft, hazy horizon")

-- 6. SKY (Clouds and celestial bodies)
local sky = Instance.new("Sky")
sky.Name = "ACNHSky"
sky.SkyboxBk = "rbxasset://sky/sky512_bk.tex"
sky.SkyboxDn = "rbxasset://sky/sky512_dn.tex"
sky.SkyboxFt = "rbxasset://sky/sky512_ft.tex"
sky.SkyboxLf = "rbxasset://sky/sky512_lf.tex"
sky.SkyboxRt = "rbxasset://sky/sky512_rt.tex"
sky.SkyboxUp = "rbxasset://sky/sky512_up.tex"
sky.SunAngularSize = 15  -- Larger, warmer sun
sky.MoonAngularSize = 11  -- Visible moon
sky.CelestialBodiesShown = true
sky.StarCount = 3000  -- Beautiful night sky
sky.Parent = Lighting

print("✅ Sky: Soft clouds, visible sun/moon")

-- ============================================================================
-- DYNAMIC LIGHTING (Changes with time of day)
-- ============================================================================

-- Function to update lighting based on time
local function updateLightingForTime(clockTime)
	local timeOfDay = "day"
	
	-- Determine period
	if clockTime >= 5 and clockTime < 7 then
		timeOfDay = "sunrise"
	elseif clockTime >= 7 and clockTime < 17 then
		timeOfDay = "day"
	elseif clockTime >= 17 and clockTime < 19 then
		timeOfDay = "sunset"
	else
		timeOfDay = "night"
	end
	
	-- Create smooth transitions
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	
	-- Define colors for each period
	local ambient, outdoor, brightness, sunRayIntensity
	
	if timeOfDay == "sunrise" or timeOfDay == "sunset" then
		-- GOLDEN HOUR (warm, orange, beautiful)
		ambient = Color3.fromRGB(255, 180, 120)
		outdoor = Color3.fromRGB(255, 160, 100)
		brightness = 2
		sunRayIntensity = 0.25
	elseif timeOfDay == "day" then
		-- DAYTIME (bright, cheerful, warm)
		ambient = Color3.fromRGB(150, 170, 180)
		outdoor = Color3.fromRGB(200, 210, 220)
		brightness = 2.5
		sunRayIntensity = 0.2
	else
		-- NIGHTTIME (cool, calm, blue)
		ambient = Color3.fromRGB(80, 90, 120)
		outdoor = Color3.fromRGB(60, 70, 100)
		brightness = 0.8
		sunRayIntensity = 0
	end
	
	-- Apply transitions
	local lightingTween = TweenService:Create(Lighting, tweenInfo, {
		Ambient = ambient,
		OutdoorAmbient = outdoor,
		Brightness = brightness,
	})
	lightingTween:Play()
	
	-- Update sun rays
	local sunRaysEffect = Lighting:FindFirstChild("ACNHSunRays")
	if sunRaysEffect then
		local sunRayTween = TweenService:Create(sunRaysEffect, tweenInfo, {
			Intensity = sunRayIntensity
		})
		sunRayTween:Play()
	end
	
	-- Update atmosphere color for sunset
	local atmosphereEffect = Lighting:FindFirstChild("ACNHAtmosphere")
	if atmosphereEffect and (timeOfDay == "sunset" or timeOfDay == "sunrise") then
		local atmosphereTween = TweenService:Create(atmosphereEffect, tweenInfo, {
			Color = Color3.fromRGB(255, 200, 150)  -- Warm sunset sky
		})
		atmosphereTween:Play()
	elseif atmosphereEffect and timeOfDay == "day" then
		local atmosphereTween = TweenService:Create(atmosphereEffect, tweenInfo, {
			Color = Color3.fromRGB(199, 220, 255)  -- Light blue day sky
		})
		atmosphereTween:Play()
	elseif atmosphereEffect and timeOfDay == "night" then
		local atmosphereTween = TweenService:Create(atmosphereEffect, tweenInfo, {
			Color = Color3.fromRGB(50, 60, 90)  -- Dark night sky
		})
		atmosphereTween:Play()
	end
end

-- Monitor clock time changes
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	updateLightingForTime(Lighting.ClockTime)
end)

-- Initial update
updateLightingForTime(Lighting.ClockTime)

print("✅ Dynamic lighting enabled (sunrise/day/sunset/night)")

-- ============================================================================
-- FINAL TOUCHES
-- ============================================================================

-- Enhance grass colors when parts are added
game.Workspace.DescendantAdded:Connect(function(part)
	if part:IsA("BasePart") then
		if part.Material == Enum.Material.Grass then
			part.Color = Color3.fromRGB(124, 180, 76)  -- AC:NH grass green
		elseif part.Material == Enum.Material.LeafyGrass then
			part.Color = Color3.fromRGB(100, 160, 60)
		end
	end
end)

-- Fix existing grass
for _, part in pairs(game.Workspace:GetDescendants()) do
	if part:IsA("BasePart") then
		if part.Material == Enum.Material.Grass then
			part.Color = Color3.fromRGB(124, 180, 76)
		elseif part.Material == Enum.Material.LeafyGrass then
			part.Color = Color3.fromRGB(100, 160, 60)
		end
	end
end

print("✅ Grass colors enhanced")

-- ============================================================================
-- SUMMARY
-- ============================================================================

print("═══════════════════════════════════════════════════════════════")
print("🎨 ANIMAL CROSSING LIGHTING APPLIED (SERVER)!")
print("═══════════════════════════════════════════════════════════════")
print("🌅 Lighting: Warm, dreamy tones with soft shadows")
print("✨ Effects: Bloom, color correction, depth of field, sun rays")
print("🌤️ Atmosphere: Soft haze, horizon gradient, beautiful sky")
print("⏰ Dynamic: Smooth transitions between day/sunset/night")
print("🎨 Colors: Enhanced saturation, warm cream tint")
print("═══════════════════════════════════════════════════════════════")
print("🏝️ Lighting system active!")
print("═══════════════════════════════════════════════════════════════")

