local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

-- Get ToolObjects module
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ToolObjects = require(Shared:WaitForChild("ToolObjects"))

local function resolveRemoteEvents(context: string)
    local container = ReplicatedStorage:WaitForChild("RemoteEvents")
    local remoteEvents = nil

    if container:IsA("ModuleScript") then
        local ok, moduleOrError = pcall(require, container)
        if ok and typeof(moduleOrError) == "table" then
            remoteEvents = moduleOrError
        else
            warn(
                string.format("[%s] ⚠️ Failed to require RemoteEvents module: %s", context, tostring(moduleOrError))
            )
        end
    end

    if remoteEvents and remoteEvents.ToolEvents then
        return remoteEvents
    end

    -- Fallback: treat RemoteEvents as a folder populated in Studio.
    local toolFolder = container:FindFirstChild("ToolEvents")
    if not toolFolder then
        warn(string.format("[%s] ⚠️ ToolEvents folder missing under ReplicatedStorage.RemoteEvents", context))
        return nil
    end

    return {
        ToolEvents = {
            Folder = toolFolder,
            Use = toolFolder:FindFirstChild("ToolUse"),
            Feedback = toolFolder:FindFirstChild("ToolFeedback"),
        },
    }
end

local RemoteEvents = resolveRemoteEvents("FishingController")

local TOOL_TYPE = "fishing"
local TOOL_ACTION = {
    CAST = "cast",
    ATTEMPT_CATCH = "attempt_catch",
    BITE = "bite",
    CATCH_RESULT = "catch_result",
    CAST_FAILED = "cast_failed",
}

local ToolEvents = RemoteEvents and RemoteEvents.ToolEvents

local FishingController = {}
FishingController.__index = FishingController

local QUICK_TIME_DURATION = 1.5
local MIN_BITE_DELAY = 2
local MAX_BITE_DELAY = 5

local function isFishingTool(tool: Instance?): boolean
    if not tool or not tool:IsA("Tool") then
        return false
    end

    local toolType = tool:GetAttribute("ToolType")
    if toolType and string.find(string.lower(tostring(toolType)), "fish") then
        return true
    end

    local lowerName = string.lower(tool.Name)
    if string.find(lowerName, "fish") or string.find(lowerName, "rod") then
        return true
    end

    return false
end

local function createTextLabel(name: string, textSize: number, zIndex: number)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize
    label.TextStrokeTransparency = 0.4
    label.TextStrokeColor3 = Color3.fromRGB(40, 60, 80)
    label.TextWrapped = true
    label.Visible = false
    label.ZIndex = zIndex
    return label
end

function FishingController.new()
    local self = setmetatable({}, FishingController)

    self.player = Players.LocalPlayer
    self.mouse = self.player:GetMouse()

    self.toolUseRemote = ToolEvents and ToolEvents.Use
    self.toolFeedbackRemote = ToolEvents and ToolEvents.Feedback

    self.isFishing = false
    self.hasBite = false
    self.castPosition = nil
    self.castLocation = nil
    self.equippedTool = nil
    self.hasShownNoRodMessage = false

    self.bobber = nil
    self.bobberFloatConnection = nil
    self.exclamationGui = nil

    self.biteThread = nil
    self.timeoutThread = nil
    self.messageThread = nil
    self.promptConnection = nil

    self.screenGui = nil
    self.messageLabel = nil
    self.promptLabel = nil

    self.remoteConnection = nil
    self.mouseConnection = nil
    self.characterAddedConnection = nil

    self:setupGui()

    return self
end

function FishingController:setupGui()
    local playerGui = self.player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishingHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local messageLabel = createTextLabel("MessageLabel", 26, 5)
    messageLabel.Size = UDim2.new(0, 360, 0, 60)
    messageLabel.Position = UDim2.new(0.5, -180, 0.8, 0)
    messageLabel.Text = ""
    messageLabel.Parent = screenGui

    local promptLabel = createTextLabel("PromptLabel", 32, 6)
    promptLabel.Size = UDim2.new(0, 280, 0, 70)
    promptLabel.Position = UDim2.new(0.5, -140, 0.6, 0)
    promptLabel.Text = "Press E!"
    promptLabel.TextColor3 = Color3.fromRGB(255, 244, 122)
    promptLabel.Parent = screenGui

    self.screenGui = screenGui
    self.messageLabel = messageLabel
    self.promptLabel = promptLabel
end

function FishingController:init()
    self:connectRemote()
    self:setupCharacterListeners()
    self:connectMouse()
end

function FishingController:connectRemote()
    if self.remoteConnection then
        self.remoteConnection:Disconnect()
    end

    if not self.toolFeedbackRemote then
        warn("[FishingController] ⚠️ ToolFeedback remote missing; fishing feedback disabled.")
        return
    end

    self.remoteConnection = self.toolFeedbackRemote.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" or payload.toolType ~= TOOL_TYPE then
            return
        end

        local action = payload.action
        if action == TOOL_ACTION.BITE then
            self:onBite(payload.data or {})
        elseif action == TOOL_ACTION.CATCH_RESULT then
            self:handleCatchResult(payload.data or payload)
        elseif action == TOOL_ACTION.CAST_FAILED then
            self:showMessage((payload.message or "Cast failed!"), 2)
            self.isFishing = false
        end
    end)
end

function FishingController:onBite(data)
    data = data or {}
    print("[FishingController] 🐟 BITE!", data.fishName or "something")
    self.hasBite = true

    -- Show prompt
    if self.promptLabel then
        self.promptLabel.Visible = true
        self.promptLabel.Text = "Press E!"
    end

    -- Listen for E key
    if self.promptConnection then
        self.promptConnection:Disconnect()
    end

    self.promptConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == Enum.KeyCode.E and self.hasBite then
            self:attemptCatch()
        end
    end)

    -- Auto-hide after 3 seconds
    task.delay(3, function()
        if self.promptLabel then
            self.promptLabel.Visible = false
        end
        if self.promptConnection then
            self.promptConnection:Disconnect()
        end
        self.hasBite = false
        self.isFishing = false
    end)
end

function FishingController:attemptCatch()
    print("[FishingController] Attempting catch...")
    if self.toolUseRemote then
        self.toolUseRemote:FireServer({
            toolType = TOOL_TYPE,
            action = TOOL_ACTION.ATTEMPT_CATCH,
        })
    else
        warn("[FishingController] ⚠️ ToolUse remote missing; cannot send catch request.")
    end

    if self.promptLabel then
        self.promptLabel.Visible = false
    end
    if self.promptConnection then
        self.promptConnection:Disconnect()
    end

    self.hasBite = false
    self.isFishing = false
end

function FishingController:setupCharacterListeners()
    local function handleTool(tool)
        if not tool:IsA("Tool") then
            return
        end

        if isFishingTool(tool) and tool.Parent == self.player.Character then
            self.equippedTool = tool
        end

        tool.AncestryChanged:Connect(function(_, parent)
            if parent ~= self.player.Character and tool == self.equippedTool then
                self.equippedTool = nil
                self:cancel()
            end
        end)

        tool.Equipped:Connect(function()
            if isFishingTool(tool) then
                self.equippedTool = tool
            end
        end)

        tool.Unequipped:Connect(function()
            if tool == self.equippedTool then
                self.equippedTool = nil
                self:cancel()
            end
        end)
    end

    local function onCharacter(character)
        for _, child in ipairs(character:GetChildren()) do
            handleTool(child)
        end

        character.ChildAdded:Connect(function(child)
            handleTool(child)
        end)

        character.ChildRemoved:Connect(function(child)
            if child == self.equippedTool then
                self.equippedTool = nil
                self:cancel()
            end
        end)
    end

    local character = self.player.Character or self.player.CharacterAdded:Wait()
    onCharacter(character)

    self.characterAddedConnection = self.player.CharacterAdded:Connect(function(char)
        self:resetState()
        onCharacter(char)
    end)
end

function FishingController:connectMouse()
    if self.mouseConnection then
        self.mouseConnection:Disconnect()
    end

    self.mouseConnection = self.mouse.Button1Down:Connect(function()
        self:onCastRequested()
    end)

    -- Also listen for tool activation (clicking with tool equipped)
    local character = self.player.Character
    if character then
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and isFishingTool(child) then
                child.Activated:Connect(function()
                    self:onCastRequested()
                end)
            end
        end)

        -- Connect to existing tools
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") and isFishingTool(child) then
                child.Activated:Connect(function()
                    self:onCastRequested()
                end)
            end
        end
    end
end

function FishingController:isToolReady(): boolean
    if self.equippedTool and self.equippedTool.Parent == self.player.Character then
        return true
    end

    local character = self.player.Character
    if not character then
        return false
    end

    for _, child in ipairs(character:GetChildren()) do
        if isFishingTool(child) then
            self.equippedTool = child
            return true
        end
    end

    return false
end

function FishingController:onCastRequested()
    if self.isFishing then
        return
    end

    if not self:isToolReady() then
        -- Message disabled - don't show "Equip a fishing rod first!"
        -- if not self.hasShownNoRodMessage then
        --     self.hasShownNoRodMessage = true
        --     self:showMessage("Equip a fishing rod first!", 2)
        -- end
        return
    end

    self.hasShownNoRodMessage = false

    if UserInputService:GetFocusedTextBox() then
        return
    end

    -- Use ToolObjects to cast the fishing rod
    local character = self.player.Character
    if character and self.equippedTool then
        local success, result = ToolObjects.castFishingRod(self.equippedTool, character, 50)
        if success and result then
            print("[FishingController] 🎣 Cast successful!")
            self.isFishing = true
            self.castPosition = result

            if self.toolUseRemote then
                self.toolUseRemote:FireServer({
                    toolType = TOOL_TYPE,
                    action = TOOL_ACTION.CAST,
                    position = result,
                })
            else
                warn("[FishingController] ⚠️ ToolUse remote missing; cannot notify server about cast.")
            end

            return
        elseif not success and result then
            -- Show error message
            self:showMessage(result, 2)
            return
        end
    end
end

function FishingController:isWater(target: Instance?, position: Vector3)
    local origin = position + Vector3.new(0, 6, 0)
    local direction = Vector3.new(0, -12, 0)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { self.player.Character }
    params.IgnoreWater = false

    local result = Workspace:Raycast(origin, direction, params)
    local instance = result and result.Instance or target

    if not instance then
        return nil
    end

    local material = result and result.Material or (instance:IsA("Terrain") and Enum.Material.Air or instance.Material)
    local name = string.lower(instance.Name)

    local isWaterMaterial = material == Enum.Material.Water
    local isWaterName = string.find(name, "water")
        or string.find(name, "river")
        or string.find(name, "pond")
        or string.find(name, "ocean")

    if not isWaterMaterial and not isWaterName then
        return nil
    end

    local locationType = self:resolveLocationFromInstance(instance)
    local hitPosition = result and result.Position or position

    return hitPosition + Vector3.new(0, 0.1, 0), locationType
end

function FishingController:resolveLocationFromInstance(instance: Instance): string
    if not instance then
        return "river"
    end

    local attr = instance:GetAttribute("WaterType")
    if typeof(attr) == "string" then
        local lower = string.lower(attr)
        if lower == "river" or lower == "ocean" or lower == "pond" then
            return lower
        end
    end

    if CollectionService:HasTag(instance, "OceanWater") then
        return "ocean"
    end
    if CollectionService:HasTag(instance, "RiverWater") then
        return "river"
    end
    if CollectionService:HasTag(instance, "PondWater") then
        return "pond"
    end

    local lowerName = string.lower(instance.Name)
    if string.find(lowerName, "ocean") or string.find(lowerName, "sea") then
        return "ocean"
    elseif string.find(lowerName, "pond") or string.find(lowerName, "lake") then
        return "pond"
    elseif string.find(lowerName, "river") or string.find(lowerName, "stream") then
        return "river"
    end

    return "river"
end

function FishingController:createBobber(position: Vector3)
    local part = Instance.new("Part")
    part.Name = "FishingBobber"
    part.Anchored = true
    part.CanCollide = false
    part.Color = Color3.fromRGB(255, 138, 121)
    part.Material = Enum.Material.SmoothPlastic
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(0.25, 0.25, 0.25)
    part.CFrame = CFrame.new(position)
    part.Parent = Workspace

    local baseline = position
    local start = tick()

    self.bobberFloatConnection = RunService.Heartbeat:Connect(function()
        if not part or not part.Parent then
            return
        end
        local elapsed = tick() - start
        local offset = math.sin(elapsed * 3) * 0.1
        part.Position = baseline + Vector3.new(0, offset, 0)
    end)

    return part
end

function FishingController:destroyBobber()
    if self.bobberFloatConnection then
        self.bobberFloatConnection:Disconnect()
        self.bobberFloatConnection = nil
    end

    if self.exclamationGui then
        self.exclamationGui:Destroy()
        self.exclamationGui = nil
    end

    if self.bobber then
        self.bobber:Destroy()
        self.bobber = nil
    end
end

function FishingController:showExclamation()
    if not self.bobber then
        return
    end

    if self.exclamationGui then
        self.exclamationGui:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FishingBite"
    billboard.Size = UDim2.new(0, 40, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = self.bobber

    local indicator = Instance.new("TextLabel")
    indicator.BackgroundTransparency = 1
    indicator.Text = "!"
    indicator.Font = Enum.Font.GothamBlack
    indicator.TextSize = 36
    indicator.TextColor3 = Color3.fromRGB(255, 229, 92)
    indicator.TextStrokeTransparency = 0.1
    indicator.TextStrokeColor3 = Color3.fromRGB(139, 81, 29)
    indicator.Size = UDim2.new(1, 0, 1, 0)
    indicator.Parent = billboard

    self.exclamationGui = billboard

    TweenService:Create(indicator, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextSize = 48,
    }):Play()
end

function FishingController:showPrompt()
    if not self.promptLabel then
        return
    end
    self.promptLabel.Visible = true
    self.promptLabel.TextTransparency = 0
end

function FishingController:hidePrompt()
    if self.promptLabel then
        self.promptLabel.Visible = false
    end
end

function FishingController:showMessage(message: string?, duration: number?)
    if not self.messageLabel then
        return
    end

    self.messageLabel.Text = message or ""
    self.messageLabel.Visible = true

    if self.messageThread then
        task.cancel(self.messageThread)
        self.messageThread = nil
    end

    if duration and duration > 0 then
        self.messageThread = task.delay(duration, function()
            if self.messageLabel then
                self.messageLabel.Visible = false
            end
            self.messageThread = nil
        end)
    end
end

function FishingController:cast(position: Vector3, locationType: string)
    self:resetState()

    self.isFishing = true
    self.castPosition = position
    self.castLocation = locationType or "river"

    self.bobber = self:createBobber(position)

    self:showMessage("Waiting for a bite...", math.random(12, 18) / 10)

    local delaySeconds = math.random(MIN_BITE_DELAY * 10, MAX_BITE_DELAY * 10) / 10
    self.biteThread = task.delay(delaySeconds, function()
        self.biteThread = nil
        if self.isFishing then
            self:triggerBite()
        end
    end)
end

function FishingController:triggerBite()
    if not self.isFishing or not self.bobber then
        return
    end

    self.hasBite = true
    self:showExclamation()
    self:showPrompt()
    self:showMessage("Press E!", QUICK_TIME_DURATION)

    if self.promptConnection then
        self.promptConnection:Disconnect()
        self.promptConnection = nil
    end

    self.promptConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.E then
            self:catch()
        end
    end)

    self.timeoutThread = task.delay(QUICK_TIME_DURATION, function()
        self.timeoutThread = nil
        if self.hasBite then
            self:miss()
        end
    end)
end

function FishingController:getCurrentHour(): number
    local ok, serverTime = pcall(function()
        return Workspace:GetServerTimeNow()
    end)

    if ok and typeof(serverTime) == "number" then
        local secondsInDay = 24 * 60 * 60
        local seconds = serverTime % secondsInDay
        return math.floor(seconds / 3600)
    end

    local now = os.date("*t")
    if typeof(now) == "table" and now.hour then
        return now.hour
    end

    return 12
end

function FishingController:getTimeOfDay(): string
    local hour = self:getCurrentHour()
    if hour >= 5 and hour < 18 then
        return "day"
    elseif hour >= 18 and hour < 21 then
        return "evening"
    else
        return "night"
    end
end

function FishingController:catch()
    if not self.hasBite then
        return
    end

    self:showMessage("Reeling in...", 1)
    self:attemptCatch()
end

function FishingController:miss()
    self:showMessage("The fish got away...", 2)
    self:resetState()
end

function FishingController:cancel()
    if self.isFishing then
        self:showMessage("Fishing canceled.", 1.5)
    end
    self:resetState()
end

function FishingController:clearQuickTime()
    self:hidePrompt()

    if self.timeoutThread then
        task.cancel(self.timeoutThread)
        self.timeoutThread = nil
    end

    if self.promptConnection then
        self.promptConnection:Disconnect()
        self.promptConnection = nil
    end

    if self.exclamationGui then
        self.exclamationGui:Destroy()
        self.exclamationGui = nil
    end
end

function FishingController:clearBiteThread()
    if self.biteThread then
        task.cancel(self.biteThread)
        self.biteThread = nil
    end
end

function FishingController:resetState()
    self:clearBiteThread()
    self:clearQuickTime()
    self:destroyBobber()

    self.isFishing = false
    self.hasBite = false
    self.castPosition = nil
    self.castLocation = nil
end

function FishingController:handleCatchResult(result)
    result = result or {}

    if result.success then
        local text
        if result.message then
            text = result.message
        elseif result.fishName then
            text = string.format("You caught a %s!", result.fishName)
        else
            text = "You caught a fish!"
        end

        if result.bellsEarned and result.bellsEarned > 0 then
            text = string.format("%s +%d Bells", text, result.bellsEarned)
        end

        self:showMessage(text, 3)
    else
        self:showMessage(result.message or "The fish slipped away...", 2.5)
    end

    self:resetState()
end

return FishingController
