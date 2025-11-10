--[[
	ChibiCharacterServer.luau
	
	Server-side character customization for ACNH chibi style
	Applies body proportions that can only be set from the server
]]

local Players = game:GetService("Players")

local ChibiCharacterServer = {}

local function applyProportions(character)
	task.wait(0.2) -- Wait for character to fully load
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then 
		warn("[ChibiCharacterServer] No humanoid found")
		return 
	end
	
	-- Scale character bigger (1.5x to match client)
	if character:IsA("Model") and character.PrimaryPart then
		character:ScaleTo(1.5)  -- Match client scale
		print("[ChibiCharacterServer] ✅ Scaled character to 1.5x")
	end
	
	-- Make head more spherical and rounded
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		-- Remove default face
		local face = head:FindFirstChild("face")
		if face then
			face:Destroy()
		end
		
		-- Make head perfectly spherical like Mii/ACNH
		local mesh = head:FindFirstChildOfClass("SpecialMesh")
		if not mesh then
			mesh = Instance.new("SpecialMesh")
			mesh.Parent = head
		end
		mesh.MeshType = Enum.MeshType.Head
		mesh.Scale = Vector3.new(1.5, 1.5, 1.5)  -- Bigger, rounder head
		
		-- Add simple cute face
		local newFace = Instance.new("Decal")
		newFace.Name = "face"
		newFace.Face = Enum.NormalId.Front
		newFace.Texture = "rbxasset://textures/face.png"
		newFace.Parent = head
		
		print("[ChibiCharacterServer] ✅ Made head spherical and added face")
	end
	
	-- Apply Mii/ACNH human-like proportions (must be done server-side)
	local success, err = pcall(function()
		local desc = humanoid:GetAppliedDescription()
		
		-- Wii Mii / Animal Crossing style proportions
		desc.HeadScale = 1.4          -- Bigger head for cute look
		desc.WidthScale = 1.15        -- Slightly wider body
		desc.DepthScale = 1.15        -- Slightly thicker body
		desc.HeightScale = 0.9        -- Slightly shorter but not too much
		desc.BodyTypeScale = 0        -- Round, soft body
		desc.ProportionScale = 0      -- Stubby limbs like Mii/ACNH		humanoid:ApplyDescription(desc)
		print("[ChibiCharacterServer] ✅ Applied Mii/ACNH human-like proportions")
	end)
	
	if not success then
		warn("[ChibiCharacterServer] ❌ Failed to apply proportions:", err)
	end
end

function ChibiCharacterServer.init()
	print("[ChibiCharacterServer] 🎨 Initializing server-side character customization...")
	
	-- Apply to existing players
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			applyProportions(player.Character)
		end
		
		player.CharacterAdded:Connect(applyProportions)
	end
	
	-- Apply to new players
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(applyProportions)
	end)
	
	print("[ChibiCharacterServer] ✅ Character customization active")
end

return ChibiCharacterServer
