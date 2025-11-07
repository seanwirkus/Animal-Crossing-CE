--[[
	WaterEffects.luau
	Makes water look nice with visual effects
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local WaterEffects = {}
WaterEffects.__index = WaterEffects

function WaterEffects.new()
	local self = setmetatable({}, WaterEffects)
	
	self._connection = nil
	self._effects = {}
	
	print("[WaterEffects] ✅ Created")
	return self
end

function WaterEffects:Start()
	if self._connection then
		return
	end
	
	-- Completely disable water effects - they interfere with Studio rendering
	print("[WaterEffects] ⚠️ Water effects DISABLED (was causing material rendering issues)")
	return
	
	--[[ DISABLED - Uncomment to re-enable water effects
	print("[WaterEffects] 🌊 Starting water visual effects")
	
	-- Find all water parts
	local function setupWaterEffects()
		-- Only look in specific water-related folders to avoid scanning everything
		local waterFolder = Workspace:FindFirstChild("Water")
		if waterFolder then
			for _, descendant in pairs(waterFolder:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant.Material == Enum.Material.Water then
					-- Skip if already processed
					if not descendant:GetAttribute("WaterEffectsApplied") then
						self:_applyWaterEffects(descendant)
						descendant:SetAttribute("WaterEffectsApplied", true)
					end
				end
			end
		end
	end
	
	-- Setup existing water
	setupWaterEffects()
	
	-- Watch for new water parts (only in Water folder)
	local waterFolder = Workspace:FindFirstChild("Water")
	if waterFolder then
		self._connection = waterFolder.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") and descendant.Material == Enum.Material.Water then
				task.wait(0.1)
				self:_applyWaterEffects(descendant)
				descendant:SetAttribute("WaterEffectsApplied", true)
			end
		end)
	end
	--]]
end

function WaterEffects:_applyWaterEffects(waterPart)
	-- Make water more transparent and reflective
	waterPart.Transparency = 0.3 -- Slightly transparent
	waterPart.Material = Enum.Material.Water -- Ensure it's water material
	
	-- Add PointLight for subtle glow
	local light = waterPart:FindFirstChildOfClass("PointLight")
	if not light then
		light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(100, 180, 255) -- Light blue
		light.Brightness = 0.3 -- Subtle glow
		light.Range = 20
		light.Shadows = false
		light.Parent = waterPart
	end
	
	-- Add subtle wave animation via color shift
	local colorTween = TweenService:Create(
		light,
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Brightness = 0.5}
	)
	colorTween:Play()
	
	table.insert(self._effects, {
		part = waterPart,
		light = light,
		tween = colorTween
	})
end

function WaterEffects:Stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	
	-- Clean up tweens
	for _, effect in pairs(self._effects) do
		if effect.tween then
			effect.tween:Cancel()
		end
	end
	self._effects = {}
	
	print("[WaterEffects] ✅ Stopped water visual effects")
end

function WaterEffects:Destroy()
	self:Stop()
end

return WaterEffects


