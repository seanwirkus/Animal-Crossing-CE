--[[
	Theme.lua

	Comprehensive Animal Crossing-style theme system for all GUI components.
	Provides centralized tokens for colors, radii, shadows, typography, and spacing.

	Based on the 100-point AC style guide specification.
]]

local Theme = {}

-- =============================================================================
-- COLOR PALETTE - AC-Inspired Warm, Soft Colors
-- =============================================================================

Theme.colors = {
	-- Core Backgrounds
	offWhite = Color3.fromRGB(252, 250, 242),      -- #FCFAF2 - Main background
	eggshell = Color3.fromRGB(240, 237, 228),      -- #F0EDE4 - Secondary background
	cream = Color3.fromRGB(255, 251, 231),         -- #FFFBE7 - Alternative cream

	-- Warm Yellows & Golds
	warmYellow = Color3.fromRGB(255, 223, 128),    -- #FFDF80 - Button highlights
	bellGold = Color3.fromRGB(255, 193, 77),       -- #FFC14D - Accents and borders

	-- Greens (Nature, Growth)
	leafGreen = Color3.fromRGB(156, 204, 101),     -- #9CCC65 - Success, nature
	skyBlue = Color3.fromRGB(129, 212, 250),      -- #81D4FA - Water, sky

	-- Browns (Wood, Earth)
	buttonBrown = Color3.fromRGB(121, 85, 72),     -- #795548 - Primary buttons
	darkBrown = Color3.fromRGB(62, 39, 35),        -- #3E2723 - Text, borders
	lightBrown = Color3.fromRGB(141, 110, 99),     -- #8E6E63 - Secondary elements

	-- Accent Colors
	notificationRed = Color3.fromRGB(244, 67, 54), -- #F44336 - Errors, warnings
	teal = Color3.fromRGB(4, 175, 166),            -- #04AFA6 - Selected, active states

	-- Text Colors
	textPrimary = Color3.fromRGB(33, 33, 33),      -- #212121 - Primary text
	textSecondary = Color3.fromRGB(117, 117, 117), -- #757575 - Secondary text
	textLight = Color3.fromRGB(255, 255, 255),     -- #FFFFFF - Light text on dark
}

-- =============================================================================
-- BORDER RADIUS - Large, Soft Corners (20-36px)
-- =============================================================================

Theme.radius = {
	small = UDim.new(0, 8),     -- Small elements
	medium = UDim.new(0, 16),   -- Medium elements
	large = UDim.new(0, 24),    -- Main panels, dialogs
	xlarge = UDim.new(0, 32),   -- Large containers
	xxlarge = UDim.new(0, 36),  -- Special elements
}

-- =============================================================================
-- SHADOWS - Soft Drop Shadows with Brown/Black Tints
-- =============================================================================

Theme.shadows = {
	small = {
		Color = Color3.fromRGB(0, 0, 0),
		Transparency = 0.3,
		Offset = Vector2.new(0, 2),
		Blur = 4,
	},
	medium = {
		Color = Color3.fromRGB(62, 39, 35),  -- Dark brown tint
		Transparency = 0.25,
		Offset = Vector2.new(0, 4),
		Blur = 8,
	},
	large = {
		Color = Color3.fromRGB(62, 39, 35),  -- Dark brown tint
		Transparency = 0.2,
		Offset = Vector2.new(0, 6),
		Blur = 12,
	},
}

-- =============================================================================
-- TYPOGRAPHY - Friendly, Rounded Sans-Serif
-- =============================================================================

Theme.fonts = {
	primary = Enum.Font.Gotham,           -- Main UI font
	secondary = Enum.Font.GothamMedium,   -- Medium weight
	bold = Enum.Font.GothamBold,          -- Bold weight
	black = Enum.Font.GothamBlack,        -- Extra bold
}

Theme.textSizes = {
	xsmall = 12,   -- Small labels
	small = 14,    -- Body text minimum
	medium = 16,   -- Standard body
	large = 18,    -- Large body
	xlarge = 20,   -- Subtitles
	xxlarge = 24,  -- Titles
	xxxlarge = 32, -- Hero text
}

-- =============================================================================
-- SPACING - Consistent Scale (4/8/12/16/24/32px)
-- =============================================================================

Theme.spacing = {
	xs = 4,    -- Extra small gaps
	sm = 8,    -- Small gaps
	md = 12,   -- Medium gaps
	lg = 16,   -- Large gaps
	xl = 24,   -- Extra large gaps
	xxl = 32,  -- Double extra large
}

-- =============================================================================
-- COMPONENT THEMES - Pre-configured Styles
-- =============================================================================

-- Dialog Panels (main UI surfaces)
Theme.components = {
	dialogPanel = {
		backgroundColor = Theme.colors.offWhite,
		borderColor = Theme.colors.bellGold,
		borderWidth = 3,
		cornerRadius = Theme.radius.large,
		shadow = Theme.shadows.large,
	},

	-- Primary Buttons (AC dialog choices)
	primaryButton = {
		backgroundColor = Theme.colors.buttonBrown,
		textColor = Theme.colors.textLight,
		hoverColor = Color3.fromRGB(141, 110, 99),  -- Lighter brown
		pressedColor = Color3.fromRGB(93, 64, 55),  -- Darker brown
		cornerRadius = Theme.radius.medium,
		font = Theme.fonts.bold,
		textSize = Theme.textSizes.medium,
		padding = UDim.new(0, Theme.spacing.lg),
	},

	-- Secondary Buttons
	secondaryButton = {
		backgroundColor = Theme.colors.eggshell,
		borderColor = Theme.colors.buttonBrown,
		borderWidth = 2,
		textColor = Theme.colors.buttonBrown,
		hoverColor = Theme.colors.cream,
		pressedColor = Theme.colors.warmYellow,
		cornerRadius = Theme.radius.medium,
		font = Theme.fonts.primary,
		textSize = Theme.textSizes.medium,
		padding = UDim.new(0, Theme.spacing.lg),
	},

	-- Close Buttons (consistent red X)
	closeButton = {
		backgroundColor = Theme.colors.notificationRed,
		textColor = Theme.colors.textLight,
		hoverColor = Color3.fromRGB(211, 47, 47),  -- Darker red
		pressedColor = Color3.fromRGB(183, 28, 28), -- Even darker red
		cornerRadius = Theme.radius.small,
		font = Theme.fonts.bold,
		textSize = Theme.textSizes.medium,
		size = UDim2.new(0, 32, 0, 32),
	},

	-- Loading Indicators
	loadingIndicator = {
		backgroundColor = Theme.colors.skyBlue,
		progressColor = Theme.colors.leafGreen,
		textColor = Theme.colors.textPrimary,
		cornerRadius = Theme.radius.medium,
		font = Theme.fonts.primary,
		textSize = Theme.textSizes.small,
	},

	-- Toast Notifications
	toastCard = {
		backgroundColor = Theme.colors.eggshell,
		borderColor = Theme.colors.lightBrown,
		borderWidth = 2,
		textColor = Theme.colors.textPrimary,
		cornerRadius = Theme.radius.medium,
		font = Theme.fonts.primary,
		textSize = Theme.textSizes.small,
		shadow = Theme.shadows.medium,
	},

	-- Speaker Name Tags (dialog)
	speakerTag = {
		backgroundColor = Theme.colors.warmYellow,
		textColor = Theme.colors.buttonBrown,
		cornerRadius = Theme.radius.small,
		font = Theme.fonts.bold,
		textSize = Theme.textSizes.small,
		shadow = Theme.shadows.small,
	},

	-- HUD Elements (time, currency, etc.)
	hudPanel = {
		backgroundColor = Theme.colors.eggshell,
		borderColor = Theme.colors.lightBrown,
		borderWidth = 2,
		textColor = Theme.colors.textPrimary,
		cornerRadius = Theme.radius.medium,
		font = Theme.fonts.primary,
		textSize = Theme.textSizes.small,
		shadow = Theme.shadows.small,
	},
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Apply standard shadow to a frame
function Theme.applyShadow(frame: Frame, shadowType: string)
	local shadow = Instance.new("Frame")
	shadow.Name = "ThemeShadow"
	shadow.Size = UDim2.new(1, Theme.shadows[shadowType].Blur * 2, 1, Theme.shadows[shadowType].Blur * 2)
	shadow.Position = UDim2.new(0.5, Theme.shadows[shadowType].Offset.X, 0.5, Theme.shadows[shadowType].Offset.Y)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundColor3 = Theme.shadows[shadowType].Color
	shadow.BackgroundTransparency = Theme.shadows[shadowType].Transparency
	shadow.BorderSizePixel = 0
	shadow.ZIndex = -1
	shadow.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.radius.large
	corner.Parent = shadow
end

-- Apply standard stroke to a frame
function Theme.applyStroke(frame: Frame, color: Color3, thickness: number)
	local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 2
	stroke.Parent = frame
	return stroke
end

-- Apply standard corner radius to a frame
function Theme.applyCornerRadius(frame: Frame, radiusType: string)
	local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = Theme.radius[radiusType]
	corner.Parent = frame
	return corner
end

-- Create a standard dialog panel
function Theme.createDialogPanel(parent: Instance): Frame
	local panel = Instance.new("Frame")
	panel.Name = "DialogPanel"
	panel.Size = UDim2.new(0.8, 0, 0.6, 0)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Theme.components.dialogPanel.backgroundColor
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Parent = parent

	-- Apply theme styling
	Theme.applyCornerRadius(panel, "large")
	Theme.applyStroke(panel, Theme.components.dialogPanel.borderColor, Theme.components.dialogPanel.borderWidth)
	Theme.applyShadow(panel, "large")

	return panel
end

-- Create a standard primary button
function Theme.createPrimaryButton(parent: Instance, text: string): TextButton
	local button = Instance.new("TextButton")
	button.Name = "PrimaryButton"
	button.Size = UDim2.new(0, 200, 0, 48)
	button.BackgroundColor3 = Theme.components.primaryButton.backgroundColor
	button.Text = text
	button.TextColor3 = Theme.components.primaryButton.textColor
	button.Font = Theme.components.primaryButton.font
	button.TextSize = Theme.components.primaryButton.textSize
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Parent = parent

	-- Apply theme styling
	Theme.applyCornerRadius(button, "medium")

	-- Add hover/press effects
	local originalColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Theme.components.primaryButton.hoverColor
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = originalColor
	end)
	button.MouseButton1Down:Connect(function()
		button.BackgroundColor3 = Theme.components.primaryButton.pressedColor
	end)
	button.MouseButton1Up:Connect(function()
		button.BackgroundColor3 = Theme.components.primaryButton.hoverColor
	end)

	return button
end

-- Create a standard close button
function Theme.createCloseButton(parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.Name = "CloseButton"
	button.Size = Theme.components.closeButton.size
	button.Position = UDim2.new(1, -40, 0, 10)
	button.AnchorPoint = Vector2.new(1, 0)
	button.BackgroundColor3 = Theme.components.closeButton.backgroundColor
	button.Text = "✕"
	button.TextColor3 = Theme.components.closeButton.textColor
	button.Font = Theme.components.closeButton.font
	button.TextSize = Theme.components.closeButton.textSize
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Parent = parent

	-- Apply theme styling
	Theme.applyCornerRadius(button, "small")

	-- Add hover/press effects
	local originalColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Theme.components.closeButton.hoverColor
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = originalColor
	end)
	button.MouseButton1Down:Connect(function()
		button.BackgroundColor3 = Theme.components.closeButton.pressedColor
	end)
	button.MouseButton1Up:Connect(function()
		button.BackgroundColor3 = Theme.components.closeButton.hoverColor
	end)

	return button
end

return Theme
