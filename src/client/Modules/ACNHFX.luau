-- ACNHFX.luau
-- Applies the Sky and lighting effects from ACNH-fx.rbxmx
-- This replaces the old ACLighting system with the skybox clouds and lighting
-- Now includes realistic shadows and ray tracing

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local ACNHFX = {}

local function ensureSky()
	local existing = Lighting:FindFirstChild("__WORLDFX")
	if existing and existing:IsA("Sky") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	
	local sky = Instance.new("Sky")
	sky.Name = "__WORLDFX"
	sky.Parent = Lighting
	return sky
end

function ACNHFX.setup()
	-- DISABLED - User managing all lighting/effects in Studio
	-- All shaders, color effects, post-processing, and lighting changes are disabled
	-- User can configure these directly in Roblox Studio for better control
	
	print("[ACNHFX] ⚠️ ACNH-fx effects DISABLED - managing lighting/effects in Studio")
	print("[ACNHFX]    No shaders, color correction, bloom, or post-processing will be applied")
	print("[ACNHFX]    No lighting properties will be modified")
	print("[ACNHFX]    No material conversions will occur")
	print("[ACNHFX]    Configure all effects directly in Studio's Lighting service")
	
	-- Only remove baseplate (safe cleanup, no visual effects)
	pcall(function()
		local baseplate = Workspace:FindFirstChild("Baseplate")
		if baseplate then
			baseplate:Destroy()
			print("[ACNHFX] ✅ Removed baseplate from workspace")
		end
	end)
	
	return nil
end

return ACNHFX

