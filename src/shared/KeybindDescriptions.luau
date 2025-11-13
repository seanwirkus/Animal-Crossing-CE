local KeybindDescriptions = {}

-- Normal player keybind descriptions
KeybindDescriptions.NORMAL = {
	INVENTORY = "Open inventory to manage items in backpack.",
	DROP_ITEM = "Drop the currently selected item onto the ground.",
	REACTION = "Open the Reactions wheel to perform emotes.",
	CRAFTING = "Open the crafting menu to build items.",
	TOOL_WHEEL = "Open the tool wheel for quick tool selection.",
	NOOK_PHONE = "Pull up the NookPhone interface with all apps.",
	PREMIUM_SHOP = "Open the Premium Shop to purchase Bells and Nook Miles with Robux.",
	MAP = "Open the island map (coming soon).",
	SETTINGS = "Open the settings menu.",
	GAME_MENU = "Open the unified game menu with tabs for inventory, settings, and more.",
	KEYBIND_GUIDE = "Open this interactive guide with every keybind and quick actions.",
	EMOTE = "Perform an emote (coming soon).",
}

-- Debug-only keybind descriptions
KeybindDescriptions.DEBUG = {
	DEBUG_GUI = "Toggle the developer debug menu.",
	ITEM_BROWSER = "Open the item browser to spawn any item.",
	DEBUG_DELETE = "Delete the first inventory item for testing.",
	TEST_PLANE = "Play the NookPlane cutscene (debug use).",
	QUEST_BOARD = "Open the quest board interface.",
	START_ONBOARDING = "Start the onboarding dialogue sequence.",
}

return KeybindDescriptions

