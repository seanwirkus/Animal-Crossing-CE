local ResidentServices = {}
ResidentServices.__index = ResidentServices

-- Resident Services is the main hub building on every island
-- Similar to Tom Nook's tent -> building in early game

function ResidentServices.new()
	local self = setmetatable({}, ResidentServices)

	-- Building state
	self._isabelle = nil -- Isabelle NPC instance
	self._building = nil -- The 3D building model
	self._services = {
		IslandInfo = true,
		CitizenServices = true,
		Construction = true,
		Permits = true,
		LostAndFound = true,
		Announcements = true
	}

	-- Service hours (8 AM - 10 PM)
	self._openTime = 8
	self._closeTime = 22

	-- Initialize the building
	self:_createBuilding()

	return self
end

function ResidentServices:_createBuilding()
	-- Create Resident Services building at center of island
	local building = Instance.new("Model")
	building.Name = "ResidentServices"

	-- Main building structure (simplified for now)
	local mainHall = Instance.new("Part")
	mainHall.Name = "MainHall"
	mainHall.Size = Vector3.new(40, 20, 30)
	mainHall.Position = Vector3.new(0, 10, -20) -- Center of island, slightly north
	mainHall.Anchored = true
	mainHall.CanCollide = true
	mainHall.Material = Enum.Material.Wood
	mainHall.Color = Color3.fromRGB(139, 69, 19) -- Brown wood
	mainHall.Parent = building

	-- Add roof
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(42, 2, 32)
	roof.Position = Vector3.new(0, 21, -20)
	roof.Anchored = true
	roof.CanCollide = true
	roof.Material = Enum.Material.RoofShingles
	roof.Color = Color3.fromRGB(139, 0, 0) -- Dark red roof
	roof.Parent = building

	-- Add door
	local door = Instance.new("Part")
	door.Name = "Door"
	door.Size = Vector3.new(6, 12, 1)
	door.Position = Vector3.new(0, 6, -5) -- Front of building
	door.Anchored = true
	door.CanCollide = true
	door.Material = Enum.Material.Wood
	door.Color = Color3.fromRGB(101, 67, 33) -- Darker wood
	door.Parent = building

	-- Add windows
	for i = -1, 1, 2 do
		local window = Instance.new("Part")
		window.Name = "Window"
		window.Size = Vector3.new(4, 6, 1)
		window.Position = Vector3.new(i * 8, 12, -5)
		window.Anchored = true
		window.CanCollide = true
		window.Transparency = 0.5
		window.Material = Enum.Material.Glass
		window.Parent = building
	end

	-- Add Resident Services sign
	local sign = Instance.new("Part")
	sign.Name = "ResidentServicesSign"
	sign.Size = Vector3.new(12, 4, 1)
	sign.Position = Vector3.new(0, 16, -25)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Material = Enum.Material.Wood
	sign.Color = Color3.fromRGB(255, 255, 255)
	sign.Parent = building

	-- Add sign text (using BillboardGui for now)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SignText"
	billboard.Size = UDim2.new(1, 0, 1, 0)
	billboard.Adornee = sign
	billboard.Parent = sign

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "🏛️ Resident Services"
	textLabel.TextColor3 = Color3.fromRGB(139, 69, 19)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 24
	textLabel.Parent = billboard

	building.Parent = workspace
	self._building = building

	print("[ResidentServices] Building created at center of island")
end

function ResidentServices:GetBuilding()
	return self._building
end

function ResidentServices:GetServices()
	return self._services
end

function ResidentServices:IsOpen(currentHour)
	return currentHour >= self._openTime and currentHour < self._closeTime
end

function ResidentServices:GetStatus()
	local hour = os.date("!%H") -- UTC hour
	local isOpen = self:IsOpen(hour)

	return {
		isOpen = isOpen,
		currentHour = hour,
		openTime = self._openTime,
		closeTime = self._closeTime,
		nextChange = isOpen and self._closeTime or self._openTime
	}
end

-- Service interactions
function ResidentServices:RequestService(player, serviceType)
	if not self._services[serviceType] then
		return { success = false, message = "Service not available" }
	end

	local hour = os.date("!%H")
	if not self:IsOpen(hour) then
		return {
			success = false,
			message = string.format("Resident Services is closed. Opens at %d:00.", self._openTime)
		}
	end

	-- Handle different service types
	if serviceType == "IslandInfo" then
		return self:_handleIslandInfo(player)
	elseif serviceType == "CitizenServices" then
		return self:_handleCitizenServices(player)
	elseif serviceType == "Construction" then
		return self:_handleConstruction(player)
	elseif serviceType == "Permits" then
		return self:_handlePermits(player)
	elseif serviceType == "LostAndFound" then
		return self:_handleLostAndFound(player)
	elseif serviceType == "Announcements" then
		return self:_handleAnnouncements(player)
	end

	return { success = false, message = "Unknown service type" }
end

function ResidentServices:_handleIslandInfo(player)
	-- Return island information
	return {
		success = true,
		message = "🌴 Island Information Retrieved",
		data = {
			islandName = "Your Island",
			residentCount = #game.Players:GetPlayers(),
			developmentLevel = "Growing",
			specialVisitors = "None today"
		}
	}
end

function ResidentServices:_handleCitizenServices(player)
	-- Handle citizen registration and services
	return {
		success = true,
		message = "🏠 Citizen Services Updated",
		data = {
			residentStatus = "Active",
			moveInDate = "Today",
			islandRole = "Resident"
		}
	}
end

function ResidentServices:_handleConstruction(player)
	-- Handle building permits and construction
	return {
		success = true,
		message = "🔨 Construction Services Available",
		data = {
			availableBuildings = {"House", "Shop", "Museum"},
			currentProjects = "None",
			nextUnlock = "Nook's Cranny"
		}
	}
end

function ResidentServices:_handlePermits(player)
	-- Handle various island permits
	return {
		success = true,
		message = "📋 Permits Updated",
		data = {
			activePermits = {"Basic Residency", "Resource Gathering"},
			pendingPermits = "None",
			nextPermit = "Bridge Construction"
		}
	}
end

function ResidentServices:_handleLostAndFound(player)
	-- Handle lost and found items
	return {
		success = true,
		message = "🔍 Lost & Found Checked",
		data = {
			lostItems = "None reported",
			foundItems = "None available",
			recentActivity = "No recent lost items"
		}
	}
end

function ResidentServices:_handleAnnouncements(player)
	-- Handle bulletin board announcements
	return {
		success = true,
		message = "📢 Announcements Updated",
		data = {
			todaysNews = "Welcome to your new island!",
			upcomingEvents = {"Island Opening Ceremony"},
			publicWorks = "Resident Services completed",
			lostAndFound = "No items today"
		}
	}
end

function ResidentServices:Destroy()
	if self._building then
		self._building:Destroy()
	end
	if self._isabelle then
		self._isabelle:Destroy()
	end
end

return ResidentServices
