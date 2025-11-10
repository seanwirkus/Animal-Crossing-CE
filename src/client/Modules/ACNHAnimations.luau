--[[
	ACNHAnimations.luau
	
	Handles Animal Crossing style animations
	- Arms fly back when running
	- Cute walking animations
	- Item holding poses
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ACNHAnimations = {}

local function applyRunAnimation(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local leftShoulder = character:FindFirstChild("Left Shoulder", true)
	local rightShoulder = character:FindFirstChild("Right Shoulder", true)
	
	-- Store original C0 values
	local leftOriginalC0 = leftShoulder and leftShoulder.C0
	local rightOriginalC0 = rightShoulder and rightShoulder.C0
	
	-- Connect to movement
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not character.Parent then
			connection:Disconnect()
			return
		end
		
		local velocity = rootPart.AssemblyLinearVelocity
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		
		-- If running (speed > 12), fly arms back
		if speed > 12 then
			if leftShoulder and rightShoulder then
				-- Arms fly back like ACNH
				local backAngle = math.rad(-60)  -- Arms go back
				local sideAngle = math.rad(20)   -- Arms slightly out
				
				-- Animated swing
				local time = tick() * 8
				local swing = math.sin(time) * 0.2
				
				leftShoulder.C0 = leftOriginalC0 * CFrame.Angles(backAngle + swing, 0, -sideAngle)
				rightShoulder.C0 = rightOriginalC0 * CFrame.Angles(backAngle - swing, 0, sideAngle)
			end
		-- Walking animation
		elseif speed > 2 then
			if leftShoulder and rightShoulder then
				-- Gentle arm swing when walking
				local time = tick() * 4
				local swing = math.sin(time) * 0.5
				
				leftShoulder.C0 = leftOriginalC0 * CFrame.Angles(swing, 0, 0)
				rightShoulder.C0 = rightOriginalC0 * CFrame.Angles(-swing, 0, 0)
			end
		-- Idle - return to normal
		else
			if leftShoulder and rightShoulder then
				leftShoulder.C0 = leftOriginalC0
				rightShoulder.C0 = rightOriginalC0
			end
		end
	end)
	
	print("[ACNHAnimations] ✅ Running animation applied")
end

function ACNHAnimations.init()
	print("[ACNHAnimations] 🏃 Initializing ACNH-style animations...")
	
	local function onCharacterAdded(character)
		task.wait(0.3) -- Wait for character to fully load
		applyRunAnimation(character)
	end
	
	-- Apply to local player
	local localPlayer = Players.LocalPlayer
	if localPlayer.Character then
		onCharacterAdded(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(onCharacterAdded)
	
	print("[ACNHAnimations] ✅ Animations initialized")
end

return ACNHAnimations
