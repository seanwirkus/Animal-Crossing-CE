local AvatarBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarKitFolder = ReplicatedStorage:FindFirstChild("AvatarKit")

local function newFallbackCatalog()
	local catalog = {}

	catalog.SkinTones = {
		{ id = "peach01", color = Color3.fromRGB(247, 224, 211) },
		{ id = "peach02", color = Color3.fromRGB(237, 196, 164) },
		{ id = "tan01", color = Color3.fromRGB(213, 163, 139) },
		{ id = "tan02", color = Color3.fromRGB(196, 142, 124) },
		{ id = "brown01", color = Color3.fromRGB(161, 114, 95) },
		{ id = "brown02", color = Color3.fromRGB(124, 86, 70) },
	}

	catalog.EyeColors = {
		Color3.fromRGB(47, 47, 47),
		Color3.fromRGB(42, 109, 178),
		Color3.fromRGB(43, 160, 126),
		Color3.fromRGB(124, 74, 149),
	}

	catalog.Eyes = {
		{ id = "roundLarge", size = { 0.31, 0.23 }, pos = { 0.50, 0.58 } },
		{ id = "ovalSoft", size = { 0.31, 0.20 }, pos = { 0.50, 0.60 } },
		{ id = "smileEyes", size = { 0.31, 0.18 }, pos = { 0.50, 0.62 } },
	}

	catalog.Brows = {
		{ id = "soft", size = { 0.31, 0.10 }, pos = { 0.50, 0.43 } },
		{ id = "thick", size = { 0.31, 0.11 }, pos = { 0.50, 0.41 } },
		{ id = "arched", size = { 0.31, 0.10 }, pos = { 0.50, 0.42 } },
	}

	catalog.Noses = {
		{ id = "triangle", size = { 0.08, 0.08 }, pos = { 0.50, 0.65 } },
		{ id = "dot", size = { 0.06, 0.06 }, pos = { 0.50, 0.66 } },
	}

	catalog.Mouths = {
		{ id = "smile", size = { 0.31, 0.16 }, pos = { 0.50, 0.75 } },
		{ id = "open", size = { 0.31, 0.18 }, pos = { 0.50, 0.76 } },
		{ id = "catMouth", size = { 0.31, 0.14 }, pos = { 0.50, 0.76 } },
	}

	catalog.Hair = {
		{ id = "bob", refPath = "" },
		{ id = "sidebun", refPath = "" },
		{ id = "spiky", refPath = "" },
	}

	catalog.Outfits = {
		Tops = {
			{ id = "bowCoat", templateId = 0 },
			{ id = "plainTee", templateId = 0 },
		},
		Bottoms = {
			{ id = "skirtA", templateId = 0 },
			{ id = "pantsA", templateId = 0 },
		},
		Shoes = {
			{ id = "bootsA", accessoryPath = "" },
			{ id = "sneaksA", accessoryPath = "" },
		},
	}

	catalog.Scales = {
		head = 1.55,
		height = 0.90,
		width = 0.90,
		depth = 0.90,
		proportion = 0.80,
	}

	function catalog.defaultProfile()
		return {
			version = 1,
			skinTone = catalog.SkinTones[2].id,
			eye = { id = catalog.Eyes[1].id, colorIndex = 1 },
			brow = { id = catalog.Brows[1].id },
			nose = { id = catalog.Noses[1].id },
			mouth = { id = catalog.Mouths[1].id },
			hair = { id = catalog.Hair[1].id, color = Color3.fromRGB(213, 145, 151) },
			outfit = {
				top = catalog.Outfits.Tops[2].id,
				bottom = catalog.Outfits.Bottoms[2].id,
				shoes = catalog.Outfits.Shoes[2].id,
			},
			scales = table.clone(catalog.Scales),
		}
	end

	return catalog
end

local Catalog
do
	local catalogModule = AvatarKitFolder and AvatarKitFolder:FindFirstChild("Catalog")
	if catalogModule and catalogModule:IsA("ModuleScript") then
		local ok, result = pcall(require, catalogModule)
		if ok then
			Catalog = result
		else
			warn(string.format("[AvatarBuilder] Failed to require AvatarKit/Catalog: %s", tostring(result)))
		end
	end
	if not Catalog then
		warn("[AvatarBuilder] AvatarKit/Catalog missing; using fallback catalog.")
		Catalog = newFallbackCatalog()
	end
end

local warnedMissingFaceGui = false

local CANVAS_SIZE = Vector2.new(512, 512)

local function clamp(value: number, minValue: number, maxValue: number): number
	return math.clamp(value, minValue, maxValue)
end

local function getFaceGui(head: BasePart): SurfaceGui?
	local gui = head:FindFirstChild("FaceGui")
	if gui and gui:IsA("SurfaceGui") then
		return gui
	end

	-- Create FaceGui if it doesn't exist
	gui = Instance.new("SurfaceGui")
	gui.Name = "FaceGui"
	gui.Face = Enum.NormalId.Front
	gui.Parent = head
	
	if not warnedMissingFaceGui then
		warnedMissingFaceGui = true
		print("[AvatarBuilder] Created FaceGui for facial features.")
	end
	return gui
end

local function getFaceSlot(head: BasePart, slotName: string): ImageLabel?
	local faceGui = getFaceGui(head)
	if not faceGui then
		return nil
	end
	local slot = faceGui:FindFirstChild(slotName)
	if not slot then
		slot = Instance.new("ImageLabel")
		slot.Name = slotName
		slot.BackgroundTransparency = 1
		slot.BorderSizePixel = 0
		slot.ScaleType = Enum.ScaleType.Stretch
		slot.Parent = faceGui
	end

slot.AnchorPoint = Vector2.new(0.5, 0.5)
return slot
end

local function applyFaceSlot(head: BasePart, slotName: string, definition, tint: Color3?)
	if not definition then
		return
	end

	local slot = getFaceSlot(head, slotName)
	if not slot then
		return
	end
	slot.Image = definition.image or ""
	slot.ImageColor3 = tint or Color3.new(1, 1, 1)

	local size = Vector2.new(
		math.floor((definition.size and definition.size[1] or 0.25) * CANVAS_SIZE.X),
		math.floor((definition.size and definition.size[2] or 0.25) * CANVAS_SIZE.Y)
	)

	local pos = Vector2.new(
		math.floor((definition.pos and definition.pos[1] or 0.5) * CANVAS_SIZE.X),
		math.floor((definition.pos and definition.pos[2] or 0.5) * CANVAS_SIZE.Y)
	)

	slot.Size = UDim2.fromOffset(size.X, size.Y)
	slot.Position = UDim2.fromOffset(pos.X, pos.Y)
end

local function setHumanoidScaleValues(humanoid: Humanoid, scales)
	local scaleMap = {
		HeadScale = scales.head,
		BodyHeightScale = scales.height,
		BodyWidthScale = scales.width,
		BodyDepthScale = scales.depth,
		BodyProportionScale = scales.proportion,
	}

	for attribute, value in pairs(scaleMap) do
		local numberValue = humanoid:FindFirstChild(attribute)
		if numberValue and numberValue:IsA("NumberValue") then
			numberValue.Value = value
		end
	end
end

local function setSkinColors(character: Model, color: Color3)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		bodyColors.HeadColor3 = color
		bodyColors.LeftArmColor3 = color
		bodyColors.RightArmColor3 = color
		bodyColors.LeftLegColor3 = color
		bodyColors.RightLegColor3 = color
		bodyColors.TorsoColor3 = color
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			descendant.Color = color
		end
	end
end

local function clearAccessories(character: Model, keepSet: { [string]: boolean }?)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			if not keepSet or not keepSet[child.Name] then
				child:Destroy()
			end
		end
	end
end

local function getDefinitionById(list, id)
	if not id then
		return list[1]
	end
	for _, entry in ipairs(list) do
		if entry.id == id then
			return entry
		end
	end
	return list[1]
end

local function cloneFromPath(root: Instance, path: string): Instance?
	local current = root
	for segment in string.gmatch(path, "[^/]+") do
		current = current:FindFirstChild(segment)
		if not current then
			return nil
		end
	end
	return current:Clone()
end

local function applyClassicClothing(character: Model, outfit)
	local shirt = character:FindFirstChildOfClass("Shirt")
	if not shirt then
		shirt = Instance.new("Shirt")
		shirt.Name = "ChibiShirt"
		shirt.Parent = character
	end

	local pants = character:FindFirstChildOfClass("Pants")
	if not pants then
		pants = Instance.new("Pants")
		pants.Name = "ChibiPants"
		pants.Parent = character
	end

	local top = getDefinitionById(Catalog.Outfits.Tops, outfit.top)
	if top and top.templateId and top.templateId ~= 0 then
		shirt.ShirtTemplate = ("rbxassetid://%s"):format(top.templateId)
	else
		shirt.ShirtTemplate = ""
	end

	local bottom = getDefinitionById(Catalog.Outfits.Bottoms, outfit.bottom)
	if bottom and bottom.templateId and bottom.templateId ~= 0 then
		pants.PantsTemplate = ("rbxassetid://%s"):format(bottom.templateId)
	else
		pants.PantsTemplate = ""
	end
end

local function applyAccessories(character: Model, profile)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	clearAccessories(character)

	local hairDef = getDefinitionById(Catalog.Hair, profile.hair and profile.hair.id)
	if hairDef and hairDef.refPath then
		local source = cloneFromPath(ReplicatedStorage, hairDef.refPath)
		if source and source:IsA("Accessory") then
			source.Name = "Hair_" .. hairDef.id
			source.Parent = character
			humanoid:AddAccessory(source)

			if profile.hair and profile.hair.color then
				for _, descendant in ipairs(source:GetDescendants()) do
					if descendant:IsA("BasePart") then
						descendant.Color = profile.hair.color
					end
				end
			end
		end
	end

	if profile.outfit and profile.outfit.shoes then
		local shoeDef = getDefinitionById(Catalog.Outfits.Shoes, profile.outfit.shoes)
		if shoeDef and shoeDef.accessoryPath then
			local shoeAcc = cloneFromPath(ReplicatedStorage, shoeDef.accessoryPath)
			if shoeAcc and shoeAcc:IsA("Accessory") then
				shoeAcc.Name = "Shoes_" .. shoeDef.id
				shoeAcc.Parent = character
				humanoid:AddAccessory(shoeAcc)
			end
		end
	end
end

local function resolveSkinColor(profile)
	for _, entry in ipairs(Catalog.SkinTones) do
		if entry.id == profile.skinTone then
			return entry.color
		end
	end
	return Catalog.SkinTones[1].color
end

function AvatarBuilder.applyProfile(character: Model, profile)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	if not humanoid or not head or not head:IsA("BasePart") then
		warn("[AvatarBuilder] Character missing Humanoid or Head.")
		return
	end

	local scales = profile.scales or Catalog.Scales
	setHumanoidScaleValues(humanoid, {
		head = clamp(scales.head or Catalog.Scales.head, 1.2, 1.8),
		height = clamp(scales.height or Catalog.Scales.height, 0.8, 1.05),
		width = clamp(scales.width or Catalog.Scales.width, 0.8, 1.2),
		depth = clamp(scales.depth or Catalog.Scales.depth, 0.8, 1.2),
		proportion = clamp(scales.proportion or Catalog.Scales.proportion, 0.7, 1.1),
	})

	local skinColor = resolveSkinColor(profile)
	setSkinColors(character, skinColor)

	local eyeDef = getDefinitionById(Catalog.Eyes, profile.eye and profile.eye.id)
	local browDef = getDefinitionById(Catalog.Brows, profile.brow and profile.brow.id)
	local noseDef = getDefinitionById(Catalog.Noses, profile.nose and profile.nose.id)
	local mouthDef = getDefinitionById(Catalog.Mouths, profile.mouth and profile.mouth.id)

	local eyeColor = Catalog.EyeColors[profile.eye and profile.eye.colorIndex or 1] or Catalog.EyeColors[1]

	-- Apply facial features (FaceGui will be created if needed)
	applyFaceSlot(head, "Eyes", eyeDef, eyeColor)
	applyFaceSlot(head, "Brows", browDef, eyeColor)
	applyFaceSlot(head, "Nose", noseDef, Color3.new(1, 1, 1))
	applyFaceSlot(head, "Mouth", mouthDef, Color3.new(1, 1, 1))

	applyAccessories(character, profile)
	applyClassicClothing(character, profile.outfit or {})
end

function AvatarBuilder.spawnPreview(viewport: ViewportFrame): Model?
	if not viewport then
		return nil
	end

	viewport.BackgroundTransparency = 1
	local avatarKitFolder = ReplicatedStorage:FindFirstChild("AvatarKit")
	if not avatarKitFolder then
		warn("[AvatarBuilder] AvatarKit folder missing in ReplicatedStorage.")
		return nil
	end

	local rigTemplate = avatarKitFolder:FindFirstChild("ChibiRig")
	if not rigTemplate or not rigTemplate:IsA("Model") then
		warn("[AvatarBuilder] ChibiRig model missing. Add a rig under ReplicatedStorage/AvatarKit/ChibiRig.")
		return nil
	end

	local rig = rigTemplate:Clone()
	rig.Name = "PreviewRig"
	rig.Parent = viewport

	local camera = Instance.new("Camera")
	camera.Name = "PreviewCamera"
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	task.defer(function()
		local root = rig:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local lookTarget = root.Position + Vector3.new(0, 1.2, 0)
			camera.CFrame = CFrame.new(root.Position + Vector3.new(0, 1.5, 5), lookTarget)
		end
	end)

	return rig
end

return AvatarBuilder
