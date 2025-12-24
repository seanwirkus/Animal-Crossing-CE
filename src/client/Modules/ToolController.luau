--[[
	ToolController.luau
	Handles tool activation for axe, net, and watering can
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local ToolController = {}

-- Get RemoteEvents
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local ToolEvents = RemoteEvents and RemoteEvents:FindFirstChild("ToolEvents")
local toolUseRemote = ToolEvents and ToolEvents:FindFirstChild("ToolUse")

if not toolUseRemote then
    warn("[ToolController] ⚠️ ToolUse remote not found")
end

-- Track equipped tool
local equippedTool = nil
local toolActivationConnection = nil
local rightClickConnection = nil

-- Check if tool is axe, net, watering can, or shovel
local function isToolType(tool, toolType)
    if not tool then
        return false
    end

    local toolName = tool.Name:lower()
    if toolType == "axe" then
        return toolName:find("axe")
    elseif toolType == "net" then
        return toolName:find("net")
    elseif toolType == "watering_can" then
        return toolName:find("watering")
    elseif toolType == "shovel" then
        return toolName:find("shovel")
    end

    return false
end

-- Fire tool use request to server
local function fireToolRequest(toolType, action)
    if not toolUseRemote then
        warn("[ToolController] ⚠️ ToolUse remote missing")
        return
    end
    
    local character = player.Character
    if not character then
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    toolUseRemote:FireServer({
        toolType = toolType,
        action = action,
        toolId = player:GetAttribute("EquippedToolId"),
        position = humanoidRootPart.Position,
    })
end

-- Handle tool activation
local function onToolActivated(tool)
    if isToolType(tool, "axe") then
        fireToolRequest("axe", "chop")
        print("[ToolController] 🪓 Axe chop requested")
    elseif isToolType(tool, "net") then
        fireToolRequest("net", "swing")
        print("[ToolController] 🦋 Net swing requested")
    elseif isToolType(tool, "watering_can") then
        fireToolRequest("watering_can", "water")
        print("[ToolController] 💧 Watering can use requested")
    elseif isToolType(tool, "shovel") then
        fireToolRequest("shovel", "hit")
        print("[ToolController] 🪨 Shovel hit requested")
    end
end

-- Check if tool is currently equipped
local function getEquippedToolType(character)
    if not character then
        return nil
    end
    
    -- Check player attribute
    local equippedToolType = player:GetAttribute("EquippedToolType")
    if equippedToolType then
        local toolType = tostring(equippedToolType):lower()
        if toolType:find("axe") then
            return "axe"
        elseif toolType:find("net") then
            return "net"
        elseif toolType:find("watering") then
            return "watering_can"
        elseif toolType:find("shovel") then
            return "shovel"
        end
    end

    -- Check for Tool objects
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            if isToolType(child, "axe") then
                return "axe"
            elseif isToolType(child, "net") then
                return "net"
            elseif isToolType(child, "watering_can") then
                return "watering_can"
            elseif isToolType(child, "shovel") then
                return "shovel"
            end
        end
    end

    return nil
end

-- Handle right-click activation (like shovel)
local function onRightClick()
    if UserInputService:GetFocusedTextBox() then
        return -- Don't activate if typing
    end

    local character = player.Character
    if not character then
        return
    end

    local toolType = getEquippedToolType(character)
    if toolType then
        if toolType == "axe" then
            fireToolRequest("axe", "chop")
            print("[ToolController] 🪓 Axe chop requested (right-click)")
        elseif toolType == "net" then
            fireToolRequest("net", "swing")
            print("[ToolController] 🦋 Net swing requested (right-click)")
        elseif toolType == "watering_can" then
            fireToolRequest("watering_can", "water")
            print("[ToolController] 💧 Watering can use requested (right-click)")
        elseif toolType == "shovel" then
            fireToolRequest("shovel", "hit")
            print("[ToolController] 🪨 Shovel hit requested (right-click)")
        end
    end
end

-- Monitor character for tool changes
local function onCharacterAdded(character)
    -- Disconnect old connections
    if toolActivationConnection then
        toolActivationConnection:Disconnect()
        toolActivationConnection = nil
    end
    
    -- Monitor for tool equipped
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            equippedTool = child

            -- Connect to tool activation (left-click)
            if isToolType(child, "axe") or isToolType(child, "net") or isToolType(child, "watering_can") or isToolType(child, "shovel") then
                child.Activated:Connect(function()
                    onToolActivated(child)
                end)
            end
        end
    end)

    -- Check for existing tools
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            equippedTool = child

            if isToolType(child, "axe") or isToolType(child, "net") or isToolType(child, "watering_can") or isToolType(child, "shovel") then
                child.Activated:Connect(function()
                    onToolActivated(child)
                end)
            end
        end
    end
    
    -- Monitor for tool unequipped
    character.ChildRemoved:Connect(function(child)
        if child == equippedTool then
            equippedTool = nil
        end
    end)
end

-- Initialize
function ToolController.init()
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Connect right-click for tool activation
    if rightClickConnection then
        rightClickConnection:Disconnect()
    end
    
    rightClickConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        
        if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right-click
            onRightClick()
        end
    end)
    
    print("[ToolController] ✅ Initialized tool controller")
end

return ToolController

