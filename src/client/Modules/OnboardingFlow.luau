--[[
	OnboardingFlow.luau
	
	Complete onboarding flow integrating:
	- DialogueGUI (Tom Nook dialogue)
	- CutsceneManager (camera control, transitions)
	- LoadingScreen (island loading)
	- Island selection and spawn
	
	This shows the complete flow:
	1. Dialogue with Tom Nook ✅ (already working)
	2. Island selection screen
	3. Loading screen with progress
	4. Cutscene: Camera pan over island
	5. Player spawn on island
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local DialogueGUI = require(script.Parent.DialogueGUI)
local CutsceneManager = require(script.Parent.CutsceneManager)
local LoadingScreen = require(script.Parent.LoadingScreen)
local GUIContentManager = require(script.Parent.GUIContentManager)

local OnboardingFlow = {}

-- Sample dialogue sequence (Tom Nook welcome)
local ONBOARDING_DIALOGUE = {
    {
        speaker = "Tom Nook",
        text = "Ah, welcome, welcome! So glad you could make it!",
        duration = 3,
    },
    {
        speaker = "Tom Nook",
        text = "I'm Tom Nook, and I'll be helping you get settled on your very own island getaway!",
        duration = 4,
    },
    {
        speaker = "Tom Nook",
        text = "Now then, let's pick out the perfect island for you, yes yes!",
        duration = 3,
    },
    {
        speaker = "Tom Nook",
        text = "Perfect! Your island is ready. Click the start button when you're ready to begin your adventure!",
        duration = 4,
    },
}

-- Sample island options
local ISLAND_OPTIONS = {
    { name = "Coral Cove", theme = "Beach", description = "Sandy shores and palm trees" },
    { name = "Forest Glen", theme = "Forest", description = "Lush trees and hidden streams" },
    { name = "Mountain Peak", theme = "Mountain", description = "Elevated views and waterfalls" },
    { name = "Flower Fields", theme = "Meadow", description = "Blooming flowers everywhere" },
}

--[[
	Start the complete onboarding flow
]]
function OnboardingFlow.start()
    print("[OnboardingFlow] 🎬 Starting onboarding sequence...")

    -- Step 1: Show Tom Nook dialogue
    OnboardingFlow.showDialogue(function()
        -- Step 2: After dialogue, show island selection
        OnboardingFlow.showIslandSelection(function(selectedIsland)
            -- Step 3: Load the island with loading screen
            OnboardingFlow.loadIsland(selectedIsland, function()
                -- Step 4: Play arrival cutscene
                OnboardingFlow.playArrivalCutscene(function()
                    -- Step 5: Show start day screen
                    OnboardingFlow.showStartDayScreen()
                end)
            end)
        end)
    end)
end

--[[
	Step 1: Show Tom Nook dialogue sequence
]]
function OnboardingFlow.showDialogue(onComplete: () -> ())
    print("[OnboardingFlow] 💬 Showing Tom Nook dialogue...")

    -- Use existing DialogueGUI module
    local dialogue = DialogueGUI.new()

    -- Show dialogue sequence
    dialogue:ShowSequence(ONBOARDING_DIALOGUE, {
        onComplete = function()
            print("[OnboardingFlow] ✅ Dialogue complete")
            onComplete()
        end,
    })
end

--[[
	Step 2: Show island selection screen
	TODO: Create island selection GUI
]]
function OnboardingFlow.showIslandSelection(onComplete: (island: { name: string, theme: string }) -> ())
    print("[OnboardingFlow] 🏝️ Showing island selection...")

    -- TODO: Create island selection GUI in Studio
    -- For now, auto-select first island
    task.wait(1)

    local selectedIsland = ISLAND_OPTIONS[1]
    print(string.format("[OnboardingFlow] ✅ Island selected: %s", selectedIsland.name))

    onComplete(selectedIsland)
end

--[[
	Step 3: Load the island with loading screen
]]
function OnboardingFlow.loadIsland(island: { name: string, theme: string }, onComplete: () -> ())
    print(string.format("[OnboardingFlow] 📦 Loading island: %s", island.name))

    -- Show loading screen with progress bar
    LoadingScreen.show(string.format("Loading %s...", island.name), true)

    -- Simulate island loading with progress updates
    task.spawn(function()
        -- Load terrain
        task.wait(0.5)
        LoadingScreen.setProgress(0.2)
        LoadingScreen.setStatus("Generating terrain...")

        -- Load vegetation
        task.wait(0.5)
        LoadingScreen.setProgress(0.4)
        LoadingScreen.setStatus("Planting trees...")

        -- Load buildings
        task.wait(0.5)
        LoadingScreen.setProgress(0.6)
        LoadingScreen.setStatus("Building structures...")

        -- Load wildlife
        task.wait(0.5)
        LoadingScreen.setProgress(0.8)
        LoadingScreen.setStatus("Adding wildlife...")

        -- Finalize
        task.wait(0.5)
        LoadingScreen.setProgress(1.0)
        LoadingScreen.setStatus("Almost ready...")

        task.wait(0.5)

        -- Hide loading screen
        LoadingScreen.hide()

        print("[OnboardingFlow] ✅ Island loaded")
        onComplete()
    end)
end

--[[
	Step 4: Play arrival cutscene (camera pan, fade in)
]]
function OnboardingFlow.playArrivalCutscene(onComplete: () -> ())
    print("[OnboardingFlow] 🎥 Playing arrival cutscene...")

    local cutscene = CutsceneManager.new()

    -- Find a nice spot to show (e.g., spawn location or Town Square)
    local spawnLocation = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("TownSquare")

    if not spawnLocation then
        warn("[OnboardingFlow] ⚠️ No spawn location found - skipping cutscene")
        onComplete()
        return
    end

    -- Cutscene sequence:
    -- 1. Fade from black
    -- 2. Pan camera over island
    -- 3. Focus on player spawn
    -- 4. Fade out and reset camera
    cutscene:startSequence({
        { type = "fade", direction = "out", duration = 1.5 }, -- Fade from black
        { type = "camera", target = spawnLocation, duration = 3, offset = CFrame.new(0, 10, 20) }, -- High angle view
        { type = "wait", duration = 2 }, -- Hold for a moment
        { type = "camera", target = spawnLocation, duration = 2, offset = CFrame.new(0, 2, 5) }, -- Lower to player level
        { type = "wait", duration = 1 },
        { type = "reset" }, -- Give control back to player
    }, function()
        print("[OnboardingFlow] ✅ Cutscene complete")
        onComplete()
    end)
end

--[[
	Step 5: Show start day screen with welcome message and start button
]]
function OnboardingFlow.showStartDayScreen()
    print("[OnboardingFlow] 🌅 Showing start day screen...")

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Create start day GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StartDayGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.Parent = playerGui

    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = GUIContentManager.LoadingScreen.styling.overlayColor
    overlay.BackgroundTransparency = GUIContentManager.LoadingScreen.styling.overlayTransparency
    overlay.Parent = screenGui

    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Size = UDim2.fromScale(0.6, 0.4)
    container.BackgroundColor3 = GUIContentManager.LoadingScreen.styling.backgroundColor
    container.BackgroundTransparency = 0
    container.Parent = overlay

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, GUIContentManager.LoadingScreen.styling.cornerRadius)
    containerCorner.Parent = container

    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = GUIContentManager.LoadingScreen.styling.titleColor
    containerStroke.Transparency = 0.3
    containerStroke.Thickness = 2
    containerStroke.Parent = container

    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 20)
    layout.Parent = container

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 30)
    padding.PaddingBottom = UDim.new(0, 30)
    padding.PaddingLeft = UDim.new(0, 30)
    padding.PaddingRight = UDim.new(0, 30)
    padding.Parent = container

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.titleColor
    titleLabel.TextSize = 32
    titleLabel.Text = "Welcome to Your Island!"
    titleLabel.Parent = container

    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, 0, 0, 30)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.subtitleColor
    subtitleLabel.TextSize = 18
    subtitleLabel.Text = "Your island adventure awaits..."
    subtitleLabel.Parent = container

    -- Tip
    local tipLabel = Instance.new("TextLabel")
    tipLabel.Name = "Tip"
    tipLabel.Size = UDim2.new(1, 0, 0, 40)
    tipLabel.BackgroundTransparency = 1
    tipLabel.Font = Enum.Font.Gotham
    tipLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.tipColor
    tipLabel.TextSize = 16
    tipLabel.Text = "💡 " .. GUIContentManager.getRandomLoadingTip()
    tipLabel.TextWrapped = true
    tipLabel.Parent = container

    -- Start button
    local startButton = Instance.new("TextButton")
    startButton.Name = "StartButton"
    startButton.Size = GUIContentManager.LoadingScreen.buttons.start.size
    startButton.BackgroundColor3 = GUIContentManager.LoadingScreen.buttons.start.backgroundColor
    startButton.BackgroundTransparency = 0
    startButton.BorderSizePixel = 0
    startButton.AutoButtonColor = true
    startButton.Font = Enum.Font.GothamBold
    startButton.TextColor3 = GUIContentManager.LoadingScreen.buttons.start.textColor
    startButton.TextSize = 24
    startButton.Text = "Start Your Day"
    startButton.Parent = container

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, GUIContentManager.LoadingScreen.buttons.start.cornerRadius)
    buttonCorner.Parent = startButton

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = GUIContentManager.LoadingScreen.buttons.start.strokeColor
    buttonStroke.Transparency = 0
    buttonStroke.Thickness = GUIContentManager.LoadingScreen.buttons.start.strokeThickness
    buttonStroke.Parent = startButton

    -- Button click handler
    startButton.MouseButton1Click:Connect(function()
        print("[OnboardingFlow] 🎉 Starting the day!")
        screenGui:Destroy()
        OnboardingFlow.completeOnboarding()
    end)
end

--[[
	Step 6: Complete onboarding and give player control
]]
function OnboardingFlow.completeOnboarding()
    print("[OnboardingFlow] 🎉 Onboarding complete! Welcome to your island!")

    -- TODO: Set player spawn position
    -- TODO: Enable player movement
    -- TODO: Show HUD/inventory
    -- TODO: Play welcome music

    -- Fire remote to server to mark onboarding complete
    local onboardingRemote = ReplicatedStorage:FindFirstChild("RemoteEvents")
        and ReplicatedStorage.RemoteEvents:FindFirstChild("OnboardingComplete")

    if onboardingRemote then
        onboardingRemote:FireServer()
        print("[OnboardingFlow] ✅ Server notified of onboarding completion")
    end
end

--[[
	Example: Quick test of loading screen
]]
function OnboardingFlow.testLoadingScreen()
    LoadingScreen.show("Testing loading screen...", true)

    task.spawn(function()
        for i = 0, 10 do
            task.wait(0.3)
            LoadingScreen.setProgress(i / 10)
        end
        task.wait(1)
        LoadingScreen.hide()
    end)
end

--[[
	Example: Quick test of cutscene
]]
function OnboardingFlow.testCutscene()
    local cutscene = CutsceneManager.new()

    -- Find player's character
    local player = Players.LocalPlayer
    local character = player.Character

    if not character then
        warn("[OnboardingFlow] ⚠️ No character found")
        return
    end

    cutscene:startSequence({
        { type = "fade", direction = "in", duration = 1 },
        { type = "camera", target = character.Head, duration = 2, offset = CFrame.new(5, 3, 5) },
        { type = "wait", duration = 2 },
        { type = "fade", direction = "out", duration = 1 },
        { type = "reset" },
    })
end

return OnboardingFlow
