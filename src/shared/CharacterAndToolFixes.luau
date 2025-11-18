--[[
	CharacterAndToolFixes.luau
	
	Fixes for Animal Crossing CE project:
	1. Character scaling issues after chibi system removal
	2. Tool anchoring problems preventing player movement
	3. Debug functionality for shovel and axe tools
	
	This module provides fixes for the issues that occurred after
	the chibi rig system was removed from the project.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CharacterAndToolFixes = {}

-- Character scaling configuration
local CHARACTER_CONFIG = {
	-- Scale factors to make players bigger after chibi removal
	SCALE_FACTOR = 3.0, -- 3.0x larger than default (increased from 2.5)
	HEAD_SCALE = 2.0, -- Larger head for more natural proportions (applied after base scale, increased from 1.5)
	HEIGHT_SCALE = 1.3, -- Additional height scaling to make character taller
	ARM_SCALE = 1.3,
	LEG_SCALE = 1.3,
	
	-- Which body parts to scale
	SCALE_PARTS = {
		"Head",
		"Torso", 
		"Left Arm",
		"Right Arm",
		"Left Leg",
		"Right Leg",
		"HumanoidRootPart"
	}
}

-- Tool debug configuration
local TOOL_DEBUG_CONFIG = {
	ENABLE_DEBUG_LOGS = true,
	ENABLE_SHOVEL_DEBUG = true,
	ENABLE_AXE_DEBUG = true,
	DEBUG_LOG_PREFIX = "[ToolDebug]"
}

-- Character scaling functions
function CharacterAndToolFixes.scaleCharacter(character: Model)
	if not character or not character.Parent then
		return false
	end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	
	-- Scale all major body parts
	local scaleFactor = CHARACTER_CONFIG.SCALE_FACTOR
	local heightScale = CHARACTER_CONFIG.HEIGHT_SCALE
	
	for _, partName in ipairs(CHARACTER_CONFIG.SCALE_PARTS) do
		local part = character:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			-- Apply base scaling
			local baseSize = part.Size * scaleFactor
			
			-- Apply additional height scaling to Y dimension for taller characters
			-- Skip head as it gets special scaling below
			if partName ~= "Head" then
				part.Size = Vector3.new(baseSize.X, baseSize.Y * heightScale, baseSize.Z)
				
				-- Store original size for potential restoration (for non-head parts)
				if not part:GetAttribute("OriginalSize") then
					part:SetAttribute("OriginalSize", part.Size.X .. "," .. part.Size.Y .. "," .. part.Size.Z)
				end
				
				print(string.format("[CharacterFix] Scaled %s by %.1fx (height: %.1fx)", partName, scaleFactor, heightScale))
			else
				part.Size = baseSize
				-- Head size will be stored after additional head scaling below
			end
		end
	end
	
	-- Special handling for head (often needs different scaling)
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		-- Apply additional head scaling (already scaled by SCALE_FACTOR above)
		head.Size = head.Size * CHARACTER_CONFIG.HEAD_SCALE
		
		-- Store original size for potential restoration (after all head scaling)
		if not head:GetAttribute("OriginalSize") then
			head:SetAttribute("OriginalSize", head.Size.X .. "," .. head.Size.Y .. "," .. head.Size.Z)
		end
		
		print(string.format("[CharacterFix] Head scaled by additional %.1fx (total: %.1fx)", CHARACTER_CONFIG.HEAD_SCALE, scaleFactor * CHARACTER_CONFIG.HEAD_SCALE))
	end
	
	-- Apply Humanoid height scaling for additional tallness
	if humanoid then
		-- Use BodyHeightScale if available (R15 characters)
		local heightScaleValue = humanoid:FindFirstChild("BodyHeightScale")
		if heightScaleValue and heightScaleValue:IsA("NumberValue") then
			heightScaleValue.Value = heightScaleValue.Value * heightScale
			print(string.format("[CharacterFix] Applied BodyHeightScale: %.2f", heightScaleValue.Value))
		end
	end
	
	return true
end

function CharacterAndToolFixes.restoreCharacter(character: Model)
	if not character or not character.Parent then
		return false
	end
	
	-- Restore original sizes from attributes
	for _, partName in ipairs(CHARACTER_CONFIG.SCALE_PARTS) do
		local part = character:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			local originalSizeStr = part:GetAttribute("OriginalSize")
			if originalSizeStr then
				local sizeValues = string.split(originalSizeStr, ",")
				if #sizeValues == 3 then
					part.Size = Vector3.new(
						tonumber(sizeValues[1]),
						tonumber(sizeValues[2]), 
						tonumber(sizeValues[3])
					)
					part:SetAttribute("OriginalSize", nil) -- Clear attribute
					print(string.format("[CharacterFix] Restored %s to original size", partName))
				end
			end
		end
	end
	
	return true
end

-- Tool fixing functions
function CharacterAndToolFixes.fixToolAnchoring(tool: Tool)
	if not tool or not tool.Parent then
		return false
	end
	
	-- Find all welds and constraints in the tool
	local weldsRemoved = 0
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
			-- Store debug info before removing
			if TOOL_DEBUG_CONFIG.ENABLE_DEBUG_LOGS then
				local weldInfo = string.format("%s between %s and %s", 
					descendant.ClassName, 
					descendant.Part0 and descendant.Part0.Name or "nil",
					descendant.Part1 and descendant.Part1.Name or "nil"
				)
				print(string.format("%s Removed problematic %s", TOOL_DEBUG_CONFIG.DEBUG_LOG_PREFIX, weldInfo))
			end
			
			descendant:Destroy()
			weldsRemoved = weldsRemoved + 1
		end
	end
	
	-- Remove any Anchored parts that might be anchoring to the map
	local anchoredPartsFixed = 0
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Anchored then
			descendant.Anchored = false
			anchoredPartsFixed = anchoredPartsFixed + 1
			
			if TOOL_DEBUG_CONFIG.ENABLE_DEBUG_LOGS then
				print(string.format("%s Unanchored part %s", TOOL_DEBUG_CONFIG.DEBUG_LOG_PREFIX, descendant.Name))
			end
		end
		
		-- Ensure parts don't collide with the player
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end
	
	print(string.format("[ToolFix] Removed %d welds, unanchored %d parts", weldsRemoved, anchoredPartsFixed))
	return true
end

-- Debug functionality for shovel
function CharacterAndToolFixes.debugShovel(player: Player, action: string, data: any?)
	if not TOOL_DEBUG_CONFIG.ENABLE_SHOVEL_DEBUG then
		return
	end
	
	local prefix = string.format("%s [Shovel]", TOOL_DEBUG_CONFIG.DEBUG_LOG_PREFIX)
	
	if action == "equip" then
		print(string.format("%s %s equipped shovel", prefix, player.Name))
		
		-- Check for problematic attachments
		local character = player.Character
		if character then
			local equippedTool = character:FindFirstChild("EquippedTool")
			if equippedTool then
				local welds = 0
				for _, descendant in ipairs(equippedTool:GetDescendants()) do
					if descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
						welds = welds + 1
					end
				end
				print(string.format("%s Found %d welds in equipped tool", prefix, welds))
			end
		end
		
	elseif action == "use" then
		print(string.format("%s %s tried to use shovel", prefix, player.Name))
		if data then
			print(string.format("%s Shovel use data: %s", prefix, tostring(data)))
		end
		
	elseif action == "dig" then
		print(string.format("%s %s attempted to dig", prefix, player.Name))
		if data then
			print(string.format("%s Dig position: %s", prefix, tostring(data)))
		end
	end
end

-- Debug functionality for axe
function CharacterAndToolFixes.debugAxe(player: Player, action: string, data: any?)
	if not TOOL_DEBUG_CONFIG.ENABLE_AXE_DEBUG then
		return
	end
	
	local prefix = string.format("%s [Axe]", TOOL_DEBUG_CONFIG.DEBUG_LOG_PREFIX)
	
	if action == "equip" then
		print(string.format("%s %s equipped axe", prefix, player.Name))
		
		-- Check for axe tool in character
		local character = player.Character
		if character then
			local tools = {}
			for _, tool in ipairs(character:GetChildren()) do
				if tool:IsA("Tool") and tool.Name:lower():find("axe") then
					table.insert(tools, tool.Name)
				end
			end
			if #tools > 0 then
				print(string.format("%s Found axe tools: %s", prefix, table.concat(tools, ", ")))
			end
		end
		
	elseif action == "use" then
		print(string.format("%s %s tried to use axe", prefix, player.Name))
		if data then
			print(string.format("%s Axe use data: %s", prefix, tostring(data)))
		end
		
	elseif action == "chop" then
		print(string.format("%s %s attempted to chop", prefix, player.Name))
		if data then
			print(string.format("%s Chop target: %s", prefix, tostring(data)))
		end
	end
end

-- Automatic character scaling on spawn
function CharacterAndToolFixes.setupPlayerCharacterScaling(player: Player)
	player.CharacterAdded:Connect(function(character)
		print(string.format("[CharacterFix] Setting up character scaling for %s", player.Name))
		
		-- Wait a moment for the character to fully load
		task.wait(0.5)
		
		-- Scale the character
		if CharacterAndToolFixes.scaleCharacter(character) then
			print(string.format("[CharacterFix] ✅ Successfully scaled character for %s", player.Name))
		else
			warn(string.format("[CharacterFix] ❌ Failed to scale character for %s", player.Name))
		end
		
		-- Monitor for tool equipping to fix anchoring
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				task.wait(0.1) -- Wait for tool to fully load
				CharacterAndToolFixes.fixToolAnchoring(child)
			end
		end)
		
		-- Monitor for existing tools
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				CharacterAndToolFixes.fixToolAnchoring(child)
			end
		end
	end)
end

-- Initialize the fixes
function CharacterAndToolFixes.init()
	print("[CharacterAndToolFixes] 🚀 Initializing character and tool fixes...")
	
	-- Set up automatic character scaling for all players
	for _, player in ipairs(Players:GetPlayers()) do
		CharacterAndToolFixes.setupPlayerCharacterScaling(player)
	end
	
	-- Set up for new players
	Players.PlayerAdded:Connect(function(player)
		CharacterAndToolFixes.setupPlayerCharacterScaling(player)
	end)
	
	-- Add debug RemoteEvents for testing
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = ReplicatedStorage
	end
	
	-- Debug event for testing tool fixes
	local debugRemote = Instance.new("RemoteEvent")
	debugRemote.Name = "ToolDebugEvent"
	debugRemote.Parent = remoteEvents
	
	debugRemote.OnServerEvent:Connect(function(player, action, data)
		if action == "scaleCharacter" then
			CharacterAndToolFixes.scaleCharacter(player.Character)
			
		elseif action == "restoreCharacter" then
			CharacterAndToolFixes.restoreCharacter(player.Character)
			
		elseif action == "debugShovel" then
			CharacterAndToolFixes.debugShovel(player, data.action, data.data)
			
		elseif action == "debugAxe" then
			CharacterAndToolFixes.debugAxe(player, data.action, data.data)
			
		elseif action == "fixTools" then
			local character = player.Character
			if character then
				for _, tool in ipairs(character:GetChildren()) do
					if tool:IsA("Tool") then
						CharacterAndToolFixes.fixToolAnchoring(tool)
					end
				end
			end
		end
	end)
	
	print("[CharacterAndToolFixes] ✅ Character and tool fixes initialized!")
end

-- Export functions for manual use
CharacterAndToolFixes.scaleCharacter = CharacterAndToolFixes.scaleCharacter
CharacterAndToolFixes.restoreCharacter = CharacterAndToolFixes.restoreCharacter
CharacterAndToolFixes.fixToolAnchoring = CharacterAndToolFixes.fixToolAnchoring
CharacterAndToolFixes.debugShovel = CharacterAndToolFixes.debugShovel
CharacterAndToolFixes.debugAxe = CharacterAndToolFixes.debugAxe
CharacterAndToolFixes.setupPlayerCharacterScaling = CharacterAndToolFixes.setupPlayerCharacterScaling

return CharacterAndToolFixes