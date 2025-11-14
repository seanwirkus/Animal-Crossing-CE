--[[
	ThemeProvider.lua

	Context provider for theme access across all GUI components.
	Provides centralized theme management and ensures consistent styling.
]]

local Theme = require(script.Parent.Theme)

local ThemeProvider = {}

-- =============================================================================
-- THEME CONTEXT MANAGEMENT
-- =============================================================================

local _currentTheme = Theme
local _themeListeners = {}

-- Get current theme
function ThemeProvider.getTheme()
    return _currentTheme
end

-- Set custom theme (for future extensibility)
function ThemeProvider.setTheme(newTheme)
    _currentTheme = newTheme
    -- Notify listeners of theme change
    for _, listener in ipairs(_themeListeners) do
        if typeof(listener) == "function" then
            task.spawn(function()
                local success, err = pcall(listener, newTheme)
                if not success then
                    warn("[ThemeProvider] Theme change listener failed:", err)
                end
            end)
        end
    end
end

-- Add theme change listener
function ThemeProvider.onThemeChanged(listener)
    table.insert(_themeListeners, listener)
    return function()
        -- Return cleanup function
        local index = table.find(_themeListeners, listener)
        if index then
            table.remove(_themeListeners, index)
        end
    end
end

-- =============================================================================
-- CONVENIENCE ACCESSORS
-- =============================================================================

-- Get color by name
function ThemeProvider.getColor(colorName)
    local color = _currentTheme.colors[colorName] or _currentTheme.colors.offWhite
    print(string.format("[ThemeProvider] 🎨 getColor('%s') -> %s", colorName, tostring(color)))
    return color
end

-- Get radius by name
function ThemeProvider.getRadius(radiusName)
    return _currentTheme.radius[radiusName] or _currentTheme.radius.medium
end

-- Get spacing by name
function ThemeProvider.getSpacing(spacingName)
    return _currentTheme.spacing[spacingName] or _currentTheme.spacing.md
end

-- Get text size by name
function ThemeProvider.getTextSize(sizeName)
    return _currentTheme.textSizes[sizeName] or _currentTheme.textSizes.medium
end

-- Get font by name
function ThemeProvider.getFont(fontName)
    return _currentTheme.fonts[fontName] or _currentTheme.fonts.primary
end

-- =============================================================================
-- COMPONENT CREATION HELPERS
-- =============================================================================

-- Create themed dialog panel
function ThemeProvider.createDialogPanel(parent, config)
    config = config or {}
    local panel = _currentTheme.createDialogPanel(parent)

    -- Apply custom config
    if config.size then
        panel.Size = config.size
    end
    if config.position then
        panel.Position = config.position
    end
    if config.anchorPoint then
        panel.AnchorPoint = config.anchorPoint
    end

    return panel
end

-- Create themed primary button
function ThemeProvider.createPrimaryButton(parent, text, config)
    config = config or {}
    local button = _currentTheme.createPrimaryButton(parent, text)

    -- Apply custom config
    if config.size then
        button.Size = config.size
    end
    if config.position then
        button.Position = config.position
    end
    if config.onClick and typeof(config.onClick) == "function" then
        button.MouseButton1Click:Connect(config.onClick)
    end

    return button
end

-- Create themed close button
function ThemeProvider.createCloseButton(parent, config)
    config = config or {}
    local button = _currentTheme.createCloseButton(parent)

    -- Apply custom config
    if config.position then
        button.Position = config.position
    end
    if config.anchorPoint then
        button.AnchorPoint = config.anchorPoint
    end
    if config.onClick and typeof(config.onClick) == "function" then
        button.MouseButton1Click:Connect(config.onClick)
    end

    return button
end

-- =============================================================================
-- BATCH STYLING HELPERS
-- =============================================================================

-- Apply theme to a frame (colors, corners, shadows)
function ThemeProvider.styleFrame(frame, styleConfig)
    styleConfig = styleConfig or {}

    -- Get config keys for logging
    local configKeys = {}
    for key, _ in pairs(styleConfig) do
        table.insert(configKeys, tostring(key))
    end
    print(
        string.format(
            "[ThemeProvider] 🎨 styleFrame called on %s with config keys: %s",
            frame.Name,
            table.concat(configKeys, ", ")
        )
    )

    -- Background color
    if styleConfig.backgroundColor then
        frame.BackgroundColor3 = typeof(styleConfig.backgroundColor) == "string"
                and ThemeProvider.getColor(styleConfig.backgroundColor)
            or styleConfig.backgroundColor
    end

    -- Corner radius
    if styleConfig.cornerRadius then
        local radiusType = typeof(styleConfig.cornerRadius) == "string" and styleConfig.cornerRadius or "medium"
        _currentTheme.applyCornerRadius(frame, radiusType)
    end

    -- Stroke/border
    if styleConfig.strokeColor then
        local color = typeof(styleConfig.strokeColor) == "string" and ThemeProvider.getColor(styleConfig.strokeColor)
            or styleConfig.strokeColor
        local thickness = styleConfig.strokeThickness or 2
        _currentTheme.applyStroke(frame, color, thickness)
    end

    -- Shadow
    if styleConfig.shadow then
        local shadowType = typeof(styleConfig.shadow) == "string" and styleConfig.shadow or "medium"
        _currentTheme.applyShadow(frame, shadowType)
    end
end

-- Apply theme to text labels
function ThemeProvider.styleText(textObject, styleConfig)
    styleConfig = styleConfig or {}

    -- Get config keys for logging
    local configKeys = {}
    for key, _ in pairs(styleConfig) do
        table.insert(configKeys, tostring(key))
    end
    print(
        string.format(
            "[ThemeProvider] 🎨 styleText called on %s with config keys: %s",
            textObject.Name,
            table.concat(configKeys, ", ")
        )
    )

    -- Text color
    if styleConfig.textColor then
        textObject.TextColor3 = typeof(styleConfig.textColor) == "string"
                and ThemeProvider.getColor(styleConfig.textColor)
            or styleConfig.textColor
    end

    -- Font
    if styleConfig.font then
        textObject.Font = typeof(styleConfig.font) == "string" and ThemeProvider.getFont(styleConfig.font)
            or styleConfig.font
    end

    -- Text size
    if styleConfig.textSize then
        textObject.TextSize = typeof(styleConfig.textSize) == "string"
                and ThemeProvider.getTextSize(styleConfig.textSize)
            or styleConfig.textSize
    end

    -- Text stroke (subtle shadow for readability)
    if styleConfig.textStroke ~= false then
        textObject.TextStrokeTransparency = 0.8
        textObject.TextStrokeColor3 = ThemeProvider.getColor("textLight")
    end
end

-- =============================================================================
-- LEGACY COMPATIBILITY
-- =============================================================================

-- Direct access to theme for backward compatibility
ThemeProvider.colors = _currentTheme.colors
ThemeProvider.radius = _currentTheme.radius
ThemeProvider.fonts = _currentTheme.fonts
ThemeProvider.textSizes = _currentTheme.textSizes
ThemeProvider.spacing = _currentTheme.spacing
ThemeProvider.shadows = _currentTheme.shadows
ThemeProvider.components = _currentTheme.components

-- Direct access to utility functions
ThemeProvider.applyShadow = _currentTheme.applyShadow
ThemeProvider.applyStroke = _currentTheme.applyStroke
ThemeProvider.applyCornerRadius = _currentTheme.applyCornerRadius

return ThemeProvider
