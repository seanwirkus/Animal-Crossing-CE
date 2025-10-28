local Villagers = {
	maple = {
		id = "maple",
		displayName = "Maple",
		personality = "Normal",
		favoriteItems = { "fruit_peach", "furniture_bonsai_tree", "bug_common_butterfly" },
		dialogue = {
			greetings = {
				"Oh! I was just thinking of you, honey!",
				"Morning glow suits you so well, dear.",
			},
			daily = {
				"I baked fresh peach tarts. Want to share?",
				"Let's take a deep breath and enjoy the breeze.",
				"My scrapbook is filling up with island memories.",
			},
			catchphrases = { "honey", "dewdrop" },
			quests = {
				"Could you gather some softwood for my crafting project?",
				"I'm brewing tea—would you bring me a Sunrise Peach?",
			},
		},
		schedule = {
			{ activity = "MorningStretch", startHour = 6, endHour = 8, locationTag = "Plaza" },
			{ activity = "CafeVisit", startHour = 8, endHour = 11, locationTag = "Cafe" },
			{ activity = "Gardening", startHour = 11, endHour = 14, locationTag = "FlowerBeds" },
			{ activity = "Stroll", startHour = 14, endHour = 18, locationTag = "Beach" },
			{ activity = "Reading", startHour = 18, endHour = 22, locationTag = "Home" },
			{ activity = "Sleep", startHour = 22, endHour = 6, locationTag = "Home" },
		},
		homeModel = "MapleHouse",
		themeColor = { 0.78, 0.55, 0.42 },
	},
	finn = {
		id = "finn",
		displayName = "Finn",
		personality = "Lazy",
		favoriteItems = { "fish_perch", "fruit_orange", "furniture_shell_lamp" },
		dialogue = {
			greetings = {
				"Heeey, pal! Did you hear the waves today?",
				"You brought snacks, right? I brought napping skills.",
			},
			daily = {
				"I took a nap on the dock. Now I need a break.",
				"Ever tried orange slices on toast? Bliss.",
				"Fish tell the best stories if you listen close.",
			},
			catchphrases = { "snooze", "wave" },
			quests = {
				"Mind catching me a Sea Bass? I owe it a rematch.",
				"I'm crafting a hammock—need some Softwood ASAP!",
			},
		},
		schedule = {
			{ activity = "Sleep", startHour = 1, endHour = 9, locationTag = "Home" },
			{ activity = "BeachNap", startHour = 9, endHour = 12, locationTag = "BeachHammock" },
			{ activity = "Fishing", startHour = 12, endHour = 16, locationTag = "Pier" },
			{ activity = "SnackTime", startHour = 16, endHour = 19, locationTag = "Plaza" },
			{ activity = "Stargazing", startHour = 19, endHour = 1, locationTag = "Clifftop" },
		},
		homeModel = "FinnHouse",
		themeColor = { 0.34, 0.56, 0.9 },
	},
	tangy = {
		id = "tangy",
		displayName = "Tangy",
		personality = "Peppy",
		favoriteItems = { "fruit_orange", "furniture_shell_lamp", "tool_fishing_rod_basic" },
		dialogue = {
			greetings = {
				"Eeeee! Perfect timing, zest!",
				"I'm sparkling today—wanna sparkle too?",
			},
			daily = {
				"I made a mood board out of shells and glitter.",
				"The plaza music is my cardio!",
				"Let's host a fashion show by the beach.",
			},
			catchphrases = { "zest", "spark" },
			quests = {
				"I need a Ribbon Eel for a photo shoot. Help?",
				"Could you place two pieces of furniture near the plaza? We need POP!",
			},
		},
		schedule = {
			{ activity = "Jogging", startHour = 6, endHour = 8, locationTag = "Beach" },
			{ activity = "PlazaDance", startHour = 8, endHour = 12, locationTag = "Plaza" },
			{ activity = "MakeoverStudio", startHour = 12, endHour = 17, locationTag = "AbleSisters" },
			{ activity = "PhotoShoot", startHour = 17, endHour = 21, locationTag = "Pier" },
			{ activity = "LateSnack", startHour = 21, endHour = 24, locationTag = "Cafe" },
			{ activity = "Sleep", startHour = 0, endHour = 6, locationTag = "Home" },
		},
		homeModel = "TangyHouse",
		themeColor = { 0.98, 0.62, 0.12 },
	},
	apollo = {
		id = "apollo",
		displayName = "Apollo",
		personality = "Cranky",
		favoriteItems = { "fish_barredknifejaw", "crafting_iron_nugget", "furniture_wooden_chair" },
		dialogue = {
			greetings = {
				"Feathers ruffled? Mine sure aren't.",
				"Hope you're ready to work today.",
			},
			daily = {
				"Discipline keeps the island sharp.",
				"That sea breeze stirs up old memories.",
				"I hammered out a new DIY recipe for ya.",
			},
			catchphrases = { "feathers", "talon" },
			quests = {
				"Bring me three Iron Nuggets. Need to reinforce my porch.",
				"Think you can catch a Barred Knifejaw? Prove it.",
			},
		},
		schedule = {
			{ activity = "DawnDrill", startHour = 4, endHour = 7, locationTag = "Clifftop" },
			{ activity = "Workshop", startHour = 7, endHour = 12, locationTag = "Home" },
			{ activity = "Fishing", startHour = 12, endHour = 15, locationTag = "RiverMouth" },
			{ activity = "Patrol", startHour = 15, endHour = 20, locationTag = "IslandPaths" },
			{ activity = "Relax", startHour = 20, endHour = 24, locationTag = "Home" },
			{ activity = "Sleep", startHour = 0, endHour = 4, locationTag = "Home" },
		},
		homeModel = "ApolloHouse",
		themeColor = { 0.63, 0.63, 0.67 },
	},
	poppy = {
		id = "poppy",
		displayName = "Poppy",
		personality = "Normal",
		favoriteItems = { "bug_firefly", "furniture_bonsai_tree", "fruit_pear" },
		dialogue = {
			greetings = {
				"I saved a comfy spot for you!",
				"The forest whispers hello today.",
			},
			daily = {
				"I pressed flowers into a new book.",
				"Nighttime fireflies are little stars.",
				"Let's craft something gentle, shall we?",
			},
			catchphrases = { "nutty", "glow" },
			quests = {
				"Could you catch a Firefly for my lantern project?",
				"I'm low on River Clay—mind picking up three lumps?",
			},
		},
		schedule = {
			{ activity = "TeaTime", startHour = 6, endHour = 9, locationTag = "Cafe" },
			{ activity = "Reading", startHour = 9, endHour = 12, locationTag = "Library" },
			{ activity = "ForestWalk", startHour = 12, endHour = 17, locationTag = "Woods" },
			{ activity = "Crafting", startHour = 17, endHour = 21, locationTag = "Home" },
			{ activity = "Stargazing", startHour = 21, endHour = 24, locationTag = "Clifftop" },
			{ activity = "Sleep", startHour = 0, endHour = 6, locationTag = "Home" },
		},
		homeModel = "PoppyHouse",
		themeColor = { 0.8, 0.24, 0.3 },
	},
	sheldon = {
		id = "sheldon",
		displayName = "Sheldon",
		personality = "Jock",
		favoriteItems = { "tool_bug_net_basic", "fruit_orange", "fish_tilapia" },
		dialogue = {
			greetings = {
				"Bro, ready for a sprint set?",
				"My muscles woke up before sunrise!",
			},
			daily = {
				"Training tip: chase bugs, build reflexes.",
				"I bet you can't beat my fishing record.",
				"Protein smoothies taste better on the beach.",
			},
			catchphrases = { "cardio", "nutmeg" },
			quests = {
				"Catch three Tiger Beetles so we can race them!",
				"I'm perfecting a balance beam—need Hardwood deliveries.",
			},
		},
		schedule = {
			{ activity = "SunriseWorkout", startHour = 5, endHour = 8, locationTag = "Plaza" },
			{ activity = "TrailRun", startHour = 8, endHour = 11, locationTag = "IslandPaths" },
			{ activity = "BugHunt", startHour = 11, endHour = 15, locationTag = "Meadow" },
			{ activity = "StrengthTraining", startHour = 15, endHour = 19, locationTag = "Gym" },
			{ activity = "Recovery", startHour = 19, endHour = 23, locationTag = "HotSpring" },
			{ activity = "Sleep", startHour = 23, endHour = 5, locationTag = "Home" },
		},
		homeModel = "SheldonHouse",
		themeColor = { 0.95, 0.76, 0.27 },
	},
}

return Villagers
