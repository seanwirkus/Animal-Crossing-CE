-- HomePlacementGUI.luau
-- Client-side home placement editor with ghost preview and validation
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local HomePlacementGUI = {}
HomePlacementGUI.__index = HomePlacementGUI

function HomePlacementGUI.new()
	local self = setmetatable({}, HomePlacementGUI)

	self.active = false
	self.ghostModel = nil
	self.currentPosition = nil
	self.isValidPosition = false
	self.rotationAngle = 0
	self.smoothedPosition = nil
	self.lastValidPosition = nil

	-- Create UI
	self:_createUI()

	print("[HomePlacementGUI] ✅ Initialized")
	return self
end

function HomePlacementGUI:_createUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HomePlacementGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = player.PlayerGui

	-- Create instruction frame
	local instructionFrame = Instance.new("Frame")
	instructionFrame.Name = "InstructionFrame"
	instructionFrame.Size = UDim2.new(0, 400, 0, 150)
	instructionFrame.Position = UDim2.new(0.5, -200, 0.05, 0)
	instructionFrame.BackgroundColor3 = Color3.fromRGB(255, 252, 245)
	instructionFrame.BorderSizePixel = 0
	instructionFrame.Parent = screenGui

	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = instructionFrame

	-- Shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0, -15, 0, -15)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxasset://textures/ui/InspectMenu/shadow.png"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.8
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.ZIndex = -1
	shadow.Parent = instructionFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🏠 Place Your Home"
	title.TextColor3 = Color3.fromRGB(89, 70, 44)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = instructionFrame

	-- Status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -20, 0, 25)
	statusLabel.Position = UDim2.new(0, 10, 0, 55)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "✅ Ready to place"
	statusLabel.TextColor3 = Color3.fromRGB(120, 200, 120)
	statusLabel.TextSize = 18
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = instructionFrame

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(1, -20, 0, 60)
	instructions.Position = UDim2.new(0, 10, 0, 85)
	instructions.BackgroundTransparency = 1
	instructions.Text = "• Move mouse to position\n• R to rotate\n• Click to place\n• ESC to cancel"
	instructions.TextColor3 = Color3.fromRGB(89, 70, 44)
	instructions.TextSize = 14
	instructions.Font = Enum.Font.Gotham
	instructions.TextXAlignment = Enum.TextXAlignment.Left
	instructions.TextYAlignment = Enum.TextYAlignment.Top
	instructions.Parent = instructionFrame

	self.screenGui = screenGui
	self.statusLabel = statusLabel
end

function HomePlacementGUI:startPlacement(homeTemplate)
	if self.active then
		warn("[HomePlacementGUI] Placement already active!")
		return
	end

	-- Create ghost model from template
	if homeTemplate and homeTemplate:IsA("Model") then
		self.ghostModel = homeTemplate:Clone()
		self.ghostModel.Name = "HomePlacementGhost"

		-- Guarantee a PrimaryPart for stable PivotTo calls
		if not self.ghostModel.PrimaryPart then
			local anchor = Instance.new("Part")
			anchor.Name = "PlacementAnchor"
			anchor.Size = self.ghostModel:GetExtentsSize()
			anchor.Transparency = 1
			anchor.CanCollide = false
			anchor.Anchored = true
			anchor.Parent = self.ghostModel
			self.ghostModel.PrimaryPart = anchor
		end

		-- Make all parts transparent and non-collidable
		for _, descendant in ipairs(self.ghostModel:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 0.5
				descendant.CanCollide = false
				descendant.Anchored = true
				descendant.Material = Enum.Material.ForceField
			end
		end

		self.ghostModel.Parent = workspace
	else
		warn("[HomePlacementGUI] No valid home template provided!")
		return
	end

	self.active = true
	self.screenGui.Enabled = true
	self.rotationAngle = 0
	self.smoothedPosition = nil
	self.lastValidPosition = nil

	-- Lock player movement (optional)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = 0
	end

	-- Connect update loop
	self.updateConnection = RunService.RenderStepped:Connect(function()
		self:_updateGhostPosition()
	end)

	-- Connect rotation input
	self.rotateConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.R then
			self:_rotateGhost()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			self:cancelPlacement()
		end
	end)

	-- Connect click to place
	self.clickConnection = mouse.Button1Down:Connect(function()
		if self.isValidPosition then
			self:confirmPlacement()
		end
	end)

	print("[HomePlacementGUI] ✅ Placement mode started")
end

function HomePlacementGUI:_updateGhostPosition()
	if not self.active or not self.ghostModel then return end

	if not mouse.Hit then
		self.isValidPosition = false
		self.statusLabel.Text = "❌ Point at the ground to place"
		self.statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
		return
	end

	-- Raycast from mouse to ground
	local rayOrigin = mouse.Hit.Position + Vector3.new(0, 50, 0)
	local rayDirection = Vector3.new(0, -100, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }
	raycastParams.IgnoreWater = true

	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if rayResult then
		local position = rayResult.Position

		-- Snap to a gentle grid to reduce jitter/sensitivity
		local snap = 2
		position = Vector3.new(
			math.floor(position.X / snap + 0.5) * snap,
			position.Y,
			math.floor(position.Z / snap + 0.5) * snap
		)

		-- Smooth movement so the ghost model doesn't fly around
		if self.smoothedPosition then
			position = self.smoothedPosition:Lerp(position, 0.3)
		end
		self.currentPosition = position
		self.smoothedPosition = position

		-- Position ghost model
		local rotation = CFrame.Angles(0, math.rad(self.rotationAngle), 0)
		self.ghostModel:PivotTo(CFrame.new(position) * rotation)

		-- Validate position (client-side preview, server will validate again)
		local isValid = self:_validatePosition(position)
		self:_updateGhostAppearance(isValid)
		self.isValidPosition = isValid
		if isValid then
			self.lastValidPosition = position
		elseif self.lastValidPosition then
			-- Keep the ghost anchored to the last valid spot instead of jumping erratically
			self.ghostModel:PivotTo(CFrame.new(self.lastValidPosition) * rotation)
		end

		-- Update status
		if isValid then
			self.statusLabel.Text = "✅ Valid location - Click to place"
			self.statusLabel.TextColor3 = Color3.fromRGB(120, 200, 120)
		else
			self.statusLabel.Text = "❌ Invalid location"
			self.statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
		end
	else
		self.isValidPosition = false
		self.statusLabel.Text = "❌ No valid ground"
		self.statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
	end
end

function HomePlacementGUI:_validatePosition(position)
	-- Client-side basic validation (server will do full validation)

	-- Check if on ground
	local rayOrigin = position + Vector3.new(0, 5, 0)
	local rayDirection = Vector3.new(0, -10, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }

	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if not rayResult then
		return false -- Not on ground
	end

	-- Check if too steep
	local groundY = rayResult.Position.Y
	if math.abs(position.Y - groundY) > 3 then
		return false -- Too steep
	end

	-- Check for nearby obstacles
	local homeSize = Vector3.new(10, 8, 10)
	local region = Region3.new(
		position - homeSize / 2,
		position + homeSize / 2
	):ExpandToGrid(4)

	local partsInRegion = workspace:FindPartsInRegion3(region, self.ghostModel, 50)
	for _, part in ipairs(partsInRegion) do
		if part:IsA("BasePart") and part.Parent ~= self.ghostModel then
			local parentName = (part.Parent and part.Parent.Name or ""):lower()

			-- Check for obstacles
			if parentName:find("home") or parentName:find("building") or
			   parentName:find("rock") or parentName:find("tree") or
			   parentName:find("tent") or part.Size.Magnitude > 5 then
				return false -- Blocked by obstacle
			end
		end
	end

	return true
end

function HomePlacementGUI:_updateGhostAppearance(isValid)
	if not self.ghostModel then return end

	local color = isValid and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 120, 120)

	for _, descendant in ipairs(self.ghostModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Color = color
		end
	end
end

function HomePlacementGUI:_rotateGhost()
	self.rotationAngle = (self.rotationAngle + 45) % 360
	print("[HomePlacementGUI] Rotated to", self.rotationAngle, "degrees")
end

function HomePlacementGUI:confirmPlacement()
	if not self.active or not self.currentPosition then return end

	print("[HomePlacementGUI] Placing home at", self.currentPosition)

	-- Send to server
	local placeHomeRemote = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("PlaceHome")
	if placeHomeRemote then
		placeHomeRemote:FireServer(self.currentPosition, self.rotationAngle)
	else
		warn("[HomePlacementGUI] PlaceHome remote not found!")
	end

	self:endPlacement()
end

function HomePlacementGUI:cancelPlacement()
	print("[HomePlacementGUI] Placement cancelled")
	self:endPlacement()
end

function HomePlacementGUI:endPlacement()
	self.active = false
	self.screenGui.Enabled = false

	-- Cleanup ghost model
	if self.ghostModel then
		self.ghostModel:Destroy()
		self.ghostModel = nil
	end

	-- Disconnect connections
	if self.updateConnection then
		self.updateConnection:Disconnect()
		self.updateConnection = nil
	end

	if self.rotateConnection then
		self.rotateConnection:Disconnect()
		self.rotateConnection = nil
	end

	if self.clickConnection then
		self.clickConnection:Disconnect()
		self.clickConnection = nil
	end

	-- Restore player movement
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = 16
	end

	print("[HomePlacementGUI] Placement mode ended")
end

return HomePlacementGUI
