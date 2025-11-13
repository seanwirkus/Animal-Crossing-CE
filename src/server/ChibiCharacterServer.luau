--[[
	ChibiCharacterServer.luau
	
	Server-side character customization for ACNH chibi style
	Applies body proportions that can only be set from the server
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChibiCharacterServer = {}

-- Helper functions for creating ChibiRig model
local function createPart(name, size, position, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = false
    part.CanCollide = true
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

local function ensureChibiRigExists()
    local avatarKitFolder = ReplicatedStorage:FindFirstChild("AvatarKit")
    if not avatarKitFolder then
        avatarKitFolder = Instance.new("Folder")
        avatarKitFolder.Name = "AvatarKit"
        avatarKitFolder.Parent = ReplicatedStorage
    end

    local existing = avatarKitFolder:FindFirstChild("ChibiRig")
    if existing then
        return existing
    end

    print("[ChibiCharacterServer] Creating ChibiRig model...")

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

    -- Add forearms
    local leftForearm = createPart("LeftLowerArm", Vector3.new(0.5, 1.0, 0.5), Vector3.new(-1.2, 1.9, 0))
    leftForearm.Parent = rig
    local rightForearm = createPart("RightLowerArm", Vector3.new(0.5, 1.0, 0.5), Vector3.new(1.2, 1.9, 0))
    rightForearm.Parent = rig

    -- Add bigger spherical hands (more chibi-like) - proper spheres
    local leftHand = createPart("LeftHand", Vector3.new(0.3, 0.3, 0.3), Vector3.new(-1.2, 1.3, 0))
    local leftHandMesh = createSphereMesh(Vector3.new(4, 4, 4))  -- Larger scale for more prominent spheres
    leftHandMesh.Parent = leftHand
    leftHand.Parent = rig

    local rightHand = createPart("RightHand", Vector3.new(0.3, 0.3, 0.3), Vector3.new(1.2, 1.3, 0))
    local rightHandMesh = createSphereMesh(Vector3.new(4, 4, 4))  -- Larger scale for more prominent spheres
    rightHandMesh.Parent = rightHand
    rightHand.Parent = rig

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
    bodyColors.LeftHandColor3 = Color3.fromRGB(255, 228, 200)
    bodyColors.RightHandColor3 = Color3.fromRGB(255, 228, 200)
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
        { leftArm, leftForearm },
        { rightArm, rightForearm },
        { leftForearm, leftHand },
        { rightForearm, rightHand },
        { humanoidRootPart, leftLeg },
        { humanoidRootPart, rightLeg },
    }

    for _, pair in ipairs(welds) do
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = pair[1]
        weld.Part1 = pair[2]
        weld.Parent = pair[1]
    end

    rig.Parent = avatarKitFolder
    print("[ChibiCharacterServer] ✅ ChibiRig model created")
    return rig
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
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
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
		warn("[ChibiCharacterServer] Failed to get ChibiRig template")
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
		warn("[ChibiCharacterServer] No humanoid in ChibiRig")
		return
	end

	-- Set the player as the humanoid's player
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	
	-- Set humanoid properties
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Health = humanoid.MaxHealth

	-- Position the chibi rig at the character's current position
	local oldRoot = character:FindFirstChild("HumanoidRootPart")
	local spawnPosition = Vector3.new(0, 5, 0) -- Default spawn position
	
	if oldRoot then
		spawnPosition = oldRoot.Position
		local root = chibiRig:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = oldRoot.CFrame
		end
	end

	-- Scale the chibi rig bigger (2.5x for more chibi effect) BEFORE setting as character
	if chibiRig:IsA("Model") and chibiRig.PrimaryPart then
		chibiRig:ScaleTo(2.5)
		print("[ChibiCharacterServer] ✅ Scaled ChibiRig to 2.5x")
	end

	-- Remove the old character
	character:Destroy()

	-- Parent the chibi rig to workspace FIRST
	chibiRig.Parent = workspace
	
	-- Ensure all parts are visible and not transparent
	for _, part in ipairs(chibiRig:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0
			part.CanCollide = true
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
	local head = chibiRig:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local face = head:FindFirstChild("face")
		if not face then
			face = Instance.new("Decal")
			face.Name = "face"
			face.Face = Enum.NormalId.Front
			face.Texture = "rbxasset://textures/face.png"
			face.Parent = head
		end
	end

	print("[ChibiCharacterServer] ✅ Replaced character with ChibiRig")
end

function ChibiCharacterServer.init()
	print("[ChibiCharacterServer] 🎨 Initializing server-side ChibiRig replacement...")
	print("[ChibiCharacterServer] ℹ️ ChibiRig features: spherical hands, short stature, wide body parts")

	-- Clear processed characters table
	processedCharacters = {}

	-- Apply to existing players
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			task.spawn(function()
				replaceWithChibiRig(player.Character, player)
			end)
		end

		local connection = player.CharacterAdded:Connect(function(character)
			-- Add a small delay to prevent immediate re-trigger
			task.spawn(function()
				task.wait(0.2) -- Slightly longer delay
				replaceWithChibiRig(character, player)
			end)
		end)
	end

	-- Apply to new players
	Players.PlayerAdded:Connect(function(player)
		local connection = player.CharacterAdded:Connect(function(character)
			-- Add a small delay to prevent immediate re-trigger
			task.spawn(function()
				task.wait(0.2) -- Slightly longer delay
				replaceWithChibiRig(character, player)
			end)
		end)
	end)

	print("[ChibiCharacterServer] ✅ ChibiRig replacement active")
end

return ChibiCharacterServer
