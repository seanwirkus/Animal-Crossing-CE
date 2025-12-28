--[[
	StatusHUD.luau
	
	Permanent status HUD that shows player information (bells, miles, inventory, quests)
	Always visible at the top of the screen, similar to Animal Crossing style
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LOCAL_PLAYER = Players.LocalPlayer

local StatusHUD = {}
StatusHUD.__index = StatusHUD

local HUD_COLORS = {
    bar = Color3.fromRGB(248, 244, 232),
    barHighlight = Color3.fromRGB(252, 249, 243),
    border = Color3.fromRGB(214, 204, 190),
    divider = Color3.fromRGB(220, 210, 196),
    text = Color3.fromRGB(74, 60, 46),
    iconText = Color3.fromRGB(255, 255, 255),
    bells = Color3.fromRGB(244, 200, 96),
    miles = Color3.fromRGB(92, 185, 176),
    inventory = Color3.fromRGB(208, 180, 140),
    quests = Color3.fromRGB(130, 200, 120),
    time = Color3.fromRGB(120, 170, 210),
    date = Color3.fromRGB(170, 140, 200),
    region = Color3.fromRGB(120, 170, 140),
    players = Color3.fromRGB(210, 160, 120),
}

local function formatNumber(num: number): string
    local formatted = tostring(math.floor(num or 0))
    local k
    repeat
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return formatted
end

local function formatTime(now: { hour: number, min: number })
    local hours = now.hour or 12
    local minutes = now.min or 0
    local ampm = hours >= 12 and "PM" or "AM"

    if hours > 12 then
        hours = hours - 12
    elseif hours == 0 then
        hours = 12
    end

    return string.format("%d:%02d %s", hours, minutes, ampm)
end

local function formatDate(now: { month: number, day: number })
    local monthNames = {
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    }
    return string.format("%s %d", monthNames[now.month or 1], now.day or 1)
end

local function describeRegion(position: Vector3?)
    if not position then
        return "--"
    end

    local ns = position.Z >= 0 and "S" or "N"
    local ew = position.X >= 0 and "E" or "W"
    local distance = math.floor(Vector3.new(position.X, 0, position.Z).Magnitude)
    return string.format("%s%s %dm", ns, ew, distance)
end

function StatusHUD.new()
    local self = setmetatable({}, StatusHUD)
    
    self.player = LOCAL_PLAYER
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.visible = true
    self.statusChips = {}
    self._tickerActive = false
    self.dynamicState = {
        bells = 0,
        miles = 0,
        time = "--:--",
        date = "--",
        region = "--",
        players = 0,
        inventory = {
            used = 0,
            max = 0,
        },
        quests = {
            active = {},
            completed = 0,
        },
    }
    
    self:createHUD()
    self:setupConnections()
    self:_connectDataSources()
    self:_startTicker()
    
    print("[StatusHUD] ✅ Status HUD initialized")
    return self
end

function StatusHUD:createHUD()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatusHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 50 -- Above most other UI
    screenGui.IgnoreGuiInset = true
    screenGui.Enabled = true
    screenGui.Parent = self.playerGui
    
    self.gui = screenGui
    
    -- Main container at top-right of screen
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.fromOffset(0, 0)
    mainContainer.AutomaticSize = Enum.AutomaticSize.XY
    mainContainer.AnchorPoint = Vector2.new(1, 0)
    mainContainer.Position = UDim2.new(1, -6, 0, 6)
    mainContainer.BackgroundTransparency = 1
    mainContainer.Parent = screenGui
    
    -- Status bar container (two rows)
    local statusBar = Instance.new("Frame")
    statusBar.Name = "StatusBar"
    statusBar.Size = UDim2.fromOffset(0, 0)
    statusBar.AutomaticSize = Enum.AutomaticSize.XY
    statusBar.BackgroundColor3 = HUD_COLORS.bar
    statusBar.BorderSizePixel = 0
    statusBar.Parent = mainContainer
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 16)
    statusCorner.Parent = statusBar
    
    local statusStroke = Instance.new("UIStroke")
    statusStroke.Color = HUD_COLORS.border
    statusStroke.Thickness = 1
    statusStroke.Transparency = 0.5
    statusStroke.Parent = statusBar

    local statusGradient = Instance.new("UIGradient")
    statusGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, HUD_COLORS.barHighlight),
        ColorSequenceKeypoint.new(1, HUD_COLORS.bar),
    })
    statusGradient.Rotation = 90
    statusGradient.Parent = statusBar
    
    local barLayout = Instance.new("UIListLayout")
    barLayout.FillDirection = Enum.FillDirection.Vertical
    barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    barLayout.Padding = UDim.new(0, 4)
    barLayout.SortOrder = Enum.SortOrder.LayoutOrder
    barLayout.Parent = statusBar
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent = statusBar

    local infoRow = Instance.new("Frame")
    infoRow.Name = "InfoRow"
    infoRow.Size = UDim2.fromOffset(0, 0)
    infoRow.AutomaticSize = Enum.AutomaticSize.XY
    infoRow.BackgroundTransparency = 1
    infoRow.LayoutOrder = 1
    infoRow.Parent = statusBar

    local infoLayout = Instance.new("UIListLayout")
    infoLayout.FillDirection = Enum.FillDirection.Horizontal
    infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    infoLayout.Padding = UDim.new(0, 8)
    infoLayout.Parent = infoRow

    local statusRow = Instance.new("Frame")
    statusRow.Name = "StatusRow"
    statusRow.Size = UDim2.fromOffset(0, 0)
    statusRow.AutomaticSize = Enum.AutomaticSize.XY
    statusRow.BackgroundTransparency = 1
    statusRow.LayoutOrder = 2
    statusRow.Parent = statusBar

    local statusLayout = Instance.new("UIListLayout")
    statusLayout.FillDirection = Enum.FillDirection.Horizontal
    statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    statusLayout.Padding = UDim.new(0, 8)
    statusLayout.Parent = statusRow
    
    -- Create status chips
    local infoConfig = {
        { key = "time", icon = "T", title = "Time", color = HUD_COLORS.time },
        { key = "date", icon = "D", title = "Date", color = HUD_COLORS.date },
        { key = "region", icon = "A", title = "Area", color = HUD_COLORS.region },
        { key = "players", icon = "P", title = "Players", color = HUD_COLORS.players },
    }

    local statusConfig = {
        { key = "bells", icon = "B", title = "Bells", color = HUD_COLORS.bells },
        { key = "miles", icon = "M", title = "Miles", color = HUD_COLORS.miles },
        { key = "inventory", icon = "I", title = "Bag", color = HUD_COLORS.inventory },
        { key = "quests", icon = "Q", title = "Quests", color = HUD_COLORS.quests },
    }
    
    for index, config in ipairs(infoConfig) do
        local chip, valueLabel = self:createStatusChip(config.icon, config.title, config.color)
        chip.LayoutOrder = index
        chip.Parent = infoRow
        self.statusChips[config.key] = valueLabel
    end

    for index, config in ipairs(statusConfig) do
        local chip, valueLabel = self:createStatusChip(config.icon, config.title, config.color)
        chip.LayoutOrder = index
        chip.Parent = statusRow
        self.statusChips[config.key] = valueLabel
    end
    
    self.mainContainer = mainContainer
    self.statusBar = statusBar
    self.infoRow = infoRow
    self.statusRow = statusRow
end

function StatusHUD:createStatusChip(iconText: string, titleText: string, accentColor: Color3)
    local chip = Instance.new("Frame")
    chip.Name = "StatusChip"
    chip.Size = UDim2.fromOffset(0, 20)
    chip.AutomaticSize = Enum.AutomaticSize.X
    chip.BackgroundTransparency = 1
    chip.BorderSizePixel = 0
    
    local chipLayout = Instance.new("UIListLayout")
    chipLayout.FillDirection = Enum.FillDirection.Horizontal
    chipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    chipLayout.Padding = UDim.new(0, 5)
    chipLayout.Parent = chip
    
    local iconBubble = Instance.new("Frame")
    iconBubble.Name = "IconBubble"
    iconBubble.Size = UDim2.fromOffset(16, 16)
    iconBubble.BackgroundColor3 = accentColor
    iconBubble.BorderSizePixel = 0
    iconBubble.Parent = chip

    local bubbleCorner = Instance.new("UICorner")
    bubbleCorner.CornerRadius = UDim.new(0, 8)
    bubbleCorner.Parent = iconBubble

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.fromScale(1, 1)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = iconText
    iconLabel.TextColor3 = HUD_COLORS.iconText
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 9
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.Parent = iconBubble
    
    -- Value (main display)
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.fromOffset(0, 16)
    valueLabel.AutomaticSize = Enum.AutomaticSize.X
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = string.format("%s --", titleText)
    valueLabel.TextColor3 = HUD_COLORS.text
    valueLabel.Font = Enum.Font.GothamSemibold
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel:SetAttribute("Title", titleText)
    valueLabel.Parent = chip
    
    return chip, valueLabel
end

function StatusHUD:updateStatusChip(key: string, valueText: string)
    local valueLabel = self.statusChips and self.statusChips[key]
    if valueLabel then
        local title = valueLabel:GetAttribute("Title")
        if title then
            valueLabel.Text = string.format("%s %s", title, valueText)
        else
            valueLabel.Text = valueText
        end
    end
end

function StatusHUD:updateStatusChips()
    self:updateStatusChip("time", self.dynamicState.time or "--:--")
    self:updateStatusChip("date", self.dynamicState.date or "--")
    self:updateStatusChip("region", self.dynamicState.region or "--")
    self:updateStatusChip("players", tostring(self.dynamicState.players or 0))

    self:updateStatusChip("bells", formatNumber(self.dynamicState.bells))
    self:updateStatusChip("miles", formatNumber(self.dynamicState.miles))
    
    local inventoryState = self.dynamicState.inventory
    local bagText = inventoryState.max > 0 and string.format("%d/%d", inventoryState.used, inventoryState.max)
        or "0/0"
    self:updateStatusChip("inventory", bagText)
    
    local questState = self.dynamicState.quests
    local tasksText = string.format("%d/%d", #questState.active, questState.completed)
    self:updateStatusChip("quests", tasksText)
end

function StatusHUD:setupConnections()
    -- No specific connections needed for now
    -- Will be updated through data source connections
end

function StatusHUD:_startTicker()
    if self._tickerActive then
        return
    end

    self._tickerActive = true
    task.spawn(function()
        local lastMinute = -1
        while self._tickerActive do
            local now = os.date("*t", os.time())
            if now.min ~= lastMinute then
                self.dynamicState.time = formatTime(now)
                self.dynamicState.date = formatDate(now)
                lastMinute = now.min
            end

            self.dynamicState.players = #Players:GetPlayers()
            self.dynamicState.region = self:_getRegionLabel()

            self:updateStatusChips()
            task.wait(1)
        end
    end)
end

function StatusHUD:_getRegionLabel()
    local character = self.player and self.player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return describeRegion(root and root.Position)
end

function StatusHUD:_connectDataSources()
    self:_connectCurrencyUpdates()
    self:_connectInventoryUpdates()
    self:_connectQuestUpdates()
end

function StatusHUD:_connectCurrencyUpdates()
    local success, remote = pcall(function()
        return ReplicatedStorage:WaitForChild("CurrencyEvent", 5)
    end)
    
    if not success or not remote then
        warn("[StatusHUD] ⚠️ CurrencyEvent not available")
        return
    end
    
    remote.OnClientEvent:Connect(function(action, data)
        if action == "UpdateBells" and data then
            self.dynamicState.bells = data.bells or self.dynamicState.bells
        elseif action == "UpdateMiles" and data then
            self.dynamicState.miles = data.miles or self.dynamicState.miles
        elseif action == "UpdateAll" and data then
            self.dynamicState.bells = data.bells or self.dynamicState.bells
            self.dynamicState.miles = data.miles or self.dynamicState.miles
        end
        
        self:updateStatusChips()
    end)
    
    remote:FireServer("GetCurrency")
end

function StatusHUD:_connectInventoryUpdates()
    task.spawn(function()
        local inventoryClient = self:_waitForGlobal("InventoryClient", 15)
        if not inventoryClient then
            warn("[StatusHUD] ⚠️ InventoryClient not available")
            return
        end
        
        if inventoryClient.getInventorySnapshot then
            local snapshot = inventoryClient:getInventorySnapshot()
            self:updateInventorySummary(snapshot)
        end
        
        if inventoryClient.onInventoryChanged then
            inventoryClient:onInventoryChanged(function(snapshot)
                self:updateInventorySummary(snapshot)
            end)
        end
    end)
end

function StatusHUD:_waitForGlobal(key: string, timeout: number?)
    local waited = 0
    local duration = timeout or 10
    while waited <= duration do
        local value = rawget(_G, key)
        if value then
            return value
        end
        task.wait(0.5)
        waited += 0.5
    end
    return nil
end

function StatusHUD:updateInventorySummary(snapshot)
    if not snapshot then
        return
    end
    
    local slots = snapshot.slots or {}
    local used = 0
    
    for _, state in pairs(slots) do
        if state and state.itemId then
            used += 1
        end
    end
    
    self.dynamicState.inventory = {
        used = used,
        max = snapshot.maxSlots or self.dynamicState.inventory.max,
    }
    
    self:updateStatusChips()
end

function StatusHUD:_connectQuestUpdates()
    local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        warn("[StatusHUD] ⚠️ RemoteEvents folder missing")
        return
    end
    
    local questRemote = remoteFolder:FindFirstChild("QuestEvent")
    if not questRemote then
        warn("[StatusHUD] ⚠️ QuestEvent missing")
        return
    end
    
    questRemote.OnClientEvent:Connect(function(action, data)
        if action == "SyncQuests" then
            self:updateQuestSummary(data)
        end
    end)
    
    task.delay(1, function()
        questRemote:FireServer("RequestQuests")
    end)
end

function StatusHUD:updateQuestSummary(quests)
    quests = quests or {}
    local active = {}
    local completed = 0
    
    for _, quest in ipairs(quests) do
        if quest.state == "completed" then
            completed += 1
        else
            table.insert(active, quest)
        end
    end
    
    self.dynamicState.quests = {
        active = active,
        completed = completed,
    }
    
    self:updateStatusChips()
end

function StatusHUD:show()
    self.visible = true
    if self.gui then
        self.gui.Enabled = true
    end
end

function StatusHUD:hide()
    self.visible = false
    if self.gui then
        self.gui.Enabled = false
    end
end

function StatusHUD:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function StatusHUD:destroy()
    self._tickerActive = false
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
end

return StatusHUD
