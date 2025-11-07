--[[
	ChibiCharacter.luau
	Transforms player character into cute chibi-style proportions
	Inspired by Animal Crossing character design
]]

local ChibiCharacter = {}
ChibiCharacter.__index = ChibiCharacter

local Players = game:GetService("Players")

-- Chibi proportions configuration
local CHIBI_CONFIG = {
	-- Overall character scale
	overallScale = 0.85,  -- Make character slightly smaller overall
	
	-- Body part scales (relative to normal size)
	headScale = 1.3,      -- Bigger head (130% of normal)
	torsoScale = 0.9,     -- Slightly smaller torso
	
	-- Limb scales
	leftArmScale = 0.75,   -- Shorter arms
	rightArmScale = 0.75,
	leftLegScale = 0.8,    -- Shorter legs
	rightLegScale = 0.8,
	
	-- Make character rounder/cuter
	bodyProportions = {
		bodyDepthScale = 1.1,   -- Slightly rounder front-to-back
		bodyWidthScale = 1.0,   -- Normal width
	}
}

function ChibiCharacter.new()
	local self = setmetatable({}, ChibiCharacter)
	
	self.player = Players.LocalPlayer
	self.appliedCharacters = {}
	
	self:init()
	
	return self
end

function ChibiCharacter:init()
	-- Apply to current character if it exists
	if self.player.Character then
		self:applyToCharacter(self.player.Character)
	end
	
	-- Apply to future characters when they respawn
	self.player.CharacterAdded:Connect(function(character)
		self:applyToCharacter(character)
	end)
	
	print("[ChibiCharacter] ✅ Initialized - cute chibi mode enabled!")
end

function ChibiCharacter:applyToCharacter(character)
	-- Wait for humanoid to load
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		warn("[ChibiCharacter] No humanoid found")
		return
	end
	
	-- Wait a moment for character to fully load
	task.wait(0.5)
	
	print("[ChibiCharacter] 🎀 Applying chibi proportions...")
	
	-- Apply overall body scale through Humanoid
	local bodyDepthScale = humanoid:FindFirstChild("BodyDepthScale") or Instance.new("NumberValue")
	bodyDepthScale.Name = "BodyDepthScale"
	bodyDepthScale.Value = CHIBI_CONFIG.bodyProportions.bodyDepthScale
	bodyDepthScale.Parent = humanoid
	
	local bodyWidthScale = humanoid:FindFirstChild("BodyWidthScale") or Instance.new("NumberValue")
	bodyWidthScale.Name = "BodyWidthScale"
	bodyWidthScale.Value = CHIBI_CONFIG.bodyProportions.bodyWidthScale
	bodyWidthScale.Parent = humanoid
	
	-- Apply individual body part scales
	self:scaleBodyPart(humanoid, "Head", CHIBI_CONFIG.headScale)
	self:scaleBodyPart(humanoid, "UpperTorso", CHIBI_CONFIG.torsoScale)
	self:scaleBodyPart(humanoid, "LowerTorso", CHIBI_CONFIG.torsoScale)
	
	self:scaleBodyPart(humanoid, "LeftUpperArm", CHIBI_CONFIG.leftArmScale)
	self:scaleBodyPart(humanoid, "LeftLowerArm", CHIBI_CONFIG.leftArmScale)
	self:scaleBodyPart(humanoid, "LeftHand", CHIBI_CONFIG.leftArmScale)
	
	self:scaleBodyPart(humanoid, "RightUpperArm", CHIBI_CONFIG.rightArmScale)
	self:scaleBodyPart(humanoid, "RightLowerArm", CHIBI_CONFIG.rightArmScale)
	self:scaleBodyPart(humanoid, "RightHand", CHIBI_CONFIG.rightArmScale)
	
	self:scaleBodyPart(humanoid, "LeftUpperLeg", CHIBI_CONFIG.leftLegScale)
	self:scaleBodyPart(humanoid, "LeftLowerLeg", CHIBI_CONFIG.leftLegScale)
	self:scaleBodyPart(humanoid, "LeftFoot", CHIBI_CONFIG.leftLegScale)
	
	self:scaleBodyPart(humanoid, "RightUpperLeg", CHIBI_CONFIG.rightLegScale)
	self:scaleBodyPart(humanoid, "RightLowerLeg", CHIBI_CONFIG.rightLegScale)
	self:scaleBodyPart(humanoid, "RightFoot", CHIBI_CONFIG.rightLegScale)
	
	-- Store that we've applied to this character
	self.appliedCharacters[character] = true
	
	print("[ChibiCharacter] ✨ Chibi transformation complete!")
end

function ChibiCharacter:scaleBodyPart(humanoid, bodyPartName, scale)
	-- Create or update the scale value for this body part
	local scaleValueName = bodyPartName .. "Scale"
	local scaleValue = humanoid:FindFirstChild(scaleValueName)
	
	if not scaleValue then
		scaleValue = Instance.new("NumberValue")
		scaleValue.Name = scaleValueName
		scaleValue.Parent = humanoid
	end
	
	scaleValue.Value = scale
end

function ChibiCharacter:resetCharacter(character)
	-- Reset to normal proportions
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Remove all custom scale values
	for _, child in pairs(humanoid:GetChildren()) do
		if child:IsA("NumberValue") and child.Name:match("Scale$") then
			child:Destroy()
		end
	end
	
	print("[ChibiCharacter] Character reset to normal proportions")
end

return ChibiCharacter
