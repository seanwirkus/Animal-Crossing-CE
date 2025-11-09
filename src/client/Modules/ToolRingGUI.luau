--[[
    ToolRingGUI.luau

    Re-implementation of the Animal Crossing inspired tool ring.
    Shows up to 8 tools in a circular menu, highlights the equipped tool,
    and mirrors the cozy ACNH colour palette.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SLOT_COUNT = 8

local RING_RADIUS = 140
local TOOL_SLOT_SIZE = 75
local CENTER_SIZE = 100
local GLOW_SIZE = 130

local COLORS = {
    ITEM_GRABBED = Color3.fromRGB(255, 234, 160), -- Bright yellow highlight
    ITEM_SELECTED = Color3.fromRGB(3, 176, 170), -- Teal accent
    BG_PRIMARY = Color3.fromRGB(255, 251, 231),
    BG_SECONDARY = Color3.fromRGB(255, 255, 255),
    BORDER_DARK = Color3.fromRGB(100, 80, 60),
    SLOT_NORMAL = Color3.fromRGB(240, 235, 220),
    SLOT_HOVER = Color3.fromRGB(222, 216, 200),
    SLOT_EQUIPPED = Color3.fromRGB(253, 211, 120),
    TEXT_DARK = Color3.fromRGB(60, 50, 40),
    TEXT_LIGHT = Color3.fromRGB(255, 255, 255),
}

local TOOL_KEYWORDS = {
    "fishing", "rod", "axe", "net", "shovel", "watering", "can", "slingshot",
    "ladder", "flimsy", "stone", "iron", "golden", "tool", "tools",
}

local ACCEPTED_CATEGORIES = {
    Tools = true,
    Equipment = true,
    "Vaulting Pole" = true,
}

local ToolRingGUI = {}
ToolRingGUI.__index = ToolRingGUI

-- Utility -------------------------------------------------------------------

local function isToolKeywordMatch(itemId: string, itemName: string?): boolean
    local lowerId = string.lower(itemId)
    local lowerName = string.lower(itemName or "")

    for _, keyword in ipairs(TOOL_KEYWORDS) do
        if string.find(lowerId, keyword, 1, true) or string.find(lowerName, keyword, 1, true) then
            return true
        end
    end

    return false
end

local function cloneToolEntry(entry)
    local copy = {}
    for key, value in pairs(entry) do
        copy[key] = value
    end
    return copy
end

-- Class ---------------------------------------------------------------------

function ToolRingGUI.new()
    local self = setmetatable({}, ToolRingGUI)

    self.player = Players.LocalPlayer
    self.gui = nil
    self.backgroundFrame = nil
    self.ringContainer = nil
    self.centerLabel = nil
    self.descriptionLabel = nil
    self.instructionLabel = nil
    self.toolSlots = table.create(SLOT_COUNT)
    self.selectedSlot = 1
    self.equippedItemSlot = nil
    self.visible = false

    self.inventoryClient = nil
    self.inventoryConnections = {}
    self.inventorySignalConn = nil

    local shared = ReplicatedStorage:WaitForChild("Shared")
    self.spriteConfig = require(shared:WaitForChild("SpriteConfig"))
    self.itemDataFetcher = require(shared:WaitForChild("ItemDataFetcher"))
    self.displayItemMap = self.itemDataFetcher.getDisplayItemMap()

    self.tools = {}
    for i = 1, SLOT_COUNT do
        self.tools[i] = {
            isEmpty = true,
            name = "Empty",
            description = "",
            count = 0,
        }
    end

    self:buildGui()

    return self
end

-- Internal helpers ----------------------------------------------------------

function ToolRingGUI:destroyInventoryConnections()
    for _, connection in ipairs(self.inventoryConnections) do
        connection:Disconnect()
    end
    table.clear(self.inventoryConnections)

    if self.inventorySignalConn then
        self.inventorySignalConn:Disconnect()
        self.inventorySignalConn = nil
    end
end

function ToolRingGUI:resolveItemDefinition(itemId: string?)
    if not itemId then
        return nil
    end

    local definition = self.displayItemMap[itemId]
    if not definition and self.inventoryClient and self.inventoryClient.getItemDefinition then
        definition = self.inventoryClient:getItemDefinition(itemId)
    end

    if not definition then
        definition = self.itemDataFetcher.getItem and self.itemDataFetcher.getItem(itemId) or nil
    end

    return definition
end

function ToolRingGUI:isTool(itemId: string, itemName: string?, definition: any?)
    if definition and definition.category and ACCEPTED_CATEGORIES[definition.category] then
        return true
    end

    return isToolKeywordMatch(itemId, itemName or (definition and definition.name))
end

function ToolRingGUI:getToolDescription(definition, count)
    if not definition then
        return count and count > 1 and ("x" .. tostring(count)) or ""
    end

    local segments = {}
    if definition.name then
        table.insert(segments, definition.name)
    end

    if definition.category and definition.category ~= "" then
        table.insert(segments, definition.category)
    end

    if definition.source and typeof(definition.source) == "table" and #definition.source > 0 then
        table.insert(segments, definition.source[1])
    end

    return table.concat(segments, " • ")
end

function ToolRingGUI:applySprite(imageObject, spriteIndex)
    if not imageObject then
        return
    end

    imageObject.Visible = spriteIndex ~= nil
    if not spriteIndex then
        imageObject.Image = ""
        return
    end

    local success = self.spriteConfig.applySprite(imageObject, spriteIndex)
    if not success then
        imageObject.Image = ""
    end
end

function ToolRingGUI:updateSelectionHighlight()
    for index, slot in ipairs(self.toolSlots) do
        if slot and slot.frame then
            local tool = self.tools[index]

            local isSelected = index == self.selectedSlot
            local isEquipped = tool.slotIndex and tool.slotIndex == self.equippedItemSlot

            local backgroundColor = COLORS.SLOT_NORMAL
            if isSelected then
                backgroundColor = COLORS.ITEM_GRABBED
            elseif isEquipped then
                backgroundColor = COLORS.SLOT_EQUIPPED
            end

            slot.frame.BackgroundColor3 = backgroundColor

            if slot.selectionTween then
                slot.selectionTween:Cancel()
                slot.selectionTween = nil
            end

            local targetSize = TOOL_SLOT_SIZE
            if isSelected then
                targetSize = TOOL_SLOT_SIZE + 8
            end

            slot.selectionTween = TweenService:Create(
                slot.frame,
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = UDim2.fromOffset(targetSize, targetSize) }
            )
            slot.selectionTween:Play()
        end
    end
end

-- GUI creation --------------------------------------------------------------

function ToolRingGUI:buildGui()
    local playerGui = self.player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "ToolRingGUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 50
    gui.Enabled = false
    gui.Parent = playerGui
    self.gui = gui

    local boardSize = (RING_RADIUS + TOOL_SLOT_SIZE) * 2 + 120

    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromOffset(boardSize, boardSize)
    backdrop.Position = UDim2.new(0.5, -boardSize / 2, 0.5, -boardSize / 2)
    backdrop.BackgroundColor3 = COLORS.BG_PRIMARY
    backdrop.BackgroundTransparency = 0.05
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = gui
    self.backgroundFrame = backdrop

    local backdropCorner = Instance.new("UICorner")
    backdropCorner.CornerRadius = UDim.new(0, 32)
    backdropCorner.Parent = backdrop

    local backdropStroke = Instance.new("UIStroke")
    backdropStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    backdropStroke.Thickness = 3
    backdropStroke.Color = COLORS.BORDER_DARK
    backdropStroke.Parent = backdrop

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "DropShadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.Size = UDim2.fromScale(1, 1)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageTransparency = 0.5
    shadow.ZIndex = 0
    shadow.Parent = backdrop

    local ringContainer = Instance.new("Frame")
    ringContainer.Name = "RingContainer"
    local diameter = (RING_RADIUS + TOOL_SLOT_SIZE)
    ringContainer.Size = UDim2.fromOffset(diameter * 2, diameter * 2)
    ringContainer.Position = UDim2.new(0.5, -diameter, 0.5, -diameter - 20)
    ringContainer.BackgroundTransparency = 1
    ringContainer.ZIndex = 3
    ringContainer.Parent = backdrop
    self.ringContainer = ringContainer

    local glow = Instance.new("Frame")
    glow.Name = "CenterGlow"
    glow.Size = UDim2.fromOffset(GLOW_SIZE, GLOW_SIZE)
    glow.Position = UDim2.new(0.5, -GLOW_SIZE / 2, 0.5, -GLOW_SIZE / 2)
    glow.BackgroundColor3 = COLORS.ITEM_SELECTED
    glow.BackgroundTransparency = 0.85
    glow.BorderSizePixel = 0
    glow.ZIndex = 2
    glow.Parent = ringContainer

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = glow

    local centerLabel = Instance.new("TextLabel")
    centerLabel.Name = "CenterLabel"
    centerLabel.Size = UDim2.fromOffset(CENTER_SIZE, CENTER_SIZE)
    centerLabel.Position = UDim2.new(0.5, -CENTER_SIZE / 2, 0.5, -CENTER_SIZE / 2)
    centerLabel.BackgroundColor3 = COLORS.BG_SECONDARY
    centerLabel.BorderSizePixel = 0
    centerLabel.Font = Enum.Font.GothamBold
    centerLabel.TextColor3 = COLORS.ITEM_SELECTED
    centerLabel.TextScaled = true
    centerLabel.Text = ""
    centerLabel.ZIndex = 4
    centerLabel.Parent = ringContainer
    self.centerLabel = centerLabel

    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(1, 0)
    centerCorner.Parent = centerLabel

    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Name = "DescriptionLabel"
    descriptionLabel.Size = UDim2.fromOffset(boardSize - 80, 44)
    descriptionLabel.Position = UDim2.new(0.5, -(boardSize - 80) / 2, 1, -60)
    descriptionLabel.BackgroundColor3 = COLORS.BG_SECONDARY
    descriptionLabel.BorderSizePixel = 0
    descriptionLabel.Font = Enum.Font.GothamBold
    descriptionLabel.TextColor3 = COLORS.TEXT_DARK
    descriptionLabel.TextSize = 20
    descriptionLabel.TextWrapped = true
    descriptionLabel.Text = "Select a tool"
    descriptionLabel.ZIndex = 3
    descriptionLabel.Parent = backdrop
    self.descriptionLabel = descriptionLabel

    local descriptionCorner = Instance.new("UICorner")
    descriptionCorner.CornerRadius = UDim.new(0, 16)
    descriptionCorner.Parent = descriptionLabel

    local instructionLabel = Instance.new("TextLabel")
    instructionLabel.Name = "InstructionLabel"
    instructionLabel.Size = UDim2.fromOffset(boardSize - 60, 32)
    instructionLabel.Position = UDim2.new(0.5, -(boardSize - 60) / 2, 0, 24)
    instructionLabel.BackgroundColor3 = COLORS.BG_SECONDARY
    instructionLabel.BorderSizePixel = 0
    instructionLabel.Font = Enum.Font.GothamBold
    instructionLabel.TextColor3 = COLORS.BORDER_DARK
    instructionLabel.TextSize = 18
    instructionLabel.Text = "⚒️ TOOL RING — Click a tool to equip"
    instructionLabel.ZIndex = 3
    instructionLabel.Parent = backdrop
    self.instructionLabel = instructionLabel

    local instructionCorner = Instance.new("UICorner")
    instructionCorner.CornerRadius = UDim.new(0, 14)
    instructionCorner.Parent = instructionLabel

    self:createSlots()
end

function ToolRingGUI:createSlots()
    for index = 1, SLOT_COUNT do
        local angle = (index - 1) * (math.pi * 2 / SLOT_COUNT) - math.pi / 2
        local offsetX = math.cos(angle) * RING_RADIUS
        local offsetY = math.sin(angle) * RING_RADIUS

        local slotFrame = Instance.new("Frame")
        slotFrame.Name = "ToolSlot" .. index
        slotFrame.Size = UDim2.fromOffset(TOOL_SLOT_SIZE, TOOL_SLOT_SIZE)
        slotFrame.Position = UDim2.new(0.5, offsetX - TOOL_SLOT_SIZE / 2, 0.5, offsetY - TOOL_SLOT_SIZE / 2)
        slotFrame.BackgroundColor3 = COLORS.SLOT_NORMAL
        slotFrame.BorderColor3 = COLORS.BORDER_DARK
        slotFrame.BorderSizePixel = 3
        slotFrame.ZIndex = 4
        slotFrame.Parent = self.ringContainer

        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(1, 0)
        slotCorner.Parent = slotFrame

        local button = Instance.new("TextButton")
        button.Name = "Interactive"
        button.Text = ""
        button.Size = UDim2.fromScale(1, 1)
        button.BackgroundTransparency = 1
        button.ZIndex = 5
        button.Parent = slotFrame

        local icon = Instance.new("ImageLabel")
        icon.Name = "ItemIcon"
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, TOOL_SLOT_SIZE - 18, 0, TOOL_SLOT_SIZE - 24)
        icon.Position = UDim2.new(0.5, 0, 0.5, -6)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.ZIndex = 6
        icon.Parent = slotFrame

        local countBadge = Instance.new("Frame")
        countBadge.Name = "CountBadge"
        countBadge.Size = UDim2.fromOffset(28, 24)
        countBadge.Position = UDim2.new(1, -24, 1, -26)
        countBadge.BackgroundColor3 = COLORS.ITEM_SELECTED
        countBadge.BorderSizePixel = 0
        countBadge.Visible = false
        countBadge.ZIndex = 7
        countBadge.Parent = slotFrame

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(1, 0)
        badgeCorner.Parent = countBadge

        local countLabel = Instance.new("TextLabel")
        countLabel.Name = "CountLabel"
        countLabel.Size = UDim2.fromScale(1, 1)
        countLabel.BackgroundTransparency = 1
        countLabel.Font = Enum.Font.GothamBold
        countLabel.TextColor3 = COLORS.TEXT_LIGHT
        countLabel.TextScaled = true
        countLabel.Text = "1"
        countLabel.ZIndex = 8
        countLabel.Parent = countBadge

        local nameTag = Instance.new("TextLabel")
        nameTag.Name = "NameTag"
        nameTag.Size = UDim2.new(1, 12, 0, 22)
        nameTag.Position = UDim2.new(0, -6, 1, 6)
        nameTag.BackgroundColor3 = COLORS.BG_PRIMARY
        nameTag.BorderSizePixel = 0
        nameTag.Font = Enum.Font.Gotham
        nameTag.TextColor3 = COLORS.TEXT_DARK
        nameTag.TextSize = 12
        nameTag.TextWrapped = true
        nameTag.Visible = false
        nameTag.ZIndex = 5
        nameTag.Parent = slotFrame

        local nameCorner = Instance.new("UICorner")
        nameCorner.CornerRadius = UDim.new(0, 10)
        nameCorner.Parent = nameTag

        button.MouseEnter:Connect(function()
            nameTag.Visible = not self.tools[index].isEmpty

            if not self.tools[index].isEmpty and index ~= self.selectedSlot then
                TweenService:Create(
                    slotFrame,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { BackgroundColor3 = COLORS.SLOT_HOVER }
                ):Play()
            end
        end)

        button.MouseLeave:Connect(function()
            nameTag.Visible = false

            if index ~= self.selectedSlot then
                TweenService:Create(
                    slotFrame,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { BackgroundColor3 = COLORS.SLOT_NORMAL }
                ):Play()
            end
        end)

        button.Activated:Connect(function()
            self:selectTool(index)
            self:equipTool(index)
        end)

        self.toolSlots[index] = {
            frame = slotFrame,
            icon = icon,
            countBadge = countBadge,
            countLabel = countLabel,
            nameTag = nameTag,
        }
    end

    self:updateSlotUI()
end

-- Inventory integration -----------------------------------------------------

function ToolRingGUI:setInventoryClient(inventoryClient)
    self:destroyInventoryConnections()

    self.inventoryClient = inventoryClient
    if not inventoryClient then
        return
    end

    if inventoryClient.onInventoryChanged then
        self.inventorySignalConn = inventoryClient:onInventoryChanged(function()
            self:updateToolsFromInventory()
        end)
    end

    local remote = inventoryClient.inventoryRemote
    if remote then
        table.insert(self.inventoryConnections, remote.OnClientEvent:Connect(function(action, data)
            if action == "SyncInventory" then
                self:updateToolsFromInventory()
            elseif action == "EquipItem" and data then
                self.equippedItemSlot = data.slotIndex
                self:updateSlotUI()
            elseif action == "UnequipItem" then
                self.equippedItemSlot = nil
                self:updateSlotUI()
            end
        end))
    end

    self:updateToolsFromInventory()
end

function ToolRingGUI:updateToolsFromInventory()
    if not self.inventoryClient then
        return
    end

    local slotState = self.inventoryClient.slotState or {}
    local maxSlots = self.inventoryClient.maxSlots or SLOT_COUNT

    local toolEntries = {}

    for slotIndex = 1, maxSlots do
        local state = slotState[slotIndex]
        if state and state.itemId then
            local itemId = tostring(state.itemId)
            local definition = self:resolveItemDefinition(itemId)
            local displayName = definition and (definition.displayName or definition.name) or state.name or itemId

            if self:isTool(itemId, displayName, definition) then
                local entry = {
                    slotIndex = slotIndex,
                    itemId = itemId,
                    spriteIndex = definition and definition.spriteIndex or state.spriteIndex,
                    name = displayName,
                    count = state.count or 1,
                    description = self:getToolDescription(definition, state.count),
                    definition = definition,
                    isEmpty = false,
                }

                table.insert(toolEntries, entry)
            end
        end
    end

    table.sort(toolEntries, function(a, b)
        return a.slotIndex < b.slotIndex
    end)

    for i = 1, SLOT_COUNT do
        local entry = toolEntries[i]
        if entry then
            self.tools[i] = entry
        else
            self.tools[i] = {
                isEmpty = true,
                name = "Empty",
                description = "No tool equipped",
                count = 0,
            }
        end
    end

    if self.tools[self.selectedSlot].isEmpty then
        for index, tool in ipairs(self.tools) do
            if not tool.isEmpty then
                self.selectedSlot = index
                break
            end
        end
    end

    self:updateSlotUI()
end

function ToolRingGUI:updateSlotUI()
    for index, slot in ipairs(self.toolSlots) do
        local tool = self.tools[index]
        if slot then
            slot.nameTag.Text = tool.name or "Empty"
            slot.nameTag.Visible = false

            if tool.isEmpty then
                slot.icon.Image = ""
                slot.icon.Visible = false
                slot.countBadge.Visible = false
            else
                self:applySprite(slot.icon, tool.spriteIndex)
                slot.icon.Visible = true

                if tool.count and tool.count > 1 then
                    slot.countBadge.Visible = true
                    slot.countLabel.Text = tostring(tool.count)
                else
                    slot.countBadge.Visible = false
                end
            end
        end
    end

    self:updateCenterDisplay()
    self:updateSelectionHighlight()
end

function ToolRingGUI:updateCenterDisplay()
    if not self.centerLabel then
        return
    end

    local tool = self.tools[self.selectedSlot]
    if not tool or tool.isEmpty then
        self.centerLabel.Text = ""
        if self.descriptionLabel then
            self.descriptionLabel.Text = "Select a tool"
        end
        return
    end

    local countDisplay = tool.count and tool.count > 1 and ("x" .. tostring(tool.count)) or "1"
    self.centerLabel.Text = countDisplay

    if self.descriptionLabel then
        self.descriptionLabel.Text = tool.description ~= "" and tool.description or tool.name
    end
end

-- Public API ----------------------------------------------------------------

function ToolRingGUI:selectTool(index)
    if index < 1 or index > SLOT_COUNT then
        return
    end

    self.selectedSlot = index
    self:updateCenterDisplay()
    self:updateSelectionHighlight()

    local selected = self.tools[index]
    if selected and not selected.isEmpty then
        print(string.format("[ToolRing] ✅ Selected tool: %s (slot %d)", selected.name, index))
    end
end

function ToolRingGUI:equipTool(index)
    if not self.inventoryClient then
        warn("[ToolRing] ⚠️ Cannot equip without inventory client")
        return
    end

    if index < 1 or index > SLOT_COUNT then
        return
    end

    local tool = self.tools[index]
    if not tool or tool.isEmpty or not tool.itemId then
        return
    end

    local remote = self.inventoryClient.inventoryRemote
    if not remote then
        warn("[ToolRing] ⚠️ No inventory remote available")
        return
    end

    self.equippedItemSlot = tool.slotIndex
    self:updateSelectionHighlight()

    remote:FireServer("EquipItem", {
        itemId = tool.itemId,
        slotIndex = tool.slotIndex,
        name = tool.name,
    })

    print(string.format("[ToolRing] ⚒️ Equipping tool %s from slot %d", tool.name, tool.slotIndex or -1))
end

function ToolRingGUI:show()
    if self.visible then
        return
    end

    self.visible = true
    self.gui.Enabled = true

    self:updateToolsFromInventory()

    for _, slot in ipairs(self.toolSlots) do
        if slot and slot.frame then
            slot.frame.Size = UDim2.fromOffset(0, 0)
            TweenService:Create(
                slot.frame,
                TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = UDim2.fromOffset(TOOL_SLOT_SIZE, TOOL_SLOT_SIZE) }
            ):Play()
        end
    end

    if self.centerLabel then
        self.centerLabel.Size = UDim2.fromOffset(10, 10)
        TweenService:Create(
            self.centerLabel,
            TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = UDim2.fromOffset(CENTER_SIZE, CENTER_SIZE) }
        ):Play()
    end

    print("[ToolRing] 🎯 Tool ring OPENED")
end

function ToolRingGUI:hide()
    if not self.visible then
        return
    end

    self.visible = false

    for _, slot in ipairs(self.toolSlots) do
        if slot and slot.frame then
            TweenService:Create(
                slot.frame,
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                { Size = UDim2.fromOffset(0, 0) }
            ):Play()
        end
    end

    if self.centerLabel then
        TweenService:Create(
            self.centerLabel,
            TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            { Size = UDim2.fromOffset(0, 0) }
        ):Play()
    end

    task.delay(0.22, function()
        if not self.visible then
            self.gui.Enabled = false
        end
    end)

    print("[ToolRing] 🎯 Tool ring CLOSED")
end

function ToolRingGUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function ToolRingGUI:isVisible()
    return self.visible
end

function ToolRingGUI:getSelectedTool()
    return cloneToolEntry(self.tools[self.selectedSlot] or {})
end

function ToolRingGUI:destroy()
    self:destroyInventoryConnections()

    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
end

ToolRingGUI.Show = ToolRingGUI.show
ToolRingGUI.Hide = ToolRingGUI.hide
ToolRingGUI.Toggle = ToolRingGUI.toggle

return ToolRingGUI

