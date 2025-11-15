--[[
	ACNHCamera.luau
	
	Smoothed default Roblox camera:
	- Keeps classic controls (right-mouse drag, mouse wheel zoom, mobile gestures)
	- Adds a subtle per-frame smoothing pass for cinematic feel
	- Applies a light motion blur based on camera translation speed
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SettingsController = require(script.Parent.SettingsController)

local ACNHCamera = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SMOOTH_SPEED = 10
local DEFAULT_FOV = 75
local BASE_BLUR_MULTIPLIER = 2
local MAX_BLUR_SIZE = 6

local _isActive = false
local _smoothedCFrame = nil
local _blurEffect = nil
local _characterAddedConn = nil

local function ensureBlurEffect()
    if _blurEffect and _blurEffect.Parent then
        return _blurEffect
    end

    local blur = Lighting:FindFirstChild("ACNHCameraBlur")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "ACNHCameraBlur"
        blur.Size = 0
        blur.Parent = Lighting
    end

    _blurEffect = blur
    return _blurEffect
end

local function attachCameraToHumanoid(humanoid)
    if not humanoid then
        return
    end

    camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    if not camera then
        return
    end

    local needsSnap = camera.CameraSubject ~= humanoid or camera.CameraType ~= Enum.CameraType.Custom
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid

    if needsSnap then
        local rootPart = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local lookVector = rootPart.CFrame.LookVector
            local offset = Vector3.new(0, 6, -12)
            camera.CFrame = CFrame.new(rootPart.Position + offset, rootPart.Position + lookVector)
        end
    end
end

function ACNHCamera.init()
    if _isActive then
        ACNHCamera.disable()
    end

    SettingsController.init()

    _isActive = true
    camera = workspace.CurrentCamera

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")

    if camera then
        camera.FieldOfView = DEFAULT_FOV
    end
    attachCameraToHumanoid(humanoid)

    player.CameraMode = Enum.CameraMode.Classic
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    local blur = ensureBlurEffect()
    blur.Size = 0
    _smoothedCFrame = nil

    RunService:BindToRenderStep("ACNHSmoothCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not _isActive then
            return
        end

        camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local targetCFrame = camera.CFrame
        if not _smoothedCFrame then
            _smoothedCFrame = targetCFrame
        else
            local alpha = math.clamp(dt * SMOOTH_SPEED, 0, 1)
            _smoothedCFrame = _smoothedCFrame:Lerp(targetCFrame, alpha)
            camera.CFrame = _smoothedCFrame
        end

        local translation = (_smoothedCFrame.Position - targetCFrame.Position).Magnitude
        local blurSetting = SettingsController.getSetting("blurIntensity")
        if typeof(blurSetting) ~= "number" then
            blurSetting = 0.25
        end
        blurSetting = math.clamp(blurSetting, 0, 1)
        local maxBlur = MAX_BLUR_SIZE * blurSetting
        if maxBlur <= 0 then
            blur.Size = 0
        else
            blur.Size = math.clamp(translation * BASE_BLUR_MULTIPLIER * blurSetting, 0, maxBlur)
        end
    end)

    if _characterAddedConn then
        _characterAddedConn:Disconnect()
    end

    _characterAddedConn = player.CharacterAdded:Connect(function(newCharacter)
        if not _isActive then
            return
        end

        local newHumanoid = newCharacter:WaitForChild("Humanoid")
        attachCameraToHumanoid(newHumanoid)
        _smoothedCFrame = nil
    end)

    print("[ACNHCamera] ✅ Smoothing enabled with classic controls")
end

function ACNHCamera.disable()
    if not _isActive then
        return
    end

    _isActive = false
    RunService:UnbindFromRenderStep("ACNHSmoothCamera")

    if _characterAddedConn then
        _characterAddedConn:Disconnect()
        _characterAddedConn = nil
    end

    camera = workspace.CurrentCamera
    if camera then
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                attachCameraToHumanoid(humanoid)
            end
        else
            camera.CameraType = Enum.CameraType.Custom
        end
    end

    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    if _blurEffect then
        _blurEffect.Size = 0
    end

    _smoothedCFrame = nil
    print("[ACNHCamera] Camera reset to default")
end

return ACNHCamera
