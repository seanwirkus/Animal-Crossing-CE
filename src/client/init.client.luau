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

local RecipesInventoryGUIModule = require(script.Modules.RecipesInventoryGUI)
print("[Client] ✅ RecipesInventoryGUI module loaded")

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

-- Create Recipes Inventory GUI instance
local recipesInventoryGUI = RecipesInventoryGUIModule.new()

-- Create GUIManager for exclusive GUI visibility
local GUIManager = require(script.Modules.GUIManager)
local guiManager = GUIManager.new()
print("[Client] ✅ GUIManager loaded successfully")

-- Find or create ScreenGui for Recipes Inventory
local playerGui = _Players.LocalPlayer:WaitForChild("PlayerGui")
local recipesScreenGui = playerGui:FindFirstChild("RecipesInventoryGUI")
if not recipesScreenGui then
	recipesScreenGui = Instance.new("ScreenGui")
	recipesScreenGui.Name = "RecipesInventoryGUI"
	recipesScreenGui.ResetOnSpawn = false
	recipesScreenGui.DisplayOrder = 10
	recipesScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	recipesScreenGui.Parent = playerGui
end

-- Initialize Recipes Inventory GUI
recipesInventoryGUI:Init(recipesScreenGui)
recipesInventoryGUI:Hide()  -- Start hidden
guiManager:registerGUI("recipes", recipesInventoryGUI)
print("[Client] ✅ Recipes Inventory GUI initialized")

-- Create standalone ScreenGui for DebugInventoryGrid (Item Browser)
local itemBrowserScreenGui = playerGui:FindFirstChild("ItemBrowserGUI")
if not itemBrowserScreenGui then
	itemBrowserScreenGui = Instance.new("ScreenGui")
	itemBrowserScreenGui.Name = "ItemBrowserGUI"
	itemBrowserScreenGui.ResetOnSpawn = false
	itemBrowserScreenGui.DisplayOrder = 9
	itemBrowserScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	itemBrowserScreenGui.Parent = playerGui
end

-- Initialize DebugInventoryGrid standalone
debugInventoryGrid:Init(itemBrowserScreenGui)
debugInventoryGrid:Hide()  -- Start hidden
guiManager:registerGUI("itemBrowser", debugInventoryGrid)
print("[Client] ✅ DebugInventoryGrid initialized standalone")

-- Register ITEM_BROWSER keybind (B key)  
keybindManager:registerBind("ITEM_BROWSER", function(inputState)
	if inputState == "began" then
		guiManager:toggleGUI("itemBrowser")
	end
end)
print("[Client] ✅ Item Browser keybind registered (B key)")

-- Register TOOL_WHEEL keybind (T key) - can be added later
keybindManager:registerBind("TOOL_WHEEL", function(inputState)
	if inputState == "began" then
		print("[Keybind] Tool wheel triggered (T key)")
        end
    end)

-- DebugManager is no longer needed (can be removed later if unused)
print("[Client] ✅ Debug systems initialized")

-- Create standalone ScreenGui for DebugCraftingMenu
local craftingMenuScreenGui = playerGui:FindFirstChild("CraftingMenuGUI")
if not craftingMenuScreenGui then
	craftingMenuScreenGui = Instance.new("ScreenGui")
	craftingMenuScreenGui.Name = "CraftingMenuGUI"
	craftingMenuScreenGui.ResetOnSpawn = false
	craftingMenuScreenGui.DisplayOrder = 11
	craftingMenuScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	craftingMenuScreenGui.Parent = playerGui
end

-- Initialize DebugCraftingMenu standalone
debugCraftingMenu:Init(craftingMenuScreenGui)
debugCraftingMenu:Hide()  -- Start hidden
guiManager:registerGUI("crafting", debugCraftingMenu)
print("[Client] ✅ DebugCraftingMenu initialized standalone")

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

        -- Register inventory with GUIManager if not already registered
        if not guiManager:isVisible("inventory") and inventoryClient.visible then
            guiManager:registerGUI("inventory", inventoryClient)
        end
        
        -- Now toggle visibility through GUIManager
        if inventoryClient.inventoryFrame then
            local targetVisibility = not inventoryClient.visible
            
            -- Register inventory if not already registered
            if not guiManager:getCurrentVisible() or guiManager:getCurrentVisible() ~= "inventory" then
                guiManager:registerGUI("inventory", inventoryClient)
            end
            
            if targetVisibility then
                guiManager:showGUI("inventory")
                inventoryClient:requestInventory()
            else
                guiManager:hideGUI("inventory")
            end
            print("[Keybind] ✅ Inventory toggled: " .. tostring(targetVisibility))
        else
            warn("[Keybind] ❌ Cannot toggle inventory - GUI not found!")
        end
    end
end)

-- Register REACTION keybind (R key) for Recipes Inventory
keybindManager:registerBind("REACTION", function(inputState)
	if inputState == "began" then
		print("[Keybind] R key pressed - toggling Recipes Inventory...")
		guiManager:toggleGUI("recipes")
		print("[Keybind] ✅ Recipes Inventory toggled")
	end
end)

-- Register inventory GUI with GUIManager
guiManager:registerGUI("inventory", inventoryClient)

-- Register DebugManager GUI with GUIManager
local debugGui = _Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DebugGUIManager")
if debugGui then
	-- Create a wrapper object for DebugManager that works with GUIManager
	local debugManagerWrapper = {
		Hide = function()
			debugGui.Enabled = false
		end,
		Show = function()
			debugGui.Enabled = true
		end,
		Toggle = function()
			debugGui.Enabled = not debugGui.Enabled
		end,
	}
	guiManager:registerGUI("debug", debugManagerWrapper)
	print("[Client] ✅ DebugManager GUI registered")
end

-- Register DEBUG_GUI keybind (G key)
keybindManager:registerBind("DEBUG_GUI", function(inputState)
	if inputState == "began" then
		print("[Keybind] G key pressed - toggling debug GUI...")
		guiManager:toggleGUI("debug")
		print("[Keybind] ✅ Debug GUI toggled")
    end
end)

-- Register CRAFTING keybind (C key) for DebugCraftingMenu
keybindManager:registerBind("CRAFTING", function(inputState)
	if inputState == "began" then
		print("[Keybind] C key pressed - toggling Crafting Menu...")
		guiManager:toggleGUI("crafting")
		print("[Keybind] ✅ Crafting Menu toggled")
	end
end)

-- Register ESC key to close current GUI
keybindManager:registerBind("SETTINGS", function(inputState)
	if inputState == "began" then
		print("[Keybind] ESC pressed - closing current GUI...")
		if guiManager:getCurrentVisible() then
			guiManager:hideGUI(guiManager:getCurrentVisible())
		end
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
_G.RecipesInventoryGUI = recipesInventoryGUI  -- Store for debugging
_G.GUIManager = guiManager  -- Store for debugging
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
