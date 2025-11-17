--[[
	ShovelClient.luau
	
	Client-side shovel handling:
	- Detects when player uses shovel
	- Sends dig request to server
	- Shows visual feedback
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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

local RemoteEvents = resolveRemoteEvents("ShovelClient")

local ShovelClient = {}

local TOOL_TYPE = "shovel"
local player = Players.LocalPlayer

local toolEvents = RemoteEvents and RemoteEvents.ToolEvents
local toolUseRemote = toolEvents and toolEvents.Use
local toolFeedbackRemote = toolEvents and toolEvents.Feedback

local isShovelEquipped = false
local savedWalkSpeed = 16
local savedJumpPower = 50

local function getMouseTargetPosition()
    local mouse = player:GetMouse()
    if not mouse then
        return nil, nil
    end

    local character = player.Character
    if not character then
        return nil, nil
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return nil, nil
    end

    -- Raycast from camera to mouse hit position
    local camera = workspace.CurrentCamera
    if not camera then
        return nil, nil
    end

    local rayOrigin = camera.CFrame.Position
    local rayDirection = (mouse.Hit.Position - rayOrigin).Unit * 100

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = { character }

    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if rayResult then
        return rayResult.Position, rayResult.Instance
    end

    return mouse.Hit.Position, mouse.Target
end

local function fireDigRequest(targetPosition, targetInstance)
    if not toolUseRemote then
        warn("[ShovelClient] ⚠️ ToolUse remote is missing")
        return
    end

    toolUseRemote:FireServer({
        toolType = TOOL_TYPE,
        action = "dig",
        toolId = player:GetAttribute("EquippedToolId"),
        position = targetPosition,
        targetInstance = targetInstance,
    })
end

local function onToolActivated(tool)
    if not tool.Name:lower():find("shovel") then
        return
    end

    -- Disabled: Tool activation no longer triggers digging
    -- Only right-click activates digging now
    -- print("[ShovelClient] 🪓 Dig requested via tool activation (ignored - use right-click)")
    -- local targetPosition, targetInstance = getMouseTargetPosition()
    -- fireDigRequest(targetPosition, targetInstance)
end

local isDigging = false -- Track if currently digging

local function checkForEquippedShovel(character)
    local hasShovel = false
    
    -- Check player attribute first
    local equippedToolType = player:GetAttribute("EquippedToolType")
    if equippedToolType and tostring(equippedToolType):lower():find("shovel") then
        hasShovel = true
    end
    
    -- Check for Tool objects with "shovel" in name
    if not hasShovel then
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") and child.Name:lower():find("shovel") then
                hasShovel = true
                break
            end
        end
    end
    
    -- Check for visual attachment (EquippedTool model with Shovel inside)
    if not hasShovel then
        local equippedTool = character:FindFirstChild("EquippedTool")
        if equippedTool and equippedTool:IsA("Model") then
            local shovelModel = equippedTool:FindFirstChild("Shovel")
            if shovelModel then
                hasShovel = true
            end
        end
    end

    local wasEquipped = isShovelEquipped
    isShovelEquipped = hasShovel

    -- Don't block movement when equipping - only block during actual digging
    -- Just update the equipped state
    if hasShovel and not wasEquipped then
        print("[ShovelClient] 🔨 Shovel equipped (movement enabled)")
    elseif not hasShovel and wasEquipped then
        -- If unequipping while digging, restore movement
        if isDigging then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = savedWalkSpeed
                humanoid.JumpPower = savedJumpPower
                isDigging = false
                print("[ShovelClient] 🔓 Movement restored (shovel unequipped)")
            end
        end
    end
end

local function playDigAnimation(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end

    -- Block movement during digging
    if not isDigging then
        isDigging = true
        savedWalkSpeed = humanoid.WalkSpeed
        savedJumpPower = humanoid.JumpPower
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        print("[ShovelClient] 🔒 Movement disabled (digging started)")
    end

    -- Try to load dig animation from ReplicatedStorage
    local animationsFolder = ReplicatedStorage:FindFirstChild("Animations")
    if animationsFolder then
        local digAnimation = animationsFolder:FindFirstChild("Dig")
        if digAnimation and digAnimation:IsA("Animation") then
            local animationTrack = humanoid:LoadAnimation(digAnimation)
            if animationTrack then
                animationTrack:Play()
                
                -- Restore movement when animation completes
                animationTrack.Ended:Connect(function()
                    if isDigging then
                        humanoid.WalkSpeed = savedWalkSpeed
                        humanoid.JumpPower = savedJumpPower
                        isDigging = false
                        print("[ShovelClient] 🔓 Movement restored (digging finished)")
                    end
                end)
                
                return animationTrack
            end
        end
    end

    -- Create a smooth digging animation using TweenService
    local TweenService = game:GetService("TweenService")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local rightArm = character:FindFirstChild("Right Arm")
    
    if rootPart then
        -- Store original positions
        local originalCFrame = rootPart.CFrame
        local originalArmCFrame = rightArm and rightArm.CFrame or nil
        
        -- Animate digging motion: character leans forward and arm swings down
        -- Tween 1: Lean forward and raise arm
        local leanTween = TweenService:Create(
            rootPart,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { CFrame = originalCFrame * CFrame.Angles(math.rad(-15), 0, 0) }
        )
        
        local armTween = nil
        if rightArm then
            armTween = TweenService:Create(
                rightArm,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { CFrame = (originalArmCFrame or rightArm.CFrame) * CFrame.Angles(math.rad(45), 0, 0) }
            )
        end
        
        leanTween:Play()
        if armTween then
            armTween:Play()
        end
        
        -- Tween 2: Swing down (dig motion)
        task.wait(0.15)
        
        local digDownTween = TweenService:Create(
            rootPart,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { CFrame = originalCFrame * CFrame.Angles(math.rad(-25), 0, 0) }
        )
        
        local armDownTween = nil
        if rightArm then
            armDownTween = TweenService:Create(
                rightArm,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { CFrame = (originalArmCFrame or rightArm.CFrame) * CFrame.Angles(math.rad(80), 0, 0) }
            )
        end
        
        digDownTween:Play()
        if armDownTween then
            armDownTween:Play()
        end
        
        -- Tween 3: Return to normal
        task.wait(0.2)
        
        local returnTween = TweenService:Create(
            rootPart,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { CFrame = originalCFrame }
        )
        
        local armReturnTween = nil
        if rightArm then
            armReturnTween = TweenService:Create(
                rightArm,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { CFrame = originalArmCFrame or rightArm.CFrame }
            )
        end
        
        returnTween:Play()
        if armReturnTween then
            armReturnTween:Play()
        end
        
        -- Wait for animation to complete and restore movement
        task.spawn(function()
            task.wait(0.5) -- Total animation duration
            if rootPart and rootPart.Parent and isDigging and humanoid then
                humanoid.WalkSpeed = savedWalkSpeed
                humanoid.JumpPower = savedJumpPower
                isDigging = false
                print("[ShovelClient] 🔓 Movement restored (digging finished)")
            end
        end)
    end

    return nil
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed or not isShovelEquipped then
        return
    end

    -- Only right-click (MouseButton2) activates digging
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local targetPosition, targetInstance = getMouseTargetPosition()
        if targetPosition then
            print("[ShovelClient] 🕳️ Right-click dig requested at:", targetPosition)
            
            -- Play dig animation
            local character = player.Character
            if character then
                playDigAnimation(character)
            end
            
            fireDigRequest(targetPosition, targetInstance)
        end
    end
    -- Removed left-click and spacebar - only right-click activates digging
end

local function connectCharacterListeners(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Activated:Connect(function()
                onToolActivated(child)
            end)
        end
        checkForEquippedShovel(character)
    end)

    character.ChildRemoved:Connect(function()
        checkForEquippedShovel(character)
    end)

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            child.Activated:Connect(function()
                onToolActivated(child)
            end)
        end
    end

    checkForEquippedShovel(character)
end

function ShovelClient.init()
    print("[ShovelClient] 🔨 Initializing shovel client...")

    if player.Character then
        connectCharacterListeners(player.Character)
    end

    player.CharacterAdded:Connect(connectCharacterListeners)

    UserInputService.InputBegan:Connect(onInputBegan)

    if toolFeedbackRemote then
        toolFeedbackRemote.OnClientEvent:Connect(function(payload)
            if type(payload) ~= "table" or payload.toolType ~= TOOL_TYPE then
                return
            end

            if payload.action == "dig_success" then
                local resultType = payload.resultType or (payload.data and payload.data.resultType)
                print("[ShovelClient] ✅ Dig success:", resultType or "unknown")
            elseif payload.action == "dig_failed" then
                warn("[ShovelClient] ❌ Dig failed:", payload.message or "Unknown reason")
            end
        end)
    else
        warn("[ShovelClient] ⚠️ ToolFeedback remote is missing")
    end

    print("[ShovelClient] ✅ Shovel client initialized")
end

return ShovelClient
