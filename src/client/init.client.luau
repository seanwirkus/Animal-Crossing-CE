-- Roblox globals
local game = game

--[[
    TODO: GAME LAUNCH INTEGRATION CHECKLIST
    - [DAY 1] Integrate CurrencyDisplay.luau
    - [DAY 2] Integrate FishingController.luau
    - [DAY 3] Integrate BugController.luau (create file)
    - [DAY 4] Integrate ShopGUI.luau
    - [DAY 6] Integrate TutorialManager.luau (create file)
    - [DAY 7] Integrate AchievementPopup.luau (create file)
    - [DAY 11] Add sound effects and particle systems
    - [DAY 11] Add mobile control buttons
    
    See GAME_LAUNCH_PLAN.md for full implementation timeline
]]

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

local ChibiCharacter = require(script.Modules.ChibiCharacter)
print("[Client] Loading chibi character system...")
ChibiCharacter.init() -- Initialize the chibi character system
print("[Client] ✅ Chibi character system loaded")

local InventoryGuiSetup = require(script.Modules.InventoryGuiSetup)
print("[Client] ✅ InventoryGuiSetup loaded")

local CurrencyDisplay = require(script.Modules.CurrencyDisplay)
print("[Client] ✅ CurrencyDisplay module loaded")

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

local ToolRingGUIModule = require(script.Modules.ToolRingGUI)
print("[Client] ✅ ToolRingGUI module loaded")

local ShopGUIModule = require(script.Modules.ShopGUI)
print("[Client] ✅ ShopGUI module loaded")

local NookPhoneGUIModule = require(script.Modules.NookPhoneGUI)
print("[Client] ✅ NookPhoneGUI module loaded")

local NookShoppingGUIModule = require(script.Modules.NookShoppingGUI)
print("[Client] ✅ NookShoppingGUI module loaded")

local FishingControllerModule = require(script.Modules.FishingController)
local SlingshotControllerModule = require(script.Modules.SlingshotController)
print("[Client] ✅ SlingshotController module loaded")

-- local ChibiCharacter = require(script.Modules.ChibiCharacter)
-- print("[Client] ✅ ChibiCharacter module loaded")

-- WaterEffects DISABLED - was causing material rendering issues in Studio
-- local WaterEffectsModule = require(script.Modules.WaterEffects)
-- print("[Client] ✅ WaterEffects module loaded")

-- Initialize HUD system
local _HUD = nil
local HUDSuccess, HUDErr = pcall(function()
	local HUDModule = require(script.Modules.HUD)
	_HUD = HUDModule.new()
end)
if not HUDSuccess then
	warn("[Client] ❌ Failed to initialize HUD:", tostring(HUDErr))
	warn(debug.traceback())
else
	print("[Client] ✅ HUD system initialized")
end

-- ACNH-fx Sky setup DISABLED - user managing effects in Studio
-- local ACNHFXSuccess, ACNHFXErr = pcall(function()
-- 	local ACNHFX = require(script.Modules.ACNHFX)
-- 	ACNHFX.setup()
-- end)
-- if not ACNHFXSuccess then
-- 	warn("[Client] ❌ Failed to apply ACNH-fx:", tostring(ACNHFXErr))
-- 	warn(debug.traceback())
-- end
print("[Client] ℹ️ ACNH-fx effects disabled - managing lighting/effects in Studio")

-- Dialogue GUI for onboarding/debug dialogues
print("[Client] 🔍 Attempting to load DialogueGUI...")
local DialogueGUI
local dialogueGUISuccess, dialogueGUIErr = pcall(function()
	print("[Client] 🔍 Calling require for DialogueGUI...")
	DialogueGUI = require(script.Modules.DialogueGUI)
	print("[Client] 🔍 Require completed, DialogueGUI type:", type(DialogueGUI))
end)
print("[Client] 🔍 DialogueGUI load result:", dialogueGUISuccess, type(DialogueGUI))
if dialogueGUISuccess then
	print("[Client] ✅ DialogueGUI module loaded successfully")
else
	warn("[Client] ❌ Failed to load DialogueGUI:", tostring(dialogueGUIErr))
	warn(debug.traceback())
end

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

local fishingController = FishingControllerModule.new()
fishingController:init()
print("[Client] ✅ FishingController initialized")

-- Initialize slingshot controller
local slingshotController = SlingshotControllerModule.new()
print("[Client] ✅ SlingshotController initialized")

-- Create GUIManager for exclusive GUI visibility
local GUIManager = require(script.Modules.GUIManager)
local guiManager = GUIManager.new()
print("[Client] ✅ GUIManager loaded successfully")

-- Find or create ScreenGui for Recipes Inventory
local playerGui = _Players.LocalPlayer:WaitForChild("PlayerGui")

local currencyDisplay = CurrencyDisplay.new()
print("[Client] ✅ Currency HUD initialized")

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

-- Initialize Tool Ring GUI
local toolRingGUI = ToolRingGUIModule.new()
-- Connect tool ring to inventory
toolRingGUI:setInventoryClient(inventoryClient)
guiManager:registerGUI("toolRing", toolRingGUI)
print("[Client] ✅ ToolRingGUI initialized")

-- Register TOOL_WHEEL keybind (T key)
keybindManager:registerBind("TOOL_WHEEL", function(inputState)
	if inputState == "began" then
		print("[Keybind] Tool wheel triggered (T key)")
		guiManager:toggleGUI("toolRing")
	end
end)
print("[Client] ✅ Tool Ring keybind registered (T key)")

-- Initialize ShopGUI
local shopGUI = ShopGUIModule.new()
guiManager:registerGUI("shop", shopGUI)
print("[Client] ✅ ShopGUI initialized")

-- Initialize NookShoppingGUI first
local nookShoppingGUI = NookShoppingGUIModule.new()
guiManager:registerGUI("nookShopping", nookShoppingGUI)
print("[Client] ✅ NookShoppingGUI initialized")

-- Initialize NookPhoneGUI and connect it to NookShoppingGUI
local nookPhoneGUI = NookPhoneGUIModule.new()
nookPhoneGUI:setShopGUI(nookShoppingGUI)
guiManager:registerGUI("nookPhone", nookPhoneGUI)
print("[Client] ✅ NookPhoneGUI initialized")

-- Register NOOK_PHONE keybind (P key)
keybindManager:registerBind("NOOK_PHONE", function(inputState)
	if inputState == "began" then
		print("[Keybind] NookPhone triggered (P key)")
		guiManager:toggleGUI("nookPhone")
	end
end)
print("[Client] ✅ NookPhone keybind registered (P key)")

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

-- Register DEBUG DELETE keybind (X key) to test inventory deletion
keybindManager:registerBind("DEBUG_DELETE", function(inputState)
	if inputState == "began" then
		print("[Debug] X key pressed - deleting first item...")
		local inventoryClient = _G.InventoryClient
		if inventoryClient and inventoryClient.inventoryRemote then
			-- Delete the first item we find
			for slotIndex, state in pairs(inventoryClient.slotState) do
				if state and state.itemId then
					print("[Debug] Deleting item:", state.itemId, "from slot", slotIndex)
					inventoryClient.inventoryRemote:FireServer("DeleteItem", {
						itemId = state.itemId,
						count = 1,
					})
					break
				end
			end
		else
			warn("[Debug] No inventory client or remote available")
		end
	end
end)


-- Register START_ONBOARDING debug keybind (N key) - only if DialogueGUI loaded
print("[Client] 🔍 Checking DialogueGUI registration - success:", dialogueGUISuccess, "type:", type(DialogueGUI))
if dialogueGUISuccess and DialogueGUI then
	print("[Client] 🔍 Registering START_ONBOARDING keybind...")
	keybindManager:registerBind("START_ONBOARDING", function(inputState)
		if inputState == "began" then
			print("[Keybind] N key pressed - starting onboarding debug sequence...")
			
			-- Show toast notification
			if DialogueGUI and DialogueGUI.showToast then
				DialogueGUI.showToast("🏝️ Starting Onboarding Sequence...", 2)
			end
			
			local dialogue = DialogueGUI.new()
			local ok = dialogue:Init()
			if not ok then
				warn("[OnboardingDebug] ❌ DialogueGUI not found in PlayerGui. Please place your styled DialogueGUI in PlayerGui.")
				return
			end
			
			-- Simplified onboarding sequence: Tom Nook, Isabelle, Orville
			local playerName = _Players.LocalPlayer.Name
			local seq = {
				{ villagerName = "Tom Nook", text = "Ah, " .. playerName .. "! Welcome, welcome! Yes, yes!" },
				{ villagerName = "Tom Nook", text = "Thanks for choosing the Deserted Island Getaway Package! We'll get you all set up." },
				{ villagerName = "Tom Nook", text = "First, we'll choose an island layout. Take your time—there's no wrong choice, yes, yes!" },
				{ villagerName = "Tom Nook", text = "Next, we'll give your island a perfect name. Something truly charming!" },
				{ villagerName = "Orville", text = "Dodo Airlines! Orville here. We'll handle your flight arrangements. When you're ready, we fly!" },
				{ villagerName = "Tom Nook", text = "Very good! We'll get everything ready. Please enjoy the short flight to your new home!" },
				{ villagerName = "Isabelle", text = "Hello! I'm Isabelle. I'll be here to help with announcements and island life once you arrive." },
			}
			
			-- Callback when sequence completes (after last dialogue)
			local function onComplete()
				print("[OnboardingDebug] ✅ Dialogue sequence complete. Opening island selection...")
				if DialogueGUI and DialogueGUI.showToast then
					DialogueGUI.showToast("🎯 Opening Island Selection...", 2)
				end
				
				-- Try to open island selection GUI (if available)
				-- TODO: Replace with actual OnboardingGUI or UnifiedOnboardingFlow integration
				local success, err = pcall(function()
					-- Check if OnboardingGUI exists
					local onboardingPath = script:FindFirstChild("OnboardingGUI") 
						or _ReplicatedStorage:FindFirstChild("OnboardingGUI")
					
					if onboardingPath then
						local _OnboardingGUI = require(onboardingPath)
						-- Open island selection (you'll need to provide templates)
						warn("[OnboardingDebug] ⚠️ OnboardingGUI found but integration not yet complete")
					else
						print("[OnboardingDebug] ℹ️ Island selection will be integrated here")
					end
				end)
				
				if not success then
					warn("[OnboardingDebug] ⚠️ Could not open island selection:", tostring(err))
				end
			end
			
			dialogue:ShowSequence(seq, { 
				autoAdvance = false,
				onComplete = onComplete
			})
			print("[OnboardingDebug] ✅ Dialogue sequence shown. Click Continue to proceed through steps.")
		end
	end)
	print("[Client] ✅ START_ONBOARDING keybind registered (N key)")
else
	warn("[Client] ⚠️ START_ONBOARDING keybind not registered - DialogueGUI failed to load")
end

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

-- Water Visual Effects DISABLED - was causing material rendering issues in Studio
-- local waterEffects = WaterEffectsModule.new()
-- waterEffects:Start()
print("[Client] ℹ️ Water visual effects DISABLED (use Studio lighting instead)")

print("[Client] ✅ SlingshotController initialized")

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
