local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local BuildingCatalog = require(sharedFolder:WaitForChild("BuildingCatalog"))
local ItemDataFetcher = require(sharedFolder:WaitForChild("ItemDataFetcher"))

local BuildingGUI = {}
BuildingGUI.__index = BuildingGUI

local COLORS = {
    BACKGROUND = Color3.fromRGB(255, 251, 235),
    PANEL = Color3.fromRGB(249, 244, 226),
    BORDER = Color3.fromRGB(120, 98, 78),
    TEXT = Color3.fromRGB(60, 48, 40),
    TEXT_SUBTLE = Color3.fromRGB(100, 88, 74),
    ACCENT = Color3.fromRGB(66, 176, 149),
    LOCKED = Color3.fromRGB(196, 196, 196),
    IN_PROGRESS = Color3.fromRGB(255, 210, 92),
    COMPLETED = Color3.fromRGB(135, 196, 114),
    ERROR = Color3.fromRGB(196, 72, 72),
}

local STATUS_COLORS = {
    locked = COLORS.LOCKED,
    available = COLORS.ACCENT,
    ["in-progress"] = COLORS.IN_PROGRESS,
    completed = COLORS.COMPLETED,
    repeatable = COLORS.ACCENT,
}

local function createSectionLabel(text: string, parent: Instance)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = COLORS.TEXT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Size = UDim2.new(1, 0, 0, 24)
    label.Text = text
    label.Parent = parent
    return label
end

local function createDivider(parent: Instance)
    local divider = Instance.new("Frame")
    divider.BackgroundColor3 = COLORS.BORDER
    divider.BorderSizePixel = 0
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Parent = parent
    return divider
end

local function formatRequirement(requirement)
    local item = ItemDataFetcher.getItem(requirement.itemId)
    local itemName = item and (item.displayName or item.name) or requirement.itemId
    return string.format("%s × %d", itemName, requirement.count or 1)
end

local function cloneDictionary(source)
    return table.clone(source)
end

function BuildingGUI.new()
    local self = setmetatable({}, BuildingGUI)

    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")

    self.categories = BuildingCatalog.getCategories()
    self.selectedCategory = self.categories[1] and self.categories[1].id or "community"
    self.selectedProjectId = nil
    self.visible = false

    self.progress = {
        island = {},
        home = {},
    }

    self.feedbackTicker = 0

    self:_createRemotes()
    self:_buildGui()
    self:_connectRemotes()

    return self
end

function BuildingGUI:_createRemotes()
    local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "RemoteEvents"
        remoteFolder.Parent = ReplicatedStorage
    end

    self.requestRemote = remoteFolder:FindFirstChild("BuildingRequest")
    if not self.requestRemote then
        self.requestRemote = Instance.new("RemoteEvent")
        self.requestRemote.Name = "BuildingRequest"
        self.requestRemote.Parent = remoteFolder
    end

    self.progressRemote = remoteFolder:FindFirstChild("BuildingProgress")
    if not self.progressRemote then
        self.progressRemote = Instance.new("RemoteEvent")
        self.progressRemote.Name = "BuildingProgress"
        self.progressRemote.Parent = remoteFolder
    end
end

function BuildingGUI:_buildGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BuildingInterface"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 45
    screenGui.Parent = self.playerGui
    self.gui = screenGui

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    -- Responsive sizing using scale with constraints
    container.Size = UDim2.fromScale(0.85, 0.85)
    container.BackgroundColor3 = COLORS.BACKGROUND
    container.BorderSizePixel = 0
    container.Parent = screenGui
    
    -- Size constraints for responsive behavior
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(800, 500)
    sizeConstraint.MaxSize = Vector2.new(1200, 800)
    sizeConstraint.Parent = container

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 16)
    containerCorner.Parent = container

    local containerStroke = Instance.new("UIStroke")
    containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    containerStroke.Thickness = 3
    containerStroke.Color = COLORS.BORDER
    containerStroke.Parent = container

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, -40, 0, 50)
    header.Position = UDim2.fromOffset(20, 20)
    header.Parent = container

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(0.6, 1)
    title.Text = "🏝️ Island Development"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 30
    title.TextColor3 = COLORS.TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.AutoButtonColor = true
    closeButton.BackgroundColor3 = COLORS.ACCENT
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Text = "X"
    closeButton.Size = UDim2.fromOffset(44, 44)
    closeButton.Position = UDim2.new(1, -44, 0, 3)
    closeButton.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        self:Hide()
    end)

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.fromOffset(20, 80)
    content.Size = UDim2.new(1, -40, 1, -120)
    content.BackgroundTransparency = 1
    content.Parent = container

    local categoryFrame = Instance.new("Frame")
    categoryFrame.Name = "CategoryFrame"
    categoryFrame.Size = UDim2.new(0, 200, 1, 0)
    categoryFrame.BackgroundColor3 = COLORS.PANEL
    categoryFrame.BorderSizePixel = 0
    categoryFrame.Parent = content
    self.categoryFrame = categoryFrame

    local categorySizeConstraint = Instance.new("UISizeConstraint")
    categorySizeConstraint.MinSize = Vector2.new(180, 0)
    categorySizeConstraint.MaxSize = Vector2.new(220, math.huge)
    categorySizeConstraint.Parent = categoryFrame

    local categoryCorner = Instance.new("UICorner")
    categoryCorner.CornerRadius = UDim.new(0, 12)
    categoryCorner.Parent = categoryFrame

    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.Padding = UDim.new(0, 6)
    categoryLayout.FillDirection = Enum.FillDirection.Vertical
    categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    categoryLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    categoryLayout.Parent = categoryFrame

    local projectFrame = Instance.new("Frame")
    projectFrame.Name = "ProjectFrame"
    projectFrame.Size = UDim2.new(0, 360, 1, 0)
    projectFrame.Position = UDim2.fromOffset(220, 0)
    projectFrame.BackgroundColor3 = COLORS.PANEL
    projectFrame.BorderSizePixel = 0
    projectFrame.Parent = content
    self.projectFrame = projectFrame

    local projectSizeConstraint = Instance.new("UISizeConstraint")
    projectSizeConstraint.MinSize = Vector2.new(300, 0)
    projectSizeConstraint.MaxSize = Vector2.new(400, math.huge)
    projectSizeConstraint.Parent = projectFrame

    local projectCorner = Instance.new("UICorner")
    projectCorner.CornerRadius = UDim.new(0, 12)
    projectCorner.Parent = projectFrame

    local projectList = Instance.new("ScrollingFrame")
    projectList.Name = "ProjectList"
    projectList.BackgroundTransparency = 1
    projectList.BorderSizePixel = 0
    projectList.Size = UDim2.new(1, -20, 1, -20)
    projectList.Position = UDim2.fromOffset(10, 10)
    projectList.ScrollBarThickness = 6
    projectList.CanvasSize = UDim2.new(0, 0, 0, 0)
    projectList.Parent = projectFrame
    self.projectList = projectList

    local projectLayout = Instance.new("UIListLayout")
    projectLayout.Padding = UDim.new(0, 6)
    projectLayout.FillDirection = Enum.FillDirection.Vertical
    projectLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    projectLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    projectLayout.SortOrder = Enum.SortOrder.LayoutOrder
    projectLayout.Parent = projectList

    local detailFrame = Instance.new("Frame")
    detailFrame.Name = "DetailFrame"
    detailFrame.Size = UDim2.new(1, -600, 1, 0) -- Responsive: takes remaining space
    detailFrame.Position = UDim2.fromOffset(600, 0)
    detailFrame.BackgroundColor3 = COLORS.PANEL
    detailFrame.BorderSizePixel = 0
    detailFrame.Parent = content
    self.detailFrame = detailFrame

    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 12)
    detailCorner.Parent = detailFrame

    local detailPadding = Instance.new("UIPadding")
    detailPadding.PaddingTop = UDim.new(0, 12)
    detailPadding.PaddingBottom = UDim.new(0, 12)
    detailPadding.PaddingLeft = UDim.new(0, 16)
    detailPadding.PaddingRight = UDim.new(0, 16)
    detailPadding.Parent = detailFrame

    local detailTitle = Instance.new("TextLabel")
    detailTitle.Name = "DetailTitle"
    detailTitle.BackgroundTransparency = 1
    detailTitle.Font = Enum.Font.GothamBold
    detailTitle.TextSize = 24
    detailTitle.TextColor3 = COLORS.TEXT
    detailTitle.TextXAlignment = Enum.TextXAlignment.Left
    detailTitle.Size = UDim2.new(1, 0, 0, 30)
    detailTitle.Text = "Select a project"
    detailTitle.Parent = detailFrame
    self.detailTitle = detailTitle

    local detailDescription = Instance.new("TextLabel")
    detailDescription.Name = "DetailDescription"
    detailDescription.BackgroundTransparency = 1
    detailDescription.Font = Enum.Font.Gotham
    detailDescription.TextSize = 16
    detailDescription.TextColor3 = COLORS.TEXT_SUBTLE
    detailDescription.TextXAlignment = Enum.TextXAlignment.Left
    detailDescription.TextYAlignment = Enum.TextYAlignment.Top
    detailDescription.TextWrapped = true
    detailDescription.Size = UDim2.new(1, 0, 0, 80)
    detailDescription.Position = UDim2.fromOffset(0, 36)
    detailDescription.Text = "Gather materials and work together to unlock island amenities."
    detailDescription.Parent = detailFrame
    self.detailDescription = detailDescription

    local requirementLabel = createSectionLabel("Requirements", detailFrame)
    requirementLabel.Position = UDim2.fromOffset(0, 120)

    local requirementsText = Instance.new("TextLabel")
    requirementsText.Name = "RequirementsText"
    requirementsText.BackgroundTransparency = 1
    requirementsText.Font = Enum.Font.Gotham
    requirementsText.TextSize = 16
    requirementsText.TextColor3 = COLORS.TEXT
    requirementsText.TextXAlignment = Enum.TextXAlignment.Left
    requirementsText.TextYAlignment = Enum.TextYAlignment.Top
    requirementsText.TextWrapped = true
    requirementsText.Size = UDim2.new(1, 0, 0, 60)
    requirementsText.Position = UDim2.fromOffset(0, 150)
    requirementsText.Text = "-"
    requirementsText.Parent = detailFrame
    self.requirementsText = requirementsText

    local rewardsLabel = createSectionLabel("Rewards", detailFrame)
    rewardsLabel.Position = UDim2.fromOffset(0, 220)

    local rewardsText = Instance.new("TextLabel")
    rewardsText.Name = "RewardsText"
    rewardsText.BackgroundTransparency = 1
    rewardsText.Font = Enum.Font.Gotham
    rewardsText.TextSize = 16
    rewardsText.TextColor3 = COLORS.TEXT
    rewardsText.TextXAlignment = Enum.TextXAlignment.Left
    rewardsText.TextYAlignment = Enum.TextYAlignment.Top
    rewardsText.TextWrapped = true
    rewardsText.Size = UDim2.new(1, 0, 0, 40)
    rewardsText.Position = UDim2.fromOffset(0, 250)
    rewardsText.Text = "-"
    rewardsText.Parent = detailFrame
    self.rewardsText = rewardsText

    local progressLabel = createSectionLabel("Progress", detailFrame)
    progressLabel.Position = UDim2.fromOffset(0, 300)

    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.BackgroundTransparency = 1
    progressText.Font = Enum.Font.Gotham
    progressText.TextSize = 16
    progressText.TextColor3 = COLORS.TEXT
    progressText.TextXAlignment = Enum.TextXAlignment.Left
    progressText.TextYAlignment = Enum.TextYAlignment.Top
    progressText.TextWrapped = true
    progressText.Size = UDim2.new(1, 0, 0, 40)
    progressText.Position = UDim2.fromOffset(0, 330)
    progressText.Text = "-"
    progressText.Parent = detailFrame
    self.progressText = progressText

    createDivider(detailFrame).Position = UDim2.fromOffset(0, 380)

    local buildButton = Instance.new("TextButton")
    buildButton.Name = "BuildButton"
    buildButton.AutoButtonColor = true
    buildButton.BackgroundColor3 = COLORS.ACCENT
    buildButton.Font = Enum.Font.GothamBold
    buildButton.TextSize = 18
    buildButton.TextColor3 = Color3.new(1, 1, 1)
    buildButton.Size = UDim2.fromOffset(220, 48)
    buildButton.Position = UDim2.fromOffset(0, 400)
    buildButton.Text = "Contribute Materials"
    buildButton.Parent = detailFrame
    self.buildButton = buildButton

    local buildCorner = Instance.new("UICorner")
    buildCorner.CornerRadius = UDim.new(0, 12)
    buildCorner.Parent = buildButton

    buildButton.MouseButton1Click:Connect(function()
        self:_attemptBuild()
    end)

    local feedbackLabel = Instance.new("TextLabel")
    feedbackLabel.Name = "FeedbackLabel"
    feedbackLabel.BackgroundTransparency = 1
    feedbackLabel.Font = Enum.Font.Gotham
    feedbackLabel.TextSize = 14
    feedbackLabel.TextColor3 = COLORS.TEXT_SUBTLE
    feedbackLabel.TextXAlignment = Enum.TextXAlignment.Left
    feedbackLabel.Text = ""
    feedbackLabel.Position = UDim2.fromOffset(0, 460)
    feedbackLabel.Size = UDim2.new(1, 0, 0, 24)
    feedbackLabel.Parent = detailFrame
    self.feedbackLabel = feedbackLabel

    self:_buildCategoryButtons()
    self:_renderProjectList()
end

function BuildingGUI:_buildCategoryButtons()
    for _, child in ipairs(self.categoryFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") or child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = self.categoryFrame

    for index, category in ipairs(self.categories) do
        local button = Instance.new("TextButton")
        button.Name = category.id .. "Button"
        button.AutoButtonColor = false
        button.BackgroundColor3 = COLORS.PANEL
        button.TextColor3 = COLORS.TEXT
        button.Font = Enum.Font.GothamBold
        button.TextSize = 18
        button.Size = UDim2.new(1, -24, 0, 50)
        button.TextWrapped = true
        button.Text = category.name
        button.LayoutOrder = index
        button.Parent = self.categoryFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = button

        button.MouseButton1Click:Connect(function()
            self.selectedCategory = category.id
            self:_renderProjectList()
        end)
    end
end

local function statusLabelText(status: string, delivered: number, required: number)
    if status == "completed" then
        return string.format("Completed (%d/%d)", required, required)
    elseif status == "repeatable" then
        return string.format("Delivered %d time(s)", delivered)
    elseif status == "in-progress" then
        return string.format("In progress (%d/%d)", delivered, required)
    elseif status == "locked" then
        return "Locked"
    else
        return string.format("Available (%d/%d)", delivered, required)
    end
end

function BuildingGUI:_renderProjectList()
    for _, child in ipairs(self.projectList:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local projects = BuildingCatalog.getProjectsForCategory(self.selectedCategory)
    if #projects == 0 then
        local empty = Instance.new("TextLabel")
        empty.BackgroundTransparency = 1
        empty.TextColor3 = COLORS.TEXT_SUBTLE
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 16
        empty.TextWrapped = true
        empty.Size = UDim2.new(1, -20, 0, 80)
        empty.Text = "No projects available in this category yet."
        empty.Parent = self.projectList
        self.projectList.CanvasSize = UDim2.fromOffset(0, 80)
        return
    end

    local listHeight = 0
    for index, project in ipairs(projects) do
        local progressEntry = self:_getProgressForProject(project)
        local delivered = progressEntry.delivered or 0
        local required = 1
        if project.requirements and project.requirements.deliveries then
            required = project.requirements.deliveries
        end

        local status = progressEntry.status or "available"
        local statusColor = STATUS_COLORS[status] or COLORS.TEXT_SUBTLE
        -- statusColor values used for stroke below, no need for manual RGB conversion
        local button = Instance.new("TextButton")
        button.Name = project.id .. "Entry"
        button.AutoButtonColor = false
        button.Size = UDim2.new(1, -8, 0, 70)
        button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = "" -- Clear default text
        button.LayoutOrder = index
        button.Parent = self.projectList
        button:SetAttribute("ProjectId", project.id)
        
        -- Project name label (bold)
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, -16, 0, 30)
        nameLabel.Position = UDim2.fromOffset(8, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = project.name
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 16
        nameLabel.TextColor3 = COLORS.TEXT
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Top
        nameLabel.TextWrapped = true
        nameLabel.Parent = button
        
        -- Status label (colored)
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(1, -16, 0, 25)
        statusLabel.Position = UDim2.fromOffset(8, 38)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = statusLabelText(status, delivered, required)
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.TextSize = 14
        statusLabel.TextColor3 = statusColor
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.TextYAlignment = Enum.TextYAlignment.Top
        statusLabel.Parent = button

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Thickness = 2
        stroke.Color = STATUS_COLORS[status] or COLORS.BORDER
        stroke.Parent = button

        button.MouseButton1Click:Connect(function()
            self.selectedProjectId = project.id
            self:_updateSelectionHighlight()
            self:_updateDetailPanel()
        end)

        listHeight += 76

        if not self.selectedProjectId then
            self.selectedProjectId = project.id
        end
    end

    self.projectList.CanvasSize = UDim2.fromOffset(0, math.max(listHeight, self.projectList.AbsoluteSize.Y))
    self:_updateSelectionHighlight()
    self:_updateDetailPanel()
end

function BuildingGUI:_updateSelectionHighlight()
    for _, child in ipairs(self.projectList:GetChildren()) do
        if child:IsA("TextButton") then
            local projectId = child:GetAttribute("ProjectId")
            if self.selectedProjectId and projectId == self.selectedProjectId then
                child.BackgroundColor3 = Color3.fromRGB(255, 242, 217)
            else
                child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end
end

function BuildingGUI:_getProgressForProject(project)
    if project.scope == "island" then
        return cloneDictionary(
            self.progress.island[project.id] or { delivered = 0, status = "available", contributions = {} }
        )
    else
        return cloneDictionary(
            self.progress.home[project.id] or { delivered = 0, status = "available", contributions = {} }
        )
    end
end

function BuildingGUI:_updateDetailPanel()
    if not self.selectedProjectId then
        self.detailTitle.Text = "Select a project"
        self.detailDescription.Text = "Gather materials to kickstart island development."
        self.requirementsText.Text = "-"
        self.rewardsText.Text = "-"
        self.progressText.Text = "-"
        self.buildButton.Active = false
        self.buildButton.AutoButtonColor = false
        self.buildButton.BackgroundColor3 = COLORS.LOCKED
        self.buildButton.Text = "Select a project"
        return
    end

    local project = BuildingCatalog.getProject(self.selectedProjectId)
    if not project then
        return
    end

    local progressEntry = self:_getProgressForProject(project)
    local delivered = progressEntry.delivered or 0
    local required = 1
    if project.requirements and project.requirements.deliveries then
        required = project.requirements.deliveries
    end

    self.detailTitle.Text = project.name
    self.detailDescription.Text = project.description

    local requirementLines = {}
    if project.requirements and project.requirements.materials then
        for _, requirement in ipairs(project.requirements.materials) do
            table.insert(requirementLines, "• " .. formatRequirement(requirement))
        end
    else
        table.insert(requirementLines, "• No materials required")
    end
    self.requirementsText.Text = table.concat(requirementLines, "\n")

    local rewards = {}
    if project.rewards and project.rewards.bells then
        table.insert(rewards, string.format("💰 %d Bells", project.rewards.bells))
    end
    if project.rewards and project.rewards.items then
        for _, itemId in ipairs(project.rewards.items) do
            local item = ItemDataFetcher.getItem(itemId)
            local itemName = item and (item.displayName or item.name) or itemId
            table.insert(rewards, "🎁 " .. itemName)
        end
    end
    if #rewards == 0 then
        rewards[1] = "-"
    end
    self.rewardsText.Text = table.concat(rewards, "\n")

    local contributorsCount = 0
    if progressEntry.contributions then
        for _ in pairs(progressEntry.contributions) do
            contributorsCount += 1
        end
    end

    local status = progressEntry.status or "available"
    self.progressText.Text =
        string.format("Status: %s\nContributors: %d", statusLabelText(status, delivered, required), contributorsCount)

    local enabled = status == "available" or status == "in-progress" or status == "repeatable"
    self.buildButton.Active = enabled
    self.buildButton.AutoButtonColor = enabled
    self.buildButton.BackgroundColor3 = enabled and COLORS.ACCENT or COLORS.LOCKED
    if status == "completed" and not project.repeatable then
        self.buildButton.Text = "Completed"
    elseif status == "locked" then
        self.buildButton.Text = "Locked"
    elseif project.repeatable then
        self.buildButton.Text = "Deliver Materials"
    else
        self.buildButton.Text = delivered > 0 and "Finish Project" or "Contribute Materials"
    end
end

function BuildingGUI:_attemptBuild()
    if not self.selectedProjectId then
        return
    end

    local project = BuildingCatalog.getProject(self.selectedProjectId)
    if not project then
        return
    end

    local progressEntry = self:_getProgressForProject(project)
    local status = progressEntry.status or "available"
    local allowed = status == "available" or status == "in-progress" or status == "repeatable"

    if not allowed then
        self:_showFeedback("Project is currently locked.", true)
        return
    end

    if self.requestRemote then
        self.requestRemote:FireServer({
            action = "build",
            projectId = project.id,
        })
    end
end

function BuildingGUI:_showFeedback(message: string, isError: boolean)
    if not self.feedbackLabel then
        return
    end

    self.feedbackLabel.Text = message
    self.feedbackLabel.TextColor3 = isError and COLORS.ERROR or COLORS.TEXT
    self.feedbackTicker += 1
    local currentTick = self.feedbackTicker

    task.delay(3, function()
        if self.feedbackTicker == currentTick then
            self.feedbackLabel.Text = ""
        end
    end)
end

function BuildingGUI:_connectRemotes()
    if not self.progressRemote then
        return
    end

    self.progressRemote.OnClientEvent:Connect(function(action, payload)
        if action == "sync" then
            self.progress.island = payload and payload.island or {}
            self.progress.home = payload and payload.home or {}
            self:_renderProjectList()
        elseif action == "islandUpdate" then
            if payload and payload.island then
                for projectId, progress in pairs(payload.island) do
                    self.progress.island[projectId] = progress
                end
                self:_renderProjectList()
            end
        elseif action == "homeUpdate" then
            if payload and payload.home then
                for projectId, progress in pairs(payload.home) do
                    self.progress.home[projectId] = progress
                end
                self:_renderProjectList()
            end
        elseif action == "feedback" then
            if payload and payload.message then
                self:_showFeedback(payload.message, payload.isError)
            end
        end
    end)
end

function BuildingGUI:Show()
    if self.visible then
        return
    end

    self.visible = true
    if self.gui then
        self.gui.Enabled = true
    end

    if self.requestRemote then
        self.requestRemote:FireServer({ action = "sync" })
    end
end

function BuildingGUI:Hide()
    if not self.visible then
        return
    end

    self.visible = false
    if self.gui then
        self.gui.Enabled = false
    end
end

function BuildingGUI:isVisible()
    return self.visible
end

return BuildingGUI
