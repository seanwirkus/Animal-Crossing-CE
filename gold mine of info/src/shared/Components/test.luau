--[[
    Test - Generated from test.rbxm
    Reusable GUI component for Animal Crossing game
]]

local TweenService = game:GetService("TweenService")

local Test = {}
Test.__index = Test

function Test.new(parent)
    local self = setmetatable({}, Test)
    self._parent = parent
    self._gui = nil
    
    self:_createGUI()
    
    return self
end

function Test:_createGUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TestGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = self._parent
    
    -- Create main frame
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Test Component"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -20, 0, 100)
    description.Position = UDim2.new(0, 10, 0, 50)
    description.BackgroundTransparency = 1
    description.Text = "This is a test component generated from your .rbxm file. It can be reused across your Animal Crossing game!"
    description.TextColor3 = Color3.fromRGB(255, 255, 255)
    description.TextWrapped = true
    description.Font = Enum.Font.Gotham
    description.Parent = frame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 80, 0, 30)
    closeButton.Position = UDim2.new(0.5, -40, 1, -40)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeButton.Text = "Close"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.Gotham
    closeButton.Parent = frame
    
    -- Add corner rounding to button
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = closeButton
    
    -- Button click handler
    closeButton.MouseButton1Click:Connect(function()
        self:Hide()
    end)
    
    self._gui = screenGui
    print("[Test] GUI created")
end

function Test:Show()
    if self._gui then
        self._gui.Enabled = true
        print("[Test] Shown")
    end
end

function Test:Hide()
    if self._gui then
        self._gui.Enabled = false
        print("[Test] Hidden")
    end
end

function Test:Destroy()
    if self._gui then
        self._gui:Destroy()
        self._gui = nil
        print("[Test] Destroyed")
    end
end

return Test
