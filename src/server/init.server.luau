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

-- Create dropped item in the world with 3D sprite and proper tracking
local function createDroppedItem(player, itemId, count, worldPosition)
        if not ItemData[itemId] then
                warn("[Server] Unknown item:", itemId)
                return
        end

        local item = ItemData[itemId]
        local worldItemId = nextItemId
        nextItemId = nextItemId + 1

        local model = Instance.new("Model")
        model.Name = "WorldItem_" .. worldItemId .. "_" .. item.name
        model.Parent = workspace

        local pivot = Instance.new("Part")
        pivot.Name = "Pivot"
        pivot.Transparency = 1
        pivot.Anchored = true
        pivot.CanCollide = false
        pivot.CFrame = CFrame.new(worldPosition + Vector3.new(0, 2, 0))
        pivot.Parent = model

        local core = Instance.new("Part")
        core.Name = "Core"
        core.Size = Vector3.new(1.15, 1.15, 1.15)
        core.Material = Enum.Material.SmoothPlastic
        core.Color = Color3.fromHSV(((item.index or 1) % SpriteConfig.COLUMNS) / SpriteConfig.COLUMNS, 0.45, 1)
        core.CanCollide = false
        core.Anchored = false
        core.CFrame = pivot.CFrame
        core.CastShadow = true
        core.Parent = model

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Scale = Vector3.new(1.15, 0.7, 1.15)
        mesh.Parent = core

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = core
        weld.Part1 = pivot
        weld.Parent = core

        local sparkleBase = Instance.new("Part")
        sparkleBase.Name = "GlowRing"
        sparkleBase.Size = Vector3.new(1.25, 0.1, 1.25)
        sparkleBase.Material = Enum.Material.Neon
        sparkleBase.Color = Color3.fromRGB(255, 255, 255)
        sparkleBase.CanCollide = false
        sparkleBase.Anchored = false
        sparkleBase.CFrame = pivot.CFrame * CFrame.new(0, -0.5, 0)
        sparkleBase.Parent = model

        local ringMesh = Instance.new("SpecialMesh")
        ringMesh.MeshType = Enum.MeshType.Torus
        ringMesh.Scale = Vector3.new(1.25, 0.2, 1.25)
        ringMesh.Parent = sparkleBase

        local ringWeld = Instance.new("WeldConstraint")
        ringWeld.Part0 = sparkleBase
        ringWeld.Part1 = pivot
        ringWeld.Parent = sparkleBase

        local spriteBillboard = Instance.new("BillboardGui")
        spriteBillboard.Name = "SpriteBillboard"
        spriteBillboard.Size = UDim2.new(0, 96, 0, 96)
        spriteBillboard.LightInfluence = 0
        spriteBillboard.AlwaysOnTop = false
        spriteBillboard.StudsOffsetWorldSpace = Vector3.new(0, 0.9, 0)
        spriteBillboard.Parent = pivot

        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Size = UDim2.new(1, 0, 1, 0)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = "rbxassetid://74324628581851"
        imageLabel.ImageTransparency = 0
        imageLabel.Parent = spriteBillboard

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

        imageLabel.ImageRectOffset = offset
        imageLabel.ImageRectSize = size

        local nameBillboard = Instance.new("BillboardGui")
        nameBillboard.Name = "NameBillboard"
        nameBillboard.Size = UDim2.new(0, 140, 0, 32)
        nameBillboard.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
        nameBillboard.AlwaysOnTop = true
        nameBillboard.Parent = pivot

        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeColor3 = Color3.new(0.1, 0.1, 0.1)
        nameLabel.TextStrokeTransparency = 0.4
        nameLabel.Text = string.format("%s x%d", item.name, count)
        nameLabel.Parent = nameBillboard

        local attachment = Instance.new("Attachment")
        attachment.Parent = pivot
        attachment.Position = Vector3.new(0, 0.4, 0)

        local particleEmitter = Instance.new("ParticleEmitter")
        particleEmitter.Parent = attachment
        particleEmitter.LightEmission = 0.6
        particleEmitter.LightInfluence = 0
        particleEmitter.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.15),
                NumberSequenceKeypoint.new(0.5, 0.25),
                NumberSequenceKeypoint.new(1, 0),
        })
        particleEmitter.Lifetime = NumberRange.new(0.8, 1.2)
        particleEmitter.Rate = 12
        particleEmitter.Speed = NumberRange.new(0.6, 1.2)
        particleEmitter.SpreadAngle = Vector2.new(30, 30)
        particleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 235, 200))
        particleEmitter.Texture = "rbxassetid://130219045" -- sparkle texture

        local pointLight = Instance.new("PointLight")
        pointLight.Parent = pivot
        pointLight.Color = core.Color
        pointLight.Range = 6
        pointLight.Brightness = 1.6

        model.PrimaryPart = pivot

        worldItems[worldItemId] = {
                itemId = itemId,
                count = count,
                position = worldPosition,
                droppedBy = player.UserId,
                droppedAt = tick(),
                model = model,
        }

        TweenService:Create(pivot, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = worldPosition,
        }):Play()

        local bobConnection
        local baseTime = tick()
        local bobStart = baseTime + 0.35
        bobConnection = RunService.Heartbeat:Connect(function()
                if not model.Parent or not pivot.Parent then
                        if bobConnection then
                                bobConnection:Disconnect()
                        end
                        return
                end

                local now = tick()
                if now < bobStart then
                        return
                end

                local elapsed = now - baseTime
                local bobOffset = math.sin(elapsed * 2.2) * 0.15
                pivot.Position = Vector3.new(worldPosition.X, worldPosition.Y + 0.2 + bobOffset, worldPosition.Z)
        end)

        local function pickupItem(pickingPlayer)
                if not worldItems[worldItemId] then
                        return
                end

                print("[Server]", pickingPlayer.Name, "picked up", count, "x", item.name)

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

                worldItems[worldItemId] = nil

                if bobConnection then
                        bobConnection:Disconnect()
                end

                model:Destroy()
        end

        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 12
        clickDetector.Parent = core
        clickDetector.MouseClick:Connect(pickupItem)

        local proximityConnection
        proximityConnection = RunService.Heartbeat:Connect(function()
                if not model.Parent then
                        if proximityConnection then
                                proximityConnection:Disconnect()
                        end
                        return
                end

                for _, otherPlayer in ipairs(Players:GetPlayers()) do
                        local character = otherPlayer.Character
                        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                                local distance = (rootPart.Position - worldPosition).Magnitude
                                if distance <= 3 then
                                        pickupItem(otherPlayer)
                                        if proximityConnection then
                                                proximityConnection:Disconnect()
                                        end
                                        return
                                end
                        end
                end
        end)

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
	player.CharacterAdded:Connect(function(character)
		print("[Server] Character added for:", player.Name)
		task.wait(1)
		print("[Server] Initializing inventory for:", player.Name)
		initializePlayerInventory(player)
		
                -- Send initial inventory to client
                local inventory = playerInventories[player.UserId]
                if inventory then
                        print("[Server] Sending initial inventory to", player.Name, "with", countFilledSlots(inventory.slots), "items")
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