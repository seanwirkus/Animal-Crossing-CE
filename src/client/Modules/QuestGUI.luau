-- QuestGUI.luau - Client-side quest display and management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local QuestGUI = {}
QuestGUI.__index = QuestGUI

function QuestGUI.new()
    local self = setmetatable({}, QuestGUI)

    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.gui = nil
    self.visible = false
    self.quests = {}

    -- Create GUI
    self:_createGUI()

    -- Connect to server
    self:_setupRemotes()

    print("[QuestGUI] ✅ Initialized")
    return self
end

function QuestGUI:_createGUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "QuestGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 30
    screenGui.Enabled = false
    screenGui.Parent = self.playerGui

    self.gui = screenGui

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 600)
    mainFrame.Position = UDim2.new(1, -420, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -20, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "📋 Quests"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 24
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)

    -- Scroll frame for quests
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "QuestList"
    scrollFrame.Size = UDim2.new(1, -20, 1, -70)
    scrollFrame.Position = UDim2.new(0, 10, 0, 60)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame

    -- Update canvas size
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)

    self.questList = scrollFrame
    self.listLayout = listLayout

    -- Empty state
    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "EmptyLabel"
    emptyLabel.Size = UDim2.new(1, 0, 0, 100)
    emptyLabel.Position = UDim2.new(0, 0, 0, 0)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "No active quests\nComplete tasks to unlock quests!"
    emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    emptyLabel.TextSize = 16
    emptyLabel.Font = Enum.Font.Gotham
    emptyLabel.TextWrapped = true
    emptyLabel.Visible = true
    emptyLabel.Parent = scrollFrame

    self.emptyLabel = emptyLabel
end

function QuestGUI:_setupRemotes()
    local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
    local questRemote = remoteEventsFolder:WaitForChild("QuestEvent")

    -- Listen for quest updates
    questRemote.OnClientEvent:Connect(function(action, data)
        if action == "SyncQuests" then
            self:updateQuests(data)
        elseif action == "RewardsClaimed" then
            -- Show notification
            print("[QuestGUI] ✅ Rewards claimed for quest:", data.questId)
        end
    end)

    -- Request initial quest data
    task.wait(1) -- Wait for server to be ready
    questRemote:FireServer("RequestQuests")
end

function QuestGUI:updateQuests(quests)
    self.quests = quests or {}

    -- Clear existing quest UI
    for _, child in ipairs(self.questList:GetChildren()) do
        if child:IsA("Frame") and child.Name == "QuestItem" then
            child:Destroy()
        end
    end

    -- Show/hide empty state
    if #self.quests == 0 then
        self.emptyLabel.Visible = true
        return
    else
        self.emptyLabel.Visible = false
    end

    -- Create quest items
    for i, quest in ipairs(self.quests) do
        self:_createQuestItem(quest, i)
    end
end

function QuestGUI:_createQuestItem(quest, index)
    local questFrame = Instance.new("Frame")
    questFrame.Name = "QuestItem"
    questFrame.Size = UDim2.new(1, 0, 0, 120)
    questFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    questFrame.BorderSizePixel = 0
    questFrame.LayoutOrder = index
    questFrame.Parent = self.questList

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = questFrame

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 50, 0, 50)
    iconLabel.Position = UDim2.new(0, 10, 0, 10)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = quest.icon or "📋"
    iconLabel.TextSize = 32
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.Parent = questFrame

    -- Quest name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -70, 0, 25)
    nameLabel.Position = UDim2.new(0, 70, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = quest.name or "Unknown Quest"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 18
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = questFrame

    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -70, 0, 40)
    descLabel.Position = UDim2.new(0, 70, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = quest.description or ""
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextSize = 14
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = questFrame

    -- Progress bar
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(1, -20, 0, 20)
    progressFrame.Position = UDim2.new(0, 10, 1, -30)
    progressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = questFrame

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressFrame

    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = progressBar

    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.Position = UDim2.new(0, 0, 0, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = string.format("%d / %d", quest.progress or 0, quest.target or 1)
    progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressText.TextSize = 12
    progressText.Font = Enum.Font.GothamBold
    progressText.Parent = progressFrame

    -- Update progress
    local progress = quest.progress or 0
    local target = quest.target or 1
    local percentage = math.min(progress / target, 1)
    progressBar.Size = UDim2.new(percentage, 0, 1, 0)

    -- Claim button (if completed)
    if quest.state == "completed" then
        local claimButton = Instance.new("TextButton")
        claimButton.Name = "ClaimButton"
        claimButton.Size = UDim2.new(0, 100, 0, 30)
        claimButton.Position = UDim2.new(1, -110, 1, -30)
        claimButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        claimButton.Text = "Claim"
        claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        claimButton.TextSize = 14
        claimButton.Font = Enum.Font.GothamBold
        claimButton.Parent = questFrame

        local claimCorner = Instance.new("UICorner")
        claimCorner.CornerRadius = UDim.new(0, 6)
        claimCorner.Parent = claimButton

        claimButton.MouseButton1Click:Connect(function()
            self:_claimRewards(quest.id)
        end)

        -- Highlight completed quests
        questFrame.BackgroundColor3 = Color3.fromRGB(60, 80, 50)
    end

    -- Category badge
    local categoryLabel = Instance.new("TextLabel")
    categoryLabel.Name = "Category"
    categoryLabel.Size = UDim2.new(0, 60, 0, 20)
    categoryLabel.Position = UDim2.new(1, -70, 0, 10)
    categoryLabel.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    categoryLabel.Text = string.upper(quest.category or "quest")
    categoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    categoryLabel.TextSize = 10
    categoryLabel.Font = Enum.Font.GothamBold
    categoryLabel.Parent = questFrame

    local categoryCorner = Instance.new("UICorner")
    categoryCorner.CornerRadius = UDim.new(0, 4)
    categoryCorner.Parent = categoryLabel
end

function QuestGUI:_claimRewards(questId)
    local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
    local questRemote = remoteEventsFolder:WaitForChild("QuestEvent")
    questRemote:FireServer("ClaimRewards", { questId = questId })
end

function QuestGUI:show()
    if self.visible then
        return
    end

    if self.gui then
        self.gui.Enabled = true
        self.visible = true

        -- Request latest quest data
        local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
        local questRemote = remoteEventsFolder:FindFirstChild("QuestEvent")
        if questRemote then
            questRemote:FireServer("RequestQuests")
        end

        print("[QuestGUI] ✅ Shown")
    end
end

function QuestGUI:hide()
    if not self.visible then
        return
    end

    if self.gui then
        self.gui.Enabled = false
        self.visible = false
        print("[QuestGUI] ✅ Hidden")
    end
end

function QuestGUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function QuestGUI:isVisible()
    return self.visible
end

return QuestGUI
