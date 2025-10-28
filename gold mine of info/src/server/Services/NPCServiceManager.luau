-- NPC Service Manager
-- Coordinates services provided by each special character
local NPCServiceManager = {}
NPCServiceManager.__index = NPCServiceManager

function NPCServiceManager.new(remotes, characterDB, playerIslandService, economy, inventory)
	local self = setmetatable({}, NPCServiceManager)
	self._remotes = remotes
	self._characterDB = characterDB
	self._playerIslandService = playerIslandService
	self._economy = economy
	self._inventory = inventory
	return self
end

-- TOM NOOK SERVICES
function NPCServiceManager:TomNookServices()
	return {
		-- Island Creation
		CreateIsland = function(player)
			local tomNook = self._characterDB:GetCharacterInfo("Tom Nook")
			print(string.format("[Tom Nook] %s is helping %s create an island", tomNook.name, player.Name))
			
			-- Trigger island creation
			if self._playerIslandService then
				self._playerIslandService:CreatePlayerIsland(player)
			end
		end,
		
		-- Home Upgrade
		UpgradeHome = function(player, upgradeLevel)
			local tomNook = self._characterDB:GetCharacterInfo("Tom Nook")
			print(string.format("[Tom Nook] Upgrading %s's home to level %d", player.Name, upgradeLevel))
			
			local costs = {
				[1] = {bells = 5000, description = "Tent → Small House"},
				[2] = {bells = 98000, description = "Small House → Medium House"},
				[3] = {bells = 198000, description = "Medium House → Large House"},
				[4] = {bells = 348000, description = "Large House → Villa"},
			}
			
			local cost = costs[upgradeLevel]
			if cost then
				-- Check if player can afford
				-- Apply upgrade
				-- This would integrate with your home service
				return true, cost
			end
			return false, nil
		end,
		
		-- Infrastructure
		BuildInfrastructure = function(player, structureType)
			local costs = {
				bridge = {bells = 98000, description = "Bridge Construction"},
				incline = {bells = 98000, description = "Incline Construction"},
				fountain = {bells = 50000, description = "Fountain"},
			}
			
			return costs[structureType]
		end,
	}
end

-- ISABELLE SERVICES
function NPCServiceManager:IsabelleServices()
	return {
		-- Island Evaluation
		EvaluateIsland = function(player)
			local isabelle = self._characterDB:GetCharacterInfo("Isabelle")
			print(string.format("[Isabelle] Evaluating %s's island", player.Name))
			
			-- Calculate island rating (1-5 stars)
			local rating = {
				stars = 3,
				feedback = "Your island is coming along nicely! Try planting more flowers and adding furniture.",
				improvements = {
					"Add 10 more flowers",
					"Place 5 pieces of furniture outside",
					"Invite 3 more villagers"
				}
			}
			
			return rating
		end,
		
		-- Change Island Flag
		ChangeFlag = function(player, flagDesign)
			local isabelle = self._characterDB:GetCharacterInfo("Isabelle")
			print(string.format("[Isabelle] Changing island flag for %s", player.Name))
			-- Apply flag design
			return true
		end,
		
		-- Change Island Tune
		ChangeTune = function(player, tuneNotes)
			local isabelle = self._characterDB:GetCharacterInfo("Isabelle")
			print(string.format("[Isabelle] Changing island tune for %s", player.Name))
			-- Apply tune
			return true
		end,
		
		-- Resident Complaint
		HandleComplaint = function(player, villagerName)
			local isabelle = self._characterDB:GetCharacterInfo("Isabelle")
			print(string.format("[Isabelle] Handling complaint about %s from %s", villagerName, player.Name))
			-- Handle villager removal or clothing reset
			return true
		end,
	}
end

-- ORVILLE SERVICES
function NPCServiceManager:OrvilleServices()
	return {
		-- Travel to Mystery Island
		MysteryIslandTour = function(player)
			local orville = self._characterDB:GetCharacterInfo("Orville")
			print(string.format("[Orville] %s is taking a mystery island tour!", player.Name))
			
			local cost = 2000 -- Nook Miles
			-- Check miles, deduct, teleport to mystery island
			return true, cost
		end,
		
		-- Visit Friend's Island
		VisitFriend = function(player, friendUserId)
			local orville = self._characterDB:GetCharacterInfo("Orville")
			print(string.format("[Orville] %s is visiting friend %d", player.Name, friendUserId))
			-- Teleport to friend's island
			return true
		end,
		
		-- Generate Dodo Code
		GenerateDodoCode = function(player)
			local orville = self._characterDB:GetCharacterInfo("Orville")
			local code = string.format("%05d", math.random(0, 99999))
			print(string.format("[Orville] Generated Dodo Code %s for %s", code, player.Name))
			return code
		end,
	}
end

-- BLATHERS SERVICES
function NPCServiceManager:BlathersServices()
	return {
		-- Donate Item
		DonateItem = function(player, itemType, itemName)
			local blathers = self._characterDB:GetCharacterInfo("Blathers")
			print(string.format("[Blathers] %s donated %s (%s)", player.Name, itemName, itemType))
			
			-- Add to museum collection
			-- Remove from player inventory
			-- Show acceptance dialogue
			
			local responses = {
				fish = "Ah, a splendid specimen! This will look wonderful in the aquarium!",
				bug = "Hoo! A bug! How... delightful. *shudders* I'll add it to the collection promptly.",
				fossil = "Ah yes, a magnificent fossil! Let me assess it for you.",
				art = "What a beautiful piece of art! If it's genuine, it will be a fine addition."
			}
			
			return true, responses[itemType] or blathers.quote
		end,
		
		-- Assess Fossil
		AssessFossil = function(player, fossilId)
			local blathers = self._characterDB:GetCharacterInfo("Blathers")
			print(string.format("[Blathers] Assessing fossil for %s", player.Name))
			
			-- Identify fossil
			local fossilName = "T-Rex Skull" -- Example
			return fossilName
		end,
	}
end

-- K.K. SLIDER SERVICES
function NPCServiceManager:KKSliderServices()
	return {
		-- Request Song
		RequestSong = function(player, songName)
			local kk = self._characterDB:GetCharacterInfo("K.K. Slider")
			print(string.format("[K.K. Slider] Playing '%s' for %s", songName, player.Name))
			
			-- Play song, give record to player
			return true
		end,
		
		-- Random Performance
		RandomPerformance = function(player)
			local kk = self._characterDB:GetCharacterInfo("K.K. Slider")
			local songs = {"K.K. Cruisin'", "K.K. Bubblegum", "K.K. Jazz", "Animal City"}
			local randomSong = songs[math.random(#songs)]
			
			print(string.format("[K.K. Slider] Random performance: '%s' for %s", randomSong, player.Name))
			return randomSong
		end,
	}
end

-- TIMMY & TOMMY SERVICES
function NPCServiceManager:NooksCrannyServices()
	return {
		-- Buy Item
		BuyItem = function(player, itemName, price)
			local timmy = self._characterDB:GetCharacterInfo("Timmy")
			print(string.format("[Timmy & Tommy] %s bought %s for %d bells", player.Name, itemName, price))
			
			-- Check bells, deduct, give item
			if self._economy then
				local success = self._economy:RemoveBells(player.UserId, price)
				if success and self._inventory then
					self._inventory:AddItem(player.UserId, itemName, 1)
					return true
				end
			end
			return false
		end,
		
		-- Sell Item
		SellItem = function(player, itemName, price)
			local tommy = self._characterDB:GetCharacterInfo("Tommy")
			print(string.format("[Timmy & Tommy] %s sold %s for %d bells", player.Name, itemName, price))
			
			-- Remove item, add bells
			if self._inventory then
				local success = self._inventory:RemoveItem(player.UserId, itemName, 1)
				if success and self._economy then
					self._economy:AddBells(player.UserId, price)
					return true
				end
			end
			return false
		end,
		
		-- Hot Item of the Day
		GetHotItem = function()
			local items = {"Wooden Chair", "Stone Axe", "Clay Furnace"}
			return items[math.random(#items)]
		end,
	}
end

-- CELESTE SERVICES
function NPCServiceManager:CelesteServices()
	return {
		-- Give Star DIY Recipe
		GiveStarRecipe = function(player)
			local celeste = self._characterDB:GetCharacterInfo("Celeste")
			print(string.format("[Celeste] Giving star recipe to %s", player.Name))
			
			local recipes = {"Star Wand", "Moon Chair", "Nova Light", "Crescent-Moon Chair"}
			local randomRecipe = recipes[math.random(#recipes)]
			
			-- Give recipe to player
			return randomRecipe
		end,
		
		-- Teach About Stars
		TeachAstronomy = function(player)
			local celeste = self._characterDB:GetCharacterInfo("Celeste")
			return string.format("%s Tonight is perfect for stargazing!", celeste.quote)
		end,
	}
end

-- LEIF SERVICES
function NPCServiceManager:LeifServices()
	return {
		-- Buy Plants
		BuyPlant = function(player, plantType, quantity)
			local leif = self._characterDB:GetCharacterInfo("Leif")
			print(string.format("[Leif] %s bought %d %s", player.Name, quantity, plantType))
			
			local prices = {
				flower = 240,
				shrub = 280,
				pumpkin = 140,
			}
			
			local totalCost = (prices[plantType] or 200) * quantity
			
			-- Process purchase
			return true, totalCost
		end,
		
		-- Weeding Service
		WeedingService = function(player)
			local leif = self._characterDB:GetCharacterInfo("Leif")
			print(string.format("[Leif] Removing weeds for %s", player.Name))
			
			-- Remove all weeds from island
			return true, 100000 -- Cost in bells
		end,
	}
end

-- KICKS SERVICES
function NPCServiceManager:KicksServices()
	return {
		-- Buy Shoes/Bags
		BuyAccessory = function(player, accessoryType, itemName, price)
			local kicks = self._characterDB:GetCharacterInfo("Kicks")
			print(string.format("[Kicks] %s bought %s for %d bells", player.Name, itemName, price))
			
			-- Process purchase
			return true
		end,
	}
end

-- Get all services for a character
function NPCServiceManager:GetServicesForCharacter(characterName)
	local services = {
		["Tom Nook"] = self:TomNookServices(),
		["Isabelle"] = self:IsabelleServices(),
		["Orville"] = self:OrvilleServices(),
		["Blathers"] = self:BlathersServices(),
		["K.K. Slider"] = self:KKSliderServices(),
		["Timmy"] = self:NooksCrannyServices(),
		["Tommy"] = self:NooksCrannyServices(),
		["Celeste"] = self:CelesteServices(),
		["Leif"] = self:LeifServices(),
		["Kicks"] = self:KicksServices(),
	}
	
	return services[characterName]
end

return NPCServiceManager

