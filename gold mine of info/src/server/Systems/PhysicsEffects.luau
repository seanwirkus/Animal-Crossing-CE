#! -0
--[[
	PhysicsEffects
	Handles physics-based interactions and visual effects:
	- Rock breaking animations and particles
	- Tree shaking with fruit/resources falling
	- Water splashes when fishing
	- Tool hit effects with debris
	- Smooth animations and effects
]]

local PhysicsEffects = {}
PhysicsEffects.__index = PhysicsEffects

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Configuration
local CONFIG = {
	SHAKE_DURATION = 0.6,
	SHAKE_INTENSITY = 2,
	ROCK_BREAK_DURATION = 0.8,
	PARTICLE_COUNT = 12,
	PARTICLE_SPEED = 25,
	WATER_SPLASH_DURATION = 0.5,
}

function PhysicsEffects.new()
	local self = setmetatable({}, PhysicsEffects)
	self._activeEffects = {}
	return self
end

--[[
	Tree Shaking Effect
	Makes tree shake and drops fruit particles
]]
function PhysicsEffects:ShakeTree(treeModel, fruitCount)
	if not treeModel then return end
	
	local rootPart = treeModel:GetPrimaryPart() or treeModel:FindFirstChild("Trunk")
	if not rootPart then return end

	-- Check if already shaking
	if self._activeEffects[treeModel] then return end
	self._activeEffects[treeModel] = true

	-- Create shake animation
	local originalCFrame = rootPart.CFrame
	local shakeOffsets = {
		Vector3.new(0.5, 0, 0),
		Vector3.new(-0.5, 0, 0),
		Vector3.new(0, 0, 0.5),
		Vector3.new(0, 0, -0.5),
	}

	-- Animate shaking
	for i = 1, 8 do
		rootPart.CFrame = originalCFrame * CFrame.new(shakeOffsets[((i - 1) % 4) + 1])
		task.wait(CONFIG.SHAKE_DURATION / 8)
	end

	-- Return to original position
	rootPart.CFrame = originalCFrame

	-- Spawn fruit particles
	self:_createFruitParticles(treeModel, fruitCount)

	-- Clean up effect marker
	task.wait(0.2)
	self._activeEffects[treeModel] = nil
end

--[[
	Rock Breaking Effect
	Makes rock shake and break apart with particles
]]
function PhysicsEffects:BreakRock(rockModel, ores)
	if not rockModel then return end

	local rootPart = rockModel:GetPrimaryPart() or rockModel:FindFirstChild("Body")
	if not rootPart then return end

	-- Rock break animation - crack and crumble
	local originalSize = rootPart.Size
	local breakTween = TweenService:Create(
		rootPart,
		TweenInfo.new(CONFIG.ROCK_BREAK_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = originalSize * Vector3.new(0.8, 0.6, 0.8),
			Transparency = 0.3,
		}
	)
	breakTween:Play()

	-- Particle effects
	self:_createOreParticles(rockModel, ores or 3)

	-- Fade and destroy
	task.wait(CONFIG.ROCK_BREAK_DURATION)

	local fadeTween = TweenService:Create(
		rootPart,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Transparency = 1,
		}
	)
	fadeTween:Play()

	task.wait(0.3)
	rootPart.CanCollide = false
end

--[[
	Water Splash Effect
	Creates splash particles when fishing
]]
function PhysicsEffects:CreateWaterSplash(position)
	local splashParent = Instance.new("Attachment")
	splashParent.Parent = workspace
	splashParent.WorldPosition = position

	-- Create splash particles
	for i = 1, 8 do
		local particle = Instance.new("Part")
		particle.Shape = Enum.PartType.Ball
		particle.Size = Vector3.new(0.3, 0.3, 0.3)
		particle.CanCollide = false
		particle.CFrame = CFrame.new(position) * CFrame.new(
			(math.random() - 0.5) * 4,
			math.random() * 2,
			(math.random() - 0.5) * 4
		)
		particle.Color = Color3.fromRGB(135, 206, 235)
		particle.Material = Enum.Material.Neon
		particle.Parent = workspace

		-- Gravity effect
		local velocity = Vector3.new(
			(math.random() - 0.5) * CONFIG.PARTICLE_SPEED,
			math.random() * CONFIG.PARTICLE_SPEED,
			(math.random() - 0.5) * CONFIG.PARTICLE_SPEED
		)

		task.spawn(function()
			for _ = 1, 10 do
				particle.Position = particle.Position + velocity * 0.016
				velocity = velocity + Vector3.new(0, -0.5, 0) * 0.016
				task.wait(0.016)
			end
			particle:Destroy()
		end)
	end

	Debris:AddItem(splashParent, 1)
end

--[[
	Tool Hit Effect
	Creates debris and dust when tool hits something
]]
function PhysicsEffects:CreateToolHitEffect(hitPosition, toolType)
	local particleColor = self:_getToolColor(toolType)

	-- Create dust particles
	for i = 1, CONFIG.PARTICLE_COUNT do
		local particle = Instance.new("Part")
		particle.Shape = Enum.PartType.Ball
		particle.Size = Vector3.new(0.2, 0.2, 0.2)
		particle.CanCollide = false
		particle.CFrame = CFrame.new(hitPosition + Vector3.new(
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2
		))
		particle.Color = particleColor
		particle.Material = Enum.Material.Sand
		particle.Transparency = 0.3
		particle.Parent = workspace

		-- Velocity spreading
		local angle = (i / CONFIG.PARTICLE_COUNT) * math.pi * 2
		local speed = math.random(10, 20)
		local velocity = Vector3.new(
			math.cos(angle) * speed,
			math.random(5, 15),
			math.sin(angle) * speed
		)

		task.spawn(function()
			for step = 1, 20 do
				particle.Position = particle.Position + velocity * 0.016
				particle.Transparency = 0.3 + (step / 20) * 0.7
				velocity = velocity * 0.98 -- Slow down
				task.wait(0.016)
			end
			particle:Destroy()
		end)
	end
end

--[[
	Smooth Movement Animation
	Animate objects smoothly to new positions
]]
function PhysicsEffects:AnimateMovement(model, targetCFrame, duration)
	local rootPart = model:GetPrimaryPart()
	if not rootPart then return end

	local tween = TweenService:Create(
		rootPart,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ CFrame = targetCFrame }
	)
	tween:Play()

	return tween.Completed:Wait()
end

-- PRIVATE HELPERS

function PhysicsEffects:_createFruitParticles(treeModel, count)
	local treePos = treeModel:GetPrimaryPart().Position
	local colors = {
		Color3.fromRGB(255, 0, 0),    -- Red
		Color3.fromRGB(0, 128, 0),    -- Green
		Color3.fromRGB(255, 165, 0),  -- Orange
	}

	for i = 1, (count or 3) do
		local fruit = Instance.new("Part")
		fruit.Shape = Enum.PartType.Ball
		fruit.Size = Vector3.new(0.4, 0.4, 0.4)
		fruit.CanCollide = true
		fruit.CFrame = CFrame.new(treePos + Vector3.new(
			(math.random() - 0.5) * 4,
			5,
			(math.random() - 0.5) * 4
		))
		fruit.Color = colors[math.random(1, #colors)]
		fruit.Material = Enum.Material.SmoothPlastic
		fruit.Parent = workspace

		-- Velocity
		local velocity = Vector3.new(
			(math.random() - 0.5) * 10,
			math.random(5, 15),
			(math.random() - 0.5) * 10
		)

		task.spawn(function()
			for _ = 1, 300 do -- 5 seconds
				fruit.Position = fruit.Position + velocity * 0.016
				velocity = velocity + Vector3.new(0, -9.8 * 0.016, 0)
				task.wait(0.016)
				if fruit.Parent == nil then break end
			end
		end)

		Debris:AddItem(fruit, 10)
	end
end

function PhysicsEffects:_createOreParticles(rockModel, count)
	local rockPos = rockModel:GetPrimaryPart().Position
	local oreColors = {
		Color3.fromRGB(128, 128, 128),  -- Iron
		Color3.fromRGB(184, 134, 11),   -- Gold
		Color3.fromRGB(169, 169, 169),  -- Stone
	}

	for i = 1, count do
		local ore = Instance.new("Part")
		ore.Shape = Enum.PartType.Cube
		ore.Size = Vector3.new(0.3, 0.3, 0.3)
		ore.CanCollide = false
		ore.CFrame = CFrame.new(rockPos + Vector3.new(
			(math.random() - 0.5) * 3,
			2,
			(math.random() - 0.5) * 3
		))
		ore.Color = oreColors[math.random(1, #oreColors)]
		ore.Material = Enum.Material.Rock
		ore.Parent = workspace

		local velocity = Vector3.new(
			(math.random() - 0.5) * 15,
			math.random(10, 20),
			(math.random() - 0.5) * 15
		)

		task.spawn(function()
			for _ = 1, 200 do
				ore.Position = ore.Position + velocity * 0.016
				velocity = velocity + Vector3.new(0, -9.8 * 0.016, 0)
				task.wait(0.016)
				if ore.Parent == nil then break end
			end
		end)

		Debris:AddItem(ore, 8)
	end
end

function PhysicsEffects:_getToolColor(toolType)
	local colorMap = {
		axe = Color3.fromRGB(139, 69, 19),     -- Brown
		shovel = Color3.fromRGB(184, 134, 11), -- Gold
		rod = Color3.fromRGB(100, 149, 237),   -- Blue
		net = Color3.fromRGB(144, 238, 144),   -- Light green
	}

	return colorMap[toolType] or Color3.fromRGB(200, 200, 200)
end

function PhysicsEffects:Destroy()
	self._activeEffects = {}
end

return PhysicsEffects
