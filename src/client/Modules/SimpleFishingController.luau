--[[
	SimpleFishingController.luau
	A simplified, non-glitchy fishing system for Animal Crossing

	How it works:
	1. Player equips fishing rod
	2. Player clicks on water
	3. Bobber appears, waits for bite (2-5 seconds)
	4. "!" bubble appears
	5. Player presses E to catch
	6. Fish added to inventory
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local SimpleFishingController = {}

-- State
local isFishing = false
local hasBite = false
local currentBobber = nil
local biteConnection = nil
local equippedFishingRod = nil

-- Configuration
local CAST_RANGE = 50
local BITE_MIN_TIME = 2
local BITE_MAX_TIME = 5
local CATCH_WINDOW = 2 -- seconds to press E after bite

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ToolEvents = RemoteEvents:FindFirstChild("ToolEvents")
if not ToolEvents then
	ToolEvents = Instance.new("Folder")
	ToolEvents.Name = "ToolEvents"
	ToolEvents.Parent = RemoteEvents
end

local toolUseRemote = ToolEvents:FindFirstChild("ToolUse")
if not toolUseRemote then
	toolUseRemote = Instance.new("RemoteEvent")
	toolUseRemote.Name = "ToolUse"
	toolUseRemote.Parent = ToolEvents
end

-- Check if position is in water
local function isWater(position)
	local terrain = Workspace.Terrain
	local region = Region3.new(position - Vector3.new(2, 2, 2), position + Vector3.new(2, 2, 2))
	region = region:ExpandToGrid(4)

	local materials, _ = terrain:ReadVoxels(region, 4)
	local size = materials.Size

	for x = 1, size.X do
		for y = 1, size.Y do
			for z = 1, size.Z do
				if materials[x][y][z] == Enum.Material.Water then
					return true
				end
			end
		end
	end

	return false
end

-- Create bobber visual
local function createBobber(position)
	local bobber = Instance.new("Part")
	bobber.Name = "FishingBobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.5, 0.5, 0.5)
	bobber.Position = position
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.BrickColor = BrickColor.new("Bright red")
	bobber.Material = Enum.Material.SmoothPlastic
	bobber.Parent = Workspace

	-- Add bobbing animation
	local bobTween = TweenService:Create(
		bobber,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Position = position + Vector3.new(0, 0.3, 0)}
	)
	bobTween:Play()

	return bobber
end

-- Create bite indicator
local function createBiteIndicator(position)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BiteIndicator"
	billboard.Size = UDim2.new(0, 100, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = currentBobber

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "!"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	return billboard
end

-- Clean up fishing state
local function cleanupFishing()
	isFishing = false
	hasBite = false

	if currentBobber then
		currentBobber:Destroy()
		currentBobber = nil
	end

	if biteConnection then
		biteConnection:Disconnect()
		biteConnection = nil
	end

	print("[SimpleFishing] ✅ Fishing cleaned up")
end

-- Handle casting
local function castFishingRod(clickPosition)
	if isFishing then
		print("[SimpleFishing] ⚠️ Already fishing!")
		return
	end

	-- Check if position is water
	if not isWater(clickPosition) then
		print("[SimpleFishing] ⚠️ Not water!")
		return
	end

	-- Check range
	local distance = (clickPosition - humanoidRootPart.Position).Magnitude
	if distance > CAST_RANGE then
		print("[SimpleFishing] ⚠️ Too far!")
		return
	end

	print("[SimpleFishing] 🎣 Casting at:", clickPosition)

	isFishing = true
	hasBite = false

	-- Create bobber
	currentBobber = createBobber(clickPosition)

	-- Wait for bite (random time)
	local biteTime = math.random(BITE_MIN_TIME * 10, BITE_MAX_TIME * 10) / 10
	print(string.format("[SimpleFishing] ⏱️ Bite in %.1f seconds", biteTime))

	task.wait(biteTime)

	-- Check if still fishing
	if not isFishing or not currentBobber then
		print("[SimpleFishing] ❌ Fishing cancelled before bite")
		return
	end

	-- Bite!
	hasBite = true
	print("[SimpleFishing] 🐟 BITE! Press E to catch!")

	-- Create bite indicator
	createBiteIndicator(currentBobber.Position)

	-- Make bobber flash
	local originalColor = currentBobber.BrickColor
	for i = 1, 6 do
		if not currentBobber then break end
		currentBobber.BrickColor = BrickColor.new("Bright yellow")
		task.wait(0.15)
		if not currentBobber then break end
		currentBobber.BrickColor = originalColor
		task.wait(0.15)
	end

	-- If player didn't catch in time, fish escapes
	if hasBite then
		print("[SimpleFishing] 🐟 Fish escaped!")
		cleanupFishing()
	end
end

-- Handle catching
local function attemptCatch()
	if not isFishing then
		return
	end

	if not hasBite then
		print("[SimpleFishing] ⚠️ Too early! No bite yet.")
		return
	end

	print("[SimpleFishing] ✅ CAUGHT!")

	-- Send to server
	toolUseRemote:FireServer({
		toolType = "fishing",
		action = "catch",
		position = currentBobber and currentBobber.Position or Vector3.new(0, 0, 0),
	})

	-- Clean up
	cleanupFishing()
end

-- Monitor mouse clicks for casting
local function onMouseClick(target, position)
	if not equippedFishingRod then
		return
	end

	if isFishing then
		return
	end

	-- Check if clicked on water
	castFishingRod(position)
end

-- Check if fishing rod is equipped via player attribute
local function isFishingRodEquipped()
	local toolType = player:GetAttribute("EquippedToolType")
	if toolType and (tostring(toolType):lower():find("fishing") or tostring(toolType):lower():find("rod")) then
		return true
	end
	return false
end

-- Monitor for fishing rod equipped/unequipped via attribute changes
local function setupAttributeMonitoring()
	player:GetAttributeChangedSignal("EquippedToolType"):Connect(function()
		local toolType = player:GetAttribute("EquippedToolType")

		if toolType and (tostring(toolType):lower():find("fishing") or tostring(toolType):lower():find("rod")) then
			equippedFishingRod = true
			print("[SimpleFishing] 🎣 Fishing rod equipped!")
		else
			if equippedFishingRod then
				equippedFishingRod = nil
				print("[SimpleFishing] ✅ Fishing rod unequipped")
				cleanupFishing()
			end
		end
	end)

	-- Check initial state
	if isFishingRodEquipped() then
		equippedFishingRod = true
		print("[SimpleFishing] 🎣 Fishing rod initially equipped!")
	end
end

-- Monitor character for setup
local function setupCharacter(char)
	character = char
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

-- Initialize
function SimpleFishingController.init()
	print("[SimpleFishing] 🎣 Initializing fishing controller...")

	-- Setup attribute monitoring for fishing rod
	setupAttributeMonitoring()

	-- Setup character
	if player.Character then
		setupCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupCharacter)

	-- Listen for E key to catch fish
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.E then
			attemptCatch()
		end
	end)

	-- Listen for mouse clicks to cast
	local mouse = player:GetMouse()
	mouse.Button1Down:Connect(function()
		if not equippedFishingRod then return end

		local target = mouse.Target
		local hitPosition = mouse.Hit.Position

		if target then
			onMouseClick(target, hitPosition)
		end
	end)

	print("[SimpleFishing] ✅ Fishing controller ready!")
end

return SimpleFishingController
