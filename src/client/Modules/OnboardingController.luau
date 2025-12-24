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

-- Tutorial steps - simplified
local STEPS = {
    WELCOME = 1,
    MOVEMENT = 2,
    BUILD_HOME = 3,
    COMPLETE = 4,
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
    self._titleLabel = nil
    self._iconLabel = nil
    self._buttonFrame = nil
    self._boardSurfaceGui = nil
    self._boardTextLabel = nil
    self._boardHeaderLabel = nil
    self._onCompleteCallback = nil
    self.homePlaced = false

    self:createGUI()
    self:_connectHomePlacementUpdates()

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

    -- Tutorial box (bottom center) - Animal Crossing style
    local tutorialBox = Instance.new("Frame")
    tutorialBox.Name = "TutorialBox"
    tutorialBox.Size = UDim2.new(0, 650, 0, 180)
    tutorialBox.Position = UDim2.new(0.5, -325, 1, -200)
    tutorialBox.BackgroundColor3 = Color3.fromRGB(255, 250, 235) -- Warmer cream
    tutorialBox.BorderSizePixel = 0
    tutorialBox.Parent = screenGui

    -- Subtle shadow effect
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 8, 1, 8)
    shadow.Position = UDim2.new(0, 4, 0, 4)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.85
    shadow.ZIndex = -1
    shadow.Parent = tutorialBox

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 16)
    shadowCorner.Parent = shadow

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 16)
    boxCorner.Parent = tutorialBox

    -- Multiple stroke layers for depth
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(139, 90, 43) -- Brown border
    boxStroke.Thickness = 4
    boxStroke.Parent = tutorialBox

    -- Inner highlight stroke
    local innerFrame = Instance.new("Frame")
    innerFrame.Name = "InnerHighlight"
    innerFrame.Size = UDim2.new(1, -8, 1, -8)
    innerFrame.Position = UDim2.new(0, 4, 0, 4)
    innerFrame.BackgroundTransparency = 1
    innerFrame.Parent = tutorialBox

    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(255, 255, 255)
    innerStroke.Thickness = 2
    innerStroke.Transparency = 0.6
    innerStroke.Parent = innerFrame

    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 13)
    innerCorner.Parent = innerFrame

    -- Icon with background circle
    local iconCircle = Instance.new("Frame")
    iconCircle.Name = "IconCircle"
    iconCircle.Size = UDim2.new(0, 70, 0, 70)
    iconCircle.Position = UDim2.new(0, 20, 0, 20)
    iconCircle.BackgroundColor3 = Color3.fromRGB(255, 228, 181) -- Peach
    iconCircle.BorderSizePixel = 0
    iconCircle.Parent = tutorialBox

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0) -- Full circle
    circleCorner.Parent = iconCircle

    local circleStroke = Instance.new("UIStroke")
    circleStroke.Color = Color3.fromRGB(139, 90, 43)
    circleStroke.Thickness = 2
    circleStroke.Parent = iconCircle

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.Position = UDim2.new(0, 0, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 42
    iconLabel.Text = "🏝️"
    iconLabel.Parent = iconCircle

    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -110, 0, 30)
    titleLabel.Position = UDim2.new(0, 100, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = Color3.fromRGB(86, 60, 40) -- Dark brown
    titleLabel.Text = "Welcome to Your Island!"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = tutorialBox

    -- Text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -110, 1, -105)
    textLabel.Position = UDim2.new(0, 100, 0, 50)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 15
    textLabel.TextColor3 = Color3.fromRGB(70, 55, 45)
    textLabel.Text = "Welcome to your island!"
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.Parent = tutorialBox

    self._titleLabel = titleLabel
    self._textLabel = textLabel
    self._iconLabel = iconLabel

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

function OnboardingController:clearButtons()
    if not self._buttonFrame then
        return
    end

    for _, child in ipairs(self._buttonFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

function OnboardingController:_setupBoardDisplay()
    local function findBoardModel(): Model?
        local nameCandidates = { "Whiteboard", "whiteboard", "WHITEBOARD", "TutorialBoard" }
        for _, candidate in ipairs(nameCandidates) do
            local board = Workspace:FindFirstChild(candidate)
            if board and board:IsA("Model") then
                return board
            end
        end

        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") and string.find(string.lower(child.Name), "board") then
                return child
            end
        end

        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("Model") and string.find(string.lower(descendant.Name), "board") then
                return descendant
            end
        end

        return nil
    end

    local boardModel = findBoardModel()
    if not boardModel then
        warn("[OnboardingController] ⚠️ Whiteboard model not found - board display disabled")
        return
    end

    local targetPart = findLargestPart(boardModel)
    if not targetPart then
        warn("[OnboardingController] ⚠️ Board model found but no BasePart detected")
        return
    end

    local existingGui = targetPart:FindFirstChildOfClass("SurfaceGui")
    if existingGui and existingGui.Name == "OnboardingBoard" then
        existingGui:Destroy()
    end

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "OnboardingBoard"
    surfaceGui.Adornee = targetPart
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.CanvasSize = Vector2.new(1024, 640)
    surfaceGui.LightInfluence = 1
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    surfaceGui.Enabled = false
    surfaceGui.Parent = targetPart

    local container = Instance.new("Frame")
    container.Size = UDim2.fromScale(1, 1)
    container.BackgroundColor3 = Color3.fromRGB(255, 253, 243)
    container.BackgroundTransparency = 0.08
    container.BorderSizePixel = 0
    container.Parent = surfaceGui

    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(120, 95, 72)
    border.Thickness = 4
    border.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 24)
    corner.Parent = container

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, -40, 0, 70)
    header.Position = UDim2.new(0, 20, 0, 20)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 40
    header.TextColor3 = Color3.fromRGB(86, 60, 40)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "Onboarding"
    header.Parent = container

    local body = Instance.new("TextLabel")
    body.Name = "Body"
    body.Size = UDim2.new(1, -40, 1, -120)
    body.Position = UDim2.new(0, 20, 0, 100)
    body.BackgroundTransparency = 1
    body.Font = Enum.Font.Gotham
    body.TextSize = 24
    body.TextWrapped = true
    body.TextColor3 = Color3.fromRGB(70, 55, 45)
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Text = ""
    body.Parent = container

    self._boardSurfaceGui = surfaceGui
    self._boardTextLabel = body
    self._boardHeaderLabel = header
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
    self:clearButtons()

    local nextButton = Instance.new("TextButton")
    nextButton.Name = "NextButton"
    nextButton.Size = UDim2.new(0, 140, 0, 45)
    nextButton.BackgroundColor3 = Color3.fromRGB(144, 202, 119) -- AC green
    nextButton.BorderSizePixel = 0
    nextButton.Font = Enum.Font.GothamBold
    nextButton.TextSize = 17
    nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    nextButton.Text = "Next →"
    nextButton.AutoButtonColor = false
    nextButton.Parent = self._buttonFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = nextButton

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(100, 150, 85)
    btnStroke.Thickness = 2
    btnStroke.Parent = nextButton

    -- Hover effect
    nextButton.MouseEnter:Connect(function()
        nextButton.BackgroundColor3 = Color3.fromRGB(164, 222, 139)
    end)

    nextButton.MouseLeave:Connect(function()
        nextButton.BackgroundColor3 = Color3.fromRGB(144, 202, 119)
    end)

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
    local icon = "🏝️"

    self:clearButtons()

    if step == STEPS.WELCOME then
        headerTitle = "Welcome to Your Island"
        icon = "🏝️"
        self._titleLabel.Text = "Welcome to Your Island!"
        self._textLabel.Text =
            "You've just arrived on this beautiful island! I've given you some starter tools. Let's get you settled in!"
        self:createNextButton()
    elseif step == STEPS.MOVEMENT then
        headerTitle = "Movement"
        icon = "🏃"
        self._titleLabel.Text = "Controls"
        self._textLabel.Text =
            "Use WASD to move around\nPress SPACE to jump\nPress T to open your tool wheel\nPress E to open inventory"
        self:createNextButton()
    elseif step == STEPS.BUILD_HOME then
        headerTitle = "Build Home"
        icon = "🏠"
        self._titleLabel.Text = "Place Your Tent"
        self._textLabel.Text =
            "Let's place your starter tent! You can place it now or finish onboarding and place it later from the Home menu."

        local buildButton = Instance.new("TextButton")
        buildButton.Name = "BuildButton"
        buildButton.Size = UDim2.new(0, 160, 0, 45)
        buildButton.BackgroundColor3 = Color3.fromRGB(115, 169, 219)
        buildButton.BorderSizePixel = 0
        buildButton.Font = Enum.Font.GothamBold
        buildButton.TextSize = 17
        buildButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        buildButton.Text = "🏠 Place Tent"
        buildButton.AutoButtonColor = false
        buildButton.Parent = self._buttonFrame

        local buildCorner = Instance.new("UICorner")
        buildCorner.CornerRadius = UDim.new(0, 10)
        buildCorner.Parent = buildButton

        local buildStroke = Instance.new("UIStroke")
        buildStroke.Color = Color3.fromRGB(85, 139, 189)
        buildStroke.Thickness = 2
        buildStroke.Parent = buildButton

        buildButton.MouseEnter:Connect(function()
            buildButton.BackgroundColor3 = Color3.fromRGB(135, 189, 239)
        end)

        buildButton.MouseLeave:Connect(function()
            buildButton.BackgroundColor3 = Color3.fromRGB(115, 169, 219)
        end)

        buildButton.MouseButton1Click:Connect(function()
            self:buildHome()
        end)

        -- Continue button so the player is never blocked by placement timing
        local continueButton = Instance.new("TextButton")
        continueButton.Name = "ContinueButton"
        continueButton.Size = UDim2.new(0, 160, 0, 45)
        continueButton.BackgroundColor3 = Color3.fromRGB(144, 202, 119)
        continueButton.BorderSizePixel = 0
        continueButton.Font = Enum.Font.GothamBold
        continueButton.TextSize = 17
        continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        continueButton.Text = "I'll Place Later →"
        continueButton.AutoButtonColor = false
        continueButton.Parent = self._buttonFrame

        local continueCorner = Instance.new("UICorner")
        continueCorner.CornerRadius = UDim.new(0, 10)
        continueCorner.Parent = continueButton

        local continueStroke = Instance.new("UIStroke")
        continueStroke.Color = Color3.fromRGB(100, 150, 85)
        continueStroke.Thickness = 2
        continueStroke.Parent = continueButton

        continueButton.MouseEnter:Connect(function()
            continueButton.BackgroundColor3 = Color3.fromRGB(164, 222, 139)
        end)

        continueButton.MouseLeave:Connect(function()
            continueButton.BackgroundColor3 = Color3.fromRGB(144, 202, 119)
        end)

        continueButton.MouseButton1Click:Connect(function()
            self:nextStep()
        end)

        -- Add skip button
        local skipButton = Instance.new("TextButton")
        skipButton.Name = "SkipButton"
        skipButton.Size = UDim2.new(0, 100, 0, 45)
        skipButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        skipButton.BorderSizePixel = 0
        skipButton.Font = Enum.Font.Gotham
        skipButton.TextSize = 15
        skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        skipButton.Text = "Skip"
        skipButton.AutoButtonColor = false
        skipButton.Parent = self._buttonFrame

        local skipCorner = Instance.new("UICorner")
        skipCorner.CornerRadius = UDim.new(0, 10)
        skipCorner.Parent = skipButton

        skipButton.MouseButton1Click:Connect(function()
            self:complete()
        end)
    elseif step == STEPS.COMPLETE then
        headerTitle = "All Set!"
        icon = "🎉"
        self._titleLabel.Text = "You're Ready!"
        self._textLabel.Text =
            "Explore your island and have fun!\n\nKey Tips:\n• T = Tool wheel\n• E = Inventory\n• P = NookPhone\n• Use axe on trees, shovel on rocks"

        local doneButton = Instance.new("TextButton")
        doneButton.Name = "DoneButton"
        doneButton.Size = UDim2.new(0, 140, 0, 45)
        doneButton.BackgroundColor3 = Color3.fromRGB(255, 195, 77) -- Golden
        doneButton.BorderSizePixel = 0
        doneButton.Font = Enum.Font.GothamBold
        doneButton.TextSize = 17
        doneButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        doneButton.Text = "Let's Go!"
        doneButton.AutoButtonColor = false
        doneButton.Parent = self._buttonFrame

        local doneCorner = Instance.new("UICorner")
        doneCorner.CornerRadius = UDim.new(0, 10)
        doneCorner.Parent = doneButton

        local doneStroke = Instance.new("UIStroke")
        doneStroke.Color = Color3.fromRGB(215, 155, 37)
        doneStroke.Thickness = 2
        doneStroke.Parent = doneButton

        doneButton.MouseEnter:Connect(function()
            doneButton.BackgroundColor3 = Color3.fromRGB(255, 215, 117)
        end)

        doneButton.MouseLeave:Connect(function()
            doneButton.BackgroundColor3 = Color3.fromRGB(255, 195, 77)
        end)

        doneButton.MouseButton1Click:Connect(function()
            self:finish()
        end)
    else
        self._titleLabel.Text = "Coming Soon"
        self._textLabel.Text = "Next step coming soon!"
        self:createNextButton()
    end

    -- Update icon
    if self._iconLabel then
        self._iconLabel.Text = icon
    end

    self:_updateBoardDisplay(self._textLabel.Text, headerTitle)
    self:_setBoardDisplayVisible(true)
end

function OnboardingController:nextStep()
    if self.currentStep < STEPS.COMPLETE then
        self:showStep(self.currentStep + 1)
    end
end

function OnboardingController:buildHome()
    print("[OnboardingController] Building home...")

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

    -- Keep onboarding UI visible so players can continue through tips even if they place later
end

function OnboardingController:complete()
    print("[OnboardingController] Tutorial completed")

    if _G.OnboardingTutorialCompleteFired then
        print("[OnboardingController] Tutorial completion already reported - skipping duplicate")
    end

    -- Fire remote to mark tutorial complete
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local tutorialCompleteRemote = remotes:FindFirstChild("TutorialComplete")
        if tutorialCompleteRemote then
            tutorialCompleteRemote:FireServer()
            _G.OnboardingTutorialCompleteFired = true
        end
    end

    if self._onCompleteCallback then
        self._onCompleteCallback()
    end

    self:finish()
end

function OnboardingController:finish()
    self.isActive = false
    self._gui.Enabled = false
    self:_setBoardDisplayVisible(false)

    print("[OnboardingController] Tutorial finished!")
end

function OnboardingController:_connectHomePlacementUpdates()
    local remotes = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
    if not remotes then
        warn("[OnboardingController] RemoteEvents not found for home placement updates")
        return
    end

    local homeDataUpdate = remotes:WaitForChild("HomeDataUpdate", 5)
    if not homeDataUpdate then
        warn("[OnboardingController] HomeDataUpdate remote not found")
        return
    end

    homeDataUpdate.OnClientEvent:Connect(function(homeData)
        if homeData and homeData.owner == player.UserId then
            self.homePlaced = true
            if self.isActive and self.currentStep == STEPS.BUILD_HOME then
                self:showStep(STEPS.COMPLETE)
            end
        end
    end)
end

function OnboardingController:showBoard()
    self:_setBoardDisplayVisible(true)
end

function OnboardingController:hideBoard()
    self:_setBoardDisplayVisible(false)
end

function OnboardingController:setOnCompleteCallback(callback: (() -> ())?)
    self._onCompleteCallback = callback
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

return OnboardingController
