--[[
	ShovelClient.luau
	
	Client-side shovel handling:
	- Detects when player uses shovel
	- Sends dig request to server
	- Shows visual feedback
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local function resolveRemoteEvents(context: string)
    local container = ReplicatedStorage:WaitForChild("RemoteEvents")
    local remoteEvents = nil

    if container:IsA("ModuleScript") then
        local ok, moduleOrError = pcall(require, container)
        if ok and typeof(moduleOrError) == "table" then
            remoteEvents = moduleOrError
        else
            warn(
                string.format("[%s] ⚠️ Failed to require RemoteEvents module: %s", context, tostring(moduleOrError))
            )
        end
    end

    if remoteEvents and remoteEvents.ToolEvents then
        return remoteEvents
    end

    local toolFolder = container:FindFirstChild("ToolEvents")
    if not toolFolder then
        warn(string.format("[%s] ⚠️ ToolEvents folder missing under ReplicatedStorage.RemoteEvents", context))
        return nil
    end

    return {
        ToolEvents = {
            Folder = toolFolder,
            Use = toolFolder:FindFirstChild("ToolUse"),
            Feedback = toolFolder:FindFirstChild("ToolFeedback"),
        },
    }
end

local RemoteEvents = resolveRemoteEvents("ShovelClient")

local ShovelClient = {}

local TOOL_TYPE = "shovel"
local player = Players.LocalPlayer

local toolEvents = RemoteEvents and RemoteEvents.ToolEvents
local toolUseRemote = toolEvents and toolEvents.Use
local toolFeedbackRemote = toolEvents and toolEvents.Feedback

local isShovelEquipped = false

local function fireDigRequest()
    if not toolUseRemote then
        warn("[ShovelClient] ⚠️ ToolUse remote is missing")
        return
    end

    toolUseRemote:FireServer({
        toolType = TOOL_TYPE,
        action = "dig",
        toolId = player:GetAttribute("EquippedToolId"),
    })
end

local function onToolActivated(tool)
    if not tool.Name:lower():find("shovel") then
        return
    end

    print("[ShovelClient] 🪓 Dig requested via tool activation")
    fireDigRequest()
end

local function checkForEquippedShovel(character)
    local hasShovel = player:GetAttribute("EquippedToolType") == TOOL_TYPE

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") and child.Name:lower():find("shovel") then
            hasShovel = true
            break
        end
    end

    isShovelEquipped = hasShovel
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed or not isShovelEquipped then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.Space then
        print("[ShovelClient] 🕳️ Dig requested via input")
        fireDigRequest()
    end
end

local function connectCharacterListeners(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Activated:Connect(function()
                onToolActivated(child)
            end)
        end
        checkForEquippedShovel(character)
    end)

    character.ChildRemoved:Connect(function()
        checkForEquippedShovel(character)
    end)

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            child.Activated:Connect(function()
                onToolActivated(child)
            end)
        end
    end

    checkForEquippedShovel(character)
end

function ShovelClient.init()
    print("[ShovelClient] 🔨 Initializing shovel client...")

    if player.Character then
        connectCharacterListeners(player.Character)
    end

    player.CharacterAdded:Connect(connectCharacterListeners)

    UserInputService.InputBegan:Connect(onInputBegan)

    if toolFeedbackRemote then
        toolFeedbackRemote.OnClientEvent:Connect(function(payload)
            if type(payload) ~= "table" or payload.toolType ~= TOOL_TYPE then
                return
            end

            if payload.action == "dig_success" then
                local resultType = payload.resultType or (payload.data and payload.data.resultType)
                print("[ShovelClient] ✅ Dig success:", resultType or "unknown")
            elseif payload.action == "dig_failed" then
                warn("[ShovelClient] ❌ Dig failed:", payload.message or "Unknown reason")
            end
        end)
    else
        warn("[ShovelClient] ⚠️ ToolFeedback remote is missing")
    end

    print("[ShovelClient] ✅ Shovel client initialized")
end

return ShovelClient
