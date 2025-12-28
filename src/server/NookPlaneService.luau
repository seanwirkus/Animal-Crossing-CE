--[[
    NookPlaneService.luau
    Handles delivery of purchased items via NookPlane (DAL plane)
    - Plane flies over player's position
    - Drops present package within 210 studs
    - Delivers within 30 seconds of purchase
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local NookPlaneService = {}
NookPlaneService.pendingDeliveries = {} -- { [playerId] = { deliveries = {}, plane = nil } }
NookPlaneService.addItemToInventory = nil
NookPlaneService.deliveryRemote = nil

-- Configuration
local DELIVERY_TIME = 15 -- Seconds before plane arrives (not 30 since user wants fast)
local DROP_RADIUS = 150 -- Max distance from player to drop (210 studs max, keep closer)
local PLANE_HEIGHT = 120 -- Height the plane flies at
local PLANE_SPEED = 80 -- Studs per second
local PRESENT_FALL_SPEED = 40 -- How fast presents fall
local PLANE_YAW_OFFSET = math.rad(90) -- Rotate plane to align template orientation (right wing was front)

-- Try to get NookPlane model from ReplicatedStorage, fallback to creating one
local function createPlane()
    -- First, try to find the NookPlane model in ReplicatedStorage
    local nookPlaneTemplate = ReplicatedStorage:FindFirstChild("NookPlane")

    if nookPlaneTemplate and nookPlaneTemplate:IsA("Model") then
        -- Clone the existing model
        local plane = nookPlaneTemplate:Clone()
        plane.Name = "NookPlane_Delivery"

        -- Make sure all parts are anchored and non-collidable for flight
        for _, part in ipairs(plane:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.CanCollide = false
            end
        end

        -- Ensure there's a PrimaryPart
        if not plane.PrimaryPart then
            local body = plane:FindFirstChild("Body") or plane:FindFirstChildWhichIsA("BasePart")
            if body then
                plane.PrimaryPart = body
            end
        end

        if plane.PrimaryPart then
            print("[NookPlaneService] ✈️ Using NookPlane model from ReplicatedStorage")
            return plane
        end

        warn("[NookPlaneService] ⚠️ NookPlane model missing BasePart; falling back to simple plane")
        plane:Destroy()
    end

    -- Fallback: Create a simple plane model
    print("[NookPlaneService] ⚠️ NookPlane model not found in ReplicatedStorage, creating fallback")

    local plane = Instance.new("Model")
    plane.Name = "NookPlane_Delivery"

    -- Main body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(16, 4, 40)
    body.BrickColor = BrickColor.new("Teal")
    body.Material = Enum.Material.SmoothPlastic
    body.Anchored = true
    body.CanCollide = false
    body.Parent = plane

    -- Wings
    local leftWing = Instance.new("Part")
    leftWing.Name = "LeftWing"
    leftWing.Size = Vector3.new(30, 1, 10)
    leftWing.BrickColor = BrickColor.new("Teal")
    leftWing.Material = Enum.Material.SmoothPlastic
    leftWing.Anchored = true
    leftWing.CanCollide = false
    leftWing.CFrame = body.CFrame * CFrame.new(-15, 0, -5)
    leftWing.Parent = plane

    local rightWing = Instance.new("Part")
    rightWing.Name = "RightWing"
    rightWing.Size = Vector3.new(30, 1, 10)
    rightWing.BrickColor = BrickColor.new("Teal")
    rightWing.Material = Enum.Material.SmoothPlastic
    rightWing.Anchored = true
    rightWing.CanCollide = false
    rightWing.CFrame = body.CFrame * CFrame.new(15, 0, -5)
    rightWing.Parent = plane

    -- Tail
    local tail = Instance.new("Part")
    tail.Name = "Tail"
    tail.Size = Vector3.new(2, 8, 6)
    tail.BrickColor = BrickColor.new("Teal")
    tail.Material = Enum.Material.SmoothPlastic
    tail.Anchored = true
    tail.CanCollide = false
    tail.CFrame = body.CFrame * CFrame.new(0, 4, 15)
    tail.Parent = plane

    -- DAL Logo (simple text using SurfaceGui)
    local logoDecal = Instance.new("SurfaceGui")
    logoDecal.Face = Enum.NormalId.Right
    logoDecal.Parent = body

    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.BackgroundTransparency = 1
    logoText.Text = "DAL"
    logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    logoText.TextScaled = true
    logoText.Font = Enum.Font.GothamBold
    logoText.Parent = logoDecal

    local logoDecal2 = Instance.new("SurfaceGui")
    logoDecal2.Face = Enum.NormalId.Left
    logoDecal2.Parent = body

    local logoText2 = Instance.new("TextLabel")
    logoText2.Size = UDim2.fromScale(1, 1)
    logoText2.BackgroundTransparency = 1
    logoText2.Text = "DAL"
    logoText2.TextColor3 = Color3.fromRGB(255, 255, 255)
    logoText2.TextScaled = true
    logoText2.Font = Enum.Font.GothamBold
    logoText2.Parent = logoDecal2

    -- Propeller (simple spinning part)
    local propeller = Instance.new("Part")
    propeller.Name = "Propeller"
    propeller.Size = Vector3.new(8, 1, 1)
    propeller.BrickColor = BrickColor.new("Institutional white")
    propeller.Material = Enum.Material.SmoothPlastic
    propeller.Anchored = true
    propeller.CanCollide = false
    propeller.CFrame = body.CFrame * CFrame.new(0, 0, -21)
    propeller.Parent = plane

    plane.PrimaryPart = body
    return plane
end

-- Create a present package
local function createPresent(itemId, count)
    local present = Instance.new("Model")
    present.Name = "DeliveryPresent_" .. itemId

    -- Box
    local box = Instance.new("Part")
    box.Name = "Box"
    box.Size = Vector3.new(3, 3, 3)
    box.BrickColor = BrickColor.new("Bright yellow")
    box.Material = Enum.Material.SmoothPlastic
    box.Anchored = true
    box.CanCollide = false
    box.Parent = present

    -- Ribbon
    local ribbonH = Instance.new("Part")
    ribbonH.Name = "RibbonH"
    ribbonH.Size = Vector3.new(3.2, 0.5, 0.5)
    ribbonH.BrickColor = BrickColor.new("Bright red")
    ribbonH.Material = Enum.Material.SmoothPlastic
    ribbonH.Anchored = true
    ribbonH.CanCollide = false
    ribbonH.CFrame = box.CFrame * CFrame.new(0, 1.5, 0)
    ribbonH.Parent = present

    local ribbonV = Instance.new("Part")
    ribbonV.Name = "RibbonV"
    ribbonV.Size = Vector3.new(0.5, 0.5, 3.2)
    ribbonV.BrickColor = BrickColor.new("Bright red")
    ribbonV.Material = Enum.Material.SmoothPlastic
    ribbonV.Anchored = true
    ribbonV.CanCollide = false
    ribbonV.CFrame = box.CFrame * CFrame.new(0, 1.5, 0)
    ribbonV.Parent = present

    -- Parachute
    local chute = Instance.new("Part")
    chute.Name = "Parachute"
    chute.Size = Vector3.new(6, 0.5, 6)
    chute.BrickColor = BrickColor.new("Institutional white")
    chute.Material = Enum.Material.Fabric
    chute.Anchored = true
    chute.CanCollide = false
    chute.Shape = Enum.PartType.Ball
    chute.Size = Vector3.new(8, 4, 8)
    chute.CFrame = box.CFrame * CFrame.new(0, 6, 0)
    chute.Parent = present

    -- Strings connecting parachute to box
    local function createString(offset)
        local str = Instance.new("Part")
        str.Name = "String"
        str.Size = Vector3.new(0.1, 5, 0.1)
        str.BrickColor = BrickColor.new("Brown")
        str.Material = Enum.Material.Fabric
        str.Anchored = true
        str.CanCollide = false
        str.CFrame = box.CFrame * CFrame.new(offset.X, 3.5, offset.Z) * CFrame.Angles(math.rad(offset.Angle), 0, 0)
        str.Parent = present
        return str
    end

    createString({X = 1.5, Z = 1.5, Angle = 15})
    createString({X = -1.5, Z = 1.5, Angle = 15})
    createString({X = 1.5, Z = -1.5, Angle = -15})
    createString({X = -1.5, Z = -1.5, Angle = -15})

    -- Store item data
    present:SetAttribute("ItemId", itemId)
    present:SetAttribute("Count", count)

    present.PrimaryPart = box
    return present
end

-- Queue a delivery for a player
function NookPlaneService.queueDelivery(player, itemId, count)
    local playerId = player.UserId

    if not NookPlaneService.pendingDeliveries[playerId] then
        NookPlaneService.pendingDeliveries[playerId] = {
            deliveries = {},
            planeActive = false,
            scheduledTime = 0,
        }
    end

    local playerData = NookPlaneService.pendingDeliveries[playerId]

    table.insert(playerData.deliveries, {
        itemId = itemId,
        count = count,
        queuedAt = os.time(),
    })

    -- Schedule plane if not already scheduled
    if not playerData.planeActive and #playerData.deliveries > 0 then
        playerData.scheduledTime = os.time() + DELIVERY_TIME
        playerData.planeActive = true

        -- Notify client about incoming delivery
        if NookPlaneService.deliveryRemote then
            NookPlaneService.deliveryRemote:FireClient(player, "DeliveryScheduled", {
                arrivalTime = DELIVERY_TIME,
                items = playerData.deliveries,
            })
        end

        -- Start delivery coroutine
        task.spawn(function()
            task.wait(DELIVERY_TIME)
            NookPlaneService.executeDelivery(player)
        end)
    end

    return true
end

-- Get delivery status for a player
function NookPlaneService.getDeliveryStatus(player)
    local playerId = player.UserId
    local playerData = NookPlaneService.pendingDeliveries[playerId]

    if not playerData or #playerData.deliveries == 0 then
        return {
            hasDeliveries = false,
            items = {},
            timeRemaining = 0,
        }
    end

    local timeRemaining = math.max(0, playerData.scheduledTime - os.time())

    return {
        hasDeliveries = true,
        items = playerData.deliveries,
        timeRemaining = timeRemaining,
        planeActive = playerData.planeActive,
    }
end

-- Execute the delivery (fly plane over and drop presents)
function NookPlaneService.executeDelivery(player)
    local playerId = player.UserId
    local playerData = NookPlaneService.pendingDeliveries[playerId]

    if not playerData or #playerData.deliveries == 0 then
        return
    end

    -- Get player position
    local character = player.Character
    if not character then
        -- Player left, cancel delivery and refund items later
        print("[NookPlaneService] Player not in game, retrying delivery in 10s")
        task.wait(10)
        NookPlaneService.executeDelivery(player)
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        task.wait(2)
        NookPlaneService.executeDelivery(player)
        return
    end

    local playerPos = rootPart.Position

    -- Notify player
    if NookPlaneService.deliveryRemote then
        NookPlaneService.deliveryRemote:FireClient(player, "PlaneArriving", {})
    end

    -- Create plane
    local plane = createPlane()

    -- Calculate flight path (fly from one side to the other over player)
    local direction = Vector3.new(1, 0, 0.3).Unit -- Slightly angled path
    local startPos = playerPos + Vector3.new(0, PLANE_HEIGHT, 0) - direction * 300
    local endPos = playerPos + Vector3.new(0, PLANE_HEIGHT, 0) + direction * 300
    local dropPos = playerPos + Vector3.new(0, PLANE_HEIGHT, 0)

    plane:SetPrimaryPartCFrame(CFrame.new(startPos, endPos) * CFrame.Angles(0, PLANE_YAW_OFFSET, 0))
    plane.Parent = Workspace

    -- Calculate drop point (within DROP_RADIUS of player)
    local dropOffset = Vector3.new(
        (math.random() - 0.5) * DROP_RADIUS * 2,
        0,
        (math.random() - 0.5) * DROP_RADIUS * 2
    )
    local presentDropPos = playerPos + dropOffset

    -- Raycast to find ground
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {character, plane}

    local groundRay = Workspace:Raycast(
        Vector3.new(presentDropPos.X, playerPos.Y + 50, presentDropPos.Z),
        Vector3.new(0, -200, 0),
        rayParams
    )

    local groundY = playerPos.Y
    if groundRay then
        groundY = groundRay.Position.Y
    end

    -- Fly the plane
    local flightDistance = (endPos - startPos).Magnitude
    local flightTime = flightDistance / PLANE_SPEED
    local dropDistance = (dropPos - startPos).Magnitude
    local dropTime = dropDistance / PLANE_SPEED

    local startTime = tick()
    local hasDropped = false
    local deliveriesToDrop = table.clone(playerData.deliveries)

    -- Clear pending deliveries
    playerData.deliveries = {}
    playerData.planeActive = false

    -- Animate plane flight
    local planeConnection
    planeConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / flightTime, 1)

        -- Lerp position
        local currentPos = startPos:Lerp(endPos, progress)
        plane:SetPrimaryPartCFrame(CFrame.new(currentPos, endPos) * CFrame.Angles(0, PLANE_YAW_OFFSET, 0))

        -- Spin propeller
        local propeller = plane:FindFirstChild("Propeller")
        if propeller then
            propeller.CFrame = propeller.CFrame * CFrame.Angles(0, 0, math.rad(15))
        end

        -- Drop presents when over player
        if not hasDropped and elapsed >= dropTime then
            hasDropped = true

            -- Drop all presents
            for i, delivery in ipairs(deliveriesToDrop) do
                task.spawn(function()
                    task.wait(i * 0.3) -- Stagger drops slightly

                    local offset = Vector3.new(
                        (math.random() - 0.5) * 20,
                        0,
                        (math.random() - 0.5) * 20
                    )

                    local present = createPresent(delivery.itemId, delivery.count)
                    local dropStartPos = currentPos + offset + Vector3.new(0, -5, 0)
                    present:SetPrimaryPartCFrame(CFrame.new(dropStartPos))
                    present.Parent = Workspace

                    -- Fall animation
                    local targetY = groundY + 2
                    local fallDistance = dropStartPos.Y - targetY
                    local fallTime = fallDistance / PRESENT_FALL_SPEED

                    local presentStart = tick()
                    local presentConnection
                    presentConnection = RunService.Heartbeat:Connect(function()
                        local fallElapsed = tick() - presentStart
                        local fallProgress = math.min(fallElapsed / fallTime, 1)

                        local currentY = dropStartPos.Y - (dropStartPos.Y - targetY) * fallProgress
                        local sway = math.sin(fallElapsed * 3) * 2 * (1 - fallProgress)

                        present:SetPrimaryPartCFrame(CFrame.new(
                            dropStartPos.X + sway,
                            currentY,
                            dropStartPos.Z + sway * 0.5
                        ))

                        if fallProgress >= 1 then
                            presentConnection:Disconnect()

                            -- Present landed - make it collectible
                            NookPlaneService.makePresentCollectible(present, player, delivery.itemId, delivery.count)
                        end
                    end)
                end)
            end

            -- Notify player
            if NookPlaneService.deliveryRemote then
                NookPlaneService.deliveryRemote:FireClient(player, "PackagesDropped", {
                    count = #deliveriesToDrop,
                })
            end
        end

        -- End flight
        if progress >= 1 then
            planeConnection:Disconnect()
            plane:Destroy()
        end
    end)
end

-- Make a present collectible
function NookPlaneService.makePresentCollectible(present, player, itemId, count)
    local box = present.PrimaryPart
    if not box then return end

    -- Remove parachute after landing
    task.wait(0.5)
    local chute = present:FindFirstChild("Parachute")
    if chute then
        local fadeOut = TweenService:Create(chute, TweenInfo.new(0.5), {Transparency = 1})
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            chute:Destroy()
        end)
    end

    for _, str in ipairs(present:GetChildren()) do
        if str.Name == "String" then
            str:Destroy()
        end
    end

    -- Make box collidable and collectible
    box.Anchored = false
    box.CanCollide = true

    -- Add touch detection
    local collected = false
    box.Touched:Connect(function(hit)
        if collected then return end

        local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
        if hitPlayer and hitPlayer == player then
            collected = true

            -- Add item to inventory
            if NookPlaneService.addItemToInventory then
                local success, err = NookPlaneService.addItemToInventory(player, {
                    itemId = itemId,
                    count = count,
                })

                if success then
                    print("[NookPlaneService] Delivered item:", itemId, "x" .. count, "to", player.Name)

                    -- Notify player
                    if NookPlaneService.deliveryRemote then
                        NookPlaneService.deliveryRemote:FireClient(player, "ItemCollected", {
                            itemId = itemId,
                            count = count,
                        })
                    end
                else
                    print("[NookPlaneService] Failed to deliver item:", err)
                    -- Inventory full - item stays on ground
                    collected = false
                    return
                end
            end

            -- Animate collection
            local collectTween = TweenService:Create(box, TweenInfo.new(0.3), {
                Size = Vector3.new(0.1, 0.1, 0.1),
                Transparency = 1,
            })
            collectTween:Play()
            collectTween.Completed:Connect(function()
                present:Destroy()
            end)
        end
    end)

    -- Auto-collect after 2 minutes or despawn after 5 minutes
    task.spawn(function()
        task.wait(120) -- 2 minutes
        if present.Parent and not collected then
            -- Auto-add to inventory if player is still in game
            if player.Parent and NookPlaneService.addItemToInventory then
                collected = true
                local success = NookPlaneService.addItemToInventory(player, {
                    itemId = itemId,
                    count = count,
                })

                if success then
                    print("[NookPlaneService] Auto-delivered expired item to", player.Name)
                    if NookPlaneService.deliveryRemote then
                        NookPlaneService.deliveryRemote:FireClient(player, "ItemAutoCollected", {
                            itemId = itemId,
                            count = count,
                        })
                    end
                end
            end

            if present.Parent then
                present:Destroy()
            end
        end
    end)
end

-- Initialize the service
function NookPlaneService.initialize(remoteEventsFolder, addItemFunc)
    NookPlaneService.addItemToInventory = addItemFunc

    -- Create or get delivery remote
    local deliveryRemote = remoteEventsFolder:FindFirstChild("NookPlaneDelivery")
    if not deliveryRemote then
        deliveryRemote = Instance.new("RemoteEvent")
        deliveryRemote.Name = "NookPlaneDelivery"
        deliveryRemote.Parent = remoteEventsFolder
    end
    NookPlaneService.deliveryRemote = deliveryRemote

    -- Handle client requests for delivery status
    deliveryRemote.OnServerEvent:Connect(function(player, action)
        if action == "GetStatus" then
            local status = NookPlaneService.getDeliveryStatus(player)
            deliveryRemote:FireClient(player, "DeliveryStatus", status)
        end
    end)

    print("[NookPlaneService] Initialized")
    return NookPlaneService
end

-- Cleanup when player leaves
function NookPlaneService.onPlayerRemoved(player)
    local playerId = player.UserId
    -- Keep pending deliveries for reconnection (could save to datastore)
    -- For now, just clean up
    NookPlaneService.pendingDeliveries[playerId] = nil
end

return NookPlaneService
