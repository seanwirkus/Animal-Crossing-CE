-- HomePlacementController.luau
-- Handles client-side home placement triggered by server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local HomePlacementGUI = require(script.Parent.HomePlacementGUI)
local HomeTemplates = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HomeTemplates"))

local player = Players.LocalPlayer
local CAMERA_BIND_NAME = "HomePlacementCamera"
local DRONE_CAMERA_HEIGHT = 50
local DRONE_TRANSITION_SECONDS = 0.75

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
	self._cameraRestore = nil
	self._placementStarting = false

	self.placementGUI.onPlacementEnded = function()
		self:_restorePlacementCamera()
		self._placementStarting = false
	end

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

function HomePlacementController:_getDroneCFrame()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return nil
	end

	local focus = rootPart.Position
	local cameraPos = focus + Vector3.new(0, DRONE_CAMERA_HEIGHT, 0)
	return CFrame.new(cameraPos, focus)
end

function HomePlacementController:_enterPlacementCamera()
	local camera = Workspace.CurrentCamera
	if not camera then
		warn("[HomePlacementController] ❌ No camera available for placement")
		return false
	end

	local targetCFrame = self:_getDroneCFrame()
	if not targetCFrame then
		warn("[HomePlacementController] ❌ No character root for placement camera")
		return false
	end

	self._cameraRestore = {
		CameraType = camera.CameraType,
		CameraSubject = camera.CameraSubject,
		CFrame = camera.CFrame,
	}

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = nil

	local startCFrame = camera.CFrame
	local startTime = os.clock()

	RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)
	RunService:BindToRenderStep(CAMERA_BIND_NAME, Enum.RenderPriority.Camera.Value + 2, function()
		local currentTarget = self:_getDroneCFrame() or targetCFrame
		local elapsed = os.clock() - startTime
		local alpha = DRONE_TRANSITION_SECONDS > 0 and math.clamp(elapsed / DRONE_TRANSITION_SECONDS, 0, 1) or 1
		local eased = 1 - (1 - alpha) * (1 - alpha)
		if alpha < 1 then
			camera.CFrame = startCFrame:Lerp(currentTarget, eased)
		else
			camera.CFrame = currentTarget
		end
	end)

	task.wait(DRONE_TRANSITION_SECONDS)
	return true
end

function HomePlacementController:_restorePlacementCamera()
	RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)

	local camera = Workspace.CurrentCamera
	if camera and self._cameraRestore then
		camera.CameraType = self._cameraRestore.CameraType
		camera.CameraSubject = self._cameraRestore.CameraSubject
		camera.CFrame = self._cameraRestore.CFrame
	end

	self._cameraRestore = nil
end

function HomePlacementController:startPlacement()
	if self._placementStarting or self.placementGUI.active then
		warn("[HomePlacementController] Placement already in progress")
		return
	end

	self._placementStarting = true

	local didTransition = self:_enterPlacementCamera()

	-- Use a procedurally generated tent so we never depend on imported OBJ content.
	local homeTemplate = HomeTemplates.createTentTemplate({
		anchored = true,
	})

	if not homeTemplate then
		warn("[HomePlacementController] ❌ Failed to create home template")
		if didTransition then
			self:_restorePlacementCamera()
		end
		self._placementStarting = false
		return
	end

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
