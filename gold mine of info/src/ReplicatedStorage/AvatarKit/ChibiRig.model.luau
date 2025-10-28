-- ChibiRig Model for Avatar Preview
-- This is the model file that AvatarBuilder.spawnPreview() looks for

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarKitFolder = ReplicatedStorage:FindFirstChild("AvatarKit")

if not AvatarKitFolder then
	AvatarKitFolder = Instance.new("Folder")
	AvatarKitFolder.Name = "AvatarKit"
	AvatarKitFolder.Parent = ReplicatedStorage
end

-- Create ChibiRig model - this is what spawnPreview needs
local function createChibiRig()
	local rig = Instance.new("Model")
	rig.Name = "ChibiRig"

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = rig

	-- Root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(1, 1, 1)
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Transparency = 1 -- Invisible root
	rootPart.Parent = rig

	rig.PrimaryPart = rootPart

	-- Create basic body parts for avatar preview
	local parts = {
		{Name = "Head", Size = Vector3.new(1.2, 1.2, 1), Position = Vector3.new(0, 3, 0)},
		{Name = "Torso", Size = Vector3.new(2, 2, 1), Position = Vector3.new(0, 1.5, 0)},
		{Name = "Left Arm", Size = Vector3.new(0.6, 1.8, 0.6), Position = Vector3.new(-1.8, 2, 0)},
		{Name = "Right Arm", Size = Vector3.new(0.6, 1.8, 0.6), Position = Vector3.new(1.8, 2, 0)},
		{Name = "Left Leg", Size = Vector3.new(0.6, 1.8, 0.6), Position = Vector3.new(-0.6, -0.5, 0)},
		{Name = "Right Leg", Size = Vector3.new(0.6, 1.8, 0.6), Position = Vector3.new(0.6, -0.5, 0)},
	}

	for _, partData in ipairs(parts) do
		local part = Instance.new("Part")
		part.Name = partData.Name
		part.Size = partData.Size
		part.Position = partData.Position
		part.Anchored = true
		part.CanCollide = false
		part.BrickColor = BrickColor.new("Light orange")
		part.Material = Enum.Material.SmoothPlastic
		part.Parent = rig

		-- Weld to root (except root itself)
		if part.Name ~= "HumanoidRootPart" then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rootPart
			weld.Part1 = part
			weld.Parent = rootPart
		end
	end

	-- Add body colors
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3 = Color3.fromRGB(238, 195, 154)
	bodyColors.TorsoColor3 = Color3.fromRGB(238, 195, 154)
	bodyColors.LeftArmColor3 = Color3.fromRGB(238, 195, 154)
	bodyColors.RightArmColor3 = Color3.fromRGB(238, 195, 154)
	bodyColors.LeftLegColor3 = Color3.fromRGB(238, 195, 154)
	bodyColors.RightLegColor3 = Color3.fromRGB(238, 195, 154)
	bodyColors.Parent = rig

	return rig
end

-- Create and store the ChibiRig model in ReplicatedStorage
local chibiRig = createChibiRig()
chibiRig.Parent = AvatarKitFolder

print("[AvatarKit] ChibiRig model created for character preview")

return chibiRig
