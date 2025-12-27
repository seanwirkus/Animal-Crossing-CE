--[[
	TreeShakingSystem.luau
	Handles tree shaking mechanics - players can shake trees to get apples and other items
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local TreeShakingSystem = {}
TreeShakingSystem.__index = TreeShakingSystem

-- Apple asset ID (legacy fallback if no Workspace.Apple template is present)
local APPLE_ASSET_ID = nil -- Optional legacy fallback

-- Configuration
local CONFIG = {
    SHAKE_DURATION = 0.6,
    SHAKE_INTENSITY = 2,
    APPLE_DROP_CHANCE = 0.7, -- 70% chance to drop apple
    MAX_APPLES_PER_TREE = 3, -- Max apples that can drop from one shake
    APPLE_RESPAWN_TIME = 300, -- 5 minutes before tree can drop apples again
    COOLDOWN_TIME = 2, -- 2 seconds between shakes
}

-- Track tree states
local treeStates = {} -- [treeModel] = {lastShakeTime, lastAppleDropTime, canDropApples}
local playerCooldowns = {} -- [player] = lastShakeTime

--[[
	Initialize the tree shaking system
]]
function TreeShakingSystem.init(appleAssetId: number?)
    APPLE_ASSET_ID = appleAssetId
    print("[TreeShakingSystem] 🌳 Initialized tree shaking system")
    if Workspace:FindFirstChild("Apple") then
        print("[TreeShakingSystem] 🍎 Apple template found in Workspace")
    elseif APPLE_ASSET_ID then
        print("[TreeShakingSystem] 🍎 Apple asset ID:", APPLE_ASSET_ID)
    else
        warn("[TreeShakingSystem] ⚠️ No apple template found - apples will use fallback parts")
    end

    -- Find or create RemoteEvent for tree shaking
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = ReplicatedStorage
    end

    local shakeTreeRemote = remoteEventsFolder:FindFirstChild("ShakeTree")
    if not shakeTreeRemote then
        shakeTreeRemote = Instance.new("RemoteEvent")
        shakeTreeRemote.Name = "ShakeTree"
        shakeTreeRemote.Parent = remoteEventsFolder
    end

    -- Handle tree shaking requests
    shakeTreeRemote.OnServerEvent:Connect(function(player, treeModel)
        TreeShakingSystem.shakeTree(player, treeModel)
    end)

    print("[TreeShakingSystem] ✅ Tree shaking system ready")
end

--[[
	Shake a tree and drop apples
]]
function TreeShakingSystem.shakeTree(player: Player, treeModel: Model)
    if not player or not treeModel or not treeModel.Parent then
        return
    end

    -- Check cooldown
    local now = tick()
    if playerCooldowns[player] and (now - playerCooldowns[player]) < CONFIG.COOLDOWN_TIME then
        return -- Still on cooldown
    end
    playerCooldowns[player] = now

    -- Get tree state
    local treeState = treeStates[treeModel]
    if not treeState then
        treeState = {
            lastShakeTime = 0,
            lastAppleDropTime = 0,
            canDropApples = true,
        }
        treeStates[treeModel] = treeState
    end

    -- Check if tree can drop apples (respawn timer)
    if treeState.lastAppleDropTime > 0 then
        local timeSinceLastDrop = now - treeState.lastAppleDropTime
        if timeSinceLastDrop < CONFIG.APPLE_RESPAWN_TIME then
            -- Tree was recently shaken, can't drop apples yet
            treeState.canDropApples = false
        else
            -- Enough time has passed, can drop apples again
            treeState.canDropApples = true
        end
    end

    -- Animate tree shaking
    TreeShakingSystem._animateTreeShake(treeModel)

    -- Drop apples if possible
    if treeState.canDropApples and math.random() < CONFIG.APPLE_DROP_CHANCE then
        local appleCount = math.random(1, CONFIG.MAX_APPLES_PER_TREE)
        TreeShakingSystem._dropApples(treeModel, appleCount, player)
        treeState.lastAppleDropTime = now
        treeState.canDropApples = false
    end

    treeState.lastShakeTime = now
end

--[[
	Animate tree shaking
]]
function TreeShakingSystem._animateTreeShake(treeModel: Model)
    local leafParts = {}
    for _, desc in ipairs(treeModel:GetDescendants()) do
        if desc:IsA("BasePart") then
            local name = desc.Name:lower()
            local parentName = desc.Parent and desc.Parent.Name:lower() or ""
            if name:find("leaf") or name:find("foliage") or parentName:find("leaf") or parentName:find("foliage") then
                table.insert(leafParts, desc)
            end
        end
    end

    if #leafParts == 0 then
        return
    end

    local originalCFrames = {}
    for _, part in ipairs(leafParts) do
        originalCFrames[part] = part.CFrame
    end

    -- Create vertical shake animation (leaves only)
    local shakeSteps = 8
    for i = 1, shakeSteps do
        local direction = (i % 2 == 0) and 1 or -1
        local offset = Vector3.new(0, CONFIG.SHAKE_INTENSITY * direction, 0)
        for _, part in ipairs(leafParts) do
            local original = originalCFrames[part]
            if original then
                part.CFrame = original * CFrame.new(offset)
            end
        end
        task.wait(CONFIG.SHAKE_DURATION / shakeSteps)
    end

    -- Return to original position
    for part, original in pairs(originalCFrames) do
        if part and part.Parent then
            part.CFrame = original
        end
    end
end

--[[
	Drop apples from tree
]]
function TreeShakingSystem._dropApples(treeModel: Model, count: number, player: Player)
    local rootPart = treeModel.PrimaryPart or treeModel:FindFirstChildOfClass("BasePart")
    if not rootPart then
        return
    end

    local treePosition = rootPart.Position
    local treeTop = treePosition + Vector3.new(0, 10, 0) -- Drop from top of tree

    local appleTemplate = Workspace:FindFirstChild("Apple")
    if not appleTemplate then
        warn("[TreeShakingSystem] ⚠️ Apple template not found in Workspace - using fallback apples")
        for i = 1, count do
            TreeShakingSystem._createFallbackApple(treeTop, player)
        end
        return
    end

    -- Clone and drop apples
    for i = 1, count do
        local apple = appleTemplate:Clone()
        apple.Name = "Apple"

        -- Position apple at tree top with random offset
        local offset = Vector3.new((math.random() - 0.5) * 4, 0, (math.random() - 0.5) * 4)
        local spawnPosition = treeTop + offset

        if apple:IsA("Model") then
            local primary = apple.PrimaryPart or apple:FindFirstChildWhichIsA("BasePart", true)
            if primary then
                apple.PrimaryPart = primary
                apple:PivotTo(CFrame.new(spawnPosition))
            else
                apple:MoveTo(spawnPosition)
            end
        elseif apple:IsA("BasePart") then
            apple.CFrame = CFrame.new(spawnPosition)
        end

        -- Make apple fall with physics
        for _, part in ipairs(apple:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = true
                part.Massless = false
                -- Add initial velocity for realistic drop
                part.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * 5, -5, (math.random() - 0.5) * 5)
            end
        end
        if apple:IsA("BasePart") then
            apple.Anchored = false
            apple.CanCollide = true
            apple.Massless = false
            apple.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * 5, -5, (math.random() - 0.5) * 5)
        end

        apple.Parent = workspace

        -- Add ProximityPrompt for pickup
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "PickupApple"
        prompt.ActionText = "Pick Up"
        prompt.ObjectText = "Apple"
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 8
        prompt.RequiresLineOfSight = false

        -- Attach to primary part or first part
        local applePart = apple:IsA("Model") and (apple.PrimaryPart or apple:FindFirstChildOfClass("BasePart"))
            or (apple:IsA("BasePart") and apple)
        if applePart then
            prompt.Parent = applePart

            -- Handle pickup
            prompt.Triggered:Connect(function(pickingPlayer)
                -- Add apple to inventory
                local inventoryEvent = ReplicatedStorage:FindFirstChild("RemoteEvents")
                    :FindFirstChild("InventoryEvent")
                if inventoryEvent then
                    inventoryEvent:FireServer(pickingPlayer, "add_item", "apple", 1)
                    print("[TreeShakingSystem] 🍎", pickingPlayer.Name, "picked up an apple")
                end

                -- Destroy apple
                apple:Destroy()
            end)
        else
            -- Fallback if model structure is unexpected
            TreeShakingSystem._createFallbackApple(treeTop, player)
        end
    end
end

--[[
	Create a fallback apple (simple red sphere) if asset loading fails
]]
function TreeShakingSystem._createFallbackApple(position: Vector3, player: Player)
    local apple = Instance.new("Part")
    apple.Name = "Apple"
    apple.Size = Vector3.new(0.5, 0.5, 0.5)
    apple.Shape = Enum.PartType.Ball
    apple.Material = Enum.Material.SmoothPlastic
    apple.Color = Color3.fromRGB(255, 0, 0) -- Red apple
    apple.Anchored = false
    apple.CanCollide = true
    apple.Massless = false
    apple.CFrame = CFrame.new(position)
    apple.Parent = workspace

    -- Add initial velocity
    apple.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * 5, -5, (math.random() - 0.5) * 5)

    -- Add ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PickupApple"
    prompt.ActionText = "Pick Up"
    prompt.ObjectText = "Apple"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Parent = apple

    -- Handle pickup
    prompt.Triggered:Connect(function(pickingPlayer)
        local inventoryEvent = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("InventoryEvent")
        if inventoryEvent then
            inventoryEvent:FireServer(pickingPlayer, "add_item", "apple", 1)
            print("[TreeShakingSystem] 🍎", pickingPlayer.Name, "picked up an apple")
        end
        apple:Destroy()
    end)
end

return TreeShakingSystem
