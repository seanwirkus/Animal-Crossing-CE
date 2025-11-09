--[[
    ChibiRig.model.luau

    Provides a light-weight chibi rig that can be reused by avatar preview
    UIs. The model is intentionally simple: a humanoid with exaggerated head
    size and rounded limbs, styled after Animal Crossing villagers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarKitFolder = ReplicatedStorage:FindFirstChild("AvatarKit")
if not AvatarKitFolder then
    AvatarKitFolder = Instance.new("Folder")
    AvatarKitFolder.Name = "AvatarKit"
    AvatarKitFolder.Parent = ReplicatedStorage
end

local function createPart(name, size, position, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Color = color or Color3.fromRGB(255, 228, 200)
    part.Material = Enum.Material.SmoothPlastic
    return part
end

local function createSphereMesh(scale)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = scale
    return mesh
end

local existing = AvatarKitFolder:FindFirstChild("ChibiRig")
if existing then
    return existing
end

local rig = Instance.new("Model")
rig.Name = "ChibiRig"

local humanoidRootPart = createPart("HumanoidRootPart", Vector3.new(2, 1, 1), Vector3.new(0, 2.5, 0))
humanoidRootPart.Transparency = 1
humanoidRootPart.Parent = rig

rig.PrimaryPart = humanoidRootPart

local humanoid = Instance.new("Humanoid")
humanoid.Name = "Humanoid"
humanoid.Parent = rig

local head = createPart("Head", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 4.3, 0))
local headMesh = createSphereMesh(Vector3.new(1.25, 1.3, 1.25))
headMesh.Parent = head
head.Parent = rig

local torso = createPart("UpperTorso", Vector3.new(1.8, 1.6, 1.4), Vector3.new(0, 3, 0))
torso.Parent = rig

local lowerTorso = createPart("LowerTorso", Vector3.new(1.7, 1.2, 1.4), Vector3.new(0, 1.8, 0))
lowerTorso.Parent = rig

local leftArm = createPart("LeftUpperArm", Vector3.new(0.55, 1.2, 0.55), Vector3.new(-1.2, 3.2, 0))
leftArm.Parent = rig
local rightArm = createPart("RightUpperArm", Vector3.new(0.55, 1.2, 0.55), Vector3.new(1.2, 3.2, 0))
rightArm.Parent = rig

local leftLeg = createPart("LeftUpperLeg", Vector3.new(0.6, 1.3, 0.6), Vector3.new(-0.5, 0.6, 0))
leftLeg.Color = Color3.fromRGB(92, 159, 115)
leftLeg.Parent = rig
local rightLeg = createPart("RightUpperLeg", Vector3.new(0.6, 1.3, 0.6), Vector3.new(0.5, 0.6, 0))
rightLeg.Color = Color3.fromRGB(92, 159, 115)
rightLeg.Parent = rig

local bodyColors = Instance.new("BodyColors")
bodyColors.HeadColor3 = Color3.fromRGB(255, 228, 200)
bodyColors.LeftArmColor3 = Color3.fromRGB(255, 228, 200)
bodyColors.RightArmColor3 = Color3.fromRGB(255, 228, 200)
bodyColors.TorsoColor3 = Color3.fromRGB(255, 228, 200)
bodyColors.LeftLegColor3 = Color3.fromRGB(92, 159, 115)
bodyColors.RightLegColor3 = Color3.fromRGB(92, 159, 115)
bodyColors.Parent = rig

local welds = {
    { humanoidRootPart, head },
    { humanoidRootPart, torso },
    { humanoidRootPart, lowerTorso },
    { humanoidRootPart, leftArm },
    { humanoidRootPart, rightArm },
    { humanoidRootPart, leftLeg },
    { humanoidRootPart, rightLeg },
}

for _, pair in ipairs(welds) do
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = pair[1]
    weld.Part1 = pair[2]
    weld.Parent = pair[1]
end

rig.Parent = AvatarKitFolder

return rig

