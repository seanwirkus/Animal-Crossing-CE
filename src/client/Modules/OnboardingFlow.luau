--[[
    OnboardingFlow.luau

    Orchestrates the complete onboarding experience:
    1) Tom Nook dialogue
    2) Island selection
    3) Loading screen
    4) Arrival cutscene
    5) Start-of-day handoff to OnboardingController stepper
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Modules
local DialogueGUI = require(script.Parent.DialogueGUI)
local CutsceneManager = require(script.Parent.CutsceneManager)
local LoadingScreen = require(script.Parent.LoadingScreen)
local GUIContentManager = require(script.Parent.GUIContentManager)
local OnboardingController = require(script.Parent.OnboardingController)

local OnboardingFlow = {
    _controller = nil,
    _isRunning = false,
    _islandSelectionGui = nil,
    _startDayGui = nil,
}

-- Dialogue beats
local ONBOARDING_DIALOGUE = {
    {
        villagerName = "Tom Nook",
        text = "Ah, welcome, welcome! So glad you could make it!",
    },
    {
        villagerName = "Tom Nook",
        text = "I'm Tom Nook, and I'll be helping you get settled on your very own island getaway!",
    },
    {
        villagerName = "Tom Nook",
        text = "First, let's pick out the perfect island layout for you.",
    },
    {
        villagerName = "Tom Nook",
        text = "Once we land, I'll help you place your starter home and get you set up.",
    },
}

-- Island options (placeholder themes)
local ISLAND_OPTIONS = {
    { name = "Coral Cove", theme = "Beach", description = "Sandy shores, palm trees, and gentle waves." },
    { name = "Forest Glen", theme = "Forest", description = "Lush trees, winding rivers, and cozy clearings." },
    { name = "Mountain Peak", theme = "Mountain", description = "Elevated views, waterfalls, and crisp air." },
    { name = "Flower Fields", theme = "Meadow", description = "Endless blooms, butterflies, and open skies." },
}

local function getPlayerGui(): PlayerGui
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function cleanupGui(gui: ScreenGui?)
    if gui and gui.Parent then
        gui:Destroy()
    end
end

local function fireTutorialCompleteRemote()
    if _G.OnboardingTutorialCompleteFired then
        return
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local tutorialCompleteRemote = remotes and remotes:FindFirstChild("TutorialComplete")

    if tutorialCompleteRemote then
        tutorialCompleteRemote:FireServer()
        _G.OnboardingTutorialCompleteFired = true
        print("[OnboardingFlow] ✅ Server notified of onboarding completion")
    else
        warn("[OnboardingFlow] ⚠️ TutorialComplete remote not found")
    end
end

local function ensureController(): OnboardingController
    local controller = OnboardingFlow._controller
    if controller then
        -- Controller already exists, just return it without re-setting callback
        return controller
    end

    -- Create new controller and set callback only once
    controller = OnboardingController.new()
    controller:setOnCompleteCallback(function()
        OnboardingFlow.completeOnboarding()
    end)
    controller:hide()
    controller:hideBoard()

    OnboardingFlow._controller = controller
    return controller
end

--[[
    Step 1: Tom Nook dialogue
]]
function OnboardingFlow.showDialogue(onComplete: () -> ())
    print("[OnboardingFlow] 💬 Showing onboarding dialogue...")

    local dialogue = DialogueGUI.new()
    local ok = dialogue:Init()
    if not ok then
        warn("[OnboardingFlow] ⚠️ DialogueGUI not found - skipping dialogue step")
        onComplete()
        return
    end

    dialogue:ShowSequence(ONBOARDING_DIALOGUE, {
        autoAdvance = false,
        onComplete = function()
            print("[OnboardingFlow] ✅ Dialogue complete")
            onComplete()
        end,
    })
end

--[[
    Step 2: Island selection UI
]]
function OnboardingFlow.showIslandSelection(onComplete: (island: { name: string, theme: string }) -> ())
    print("[OnboardingFlow] 🏝️ Rendering island selection UI...")

    local controller = ensureController()
    controller:hide()
    controller:hideBoard()

    cleanupGui(OnboardingFlow._islandSelectionGui)

    local playerGui = getPlayerGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "IslandSelectionGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 120
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    OnboardingFlow._islandSelectionGui = screenGui

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.Parent = screenGui

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Size = UDim2.fromScale(0.8, 0.7)
    container.BackgroundColor3 = GUIContentManager.LoadingScreen.styling.backgroundColor
    container.BorderSizePixel = 0
    container.Parent = overlay

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, GUIContentManager.LoadingScreen.styling.cornerRadius)
    containerCorner.Parent = container

    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = GUIContentManager.LoadingScreen.styling.titleColor
    containerStroke.Transparency = 0.2
    containerStroke.Thickness = 2
    containerStroke.Parent = container

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.PaddingLeft = UDim.new(0, 24)
    padding.PaddingRight = UDim.new(0, 24)
    padding.Parent = container

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 32
    title.TextColor3 = GUIContentManager.LoadingScreen.styling.titleColor
    title.Text = "Choose Your Island"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 28)
    subtitle.Position = UDim2.new(0, 0, 0, 40)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 18
    subtitle.TextColor3 = GUIContentManager.LoadingScreen.styling.subtitleColor
    subtitle.Text = "Each layout offers a different vibe—pick the one you like best!"
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = container

    local listFrame = Instance.new("Frame")
    listFrame.Name = "ListFrame"
    listFrame.Size = UDim2.new(1, 0, 1, -140)
    listFrame.Position = UDim2.new(0, 0, 0, 80)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = container

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.5, -16, 0, 140)
    grid.FillDirectionMaxCells = 2
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    grid.VerticalAlignment = Enum.VerticalAlignment.Top
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.CellPadding = UDim2.new(0, 16, 0, 16)
    grid.Parent = listFrame

    local selectedIsland: { name: string, theme: string }? = nil

    local function renderIslandCard(parent: Instance, island: { name: string, theme: string, description: string })
        local card = Instance.new("Frame")
        card.Name = island.name
        card.BackgroundColor3 = Color3.fromRGB(255, 252, 242)
        card.BorderSizePixel = 0
        card.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(180, 150, 110)
        stroke.Thickness = 2
        stroke.Transparency = 0.3
        stroke.Parent = card

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.Parent = card

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(1, 0, 0, 32)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 24
        nameLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.titleColor
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Text = island.name
        nameLabel.Parent = card

        local themeLabel = Instance.new("TextLabel")
        themeLabel.Name = "Theme"
        themeLabel.Size = UDim2.new(1, 0, 0, 22)
        themeLabel.Position = UDim2.new(0, 0, 0, 30)
        themeLabel.BackgroundTransparency = 1
        themeLabel.Font = Enum.Font.GothamSemibold
        themeLabel.TextSize = 18
        themeLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.subtitleColor
        themeLabel.TextXAlignment = Enum.TextXAlignment.Left
        themeLabel.Text = string.format("Theme: %s", island.theme)
        themeLabel.Parent = card

        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, 0, 0, 48)
        descLabel.Position = UDim2.new(0, 0, 0, 58)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 16
        descLabel.TextWrapped = true
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.tipColor
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Text = island.description
        descLabel.Parent = card

        local chooseButton = Instance.new("TextButton")
        chooseButton.Name = "Choose"
        chooseButton.Size = UDim2.new(0, 160, 0, 36)
        chooseButton.Position = UDim2.new(1, -180, 1, -46)
        chooseButton.AnchorPoint = Vector2.new(0, 0)
        chooseButton.BackgroundColor3 = GUIContentManager.LoadingScreen.buttons.start.backgroundColor
        chooseButton.TextColor3 = GUIContentManager.LoadingScreen.buttons.start.textColor
        chooseButton.AutoButtonColor = true
        chooseButton.Font = Enum.Font.GothamBold
        chooseButton.TextSize = 18
        chooseButton.Text = "Choose"
        chooseButton.BorderSizePixel = 0
        chooseButton.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, GUIContentManager.LoadingScreen.buttons.start.cornerRadius)
        btnCorner.Parent = chooseButton

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = GUIContentManager.LoadingScreen.buttons.start.strokeColor
        btnStroke.Transparency = 0.2
        btnStroke.Thickness = GUIContentManager.LoadingScreen.buttons.start.strokeThickness
        btnStroke.Parent = chooseButton

        chooseButton.MouseButton1Click:Connect(function()
            selectedIsland = island
            title.Text = string.format("Choose Your Island • %s", island.name)

            -- Update visual selection
            for _, sibling in ipairs(listFrame:GetChildren()) do
                if sibling:IsA("Frame") then
                    local siblingStroke = sibling:FindFirstChildOfClass("UIStroke")
                    if siblingStroke then
                        siblingStroke.Color = Color3.fromRGB(180, 150, 110)
                        siblingStroke.Thickness = 2
                    end
                end
            end

            stroke.Color = GUIContentManager.LoadingScreen.buttons.start.backgroundColor
            stroke.Thickness = 3
        end)
    end

    for _, island in ipairs(ISLAND_OPTIONS) do
        renderIslandCard(listFrame, island)
    end

    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 60)
    footer.Position = UDim2.new(0, 0, 1, -60)
    footer.BackgroundTransparency = 1
    footer.Parent = container

    local footerLayout = Instance.new("UIListLayout")
    footerLayout.FillDirection = Enum.FillDirection.Horizontal
    footerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    footerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    footerLayout.Padding = UDim.new(0, 12)
    footerLayout.Parent = footer

    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "Cancel"
    cancelButton.Size = UDim2.new(0, 140, 0, 44)
    cancelButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelButton.Font = Enum.Font.Gotham
    cancelButton.TextSize = 18
    cancelButton.AutoButtonColor = true
    cancelButton.Text = "Maybe Later"
    cancelButton.BorderSizePixel = 0
    cancelButton.Parent = footer

    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 10)
    cancelCorner.Parent = cancelButton

    cancelButton.MouseButton1Click:Connect(function()
        print("[OnboardingFlow] ℹ️ Player skipped island selection for now")
        cleanupGui(screenGui)
        OnboardingFlow._islandSelectionGui = nil
        onComplete(ISLAND_OPTIONS[1])
    end)

    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "Confirm"
    confirmButton.Size = UDim2.new(0, 200, 0, 44)
    confirmButton.BackgroundColor3 = GUIContentManager.LoadingScreen.buttons.start.backgroundColor
    confirmButton.TextColor3 = GUIContentManager.LoadingScreen.buttons.start.textColor
    confirmButton.Font = Enum.Font.GothamBold
    confirmButton.TextSize = 20
    confirmButton.Text = "Fly to Island"
    confirmButton.AutoButtonColor = true
    confirmButton.BorderSizePixel = 0
    confirmButton.Parent = footer

    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, GUIContentManager.LoadingScreen.buttons.start.cornerRadius)
    confirmCorner.Parent = confirmButton

    local confirmStroke = Instance.new("UIStroke")
    confirmStroke.Color = GUIContentManager.LoadingScreen.buttons.start.strokeColor
    confirmStroke.Transparency = 0.1
    confirmStroke.Thickness = GUIContentManager.LoadingScreen.buttons.start.strokeThickness
    confirmStroke.Parent = confirmButton

    confirmButton.MouseButton1Click:Connect(function()
        if not selectedIsland then
            warn("[OnboardingFlow] ⚠️ No island selected - defaulting to first option")
            selectedIsland = ISLAND_OPTIONS[1]
        end

        cleanupGui(screenGui)
        OnboardingFlow._islandSelectionGui = nil
        print(string.format("[OnboardingFlow] ✅ Island selected: %s", selectedIsland.name))
        onComplete(selectedIsland)
    end)
end

--[[
    Step 3: Loading screen
]]
function OnboardingFlow.loadIsland(island: { name: string, theme: string }, onComplete: () -> ())
    print(string.format("[OnboardingFlow] 📦 Loading island: %s", island.name))

    -- Island loading happens asynchronously in background
    -- Loading screen and progress are handled by the caller (in onboarding start)
    task.spawn(function()
        -- Simulate island initialization in background
        task.wait(0.5)
        print("[OnboardingFlow] ✅ Island load sequence finished")
        onComplete()
    end)
end

--[[
    Step 4: Arrival cutscene
]]
function OnboardingFlow.playArrivalCutscene(onComplete: () -> ())
    print("[OnboardingFlow] 🎥 Playing arrival cutscene...")

    local cutscene = CutsceneManager.new()

    -- Pick a nice target: SpawnLocation or TownSquare
    local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("TownSquare")
    if not spawnLocation then
        warn("[OnboardingFlow] ⚠️ No spawn location found - skipping cutscene")
        onComplete()
        return
    end

    cutscene:startSequence({
        { type = "fade", direction = "out", duration = 1.2 },
        { type = "camera", target = spawnLocation, duration = 3, offset = CFrame.new(0, 12, 20) },
        { type = "wait", duration = 1.5 },
        { type = "camera", target = spawnLocation, duration = 2.5, offset = CFrame.new(0, 4, 8) },
        { type = "wait", duration = 1 },
        { type = "reset" },
    }, function()
        print("[OnboardingFlow] ✅ Cutscene complete")
        onComplete()
    end)
end

--[[
    Step 5: Start-of-day screen leading into the stepper
]]
function OnboardingFlow.showStartDayScreen()
    print("[OnboardingFlow] 🌅 Showing start-of-day screen...")

    local controller = ensureController()
    controller:hideBoard()
    controller:hide()

    cleanupGui(OnboardingFlow._startDayGui)

    local playerGui = getPlayerGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StartDayGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 130
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    OnboardingFlow._startDayGui = screenGui

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = GUIContentManager.LoadingScreen.styling.overlayColor
    overlay.BackgroundTransparency = GUIContentManager.LoadingScreen.styling.overlayTransparency
    overlay.Parent = screenGui

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Size = UDim2.fromScale(0.6, 0.42)
    container.BackgroundColor3 = GUIContentManager.LoadingScreen.styling.backgroundColor
    container.Parent = overlay

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, GUIContentManager.LoadingScreen.styling.cornerRadius)
    containerCorner.Parent = container

    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = GUIContentManager.LoadingScreen.styling.titleColor
    containerStroke.Transparency = 0.3
    containerStroke.Thickness = 2
    containerStroke.Parent = container

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 18)
    layout.Parent = container

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 30)
    padding.PaddingBottom = UDim.new(0, 30)
    padding.PaddingLeft = UDim.new(0, 30)
    padding.PaddingRight = UDim.new(0, 30)
    padding.Parent = container

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.titleColor
    titleLabel.TextSize = 28
    titleLabel.Text = "Welcome to Your Island!"
    titleLabel.Parent = container

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, 0, 0, 30)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.subtitleColor
    subtitleLabel.TextSize = 18
    subtitleLabel.Text = "Let's get you settled with a quick walkthrough."
    subtitleLabel.Parent = container

    local tipLabel = Instance.new("TextLabel")
    tipLabel.Name = "Tip"
    tipLabel.Size = UDim2.new(1, 0, 0, 42)
    tipLabel.BackgroundTransparency = 1
    tipLabel.Font = Enum.Font.Gotham
    tipLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.tipColor
    tipLabel.TextSize = 16
    tipLabel.TextWrapped = true
    tipLabel.Text = "💡 " .. GUIContentManager.getRandomLoadingTip()
    tipLabel.Parent = container

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
    startButton.Text = "Start"
    startButton.Parent = container

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, GUIContentManager.LoadingScreen.buttons.start.cornerRadius)
    buttonCorner.Parent = startButton

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = GUIContentManager.LoadingScreen.buttons.start.strokeColor
    buttonStroke.Transparency = 0
    buttonStroke.Thickness = GUIContentManager.LoadingScreen.buttons.start.strokeThickness
    buttonStroke.Parent = startButton

    startButton.MouseButton1Click:Connect(function()
        print("[OnboardingFlow] 🎬 Starting onboarding")
        _G.PreStartCompleted = true
        cleanupGui(screenGui)
        OnboardingFlow._startDayGui = nil

        controller:showBoard()
        controller:start()
        controller:show()
    end)
end

--[[
    Entry point
]]
function OnboardingFlow.start()
    if OnboardingFlow._isRunning then
        print("[OnboardingFlow] 🔁 Onboarding already running - ignoring duplicate start")
        return
    end

    OnboardingFlow._isRunning = true
    ensureController()

    print("[OnboardingFlow] 🎬 Starting onboarding sequence...")

    -- Skip dialogue and island selection - go straight to Coral Cove
    local defaultIsland = ISLAND_OPTIONS[1] -- Coral Cove
    print("[OnboardingFlow] ⏭️ Skipping dialogue and island selection - loading Coral Cove")

    -- NORMAL FLOW: Show loading screen FIRST, then cutscene, then island
    print("[OnboardingFlow] 📦 Showing loading screen first...")
    LoadingScreen.show(string.format("Flying to %s...", defaultIsland.name), true)

    task.spawn(function()
        -- Show loading progress
        task.wait(0.4)
        LoadingScreen.setProgress(0.2)
        LoadingScreen.setStatus("Charting the island layout...")

        task.wait(0.6)
        LoadingScreen.setProgress(0.45)
        LoadingScreen.setStatus("Planting trees and flowers...")

        task.wait(0.6)
        LoadingScreen.setProgress(0.7)
        LoadingScreen.setStatus("Building the airport...")

        task.wait(0.6)
        LoadingScreen.setProgress(0.9)
        LoadingScreen.setStatus("Preparing your starter supplies...")

        task.wait(0.5)
        LoadingScreen.setProgress(1)
        LoadingScreen.setStatus("Ready to land!")

        task.wait(1)
        LoadingScreen.hide()

        -- After loading screen, play cutscene
        print("[OnboardingFlow] 🎥 Now playing arrival cutscene...")
        OnboardingFlow.playArrivalCutscene(function()
            print("[OnboardingFlow] ✅ Cutscene complete, onboarding done!")
            OnboardingFlow.completeOnboarding()
        end)
    end)
end

--[[
    Finalization
]]
function OnboardingFlow.completeOnboarding()
    print("[OnboardingFlow] 🎉 Onboarding complete! Welcome to your island!")

    cleanupGui(OnboardingFlow._islandSelectionGui)
    cleanupGui(OnboardingFlow._startDayGui)
    OnboardingFlow._islandSelectionGui = nil
    OnboardingFlow._startDayGui = nil
    OnboardingFlow._isRunning = false

    local controller = OnboardingFlow._controller
    if controller and controller.isActive then
        controller:hide()
    end

    fireTutorialCompleteRemote()
end

--[[
    Debug helpers
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

function OnboardingFlow.testCutscene()
    local cutscene = CutsceneManager.new()

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
