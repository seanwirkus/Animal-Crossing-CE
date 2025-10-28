local Catalog = {}

local function color3FromHex(hex: string): Color3
	hex = hex:gsub("#", "")
	assert(#hex == 6, "Hex colors must be 6 characters.")
	local r = tonumber(hex:sub(1, 2), 16) or 255
	local g = tonumber(hex:sub(3, 4), 16) or 255
	local b = tonumber(hex:sub(5, 6), 16) or 255
	return Color3.fromRGB(r, g, b)
end

Catalog.SkinTones = {
	{ id = "peach01", color = color3FromHex("#F7E0D3") },
	{ id = "peach02", color = color3FromHex("#EDC4A4") },
	{ id = "tan01", color = color3FromHex("#D5A38B") },
	{ id = "tan02", color = color3FromHex("#C48E7C") },
	{ id = "brown01", color = color3FromHex("#A1725F") },
	{ id = "brown02", color = color3FromHex("#7C5646") },
}

Catalog.EyeColors = {
	color3FromHex("#2F2F2F"),
	color3FromHex("#2A6DB2"),
	color3FromHex("#2BA07E"),
	color3FromHex("#7C4A95"),
}

Catalog.Eyes = {
	{ id = "roundLarge", image = "rbxassetid://0", size = { 0.31, 0.23 }, pos = { 0.50, 0.58 } },
	{ id = "ovalSoft", image = "rbxassetid://0", size = { 0.31, 0.20 }, pos = { 0.50, 0.60 } },
	{ id = "smileEyes", image = "rbxassetid://0", size = { 0.31, 0.18 }, pos = { 0.50, 0.62 } },
}

Catalog.Brows = {
	{ id = "soft", image = "rbxassetid://0", size = { 0.31, 0.10 }, pos = { 0.50, 0.43 } },
	{ id = "thick", image = "rbxassetid://0", size = { 0.31, 0.11 }, pos = { 0.50, 0.41 } },
	{ id = "arched", image = "rbxassetid://0", size = { 0.31, 0.10 }, pos = { 0.50, 0.42 } },
}

Catalog.Noses = {
	{ id = "triangle", image = "rbxassetid://0", size = { 0.08, 0.08 }, pos = { 0.50, 0.65 } },
	{ id = "dot", image = "rbxassetid://0", size = { 0.06, 0.06 }, pos = { 0.50, 0.66 } },
}

Catalog.Mouths = {
	{ id = "smile", image = "rbxassetid://0", size = { 0.31, 0.16 }, pos = { 0.50, 0.75 } },
	{ id = "open", image = "rbxassetid://0", size = { 0.31, 0.18 }, pos = { 0.50, 0.76 } },
	{ id = "catMouth", image = "rbxassetid://0", size = { 0.31, 0.14 }, pos = { 0.50, 0.76 } },
}

Catalog.Hair = {
	{ id = "bob", refPath = "AvatarKit/Hair/Bob" },
	{ id = "sidebun", refPath = "AvatarKit/Hair/SideBun" },
	{ id = "spiky", refPath = "AvatarKit/Hair/Spiky" },
}

Catalog.Outfits = {
	Tops = {
		{ id = "bowCoat", templateId = 0 },
		{ id = "plainTee", templateId = 0 },
	},
	Bottoms = {
		{ id = "skirtA", templateId = 0 },
		{ id = "pantsA", templateId = 0 },
	},
	Shoes = {
		{ id = "bootsA", accessoryPath = "AvatarKit/Shoes/BootsA" },
		{ id = "sneaksA", accessoryPath = "AvatarKit/Shoes/SneaksA" },
	},
}

Catalog.Scales = {
	head = 1.55,
	height = 0.90,
	width = 0.90,
	depth = 0.90,
	proportion = 0.80,
}

function Catalog.defaultProfile()
	local function clone(value)
		if typeof(value) == "table" then
			return table.clone(value)
		end
		return value
	end

	return {
		version = 1,
		skinTone = Catalog.SkinTones[2].id,
		eye = { id = Catalog.Eyes[1].id, colorIndex = 1 },
		brow = { id = Catalog.Brows[1].id },
		nose = { id = Catalog.Noses[1].id },
		mouth = { id = Catalog.Mouths[1].id },
		hair = { id = Catalog.Hair[1].id, color = color3FromHex("#D59197") },
		outfit = {
			top = Catalog.Outfits.Tops[2].id,
			bottom = Catalog.Outfits.Bottoms[2].id,
			shoes = Catalog.Outfits.Shoes[2].id,
		},
		scales = clone(Catalog.Scales),
	}
end

return Catalog
