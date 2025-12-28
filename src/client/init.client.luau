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
local StatusHUDModule = require(script.Modules.StatusHUD)

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

-- Custom ProximityPrompt UI for Bell Bags (gold-colored prompt)
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local function createBellBagPromptUI(prompt, inputType)
    -- Create a BillboardGui for custom bell bag prompt
    local adornee = prompt.Parent
    if not adornee then return nil end

    -- Get bell value from attribute
    local bellsValue = prompt:GetAttribute("BellsValue") or 0

    -- Format bells with commas (e.g., 99,000)
    local function formatBells(value)
        local formatted = tostring(value)
        local reversed = formatted:reverse()
        local result = reversed:gsub("(%d%d%d)", "%1,")
        return result:reverse():gsub("^,", "")
    end

    local formattedBells = formatBells(bellsValue)

    -- Determine bag size for styling
    local isLarge = bellsValue >= 99000
    local isMedium = bellsValue >= 10000 and bellsValue < 99000

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "BellBagPromptUI"
    billboardGui.Adornee = adornee
    billboardGui.Size = UDim2.fromOffset(220, 100)
    billboardGui.StudsOffset = Vector3.new(0, 3.5, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboardGui.Parent = localPlayer.PlayerGui

    -- Main frame with rich gold gradient styling
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "PromptFrame"
    mainFrame.Size = UDim2.fromScale(1, 1)
    mainFrame.BackgroundColor3 = isLarge and Color3.fromRGB(255, 215, 0) -- Bright gold for large
        or isMedium and Color3.fromRGB(255, 200, 60) -- Gold for medium
        or Color3.fromRGB(240, 190, 80) -- Softer gold for small
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = billboardGui

    -- Add gradient for premium look
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 50)),
    })
    gradient.Rotation = -45
    gradient.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = isLarge and 4 or 3
    stroke.Color = Color3.fromRGB(160, 110, 20) -- Rich brown/gold border
    stroke.Parent = mainFrame

    -- "Collect Bells" title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.28, 0)
    titleLabel.Position = UDim2.fromOffset(0, 4)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Color3.fromRGB(100, 60, 20)
    titleLabel.Text = "Collect Bells"
    titleLabel.Parent = mainFrame

    -- Big bells amount display
    local bellsLabel = Instance.new("TextLabel")
    bellsLabel.Name = "BellsAmount"
    bellsLabel.Size = UDim2.new(1, 0, 0.38, 0)
    bellsLabel.Position = UDim2.new(0, 0, 0.26, 0)
    bellsLabel.BackgroundTransparency = 1
    bellsLabel.Font = Enum.Font.GothamBlack
    bellsLabel.TextSize = isLarge and 26 or isMedium and 24 or 22
    bellsLabel.TextColor3 = Color3.fromRGB(70, 40, 10) -- Dark brown
    bellsLabel.Text = formattedBells .. " Bells"
    bellsLabel.Parent = mainFrame

    -- Add text shadow for depth
    local shadowLabel = Instance.new("TextLabel")
    shadowLabel.Name = "Shadow"
    shadowLabel.Size = bellsLabel.Size
    shadowLabel.Position = bellsLabel.Position + UDim2.fromOffset(1, 1)
    shadowLabel.BackgroundTransparency = 1
    shadowLabel.Font = Enum.Font.GothamBlack
    shadowLabel.TextSize = bellsLabel.TextSize
    shadowLabel.TextColor3 = Color3.fromRGB(40, 20, 5)
    shadowLabel.TextTransparency = 0.6
    shadowLabel.Text = bellsLabel.Text
    shadowLabel.ZIndex = bellsLabel.ZIndex - 1
    shadowLabel.Parent = mainFrame

    -- Key prompt frame
    local keyFrame = Instance.new("Frame")
    keyFrame.Size = UDim2.fromOffset(32, 32)
    keyFrame.Position = UDim2.new(0.5, -16, 0.66, 2)
    keyFrame.BackgroundColor3 = Color3.fromRGB(70, 40, 15)
    keyFrame.BorderSizePixel = 0
    keyFrame.Parent = mainFrame

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 8)
    keyCorner.Parent = keyFrame

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Thickness = 2
    keyStroke.Color = Color3.fromRGB(50, 25, 10)
    keyStroke.Parent = keyFrame

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.fromScale(1, 1)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Font = Enum.Font.GothamBlack
    keyLabel.TextSize = 16
    keyLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
    keyLabel.Text = "E"
    keyLabel.Parent = keyFrame

    -- Sparkle animation for large bags
    local sparkleTime = 0
    local pulseConnection
    pulseConnection = _RunService.Heartbeat:Connect(function(dt)
        if not billboardGui.Parent then
            pulseConnection:Disconnect()
            return
        end

        sparkleTime = sparkleTime + dt

        -- Gentle pulse
        local scale = 1 + 0.04 * math.sin(sparkleTime * 4)
        mainFrame.Size = UDim2.fromScale(scale, scale)
        mainFrame.Position = UDim2.fromScale((1 - scale) / 2, (1 - scale) / 2)

        -- Shimmer effect on gradient
        gradient.Offset = Vector2.new(0.1 * math.sin(sparkleTime * 2), 0.1 * math.cos(sparkleTime * 2))

        -- Extra glow for large bags
        if isLarge then
            local brightness = 0.9 + 0.1 * math.sin(sparkleTime * 6)
            stroke.Transparency = 1 - brightness
        end
    end)

    return billboardGui
end

-- Handle custom ProximityPrompt UI for bell bags
local bellBagPromptUIs = {}

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
    if prompt:GetAttribute("IsBellBag") then
        local ui = createBellBagPromptUI(prompt, inputType)
        if ui then
            bellBagPromptUIs[prompt] = ui
        end
    end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
    if bellBagPromptUIs[prompt] then
        bellBagPromptUIs[prompt]:Destroy()
        bellBagPromptUIs[prompt] = nil
    end
end)

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

-- Initialize StatusHUD (always visible at top of screen)
local statusHUD = StatusHUDModule.new()

print("[Client] All systems ready")
