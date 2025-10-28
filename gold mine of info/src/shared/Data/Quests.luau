local Quests = {
	daily_greeting_round = {
		id = "daily_greeting_round",
		title = "Morning Hellos",
		description = "Greet three villagers to brighten their day.",
		category = "Daily",
		objectives = {
			{ objectiveType = "TalkToVillager", amount = 3, hint = "Find villagers around the plaza and say hello." },
		},
		rewards = { bells = 300, miles = 100 },
	},
	daily_resource_fruit = {
		id = "daily_resource_fruit",
		title = "Fruit Basket Delivery",
		description = "Gather five pieces of native fruit for the community basket.",
		category = "Daily",
		objectives = {
			{ objectiveType = "GatherItem", targetId = "fruit_peach", amount = 5, hint = "Shake fruit trees near the plaza." },
		},
		rewards = { bells = 600, miles = 120 },
	},
	daily_shell_collection = {
		id = "daily_shell_collection",
		title = "Beachcomber",
		description = "Collect three shells washed ashore after the tide.",
		category = "Daily",
		objectives = {
			{ objectiveType = "GatherItem", amount = 3, hint = "Check both beaches for sparkling shells." },
		},
		rewards = { bells = 450, miles = 90 },
	},
	daily_bug_round = {
		id = "daily_bug_round",
		title = "Bug Basics",
		description = "Catch four bugs for the museum curator.",
		category = "Daily",
		objectives = {
			{ objectiveType = "CatchBug", amount = 4, hint = "Bring any bugs to Blathers in the plaza tent." },
		},
		rewards = { bells = 400, miles = 110 },
	},
	daily_fish_round = {
		id = "daily_fish_round",
		title = "Gone Fishin'",
		description = "Catch three island fish.",
		category = "Daily",
		objectives = {
			{ objectiveType = "CatchFish", amount = 3, hint = "Try the pier or river mouth for quick catches." },
		},
		rewards = { bells = 500, miles = 130 },
	},
	weekly_home_upgrade = {
		id = "weekly_home_upgrade",
		title = "Home Makeover",
		description = "Place five pieces of furniture inside or outside your home.",
		category = "Weekly",
		objectives = {
			{ objectiveType = "DecorateArea", amount = 5, hint = "Use the decorating mode to arrange furniture." },
		},
		rewards = { miles = 600, bells = 1000 },
	},
	weekly_friendship_focus = {
		id = "weekly_friendship_focus",
		title = "Friendship Goals",
		description = "Complete three villager requests.",
		category = "Weekly",
		objectives = {
			{ objectiveType = "DeliverGift", amount = 3, hint = "Villagers with icons above their head need help." },
		},
		rewards = { miles = 800, bells = 1200 },
	},
	weekly_bug_showcase = {
		id = "weekly_bug_showcase",
		title = "Bug Showcase",
		description = "Catch one rare bug for Flick's exhibit.",
		category = "Weekly",
		objectives = {
			{ objectiveType = "CatchBug", targetId = "bug_atlas_moth", amount = 1, hint = "Check coconut trees after sunset." },
		},
		rewards = { miles = 650, bells = 2500 },
	},
	weekly_fish_tourney = {
		id = "weekly_fish_tourney",
		title = "Fishing Tourney Prep",
		description = "Bring C.J. a prized fish.",
		category = "Weekly",
		objectives = {
			{ objectiveType = "CatchFish", targetId = "fish_barredknifejaw", amount = 1, hint = "Look for large shadows by the reef at night." },
		},
		rewards = { miles = 700, bells = 3500 },
	},
	milestone_tool_master = {
		id = "milestone_tool_master",
		title = "Tool Mastery",
		description = "Craft each beginner tool at least once.",
		category = "Milestone",
		objectives = {
			{ objectiveType = "GatherItem", targetId = "tool_fishing_rod_basic", amount = 1, hint = "Craft at the workbench using Softwood and Iron." },
			{ objectiveType = "GatherItem", targetId = "tool_bug_net_basic", amount = 1, hint = "Craft at the workbench using Softwood." },
			{ objectiveType = "GatherItem", targetId = "tool_shovel_basic", amount = 1, hint = "Craft at the workbench using Hardwood and Iron." },
			{ objectiveType = "GatherItem", targetId = "tool_watering_can_basic", amount = 1, hint = "Craft at the workbench using Softwood and Clay." },
		},
		rewards = { miles = 1000 },
	},
	milestone_museum_supporter = {
		id = "milestone_museum_supporter",
		title = "Museum Supporter",
		description = "Donate 10 unique items to the museum.",
		category = "Milestone",
		objectives = {
			{ objectiveType = "DeliverGift", amount = 10, hint = "Any unique fish, bugs, or fossils count toward the total." },
		},
		rewards = { miles = 1500, bells = 2000 },
	},
	milestone_garden_guru = {
		id = "milestone_garden_guru",
		title = "Garden Guru",
		description = "Grow and water 15 flowers.",
		category = "Milestone",
		objectives = {
			{ objectiveType = "DecorateArea", amount = 15, hint = "Plant flower seeds and keep them watered daily." },
		},
		rewards = { miles = 1200 },
	},
	milestone_relationship_lvl1 = {
		id = "milestone_relationship_lvl1",
		title = "Heartfelt Friend",
		description = "Reach relationship level 3 with any villager.",
		category = "Milestone",
		personalityBias = { "Normal", "Lazy", "Peppy", "Cranky", "Snooty", "Jock" },
		objectives = {
			{ objectiveType = "TalkToVillager", amount = 10, hint = "Chat, gift, and complete requests for your favorite villager." },
		},
		rewards = { miles = 1600, bells = 1800 },
	},
	daily_crafting_order = {
		id = "daily_crafting_order",
		title = "Craft Order",
		description = "Craft two pieces of furniture for the island shop.",
		category = "Daily",
		objectives = {
			{ objectiveType = "GatherItem", amount = 2, hint = "Any furniture crafted at the workbench counts." },
		},
		rewards = { bells = 800, miles = 140 },
	},
	daily_photo_op = {
		id = "daily_photo_op",
		title = "Photo Finish",
		description = "Pose with a villager at a scenic spot.",
		category = "Daily",
		objectives = {
			{ objectiveType = "TalkToVillager", amount = 1, hint = "Use the emote camera near the beach photo stand." },
		},
		rewards = { miles = 160, bells = 300 },
	},
	daily_cleanup = {
		id = "daily_cleanup",
		title = "Keep It Clean",
		description = "Pick up five weeds or loose items around the island.",
		category = "Daily",
		objectives = {
			{ objectiveType = "GatherItem", amount = 5, hint = "Weeds sprout near the cliffs after rain." },
		},
		rewards = { bells = 250, miles = 150 },
	},
}

return Quests
