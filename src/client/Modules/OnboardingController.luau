--[[
	OnboardingController.luau
	
	Guides new players through the initial setup:
	1. Welcome to your island
	2. Learn to move around
	3. Find the DIY Workbench
	4. Craft basic tools
	5. Build your first home (tent)
	6. Tutorial complete!
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local OnboardingController = {}
OnboardingController.__index = OnboardingController

-- Singleton
local _instance = nil

-- Tutorial steps
local STEPS = {
    WELCOME = 1,
    MOVEMENT = 2,
    FIND_WORKBENCH = 3,
    CRAFT_TOOLS = 4,
    BUILD_HOME = 5,
    COMPLETE = 6,
}

local function findLargestPart(model: Model?): BasePart?
    if not model then
        return nil
    end

    local chosen: BasePart? = nil
    local bestScore = -math.huge

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local nameLower = descendant.Name:lower()
            local preferred = 0
            if nameLower == "front" or nameLower == "back" then
                preferred = 3
            elseif nameLower:find("board") then
                preferred = 2
            elseif nameLower:find("stand") then
                preferred = -1
            end

            local area = descendant.Size.X * descendant.Size.Y
            local score = preferred * 1e6 + area

            if score > bestScore then
                chosen = descendant
                bestScore = score
            end
        end
    end

    return chosen
end

function OnboardingController.new()
    if _instance then
        return _instance
    end

    local self = setmetatable({}, OnboardingController)

    self.currentStep = STEPS.WELCOME
    self.isActive = false
    self._gui = nil
    self._textLabel = nil
    self._buttonFrame = nil
    self._boardSurfaceGui = nil
    self._boardTextLabel = nil
    self._boardHeaderLabel = nil

    self:createGUI()

    _instance = self
    return self
end

function OnboardingController:createGUI()
    -- Create ScreenGui
    local screenGui = playerGui:FindFirstChild("OnboardingGUI")
    if screenGui then
        screenGui:Destroy()
    end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OnboardingGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100 -- Above everything else
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    self._gui = screenGui

    -- Tutorial box (bottom center)
    local tutorialBox = Instance.new("Frame")
    tutorialBox.Name = "TutorialBox"
    tutorialBox.Size = UDim2.new(0, 600, 0, 150)
    tutorialBox.Position = UDim2.new(0.5, -300, 1, -180)
    tutorialBox.BackgroundColor3 = Color3.fromRGB(255, 251, 231)
    tutorialBox.BorderSizePixel = 0
    tutorialBox.Parent = screenGui

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 12)
    boxCorner.Parent = tutorialBox

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(139, 90, 43)
    boxStroke.Thickness = 3
    boxStroke.Parent = tutorialBox

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0, 15, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 40
    iconLabel.Text = "🏝️"
    iconLabel.Parent = tutorialBox

    -- Text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -90, 1, -80)
    textLabel.Position = UDim2.new(0, 85, 0, 10)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 16
    textLabel.TextColor3 = Color3.fromRGB(60, 50, 40)
    textLabel.Text = "Welcome to your island!"
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.Parent = tutorialBox

    self._textLabel = textLabel

    -- Button frame
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "Buttons"
    buttonFrame.Size = UDim2.new(1, -20, 0, 40)
    buttonFrame.Position = UDim2.new(0, 10, 1, -50)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = tutorialBox

    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonFrame

    self._buttonFrame = buttonFrame

    -- Create default next button
    self:createNextButton()
    self:_setupBoardDisplay()
    self:_updateBoardDisplay(self._textLabel.Text)
end

function OnboardingController:_setupBoardDisplay()
    -- Whiteboard system removed - skipping board display
    return
end

function OnboardingController:_setBoardDisplayVisible(isVisible: boolean)
    if self._boardSurfaceGui then
        self._boardSurfaceGui.Enabled = isVisible
    end
end

function OnboardingController:_updateBoardDisplay(text: string, headerText: string?)
    if not self._boardTextLabel then
        return
    end

    if self._boardHeaderLabel then
        self._boardHeaderLabel.Text = headerText or "Onboarding"
    end

    self._boardTextLabel.Text = text or ""
end

function OnboardingController:createNextButton()
    -- Clear existing buttons
    for _, child in ipairs(self._buttonFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local nextButton = Instance.new("TextButton")
    nextButton.Name = "NextButton"
    nextButton.Size = UDim2.new(0, 120, 0, 40)
    nextButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    nextButton.BorderSizePixel = 0
    nextButton.Font = Enum.Font.GothamBold
    nextButton.TextSize = 16
    nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    nextButton.Text = "Next →"
    nextButton.Parent = self._buttonFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = nextButton

    nextButton.MouseButton1Click:Connect(function()
        self:nextStep()
    end)

    return nextButton
end

function OnboardingController:start()
    if self.isActive then
        return
    end

    print("[OnboardingController] Starting tutorial...")

    self.isActive = true
    self.currentStep = STEPS.WELCOME
    self._gui.Enabled = true
    self:_setBoardDisplayVisible(true)

    self:showStep(STEPS.WELCOME)
end

function OnboardingController:showStep(step)
    self.currentStep = step
    local headerTitle = "Onboarding"

    if step == STEPS.WELCOME then
        headerTitle = "Welcome to Your Island"
        self._textLabel.Text =
            "Welcome to your island! 🏝️\n\nYou've just arrived on this beautiful deserted island. Let's get you settled in!"
        self:createNextButton()
    elseif step == STEPS.MOVEMENT then
        headerTitle = "Movement 101"
        self._textLabel.Text =
            "Movement Tutorial 🏃\n\nUse WASD keys to move around.\nPress SPACE to jump.\nMove your mouse to look around."
        self:createNextButton()
    elseif step == STEPS.FIND_WORKBENCH then
        headerTitle = "Find the Workbench"
        self._textLabel.Text =
            "Find the DIY Workbench 🔨\n\nLook around your island for a wooden workbench. Walk up to it and press the interaction button to craft items."

        local skipButton = Instance.new("TextButton")
        skipButton.Name = "SkipButton"
        skipButton.Size = UDim2.new(0, 120, 0, 40)
        skipButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
        skipButton.BorderSizePixel = 0
        skipButton.Font = Enum.Font.Gotham
        skipButton.TextSize = 16
        skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        skipButton.Text = "Skip Tutorial"
        skipButton.Parent = self._buttonFrame

        local skipCorner = Instance.new("UICorner")
        skipCorner.CornerRadius = UDim.new(0, 8)
        skipCorner.Parent = skipButton

        skipButton.MouseButton1Click:Connect(function()
            self:complete()
        end)
    elseif step == STEPS.CRAFT_TOOLS then
        headerTitle = "Craft Your Tools"
        self._textLabel.Text =
            "Craft Your First Tools 🛠️\n\nAt the workbench, craft basic tools like:\n• Fishing Rod\n• Net\n• Shovel\n• Axe\n\nThese will help you gather resources!"
        self:createNextButton()
    elseif step == STEPS.BUILD_HOME then
        headerTitle = "Build Your Home"
        self._textLabel.Text =
            "Build Your Home 🏠\n\nEvery island needs a home! Use the resources you've gathered to build your first tent. You can upgrade it later!"

        local buildButton = Instance.new("TextButton")
        buildButton.Name = "BuildButton"
        buildButton.Size = UDim2.new(0, 150, 0, 40)
        buildButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
        buildButton.BorderSizePixel = 0
        buildButton.Font = Enum.Font.GothamBold
        buildButton.TextSize = 16
        buildButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        buildButton.Text = "Build Home"
        buildButton.Parent = self._buttonFrame

        local buildCorner = Instance.new("UICorner")
        buildCorner.CornerRadius = UDim.new(0, 8)
        buildCorner.Parent = buildButton

        buildButton.MouseButton1Click:Connect(function()
            self:buildHome()
        end)
    elseif step == STEPS.COMPLETE then
        headerTitle = "Tutorial Complete"
        self._textLabel.Text =
            "Tutorial Complete! 🎉\n\nYou're all set! Explore your island, gather resources, and make it your own.\n\nPress ESC anytime to open the menu."

        local doneButton = Instance.new("TextButton")
        doneButton.Name = "DoneButton"
        doneButton.Size = UDim2.new(0, 120, 0, 40)
        doneButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        doneButton.BorderSizePixel = 0
        doneButton.Font = Enum.Font.GothamBold
        doneButton.TextSize = 16
        doneButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        doneButton.Text = "Let's Go!"
        doneButton.Parent = self._buttonFrame

        local doneCorner = Instance.new("UICorner")
        doneCorner.CornerRadius = UDim.new(0, 8)
        doneCorner.Parent = doneButton

        doneButton.MouseButton1Click:Connect(function()
            self:finish()
        end)
    else
        self._textLabel.Text = "Next step coming soon!"
        self:createNextButton()
    end

    self:_updateBoardDisplay(self._textLabel.Text, headerTitle)
end

function OnboardingController:nextStep()
    if self.currentStep < STEPS.COMPLETE then
        self:showStep(self.currentStep + 1)
    end
end

function OnboardingController:buildHome()
    print("[OnboardingController] Building home...")

    -- Hide onboarding GUI during placement
    self:hide()

    -- Fire remote to server to trigger placement mode
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local buildHomeRemote = remotes:FindFirstChild("BuildPlayerHome")
        if buildHomeRemote then
            buildHomeRemote:FireServer()
            print("[OnboardingController] ✅ Requested home placement from server")
        else
            warn("[OnboardingController] BuildPlayerHome remote not found")
        end
    end

    -- Wait for home to be placed, then show completion
    -- The server will handle the placement flow
    task.wait(2) -- Give time for placement to start

    -- Move to complete step (will show after placement finishes)
    self:showStep(STEPS.COMPLETE)
end

function OnboardingController:complete()
    print("[OnboardingController] Tutorial completed")

    -- Fire remote to mark tutorial complete
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local tutorialCompleteRemote = remotes:FindFirstChild("TutorialComplete")
        if tutorialCompleteRemote then
            tutorialCompleteRemote:FireServer()
        end
    end

    self:finish()
end

function OnboardingController:finish()
    self.isActive = false
    self._gui.Enabled = false
    self:_setBoardDisplayVisible(false)

    print("[OnboardingController] Tutorial finished!")
end

function OnboardingController:hide()
    if self._gui then
        self._gui.Enabled = false
    end
    self:_setBoardDisplayVisible(false)
end

function OnboardingController:show()
    if self._gui then
        self._gui.Enabled = true
    end
    self:_setBoardDisplayVisible(self.isActive)
end

-- Setup remote listener for server to start tutorial
local function setupRemoteListener()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes then
        local startTutorialRemote = remotes:FindFirstChild("StartOnboarding")
        if not startTutorialRemote then
            startTutorialRemote = Instance.new("RemoteEvent")
            startTutorialRemote.Name = "StartOnboarding"
            startTutorialRemote.Parent = remotes
        end

        startTutorialRemote.OnClientEvent:Connect(function()
            local controller = OnboardingController.new()
            controller:start()
        end)
    end
end

-- Auto-setup
task.spawn(setupRemoteListener)

return OnboardingController
