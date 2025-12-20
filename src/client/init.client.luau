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
local StarterGui = game:GetService("StarterGui")

-- Disable annoying Roblox Studio UI interference
pcall(function()
    -- Disable Studio command bar from appearing during testing
    StarterGui:SetCore("TopbarEnabled", true) -- Keep topbar for Roblox menu

    -- Set core GUI to minimal to prevent Studio UI interference
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

    -- Mouse lock to prevent Studio command bar from appearing
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true

    print("[Client] 🎮 Studio UI interference mitigation enabled")
end)

-- Additional Studio UI prevention
if _RunService:IsStudio() then
    -- In Studio, keep focus on the game viewport
    task.spawn(function()
        while task.wait(0.5) do
            -- Periodically ensure mouse stays in game context
            pcall(function()
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end)
        end
    end)
    print("[Client] 🎮 Studio mode: Focus lock enabled to prevent command bar interference")
end

-- ═══════════════════════════════════════════════════════════════
-- LOADING SCREEN FIRST - Show immediately before everything else
-- ═══════════════════════════════════════════════════════════════
-- DISABLED FOR DEBUG
-- print("[Client] 🎬 SHOWING LOADING SCREEN FIRST...")
local _LoadingScreenModule = require(script.Modules.LoadingScreen)
-- _LoadingScreenModule.init()
-- print("[Client] ✅ Loading screen displayed")
print("[Client] ⏸️ LOADING SCREEN DISABLED FOR DEBUG")

-- ═══════════════════════════════════════════════════════════════
-- NOW load everything else in the background
-- ═══════════════════════════════════════════════════════════════

-- Load modules (they are children of this script)
print("[Client] Loading modules from script children...")
print("[Client] Script children:", script:GetChildren())

local InventoryClient = require(script.InventoryClient)
print("[Client] ✅ InventoryClient loaded")

local ACNHAnimations = require(script.Modules.ACNHAnimations)
print("[Client] Loading ACNH animations...")
ACNHAnimations.init() -- Initialize running animations
print("[Client] ✅ ACNH animations loaded")

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

local CraftingGUIModule = require(script.Modules.CraftingGUI)
print("[Client] ✅ CraftingGUI module loaded")
-- Initialize the crafting GUI (creates singleton instance)
local craftingGUI = CraftingGUIModule.new()
print("[Client] ✅ CraftingGUI initialized")

local _OnboardingControllerModule = require(script.Modules.OnboardingController)
print("[Client] ✅ OnboardingController module loaded (disabled for debug)")
-- Onboarding controller auto-initializes and listens for server events

local RecipesInventoryGUIModule = require(script.Modules.RecipesInventoryGUI)
print("[Client] ✅ RecipesInventoryGUI module loaded")

local DebugManager = require(script.Modules.DebugManager)
print("[Client] ✅ DebugManager module loaded")

local ToolRingGUIModule = require(script.Modules.ToolRingGUI)
print("[Client] ✅ ToolRingGUI module loaded")

local ShopGUIModule = require(script.Modules.ShopGUI)
print("[Client] ✅ ShopGUI module loaded")

local EmoteWheelModule = require(script.Modules.EmoteWheel)
print("[Client] ✅ EmoteWheel module loaded")

local BuildingGUIModule = require(script.Modules.BuildingGUI)
print("[Client] ✅ BuildingGUI module loaded")

local NookPhoneGUIModule = require(script.Modules.NookPhoneGUI)
print("[Client] ✅ NookPhoneGUI module loaded")

local NookShoppingGUIModule = require(script.Modules.NookShoppingGUI)
print("[Client] ✅ NookShoppingGUI module loaded")

local QuestGUIModule = require(script.Modules.QuestGUI)
print("[Client] ✅ QuestGUI module loaded")

local TutorialManagerModule = require(script.Modules.TutorialManager)
print("[Client] ✅ TutorialManager module loaded")

local HomeScreenModule = require(script.Modules.HomeScreen)
print("[Client] ✅ HomeScreen module loaded")

local _OnboardingFlowModule = require(script.Modules.OnboardingFlow)
print("[Client] ✅ OnboardingFlow module loaded (disabled for debug)")

local FishingControllerModule = require(script.Modules.FishingController)
local SlingshotControllerModule = require(script.Modules.SlingshotController)
print("[Client] ✅ SlingshotController module loaded")

local ShovelClientModule = require(script.Modules.ShovelClient)
print("[Client] ✅ ShovelClient module loaded")

local ToolControllerModule = require(script.Modules.ToolController)
print("[Client] ✅ ToolController module loaded")

-- WaterEffects DISABLED - was causing material rendering issues in Studio
-- local WaterEffectsModule = require(script.Modules.WaterEffects)
-- print("[Client] ✅ WaterEffects module loaded")

-- Visual Effects system - Beautiful blur, shaders, and post-processing
local VisualEffectsModule = require(script.Modules.VisualEffects)
print("[Client] ✅ VisualEffects module loaded")

local ParticleEffectsModule = require(script.Modules.ParticleEffects)
print("[Client] ✅ ParticleEffects module loaded")

-- Startup Keybind Hint - DISABLED (user requested removal)
-- local StartupKeybindHintModule = require(script.Modules.StartupKeybindHint)
-- print("[Client] ✅ StartupKeybindHint module loaded")

-- NookPlane - Cutscene system for flying
local NookPlaneModule = require(script.Modules.NookPlane)
print("[Client] ✅ NookPlane module loaded")

local DIYWorkBenchControllerModule = require(script.Modules.DIYWorkBenchController)
print("[Client] ✅ DIYWorkBenchController module loaded")

local HomePlacementControllerModule = require(script.Modules.HomePlacementController)
print("[Client] ✅ HomePlacementController module loaded")

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
_G.KeybindManager = keybindManager -- Store globally for debug menu access
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
local _slingshotController = SlingshotControllerModule.new()
print("[Client] ✅ SlingshotController initialized")

-- Initialize shovel client
ShovelClientModule.init()
print("[Client] ✅ ShovelClient initialized")

ToolControllerModule.init()
print("[Client] ✅ ToolController initialized")

-- Create GUIManager for exclusive GUI visibility
local GUIManager = require(script.Modules.GUIManager)
local guiManager = GUIManager.new()
print("[Client] ✅ GUIManager loaded successfully")

local emoteWheel = EmoteWheelModule.new()
guiManager:registerGUI("emoteWheel", emoteWheel)

-- Initialize Quest GUI
local questGUI = QuestGUIModule.new()
print("[Client] ✅ QuestGUI initialized")

-- Register Quest GUI with GUIManager
guiManager:registerGUI("QuestGUI", questGUI)
print("[Client] ✅ QuestGUI registered with GUIManager")

-- Initialize Tutorial Manager (will listen for server to start tutorial)
local tutorialManager = TutorialManagerModule.new()
_G.TutorialManager = tutorialManager -- Expose globally for testing
print("[Client] ✅ TutorialManager initialized")

local SettingsControllerModule = require(script.Modules.SettingsController)
local settingsController = SettingsControllerModule.init({
    guiManager = guiManager,
})
print("[Client] ✅ SettingsController initialized")

-- Initialize comprehensive Game Menu (` key)
local GameMenuModule = require(script.Modules.GameMenu)
GameMenuModule.init(guiManager, settingsController, inventoryClient)
print("[Client] ✅ GameMenu initialized (` key)")

HomeScreenModule.initialize({
    guiManager = guiManager,
    inventoryClient = inventoryClient,
    settingsController = settingsController,
    gameMenu = GameMenuModule,
    keybindManager = keybindManager,
})

-- KeybindGuide - DISABLED (user requested removal)
-- local KeybindGuideModule = require(script.Modules.KeybindGuide)
-- KeybindGuideModule.init(guiManager, keybindManager, GameMenuModule, settingsController)
-- print("[Client] ✅ Keybind Guide initialized (F1)")

keybindManager:registerBind("GAME_MENU", function(inputState)
    if inputState == "began" then
        GameMenuModule.toggle()
    end
end)

-- KEYBIND_GUIDE keybind - DISABLED (user requested removal)
-- keybindManager:registerBind("KEYBIND_GUIDE", function(inputState)
--     if inputState == "began" then
--         KeybindGuideModule.toggle()
--     end
-- end)

local localPlayer = _Players.LocalPlayer

local ACNHCameraModule = require(script.Modules.ACNHCamera)
print("[Client] ✅ ACNHCamera module loaded")

-- Initialize camera IMMEDIATELY (before loading screen)
-- This allows the player to see the game world and move the camera around
ACNHCameraModule.init()
print("[Client] 🎥 Animal Crossing camera initialized")

-- DISABLED FOR DEBUG: Skip loading screen and onboarding
print("[Client] ⏸️ LOADING SCREEN & ONBOARDING DISABLED FOR DEBUG")
print("[Client] ✅ Game fully ready - skipping startup flows")

task.wait(0.2) -- Brief wait for modules to settle
-- StartupKeybindHintModule.init() -- Disabled: Remove keybind GUI
-- print("[Client] 🎮 Keybind hint displayed")

-- Expose NookPlane for cutscenes (can be called from scripts)
_G.NookPlane = NookPlaneModule
print("[Client] ✈️ NookPlane exposed to _G for cutscenes")

-- Initialize visual effects immediately (they load fast)
VisualEffectsModule.initialize(localPlayer)
ParticleEffectsModule.initialize()
print("[Client] ✨ Visual effects initialized (bloom, blur, DOF, atmosphere, particles)")

-- Find or create ScreenGui for Recipes Inventory
local playerGui = _Players.LocalPlayer:WaitForChild("PlayerGui")

local _currencyDisplay = CurrencyDisplay.new()
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
recipesInventoryGUI:Hide() -- Start hidden
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
debugInventoryGrid:Hide() -- Start hidden
guiManager:registerGUI("itemBrowser", debugInventoryGrid)
print("[Client] ✅ DebugInventoryGrid initialized standalone")

-- Register ITEM_BROWSER keybind (B key)
keybindManager:registerBind("ITEM_BROWSER", function(inputState)
    if inputState == "began" then
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")
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

        -- Close NookPhone/Shopping when opening tool wheel
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")

        guiManager:toggleGUI("toolRing")
    end
end)
print("[Client] ✅ Tool Ring keybind registered (T key)")

-- Initialize ShopGUI
local shopGUI = ShopGUIModule.new()
guiManager:registerGUI("shop", shopGUI)
print("[Client] ✅ ShopGUI initialized")

-- Initialize Building GUI
local buildingGUI = BuildingGUIModule.new()
guiManager:registerGUI("building", buildingGUI)
print("[Client] ✅ BuildingGUI initialized")

-- Initialize NookShoppingGUI first
local nookShoppingGUI = NookShoppingGUIModule.new()
guiManager:registerGUI("nookShopping", nookShoppingGUI)
print("[Client] ✅ NookShoppingGUI initialized")

-- Initialize Minimap first (needed for NookPhone map app)
local MinimapModule = require(script.Modules.Minimap)

-- Initialize NookPhoneGUI and connect it to NookShoppingGUI, GUIManager, and Minimap
local nookPhoneGUI = NookPhoneGUIModule.new()
nookPhoneGUI:setShopGUI(nookShoppingGUI)
nookPhoneGUI:init(guiManager, MinimapModule) -- Connect to GUIManager and Minimap for app functionality
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

-- Register BUILD keybind (H key)
keybindManager:registerBind("BUILD", function(inputState)
    if inputState == "began" then
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")
        guiManager:toggleGUI("building")
    end
end)
print("[Client] ✅ Building interface keybind registered (H key)")

-- NOOK_SHOPPING keybind (S key) removed - Nook Shopping can only be accessed through NookPhone (P key)

-- Initialize Premium Shop GUI
local PremiumShopGUIModule = require(script.Modules.PremiumShopGUI)
local premiumShopGUI = PremiumShopGUIModule.new()
guiManager:registerGUI("premiumShop", premiumShopGUI)
print("[Client] ✅ PremiumShopGUI initialized")

-- Register PREMIUM_SHOP keybind (F2 key)
keybindManager:registerBind("PREMIUM_SHOP", function(inputState)
    if inputState == "began" then
        print("[Keybind] Premium Shop triggered (F2 key)")
        guiManager:toggleGUI("premiumShop")
    end
end)
print("[Client] ✅ Premium Shop keybind registered (F2 key)")

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
debugCraftingMenu:Hide() -- Start hidden
guiManager:registerGUI("crafting", debugCraftingMenu)
print("[Client] ✅ DebugCraftingMenu initialized standalone")

-- Register INVENTORY keybind (E key)
keybindManager:registerBind("INVENTORY", function(inputState)
    if inputState == "began" then
        print("[Keybind] E key pressed - toggling inventory...")

        -- Close NookPhone/Shopping when opening inventory
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")

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
                        inventoryClient.slotTemplate = inventoryClient.inventoryItems
                            and inventoryClient.inventoryItems:FindFirstChild("ItemSlotTemplate")
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

-- Register QUESTS keybind (J key) for Quest GUI
keybindManager:registerBind("QUESTS", function(inputState)
    if inputState == "began" then
        print("[Keybind] J key pressed - toggling Quest GUI...")
        guiManager:toggleGUI("QuestGUI")
        print("[Keybind] ✅ Quest GUI toggled")
    end
end)
print("[Client] ✅ Quest GUI keybind registered (J key)")

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
-- Note: This is a DEBUG keybind, so it only works when debug mode is enabled
-- To enable debug mode: Open Game Menu (` key) → Debug tab → Toggle "Debug Mode" ON
-- OR: In Studio, you can enable it via: _G.KeybindManager:setDebugMode(true)
keybindManager:registerBind("DEBUG_GUI", function(inputState)
    if inputState == "began" then
        print("[Keybind] G key pressed - toggling debug GUI...")

        -- Close NookPhone/Shopping when opening debug GUI
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")

        guiManager:toggleGUI("debug")
        print("[Keybind] ✅ Debug GUI toggled")
    end
end)

-- Enable debug mode by default in Studio for easier development
if game:GetService("RunService"):IsStudio() then
    keybindManager:setDebugMode(true)
    print("[Client] ✅ Debug mode enabled by default in Studio")
end

-- Register CRAFTING keybind (C key) for DebugCraftingMenu
keybindManager:registerBind("CRAFTING", function(inputState)
    if inputState == "began" then
        print("[Keybind] C key pressed - toggling Crafting Menu...")

        -- Close NookPhone/Shopping when opening crafting
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")

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
                warn(
                    "[OnboardingDebug] ❌ DialogueGUI not found in PlayerGui. Please place your styled DialogueGUI in PlayerGui."
                )
                return
            end

            -- Simplified onboarding sequence: Tom Nook, Isabelle, Orville
            local playerName = _Players.LocalPlayer.Name
            local seq = {
                { villagerName = "Tom Nook", text = "Ah, " .. playerName .. "! Welcome, welcome! Yes, yes!" },
                {
                    villagerName = "Tom Nook",
                    text = "Thanks for choosing the Deserted Island Getaway Package! We'll get you all set up.",
                },
                {
                    villagerName = "Tom Nook",
                    text = "First, we'll choose an island layout. Take your time—there's no wrong choice, yes, yes!",
                },
                {
                    villagerName = "Tom Nook",
                    text = "Next, we'll give your island a perfect name. Something truly charming!",
                },
                {
                    villagerName = "Orville",
                    text = "Dodo Airlines! Orville here. We'll handle your flight arrangements. When you're ready, we fly!",
                },
                {
                    villagerName = "Tom Nook",
                    text = "Very good! We'll get everything ready. Please enjoy the short flight to your new home!",
                },
                {
                    villagerName = "Isabelle",
                    text = "Hello! I'm Isabelle. I'll be here to help with announcements and island life once you arrive.",
                },
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
                onComplete = onComplete,
            })
            print("[OnboardingDebug] ✅ Dialogue sequence shown. Click Continue to proceed through steps.")
        end
    end)
    print("[Client] ✅ START_ONBOARDING keybind registered (N key)")
else
    warn("[Client] ⚠️ START_ONBOARDING keybind not registered - DialogueGUI failed to load")
end

-- Register ESC key to open/close settings menu
keybindManager:registerBind("SETTINGS", function(inputState)
    if inputState == "began" then
        SettingsControllerModule.toggle()
    end
end)

-- Register missing keybind handlers (MAP, EMOTE, DROP_ITEM)
-- MinimapModule already loaded above for NookPhone
keybindManager:registerBind("MAP", function(inputState)
    if inputState == "began" then
        MinimapModule:toggle()
    end
end)
print("[Client] ✅ Minimap keybind registered (M key)")

keybindManager:registerBind("EMOTE", function(inputState)
    if inputState == "began" then
        guiManager:toggleGUI("emoteWheel")
    end
end)

keybindManager:registerBind("DROP_ITEM", function(inputState)
    if inputState == "began" then
        print("[Keybind] Q key pressed - Drop item feature coming soon!")
        -- TODO: Implement drop item functionality
        -- This should drop the currently selected/equipped item
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
_G.DebugInventoryGrid = debugInventoryGrid -- Store for refresh hook
_G.RecipesInventoryGUI = recipesInventoryGUI -- Store for debugging
_G.GUIManager = guiManager -- Store for debugging

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
