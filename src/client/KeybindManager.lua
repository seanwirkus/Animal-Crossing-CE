-- KeybindManager.lua
-- Centralized keybind mapping system for Animal Crossing CE

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
    PREMIUM_SHOP = Enum.KeyCode.F2,

    -- Navigation
    MAP = Enum.KeyCode.M,

    -- Settings
    SETTINGS = Enum.KeyCode.Escape,

    -- Menus
    GAME_MENU = Enum.KeyCode.Tilde,
    KEYBIND_GUIDE = Enum.KeyCode.F1,

    -- Future binds
    EMOTE = Enum.KeyCode.V,

    -- Item Browser
    ITEM_BROWSER = Enum.KeyCode.B,

    -- Building interface
    BUILD = Enum.KeyCode.H,

    -- Quests
    QUESTS = Enum.KeyCode.J,
}

-- Debug keybinds (only active in debug mode)
KeybindManager.DEBUG_KEYBINDS = {
    DEBUG_GUI = Enum.KeyCode.G,
    DEBUG_DELETE = Enum.KeyCode.X,
    TEST_PLANE = Enum.KeyCode.F9,
    QUEST_BOARD = Enum.KeyCode.Q,
    START_ONBOARDING = Enum.KeyCode.N,
}

KeybindManager._debugMode = false
KeybindManager.HANDLERS = {}

function KeybindManager.new()
    local self = setmetatable({}, KeybindManager)
    self.connections = {}
    self.activeBinds = {}
    self._debugMode = false
    return self
end

function KeybindManager:setDebugMode(enabled)
    self._debugMode = enabled
    KeybindManager._debugMode = enabled
end

function KeybindManager:isDebugMode()
    return self._debugMode
end

function KeybindManager:registerBind(bindName, callback)
    local keyCode = self.KEYBINDS[bindName] or self.DEBUG_KEYBINDS[bindName]
    if not keyCode then
        warn("[KeybindManager] Unknown bind name: " .. bindName)
        return false
    end

    self.HANDLERS[bindName] = callback
    self.activeBinds[bindName] = true
    return true
end

function KeybindManager:unregisterBind(bindName)
    self.HANDLERS[bindName] = nil
    self.activeBinds[bindName] = false
end

function KeybindManager:connect(userInputService)
    if not userInputService then
        warn("[KeybindManager] UserInputService is nil")
        return false
    end

    local inputBeganConnection = userInputService.InputBegan:Connect(function(input, gameProcessed)
        if not input.KeyCode or gameProcessed then
            return
        end

        -- Check normal keybinds
        for bindName, keyCode in pairs(self.KEYBINDS) do
            if input.KeyCode == keyCode and self.HANDLERS[bindName] then
                local success, err = pcall(function()
                    self.HANDLERS[bindName]("began")
                end)
                if not success then
                    warn("[KeybindManager] Error in handler for " .. bindName .. ": " .. tostring(err))
                end
            end
        end

        -- Check debug keybinds
        if self._debugMode then
            for bindName, keyCode in pairs(self.DEBUG_KEYBINDS) do
                if input.KeyCode == keyCode and self.HANDLERS[bindName] then
                    local success, err = pcall(function()
                        self.HANDLERS[bindName]("began")
                    end)
                    if not success then
                        warn("[KeybindManager] Error in handler for " .. bindName .. ": " .. tostring(err))
                    end
                end
            end
        end
    end)

    local inputEndedConnection = userInputService.InputEnded:Connect(function(input, gameProcessed)
        if not input.KeyCode or gameProcessed then
            return
        end

        -- Check normal keybinds
        for bindName, keyCode in pairs(self.KEYBINDS) do
            if input.KeyCode == keyCode and self.HANDLERS[bindName] then
                local success, err = pcall(function()
                    self.HANDLERS[bindName]("ended")
                end)
                if not success then
                    warn("[KeybindManager] Error in handler for " .. bindName .. ": " .. tostring(err))
                end
            end
        end

        -- Check debug keybinds
        if self._debugMode then
            for bindName, keyCode in pairs(self.DEBUG_KEYBINDS) do
                if input.KeyCode == keyCode and self.HANDLERS[bindName] then
                    local success, err = pcall(function()
                        self.HANDLERS[bindName]("ended")
                    end)
                    if not success then
                        warn("[KeybindManager] Error in handler for " .. bindName .. ": " .. tostring(err))
                    end
                end
            end
        end
    end)

    table.insert(self.connections, inputBeganConnection)
    table.insert(self.connections, inputEndedConnection)
    return true
end

function KeybindManager:disconnect()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
end

function KeybindManager:getActiveBinds()
    local active = {}
    for bindName, _ in pairs(self.activeBinds) do
        if self.activeBinds[bindName] then
            table.insert(active, bindName)
        end
    end
    return active
end

function KeybindManager:printKeybindReference()
    print("\n=== KEYBIND REFERENCE ===")
    print("--- NORMAL KEYBINDS ---")
    for bindName, keyCode in pairs(self.KEYBINDS) do
        local status = self.activeBinds[bindName] and "ACTIVE" or "INACTIVE"
        print(status .. " | " .. bindName .. " -> " .. tostring(keyCode))
    end
    print("--- DEBUG KEYBINDS (Debug Mode: " .. (self._debugMode and "ON" or "OFF") .. ") ---")
    for bindName, keyCode in pairs(self.DEBUG_KEYBINDS) do
        local status = (self.activeBinds[bindName] and self._debugMode) and "ACTIVE" or "INACTIVE"
        print(status .. " | " .. bindName .. " -> " .. tostring(keyCode))
    end
    print("========================\n")
end

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
