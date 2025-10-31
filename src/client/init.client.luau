-- Roblox globals
local game = game

-- Import services
local _Players = game:GetService("Players")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local _RunService = game:GetService("RunService")

-- Load modules (they are children of this script)
print("[Client] Loading modules from script children...")
print("[Client] Script children:", script:GetChildren())

local InventoryClient = require(script.InventoryClient)
print("[Client] ✅ InventoryClient loaded")

local InventoryGuiSetup = require(script.Modules.InventoryGuiSetup)
print("[Client] ✅ InventoryGuiSetup loaded")

local KeybindManager = require(script.KeybindManager)
print("[Client] ✅ KeybindManager loaded")

local DebugInventoryGridModule = require(script.Modules.DebugInventoryGrid)
print("[Client] ✅ DebugInventoryGrid module loaded")

local DebugCraftingMenuModule = require(script.Modules.DebugCraftingMenu)
print("[Client] ✅ DebugCraftingMenu module loaded")

local DebugManager = require(script.Modules.DebugManager)
print("[Client] ✅ DebugManager module loaded")

-- Create GUI structures first
InventoryGuiSetup.createInventoryGui()
print("[Client] ✅ Main inventory GUI created")

InventoryGuiSetup.createDebugInventoryGui()
print("[Client] ✅ Debug inventory GUI created")

InventoryGuiSetup.setupResponsiveLayout()
print("[Client] ✅ Responsive layout enabled")

-- Initialize InventoryClient
local inventoryClient = InventoryClient.init()
print("[Client] ✅ InventoryClient initialized")

-- Setup KeybindManager
local keybindManager = KeybindManager.new()
print("[Client] ✅ KeybindManager created")

-- Create instances of debug modules
local debugInventoryGrid = DebugInventoryGridModule.new()
local debugCraftingMenu = DebugCraftingMenuModule.new()

-- Initialize DebugManager with other debug modules
DebugManager:Init({
	DebugInventoryGrid = debugInventoryGrid,
	DebugCraftingMenu = debugCraftingMenu,
})
print("[Client] ✅ Debug systems initialized")

-- Register INVENTORY keybind (E key)
keybindManager:registerBind("INVENTORY", function(inputState)
    if inputState == "began" then
        print("[Keybind] E key pressed - toggling inventory...")
        
        -- Try to attach GUI if not already attached
        if not inventoryClient.inventoryFrame or not inventoryClient.inventoryGui then
            print("[Keybind] Attempting to attach inventory GUI...")
            local attached = inventoryClient:attachGui()
            if not attached then
                -- Try fallback methods
                local function findDescendantByName(root, name)
                    for _, child in ipairs(root:GetDescendants()) do
                        if child.Name == name then
                            return child
                        end
                    end
                    return nil
                end

                local frame = findDescendantByName(inventoryClient.gui, "InventoryFrame")
                if frame and frame:IsA("Frame") then
                    local parentGui = frame:FindFirstAncestorWhichIsA("ScreenGui")
                    if parentGui then
                        inventoryClient.inventoryGui = parentGui
                        inventoryClient.inventoryFrame = frame
                        inventoryClient.inventoryItems = frame:FindFirstChild("InventoryItems")
                        inventoryClient.slotTemplate = inventoryClient.inventoryItems and inventoryClient.inventoryItems:FindFirstChild("ItemSlotTemplate")
                        if inventoryClient.slotTemplate then
                            inventoryClient.slotTemplate.Visible = false
                            print("[Keybind] ✅ Successfully attached via fallback")
                        end
                    end
                end
            end
        end

        -- Now toggle visibility
        if inventoryClient.inventoryFrame then
            local targetVisibility = not inventoryClient.visible
            inventoryClient:setInventoryVisible(targetVisibility)
            if targetVisibility then
                inventoryClient:requestInventory()
            end
            print("[Keybind] ✅ Inventory toggled: " .. tostring(targetVisibility))
        else
            warn("[Keybind] ❌ Cannot toggle inventory - GUI not found!")
        end
    end
end)

-- Register REACTION keybind (R key)
keybindManager:registerBind("REACTION", function(inputState)
	if inputState == "began" then
		print("[Keybind] Reaction triggered (R key)")
	end
end)

-- Register TOOL_WHEEL keybind (Space)
keybindManager:registerBind("TOOL_WHEEL", function(inputState)
	if inputState == "began" then
		print("[Keybind] Tool wheel triggered (Space key)")
        end
    end)

-- Register DEBUG_GUI keybind (G key)
keybindManager:registerBind("DEBUG_GUI", function(inputState)
	if inputState == "began" then
		print("[Keybind] G key pressed - toggling debug GUI...")
		DebugManager:Toggle()
		print("[Keybind] ✅ Debug GUI toggled")
    end
end)

-- Print debug reference BEFORE connecting
print("\n[Client] Keybind status BEFORE connection:")
keybindManager:printKeybindReference()

-- Connect all keybinds to input events
keybindManager:connect(UserInputService)
print("[Client] ✅ Keybinds connected")

-- Print debug reference AFTER connecting
print("\n[Client] Keybind status AFTER connection:")
keybindManager:printKeybindReference()

-- Verify handlers are registered
print("\n[Client] Active handlers:")
for bindName, handler in pairs(KeybindManager.HANDLERS) do
    print("  ✅", bindName, "→", type(handler))
end

-- Store globally for debugging
_G.KeybindManager = keybindManager
_G.InventoryClient = inventoryClient
_G.DebugManager = DebugManager
_G.DebugInventoryGrid = debugInventoryGrid  -- Store for refresh hook
print("[Client] ✅ All systems ready!")

-- Hook into inventory sync to refresh debug inventory when level changes
inventoryClient.inventoryRemote.OnClientEvent:Connect(function(action, data)
    if action == "SyncInventory" and debugInventoryGrid then
        -- Refresh debug inventory when inventory syncs (level might have changed)
        if debugInventoryGrid.refresh then
            debugInventoryGrid:refresh()
        end
    end
end)
