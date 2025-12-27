-- HomePlacementController.luau
-- Handles client-side home placement triggered by server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local HomePlacementGUI = require(script.Parent.HomePlacementGUI)
local HomeTemplates = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HomeTemplates"))

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
			print("[HomePlacementController] ✅ Server says we can place home!", message or "")
			self:startPlacement()
		else
			warn("[HomePlacementController] ❌ Cannot place home:", message)
			local notificationText = message or "You need more resources before placing a home."
			pcall(function()
				StarterGui:SetCore("SendNotification", {
					Title = "Cannot Place Home",
					Text = notificationText,
					Duration = 5,
				})
			end)

			if materials then
				local parts = {}
				for _, material in ipairs(materials) do
					table.insert(parts, string.format("%dx %s", material.count, material.itemId))
				end
				print("[HomePlacementController] Required materials:", table.concat(parts, ", "))
			end
		end
	end)
end

function HomePlacementController:startPlacement()
	-- Use a procedurally generated tent so we never depend on imported OBJ content.
	local homeTemplate = HomeTemplates.createTentTemplate({
		anchored = true,
	})

	-- Start placement GUI
	print("[HomePlacementController] Starting placement with template:", homeTemplate.Name)
	self.placementGUI:startPlacement(homeTemplate)
end

-- Request placement from Nook Phone or other UI
function HomePlacementController:requestPlacement()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	local startPlacementRemote = remoteEvents:WaitForChild("StartHomePlacement")

	print("[HomePlacementController] 📱 Requesting home placement from server...")
	startPlacementRemote:FireServer()
end

-- Alias for different naming conventions
function HomePlacementController:open()
	self:requestPlacement()
end

-- Initialize singleton
return HomePlacementController.new()
