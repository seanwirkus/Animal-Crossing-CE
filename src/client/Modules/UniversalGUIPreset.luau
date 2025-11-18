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
    -- Skip elements that are already styled (performance optimization)
    if element:GetAttribute("UniversalStyled") then
        return false
    end

    -- Skip elements that are part of theme shadows or special effects
    if element.Name:find("ThemeShadow") or element.Name:find("LS_") then
        return false
    end

    -- Skip elements that already have custom styling
    if element:GetAttribute("CustomStyled") then
        return false
    end

    -- Skip inventory slots to prevent overriding item display
    -- Check if element is part of inventory system
    local parent = element.Parent
    while parent do
        if parent.Name == "InventoryItems" or parent.Name == "InventoryFrame" then
            return false
        end
        parent = parent.Parent
    end
    if element.Name:find("Slot_") or element.Name == "ItemSlotTemplate" or element.Name == "ItemIcon" then
        return false
    end

    return true
end

-- Apply preset to a single element
local function applyPresetToElement(element)
    if not shouldStyleElement(element) then
        return false
    end

    local preset = UNIVERSAL_PRESETS[element.ClassName]
    if not preset then
        return false
    end

    -- Removed excessive logging for performance (was logging every element)

    -- Apply styling based on element type
    local success, err = pcall(function()
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
    end)

    if not success then
        warn("[UniversalGUIPreset] Failed to style", element.Name, ":", err)
        return false
    end

    -- Mark as styled to prevent re-styling
    element:SetAttribute("UniversalStyled", true)
    return true
end

-- Recursively apply presets to all descendants
local function applyPresetsRecursive(parent)
    -- Check if parent is already styled before processing
    if parent:GetAttribute("UniversalStyled") then
        return -- Skip entire subtree if already styled
    end

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

    -- Handle module objects that have a .gui property (like EmoteWheel)
    local actualGUI = guiObject
    if typeof(guiObject) ~= "Instance" then
        if typeof(guiObject) == "table" and guiObject.gui then
            actualGUI = guiObject.gui
        else
            warn(string.format("[UniversalGUIPreset] ⚠️ guiObject is not an Instance and has no .gui property (type: %s)", typeof(guiObject)))
            return
        end
    end

    if not actualGUI or not actualGUI:IsA("Instance") then
        warn("[UniversalGUIPreset] ⚠️ actualGUI is not a valid Instance")
        return
    end

    -- Reduced logging for performance (only log once per GUI, not per element)

    -- Handle different GUI object types
    if actualGUI:IsA("ScreenGui") then
        -- Apply ScreenGui presets
        local sgPreset = UNIVERSAL_PRESETS.ScreenGui
        if sgPreset.IgnoreGuiInset ~= nil then
            actualGUI.IgnoreGuiInset = sgPreset.IgnoreGuiInset
        end
        if sgPreset.ZIndexBehavior then
            actualGUI.ZIndexBehavior = sgPreset.ZIndexBehavior
        end

        -- Apply to all descendants
        for _, child in ipairs(actualGUI:GetChildren()) do
            applyPresetsRecursive(child)
        end
    else
        -- Apply to the object and its descendants
        applyPresetsRecursive(actualGUI)
    end

    local duration = os.clock() - startTime
    -- Only log if it takes significant time (>0.1s) to reduce console spam
    if duration > 0.1 then
        print(string.format("[UniversalGUIPreset] ✅ Applied to %s in %.3fs", actualGUI.Name or "Unknown", duration))
    end
end

-- Apply presets to all registered GUIs (called by GUIManager to avoid circular dependency)
function UniversalGUIPreset.applyToRegisteredGUIs(registry)
    local startTime = os.clock()

    -- Reduced logging for performance

    local appliedCount = 0
    for name, guiData in pairs(registry) do
        if guiData and guiData.object then
            UniversalGUIPreset.applyToGUI(guiData.object)
            appliedCount += 1
        end
    end

    local duration = os.clock() - startTime
    -- Only log if it takes significant time or if many GUIs were processed
    if duration > 0.1 or appliedCount > 5 then
        print(string.format("[UniversalGUIPreset] ✅ Applied to %d GUIs in %.3fs", appliedCount, duration))
    end
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
    -- Reduced logging for performance
end

return UniversalGUIPreset
