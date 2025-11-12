--[[
    ToolRingGUI.luau

    Re-implementation of the Animal Crossing inspired tool ring.
    Shows up to 8 tools in a circular menu, highlights the equipped tool,
    and mirrors the cozy ACNH colour palette.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local InventoryGuiSetup = require(script.Parent:WaitForChild("InventoryGuiSetup"))

local SLOT_COUNT = 8

local RING_RADIUS = 140
local TOOL_SLOT_SIZE = 75
local CENTER_SIZE = 100
local GLOW_SIZE = 130

local COLORS = {
    ITEM_GRABBED = Color3.fromRGB(122, 198, 255),
    ITEM_SELECTED = Color3.fromRGB(86, 174, 255),
    BORDER_DARK = Color3.fromRGB(120, 138, 160),
    SLOT_NORMAL = Color3.fromRGB(245, 247, 250),
    SLOT_HOVER = Color3.fromRGB(234, 242, 252),
    SLOT_EQUIPPED = Color3.fromRGB(214, 230, 251),
    TEXT_DARK = Color3.fromRGB(110, 122, 138),
    TEXT_LIGHT = Color3.fromRGB(245, 247, 250),
    STROKE_SUBTLE = Color3.fromRGB(186, 198, 212),
}

local TOOL_KEYWORDS = {
    "fishing", "rod", "axe", "net", "shovel", "watering", "can", "slingshot",
    "ladder", "flimsy", "stone", "iron", "golden", "tool", "tools",
}

local ACCEPTED_CATEGORIES = {
    Tools = true,
    Equipment = true,
    ["Vaulting Pole"] = true,
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
    self.ringContainer = nil
    self.centerLabel = nil
    self.selectedLabel = nil
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
    self.toolObjects = require(shared:WaitForChild("ToolObjects"))
    self.displayItemMap = self.itemDataFetcher.getDisplayItemMap()

    local playerScripts = self.player:WaitForChild("PlayerScripts")
    local inventoryStylingModule = playerScripts:FindFirstChild("InventoryStyling")
    if inventoryStylingModule then
        self.inventoryStyling = require(inventoryStylingModule)
    else
        warn("[ToolRingGUI] ⚠️ InventoryStyling module not found; using fallback styling")
        self.inventoryStyling = nil
    end

    self.slotTemplate = InventoryGuiSetup.createSlotTemplate()
    self.slotTemplate.Name = "InventoryItemSlotTemplate"
    self.slotTemplate.Visible = false

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

function ToolRingGUI:applySlotStyling(slotFrame: Frame?, state: string?)
    if not slotFrame then
        return
    end

    local corner = slotFrame:FindFirstChild("ToolRingCorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Name = "ToolRingCorner"
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = slotFrame
    end

    local stroke = slotFrame:FindFirstChild("ToolRingStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Name = "ToolRingStroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = slotFrame
    end

    local backgroundColor = COLORS.SLOT_NORMAL
    local backgroundTransparency = 0.4
    local strokeColor = COLORS.STROKE_SUBTLE
    local strokeThickness = 1.5

    if state == "selected" then
        backgroundColor = COLORS.ITEM_SELECTED
        backgroundTransparency = 0.15
        strokeColor = COLORS.ITEM_SELECTED
        strokeThickness = 2.5
    elseif state == "hover" then
        backgroundColor = COLORS.SLOT_HOVER
        backgroundTransparency = 0.2
        strokeColor = COLORS.ITEM_GRABBED
        strokeThickness = 2
    elseif state == "equipped" then
        backgroundColor = COLORS.SLOT_EQUIPPED
        backgroundTransparency = 0.25
        strokeColor = COLORS.ITEM_SELECTED
        strokeThickness = 2
    end

    slotFrame.BackgroundColor3 = backgroundColor
    slotFrame.BackgroundTransparency = backgroundTransparency
    slotFrame.BorderSizePixel = 0

    stroke.Color = strokeColor
    stroke.Thickness = strokeThickness
    stroke.Transparency = 0
end

function ToolRingGUI:applyCountStyling(label: TextLabel?)
    if not label then
        return
    end

    if self.inventoryStyling and self.inventoryStyling.ApplyItemCountStyling then
        self.inventoryStyling.ApplyItemCountStyling(label)
    else
        label.TextColor3 = COLORS.TEXT_LIGHT
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
    end
end

function ToolRingGUI:applyNameStyling(label: TextLabel?)
    if not label then
        return
    end

    if self.inventoryStyling and self.inventoryStyling.ApplyItemNameStyling then
        self.inventoryStyling.ApplyItemNameStyling(label)
    else
        label.TextColor3 = COLORS.TEXT_DARK
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
    end
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
        if slot and slot.frame and slot.container then
            local tool = self.tools[index]

            local isSelected = index == self.selectedSlot
            local isEquipped = tool.slotIndex and tool.slotIndex == self.equippedItemSlot

            local stylingState = "default"
            if isSelected then
                stylingState = "selected"
            elseif isEquipped then
                stylingState = "equipped"
            end

            self:applySlotStyling(slot.frame, stylingState)

            if slot.numberLabel then
                if isSelected then
                    slot.numberLabel.TextColor3 = COLORS.ITEM_SELECTED
                elseif isEquipped then
                    slot.numberLabel.TextColor3 = COLORS.SLOT_EQUIPPED
                else
                    slot.numberLabel.TextColor3 = COLORS.TEXT_DARK
                end
            end

            if slot.selectionTween then
                slot.selectionTween:Cancel()
                slot.selectionTween = nil
            end

            local targetSize = TOOL_SLOT_SIZE
            if isSelected then
                targetSize = TOOL_SLOT_SIZE + 8
            end

            slot.selectionTween = TweenService:Create(
                slot.container,
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

    local diameter = (RING_RADIUS + TOOL_SLOT_SIZE) * 2

    local ringContainer = Instance.new("Frame")
    ringContainer.Name = "RingContainer"
    ringContainer.Size = UDim2.fromOffset(diameter, diameter)
    ringContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    ringContainer.Position = UDim2.fromScale(0.5, 0.5)
    ringContainer.BackgroundTransparency = 1
    ringContainer.ZIndex = 3
    ringContainer.Parent = gui
    self.ringContainer = ringContainer

    local halo = Instance.new("Frame")
    halo.Name = "CenterHalo"
    halo.Size = UDim2.fromOffset(GLOW_SIZE + 36, GLOW_SIZE + 36)
    halo.AnchorPoint = Vector2.new(0.5, 0.5)
    halo.Position = UDim2.fromScale(0.5, 0.5)
    halo.BackgroundTransparency = 0.85
    halo.BackgroundColor3 = COLORS.SLOT_HOVER
    halo.BorderSizePixel = 0
    halo.ZIndex = 1
    halo.Parent = ringContainer

    local haloCorner = Instance.new("UICorner")
    haloCorner.CornerRadius = UDim.new(1, 0)
    haloCorner.Parent = halo

    local haloStroke = Instance.new("UIStroke")
    haloStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    haloStroke.Color = COLORS.STROKE_SUBTLE
    haloStroke.Thickness = 1.5
    haloStroke.Transparency = 0.3
    haloStroke.Parent = halo

    local centerPad = Instance.new("Frame")
    centerPad.Name = "CenterPad"
    centerPad.Size = UDim2.fromOffset(CENTER_SIZE + 24, CENTER_SIZE + 24)
    centerPad.AnchorPoint = Vector2.new(0.5, 0.5)
    centerPad.Position = UDim2.fromScale(0.5, 0.5)
    centerPad.BackgroundColor3 = COLORS.SLOT_NORMAL
    centerPad.BackgroundTransparency = 0.25
    centerPad.BorderSizePixel = 0
    centerPad.ZIndex = 2
    centerPad.Parent = ringContainer

    local padCorner = Instance.new("UICorner")
    padCorner.CornerRadius = UDim.new(1, 0)
    padCorner.Parent = centerPad

    local padStroke = Instance.new("UIStroke")
    padStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    padStroke.Color = COLORS.STROKE_SUBTLE
    padStroke.Thickness = 1.5
    padStroke.Transparency = 0.15
    padStroke.Parent = centerPad

    local centerLabel = Instance.new("TextLabel")
    centerLabel.Name = "CenterLabel"
    centerLabel.Size = UDim2.fromOffset(CENTER_SIZE, CENTER_SIZE)
    centerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    centerLabel.Position = UDim2.fromScale(0.5, 0.5)
    centerLabel.BackgroundTransparency = 1
    centerLabel.Font = Enum.Font.GothamMedium
    centerLabel.TextColor3 = COLORS.ITEM_SELECTED
    centerLabel.TextScaled = true
    centerLabel.Text = ""
    centerLabel.ZIndex = 4
    centerLabel.Parent = ringContainer
    self.centerLabel = centerLabel

    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Name = "SelectedLabel"
    selectedLabel.AnchorPoint = Vector2.new(0.5, 0)
    selectedLabel.Position = UDim2.new(0.5, 0, 1, 12)
    selectedLabel.Size = UDim2.fromOffset(diameter, 28)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = "Select a tool"
    selectedLabel.TextColor3 = COLORS.TEXT_DARK
    selectedLabel.TextSize = 20
    selectedLabel.Font = Enum.Font.GothamMedium
    selectedLabel.TextWrapped = true
    selectedLabel.ZIndex = 4
    selectedLabel.Parent = ringContainer
    self.selectedLabel = selectedLabel

    self:createSlots()
end

function ToolRingGUI:createSlots()
    local template = self.slotTemplate
    if not template then
        template = InventoryGuiSetup.createSlotTemplate()
        template.Name = "InventoryItemSlotTemplate"
        template.Visible = false
        self.slotTemplate = template
    end

    for index = 1, SLOT_COUNT do
        local angle = (index - 1) * (math.pi * 2 / SLOT_COUNT) - math.pi / 2
        local offsetX = math.cos(angle) * RING_RADIUS
        local offsetY = math.sin(angle) * RING_RADIUS

        local container = Instance.new("Frame")
        container.Name = string.format("ItemSlotFrame%d", index)
        container.Size = UDim2.fromOffset(TOOL_SLOT_SIZE, TOOL_SLOT_SIZE)
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ZIndex = 4
        container.Parent = self.ringContainer
        container:SetAttribute("RingIndex", index)

        local slotFrame = template:Clone()
        slotFrame.Visible = true
        slotFrame.Name = "InventoryItemSlotTemplate"
        slotFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        slotFrame.Position = UDim2.fromScale(0.5, 0.5)
        slotFrame.Size = UDim2.new(1, 0, 1, 0)
        slotFrame.ZIndex = 5
        slotFrame.Parent = container

        self:applySlotStyling(slotFrame, "default")

        local icon = slotFrame:FindFirstChild("ItemIcon")
        if icon and icon:IsA("ImageLabel") then
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
            icon.Position = UDim2.new(0.5, 0, 0.45, 0)
            icon.Size = UDim2.fromOffset(TOOL_SLOT_SIZE - 18, TOOL_SLOT_SIZE - 24)
            icon.ZIndex = 6
        end

        local nameTag = slotFrame:FindFirstChild("ItemName")
        if nameTag and nameTag:IsA("TextLabel") then
            nameTag.Visible = false
            nameTag.AnchorPoint = Vector2.new(0.5, 0)
            nameTag.Position = UDim2.new(0.5, 0, 1, 6)
            nameTag.Size = UDim2.new(1, 12, 0, 22)
            nameTag.BackgroundTransparency = 1
            nameTag.ZIndex = 6
            if not nameTag:FindFirstChildOfClass("UICorner") then
                local nameCorner = Instance.new("UICorner")
                nameCorner.CornerRadius = UDim.new(0, 10)
                nameCorner.Parent = nameTag
            end
            self:applyNameStyling(nameTag)
        end

        local templateCountLabel = slotFrame:FindFirstChild("ItemCount")
        if templateCountLabel and templateCountLabel:IsA("TextLabel") then
            templateCountLabel.Visible = false
        end

        local countBadge = Instance.new("Frame")
        countBadge.Name = "CountBadge"
        countBadge.Size = UDim2.fromOffset(32, 28)
        countBadge.AnchorPoint = Vector2.new(1, 1)
        countBadge.Position = UDim2.new(1, -6, 1, -6)
        countBadge.BackgroundColor3 = COLORS.ITEM_SELECTED
        countBadge.BorderSizePixel = 0
        countBadge.Visible = false
        countBadge.ZIndex = 8
        countBadge.Parent = container

        local badgeCorner = countBadge:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(1, 0)
        badgeCorner.Parent = countBadge

        local countLabel = countBadge:FindFirstChild("CountLabel")
        if not countLabel then
            countLabel = Instance.new("TextLabel")
            countLabel.Name = "CountLabel"
            countLabel.Size = UDim2.fromScale(1, 1)
            countLabel.BackgroundTransparency = 1
            countLabel.ZIndex = 9
            countLabel.Parent = countBadge
        end
        countLabel.Text = ""
        countLabel.TextScaled = true
        self:applyCountStyling(countLabel)

        local button = Instance.new("TextButton")
        button.Name = "Interactive"
        button.Text = ""
        button.AutoButtonColor = false
        button.Size = UDim2.fromScale(1, 1)
        button.BackgroundTransparency = 1
        button.ZIndex = 10
        button.Parent = container

        button.MouseEnter:Connect(function()
            if nameTag then
                nameTag.Visible = not self.tools[index].isEmpty
            end

            if not self.tools[index].isEmpty and index ~= self.selectedSlot then
                self:applySlotStyling(slotFrame, "hover")
            end
        end)

        button.MouseLeave:Connect(function()
            if nameTag then
                nameTag.Visible = false
            end

            if index ~= self.selectedSlot then
                self:applySlotStyling(slotFrame, "default")
            end
        end)

        button.Activated:Connect(function()
            self:selectTool(index)
            self:equipTool(index)
        end)

        self.toolSlots[index] = {
            container = container,
            frame = slotFrame,
            icon = icon,
            countBadge = countBadge,
            countLabel = countLabel,
            nameTag = nameTag,
            numberLabel = nil,
            selectionTween = nil,
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
            if slot.nameTag then
                slot.nameTag.Text = tool.name or "Empty"
                slot.nameTag.Visible = false
            end

            if tool.isEmpty then
                if slot.icon then
                    slot.icon.Image = ""
                    slot.icon.Visible = false
                end
                if slot.countBadge then
                    slot.countBadge.Visible = false
                end
                if slot.countLabel then
                    slot.countLabel.Text = ""
                end
            else
                if slot.icon then
                    self:applySprite(slot.icon, tool.spriteIndex)
                    slot.icon.Visible = true
                end

                if slot.countBadge and slot.countLabel then
                    if tool.count and tool.count > 1 then
                        slot.countBadge.Visible = true
                        slot.countLabel.Text = tostring(tool.count)
                    else
                        slot.countBadge.Visible = false
                        slot.countLabel.Text = ""
                    end
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
        if self.selectedLabel then
            self.selectedLabel.Text = "Select a tool"
        end
        return
    end

    local countDisplay = tool.count and tool.count > 1 and ("x" .. tostring(tool.count)) or "1"
    self.centerLabel.Text = countDisplay

    if self.selectedLabel then
        self.selectedLabel.Text = tool.description ~= "" and tool.description or tool.name
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

    -- Get the character and unequip any existing tools
    local character = self.player.Character
    if character then
        -- Remove any existing tools from character
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                item:Destroy()
            end
        end
        
        -- Equip the 3D tool model
        self.toolObjects.equipTool(character, tool.itemId)
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
        if slot and slot.container then
            slot.container.Size = UDim2.fromOffset(0, 0)
            TweenService:Create(
                slot.container,
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
        if slot and slot.container then
            TweenService:Create(
                slot.container,
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

