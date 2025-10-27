-- Server initialization script
-- Complete server-side inventory management

print("✅ Animal Crossing server systems ready!")
print("📊 ServerScriptService scripts will run automatically")

-- Import services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

print("[Server] 🚀 Starting inventory system...")

-- Create RemoteEvent
local inventoryRemote = ReplicatedStorage:FindFirstChild("InventoryEvent") or Instance.new("RemoteEvent")
inventoryRemote.Name = "InventoryEvent"
inventoryRemote.Parent = ReplicatedStorage

-- Player inventory storage
local playerInventories = {}

-- Inventory slot configuration
local MAX_SLOTS = 20

-- World item storage - tracks all dropped items
local worldItems = {}
local nextItemId = 1

-- ItemData for server
local ItemData = {
	-- Row 1: Tools (indices 1-21) - ACTUAL ORDER FROM SPRITE SHEET
	leaf = { index = 1, name = "Leaf" },
	shovel = { index = 2, name = "Shovel" },
	net = { index = 3, name = "Net" },
	slingshot = { index = 4, name = "Slingshot" },
	fishing_rod = { index = 5, name = "Fishing Rod" },
	watering_can = { index = 6, name = "Watering Can" },
	axe = { index = 7, name = "Axe" },
	stone_axe = { index = 8, name = "Stone Axe" },
	shovel_2 = { index = 9, name = "Shovel" }, -- Another shovel variant
	pole_vault = { index = 10, name = "Vaulting Pole" },
	ladder = { index = 11, name = "Ladder" },
	flute = { index = 12, name = "Pan Flute" },
	flute_2 = { index = 13, name = "Flute" }, -- Another flute variant
	tambourine = { index = 14, name = "Tambourine" },
	golden_axe = { index = 15, name = "Golden Axe" },
	golden_net = { index = 16, name = "Golden Net" },
	golden_shovel = { index = 17, name = "Golden Shovel" },
	golden_can = { index = 18, name = "Golden Can" },
	golden_slingshot = { index = 19, name = "Golden Slingshot" },
	golden_fishing_rod = { index = 20, name = "Golden Fishing Rod" },
	golden_ladder = { index = 21, name = "Golden Ladder" },
	
	-- Row 2: Clothing/Items (indices 22-42)
	glasses_red = { index = 22, name = "Red Glasses" },
	shirt_striped = { index = 23, name = "Striped Shirt" },
	shirt_blue = { index = 24, name = "Blue Shirt" },
	bag_blue = { index = 25, name = "Bag (Blue)" },
	socks = { index = 26, name = "Socks" },
	shoes_yellow = { index = 27, name = "Shoes (Yellow)" },
	shoes_black = { index = 28, name = "Shoes (Black)" },
	umbrella_red = { index = 29, name = "Red Umbrella" },
	purse_pink = { index = 30, name = "Purse (Pink)" },
	egg_purple = { index = 31, name = "Purple Egg" },
	egg_orange = { index = 32, name = "Orange Egg" },
	egg_yellow = { index = 33, name = "Yellow Egg" },
	egg_green = { index = 34, name = "Green Egg" },
	bell_bag_small = { index = 35, name = "Small Bell Bag" },
	bell_bag_med = { index = 36, name = "Bell Bag" },
	bell_bag_large = { index = 37, name = "Large Bell Bag" },
	bottle_message = { index = 38, name = "Message Bottle" },
	recipe_card = { index = 39, name = "DIY Recipe Card" },
	paper_gift = { index = 40, name = "Gift Bag" },
	leaf_fossil = { index = 41, name = "Fossil Leaf" },
	
	-- Row 3: Flowers (indices 43-63)
	rose_red = { index = 43, name = "Red Rose" },
	rose_white = { index = 44, name = "White Rose" },
	rose_pink = { index = 45, name = "Pink Rose" },
	rose_yellow = { index = 46, name = "Yellow Rose" },
	tulip_red = { index = 47, name = "Red Tulip" },
	tulip_white = { index = 48, name = "White Tulip" },
	tulip_orange = { index = 49, name = "Orange Tulip" },
	lily_pink = { index = 50, name = "Pink Lily" },
	lily_yellow = { index = 51, name = "Yellow Lily" },
	lily_white = { index = 52, name = "White Lily" },
	mum_purple = { index = 53, name = "Purple Mum" },
	mum_red = { index = 54, name = "Red Mum" },
	mum_white = { index = 55, name = "White Mum" },
	hyacinth_blue = { index = 56, name = "Blue Hyacinth" },
	hyacinth_pink = { index = 57, name = "Pink Hyacinth" },
	hyacinth_orange = { index = 58, name = "Orange Hyacinth" },
	hyacinth_white = { index = 59, name = "White Hyacinth" },
	cosmos_red = { index = 60, name = "Red Cosmos" },
	cosmos_yellow = { index = 61, name = "Yellow Cosmos" },
	cosmos_white = { index = 62, name = "White Cosmos" },
	
	-- Row 4: Fish (indices 64-84)
	fish_betta = { index = 64, name = "Betta" },
	fish_clown = { index = 65, name = "Clownfish" },
	fish_puffer = { index = 66, name = "Pufferfish" },
	fish_tuna = { index = 67, name = "Tuna" },
	fish_bass = { index = 68, name = "Black Bass" },
	fish_snapper = { index = 69, name = "Red Snapper" },
	fish_goldfish = { index = 70, name = "Goldfish" },
	fish_koi = { index = 71, name = "Koi" },
	fish_loach = { index = 72, name = "Loach" },
	fish_seahorse = { index = 73, name = "Seahorse" },
	
	-- Row 5: Bugs (indices 85-105)
	bug_butterfly = { index = 85, name = "Common Butterfly" },
	bug_moth = { index = 86, name = "Moth" },
	bug_ladybug = { index = 87, name = "Ladybug" },
	bug_beetle = { index = 88, name = "Stag Beetle" },
	bug_dragonfly = { index = 89, name = "Dragonfly" },
	bug_firefly = { index = 90, name = "Firefly" },
	bug_spider = { index = 91, name = "Spider" },
	bug_scorpion = { index = 92, name = "Scorpion" },
	bug_tar = { index = 93, name = "Tarantula" },
	bug_cicada = { index = 94, name = "Cicada" },
	
	-- Row 6: Seasonal (indices 106-126)
	snowflake = { index = 106, name = "Snowflake" },
	ornament_red = { index = 107, name = "Red Ornament" },
	ornament_blue = { index = 108, name = "Blue Ornament" },
	ornament_gold = { index = 109, name = "Gold Ornament" },
	pumpkin_orange = { index = 110, name = "Orange Pumpkin" },
	pumpkin_white = { index = 111, name = "White Pumpkin" },
	pumpkin_yellow = { index = 112, name = "Yellow Pumpkin" },
	pumpkin_green = { index = 113, name = "Green Pumpkin" },
	heart_pink = { index = 114, name = "Heart Crystal" },
}

local SpriteConfig = {
        SHEET_ASSET = "rbxassetid://74324628581851",
        COLUMNS = 21,
        ROWS = 24,
        TILE = 36.6,
        INNER = Vector2.new(6, 6),
        OUTER = Vector2.new(4, 4),
        BLEED_FIX = 0.25,
}

-- Initialize player inventory
local function initializePlayerInventory(player)
        local starterItems = {
                -- Essential Tools
                { itemId = "shovel", count = 1 },
                { itemId = "net", count = 1 },
                { itemId = "fishing_rod", count = 1 },
                { itemId = "watering_can", count = 1 },
                { itemId = "axe", count = 1 },
                { itemId = "slingshot", count = 1 },
                { itemId = "ladder", count = 1 },

                -- Starting Currency
                { itemId = "bell_bag_small", count = 5 },
                { itemId = "bell_bag_med", count = 2 },

                -- Sample Flowers
                { itemId = "rose_red", count = 3 },
                { itemId = "rose_white", count = 2 },
                { itemId = "tulip_red", count = 2 },

                -- Sample Fish
                { itemId = "fish_betta", count = 1 },
                { itemId = "fish_goldfish", count = 1 },

                -- Sample Bugs
                { itemId = "bug_butterfly", count = 2 },
                { itemId = "bug_ladybug", count = 1 },

                -- Basic Materials (using items that exist in our mapping)
                { itemId = "egg_purple", count = 3 },
                { itemId = "egg_orange", count = 2 },
                { itemId = "leaf_fossil", count = 1 },
        }

        local slots = table.create(MAX_SLOTS)
        for i = 1, MAX_SLOTS do
                slots[i] = nil
        end

        for index, item in ipairs(starterItems) do
                if index > MAX_SLOTS then break end
                slots[index] = { itemId = item.itemId, count = item.count }
        end

        playerInventories[player.UserId] = {
                slots = slots,
                maxSlots = MAX_SLOTS,
        }

        print("[Server] ✅ Initialized inventory for", player.Name, "with", #starterItems, "starter items and", MAX_SLOTS, "slots")
end

local function cloneSlots(slots)
        local serialized = {}
        for index = 1, MAX_SLOTS do
                local slot = slots[index]
                if slot and slot.itemId and slot.count and slot.count > 0 then
                        serialized[index] = {
                                itemId = slot.itemId,
                                count = slot.count,
                        }
                end
        end
        return serialized
end

local function countFilledSlots(slots)
        local count = 0
        for index = 1, MAX_SLOTS do
                if slots[index] then
                        count += 1
                end
        end
        return count
end

local function syncInventoryToClient(player)
	local inventory = playerInventories[player.UserId]
	if not inventory then return end

	inventoryRemote:FireClient(player, "SyncInventory", {
		maxSlots = inventory.maxSlots or MAX_SLOTS,
		slots = cloneSlots(inventory.slots),
	})
end

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

        -- Create ultra 3D layered depth effect with enhanced shadows
        -- Ground shadow (darkest, largest)
        local groundShadow = Instance.new("Part")
        groundShadow.Name = "GroundShadow"
        groundShadow.Size = Vector3.new(5.5, 0.05, 5.5) -- Larger shadow
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
        groundShadowSprite.ImageTransparency = 0.6
        groundShadowSprite.ImageColor3 = Color3.new(0.1, 0.1, 0.1) -- Very dark shadow
        groundShadowSprite.ScaleType = Enum.ScaleType.Stretch
        groundShadowSprite.Parent = groundShadowGui

        -- Calculate sprite rect for this specific item
        local offset, size = Vector2.new(0, 0), Vector2.new(36, 36)
        if item.index then
                local i0 = item.index - 1
                local col = i0 % SpriteConfig.COLUMNS
                local row = math.floor(i0 / SpriteConfig.COLUMNS)
                local x = math.floor(SpriteConfig.OUTER.X + col * (SpriteConfig.TILE + SpriteConfig.INNER.X) + 0.5)
                local y = math.floor(SpriteConfig.OUTER.Y + row * (SpriteConfig.TILE + SpriteConfig.INNER.Y) + 0.5)
                local spriteSize = math.floor(SpriteConfig.TILE - SpriteConfig.BLEED_FIX * 2 + 0.5)
                offset = Vector2.new(x + SpriteConfig.BLEED_FIX, y + SpriteConfig.BLEED_FIX)
                size = Vector2.new(spriteSize, spriteSize)
        end

        -- Apply sprite rect to ground shadow
        groundShadowSprite.ImageRectOffset = offset
        groundShadowSprite.ImageRectSize = size

        -- Create SOLID depth layers - no transparency, solid opaque depth
        local depthLayers = {}
        local layerCount = 8 -- Fewer layers, all solid
        
        for i = 1, layerCount do
                local layerPart = Instance.new("Part")
                layerPart.Name = "DepthLayer_" .. i
                
                -- Solid layer properties - all opaque, no transparency
                local progress = i / layerCount -- 0 to 1
                local sizeMultiplier = 1 + (progress * 0.3) -- 1.0 to 1.3 (subtle size increase)
                local height = 0.1 -- All layers same height - solid thickness
                local darkness = 0.1 + (progress * 0.4) -- 0.1 to 0.5 (dark to medium)
                
                -- Stack layers tightly together for solid depth
                local heightOffset = 0.01 + (progress * 0.08) -- 0.01 to 0.09 (tight stacking)
                
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
                layerSprite.ImageTransparency = 0 -- NO TRANSPARENCY - completely opaque
                layerSprite.ImageColor3 = Color3.new(darkness, darkness, darkness)
                layerSprite.ScaleType = Enum.ScaleType.Stretch
                layerSprite.Parent = layerGui
                
                -- Apply sprite rect for proper item display
                layerSprite.ImageRectOffset = offset
                layerSprite.ImageRectSize = size
                
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
        imageLabel.ImageRectOffset = offset
        imageLabel.ImageRectSize = size

	-- Enhanced point light with better range and color
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "SpriteGlow"
	pointLight.Range = 12 -- Increased range
	pointLight.Brightness = 2.2 -- Brighter
	pointLight.Color = Color3.fromRGB(255, 235, 200) -- Warmer color
	pointLight.Shadows = false
	pointLight.Parent = spritePart

	-- Enhanced sparkles with better color and effect
	local sparkles = Instance.new("Sparkles")
	sparkles.Name = "SpriteSparkles"
	sparkles.SparkleColor = Color3.fromRGB(255, 245, 220) -- Warmer sparkle color
	sparkles.Parent = spritePart

	-- Add additional ambient light for extra glow
	local ambientLight = Instance.new("PointLight")
	ambientLight.Name = "AmbientGlow"
	ambientLight.Range = 8
	ambientLight.Brightness = 1.2
	ambientLight.Color = Color3.fromRGB(255, 250, 240)
	ambientLight.Shadows = false
	ambientLight.Parent = pivot

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
                                        slots[existingIndex].count += count
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

        elseif action == "DropItem" and data then
                local itemId = data.itemId
                local count = data.count or 1
                local slotIndex = data.slotIndex
                local worldPosition = data.worldPosition or Vector3.new(0, 10, 0)

                print("[Server]", player.Name, "dropped", count, "x", ItemData[itemId] and ItemData[itemId].name or itemId, "at world position", worldPosition)

                local slots = inventory.slots
                local function removeFromSlot(index)
                        local slot = slots[index]
                        if slot and slot.itemId == itemId and slot.count >= count then
                                slot.count -= count
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
                local swap = data.swap

                if not fromIndex or not toIndex then
                        return
                end

                if fromIndex < 1 or fromIndex > (inventory.maxSlots or MAX_SLOTS) then
                        return
                end

                if toIndex < 1 or toIndex > (inventory.maxSlots or MAX_SLOTS) then
                        return
                end

                local slots = inventory.slots
                local moving = slots[fromIndex]
                if not moving then
                        return
                end

                if swap and slots[toIndex] then
                        slots[fromIndex], slots[toIndex] = slots[toIndex], moving
                else
                        slots[toIndex] = moving
                        slots[fromIndex] = nil
                end

                syncInventoryToClient(player)

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
	
	-- Track if inventory has been initialized for this player
	local inventoryInitialized = false
	
	player.CharacterAdded:Connect(function(character)
		print("[Server] Character added for:", player.Name)
		
		-- Only initialize inventory once per player
		if not inventoryInitialized then
			task.wait(1)
			print("[Server] Initializing inventory for:", player.Name)
			initializePlayerInventory(player)
			inventoryInitialized = true
			
			-- Send initial inventory to client
			local inventory = playerInventories[player.UserId]
			if inventory then
				print("[Server] Sending initial inventory to", player.Name, "with", countFilledSlots(inventory.slots), "items")
				syncInventoryToClient(player)
			else
				warn("[Server] No inventory found for", player.Name)
			end
		else
			print("[Server] Inventory already initialized for", player.Name, "- skipping")
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
    spriteImage.ImageRectOffset = Vector2.new(x * 32, y * 32)
    spriteImage.ImageRectSize = Vector2.new(32, 32)
    
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
