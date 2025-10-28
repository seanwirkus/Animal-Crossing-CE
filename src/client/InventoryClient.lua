local game = game
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Roblox globals are available automatically in Roblox environment

local InventoryClient = {}
InventoryClient.__index = InventoryClient
InventoryClient.MAX_SLOTS = 20  -- Constant for maximum inventory slots

local function cloneState(state)
    if not state then
        return nil
    end

    return {
        itemId = state.itemId,
        count = state.count,
    }
end

function InventoryClient.new()
    local self = setmetatable({}, InventoryClient)

    self.player = Players.LocalPlayer
    self.gui = self.player:WaitForChild("PlayerGui")

    self.sharedFolder = ReplicatedStorage:WaitForChild("Shared")
    self.itemDataFetcher = require(self.sharedFolder:WaitForChild("ItemDataFetcher"))
    self.spriteConfig = require(self.sharedFolder:WaitForChild("SpriteConfig"))

    self.inventoryRemote = ReplicatedStorage:WaitForChild("InventoryEvent")

    self.displayItems = self.itemDataFetcher.getDisplayItemMap()

    self.inventoryGui = nil
    self.inventoryFrame = nil
    self.inventoryItems = nil
    self.slotTemplate = nil

    self.visible = false
    self.slotsByIndex = {}
    self.maxSlots = 20  -- Match server's MAX_SLOTS
    self.slotState = {}
    self.drag = nil
    self.pendingData = nil

    self.connections = {}

    return self
end

function InventoryClient:disconnectAll()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    for k in pairs(self.connections) do
        self.connections[k] = nil
    end
end

function InventoryClient:trackConnection(connection)
    if connection then
        table.insert(self.connections, connection)
    end
end

function InventoryClient:getItemDefinition(itemId)
    return self.displayItems[itemId]
end

function InventoryClient:updateItemIcon(icon, itemDefinition)
    if not icon then
        return
    end

    if not itemDefinition or not itemDefinition.spriteIndex then
        icon.Image = ""
        return
    end

    local offset, size = self.spriteConfig.getSpriteRect(itemDefinition.spriteIndex)
    if not offset or not size then
        icon.Image = ""
        return
    end

    icon.Image = self.spriteConfig.SHEET_ASSET
    icon.ImageRectOffset = offset
    icon.ImageRectSize = size
end

function InventoryClient:updateSlotAppearance(slot, state)
    local icon = slot:FindFirstChild("ItemIcon")
    local countLabel = slot:FindFirstChild("ItemCount")
    local nameLabel = slot:FindFirstChild("ItemName")

    if state and state.itemId then
        local definition = self:getItemDefinition(state.itemId)
        self:updateItemIcon(icon, definition)

        if countLabel then
            if state.count and state.count > 1 then
                countLabel.Text = tostring(state.count)
                countLabel.Visible = true
            else
                countLabel.Text = ""
                countLabel.Visible = false
            end
        end

        if nameLabel then
            nameLabel.Text = definition and definition.name or state.itemId
            nameLabel.Visible = false  -- Start hidden, will show on hover
        end
    else
        if icon then
            icon.Image = ""
        end
        if countLabel then
            countLabel.Text = ""
            countLabel.Visible = false
        end
        if nameLabel then
            nameLabel.Text = ""
            nameLabel.Visible = false
        end
    end
end

function InventoryClient:ensureSlot(slotIndex)
    if self.slotsByIndex[slotIndex] and self.slotsByIndex[slotIndex].Parent then
        return self.slotsByIndex[slotIndex]
    end

    local clone = self.slotTemplate:Clone()
    clone.Name = "Slot_" .. slotIndex
    clone.Visible = true
    clone.Parent = self.inventoryItems
    self.slotsByIndex[slotIndex] = clone

    -- Ensure ItemName label exists for hover text
    local nameLabel = clone:FindFirstChild("ItemName")
    if not nameLabel then
        nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "ItemName"
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)  -- Bottom 30% of slot
        nameLabel.Position = UDim2.new(0, 0, 0.7, 0)  -- Bottom of slot
        nameLabel.BackgroundTransparency = 0.5
        nameLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextWrapped = true
        nameLabel.ZIndex = clone.ZIndex + 1
        nameLabel.Parent = clone
    end

    self:configureSlotInteractions(clone, slotIndex)

    return clone
end

function InventoryClient:configureSlotInteractions(slot, slotIndex)
    slot:SetAttribute("SlotIndex", slotIndex)

    local clickRegion = slot:FindFirstChild("ClickRegion")
    if not clickRegion then
        clickRegion = Instance.new("TextButton")
        clickRegion.Name = "ClickRegion"
        clickRegion.Text = ""
        clickRegion.BackgroundTransparency = 1
        clickRegion.AutoButtonColor = false
        clickRegion.Size = UDim2.new(1, 0, 1, 0)
        clickRegion.ZIndex = slot.ZIndex + 1
        clickRegion.Parent = slot
    end

    -- Primary click behaviour for drag/drop
    clickRegion.MouseButton1Down:Connect(function()
        print("[SLOT INTERACTION] Mouse down on slot", slotIndex)

        if self.drag then
            print("[SLOT INTERACTION] Attempting to drop currently dragged item")
            self.drag.justPickedUp = false
            local mousePos = UserInputService:GetMouseLocation()
            local destinationIndex = self:getSlotIndexFromPoint(mousePos) or slotIndex
            self:finishDrag(mousePos, false, destinationIndex)
            return
        end

        if not self.slotState[slotIndex] then
            print("[SLOT INTERACTION] Slot", slotIndex, "has no item to drag")
            return
        end

        print("[SLOT INTERACTION] Starting drag from slot", slotIndex)
        self:beginDrag(slotIndex)
    end)

    -- Mouse up finalises drag when the item has already been picked up
    clickRegion.MouseButton1Up:Connect(function()
        print("[SLOT INTERACTION] Mouse up on slot", slotIndex)
        if not self.drag then
            return
        end

        local mousePos = UserInputService:GetMouseLocation()
        local destinationIndex = self:getSlotIndexFromPoint(mousePos)

        if self.drag.justPickedUp and (not destinationIndex or destinationIndex == self.drag.originSlot) then
            print("[SLOT INTERACTION] Release on origin immediately after pickup - keeping item attached")
            self.drag.justPickedUp = false
            return
        end

        self.drag.justPickedUp = false
        print("[SLOT INTERACTION] Finishing drag from mouse up; destination:", destinationIndex)
        self:finishDrag(mousePos, false, destinationIndex)
    end)

    clickRegion.MouseEnter:Connect(function()
        local state = self.slotState[slotIndex]
        local nameLabel = slot:FindFirstChild("ItemName")
        if nameLabel and state and self.displayItems[state.itemId] then
            nameLabel.Text = self.displayItems[state.itemId].name
            nameLabel.Visible = true
        end
        -- Change background color on hover
        slot.BackgroundColor3 = Color3.fromHex("#04AFA6")
    end)

    clickRegion.MouseLeave:Connect(function()
        local nameLabel = slot:FindFirstChild("ItemName")
        if nameLabel then
            nameLabel.Visible = false
        end
        -- Reset background color to default (238, 226, 204)
        slot.BackgroundColor3 = Color3.fromRGB(238, 226, 204)
    end)
end

function InventoryClient:refreshSlot(slotIndex)
    local slot = self:ensureSlot(slotIndex)
    if not slot then
        return
    end

    slot.Visible = slotIndex <= self.maxSlots
    self:updateSlotAppearance(slot, self.slotState[slotIndex])
end

function InventoryClient:setInventoryVisible(shouldShow)
    self.visible = shouldShow
    print("[InventoryClient] setInventoryVisible called with:", shouldShow)
    print("[InventoryClient] self.inventoryFrame:", self.inventoryFrame)
    print("[InventoryClient] self.inventoryGui:", self.inventoryGui)

    if not self.inventoryFrame then
        print("[InventoryClient] ❌ inventoryFrame is nil, cannot set visibility")
        return
    end

    self.inventoryFrame.Visible = shouldShow
    print("[InventoryClient] ✅ Set inventoryFrame.Visible to:", shouldShow)

    if not shouldShow and self.drag then
        self:finishDrag(nil, true)
    end
end

function InventoryClient:createGhost(state)
    local ghost = self.slotTemplate:Clone()
    ghost.Name = "DragGhost"
    ghost.Visible = true
    ghost.Active = false
    ghost.Selectable = false
    ghost.ZIndex = 200
    ghost.AnchorPoint = Vector2.new(0.5, 0.5)

    local templateSize = self.slotTemplate.AbsoluteSize
    local width = templateSize.X
    local height = templateSize.Y

    if width == 0 or height == 0 then
        local size = self.slotTemplate.Size
        width = size.X.Offset
        height = size.Y.Offset
    end

    if width == 0 then
        width = 72
    end

    if height == 0 then
        height = 72
    end

    local scaleFactor = 0.85
    ghost.Size = UDim2.fromOffset(math.floor(width * scaleFactor), math.floor(height * scaleFactor))

    for _, child in ipairs(ghost:GetChildren()) do
        if child:IsA("GuiButton") then
            child:Destroy()
        end
    end

    ghost.Parent = self.inventoryGui
    self:updateSlotAppearance(ghost, state)

    return ghost
end

function InventoryClient:updateGhostPosition()
    if not self.drag or not self.drag.ghost or not self.drag.ghost.Parent then
        return
    end

    local position = UserInputService:GetMouseLocation()
    self.drag.ghost.Position = UDim2.fromOffset(position.X, position.Y)
end

function InventoryClient:beginDrag(slotIndex)
    print("[DRAG DEBUG] beginDrag called for slot:", slotIndex)
    print("[DRAG DEBUG] Current slotState for slot " .. slotIndex .. ":", self.slotState[slotIndex])
    
    if self.drag then
        print("[DRAG DEBUG] Already dragging, finishing previous drag")
        self:finishDrag(nil, true)
    end

    local state = self.slotState[slotIndex]
    if not state then
        print("[DRAG DEBUG] ❌ No state found for slot", slotIndex, "- aborting drag")
        return
    end

    print("[DRAG DEBUG] Removing item from slot", slotIndex, "temporarily")
    self.slotState[slotIndex] = nil
    self:refreshSlot(slotIndex)

    local ghost = self:createGhost(state)

    self.drag = {
        originSlot = slotIndex,
        state = cloneState(state),
        ghost = ghost,
        connection = RunService.RenderStepped:Connect(function()
            self:updateGhostPosition()
        end),
        justPickedUp = true,
    }

    print("[DRAG DEBUG] ✅ Drag started successfully for item:", state.itemId, "count:", state.count)
    self:updateGhostPosition()
end

function InventoryClient:getSlotIndexFromPoint(point)
    print("[SLOT DEBUG] Checking point:", point.X, point.Y)
    for index, slot in pairs(self.slotsByIndex) do
        if slot and slot.Visible then
            local pos = slot.AbsolutePosition
            local size = slot.AbsoluteSize
            print("[SLOT DEBUG] Slot", index, "bounds: pos(", pos.X, pos.Y, ") size(", size.X, size.Y, ")")
            if point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y then
                print("[SLOT DEBUG] ✅ Point is in slot", index)
                return index
            end
        end
    end
    print("[SLOT DEBUG] ❌ Point not in any slot")
    return nil
end

function InventoryClient:dropItemToWorld(dragState, mousePosition)
    self.slotState[dragState.originSlot] = nil
    self:refreshSlot(dragState.originSlot)

    -- Drop item at a fixed short distance in front of the player instead of raycasting to mouse
    local character = self.player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

    local worldPosition
    if humanoidRootPart then
        -- Drop 2-3 feet in front of the player
        local forwardDirection = humanoidRootPart.CFrame.LookVector
        worldPosition = humanoidRootPart.Position + forwardDirection * 3 + Vector3.new(0, 0, 0)  -- 3 studs forward
    else
        -- Fallback to camera position if no character
        local camera = workspace.CurrentCamera
        worldPosition = camera.CFrame.Position + camera.CFrame.LookVector * 6
    end

    self.inventoryRemote:FireServer("DropItem", {
        itemId = dragState.state.itemId,
        count = dragState.state.count,
        slotIndex = dragState.originSlot,
        worldPosition = worldPosition,
    })
end

function InventoryClient:finishDrag(mousePos, cancelled, targetIndex)
    print("[DRAG DEBUG] finishDrag called - cancelled:", cancelled, "targetIndex:", targetIndex)
    
    local dragState = self.drag
    if not dragState then
        print("[DRAG DEBUG] ❌ No drag state found!")
        return
    end

    if dragState.connection then
        dragState.connection:Disconnect()
    end

    if dragState.ghost then
        dragState.ghost:Destroy()
    end

    self.drag = nil

    if cancelled then
        print("[DRAG DEBUG] Drag cancelled - restoring item to slot", dragState.originSlot)
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        return
    end

    -- If no target index provided, try to find it from mouse position
    local destinationIndex = targetIndex or self:getSlotIndexFromPoint(mousePos or UserInputService:GetMouseLocation())
    
    print("[DRAG DEBUG] Destination index:", destinationIndex, "Origin slot:", dragState.originSlot)

    if not destinationIndex then
        print("[DRAG DEBUG] Dropped outside inventory grid - sending to world")
        self:dropItemToWorld(dragState, mousePos)
        return
    end

    if destinationIndex == dragState.originSlot then
        print("[DRAG DEBUG] Dropped back on origin slot - restoring")
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        return
    end

    -- Simple swap/move logic
    print("[DRAG DEBUG] Swapping items between slot", dragState.originSlot, "and", destinationIndex)
    
    local destinationItem = self.slotState[destinationIndex]
    
    -- Put dragged item in destination
    self.slotState[destinationIndex] = cloneState(dragState.state)
    
    -- Put what was at destination into origin (if anything)
    if destinationItem then
        self.slotState[dragState.originSlot] = cloneState(destinationItem)
    else
        self.slotState[dragState.originSlot] = nil
    end
    
    -- Refresh UI
    self:refreshSlot(dragState.originSlot)
    self:refreshSlot(destinationIndex)
    
    -- Send to server - always use swap=true for drag operations
    self.inventoryRemote:FireServer("MoveItem", {
        fromIndex = dragState.originSlot,
        toIndex = destinationIndex,
        swap = true,
    })
    
    print("[DRAG DEBUG] ✅ Move complete, sent to server")
end

function InventoryClient:populateFromServer(payload)
    print("[POPULATE DEBUG] populateFromServer called")
    print("[POPULATE DEBUG] Payload:", payload)
    print("[POPULATE DEBUG] inventoryItems exists:", self.inventoryItems ~= nil)
    print("[POPULATE DEBUG] slotTemplate exists:", self.slotTemplate ~= nil)
    
    if not self.inventoryItems or not self.slotTemplate then
        print("[POPULATE DEBUG] Not ready yet, storing as pendingData")
        self.pendingData = payload
        return
    end

    if self.drag then
        print("[POPULATE DEBUG] Cancelling current drag operation")
        self:finishDrag(nil, true)
    end

    local maxSlots = 20
    local incomingSlots = {}

    if typeof(payload) == "table" then
        if payload.maxSlots then
            maxSlots = payload.maxSlots
            print("[POPULATE DEBUG] Max slots from server:", maxSlots)
        end

        if payload.slots then
            print("[POPULATE DEBUG] Using payload.slots")
            for index, slot in pairs(payload.slots) do
                incomingSlots[index] = slot
            end
        else
            print("[POPULATE DEBUG] Using payload as array")
            for index, slot in ipairs(payload) do
                incomingSlots[index] = slot
            end
        end
    end

    print("[POPULATE DEBUG] Incoming slots data:")
    for index, slot in pairs(incomingSlots) do
        if slot then
            print("[POPULATE DEBUG]   Slot", index, ":", slot.itemId, "x" .. (slot.count or 0))
        end
    end

    self.maxSlots = maxSlots

    print("[POPULATE DEBUG] Current state before populate:")
    for i = 1, self.maxSlots do
        if self.slotState[i] then
            print("[POPULATE DEBUG]   Slot", i, ":", self.slotState[i].itemId, "x" .. self.slotState[i].count)
        end
    end

    -- First, clear all slots
    for index = 1, self.maxSlots do
        self.slotState[index] = nil
    end
    
    -- Then, set only the slots that have items (from server data)
    for index, slotData in pairs(incomingSlots) do
        if slotData and slotData.itemId and slotData.count and slotData.count > 0 then
            self.slotState[index] = {
                itemId = slotData.itemId,
                count = slotData.count,
            }
            print("[POPULATE DEBUG] Set slot", index, "to:", slotData.itemId, "x" .. slotData.count)
        end
    end
    
    -- Finally, refresh all slot UIs
    for index = 1, self.maxSlots do
        self:refreshSlot(index)
    end

    print("[POPULATE DEBUG] Final state after populate:")
    for i = 1, self.maxSlots do
        if self.slotState[i] then
            print("[POPULATE DEBUG]   Slot", i, ":", self.slotState[i].itemId, "x" .. self.slotState[i].count)
        end
    end

    for index, slot in pairs(self.slotsByIndex) do
        if index > self.maxSlots then
            slot.Visible = false
            self.slotState[index] = nil
        end
    end
end

function InventoryClient:requestInventory()
    if self.inventoryRemote then
        self.inventoryRemote:FireServer("RequestInventory")
    end
end

function InventoryClient:setupRemoteHandling()
    self:trackConnection(self.inventoryRemote.OnClientEvent:Connect(function(action, data)
        if action == "SyncInventory" then
            self:populateFromServer(data)
        end
    end))
end

function InventoryClient:bindInput()
    -- Handle sync from server
    self:trackConnection(self.inventoryRemote.OnClientEvent:Connect(function(action, data)
        print("[SYNC DEBUG] Received server event - action:", action)
        
        if action == "SyncInventory" then
            print("[SYNC DEBUG] SyncInventory received from server")
            print("[SYNC DEBUG] Data received:", data)
            
            -- Save current state for items being dragged
            local draggedState = self.drag and self.drag.state
            local dragOrigin = self.drag and self.drag.originSlot
            
            if draggedState then
                print("[SYNC DEBUG] Preserving dragged item:", draggedState.itemId, "from slot", dragOrigin)
            end
            
            -- Log current state before sync
            print("[SYNC DEBUG] Client state before sync:")
            for i = 1, self.maxSlots do
                if self.slotState[i] then
                    print("[SYNC DEBUG]   Slot", i, ":", self.slotState[i].itemId, "x" .. self.slotState[i].count)
                end
            end
            
            -- Update state
            if data and data.slots then
                print("[SYNC DEBUG] Updating slots from server data")
                for i = 1, data.maxSlots or self.maxSlots do
                    if data.slots[i] then
                        self.slotState[i] = {
                            itemId = data.slots[i].itemId,
                            count = data.slots[i].count
                        }
                    else
                        self.slotState[i] = nil
                    end
                end
            end
            
            -- Restore dragged item state if needed
            if draggedState and dragOrigin then
                print("[SYNC DEBUG] Restoring dragged item to slot", dragOrigin)
                self.slotState[dragOrigin] = draggedState
            end
            
            -- Log state after sync
            print("[SYNC DEBUG] Client state after sync:")
            for i = 1, self.maxSlots do
                if self.slotState[i] then
                    print("[SYNC DEBUG]   Slot", i, ":", self.slotState[i].itemId, "x" .. self.slotState[i].count)
                end
            end
            
            -- Refresh all slots
            for i = 1, self.maxSlots do
                self:refreshSlot(i)
            end
            
            print("[SYNC DEBUG] ✅ Sync complete, all slots refreshed")
        end
    end))
end

function InventoryClient:attachGui()
    -- Wait for GUI to be copied from StarterGui to PlayerGui
    self.inventoryGui = self.gui:WaitForChild("InventoryGUI", 5)
    if not self.inventoryGui then
        warn("[InventoryClient] InventoryGUI not found in PlayerGui after waiting")
        return false
    end
    
    print("[InventoryClient] ✅ Found InventoryGUI in PlayerGui")

    self.inventoryFrame = self.inventoryGui:FindFirstChild("InventoryFrame")
    if not self.inventoryFrame then
        warn("[InventoryClient] InventoryFrame missing")
        return false
    end

    self.inventoryItems = self.inventoryFrame:FindFirstChild("InventoryItems")
    if not self.inventoryItems then
        warn("[InventoryClient] InventoryItems missing")
        return false
    end

    self.slotTemplate = self.inventoryItems:FindFirstChild("ItemSlotTemplate")
    if not self.slotTemplate then
        warn("[InventoryClient] ItemSlotTemplate missing")
        return false
    end

    self.slotTemplate.Visible = false
    self.inventoryGui.Enabled = true
    self.inventoryFrame.Visible = false

    for index, slot in pairs(self.slotsByIndex) do
        if slot.Parent ~= self.inventoryItems then
            slot:Destroy()
            self.slotsByIndex[index] = nil
        end
    end

    return true
end

function InventoryClient:start()
    if not self:attachGui() then
        return
    end

    self:bindInput()
    self:setupRemoteHandling()

    if self.pendingData then
        self:populateFromServer(self.pendingData)
        self.pendingData = nil
    end

    self:requestInventory()
end

function InventoryClient.init()
    local controller = InventoryClient.new()
    controller:start()
    return controller
end

return InventoryClient
