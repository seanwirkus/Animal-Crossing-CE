local Players = game:GetService("Players")

local ChibiCharacter = {}

function ChibiCharacter.init()
    local function onCharacterAdded(character)
        task.wait(0.1) -- Wait for character to fully load
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        -- ChibiRig is already scaled on server, no client scaling needed
        print("[ChibiCharacter] ✅ ChibiRig character loaded (scaled on server)")
    end
    
    local LocalPlayer = Players.LocalPlayer
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

return ChibiCharacter
