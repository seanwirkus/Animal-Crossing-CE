local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BalloonSpawner = {}
BalloonSpawner.activeBalloons = {}
BalloonSpawner.nextBalloonId = 1

-- Configuration
local SPAWN_INTERVAL = 120 -- Spawn a balloon every 2 minutes
local BALLOON_SPEED = 10 -- Studs per second
local BALLOON_HEIGHT = 60 -- Height above ground
local BALLOON_LIFETIME = 120 -- Despawn after 2 minutes if not popped
local SPAWN_DISTANCE = 200 -- Distance from map edge to spawn

-- Loot tables for presents
local PRESENT_LOOT = {
    -- Common items (70%)
    { weight = 20, itemId = "iron_nugget", minCount = 3, maxCount = 5 },
    { weight = 20, itemId = "stone", minCount = 5, maxCount = 10 },
    { weight = 15, itemId = "wood", minCount = 5, maxCount = 10 },
    { weight = 15, itemId = "clay", minCount = 3, maxCount = 5 },

    -- Uncommon items (20%)
    { weight = 10, itemId = "gold_nugget", minCount = 1, maxCount = 2 },
    { weight = 5, itemId = "star_fragment", minCount = 1, maxCount = 1 },
    { weight = 5, itemId = "large_star_fragment", minCount = 1, maxCount = 1 },

    -- Rare items (10%)
    { weight = 5, itemId = "nook_miles_ticket", minCount = 1, maxCount = 1 },
    { weight = 3, itemId = "golden_nugget", minCount = 1, maxCount = 1 },
    { weight = 2, itemId = "zodiac_fragment", minCount = 1, maxCount = 1 },
}

-- Get weighted random item from loot table
local function getRandomLoot()
    local totalWeight = 0
    for _, loot in ipairs(PRESENT_LOOT) do
        totalWeight = totalWeight + loot.weight
    end

    local roll = math.random() * totalWeight
    local currentWeight = 0

    for _, loot in ipairs(PRESENT_LOOT) do
        currentWeight = currentWeight + loot.weight
        if roll <= currentWeight then
            local count = math.random(loot.minCount, loot.maxCount)
            return loot.itemId, count
        end
    end

    -- Fallback
    return "iron_nugget", 3
end

-- Spawn a balloon at a random position
function BalloonSpawner.spawnBalloon()
    -- Try ReplicatedStorage first, then ServerStorage
    local balloonTemplate = ReplicatedStorage:FindFirstChild("BalloonPresent")
    if not balloonTemplate then
        local ServerStorage = game:GetService("ServerStorage")
        balloonTemplate = ServerStorage:FindFirstChild("BalloonPresent")
    end

    if not balloonTemplate then
        warn("[BalloonSpawner] ⚠️ BalloonPresent model not found in ReplicatedStorage or ServerStorage!")
        return nil
    end

    local balloonId = BalloonSpawner.nextBalloonId
    BalloonSpawner.nextBalloonId = BalloonSpawner.nextBalloonId + 1

    -- Clone the balloon model
    local balloon = balloonTemplate:Clone()
    balloon.Name = "Balloon_" .. balloonId

    -- Scale down the balloon and present by 25% (0.75x)
    local scaleFactor = 0.75
    for _, part in ipairs(balloon:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Size = part.Size * scaleFactor
        end
    end

    -- Adjust hitbox to be 1/2 height (upper part only)
    -- Find the hitbox part - check Present model first since mesh is inside it
    local hitboxPart = nil
    local presentModel = balloon:FindFirstChild("Present")
    if presentModel then
        -- Look for a part named "Hitbox" in Present model
        hitboxPart = presentModel:FindFirstChild("Hitbox")

        -- If no Hitbox found, check if there's a main part in Present that serves as hitbox
        if not hitboxPart then
            -- Look for parts that might be the hitbox (could be named "Present" or be the PrimaryPart)
            for _, child in ipairs(presentModel:GetChildren()) do
                if
                    child:IsA("BasePart")
                    and (child.Name == "Present" or child.Name == "Hitbox" or child == presentModel.PrimaryPart)
                then
                    hitboxPart = child
                    break
                end
            end
        end
    end

    -- If still not found, check root level
    if not hitboxPart then
        hitboxPart = balloon:FindFirstChild("Hitbox")
    end

    if hitboxPart and hitboxPart:IsA("BasePart") then
        local originalSize = hitboxPart.Size
        local originalCFrame = hitboxPart.CFrame

        -- Make height 1/2 of original
        local newSize = Vector3.new(originalSize.X, originalSize.Y * 0.5, originalSize.Z)
        hitboxPart.Size = newSize

        -- Position at upper half (move up by 1/4 of original height to center the smaller hitbox at top)
        local offsetY = originalSize.Y * 0.25
        hitboxPart.CFrame = originalCFrame * CFrame.new(0, offsetY, 0)

        print("[BalloonSpawner] ✅ Adjusted hitbox size to", newSize, "at upper half")
    end

    -- Random spawn position (edges of map)
    local side = math.random(1, 4) -- 1=North, 2=South, 3=East, 4=West
    local spawnX, spawnZ
    local targetX, targetZ

    if side == 1 then -- North to South
        spawnX = math.random(-100, 100)
        spawnZ = SPAWN_DISTANCE
        targetX = spawnX + math.random(-20, 20)
        targetZ = -SPAWN_DISTANCE
    elseif side == 2 then -- South to North
        spawnX = math.random(-100, 100)
        spawnZ = -SPAWN_DISTANCE
        targetX = spawnX + math.random(-20, 20)
        targetZ = SPAWN_DISTANCE
    elseif side == 3 then -- East to West
        spawnX = SPAWN_DISTANCE
        spawnZ = math.random(-100, 100)
        targetX = -SPAWN_DISTANCE
        targetZ = spawnZ + math.random(-20, 20)
    else -- West to East
        spawnX = -SPAWN_DISTANCE
        spawnZ = math.random(-100, 100)
        targetX = SPAWN_DISTANCE
        targetZ = spawnZ + math.random(-20, 20)
    end

    local spawnPosition = Vector3.new(spawnX, BALLOON_HEIGHT, spawnZ)
    local targetPosition = Vector3.new(targetX, BALLOON_HEIGHT, targetZ)

    -- Position the balloon
    local balloonPart = balloon:FindFirstChild("Balloon") or balloon:FindFirstChildWhichIsA("BasePart")
    if balloonPart then
        balloon.PrimaryPart = balloonPart
        balloonPart.CFrame = CFrame.new(spawnPosition)
        balloonPart.Anchored = true -- Start anchored
        balloonPart.CanCollide = false
        balloonPart.Transparency = 0 -- Make sure it's visible
    else
        warn("[BalloonSpawner] ⚠️ No Balloon part found in model!")
        balloon:Destroy()
        return nil
    end

    -- Position present parts relative to balloon BEFORE parenting
    local presentModel = balloon:FindFirstChild("Present")
    if presentModel then
        for _, child in ipairs(presentModel:GetDescendants()) do
            if child:IsA("BasePart") then
                -- Position 15 studs below balloon so the string/line is visible
                child.CFrame = balloonPart.CFrame * CFrame.new(0, -10, 0)
                child.Anchored = true
            end
        end
    end

    balloon.Parent = Workspace

    print("[BalloonSpawner] 🎈 Balloon spawned at", spawnPosition, "moving to", targetPosition)

    -- Now create welds
    if balloonPart and presentModel then
        -- Weld all present parts to the balloon
        local presentParts = {}
        for _, child in ipairs(presentModel:GetDescendants()) do
            if child:IsA("BasePart") then
                table.insert(presentParts, child)
            end
        end

        -- Create welds from balloon to all present parts
        for _, part in ipairs(presentParts) do
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = balloonPart
            weld.Part1 = part
            weld.Parent = balloonPart
        end

        -- Now unanchor everything (welds keep them together)
        balloonPart.Anchored = false
        for _, part in ipairs(presentParts) do
            part.Anchored = false
            part.Massless = true
            part.CanCollide = false
        end

        print("[BalloonSpawner] ✅ Welded", #presentParts, "present parts to balloon")
    elseif balloonPart then
        -- No present model, just unanchor balloon
        balloonPart.Anchored = false
        print("[BalloonSpawner] ⚠️ No Present model found, balloon spawned without present")
    end

    -- Calculate travel time based on distance
    local distance = (targetPosition - spawnPosition).Magnitude
    local _travelTime = distance / BALLOON_SPEED

    -- Generate loot for this balloon
    local lootItemId, lootCount = getRandomLoot()

    -- Store balloon data
    BalloonSpawner.activeBalloons[balloonId] = {
        model = balloon,
        spawnTime = tick(),
        lootItemId = lootItemId,
        lootCount = lootCount,
        isPopped = false,
    }

    print("[BalloonSpawner] 🎈 Spawned balloon", balloonId, "with", lootCount, "x", lootItemId)

    -- Move balloon across the sky
    local primaryPart = balloon.PrimaryPart
    if primaryPart then
        -- Make sure the balloon part is the anchor
        primaryPart.Anchored = false
        primaryPart.CanCollide = true -- Allow collision to prevent flying through map
        primaryPart.Massless = false
        primaryPart.CustomPhysicalProperties = PhysicalProperties.new(0.2, 0.3, 0.5)
        primaryPart.Transparency = 0 -- Ensure visible

        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Velocity = (targetPosition - spawnPosition).Unit * BALLOON_SPEED
        bodyVelocity.Parent = primaryPart

        local floatAttachment = Instance.new("Attachment")
        floatAttachment.Name = "FloatAttachment"
        floatAttachment.Parent = primaryPart

        local floatForce = Instance.new("VectorForce")
        floatForce.Name = "FloatForce"
        floatForce.Attachment0 = floatAttachment
        floatForce.RelativeTo = Enum.ActuatorRelativeTo.World
        floatForce.ApplyAtCenterOfMass = true
        local mass = math.max(primaryPart:GetMass(), 0.05)
        floatForce.Force = Vector3.new(0, mass * Workspace.Gravity, 0)
        floatForce.Parent = primaryPart

        -- Make all other balloon parts massless and welded
        for _, part in ipairs(balloon:GetDescendants()) do
            if part:IsA("BasePart") and part ~= primaryPart then
                part.CanCollide = true -- Allow collision
                part.Anchored = false
                part.Massless = true
            end
        end

        print("[BalloonSpawner] ✅ Balloon", balloonId, "moving with velocity", bodyVelocity.Velocity)

        -- Set up collision detection for balloon popping
        local balloonMesh = balloon:FindFirstChild("Balloon")
        if balloonMesh then
            balloonMesh.Touched:Connect(function(hit)
                BalloonSpawner.onBalloonHit(balloonId, hit)
            end)
        end
    end

    -- Auto-despawn after lifetime
    task.delay(BALLOON_LIFETIME, function()
        if BalloonSpawner.activeBalloons[balloonId] and not BalloonSpawner.activeBalloons[balloonId].isPopped then
            print("[BalloonSpawner] ⏱️ Balloon", balloonId, "despawned (timeout)")
            BalloonSpawner.removeBalloon(balloonId)
        end
    end)

    return balloonId
end

-- Handle balloon being hit
function BalloonSpawner.onBalloonHit(balloonId, hitPart)
    local balloonData = BalloonSpawner.activeBalloons[balloonId]
    if not balloonData or balloonData.isPopped then
        return
    end

    -- Check if hit by a projectile or slingshot (if hitPart is provided)
    -- If hitPart is nil, it means this was called from a server event and we should proceed
    if hitPart then
        local parentName = hitPart.Parent and hitPart.Parent.Name or ""
        local isProjectile = hitPart.Name == "Projectile"
            or hitPart.Name == "SlingshotProjectile"
            or parentName == "Slingshot"
        if not isProjectile then
            return
        end
    end

    print("[BalloonSpawner] 💥 Balloon", balloonId, "popped!")

    -- Mark as popped
    balloonData.isPopped = true

    -- Get balloon and present
    local balloon = balloonData.model
    local balloonMesh = balloon:FindFirstChild("Balloon")
    local present = balloon:FindFirstChild("Present")

    if not present then
        warn("[BalloonSpawner] ⚠️ Present not found in balloon!")
        BalloonSpawner.removeBalloon(balloonId)
        return
    end

    -- Pop effect - destroy balloon
    if balloonMesh then
        -- Particle effect
        local explosion = Instance.new("Explosion")
        explosion.BlastRadius = 0
        explosion.BlastPressure = 0
        explosion.Position = balloonMesh.Position
        explosion.Parent = Workspace

        balloonMesh:Destroy()
    end

    -- Detach present and make it fall
    present.Parent = Workspace
    present.Name = "FallingPresent_" .. balloonId

    -- Enable physics for all present parts
    for _, part in ipairs(present:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = true
            part.Massless = false
        end
    end

    -- Set primary part for present
    local presentPart = present.PrimaryPart or present:FindFirstChildWhichIsA("BasePart")
    if presentPart then
        present.PrimaryPart = presentPart

        -- Add ground detection
        presentPart.Touched:Connect(function(hit)
            if hit:IsA("Terrain") or (hit:IsA("BasePart") and hit.Name == "Baseplate") then
                BalloonSpawner.onPresentLanded(balloonId, present, presentPart.Position)
            end
        end)

        -- Add glow effect
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = 2
        pointLight.Range = 15
        pointLight.Color = Color3.fromRGB(255, 220, 100)
        pointLight.Parent = presentPart
    end

    -- Remove original balloon model
    task.delay(0.5, function()
        if balloon.Parent then
            balloon:Destroy()
        end
    end)
end

-- Handle present landing on ground
function BalloonSpawner.onPresentLanded(balloonId, present, position)
    local balloonData = BalloonSpawner.activeBalloons[balloonId]
    if not balloonData then
        return
    end

    print("[BalloonSpawner] 🎁 Present landed at", position)

    -- Wait a moment for physics to settle
    task.wait(0.5)

    -- Create dropped item at present location
    local itemId = balloonData.lootItemId
    local count = balloonData.lootCount

    -- Create visual dropped item
    BalloonSpawner.createDroppedItem(itemId, count, position)

    -- Get the createDroppedItem function from server (for backwards compatibility)
    local event = ReplicatedStorage:FindFirstChild("BalloonPresentDropped")
    if event then
        event:Fire(itemId, count, position)
    end

    -- Clean up present with particle effect
    local presentPart = present.PrimaryPart or present:FindFirstChildWhichIsA("BasePart")
    if presentPart then
        -- Sparkle effect
        local particles = Instance.new("ParticleEmitter")
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Rate = 50
        particles.Lifetime = NumberRange.new(1, 2)
        particles.Speed = NumberRange.new(5, 10)
        particles.SpreadAngle = Vector2.new(180, 180)
        particles.Parent = presentPart

        task.delay(1, function()
            particles.Enabled = false
            task.wait(2)
            if present.Parent then
                present:Destroy()
            end
        end)
    end

    -- Clean up balloon data
    task.delay(3, function()
        BalloonSpawner.removeBalloon(balloonId)
    end)
end

-- Create a dropped item visual at position
function BalloonSpawner.createDroppedItem(itemId, count, position)
    -- Create a glowing orb to represent the item
    local itemDrop = Instance.new("Part")
    itemDrop.Name = "DroppedItem"
    itemDrop.Shape = Enum.PartType.Ball
    itemDrop.Size = Vector3.new(2, 2, 2)
    itemDrop.Position = position + Vector3.new(0, 2, 0)
    itemDrop.Anchored = true
    itemDrop.CanCollide = false
    itemDrop.Material = Enum.Material.Neon
    itemDrop.BrickColor = BrickColor.new("Bright yellow")
    itemDrop.Parent = Workspace

    -- Add billboard label
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 150, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = itemDrop

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s x%d", itemId, count)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard

    -- Add proximity prompt for pickup
    local proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.ActionText = "Pick up"
    proximityPrompt.ObjectText = string.format("%s x%d", itemId, count)
    proximityPrompt.MaxActivationDistance = 10
    proximityPrompt.Parent = itemDrop

    proximityPrompt.Triggered:Connect(function(player)
        -- Add item to player inventory
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local inventoryRemote = remotes:FindFirstChild("InventoryEvent")
            if inventoryRemote then
                inventoryRemote:FireClient(player, "AddItem", { itemId = itemId, count = count })
                print(string.format("[BalloonSpawner] ✅ Gave %s x%d to %s", itemId, count, player.Name))
            end
        end

        -- Destroy the dropped item
        itemDrop:Destroy()
    end)

    -- Auto-despawn after 5 minutes
    task.delay(300, function()
        if itemDrop and itemDrop.Parent then
            itemDrop:Destroy()
        end
    end)

    print(string.format("[BalloonSpawner] 📦 Created dropped item: %s x%d at %s", itemId, count, tostring(position)))
end

-- Remove balloon from tracking
function BalloonSpawner.removeBalloon(balloonId)
    local balloonData = BalloonSpawner.activeBalloons[balloonId]
    if not balloonData then
        return
    end

    -- Clean up model
    if balloonData.model and balloonData.model.Parent then
        balloonData.model:Destroy()
    end

    BalloonSpawner.activeBalloons[balloonId] = nil
end

-- Start spawning balloons
function BalloonSpawner.start()
    print("[BalloonSpawner] 🎈 Starting balloon spawner...")
    print("[BalloonSpawner] ℹ️ Debug mode: Spawning balloons every", SPAWN_INTERVAL, "seconds")

    -- Spawn balloons on normal interval
    while true do
        task.wait(SPAWN_INTERVAL)
        BalloonSpawner.spawnBalloon()
    end
end

return BalloonSpawner
