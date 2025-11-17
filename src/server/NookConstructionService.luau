--[[
	NookConstructionService.luau
	
	Handles Nook Construction projects (buildings, bridges, inclines, etc.)
	For debugging: All construction completes instantly
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local NookConstructionService = {}
NookConstructionService.__index = NookConstructionService

-- DEBUG MODE: Instant construction completion
local DEBUG_INSTANT_CONSTRUCTION = true

local _instance = nil

function NookConstructionService.new()
	if _instance then
		return _instance
	end

	local self = setmetatable({}, NookConstructionService)

	self._activeProjects = {} -- [projectId] = projectData
	self._playerIslandService = nil -- Will be set by init

	-- Setup RemoteEvents
	self:_setupRemoteEvents()

	_instance = self
	print("[NookConstructionService] ✅ Initialized (DEBUG: Instant construction enabled)")
	return self
end

function NookConstructionService:SetPlayerIslandService(service)
	self._playerIslandService = service
	print("[NookConstructionService] ✅ Connected to PlayerIslandService")
end

function NookConstructionService:_setupRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
	end

	-- StartConstruction RemoteEvent
	local startConstructionRemote = remoteEventsFolder:FindFirstChild("StartConstruction")
	if not startConstructionRemote then
		startConstructionRemote = Instance.new("RemoteEvent")
		startConstructionRemote.Name = "StartConstruction"
		startConstructionRemote.Parent = remoteEventsFolder
	end

	startConstructionRemote.OnServerEvent:Connect(function(player, projectData)
		self:StartConstruction(player, projectData)
	end)

	-- CompleteConstruction RemoteEvent (for debugging - manually complete)
	local completeConstructionRemote = remoteEventsFolder:FindFirstChild("CompleteConstruction")
	if not completeConstructionRemote then
		completeConstructionRemote = Instance.new("RemoteEvent")
		completeConstructionRemote.Name = "CompleteConstruction"
		completeConstructionRemote.Parent = remoteEventsFolder
	end

	completeConstructionRemote.OnServerEvent:Connect(function(player, projectId)
		self:CompleteConstruction(player, projectId)
	end)
end

function NookConstructionService:StartConstruction(player, projectData)
	local userId = player.UserId
	
	if not projectData or not projectData.type or not projectData.position then
		warn("[NookConstructionService] Invalid project data")
		return false, "Invalid project data"
	end

	local projectId = projectData.id or ("project_" .. userId .. "_" .. os.time())
	
	-- Check if player already has this project
	if self._activeProjects[projectId] then
		return false, "Project already exists"
	end

	-- Create project entry
	local project = {
		id = projectId,
		owner = userId,
		type = projectData.type, -- "bridge", "incline", "building", etc.
		position = projectData.position,
		modelName = projectData.modelName or projectData.type, -- Model name in ReplicatedStorage
		started = os.time(),
		status = "in-progress",
	}

	self._activeProjects[projectId] = project

	-- DEBUG: Complete instantly if enabled
	if DEBUG_INSTANT_CONSTRUCTION then
		print(string.format("[NookConstructionService] 🚀 DEBUG: Instantly completing construction for %s", projectId))
		task.wait(0.1) -- Small delay for visual feedback
		self:CompleteConstruction(player, projectId)
		return true, "Construction started (completed instantly for debugging)"
	else
		-- Normal construction would have a timer here
		-- For now, just mark as in-progress
		print(string.format("[NookConstructionService] ✅ Started construction: %s at %s", projectId, tostring(projectData.position)))
		return true, "Construction started"
	end
end

function NookConstructionService:CompleteConstruction(player, projectId)
	local userId = player.UserId
	local project = self._activeProjects[projectId]

	if not project then
		warn("[NookConstructionService] Project not found:", projectId)
		return false, "Project not found"
	end

	if project.owner ~= userId then
		warn("[NookConstructionService] Player doesn't own this project")
		return false, "You don't own this project"
	end

	if project.status == "completed" then
		return false, "Project already completed"
	end

	-- Place the construction model
	local success, message = self:_placeConstructionModel(player, project)
	if not success then
		warn("[NookConstructionService] Failed to place model:", message)
		return false, message
	end

	-- Mark as completed
	project.status = "completed"
	project.completed = os.time()

	-- Notify client
	self:_notifyClient(player, "constructionComplete", {
		projectId = projectId,
		message = "Construction completed!"
	})

	print(string.format("[NookConstructionService] ✅ Completed construction: %s", projectId))
	return true, "Construction completed!"
end

function NookConstructionService:_placeConstructionModel(player, project)
	-- Try to find model in ReplicatedStorage
	local model = ReplicatedStorage:FindFirstChild(project.modelName)
	if not model or not model:IsA("Model") then
		-- Try NookConstruction folder
		local nookConstructionFolder = ReplicatedStorage:FindFirstChild("NookConstruction")
		if nookConstructionFolder then
			model = nookConstructionFolder:FindFirstChild(project.modelName)
		end
	end

	if not model or not model:IsA("Model") then
		warn(string.format("[NookConstructionService] ⚠️ Model '%s' not found in ReplicatedStorage", project.modelName))
		return false, string.format("Model '%s' not found", project.modelName)
	end

	-- Clone model
	local constructionModel = model:Clone()
	constructionModel.Name = project.type .. "_" .. player.Name

	-- Position model
	local position = project.position
	if typeof(position) == "table" then
		position = Vector3.new(position.X or position.x, position.Y or position.y, position.Z or position.z)
	end

	-- Set position
	if constructionModel.PrimaryPart then
		constructionModel:SetPrimaryPartCFrame(CFrame.new(position))
	else
		local firstPart = constructionModel:FindFirstChildOfClass("BasePart")
		if firstPart then
			firstPart.CFrame = CFrame.new(position)
		end
	end

	-- Parent to island folder if available
	local parentFolder = nil
	if self._playerIslandService then
		local islandFolder = self._playerIslandService:getPlayerIslandFolder(player.UserId)
		if islandFolder then
			local buildingsFolder = islandFolder:FindFirstChild("Buildings")
			if not buildingsFolder then
				buildingsFolder = Instance.new("Folder")
				buildingsFolder.Name = "Buildings"
				buildingsFolder.Parent = islandFolder
			end
			parentFolder = buildingsFolder
		end
	end

	-- Fallback to Workspace
	if not parentFolder then
		local constructionsFolder = Workspace:FindFirstChild("Constructions")
		if not constructionsFolder then
			constructionsFolder = Instance.new("Folder")
			constructionsFolder.Name = "Constructions"
			constructionsFolder.Parent = Workspace
		end
		parentFolder = constructionsFolder
	end

	constructionModel.Parent = parentFolder

	-- Set attributes
	constructionModel:SetAttribute("ConstructionType", project.type)
	constructionModel:SetAttribute("Owner", player.UserId)
	constructionModel:SetAttribute("ProjectId", project.id)
	constructionModel:SetAttribute("Completed", os.time())

	print(string.format("[NookConstructionService] ✅ Placed construction model: %s at %s", project.modelName, tostring(position)))
	return true, "Model placed"
end

function NookConstructionService:_notifyClient(player, action, data)
	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		return
	end

	local notificationRemote = remoteEventsFolder:FindFirstChild("ConstructionNotification")
	if not notificationRemote then
		notificationRemote = Instance.new("RemoteEvent")
		notificationRemote.Name = "ConstructionNotification"
		notificationRemote.Parent = remoteEventsFolder
	end

	notificationRemote:FireClient(player, action, data)
end

function NookConstructionService:GetPlayerProjects(player)
	local userId = player.UserId
	local projects = {}

	for projectId, project in pairs(self._activeProjects) do
		if project.owner == userId then
			table.insert(projects, project)
		end
	end

	return projects
end

-- Initialize service
local service = NookConstructionService.new()

return NookConstructionService

