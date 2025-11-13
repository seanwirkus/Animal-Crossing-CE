local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local BuildingCatalog = require(sharedFolder:WaitForChild("BuildingCatalog"))
local IslandProgress = require(sharedFolder:WaitForChild("IslandProgress"))

local BuildingService = {}
BuildingService.__index = BuildingService

export type Options = {
    hasMaterials: ((Player, { { itemId: string, count: number } }, number?) -> boolean)?,
    consumeMaterials: ((Player, { { itemId: string, count: number } }, number?) -> boolean)?,
    currencyManager: any?,
}

function BuildingService.new(options: Options?)
    local self = setmetatable({}, BuildingService)
    options = options or {}

    self.hasMaterials = options.hasMaterials
    self.consumeMaterials = options.consumeMaterials
    self.currencyManager = options.currencyManager

    self.islandProgress = {}
    self.homeProgress = {}

    self.remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not self.remoteFolder then
        self.remoteFolder = Instance.new("Folder")
        self.remoteFolder.Name = "RemoteEvents"
        self.remoteFolder.Parent = ReplicatedStorage
    end

    self.requestRemote = self.remoteFolder:FindFirstChild("BuildingRequest")
    if not self.requestRemote then
        self.requestRemote = Instance.new("RemoteEvent")
        self.requestRemote.Name = "BuildingRequest"
        self.requestRemote.Parent = self.remoteFolder
    end

    self.progressRemote = self.remoteFolder:FindFirstChild("BuildingProgress")
    if not self.progressRemote then
        self.progressRemote = Instance.new("RemoteEvent")
        self.progressRemote.Name = "BuildingProgress"
        self.progressRemote.Parent = self.remoteFolder
    end

    self:_initializeIslandProgress()

    self.requestRemote.OnServerEvent:Connect(function(player, payload)
        self:_handleRequest(player, payload)
    end)

    Players.PlayerAdded:Connect(function(player)
        self:_onPlayerAdded(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.homeProgress[player.UserId] = nil
    end)

    print("[BuildingService] ✅ Initialized")
    return self
end

local function cloneContributions(source)
    local target = {}
    if typeof(source) ~= "table" then
        return target
    end
    for key, value in pairs(source) do
        target[key] = value
    end
    return target
end

function BuildingService:_initializeIslandProgress()
    for _, project in ipairs(BuildingCatalog.getAllProjects()) do
        if project.scope == "island" then
            local entry = IslandProgress.createEntry()
            entry.status = "locked"
            self.islandProgress[project.id] = entry
        end
    end
    self:_recalculateIslandStatuses()
end

function BuildingService:_handleRequest(player, payload)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end

    if typeof(payload) ~= "table" then
        return
    end

    local action = payload.action
    if action == "sync" then
        self:_sendSync(player)
    elseif action == "build" then
        local projectId = payload.projectId
        if typeof(projectId) ~= "string" then
            return
        end
        self:_attemptBuild(player, projectId)
    end
end

function BuildingService:_onPlayerAdded(player)
    self:_ensureHomeProgress(player)
    self:_sendSync(player)
end

function BuildingService:_ensureHomeProgress(player)
    local userId = player.UserId
    local data = self.homeProgress[userId]
    if not data then
        data = {}
        self.homeProgress[userId] = data
    end

    for _, project in ipairs(BuildingCatalog.getAllProjects()) do
        if project.scope ~= "island" and not data[project.id] then
            data[project.id] = IslandProgress.createEntry()
        end
    end

    self:_recalculateHomeStatuses(player)
end

function BuildingService:_recalculateIslandStatuses()
    local function resolver(dependencyId)
        local dependency = self.islandProgress[dependencyId]
        if dependency then
            return dependency.status or "locked"
        end
        return "locked"
    end

    for _, project in ipairs(BuildingCatalog.getAllProjects()) do
        if project.scope == "island" then
            local entry = self.islandProgress[project.id]
            if not entry then
                entry = IslandProgress.createEntry()
                self.islandProgress[project.id] = entry
            end
            entry.status = IslandProgress.computeStatus(project, entry, resolver)
        end
    end
end

function BuildingService:_recalculateHomeStatuses(player)
    local userId = player.UserId
    local data = self.homeProgress[userId]
    if not data then
        data = {}
        self.homeProgress[userId] = data
    end

    local function resolver(dependencyId)
        local dependencyProject = BuildingCatalog.getProject(dependencyId)
        if dependencyProject then
            if dependencyProject.scope == "island" then
                local islandEntry = self.islandProgress[dependencyId]
                return islandEntry and islandEntry.status or "locked"
            else
                local dependencyEntry = data[dependencyId]
                if dependencyEntry then
                    return dependencyEntry.status or "locked"
                end
            end
        end
        return "locked"
    end

    for _, project in ipairs(BuildingCatalog.getAllProjects()) do
        if project.scope ~= "island" then
            local entry = data[project.id]
            if not entry then
                entry = IslandProgress.createEntry()
                data[project.id] = entry
            end
            entry.status = IslandProgress.computeStatus(project, entry, resolver)
        end
    end
end

function BuildingService:_attemptBuild(player, projectId)
    local project = BuildingCatalog.getProject(projectId)
    if not project then
        return
    end

    if project.scope == "island" then
        self:_attemptIslandBuild(player, project)
    else
        self:_attemptHomeBuild(player, project)
    end
end

local function hasMaterialList(materials)
    if typeof(materials) ~= "table" then
        return false
    end
    return #materials > 0
end

function BuildingService:_attemptIslandBuild(player, project)
    local entry = self.islandProgress[project.id]
    if not entry then
        entry = IslandProgress.createEntry()
        self.islandProgress[project.id] = entry
    end

    self:_recalculateIslandStatuses()

    if entry.status == "locked" then
        self:_sendFeedback(player, "This project is still locked.", true)
        return
    end

    if entry.status == "completed" and not project.repeatable then
        self:_sendFeedback(player, "Project already completed!", true)
        return
    end

    local materials = project.requirements and project.requirements.materials or {}
    local requiresMaterials = hasMaterialList(materials)

    if requiresMaterials and self.hasMaterials then
        local hasAll = self.hasMaterials(player, materials, 1)
        if not hasAll then
            self:_sendFeedback(player, "You don't have the required materials.", true)
            return
        end
    end

    if requiresMaterials and self.consumeMaterials then
        local consumed = self.consumeMaterials(player, materials, 1)
        if not consumed then
            self:_sendFeedback(player, "Unable to withdraw materials.", true)
            return
        end
    end

    entry.delivered = (entry.delivered or 0) + 1
    entry.contributions = entry.contributions or {}
    entry.contributions[player.UserId] = (entry.contributions[player.UserId] or 0) + 1

    local required = 1
    if project.requirements and project.requirements.deliveries then
        required = project.requirements.deliveries
    end

    if not project.repeatable and entry.delivered >= required then
        entry.status = "completed"
    else
        entry.status = "in-progress"
    end

    self:_rewardPlayer(player, project)

    self:_recalculateIslandStatuses()
    self:_broadcastIslandUpdate()

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer and otherPlayer.Parent then
            self:_ensureHomeProgress(otherPlayer)
            self:_sendHomeUpdate(otherPlayer)
        end
    end
    self:_sendFeedback(player, "Thanks for contributing to the island!", false)
end

function BuildingService:_attemptHomeBuild(player, project)
    local userId = player.UserId
    local data = self.homeProgress[userId]
    if not data then
        data = {}
        self.homeProgress[userId] = data
    end

    local entry = data[project.id]
    if not entry then
        entry = IslandProgress.createEntry()
        data[project.id] = entry
    end

    self:_recalculateHomeStatuses(player)

    if entry.status == "locked" then
        self:_sendFeedback(player, "Unlock earlier projects to continue.", true)
        return
    end

    if entry.status == "completed" and not project.repeatable then
        self:_sendFeedback(player, "You've already finished this upgrade!", true)
        return
    end

    local materials = project.requirements and project.requirements.materials or {}
    local requiresMaterials = hasMaterialList(materials)

    if requiresMaterials and self.hasMaterials then
        local hasAll = self.hasMaterials(player, materials, 1)
        if not hasAll then
            self:_sendFeedback(player, "You don't have the required materials.", true)
            return
        end
    end

    if requiresMaterials and self.consumeMaterials then
        local consumed = self.consumeMaterials(player, materials, 1)
        if not consumed then
            self:_sendFeedback(player, "Unable to withdraw materials.", true)
            return
        end
    end

    entry.delivered = (entry.delivered or 0) + 1
    entry.contributions = entry.contributions or {}
    entry.contributions[userId] = (entry.contributions[userId] or 0) + 1

    local required = 1
    if project.requirements and project.requirements.deliveries then
        required = project.requirements.deliveries
    end

    if project.repeatable then
        entry.status = "repeatable"
    elseif entry.delivered >= required then
        entry.status = "completed"
    else
        entry.status = "in-progress"
    end

    self:_rewardPlayer(player, project)

    self:_recalculateHomeStatuses(player)
    self:_sendHomeUpdate(player)
    self:_sendFeedback(player, "Upgrade recorded!", false)
end

function BuildingService:_rewardPlayer(player, project)
    if not self.currencyManager then
        return
    end

    local rewards = project.rewards
    if rewards and rewards.bells and rewards.bells > 0 then
        local ok, err = pcall(function()
            return self.currencyManager.addBells(player, rewards.bells)
        end)
        if not ok then
            warn("[BuildingService] Failed to grant bells:", err)
        end
    end
end

function BuildingService:_broadcastIslandUpdate()
    if not self.progressRemote then
        return
    end

    self.progressRemote:FireAllClients("islandUpdate", {
        island = self:_buildIslandPayload(),
    })
end

function BuildingService:_sendHomeUpdate(player)
    if not self.progressRemote then
        return
    end

    self.progressRemote:FireClient(player, "homeUpdate", {
        home = self:_buildHomePayload(player),
    })
end

function BuildingService:_buildIslandPayload()
    local payload = {}
    for projectId, entry in pairs(self.islandProgress) do
        payload[projectId] = {
            delivered = entry.delivered or 0,
            status = entry.status or "available",
            contributions = cloneContributions(entry.contributions),
        }
    end
    return payload
end

function BuildingService:_buildHomePayload(player)
    local userId = player.UserId
    local data = self.homeProgress[userId] or {}
    local payload = {}

    for _, project in ipairs(BuildingCatalog.getAllProjects()) do
        if project.scope ~= "island" then
            local entry = data[project.id]
            if not entry then
                entry = IslandProgress.createEntry()
                data[project.id] = entry
            end
            payload[project.id] = {
                delivered = entry.delivered or 0,
                status = entry.status or "available",
                contributions = cloneContributions(entry.contributions),
            }
        end
    end

    return payload
end

function BuildingService:_sendSync(player)
    if not self.progressRemote then
        return
    end

    self:_recalculateIslandStatuses()
    self:_ensureHomeProgress(player)

    self.progressRemote:FireClient(player, "sync", {
        island = self:_buildIslandPayload(),
        home = self:_buildHomePayload(player),
    })
end

function BuildingService:_sendFeedback(player, message, isError)
    if not self.progressRemote then
        return
    end

    self.progressRemote:FireClient(player, "feedback", {
        message = message,
        isError = isError,
    })
end

return BuildingService
