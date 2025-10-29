local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

    -- Ensure proper ScaleType for sprite rendering
    if icon.ScaleType ~= Enum.ScaleType.Fit then
        icon.ScaleType = Enum.ScaleType.Fit
    end

    if not self.spriteConfig.applySprite(icon, itemDefinition.spriteIndex) then
        icon.Image = ""
    end
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

    clickRegion.MouseButton1Down:Connect(function()
        if self.drag then
            self:finishDrag(UserInputService:GetMouseLocation(), false, slotIndex)
        else
            if self.slotState[slotIndex] then
                self:beginDrag(slotIndex)
            end
        end
    end)

    clickRegion.MouseEnter:Connect(function()
        local state = self.slotState[slotIndex]
        local nameLabel = slot:FindFirstChild("ItemName")
        if nameLabel and state and self.displayItems[state.itemId] then
            nameLabel.Text = self.displayItems[state.itemId].name
            nameLabel.Visible = true
        end
        slot.BackgroundColor3 = Color3.fromHex("#04AFA6")
    end)

    clickRegion.MouseLeave:Connect(function()
        local nameLabel = slot:FindFirstChild("ItemName")
        if nameLabel then
            nameLabel.Visible = false
        end
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
    local ghostSize = self.drag.ghost.AbsoluteSize
    local yOffset = ghostSize.Y > 0 and ghostSize.Y * 0.4 or 20
    self.drag.ghost.Position = UDim2.fromOffset(position.X, position.Y - yOffset)
end

function InventoryClient:beginDrag(slotIndex)
    if self.drag then
        self:finishDrag(nil, true) -- Cancel previous drag
    end

    local state = self.slotState[slotIndex]
    if not state then return end

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
    }

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

function InventoryClient:dropItemToWorld(dragState, mousePos)
    print("[DRAG DEBUG] Attempting to drop item to world")
    local character = self.player.Character
    if not character then
        print("[DRAG DEBUG] ❌ No character found to drop item from")
        self:finishDrag(mousePos, true) -- Cancel drag
        return
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        print("[DRAG DEBUG] ❌ No HumanoidRootPart found")
        self:finishDrag(mousePos, true) -- Cancel drag
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        print("[DRAG DEBUG] ❌ No camera found")
        self:finishDrag(mousePos, true) -- Cancel drag
        return
    end

    -- Drop it a few studs in front of the player
    local forwardDirection = humanoidRootPart.CFrame.LookVector
    local worldPosition = humanoidRootPart.Position + forwardDirection * 3 + Vector3.new(0, 0, 0) -- 3 studs forward

    self.inventoryRemote:FireServer("DropItem", {
        itemId = dragState.state.itemId,
        count = dragState.state.count,
        position = worldPosition,
    })

    print("[DRAG DEBUG] ✅ Fired DropItem event to server")
end

function InventoryClient:finishDrag(mousePos, cancelled, targetIndex)
    local dragState = self.drag
    if not dragState then return end

    if dragState.connection then
        dragState.connection:Disconnect()
    end
    if dragState.ghost then
        dragState.ghost:Destroy()
    end
    self.drag = nil

    if cancelled then
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        return
    end

    local destinationIndex = targetIndex or self:getSlotIndexFromPoint(mousePos or UserInputService:GetMouseLocation())

    if not destinationIndex then
        -- Dropped outside of inventory, put it back for now.
        -- World drop can be re-implemented here if desired.
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        -- Fire drop event
        self:dropItemToWorld(dragState, mousePos)
        return
    end

    if destinationIndex == dragState.originSlot then
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        return
    end

    -- Optimistically update client state
    local destinationItem = self.slotState[destinationIndex]
    self.slotState[destinationIndex] = cloneState(dragState.state)
    if destinationItem then
        self.slotState[dragState.originSlot] = cloneState(destinationItem)
    else
        self.slotState[dragState.originSlot] = nil
    end

    self:refreshSlot(dragState.originSlot)
    self:refreshSlot(destinationIndex)

    -- Inform server of the move
    self.inventoryRemote:FireServer("MoveItem", {
        fromIndex = dragState.originSlot,
        toIndex = destinationIndex,
        swap = true,
    })
end

function InventoryClient:populateFromServer(payload)
    print("[POPULATE DEBUG] populateFromServer called")
    
    if not self.inventoryItems or not self.slotTemplate then
        print("[POPULATE DEBUG] Not ready yet, storing as pendingData")
        self.pendingData = payload
        return
    end

    if self.drag then
        print("[POPULATE DEBUG] Cancelling current drag operation due to server sync")
        self:finishDrag(nil, true)
    end

    local maxSlots = (payload and payload.maxSlots) or self.maxSlots or 20
    local incomingSlots = (payload and payload.slots) or {}

    self.maxSlots = maxSlots

    -- Create a fresh state table
    local newState = {}
    for i = 1, self.maxSlots do
        local slotData = incomingSlots[tostring(i)] or incomingSlots[i]
        if slotData and slotData.itemId and slotData.count and slotData.count > 0 then
            newState[i] = {
                itemId = slotData.itemId,
                count = slotData.count,
            }
        end
    end
    
    self.slotState = newState

    -- Refresh all visible slots
    for i = 1, self.maxSlots do
        self:refreshSlot(i)
    end

    -- Hide slots that are no longer in use
    for index, slot in pairs(self.slotsByIndex) do
        if index > self.maxSlots then
            slot.Visible = false
        end
    end
    
    print("[POPULATE DEBUG] ✅ Population complete. Slots refreshed.")
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

    self:trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and self.drag then
            local mousePos = UserInputService:GetMouseLocation()
            if not self:getSlotIndexFromPoint(mousePos) then
                self:finishDrag(mousePos, false, nil)
            end
        end
    end))
end

function InventoryClient:bindInput()
    -- This is now handled by setupRemoteHandling to avoid duplicate listeners
end

function InventoryClient:attachGui()
    -- The GUI should already be created by InventoryGuiSetup before this is called
    print("[InventoryClient] Looking for InventoryGUI in PlayerGui...")
    print("[InventoryClient] PlayerGui children count:", #self.gui:GetChildren())
    
    for _, child in ipairs(self.gui:GetChildren()) do
        print("[InventoryClient] - Found in PlayerGui:", child.Name, "(Enabled=" .. tostring(child:FindFirstChildOfClass("ScreenGui") and child:FindFirstChildOfClass("ScreenGui").Enabled or "N/A") .. ")")
    end
    
    self.inventoryGui = self.gui:FindFirstChild("InventoryGUI")
    if not self.inventoryGui then
        -- Try waiting a bit in case of timing issues
        warn("[InventoryClient] InventoryGUI not found immediately, waiting...")
        self.inventoryGui = self.gui:WaitForChild("InventoryGUI", 10)
    end
    
    if not self.inventoryGui then
        warn("[InventoryClient] ❌ InventoryGUI not found in PlayerGui after waiting")
        warn("[InventoryClient] PlayerGui children:", self.gui:GetChildren())
        return false
    end
    
    print("[InventoryClient] ✅ Found InventoryGUI in PlayerGui")
    print("[InventoryClient] InventoryGUI.Enabled:", self.inventoryGui.Enabled)

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
    
    print("[InventoryClient] ✅ After attachGui: inventoryGui.Enabled=" .. tostring(self.inventoryGui.Enabled) .. ", inventoryFrame.Visible=" .. tostring(self.inventoryFrame.Visible))

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
