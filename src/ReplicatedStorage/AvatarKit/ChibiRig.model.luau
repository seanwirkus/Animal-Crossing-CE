--[[
    ChibiRig.model.luau

    Ensures a single copy of the chibi rig template exists inside
    ReplicatedStorage/AvatarKit. The rig construction is handled by
    ChibiRigBuilder so it can be reused by both the client preview and server
    character replacement systems.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local avatarKitFolder = ReplicatedStorage:FindFirstChild("AvatarKit")
if not avatarKitFolder then
    avatarKitFolder = Instance.new("Folder")
    avatarKitFolder.Name = "AvatarKit"
    avatarKitFolder.Parent = ReplicatedStorage
end

local ChibiRigBuilder = require(avatarKitFolder:WaitForChild("ChibiRigBuilder"))

local rig = ChibiRigBuilder.ensureRig()

print("[ChibiRig] ✅ ChibiRig model ready in ReplicatedStorage")

return rig
