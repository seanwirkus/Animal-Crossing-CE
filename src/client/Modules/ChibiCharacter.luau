local Players = game:GetService("Players")

local ChibiCharacter = {}

function ChibiCharacter.init()
    local function onCharacterAdded(character)
        task.wait(0.1) -- Wait for character to fully load
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- Use pcall in case properties don't exist
        pcall(function()
            local desc = humanoid:GetAppliedDescription()
            
            -- ACNH-style proportions
            desc.HeadScale = 1.75         -- Much bigger head
            desc.WidthScale = 1.1         -- Wider
            desc.DepthScale = 1.1         -- Thicker  
            desc.HeightScale = 0.7        -- Shorter
            desc.BodyTypeScale = 0.1      -- Slightly round
            
            humanoid:ApplyDescription(desc)
            print("[ChibiCharacter] ✅ Applied ACNH style")
        end)
    end
    
    local LocalPlayer = Players.LocalPlayer
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

return ChibiCharacter
