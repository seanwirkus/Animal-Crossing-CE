--[[
	ObjectiveTracker.luau

	A small, always-visible HUD card that answers "what should I do next?".

	It listens to the quest system (QuestEvent / SyncQuests) and surfaces the
	single most relevant objective: a quest that's ready to claim, otherwise the
	tutorial/active quest closest to completion. This is the glue that keeps the
	core loop (gather -> craft -> fish -> complete quests -> claim -> upgrade)
	visible at all times instead of buried in the NookPhone.

	Usage:
		local ObjectiveTracker = require(script.Parent.ObjectiveTracker)
		local tracker = ObjectiveTracker.new()
		tracker:show()
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ObjectiveTracker = {}
ObjectiveTracker.__index = ObjectiveTracker

-- Lower category number = higher priority when choosing what to display.
local CATEGORY_PRIORITY = {
    tutorial = 1,
    story = 2,
    daily = 3,
    weekly = 4,
    milestone = 5,
}

local COLORS = {
    background = Color3.fromRGB(255, 250, 235),
    stroke = Color3.fromRGB(180, 150, 120),
    header = Color3.fromRGB(120, 160, 90),
    title = Color3.fromRGB(70, 55, 45),
    hint = Color3.fromRGB(120, 105, 90),
    barTrack = Color3.fromRGB(225, 215, 195),
    barFill = Color3.fromRGB(144, 202, 119),
    readyFill = Color3.fromRGB(255, 195, 77),
}

function ObjectiveTracker.new()
    local self = setmetatable({}, ObjectiveTracker)

    self.player = Players.LocalPlayer
    self.quests = {}
    self.visible = false
    self._currentQuestId = nil

    self:_buildGui()
    self:_setupRemote()

    return self
end

function ObjectiveTracker:_buildGui()
    local playerGui = self.player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ObjectiveTrackerGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 45 -- Below StatusHUD (50) and modal GUIs (100+)
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = false
    screenGui.Parent = playerGui
    self.gui = screenGui

    -- Card anchored to the mid-left edge (clear of the top-right status bar)
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.AnchorPoint = Vector2.new(0, 0.5)
    card.Position = UDim2.new(0, -300, 0.45, 0) -- starts off-screen for slide-in
    card.Size = UDim2.fromOffset(280, 116)
    card.BackgroundColor3 = COLORS.background
    card.BorderSizePixel = 0
    card.Parent = screenGui
    self.card = card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.stroke
    stroke.Thickness = 2
    stroke.Parent = card

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 14)
    padding.PaddingRight = UDim.new(0, 14)
    padding.Parent = card

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 18)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 13
    header.TextColor3 = COLORS.header
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "📋 NEXT STEP"
    header.Parent = card
    self.headerLabel = header

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.fromOffset(0, 22)
    title.Size = UDim2.new(1, 0, 0, 22)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextColor3 = COLORS.title
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Text = "Getting started"
    title.Parent = card
    self.titleLabel = title

    local hint = Instance.new("TextLabel")
    hint.Name = "Hint"
    hint.Position = UDim2.fromOffset(0, 44)
    hint.Size = UDim2.new(1, 0, 0, 30)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 13
    hint.TextColor3 = COLORS.hint
    hint.TextWrapped = true
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.TextYAlignment = Enum.TextYAlignment.Top
    hint.Text = "Open your NookPhone to view quests."
    hint.Parent = card
    self.hintLabel = hint

    -- Progress bar
    local barTrack = Instance.new("Frame")
    barTrack.Name = "BarTrack"
    barTrack.AnchorPoint = Vector2.new(0, 1)
    barTrack.Position = UDim2.new(0, 0, 1, -16)
    barTrack.Size = UDim2.new(1, 0, 0, 10)
    barTrack.BackgroundColor3 = COLORS.barTrack
    barTrack.BorderSizePixel = 0
    barTrack.Parent = card

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = barTrack

    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.fromScale(0, 1)
    barFill.BackgroundColor3 = COLORS.barFill
    barFill.BorderSizePixel = 0
    barFill.Parent = barTrack
    self.barFill = barFill

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = barFill

    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.AnchorPoint = Vector2.new(1, 1)
    progressText.Position = UDim2.new(1, 0, 1, -2)
    progressText.Size = UDim2.fromOffset(80, 14)
    progressText.BackgroundTransparency = 1
    progressText.Font = Enum.Font.GothamMedium
    progressText.TextSize = 12
    progressText.TextColor3 = COLORS.hint
    progressText.TextXAlignment = Enum.TextXAlignment.Right
    progressText.Text = ""
    progressText.Parent = card
    self.progressText = progressText
end

function ObjectiveTracker:_setupRemote()
    task.spawn(function()
        local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
        if not remoteEventsFolder then
            warn("[ObjectiveTracker] RemoteEvents folder not found")
            return
        end
        local questRemote = remoteEventsFolder:WaitForChild("QuestEvent", 15)
        if not questRemote then
            warn("[ObjectiveTracker] QuestEvent not found")
            return
        end

        questRemote.OnClientEvent:Connect(function(action, data)
            if action == "SyncQuests" then
                self.quests = data or {}
                self:_render()
            end
        end)

        -- Ask the server for the current quest list
        questRemote:FireServer("RequestQuests")
    end)
end

-- Choose the single most relevant quest to surface.
function ObjectiveTracker:_pickQuest()
    local best = nil
    local bestScore = -math.huge

    for _, quest in ipairs(self.quests) do
        local state = quest.state
        -- Ignore quests that are already claimed
        if state ~= "claimed" then
            local categoryPriority = CATEGORY_PRIORITY[quest.category] or 6
            local score

            if state == "completed" then
                -- Ready-to-claim quests are the most important nudge.
                score = 1000 - categoryPriority
            else
                -- Active quests: prefer high-priority categories and progress.
                local target = math.max(1, quest.target or 1)
                local ratio = math.clamp((quest.progress or 0) / target, 0, 1)
                score = 100 - categoryPriority * 10 + ratio * 5
            end

            if score > bestScore then
                bestScore = score
                best = quest
            end
        end
    end

    return best
end

function ObjectiveTracker:_render()
    local quest = self:_pickQuest()

    if not quest then
        self.titleLabel.Text = "Free play!"
        self.hintLabel.Text = "Explore your island. New quests appear in your NookPhone."
        self.headerLabel.Text = "📋 NEXT STEP"
        self.progressText.Text = ""
        self.barFill.Size = UDim2.fromScale(0, 1)
        self._currentQuestId = nil
        return
    end

    self._currentQuestId = quest.id

    local target = math.max(1, quest.target or 1)
    local progress = math.clamp(quest.progress or 0, 0, target)
    local ratio = progress / target
    local isReady = quest.state == "completed"

    self.titleLabel.Text = string.format("%s %s", quest.icon or "📋", quest.name or "Objective")

    if isReady then
        self.headerLabel.Text = "✅ READY TO CLAIM"
        self.hintLabel.Text = "Open your NookPhone quest log to claim your reward!"
        self.barFill.BackgroundColor3 = COLORS.readyFill
    else
        self.headerLabel.Text = "📋 NEXT STEP"
        local hint = quest.description
        local objectives = quest.objectives
        if objectives and objectives[1] and objectives[1].hint then
            hint = objectives[1].hint
        end
        self.hintLabel.Text = hint or "Make progress to complete this quest."
        self.barFill.BackgroundColor3 = COLORS.barFill
    end

    self.progressText.Text = string.format("%d / %d", progress, target)
    TweenService:Create(
        self.barFill,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.fromScale(ratio, 1) }
    ):Play()
end

function ObjectiveTracker:show()
    if self.visible then
        return
    end
    self.visible = true
    self.gui.Enabled = true
    self:_render()

    -- Slide in from the left
    self.card.Position = UDim2.new(0, -300, 0.45, 0)
    TweenService:Create(
        self.card,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 12, 0.45, 0) }
    ):Play()
end

function ObjectiveTracker:hide()
    if not self.visible then
        return
    end
    self.visible = false

    local tween = TweenService:Create(
        self.card,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0, -300, 0.45, 0) }
    )
    tween:Play()
    tween.Completed:Connect(function()
        if not self.visible then
            self.gui.Enabled = false
        end
    end)
end

function ObjectiveTracker:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

return ObjectiveTracker
