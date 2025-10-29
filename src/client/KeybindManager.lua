-- KeybindManager.lua
-- Centralized keybind mapping system for Animal Crossing CE
-- Supports easy addition and modification of keybinds

local KeybindManager = {}
KeybindManager.__index = KeybindManager

-- Define all keybinds in one place
KeybindManager.KEYBINDS = {
	-- Inventory & Items
	INVENTORY = Enum.KeyCode.E,
	DROP_ITEM = Enum.KeyCode.Q,
	
	-- Reactions
	REACTION = Enum.KeyCode.R,
	
	-- Tools & Crafting
	CRAFTING = Enum.KeyCode.Tab,
	TOOL_WHEEL = Enum.KeyCode.T,
	
	-- Navigation
	MAP = Enum.KeyCode.M,
	
	-- Debug
	DEBUG_GUI = Enum.KeyCode.G,
	
	-- Future binds (placeholder)
	EMOTE = Enum.KeyCode.V,
	SETTINGS = Enum.KeyCode.Escape,
}

-- Keybind callback handlers
KeybindManager.HANDLERS = {}

function KeybindManager.new()
	local self = setmetatable({}, KeybindManager)
	self.connections = {}
	self.activeBinds = {} -- Track which binds are registered
	return self
end

-- Register a keybind handler
function KeybindManager:registerBind(bindName, callback)
	if not self.KEYBINDS[bindName] then
		warn("[KeybindManager] Unknown bind name: " .. bindName)
		return false
	end
	
	self.HANDLERS[bindName] = callback
	self.activeBinds[bindName] = true
	
	print("[KeybindManager] ✅ Registered keybind: " .. bindName .. " (" .. tostring(self.KEYBINDS[bindName]) .. ")")
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
	-- InputBegan - key down
	local inputBeganConnection = userInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		
		-- Check each registered bind
		for bindName, keyCode in pairs(self.KEYBINDS) do
			if input.KeyCode == keyCode and self.HANDLERS[bindName] then
				local handler = self.HANDLERS[bindName]
				local success, err = pcall(function()
					handler("began")
				end)
				
				if not success then
					warn("[KeybindManager] Error in handler for " .. bindName .. ": " .. err)
				end
			end
		end
	end)
	
	-- InputEnded - key released
	local inputEndedConnection = userInputService.InputEnded:Connect(function(input, gameProcessed)
		-- Check each registered bind
		for bindName, keyCode in pairs(self.KEYBINDS) do
			if input.KeyCode == keyCode and self.HANDLERS[bindName] then
				-- Call with optional "ended" event (not all handlers need to respond)
				local handler = self.HANDLERS[bindName]
				if handler then
					local success, err = pcall(function()
						handler("ended")
					end)
					
					if not success then
						warn("[KeybindManager] Error in handler for " .. bindName .. ": " .. err)
					end
				end
			end
		end
	end)
	
	table.insert(self.connections, inputBeganConnection)
	table.insert(self.connections, inputEndedConnection)
	
	print("[KeybindManager] ✅ Input connections established")
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
	for bindName, keyCode in pairs(self.KEYBINDS) do
		local status = self.activeBinds[bindName] and "✅ ACTIVE" or "❌ INACTIVE"
		print(status .. " | " .. bindName .. " → " .. tostring(keyCode))
	end
	print("========================\n")
end

return KeybindManager