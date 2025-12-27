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
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import the new AC theme system
local ThemeProvider = require(script.Parent.ThemeProvider)
local GUIContentManager = require(script.Parent.GUIContentManager)

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
    viewportFrame: ViewportFrame,
    planeModel: Model?,
    startButton: TextButton,
    nookPhoneFrame: Frame?,
    islandMapFrame: Frame?,
}

type MovementState = {
    WalkSpeed: number?,
    JumpPower: number?,
    JumpHeight: number?,
}

local LoadingScreen = {}
LoadingScreen.isLoading = false

local LOADING_TIPS = GUIContentManager.getLoadingTips()
local ASSETS_TO_PRELOAD = GUIContentManager.getPreloadAssets()

local START_BUTTON_SIZE = GUIContentManager.LoadingScreen.buttons.start.size

-- Responsive sizing helpers
-- Simple post-effects managed per-client on CurrentCamera
local _effects = {
    Bloom = nil :: BloomEffect?,
    SunRays = nil :: SunRaysEffect?,
    ColorCorrection = nil :: ColorCorrectionEffect?,
}

local _selectedPreset = "Medium"

local function getCurrentCamera(): Camera
    return Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
end

local function ensurePostEffects()
    local cam = getCurrentCamera()
    if not _effects.Bloom or not _effects.Bloom.Parent then
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "LS_Bloom"
        bloom.Intensity = 0
        bloom.Size = 0
        bloom.Threshold = 1
        bloom.Enabled = false
        bloom.Parent = cam
        _effects.Bloom = bloom
    end
    if not _effects.SunRays or not _effects.SunRays.Parent then
        local sun = Instance.new("SunRaysEffect")
        sun.Name = "LS_SunRays"
        sun.Intensity = 0
        sun.Spread = 0.2
        sun.Enabled = false
        sun.Parent = cam
        _effects.SunRays = sun
    end
    if not _effects.ColorCorrection or not _effects.ColorCorrection.Parent then
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "LS_ColorCorrection"
        cc.Contrast = 0
        cc.Saturation = 0
        cc.Brightness = 0
        cc.Enabled = false
        cc.Parent = cam
        _effects.ColorCorrection = cc
    end
end

local function applyGraphicsPreset(preset: string)
    _selectedPreset = preset
    ensurePostEffects()
    local bloom = _effects.Bloom :: BloomEffect
    local sun = _effects.SunRays :: SunRaysEffect
    local cc = _effects.ColorCorrection :: ColorCorrectionEffect

    if preset == "Low" then
        bloom.Enabled = false
        bloom.Intensity = 0
        bloom.Size = 0
        sun.Enabled = false
        sun.Intensity = 0
        cc.Enabled = false
        cc.Contrast = 0
        cc.Saturation = 0
        cc.Brightness = 0
    elseif preset == "High" then
        bloom.Enabled = true
        bloom.Intensity = 0.6
        bloom.Size = 20
        sun.Enabled = true
        sun.Intensity = 0.1
        cc.Enabled = true
        cc.Contrast = 0.06
        cc.Saturation = 0.08
        cc.Brightness = 0.02
    else -- Medium
        bloom.Enabled = true
        bloom.Intensity = 0.35
        bloom.Size = 16
        sun.Enabled = true
        sun.Intensity = 0.06
        cc.Enabled = true
        cc.Contrast = 0.03
        cc.Saturation = 0.04
        cc.Brightness = 0.01
    end
end

local _refs: GuiRefs? = nil
local _planeAnimationConnection: RBXScriptConnection? = nil
local _tipThread: thread? = nil
local _tipIndex = 0
local _random = Random.new()
local _progressVisible = false
local _progressValue = 0
local _statusText = "Loading..."
local _coreGuiDisabled = false
local _characterFrozen = false
local _savedMovement: MovementState = {}
local _planeAnimationTime = 0

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

local function loadNookPlaneModel(): Model?
    -- Try to load from ReplicatedStorage
    local success, result = pcall(function()
        print("[LoadingScreen] 🔍 Searching for NookPlane in ReplicatedStorage...")

        -- List all children for debugging
        print("[LoadingScreen] ReplicatedStorage contents:")
        for _, child in ipairs(ReplicatedStorage:GetChildren()) do
            print("  -", child.Name, "(" .. child.ClassName .. ")")
        end

        -- First try to find it directly by exact name
        local nookPlaneAsset = ReplicatedStorage:FindFirstChild("NookPlane")

        -- If not found, try case-insensitive search
        if not nookPlaneAsset then
            for _, child in ipairs(ReplicatedStorage:GetChildren()) do
                if string.lower(child.Name) == "nookplane" then
                    nookPlaneAsset = child
                    print("[LoadingScreen] Found NookPlane (case-insensitive):", child.Name)
                    break
                end
            end
        end

        -- If still not found, try partial name match
        if not nookPlaneAsset then
            for _, child in ipairs(ReplicatedStorage:GetChildren()) do
                if string.find(string.lower(child.Name), "nook") and string.find(string.lower(child.Name), "plane") then
                    nookPlaneAsset = child
                    print("[LoadingScreen] Found plane model by partial match:", child.Name)
                    break
                end
            end
        end

        -- If not found, wait for it (longer timeout)
        if not nookPlaneAsset then
            print("[LoadingScreen] Waiting for NookPlane in ReplicatedStorage (5 second timeout)...")
            local waitSuccess, waitResult = pcall(function()
                return ReplicatedStorage:WaitForChild("NookPlane", 5)
            end)
            if waitSuccess and waitResult then
                nookPlaneAsset = waitResult
            end
        end

        if not nookPlaneAsset then
            error(
                "NookPlane not found in ReplicatedStorage. Make sure you've inserted NookPlane.rbxm into ReplicatedStorage in Studio."
            )
        end

        print("[LoadingScreen] ✅ Found asset:", nookPlaneAsset.Name, "Type:", nookPlaneAsset.ClassName)

        -- Check if it's a Model
        local modelToClone: Model? = nil
        if nookPlaneAsset:IsA("Model") then
            modelToClone = nookPlaneAsset
            print("[LoadingScreen] Asset is a Model")
        else
            -- Maybe it's a Folder containing a Model?
            print("[LoadingScreen] Asset is not a Model, searching for Model inside...")
            local modelInside = nookPlaneAsset:FindFirstChildOfClass("Model", true) -- Recursive search
            if modelInside then
                modelToClone = modelInside
                print("[LoadingScreen] Found Model inside:", modelInside.Name, "at path:", modelInside:GetFullName())
            else
                -- Try to find any Model in ReplicatedStorage
                print("[LoadingScreen] No Model found inside, searching all of ReplicatedStorage...")
                local allModels = {}
                for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
                    if child:IsA("Model") and string.find(string.lower(child.Name), "plane") then
                        table.insert(allModels, child)
                    end
                end
                if #allModels > 0 then
                    modelToClone = allModels[1]
                    local chosen = modelToClone :: Model
                    print("[LoadingScreen] Found plane model in ReplicatedStorage:", chosen:GetFullName())
                else
                    error(
                        "NookPlane is not a Model, it's a "
                            .. nookPlaneAsset.ClassName
                            .. ". No plane models found in ReplicatedStorage."
                    )
                end
            end
        end

        if not modelToClone then
            error("Could not find a Model to clone")
        end

        -- Clone the model
        local planeClone = modelToClone:Clone()
        planeClone.Name = "LoadingPlane"

        -- Ensure it has parts
        local parts = planeClone:GetDescendants()
        local partCount = 0
        for _, descendant in ipairs(parts) do
            if descendant:IsA("BasePart") then
                partCount = partCount + 1
            end
        end

        print("[LoadingScreen] ✈️ NookPlane loaded successfully with", partCount, "parts")

        -- Ensure PrimaryPart is set
        if not planeClone.PrimaryPart then
            local firstPart = planeClone:FindFirstChildOfClass("BasePart")
            if firstPart then
                planeClone.PrimaryPart = firstPart
                print("[LoadingScreen] Set PrimaryPart to:", firstPart.Name)
            end
        end

        return planeClone
    end)

    if success and result then
        return result
    else
        warn("[LoadingScreen] ⚠️ Failed to load NookPlane:", tostring(result))
        warn("[LoadingScreen] Make sure NookPlane (as a Model) exists in ReplicatedStorage")
        -- List what's actually in ReplicatedStorage for debugging
        print("[LoadingScreen] Current ReplicatedStorage children:")
        for _, child in ipairs(ReplicatedStorage:GetChildren()) do
            print("  -", child.Name, "(" .. child.ClassName .. ")")
        end
        return nil
    end
end

local function setupPlaneViewport(viewportFrame: ViewportFrame, planeModel: Model)
    print("[LoadingScreen] Setting up plane viewport...")

    -- Set up camera for side view of plane flying
    local camera = Instance.new("Camera")
    camera.Name = "PlaneCamera"
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera

    -- Scale the plane to 8x size (REALLY BIG and eye-catching)
    local scaleFactor = 8
    print("[LoadingScreen] Scaling plane to", scaleFactor, "x size for maximum visibility")

    -- Make sure all parts are visible and properly set up first
    local partCount = 0
    local firstPartFound: BasePart? = nil

    for _, descendant in ipairs(planeModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            -- Scale the part
            descendant.Size = descendant.Size * scaleFactor
            -- Scale any meshes
            local mesh = descendant:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                if mesh.Scale then
                    mesh.Scale = mesh.Scale * scaleFactor
                end
            end
            -- Don't force transparency to 0, respect the model's original transparency
            partCount = partCount + 1
            if not firstPartFound then
                firstPartFound = descendant
            end
        elseif descendant:IsA("SurfaceLight") then
            local sl = descendant :: SurfaceLight
            sl.Enabled = true
        elseif descendant:IsA("PointLight") then
            local pl = descendant :: PointLight
            pl.Enabled = true
            pl.Range = pl.Range * scaleFactor
        elseif descendant:IsA("SpotLight") then
            local spl = descendant :: SpotLight
            spl.Enabled = true
            spl.Range = spl.Range * scaleFactor
        end
    end

    print("[LoadingScreen] Scaled", partCount, "parts to", scaleFactor, "x size")

    print("[LoadingScreen] Processed", partCount, "parts in plane model")

    -- Ensure PrimaryPart is set before parenting
    if not planeModel.PrimaryPart then
        -- Try to find a part (check direct children first, then descendants)
        local firstPart = planeModel:FindFirstChildOfClass("BasePart") or firstPartFound
        if firstPart then
            planeModel.PrimaryPart = firstPart
            print("[LoadingScreen] Set PrimaryPart to:", firstPart.Name, "at path:", firstPart:GetFullName())
        else
            warn("[LoadingScreen] ⚠️ No parts found in plane model! Part count was:", partCount)
            -- Try to find ANY part recursively
            for _, descendant in ipairs(planeModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    planeModel.PrimaryPart = descendant
                    print("[LoadingScreen] Found and set PrimaryPart to:", descendant.Name)
                    break
                end
            end
            if not planeModel.PrimaryPart then
                warn("[LoadingScreen] ❌ Could not set PrimaryPart - model may be empty or corrupted")
                return
            end
        end
    else
        print("[LoadingScreen] PrimaryPart already set to:", planeModel.PrimaryPart.Name)
    end

    -- Parent plane to viewport first (needed for GetBoundingBox and rendering)
    planeModel.Parent = viewportFrame
    print("[LoadingScreen] Plane parented to viewport")

    -- Simplified lighting - single ambient light for better performance
    local ambientLight = Instance.new("PointLight")
    ambientLight.Brightness = 2
    ambientLight.Color = Color3.fromRGB(255, 255, 255)
    ambientLight.Range = 400 * scaleFactor
    ambientLight.Shadows = false

    local lightPart = Instance.new("Part")
    lightPart.Name = "AmbientLight"
    lightPart.Size = Vector3.new(1, 1, 1) * scaleFactor
    lightPart.Transparency = 1
    lightPart.CanCollide = false
    lightPart.Anchored = true
    lightPart.Position = Vector3.new(0, 15, 0) * scaleFactor
    lightPart.Parent = planeModel
    ambientLight.Parent = lightPart

    -- Position plane at origin, rotated to show side view
    -- Try to position it nicely for side view
    task.defer(function()
        local success, _cf, size = pcall(function()
            return planeModel:GetBoundingBox()
        end)

        if success and size then
            print("[LoadingScreen] Plane bounding box:", size)
            -- Position plane centered, rotated to face right (positive X)
            local planeCFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
            planeModel:PivotTo(planeCFrame)
        else
            -- Fallback: just rotate it to face right
            local planeCFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
            planeModel:PivotTo(planeCFrame)
            print("[LoadingScreen] Used fallback positioning")
        end
    end)

    -- Initial positioning (will be refined by deferred calculation)
    local planeCFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
    planeModel:PivotTo(planeCFrame)

    -- Set up camera position (calculate after a frame to ensure model is rendered)
    task.defer(function()
        -- Wait a moment for model to render
        task.wait(0.2)
        local success, _cf, size = pcall(function()
            return planeModel:GetBoundingBox()
        end)

        if success and size then
            print("[LoadingScreen] Setting up camera with size:", size)
            local maxSize = math.max(size.X, size.Y, size.Z)

            -- Side view camera: position camera to the side (right), slightly above
            -- Account for 8x scale - need optimal distance to see the HUGE plane
            local cameraDistance = maxSize * 1.5 -- Perfect distance for 8x plane
            local cameraHeight = size.Y * 0.25 -- Slightly above center for dynamic view

            -- Position camera to the right side, looking at the plane from side view
            local cameraPosition = Vector3.new(cameraDistance, cameraHeight, 0)
            local lookAtPosition = Vector3.new(0, cameraHeight, 0) -- Look at plane center

            camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
            camera.FieldOfView = 70 -- Wide FOV to see the huge plane in all its glory
            print("[LoadingScreen] Camera positioned at:", cameraPosition, "for 8x scaled plane")
        else
            -- Fallback camera position (scaled for 8x plane)
            local cameraPosition = Vector3.new(120, 30, 0) -- Further back and higher for 8x plane
            local lookAtPosition = Vector3.new(0, 0, 0)
            camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
            camera.FieldOfView = 70 -- Wide FOV
            print("[LoadingScreen] Used fallback camera position for 8x scaled plane")
        end
    end)

    -- Set initial camera position (will be refined by deferred calculation)
    -- Account for 8x scaled plane - need optimal distance
    local cameraPosition = Vector3.new(120, 30, 0) -- Further back and higher for 8x plane
    local lookAtPosition = Vector3.new(0, 0, 0)
    camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
    camera.FieldOfView = 70 -- Wide FOV to see the huge plane

    print("[LoadingScreen] Viewport setup complete")
end

local function stopPlaneAnimation()
    if _planeAnimationConnection then
        _planeAnimationConnection:Disconnect()
        _planeAnimationConnection = nil
    end
    _planeAnimationTime = 0
end

local function startPlaneAnimation()
    stopPlaneAnimation()
    local refs = _refs
    if not refs or not refs.planeModel then
        return
    end

    _planeAnimationTime = 0
    _planeAnimationConnection = RunService.RenderStepped:Connect(function(dt)
        _planeAnimationTime += dt

        if refs.planeModel and refs.planeModel.Parent then
            -- Simplified flying animation for better performance
            local forwardSpeed = 1.2
            local loopDistance = 60
            local forwardDistance = (_planeAnimationTime * forwardSpeed) % loopDistance

            -- Simple vertical bobbing
            local verticalBob = math.sin(_planeAnimationTime * 0.8) * 4

            -- Gentle banking
            local bankAngle = math.sin(_planeAnimationTime * 0.3) * 8

            local baseRotation = CFrame.Angles(0, math.rad(90), math.rad(bankAngle))
            local scaleMultiplier = 8
            local animatedPosition = Vector3.new(0, verticalBob * scaleMultiplier, -forwardDistance * scaleMultiplier)

            refs.planeModel:PivotTo(baseRotation * CFrame.new(animatedPosition))
        end
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
    background.BackgroundColor3 = ThemeProvider.getColor("skyBlue")
    background.BorderSizePixel = 0
    background.Parent = screenGui

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ThemeProvider.getColor("skyBlue")),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 240)), -- Keep some variation
        ColorSequenceKeypoint.new(1, ThemeProvider.getColor("leafGreen")),
    })
    gradient.Rotation = 135
    gradient.Parent = background

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 2000
    overlay.Parent = screenGui

    -- Removed Nook Phone label and island map elements per user request
    -- These UI elements cluttered the loading screen

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Size = UDim2.fromScale(0.85, 0) -- Balanced container size
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundColor3 = GUIContentManager.LoadingScreen.styling.backgroundColor
    container.BackgroundTransparency = 0
    container.BorderSizePixel = 0
    container.Parent = background

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(500, 400) -- Reasonable minimum
    sizeConstraint.MaxSize = Vector2.new(1200, 800) -- Reasonable maximum
    sizeConstraint.Parent = container

    -- Apply ACNH-style corner radius
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, GUIContentManager.LoadingScreen.styling.cornerRadius)
    containerCorner.Parent = container

    -- Apply ACNH-style border
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = GUIContentManager.LoadingScreen.styling.titleColor
    containerStroke.Transparency = 0.3
    containerStroke.Thickness = 2
    containerStroke.Parent = container

    -- Decorative corner elements removed - they were causing glitches

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0.03, 0)
    padding.PaddingBottom = UDim.new(0.035, 0)
    padding.PaddingLeft = UDim.new(0.035, 0)
    padding.PaddingRight = UDim.new(0.035, 0)
    padding.Parent = container

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 12)
    layout.Parent = container

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "Animal Crossing CE"
    titleLabel.TextColor3 = ThemeProvider.getColor("textLight")
    titleLabel.TextScaled = true
    titleLabel.TextStrokeTransparency = 0.8
    titleLabel.TextStrokeColor3 = ThemeProvider.getColor("lightBrown")
    titleLabel.LayoutOrder = 1
    titleLabel.Parent = container

    local titleTextConstraint = Instance.new("UITextSizeConstraint")
    titleTextConstraint.MaxTextSize = 36
    titleTextConstraint.MinTextSize = 18
    titleTextConstraint.Parent = titleLabel

    -- CENTERED PLANE VIEWPORT - Large and eye-catching but balanced
    local viewportContainer = Instance.new("Frame")
    viewportContainer.Name = "PlaneViewportContainer"
    viewportContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    viewportContainer.Position = UDim2.fromScale(0.5, 0.5)
    viewportContainer.Size = UDim2.new(0.75, 0, 0.45, 0) -- Balanced viewport (75% width, 45% height) - big but leaves room for UI
    viewportContainer.BackgroundTransparency = 1
    viewportContainer.LayoutOrder = 2
    viewportContainer.Parent = container

    local viewportFrame = Instance.new("ViewportFrame")
    viewportFrame.Name = "PlaneViewport"
    viewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    viewportFrame.Position = UDim2.fromScale(0.5, 0.5)
    viewportFrame.Size = UDim2.new(1, 0, 1, 0) -- Fill container
    viewportFrame.BackgroundColor3 = Color3.fromRGB(135, 206, 250)
    viewportFrame.BackgroundTransparency = 0.1 -- Slight sky blue tint
    viewportFrame.BorderSizePixel = 0
    viewportFrame.Parent = viewportContainer

    -- Add rounded corners to viewport
    local viewportCorner = Instance.new("UICorner")
    viewportCorner.CornerRadius = UDim.new(0, 16)
    viewportCorner.Parent = viewportFrame

    -- Add subtle border/glow
    local viewportStroke = Instance.new("UIStroke")
    viewportStroke.Color = Color3.fromRGB(200, 230, 255)
    viewportStroke.Thickness = 3
    viewportStroke.Transparency = 0.3
    viewportStroke.Parent = viewportFrame

    -- Text content below viewport
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.AutomaticSize = Enum.AutomaticSize.Y
    textContainer.Size = UDim2.new(1, 0, 0, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.LayoutOrder = 3
    textContainer.Parent = container

    -- Vertical flex layout - stretches horizontally, centers items
    local textLayout = Instance.new("UIListLayout")
    textLayout.FillDirection = Enum.FillDirection.Vertical
    textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    textLayout.Padding = UDim.new(0, 16)
    textLayout.Parent = textContainer

    -- Make textContainer stretch horizontally
    textContainer.Size = UDim2.new(1, 0, 0, 0) -- Full width, auto height

    local _leftCol = textContainer -- Reuse variable name for compatibility

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, 0, 0, 0) -- Stretch horizontally
    statusLabel.AutomaticSize = Enum.AutomaticSize.Y -- Auto height only
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Text = _statusText
    statusLabel.TextColor3 = ThemeProvider.getColor("textLight")
    statusLabel.TextScaled = true
    statusLabel.TextWrapped = true
    statusLabel.TextStrokeTransparency = 0.85
    statusLabel.TextStrokeColor3 = ThemeProvider.getColor("lightBrown")
    statusLabel.LayoutOrder = 1
    statusLabel.Parent = textContainer

    local statusTextConstraint = Instance.new("UITextSizeConstraint")
    statusTextConstraint.MaxTextSize = 18
    statusTextConstraint.MinTextSize = 12
    statusTextConstraint.Parent = statusLabel

    -- Try to load and set up the plane
    local planeModel: Model? = nil
    local loadSuccess, loadError = pcall(function()
        planeModel = loadNookPlaneModel()
    end)

    if not loadSuccess then
        warn("[LoadingScreen] Error loading plane model:", tostring(loadError))
    end

    if planeModel then
        print("[LoadingScreen] Attempting to set up viewport with plane model")
        local setupSuccess, setupError = pcall(function()
            setupPlaneViewport(viewportFrame, planeModel)
        end)
        if not setupSuccess then
            warn("[LoadingScreen] Error setting up viewport:", tostring(setupError))
            -- Clean up failed model
            planeModel:Destroy()
            planeModel = nil
        end
    end

    -- If plane model failed to load or set up, show fallback
    if not planeModel then
        print("[LoadingScreen] Using fallback placeholder")
        -- Fallback: show a simple placeholder message
        local placeholder = Instance.new("TextLabel")
        placeholder.Name = "Placeholder"
        placeholder.Size = UDim2.fromScale(1, 1)
        placeholder.BackgroundTransparency = 1
        placeholder.Text = "✈️"
        placeholder.TextColor3 = Color3.fromRGB(90, 170, 220)
        placeholder.TextSize = 64
        placeholder.Font = Enum.Font.GothamBold
        placeholder.Parent = viewportFrame
    end

    local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(1, 0, 0, 48) -- Stretch horizontally (full width)
    progressContainer.BackgroundColor3 = ThemeProvider.getColor("eggshell")
    progressContainer.BackgroundTransparency = 0.1
    progressContainer.BorderSizePixel = 0
    progressContainer.LayoutOrder = 2
    progressContainer.Parent = textContainer

    -- Apply AC-style medium corner radius
    ThemeProvider.applyCornerRadius(progressContainer, "medium")

    -- Apply subtle stroke
    ThemeProvider.applyStroke(progressContainer, ThemeProvider.getColor("lightBrown"), 2)

    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.BackgroundColor3 = ThemeProvider.getColor("skyBlue")
    progressFill.BorderSizePixel = 0
    progressFill.Size = UDim2.new(_progressValue, 0, 1, 0)
    progressFill.Parent = progressContainer

    -- Apply corner radius to fill
    ThemeProvider.applyCornerRadius(progressFill, "medium")

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

    local tipLabel = Instance.new("TextLabel")
    tipLabel.Name = "Tip"
    tipLabel.Size = UDim2.new(1, 0, 0, 0) -- Stretch horizontally
    tipLabel.AutomaticSize = Enum.AutomaticSize.Y
    tipLabel.BackgroundTransparency = 1
    tipLabel.Font = Enum.Font.Gotham
    tipLabel.TextColor3 = GUIContentManager.LoadingScreen.styling.tipColor
    tipLabel.TextScaled = true
    tipLabel.TextWrapped = true
    tipLabel.TextStrokeTransparency = 0.9
    tipLabel.TextStrokeColor3 = ThemeProvider.getColor("textSecondary")
    tipLabel.LayoutOrder = 4
    tipLabel.Parent = textContainer

    local tipTextConstraint = Instance.new("UITextSizeConstraint")
    tipTextConstraint.MaxTextSize = 16
    tipTextConstraint.MinTextSize = 10
    tipTextConstraint.Parent = tipLabel

    local startButton = Instance.new("TextButton")
    startButton.Name = "StartButton"
    startButton.Size = START_BUTTON_SIZE
    startButton.BackgroundColor3 = GUIContentManager.LoadingScreen.buttons.start.backgroundColor
    startButton.BackgroundTransparency = 0
    startButton.BorderSizePixel = 0
    startButton.AutoButtonColor = true
    startButton.Font = Enum.Font.GothamBold
    startButton.TextColor3 = GUIContentManager.LoadingScreen.buttons.start.textColor
    startButton.TextSize = 28
    startButton.Text = GUIContentManager.LoadingScreen.buttons.start.text
    startButton.Visible = false
    startButton.LayoutOrder = 5
    startButton.ZIndex = 10
    startButton.Parent = textContainer

    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0, GUIContentManager.LoadingScreen.buttons.start.cornerRadius)
    startCorner.Parent = startButton

    local startStroke = Instance.new("UIStroke")
    startStroke.Color = GUIContentManager.LoadingScreen.buttons.start.strokeColor
    startStroke.Transparency = 0
    startStroke.Thickness = GUIContentManager.LoadingScreen.buttons.start.strokeThickness
    startStroke.Parent = startButton

    startButton.MouseButton1Click:Connect(function()
        LoadingScreen.hide()
    end)

    _refs = {
        screenGui = screenGui,
        container = container,
        statusLabel = statusLabel,
        tipLabel = tipLabel,
        progressContainer = progressContainer,
        progressFill = progressFill,
        progressText = progressText,
        viewportFrame = viewportFrame,
        planeModel = planeModel,
        startButton = startButton,
        nookPhoneFrame = nookPhoneFrame,
        islandMapFrame = islandMapFrame,
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

    -- Clean up plane model if it exists
    if refs.planeModel then
        refs.planeModel:Destroy()
        refs.planeModel = nil
    end

    stopPlaneAnimation()
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
    local startTime = os.clock()
    if LoadingScreen.isLoading then
        LoadingScreen.hide()
    end

    _statusText = statusText or "Loading..."
    _progressVisible = showProgressBar == true
    if _progressVisible then
        _progressValue = 0
    end

    local guiStart = os.clock()
    local refs = ensureGui()
    local guiTime = os.clock() - guiStart
    print(string.format("[LoadingScreen] 📺 GUI creation took %.3fs", guiTime))
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
    startPlaneAnimation()
    startTipRotation()

    local totalTime = os.clock() - startTime
    print(string.format("[LoadingScreen] 📺 show() completed in %.3fs", totalTime))
end

local function finishHide()
    stopTipRotation()
    stopPlaneAnimation()
    restoreCoreGui()
    restoreCharacter()
    teardownGui()
    LoadingScreen.isLoading = false
    _progressVisible = false
    -- Mark that the pre-start flow has completed to suppress onboarding popups
    _G.PreStartCompleted = true
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
            { BackgroundTransparency = 1 }
        )
        tween:Play()
        tween.Completed:Wait()
    end

    finishHide()
end

function LoadingScreen.showDuring(statusText: string?, callback: () -> any)
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
            ContentProvider:PreloadAsync({ assetId })
        end)
        if not success then
            warn(string.format("[LoadingScreen] Failed to preload asset %s: %s", assetId, tostring(err)))
        end
        LoadingScreen.setProgress(index / #ASSETS_TO_PRELOAD)
    end
end

function LoadingScreen.init()
    -- Prepare default graphics preset effects
    ensurePostEffects()
    applyGraphicsPreset(_selectedPreset)

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
        local refs = _refs
        if refs then
            LoadingScreen.setStatus("Ready to start!")
            showStartButton(GUIContentManager.LoadingScreen.buttons.start.text, true)
        else
            -- Fallback: show Start if refs missing
            LoadingScreen.setStatus("Press start to continue")
            showStartButton("Press to Start", true)
        end
    end)
end

return LoadingScreen
