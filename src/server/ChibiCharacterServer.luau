--[[
	ChibiCharacterServer.luau
	
	Server-side character customization for ACNH chibi style
	Applies body proportions that can only be set from the server
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local avatarKitFolder = ReplicatedStorage:FindFirstChild("AvatarKit")
if not avatarKitFolder then
    avatarKitFolder = Instance.new("Folder")
    avatarKitFolder.Name = "AvatarKit"
    avatarKitFolder.Parent = ReplicatedStorage
end

local ChibiRigBuilder = require(ReplicatedStorage:WaitForChild("AvatarKit"):WaitForChild("ChibiRigBuilder"))

local DebugLogger = require(ReplicatedStorage.Shared.DebugLogger)
local MODULE_NAME = "ChibiCharacterServer"

local function logInfo(message, context)
    DebugLogger.info(MODULE_NAME, message, context)
end

local function logWarn(message, context)
    DebugLogger.warn(MODULE_NAME, message, context)
end

local ChibiCharacterServer = {}

local function ensureChibiRigExists()
    return ChibiRigBuilder.ensureRig()
end

-- Track which characters have already been processed to prevent infinite loops
local processedCharacters = {}

-- Track which players are currently having their character replaced
local replacingCharacter = {}

local function replaceWithChibiRig(character, player)
    -- Prevent infinite loop - check if this character is already a ChibiRig or has been processed
    if not character or not character.Parent then
        return
    end

    -- Check if we're already replacing this player's character
    if replacingCharacter[player] then
        return
    end

    -- Check if we've already processed this character instance
    if processedCharacters[character] then
        return
    end

    -- Check if character name indicates it's already a ChibiRig
    if string.find(character.Name, "_Chibi") or character.Name == player.Name .. "_Chibi" then
        processedCharacters[character] = true
        return -- Already a ChibiRig, don't replace again
    end

    -- Check if this character is already the ChibiRig by checking its structure
    -- ChibiRig has specific parts that regular characters don't have
    local head = character:FindFirstChild("Head")

    -- Check if character has ChibiRig-specific structure
    -- ChibiRig has a Head with a SpecialMesh (sphere mesh)
    if head and head:IsA("BasePart") then
        local headMesh = head:FindFirstChildOfClass("SpecialMesh")
        -- ChibiRig has a sphere mesh on the head
        if headMesh and headMesh.MeshType == Enum.MeshType.Sphere then
            processedCharacters[character] = true
            return -- This is already a ChibiRig
        end

        -- If head is unusually large (ChibiRig characteristic after scaling), it's already replaced
        if head.Size.X > 2.0 then -- After 2.5x scaling, ChibiRig head is ~3.5
            processedCharacters[character] = true
            return
        end
    end

    -- Check if character has ChibiRig-specific attributes or structure
    -- ChibiRig models typically have a specific scale or structure
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart and rootPart:IsA("BasePart") then
        -- ChibiRig characters are typically larger due to scaling
        -- If the root part is unusually large, it's likely already a ChibiRig
        -- Normal characters have root part size ~2,1,1 (magnitude ~2.45)
        -- Scaled ChibiRig has root part size ~5,2.5,2.5 (magnitude ~6.12)
        if rootPart.Size.Magnitude > 5 then
            processedCharacters[character] = true
            return
        end
    end

    processedCharacters[character] = true
    replacingCharacter[player] = true

    task.wait(0.2) -- Wait for character to fully load

    -- Ensure the ChibiRig template exists
    local chibiRigTemplate = ensureChibiRigExists()
    if not chibiRigTemplate or not chibiRigTemplate:IsA("Model") then
        logWarn("Failed to get ChibiRig template")
        return
    end

    -- Clone the ChibiRig
    local chibiRig = chibiRigTemplate:Clone()
    chibiRig.Name = player.Name .. "_Chibi"

    -- Mark as processed BEFORE any operations to prevent loop
    processedCharacters[chibiRig] = true

    -- Set up the humanoid
    local humanoid = chibiRig:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        logWarn("No humanoid in ChibiRig")
        return
    end

    -- Set the player as the humanoid's player
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false) -- Prevent sitting

    -- Set humanoid properties
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Health = humanoid.MaxHealth
    humanoid.Sit = false -- Ensure not sitting
    humanoid.PlatformStand = false -- Prevent platform stand
    humanoid.WalkSpeed = 12
    humanoid.JumpPower = 35
    humanoid.AutoRotate = true
    humanoid.HipHeight = 2

    -- Position the chibi rig at the character's current position
    local oldRoot = character:FindFirstChild("HumanoidRootPart")

    if oldRoot then
        local root = chibiRig:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = oldRoot.CFrame
        end
    end

    -- Scale the chibi rig to actual chibi size (1.0x for proper proportions) BEFORE setting as character
    if chibiRig:IsA("Model") and chibiRig.PrimaryPart then
        chibiRig:ScaleTo(1.0) -- Keep original chibi proportions - NOT huge
        logInfo("ChibiRig scaled", { player = player.Name })
    end

    -- Remove the old character
    character:Destroy()

    -- Parent the chibi rig to workspace FIRST
    chibiRig.Parent = workspace

    -- Ensure all parts are visible and not transparent
    for _, part in ipairs(chibiRig:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0
            if part.Name == "HumanoidRootPart" then
                part.CanCollide = true
            else
                part.CanCollide = false
            end
        end
    end

    -- Mark as processed BEFORE setting character to prevent loop
    processedCharacters[chibiRig] = true

    -- Set the player's character to the chibi rig
    -- This will trigger CharacterAdded, but our checks will prevent re-processing
    player.Character = chibiRig

    -- Clear the replacement flag after a short delay
    task.delay(1.0, function()
        replacingCharacter[player] = nil
    end)

    -- Add a simple face if not present
    local chibiHead = chibiRig:FindFirstChild("Head")
    if chibiHead and chibiHead:IsA("BasePart") then
        local face = chibiHead:FindFirstChild("face")
        if not face then
            face = Instance.new("Decal")
            face.Name = "face"
            face.Face = Enum.NormalId.Front
            face.Texture = "rbxasset://textures/face.png"
            face.Parent = chibiHead
        end
    end

    logInfo("Replaced character with ChibiRig", { player = player.Name })
end

function ChibiCharacterServer.init()
    logInfo("🎨 Initializing server-side ChibiRig replacement...")
    logInfo("ℹ️ ChibiRig features: slender block proportions, tapered limbs, stylized torso")

    -- Clear processed characters table
    processedCharacters = {}

    -- Apply to existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            task.spawn(function()
                replaceWithChibiRig(player.Character, player)
            end)
        end

        local _connection = player.CharacterAdded:Connect(function(character)
            -- Add a small delay to prevent immediate re-trigger
            task.spawn(function()
                task.wait(0.2) -- Slightly longer delay
                replaceWithChibiRig(character, player)
            end)
        end)
    end

    -- Apply to new players
    Players.PlayerAdded:Connect(function(player)
        local _connection = player.CharacterAdded:Connect(function(character)
            -- Add a small delay to prevent immediate re-trigger
            task.spawn(function()
                task.wait(0.2) -- Slightly longer delay
                replaceWithChibiRig(character, player)
            end)
        end)
    end)

    logInfo("✅ ChibiRig replacement active")
end

return ChibiCharacterServer
