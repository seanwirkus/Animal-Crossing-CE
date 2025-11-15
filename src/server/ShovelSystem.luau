--[[
	ShovelSystem.luau

	Handles shovel digging mechanics:
	- Digging holes in the ground
	- Finding buried items/bells through DigSpotManager
	- Filling holes back in
]]

local Workspace = game:GetService("Workspace")

local ShovelSystem = {}

-- Load dependencies
local CurrencyManager = require(script.Parent:WaitForChild("CurrencyManager"))
local DigSpotManager = require(script.Parent:WaitForChild("DigSpotManager"))

-- Configuration
local HOLE_ASSET_ID = 98139431900134
local DIG_COOLDOWN = 1 -- Seconds between digs

-- Player cooldowns
local playerCooldowns = {}

--[[
	Creates a hole at the given position
]]
local function createHole(position)
    local success, holeModel = pcall(function()
        return game:GetService("InsertService"):LoadAsset(HOLE_ASSET_ID)
    end)

    if not success or not holeModel then
        warn("[ShovelSystem] Failed to load hole asset")
        return nil
    end

    local hole = holeModel:GetChildren()[1]
    if not hole then
        holeModel:Destroy()
        return nil
    end

    hole = hole:Clone()
    holeModel:Destroy()

    -- Position the hole ON TOP of terrain
    if hole:IsA("Model") and hole.PrimaryPart then
        local primaryPart = hole.PrimaryPart
        local size = primaryPart.Size
        local bottomOffset = size.Y / 2
        local adjustedPosition = position - Vector3.new(0, bottomOffset, 0)
        hole:MoveTo(adjustedPosition)
    elseif hole:IsA("BasePart") then
        local bottomOffset = hole.Size.Y / 2
        hole.Position = position - Vector3.new(0, bottomOffset, 0)
    else
        -- For models without PrimaryPart, try to find the lowest part
        local lowestPart = nil
        local lowestY = math.huge
        for _, part in ipairs(hole:GetDescendants()) do
            if part:IsA("BasePart") then
                local partBottom = part.Position.Y - part.Size.Y / 2
                if partBottom < lowestY then
                    lowestY = partBottom
                    lowestPart = part
                end
            end
        end
        if lowestPart then
            local offset = position.Y - lowestY
            hole:PivotTo(CFrame.new(position - Vector3.new(0, offset, 0)))
        else
            hole:PivotTo(CFrame.new(position))
        end
    end

    hole.Name = "DugHole"

    -- Parent to workspace
    local holesFolder = Workspace:FindFirstChild("DugHoles")
    if not holesFolder then
        holesFolder = Instance.new("Folder")
        holesFolder.Name = "DugHoles"
        holesFolder.Parent = Workspace
    end

    hole.Parent = holesFolder
    return hole
end

--[[
	Attempts to dig with the player's currently equipped shovel.
	Returns success:boolean, resultType:string?, resultData:table?, errorMessage:string?
]]
local function performDig(player)
    local userId = player.UserId

    -- Check cooldown
    if playerCooldowns[userId] and tick() - playerCooldowns[userId] < DIG_COOLDOWN then
        local remaining = DIG_COOLDOWN - (tick() - playerCooldowns[userId])
        return false, nil, nil, string.format("Need to wait %.1fs before digging again.", remaining)
    end

    -- Check if player has shovel equipped
    local character = player.Character
    if not character then
        return false, nil, nil, "Character not loaded."
    end

    local hasShovelEquipped = false

    local tool = character:FindFirstChildOfClass("Tool")
    if tool and tool.Name:lower():find("shovel") then
        hasShovelEquipped = true
    end

    if not hasShovelEquipped then
        local equippedToolType = player:GetAttribute("EquippedToolType")
        if equippedToolType and tostring(equippedToolType):lower() == "shovel" then
            hasShovelEquipped = true
        end
    end

    if not hasShovelEquipped then
        return false, nil, nil, "Equip a shovel to dig."
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false, nil, nil, "HumanoidRootPart missing."
    end

    -- Get dig position in front of player
    local digPos = rootPart.Position + (rootPart.CFrame.LookVector * 3)

    -- Raycast to find ground position
    local rayOrigin = digPos + Vector3.new(0, 5, 0)
    local rayDirection = Vector3.new(0, -20, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if not rayResult then
        return false, nil, nil, "Couldn't find ground to dig."
    end

    local holePosition = rayResult.Position + (rayResult.Normal * 0.2)

    -- Check if player already has a hole here
    if DigSpotManager.hasDugHole(player, holePosition) then
        return false, nil, nil, "There's already a hole here."
    end

    -- Handle the dig through DigSpotManager
    local success, resultType, resultData = DigSpotManager.handleDig(player, holePosition)

    local digSucceeded = false

    if success then
        digSucceeded = true

        -- Create the visual hole
        createHole(holePosition)

        -- Handle rewards based on result type
        if resultType == "fossil" and resultData then
            print(string.format("[ShovelSystem] 🦴 Player %s dug up fossil: %s", player.Name, resultData.itemId))
        elseif resultType == "bell" and resultData then
            local bellSuccess = CurrencyManager.addBells(player, resultData.amount)
            if bellSuccess then
                print(string.format("[ShovelSystem] 💰 Player %s dug up %d bells", player.Name, resultData.amount))
            else
                warn(
                    string.format(
                        "[ShovelSystem] ❌ Failed to add %d bells to player %s",
                        resultData.amount,
                        player.Name
                    )
                )
            end
        elseif resultType == "empty" then
            print(string.format("[ShovelSystem] 🕳️ Player %s dug an empty hole", player.Name))
        end
    else
        print(string.format("[ShovelSystem] ❌ Dig failed for player %s", player.Name))
    end

    playerCooldowns[userId] = tick()

    if digSucceeded then
        return true, resultType, resultData
    end

    return false, nil, nil, "Nothing was found."
end

--[[
	Initializes the shovel system
]]
function ShovelSystem.init()
    print("[ShovelSystem] 🔨 Initializing shovel system...")
    DigSpotManager.init()
    print("[ShovelSystem] ✅ Shovel system initialized")
end

function ShovelSystem.attemptDig(player)
    return performDig(player)
end

return ShovelSystem
