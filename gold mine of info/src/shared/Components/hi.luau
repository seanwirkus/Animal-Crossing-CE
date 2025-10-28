--[[
    Hi - Generated from hi.rbxmx
    Reusable GUI component for Animal Crossing game
]]

local TweenService = game:GetService("TweenService")

local Hi = {}
Hi.__index = Hi

function Hi.new(parent)
    local self = setmetatable({}, Hi)
    self._parent = parent
    self._gui = nil
    
    self:_createGUI()
    
    return self
end

function Hi:_createGUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = self._parent
    
    -- Create main frame (based on your hi.rbxmx styling)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 100)
    mainFrame.Position = UDim2.new(1, -320, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0.745, 0.655, 0.271) -- Golden color from your XML
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = mainFrame
    
    -- Bells display
    local bellsFrame = Instance.new("Frame")
    bellsFrame.Name = "BellsFrame"
    bellsFrame.Size = UDim2.new(0, 120, 1, 0)
    bellsFrame.Position = UDim2.new(0, 0, 0, 0)
    bellsFrame.BackgroundTransparency = 1
    bellsFrame.Parent = mainFrame
    
    local bellsIcon = Instance.new("TextLabel")
    bellsIcon.Name = "BellsIcon"
    bellsIcon.Size = UDim2.new(0, 30, 1, 0)
    bellsIcon.Position = UDim2.new(0, 0, 0, 0)
    bellsIcon.BackgroundTransparency = 1
    bellsIcon.Text = "🔔"
    bellsIcon.TextColor3 = Color3.fromRGB(255, 255, 0)
    bellsIcon.TextScaled = true
    bellsIcon.Font = Enum.Font.GothamBold
    bellsIcon.Parent = bellsFrame
    
    local bellsLabel = Instance.new("TextLabel")
    bellsLabel.Name = "BellsLabel"
    bellsLabel.Size = UDim2.new(1, -40, 1, 0)
    bellsLabel.Position = UDim2.new(0, 35, 0, 0)
    bellsLabel.BackgroundTransparency = 1
    bellsLabel.Text = "1,000"
    bellsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    bellsLabel.TextScaled = true
    bellsLabel.Font = Enum.Font.GothamBold
    bellsLabel.TextXAlignment = Enum.TextXAlignment.Left
    bellsLabel.Parent = bellsFrame
    
    -- Miles display
    local milesFrame = Instance.new("Frame")
    milesFrame.Name = "MilesFrame"
    milesFrame.Size = UDim2.new(0, 120, 1, 0)
    milesFrame.Position = UDim2.new(0, 130, 0, 0)
    milesFrame.BackgroundTransparency = 1
    milesFrame.Parent = mainFrame
    
    local milesIcon = Instance.new("TextLabel")
    milesIcon.Name = "MilesIcon"
    milesIcon.Size = UDim2.new(0, 30, 1, 0)
    milesIcon.Position = UDim2.new(0, 0, 0, 0)
    milesIcon.BackgroundTransparency = 1
    milesIcon.Text = "✈️"
    milesIcon.TextColor3 = Color3.fromRGB(0, 150, 255)
    milesIcon.TextScaled = true
    milesIcon.Font = Enum.Font.GothamBold
    milesIcon.Parent = milesFrame
    
    local milesLabel = Instance.new("TextLabel")
    milesLabel.Name = "MilesLabel"
    milesLabel.Size = UDim2.new(1, -40, 1, 0)
    milesLabel.Position = UDim2.new(0, 35, 0, 0)
    milesLabel.BackgroundTransparency = 1
    milesLabel.Text = "500"
    milesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    milesLabel.TextScaled = true
    milesLabel.Font = Enum.Font.GothamBold
    milesLabel.TextXAlignment = Enum.TextXAlignment.Left
    milesLabel.Parent = milesFrame
    
    self._gui = screenGui
    print("[Hi] Stats GUI created with proper styling")
end

function Hi:Show()
    if self._gui then
        self._gui.Enabled = true
        print("[Hi] Shown")
    end
end

function Hi:Hide()
    if self._gui then
        self._gui.Enabled = false
        print("[Hi] Hidden")
    end
end

function Hi:UpdateStats(bells: number, miles: number)
    if not self._gui then return end
    
    -- Update bells display
    local bellsLabel = self._gui:FindFirstChild("MainFrame"):FindFirstChild("BellsFrame"):FindFirstChild("BellsLabel")
    if bellsLabel then
        bellsLabel.Text = tostring(bells)
    end
    
    -- Update miles display
    local milesLabel = self._gui:FindFirstChild("MainFrame"):FindFirstChild("MilesFrame"):FindFirstChild("MilesLabel")
    if milesLabel then
        milesLabel.Text = tostring(miles)
    end
    
    print(`[Hi] Updated stats: {bells} bells, {miles} miles`)
end

function Hi:Destroy()
    if self._gui then
        self._gui:Destroy()
        self._gui = nil
        print("[Hi] Destroyed")
    end
end

return Hi
