local AvatarPersistenceService = {}

function AvatarPersistenceService.OnStart()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local AvatarKit = ReplicatedStorage:FindFirstChild("AvatarKit")
    if not AvatarKit then
    	AvatarKit = Instance.new("Folder")
    	AvatarKit.Name = "AvatarKit"
    	AvatarKit.Parent = ReplicatedStorage
    end
    local RemotesFolder = AvatarKit:FindFirstChild("Remotes")
    if not RemotesFolder then
    	RemotesFolder = Instance.new("Folder")
    	RemotesFolder.Name = "Remotes"
    	RemotesFolder.Parent = AvatarKit
    end

    local requestSaveRemote = RemotesFolder:FindFirstChild("RequestSave")
    if not requestSaveRemote then
    	requestSaveRemote = Instance.new("RemoteFunction")
    	requestSaveRemote.Name = "RequestSave"
    	requestSaveRemote.Parent = RemotesFolder
    end

    local profileStore = require(script.Parent.Parent:WaitForChild("AvatarProfileStore"))

    requestSaveRemote.OnServerInvoke = function(player: Player, profile: table?)
    	if profile == nil then
    		return profileStore.loadProfile(player)
    	end

    	local success, clean = profileStore.saveProfile(player, profile)
    	if success then
    		return clean
    	end

    	return profileStore.loadProfile(player)
    end
end

return AvatarPersistenceService
