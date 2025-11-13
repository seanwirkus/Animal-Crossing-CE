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
        settingsPanel: Frame?,
        applyButton: TextButton?,
        keybindsPanel: Frame?,
        continueButton: TextButton?,
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
                        error("NookPlane not found in ReplicatedStorage. Make sure you've inserted NookPlane.rbxm into ReplicatedStorage in Studio.")
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
                        local modelInside = nookPlaneAsset:FindFirstChildOfClass("Model", true)  -- Recursive search
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
                                        error("NookPlane is not a Model, it's a " .. nookPlaneAsset.ClassName .. ". No plane models found in ReplicatedStorage.")
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
        
        -- Scale the plane to 2x size
        local scaleFactor = 2
        print("[LoadingScreen] Scaling plane to", scaleFactor, "x size")
        
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
        
        -- Add ambient lighting for the viewport (create a light source)
        -- Use the same scaleFactor defined above
        local light = Instance.new("PointLight")
        light.Brightness = 3
        light.Color = Color3.fromRGB(255, 255, 255)
        light.Range = 200 * scaleFactor
        light.Shadows = false
        
        -- Attach light to the plane (or create a separate part for it)
        local lightPart = Instance.new("Part")
        lightPart.Name = "ViewportLight"
        lightPart.Size = Vector3.new(1, 1, 1) * scaleFactor
        lightPart.Transparency = 1
        lightPart.CanCollide = false
        lightPart.Anchored = true
        lightPart.Position = Vector3.new(0, 15, 0) * scaleFactor  -- Above the plane
        lightPart.Parent = planeModel
        light.Parent = lightPart
        
        -- Add another light from the front to help visibility
        local frontLight = Instance.new("PointLight")
        frontLight.Brightness = 2
        frontLight.Color = Color3.fromRGB(255, 255, 255)
        frontLight.Range = 150 * scaleFactor
        frontLight.Shadows = false
        
        local frontLightPart = Instance.new("Part")
        frontLightPart.Name = "FrontLight"
        frontLightPart.Size = Vector3.new(1, 1, 1) * scaleFactor
        frontLightPart.Transparency = 1
        frontLightPart.CanCollide = false
        frontLightPart.Anchored = true
        frontLightPart.Position = Vector3.new(-10, 5, 0) * scaleFactor  -- In front of the plane
        frontLightPart.Parent = planeModel
        frontLight.Parent = frontLightPart
        
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
                        -- Account for 2x scale
                        local cameraDistance = maxSize * 2.2
                        local cameraHeight = size.Y * 0.2
                        
                        -- Position camera to the right side, looking at the plane from side view
                        local cameraPosition = Vector3.new(cameraDistance, cameraHeight, 0)
                        local lookAtPosition = Vector3.new(0, cameraHeight, 0)  -- Look at plane center
                        
                        camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
                        camera.FieldOfView = 55  -- Slightly wider FOV to see the bigger plane
                        print("[LoadingScreen] Camera positioned at:", cameraPosition, "for scaled plane")
                else
                        -- Fallback camera position (scaled for 2x plane)
                        local cameraPosition = Vector3.new(45, 10, 0)
                        local lookAtPosition = Vector3.new(0, 0, 0)
                        camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
                        camera.FieldOfView = 55
                        print("[LoadingScreen] Used fallback camera position for scaled plane")
                end
        end)
        
        -- Set initial camera position (will be refined by deferred calculation)
        -- Account for 2x scaled plane
        local cameraPosition = Vector3.new(45, 10, 0)
        local lookAtPosition = Vector3.new(0, 0, 0)
        camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
        camera.FieldOfView = 55
        
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
                        -- Flying animation: continuous forward movement with realistic flight dynamics
                        -- Plane is rotated -90 degrees for side view, so Z is forward direction
                        
                        -- Continuous forward movement (flying forward continuously)
                        local forwardSpeed = 0.8  -- Speed of forward movement (faster for 4x plane)
                        local loopDistance = 30  -- Distance before looping back
                        local forwardDistance = (_planeAnimationTime * forwardSpeed) % loopDistance
                        
                        -- Vertical movement (gentle bobbing like flying through air)
                        local verticalBob = math.sin(_planeAnimationTime * 1.5) * 3  -- More pronounced vertical bobbing
                        
                        -- Banking (roll) - smooth banking left and right like a plane flying
                        local bankAngle = math.sin(_planeAnimationTime * 0.6) * 10  -- More noticeable banking
                        
                        -- Pitch - slight nose up/down movement
                        local pitchAngle = math.sin(_planeAnimationTime * 0.4) * 5  -- Slight pitch variation
                        
                        -- Horizontal drift (side to side)
                        local horizontalDrift = math.sin(_planeAnimationTime * 0.5) * 2  -- Side to side drift
                        
                                -- Base rotation for side view (+90 degrees around Y to face right)
                                local baseRotation = CFrame.Angles(0, math.rad(90), 0)
                        
                        -- Combine all rotations: pitch (nose up/down), banking (roll), and maintain forward direction
                        local animatedRotation = baseRotation 
                                * CFrame.Angles(math.rad(pitchAngle), 0, math.rad(bankAngle))
                        
                        -- Position: continuous forward movement + vertical bobbing + horizontal drift
                        -- Scale positions by 2 to match the scaled model
                        -- Use negative Z for forward movement (plane flies forward in -Z direction when rotated -90)
                        local scaleMultiplier = 2
                        local animatedPosition = Vector3.new(
                                horizontalDrift * scaleMultiplier, 
                                verticalBob * scaleMultiplier, 
                                -forwardDistance * scaleMultiplier  -- Negative Z = forward (since rotated -90 around Y)
                        )
                        
                        refs.planeModel:PivotTo(animatedRotation * CFrame.new(animatedPosition))
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

        -- Two-column content row: left = text/controls, right = plane viewport
        local contentRow = Instance.new("Frame")
        contentRow.Name = "ContentRow"
        contentRow.AutomaticSize = Enum.AutomaticSize.Y
        contentRow.Size = UDim2.new(1, 0, 0, 0)
        contentRow.BackgroundTransparency = 1
        contentRow.LayoutOrder = 2
        contentRow.Parent = container

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.FillDirection = Enum.FillDirection.Horizontal
        contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        contentLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        contentLayout.Padding = UDim.new(0, 12)
        contentLayout.Parent = contentRow

        local leftCol = Instance.new("Frame")
        leftCol.Name = "LeftCol"
        leftCol.AutomaticSize = Enum.AutomaticSize.Y
        leftCol.Size = UDim2.new(1, -280, 0, 0)
        leftCol.BackgroundTransparency = 1
        leftCol.Parent = contentRow

        local leftLayout = Instance.new("UIListLayout")
        leftLayout.FillDirection = Enum.FillDirection.Vertical
        leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        leftLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        leftLayout.Padding = UDim.new(0, 10)
        leftLayout.Parent = leftCol

        local rightCol = Instance.new("Frame")
        rightCol.Name = "RightCol"
        rightCol.Size = UDim2.new(0, 260, 0, 220)
        rightCol.BackgroundTransparency = 1
        rightCol.Parent = contentRow

        local viewportFrame = Instance.new("ViewportFrame")
        viewportFrame.Name = "PlaneViewport"
        viewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        viewportFrame.Position = UDim2.fromScale(0.5, 0.5)
        viewportFrame.Size = UDim2.new(1, -8, 1, -8)
        viewportFrame.BackgroundColor3 = Color3.fromRGB(135, 206, 250)
        viewportFrame.BackgroundTransparency = 1
        viewportFrame.BorderSizePixel = 0
        viewportFrame.Parent = rightCol

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "Status"
        statusLabel.AutomaticSize = Enum.AutomaticSize.XY
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.Text = _statusText
        statusLabel.TextColor3 = Color3.fromRGB(70, 70, 70)
        statusLabel.TextSize = 20
        statusLabel.TextWrapped = true
        statusLabel.LayoutOrder = 1
        statusLabel.Parent = leftCol

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
        progressContainer.Size = UDim2.new(1, 0, 0, 48)
        progressContainer.BackgroundColor3 = Color3.fromRGB(240, 248, 255)
        progressContainer.BackgroundTransparency = 0.1
        progressContainer.BorderSizePixel = 0
        progressContainer.LayoutOrder = 2
        progressContainer.Parent = leftCol

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

        -- Settings panel (shown before Start)
        local settingsPanel = Instance.new("Frame")
        settingsPanel.Name = "SettingsPanel"
        settingsPanel.BackgroundTransparency = 1
        settingsPanel.Size = UDim2.new(1, 0, 0, 90)
        settingsPanel.Visible = false
        settingsPanel.LayoutOrder = 3
        settingsPanel.Parent = leftCol

        local settingsTitle = Instance.new("TextLabel")
        settingsTitle.BackgroundTransparency = 1
        settingsTitle.Font = Enum.Font.GothamBold
        settingsTitle.Text = "Graphics Preset"
        settingsTitle.TextColor3 = Color3.fromRGB(70, 70, 70)
        settingsTitle.TextSize = 20
        settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
        settingsTitle.Size = UDim2.new(1, 0, 0, 24)
        settingsTitle.Parent = settingsPanel

        local presetsRow = Instance.new("Frame")
        presetsRow.BackgroundTransparency = 1
        presetsRow.Size = UDim2.new(1, 0, 0, 40)
        presetsRow.Position = UDim2.new(0, 0, 0, 28)
        presetsRow.Parent = settingsPanel

        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout.Padding = UDim.new(0, 10)
        rowLayout.Parent = presetsRow

        local function makePresetButton(label: string): TextButton
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 110, 1, 0)
                btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                btn.BackgroundTransparency = 0.1
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = true
                btn.Font = Enum.Font.Gotham
                btn.TextColor3 = Color3.fromRGB(65, 120, 160)
                btn.TextSize = 18
                btn.Text = label
                btn.Parent = presetsRow
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 10)
                c.Parent = btn
                local s = Instance.new("UIStroke")
                s.Color = Color3.fromRGB(200, 220, 240)
                s.Transparency = 0.2
                s.Thickness = 2
                s.Parent = btn
                return btn
        end

        local lowBtn = makePresetButton("Low")
        local medBtn = makePresetButton("Medium")
        local highBtn = makePresetButton("High")

        local function styleSelection(sel: string)
                local function style(btn: TextButton, active: boolean)
                        btn.BackgroundTransparency = active and 0 or 0.1
                        btn.TextColor3 = active and Color3.fromRGB(4, 175, 166) or Color3.fromRGB(65, 120, 160)
                end
                style(lowBtn, sel == "Low")
                style(medBtn, sel == "Medium")
                style(highBtn, sel == "High")
        end
        styleSelection(_selectedPreset)

        lowBtn.MouseButton1Click:Connect(function()
                _selectedPreset = "Low"
                styleSelection(_selectedPreset)
        end)
        medBtn.MouseButton1Click:Connect(function()
                _selectedPreset = "Medium"
                styleSelection(_selectedPreset)
        end)
        highBtn.MouseButton1Click:Connect(function()
                _selectedPreset = "High"
                styleSelection(_selectedPreset)
        end)

        local applyButton = Instance.new("TextButton")
        applyButton.Name = "ApplyButton"
        applyButton.Size = UDim2.new(0, 220, 0, 40)
        applyButton.Position = UDim2.new(0, 0, 0, 72)
        applyButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        applyButton.BackgroundTransparency = 0.1
        applyButton.BorderSizePixel = 0
        applyButton.AutoButtonColor = true
        applyButton.Font = Enum.Font.GothamBold
        applyButton.TextColor3 = Color3.fromRGB(65, 120, 160)
        applyButton.TextSize = 20
        applyButton.Text = "Apply & Continue"
        applyButton.Parent = settingsPanel
        local applyCorner = Instance.new("UICorner")
        applyCorner.CornerRadius = UDim.new(0, 12)
        applyCorner.Parent = applyButton
        local applyStroke = Instance.new("UIStroke")
        applyStroke.Color = Color3.fromRGB(200, 220, 240)
        applyStroke.Transparency = 0.2
        applyStroke.Thickness = 2
        applyStroke.Parent = applyButton

        -- Keybinds panel
        local keybindsPanel = Instance.new("Frame")
        keybindsPanel.Name = "KeybindsPanel"
        keybindsPanel.BackgroundTransparency = 1
        keybindsPanel.Size = UDim2.new(1, 0, 0, 130)
        keybindsPanel.Visible = false
        keybindsPanel.LayoutOrder = 4
        keybindsPanel.Parent = leftCol

        local kbTitle = Instance.new("TextLabel")
        kbTitle.BackgroundTransparency = 1
        kbTitle.Font = Enum.Font.GothamBold
        kbTitle.Text = "Keybinds"
        kbTitle.TextColor3 = Color3.fromRGB(70, 70, 70)
        kbTitle.TextSize = 20
        kbTitle.TextXAlignment = Enum.TextXAlignment.Left
        kbTitle.Size = UDim2.new(1, 0, 0, 24)
        kbTitle.Parent = keybindsPanel

        local kbText = Instance.new("TextLabel")
        kbText.BackgroundTransparency = 1
        kbText.Font = Enum.Font.Gotham
        kbText.Text = "E — Inventory\nB — Item Browser\nC — Crafting\nG — Debug Tools\nR — Recipes"
        kbText.TextColor3 = Color3.fromRGB(70, 70, 70)
        kbText.TextSize = 18
        kbText.TextXAlignment = Enum.TextXAlignment.Left
        kbText.TextYAlignment = Enum.TextYAlignment.Top
        kbText.TextWrapped = true
        kbText.Size = UDim2.new(1, 0, 0, 80)
        kbText.Position = UDim2.new(0, 0, 0, 28)
        kbText.Parent = keybindsPanel

        local continueButton = Instance.new("TextButton")
        continueButton.Name = "ContinueButton"
        continueButton.Size = UDim2.new(0, 220, 0, 40)
        continueButton.Position = UDim2.new(0, 0, 0, 112)
        continueButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        continueButton.BackgroundTransparency = 0.1
        continueButton.BorderSizePixel = 0
        continueButton.AutoButtonColor = true
        continueButton.Font = Enum.Font.GothamBold
        continueButton.TextColor3 = Color3.fromRGB(65, 120, 160)
        continueButton.TextSize = 20
        continueButton.Text = "Continue"
        continueButton.Parent = keybindsPanel
        local contCorner = Instance.new("UICorner")
        contCorner.CornerRadius = UDim.new(0, 12)
        contCorner.Parent = continueButton
        local contStroke = Instance.new("UIStroke")
        contStroke.Color = Color3.fromRGB(200, 220, 240)
        contStroke.Transparency = 0.2
        contStroke.Thickness = 2
        contStroke.Parent = continueButton

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
        startButton.Parent = leftCol

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
        tipLabel.Parent = leftCol

        -- Wire panel actions
        applyButton.MouseButton1Click:Connect(function()
                applyGraphicsPreset(_selectedPreset)
                settingsPanel.Visible = false
                keybindsPanel.Visible = true
                LoadingScreen.setStatus("Keybinds overview")
        end)
        continueButton.MouseButton1Click:Connect(function()
                keybindsPanel.Visible = false
                LoadingScreen.setStatus("Press start to continue")
                showStartButton("Press to Start", true)
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
                settingsPanel = settingsPanel,
                applyButton = applyButton,
                keybindsPanel = keybindsPanel,
                continueButton = continueButton,
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
        startPlaneAnimation()
        startTipRotation()
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
                        {BackgroundTransparency = 1}
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
                        ContentProvider:PreloadAsync({assetId})
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
                        LoadingScreen.setStatus("Choose your settings")
                        if refs.settingsPanel then refs.settingsPanel.Visible = true end
                        if refs.keybindsPanel then refs.keybindsPanel.Visible = false end
                        hideStartButton()
                else
                        -- Fallback: show Start if refs missing
                        LoadingScreen.setStatus("Press start to continue")
                        showStartButton("Press to Start", true)
                end
        end)
end

return LoadingScreen
