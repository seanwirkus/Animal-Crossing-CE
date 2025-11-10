local Players = game:GetService("Players")

local ChibiCharacter = {}

function ChibiCharacter.init()
    local function onCharacterAdded(character)
        task.wait(0.1) -- Wait for character to fully load
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- First, scale the entire character to 1.5x (bigger!)
        if character:IsA("Model") and character.PrimaryPart then
            character:ScaleTo(1.5)
            print("[ChibiCharacter] ✅ Scaled character to 1.5x")
        end
        
        -- Then apply ACNH chibi proportions
        local success, err = pcall(function()
            local desc = humanoid:GetAppliedDescription()
            
            -- ACNH-style chibi proportions (big head, short body)
            desc.HeadScale = 1.0        -- Much bigger head for chibi look
            desc.WidthScale = 3.0      -- Wider body
            desc.DepthScale = 3.0        -- Thicker body  
            desc.HeightScale = 0.8        -- Shorter torso/legs (chibi!)
            desc.BodyTypeScale = 0        -- Round, soft body
            
            humanoid:ApplyDescription(desc)
            print("[ChibiCharacter] ✅ Applied ACNH chibi proportions")
        end)
        
        if not success then
            warn("[ChibiCharacter] ❌ Failed to apply proportions:", err)
        end
    end
    
    local LocalPlayer = Players.LocalPlayer
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

return ChibiCharacter
