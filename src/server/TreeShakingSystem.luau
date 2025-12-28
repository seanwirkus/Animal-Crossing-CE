--[[
	TreeShakingSystem.luau
	Handles tree shaking mechanics - players can shake trees to get apples and other items
	Features:
	- Visual apples displayed on trees before shaking
	- Realistic leaf shaking animation with rotation and bounce
	- Apple dropping physics
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local TreeShakingSystem = {}
TreeShakingSystem.__index = TreeShakingSystem
TreeShakingSystem.addItemToInventory = nil

-- Apple asset ID (legacy fallback if no Workspace.Apple template is present)
local APPLE_ASSET_ID = nil -- Optional legacy fallback

-- Configuration
local CONFIG = {
    SHAKE_DURATION = 0.8,
    SHAKE_INTENSITY = 1.5,
    LEAF_SHAKE_INTENSITY = 0.3, -- Rotation intensity for leaves
    APPLE_DROP_CHANCE = 0.7, -- 70% chance to drop apple
    MAX_APPLES_PER_TREE = 2, -- Max apples that can drop from one shake
    APPLE_RESPAWN_TIME = 300, -- 5 minutes before tree can drop apples again
    COOLDOWN_TIME = 2, -- 2 seconds between shakes
    -- Visual apple settings
    VISUAL_APPLE_COUNT = 2, -- Number of apples to show on tree
    APPLE_SIZE = Vector3.new(0.6, 0.6, 0.6),
    APPLE_COLOR = Color3.fromRGB(220, 40, 40), -- Red apple color
    APPLE_SIZE_IN_TREE = Vector3.new(1.2, 1.2, 1.2), -- 2x size for apples in trees
}

-- Track tree states
local treeStates = {} -- [treeModel] = {lastShakeTime, lastAppleDropTime, canDropApples, visualApples}
local playerCooldowns = {} -- [player] = lastShakeTime

--[[
	Create a visual apple part to attach to tree leaves
]]
local function createVisualApple(position: Vector3, parent: Instance): BasePart
    local apple = Instance.new("Part")
    apple.Name = "VisualApple"
    apple.Size = CONFIG.APPLE_SIZE_IN_TREE
    apple.Shape = Enum.PartType.Ball
    apple.Material = Enum.Material.SmoothPlastic
    apple.Color = CONFIG.APPLE_COLOR
    apple.Anchored = true
    apple.CanCollide = false
    apple.CastShadow = true
    apple.CFrame = CFrame.new(position)
    apple.Parent = parent

    -- Add a small stem
    local stem = Instance.new("Part")
    stem.Name = "Stem"
    stem.Size = Vector3.new(0.08, 0.15, 0.08)
    stem.Material = Enum.Material.Wood
    stem.Color = Color3.fromRGB(101, 67, 33)
    stem.Anchored = true
    stem.CanCollide = false
    stem.CFrame = CFrame.new(position + Vector3.new(0, CONFIG.APPLE_SIZE.Y / 2 + 0.05, 0))
    stem.Parent = apple

    -- Weld stem to apple
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = apple
    weld.Part1 = stem
    weld.Parent = apple

    return apple
end

--[[
	Spawn visual apples on a tree's leaves
]]
function TreeShakingSystem._spawnVisualApples(treeModel: Model)
    local treeState = treeStates[treeModel]
    if not treeState then return end

    -- Clear existing visual apples
    TreeShakingSystem._clearVisualApples(treeModel)

    -- Find leaves container
    local leavesContainer = treeModel:FindFirstChild("LeavesModel")
        or treeModel:FindFirstChild("Leaves model")
        or treeModel:FindFirstChild("Leaves")

    if not leavesContainer then
        for _, desc in ipairs(treeModel:GetDescendants()) do
            if desc:IsA("Model") or desc:IsA("Folder") then
                local name = desc.Name:lower()
                if name == "leavesmodel" or name == "leaves model" or (name:find("leaves") and name:find("model")) then
                    leavesContainer = desc
                    break
                end
            end
        end
    end

    if not leavesContainer then return end

    -- Find leaf parts to attach apples to
    local leafParts = {}
    for _, desc in ipairs(leavesContainer:GetDescendants()) do
        if desc:IsA("BasePart") then
            table.insert(leafParts, desc)
        end
    end

    if #leafParts == 0 then return end

    -- Create visual apples folder
    local applesFolder = Instance.new("Folder")
    applesFolder.Name = "VisualApples"
    applesFolder.Parent = treeModel

    treeState.visualApples = {}

    -- Spawn apples at random positions within the leaves
    for i = 1, CONFIG.VISUAL_APPLE_COUNT do
        local randomLeaf = leafParts[math.random(1, #leafParts)]
        local leafCF = randomLeaf.CFrame
        local leafSize = randomLeaf.Size

        -- Random offset within the leaf bounds (slightly below to look like hanging)
        local offset = Vector3.new(
            (math.random() - 0.5) * leafSize.X * 0.6,
            -leafSize.Y * 0.3 - math.random() * 0.5,
            (math.random() - 0.5) * leafSize.Z * 0.6
        )

        local applePos = leafCF.Position + offset
        local apple = createVisualApple(applePos, applesFolder)
        table.insert(treeState.visualApples, apple)
    end
end

--[[
	Clear visual apples from a tree
]]
function TreeShakingSystem._clearVisualApples(treeModel: Model)
    local applesFolder = treeModel:FindFirstChild("VisualApples")
    if applesFolder then
        applesFolder:Destroy()
    end

    local treeState = treeStates[treeModel]
    if treeState then
        treeState.visualApples = {}
    end
end

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

    -- Initialize trees in the workspace with visual apples
    task.spawn(function()
        task.wait(2) -- Wait for world to load
        TreeShakingSystem._initializeAllTrees()
    end)

    print("[TreeShakingSystem] ✅ Tree shaking system ready")
end

--[[
	Initialize all trees in the workspace with visual apples
]]
function TreeShakingSystem._initializeAllTrees()
    -- Find all trees in workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("tree") or name:find("fruit") then
                -- Initialize tree state if not exists
                if not treeStates[obj] then
                    treeStates[obj] = {
                        lastShakeTime = 0,
                        lastAppleDropTime = 0,
                        canDropApples = true,
                        visualApples = {},
                    }
                end

                -- Spawn visual apples on the tree
                if treeStates[obj].canDropApples then
                    TreeShakingSystem._spawnVisualApples(obj)
                end
            end
        end
    end

    print("[TreeShakingSystem] 🍎 Initialized visual apples on all trees")
end

function TreeShakingSystem.setAddItemFunction(addItemFunc)
    TreeShakingSystem.addItemToInventory = addItemFunc
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
            visualApples = {},
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
            -- Respawn visual apples
            TreeShakingSystem._spawnVisualApples(treeModel)
        end
    end

    -- Animate tree shaking (leaves shake with rotation)
    TreeShakingSystem._animateTreeShake(treeModel)

    -- Drop apples if possible
    if treeState.canDropApples and math.random() < CONFIG.APPLE_DROP_CHANCE then
        local appleCount = math.random(1, CONFIG.MAX_APPLES_PER_TREE)

        -- Clear visual apples (they're falling!)
        TreeShakingSystem._clearVisualApples(treeModel)

        TreeShakingSystem._dropApples(treeModel, appleCount, player)
        treeState.lastAppleDropTime = now
        treeState.canDropApples = false
    end

    treeState.lastShakeTime = now
end

--[[
	Collect all leaf parts from a tree model for shaking animation
]]
local function collectLeafParts(treeModel)
    local leafParts = {}

    -- Find leaves container (try multiple naming conventions)
    local leavesContainer = treeModel:FindFirstChild("LeavesModel")
        or treeModel:FindFirstChild("Leaves model")
        or treeModel:FindFirstChild("Leaves")

    if not leavesContainer then
        for _, desc in ipairs(treeModel:GetDescendants()) do
            if desc:IsA("Model") or desc:IsA("Folder") then
                local name = desc.Name:lower()
                if name:find("leaves") then
                    leavesContainer = desc
                    break
                end
            end
        end
    end

    -- Collect all BaseParts from the leaves container
    if leavesContainer then
        for _, desc in ipairs(leavesContainer:GetDescendants()) do
            if desc:IsA("BasePart") then
                table.insert(leafParts, desc)
            end
        end
        -- Also include the container itself if it's a BasePart
        if leavesContainer:IsA("BasePart") then
            table.insert(leafParts, leavesContainer)
        end
    end

    -- Fallback: find any parts with "leaf" in the name
    if #leafParts == 0 then
        for _, desc in ipairs(treeModel:GetDescendants()) do
            if desc:IsA("BasePart") then
                local name = desc.Name:lower()
                if name:find("leaf") or name:find("foliage") then
                    table.insert(leafParts, desc)
                end
            end
        end
    end

    return leafParts
end

--[[
	Animate tree shaking - makes leaf parts visibly shake
]]
function TreeShakingSystem._animateTreeShake(treeModel: Model)
    local leafParts = collectLeafParts(treeModel)

    if #leafParts == 0 then
        warn("[TreeShakingSystem] No leaf parts found to shake for:", treeModel.Name)
        return
    end

    -- Store original CFrames
    local originalCFrames = {}
    for _, part in ipairs(leafParts) do
        originalCFrames[part] = part.CFrame
    end

    -- Shake animation parameters
    local shakeSteps = 10
    local dampingFactor = 0.8

    for i = 1, shakeSteps do
        local damping = math.pow(dampingFactor, i - 1)
        local direction = (i % 2 == 0) and 1 or -1

        -- Shake offsets
        local horizontalOffset = CONFIG.SHAKE_INTENSITY * 0.5 * direction * damping
        local verticalOffset = CONFIG.SHAKE_INTENSITY * 0.3 * direction * damping
        local rotationAngle = math.rad(CONFIG.LEAF_SHAKE_INTENSITY * 20 * direction * damping)

        for _, part in ipairs(leafParts) do
            local original = originalCFrames[part]
            if original and part.Parent then
                local offset = Vector3.new(horizontalOffset, verticalOffset, horizontalOffset * 0.3)
                local rotation = CFrame.Angles(rotationAngle * 0.5, 0, rotationAngle)
                part.CFrame = original * CFrame.new(offset) * rotation
            end
        end

        task.wait(CONFIG.SHAKE_DURATION / shakeSteps)
    end

    -- Return to original position with tween
    for part, original in pairs(originalCFrames) do
        if part and part.Parent then
            local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(part, tweenInfo, { CFrame = original })
            tween:Play()
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
                -- Scale apple parts to be 2x larger when dropped from trees
                for _, part in ipairs(apple:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Size = part.Size * 2
                    end
                end
            else
                apple:MoveTo(spawnPosition)
                -- Scale apple parts to be 2x larger when dropped from trees
                for _, part in ipairs(apple:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Size = part.Size * 2
                    end
                end
            end
        elseif apple:IsA("BasePart") then
            apple.CFrame = CFrame.new(spawnPosition)
            -- Scale apple to be 2x larger when dropped from trees
            apple.Size = apple.Size * 2
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
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.MaxActivationDistance = 8
        prompt.RequiresLineOfSight = false

        -- Attach to primary part or first part
        local applePart = apple:IsA("Model") and (apple.PrimaryPart or apple:FindFirstChildOfClass("BasePart"))
            or (apple:IsA("BasePart") and apple)
        if applePart then
            prompt.Parent = applePart

            -- Handle pickup
            prompt.Triggered:Connect(function(pickingPlayer)
                if TreeShakingSystem.addItemToInventory then
                    local success, err = TreeShakingSystem.addItemToInventory(pickingPlayer, {
                        itemId = "apple",
                        count = 1,
                    })
                    if success then
                        print("[TreeShakingSystem] 🍎", pickingPlayer.Name, "picked up an apple")
                        apple:Destroy()
                    else
                        warn("[TreeShakingSystem] ⚠️ Failed to add apple to inventory:", err)
                    end
                else
                    warn("[TreeShakingSystem] ⚠️ addItemToInventory not set - cannot grant apple")
                end
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
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Parent = apple

    -- Handle pickup
    prompt.Triggered:Connect(function(pickingPlayer)
        if TreeShakingSystem.addItemToInventory then
            local success, err = TreeShakingSystem.addItemToInventory(pickingPlayer, {
                itemId = "apple",
                count = 1,
            })
            if success then
                print("[TreeShakingSystem] 🍎", pickingPlayer.Name, "picked up an apple")
                apple:Destroy()
            else
                warn("[TreeShakingSystem] ⚠️ Failed to add apple to inventory:", err)
            end
        else
            warn("[TreeShakingSystem] ⚠️ addItemToInventory not set - cannot grant apple")
        end
    end)
end

return TreeShakingSystem
