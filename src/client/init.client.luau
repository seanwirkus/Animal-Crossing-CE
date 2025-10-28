print("[Client] Script started - script:", script)
print("[Client] script.Name:", script.Name)
print("[Client] script.Parent:", script.Parent)
print("[Client] Children of script:", script:GetChildren())

-- Debug: list what's in THIS script (should show modules as children)
for i, child in ipairs(script:GetChildren()) do
	print("[Client]   [" .. i .. "] " .. child.Name .. " (" .. child.ClassName .. ")")
end

-- Modules are children of the Client script itself
local InventoryClient = require(script.InventoryClient)
print("[Client] ✅ InventoryClient loaded")

local KeybindManager = require(script.KeybindManager)
print("[Client] ✅ KeybindManager loaded")

local UserInputService = game:GetService("UserInputService")
print("[Client] ✅ UserInputService loaded")

-- Initialize InventoryClient
local inventoryClient = InventoryClient.init()
print("[Client] ✅ InventoryClient initialized")

-- Setup KeybindManager
local keybindManager = KeybindManager.new()
print("[Client] ✅ KeybindManager created")

-- Register INVENTORY keybind (E key)
keybindManager:registerBind("INVENTORY", function(inputState)
	if inputState == "began" then
		inventoryClient:setInventoryVisible(not inventoryClient.visible)
		if inventoryClient.visible then
			inventoryClient:requestInventory()
		end
		print("[Keybind] Inventory toggled: " .. tostring(inventoryClient.visible))
	end
end)

-- Register REACTION keybind (R key)
keybindManager:registerBind("REACTION", function(inputState)
	if inputState == "began" then
		print("[Keybind] Reaction triggered (R key)")
	end
end)

-- Register CRAFTING keybind (Tab)
keybindManager:registerBind("CRAFTING", function(inputState)
	if inputState == "began" then
		print("[Keybind] Crafting menu triggered (Tab key)")
	end
end)

-- Register TOOL_WHEEL keybind (Space)
keybindManager:registerBind("TOOL_WHEEL", function(inputState)
	if inputState == "began" then
		print("[Keybind] Tool wheel triggered (Space key)")
	end
end)

-- Connect all keybinds to input events
keybindManager:connect(UserInputService)
print("[Client] ✅ Keybinds connected")

-- Print debug reference
keybindManager:printKeybindReference()

-- Store globally for debugging
_G.KeybindManager = keybindManager
_G.InventoryClient = inventoryClient
print("[Client] ✅ All systems ready!")
