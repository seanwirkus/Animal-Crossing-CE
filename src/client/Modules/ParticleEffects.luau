--[[
	ParticleEffects.luau
	
	Creates beautiful ambient particle effects for Animal Crossing CE:
	- Floating sakura petals
	- Fireflies at night
	- Dust motes in sunlight
	- Sparkles near water
	- Seasonal effects (snow, leaves, etc.)
	
	Usage:
		local ParticleEffects = require(script.Parent.ParticleEffects)
		ParticleEffects.initialize()
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local ParticleEffects = {}

-- Configuration
local CONFIG = {
	-- Sakura petals (cherry blossoms)
	sakura = {
		enabled = true,
		color = ColorSequence.new(Color3.fromRGB(255, 200, 220)),
		rate = 5,
		lifetime = NumberRange.new(8, 12),
		speed = NumberRange.new(2, 4),
		rotation = NumberRange.new(-180, 180),
		rotationSpeed = NumberRange.new(-40, 40)
	},
	
	-- Fireflies (nighttime ambiance)
	fireflies = {
		enabled = true,
		color = ColorSequence.new(Color3.fromRGB(255, 255, 150)),
		rate = 3,
		lifetime = NumberRange.new(3, 5),
		speed = NumberRange.new(1, 2),
		brightness = 2
	},
	
	-- Dust motes (sunbeams)
	dust = {
		enabled = true,
		color = ColorSequence.new(Color3.fromRGB(255, 250, 230)),
		rate = 8,
		lifetime = NumberRange.new(5, 8),
		speed = NumberRange.new(0.5, 1)
	},
	
	-- Sparkles near water
	waterSparkles = {
		enabled = true,
		color = ColorSequence.new(Color3.fromRGB(150, 220, 255)),
		rate = 10,
		lifetime = NumberRange.new(1, 2),
		speed = NumberRange.new(0, 1)
	}
}

--[[
	Creates sakura petal particle emitter
	Floating pink petals for spring atmosphere
]]
local function createSakuraPetals()
	if not CONFIG.sakura.enabled then return nil end
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SakuraPetals"
	
	-- Visual properties
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"  -- Soft particle texture
	emitter.Color = CONFIG.sakura.color
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	
	-- Emission properties
	emitter.Rate = CONFIG.sakura.rate
	emitter.Lifetime = CONFIG.sakura.lifetime
	emitter.Speed = CONFIG.sakura.speed
	emitter.SpreadAngle = Vector2.new(30, 30)
	
	-- Movement properties
	emitter.Rotation = CONFIG.sakura.rotation
	emitter.RotSpeed = CONFIG.sakura.rotationSpeed
	emitter.Acceleration = Vector3.new(0, -2, 0)  -- Gentle fall
	emitter.Drag = 1  -- Float in air
	
	-- Behavior
	emitter.VelocityInheritance = 0
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Enabled = true
	
	return emitter
end

--[[
	Creates firefly particle emitter
	Glowing bugs for nighttime atmosphere
]]
local function createFireflies()
	if not CONFIG.fireflies.enabled then return nil end
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Fireflies"
	
	-- Visual properties
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = CONFIG.fireflies.color
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Size = NumberSequence.new(0.2, 0.3)
	emitter.Brightness = CONFIG.fireflies.brightness
	emitter.LightEmission = 1  -- Glowing effect
	emitter.LightInfluence = 0
	
	-- Emission properties
	emitter.Rate = CONFIG.fireflies.rate
	emitter.Lifetime = CONFIG.fireflies.lifetime
	emitter.Speed = CONFIG.fireflies.speed
	emitter.SpreadAngle = Vector2.new(180, 180)
	
	-- Movement properties
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Acceleration = Vector3.new(0, 0.5, 0)  -- Slight upward drift
	emitter.Drag = 2
	
	-- Behavior
	emitter.VelocityInheritance = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Enabled = false  -- Only enabled at night
	
	return emitter
end

--[[
	Creates dust mote particle emitter
	Small particles visible in sunbeams
]]
local function createDustMotes()
	if not CONFIG.dust.enabled then return nil end
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "DustMotes"
	
	-- Visual properties
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = CONFIG.dust.color
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Size = NumberSequence.new(0.1, 0.15)
	emitter.LightInfluence = 1  -- Affected by sunlight
	
	-- Emission properties
	emitter.Rate = CONFIG.dust.rate
	emitter.Lifetime = CONFIG.dust.lifetime
	emitter.Speed = CONFIG.dust.speed
	emitter.SpreadAngle = Vector2.new(30, 30)
	
	-- Movement properties
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-20, 20)
	emitter.Acceleration = Vector3.new(0, 0.1, 0)
	emitter.Drag = 3
	
	-- Behavior
	emitter.VelocityInheritance = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Enabled = true
	
	return emitter
end

--[[
	Creates water sparkle particle emitter
	Glittering effect near water surfaces
]]
local function createWaterSparkles()
	if not CONFIG.waterSparkles.enabled then return nil end
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "WaterSparkles"
	
	-- Visual properties
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = CONFIG.waterSparkles.color
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Brightness = 1.5
	emitter.LightEmission = 0.8
	emitter.LightInfluence = 0.2
	
	-- Emission properties
	emitter.Rate = CONFIG.waterSparkles.rate
	emitter.Lifetime = CONFIG.waterSparkles.lifetime
	emitter.Speed = CONFIG.waterSparkles.speed
	emitter.SpreadAngle = Vector2.new(180, 0)
	
	-- Movement properties
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-100, 100)
	emitter.Acceleration = Vector3.new(0, 1, 0)
	emitter.Drag = 1
	
	-- Behavior
	emitter.VelocityInheritance = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Enabled = true
	
	return emitter
end

--[[
	Creates an attachment point for particles in the world
	@param position Vector3 - World position for particles
	@param name string - Name for the attachment
]]
local function createParticleAttachment(position, name)
	local part = Instance.new("Part")
	part.Name = name .. "Source"
	part.Size = Vector3.new(50, 20, 50)  -- Large area for particle spread
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = Workspace
	
	return part
end

--[[
	Enables/disables fireflies based on time of day
]]
local function updateFirefliesForTime()
	local hour = Lighting.ClockTime
	local isNight = hour >= 18 or hour <= 6
	
	-- Find all firefly emitters
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ParticleEmitter") and obj.Name == "Fireflies" then
			obj.Enabled = isNight
		end
	end
end

--[[
	Main initialization function
	Creates ambient particle effects in the world
]]
function ParticleEffects.initialize()
	print("[ParticleEffects] 🌸 Initializing particle effects...")
	
	-- Create central particle source (adjust position as needed)
	local centerPos = Vector3.new(0, 50, 0)  -- High in the sky
	local particleSource = createParticleAttachment(centerPos, "AmbientParticles")
	
	-- Add sakura petals
	local sakura = createSakuraPetals()
	if sakura then
		sakura.Parent = particleSource
		print("[ParticleEffects] 🌸 Sakura petals created")
	end
	
	-- Add fireflies
	local fireflies = createFireflies()
	if fireflies then
		fireflies.Parent = particleSource
		print("[ParticleEffects] ✨ Fireflies created")
	end
	
	-- Add dust motes
	local dust = createDustMotes()
	if dust then
		dust.Parent = particleSource
		print("[ParticleEffects] 💨 Dust motes created")
	end
	
	-- Update fireflies based on time of day
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateFirefliesForTime)
	updateFirefliesForTime()
	
	-- Add water sparkles to any water parts
	task.spawn(function()
		task.wait(2)  -- Wait for terrain to load
		
		for _, part in ipairs(Workspace:GetDescendants()) do
			if part:IsA("Part") and part.Material == Enum.Material.Water then
				local sparkles = createWaterSparkles()
				if sparkles then
					sparkles.Parent = part
					print("[ParticleEffects] 💧 Water sparkles added to", part.Name)
				end
			end
		end
	end)
	
	print("[ParticleEffects] ✅ Particle effects initialized!")
	
	return ParticleEffects
end

--[[
	Removes all particle effects
]]
function ParticleEffects.disable()
	print("[ParticleEffects] 🔇 Disabling particle effects...")
	
	-- Remove particle sources
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj.Name:match("ParticleSource") or 
		   (obj:IsA("ParticleEmitter") and (
		       obj.Name == "SakuraPetals" or 
		       obj.Name == "Fireflies" or 
		       obj.Name == "DustMotes" or 
		       obj.Name == "WaterSparkles"
		   )) then
			obj:Destroy()
		end
	end
	
	print("[ParticleEffects] ❌ Particle effects disabled")
end

--[[
	Updates particle quality settings
	@param settings table - Graphics quality settings from SettingsController
]]
function ParticleEffects.updateQuality(settings)
	if not settings then return end
	
	local grassQuality = settings.grassQuality or 1.0
	local particleDensity = settings.particleDensity or 1.0
	
	-- Update particle rates based on quality
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ParticleEmitter") then
			if obj.Name == "SakuraPetals" or obj.Name == "Fireflies" or obj.Name == "DustMotes" then
				-- Scale rate by grass quality and particle density
				local baseRate = CONFIG[obj.Name:lower()] and CONFIG[obj.Name:lower()].rate or 5
				obj.Rate = baseRate * grassQuality * particleDensity
				obj.Enabled = (grassQuality > 0 and particleDensity > 0)
			elseif obj.Name == "WaterSparkles" then
				-- Water particles use water quality
				local waterQuality = settings.waterQuality or 1.0
				local baseRate = CONFIG.waterSparkles and CONFIG.waterSparkles.rate or 10
				obj.Rate = baseRate * waterQuality * particleDensity
				obj.Enabled = (waterQuality > 0 and particleDensity > 0)
			end
		end
	end
	
	print("[ParticleEffects] ✅ Particle quality updated")
end

--[[
	Enables seasonal particle effects
	@param season string - "spring", "summer", "fall", "winter"
]]
function ParticleEffects.setSeason(season)
	season = season:lower()
	
	if season == "spring" then
		CONFIG.sakura.enabled = true
		CONFIG.sakura.color = ColorSequence.new(Color3.fromRGB(255, 200, 220))  -- Pink petals
		CONFIG.sakura.speed = NumberRange.new(2, 4)
		print("[ParticleEffects] 🌸 Spring mode enabled (sakura)")
	elseif season == "summer" then
		CONFIG.sakura.enabled = false  -- No falling particles in summer
		CONFIG.fireflies.rate = 8  -- More fireflies in summer
		CONFIG.dust.rate = 12  -- More dust motes in bright summer
		print("[ParticleEffects] ☀️ Summer mode enabled (fireflies)")
	elseif season == "fall" then
		CONFIG.sakura.enabled = true
		CONFIG.sakura.color = ColorSequence.new(Color3.fromRGB(255, 150, 80))  -- Orange leaves
		CONFIG.sakura.speed = NumberRange.new(3, 5)  -- Faster fall
		CONFIG.sakura.rate = 8  -- More leaves
		print("[ParticleEffects] 🍂 Fall mode enabled (leaves)")
	elseif season == "winter" then
		CONFIG.sakura.enabled = true
		CONFIG.sakura.color = ColorSequence.new(Color3.fromRGB(255, 255, 255))  -- Snowflakes
		CONFIG.sakura.speed = NumberRange.new(1, 2)  -- Slower fall
		CONFIG.sakura.rate = 12  -- More snow
		CONFIG.dust.rate = 5  -- Less dust in winter
		print("[ParticleEffects] ❄️ Winter mode enabled (snow)")
	end
	
	-- Reinitialize to apply changes
	ParticleEffects.disable()
	task.wait(0.1)
	ParticleEffects.initialize()
end

return ParticleEffects
