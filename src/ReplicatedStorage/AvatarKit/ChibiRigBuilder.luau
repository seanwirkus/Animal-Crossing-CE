--[[
    ChibiRigBuilder

    Builds a stylized chibi avatar rig that matches the Animal Crossing inspired
    aesthetic. The helper exposes a single function, `ensureRig`, which creates
    the rig model under ReplicatedStorage/AvatarKit (or reuses the existing
    template).

    The resulting rig features rounded limbs, spherical hands, a large head and
    other cute accents so that player characters no longer appear as blocky
    rectangles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChibiRigBuilder = {}

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

local function createCylinderLimb(name: string, size: Vector3, position: Vector3, color: Color3)
    local part = createBasePart(name, size, position, color, Enum.PartType.Cylinder)
    addSpecialMesh(part, Enum.MeshType.Cylinder, Vector3.new(1, 1.05, 1))
    return part
end

local function addBlush(head: BasePart)
    for index, offset in ipairs({Vector3.new(-0.45, -0.15, -0.68), Vector3.new(0.45, -0.15, -0.68)}) do
        local blush = createSpherePart("Blush" .. index, 0.3, head.Position + offset, BLUSH_COLOR, Vector3.new(1, 0.6, 1))
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

    local humanoidRootPart = createBasePart("HumanoidRootPart", Vector3.new(1.6, 1.2, 1.2), Vector3.new(0, 2.7, 0), SKIN_COLOR)
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

    local head = createSpherePart("Head", 1.8, Vector3.new(0, 4.6, 0), SKIN_COLOR, Vector3.new(1.35, 1.45, 1.35))
    head.Parent = rig

    local face = Instance.new("Decal")
    face.Name = "face"
    face.Face = Enum.NormalId.Front
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head

    local torso = createBasePart("UpperTorso", Vector3.new(1.5, 1.4, 1.2), Vector3.new(0, 3.3, 0), SHIRT_COLOR)
    addSpecialMesh(torso, Enum.MeshType.Sphere, Vector3.new(1.3, 0.9, 1.1))
    torso.Parent = rig

    local lowerTorso = createBasePart("LowerTorso", Vector3.new(1.4, 1.0, 1.1), Vector3.new(0, 2.3, 0), PANTS_COLOR)
    addSpecialMesh(lowerTorso, Enum.MeshType.Sphere, Vector3.new(1.2, 0.85, 1.0))
    lowerTorso.Parent = rig

    local leftArm = createCylinderLimb("LeftUpperArm", Vector3.new(0.6, 1.1, 0.6), Vector3.new(-1.0, 3.5, 0), SKIN_COLOR)
    leftArm.Parent = rig
    local rightArm = createCylinderLimb("RightUpperArm", Vector3.new(0.6, 1.1, 0.6), Vector3.new(1.0, 3.5, 0), SKIN_COLOR)
    rightArm.Parent = rig

    local leftForearm = createCylinderLimb("LeftLowerArm", Vector3.new(0.55, 0.95, 0.55), Vector3.new(-1.0, 2.6, 0), SKIN_COLOR)
    leftForearm.Parent = rig
    local rightForearm = createCylinderLimb("RightLowerArm", Vector3.new(0.55, 0.95, 0.55), Vector3.new(1.0, 2.6, 0), SKIN_COLOR)
    rightForearm.Parent = rig

    local leftHand = createSpherePart("LeftHand", 0.7, Vector3.new(-1.0, 2.0, 0), SKIN_COLOR, Vector3.new(1.2, 1.2, 1.2))
    leftHand.Parent = rig
    local rightHand = createSpherePart("RightHand", 0.7, Vector3.new(1.0, 2.0, 0), SKIN_COLOR, Vector3.new(1.2, 1.2, 1.2))
    rightHand.Parent = rig

    local leftLeg = createCylinderLimb("LeftUpperLeg", Vector3.new(0.65, 1.0, 0.65), Vector3.new(-0.45, 1.4, 0), PANTS_COLOR)
    leftLeg.Parent = rig
    local rightLeg = createCylinderLimb("RightUpperLeg", Vector3.new(0.65, 1.0, 0.65), Vector3.new(0.45, 1.4, 0), PANTS_COLOR)
    rightLeg.Parent = rig

    local leftShin = createCylinderLimb("LeftLowerLeg", Vector3.new(0.6, 0.9, 0.6), Vector3.new(-0.45, 0.6, 0), PANTS_COLOR)
    leftShin.Parent = rig
    local rightShin = createCylinderLimb("RightLowerLeg", Vector3.new(0.6, 0.9, 0.6), Vector3.new(0.45, 0.6, 0), PANTS_COLOR)
    rightShin.Parent = rig

    local leftFoot = createBasePart("LeftFoot", Vector3.new(0.7, 0.35, 0.9), Vector3.new(-0.45, 0.1, 0.15), SHOE_COLOR)
    addSpecialMesh(leftFoot, Enum.MeshType.Head, Vector3.new(1.0, 0.6, 1.4))
    leftFoot.Parent = rig

    local rightFoot = createBasePart("RightFoot", Vector3.new(0.7, 0.35, 0.9), Vector3.new(0.45, 0.1, 0.15), SHOE_COLOR)
    addSpecialMesh(rightFoot, Enum.MeshType.Head, Vector3.new(1.0, 0.6, 1.4))
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

    local weldPairs = {
        { humanoidRootPart, head },
        { humanoidRootPart, torso },
        { humanoidRootPart, lowerTorso },
        { humanoidRootPart, leftArm },
        { humanoidRootPart, rightArm },
        { leftArm, leftForearm },
        { rightArm, rightForearm },
        { leftForearm, leftHand },
        { rightForearm, rightHand },
        { humanoidRootPart, leftLeg },
        { humanoidRootPart, rightLeg },
        { leftLeg, leftShin },
        { rightLeg, rightShin },
        { leftShin, leftFoot },
        { rightShin, rightFoot },
    }

    for _, pair in ipairs(weldPairs) do
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = pair[1]
        weld.Part1 = pair[2]
        weld.Parent = pair[1]
    end

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
