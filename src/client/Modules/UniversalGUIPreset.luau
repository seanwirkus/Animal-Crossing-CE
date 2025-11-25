--[[
	UniversalGUIPreset.luau

	STYLING OVERRIDES REMOVED as requested
	No longer applies universal theme presets to GUI elements
]]

local UniversalGUIPreset = {}

-- =============================================================================
-- ALL STYLING OVERRIDES REMOVED - NO LONGER APPLIES THEMES
-- =============================================================================

-- Function that does nothing - styling overrides removed
function UniversalGUIPreset.applyToGUI(guiObject)
    -- No longer applies any styling
    return
end

-- Function that does nothing - styling overrides removed
function UniversalGUIPreset.applyToRegisteredGUIs(registry)
    -- No longer applies any styling
    return
end

-- Function that does nothing - styling overrides removed
function UniversalGUIPreset.refreshGUI(guiObject)
    -- No longer applies any styling
    return
end

-- Function that returns nil - no presets
function UniversalGUIPreset.getPreset(className)
    return nil
end

-- Function that does nothing - no longer sets presets
function UniversalGUIPreset.setPreset(className, preset)
    -- No longer sets presets
    return
end

return UniversalGUIPreset
