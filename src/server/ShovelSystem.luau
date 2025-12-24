--[[
	ShovelSystem.luau

	Handles shovel digging mechanics:
	- Digging holes in the ground
	- Finding buried items/bells through DigSpotManager
	- Filling holes back in
]]

local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
local holesFolder: Folder? = nil

local function getHolesFolder(): Folder
    if holesFolder and holesFolder.Parent then
        return holesFolder
    end

    local folder = Workspace:FindFirstChild("DugHoles")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "DugHoles"
        folder.Parent = Workspace
    end

    holesFolder = folder
    return folder
end

-- Grid alignment for holes
local GRID_SIZE = 8 -- Align holes to 8-stud grid (more space between holes)

local function snapToGrid(position: Vector3): Vector3
    local snappedX = math.floor(position.X / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
    local snappedZ = math.floor(position.Z / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
    return Vector3.new(snappedX, position.Y, snappedZ)
end

local function placeModelAtPosition(model: Instance, position: Vector3, surfaceNormal: Vector3?)
    -- Snap to grid first (X and Z only, keep Y from original position for raycast start)
    local originalY = position.Y
    local snappedPos = snapToGrid(position)
    
    -- Use snapped X/Z but start raycast higher up to ensure we find ground
    local rayOrigin = Vector3.new(snappedPos.X, math.max(originalY, position.Y) + 50, snappedPos.Z)
    local rayDirection = Vector3.new(0, -200, 0) -- Cast far down
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { Workspace.Terrain }
    raycastParams.RespectCanCollide = false -- Allow passing through non-collidable parts
    
    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if not rayResult then
        warn("[ShovelSystem] ⚠️ Could not find ground at position:", snappedPos)
        return false
    end
    
    -- Use the actual ground position from raycast
    position = rayResult.Position
    surfaceNormal = rayResult.Normal or Vector3.new(0, 1, 0)
    
    -- Check if surface is flat enough
    local upVector = Vector3.new(0, 1, 0)
    local angle = math.acos(math.clamp(surfaceNormal:Dot(upVector), -1, 1))
    
    -- Only place on relatively flat surfaces (less than 15 degrees slope)
    if angle > math.rad(15) then
        warn("[ShovelSystem] ⚠️ Surface too steep - cannot dig here (angle:", math.deg(angle), "degrees)")
        return false
    end
    
    if model:IsA("Model") then
        local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") or model:FindFirstChildWhichIsA("MeshPart")
        if not primary then
            warn("[ShovelSystem] ⚠️ Model has no primary part, BasePart, or MeshPart")
            return false
        end

        model.PrimaryPart = primary
        
        -- Calculate bottom offset based on the part's actual size
        local bottomOffset = primary.Size.Y / 2
        
        -- Position hole ON TOP of terrain - raise it higher so it sits properly on surface
        local finalPosition = position + (surfaceNormal * 0.5) -- Larger offset to sit on top of terrain
        
        -- Use PivotTo to position the model so bottom sits on ground
        -- Add extra Y offset to ensure it's above the terrain surface (no grass showing through)
        model:PivotTo(CFrame.new(finalPosition - Vector3.new(0, bottomOffset - 0.6, 0)))
        
        -- Anchor all parts so they don't fall and make them visible
        -- First pass: identify the primary part (largest part, usually the hole itself)
        local primaryPart = model.PrimaryPart
        local allParts = {}
        local largestPart = nil
        local largestSize = 0
        
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                table.insert(allParts, part)
                local size = part.Size.X * part.Size.Y * part.Size.Z
                if size > largestSize then
                    largestSize = size
                    largestPart = part
                end
            end
        end
        
        -- Second pass: hide everything except the main hole part(s)
        for _, part in ipairs(allParts) do
            part.Anchored = true
            part.CanCollide = false
            
            -- Aggressively hide any gray/default/small parts
            local isGray = part.Material == Enum.Material.Plastic or 
                          (part.Color.R > 0.7 and part.Color.G > 0.7 and part.Color.B > 0.7)
            
            local isSmall = part.Size.Magnitude < 2 -- Hide parts smaller than 2 studs
            local isDefaultName = part.Name == "Handle" or 
                                  part.Name == "PrimaryPart" or 
                                  part.Name:lower():find("part") or 
                                  part.Name:lower():find("stud") or
                                  part.Name:lower():find("handle") or
                                  part.Name == "Part"
            
            -- Hide if it's gray, small, or has a default name (unless it's the largest part)
            if (isGray or isSmall or isDefaultName) and part ~= largestPart then
                part.Transparency = 1 -- Fully hide gray/small/default parts
            else
                part.Transparency = 0 -- Show actual hole parts
            end
        end
        
        print("[ShovelSystem] ✅ Positioned hole at:", finalPosition, "on surface with normal:", surfaceNormal)
        return true
    elseif model:IsA("BasePart") or model:IsA("MeshPart") then
        local bottomOffset = model.Size.Y / 2
        local finalPosition = position + (surfaceNormal * 0.5) -- Higher offset
        model.Position = finalPosition - Vector3.new(0, bottomOffset - 0.6, 0) -- Raise it up more (no grass showing)
        model.Anchored = true
        model.CanCollide = false
        model.Transparency = 0
        return true
    else
        -- Fallback: find any BasePart or MeshPart and use it
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                local bottomOffset = part.Size.Y / 2
                local finalPosition = position + (surfaceNormal * 0.5) -- Higher offset
                model:PivotTo(CFrame.new(finalPosition - Vector3.new(0, bottomOffset - 0.6, 0))) -- Raise it up more (no grass showing)
                
                -- Anchor all parts
                for _, p in ipairs(model:GetDescendants()) do
                    if p:IsA("BasePart") or p:IsA("MeshPart") then
                        p.Anchored = true
                        p.CanCollide = false
                        p.Transparency = 0
                    end
                end
                return true
            end
        end
    end
    
    warn("[ShovelSystem] ⚠️ Could not place model - no valid parts found")
    return false
end

local function createFallbackHole(position: Vector3, surfaceNormal: Vector3?)
    -- Snap to grid
    local snappedPos = snapToGrid(position)
    
    -- Find ground at grid position
    local rayOrigin = Vector3.new(snappedPos.X, position.Y + 50, snappedPos.Z)
    local rayDirection = Vector3.new(0, -200, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { Workspace.Terrain }
    raycastParams.RespectCanCollide = false
    
    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if not rayResult then
        warn("[ShovelSystem] ⚠️ Could not find ground for fallback hole")
        return nil
    end
    
    position = rayResult.Position
    surfaceNormal = rayResult.Normal or Vector3.new(0, 1, 0)
    
    -- Check surface angle
    local upVector = Vector3.new(0, 1, 0)
    local angle = math.acos(math.clamp(surfaceNormal:Dot(upVector), -1, 1))
    
    if angle > math.rad(15) then
        warn("[ShovelSystem] ⚠️ Surface too steep for fallback hole")
        return nil
    end
    
    -- Create fallback hole but make it transparent so it's invisible
    -- This ensures the dig spot system still works even if HoleDug model is missing
    local holePart = Instance.new("Part")
    holePart.Name = "DugHole"
    holePart.Shape = Enum.PartType.Cylinder
    holePart.Size = Vector3.new(3.6, 0.35, 3.6)
    holePart.Material = Enum.Material.Sand
    holePart.Color = Color3.fromRGB(124, 92, 70)
    holePart.Anchored = true
    holePart.CanCollide = false
    holePart.Transparency = 1 -- Fully transparent so gray stud is invisible
    
    -- Position hole ON TOP of terrain (raise it higher - no grass showing through)
    local bottomOffset = holePart.Size.Y / 2
    local finalPosition = position + (surfaceNormal * 0.5) -- Higher offset to sit on top
    holePart.CFrame = CFrame.new(finalPosition - Vector3.new(0, bottomOffset - 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
    holePart.Parent = getHolesFolder()
    
    print("[ShovelSystem] ✅ Created transparent fallback hole at:", finalPosition)
    return holePart
end

local function createHole(position, surfaceNormal: Vector3?)
    local folder = getHolesFolder()

    -- First, try to get HoleDug model from ReplicatedStorage
    local holeModel = ReplicatedStorage:FindFirstChild("HoleDug")
    if holeModel then
        -- Handle both Model and MeshPart/Part cases
        local hole = nil
        if holeModel:IsA("Model") then
            hole = holeModel:Clone()
        elseif holeModel:IsA("BasePart") or holeModel:IsA("MeshPart") then
            -- If it's a single part, wrap it in a model
            hole = Instance.new("Model")
            holeModel:Clone().Parent = hole
            hole.PrimaryPart = hole:FindFirstChildWhichIsA("BasePart")
        else
            warn("[ShovelSystem] ⚠️ HoleDug is not a Model or BasePart, it's a", holeModel.ClassName)
        end
        
        if hole then
            hole.Name = "DugHole"
            
            -- Ensure all parts are visible and properly configured BEFORE placing
            for _, part in ipairs(hole:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.Anchored = true
                    part.CanCollide = false
                    
                    -- Hide any gray/default parts that might be in the middle (PrimaryPart, Handle, etc.)
                    local isGray = part.Material == Enum.Material.Plastic or 
                                  part.Color.R > 0.7 and part.Color.G > 0.7 and part.Color.B > 0.7
                    
                    if part.Name == "Handle" or 
                       part.Name == "PrimaryPart" or 
                       part.Name:lower():find("part") or 
                       part.Name:lower():find("stud") or
                       isGray then
                        part.Transparency = 1 -- Hide gray/default parts
                    else
                        part.Transparency = 0 -- Show actual hole parts
                    end
                end
            end
            
            -- Ensure PrimaryPart is set
            if not hole.PrimaryPart then
                local firstPart = hole:FindFirstChildWhichIsA("BasePart") or hole:FindFirstChildWhichIsA("MeshPart")
                if firstPart then
                    hole.PrimaryPart = firstPart
                end
            end
            
            local success = placeModelAtPosition(hole, position, surfaceNormal)
            if success then
                hole.Parent = folder
                print("[ShovelSystem] ✅ Used HoleDug model from ReplicatedStorage (parts:", #hole:GetDescendants(), ")")
                return hole
            else
                warn("[ShovelSystem] ⚠️ Failed to place HoleDug model at position")
                hole:Destroy()
            end
        end
    else
        warn("[ShovelSystem] ⚠️ HoleDug model not found in ReplicatedStorage")
    end

    -- Fallback: Try to load from asset ID
    local success, loadedModel = pcall(function()
        return InsertService:LoadAsset(HOLE_ASSET_ID)
    end)

    if success and loadedModel then
        local child = loadedModel:GetChildren()[1]
        if child then
            local hole = child:Clone()
            loadedModel:Destroy()
            hole.Name = "DugHole"
            
            -- Ensure all parts are visible (hide gray parts)
            for _, part in ipairs(hole:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.Anchored = true
                    part.CanCollide = false
                    
                    -- Hide gray/default parts
                    local isGray = part.Material == Enum.Material.Plastic or 
                                  part.Color.R > 0.7 and part.Color.G > 0.7 and part.Color.B > 0.7
                    
                    if part.Name == "Handle" or 
                       part.Name == "PrimaryPart" or 
                       part.Name:lower():find("part") or 
                       part.Name:lower():find("stud") or
                       isGray then
                        part.Transparency = 1
                    else
                        part.Transparency = 0
                    end
                end
            end
            
            if not hole.PrimaryPart then
                local firstPart = hole:FindFirstChildWhichIsA("BasePart") or hole:FindFirstChildWhichIsA("MeshPart")
                if firstPart then
                    hole.PrimaryPart = firstPart
                end
            end
            
            local placeSuccess = placeModelAtPosition(hole, position, surfaceNormal)
            if placeSuccess then
                hole.Parent = folder
                print("[ShovelSystem] ✅ Used hole model from asset")
                return hole
            else
                hole:Destroy()
            end
        end
        loadedModel:Destroy()
    else
        warn("[ShovelSystem] Failed to load hole asset; using fallback")
    end

    -- Last resort: Create fallback hole
    warn("[ShovelSystem] ⚠️ HoleDug model not found in ReplicatedStorage, using fallback cylinder")
    return createFallbackHole(position, surfaceNormal)
end

--[[
	Digs up a tree - scales it down, adds to inventory, and spawns a hole
]]
local function performTreeDig(player, treeModel)
    if not treeModel or not treeModel.Parent then
        return false, nil, nil, "Tree not found."
    end

    -- Get tree position (bottom of tree)
    local treePosition = treeModel:GetPivot().Position
    local treeParts = {}
    local lowestY = math.huge
    
    for _, part in ipairs(treeModel:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(treeParts, part)
            local partBottom = part.Position.Y - part.Size.Y / 2
            if partBottom < lowestY then
                lowestY = partBottom
                treePosition = Vector3.new(part.Position.X, partBottom, part.Position.Z)
            end
        end
    end

    -- Scale tree down animation
    local scaleTween = TweenService:Create(
        treeModel,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        { Size = treeModel.Size * 0.01 }
    )
    scaleTween:Play()

    -- Add tree to inventory - determine tree type from model name
    local treeItemId = "tree" -- Default tree item
    local treeName = treeModel.Name:lower()
    
    -- Map tree types to item IDs
    if treeName:find("cherry") then
        treeItemId = "cherry_tree"
    elseif treeName:find("apple") then
        treeItemId = "apple_tree"
    elseif treeName:find("peach") then
        treeItemId = "peach_tree"
    elseif treeName:find("orange") then
        treeItemId = "orange_tree"
    elseif treeName:find("pear") then
        treeItemId = "pear_tree"
    end
    
    -- Add tree to inventory - use direct function call if available
    -- This will be set by init.server.luau after ShovelSystem is initialized
    if ShovelSystem.addItemToInventory then
        ShovelSystem.addItemToInventory(player, {
            itemId = treeItemId,
            count = 1,
        })
        print("[ShovelSystem] 🌳 Added " .. treeItemId .. " to inventory")
    else
        warn("[ShovelSystem] ⚠️ addItemToInventory function not set - tree not added to inventory")
    end

    -- Wait for scale animation to complete, then remove tree
    scaleTween.Completed:Wait()
    
    -- Find ground position and surface normal for tree hole
    local rayOrigin = treePosition + Vector3.new(0, 10, 0)
    local rayDirection = Vector3.new(0, -50, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { Workspace.Terrain }
    
    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    local groundPosition = treePosition
    local treeSurfaceNormal = nil
    
    if rayResult then
        groundPosition = rayResult.Position
        treeSurfaceNormal = rayResult.Normal
    end
    
    -- DISABLED: No hole creation for tree digging
    -- createHole(groundPosition, treeSurfaceNormal)
    print("[ShovelSystem] 🕳️ Tree hole creation DISABLED (no visual holes)")

    -- Remove tree model
    task.wait(0.1) -- Brief delay before removing
    treeModel:Destroy()

    playerCooldowns[player.UserId] = tick()

    return true, "tree", { treeType = treeModel.Name }
end

--[[
	Attempts to dig with the player's currently equipped shovel.
	Returns success:boolean, resultType:string?, resultData:table?, errorMessage:string?
]]
local function performDig(player, targetPosition, targetInstance)
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

    -- Check if target is a tree
    local targetTree = nil
    if targetInstance then
        local current = targetInstance
        while current and current ~= workspace do
            if current:GetAttribute("HarvestType") == "tree" or current:GetAttribute("ResourceType") == "tree" or 
               current.Name:lower():find("tree") then
                targetTree = current
                break
            end
            current = current.Parent
        end
    end

    -- If digging a tree, handle tree digging
    if targetTree and targetTree:IsA("Model") then
        return performTreeDig(player, targetTree)
    end

    -- Get dig position - use provided targetPosition or calculate from player
    local holePosition = nil
    local surfaceNormal = nil
    
    if targetPosition then
        -- Raycast to find ground at target position
        local rayOrigin = targetPosition + Vector3.new(0, 10, 0)
        local rayDirection = Vector3.new(0, -50, 0)

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Include
        raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

        local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        if rayResult then
            surfaceNormal = rayResult.Normal
            
            -- Check if surface is flat enough (normal should be close to vertical)
            local upVector = Vector3.new(0, 1, 0)
            local angle = math.acos(math.clamp(surfaceNormal:Dot(upVector), -1, 1))
            
            -- Only allow digging on relatively flat surfaces (less than 15 degrees slope)
            if angle > math.rad(15) then
                return false, nil, nil, "Can only dig on flat surfaces."
            end
            
            holePosition = rayResult.Position
        end
    end

    -- Fallback: Get dig position in front of player
    if not holePosition then
        local digPos = rootPart.Position + (rootPart.CFrame.LookVector * 3)

        -- Raycast to find ground position
        local rayOrigin = digPos + Vector3.new(0, 10, 0)
        local rayDirection = Vector3.new(0, -50, 0)

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Include
        raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

        local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        if not rayResult then
            return false, nil, nil, "Couldn't find ground to dig."
        end
        
        surfaceNormal = rayResult.Normal
        
        -- Check if surface is flat enough
        local upVector = Vector3.new(0, 1, 0)
        local angle = math.acos(math.clamp(surfaceNormal:Dot(upVector), -1, 1))
        
        if angle > math.rad(15) then
            return false, nil, nil, "Can only dig on flat surfaces."
        end

        holePosition = rayResult.Position
    end

    -- Check if player already has a hole here
    if DigSpotManager.hasDugHole(player, holePosition) then
        return false, nil, nil, "There's already a hole here."
    end

    -- Handle the dig through DigSpotManager
    local success, resultType, resultData = DigSpotManager.handleDig(player, holePosition)

    local digSucceeded = false

    if success then
        digSucceeded = true

        -- DISABLED: No more visual holes created
        -- createHole(holePosition, surfaceNormal)
        print("[ShovelSystem] 🕳️ Dig hole creation DISABLED (no visual holes)")

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

function ShovelSystem.attemptDig(player, targetPosition, targetInstance)
    return performDig(player, targetPosition, targetInstance)
end

-- Set inventory function from init.server
function ShovelSystem.setAddItemFunction(addItemFunc)
    ShovelSystem.addItemToInventory = addItemFunc
end

return ShovelSystem
