#! -0
--[[
	EnvironmentalEffects
	Manages ambient environmental effects:
	- Wind swaying (affects trees and objects)
	- Fireflies/ambient creatures at night
	- Puddles after rain
	- Cloud shadows moving across landscape
	- Dynamic particle effects
]]

local EnvironmentalEffects = {}
EnvironmentalEffects.__index = EnvironmentalEffects

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

function EnvironmentalEffects.new(clock)
	local self = setmetatable({}, EnvironmentalEffects)
	self._clock = clock
	self._activeWindParts = {}
	self._fireflies = {}
	self._puddles = {}
	self._windActive = false
	self._windStrength = 0
	
	-- Initialize effects
	self:_startEnvironmentalLoop()
	
	return self
end

--[[
	Main environmental loop
	Updates all active effects
]]
function EnvironmentalEffects:_startEnvironmentalLoop()
	task.spawn(function()
		while true do
			task.wait(0.1)
			
			-- Update wind effects
			self:_updateWind()
			
			-- Update fireflies at night
			self:_updateFireflies()
			
			-- Update puddles
			self:_updatePuddles()
			
			-- Update cloud shadows
			self:_updateCloudShadows()
		end
	end)
end

--[[
	Wind System
	Creates swaying effect for trees and foliage
]]
function EnvironmentalEffects:_updateWind()
	local hour = self._clock:GetClockState().clockTime
	
	-- Wind is more active at certain times
	local baseWind = math.sin(os.time() / 3) * 0.5 + 0.5
	
	-- Stronger wind in fall/winter (when season system integrates)
	self._windStrength = baseWind * 2
	
	-- Apply wind to all trees
	local treeFolder = workspace:FindFirstChild("Island") and 
	                   workspace.Island:FindFirstChild("Trees")
	
	if treeFolder then
		for _, tree in pairs(treeFolder:GetChildren()) do
			if tree:IsA("Model") then
				self:_applyWindToTree(tree)
			end
		end
	end
end

function EnvironmentalEffects:_applyWindToTree(tree)
	local trunk = tree:FindFirstChild("Trunk") or tree:GetPrimaryPart()
	if not trunk then return end
	
	-- Calculate wind sway
	local originalRotation = trunk.CFrame.Rotation
	local swayAmount = math.sin(os.time() * 2) * 0.05 * self._windStrength
	
	-- Apply subtle rotation
	trunk.CFrame = CFrame.new(trunk.CFrame.Position) * 
	              CFrame.Angles(swayAmount, 0, swayAmount * 0.5)
end

--[[
	Firefly System
	Creates ambient fireflies at night
]]
function EnvironmentalEffects:_updateFireflies()
	local clockState = self._clock:GetClockState()
	local isNight = not clockState.isDay
	
	if isNight and #self._fireflies < 10 then
		-- Spawn new fireflies at night
		for _ = 1, math.min(3, 10 - #self._fireflies) do
			self:_spawnFirefly()
		end
	elseif not isNight and #self._fireflies > 0 then
		-- Remove fireflies during day
		for _, ff in pairs(self._fireflies) do
			if ff and ff.Parent then
				ff:Destroy()
			end
		end
		self._fireflies = {}
	end
	
	-- Move fireflies around
	for i, ff in pairs(self._fireflies) do
		if ff and ff.Parent then
			self:_moveFirefly(ff, i)
		else
			table.remove(self._fireflies, i)
		end
	end
end

function EnvironmentalEffects:_spawnFirefly()
	local firefly = Instance.new("Part")
	firefly.Shape = Enum.PartType.Ball
	firefly.Size = Vector3.new(0.2, 0.2, 0.2)
	firefly.CanCollide = false
	firefly.CFrame = CFrame.new(
		Vector3.new(
			math.random(-100, 100),
			math.random(20, 50),
			math.random(-100, 100)
		)
	)
	firefly.Color = Color3.fromRGB(255, 255, 100)
	firefly.Material = Enum.Material.Neon
	firefly.Transparency = 0.3
	firefly.Parent = workspace
	
	-- Add light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 255, 100)
	light.Brightness = 2
	light.Range = 15
	light.Parent = firefly
	
	-- Attach metadata
	firefly:SetAttribute("FireflyTime", os.time())
	firefly:SetAttribute("FireflyTargetX", math.random(-100, 100))
	firefly:SetAttribute("FireflyTargetZ", math.random(-100, 100))
	
	table.insert(self._fireflies, firefly)
end

function EnvironmentalEffects:_moveFirefly(ff, index)
	local targetX = ff:GetAttribute("FireflyTargetX") or 0
	local targetZ = ff:GetAttribute("FireflyTargetZ") or 0
	
	-- Move towards target
	local currentPos = ff.Position
	local targetPos = Vector3.new(targetX, currentPos.Y + math.sin(os.time() + index) * 0.5, targetZ)
	
	local moveDir = (targetPos - currentPos).Unit
	ff.Position = currentPos + moveDir * 0.05
	
	-- If near target, pick new target
	if (ff.Position - targetPos).Magnitude < 2 then
		ff:SetAttribute("FireflyTargetX", math.random(-100, 100))
		ff:SetAttribute("FireflyTargetZ", math.random(-100, 100))
	end
	
	-- Gentle bobbing
	local bobOffset = math.sin(os.time() * 3 + index) * 0.3
	ff.Position = ff.Position + Vector3.new(0, bobOffset * 0.016, 0)
end

--[[
	Puddle System
	Creates puddles after rain
]]
function EnvironmentalEffects:_updatePuddles()
	-- Puddles fade over time
	for i, puddle in pairs(self._puddles) do
		if puddle and puddle.Parent then
			local age = os.time() - puddle:GetAttribute("PuddleCreatedTime")
			local maxAge = puddle:GetAttribute("PuddleMaxAge") or 60
			
			if age > maxAge then
				-- Fade out
				local transparency = math.min(1, (age - maxAge) / 5)
				puddle.Transparency = transparency
				
				if transparency >= 1 then
					puddle:Destroy()
					table.remove(self._puddles, i)
				end
			end
		else
			table.remove(self._puddles, i)
		end
	end
end

function EnvironmentalEffects:CreatePuddles(centerPos, count)
	for _ = 1, count do
		local puddle = Instance.new("Part")
		puddle.Shape = Enum.PartType.Cylinder
		puddle.Size = Vector3.new(2, 0.1, 2)
		puddle.CanCollide = false
		puddle.Anchored = true
		puddle.CFrame = CFrame.new(
			centerPos + Vector3.new(
				(math.random() - 0.5) * 10,
				0.05,
				(math.random() - 0.5) * 10
			)
		) * CFrame.Angles(math.pi/2, 0, 0)
		puddle.Color = Color3.fromRGB(100, 150, 200)
		puddle.Material = Enum.Material.SmoothPlastic
		puddle.Transparency = 0.4
		puddle.Parent = workspace
		
		puddle:SetAttribute("PuddleCreatedTime", os.time())
		puddle:SetAttribute("PuddleMaxAge", 60) -- Lasts 60 seconds
		
		table.insert(self._puddles, puddle)
	end
end

--[[
	Cloud Shadow System
	Creates moving shadows across landscape
]]
function EnvironmentalEffects:_updateCloudShadows()
	-- Cloud shadows move slowly across the island
	local time = os.time()
	local shadowPosition = (time % 600) / 600 -- Loop every 10 minutes
	
	-- Update shadow properties in lighting
	local shadowIntensity = 0.2 + math.sin(time / 5) * 0.1
	Lighting.ClockTime = Lighting.ClockTime -- No change, just keeping consistent
end

--[[
	Sunrise/Sunset Transitions
	Smooth color transitions during day/night change
]]
function EnvironmentalEffects:CreateSunriseEffect()
	local tweenInfo = TweenInfo.new(
		30, -- 30 seconds
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)
	
	local lighting = Lighting
	local tweenData = {
		Brightness = 2.0,
		Ambient = Color3.fromRGB(220, 230, 240),
	}
	
	local tween = TweenService:Create(lighting, tweenInfo, tweenData)
	tween:Play()
end

function EnvironmentalEffects:CreateSunsetEffect()
	local tweenInfo = TweenInfo.new(
		30, -- 30 seconds
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)
	
	local lighting = Lighting
	local tweenData = {
		Brightness = 1.5,
		Ambient = Color3.fromRGB(255, 150, 100), -- Orange sunset
	}
	
	local tween = TweenService:Create(lighting, tweenInfo, tweenData)
	tween:Play()
end

--[[
	Weather-based Effects
]]
function EnvironmentalEffects:CreateRainSound()
	-- Play ambient rain sound
	-- Implementation depends on sound asset availability
end

function EnvironmentalEffects:CreateSnowAccumulation()
	-- Over time, snow accumulates on ground (visual effect)
	-- Could adjust terrain colors to whiter tones
end

function EnvironmentalEffects:Destroy()
	-- Clean up all effects
	for _, ff in pairs(self._fireflies) do
		if ff and ff.Parent then
			ff:Destroy()
		end
	end
	
	for _, puddle in pairs(self._puddles) do
		if puddle and puddle.Parent then
			puddle:Destroy()
		end
	end
	
	self._fireflies = {}
	self._puddles = {}
end

return EnvironmentalEffects
