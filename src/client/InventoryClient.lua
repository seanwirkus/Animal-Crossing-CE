local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local InventoryClient = {}
InventoryClient.__index = InventoryClient
InventoryClient.MAX_SLOTS = 10  -- Always show 10 slots (1 row)

-- Create reusable sound for inventory operations
local function createInventorySound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://115624513042963"
	sound.Volume = 0.5
	sound.PlayOnRemove = false
	sound.Parent = SoundService
	return sound
end

local _inventorySound = nil
local function playInventorySound()
	if not _inventorySound then
		_inventorySound = createInventorySound()
	end
	-- Clone sound to allow overlapping
	local soundClone = _inventorySound:Clone()
	soundClone.Parent = SoundService
	soundClone:Play()
	game:GetService("Debris"):AddItem(soundClone, soundClone.TimeLength + 0.1)
end

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
    
    -- Load context menu - optional feature
    self.contextMenu = nil
    local success, contextMenuModule = pcall(function()
        local clientFolder = script.Parent
        local modulesFolder = clientFolder:FindFirstChild("Modules")
        if modulesFolder then
            local contextMenuModule = modulesFolder:FindFirstChild("ContextMenu")
            if contextMenuModule then
                return require(contextMenuModule)
            end
        end
        return nil
    end)
    
    if success and contextMenuModule then
        self.contextMenu = contextMenuModule.new(nil, self.inventoryRemote, self.itemDataFetcher)
        print("[InventoryClient] ✅ Context menu loaded")
    end

    self.inventoryGui = nil
    self.inventoryFrame = nil
    self.inventoryItems = nil
    self.slotTemplate = nil

    self.visible = false
    self.slotsByIndex = {}
    self.maxSlots = 10  -- Start with level 1 (10 slots)
    self.inventoryLevel = 1  -- Track inventory level
    self.slotState = {}
    self.drag = nil
    self.pendingData = nil
    self._isInitialLoad = false  -- Track if this is the first inventory load

    self.connections = {}
    self.inventoryChanged = Instance.new("BindableEvent")

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

function InventoryClient:onInventoryChanged(callback)
    if not self.inventoryChanged then
        return { Disconnect = function() end }
    end

    return self.inventoryChanged.Event:Connect(callback)
end

function InventoryClient:getInventorySnapshot()
    local slots = {}
    for index, state in pairs(self.slotState) do
        slots[index] = cloneState(state)
    end

    return {
        slots = slots,
        maxSlots = self.maxSlots,
        inventoryLevel = self.inventoryLevel,
    }
end

function InventoryClient:_emitInventoryChanged()
    if self.inventoryChanged then
        self.inventoryChanged:Fire(self:getInventorySnapshot())
    end
end

function InventoryClient:getItemDefinition(itemId)
    return self.displayItems[itemId]
end

function InventoryClient:updateItemIcon(icon, itemDefinition)
    if not icon then
        warn("[InventoryClient] updateItemIcon called with nil icon")
        return
    end

    if not itemDefinition then
        icon.Image = ""
        icon.ImageRectOffset = Vector2.new(0, 0)
        icon.ImageRectSize = Vector2.new(0, 0)
        return
    end

    if not itemDefinition.spriteIndex then
        icon.Image = ""
        icon.ImageRectOffset = Vector2.new(0, 0)
        icon.ImageRectSize = Vector2.new(0, 0)
        warn("[InventoryClient] Item", itemDefinition.name or itemDefinition.id, "has no spriteIndex")
        return
    end

    -- Ensure proper ScaleType for sprite rendering
    if icon.ScaleType ~= Enum.ScaleType.Fit then
        icon.ScaleType = Enum.ScaleType.Fit
    end

    -- Apply sprite
    local success = self.spriteConfig.applySprite(icon, itemDefinition.spriteIndex)
    if not success then
        -- If sprite application failed, clear the icon
        icon.Image = ""
        icon.ImageRectOffset = Vector2.new(0, 0)
        icon.ImageRectSize = Vector2.new(0, 0)
        warn("[InventoryClient] Failed to apply sprite for item:", itemDefinition.name or itemDefinition.id, "spriteIndex:", itemDefinition.spriteIndex)
    else
        -- Successfully applied sprite
        print("[InventoryClient] ✅ Applied sprite", itemDefinition.spriteIndex, "for item:", itemDefinition.name or itemDefinition.id)
    end
end

function InventoryClient:updateSlotAppearance(slot, state)
    local icon = slot:FindFirstChild("ItemIcon")
    local countLabel = slot:FindFirstChild("ItemCount")
    local nameLabel = slot:FindFirstChild("ItemName")
    
    -- Ensure ItemIcon exists
    if not icon then
        icon = Instance.new("ImageLabel")
        icon.Name = "ItemIcon"
        icon.Size = UDim2.new(0.8, 0, 0.7, 0)
        icon.Position = UDim2.new(0.1, 0, 0.05, 0)
        icon.AnchorPoint = Vector2.new(0, 0)
        icon.BackgroundTransparency = 1
        icon.Image = ""
        icon.ScaleType = Enum.ScaleType.Fit
        icon.ZIndex = slot.ZIndex + 1
        icon.Visible = true
        icon.Parent = slot
    end
    
    -- Ensure icon is visible
    icon.Visible = true

    if state and state.itemId then
        local definition = self:getItemDefinition(state.itemId)
        if not definition then
            -- Silently handle missing items (they'll just show empty icon)
            -- Don't spam warnings for items like hyacinth_blue that might not be in manifest yet
        end
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
        -- Empty slot - show placeholder
        if icon then
            icon.Image = ""
            icon.ImageRectOffset = Vector2.new(0, 0)
            icon.ImageRectSize = Vector2.new(0, 0)
        end
        
        -- Make empty slot visible with light background
        if slot then
            slot.BackgroundTransparency = 0.3  -- Semi-transparent to show it's empty
            slot.BackgroundColor3 = Color3.fromRGB(240, 240, 240)  -- Light gray
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
    -- Check if slot exists and is valid
    if self.slotsByIndex[slotIndex] and self.slotsByIndex[slotIndex].Parent then
        print("[InventoryClient] 🔄 Slot", slotIndex, "already exists, returning existing slot")
        return self.slotsByIndex[slotIndex]
    end

    print("[InventoryClient] 🆕 Creating NEW slot", slotIndex)
    
    local clone = self.slotTemplate:Clone()
    clone.Name = "Slot_" .. slotIndex
    clone.Visible = true
    clone.LayoutOrder = slotIndex  -- Set LayoutOrder so UIGridLayout positions it correctly
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

    -- Ensure EquipButton exists for hover interaction
    local equipButton = clone:FindFirstChild("EquipButton")
    if not equipButton then
        equipButton = Instance.new("TextButton")
        equipButton.Name = "EquipButton"
        equipButton.Text = "⚒️"  -- Tool emoji for equip
        equipButton.Font = Enum.Font.Gotham
        equipButton.TextSize = 18
        equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        equipButton.BackgroundColor3 = Color3.fromRGB(3, 176, 170)  -- Teal from color scheme
        equipButton.BackgroundTransparency = 0
        equipButton.BorderSizePixel = 0
        equipButton.Size = UDim2.new(0.4, 0, 0.4, 0)  -- 40% size in corner
        equipButton.Position = UDim2.new(0.6, 0, 0, 0)  -- Top-right corner
        equipButton.ZIndex = clone.ZIndex + 2
        equipButton.Visible = false  -- Hidden by default, shown on hover
        equipButton.Parent = clone
    end

    -- Configure interactions for this NEW slot
    self:configureSlotInteractions(clone, slotIndex)
    
    print("[InventoryClient] ✅ Slot", slotIndex, "created with interactions configured")

    return clone
end

function InventoryClient:configureSlotInteractions(slot, slotIndex)
    print("[InventoryClient] ⚙️ Configuring interactions for slot", slotIndex)
    slot:SetAttribute("SlotIndex", slotIndex)

    local clickRegion = slot:FindFirstChild("ClickRegion")
    if not clickRegion then
        print("[InventoryClient] Creating NEW ClickRegion for slot", slotIndex)
        clickRegion = Instance.new("TextButton")
        clickRegion.Name = "ClickRegion"
        clickRegion.Text = ""
        clickRegion.BackgroundTransparency = 1
        clickRegion.AutoButtonColor = false
        clickRegion.Size = UDim2.new(1, 0, 1, 0)
        clickRegion.ZIndex = slot.ZIndex + 1
        clickRegion.Parent = slot
    else
        print("[InventoryClient] ClickRegion already exists for slot", slotIndex)
    end
    
    -- Always update Active/Selectable state based on current slot state
    local hasItem = self.slotState[slotIndex] ~= nil
    clickRegion.Active = true  -- Always active so empty slots can receive drops
    clickRegion.Selectable = hasItem  -- Only selectable if it has an item (prevents cursor)
    
    print("[InventoryClient] 🔍 ClickRegion properties - Active:", clickRegion.Active, "Selectable:", clickRegion.Selectable, "ZIndex:", clickRegion.ZIndex)
    
    -- Disconnect old connections if they exist (stored in tags)
    local oldConnections = clickRegion:GetAttribute("_connectionIds") or {}
    if type(oldConnections) == "table" and #oldConnections > 0 then
        print("[InventoryClient] ♻️ Found", #oldConnections, "old connections, disconnecting...")
        -- Clear the old connections flag
        clickRegion:SetAttribute("_connectionsSetup", nil)
    end
    
    -- Only create connections once per slot (check for attribute to avoid duplicates)
    if clickRegion:GetAttribute("_connectionsSetup") then
        print("[InventoryClient] ⚠️ Connections already setup for slot", slotIndex, "- properties updated, SKIPPING reconnect")
        return
    end
    
    print("[InventoryClient] 🔗 Setting up NEW connections for slot", slotIndex)
    clickRegion:SetAttribute("_connectionsSetup", true)
    
    -- Click-to-pick, click-to-drop system
    local clickConnection = clickRegion.MouseButton1Click:Connect(function()
        print("[InventoryClient] 🖱️ SLOT CLICKED:", slotIndex)
        print("[InventoryClient] Current drag state:", self.drag and "DRAGGING" or "NOT DRAGGING")
        print("[InventoryClient] Slot has item:", self.slotState[slotIndex] and self.slotState[slotIndex].itemId or "NO ITEM")
        
        if not self.drag then
            -- Not dragging: pick up item from this slot
            if self.slotState[slotIndex] then
                print("[InventoryClient] ✅ Starting drag from slot", slotIndex)
                self:beginDrag(slotIndex)
            else
                print("[InventoryClient] ❌ No item in slot", slotIndex, "to drag")
            end
        else
            -- Already dragging: drop item in this slot
            print("[InventoryClient] Already dragging from slot", self.drag.originSlot, "to slot", slotIndex)
            if self.drag.originSlot == slotIndex then
                -- Clicked same slot - cancel drag (put item back)
                print("[InventoryClient] ✅ Canceling drag (same slot)")
                self:finishDrag(nil, true, nil)
            else
                -- Clicked different slot - move item there
                print("[InventoryClient] ✅ Moving item to slot", slotIndex)
                self:finishDrag(nil, false, slotIndex)
            end
        end
    end)
    
    -- Track mouse over slot for hover effects
    local enterConnection = clickRegion.MouseEnter:Connect(function()
        print("[InventoryClient] 🖱️ Mouse ENTERED slot", slotIndex)
        local state = self.slotState[slotIndex]
        local nameLabel = slot:FindFirstChild("ItemName")
        local equipButton = slot:FindFirstChild("EquipButton")
        
        if nameLabel and state and self.displayItems[state.itemId] then
            nameLabel.Text = self.displayItems[state.itemId].name
            nameLabel.Visible = true
        end
        
        -- Show equip button on hover if slot has an item
        if equipButton and state and state.itemId and state.itemId ~= "" then
            equipButton.Visible = true
        end
        
        slot.BackgroundColor3 = Color3.fromHex("#04AFA6")
    end)

    local leaveConnection = clickRegion.MouseLeave:Connect(function()
        print("[InventoryClient] 🖱️ Mouse LEFT slot", slotIndex)
        local nameLabel = slot:FindFirstChild("ItemName")
        local equipButton = slot:FindFirstChild("EquipButton")
        
        if nameLabel then
            nameLabel.Visible = false
        end
        
        if equipButton then
            equipButton.Visible = false
        end
        
        slot.BackgroundColor3 = Color3.fromRGB(238, 226, 204)
    end)
    
    -- Track all connections for cleanup
    self:trackConnection(clickConnection)
    self:trackConnection(enterConnection)
    self:trackConnection(leaveConnection)
    
    -- Add equip button click handler
    local equipButton = slot:FindFirstChild("EquipButton")
    if equipButton then
        local equipButtonConnection = equipButton.MouseButton1Click:Connect(function()
            print("[InventoryClient] ⚒️ EQUIP BUTTON CLICKED for slot", slotIndex)
            local state = self.slotState[slotIndex]
            if state and state.itemId then
                print("[InventoryClient] ✅ Equipping item:", state.itemId)
                if self.contextMenu then
                    -- Pass an item object with id property
                    self.contextMenu:equipItem({id = state.itemId})
                end
            end
        end)
        self:trackConnection(equipButtonConnection)
    end
    
    print("[InventoryClient] ✅ Connections setup complete for slot", slotIndex, "- Total connections:", #self.connections)
end

-- Add global right-click handler instead of per-slot handlers
function InventoryClient:setupGlobalRightClick()
    local UserInputService = game:GetService("UserInputService")
    
    local globalRightClickConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            -- Check if inventory is visible
            if not self.visible or not self.inventoryFrame or not self.inventoryFrame.Visible then
                return
            end
            
            -- Get mouse position and find which slot it's over
            local mouse = Players.LocalPlayer:GetMouse()
            local mousePos = Vector2.new(mouse.X, mouse.Y)
            
            -- Find slot under mouse
            local targetSlot = nil
            local targetSlotIndex = nil
            
            for slotIndex, slot in pairs(self.slotsByIndex) do
                if slot and slot.Visible and slot.AbsoluteSize.X > 0 and slot.AbsoluteSize.Y > 0 then
                    local slotPos = slot.AbsolutePosition
                    local slotSize = slot.AbsoluteSize
                    
                    if mousePos.X >= slotPos.X and mousePos.X <= slotPos.X + slotSize.X and
                       mousePos.Y >= slotPos.Y and mousePos.Y <= slotPos.Y + slotSize.Y then
                        targetSlot = slot
                        targetSlotIndex = slotIndex
                        break
                    end
                end
            end
            
            if not targetSlot or not targetSlotIndex then
                return
            end
            
            print("[InventoryClient] 🔴 RIGHT-CLICK DETECTED on slot", targetSlotIndex)
            local state = self.slotState[targetSlotIndex]
            
            -- Defensive check: slot must have a valid itemId
            if not state or not state.itemId or state.itemId == "" or state.itemId == false then
                print("[InventoryClient] No valid item in this slot; skipping context menu.")
                return
            end
            
            -- Confirm not a dummy or empty template slot
            if tostring(state.itemId):lower():match("empty") or tostring(state.itemId):lower():match("template") then
                print("[InventoryClient] Slot is a template or empty placeholder; skipping context menu.")
                return
            end
            
            print("[InventoryClient] ✅ Valid item found:", state.itemId)
            
            -- Show context menu if available
            if self.contextMenu then
                print("[InventoryClient] ✅ Context menu exists, showing...")
                pcall(function()
                    print("[InventoryClient] Mouse position:", mouse.X, mouse.Y)
                    
                    -- Create item data object for context menu
                    local itemData = {
                        id = state.itemId,
                        itemId = state.itemId,
                        count = state.count or 1,
                        name = nil
                    }
                    -- Try to get item name from definition
                    local definition = self:getItemDefinition(state.itemId)
                    if definition then
                        itemData.name = definition.name
                        itemData.category = definition.category
                    end
                    print("[InventoryClient] Calling contextMenu:show() with:", itemData.id, itemData.name)
                    self.contextMenu:show(itemData, mousePos)
                    print("[InventoryClient] ✅ Context menu show() call completed")
                end)
            else
                warn("[InventoryClient] ❌ NO CONTEXT MENU AVAILABLE!")
            end
        end
    end)
    
    self:trackConnection(globalRightClickConnection)
end

function InventoryClient:refreshSlot(slotIndex)
    local slot = self:ensureSlot(slotIndex)
    if not slot then
        warn("[InventoryClient] ❌ Failed to create slot", slotIndex)
        return
    end

    -- Always ensure LayoutOrder matches slotIndex to maintain position
    slot.LayoutOrder = slotIndex
    
    -- Show slots up to maxSlots OR minimum 10 slots (whichever is higher)
    local MINIMUM_SLOTS = 10
    local slotsToShow = math.max(self.maxSlots or 10, MINIMUM_SLOTS)
    slot.Visible = slotIndex <= slotsToShow
    
    -- Update Selectable state for empty slots (prevents cursor but allows drops)
    local hasItem = self.slotState[slotIndex] ~= nil
    local clickRegion = slot:FindFirstChild("ClickRegion")
    if clickRegion then
        clickRegion.Active = true  -- Always active so empty slots can receive drops
        clickRegion.Selectable = hasItem  -- Only selectable if it has an item (prevents cursor)
    end
    
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
    
    -- Make ghost slightly transparent and larger for better visibility
    ghost.BackgroundTransparency = 0.3

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

    -- Slightly larger ghost for better visibility when dragging
    local scaleFactor = 1.1
    ghost.Size = UDim2.fromOffset(math.floor(width * scaleFactor), math.floor(height * scaleFactor))

    -- Remove all interactive elements from ghost
    for _, child in ipairs(ghost:GetChildren()) do
        if child:IsA("GuiButton") or child:IsA("TextButton") or child:IsA("ImageButton") then
            child:Destroy()
        end
    end

    ghost.Parent = self.inventoryGui
    self:updateSlotAppearance(ghost, state)
    
    -- Position immediately at cursor
    self:updateGhostPosition()

    return ghost
end

function InventoryClient:updateGhostPosition()
    if not self.drag or not self.drag.ghost or not self.drag.ghost.Parent then
        return
    end

    local position = UserInputService:GetMouseLocation()
    local ghostSize = self.drag.ghost.AbsoluteSize
    -- Offset ghost upward so it's under the cursor (not centered)
    local yOffset = ghostSize.Y > 0 and (ghostSize.Y * 0.5 + 10) or 30
    self.drag.ghost.Position = UDim2.fromOffset(position.X, position.Y - yOffset)
end

function InventoryClient:beginDrag(slotIndex)
    print("[InventoryClient] 🚀 BEGIN DRAG called for slot", slotIndex)
    
    if self.drag then
        print("[InventoryClient] ⚠️ Already dragging, canceling previous drag")
        self:finishDrag(nil, true) -- Cancel previous drag
    end

    local state = self.slotState[slotIndex]
    if not state then 
        warn("[InventoryClient] ❌ No state found for slot", slotIndex)
        return 
    end
    
    print("[InventoryClient] ✅ Dragging item:", state.itemId, "x" .. state.count)

    self.slotState[slotIndex] = nil
    self:refreshSlot(slotIndex)
    self:_emitInventoryChanged()

    local ghost = self:createGhost(state)
    
    -- Activate screen clicker for world drops
    if self.screenClicker then
        print("[InventoryClient] 🎯 Enabling screenClicker for world drops")
        self.screenClicker.Active = true
        self.screenClicker.Visible = true
        self.screenClicker.ZIndex = -1  -- Still behind slots, just catches outside clicks
    end

    self.drag = {
        originSlot = slotIndex,
        state = cloneState(state),
        ghost = ghost,
        connection = RunService.RenderStepped:Connect(function()
            self:updateGhostPosition()
        end),
    }

    self:updateGhostPosition()
    print("[InventoryClient] ✅ Drag initialized successfully")
end

function InventoryClient:getSlotIndexFromPoint(point)
    -- Check if point is within inventory frame first
    if self.inventoryFrame and self.inventoryFrame.Visible then
        local framePos = self.inventoryFrame.AbsolutePosition
        local frameSize = self.inventoryFrame.AbsoluteSize
        if point.X < framePos.X or point.X > framePos.X + frameSize.X or
           point.Y < framePos.Y or point.Y > framePos.Y + frameSize.Y then
            -- Point is outside inventory frame
            return nil
        end
    end
    
    -- Check if point is within any slot
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
    
    -- Deactivate screen clicker
    if self.screenClicker then
        print("[InventoryClient] 🔒 Disabling screenClicker after drag")
        self.screenClicker.Active = false
        self.screenClicker.Visible = false
        self.screenClicker.ZIndex = -1
    end
    
    self.drag = nil

    if cancelled then
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        self:_emitInventoryChanged()
        return
    end

    local destinationIndex = targetIndex or self:getSlotIndexFromPoint(mousePos or UserInputService:GetMouseLocation())

    if not destinationIndex then
        -- Dropped outside of inventory, put it back for now.
        -- World drop can be re-implemented here if desired.
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        self:_emitInventoryChanged()
        -- Fire drop event
        self:dropItemToWorld(dragState, mousePos)
        return
    end

    if destinationIndex == dragState.originSlot then
        self.slotState[dragState.originSlot] = cloneState(dragState.state)
        self:refreshSlot(dragState.originSlot)
        self:_emitInventoryChanged()
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
    self:_emitInventoryChanged()

    -- Play inventory sound on successful move
    playInventorySound()

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

    -- Don't cancel drag during sync - just update the state
    -- The drag will complete naturally when user releases mouse
    local wasDragging = self.drag ~= nil

    local maxSlots = (payload and payload.maxSlots) or self.maxSlots or 10
    local inventoryLevel = (payload and payload.inventoryLevel) or 1
    local incomingSlots = (payload and payload.slots) or {}

    self.maxSlots = maxSlots
    self.inventoryLevel = inventoryLevel

    -- Create a fresh state table
    local newState = {}
    local itemCountChanged = false
    
    -- Track which slots actually changed to minimize refreshes
    local slotsToRefresh = {}
    
    for i = 1, self.maxSlots do
        local slotData = incomingSlots[tostring(i)] or incomingSlots[i]
        -- Fix: Check for itemId being empty string (server sends "" for empty slots)
        if slotData and slotData.itemId and slotData.itemId ~= "" and slotData.count and slotData.count > 0 then
            newState[i] = {
                itemId = slotData.itemId,
                count = slotData.count,
            }
            print(string.format("[POPULATE DEBUG] Slot %d: %s x%d", i, slotData.itemId, slotData.count))
            
            -- Check if item changed in this slot
            local oldSlot = self.slotState[i]
            if not oldSlot or oldSlot.itemId ~= slotData.itemId or oldSlot.count ~= slotData.count then
                itemCountChanged = true
                slotsToRefresh[i] = true
            end
        else
            -- Slot is empty - check if it had an item before
            if self.slotState[i] then
                itemCountChanged = true
                slotsToRefresh[i] = true
            end
        end
    end
    
    self.slotState = newState

    -- ALWAYS ensure we have 10 slots visible (even if empty!)
    local MINIMUM_SLOTS = 10
    local slotsToShow = math.max(self.maxSlots, MINIMUM_SLOTS)
    
    -- Refresh ALL slots to ensure proper state (drag-and-drop needs this)
    for i = 1, slotsToShow do
        self:refreshSlot(i)
    end
    
    -- Make sure all slots up to MINIMUM_SLOTS are visible
    for i = 1, slotsToShow do
        local slot = self.slotsByIndex[i]
        if slot then
            slot.Visible = true  -- Always show first 10 slots
        end
    end

    self:_emitInventoryChanged()
    
    -- Mark that initial load is done after first population (before sound check)
    local wasInitialLoad = not self._isInitialLoad
    if wasInitialLoad then
        self._isInitialLoad = true
    end
    
    -- Play sound when items change (not during initial load or drag)
    print("[SOUND DEBUG] itemCountChanged:", itemCountChanged, "wasDragging:", wasDragging, "_isInitialLoad:", self._isInitialLoad)
    if itemCountChanged and not wasDragging and not wasInitialLoad then
        print("[SOUND DEBUG] ✅ Playing inventory sound!")
        playInventorySound()
    else
        print("[SOUND DEBUG] ❌ Not playing sound - itemCountChanged:", itemCountChanged, "wasDragging:", wasDragging, "wasInitialLoad:", wasInitialLoad)
    end
    
    print("[POPULATE DEBUG] ✅ Population complete. Level", inventoryLevel, "with", maxSlots, "slots refreshed.", wasDragging and "(drag in progress)" or "")
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

    -- Handle clicks outside inventory (world drop)
    -- Create a screen-wide click detector that's only active when dragging
    -- This catches clicks that don't hit slots (slots are children so they handle clicks first)
    if self.inventoryGui then
        local screenClicker = Instance.new("TextButton")
        screenClicker.Name = "ScreenClicker"
        screenClicker.Size = UDim2.new(1, 0, 1, 0)
        screenClicker.Position = UDim2.new(0, 0, 0, 0)
        screenClicker.BackgroundTransparency = 1
        screenClicker.Text = ""
        screenClicker.ZIndex = -1  -- BELOW everything so it doesn't block clicks
        screenClicker.Active = false  -- Only active when dragging
        screenClicker.Visible = false  -- Hidden when not dragging
        screenClicker.Parent = self.inventoryGui
        self.screenClicker = screenClicker
        
        print("[InventoryClient] ✅ ScreenClicker created - ZIndex:", screenClicker.ZIndex, "Active:", screenClicker.Active, "Visible:", screenClicker.Visible)
        
        screenClicker.MouseButton1Click:Connect(function()
            if self.drag then
                -- Check if click is outside inventory frame
                local mousePos = UserInputService:GetMouseLocation()
                local targetSlot = self:getSlotIndexFromPoint(mousePos)
                
                -- Only drop if not clicking on a slot and not clicking on inventory frame
                if not targetSlot then
                    -- Double-check: if inventory frame exists and is visible, make sure we're outside it
                    if self.inventoryFrame and self.inventoryFrame.Visible then
                        local framePos = self.inventoryFrame.AbsolutePosition
                        local frameSize = self.inventoryFrame.AbsoluteSize
                        if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
                           mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
                            -- Clicked outside inventory frame - drop to world
                            self:finishDrag(mousePos, false, nil)
                        end
                    else
                        -- No inventory frame or not visible - drop to world
                        self:finishDrag(mousePos, false, nil)
                    end
                end
            end
        end)
    end
end

function InventoryClient:bindInput()
    -- This is now handled by setupRemoteHandling to avoid duplicate listeners
end

function InventoryClient:attachGui()
    -- Prefer existing GUI authored in Studio: find any Frame named "InventoryFrame" under PlayerGui
    local function findDescendantByName(root, name)
        for _, d in ipairs(root:GetDescendants()) do
            if d.Name == name then
                return d
            end
        end
        return nil
    end

    local frame = findDescendantByName(self.gui, "InventoryFrame")
    if not frame or not frame:IsA("Frame") then
        -- GUI might not be loaded yet, try again later
        warn("[InventoryClient] ⚠️ Could not find InventoryFrame under PlayerGui (GUI may load later)")
        return false
    end

    self.inventoryFrame = frame
    self.inventoryGui = frame:FindFirstAncestorWhichIsA("ScreenGui")
    if not self.inventoryGui then
        warn("[InventoryClient] ❌ InventoryFrame has no ScreenGui ancestor")
        return false
    end

    -- Find required children inside the frame
    self.inventoryItems = frame:FindFirstChild("InventoryItems")
    self.slotTemplate = self.inventoryItems and self.inventoryItems:FindFirstChild("ItemSlotTemplate") or nil

    -- Deep fallback: locate ItemSlotTemplate anywhere under PlayerGui
    if not self.slotTemplate then
        for _, d in ipairs(self.gui:GetDescendants()) do
            if d:IsA("GuiObject") and d.Name == "ItemSlotTemplate" then
                self.slotTemplate = d
                self.inventoryItems = d.Parent
                -- If we don't have the frame yet, infer from ancestors
                if not self.inventoryFrame then
                    local ancestorFrame = d:FindFirstAncestorWhichIsA("Frame")
                    if ancestorFrame then
                        self.inventoryFrame = ancestorFrame
                    end
                end
                break
            end
        end
    end

    if not self.inventoryItems or not self.slotTemplate then
        warn("[InventoryClient] ⚠️ Could not locate InventoryItems and ItemSlotTemplate (GUI may load later)")
        return false
    end

    self.slotTemplate.Visible = false
    self.inventoryGui.Enabled = true
    self.inventoryFrame.Visible = false
    
    -- Attach context menu to inventory GUI
    if self.contextMenu then
        self.contextMenu:setScreenGui(self.inventoryGui)
    end
    
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
    -- Try to attach GUI, but don't fail if it's not ready yet
    local attached = self:attachGui()
    if not attached then
        print("[InventoryClient] ⚠️ GUI not ready yet, will retry when E key is pressed")
    end

    self:bindInput()
    self:setupRemoteHandling()

    if self.pendingData then
        self:populateFromServer(self.pendingData)
        self.pendingData = nil
    end

    -- Request inventory even if GUI isn't attached yet
    self:requestInventory()
    
    -- Initialize global right-click handler
    self:setupGlobalRightClick()
    
    -- Set up a retry mechanism to attach GUI when it becomes available
    task.spawn(function()
        local maxRetries = 10
        local retryCount = 0
        while not self.inventoryFrame and retryCount < maxRetries do
            task.wait(1)
            retryCount = retryCount + 1
            if self:attachGui() then
                print("[InventoryClient] ✅ GUI attached after retry", retryCount)
                -- Process any pending data
                if self.pendingData then
                    self:populateFromServer(self.pendingData)
                    self.pendingData = nil
                end
                break
            end
        end
        if not self.inventoryFrame then
            warn("[InventoryClient] ⚠️ GUI still not found after", maxRetries, "retries")
        end
    end)
end

function InventoryClient.init()
    local controller = InventoryClient.new()
    controller:start()
    return controller
end

return InventoryClient
