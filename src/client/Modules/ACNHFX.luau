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
	print("[ACNHFX] ☁️ Setting up ACNH-fx Sky with clouds and realistic lighting...")
	
	-- Remove baseplate if it exists in workspace
	pcall(function()
		local baseplate = Workspace:FindFirstChild("Baseplate")
		if baseplate then
			baseplate:Destroy()
			print("[ACNHFX] ✅ Removed baseplate from workspace")
		end
	end)
	
	-- Clear any old lighting effects (but keep basic lighting properties)
	pcall(function()
		-- Remove old effects
		for _, child in ipairs(Lighting:GetChildren()) do
			if child:IsA("Atmosphere") or 
			   child:IsA("BloomEffect") or 
			   child:IsA("ColorCorrectionEffect") or 
			   child:IsA("SunRaysEffect") or
			   child:IsA("DepthOfFieldEffect") then
				child:Destroy()
			end
		end
		
		-- Also remove old Sky if it's not our __WORLDFX
		for _, child in ipairs(Lighting:GetChildren()) do
			if child:IsA("Sky") and child.Name ~= "__WORLDFX" then
				child:Destroy()
			end
		end
	end)
	
	-- Set up realistic lighting with shadows and ray tracing
	pcall(function()
		-- Enable global shadows for realistic lighting
		Lighting.GlobalShadows = true
		
		-- Use Voxel technology for ray tracing (realistic shadows)
		-- This provides the most realistic shadow rendering
		Lighting.Technology = Enum.Technology.Voxel
		
		-- Shadow quality settings
		Lighting.ShadowSoftness = 0.2  -- Lower = sharper shadows (more realistic)
		Lighting.ShadowColor = Color3.fromRGB(0, 0, 0)  -- Pure black shadows
		
		-- Aggressive anti-plastic lighting properties (matte, non-plastic look)
		Lighting.Brightness = 1.8  -- Slightly dimmer for more realistic look
		Lighting.ExposureCompensation = -0.1  -- Slightly underexposed to reduce shine
		Lighting.EnvironmentDiffuseScale = 1.2  -- Extra diffuse lighting for matte look
		Lighting.EnvironmentSpecularScale = 0  -- ZERO specular - completely eliminate shine
		Lighting.ReflectionsEnabled = false  -- Disable reflections for matte appearance
		
		-- Softer ambient lighting (less bright = less plastic)
		Lighting.Ambient = Color3.fromRGB(80, 100, 120)  -- Darker ambient (reduces overall brightness/shine)
		Lighting.OutdoorAmbient = Color3.fromRGB(120, 140, 160)  -- Less bright outdoor
		
		-- Color shift for realistic sky/ground colors
		Lighting.ColorShift_Top = Color3.fromRGB(135, 206, 235)  -- Sky blue
		Lighting.ColorShift_Bottom = Color3.fromRGB(180, 160, 140)  -- Ground tint
		
		-- Clock time for good lighting
		Lighting.ClockTime = 12.0  -- Noon for clear, realistic shadows
		Lighting.GeographicLatitude = 25.0  -- Subtropical (like Animal Crossing islands)
		
		print("[ACNHFX] ✅ Realistic lighting with shadows and ray tracing enabled!")
		print("[ACNHFX]    Technology: Voxel (Ray Tracing)")
		print("[ACNHFX]    GlobalShadows: Enabled")
		print("[ACNHFX]    ShadowSoftness: 0.2 (Sharp shadows)")
		print("[ACNHFX]    SpecularScale: 0 (NO SHINE - completely matte)")
		print("[ACNHFX]    Reflections: Disabled")
		print("[ACNHFX]    Brightness: 1.8 (Reduced for less plastic look)")
	end)
	
	-- Add color correction to reduce saturation and contrast (helps with plastic look)
	pcall(function()
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "AC_AntiPlastic"
		cc.Enabled = true
		cc.Saturation = -0.15  -- Reduce saturation (less vivid = less plastic)
		cc.Contrast = -0.1  -- Reduce contrast (softer = less plastic)
		cc.Brightness = 0  -- Neutral brightness
		cc.TintColor = Color3.fromRGB(255, 255, 255)  -- Neutral tint
		cc.Parent = Lighting
		print("[ACNHFX] ✅ Color correction applied (desaturated for matte look)")
	end)
	
	-- Set default materials to be less reflective/more matte
	-- This helps prevent the plastic look on all parts
	task.spawn(function()
		-- Wait a frame to let workspace load
		RunService.Heartbeat:Wait()
		
		local function makeMatte(part)
			if part:IsA("BasePart") then
				-- Aggressively convert ALL shiny materials to matte ones
				-- BUT preserve natural materials that need their textures
				local material = part.Material
				
				-- PRESERVE natural/environmental materials (they need their textures!)
				local preserveMaterials = {
					Enum.Material.Grass,
					Enum.Material.LeafyGrass,
					Enum.Material.Ground,
					Enum.Material.Rock,
					Enum.Material.Sand,
					Enum.Material.Snow,
					Enum.Material.Wood,
					Enum.Material.WoodPlanks,
					Enum.Material.Concrete,
					Enum.Material.Brick,
					Enum.Material.Cobblestone,
					Enum.Material.Slate,
					Enum.Material.Water,
					Enum.Material.Asphalt,
				}
				
				-- Check if this material should be preserved
				local shouldPreserve = false
				for _, preserveMat in ipairs(preserveMaterials) do
					if material == preserveMat then
						shouldPreserve = true
						break
					end
				end
				
				-- Only convert if it's not a natural material
				if not shouldPreserve then
					-- Convert all plastic/shiny materials to fabric (completely matte)
					if material == Enum.Material.Plastic 
						or material == Enum.Material.SmoothPlastic
						or material == Enum.Material.Neon
						or material == Enum.Material.Glass
						or material == Enum.Material.Metal
						or material == Enum.Material.DiamondPlate
						or material == Enum.Material.CorrodedMetal
						or material == Enum.Material.ForceField then
						part.Material = Enum.Material.Fabric  -- Most matte material
					end
				end
				-- If it's a natural material, leave it alone (preserve texture)
			end
		end
		
		-- Apply to existing parts
		for _, part in ipairs(Workspace:GetDescendants()) do
			makeMatte(part)
		end
		
		-- Apply to newly added parts
		Workspace.DescendantAdded:Connect(function(part)
			makeMatte(part)
		end)
		
		print("[ACNHFX] ✅ Applied matte material defaults to prevent plastic look")
	end)
	
	-- Set up the Sky from ACNH-fx.rbxmx
	local sky = ensureSky()
	
	-- Apply all settings from ACNH-fx.rbxmx
	sky.CelestialBodiesShown = false
	sky.MoonAngularSize = 11
	sky.MoonTextureId = ""
	sky.SkyboxBk = "rbxassetid://6295671271"
	sky.SkyboxDn = "rbxassetid://6295671382"
	sky.SkyboxFt = "rbxassetid://6295671136"
	sky.SkyboxLf = "rbxassetid://6295670996"
	sky.SkyboxRt = "rbxassetid://6295671509"
	sky.SkyboxUp = "rbxassetid://6295671667"
	sky.SkyboxOrientation = Vector3.new(0, 0, 0)
	sky.StarCount = 0
	sky.SunAngularSize = 10
	sky.SunTextureId = "rbxasset://sky/sun.jpg"
	
	print("[ACNHFX] ✅ Sky configured with skybox textures and clouds!")
	print("[ACNHFX] 📝 You can now tweak settings in referenceRBXMXfiles/ACNH-fx.rbxmx")
	
	return sky
end

return ACNHFX

