--[[
	ShovelSystem.luau

	Handles shovel digging mechanics:
	- Digging holes in the ground
	- Finding buried items/bells through DigSpotManager
	- Filling holes back in
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	Handles a player digging
]]
local function handleDig(player)
    local userId = player.UserId

    -- Check cooldown
    if playerCooldowns[userId] and tick() - playerCooldowns[userId] < DIG_COOLDOWN then
        return
    end

    -- Check if player has shovel equipped
    local character = player.Character
    if not character then
        return
    end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool or not tool.Name:lower():find("shovel") then
        return -- Not holding a shovel
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
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
        return
    end

    local holePosition = rayResult.Position + (rayResult.Normal * 0.2)

    -- Check if player already has a hole here
    if DigSpotManager.hasDugHole(player, holePosition) then
        return -- Can't dig where there's already a hole
    end

    -- Handle the dig through DigSpotManager
    local success, resultType, resultData = DigSpotManager.handleDig(player, holePosition)

    if success then
        -- Create the visual hole
        createHole(holePosition)

        -- Handle rewards based on result type
        if resultType == "fossil" and resultData then
            -- TODO: Add fossil to inventory
            print(string.format("[ShovelSystem] 🦴 Player %s dug up fossil: %s", player.Name, resultData.itemId))
        elseif resultType == "bell" and resultData then
            -- Add bells to currency
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

        -- Fire event to client for visual feedback
        local digEvent = ReplicatedStorage:FindFirstChild("ShovelDig")
        if digEvent then
            digEvent:FireClient(player, resultType, resultData)
        end
    else
        print(string.format("[ShovelSystem] ❌ Dig failed for player %s", player.Name))
    end

    -- Set cooldown
    playerCooldowns[userId] = tick()
end

--[[
	Initializes the shovel system
]]
function ShovelSystem.init()
    print("[ShovelSystem] 🔨 Initializing shovel system...")

    -- Create RemoteEvent for shovel actions FIRST (before DigSpotManager needs it)
    local shovelEvent = ReplicatedStorage:FindFirstChild("ShovelDig")
    if not shovelEvent then
        shovelEvent = Instance.new("RemoteEvent")
        shovelEvent.Name = "ShovelDig"
        shovelEvent.Parent = ReplicatedStorage
        print("[ShovelSystem] ✅ Created ShovelDig RemoteEvent")
    end

    -- Initialize DigSpotManager (it will use the RemoteEvent we just created)
    DigSpotManager.init()

    -- Listen for dig requests
    shovelEvent.OnServerEvent:Connect(function(player)
        handleDig(player)
    end)

    print("[ShovelSystem] ✅ Shovel system initialized")
end

return ShovelSystem
