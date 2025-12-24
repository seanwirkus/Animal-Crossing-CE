local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local TOOL_MODELS = {
    -- Fishing Rods (with underscores to match sprite IDs)
    ["fishing_rod"] = "FishingRod",
    ["flimsy_fishing_rod"] = "FlimsyFishingRod",
    ["golden_fishing_rod"] = "GoldenFishingRod",

    -- Also support hyphenated versions
    ["fishing-rod"] = "FishingRod",
    ["flimsy-fishing-rod"] = "FlimsyFishingRod",
    ["golden-fishing-rod"] = "GoldenFishingRod",

    -- Nets
    ["net"] = "Net",
    ["flimsy_net"] = "FlimsyNet",
    ["golden_net"] = "GoldenNet",

    -- Shovels
    ["shovel"] = "Shovel",
    ["flimsy_shovel"] = "FlimshyShovel",
    ["golden_shovel"] = "GoldenShovel",

    -- Axes
    ["axe"] = "Axe",
    ["flimsy_axe"] = "FlimsyAxe",
    ["stone_axe"] = "StoneAxe",
    ["golden_axe"] = "GoldenAxe",
    ["axe_flimsy"] = "FlimsyAxe",

    -- Others
    ["slingshot"] = "Slingshot",
    ["golden_slingshot"] = "GoldenSlingshot",
    ["vaulting_pole"] = "VaultingPole",
    ["ladder"] = "Ladder",
}

local SLINGSHOT_SCALE = 0.2

local ToolObjects = {}

local function getRightHandPart(character: Model): BasePart?
    return character:FindFirstChild("RightHand")
        or character:FindFirstChild("RightLowerArm")
        or character:FindFirstChild("Right Arm")
        or character:FindFirstChild("RightUpperArm")
        or character:FindFirstChild("Torso")
end

local function ensureDefaultCFrame(part: BasePart?): CFrameValue?
    if not part or not part:IsA("BasePart") then
        return nil
    end

    local existing = part:FindFirstChild("DefaultCFrame")
    if existing and existing:IsA("CFrameValue") then
        return existing
    end

    local defaultValue = Instance.new("CFrameValue")
    defaultValue.Name = "DefaultCFrame"
    defaultValue.Value = part.CFrame
    defaultValue.Parent = part

    return defaultValue
end

local function renameRope(part: BasePart)
    if not part then
        return
    end

    if part.Name == "LettRope" or part.Name == "LeftString" then
        part.Name = "LeftRope"
    elseif part.Name == "RightString" then
        part.Name = "RightRope"
    end
end

local function configureSlingshotParts(tool: Tool, originalModel: Instance)
    if originalModel and originalModel:IsA("Model") then
        local currentPivot = originalModel:GetPivot()
        originalModel:ScaleTo(SLINGSHOT_SCALE)
        originalModel:PivotTo(currentPivot)
    end

    for _, descendant in ipairs(originalModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            renameRope(descendant)
            descendant.CanCollide = false
            descendant.Massless = true
            descendant.Anchored = false
        end
    end

    -- Move original children under the new tool container
    for _, child in ipairs(originalModel:GetChildren()) do
        child.Parent = tool
    end

    local slinger = tool:FindFirstChild("Slinger", true)
    if slinger and slinger:IsA("BasePart") then
        if slinger.Parent ~= tool then
            slinger.Parent = tool
        end
        slinger.CanCollide = false
        slinger.Massless = true
        ensureDefaultCFrame(slinger)
    else
        warn("[ToolObjects] ⚠️ Slingshot model missing Slinger part")
    end

    local handle = tool:FindFirstChild("Handle", true)
    if handle and handle:IsA("BasePart") then
        handle.Name = "Handle"
        handle.CanCollide = false
        handle.Massless = true
        if handle.Parent ~= tool then
            handle.Parent = tool
        end
        ensureDefaultCFrame(handle)
    else
        warn("[ToolObjects] ⚠️ Slingshot model missing Handle part")
    end

    local leftRope = tool:FindFirstChild("LeftRope", true)
    if leftRope and leftRope:IsA("BasePart") then
        ensureDefaultCFrame(leftRope)
    end

    local rightRope = tool:FindFirstChild("RightRope", true)
    if rightRope and rightRope:IsA("BasePart") then
        ensureDefaultCFrame(rightRope)
    end

    if originalModel then
        originalModel:Destroy()
    end

    tool:SetAttribute("SlingshotSetup", true)
end

local function animateSlingshotRelease(tool: Tool)
    local slinger = tool:FindFirstChild("Slinger", true)
    if not slinger or not slinger:IsA("BasePart") then
        return
    end

    local defaultSlinger = ensureDefaultCFrame(slinger)
    if not defaultSlinger then
        return
    end

    local pullTween = TweenService:Create(
        slinger,
        TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { CFrame = defaultSlinger.Value * CFrame.new(0, 0, -0.3) }
    )

    local releaseTween = TweenService:Create(
        slinger,
        TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
        { CFrame = defaultSlinger.Value }
    )

    pullTween:Play()
    pullTween.Completed:Connect(function()
        releaseTween:Play()
    end)

    local function alignRope(ropeName)
        local rope = tool:FindFirstChild(ropeName, true)
        if not rope or not rope:IsA("BasePart") then
            return
        end

        local defaultRope = ensureDefaultCFrame(rope)
        local targetCF = CFrame.lookAt(rope.Position, slinger.Position, rope.CFrame.UpVector)
        local ropePull = TweenService:Create(
            rope,
            TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            { CFrame = targetCF }
        )
        ropePull:Play()
        ropePull.Completed:Connect(function()
            if defaultRope then
                TweenService:Create(
                    rope,
                    TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                    { CFrame = defaultRope.Value }
                ):Play()
            end
        end)
    end

    alignRope("LeftRope")
    alignRope("RightRope")
end

ToolObjects.animateSlingshotRelease = animateSlingshotRelease

local function disableShovelCollision(shovelModel: Model)
    for _, descendant in ipairs(shovelModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.Massless = true
        end
    end
end

-- Create a simple custom shovel model
local function createCustomShovelModel(): Model
    local shovelModel = Instance.new("Model")
    shovelModel.Name = "Shovel"

    -- Shovel handle (long stick)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.2, 2.5, 0.2)
    handle.Material = Enum.Material.Wood
    handle.Color = Color3.fromRGB(101, 67, 33) -- Brown wood
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = shovelModel

    -- Shovel blade (metal part)
    local blade = Instance.new("Part")
    blade.Name = "Blade"
    blade.Size = Vector3.new(0.5, 0.8, 0.1)
    blade.Material = Enum.Material.Metal
    blade.Color = Color3.fromRGB(200, 200, 200) -- Silver metal
    blade.CanCollide = false
    blade.Massless = true
    blade.Parent = shovelModel

    -- Position blade at bottom of handle
    local bladeWeld = Instance.new("WeldConstraint")
    bladeWeld.Part0 = handle
    bladeWeld.Part1 = blade
    bladeWeld.Parent = blade

    blade.CFrame = handle.CFrame * CFrame.new(0, -handle.Size.Y / 2 - blade.Size.Y / 2 + 0.1, 0) * CFrame.Angles(math.rad(-20), 0, 0)

    -- Set primary part
    shovelModel.PrimaryPart = handle

    return shovelModel
end

-- Create a simple custom fishing rod model
local function createCustomFishingRodModel(): Model
    local rodModel = Instance.new("Model")
    rodModel.Name = "FishingRod"

    -- Fishing pole (long stick)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.15, 3, 0.15)
    handle.Material = Enum.Material.Wood
    handle.Color = Color3.fromRGB(139, 90, 43) -- Brown wood
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = rodModel

    -- Reel (small cylinder at bottom)
    local reel = Instance.new("Part")
    reel.Name = "Reel"
    reel.Size = Vector3.new(0.3, 0.3, 0.3)
    reel.Shape = Enum.PartType.Cylinder
    reel.Material = Enum.Material.Metal
    reel.Color = Color3.fromRGB(150, 150, 150)
    reel.CanCollide = false
    reel.Massless = true
    reel.Parent = rodModel

    local reelWeld = Instance.new("WeldConstraint")
    reelWeld.Part0 = handle
    reelWeld.Part1 = reel
    reelWeld.Parent = reel

    reel.CFrame = handle.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(90))

    -- Tip attachment for fishing line
    local tipAttach = Instance.new("Attachment")
    tipAttach.Name = "TipAttachment"
    tipAttach.Position = Vector3.new(0, handle.Size.Y / 2, 0)
    tipAttach.Parent = handle

    -- Float/Bobber
    local float = Instance.new("Part")
    float.Name = "Float"
    float.Size = Vector3.new(0.4, 0.4, 0.4)
    float.Shape = Enum.PartType.Ball
    float.Material = Enum.Material.SmoothPlastic
    float.Color = Color3.fromRGB(255, 80, 80) -- Red bobber
    float.CanCollide = true
    float.Massless = false
    float.Anchored = true
    float.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.3, 0.5, 1, 1)
    float.Position = handle.Position
    float.Parent = rodModel

    local floatAttach = Instance.new("Attachment")
    floatAttach.Name = "FloatAttachment"
    floatAttach.Position = Vector3.new(0, 0, 0)
    floatAttach.Parent = float

    -- Fishing line
    local fishingLine = Instance.new("RopeConstraint")
    fishingLine.Name = "FishingLine"
    fishingLine.Attachment0 = tipAttach
    fishingLine.Attachment1 = floatAttach
    fishingLine.Length = 10
    fishingLine.Visible = true
    fishingLine.Color = BrickColor.new("White")
    fishingLine.Thickness = 0.05
    fishingLine.Restitution = 0
    fishingLine.Parent = rodModel

    rodModel.PrimaryPart = handle

    return rodModel
end

-- Create a simple custom axe model
local function createCustomAxeModel(): Model
    local axeModel = Instance.new("Model")
    axeModel.Name = "Axe"

    -- Axe handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.2, 2, 0.2)
    handle.Material = Enum.Material.Wood
    handle.Color = Color3.fromRGB(101, 67, 33)
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = axeModel

    -- Axe head (metal blade)
    local blade = Instance.new("Part")
    blade.Name = "Blade"
    blade.Size = Vector3.new(0.8, 0.6, 0.15)
    blade.Material = Enum.Material.Metal
    blade.Color = Color3.fromRGB(180, 180, 180)
    blade.CanCollide = false
    blade.Massless = true
    blade.Parent = axeModel

    local bladeWeld = Instance.new("WeldConstraint")
    bladeWeld.Part0 = handle
    bladeWeld.Part1 = blade
    bladeWeld.Parent = blade

    blade.CFrame = handle.CFrame * CFrame.new(0.3, handle.Size.Y / 2 - 0.2, 0) * CFrame.Angles(0, 0, math.rad(45))

    axeModel.PrimaryPart = handle

    return axeModel
end

-- Create a simple custom net model
local function createCustomNetModel(): Model
    local netModel = Instance.new("Model")
    netModel.Name = "Net"

    -- Net handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.15, 2.5, 0.15)
    handle.Material = Enum.Material.Wood
    handle.Color = Color3.fromRGB(101, 67, 33)
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = netModel

    -- Net hoop
    local hoop = Instance.new("Part")
    hoop.Name = "Hoop"
    hoop.Size = Vector3.new(1.2, 0.1, 1.2)
    hoop.Shape = Enum.PartType.Cylinder
    hoop.Material = Enum.Material.Metal
    hoop.Color = Color3.fromRGB(100, 100, 100)
    hoop.CanCollide = false
    hoop.Massless = true
    hoop.Parent = netModel

    local hoopWeld = Instance.new("WeldConstraint")
    hoopWeld.Part0 = handle
    hoopWeld.Part1 = hoop
    hoopWeld.Parent = hoop

    hoop.CFrame = handle.CFrame * CFrame.new(0, handle.Size.Y / 2 + 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))

    -- Net mesh (semi-transparent part)
    local mesh = Instance.new("Part")
    mesh.Name = "Mesh"
    mesh.Size = Vector3.new(1.1, 0.05, 1.1)
    mesh.Shape = Enum.PartType.Cylinder
    mesh.Material = Enum.Material.Fabric
    mesh.Color = Color3.fromRGB(200, 255, 200)
    mesh.Transparency = 0.5
    mesh.CanCollide = false
    mesh.Massless = true
    mesh.Parent = netModel

    local meshWeld = Instance.new("WeldConstraint")
    meshWeld.Part0 = hoop
    meshWeld.Part1 = mesh
    meshWeld.Parent = mesh

    mesh.CFrame = hoop.CFrame

    netModel.PrimaryPart = handle

    return netModel
end

function ToolObjects.getToolModel(spriteId: string): Model?
    print("[ToolObjects] Creating custom tool model for:", spriteId)

    -- Use custom built-in models instead of external assets
    if spriteId:find("shovel") then
        return createCustomShovelModel()
    elseif spriteId:find("fishing") or spriteId:find("rod") then
        return createCustomFishingRodModel()
    elseif spriteId:find("axe") then
        return createCustomAxeModel()
    elseif spriteId:find("net") then
        return createCustomNetModel()
    elseif spriteId:find("slingshot") then
        -- For slingshot, try to find in ReplicatedStorage first, fall back to simple model
        local toolModels = ReplicatedStorage:FindFirstChild("ToolModels")
        if toolModels then
            local model = toolModels:FindFirstChild("Slingshot")
            if model then
                print("[ToolObjects] ✅ Found slingshot model in ReplicatedStorage")
                return model:Clone()
            end
        end
        -- Fall back to a simple slingshot model
        warn("[ToolObjects] ⚠️ Slingshot model not found, using placeholder")
        return nil
    else
        warn("[ToolObjects] ⚠️ No custom model available for:", spriteId)
        return nil
    end
end

-- Check if an item has a 3D model available
function ToolObjects.hasToolModel(spriteId: string): boolean
    return TOOL_MODELS[spriteId] ~= nil
end

-- Get a scaled version of a tool model for ground display
function ToolObjects.getGroundDisplayModel(spriteId: string): Model?
    local model = ToolObjects.getToolModel(spriteId)
    if not model then
        return nil
    end

    -- Scale down the model for ground display (50% size looks good)
    local scaleFactor = 0.5

    -- Find all parts and scale them
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Size = descendant.Size * scaleFactor
            descendant.Anchored = false
            descendant.CanCollide = false
        elseif descendant:IsA("Attachment") then
            descendant.Position = descendant.Position * scaleFactor
        elseif descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
            if descendant:IsA("Weld") then
                descendant.C0 = descendant.C0 * CFrame.new(descendant.C0.Position * (scaleFactor - 1))
                descendant.C1 = descendant.C1 * CFrame.new(descendant.C1.Position * (scaleFactor - 1))
            end
        end
    end

    return model
end

function ToolObjects.equipTool(character: Model, spriteId: string): Tool?
    print("[ToolObjects] Attempting to equip tool:", spriteId)

    local toolModel = ToolObjects.getToolModel(spriteId)
    if not toolModel then
        return nil
    end

    -- Special handling for shovels - create visual attachment instead of functional tool
    if spriteId:find("shovel") then
        print("[ToolObjects] Creating custom shovel attachment...")

        -- Remove any existing tools from character
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                item:Destroy()
            end
        end

        -- Clear any leftover visual attachment
        local existingAttachment = character:FindFirstChild("EquippedTool")
        if existingAttachment then
            existingAttachment:Destroy()
        end

        -- Create a custom shovel model instead of using external model
        local shovelModel = createCustomShovelModel()

        -- Create a visual attachment for the shovel
        local attachment = Instance.new("Model")
        attachment.Name = "EquippedTool"

        -- Use our custom shovel model
        shovelModel.Name = "Shovel"
        disableShovelCollision(shovelModel)
        shovelModel.Parent = attachment

        -- Position the shovel relative to the character hand
        local attachPart = getRightHandPart(character)
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local primaryPart = shovelModel.PrimaryPart or shovelModel:FindFirstChildWhichIsA("BasePart")
        
        if attachPart and primaryPart then
            shovelModel.PrimaryPart = primaryPart

            -- Position shovel in hand - angled down and forward
            local offset = CFrame.new(0, -0.4, 0.3) * CFrame.Angles(math.rad(-45), 0, math.rad(10))
            shovelModel:PivotTo(attachPart.CFrame * offset)

            -- Weld shovel to hand
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = attachPart
            weld.Part1 = primaryPart
            weld.Parent = primaryPart
        else
            -- Fallback: attach to root part if hand not found
            if humanoidRootPart and primaryPart then
                shovelModel.PrimaryPart = primaryPart
                local offset = CFrame.new(0.5, -0.5, 0.5) * CFrame.Angles(math.rad(-45), 0, math.rad(45))
                shovelModel:PivotTo(humanoidRootPart.CFrame * offset)

                local weld = Instance.new("WeldConstraint")
                weld.Part0 = humanoidRootPart
                weld.Part1 = primaryPart
                weld.Parent = primaryPart
            end
        end

        attachment.Parent = character

        -- Create a simple tool object just for tracking (don't interfere with movement)
        local dummyTool = Instance.new("Tool")
        dummyTool.Name = spriteId
        dummyTool.CanBeDropped = false
        dummyTool.RequiresHandle = false -- No handle needed
        dummyTool.ManualActivationOnly = true

        -- Create an invisible handle for tool system compatibility
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.01, 0.01, 0.01)
        handle.Transparency = 1
        handle.CanCollide = false
        handle.Anchored = true
        handle.Massless = true
        handle.Parent = dummyTool

        dummyTool.Parent = character

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Sit = false
            humanoid.PlatformStand = false
        end
        
        -- Set player attribute so ShovelClient can detect it
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            player:SetAttribute("EquippedToolType", "shovel")
        end

        -- Clean up attachment when tool is unequipped
        dummyTool.AncestryChanged:Connect(function(_, newParent)
            if newParent ~= character then
                if attachment and attachment.Parent then
                    attachment:Destroy()
                end
                -- Clear player attribute
                local player = Players:GetPlayerFromCharacter(character)
                if player then
                    player:SetAttribute("EquippedToolType", nil)
                end
            end
        end)

        print("[ToolObjects] ✅ Custom shovel attachment created")
        return dummyTool
    end

    -- Convert to tool if needed (for other tools)
    if not toolModel:IsA("Tool") then
        print("[ToolObjects] Converting model to tool...")
        local tool = Instance.new("Tool")
        tool.Name = spriteId
        tool.CanBeDropped = false
        tool.RequiresHandle = true

        -- Handle slingshots specially to prevent sitting bug
        if spriteId:find("slingshot") then
            print("[ToolObjects] Setting up slingshot...")
            tool.ManualActivationOnly = false -- Allow left-click activation
            tool.RequiresHandle = false -- Ranged weapon doesn't need handle grip

            configureSlingshotParts(tool, toolModel)
            toolModel = tool

            -- Set attributes
            tool:SetAttribute("ToolType", "slingshot")

            print("[ToolObjects] ✅ Slingshot configured!")

        -- Handle fishing rod specially - SKIP creating Tool to avoid physics glitches
        elseif spriteId:find("fishing") or spriteId:find("rod") then
            print("[ToolObjects] Fishing rod equipped (no Tool object - handled by FishingController)")

            -- DON'T create a Tool object - it causes physics glitches
            -- The FishingController will handle everything based on the EquippedToolType attribute

            -- Just return nil - the player attribute is already set
            return nil
        else
            -- For non-fishing rod tools, ensure we have a Handle part
            local handle = toolModel:FindFirstChildWhichIsA("BasePart")
            if handle then
                handle.Name = "Handle"
                handle.Parent = tool

                -- Set proper grip for spherical hands (compensate for larger hand radius ~0.6 studs)
                -- Position tool to avoid collision with spherical hands and prevent character from laying down
                if spriteId:find("shovel") or spriteId:find("axe") then
                    -- Shovels and axes share the same grip to avoid physics glitches
                    tool.Grip = CFrame.new(0, -0.8, 0.2) * CFrame.Angles(math.rad(-90), 0, 0)
                    tool.ManualActivationOnly = false -- Allow left-click activation
                    tool.CanBeDropped = false -- Prevent accidental dropping
                elseif spriteId:find("net") then
                    tool.Grip = CFrame.new(0, -0.7, 0) * CFrame.Angles(0, 0, 0)
                    tool.ManualActivationOnly = false -- Allow left-click activation
                    tool.CanBeDropped = false
                else
                    -- Default grip for unknown tools - position away from spherical hand center
                    tool.Grip = CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                    tool.ManualActivationOnly = false -- Allow left-click activation
                    tool.CanBeDropped = false
                end
            end
        end

        toolModel = tool
    end

    -- Remove any existing tools from character
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            item:Destroy()
        end
    end

    -- Properly equip tool using Humanoid
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        print("[ToolObjects] 🎒 Equipping tool via Humanoid...")

        -- Prevent sitting when tool is equipped
        humanoid.Sit = false
        humanoid.PlatformStand = false

        toolModel.Parent = humanoid.Parent -- Parent to character first
        humanoid:EquipTool(toolModel) -- Then equip it

        -- Set EquippedToolType attribute for the player
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            local toolType = nil
            if spriteId:find("axe") then
                toolType = "axe"
            elseif spriteId:find("shovel") then
                toolType = "shovel"
            elseif spriteId:find("net") then
                toolType = "net"
            elseif spriteId:find("watering") then
                toolType = "watering_can"
            elseif spriteId:find("fishing") or spriteId:find("rod") then
                toolType = "fishing_rod"
            elseif spriteId:find("slingshot") then
                toolType = "slingshot"
            end

            if toolType then
                player:SetAttribute("EquippedToolType", toolType)
                print(string.format("[ToolObjects] ✅ Set EquippedToolType to '%s' for player %s", toolType, player.Name))
            end
        end

        -- Monitor and prevent sitting while tool is equipped
        local sitConnection = nil
        sitConnection = humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
            if humanoid.Sit and toolModel.Parent == character then
                humanoid.Sit = false
                print("[ToolObjects] ⚠️ Prevented character from sitting while tool is equipped")
            end
        end)

        -- Clean up connection when tool is unequipped
        toolModel.AncestryChanged:Connect(function()
            if toolModel.Parent ~= character and sitConnection then
                sitConnection:Disconnect()
                sitConnection = nil

                -- Clear EquippedToolType attribute when tool is unequipped
                local player = Players:GetPlayerFromCharacter(character)
                if player then
                    player:SetAttribute("EquippedToolType", nil)
                    print(string.format("[ToolObjects] ✅ Cleared EquippedToolType for player %s", player.Name))
                end
            end
        end)
    else
        warn("[ToolObjects] ⚠️ No Humanoid found, cannot equip tool!")
        return nil
    end

    print("[ToolObjects] ✅ Tool equipped successfully:", spriteId)
    return toolModel
end

-- Check if position is in water (terrain check)
local function isInWater(position: Vector3): boolean
    local Workspace = game:GetService("Workspace")
    local region = Region3.new(position - Vector3.new(2, 2, 2), position + Vector3.new(2, 2, 2))
    local terrain = Workspace.Terrain

    local materials, _sizes = terrain:ReadVoxels(region, 4)
    local size = materials.Size

    for x = 1, size.X do
        for y = 1, size.Y do
            for z = 1, size.Z do
                if materials[x][y][z] == Enum.Material.Water then
                    return true
                end
            end
        end
    end

    return false
end

-- Cast fishing rod float into water
function ToolObjects.castFishingRod(tool: Tool, character: Model, power: number?)
    if not tool:GetAttribute("HasFloat") then
        warn("[ToolObjects] ⚠️ Tool is not a fishing rod!")
        return false, nil
    end

    if tool:GetAttribute("IsCasted") then
        print("[ToolObjects] Reeling in...")

        -- Get references needed for reeling
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local handle = tool:FindFirstChild("Handle")

        -- Get the float and reel it back
        local floatValue = tool:FindFirstChild("FloatValue")
        if floatValue and floatValue.Value and humanoidRootPart and handle then
            local float = floatValue.Value
            if float and float.Parent then
                -- Remove physics constraints
                for _, child in ipairs(float:GetChildren()) do
                    if child:IsA("BodyMover") or child:IsA("Constraint") then
                        child:Destroy()
                    end
                end

                -- Tween back to player
                local endPos = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 3
                local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                local tween = game:GetService("TweenService"):Create(float, tweenInfo, { Position = endPos })
                tween:Play()

                task.delay(0.3, function()
                    if float and float.Parent then
                        float.CanCollide = false
                        float.Anchored = true
                        float.Position = handle.Position
                    end
                end)
            end
            floatValue.Value = nil
        end

        tool:SetAttribute("IsCasted", false)
        return true, nil
    end

    local float = tool:FindFirstChild("Float")
    local handle = tool:FindFirstChild("Handle")
    if not float or not handle then
        warn("[ToolObjects] ⚠️ Missing float or handle!")
        return false, nil
    end

    print("[ToolObjects] 🎣 Casting fishing rod...")

    -- Get casting direction (where player is looking)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return false, nil
    end

    local castPower = power or 70 -- Reduced power for shorter range
    local castDirection = humanoidRootPart.CFrame.LookVector

    -- Calculate landing position with moderate range
    local landingPosition = handle.Position + castDirection * 35 + Vector3.new(0, -5, 0) -- 35 studs forward

    -- CHECK FOR WATER FIRST
    if not isInWater(landingPosition) then
        warn("[ToolObjects] ⚠️ No water detected at landing position!")
        return false, "No water detected! Cast towards water."
    end

    -- Disable the fishing line rope constraint during cast to prevent player from being pulled
    local fishingLine = tool:FindFirstChild("FishingLine", true)
    if fishingLine and fishingLine:IsA("RopeConstraint") then
        fishingLine.Enabled = false
    end

    -- Detach float for casting
    float.Anchored = false
    float.CanCollide = true
    float.Massless = true -- Make it massless so it doesn't pull the player
    float.Position = handle.Position + castDirection * 5 -- Start closer

    -- Prevent player collision
    local noCollision = Instance.new("NoCollisionConstraint")
    noCollision.Part0 = float
    noCollision.Part1 = humanoidRootPart
    noCollision.Parent = float

    -- Apply throwing force with moderate power
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(8000, 8000, 8000)
    bodyVelocity.Velocity = castDirection * castPower + Vector3.new(0, 25, 0)
    bodyVelocity.Parent = float

    -- Add drag for realistic physics
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.MaxForce = Vector3.new(0, 0, 0)
    bodyPosition.Parent = float

    task.delay(0.5, function()
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity:Destroy()
        end
        -- Enable water settling physics
        if bodyPosition and bodyPosition.Parent then
            bodyPosition.MaxForce = Vector3.new(0, 2000, 0)
            bodyPosition.Position = float.Position
        end

        -- Re-enable fishing line rope constraint after cast
        if fishingLine and fishingLine:IsA("RopeConstraint") then
            fishingLine.Enabled = true
        end
    end)

    tool:SetAttribute("IsCasted", true)
    tool:SetAttribute("BobberPosition", landingPosition)

    -- Store float reference for reeling
    local floatValue = tool:FindFirstChild("FloatValue")
    if not floatValue then
        floatValue = Instance.new("ObjectValue")
        floatValue.Name = "FloatValue"
        floatValue.Parent = tool
    end
    floatValue.Value = float

    -- Water touch detection
    local touchConnection
    touchConnection = float.Touched:Connect(function(hit)
        if hit:IsA("Terrain") or (hit:IsA("BasePart") and hit.Material == Enum.Material.Water) then
            print("[ToolObjects] 💧 Float hit water!")
            float.AssemblyLinearVelocity = Vector3.new(0, -2, 0)

            if touchConnection then
                touchConnection:Disconnect()
            end
        end
    end)

    print("[ToolObjects] ✅ Cast complete!")
    return true, landingPosition
end

-- Shoot slingshot projectile
function ToolObjects.shootSlingshot(tool: Tool, character: Model, targetPosition: Vector3)
    local toolType = tool:GetAttribute("ToolType")
    if not toolType or not string.find(string.lower(tostring(toolType)), "slingshot") then
        warn("[ToolObjects] ⚠️ Tool is not a slingshot!")
        return false, nil
    end

    local handle = tool:FindFirstChild("Handle", true)
    local slinger = tool:FindFirstChild("Slinger", true)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not handle or not humanoidRootPart or not humanoid then
        return false, "Missing handle or character"
    end

    -- Use Slinger if available, otherwise use Handle
    local shootPoint = slinger or handle

    print("[ToolObjects] 🎯 Shooting slingshot from", shootPoint.Name)

    -- Create projectile (bigger ball for easier aiming)
    local projectile = Instance.new("Part")
    projectile.Name = "SlingshotProjectile"
    projectile.Size = Vector3.new(1.5, 1.5, 1.5) -- Bigger projectile for visibility
    projectile.Shape = Enum.PartType.Ball
    projectile.Material = Enum.Material.Plastic
    projectile.BrickColor = BrickColor.new("Dark stone grey")
    projectile.CanCollide = true
    projectile.Massless = false
    projectile.Position = shootPoint.Position + humanoidRootPart.CFrame.LookVector * 3
    projectile.TopSurface = Enum.SurfaceType.Smooth
    projectile.BottomSurface = Enum.SurfaceType.Smooth

    -- Add a trail
    local trail = Instance.new("Trail")
    trail.Attachment0 = Instance.new("Attachment", projectile)
    trail.Attachment1 = Instance.new("Attachment", projectile)
    trail.Attachment0.Position = Vector3.new(0, 0.2, 0)
    trail.Attachment1.Position = Vector3.new(0, -0.2, 0)
    trail.Lifetime = 0.2
    trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.Parent = projectile

    -- Set collision group to prevent hitting player
    pcall(function()
        if not pcall(function()
            PhysicsService:GetCollisionGroupId("Projectiles")
        end) then
            PhysicsService:CreateCollisionGroup("Projectiles")
        end
        if not pcall(function()
            PhysicsService:GetCollisionGroupId("Players")
        end) then
            PhysicsService:CreateCollisionGroup("Players")
        end
        PhysicsService:CollisionGroupSetCollidable("Projectiles", "Players", false)
        projectile.CollisionGroup = "Projectiles"
    end)

    -- Make sure player can't collide with it
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local noCollision = Instance.new("NoCollisionConstraint")
            noCollision.Part0 = projectile
            noCollision.Part1 = part
            noCollision.Parent = projectile
        end
    end

    projectile.Parent = workspace

    -- Calculate direction to target
    local shootDirection = (targetPosition - projectile.Position).Unit

    -- Add velocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    bodyVelocity.Velocity = shootDirection * 150 -- Faster projectile speed
    bodyVelocity.Parent = projectile

    -- Add slight gravity effect after 0.3 seconds
    task.delay(0.3, function()
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity.Velocity = bodyVelocity.Velocity + Vector3.new(0, -20, 0)
        end
    end)

    -- Track if projectile hit something
    local hasHit = false

    -- Destroy projectile after 5 seconds
    local destroyDebounce = false
    task.delay(5, function()
        if projectile and projectile.Parent and not destroyDebounce then
            destroyDebounce = true
            projectile:Destroy()
        end
    end)

    -- Destroy on impact with non-character parts
    projectile.Touched:Connect(function(hit)
        if hasHit or destroyDebounce then
            return
        end
        if hit:IsDescendantOf(character) then
            return
        end
        if hit.Name == "SlingshotProjectile" then
            return
        end

        hasHit = true
        print("[ToolObjects] 🎯 Projectile hit:", hit.Name, hit:GetFullName())

        -- Check if this is a balloon - search up the hierarchy
        local balloon = nil
        local current = hit
        while current and current.Parent do
            if current.Name:match("Balloon_%d+") then
                balloon = current
                break
            end
            current = current.Parent
        end

        if balloon then
            print("[ToolObjects] 🎈 Found balloon:", balloon.Name)
            -- Tell the server about the balloon hit
            local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
            if remoteEvents then
                local balloonHitRemote = remoteEvents:FindFirstChild("BalloonHit")
                if balloonHitRemote then
                    balloonHitRemote:FireServer(balloon.Name)
                    print("[ToolObjects] 🎈 Sent balloon hit event for:", balloon.Name)
                else
                    warn("[ToolObjects] ⚠️ BalloonHit RemoteEvent not found!")
                end
            else
                warn("[ToolObjects] ⚠️ RemoteEvents folder not found!")
            end
        end

        task.wait(0.05) -- Small delay to ensure hit is registered
        if projectile and projectile.Parent and not destroyDebounce then
            destroyDebounce = true
            projectile:Destroy()
        end
    end)

    animateSlingshotRelease(tool)

    print("[ToolObjects] ✅ Projectile fired!")
    return true, projectile
end

return ToolObjects
