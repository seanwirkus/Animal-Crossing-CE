local templates = {
	coral_cove = {
		id = "coral_cove",
		displayName = "🏝️ Coral Cove",
		tagline = "Sun-drenched shores with plentiful shells.",
		difficulty = "Calm",
		biomeTags = { "Beach", "Lagoon", "Palm" },
		startingVillagers = { "finn", "tangy" },
		startingResources = { "fruit_orange", "shell_pink", "fish_perch", "shell_conch", "fish_seabass" },
		description = "A laid-back island dotted with tide pools, beach caves, and gentle breezes. Ideal for players who love fishing and shell hunting. Wake up to the sound of waves and palm trees swaying in the breeze.",
		vibe = "Tropical Beach Paradise",
		weatherPreference = "Sunny",
		timeOfDayBonus = "Early Morning (5-8 AM) - Extra rare fish spawns",
		thumbnail = "rbxassetid://0",
		order = 1,
		features = {
			"🏖️ Sandy beaches with coral formations",
			"🐚 Abundant shells for collection",
			"🐟 Rich fishing spots year-round",
			"🌴 Palm trees and tropical vegetation",
			"🌅 Stunning sunset views"
		},
		startingBells = 1500,
		startingMiles = 600,
	},
	forest_glade = {
		id = "forest_glade",
		displayName = "🌲 Forest Glade",
		tagline = "Mossy forests packed with woodworking materials.",
		difficulty = "Balanced",
		biomeTags = { "Forest", "River", "Waterfall" },
		startingVillagers = { "maple", "poppy" },
		startingResources = { "fruit_pear", "crafting_softwood", "bug_firefly", "crafting_hardwood", "fish_freshwater" },
		description = "Thick woodland groves with winding rivers, hidden waterfalls, and plenty of crafting materials for furniture lovers. The forest is alive with the sounds of nature and teeming with creative possibilities.",
		vibe = "Mystical Woodland Haven",
		weatherPreference = "Overcast",
		timeOfDayBonus = "Evening (6-9 PM) - Fireflies and special bugs appear",
		thumbnail = "rbxassetid://0",
		order = 2,
		features = {
			"🌳 Dense, enchanting forests",
			"💧 Rivers with waterfalls",
			"🪵 Abundant crafting materials",
			"🦋 Diverse bug habitats",
			"🍄 Moss-covered ground and mushrooms"
		},
		startingBells = 1200,
		startingMiles = 700,
	},
	highland_spring = {
		id = "highland_spring",
		displayName = "⛰️ Highland Spring",
		tagline = "Clifftop vistas and rare critters for ambitious players.",
		difficulty = "Spirited",
		biomeTags = { "Clifftop", "HotSpring", "Cedar" },
		startingVillagers = { "apollo", "sheldon" },
		startingResources = { "crafting_hardwood", "fish_koi", "bug_tiger_beetle", "crafting_stone", "fish_cherry_salmon" },
		description = "Terraced cliffs with natural hot springs and challenging terrain. Great for players seeking rarer catches and a dramatic skyline. Every sunrise reveals breathtaking views across the island kingdom.",
		vibe = "Majestic Mountain Retreat",
		weatherPreference = "Rainy & Snowy",
		timeOfDayBonus = "Night (9 PM - 5 AM) - Rare mountain dwellers emerge",
		thumbnail = "rbxassetid://0",
		order = 3,
		features = {
			"🏔️ Dramatic clifftop landscape",
			"♨️ Natural hot springs for relaxation",
			"🎣 Rare alpine fish species",
			"❄️ Cedar and pine forests",
			"⭐ Stargazing spots at night"
		},
		startingBells = 2000,
		startingMiles = 500,
	},
}

local ordered = {}
for _, template in pairs(templates) do
	table.insert(ordered, template)
end

table.sort(ordered, function(a, b)
	local orderA = a.order or math.huge
	local orderB = b.order or math.huge
	if orderA == orderB then
		return a.displayName < b.displayName
	end
	return orderA < orderB
end)

return {
	Templates = templates,
	Ordered = ordered,
}
