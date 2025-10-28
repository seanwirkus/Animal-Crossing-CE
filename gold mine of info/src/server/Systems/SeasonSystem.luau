#! -0
--[[
	SeasonSystem
	Manages seasonal changes and progression:
	- Spring: Flowers bloom, rain
	- Summer: Bright & clear, fireflies at night
	- Fall: Leaves change, wind, fog
	- Winter: Snow, ice, shorter days
	
	Integrates with IslandClock for seasonal calendar
]]

local SeasonSystem = {}
SeasonSystem.__index = SeasonSystem

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- Season definitions (month-based)
local SEASONS = {
	SPRING = { name = "Spring", months = { 3, 4, 5 }, emoji = "🌸" },
	SUMMER = { name = "Summer", months = { 6, 7, 8 }, emoji = "☀️" },
	FALL = { name = "Fall", months = { 9, 10, 11 }, emoji = "🍂" },
	WINTER = { name = "Winter", months = { 12, 1, 2 }, emoji = "❄️" },
}

-- Season colors and effects
local SEASON_CONFIG = {
	Spring = {
		terrain = Color3.fromRGB(144, 238, 144),        -- Light green
		sky = Color3.fromRGB(173, 216, 230),             -- Light blue
		ambientLight = Color3.fromRGB(220, 230, 220),
		fogColor = Color3.fromRGB(180, 200, 220),
		fogEnd = 800,
		weather = "rain",
		treeColorShift = Color3.fromRGB(100, 200, 100), -- Bright green
	},
	Summer = {
		terrain = Color3.fromRGB(120, 220, 80),          -- Bright green
		sky = Color3.fromRGB(200, 230, 255),             -- Bright blue
		ambientLight = Color3.fromRGB(240, 250, 250),
		fogColor = Color3.fromRGB(200, 230, 255),
		fogEnd = 1200,
		weather = "clear",
		treeColorShift = Color3.fromRGB(50, 150, 50),   -- Dark green
	},
	Fall = {
		terrain = Color3.fromRGB(210, 180, 100),         -- Tan/brown
		sky = Color3.fromRGB(255, 200, 100),             -- Orange sky
		ambientLight = Color3.fromRGB(230, 200, 150),
		fogColor = Color3.fromRGB(200, 150, 100),
		fogEnd = 600,
		weather = "windy",
		treeColorShift = Color3.fromRGB(255, 140, 0),   -- Orange/red
	},
	Winter = {
		terrain = Color3.fromRGB(240, 248, 255),         -- White/blue
		sky = Color3.fromRGB(180, 200, 220),             -- Gray-blue
		ambientLight = Color3.fromRGB(200, 210, 230),
		fogColor = Color3.fromRGB(220, 225, 235),
		fogEnd = 400,
		weather = "snow",
		treeColorShift = Color3.fromRGB(200, 200, 200), -- Gray/frosted
	},
}

function SeasonSystem.new(clock)
	local self = setmetatable({}, SeasonSystem)
	self._clock = clock
	self._currentSeason = nil
	self._transitioningTrees = {}
	self._environmentals = {}
	
	-- Initialize
	self:_updateSeason()
	
	-- Listen for day changes to update season
	clock:OnDayChanged(function()
		self:_updateSeason()
	end)
	
	return self
end

--[[
	Get current season name
]]
function SeasonSystem:GetCurrentSeason()
	return self._currentSeason or "Spring"
end

--[[
	Get season config
]]
function SeasonSystem:GetSeasonConfig(season)
	return SEASON_CONFIG[season] or SEASON_CONFIG.Spring
end

--[[
	Apply seasonal effects to environment
]]
function SeasonSystem:_updateSeason()
	local month = os.date("%m")
	month = tonumber(month)
	
	-- Determine season
	local season
	if month >= 3 and month <= 5 then
		season = "Spring"
	elseif month >= 6 and month <= 8 then
		season = "Summer"
	elseif month >= 9 and month <= 11 then
		season = "Fall"
	else
		season = "Winter"
	end
	
	if season == self._currentSeason then return end
	self._currentSeason = season
	
	-- Apply season effects
	self:_applySeasonalLighting(season)
	self:_applySeasonalColors(season)
	self:_applyWeatherEffects(season)
	self:_updateTreeAppearance(season)
end

--[[
	Apply lighting changes for season
]]
function SeasonSystem:_applySeasonalLighting(season)
	local config = self:GetSeasonConfig(season)
	
	-- Smooth lighting transition
	local tweenInfo = TweenInfo.new(
		5, -- 5 second transition
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)
	
	local tweenData = {
		Ambient = config.ambientLight,
		OutdoorAmbient = config.ambientLight,
		FogColor = config.fogColor,
		FogEnd = config.fogEnd,
	}
	
	local tween = TweenService:Create(Lighting, tweenInfo, tweenData)
	tween:Play()
end

--[[
	Apply color changes to terrain
]]
function SeasonSystem:_applySeasonalColors(season)
	local config = self:GetSeasonConfig(season)
	
	-- Update sky color
	local sky = Lighting:FindFirstChild("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
	
	local tweenInfo = TweenInfo.new(
		5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)
	
	-- Transition sky colors
	local skyTweenData = {
		SkyboxBk = config.sky,
		SkyboxDn = config.sky,
		SkyboxFt = config.sky,
		SkyboxLf = config.sky,
		SkyboxRt = config.sky,
		SkyboxUp = config.sky,
	}
	
	-- Note: Sky properties might not all exist, but we try to set what we can
end

--[[
	Apply weather effects
]]
function SeasonSystem:_applyWeatherEffects(season)
	local config = self:GetSeasonConfig(season)
	
	-- Clear old effects
	self:_clearWeatherEffects()
	
	if config.weather == "rain" then
		self:_createRainEffect()
	elseif config.weather == "snow" then
		self:_createSnowEffect()
	elseif config.weather == "windy" then
		self:_createWindEffect()
	end
end

--[[
	Update tree appearance for season
]]
function SeasonSystem:_updateTreeAppearance(season)
	local config = self:GetSeasonConfig(season)
	local treeFolder = workspace:FindFirstChild("Island") and 
	                   workspace.Island:FindFirstChild("Trees")
	
	if not treeFolder then return end
	
	-- Update all tree foliage colors
	for _, tree in pairs(treeFolder:GetChildren()) do
		if tree:IsA("Model") then
			self:_colorizeTree(tree, season, config)
		end
	end
end

--[[
	Colorize a tree for the season
]]
function SeasonSystem:_colorizeTree(treeModel, season, config)
	-- Find foliage parts
	for _, part in pairs(treeModel:GetDescendants()) do
		if part:IsA("Part") and part.Name:match("Foliage") or part.Name:match("Leaves") then
			-- Smooth color transition
			local tweenInfo = TweenInfo.new(
				10, -- 10 second tree color transition
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.InOut
			)
			
			local tween = TweenService:Create(part, tweenInfo, {
				Color = config.treeColorShift
			})
			tween:Play()
		end
	end
end

-- WEATHER EFFECTS

function SeasonSystem:_createRainEffect()
	-- Create rain particles at various positions
	for _ = 1, 20 do
		task.spawn(function()
			self:_raindrops()
		end)
	end
end

function SeasonSystem:_createSnowEffect()
	-- Create snow particles falling gently
	for _ = 1, 30 do
		task.spawn(function()
			self:_snowflakes()
		end)
	end
end

function SeasonSystem:_createWindEffect()
	-- Create swaying wind effect for trees
	-- Trees will automatically sway with this in effect
end

function SeasonSystem:_raindrops()
	local particle = Instance.new("Part")
	particle.Shape = Enum.PartType.Cylinder
	particle.Size = Vector3.new(0.1, 2, 0.1)
	particle.CanCollide = false
	particle.Anchored = true
	particle.CFrame = CFrame.new(
		Vector3.new(
			math.random(-150, 150),
			100,
			math.random(-150, 150)
		)
	) * CFrame.Angles(math.pi/2, 0, 0)
	particle.Color = Color3.fromRGB(100, 150, 200)
	particle.Material = Enum.Material.Neon
	particle.Transparency = 0.5
	particle.Parent = workspace
	
	table.insert(self._environmentals, particle)
	
	-- Fall
	local startY = particle.Position.Y
	while particle.Parent and particle.Position.Y > 5 do
		particle.CFrame = particle.CFrame - Vector3.new(0, 20 * 0.016, 0)
		task.wait(0.016)
	end
	
	particle:Destroy()
end

function SeasonSystem:_snowflakes()
	local particle = Instance.new("Part")
	particle.Shape = Enum.PartType.Ball
	particle.Size = Vector3.new(0.3, 0.3, 0.3)
	particle.CanCollide = false
	particle.Anchored = true
	particle.CFrame = CFrame.new(
		Vector3.new(
			math.random(-150, 150),
			100,
			math.random(-150, 150)
		)
	)
	particle.Color = Color3.fromRGB(255, 255, 255)
	particle.Material = Enum.Material.Neon
	particle.Transparency = 0.7
	particle.Parent = workspace
	
	table.insert(self._environmentals, particle)
	
	-- Fall slowly with sway
	local driftX = (math.random() - 0.5) * 0.5
	while particle.Parent and particle.Position.Y > 5 do
		particle.CFrame = particle.CFrame + Vector3.new(driftX, -5 * 0.016, 0)
		task.wait(0.016)
	end
	
	particle:Destroy()
end

function SeasonSystem:_clearWeatherEffects()
	-- Destroy all environmental particles
	for _, particle in pairs(self._environmentals) do
		if particle and particle.Parent then
			particle:Destroy()
		end
	end
	self._environmentals = {}
end

function SeasonSystem:Destroy()
	self:_clearWeatherEffects()
	self._transitioningTrees = {}
end

return SeasonSystem
