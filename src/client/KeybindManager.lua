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
	CRAFTING = Enum.KeyCode.C,  -- Changed from Tab to C for DebugCraftingMenu
	TOOL_WHEEL = Enum.KeyCode.T,
	
	-- Navigation
	MAP = Enum.KeyCode.M,
	
	-- Debug
	DEBUG_GUI = Enum.KeyCode.G,         -- G for Debug Manager  
	ITEM_BROWSER = Enum.KeyCode.B,      -- B for Item Browser
	QUEST_BOARD = Enum.KeyCode.Q,       -- Q for Quest Board (if needed later)
	
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
		local debugKeys = {Enum.KeyCode.E, Enum.KeyCode.G, Enum.KeyCode.C, Enum.KeyCode.R, Enum.KeyCode.B}
		for _, key in ipairs(debugKeys) do
			if input.KeyCode == key then
				print("[KeybindManager] 🔑 Key pressed:", input.KeyCode, "gameProcessed:", gameProcessed)
				break
			end
		end
		
		-- Check each registered bind
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
						warn("[KeybindManager] ❌ Error in handler for " .. bindName .. ": " .. tostring(err))
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
	for bindName, keyCode in pairs(self.KEYBINDS) do
		local status = self.activeBinds[bindName] and "✅ ACTIVE" or "❌ INACTIVE"
		print(status .. " | " .. bindName .. " → " .. tostring(keyCode))
	end
	print("========================\n")
end

return KeybindManager