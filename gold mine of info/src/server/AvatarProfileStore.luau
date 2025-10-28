-- local DataStoreService = game:GetService("DataStoreService") -- Disabled for now
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarKit = ReplicatedStorage:FindFirstChild("AvatarKit")

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

local function newFallbackAvatarBuilder()
	return {
		applyProfile = function() end,
		spawnPreview = function()
			return nil
		end,
	}
end

local function loadModule(folder: Instance?, moduleName: string, description: string, fallbackFactory)
	if folder then
		local module = folder:FindFirstChild(moduleName)
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module)
			if ok then
				return result
			else
				warn(string.format("[AvatarProfileStore] Failed to require %s: %s", moduleName, tostring(result)))
			end
		end
	end

	warn(string.format("[AvatarProfileStore] %s missing; using fallback implementation.", description))
	return fallbackFactory()
end

local Catalog = loadModule(AvatarKit, "Catalog", "AvatarKit Catalog", newFallbackCatalog)
local AvatarBuilder = loadModule(AvatarKit, "AvatarBuilder", "AvatarKit AvatarBuilder", newFallbackAvatarBuilder)

local AvatarProfileStore = {}

local store = DataStoreService:GetDataStore("AvatarProfileV1")

local function pickId(id: string?, list, defaultId: string)
	local fallback = defaultId or (list[1] and list[1].id)
	if not id then
		return fallback
	end
	for _, entry in ipairs(list) do
		if entry.id == id then
			return entry.id
		end
	end
	return fallback
end

local function getSkinTone(id: string?)
	for _, entry in ipairs(Catalog.SkinTones) do
		if entry.id == id then
			return entry
		end
	end
	return Catalog.SkinTones[1]
end

function AvatarProfileStore.sanitizeProfile(profile: any)
	local clean = Catalog.defaultProfile()
	if typeof(profile) ~= "table" then
		return clean
	end

	clean.skinTone = pickId(profile.skinTone, Catalog.SkinTones, clean.skinTone)

	clean.eye.id = pickId(profile.eye and profile.eye.id, Catalog.Eyes, clean.eye.id)
	local eyeColorIndex = tonumber(profile.eye and profile.eye.colorIndex) or clean.eye.colorIndex
	clean.eye.colorIndex = math.clamp(eyeColorIndex, 1, #Catalog.EyeColors)

	clean.brow.id = pickId(profile.brow and profile.brow.id, Catalog.Brows, clean.brow.id)
	clean.nose.id = pickId(profile.nose and profile.nose.id, Catalog.Noses, clean.nose.id)
	clean.mouth.id = pickId(profile.mouth and profile.mouth.id, Catalog.Mouths, clean.mouth.id)

	clean.hair.id = pickId(profile.hair and profile.hair.id, Catalog.Hair, clean.hair.id)
	if profile.hair then
		if typeof(profile.hair.color) == "Color3" then
			clean.hair.color = profile.hair.color
		elseif typeof(profile.hair.color) == "table" then
			local colorTable = profile.hair.color
			if colorTable.r and colorTable.g and colorTable.b then
				clean.hair.color = Color3.new(colorTable.r, colorTable.g, colorTable.b)
			elseif colorTable[1] and colorTable[2] and colorTable[3] then
				clean.hair.color = Color3.new(colorTable[1], colorTable[2], colorTable[3])
			end
		end
	end

	clean.outfit.top = pickId(profile.outfit and profile.outfit.top, Catalog.Outfits.Tops, clean.outfit.top)
	clean.outfit.bottom = pickId(profile.outfit and profile.outfit.bottom, Catalog.Outfits.Bottoms, clean.outfit.bottom)
	clean.outfit.shoes = pickId(profile.outfit and profile.outfit.shoes, Catalog.Outfits.Shoes, clean.outfit.shoes)

	local scales = profile.scales or {}
	clean.scales.head = math.clamp(tonumber(scales.head) or clean.scales.head, 1.2, 1.8)
	clean.scales.height = math.clamp(tonumber(scales.height) or clean.scales.height, 0.8, 1.05)
	clean.scales.width = math.clamp(tonumber(scales.width) or clean.scales.width, 0.8, 1.2)
	clean.scales.depth = math.clamp(tonumber(scales.depth) or clean.scales.depth, 0.8, 1.2)
	clean.scales.proportion = math.clamp(tonumber(scales.proportion) or clean.scales.proportion, 0.7, 1.1)

	return clean
end

local function keyForPlayer(player: Player): string
	return ("profile:%d"):format(player.UserId)
end

function AvatarProfileStore.loadProfile(player: Player)
	local key = keyForPlayer(player)
	local ok, data = pcall(store.GetAsync, store, key)
	if ok and data then
		return AvatarProfileStore.sanitizeProfile(data)
	end
	return Catalog.defaultProfile()
end

function AvatarProfileStore.saveProfile(player: Player, profile: table)
	local clean = AvatarProfileStore.sanitizeProfile(profile)
	local key = keyForPlayer(player)

	local serializable = table.clone(clean)
	serializable.hair = table.clone(clean.hair)
	if typeof(serializable.hair.color) == "Color3" then
		local c = serializable.hair.color
		serializable.hair.color = { r = c.R, g = c.G, b = c.B }
	end

	local ok, err = pcall(store.SetAsync, store, key, serializable)
	if not ok then
		warn(string.format("[AvatarProfileStore] Failed to save profile for %s: %s", player.Name, tostring(err)))
		return false, clean, err
	end

	local character = player.Character
	if character then
		task.defer(function()
			local success, applyErr = pcall(function()
				AvatarBuilder.applyProfile(character, clean)
			end)
			if not success then
				warn(string.format("[AvatarProfileStore] Failed to apply profile to %s: %s", player.Name, tostring(applyErr)))
			end
		end)
	end

	return true, clean
end

return AvatarProfileStore
