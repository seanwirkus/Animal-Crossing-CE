-- ACNH Roblox Style Guide
-- This file defines the core UI/UX styling conventions for all dialog/narration GUIs, especially villager conversations.
-- Use these constants and patterns for all dialog, narration, and management GUIs to ensure a consistent Animal Crossing-like experience.

local StyleGuide = {}

-- Roblox globals fallback for plugin/test environments


-- Color Palette
StyleGuide.Colors = {
	DialogBackground = Color3.fromRGB(44, 44, 44), -- dark background for dialog boxes
	DialogBorder = Color3.fromRGB(255, 180, 0),    -- yellow border for name tags
	DialogText = Color3.fromRGB(211, 251, 248),    -- light blue text on dark
	NameTagBackground = Color3.fromRGB(255, 204, 0),
	NameTagText = Color3.fromRGB(114, 93, 66),
	ButtonPrimary = Color3.fromRGB(255, 204, 0),
	ButtonText = Color3.fromRGB(44, 44, 44),
	-- Add more as needed
}

-- Font Styles
StyleGuide.Fonts = {
	Dialog = Enum.Font.Roboto,
	DialogSize = 48,
	DialogWeight = Enum.FontWeight.Medium,
	NameTag = Enum.Font.Roboto,
	NameTagSize = 48,
	NameTagWeight = Enum.FontWeight.Medium,
	LargeText = 60,
}

-- Dialog Box
StyleGuide.DialogBox = {
	Width = 1190,
	Height = 331,
	CornerRadius = 120,
	Padding = 32,
	BackgroundTransparency = 0.05,
}

-- Name Tag
StyleGuide.NameTag = {
	Width = 331,
	Height = 60,
	CornerRadius = 40,
	Padding = 20, -- pixels, use as needed for UIPadding or similar
	BackgroundColor = StyleGuide.Colors.NameTagBackground,
	TextColor = StyleGuide.Colors.NameTagText,
}
-- NOTE: This file assumes it is running in a Roblox environment where Color3, Enum, and UDim2 are available as globals.
-- If you are running outside Roblox, you must mock these or run in Studio/Play mode.

-- Continue Arrow (SVG as Image)
StyleGuide.ContinueArrow = {
	Image = "rbxassetid://<your_arrow_asset_id>", -- Replace with actual asset id or use data URI
	Width = 48,
	Height = 32,
}

-- Animation/Transitions
StyleGuide.Animations = {
	DialogFadeInTime = 0.25,
	DialogFadeOutTime = 0.2,
	ButtonHoverScale = 1.05,
}

-- General UI
StyleGuide.General = {
	Shadow = true,
	ShadowTransparency = 0.4,
	ShadowSize = 24,
}

-- Usage:
-- require this file in all dialog/narration GUIs and use StyleGuide.Colors, StyleGuide.Fonts, etc.

return StyleGuide
