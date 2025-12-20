-- HomePlacementController.luau
-- Handles client-side home placement triggered by server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local HomePlacementGUI = require(script.Parent.HomePlacementGUI)

local player = Players.LocalPlayer

local HomePlacementController = {}
HomePlacementController.__index = HomePlacementController

local _instance = nil

function HomePlacementController.new()
	if _instance then
		return _instance
	end

	local self = setmetatable({}, HomePlacementController)

	self.placementGUI = HomePlacementGUI.new()
	self.homeTemplate = nil

	-- Connect to server remote
	self:_setupRemotes()

	_instance = self
	print("[HomePlacementController] ✅ Initialized")
	return self
end

function HomePlacementController:_setupRemotes()
	-- Listen for server telling us to start placement
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	local startPlacementRemote = remoteEvents:WaitForChild("StartHomePlacement")

	startPlacementRemote.OnClientEvent:Connect(function(success, message, materials)
		if success then
			print("[HomePlacementController] ✅ Server says we can place home!")
			self:startPlacement()
		else
			warn("[HomePlacementController] ❌ Cannot place home:", message)
			-- TODO: Show error message to player
		end
	end)
end

function HomePlacementController:startPlacement()
	-- Get home template from ReplicatedStorage
	local homeTemplate = ReplicatedStorage:FindFirstChild("PlayerHome")
	if not homeTemplate then
		warn("[HomePlacementController] ⚠️ PlayerHome template not found in ReplicatedStorage!")
		-- Create a fallback cube as placeholder
		homeTemplate = Instance.new("Model")
		homeTemplate.Name = "TentPlaceholder"

		local part = Instance.new("Part")
		part.Size = Vector3.new(10, 8, 10)
		part.Anchored = true
		part.Color = Color3.fromRGB(200, 150, 100)
		part.Parent = homeTemplate
		homeTemplate.PrimaryPart = part
	end

	-- Start placement GUI
	print("[HomePlacementController] Starting placement with template:", homeTemplate.Name)
	self.placementGUI:startPlacement(homeTemplate)
end

-- Initialize singleton
return HomePlacementController.new()
