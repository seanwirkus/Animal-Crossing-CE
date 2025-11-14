--[[
	KeybindSymbols.luau
	
	Maps Enum.KeyCode to display symbols for UI components.
	Provides symbols for keybind buttons and tooltips.
]]

local KeybindSymbols = {}

-- Map key codes to display symbols
local KEY_SYMBOLS = {
    [Enum.KeyCode.E] = "E",
    [Enum.KeyCode.C] = "C",
    [Enum.KeyCode.T] = "T",
    [Enum.KeyCode.P] = "P",
    [Enum.KeyCode.R] = "R",
    [Enum.KeyCode.B] = "B",
    [Enum.KeyCode.G] = "G",
    [Enum.KeyCode.X] = "X",
    [Enum.KeyCode.N] = "N",
    [Enum.KeyCode.F1] = "F1",
    [Enum.KeyCode.M] = "M",
    [Enum.KeyCode.V] = "V",
    [Enum.KeyCode.Q] = "Q",
    [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.F9] = "F9",
    [Enum.KeyCode.LeftShift] = "SHIFT",
    [Enum.KeyCode.RightShift] = "SHIFT",
    [Enum.KeyCode.LeftControl] = "CTRL",
    [Enum.KeyCode.RightControl] = "CTRL",
    [Enum.KeyCode.LeftAlt] = "ALT",
    [Enum.KeyCode.RightAlt] = "ALT",
    [Enum.KeyCode.Space] = "SPACE",
    [Enum.KeyCode.Return] = "ENTER",
    [Enum.KeyCode.Tab] = "TAB",
    [Enum.KeyCode.Backspace] = "⌫",
    [Enum.KeyCode.Delete] = "DEL",
    [Enum.KeyCode.Up] = "↑",
    [Enum.KeyCode.Down] = "↓",
    [Enum.KeyCode.Left] = "←",
    [Enum.KeyCode.Right] = "→",
}

--[[
	Get display symbol for a key code
	@param keyCode Enum.KeyCode - The key code to get symbol for
	@return string - Display symbol or key name
]]
function KeybindSymbols.getSymbol(keyCode)
    if not keyCode then
        return "?"
    end

    local symbol = KEY_SYMBOLS[keyCode]
    if symbol then
        return symbol
    end

    -- Fallback to key name
    local keyName = tostring(keyCode)
    -- Remove "KeyCode." prefix if present
    if keyName:find("KeyCode.") then
        keyName = keyName:gsub("KeyCode.", "")
    end
    return keyName:upper()
end

--[[
	Get display text for a keybind name
	@param bindName string - Keybind name (e.g., "INVENTORY")
	@param keybinds table - Keybinds table from KeybindManager
	@return string - Display symbol
]]
function KeybindSymbols.getSymbolForBind(bindName, keybinds)
    if not bindName or not keybinds then
        return "?"
    end

    local keyCode = keybinds[bindName]
    if not keyCode then
        return "?"
    end

    return KeybindSymbols.getSymbol(keyCode)
end

return KeybindSymbols
