-- KeybindManager.lua
-- Centralized keybind mapping system for Animal Crossing CE
-- Supports easy addition and modification of keybinds

local KeybindManager = {}
KeybindManager.__index = KeybindManager

-- Normal player keybinds (always active)
KeybindManager.KEYBINDS = {
    -- Inventory & Items
    INVENTORY = Enum.KeyCode.E,
    DROP_ITEM = Enum.KeyCode.Q,

    -- Reactions
    REACTION = Enum.KeyCode.R,

    -- Tools & Crafting
    CRAFTING = Enum.KeyCode.C,
    TOOL_WHEEL = Enum.KeyCode.T,

    -- NookPhone
    NOOK_PHONE = Enum.KeyCode.P,
    -- NOOK_SHOPPING = Enum.KeyCode.S,  -- REMOVED: S key no longer opens Nook Shopping directly
    PREMIUM_SHOP = Enum.KeyCode.F2, -- F2 for Premium Shop (Robux purchases)

    -- Navigation
    MAP = Enum.KeyCode.M,

    -- Settings
    SETTINGS = Enum.KeyCode.Escape,

    -- Menus
    GAME_MENU = Enum.KeyCode.Tilde,
    KEYBIND_GUIDE = Enum.KeyCode.F1,

    -- Future binds (placeholder)
    EMOTE = Enum.KeyCode.V,

    -- Item Browser (always available)
    ITEM_BROWSER = Enum.KeyCode.B, -- B for Item Browser

    -- Building interface
    BUILD = Enum.KeyCode.H, -- H for Housing/Island building

    -- Quests
    QUESTS = Enum.KeyCode.J, -- J for Quests
}

-- Debug keybinds (only active in debug mode)
KeybindManager.DEBUG_KEYBINDS = {
    DEBUG_GUI = Enum.KeyCode.G, -- G for Debug Manager
    DEBUG_DELETE = Enum.KeyCode.X, -- X for Debug Delete (testing)
    TEST_PLANE = Enum.KeyCode.F9, -- F9 to test NookPlane cutscene
    QUEST_BOARD = Enum.KeyCode.Q, -- Q for Quest Board (if needed later)
    START_ONBOARDING = Enum.KeyCode.N, -- N for Onboarding/New island debug
}

-- Debug mode state
KeybindManager._debugMode = false

-- Keybind callback handlers
KeybindManager.HANDLERS = {}

function KeybindManager.new()
    local self = setmetatable({}, KeybindManager)
    self.connections = {}
    self.activeBinds = {} -- Track which binds are registered
    self._debugMode = false -- Debug mode off by default
    return self
end

--[[
	Enable or disable debug mode
	@param enabled boolean - Whether debug mode should be enabled
]]
function KeybindManager:setDebugMode(enabled)
    self._debugMode = enabled
    KeybindManager._debugMode = enabled
    print(string.format("[KeybindManager] Debug mode: %s", enabled and "ENABLED" or "DISABLED"))
end

--[[
	Get whether debug mode is enabled
	@return boolean
]]
function KeybindManager:isDebugMode()
    return self._debugMode
end

-- Register a keybind handler
function KeybindManager:registerBind(bindName, callback)
    local keyCode = self.KEYBINDS[bindName] or self.DEBUG_KEYBINDS[bindName]
    if not keyCode then
        warn("[KeybindManager] Unknown bind name: " .. bindName)
        return false
    end

    self.HANDLERS[bindName] = callback
    self.activeBinds[bindName] = true

    local bindType = self.KEYBINDS[bindName] and "normal" or "debug"
    print(string.format("[KeybindManager] ✅ Registered %s keybind: %s (%s)", bindType, bindName, tostring(keyCode)))
    return true
end

-- Unregister a keybind
function KeybindManager:unregisterBind(bindName)
    self.HANDLERS[bindName] = nil
    self.activeBinds[bindName] = false
    print("[KeybindManager] Unregistered keybind: " .. bindName)
end

-- Connect all keybind handlers to input events
function KeybindManager:connect(userInputService)
    if not userInputService then
        warn("[KeybindManager] ❌ UserInputService is nil!")
        return false
    end

    print("[KeybindManager] 🔗 Connecting to UserInputService...")
    print("[KeybindManager] 📊 Total registered handlers:", #self:getActiveBinds())

    -- InputBegan - key down
    local inputBeganConnection = userInputService.InputBegan:Connect(function(input, gameProcessed)
        -- Only handle keyboard input
        if not input.KeyCode then
            return
        end

        if gameProcessed then
            return
        end

        -- Debug: log key presses for common keys
        local debugKeys = { Enum.KeyCode.E, Enum.KeyCode.G, Enum.KeyCode.C, Enum.KeyCode.R, Enum.KeyCode.B }
        for _, key in ipairs(debugKeys) do
            if input.KeyCode == key then
                print("[KeybindManager] 🔑 Key pressed:", input.KeyCode, "gameProcessed:", gameProcessed)
                break
            end
        end

        -- Check normal keybinds
        for bindName, keyCode in pairs(self.KEYBINDS) do
            if input.KeyCode == keyCode then
                if self.HANDLERS[bindName] then
                    print("[KeybindManager] ✅ Matched keybind:", bindName, "→", keyCode)
                    local handler = self.HANDLERS[bindName]
                    local success, err = pcall(function()
                        handler("began")
                    end)

                    if not success then
                        warn("[KeybindManager] ❌ Error in handler for " .. bindName .. ": " .. tostring(err))
                        warn(debug.traceback())
                    end
                else
                    print("[KeybindManager] ⚠️ Handler missing for:", bindName, "→", keyCode)
                end
            end
        end

        -- Check debug keybinds (only if debug mode is enabled)
        if self._debugMode then
            for bindName, keyCode in pairs(self.DEBUG_KEYBINDS) do
                if input.KeyCode == keyCode then
                    if self.HANDLERS[bindName] then
                        print("[KeybindManager] ✅ Matched debug keybind:", bindName, "→", keyCode)
                        local handler = self.HANDLERS[bindName]
                        local success, err = pcall(function()
                            handler("began")
                        end)

                        if not success then
                            warn("[KeybindManager] ❌ Error in handler for " .. bindName .. ": " .. tostring(err))
                            warn(debug.traceback())
                        end
                    end
                end
            end
        end
    end)

    -- InputEnded - key released
    local inputEndedConnection = userInputService.InputEnded:Connect(function(input, gameProcessed)
        -- Only handle keyboard input
        if not input.KeyCode then
            return
        end

        if gameProcessed then
            return
        end

        -- Check normal keybinds
        for bindName, keyCode in pairs(self.KEYBINDS) do
            if input.KeyCode == keyCode and self.HANDLERS[bindName] then
                local handler = self.HANDLERS[bindName]
                if handler then
                    local success, err = pcall(function()
                        handler("ended")
                    end)

                    if not success then
                        warn("[KeybindManager] ❌ Error in handler for " .. bindName .. ": " .. tostring(err))
                    end
                end
            end
        end

        -- Check debug keybinds (only if debug mode is enabled)
        if self._debugMode then
            for bindName, keyCode in pairs(self.DEBUG_KEYBINDS) do
                if input.KeyCode == keyCode and self.HANDLERS[bindName] then
                    local handler = self.HANDLERS[bindName]
                    if handler then
                        local success, err = pcall(function()
                            handler("ended")
                        end)

                        if not success then
                            warn("[KeybindManager] ❌ Error in handler for " .. bindName .. ": " .. tostring(err))
                        end
                    end
                end
            end
        end
    end)

    table.insert(self.connections, inputBeganConnection)
    table.insert(self.connections, inputEndedConnection)

    print("[KeybindManager] ✅ Input connections established")
    print("[KeybindManager] 📝 Connected to InputBegan and InputEnded events")

    -- Verify connections are active
    if inputBeganConnection and inputBeganConnection.Connected then
        print("[KeybindManager] ✅ InputBegan connection is active")
    else
        warn("[KeybindManager] ❌ InputBegan connection failed!")
    end

    if inputEndedConnection and inputEndedConnection.Connected then
        print("[KeybindManager] ✅ InputEnded connection is active")
    else
        warn("[KeybindManager] ❌ InputEnded connection failed!")
    end

    return true
end

-- Disconnect all keybind handlers
function KeybindManager:disconnect()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
    print("[KeybindManager] Disconnected all keybind handlers")
end

-- Get all active keybinds (for debugging)
function KeybindManager:getActiveBinds()
    local active = {}
    for bindName, _ in pairs(self.activeBinds) do
        if self.activeBinds[bindName] then
            table.insert(active, bindName)
        end
    end
    return active
end

-- Print keybind reference
function KeybindManager:printKeybindReference()
    print("\n=== KEYBIND REFERENCE ===")
    print("--- NORMAL KEYBINDS ---")
    for bindName, keyCode in pairs(self.KEYBINDS) do
        local status = self.activeBinds[bindName] and "✅ ACTIVE" or "❌ INACTIVE"
        print(status .. " | " .. bindName .. " → " .. tostring(keyCode))
    end
    print("--- DEBUG KEYBINDS (Debug Mode: " .. (self._debugMode and "ON" or "OFF") .. ") ---")
    for bindName, keyCode in pairs(self.DEBUG_KEYBINDS) do
        local status = (self.activeBinds[bindName] and self._debugMode) and "✅ ACTIVE" or "❌ INACTIVE"
        print(status .. " | " .. bindName .. " → " .. tostring(keyCode))
    end
    print("========================\n")
end

--[[
	Get all keybinds (normal + debug if enabled)
	@return table - Combined keybinds table
]]
function KeybindManager:getAllKeybinds()
    local all = {}
    for k, v in pairs(self.KEYBINDS) do
        all[k] = v
    end
    if self._debugMode then
        for k, v in pairs(self.DEBUG_KEYBINDS) do
            all[k] = v
        end
    end
    return all
end

return KeybindManager
