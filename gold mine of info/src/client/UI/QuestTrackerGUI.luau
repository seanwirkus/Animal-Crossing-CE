-- QuestTrackerGUI.luau - Client-side quest tracker display for HUD

local QuestTrackerGUI = {}
QuestTrackerGUI.__index = QuestTrackerGUI

-- Colors matching AC theme
local COLORS = {
	primary = Color3.fromRGB(150, 180, 140),  -- Leaf green
	accent = Color3.fromRGB(255, 193, 7),    -- Gold
	text = Color3.fromRGB(40, 40, 40),       -- Dark text
	textLight = Color3.fromRGB(120, 120, 120),
	background = Color3.fromRGB(250, 245, 235),
	success = Color3.fromRGB(100, 200, 100),
}

function QuestTrackerGUI.new(parent)
	local self = setmetatable({}, QuestTrackerGUI)
	self._parent = parent
	self._questFrame = nil
	self._progressLabel = nil
	self._questNameLabel = nil
	self._currentQuest = nil
	
	self:_createUI()
	return self
end

function QuestTrackerGUI:_createUI()
	-- Quest tracker panel (compact, fixed position in HUD)
	local questPanel = Instance.new("Frame")
	questPanel.Name = "QuestTracker"
	questPanel.Size = UDim2.new(0, 280, 0, 90)
	questPanel.Position = UDim2.new(1, -300, 0, 90)  -- Top right, below HUD
	questPanel.BackgroundColor3 = COLORS.background
	questPanel.BorderSizePixel = 1
	questPanel.BorderColor3 = Color3.fromRGB(180, 140, 100)
	questPanel.Visible = false
	questPanel.ZIndex = 50
	questPanel.Parent = self._parent
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = questPanel
	
	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = questPanel
	
	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = questPanel
	
	-- Quest title/name
	local questName = Instance.new("TextLabel")
	questName.Name = "QuestName"
	questName.Size = UDim2.new(1, 0, 0, 20)
	questName.BackgroundTransparency = 1
	questName.Text = "📋 Quest"
	questName.TextSize = 14
	questName.Font = Enum.Font.GothamBold
	questName.TextColor3 = COLORS.primary
	questName.TextXAlignment = Enum.TextXAlignment.Left
	questName.Parent = questPanel
	
	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, 0, 0, 16)
	progressBg.BackgroundColor3 = COLORS.textLight
	progressBg.BackgroundTransparency = 0.7
	progressBg.BorderSizePixel = 0
	progressBg.Parent = questPanel
	
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 4)
	progressCorner.Parent = progressBg
	
	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = COLORS.primary
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = progressFill
	
	-- Progress text
	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Size = UDim2.new(1, 0, 1, 0)
	progressText.BackgroundTransparency = 1
	progressText.Text = "0/3"
	progressText.TextSize = 11
	progressText.Font = Enum.Font.GothamBold
	progressText.TextColor3 = Color3.new(1, 1, 1)
	progressText.Parent = progressBg
	
	self._questFrame = questPanel
	self._questNameLabel = questName
	self._progressFill = progressFill
	self._progressText = progressText
	self._progressBg = progressBg
end

-- Update the quest tracker with quest data
function QuestTrackerGUI:UpdateQuest(questData)
	if not questData then
		self._questFrame.Visible = false
		self._currentQuest = nil
		return
	end
	
	self._currentQuest = questData
	self._questFrame.Visible = true
	
	-- Update quest name
	self._questNameLabel.Text = (questData.icon or "📋") .. " " .. questData.name
	
	-- Update progress bar
	local progress = questData.progress or 0
	local target = questData.target or 1
	local percent = math.min(progress / target, 1)
	
	self._progressFill.Size = UDim2.new(percent, 0, 1, 0)
	self._progressText.Text = progress .. "/" .. target
end

-- Show quest completion notification
function QuestTrackerGUI:ShowCompletionNotification(questData)
	if not questData then return end
	
	-- You can trigger HUD notification here when quest completes
	print("[QuestTracker] Quest completed: " .. questData.name)
end

-- Hide the quest tracker
function QuestTrackerGUI:Hide()
	self._questFrame.Visible = false
	self._currentQuest = nil
end

-- Get current tracked quest
function QuestTrackerGUI:GetCurrentQuest()
	return self._currentQuest
end

return QuestTrackerGUI
