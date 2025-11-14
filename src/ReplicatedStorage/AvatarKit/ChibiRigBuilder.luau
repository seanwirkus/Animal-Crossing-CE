--[[
    ChibiRigBuilder

    Builds a stylized chibi avatar rig that matches the Animal Crossing inspired
    aesthetic. The helper exposes a single function, `ensureRig`, which creates
    the rig model under ReplicatedStorage/AvatarKit (or reuses the existing
    template).

    The resulting rig keeps rounded limbs, rounded rectangular hands, and a
    large head while leaning into a slender, blocky silhouette inspired by the
    "block guy" aesthetic, balancing cute accents with a refined angular shape.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChibiRigBuilder = {}

local PHYSICS_PROPERTIES = PhysicalProperties.new(0.9, 0.35, 0.5, 0, 0)

local function applyPhysicalProperties(part: BasePart?)
    if part then
        part.CustomPhysicalProperties = PHYSICS_PROPERTIES
    end
end

local SKIN_COLOR = Color3.fromRGB(255, 228, 200)
local SHIRT_COLOR = Color3.fromRGB(255, 242, 214)
local PANTS_COLOR = Color3.fromRGB(92, 159, 115)
local SHOE_COLOR = Color3.fromRGB(84, 67, 47)
local BLUSH_COLOR = Color3.fromRGB(255, 179, 186)

local function getAvatarKitFolder()
    local folder = ReplicatedStorage:FindFirstChild("AvatarKit")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "AvatarKit"
        folder.Parent = ReplicatedStorage
    end
    return folder
end

local function createBasePart(name: string, size: Vector3, position: Vector3, color: Color3?, shape: Enum.PartType?)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = CFrame.new(position)
    part.Anchored = false
    part.CanCollide = false
    part.Massless = true
    part.CastShadow = false
    part.Color = color or SKIN_COLOR
    part.Material = Enum.Material.SmoothPlastic
    applyPhysicalProperties(part)
    if shape then
        part.Shape = shape
    end
    return part
end

local function addSpecialMesh(part: BasePart, meshType: Enum.MeshType, scale: Vector3)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = meshType
    mesh.Scale = scale
    mesh.Parent = part
    return mesh
end

local function createSpherePart(name: string, diameter: number, position: Vector3, color: Color3?, scale: Vector3?)
    local part = createBasePart(name, Vector3.new(diameter, diameter, diameter), position, color, Enum.PartType.Ball)
    addSpecialMesh(part, Enum.MeshType.Sphere, scale or Vector3.new(1, 1, 1))
    return part
end

local function addBlush(head: BasePart)
    for index, offset in ipairs({ Vector3.new(-0.45, -0.15, -0.68), Vector3.new(0.45, -0.15, -0.68) }) do
        local blush =
            createSpherePart("Blush" .. index, 0.3, head.Position + offset, BLUSH_COLOR, Vector3.new(1, 0.6, 1))
        blush.Transparency = 0.15
        blush.Parent = head
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = head
        weld.Part1 = blush
        weld.Parent = head
    end
end

function ChibiRigBuilder.createRig()
    local rig = Instance.new("Model")
    rig.Name = "ChibiRig"

    local humanoidRootPart =
        createBasePart("HumanoidRootPart", Vector3.new(1.6, 1.2, 1.2), Vector3.new(0, 2.7, 0), SKIN_COLOR)
    humanoidRootPart.Transparency = 1
    humanoidRootPart.Massless = false
    humanoidRootPart.Parent = rig
    rig.PrimaryPart = humanoidRootPart

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.RigType = Enum.HumanoidRigType.R15
    humanoid.Parent = rig

    local animator = Instance.new("Animator")
    animator.Parent = humanoid

    local head = createBasePart("Head", Vector3.new(1.4, 1.8, 1.2), Vector3.new(0, 4.6, 0), SKIN_COLOR)
    addSpecialMesh(head, Enum.MeshType.Head, Vector3.new(1.1, 1.2, 1.05))
    head.Parent = rig

    local face = Instance.new("Decal")
    face.Name = "face"
    face.Face = Enum.NormalId.Front
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head

    -- Make torso more rounded and chibi-like
    local torso = createBasePart("UpperTorso", Vector3.new(1.2, 1.3, 0.9), Vector3.new(0, 3.3, 0), SHIRT_COLOR)
    addSpecialMesh(torso, Enum.MeshType.Head, Vector3.new(1.15, 0.9, 0.95))
    torso.Parent = rig

    local lowerTorso = createBasePart("LowerTorso", Vector3.new(1.1, 1.0, 0.85), Vector3.new(0, 2.3, 0), PANTS_COLOR)
    addSpecialMesh(lowerTorso, Enum.MeshType.Head, Vector3.new(1.1, 0.85, 0.9))
    lowerTorso.Parent = rig

    -- Make arms rounded rectangular like Wii characters (LONGER)
    local leftArm = createBasePart("LeftUpperArm", Vector3.new(0.45, 1.55, 0.45), Vector3.new(-0.9, 3.4, 0), SKIN_COLOR)
    addSpecialMesh(leftArm, Enum.MeshType.Head, Vector3.new(1.05, 0.9, 1.05))
    leftArm.Parent = rig
    local rightArm =
        createBasePart("RightUpperArm", Vector3.new(0.45, 1.55, 0.45), Vector3.new(0.9, 3.4, 0), SKIN_COLOR)
    addSpecialMesh(rightArm, Enum.MeshType.Head, Vector3.new(1.05, 0.9, 1.05))
    rightArm.Parent = rig

    local leftForearm =
        createBasePart("LeftLowerArm", Vector3.new(0.44, 1.3, 0.44), Vector3.new(-0.9, 2.25, 0), SKIN_COLOR)
    addSpecialMesh(leftForearm, Enum.MeshType.Head, Vector3.new(1.05, 0.9, 1.05))
    leftForearm.Parent = rig
    local rightForearm =
        createBasePart("RightLowerArm", Vector3.new(0.44, 1.3, 0.44), Vector3.new(0.9, 2.25, 0), SKIN_COLOR)
    addSpecialMesh(rightForearm, Enum.MeshType.Head, Vector3.new(1.05, 0.9, 1.05))
    rightForearm.Parent = rig

    -- Make hands bigger and rounded rectangular (Wii-style)
    local leftHand = createBasePart("LeftHand", Vector3.new(0.45, 0.45, 0.45), Vector3.new(-0.9, 1.9, 0), SKIN_COLOR)
    addSpecialMesh(leftHand, Enum.MeshType.Head, Vector3.new(1.0, 0.85, 1.0))
    leftHand.Parent = rig
    local rightHand = createBasePart("RightHand", Vector3.new(0.45, 0.45, 0.45), Vector3.new(0.9, 1.9, 0), SKIN_COLOR)
    addSpecialMesh(rightHand, Enum.MeshType.Head, Vector3.new(1.0, 0.85, 1.0))
    rightHand.Parent = rig

    -- Make legs rounded with sphere meshes (LONGER)
    local leftLeg =
        createBasePart("LeftUpperLeg", Vector3.new(0.45, 1.45, 0.45), Vector3.new(-0.35, 1.6, 0), PANTS_COLOR)
    addSpecialMesh(leftLeg, Enum.MeshType.Head, Vector3.new(0.95, 1.15, 0.95))
    leftLeg.Parent = rig
    local rightLeg =
        createBasePart("RightUpperLeg", Vector3.new(0.45, 1.45, 0.45), Vector3.new(0.35, 1.6, 0), PANTS_COLOR)
    addSpecialMesh(rightLeg, Enum.MeshType.Head, Vector3.new(0.95, 1.15, 0.95))
    rightLeg.Parent = rig

    local leftShin =
        createBasePart("LeftLowerLeg", Vector3.new(0.43, 1.2, 0.43), Vector3.new(-0.35, 0.75, 0), PANTS_COLOR)
    addSpecialMesh(leftShin, Enum.MeshType.Head, Vector3.new(0.95, 1.05, 0.95))
    leftShin.Parent = rig
    local rightShin =
        createBasePart("RightLowerLeg", Vector3.new(0.43, 1.2, 0.43), Vector3.new(0.35, 0.75, 0), PANTS_COLOR)
    addSpecialMesh(rightShin, Enum.MeshType.Head, Vector3.new(0.95, 1.05, 0.95))
    rightShin.Parent = rig

    local leftFoot = createBasePart("LeftFoot", Vector3.new(0.5, 0.3, 0.8), Vector3.new(-0.35, 0.1, 0.15), SHOE_COLOR)
    addSpecialMesh(leftFoot, Enum.MeshType.Head, Vector3.new(0.9, 0.5, 1.2))
    leftFoot.Parent = rig

    local rightFoot = createBasePart("RightFoot", Vector3.new(0.5, 0.3, 0.8), Vector3.new(0.35, 0.1, 0.15), SHOE_COLOR)
    addSpecialMesh(rightFoot, Enum.MeshType.Head, Vector3.new(0.9, 0.5, 1.2))
    rightFoot.Parent = rig

    addBlush(head)

    local bodyColors = Instance.new("BodyColors")
    bodyColors.HeadColor3 = SKIN_COLOR
    bodyColors.LeftArmColor3 = SKIN_COLOR
    bodyColors.RightArmColor3 = SKIN_COLOR
    bodyColors.TorsoColor3 = SHIRT_COLOR
    bodyColors.LeftLegColor3 = PANTS_COLOR
    bodyColors.RightLegColor3 = PANTS_COLOR
    bodyColors.Parent = rig

    -- Use Motor6D joints instead of WeldConstraints for proper R15 rigging
    -- This allows tools to work correctly and prevents character from laying down
    local function createMotor6D(name: string, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame)
        local motor = Instance.new("Motor6D")
        motor.Name = name
        motor.Part0 = part0
        motor.Part1 = part1
        motor.C0 = c0
        motor.C1 = c1
        motor.Parent = part0
        return motor
    end

    -- Root joints
    createMotor6D("RootJoint", humanoidRootPart, torso, CFrame.new(0, 0, 0), CFrame.new(0, 0, 0))
    createMotor6D("Waist", torso, lowerTorso, CFrame.new(0, -0.7, 0), CFrame.new(0, 0.5, 0))

    -- Head/Neck
    createMotor6D("Neck", torso, head, CFrame.new(0, 0.7, 0), CFrame.new(0, -0.9, 0))

    -- Arms
    createMotor6D("LeftShoulder", torso, leftArm, CFrame.new(-0.8, 0.5, 0), CFrame.new(0, 0.575, 0))
    createMotor6D("RightShoulder", torso, rightArm, CFrame.new(0.8, 0.5, 0), CFrame.new(0, 0.575, 0))
    createMotor6D("LeftElbow", leftArm, leftForearm, CFrame.new(0, -0.575, 0), CFrame.new(0, 0.5, 0))
    createMotor6D("RightElbow", rightArm, rightForearm, CFrame.new(0, -0.575, 0), CFrame.new(0, 0.5, 0))
    createMotor6D("LeftWrist", leftForearm, leftHand, CFrame.new(0, -0.5, 0), CFrame.new(0, 0, 0))
    createMotor6D("RightWrist", rightForearm, rightHand, CFrame.new(0, -0.5, 0), CFrame.new(0, 0, 0))

    -- Legs
    createMotor6D("LeftHip", lowerTorso, leftLeg, CFrame.new(-0.45, -0.55, 0), CFrame.new(0, 0.525, 0))
    createMotor6D("RightHip", lowerTorso, rightLeg, CFrame.new(0.45, -0.55, 0), CFrame.new(0, 0.525, 0))
    createMotor6D("LeftKnee", leftLeg, leftShin, CFrame.new(0, -0.525, 0), CFrame.new(0, 0.475, 0))
    createMotor6D("RightKnee", rightLeg, rightShin, CFrame.new(0, -0.525, 0), CFrame.new(0, 0.475, 0))
    createMotor6D("LeftAnkle", leftShin, leftFoot, CFrame.new(0, -0.475, 0), CFrame.new(0, 0.175, -0.15))
    createMotor6D("RightAnkle", rightShin, rightFoot, CFrame.new(0, -0.475, 0), CFrame.new(0, 0.175, -0.15))

    return rig
end

function ChibiRigBuilder.ensureRig()
    local folder = getAvatarKitFolder()
    local existing = folder:FindFirstChild("ChibiRig")
    if existing then
        return existing
    end

    local rig = ChibiRigBuilder.createRig()
    rig.Parent = folder
    return rig
end

return ChibiRigBuilder
