-- Roblox globals
local game = game

-- Import services
local _Players = game:GetService("Players")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local _RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Disable Roblox Studio UI interference
pcall(function()
    StarterGui:SetCore("TopbarEnabled", true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end)

-- Additional Studio UI prevention
if _RunService:IsStudio() then
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end)
        end
    end)
end

-- Load modules
local _LoadingScreenModule = require(script.Modules.LoadingScreen)
local InventoryClient = require(script.InventoryClient)
local ACNHAnimations = require(script.Modules.ACNHAnimations)
ACNHAnimations.init()

local InventoryGuiSetup = require(script.Modules.InventoryGuiSetup)
local CurrencyDisplay = require(script.Modules.CurrencyDisplay)
local KeybindManager = require(script.KeybindManager)
local DebugInventoryGridModule = require(script.Modules.DebugInventoryGrid)
local DebugCraftingMenuModule = require(script.Modules.DebugCraftingMenu)
local CraftingGUIModule = require(script.Modules.CraftingGUI)
local craftingGUI = CraftingGUIModule.new()
local _OnboardingControllerModule = require(script.Modules.OnboardingController)
local RecipesInventoryGUIModule = require(script.Modules.RecipesInventoryGUI)
local DebugManager = require(script.Modules.DebugManager)
local ToolRingGUIModule = require(script.Modules.ToolRingGUI)
local ShopGUIModule = require(script.Modules.ShopGUI)
local EmoteWheelModule = require(script.Modules.EmoteWheel)
local BuildingGUIModule = require(script.Modules.BuildingGUI)
local HomeBuildingGUIModule = require(script.Modules.HomeBuildingGUI)
local NookPhoneGUIModule = require(script.Modules.NookPhoneGUI)
local NookShoppingGUIModule = require(script.Modules.NookShoppingGUI)
local QuestGUIModule = require(script.Modules.QuestGUI)
local TutorialManagerModule = require(script.Modules.TutorialManager)
local HomeScreenModule = require(script.Modules.HomeScreen)
local _OnboardingFlowModule = require(script.Modules.OnboardingFlow)
local FishingControllerModule = require(script.Modules.FishingController)
local SlingshotControllerModule = require(script.Modules.SlingshotController)
local ShovelClientModule = require(script.Modules.ShovelClient)
local ToolControllerModule = require(script.Modules.ToolController)
local VisualEffectsModule = require(script.Modules.VisualEffects)
local ParticleEffectsModule = require(script.Modules.ParticleEffects)
local NookPlaneModule = require(script.Modules.NookPlane)
local DIYWorkBenchControllerModule = require(script.Modules.DIYWorkBenchController)
local HomePlacementControllerModule = require(script.Modules.HomePlacementController)

-- Initialize HUD system
local _HUD = nil
local HUDSuccess, HUDErr = pcall(function()
    local HUDModule = require(script.Modules.HUD)
    _HUD = HUDModule.new()
end)
if not HUDSuccess then
    warn("[Client] Failed to initialize HUD:", tostring(HUDErr))
end

-- Create GUI structures
InventoryGuiSetup.createInventoryGui()
InventoryGuiSetup.createDebugInventoryGui()
InventoryGuiSetup.setupResponsiveLayout()

-- Initialize InventoryClient
local inventoryClient = InventoryClient.init()

-- Setup KeybindManager
local keybindManager = KeybindManager.new()
_G.KeybindManager = keybindManager

-- Create instances of debug modules
local debugInventoryGrid = DebugInventoryGridModule.new()
local debugCraftingMenu = DebugCraftingMenuModule.new()
local recipesInventoryGUI = RecipesInventoryGUIModule.new()

local fishingController = FishingControllerModule.new()
fishingController:init()

local _slingshotController = SlingshotControllerModule.new()
ShovelClientModule.init()
ToolControllerModule.init()

-- Create GUIManager for exclusive GUI visibility
local GUIManager = require(script.Modules.GUIManager)
local guiManager = GUIManager.new()

local emoteWheel = EmoteWheelModule.new()
guiManager:registerGUI("emoteWheel", emoteWheel)

local questGUI = QuestGUIModule.new()
guiManager:registerGUI("QuestGUI", questGUI)

local tutorialManager = TutorialManagerModule.new()
_G.TutorialManager = tutorialManager

local SettingsControllerModule = require(script.Modules.SettingsController)
local settingsController = SettingsControllerModule.init({
    guiManager = guiManager,
})

local GameMenuModule = require(script.Modules.GameMenu)
GameMenuModule.init(guiManager, settingsController, inventoryClient)

HomeScreenModule.initialize({
    guiManager = guiManager,
    inventoryClient = inventoryClient,
    settingsController = settingsController,
    gameMenu = GameMenuModule,
    keybindManager = keybindManager,
})

keybindManager:registerBind("GAME_MENU", function(inputState)
    if inputState == "began" then
        GameMenuModule.toggle()
    end
end)

local localPlayer = _Players.LocalPlayer
local ACNHCameraModule = require(script.Modules.ACNHCamera)
ACNHCameraModule.init()

-- Listen for onboarding start from server
task.spawn(function()
    local remotes = _ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then
        warn("[Client] Remotes folder not found")
        return
    end

    local startOnboardingRemote = remotes:FindFirstChild("StartOnboarding")
    if not startOnboardingRemote then
        warn("[Client] StartOnboarding remote missing")
        return
    end

    startOnboardingRemote.OnClientEvent:Connect(function()
        _OnboardingFlowModule.start()
    end)
end)

task.wait(0.2)

-- Expose NookPlane for cutscenes
_G.NookPlane = NookPlaneModule

-- Initialize visual effects
VisualEffectsModule.initialize(localPlayer)
ParticleEffectsModule.initialize()

-- Find or create ScreenGui for Recipes Inventory
local playerGui = _Players.LocalPlayer:WaitForChild("PlayerGui")

local _currencyDisplay = CurrencyDisplay.new()

local recipesScreenGui = playerGui:FindFirstChild("RecipesInventoryGUI")
if not recipesScreenGui then
    recipesScreenGui = Instance.new("ScreenGui")
    recipesScreenGui.Name = "RecipesInventoryGUI"
    recipesScreenGui.ResetOnSpawn = false
    recipesScreenGui.DisplayOrder = 10
    recipesScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    recipesScreenGui.Parent = playerGui
end

recipesInventoryGUI:Init(recipesScreenGui)
recipesInventoryGUI:Hide()
guiManager:registerGUI("recipes", recipesInventoryGUI)

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

debugInventoryGrid:Init(itemBrowserScreenGui)
debugInventoryGrid:Hide()
guiManager:registerGUI("itemBrowser", debugInventoryGrid)

keybindManager:registerBind("ITEM_BROWSER", function(inputState)
    if inputState == "began" then
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")
        guiManager:toggleGUI("itemBrowser")
    end
end)

-- Initialize Tool Ring GUI
local toolRingGUI = ToolRingGUIModule.new()
toolRingGUI:setInventoryClient(inventoryClient)
guiManager:registerGUI("toolRing", toolRingGUI)

keybindManager:registerBind("TOOL_WHEEL", function(inputState)
    if inputState == "began" then
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")
        guiManager:toggleGUI("toolRing")
    end
end)

-- Initialize ShopGUI
local shopGUI = ShopGUIModule.new()
guiManager:registerGUI("shop", shopGUI)

-- Initialize Building GUI
local buildingGUI = BuildingGUIModule.new()
guiManager:registerGUI("building", buildingGUI)

local homeBuildingGUI = HomeBuildingGUIModule.new()
guiManager:registerGUI("homeBuilding", homeBuildingGUI)

-- Initialize NookShoppingGUI
local nookShoppingGUI = NookShoppingGUIModule.new()
guiManager:registerGUI("nookShopping", nookShoppingGUI)

-- Initialize Minimap (needed for NookPhone map app)
local MinimapModule = require(script.Modules.Minimap)

-- Initialize NookPhone GUI
local nookPhoneGUI = NookPhoneGUIModule.new()
nookPhoneGUI:init(guiManager, MinimapModule)
guiManager:registerGUI("nookPhone", nookPhoneGUI)

keybindManager:registerBind("NOOK_PHONE", function(inputState)
    if inputState == "began" then
        guiManager:toggleGUI("nookPhone")
    end
end)

keybindManager:registerBind("BUILD", function(inputState)
    if inputState == "began" then
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")
        guiManager:toggleGUI("building")
    end
end)

-- Initialize Premium Shop GUI
local PremiumShopGUIModule = require(script.Modules.PremiumShopGUI)
local premiumShopGUI = PremiumShopGUIModule.new()
guiManager:registerGUI("premiumShop", premiumShopGUI)

keybindManager:registerBind("PREMIUM_SHOP", function(inputState)
    if inputState == "began" then
        guiManager:toggleGUI("premiumShop")
    end
end)

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

debugCraftingMenu:Init(craftingMenuScreenGui)
debugCraftingMenu:Hide()
guiManager:registerGUI("crafting", debugCraftingMenu)

-- Register INVENTORY keybind (E key)
keybindManager:registerBind("INVENTORY", function(inputState)
    if inputState == "began" then
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")

        if not inventoryClient.inventoryFrame or not inventoryClient.inventoryGui then
            local attached = inventoryClient:attachGui()
            if not attached then
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
                        end
                    end
                end
            end
        end

        if not guiManager:isVisible("inventory") and inventoryClient.visible then
            guiManager:registerGUI("inventory", inventoryClient)
        end

        if inventoryClient.inventoryFrame then
            local targetVisibility = not inventoryClient.visible

            if not guiManager:getCurrentVisible() or guiManager:getCurrentVisible() ~= "inventory" then
                guiManager:registerGUI("inventory", inventoryClient)
            end

            if targetVisibility then
                guiManager:showGUI("inventory")
                inventoryClient:requestInventory()
            else
                guiManager:hideGUI("inventory")
            end
        else
            warn("[Client] Cannot toggle inventory - GUI not found")
        end
    end
end)

keybindManager:registerBind("REACTION", function(inputState)
    if inputState == "began" then
        guiManager:toggleGUI("recipes")
    end
end)

keybindManager:registerBind("QUESTS", function(inputState)
    if inputState == "began" then
        guiManager:toggleGUI("QuestGUI")
    end
end)

guiManager:registerGUI("inventory", inventoryClient)

local debugGui = _Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DebugGUIManager")
if debugGui then
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
end

keybindManager:registerBind("DEBUG_GUI", function(inputState)
    if inputState == "began" then
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")
        guiManager:toggleGUI("debug")
    end
end)

-- Enable debug mode by default in Studio
if game:GetService("RunService"):IsStudio() then
    keybindManager:setDebugMode(true)
end

keybindManager:registerBind("CRAFTING", function(inputState)
    if inputState == "began" then
        guiManager:hideGUI("nookPhone")
        guiManager:hideGUI("nookShopping")
        guiManager:toggleGUI("crafting")
    end
end)

keybindManager:registerBind("DEBUG_DELETE", function(inputState)
    if inputState == "began" then
        local inventoryClient = _G.InventoryClient
        if inventoryClient and inventoryClient.inventoryRemote then
            for slotIndex, state in pairs(inventoryClient.slotState) do
                if state and state.itemId then
                    inventoryClient.inventoryRemote:FireServer("DeleteItem", {
                        itemId = state.itemId,
                        count = 1,
                    })
                    break
                end
            end
        end
    end
end)


keybindManager:registerBind("SETTINGS", function(inputState)
    if inputState == "began" then
        SettingsControllerModule.toggle()
    end
end)

keybindManager:registerBind("MAP", function(inputState)
    if inputState == "began" then
        MinimapModule:toggle()
    end
end)

keybindManager:registerBind("EMOTE", function(inputState)
    if inputState == "began" then
        guiManager:toggleGUI("emoteWheel")
    end
end)

keybindManager:registerBind("DROP_ITEM", function(inputState)
    if inputState == "began" then
        -- TODO: Implement drop item functionality
    end
end)

-- Connect all keybinds
keybindManager:connect(UserInputService)

-- Store globally for debugging
_G.KeybindManager = keybindManager
_G.InventoryClient = inventoryClient
_G.DebugManager = DebugManager
_G.DebugInventoryGrid = debugInventoryGrid
_G.RecipesInventoryGUI = recipesInventoryGUI
_G.GUIManager = guiManager
_G.NookPhoneGUI = nookPhoneGUI

-- Hook into inventory sync to refresh debug inventory when level changes
inventoryClient.inventoryRemote.OnClientEvent:Connect(function(action, data)
    if action == "SyncInventory" and debugInventoryGrid then
        if debugInventoryGrid.refresh then
            debugInventoryGrid:refresh()
        end
    end
end)

print("[Client] All systems ready")
