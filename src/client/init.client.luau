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
        -- Ensure GUI attachment before toggling
        if not inventoryClient.inventoryFrame or not inventoryClient.inventoryGui then
            print("[Keybind] Re-attaching inventory GUI before toggle...")
            inventoryClient:attachGui()
        end

        local targetVisibility = not inventoryClient.visible
        inventoryClient:setInventoryVisible(targetVisibility)
        if targetVisibility then
            inventoryClient:requestInventory()
        end
        print("[Keybind] Inventory toggled: " .. tostring(targetVisibility))

        -- Fallback A: directly toggle known path
        if inventoryClient.gui then
            local sg = inventoryClient.gui:FindFirstChild("InventoryGUI")
            if sg and sg:FindFirstChild("InventoryFrame") then
                sg.Enabled = true
                sg.InventoryFrame.Visible = targetVisibility
                print("[Keybind] FallbackA: InventoryGUI/InventoryFrame set Visible=", targetVisibility)
            end

            -- Fallback B: deep search by name anywhere under PlayerGui
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
                if parentGui then parentGui.Enabled = true end
                frame.Visible = targetVisibility
                print("[Keybind] FallbackB: Found InventoryFrame (deep) and set Visible=", targetVisibility)
            else
                print("[Keybind] FallbackB: InventoryFrame not found in PlayerGui descendants")
            end
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
		print("[Keybind] Debug GUI toggled (G key)")
		DebugManager:Toggle()
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
_G.DebugManager = DebugManager
print("[Client] ✅ All systems ready!")
