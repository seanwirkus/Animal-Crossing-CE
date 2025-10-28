-- Roblox globals
local game = game

-- Import services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Load modules (they are children of this script)
print("[Client] Loading modules from script children...")
print("[Client] Script children:", script:GetChildren())

local InventoryClient = require(script.InventoryClient)
print("[Client] ✅ InventoryClient loaded")

local KeybindManager = require(script.KeybindManager)
print("[Client] ✅ KeybindManager loaded")

local DebugInventoryGridModule = require(script.DebugInventoryGrid)
print("[Client] ✅ DebugInventoryGrid module loaded")

local DebugCraftingMenuModule = require(script.DebugCraftingMenu)
print("[Client] ✅ DebugCraftingMenu module loaded")

-- Initialize InventoryClient
local inventoryClient = InventoryClient.init()
print("[Client] ✅ InventoryClient initialized")

-- Setup KeybindManager
local keybindManager = KeybindManager.new()
print("[Client] ✅ KeybindManager created")

-- Create DebugInventoryGrid instance (not needed as we use static methods)
-- local debugGrid = DebugInventoryGridModule.new()
print("[Client] ✅ DebugInventoryGrid ready")

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
		DebugCraftingMenuModule.toggleGlobal()
	end
end)

-- Register TOOL_WHEEL keybind (Space)
keybindManager:registerBind("TOOL_WHEEL", function(inputState)
	if inputState == "began" then
		print("[Keybind] Tool wheel triggered (Space key)")
	end
end)

-- Register DEBUG_GRID keybind (G key)
keybindManager:registerBind("DEBUG_GRID", function(inputState)
	if inputState == "began" then
		print("[Keybind] Item browser toggled (G key)")
		DebugInventoryGridModule.toggleGlobal()
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
