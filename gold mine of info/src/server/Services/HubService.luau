--[[
	HubService - Creates and manages the main hub area
	Handles hub creation, NPCs, and player spawn
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Local = {}
local Shared = {}

-- Hub references
local hubFolder = nil
local npcsFolder = nil

function Local.CreateHub()
	print("[HubService] Creating Animal Crossing hub...")
	
	-- Create hub folder
	hubFolder = Instance.new("Folder")
	hubFolder.Name = "Hub"
	hubFolder.Parent = workspace
	
	-- Create hub platform
	local platform = Instance.new("Part")
	platform.Name = "HubPlatform"
	platform.Size = Vector3.new(200, 4, 200)
	platform.Position = Vector3.new(0, 0, 0)
	platform.Material = Enum.Material.Grass
	platform.BrickColor = BrickColor.new("Bright green")
	platform.Anchored = true
	platform.Parent = hubFolder
	
	-- Create spawn location
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Size = Vector3.new(4, 1, 4)
	spawn.Position = Vector3.new(0, 2, 0)
	spawn.BrickColor = BrickColor.new("Bright yellow")
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = hubFolder
	
	-- Create NPCs folder
	npcsFolder = Instance.new("Folder")
	npcsFolder.Name = "HubNPCs"
	npcsFolder.Parent = hubFolder
	
	-- Create NPCs
	Local.CreateNPCs()
	
	-- Create decorations
	Local.CreateDecorations()
	
	-- Set up lighting
	Local.SetupLighting()
	
	print("[HubService] Hub created successfully!")
end

function Local.CreateNPCs()
	-- Tom Nook (center)
	Local.CreateNPC("Tom Nook", Vector3.new(0, 4, 0), 0, "🦝")
	
	-- Isabelle (south)
	Local.CreateNPC("Isabelle", Vector3.new(0, 4, -60), 0, "🐕")
	
	-- Orville (north)
	Local.CreateNPC("Orville", Vector3.new(0, 4, 60), 180, "🦆")
	
	-- Blathers (east)
	Local.CreateNPC("Blathers", Vector3.new(60, 4, 0), 270, "🦉")
	
	-- Timmy & Tommy (southwest)
	Local.CreateNPC("Timmy", Vector3.new(-40, 4, -40), 45, "🐭")
	Local.CreateNPC("Tommy", Vector3.new(-20, 4, -40), 45, "🐭")
end

function Local.CreateNPC(name: string, position: Vector3, rotation: number, emoji: string)
	local npc = Instance.new("Part")
	npc.Name = name
	npc.Size = Vector3.new(2, 4, 2)
	npc.Position = position
	npc.Rotation = Vector3.new(0, rotation, 0)
	npc.Material = Enum.Material.Neon
	npc.BrickColor = BrickColor.new("Bright blue")
	npc.CanCollide = false
	npc.Anchored = true
	npc.Parent = npcsFolder
	
	-- Add ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk to " .. name
	prompt.MaxActivationDistance = 10
	prompt.Parent = npc
	
	-- Add emoji label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 50, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = npc
	
	local emojiLabel = Instance.new("TextLabel")
	emojiLabel.Size = UDim2.new(1, 0, 1, 0)
	emojiLabel.BackgroundTransparency = 1
	emojiLabel.Text = emoji
	emojiLabel.TextScaled = true
	emojiLabel.Font = Enum.Font.GothamBold
	emojiLabel.Parent = billboard
	
	-- Handle interaction
	prompt.Triggered:Connect(function(player)
		Local.HandleNPCInteraction(player, name)
	end)
	
	print(`[HubService] Created NPC: {name} at {position}`)
end

function Local.HandleNPCInteraction(player: Player, npcName: string)
	print(`[HubService] {player.Name} interacted with {npcName}`)
	
	-- Handle different NPCs
	if npcName == "Tom Nook" then
		Local.HandleTomNookInteraction(player)
	elseif npcName == "Isabelle" then
		Local.HandleIsabelleInteraction(player)
	elseif npcName == "Orville" then
		Local.HandleOrvilleInteraction(player)
	elseif npcName == "Blathers" then
		Local.HandleBlathersInteraction(player)
	elseif npcName == "Timmy" or npcName == "Tommy" then
		Local.HandleShopInteraction(player)
	end
end

function Local.HandleTomNookInteraction(player: Player)
	print(`[HubService] Tom Nook interaction with {player.Name}`)
	
	-- Fire remote to start onboarding
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if remotes then
		local startRemote = remotes:WaitForChild("StartOnboarding", 5)
		if startRemote then
			startRemote:FireClient(player)
		end
	end
end

function Local.HandleIsabelleInteraction(player: Player)
	print(`[HubService] Isabelle interaction with {player.Name}`)
	-- TODO: Implement Isabelle dialogue
end

function Local.HandleOrvilleInteraction(player: Player)
	print(`[HubService] Orville interaction with {player.Name}`)
	-- TODO: Implement travel system
end

function Local.HandleBlathersInteraction(player: Player)
	print(`[HubService] Blathers interaction with {player.Name}`)
	-- TODO: Implement museum system
end

function Local.HandleShopInteraction(player: Player)
	print(`[HubService] Shop interaction with {player.Name}`)
	-- TODO: Implement shop system
end

function Local.CreateDecorations()
	-- Create trees around the hub
	for i = 1, 8 do
		local angle = (i - 1) * 45
		local x = math.cos(math.rad(angle)) * 80
		local z = math.sin(math.rad(angle)) * 80
		
		Local.CreateTree(Vector3.new(x, 4, z))
	end
	
	-- Create flowers
	for i = 1, 12 do
		local angle = (i - 1) * 30
		local x = math.cos(math.rad(angle)) * 60
		local z = math.sin(math.rad(angle)) * 60
		
		Local.CreateFlower(Vector3.new(x, 1, z))
	end
end

function Local.CreateTree(position: Vector3)
	local tree = Instance.new("Part")
	tree.Name = "Tree"
	tree.Size = Vector3.new(2, 8, 2)
	tree.Position = position
	tree.Material = Enum.Material.Wood
	tree.BrickColor = BrickColor.new("Brown")
	tree.Anchored = true
	tree.Parent = hubFolder
	
	-- Tree top
	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Size = Vector3.new(6, 6, 6)
	leaves.Position = position + Vector3.new(0, 4, 0)
	leaves.Material = Enum.Material.Grass
	leaves.BrickColor = BrickColor.new("Bright green")
	leaves.Shape = Enum.PartType.Ball
	leaves.Anchored = true
	leaves.Parent = tree
end

function Local.CreateFlower(position: Vector3)
	local flower = Instance.new("Part")
	flower.Name = "Flower"
	flower.Size = Vector3.new(1, 2, 1)
	flower.Position = position
	flower.Material = Enum.Material.Neon
	flower.BrickColor = BrickColor.new("Bright red")
	flower.Shape = Enum.PartType.Cylinder
	flower.Anchored = true
	flower.Parent = hubFolder
end

function Local.SetupLighting()
	-- Set up Animal Crossing-style lighting
	Lighting.Ambient = Color3.fromRGB(135, 206, 235)  -- Sky blue
	Lighting.Brightness = 2
	Lighting.ClockTime = 10  -- 10 AM
	Lighting.GeographicLatitude = 40.7  -- New York latitude
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	Lighting.ShadowSoftness = 0.2
	Lighting.TimeOfDay = "10:00:00"
	
	-- Create warm atmosphere
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 0.1
	colorCorrection.Contrast = 0.1
	colorCorrection.Saturation = 0.2
	colorCorrection.TintColor = Color3.fromRGB(255, 248, 220)  -- Warm tint
	colorCorrection.Parent = Lighting
	
	print("[HubService] Animal Crossing lighting setup complete!")
end

function Shared.OnStart()
	print("[HubService] Starting Animal Crossing HubService...")
	
	-- Create the hub
	Local.CreateHub()
end

return Shared
