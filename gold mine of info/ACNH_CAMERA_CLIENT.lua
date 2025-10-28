--[[
	🏝️ ANIMAL CROSSING: NEW HORIZONS CAMERA SCRIPT (CLIENT)
	
	HOW TO USE:
	1. In Roblox Studio, insert a LocalScript into StarterPlayer → StarterCharacterScripts
	2. Name it "ACNHCamera"
	3. Copy this ENTIRE script
	4. Paste into the LocalScript
	5. Run the game!
	
	This handles all CAMERA effects (client-side)
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

print("🎥 Applying Animal Crossing camera style...")

-- ============================================================================
-- CAMERA SETTINGS (AC:NH style - ENHANCED FOV)
-- ============================================================================

-- AC:NH has a distinctive wide, slightly top-down view
camera.FieldOfView = 85  -- Wide angle for spacious feel (was 70)

-- Camera distance (pulled back for better overview)
player.CameraMaxZoomDistance = 30  -- Can zoom out more
player.CameraMinZoomDistance = 15  -- Minimum distance (prevents first-person)

-- Top-down angle for AC:NH isometric-ish feel
humanoid.CameraOffset = Vector3.new(0, 4, 0)  -- Higher camera for top-down view

-- Force third person view (AC is always third person)
player.CameraMode = Enum.CameraMode.Classic

-- Additional settings
camera.CameraType = Enum.CameraType.Custom  -- Follows player smoothly

print("✅ Camera applied:")
print("  • FOV: 85° (wide angle)")
print("  • Distance: 15-30 studs (pulled back)")
print("  • Angle: +4 studs (top-down)")
print("  • Mode: Third-person locked")

-- ============================================================================
-- CHARACTER RESPAWN HANDLING
-- ============================================================================

-- Reapply settings when character respawns
player.CharacterAdded:Connect(function(newCharacter)
	task.wait(0.5)  -- Wait for character to load
	
	local newHumanoid = newCharacter:WaitForChild("Humanoid")
	
	-- Reapply camera offset
	newHumanoid.CameraOffset = Vector3.new(0, 4, 0)
	
	-- Reapply zoom settings
	player.CameraMaxZoomDistance = 30
	player.CameraMinZoomDistance = 15
	
	camera.FieldOfView = 85
	
	print("🎥 Camera reapplied after respawn")
end)

-- ============================================================================
-- SUMMARY
-- ============================================================================

print("═══════════════════════════════════════════════════════════════")
print("📷 ANIMAL CROSSING CAMERA APPLIED!")
print("═══════════════════════════════════════════════════════════════")
print("🎥 FOV: 85° (wide, spacious)")
print("📏 Distance: 15-30 studs (perfect overview)")
print("🔺 Angle: Top-down (+4 studs)")
print("🔒 Mode: Third-person only")
print("═══════════════════════════════════════════════════════════════")
print("🎮 Camera ready! Explore your island!")
print("═══════════════════════════════════════════════════════════════")

