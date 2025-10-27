local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local InventoryClient = {}
InventoryClient.__index = InventoryClient

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
    self.slotState = {}
    self.maxSlots = 0
    self.drag = nil
    self.pendingData = nil

    self.connections = {}

    return self
end

function InventoryClient:disconnectAll()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
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
            self:beginDrag(slotIndex)
        end
    end)

    clickRegion.MouseEnter:Connect(function()
        local nameLabel = slot:FindFirstChild("ItemName")
        if nameLabel and nameLabel.Text ~= "" then
            nameLabel.Visible = true
        end
    end)

    clickRegion.MouseLeave:Connect(function()
        local nameLabel = slot:FindFirstChild("ItemName")
        if nameLabel then
            nameLabel.Visible = false
        end
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

    if not self.inventoryFrame then
        return
    end

    if shouldShow and self.inventoryGui then
        self.inventoryGui.Enabled = true
    end

    self.inventoryFrame.Visible = shouldShow

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
    ghost.Size = self.slotTemplate.Size

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
    if self.drag then
        self:finishDrag(nil, true)
    end

    local state = self.slotState[slotIndex]
    if not state then
        return
    end

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
    for index, slot in pairs(self.slotsByIndex) do
        if slot and slot.Visible then
            local pos = slot.AbsolutePosition
            local size = slot.AbsoluteSize
            if point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y then
                return index
            end
        end
    end
    return nil
end

function InventoryClient:dropItemToWorld(dragState, mousePosition)
    self.slotState[dragState.originSlot] = nil
    self:refreshSlot(dragState.originSlot)

    local camera = workspace.CurrentCamera
    local screenPos = mousePosition or UserInputService:GetMouseLocation()
    local unitRay = camera:ViewportPointToRay(screenPos.X, screenPos.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { camera }

    local character = self.player.Character
    if character then
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("BasePart") then
                table.insert(params.FilterDescendantsInstances, descendant)
            end
        end
    end

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 512, params)
    local worldPosition

    if result then
        worldPosition = result.Position + Vector3.new(0, 0.5, 0)
    else
        local cameraRay = workspace:Raycast(camera.CFrame.Position, Vector3.new(0, -512, 0), params)
        if cameraRay then
            worldPosition = cameraRay.Position + Vector3.new(0, 0.5, 0)
        else
            worldPosition = camera.CFrame.Position + camera.CFrame.LookVector * 12
        end
    end

    self.inventoryRemote:FireServer("DropItem", {
        itemId = dragState.state.itemId,
        count = dragState.state.count,
        slotIndex = dragState.originSlot,
        screenPosition = Vector2.new(screenPos.X, screenPos.Y),
        worldPosition = worldPosition,
    })
end

function InventoryClient:finishDrag(mousePos, cancelled, targetIndex)
    local dragState = self.drag
    if not dragState then
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
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        return
    end

    local mousePosition = mousePos or UserInputService:GetMouseLocation()
    local destinationIndex = targetIndex or self:getSlotIndexFromPoint(mousePosition)

    if destinationIndex == dragState.originSlot then
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        return
    end

    if destinationIndex and destinationIndex ~= dragState.originSlot then
        local existing = self.slotState[destinationIndex]
        self.slotState[destinationIndex] = cloneState(dragState.state)
        if existing then
            self.slotState[dragState.originSlot] = cloneState(existing)
        else
            self.slotState[dragState.originSlot] = nil
        end

        self:refreshSlot(destinationIndex)
        self:refreshSlot(dragState.originSlot)

        self.inventoryRemote:FireServer("MoveItem", {
            fromIndex = dragState.originSlot,
            toIndex = destinationIndex,
            swap = existing ~= nil,
        })
        return
    end

    -- Dropped outside any slot
    self:dropItemToWorld(dragState, mousePosition)
end

function InventoryClient:populateFromServer(payload)
    if not self.inventoryItems or not self.slotTemplate then
        self.pendingData = payload
        return
    end

    if self.drag then
        self:finishDrag(nil, true)
    end

    local maxSlots = 20
    local incomingSlots = {}

    if typeof(payload) == "table" then
        if payload.maxSlots then
            maxSlots = payload.maxSlots
        end

        if payload.slots then
            for index, slot in pairs(payload.slots) do
                incomingSlots[index] = slot
            end
        else
            for index, slot in ipairs(payload) do
                incomingSlots[index] = slot
            end
        end
    end

    self.maxSlots = maxSlots

    for index = 1, self.maxSlots do
        local slotData = incomingSlots[index]
        if slotData and slotData.itemId and slotData.count and slotData.count > 0 then
            self.slotState[index] = {
                itemId = slotData.itemId,
                count = slotData.count,
            }
        else
            self.slotState[index] = nil
        end
        self:refreshSlot(index)
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
    self:trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == Enum.KeyCode.E then
            self:setInventoryVisible(not self.visible)
            if self.visible then
                self:requestInventory()
            end
        end
    end))

    self:trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and self.drag then
            self:finishDrag(UserInputService:GetMouseLocation())
        end
    end))
end

function InventoryClient:attachGui()
    self.inventoryGui = self.gui:FindFirstChild("InventoryGUI")
    if not self.inventoryGui then
        warn("[InventoryClient] InventoryGUI not found in PlayerGui")
        return false
    end

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
