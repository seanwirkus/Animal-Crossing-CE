-- Server initialization script
-- Complete server-side inventory management

-- Roblox globals
local game = game
local workspace = game:GetService("Workspace")

-- Import services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Roblox types and enums
local Instance = Instance
local Enum = Enum
local Vector3 = Vector3
local Vector2 = Vector2
local CFrame = CFrame
local Color3 = Color3
local UDim2 = UDim2
local TweenInfo = TweenInfo
local tick = tick
local task = task

print("✅ Animal Crossing server systems ready!")
print("📊 ServerScriptService scripts will run automatically")

print("[Server] 🚀 Starting inventory system...")

-- Create RemoteEvent
local inventoryRemote = ReplicatedStorage:FindFirstChild("InventoryEvent") or Instance.new("RemoteEvent")
inventoryRemote.Name = "InventoryEvent"
inventoryRemote.Parent = ReplicatedStorage

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local SpriteConfig = require(sharedFolder:WaitForChild("SpriteConfig"))
local ItemDataFetcher = require(sharedFolder:WaitForChild("ItemDataFetcher"))
local CraftingSystem = require(sharedFolder:WaitForChild("CraftingSystem"))
local InventoryDomain = require(sharedFolder:WaitForChild("inventory"))

local InventoryConstants = InventoryDomain.Constants
local InventorySchemas = InventoryDomain.Schemas
local InventoryValidation = InventoryDomain.Validation
local inventoryAdapterRegistry = InventoryDomain.newAdapterRegistry()
inventoryAdapterRegistry:registerLegacyAdapter(
	InventoryConstants.LEGACY_DATASET_ID,
	InventoryDomain.AdapterClass.defaultLegacyAdapter
)

-- Player inventory storage
local playerInventories = {}

local MAX_SLOTS = InventoryConstants.DEFAULT_MAX_SLOTS

-- World item storage - tracks all dropped items
local worldItems = {}
local nextItemId = 1

local ItemData = ItemDataFetcher.getFallbackData()
local DisplayItems = ItemDataFetcher.getDisplayItemMap()

local function getInventoryForPlayer(player)
        return playerInventories[player.UserId]
end

local function buildSnapshotFromState(slots, maxSlots)
        local snapshot = InventorySchemas.createSnapshot({
                maxSlots = maxSlots or MAX_SLOTS,
                source = "server-runtime",
        })

        if slots then
                for index = 1, snapshot.maxSlots do
                        local slot = slots[index]
                        if slot and slot.itemId and slot.count and slot.count > 0 then
                                snapshot.slots[index] = InventorySchemas.createSlotFromStack(index, {
                                        id = slot.itemId,
                                        count = slot.count,
                                })
                        end
                end
        end

        return snapshot
end

-- Initialize player inventory
local function initializePlayerInventory(player)
        -- Start with empty inventory (use debug GUI to add items)
        local _starterItems = {}

        local slots = {}
        for i = 1, MAX_SLOTS do
                slots[i] = nil
        end

        local snapshot = buildSnapshotFromState(slots, MAX_SLOTS)
        playerInventories[player.UserId] = {
                slots = slots,
                maxSlots = MAX_SLOTS,
                snapshot = snapshot,
                legacyPayload = inventoryAdapterRegistry:serializeForLegacy(InventoryConstants.LEGACY_DATASET_ID, snapshot),
        }

        print("[Server] ✅ Initialized empty inventory for", player.Name, "with", MAX_SLOTS, "slots")
end

local function decodeLegacyPayload(payload)
        if typeof(payload) == "string" then
                local ok, result = pcall(function()
                        return HttpService:JSONDecode(payload)
                end)
                if not ok then
                        warn("[Server] Failed to decode legacy payload JSON:", result)
                        return nil
                end
                return result
        end

        return payload
end

local function applySnapshotToInventory(inventory, snapshot)
        if not inventory or not snapshot then
                return
        end

        inventory.maxSlots = snapshot.maxSlots
        for index = 1, snapshot.maxSlots do
                local slot = snapshot.slots[index]
                local stack = slot and slot.stack
                if stack and stack.id ~= "" and stack.count and stack.count > 0 then
                        inventory.slots[index] = {
                                itemId = stack.id,
                                count = stack.count,
                                metadata = stack.metadata,
                        }
                else
                        inventory.slots[index] = nil
                end
        end

        if #inventory.slots > snapshot.maxSlots then
                for index = snapshot.maxSlots + 1, #inventory.slots do
                        inventory.slots[index] = nil
                end
        end

        inventory.snapshot = snapshot
        inventory.legacyPayload = inventoryAdapterRegistry:serializeForLegacy(InventoryConstants.LEGACY_DATASET_ID, snapshot)
end

local function hydrateInventoryFromLegacy(inventory, payload, options)
        if not inventory or not payload then
                return
        end

        payload = decodeLegacyPayload(payload)
        if not payload then
                return
        end

        local success, snapshot = pcall(function()
                return inventoryAdapterRegistry:convertLegacySnapshot(InventoryConstants.LEGACY_DATASET_ID, payload, options)
        end)

        if not success then
                warn("[Server] Failed to hydrate inventory from legacy payload:", snapshot)
                return
        end

        applySnapshotToInventory(inventory, snapshot)
end

local function cloneSlots(slots, maxSlots)
        local snapshot = buildSnapshotFromState(slots, maxSlots)
        local ok, reason = InventoryValidation.validateSnapshot(snapshot)
        if not ok then
                warn("[Server] Inventory snapshot validation failed:", reason)
        end

        local serialized = {}
        -- Always include all slot indices to provide a full snapshot to clients.
        -- Use an empty table {} to represent an empty slot (nil keys are dropped over the wire).
        for index = 1, snapshot.maxSlots do
                local slot = snapshot.slots[index]
                local stack = slot and slot.stack
                if stack and stack.id and stack.count and stack.count > 0 then
                        serialized[index] = {
                                itemId = stack.id,
                                count = stack.count,
                        }
                else
                        -- Represent empty slot with explicit shape so Luau typechecker and clients see a consistent shape.
                        serialized[index] = {
                                itemId = "",
                                count = 0,
                        }
                end
        end

        return serialized, snapshot
end

local function countFilledSlots(slots)
        local count = 0
        for index = 1, MAX_SLOTS do
                if slots[index] then
                        count = count + 1
                end
        end
        return count
end

local function totalCountForItem(inventory, itemId)
        if not inventory or not itemId then
                return 0
        end

        local total = 0
        for index = 1, inventory.maxSlots or MAX_SLOTS do
                local slot = inventory.slots[index]
                if slot and slot.itemId == itemId then
                        total = total + slot.count
                end
        end
        return total
end

-- Resolve an item's max stack size from slot metadata or item data.
-- Falls back to 99 if not specified.
local function getMaxStackForItem(itemId, slot)
        if slot and typeof(slot) == "table" and slot.maxStack then
                return slot.maxStack
        end
        local ok, itemData = pcall(function()
                return ItemDataFetcher.getItem(itemId)
        end)
        if ok and itemData then
                -- Support multiple possible field names in data
                return itemData.maxStack or itemData.stack or itemData.stackSize or InventoryConstants.DEFAULT_MAX_STACK
        end
        return InventoryConstants.DEFAULT_MAX_STACK
end

local function hasCraftingMaterials(player, materials, quantity)
        local inventory = getInventoryForPlayer(player)
        if not inventory then
                return false
        end

        quantity = quantity or 1

        for _, requirement in ipairs(materials or {}) do
                local needed = (requirement.count or 1) * quantity
                if totalCountForItem(inventory, requirement.itemId) < needed then
                        return false
                end
        end

        return true
end

local function syncInventoryToClient(player)
        local inventory = playerInventories[player.UserId]
        if not inventory then return end

        local serializedSlots, snapshot = cloneSlots(inventory.slots, inventory.maxSlots)
        inventory.snapshot = snapshot
        inventory.legacyPayload = inventoryAdapterRegistry:serializeForLegacy(InventoryConstants.LEGACY_DATASET_ID, snapshot)

        inventoryRemote:FireClient(player, "SyncInventory", {
                maxSlots = inventory.maxSlots or MAX_SLOTS,
                slots = serializedSlots,
        })
end

local function consumeCraftingMaterials(player, materials, quantity)
        local inventory = getInventoryForPlayer(player)
        if not inventory then
                return false
        end

        quantity = quantity or 1

        if not hasCraftingMaterials(player, materials, quantity) then
                return false
        end

        for _, requirement in ipairs(materials or {}) do
                local remaining = (requirement.count or 1) * quantity
                for index = 1, inventory.maxSlots or MAX_SLOTS do
                        local slot = inventory.slots[index]
                        if slot and slot.itemId == requirement.itemId then
                                local toRemove = math.min(slot.count, remaining)
                                slot.count = slot.count - toRemove
                                remaining = remaining - toRemove
                                if slot.count <= 0 then
                                        inventory.slots[index] = nil
                                end
                                if remaining <= 0 then
                                        break
                                end
                        end

                end

                if remaining > 0 then
                        return false
                end
        end

        syncInventoryToClient(player)
        return true
end

local function grantCraftedItems(player, craftedItems)
        local inventory = getInventoryForPlayer(player)
        if not inventory then
                return
        end

        for _, itemId in ipairs(craftedItems or {}) do
                local added = false
                for index = 1, inventory.maxSlots or MAX_SLOTS do
                        local slot = inventory.slots[index]
                        if slot and slot.itemId == itemId then
                                slot.count = slot.count + 1
                                added = true
                                break
                        elseif not slot then
                                inventory.slots[index] = { itemId = itemId, count = 1 }
                                added = true
                                break
                        end
                end

                if not added then
                        warn("[Server] Inventory full - crafted item", itemId, "could not be added")
                end
        end

        syncInventoryToClient(player)
end

CraftingSystem.configure({
        hasMaterials = hasCraftingMaterials,
        consumeMaterials = consumeCraftingMaterials,
        grantItems = grantCraftedItems,
})

local function cleanupWorldItemConnections(connections)
	if not connections then
		return
	end

	for index = #connections, 1, -1 do
		local connection = connections[index]
		if connection and connection.Disconnect then
			connection:Disconnect()
		end
		connections[index] = nil
	end
end

local function destroyWorldItem(worldItemId)
	local entry = worldItems[worldItemId]
	if not entry then
		return
	end

	if entry.disconnect then
		local success, err = pcall(entry.disconnect, entry)
		if not success then
			warn("[Server] Failed to run world item disconnect callback:", err)
		end
	end

	cleanupWorldItemConnections(entry.connections)

	if entry.model then
		entry.model:Destroy()
	end

	worldItems[worldItemId] = nil
end

-- Create dropped item in the world with 3D sprite and proper tracking
local function createDroppedItem(player, itemId, count, worldPosition)
	if not ItemData[itemId] then
		warn("[Server] Unknown item:", itemId)
		return
        end

	local item = ItemData[itemId]
	local worldItemId = nextItemId
	nextItemId = nextItemId + 1

	local presentationConnections = {}
	local function trackConnection(connection)
		if connection then
			table.insert(presentationConnections, connection)
		end
		return connection
	end

	local model = Instance.new("Model")
	model.Name = "WorldItem_" .. worldItemId .. "_" .. item.name
	model.Parent = workspace

        local pivot = Instance.new("Part")
        pivot.Name = "Pivot"
        pivot.Transparency = 1
        pivot.Anchored = true
        pivot.CanCollide = false
        pivot.CFrame = CFrame.new(worldPosition + Vector3.new(0, 0.5, 0))
        pivot.Parent = model

        -- Make pivot the main part with physics
        pivot.Anchored = false
        pivot.CanCollide = true
        pivot.Massless = false
        pivot.AssemblyLinearVelocity = Vector3.new(0, -5, 0) -- Initial downward velocity

        -- Make pivot invisible but solid, positioned to plop on ground
        pivot.Size = Vector3.new(1, 1, 1) -- Full height collision box
        pivot.Transparency = 1
        pivot.CFrame = CFrame.new(worldPosition + Vector3.new(0, 1, 0)) -- Start higher for plop effect

        -- Create flat sprite that lays on ground like Animal Crossing
        local spritePart = Instance.new("Part")
        spritePart.Name = "SpritePart"
        spritePart.Size = Vector3.new(4, 0.1, 4) -- A little bigger, flat part
        spritePart.Material = Enum.Material.Neon
        spritePart.Color = Color3.new(0, 0, 0)
        spritePart.Transparency = 1
        spritePart.CanCollide = false
        spritePart.Anchored = true
        spritePart.CFrame = CFrame.new(worldPosition + Vector3.new(0, 0.05, 0)) -- Just above ground
        spritePart.CastShadow = false
        spritePart.Parent = model

        -- Create simple 3D depth effect with fewer, more subtle layers
        -- Ground shadow (darkest, largest)
        local groundShadow = Instance.new("Part")
        groundShadow.Name = "GroundShadow"
        groundShadow.Size = Vector3.new(4.5, 0.05, 4.5) -- Slightly larger shadow
        groundShadow.Material = Enum.Material.Neon
        groundShadow.Color = Color3.new(0, 0, 0)
        groundShadow.Transparency = 1
        groundShadow.CanCollide = false
        groundShadow.Anchored = true
        groundShadow.CFrame = CFrame.new(worldPosition + Vector3.new(0, 0.01, 0))
        groundShadow.CastShadow = false
        groundShadow.Parent = model

        local groundShadowGui = Instance.new("SurfaceGui")
        groundShadowGui.Face = Enum.NormalId.Top
        groundShadowGui.Parent = groundShadow

        local groundShadowSprite = Instance.new("ImageLabel")
        groundShadowSprite.Size = UDim2.new(1, 0, 1, 0)
        groundShadowSprite.BackgroundTransparency = 1
        groundShadowSprite.Image = SpriteConfig.SHEET_ASSET
        groundShadowSprite.ImageTransparency = 0.7 -- More transparent shadow
        groundShadowSprite.ImageColor3 = Color3.new(0.2, 0.2, 0.2) -- Lighter shadow
        groundShadowSprite.ScaleType = Enum.ScaleType.Stretch
        groundShadowSprite.Parent = groundShadowGui

        -- Calculate sprite rect for this specific item
        local spriteOffset, spriteSize = SpriteConfig.getSpriteRect(item.index)
        if not spriteOffset or not spriteSize then
                spriteOffset = Vector2.new(0, 0)
                spriteSize = SpriteConfig.DEFAULT_IMAGE_RECT_SIZE
        end

        groundShadowSprite.ImageRectOffset = spriteOffset
        groundShadowSprite.ImageRectSize = spriteSize

        -- Create simple depth layers - just 2 subtle layers for 3D effect
        local depthLayers = {}
        local layerCount = 2 -- Reduced from 8
        
        for i = 1, layerCount do
                local layerPart = Instance.new("Part")
                layerPart.Name = "DepthLayer_" .. i
                
                -- Simple layer properties
                local progress = i / layerCount -- 0 to 1
                local sizeMultiplier = 1 + (progress * 0.15) -- 1.0 to 1.15 (subtle size increase)
                local height = 0.05 -- Thin layers
                local darkness = 0.3 + (progress * 0.3) -- 0.3 to 0.6 (medium darkness)
                
                -- Stack layers closely together
                local heightOffset = 0.02 + (progress * 0.04) -- 0.02 to 0.06 (close stacking)
                
                layerPart.Size = Vector3.new(4 * sizeMultiplier, height, 4 * sizeMultiplier)
                layerPart.Material = Enum.Material.Neon
                layerPart.Color = Color3.new(0, 0, 0)
                layerPart.Transparency = 1
                layerPart.CanCollide = false
                layerPart.Anchored = true
                layerPart.CFrame = CFrame.new(worldPosition + Vector3.new(0, heightOffset, 0))
                layerPart.CastShadow = false
                layerPart.Parent = model

                local layerGui = Instance.new("SurfaceGui")
                layerGui.Face = Enum.NormalId.Top
                layerGui.Parent = layerPart

                local layerSprite = Instance.new("ImageLabel")
                layerSprite.Size = UDim2.new(1, 0, 1, 0)
                layerSprite.BackgroundTransparency = 1
                layerSprite.Image = SpriteConfig.SHEET_ASSET
                layerSprite.ImageTransparency = 0.8 - (progress * 0.3) -- 0.8 to 0.5 (less transparent as we go up)
                layerSprite.ImageColor3 = Color3.new(darkness, darkness, darkness)
                layerSprite.ScaleType = Enum.ScaleType.Stretch
                layerSprite.Parent = layerGui
                
                -- Apply sprite rect for proper item display
                layerSprite.ImageRectOffset = spriteOffset
                layerSprite.ImageRectSize = spriteSize
                
                table.insert(depthLayers, {
                        part = layerPart,
                        sprite = layerSprite
                })
        end

        -- Top layer (main sprite)
        local topGui = Instance.new("SurfaceGui")
        topGui.Face = Enum.NormalId.Top
        topGui.Parent = spritePart

        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Size = UDim2.new(1, 0, 1, 0)
        imageLabel.BackgroundTransparency = 1
	imageLabel.Image = SpriteConfig.SHEET_ASSET
        imageLabel.ImageTransparency = 0
        imageLabel.ScaleType = Enum.ScaleType.Stretch
        imageLabel.Parent = topGui

        -- Apply sprite rect to main sprite
        imageLabel.ImageRectOffset = spriteOffset
        imageLabel.ImageRectSize = spriteSize

	-- Enhanced point light with better range and color
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "SpriteGlow"
	pointLight.Range = 6 -- Reduced from 12
	pointLight.Brightness = 1.5 -- Reduced from 2.2
	pointLight.Color = Color3.fromRGB(255, 235, 200) -- Warmer color
	pointLight.Shadows = false
	pointLight.Parent = spritePart

	-- Remove sparkles - too much visual noise
	-- local sparkles = Instance.new("Sparkles")
	-- sparkles.Name = "SpriteSparkles"
	-- sparkles.SparkleColor = Color3.fromRGB(255, 245, 220) -- Warmer sparkle color
	-- sparkles.Parent = spritePart

	-- Remove ambient light - too much glow
	-- local ambientLight = Instance.new("PointLight")
	-- ambientLight.Name = "AmbientGlow"
	-- ambientLight.Range = 8
	-- ambientLight.Brightness = 1.2
	-- ambientLight.Color = Color3.fromRGB(255, 250, 240)
	-- ambientLight.Shadows = false
	-- ambientLight.Parent = pivot

	-- Simple ground-based items with enhanced lighting and sparkles
	model.PrimaryPart = pivot

	worldItems[worldItemId] = {
		itemId = itemId,
		count = count,
		position = worldPosition,
		droppedBy = player.UserId,
		droppedAt = tick(),
		model = model,
		connections = presentationConnections,
	}

        -- Add plop animation with bounce effect for all depth layers
        local plopTweens = {}
        local scaleTweens = {}
        
        -- Animate main sprite
        local plopTween1 = TweenService:Create(spritePart, TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
            CFrame = CFrame.new(worldPosition + Vector3.new(0, 0.05, 0)) -- Final resting position on ground
        })
        plopTween1:Play()
        
        local scaleTween1 = TweenService:Create(spritePart, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = Vector3.new(4.5, 0.1, 4.5) -- Slightly larger on impact
        })
        scaleTween1:Play()
        
        -- Animate solid depth layers - no dramatic movement, just solid stacking
        for i, layer in ipairs(depthLayers) do
                local delay = (i - 1) * 0.02 -- Small stagger for solid effect
                local progress = i / layerCount
                
                -- Simple plop animation for solid layers
                local plopTween = TweenService:Create(layer.part, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                        CFrame = CFrame.new(worldPosition + Vector3.new(0, 0.01 + (progress * 0.08), 0))
                })
                
                -- Minimal scale animation for solid effect
                local scaleTween = TweenService:Create(layer.part, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = Vector3.new((4 * (1 + (progress * 0.3))) * 1.05, 0.1, (4 * (1 + (progress * 0.3))) * 1.05)
                })
                
                -- Delay the animation for staggered effect
                if delay > 0 then
                        task.wait(delay)
                end
                
                plopTween:Play()
                scaleTween:Play()
                
                table.insert(plopTweens, plopTween)
                table.insert(scaleTweens, scaleTween)
        end
        
        -- Scale back to normal size for all layers
        scaleTween1.Completed:Connect(function()
            local scaleBackTween1 = TweenService:Create(spritePart, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = Vector3.new(4, 0.1, 4) -- Back to normal size
            })
            scaleBackTween1:Play()
        end)
        
        -- Scale back solid depth layers
        for i, layer in ipairs(depthLayers) do
                local progress = i / layerCount
                local originalSize = Vector3.new(4 * (1 + (progress * 0.3)), 0.1, 4 * (1 + (progress * 0.3)))
                
                -- Connect scale back animation for each layer
                if scaleTweens[i] then
                        scaleTweens[i].Completed:Connect(function()
                                local scaleBackTween = TweenService:Create(layer.part, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                                        Size = originalSize
                                })
                                scaleBackTween:Play()
                        end)
                end
        end

        local function pickupItem(pickingPlayer)
                if not worldItems[worldItemId] then
                        return
                end

                print("[Server]", pickingPlayer.Name, "picked up", count, "x", item.name)

                -- Get player position for animation
                local character = pickingPlayer.Character
                local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                local targetPosition = humanoidRootPart and humanoidRootPart.Position or worldPosition
                
                print("[Server] 🎬 Starting pickup animation from", worldPosition, "to", targetPosition)

                -- Anchor the pivot for smooth animation
                pivot.Anchored = true
                
                -- Create satisfying pickup animation
                local pickupTween = TweenService:Create(pivot, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        CFrame = CFrame.new(targetPosition + Vector3.new(0, 2, 0))
                })
                
                -- Scale up then down for satisfying effect
                local scaleUpTween = TweenService:Create(pivot, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = Vector3.new(1.5, 1.5, 1.5)
                })
                
                local scaleDownTween = TweenService:Create(pivot, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                        Size = Vector3.new(0.1, 0.1, 0.1)
                })

                -- Start animations
                pickupTween:Play()
                scaleUpTween:Play()
                
                -- Chain the scale animations
                scaleUpTween.Completed:Connect(function()
                        scaleDownTween:Play()
                end)

                -- Add rotation for extra satisfaction
                local rotationTween = TweenService:Create(pivot, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        CFrame = pivot.CFrame * CFrame.Angles(0, math.rad(360), 0)
                })
                rotationTween:Play()

                -- Wait for animation to complete before adding to inventory
                pickupTween.Completed:Connect(function()
                        print("[Server] 🎬 Animation completed, adding to inventory")
                        
                        local inventory = playerInventories[pickingPlayer.UserId]
                        if inventory then
                                local slots = inventory.slots
                                local existingIndex
                                for index = 1, inventory.maxSlots or MAX_SLOTS do
                                        local slot = slots[index]
                                        if slot and slot.itemId == itemId then
                                                existingIndex = index
                                                break
                                        end
                                end

                                if existingIndex then
                                        slots[existingIndex].count = slots[existingIndex].count + count
                                else
                                        local emptyIndex
                                        for index = 1, inventory.maxSlots or MAX_SLOTS do
                                                if not slots[index] then
                                                        emptyIndex = index
                                                        break
                                                end
                                        end

                                        if emptyIndex then
                                                slots[emptyIndex] = { itemId = itemId, count = count }
                                        else
                                                warn("[Server]", pickingPlayer.Name, "has no space to pick up", item.name)
                                                return
                                        end
                                end

                                syncInventoryToClient(pickingPlayer)
                        end

                        destroyWorldItem(worldItemId)
                end)
        end

        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 20 -- Increased from 12 to 20
        clickDetector.Parent = pivot
        clickDetector.MouseClick:Connect(pickupItem)

	local proximityConnection
	proximityConnection = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			if proximityConnection then
				proximityConnection:Disconnect()
				proximityConnection = nil
			end
			return
		end

		for _, otherPlayer in ipairs(Players:GetPlayers()) do
                        local character = otherPlayer.Character
                        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                                local distance = (rootPart.Position - worldPosition).Magnitude
				if distance <= 8 then -- Increased from 3 to 8
					pickupItem(otherPlayer)
					if proximityConnection then
						proximityConnection:Disconnect()
						proximityConnection = nil
					end
					return
				end
			end
		end
	end)
	trackConnection(proximityConnection)

        print("[Server] ✅ Created 3D dropped item:", item.name, "x", count, "at", worldPosition)
end

-- Get all world items (for debugging/admin)
local function getAllWorldItems()
	local items = {}
        for id, item in pairs(worldItems) do
                if item.model and item.model.Parent then
                        table.insert(items, {
                                id = id,
                                itemId = item.itemId,
                                count = item.count,
                                position = item.position,
                                droppedBy = item.droppedBy,
                                droppedAt = item.droppedAt
                        })
                end
        end
	return items
end

-- Handle inventory requests
inventoryRemote.OnServerEvent:Connect(function(player, action, data)
	print("[Server] Received", action, "from", player.Name)
	local inventory = playerInventories[player.UserId]
	if not inventory then
		warn("[Server] Player inventory not found:", player.Name)
		return
	end
	
        if action == "RequestInventory" then
                print("[Server] Sending inventory to", player.Name, "with", countFilledSlots(inventory.slots), "items")
                syncInventoryToClient(player)

        elseif action == "ImportLegacyInventory" and data then
                print("[Server] Importing legacy inventory payload for", player.Name)
                hydrateInventoryFromLegacy(inventory, data.payload, data.options)
                syncInventoryToClient(player)

        elseif action == "DropItem" and data then
                local itemId = data.itemId
                local count = data.count or 1
                local slotIndex = data.slotIndex
                local worldPosition = data.worldPosition or Vector3.new(0, 10, 0)

        local display = DisplayItems[itemId]
        print("[Server]", player.Name, "dropped", count, "x", display and display.name or itemId, "at world position", worldPosition)

                local slots = inventory.slots
                local function removeFromSlot(index)
                        local slot = slots[index]
                        if slot and slot.itemId == itemId and slot.count >= count then
                                slot.count = slot.count - count
                                if slot.count <= 0 then
                                        slots[index] = nil
                                end
                                return true
                        end
                        return false
                end

                local removed = false
                if slotIndex and slotIndex >= 1 and slotIndex <= (inventory.maxSlots or MAX_SLOTS) then
                        removed = removeFromSlot(slotIndex)
                end

                if not removed then
                        for index = 1, inventory.maxSlots or MAX_SLOTS do
                                if removeFromSlot(index) then
                                        removed = true
                                        break
                                end
                        end
                end

                if removed then
                        createDroppedItem(player, itemId, count, worldPosition)
                        syncInventoryToClient(player)
                        return
                end

                warn("[Server]", player.Name, "tried to drop item they don't have:", itemId)

        elseif action == "MoveItem" and data then
                local fromIndex = data.fromIndex
                local toIndex = data.toIndex
                local swap = data.swap == true

                if type(fromIndex) ~= "number" or type(toIndex) ~= "number" then
                        return
                end

                if fromIndex == toIndex then
                        -- Nothing to do
                        return
                end

                if fromIndex < 1 or fromIndex > (inventory.maxSlots or MAX_SLOTS) then
                        return
                end

                if toIndex < 1 or toIndex > (inventory.maxSlots or MAX_SLOTS) then
                        return
                end

                local slots = inventory.slots
                local fromSlot = slots[fromIndex]
                if not fromSlot then
                        return
                end

                local toSlot = slots[toIndex]
                local itemId = fromSlot.itemId

                -- Case 1: moving into empty slot
                if not toSlot then
                        -- Move entire stack by reference
                        slots[toIndex] = fromSlot
                        slots[fromIndex] = nil
                        syncInventoryToClient(player)
                        return
                end

                -- Case 2: same itemId -> merge stacks up to maxStack
                if toSlot.itemId == itemId then
                        local maxStack = getMaxStackForItem(itemId, toSlot)
                        local fromCount = math.max(0, tonumber(fromSlot.count) or 0)
                        local toCount = math.max(0, tonumber(toSlot.count) or 0)
                        local space = math.max(0, maxStack - toCount)
                        
                        if space > 0 then
                                -- Merge what we can
                                local toAdd = math.min(space, fromCount)
                                toSlot.count = toCount + toAdd
                                local remaining = fromCount - toAdd
                                if remaining > 0 then
                                        fromSlot.count = remaining
                                else
                                        slots[fromIndex] = nil
                                end
                                toSlot.maxStack = maxStack
                                syncInventoryToClient(player)
                                return
                        end
                        -- If no space and swap=true, fall through to swap
                end

                -- Case 3: different items or full stacks of same item -> swap
                if swap then
                        slots[fromIndex], slots[toIndex] = toSlot, fromSlot
                        syncInventoryToClient(player)
                        return
                end

                -- Otherwise, reject
                warn("[Server] MoveItem rejected: target occupied and swap not requested; from:", fromIndex, "to:", toIndex)
                return

        elseif action == "add_item" and data then
                -- Validate data format
                local itemId = type(data) == "table" and data.itemId or data
                local count = (type(data) == "table" and data.count) or 1
                local maxStack = (type(data) == "table" and data.maxStack) or 99
                
                -- Check if item exists
                local itemData = ItemDataFetcher.getItem(itemId)
                if not itemData then
                        warn("[Server] Debug: Item not found:", itemId)
                        return
                end
                
                -- Validate count
                count = math.floor(count)
                if count < 1 then
                        warn("[Server] Invalid item count:", count)
                        return
                end
                
                -- Try to add to existing slot first
                local slots = inventory.slots
                local added = false
                
                for i = 1, inventory.maxSlots or MAX_SLOTS do
                        local slot = slots[i]
                        if slot and slot.itemId == itemId then
                                -- Check stack limit
                                if slot.count >= maxStack then
                                        -- Try next slot if this one is full
                                else
                                        local spaceInStack = maxStack - slot.count
                                        local addToStack = math.min(count, spaceInStack)
                                        slot.count = slot.count + addToStack
                                        count = count - addToStack
                                        added = true
                                        if count <= 0 then
                                                break
                                        end
                                end
                        end
                end
                
                -- If not added to existing slot, find empty slot
                -- Try to add remaining items to empty slots
                if count > 0 then
                        for i = 1, inventory.maxSlots or MAX_SLOTS do
                                if not slots[i] then
                                        local addToNewSlot = math.min(count, maxStack)
                                        slots[i] = { 
                                            itemId = itemId, 
                                            count = addToNewSlot,
                                            maxStack = maxStack  -- Store stack limit
                                        }
                                        count = count - addToNewSlot
                                        added = true
                                        if count <= 0 then
                                            break
                                        end
                                end
                        end
                end
                
                if added then
                        print("[Server] Debug: Added", itemId, "to", player.Name, "'s inventory")
                        syncInventoryToClient(player)
                else
                        warn("[Server] Debug: Inventory full, cannot add", itemId)
                end

                -- Return remaining count that couldn't be added
                if count > 0 then
                        warn("[Server] Could not add all items - remaining:", count)
                end

        elseif action == "craft_item" and data then
                local itemId = data.itemId
                local recipe = ItemDataFetcher.getCraftingRecipe(itemId)
                if not recipe then
                        warn("[Server] Craft failed: No recipe for", itemId)
                        return
                end
                
                -- Check if player has all required materials
                local slots = inventory.slots
                local hasMaterials = true
                local materialsToRemove = {}
                
                for _, mat in ipairs(recipe.materials or {}) do
                        local needed = mat.count or 1
                        local found = 0
                        
                        for slotIndex, slot in pairs(slots) do
                                if slot and slot.itemId == mat.itemId then
                                        found = found + slot.count
                                end
                        end
                        
                        if found < needed then
                                hasMaterials = false
                                break
                        end
                        
                        -- Record what to remove
                        materialsToRemove[mat.itemId] = needed
                end
                
                if not hasMaterials then
                        warn("[Server] Craft failed: Insufficient materials for", itemId)
                        return
                end
                
                -- Remove materials
                for matId, needed in pairs(materialsToRemove) do
                        local remaining = needed
                        for slotIndex = 1, inventory.maxSlots or MAX_SLOTS do
                                local slot = slots[slotIndex]
                                if slot and slot.itemId == matId then
                                        if slot.count >= remaining then
                                                slot.count = slot.count - remaining
                                                if slot.count <= 0 then
                                                        slots[slotIndex] = nil
                                                end
                                                break
                                        else
                                                remaining = remaining - slot.count
                                                slots[slotIndex] = nil
                                        end
                                end
                        end
                end
                
                -- Add crafted item
                local _craftedData = { itemId = itemId, count = 1 }
                -- Reuse the add_item logic
                local itemData = ItemDataFetcher.getItem(itemId)
                if itemData then
                        local maxStack = 99  -- Default for crafted items
                        local _count = 1
                        local added = false
                        
                        -- Try to add to existing slot first
                        for i = 1, inventory.maxSlots or MAX_SLOTS do
                                local slot = slots[i]
                                if slot and slot.itemId == itemId then
                                        if slot.count < maxStack then
                                                slot.count = slot.count + 1
                                                added = true
                                                break
                                        end
                                end
                        end
                        
                        -- If not added, find empty slot
                        if not added then
                                for i = 1, inventory.maxSlots or MAX_SLOTS do
                                        if not slots[i] then
                                                slots[i] = { itemId = itemId, count = 1, maxStack = maxStack }
                                                added = true
                                                break
                                        end
                                end
                        end
                        
                        if added then
                                print("[Server] Crafted", itemId, "for", player.Name)
                                syncInventoryToClient(player)
                        else
                                warn("[Server] Craft failed: Inventory full for", itemId)
                        end
                end

        elseif action == "GetWorldItems" then
                -- Debug command to see all world items
                local worldItemsList = getAllWorldItems()
                print("[Server] World items count:", #worldItemsList)
                for _, item in ipairs(worldItemsList) do
			print("[Server] - Item", item.id, ":", item.itemId, "x", item.count, "at", item.position)
		end
		inventoryRemote:FireClient(player, "WorldItemsList", worldItemsList)
	end
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
	print("[Server] Player added:", player.Name)
	
	-- Initialize inventory immediately when player joins
        print("[Server] Initializing inventory for:", player.Name)
        initializePlayerInventory(player)

        local inventory = playerInventories[player.UserId]
        local legacyAttribute = player:GetAttribute("LegacyInventoryPayload")
        if legacyAttribute then
                print("[Server] Found legacy payload attribute for", player.Name)
                hydrateInventoryFromLegacy(inventory, legacyAttribute, {
                        source = "player-attribute",
                        dataset = InventoryConstants.LEGACY_DATASET_ID,
                })
                syncInventoryToClient(player)
        end

        player.CharacterAdded:Connect(function(character)
                print("[Server] Character added for:", player.Name)

                -- Send initial inventory to client when character spawns
                local currentInventory = playerInventories[player.UserId]
                if currentInventory then
                        print("[Server] Sending initial inventory to", player.Name, "with", countFilledSlots(currentInventory.slots), "items")
                        syncInventoryToClient(player)
                else
                        warn("[Server] No inventory found for", player.Name)
                end
        end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerInventories[player.UserId] = nil
	print("[Server] Cleaned up inventory for", player.Name)
end)

print("[Server] ✅ Inventory system loaded and ready!")

-- Debug item test event
local testItemEvent = Instance.new("RemoteEvent")
testItemEvent.Name = "TestItemEvent"
testItemEvent.Parent = ReplicatedStorage

testItemEvent.OnServerEvent:Connect(function(player, x, y)
    print("[Debug] Player " .. player.Name .. " testing item at " .. x .. ", " .. y)
    
    -- Create a test item at the player's position
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local worldPosition = humanoidRootPart.Position + Vector3.new(0, 2, 0)
    
    -- Create test item with specified coordinates
    local testItemId = "test_" .. x .. "_" .. y .. "_" .. os.time()
    
    -- Use the same dropItem logic but with custom coordinates
    local model = Instance.new("Model")
    model.Name = "TestItem_" .. testItemId
    model.Parent = workspace
    
    -- Create the main sprite part
    local spritePart = Instance.new("Part")
    spritePart.Name = "SpritePart"
    spritePart.Size = Vector3.new(4, 0.1, 4)
    spritePart.Material = Enum.Material.Neon
    spritePart.Color = Color3.new(0, 0, 0)
    spritePart.Transparency = 1
    spritePart.CanCollide = false
    spritePart.Anchored = true
    spritePart.CFrame = CFrame.new(worldPosition)
    spritePart.CastShadow = false
    spritePart.Parent = model
    
    -- Create surface GUI for the sprite
    local spriteGui = Instance.new("SurfaceGui")
    spriteGui.Face = Enum.NormalId.Top
    spriteGui.Parent = spritePart
    
    local spriteImage = Instance.new("ImageLabel")
    spriteImage.Size = UDim2.new(1, 0, 1, 0)
    spriteImage.BackgroundTransparency = 1
    spriteImage.Image = SpriteConfig.SHEET_ASSET
    spriteImage.ImageTransparency = 0
    spriteImage.ScaleType = Enum.ScaleType.Stretch
    spriteImage.Parent = spriteGui

    -- Apply the specified sprite coordinates
    local spriteIndex = SpriteConfig.getIndexFromGrid(x, y)
    local offset, size = SpriteConfig.getSpriteRect(spriteIndex)
    if offset and size then
        spriteImage.ImageRectOffset = offset
        spriteImage.ImageRectSize = size
    else
        spriteImage.ImageRectOffset = Vector2.new(0, 0)
        spriteImage.ImageRectSize = SpriteConfig.DEFAULT_IMAGE_RECT_SIZE
    end
    
    -- Add click detector for pickup
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = spritePart
    
    clickDetector.MouseClick:Connect(function(clickingPlayer)
        if clickingPlayer == player then
            print("[Debug] Test item picked up by " .. player.Name)
            model:Destroy()
        end
    end)
    
    print("[Debug] Test item created at " .. worldPosition .. " with sprite " .. x .. ", " .. y)
end)
