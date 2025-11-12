--[[
	OnboardingService.luau
	
	Server-side onboarding/tutorial management.
	Tracks player tutorial progress and handles home building.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OnboardingService = {}
OnboardingService.__index = OnboardingService

function OnboardingService.new()
	local self = setmetatable({}, OnboardingService)
	
	self.playerIslandService = nil -- Will be set during init
	
	return self
end

function OnboardingService:initialize(playerIslandService)
	print("[OnboardingService] 📚 Initializing...")
	
	self.playerIslandService = playerIslandService
	
	-- Setup remotes
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	
	-- Start onboarding remote (server -> client)
	local startOnboardingRemote = remotes:FindFirstChild("StartOnboarding")
	if not startOnboardingRemote then
		startOnboardingRemote = Instance.new("RemoteEvent")
		startOnboardingRemote.Name = "StartOnboarding"
		startOnboardingRemote.Parent = remotes
	end
	self.startOnboardingRemote = startOnboardingRemote
	
	-- Tutorial complete remote (client -> server)
	local tutorialCompleteRemote = remotes:FindFirstChild("TutorialComplete")
	if not tutorialCompleteRemote then
		tutorialCompleteRemote = Instance.new("RemoteEvent")
		tutorialCompleteRemote.Name = "TutorialComplete"
		tutorialCompleteRemote.Parent = remotes
	end
	
	tutorialCompleteRemote.OnServerEvent:Connect(function(player)
		self:onTutorialComplete(player)
	end)
	
	-- Build home remote (client -> server)
	local buildHomeRemote = remotes:FindFirstChild("BuildPlayerHome")
	if not buildHomeRemote then
		buildHomeRemote = Instance.new("RemoteEvent")
		buildHomeRemote.Name = "BuildPlayerHome"
		buildHomeRemote.Parent = remotes
	end
	
	buildHomeRemote.OnServerEvent:Connect(function(player)
		self:buildPlayerHome(player)
	end)
	
	-- Listen for new players
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerJoined(player)
	end)
	
	print("[OnboardingService] ✅ Initialized")
end

function OnboardingService:onPlayerJoined(player)
	-- Wait a moment for island to be created
	task.wait(2)
	
	-- Check if player needs tutorial
	if self.playerIslandService then
		local islandData = self.playerIslandService:getPlayerIsland(player.UserId)
		
		if islandData and not islandData.hasCompletedTutorial then
			print(string.format("[OnboardingService] Starting tutorial for %s", player.Name))
			self:startTutorial(player)
		end
	end
end

function OnboardingService:startTutorial(player)
	-- Fire client event to start tutorial UI
	self.startOnboardingRemote:FireClient(player)
	
	print(string.format("[OnboardingService] Tutorial started for %s", player.Name))
end

function OnboardingService:onTutorialComplete(player)
	print(string.format("[OnboardingService] Tutorial completed by %s", player.Name))
	
	-- Mark tutorial as complete in island data
	if self.playerIslandService then
		local islandData = self.playerIslandService:getPlayerIsland(player.UserId)
		
		if islandData then
			islandData.hasCompletedTutorial = true
			self.playerIslandService:saveIsland(player.UserId, islandData)
		end
	end
	
	-- Give starter items/currency as reward
	self:giveStarterRewards(player)
end

function OnboardingService:giveStarterRewards(player)
	-- Give starting bells and miles
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local currencyRemote = remotes:FindFirstChild("CurrencyUpdate")
		if currencyRemote then
			-- Award 1000 bells and 500 miles for completing tutorial
			currencyRemote:FireClient(player, "Grant", {bells = 1000, miles = 500})
		end
	end
	
	print(string.format("[OnboardingService] Gave starter rewards to %s", player.Name))
end

function OnboardingService:buildPlayerHome(player)
	print(string.format("[OnboardingService] Building home for %s", player.Name))
	
	if not self.playerIslandService then
		warn("[OnboardingService] PlayerIslandService not available")
		return
	end
	
	local islandData = self.playerIslandService:getPlayerIsland(player.UserId)
	if not islandData then
		warn(string.format("[OnboardingService] No island data for %s", player.Name))
		return
	end
	
	-- Check if home already exists
	if islandData.hasBuiltHome then
		print(string.format("[OnboardingService] %s already has a home", player.Name))
		return
	end
	
	-- Get island center
	local center = Vector3.new(islandData.center.X, islandData.center.Y, islandData.center.Z)
	
	-- Place home near center (offset to the side)
	local homePosition = center + Vector3.new(-15, 20, 0)
	
	-- Raycast to find terrain
	local ray = workspace:Raycast(homePosition + Vector3.new(0, 100, 0), Vector3.new(0, -200, 0))
	if ray then
		homePosition = ray.Position + Vector3.new(0, 0.5, 0)
	end
	
	-- Get island folder
	local islandFolder = self.playerIslandService:getPlayerIslandFolder(player.UserId)
	if not islandFolder then
		warn(string.format("[OnboardingService] No island folder for %s", player.Name))
		return
	end
	
	-- Create buildings folder if it doesn't exist
	local buildingsFolder = islandFolder:FindFirstChild("Buildings")
	if not buildingsFolder then
		buildingsFolder = Instance.new("Folder")
		buildingsFolder.Name = "Buildings"
		buildingsFolder.Parent = islandFolder
	end
	
	-- Try to get tent template from ReplicatedStorage
	local tentTemplate = ReplicatedStorage:FindFirstChild("TentHouse")
	
	if tentTemplate and tentTemplate:IsA("Model") then
		local tent = tentTemplate:Clone()
		tent:SetPrimaryPartCFrame(CFrame.new(homePosition))
		
		-- Anchor all parts
		for _, part in ipairs(tent:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
		
		tent.Parent = buildingsFolder
		print(string.format("[OnboardingService] ✅ Placed tent home for %s", player.Name))
	else
		-- Fallback: Create simple tent
		local tent = self:createSimpleTent(homePosition)
		tent.Parent = buildingsFolder
		print(string.format("[OnboardingService] ✅ Created simple tent for %s", player.Name))
	end
	
	-- Update island data
	table.insert(islandData.buildings, {
		type = "TentHouse",
		X = homePosition.X,
		Y = homePosition.Y,
		Z = homePosition.Z,
		rotation = 0,
	})
	
	islandData.hasBuiltHome = true
	self.playerIslandService:saveIsland(player.UserId, islandData)
end

function OnboardingService:createSimpleTent(position)
	local tent = Instance.new("Model")
	tent.Name = "TentHouse"
	
	-- Tent body (triangular prism shape)
	local body = Instance.new("WedgePart")
	body.Name = "TentBody"
	body.Size = Vector3.new(8, 6, 6)
	body.Position = position + Vector3.new(0, 3, 0)
	body.Orientation = Vector3.new(0, 0, 0)
	body.Anchored = true
	body.Material = Enum.Material.Fabric
	body.BrickColor = BrickColor.new("Bright red")
	body.Parent = tent
	
	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(8, 0.5, 6)
	floor.Position = position
	floor.Anchored = true
	floor.Material = Enum.Material.Wood
	floor.BrickColor = BrickColor.new("Brown")
	floor.Parent = tent
	
	-- Door (entrance)
	local door = Instance.new("Part")
	door.Name = "Door"
	door.Size = Vector3.new(2, 4, 0.2)
	door.Position = position + Vector3.new(0, 2, -3)
	door.Anchored = true
	door.Material = Enum.Material.Fabric
	door.BrickColor = BrickColor.new("Dark orange")
	door.Parent = tent
	
	tent.PrimaryPart = floor
	
	return tent
end

return OnboardingService

