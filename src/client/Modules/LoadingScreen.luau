--!strict

--[[
        LoadingScreen.luau

        Responsive Animal Crossing-style loading screen with random tips, optional
        progress display, and reusable API used by onboarding flows.

        Exposed API:
                LoadingScreen.init() -- boot sequence with asset preload & start button
                LoadingScreen.show(statusText, showProgress, options?)
                LoadingScreen.setStatus(text)
                LoadingScreen.setProgress(alpha)
                LoadingScreen.hide()
                LoadingScreen.showDuring(statusText, callback)

        The module keeps a lightweight GUI footprint, rebuilds itself on demand,
        and clamps all public input so luau-analyze stays clean under --!strict.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

export type ShowOptions = {
        freezePlayer: boolean?,
        disableCoreGui: boolean?,
        showStartButton: boolean?,
        startButtonText: string?,
}

type GuiRefs = {
        screenGui: ScreenGui,
        container: Frame,
        statusLabel: TextLabel,
        tipLabel: TextLabel,
        progressContainer: Frame,
        progressFill: Frame,
        progressText: TextLabel,
        spinner: ImageLabel,
        startButton: TextButton,
}

type MovementState = {
        WalkSpeed: number?,
        JumpPower: number?,
        JumpHeight: number?,
}

local LoadingScreen = {}
LoadingScreen.isLoading = false

local LOADING_TIPS = {
        "Did you know? You can shake trees to find furniture!",
        "Tip: Talk to villagers every day to build friendship.",
        "Catching bugs is easier when you walk slowly!",
        "Pro tip: Fish shadows show their size. Bigger shadow = bigger fish!",
        "Don't forget to check Nook's Cranny for new items daily!",
        "Balloons often carry furniture and DIY recipes!",
        "Tip: Plant fruit trees to grow bells!",
        "Did you know? Different fish appear at different times.",
        "Fossils can be found by digging X-marks on the ground!",
        "Tip: Donate bugs and fish to Blathers for the museum!",
        "Pro tip: Save your game regularly at the tent!",
        "Did you know? You can customize some furniture items!",
        "Tip: Nook Miles can be earned by completing daily tasks!",
        "Press E to open your inventory!",
        "Tip: Golden tools are more durable than regular ones!",
        "Did you know? You can catch snowflakes in winter!",
        "Pro tip: Plant flowers to attract rare bugs!",
        "Tip: Check the beach for message bottles with DIY recipes!",
        "Did you know? Turnip prices change twice daily!",
        "Tip: Visit other players' islands for new items!",
}

local ASSETS_TO_PRELOAD = {
        "rbxassetid://79857338226248",
        "rbxassetid://98139431900134",
}

local START_BUTTON_SIZE = UDim2.new(0, 260, 0, 54)

local _refs: GuiRefs? = nil
local _spinnerConnection: RBXScriptConnection? = nil
local _tipThread: thread? = nil
local _tipIndex = 0
local _random = Random.new()
local _progressVisible = false
local _progressValue = 0
local _statusText = "Loading..."
local _coreGuiDisabled = false
local _characterFrozen = false
local _savedMovement: MovementState = {}

local function clampProgress(alpha: number): number
        if alpha < 0 then
                return 0
        elseif alpha > 1 then
                return 1
        end
        return alpha
end

local function getPlayerGui(): PlayerGui
        local player = Players.LocalPlayer
        assert(player, "LoadingScreen requires a LocalPlayer")
        return player:WaitForChild("PlayerGui")
end

local function hideStartButton()
        local refs = _refs
        if not refs then
                return
        end
        refs.startButton.Visible = false
        refs.startButton.Active = false
        refs.startButton.TextTransparency = 0
        refs.startButton.BackgroundTransparency = 0.1
        refs.startButton.Size = START_BUTTON_SIZE
end

local function showStartButton(text: string?, animate: boolean)
        local refs = _refs
        if not refs then
                return
        end

        refs.startButton.Text = text or refs.startButton.Text
        refs.startButton.Visible = true
        refs.startButton.Active = true
        refs.startButton.AutoButtonColor = true

        if animate then
                refs.startButton.Size = UDim2.new(0, START_BUTTON_SIZE.X.Offset, 0, 0)
                refs.startButton.BackgroundTransparency = 0.4
                refs.startButton.TextTransparency = 1
                local tween = TweenService:Create(
                        refs.startButton,
                        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        {
                                Size = START_BUTTON_SIZE,
                                BackgroundTransparency = 0.1,
                                TextTransparency = 0,
                        }
                )
                tween:Play()
        else
                refs.startButton.Size = START_BUTTON_SIZE
                refs.startButton.BackgroundTransparency = 0.1
                refs.startButton.TextTransparency = 0
        end
end

local function applyProgress()
        local refs = _refs
        if not refs then
                return
        end

        refs.progressFill.Size = UDim2.new(_progressValue, 0, 1, 0)
        refs.progressText.Text = string.format("%d%%", math.floor(_progressValue * 100 + 0.5))
end

local function applyProgressVisibility()
        local refs = _refs
        if refs then
                refs.progressContainer.Visible = _progressVisible
        end
end

local function updateTipText()
        local refs = _refs
        if not refs then
                return
        end
        if #LOADING_TIPS == 0 then
                refs.tipLabel.Text = ""
                return
        end

        local index = _random:NextInteger(1, #LOADING_TIPS)
        if #LOADING_TIPS > 1 then
                while index == _tipIndex do
                        index = _random:NextInteger(1, #LOADING_TIPS)
                end
        end
        _tipIndex = index
        refs.tipLabel.Text = LOADING_TIPS[index]
end

local function stopTipRotation()
        if _tipThread then
                task.cancel(_tipThread)
                _tipThread = nil
        end
end

local function startTipRotation()
        stopTipRotation()
        updateTipText()
        _tipThread = task.spawn(function()
                while LoadingScreen.isLoading do
                        task.wait(8)
                        if not LoadingScreen.isLoading then
                                break
                        end
                        updateTipText()
                end
        end)
end

local function stopSpinner()
        if _spinnerConnection then
                _spinnerConnection:Disconnect()
                _spinnerConnection = nil
        end
        local refs = _refs
        if refs then
                refs.spinner.Rotation = 0
        end
end

local function startSpinner()
        stopSpinner()
        local refs = _refs
        if not refs then
                return
        end
        local rotation = 0
        _spinnerConnection = RunService.RenderStepped:Connect(function(dt)
                rotation += dt * 180
                if rotation >= 360 then
                        rotation -= 360
                end
                refs.spinner.Rotation = rotation
        end)
end

local function disableCoreGui()
        if _coreGuiDisabled then
                return
        end
        _coreGuiDisabled = true
        pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
                StarterGui:SetCore("TopbarEnabled", false)
        end)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
end

local function restoreCoreGui()
        if not _coreGuiDisabled then
                return
        end
        _coreGuiDisabled = false
        pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
                StarterGui:SetCore("TopbarEnabled", true)
        end)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
end

local function freezeCharacter()
        if _characterFrozen then
                return
        end
        local player = Players.LocalPlayer
        if not player then
                return
        end
        local character = player.Character
        if not character then
                return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
                return
        end

        _savedMovement = {
                WalkSpeed = humanoid.WalkSpeed,
                JumpPower = humanoid.JumpPower,
                JumpHeight = humanoid.JumpHeight,
        }
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
        _characterFrozen = true
end

local function restoreCharacter()
        if not _characterFrozen then
                return
        end
        _characterFrozen = false
        local player = Players.LocalPlayer
        if not player then
                return
        end
        local character = player.Character
        if not character then
                return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
                return
        end

        humanoid.WalkSpeed = _savedMovement.WalkSpeed or 16
        humanoid.JumpPower = _savedMovement.JumpPower or 50
        humanoid.JumpHeight = _savedMovement.JumpHeight or 7.2
        _savedMovement = {}
end

local function ensureGui(): GuiRefs
        local refs = _refs
        if refs and refs.screenGui.Parent then
                return refs
        end

        local playerGui = getPlayerGui()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "LoadingScreen"
        screenGui.DisplayOrder = 1000
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = playerGui

        local background = Instance.new("Frame")
        background.Name = "Background"
        background.Size = UDim2.fromScale(1, 1)
        background.BackgroundColor3 = Color3.fromRGB(120, 190, 235)
        background.BorderSizePixel = 0
        background.Parent = screenGui

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(135, 206, 250)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 160, 210)),
        })
        gradient.Rotation = 90
        gradient.Parent = background

        local container = Instance.new("Frame")
        container.Name = "Container"
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Position = UDim2.fromScale(0.5, 0.5)
        container.Size = UDim2.fromScale(0.6, 0)
        container.AutomaticSize = Enum.AutomaticSize.Y
        container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        container.BackgroundTransparency = 0.05
        container.BorderSizePixel = 0
        container.Parent = background

        local sizeConstraint = Instance.new("UISizeConstraint")
        sizeConstraint.MinSize = Vector2.new(360, 0)
        sizeConstraint.MaxSize = Vector2.new(720, 540)
        sizeConstraint.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 18)
        corner.Parent = container

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(210, 230, 255)
        stroke.Thickness = 2
        stroke.Transparency = 0.15
        stroke.Parent = container

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 28)
        padding.PaddingBottom = UDim.new(0, 32)
        padding.PaddingLeft = UDim.new(0, 32)
        padding.PaddingRight = UDim.new(0, 32)
        padding.Parent = container

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 14)
        layout.Parent = container

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.AutomaticSize = Enum.AutomaticSize.XY
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = "Animal Crossing CE"
        titleLabel.TextColor3 = Color3.fromRGB(65, 120, 160)
        titleLabel.TextSize = 40
        titleLabel.LayoutOrder = 1
        titleLabel.Parent = container

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "Status"
        statusLabel.AutomaticSize = Enum.AutomaticSize.XY
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.Text = _statusText
        statusLabel.TextColor3 = Color3.fromRGB(70, 70, 70)
        statusLabel.TextSize = 20
        statusLabel.TextWrapped = true
        statusLabel.LayoutOrder = 2
        statusLabel.Parent = container

        local spinnerHolder = Instance.new("Frame")
        spinnerHolder.Name = "SpinnerHolder"
        spinnerHolder.Size = UDim2.new(1, 0, 0, 120)
        spinnerHolder.BackgroundTransparency = 1
        spinnerHolder.LayoutOrder = 3
        spinnerHolder.Parent = container

        local spinner = Instance.new("ImageLabel")
        spinner.Name = "Spinner"
        spinner.AnchorPoint = Vector2.new(0.5, 0.5)
        spinner.Position = UDim2.fromScale(0.5, 0.5)
        spinner.Size = UDim2.fromOffset(96, 96)
        spinner.BackgroundTransparency = 1
        spinner.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        spinner.ImageColor3 = Color3.fromRGB(90, 170, 220)
        spinner.ImageTransparency = 0.1
        spinner.Parent = spinnerHolder

        local progressContainer = Instance.new("Frame")
        progressContainer.Name = "ProgressContainer"
        progressContainer.Size = UDim2.new(1, 0, 0, 48)
        progressContainer.BackgroundColor3 = Color3.fromRGB(240, 248, 255)
        progressContainer.BackgroundTransparency = 0.1
        progressContainer.BorderSizePixel = 0
        progressContainer.LayoutOrder = 4
        progressContainer.Parent = container

        local progressCorner = Instance.new("UICorner")
        progressCorner.CornerRadius = UDim.new(0, 12)
        progressCorner.Parent = progressContainer

        local progressStroke = Instance.new("UIStroke")
        progressStroke.Color = Color3.fromRGB(200, 220, 240)
        progressStroke.Transparency = 0.25
        progressStroke.Thickness = 2
        progressStroke.Parent = progressContainer

        local progressFill = Instance.new("Frame")
        progressFill.Name = "Fill"
        progressFill.BackgroundColor3 = Color3.fromRGB(110, 190, 230)
        progressFill.BorderSizePixel = 0
        progressFill.Size = UDim2.new(_progressValue, 0, 1, 0)
        progressFill.Parent = progressContainer

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 12)
        fillCorner.Parent = progressFill

        local progressText = Instance.new("TextLabel")
        progressText.Name = "ProgressText"
        progressText.BackgroundTransparency = 1
        progressText.Size = UDim2.fromScale(1, 1)
        progressText.Font = Enum.Font.GothamBold
        progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
        progressText.TextTransparency = 0.15
        progressText.TextSize = 18
        progressText.Text = string.format("%d%%", math.floor(_progressValue * 100 + 0.5))
        progressText.Parent = progressContainer

        local startButton = Instance.new("TextButton")
        startButton.Name = "StartButton"
        startButton.Size = START_BUTTON_SIZE
        startButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        startButton.BackgroundTransparency = 0.1
        startButton.BorderSizePixel = 0
        startButton.AutoButtonColor = true
        startButton.Font = Enum.Font.GothamBold
        startButton.TextColor3 = Color3.fromRGB(65, 120, 160)
        startButton.TextSize = 24
        startButton.Text = "Press to Start"
        startButton.Visible = false
        startButton.LayoutOrder = 5
        startButton.Parent = container

        local startCorner = Instance.new("UICorner")
        startCorner.CornerRadius = UDim.new(0, 14)
        startCorner.Parent = startButton

        local startStroke = Instance.new("UIStroke")
        startStroke.Color = Color3.fromRGB(200, 220, 240)
        startStroke.Transparency = 0.2
        startStroke.Thickness = 2
        startStroke.Parent = startButton

        startButton.MouseButton1Click:Connect(function()
                LoadingScreen.hide()
        end)

        local tipLabel = Instance.new("TextLabel")
        tipLabel.Name = "Tip"
        tipLabel.AutomaticSize = Enum.AutomaticSize.XY
        tipLabel.BackgroundTransparency = 1
        tipLabel.Font = Enum.Font.Gotham
        tipLabel.TextColor3 = Color3.fromRGB(70, 70, 70)
        tipLabel.TextSize = 18
        tipLabel.TextWrapped = true
        tipLabel.LayoutOrder = 6
        tipLabel.Parent = container

        _refs = {
                screenGui = screenGui,
                container = container,
                statusLabel = statusLabel,
                tipLabel = tipLabel,
                progressContainer = progressContainer,
                progressFill = progressFill,
                progressText = progressText,
                spinner = spinner,
                startButton = startButton,
        }

        applyProgress()
        applyProgressVisibility()
        updateTipText()

        return _refs :: GuiRefs
end

local function teardownGui()
        local refs = _refs
        if not refs then
                return
        end
        _refs = nil
        refs.screenGui:Destroy()
end

function LoadingScreen.setStatus(text: string)
        _statusText = text
        local refs = _refs
        if refs then
                refs.statusLabel.Text = text
        end
end

function LoadingScreen.setProgress(alpha: number)
        _progressValue = clampProgress(alpha)
        applyProgress()
end

function LoadingScreen.show(statusText: string?, showProgressBar: boolean?, options: ShowOptions?)
        if LoadingScreen.isLoading then
                LoadingScreen.hide()
        end

        _statusText = statusText or "Loading..."
        _progressVisible = showProgressBar == true
        if _progressVisible then
                _progressValue = 0
        end

        local refs = ensureGui()
        refs.statusLabel.Text = _statusText
        applyProgressVisibility()
        applyProgress()
        hideStartButton()

        if options then
                if options.showStartButton then
                        showStartButton(options.startButtonText, false)
                end
                if options.disableCoreGui then
                        disableCoreGui()
                end
                if options.freezePlayer then
                        freezeCharacter()
                end
        end

        LoadingScreen.isLoading = true
        startSpinner()
        startTipRotation()
end

local function finishHide()
        stopTipRotation()
        stopSpinner()
        restoreCoreGui()
        restoreCharacter()
        teardownGui()
        LoadingScreen.isLoading = false
        _progressVisible = false
end

function LoadingScreen.hide()
        if not LoadingScreen.isLoading then
                return
        end

        local refs = _refs
        if refs then
                local tween = TweenService:Create(
                        refs.container,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                        {BackgroundTransparency = 1}
                )
                tween:Play()
                tween.Completed:Wait()
        end

        finishHide()
end

function LoadingScreen.showDuring(statusText: string?, callback: () -> ())
        LoadingScreen.show(statusText, true, {
                disableCoreGui = true,
                freezePlayer = true,
        })

        local ok, result = pcall(callback)
        LoadingScreen.hide()
        if not ok then
                error(result)
        end
        return result
end

local function preloadAssets()
        if #ASSETS_TO_PRELOAD == 0 then
                return
        end
        for index, assetId in ipairs(ASSETS_TO_PRELOAD) do
                local success, err = pcall(function()
                        ContentProvider:PreloadAsync({assetId})
                end)
                if not success then
                        warn(string.format("[LoadingScreen] Failed to preload asset %s: %s", assetId, tostring(err)))
                end
                LoadingScreen.setProgress(index / #ASSETS_TO_PRELOAD)
        end
end

function LoadingScreen.init()
        LoadingScreen.show("Loading your island...", true, {
                disableCoreGui = true,
                freezePlayer = true,
        })
        hideStartButton()

        task.spawn(function()
                preloadAssets()
                LoadingScreen.setProgress(1)
                if not LoadingScreen.isLoading then
                        return
                end
                LoadingScreen.setStatus("Press start to continue")
                showStartButton("Press to Start", true)
        end)
end

return LoadingScreen
