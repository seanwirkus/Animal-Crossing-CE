--[[
	HubService - Manages the main hub/plaza area where players spawn BEFORE island generation
	Similar to Dodo Airlines in Animal Crossing - players arrive here first
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Logger)

local HubService = {}
HubService.__index = HubService

-- Hub configuration
local HUB_CONFIG = {
	SPAWN_POSITION = Vector3.new(0, 50, 0),  -- High up, safe spawn
	TOM_NOOK_POSITION = Vector3.new(10, 51, 0),  -- Tom Nook desk position
	HUB_SIZE = 100,  -- Hub platform size
}

function HubService.new(remotes)
	local self = setmetatable({}, HubService)
	self._remotes = remotes
	self._hubFolder = nil
	self._tomNookModel = nil
	self._playerIslandStates = {}  -- Track which players have generated islands
	
	Logger:Info("HubService", "Initializing main hub/plaza")
	
	-- Build the enhanced hub area
	self:_buildEnhancedHub()
	
	-- Spawn NPC placeholders at hub
	self:_spawnHubPlaceholders()
	
	Logger:Info("HubService", "Hub setup complete with NPC placeholders")
	
	-- Listen for Tom Nook interactions
	local talkToNookRemote = remotes:Get("TalkToTomNook")
	if talkToNookRemote then
		talkToNookRemote.OnServerEvent:Connect(function(player)
			self:_handleTomNookInteraction(player)
		end)
	end
	
	return self
end

--[[
	Build the main hub/plaza where players first spawn
]]
function HubService:_buildHub()
	self._hubFolder = Instance.new("Folder")
	self._hubFolder.Name = "MainHub"
	self._hubFolder.Parent = game.Workspace
	
	-- Main platform (large, safe area)
	local platform = Instance.new("Part")
	platform.Name = "HubPlatform"
	platform.Size = Vector3.new(HUB_CONFIG.HUB_SIZE, 2, HUB_CONFIG.HUB_SIZE)
	platform.Position = HUB_CONFIG.SPAWN_POSITION
	platform.Anchored = true
	platform.Material = Enum.Material.Marble
	platform.Color = Color3.fromRGB(245, 245, 220)  -- Beige/cream
	platform.CanCollide = true
	platform.Parent = self._hubFolder
	
	-- Decorative border
	local border = Instance.new("Part")
	border.Name = "PlatformBorder"
	border.Size = Vector3.new(HUB_CONFIG.HUB_SIZE + 4, 4, HUB_CONFIG.HUB_SIZE + 4)
	border.Position = HUB_CONFIG.SPAWN_POSITION - Vector3.new(0, 2, 0)
	border.Anchored = true
	border.Material = Enum.Material.Brick
	border.Color = Color3.fromRGB(139, 90, 43)  -- Brown brick
	border.CanCollide = true
	border.Parent = self._hubFolder
	
	-- Welcome sign
	local sign = Instance.new("Part")
	sign.Name = "WelcomeSign"
	sign.Size = Vector3.new(20, 10, 2)
	sign.Position = HUB_CONFIG.SPAWN_POSITION + Vector3.new(0, 7, -30)
	sign.Anchored = true
	sign.Material = Enum.Material.Wood
	sign.Color = Color3.fromRGB(101, 67, 33)
	sign.CanCollide = false
	sign.Parent = self._hubFolder
	
	-- Sign text
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back
	signGui.Parent = sign
	
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "🏝️\n\nWELCOME TO\nNOOK INC.\n\nTalk to Tom Nook\nto start your island!"
	signText.TextSize = 48
	signText.Font = Enum.Font.GothamBold
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.TextStrokeTransparency = 0.5
	signText.Parent = signGui
	
	-- Player spawn location (front-center of platform)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "HubSpawn"
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = HUB_CONFIG.SPAWN_POSITION + Vector3.new(0, 1.5, 30)  -- Front of platform
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = true
	spawnLocation.Transparency = 0.5
	spawnLocation.BrickColor = BrickColor.new("Bright green")
	spawnLocation.Parent = self._hubFolder
	
	Logger:Info("HubService", "Main hub/plaza built at Y=50 with spawn location")
end

-- Build enhanced hub with decorations
function HubService:_buildEnhancedHub()
	-- Call original _buildHub
	self:_buildHub()
	
	-- Add decorative trees at corners
	local center = HUB_CONFIG.SPAWN_POSITION
	self:_addHubTree(center + Vector3.new(-60, 2, -60), self._hubFolder)
	self:_addHubTree(center + Vector3.new(60, 2, -60), self._hubFolder)
	self:_addHubTree(center + Vector3.new(-60, 2, 60), self._hubFolder)
	self:_addHubTree(center + Vector3.new(60, 2, 60), self._hubFolder)
	
	-- Add flower decorations
	for i = 1, 20 do
		local angle = (i / 20) * math.pi * 2
		local distance = 40
		local flowerPos = center + Vector3.new(
			math.cos(angle) * distance,
			2.5,
			math.sin(angle) * distance
		)
		self:_addFlower(flowerPos, self._hubFolder)
	end
end

-- Add tree decoration
function HubService:_addHubTree(position, parent)
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	tree.Parent = parent
	
	local trunk = Instance.new("Part")
	trunk.Size = Vector3.new(2, 8, 2)
	trunk.Material = Enum.Material.Wood
	trunk.Color = Color3.fromRGB(101, 67, 33)
	trunk.Anchored = true
	trunk.Position = position + Vector3.new(0, 4, 0)
	trunk.Parent = tree
	
	local foliage = Instance.new("Part")
	foliage.Size = Vector3.new(10, 10, 10)
	foliage.Shape = Enum.PartType.Ball
	foliage.Material = Enum.Material.Grass
	foliage.Color = Color3.fromRGB(34, 139, 34)
	foliage.Anchored = true
	foliage.CanCollide = false
	foliage.Position = position + Vector3.new(0, 10, 0)
	foliage.Parent = tree
	
	return tree
end

-- Add flower decoration
function HubService:_addFlower(position, parent)
	local flower = Instance.new("Part")
	flower.Name = "Flower"
	flower.Size = Vector3.new(1, 2, 1)
	flower.Material = Enum.Material.Neon
	flower.Color = Color3.fromRGB(255, math.random(100, 200), math.random(100, 200))
	flower.Anchored = true
	flower.CanCollide = false
	flower.Position = position
	flower.Parent = parent
	
	return flower
end

-- Spawn placeholder NPCs at hub
function HubService:_spawnHubPlaceholders()
	local NPCPlaceholderSpawner = require(script.Parent.NPCPlaceholderSpawner)
	if not NPCPlaceholderSpawner then
		Logger:Warn("HubService", "NPCPlaceholderSpawner not found")
		return
	end
	
	local spawner = NPCPlaceholderSpawner.new()
	local hubPlatform = self._hubFolder:FindFirstChild("HubPlatform")
	
	if hubPlatform then
		spawner:CreateHubNPCs(hubPlatform)
		Logger:Info("HubService", "✅ Hub NPC placeholders spawned (Tom Nook, Isabelle, Orville)")
	else
		Logger:Warn("HubService", "Hub platform not found for NPC spawning")
	end
end

--[[
	Spawn Tom Nook NPC in the hub
]]
function HubService:_spawnTomNook()
	local model = Instance.new("Model")
	model.Name = "TomNook"
	model.Parent = self._hubFolder
	
	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 5, 2)
	body.Position = HUB_CONFIG.TOM_NOOK_POSITION
	body.Anchored = true
	body.Material = Enum.Material.Neon
	body.Color = Color3.fromRGB(139, 90, 43)  -- Brown (raccoon color)
	body.CanCollide = false
	body.Parent = model
	
	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.5, 2.5, 2.5)
	head.Position = HUB_CONFIG.TOM_NOOK_POSITION + Vector3.new(0, 3.5, 0)
	head.Anchored = true
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(139, 90, 43)
	head.CanCollide = false
	head.Parent = model
	
	-- Desk
	local desk = Instance.new("Part")
	desk.Name = "Desk"
	desk.Size = Vector3.new(6, 3, 4)
	desk.Position = HUB_CONFIG.TOM_NOOK_POSITION + Vector3.new(0, -3, 2)
	desk.Anchored = true
	desk.Material = Enum.Material.Wood
	desk.Color = Color3.fromRGB(101, 67, 33)
	desk.CanCollide = true
	desk.Parent = model
	
	-- Name tag
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = head
	billboard.Size = UDim2.new(6, 0, 2, 0)
	billboard.MaxDistance = 50
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Parent = head
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "🦝 Tom Nook\n💼 Island Services"
	nameLabel.TextSize = 24
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)  -- Gold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboard
	
	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Tom Nook"
	prompt.ActionText = "Talk & Create Island"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	
	prompt.Triggered:Connect(function(player)
		self:_handleTomNookInteraction(player)
	end)
	
	model.PrimaryPart = body
	self._tomNookModel = model
	
	Logger:Info("HubService", "Tom Nook spawned in hub")
end

--[[
	Handle player interaction with Tom Nook
]]
function HubService:_handleTomNookInteraction(player)
	Logger:Info("HubService", "Player talking to Tom Nook", { playerId = player.UserId })
	
	-- Check if player already has an island
	if self._playerIslandStates[player.UserId] then
		-- Player has an island, offer to return
		local dialogueRemote = self._remotes:Get("ShowDialogue")
		if dialogueRemote then
			dialogueRemote:FireClient(player, {
				villagerName = "Tom Nook",
				text = "Welcome back! Would you like to return to your island?",
				color = "light",
				nameTagColor = "blue",
				continueButton = false
			})
		end
		
		-- Teleport back to island after brief delay
		task.delay(2, function()
			local teleportRemote = self._remotes:Get("TeleportToIsland")
			if teleportRemote then
				teleportRemote:FireClient(player)
			end
		end)
	else
		-- First-time island creation flow at hub via Tom Nook
		local openIslandCreationRemote = self._remotes:Get("OpenIslandCreationGUI")
		if openIslandCreationRemote then
			openIslandCreationRemote:FireClient(player)
			print("[HubService] Island creation flow started via hub Tom Nook for:", player.Name)
			return
		end
		
		-- Fallback: Isabelle greeting path
		Logger:Info("TomNookSpawner", "Player has no island; showing Isabelle greeting", { playerId = player.UserId })
		local dialogueRemote = self._remotes:Get("ShowDialogue")
		if dialogueRemote then
			dialogueRemote:FireClient(player, {
				villagerName = "Isabelle",
				text = "Oh my goodness, welcome! I'm Isabelle, the island representative! I can help you set up your very own personal island right away - completely free of charge! Ready to get started?",
				color = "light",
				nameTagColor = "yellow",
				continueButton = true
			})
		end
		
		-- After a brief delay, open the onboarding GUI
		task.delay(1.5, function()
			Logger:Info("TomNookSpawner", "Opening onboarding GUI for player", { playerId = player.UserId })
			local openGuiRemote = self._remotes:Get("OpenOnboardingGUI")
			openGuiRemote:FireClient(player)
		end)
	end
end

--[[
	Mark that a player has generated their island
]]
function HubService:MarkIslandGenerated(player)
	self._playerIslandStates[player.UserId] = true
	Logger:Info("HubService", "Player island marked as generated", { playerId = player.UserId })
end

--[[
	Get hub spawn position
]]
function HubService:GetSpawnPosition()
	return HUB_CONFIG.SPAWN_POSITION + Vector3.new(0, 3, 0)
end

function HubService:Destroy()
	Logger:Info("HubService", "Destroying")
	if self._hubFolder then
		self._hubFolder:Destroy()
	end
	self._playerIslandStates = {}
end

return HubService

