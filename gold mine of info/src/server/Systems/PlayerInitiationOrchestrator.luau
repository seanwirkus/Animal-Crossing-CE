-- Player Initiation Orchestrator
-- Coordinates Tom Nook, Isabelle, Orville, and other NPCs to facilitate island creation, home setup, and services
local PlayerInitiationOrchestrator = {}
PlayerInitiationOrchestrator.__index = PlayerInitiationOrchestrator

-- Initiation stages
local InitiationStage = {
	NEW_PLAYER = "new_player",               -- First time joining
	HUB_WELCOME = "hub_welcome",             -- Welcome at hub by Isabelle
	AIRPORT_INTRO = "airport_intro",         -- Orville introduces airport
	ISLAND_CREATION = "island_creation",     -- Tom Nook helps create island
	ISLAND_ARRIVAL = "island_arrival",       -- First arrival on island
	HOME_SELECTION = "home_selection",       -- Tom Nook helps pick home location
	HOME_SETUP = "home_setup",               -- Tom Nook sets up tent/starter home
	TUTORIAL_QUEST = "tutorial_quest",       -- First fishing quest
	SERVICES_INTRO = "services_intro",       -- Isabelle introduces island services
	MUSEUM_INTRO = "museum_intro",           -- Blathers offers museum
	SHOP_INTRO = "shop_intro",               -- Timmy & Tommy open shop
	COMPLETED = "completed"                  -- Initiation complete
}

function PlayerInitiationOrchestrator.new(remotes, characterDB)
	local self = setmetatable({}, PlayerInitiationOrchestrator)
	self._remotes = remotes
	self._characterDB = characterDB
	self._playerStages = {} -- Track each player's current stage
	return self
end

-- Get player's current initiation stage
function PlayerInitiationOrchestrator:GetPlayerStage(userId)
	return self._playerStages[userId] or InitiationStage.NEW_PLAYER
end

-- Set player's initiation stage
function PlayerInitiationOrchestrator:SetPlayerStage(userId, stage)
	self._playerStages[userId] = stage
	print(string.format("[Initiation] Player %d advanced to stage: %s", userId, stage))
end

-- Start the initiation process for a new player
function PlayerInitiationOrchestrator:BeginInitiation(player)
	local userId = player.UserId
	local currentStage = self:GetPlayerStage(userId)
	
	if currentStage == InitiationStage.NEW_PLAYER then
		self:_stageHubWelcome(player)
	end
end

-- STAGE 1: Hub Welcome by Isabelle
function PlayerInitiationOrchestrator:_stageHubWelcome(player)
	local userId = player.UserId
	self:SetPlayerStage(userId, InitiationStage.HUB_WELCOME)
	
	-- Get Isabelle's info
	local isabelle = self._characterDB:GetCharacterInfo("Isabelle")
	
	-- Show dialogue from Isabelle
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = isabelle.name,
			text = string.format("Welcome to %s! I'm %s, and I'll be helping you get settled. %s", 
				"Nook Inc. Hub", isabelle.name, isabelle.quote),
			color = "light",
			nameTagColor = "yellow",
			continueButton = true
		})
		
		task.delay(2, function()
			dialogueRemote:FireClient(player, {
				villagerName = isabelle.name,
				text = "Would you like to create your very own island getaway? Tom Nook can help you get started!",
				color = "light",
				nameTagColor = "yellow",
				continueButton = true
			})
		end)
	end
	
	-- Move to Tom Nook interaction stage
	task.delay(4, function()
		self:SetPlayerStage(userId, InitiationStage.ISLAND_CREATION)
	end)
end

-- STAGE 2: Island Creation with Tom Nook
function PlayerInitiationOrchestrator:StartIslandCreation(player)
	local userId = player.UserId
	local tomNook = self._characterDB:GetCharacterInfo("Tom Nook")
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = tomNook.name,
			text = string.format("%s Interested in a deserted island getaway package? Let me walk you through the details!", tomNook.quote),
			color = "warm",
			nameTagColor = "orange",
			continueButton = true
		})
		
		task.delay(2, function()
			dialogueRemote:FireClient(player, {
				villagerName = tomNook.name,
				text = "This package includes a beautiful island, a starter tent, and all the essentials! Ready to begin?",
				color = "warm",
				nameTagColor = "orange",
				continueButton = true
			})
		end)
	end
	
	-- Open island creation GUI
	task.delay(4, function()
		local openGuiRemote = self._remotes:Get("OpenIslandCreationGUI")
		if openGuiRemote then
			openGuiRemote:FireClient(player)
		end
	end)
end

-- STAGE 3: Island Arrival with Orville
function PlayerInitiationOrchestrator:OnIslandCreated(player, islandData)
	local userId = player.UserId
	self:SetPlayerStage(userId, InitiationStage.AIRPORT_INTRO)
	
	local orville = self._characterDB:GetCharacterInfo("Orville")
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = orville.name,
			text = string.format("%s Your island is ready for departure! Let's get you to your new home!", orville.quote),
			color = "cool",
			nameTagColor = "blue",
			continueButton = true
		})
	end
	
	-- Transition to island arrival
	task.delay(3, function()
		self:SetPlayerStage(userId, InitiationStage.ISLAND_ARRIVAL)
		self:_stageIslandArrival(player)
	end)
end

-- STAGE 4: Island Arrival
function PlayerInitiationOrchestrator:_stageIslandArrival(player)
	local userId = player.UserId
	
	-- Tom Nook and Isabelle greet on island
	local tomNook = self._characterDB:GetCharacterInfo("Tom Nook")
	local isabelle = self._characterDB:GetCharacterInfo("Isabelle")
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = tomNook.name,
			text = "Welcome to your island! Let's find the perfect spot for your home.",
			color = "warm",
			nameTagColor = "orange",
			continueButton = true
		})
		
		task.delay(3, function()
			self:SetPlayerStage(userId, InitiationStage.HOME_SELECTION)
			self:_stageHomeSelection(player)
		end)
	end
end

-- STAGE 5: Home Selection
function PlayerInitiationOrchestrator:_stageHomeSelection(player)
	local userId = player.UserId
	local tomNook = self._characterDB:GetCharacterInfo("Tom Nook")
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = tomNook.name,
			text = "I'll set up a cozy tent for you right here at the plaza! It's a perfect starter home.",
			color = "warm",
			nameTagColor = "orange",
			continueButton = true
		})
	end
	
	-- Setup home automatically
	task.delay(2, function()
		self:_stageHomeSetup(player)
	end)
end

-- STAGE 6: Home Setup
function PlayerInitiationOrchestrator:_stageHomeSetup(player)
	local userId = player.UserId
	self:SetPlayerStage(userId, InitiationStage.HOME_SETUP)
	
	local tomNook = self._characterDB:GetCharacterInfo("Tom Nook")
	
	-- Create starter tent/home (this would call your home service)
	-- For now, just show dialogue
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = tomNook.name,
			text = "There we go! Your tent is all set up. Now, let's help you learn the basics!",
			color = "warm",
			nameTagColor = "orange",
			continueButton = true
		})
	end
	
	-- Move to tutorial
	task.delay(3, function()
		self:_stageTutorialQuest(player)
	end)
end

-- STAGE 7: Tutorial Quest (Fishing)
function PlayerInitiationOrchestrator:_stageTutorialQuest(player)
	local userId = player.UserId
	self:SetPlayerStage(userId, InitiationStage.TUTORIAL_QUEST)
	
	local tomNook = self._characterDB:GetCharacterInfo("Tom Nook")
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = tomNook.name,
			text = "Here's a fishing rod! Try catching 3 fish - they're great for selling or donating to the museum!",
			color = "warm",
			nameTagColor = "orange",
			continueButton = true
		})
	end
	
	-- Give fishing rod and start quest
	-- (This would integrate with your existing FishingQuest system)
end

-- STAGE 8: Services Introduction by Isabelle
function PlayerInitiationOrchestrator:OnTutorialComplete(player)
	local userId = player.UserId
	self:SetPlayerStage(userId, InitiationStage.SERVICES_INTRO)
	
	local isabelle = self._characterDB:GetCharacterInfo("Isabelle")
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = isabelle.name,
			text = "Great job! Now let me tell you about all the services available on your island!",
			color = "light",
			nameTagColor = "yellow",
			continueButton = true
		})
		
		task.delay(2, function()
			dialogueRemote:FireClient(player, {
				villagerName = isabelle.name,
				text = "You can upgrade your home, invite villagers, build bridges, and so much more! Check the Island Services menu anytime.",
				color = "light",
				nameTagColor = "yellow",
				continueButton = true
			})
		end)
	end
	
	-- Move to museum intro
	task.delay(5, function()
		self:_stageMuseumIntro(player)
	end)
end

-- STAGE 9: Museum Introduction by Blathers
function PlayerInitiationOrchestrator:_stageMuseumIntro(player)
	local userId = player.UserId
	self:SetPlayerStage(userId, InitiationStage.MUSEUM_INTRO)
	
	local blathers = self._characterDB:GetCharacterInfo("Blathers")
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = blathers.name,
			text = string.format("%s I'm Blathers, curator of the museum! Donate fish, bugs, and fossils to help fill our collection!", blathers.quote),
			color = "cool",
			nameTagColor = "purple",
			continueButton = true
		})
	end
	
	-- Move to shop intro
	task.delay(3, function()
		self:_stageShopIntro(player)
	end)
end

-- STAGE 10: Shop Introduction by Timmy & Tommy
function PlayerInitiationOrchestrator:_stageShopIntro(player)
	local userId = player.UserId
	self:SetPlayerStage(userId, InitiationStage.SHOP_INTRO)
	
	local timmy = self._characterDB:GetCharacterInfo("Timmy")
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = "Timmy & Tommy",
			text = string.format("%s Welcome to Nook's Cranny! We sell furniture, tools, and more!", timmy.quote),
			color = "warm",
			nameTagColor = "green",
			continueButton = true
		})
	end
	
	-- Complete initiation
	task.delay(3, function()
		self:CompleteInitiation(player)
	end)
end

-- STAGE 11: Initiation Complete
function PlayerInitiationOrchestrator:CompleteInitiation(player)
	local userId = player.UserId
	self:SetPlayerStage(userId, InitiationStage.COMPLETED)
	
	local isabelle = self._characterDB:GetCharacterInfo("Isabelle")
	
	local dialogueRemote = self._remotes:Get("ShowDialogue")
	if dialogueRemote then
		dialogueRemote:FireClient(player, {
			villagerName = isabelle.name,
			text = "Congratulations! Your island life has officially begun! Have fun building your dream island! 🎉",
			color = "light",
			nameTagColor = "yellow",
			continueButton = true
		})
	end
	
	print(string.format("[Initiation] Player %s (%d) completed initiation!", player.Name, userId))
	
	-- Fire completion event for any listeners
	local completionRemote = self._remotes:Get("OnInitiationComplete")
	if completionRemote then
		completionRemote:FireClient(player)
	end
end

-- Check if player has completed initiation
function PlayerInitiationOrchestrator:HasCompletedInitiation(userId)
	return self:GetPlayerStage(userId) == InitiationStage.COMPLETED
end

-- Get character dialogue for current stage
function PlayerInitiationOrchestrator:GetStageDialogue(userId)
	local stage = self:GetPlayerStage(userId)
	
	-- Return character and dialogue based on stage
	local dialogues = {
		[InitiationStage.HUB_WELCOME] = {
			character = "Isabelle",
			text = "Welcome! Ready to start your island adventure?"
		},
		[InitiationStage.ISLAND_CREATION] = {
			character = "Tom Nook",
			text = "Let's get your island set up!"
		},
		[InitiationStage.AIRPORT_INTRO] = {
			character = "Orville",
			text = "All aboard for your island!"
		},
		-- Add more as needed
	}
	
	return dialogues[stage]
end

return PlayerInitiationOrchestrator

