--[[
	CutsceneManager.luau
	
	Handles cinematic sequences with camera control, character focus, transitions,
	and orchestration. Used for onboarding, special events, and story moments.
	
	Features:
	- Camera movement and tweening
	- Character/object focus
	- Fade in/out transitions
	- Sequence chaining
	- Background music control
	
	Usage:
		local cutscene = CutsceneManager.new()
		cutscene:startSequence({
			{type = "fade", direction = "out", duration = 1},
			{type = "camera", target = workspace.TomNook.Head, duration = 2},
			{type = "dialogue", text = "Welcome!", speaker = "Tom Nook"},
			{type = "fade", direction = "in", duration = 1}
		})
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local _RunService = game:GetService("RunService") -- (unused currently)
local _Lighting = game:GetService("Lighting") -- (unused currently)

local CutsceneManager = {}
CutsceneManager.__index = CutsceneManager

-- Active cutscene state
local _activeCutscene = nil

function CutsceneManager.new()
    local self = setmetatable({}, CutsceneManager)

    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera
    self.originalCameraType = self.camera.CameraType
    self.originalCameraSubject = self.camera.CameraSubject

    -- Fade GUI
    self.fadeGui = nil
    self.fadeFrame = nil

    -- Sequence state
    self.isPlaying = false
    self.currentSequence = nil
    self.currentStep = 0
    self.onComplete = nil

    -- Camera tweens
    self._currentCameraTween = nil

    -- Cinematic overlay (letterbox bars + dialogue panel)
    self.cinematicGui = nil
    self.topBar = nil
    self.bottomBar = nil
    self.dialoguePanel = nil
    self.speakerLabel = nil
    self.dialogueLabel = nil
    self.continueHint = nil
    self._letterboxShown = false
    self._dialogueConnections = {}

    print("[CutsceneManager] ✅ Initialized")

    return self
end

--[[
	Build the cinematic overlay: top/bottom letterbox bars and a dialogue panel.
	Reused across letterbox + dialogue steps so they share one ScreenGui.
]]
function CutsceneManager:_createCinematicGui()
    if self.cinematicGui then
        return
    end

    local playerGui = self.player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "CutsceneCinematic"
    gui.DisplayOrder = 1001 -- Above the fade overlay
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Enabled = true

    -- Top letterbox bar (starts off-screen)
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.AnchorPoint = Vector2.new(0.5, 0)
    topBar.Position = UDim2.new(0.5, 0, 0, -120)
    topBar.Size = UDim2.new(1, 0, 0, 110)
    topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    topBar.BorderSizePixel = 0
    topBar.Parent = gui

    -- Bottom letterbox bar (starts off-screen)
    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomBar"
    bottomBar.AnchorPoint = Vector2.new(0.5, 1)
    bottomBar.Position = UDim2.new(0.5, 0, 1, 120)
    bottomBar.Size = UDim2.new(1, 0, 0, 110)
    bottomBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = gui

    -- Dialogue panel (Animal Crossing style cream box, bottom center)
    local panel = Instance.new("Frame")
    panel.Name = "DialoguePanel"
    panel.AnchorPoint = Vector2.new(0.5, 1)
    panel.Position = UDim2.new(0.5, 0, 1, 130) -- starts hidden below
    panel.Size = UDim2.fromOffset(720, 150)
    panel.BackgroundColor3 = Color3.fromRGB(255, 250, 235)
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 16)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(180, 150, 120)
    panelStroke.Thickness = 2
    panelStroke.Parent = panel

    local panelPadding = Instance.new("UIPadding")
    panelPadding.PaddingTop = UDim.new(0, 16)
    panelPadding.PaddingBottom = UDim.new(0, 16)
    panelPadding.PaddingLeft = UDim.new(0, 22)
    panelPadding.PaddingRight = UDim.new(0, 22)
    panelPadding.Parent = panel

    local speakerLabel = Instance.new("TextLabel")
    speakerLabel.Name = "Speaker"
    speakerLabel.Size = UDim2.new(1, 0, 0, 26)
    speakerLabel.BackgroundTransparency = 1
    speakerLabel.Font = Enum.Font.GothamBold
    speakerLabel.TextSize = 20
    speakerLabel.TextColor3 = Color3.fromRGB(90, 130, 70)
    speakerLabel.TextXAlignment = Enum.TextXAlignment.Left
    speakerLabel.Text = ""
    speakerLabel.Parent = panel

    local dialogueLabel = Instance.new("TextLabel")
    dialogueLabel.Name = "Body"
    dialogueLabel.Position = UDim2.fromOffset(0, 32)
    dialogueLabel.Size = UDim2.new(1, 0, 1, -58)
    dialogueLabel.BackgroundTransparency = 1
    dialogueLabel.Font = Enum.Font.Gotham
    dialogueLabel.TextSize = 18
    dialogueLabel.TextColor3 = Color3.fromRGB(70, 55, 45)
    dialogueLabel.TextWrapped = true
    dialogueLabel.TextXAlignment = Enum.TextXAlignment.Left
    dialogueLabel.TextYAlignment = Enum.TextYAlignment.Top
    dialogueLabel.Text = ""
    dialogueLabel.Parent = panel

    local continueHint = Instance.new("TextLabel")
    continueHint.Name = "ContinueHint"
    continueHint.AnchorPoint = Vector2.new(1, 1)
    continueHint.Position = UDim2.fromScale(1, 1)
    continueHint.Size = UDim2.fromOffset(200, 22)
    continueHint.BackgroundTransparency = 1
    continueHint.Font = Enum.Font.GothamMedium
    continueHint.TextSize = 14
    continueHint.TextColor3 = Color3.fromRGB(150, 130, 110)
    continueHint.TextXAlignment = Enum.TextXAlignment.Right
    continueHint.Text = "Click or press E ▶"
    continueHint.Parent = panel

    gui.Parent = playerGui

    self.cinematicGui = gui
    self.topBar = topBar
    self.bottomBar = bottomBar
    self.dialoguePanel = panel
    self.speakerLabel = speakerLabel
    self.dialogueLabel = dialogueLabel
    self.continueHint = continueHint

    print("[CutsceneManager] ✅ Created cinematic overlay")
end

--[[
	Slide the letterbox bars in/out.
	@param show true to reveal bars, false to hide
	@param duration seconds for the slide (default 0.6)
]]
function CutsceneManager:setLetterbox(show: boolean, duration: number?)
    self:_createCinematicGui()
    duration = duration or 0.6
    self._letterboxShown = show

    local topGoal = show and UDim2.fromScale(0.5, 0) or UDim2.new(0.5, 0, 0, -120)
    local bottomGoal = show and UDim2.fromScale(0.5, 1) or UDim2.new(0.5, 0, 1, 120)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    TweenService:Create(self.topBar, info, { Position = topGoal }):Play()
    local bottomTween = TweenService:Create(self.bottomBar, info, { Position = bottomGoal })
    bottomTween:Play()
    bottomTween.Completed:Wait()
end

--[[
	Show a single dialogue line and yield until the player advances
	(clicks the panel or presses E / Enter / Space).
	@param speaker name shown in the header
	@param text dialogue body
]]
function CutsceneManager:showDialogue(speaker: string?, text: string?)
    self:_createCinematicGui()

    self.speakerLabel.Text = speaker or "Guide"
    self.dialogueLabel.Text = text or ""

    -- Slide the panel up into view if hidden
    if not self.dialoguePanel.Visible then
        self.dialoguePanel.Visible = true
        self.dialoguePanel.Position = UDim2.new(0.5, 0, 1, 130)
        TweenService:Create(
            self.dialoguePanel,
            TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, 0, 1, -40) }
        ):Play()
    end

    -- Wait for the player to advance
    local advanced = false
    local function advance()
        advanced = true
    end

    local clickDetector = Instance.new("TextButton")
    clickDetector.Name = "AdvanceCatcher"
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.Size = UDim2.fromScale(1, 1)
    clickDetector.ZIndex = 5
    clickDetector.Parent = self.dialoguePanel
    clickDetector.MouseButton1Click:Connect(advance)

    local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if
            input.KeyCode == Enum.KeyCode.E
            or input.KeyCode == Enum.KeyCode.Return
            or input.KeyCode == Enum.KeyCode.Space
        then
            advance()
        end
    end)

    -- Small guard so the same click that opened the panel doesn't skip it
    task.wait(0.15)
    repeat
        task.wait()
    until advanced or not self.isPlaying

    inputConn:Disconnect()
    if clickDetector then
        clickDetector:Destroy()
    end
end

--[[
	Hide the dialogue panel (slide it back down).
]]
function CutsceneManager:hideDialogue()
    if not self.dialoguePanel or not self.dialoguePanel.Visible then
        return
    end

    local tween = TweenService:Create(
        self.dialoguePanel,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, 0, 1, 130) }
    )
    tween:Play()
    tween.Completed:Wait()
    self.dialoguePanel.Visible = false
end

--[[
	Create fade overlay GUI (black screen for transitions)
]]
function CutsceneManager:_createFadeGui()
    if self.fadeGui then
        return
    end

    local playerGui = self.player:WaitForChild("PlayerGui")

    -- Create fade overlay
    self.fadeGui = Instance.new("ScreenGui")
    self.fadeGui.Name = "CutsceneFade"
    self.fadeGui.DisplayOrder = 1000 -- On top of everything
    self.fadeGui.ResetOnSpawn = false
    self.fadeGui.IgnoreGuiInset = true

    self.fadeFrame = Instance.new("Frame")
    self.fadeFrame.Name = "FadeFrame"
    self.fadeFrame.Size = UDim2.new(1, 0, 1, 0)
    self.fadeFrame.Position = UDim2.new(0, 0, 0, 0)
    self.fadeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    self.fadeFrame.BackgroundTransparency = 1 -- Start invisible
    self.fadeFrame.BorderSizePixel = 0
    self.fadeFrame.Parent = self.fadeGui

    self.fadeGui.Parent = playerGui

    print("[CutsceneManager] ✅ Created fade GUI")
end

--[[
	Fade screen to/from black
	@param direction "in" (to black) or "out" (from black to clear)
	@param duration Seconds to complete fade
	@return Promise-like (yields until complete)
]]
function CutsceneManager:fade(direction: string, duration: number)
    self:_createFadeGui()

    local targetTransparency = direction == "in" and 0 or 1

    print(string.format("[CutsceneManager] 🎬 Fading %s over %.1fs", direction, duration))

    local tween = TweenService:Create(
        self.fadeFrame,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { BackgroundTransparency = targetTransparency }
    )

    tween:Play()
    tween.Completed:Wait()

    print(string.format("[CutsceneManager] ✅ Fade %s complete", direction))
end

--[[
	Move camera to focus on a target (Part, Model, CFrame, or Vector3)
	@param target The target to focus on
	@param duration Seconds to complete movement
	@param offset Optional CFrame offset from target
]]
function CutsceneManager:focusCamera(target: Instance | CFrame | Vector3, duration: number, offset: CFrame?)
    -- Set camera to Scriptable mode
    self.camera.CameraType = Enum.CameraType.Scriptable

    -- Calculate target CFrame
    local targetCFrame: CFrame

    if typeof(target) == "Instance" then
        if target:IsA("BasePart") then
            targetCFrame = target.CFrame
        elseif target:IsA("Model") then
            targetCFrame = target:GetPivot()
        else
            warn("[CutsceneManager] ❌ Invalid target type:", target.ClassName)
            return
        end
    elseif typeof(target) == "CFrame" then
        targetCFrame = target
    elseif typeof(target) == "Vector3" then
        targetCFrame = CFrame.new(target)
    else
        warn("[CutsceneManager] ❌ Invalid target type:", typeof(target))
        return
    end

    -- Apply offset (e.g., move camera back a bit, look from angle)
    if offset then
        targetCFrame = targetCFrame * offset
    else
        -- Default: pull back 5 studs on Z axis
        targetCFrame = targetCFrame * CFrame.new(0, 2, 5)
    end

    print(string.format("[CutsceneManager] 🎥 Focusing camera on target over %.1fs", duration))

    -- Cancel any existing tween
    if self._currentCameraTween then
        self._currentCameraTween:Cancel()
    end

    -- Tween camera to target
    self._currentCameraTween = TweenService:Create(
        self.camera,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { CFrame = targetCFrame }
    )

    self._currentCameraTween:Play()
    self._currentCameraTween.Completed:Wait()

    print("[CutsceneManager] ✅ Camera focus complete")
end

--[[
	Reset camera back to player control
]]
function CutsceneManager:resetCamera()
    -- Cancel any running tweens
    if self._currentCameraTween then
        self._currentCameraTween:Cancel()
        self._currentCameraTween = nil
    end

    -- Restore original camera settings
    self.camera.CameraType = self.originalCameraType
    self.camera.CameraSubject = self.originalCameraSubject

    print("[CutsceneManager] ✅ Camera reset to player control")
end

--[[
	Wait for a duration (for sequencing)
	@param duration Seconds to wait
]]
function CutsceneManager:wait(duration: number)
    print(string.format("[CutsceneManager] ⏱️ Waiting %.1fs", duration))
    task.wait(duration)
end

--[[
	Play a cutscene sequence
	@param sequence Array of steps {type, ...params}
	@param onComplete Callback when sequence finishes
	
	Step types:
	- {type = "fade", direction = "in"/"out", duration = 1}
	- {type = "camera", target = Part, duration = 2, offset = CFrame}
	- {type = "wait", duration = 1}
	- {type = "dialogue", text = "...", speaker = "..."}
	- {type = "callback", func = function() end}
	- {type = "reset"} - Reset camera to player
	
	Example:
		cutscene:startSequence({
			{type = "fade", direction = "in", duration = 1},
			{type = "camera", target = workspace.TomNook.Head, duration = 2},
			{type = "wait", duration = 0.5},
			{type = "dialogue", text = "Welcome!", speaker = "Tom Nook"},
			{type = "fade", direction = "out", duration = 1},
			{type = "reset"}
		})
]]
function CutsceneManager:startSequence(sequence: { { [string]: any } }, onComplete: (() -> ())?)
    if self.isPlaying then
        warn("[CutsceneManager] ⚠️ Cutscene already playing - cannot start new sequence")
        return
    end

    self.isPlaying = true
    self.currentSequence = sequence
    self.currentStep = 0
    self.onComplete = onComplete

    _activeCutscene = self

    print(string.format("[CutsceneManager] 🎬 Starting sequence with %d steps", #sequence))

    -- Run sequence in coroutine
    task.spawn(function()
        for i, step in ipairs(sequence) do
            self.currentStep = i
            print(string.format("[CutsceneManager] 📍 Step %d/%d: %s", i, #sequence, step.type))

            if step.type == "fade" then
                self:fade(step.direction or "in", step.duration or 1)
            elseif step.type == "camera" then
                self:focusCamera(step.target, step.duration or 2, step.offset)
            elseif step.type == "wait" then
                self:wait(step.duration or 1)
            elseif step.type == "dialogue" then
                -- Show a cinematic dialogue line and wait for the player to advance
                print(
                    string.format("[CutsceneManager] 💬 Dialogue: %s - '%s'", step.speaker or "???", step.text or "")
                )
                self:showDialogue(step.speaker, step.text)
            elseif step.type == "letterbox" then
                -- Toggle the cinematic letterbox bars
                self:setLetterbox(step.show ~= false, step.duration)
            elseif step.type == "callback" then
                if step.func and type(step.func) == "function" then
                    local success, err = pcall(step.func)
                    if not success then
                        warn("[CutsceneManager] ❌ Callback error:", err)
                    end
                end
            elseif step.type == "reset" then
                self:resetCamera()
            else
                warn("[CutsceneManager] ⚠️ Unknown step type:", step.type)
            end
        end

        -- Tidy up cinematic overlay: drop the dialogue panel and retract bars
        self:hideDialogue()
        if self._letterboxShown then
            self:setLetterbox(false, 0.5)
        end

        -- Sequence complete
        self.isPlaying = false
        self.currentSequence = nil
        self.currentStep = 0
        _activeCutscene = nil

        -- Auto-clean fade overlay if it's fully transparent (to prevent lingering half-opaque GUI)
        if self.fadeGui and self.fadeFrame then
            local frame = self.fadeFrame
            -- If we've faded "out" (to clear) and transparency is at or above 0.99, destroy overlay
            if frame.BackgroundTransparency >= 0.99 then
                self.fadeGui:Destroy()
                self.fadeGui = nil
                self.fadeFrame = nil
                print("[CutsceneManager] 🧹 Cleaned up fade overlay")
            end
        end

        print("[CutsceneManager] ✅ Sequence complete!")

        if self.onComplete then
            self.onComplete()
        end
    end)
end

--[[
	Stop the current cutscene (emergency stop)
]]
function CutsceneManager:stop()
    if not self.isPlaying then
        return
    end

    print("[CutsceneManager] ⛔ Stopping cutscene")

    self.isPlaying = false
    self.currentSequence = nil
    self.currentStep = 0
    _activeCutscene = nil

    -- Reset camera
    self:resetCamera()

    -- Clear fade
    if self.fadeGui then
        self.fadeGui:Destroy()
        self.fadeGui = nil
        self.fadeFrame = nil
    end

    -- Clear cinematic overlay
    if self.cinematicGui then
        self.cinematicGui:Destroy()
        self.cinematicGui = nil
        self.topBar = nil
        self.bottomBar = nil
        self.dialoguePanel = nil
        self.speakerLabel = nil
        self.dialogueLabel = nil
        self.continueHint = nil
        self._letterboxShown = false
    end
end

--[[
	Check if a cutscene is currently playing
]]
function CutsceneManager.isPlaying(): boolean
    return _activeCutscene ~= nil
end

--[[
	Cleanup
]]
function CutsceneManager:destroy()
    self:stop()

    if self.fadeGui then
        self.fadeGui:Destroy()
    end

    if self.cinematicGui then
        self.cinematicGui:Destroy()
    end

    print("[CutsceneManager] 🗑️ Destroyed")
end

return CutsceneManager
