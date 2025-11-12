local Players = game:GetService("Players")

local ChibiCharacter = {}

function ChibiCharacter.init()
    local function onCharacterAdded(character)
        task.wait(0.1) -- Wait for character to fully load
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- First, scale the entire character to 1.5x (bigger!)
        if character:IsA("Model") and character.PrimaryPart and not character:GetAttribute("ChibiClientScaled") then
            character:SetAttribute("ChibiClientScaled", true)
            local ok, scaleErr = pcall(function()
                character:ScaleTo(1.5)
            end)

            if ok then
                print("[ChibiCharacter] ✅ Scaled character to 1.5x (client preview)")
            else
                warn("[ChibiCharacter] ❌ Failed to scale character:", scaleErr)
            end
        end

        -- Make sure Roblox doesn't undo the server proportions
        if humanoid.AutomaticScalingEnabled then
            humanoid.AutomaticScalingEnabled = false
        end

        print("[ChibiCharacter] ✅ Client chibi tweaks applied (server will finish proportions)")
    end
    
    local LocalPlayer = Players.LocalPlayer
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

return ChibiCharacter
