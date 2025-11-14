--[[
	ChibiRigBuilder.luau

	Creates and manages ChibiRig templates for character replacement
	Provides a standardized chibi character model with proper proportions
]]

local ChibiRigBuilder = {}

-- Cache the rig template to avoid recreating it
local chibiRigTemplate = nil

-- Create a basic chibi rig template
local function createChibiRigTemplate()
    local rig = Instance.new("Model")
    rig.Name = "ChibiRigTemplate"

    -- Create HumanoidRootPart (the main body part)
    local humanoidRootPart = Instance.new("Part")
    humanoidRootPart.Name = "HumanoidRootPart"
    humanoidRootPart.Size = Vector3.new(2, 1, 1)
    humanoidRootPart.Anchored = false
    humanoidRootPart.CanCollide = true
    humanoidRootPart.Parent = rig

    -- Create Head (spherical for chibi style)
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.4, 1.4, 1.4) -- Slightly larger for chibi proportions
    head.Anchored = false
    head.CanCollide = false
    head.Parent = rig

    -- Add sphere mesh to head
    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType = Enum.MeshType.Sphere
    headMesh.Scale = Vector3.new(1, 1, 1)
    headMesh.Parent = head

    -- Create Torso
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(1.6, 2.2, 0.8) -- Wider and shorter for chibi
    torso.Anchored = false
    torso.CanCollide = false
    torso.Parent = rig

    -- Create Left Arm
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(0.8, 1.8, 0.8) -- Shorter arms
    leftArm.Anchored = false
    leftArm.CanCollide = false
    leftArm.Parent = rig

    -- Create Right Arm
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(0.8, 1.8, 0.8)
    rightArm.Anchored = false
    rightArm.CanCollide = false
    rightArm.Parent = rig

    -- Create Left Leg
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(0.9, 1.6, 0.9) -- Shorter legs
    leftLeg.Anchored = false
    leftLeg.CanCollide = false
    leftLeg.Parent = rig

    -- Create Right Leg
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(0.9, 1.6, 0.9)
    rightLeg.Anchored = false
    rightLeg.CanCollide = false
    rightLeg.Parent = rig

    -- Create Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = rig

    -- Set up motor joints (simplified rig)
    local rootJoint = Instance.new("Motor6D")
    rootJoint.Name = "RootJoint"
    rootJoint.Part0 = humanoidRootPart
    rootJoint.Part1 = torso
    rootJoint.C0 = CFrame.new(0, 0, 0)
    rootJoint.C1 = CFrame.new(0, 0, 0)
    rootJoint.Parent = humanoidRootPart

    local neck = Instance.new("Motor6D")
    neck.Name = "Neck"
    neck.Part0 = torso
    neck.Part1 = head
    neck.C0 = CFrame.new(0, 1, 0)
    neck.C1 = CFrame.new(0, -0.5, 0)
    neck.Parent = torso

    local leftShoulder = Instance.new("Motor6D")
    leftShoulder.Name = "Left Shoulder"
    leftShoulder.Part0 = torso
    leftShoulder.Part1 = leftArm
    leftShoulder.C0 = CFrame.new(-1, 0.5, 0)
    leftShoulder.C1 = CFrame.new(0, 0.5, 0)
    leftShoulder.Parent = torso

    local rightShoulder = Instance.new("Motor6D")
    rightShoulder.Name = "Right Shoulder"
    rightShoulder.Part0 = torso
    rightShoulder.Part1 = rightArm
    rightShoulder.C0 = CFrame.new(1, 0.5, 0)
    rightShoulder.C1 = CFrame.new(0, 0.5, 0)
    rightShoulder.Parent = torso

    local leftHip = Instance.new("Motor6D")
    leftHip.Name = "Left Hip"
    leftHip.Part0 = humanoidRootPart
    leftHip.Part1 = leftLeg
    leftHip.C0 = CFrame.new(-0.5, -1, 0)
    leftHip.C1 = CFrame.new(0, 0.5, 0)
    leftHip.Parent = humanoidRootPart

    local rightHip = Instance.new("Motor6D")
    rightHip.Name = "Right Hip"
    rightHip.Part0 = humanoidRootPart
    rightHip.Part1 = rightLeg
    rightHip.C0 = CFrame.new(0.5, -1, 0)
    rightHip.C1 = CFrame.new(0, 0.5, 0)
    rightHip.Parent = humanoidRootPart

    -- Set primary part
    rig.PrimaryPart = humanoidRootPart

    return rig
end

-- Ensure the ChibiRig template exists and return it
function ChibiRigBuilder.ensureRig()
    if not chibiRigTemplate then
        chibiRigTemplate = createChibiRigTemplate()
        print("[ChibiRigBuilder] ✅ Created ChibiRig template")
    end
    return chibiRigTemplate
end

return ChibiRigBuilder
