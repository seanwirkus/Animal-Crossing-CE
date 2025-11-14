--[[
	UniversalGUIPreset.luau

	Automatically applies universal theme presets to all GUI elements for consistent styling
	and improved responsiveness. Integrates with ThemeProvider to ensure all GUIs follow
	the ACNH style guide.
]]

local ThemeProvider = require(script.Parent.ThemeProvider)

local UniversalGUIPreset = {}

-- =============================================================================
-- PRESET CONFIGURATIONS
-- =============================================================================

-- Universal presets for common GUI element types
local UNIVERSAL_PRESETS = {
    -- ScreenGui containers
    ScreenGui = {
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    },

    -- Main containers
    Frame = {
        backgroundColor = "offWhite",
        cornerRadius = "medium",
    },

    -- Text elements
    TextLabel = {
        textColor = "textPrimary",
        font = "primary",
        textSize = "medium",
        textStroke = true,
    },

    TextButton = {
        textColor = "textLight",
        font = "bold",
        textSize = "medium",
        backgroundColor = "buttonBrown",
        cornerRadius = "medium",
    },

    TextBox = {
        textColor = "textPrimary",
        font = "primary",
        textSize = "medium",
        backgroundColor = "eggshell",
        cornerRadius = "small",
        strokeColor = "lightBrown",
        strokeThickness = 1,
    },

    -- Scrollable areas
    ScrollingFrame = {
        backgroundColor = "eggshell",
        cornerRadius = "medium",
        strokeColor = "lightBrown",
        strokeThickness = 1,
    },

    -- Images
    ImageLabel = {
        backgroundTransparency = 1,
    },

    ImageButton = {
        backgroundTransparency = 1,
    },
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Check if an element should be styled (skip certain containers)
local function shouldStyleElement(element)
    -- Skip elements that are part of theme shadows or special effects
    if element.Name:find("ThemeShadow") or element.Name:find("LS_") then
        return false
    end

    -- Skip elements that already have custom styling
    if element:GetAttribute("CustomStyled") then
        return false
    end

    return true
end

-- Apply preset to a single element
local function applyPresetToElement(element)
    if not shouldStyleElement(element) then
        return
    end

    local preset = UNIVERSAL_PRESETS[element.ClassName]
    if not preset then
        return
    end

    print(string.format("[UniversalGUIPreset] 🎨 Applying preset to %s (%s)", element.Name, element.ClassName))

    -- Apply styling based on element type
    if element:IsA("Frame") then
        ThemeProvider.styleFrame(element, preset)
    elseif element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
        ThemeProvider.styleText(element, preset)
    elseif element:IsA("ScrollingFrame") then
        ThemeProvider.styleFrame(element, preset)
        -- Ensure scroll bars are themed
        element.ScrollBarImageColor3 = ThemeProvider.getColor("darkBrown")
    elseif element:IsA("ImageLabel") or element:IsA("ImageButton") then
        if preset.backgroundTransparency then
            element.BackgroundTransparency = preset.backgroundTransparency
        end
    end

    -- Mark as styled to prevent re-styling
    element:SetAttribute("UniversalStyled", true)
end

-- Recursively apply presets to all descendants
local function applyPresetsRecursive(parent)
    applyPresetToElement(parent)

    for _, child in ipairs(parent:GetChildren()) do
        applyPresetsRecursive(child)
    end
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

-- Apply universal presets to a GUI object
function UniversalGUIPreset.applyToGUI(guiObject)
    local startTime = os.clock()

    if not guiObject then
        warn("[UniversalGUIPreset] ⚠️ guiObject is nil")
        return
    end

    print(string.format("[UniversalGUIPreset] 🎨 Applying universal presets to %s", guiObject.Name or "Unknown"))

    -- Handle different GUI object types
    if guiObject:IsA("ScreenGui") then
        -- Apply ScreenGui presets
        local sgPreset = UNIVERSAL_PRESETS.ScreenGui
        if sgPreset.IgnoreGuiInset ~= nil then
            guiObject.IgnoreGuiInset = sgPreset.IgnoreGuiInset
        end
        if sgPreset.ZIndexBehavior then
            guiObject.ZIndexBehavior = sgPreset.ZIndexBehavior
        end

        -- Apply to all descendants
        for _, child in ipairs(guiObject:GetChildren()) do
            applyPresetsRecursive(child)
        end
    else
        -- Apply to the object and its descendants
        applyPresetsRecursive(guiObject)
    end

    local duration = os.clock() - startTime
    print(string.format("[UniversalGUIPreset] ✅ Universal presets applied in %.3fs", duration))
end

-- Apply presets to all registered GUIs (called by GUIManager to avoid circular dependency)
function UniversalGUIPreset.applyToRegisteredGUIs(registry)
    local startTime = os.clock()

    print("[UniversalGUIPreset] 🎨 Applying universal presets to all registered GUIs")

    local appliedCount = 0
    for name, guiData in pairs(registry) do
        if guiData and guiData.object then
            UniversalGUIPreset.applyToGUI(guiData.object)
            appliedCount += 1
        end
    end

    local duration = os.clock() - startTime
    print(string.format("[UniversalGUIPreset] ✅ Applied to %d GUIs in %.3fs", appliedCount, duration))
end

-- Refresh presets on a GUI (useful for dynamic content)
function UniversalGUIPreset.refreshGUI(guiObject)
    -- Clear existing styling marks
    local function clearMarks(parent)
        parent:SetAttribute("UniversalStyled", nil)
        for _, child in ipairs(parent:GetChildren()) do
            clearMarks(child)
        end
    end

    clearMarks(guiObject)
    UniversalGUIPreset.applyToGUI(guiObject)
end

-- Get preset configuration for a class
function UniversalGUIPreset.getPreset(className)
    return UNIVERSAL_PRESETS[className]
end

-- Add or modify a preset
function UniversalGUIPreset.setPreset(className, preset)
    UNIVERSAL_PRESETS[className] = preset
    print(string.format("[UniversalGUIPreset] 📝 Updated preset for %s", className))
end

return UniversalGUIPreset
