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

local ShovelClient = {}

local isShovelEquipped = false

local function onToolActivated(tool)
    -- Check if it's a shovel
    if not tool.Name:lower():find("shovel") then
        return
    end

    print("[ShovelClient] Shovel activated!")

    -- Send dig request to server
    local shovelEvent = ReplicatedStorage:WaitForChild("ShovelDig", 5)
    if shovelEvent then
        shovelEvent:FireServer()
    end
end

local function checkForEquippedShovel(character)
    local hasShovel = false
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") and child.Name:lower():find("shovel") then
            hasShovel = true
            break
        end
    end
    isShovelEquipped = hasShovel
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed then
        return
    end
    if not isShovelEquipped then
        return
    end

    -- Activate shovel on left mouse click or spacebar
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.Space then
        print("[ShovelClient] Shovel activated via input!")

        -- Send dig request to server
        local shovelEvent = ReplicatedStorage:WaitForChild("ShovelDig", 5)
        if shovelEvent then
            shovelEvent:FireServer()
        end
    end
end

function ShovelClient.init()
    print("[ShovelClient] 🔨 Initializing shovel client...")

    local player = Players.LocalPlayer

    -- Listen for dig results from server
    local shovelEvent = ReplicatedStorage:WaitForChild("ShovelDig", 5)
    if shovelEvent then
        shovelEvent.OnClientEvent:Connect(function(itemId, amount)
            print("[ShovelClient] Dug up", amount, "x", itemId, "!")

            -- You can add visual effects here like:
            -- - Particle effect at dig location
            -- - Sound effect
            -- - Item popup notification
        end)
    end

    -- Monitor when player equips tools
    local function onCharacterAdded(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                child.Activated:Connect(function()
                    onToolActivated(child)
                end)
            end
            checkForEquippedShovel(character)
        end)

        character.ChildRemoved:Connect(function(child)
            checkForEquippedShovel(character)
        end)

        -- Check already equipped tools
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then
                child.Activated:Connect(function()
                    onToolActivated(child)
                end)
            end
        end
        checkForEquippedShovel(character)
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)

    -- Listen for input to activate shovel
    UserInputService.InputBegan:Connect(onInputBegan)

    print("[ShovelClient] ✅ Shovel client initialized")
end

return ShovelClient
