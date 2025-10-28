--[[
OrvilleSpawner - Spawns Orville NPC at hub for travel services
Handles interaction system for Dodo Airlines travel GUI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Logger = require(ReplicatedStorage.Logger) -- Disabled for now

local OrvilleSpawner = {}
OrvilleSpawner.__index = OrvilleSpawner

-- Configuration
local CONFIG = {
	SPAWN_POSITION = Vector3.new(40, 51, 0),  -- Right side of hub (opposite Tom Nook, for his plane)
	MODEL_NAME = "Orville",
	PROMPT_TEXT = "Talk to Orville - Travel Services",
}

function OrvilleSpawner.new(remotes)
	local self = setmetatable({}, OrvilleSpawner)
	self._remotes = remotes
	self._orvilleModel = nil
	self._connections = {}
	self._promptConnection = nil

	Logger:Info("OrvilleSpawner", "Initializing Orville; waiting for players before spawning")

	self:_listenForPlayers()
	self:_ensureSpawnedForExistingPlayers()

	return self
end

function OrvilleSpawner:_listenForPlayers()
	local function onPlayerAdded()
		self:_ensureSpawned()
	end

	local function onPlayerRemoving()
		task.defer(function()
			if #Players:GetPlayers() == 0 then
				self:_despawnOrville()
			end
		end)
	end

	self._connections.playerAdded = Players.PlayerAdded:Connect(onPlayerAdded)
	self._connections.playerRemoving = Players.PlayerRemoving:Connect(onPlayerRemoving)
end

function OrvilleSpawner:_ensureSpawnedForExistingPlayers()
	if #Players:GetPlayers() > 0 then
		self:_ensureSpawned()
	end
end

function OrvilleSpawner:_ensureSpawned()
	if self._orvilleModel then
		return
	end

	self:_spawnOrville()
	self:_setupInteraction()
end

function OrvilleSpawner:_spawnOrville()
	Logger:Info("OrvilleSpawner", "Creating Orville as simple rectangle")
	self:_createFallbackModel()
end

function OrvilleSpawner:_createFallbackModel()
	Logger:Info("OrvilleSpawner", "Creating Orville as simple rectangle")

	local model = Instance.new("Model")
	model.Name = CONFIG.MODEL_NAME
	model.Parent = workspace

	local rectangle = Instance.new("Part")
	rectangle.Name = "HumanoidRootPart"
	rectangle.Size = Vector3.new(3, 5, 2)
	rectangle.Position = CONFIG.SPAWN_POSITION + Vector3.new(0, 2.5, 0)
	rectangle.Anchored = true
	rectangle.BrickColor = BrickColor.new("Bright blue")
	rectangle.Material = Enum.Material.Neon
	rectangle.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = rectangle
	billboard.Size = UDim2.new(0, 150, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.Parent = rectangle

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "✈️ " .. CONFIG.MODEL_NAME
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = billboard

	model.PrimaryPart = rectangle
	self._orvilleModel = model

	self:_addProximityPrompt(model)

	Logger:Info("OrvilleSpawner", "Orville rectangle created at", CONFIG.SPAWN_POSITION)
end

function OrvilleSpawner:_addProximityPrompt(model)
	local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("[OrvilleSpawner] No root part found for ProximityPrompt")
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OrvillePrompt"
	prompt.ActionText = CONFIG.PROMPT_TEXT
	prompt.ObjectText = "Orville"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = rootPart

	Logger:Info("OrvilleSpawner", "ProximityPrompt added to Orville")
end

function OrvilleSpawner:_setupInteraction()
	if not self._orvilleModel then
		warn("[OrvilleSpawner] No Orville model to setup interaction")
		return
	end

	local prompt = self._orvilleModel:FindFirstChild("OrvillePrompt", true)
	if not prompt then
		warn("[OrvilleSpawner] ProximityPrompt not found")
		return
	end

	if self._promptConnection then
		self._promptConnection:Disconnect()
	end

	self._promptConnection = prompt.Triggered:Connect(function(player)
		self:HandleInteraction(player)
	end)

	Logger:Info("OrvilleSpawner", "Orville interaction system ready")
end

function OrvilleSpawner:_despawnOrville()
	if self._promptConnection then
		self._promptConnection:Disconnect()
		self._promptConnection = nil
	end

	if not self._orvilleModel then
		return
	end

	Logger:Info("OrvilleSpawner", "Despawning Orville (no players remain)")
	self._orvilleModel:Destroy()
	self._orvilleModel = nil
end

function OrvilleSpawner:HandleInteraction(player)
	Logger:Info("OrvilleSpawner", "Player interacting with Orville", {
		playerId = player.UserId,
		playerName = player.Name,
	})

	local openTravelGUI = self._remotes:Get("OpenTravelGUI")
	openTravelGUI:FireClient(player)
end

function OrvilleSpawner:Destroy()
	Logger:Info("OrvilleSpawner", "Destroying Orville")
	if self._connections.playerAdded then
		self._connections.playerAdded:Disconnect()
	end
	if self._connections.playerRemoving then
		self._connections.playerRemoving:Disconnect()
	end
	self:_despawnOrville()
end

return OrvilleSpawner
