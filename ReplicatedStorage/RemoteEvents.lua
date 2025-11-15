local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

local container = script

local function ensureRemote(name: string, parent: Instance): RemoteEvent
    local remote = parent:FindFirstChild(name)
    if remote and not remote:IsA("RemoteEvent") then
        remote:Destroy()
        remote = nil
    end

    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = parent
        print(string.format("[RemoteEvents] ✅ Created RemoteEvent '%s' under %s", name, parent:GetFullName()))
    end

    return remote
end

local function ensureTopLevelRemote(name: string): RemoteEvent
    local remote = ReplicatedStorage:FindFirstChild(name)
    if remote and not remote:IsA("RemoteEvent") then
        remote:Destroy()
        remote = nil
    end

    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = ReplicatedStorage
        print(string.format("[RemoteEvents] ✅ Created top-level RemoteEvent '%s'", name))
    end

    return remote
end

-- Core remotes exposed at the root of ReplicatedStorage for legacy callers
RemoteEvents.InventoryEvent = ensureTopLevelRemote("InventoryEvent")
RemoteEvents.CurrencyEvent = ensureTopLevelRemote("CurrencyEvent")

-- Container for namespaced remotes
RemoteEvents.Container = container

local toolFolder = container:FindFirstChild("ToolEvents")
if not toolFolder then
    toolFolder = Instance.new("Folder")
    toolFolder.Name = "ToolEvents"
    toolFolder.Parent = container
end

RemoteEvents.ToolEvents = {
    Folder = toolFolder,
    Use = ensureRemote("ToolUse", toolFolder),
    Feedback = ensureRemote("ToolFeedback", toolFolder),
}

return RemoteEvents
