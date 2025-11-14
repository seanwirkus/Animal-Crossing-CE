--[[
	Minimap.luau
	
	Minimap system for Animal Crossing CE
	Shows island overview with player location
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Minimap = {}
Minimap.__index = Minimap

local LocalPlayer = Players.LocalPlayer

function Minimap.new()
    local self = setmetatable({}, Minimap)

    self.gui = nil
    self.isVisible = false
    self.updateConnection = nil

    return self
end

function Minimap:createGUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Check if GUI already exists
    local existingGui = playerGui:FindFirstChild("MinimapGUI")
    if existingGui then
        existingGui:Destroy()
    end

    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MinimapGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 50
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(1, 0) -- Top-right
    container.Position = UDim2.new(1, -20, 0, 20)
    container.Size = UDim2.new(0, 300, 0, 300)
    container.BackgroundColor3 = Color3.fromRGB(240, 248, 255)
    container.BackgroundTransparency = 0.1
    container.BorderSizePixel = 0
    container.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(65, 120, 160)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = container

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "🗺️ Island Map"
    title.TextColor3 = Color3.fromRGB(65, 120, 160)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = container

    -- Map view (simplified - shows player position)
    local mapFrame = Instance.new("Frame")
    mapFrame.Name = "MapFrame"
    mapFrame.Size = UDim2.new(1, -20, 1, -50)
    mapFrame.Position = UDim2.new(0, 10, 0, 40)
    mapFrame.BackgroundColor3 = Color3.fromRGB(92, 159, 115) -- Grass green
    mapFrame.BorderSizePixel = 0
    mapFrame.Parent = container

    local mapCorner = Instance.new("UICorner")
    mapCorner.CornerRadius = UDim.new(0, 8)
    mapCorner.Parent = mapFrame

    -- Player indicator
    local playerDot = Instance.new("Frame")
    playerDot.Name = "PlayerDot"
    playerDot.Size = UDim2.new(0, 12, 0, 12)
    playerDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    playerDot.BorderSizePixel = 0
    playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    playerDot.Position = UDim2.fromScale(0.5, 0.5) -- Center initially
    playerDot.Parent = mapFrame

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 6)
    dotCorner.Parent = playerDot

    local dotStroke = Instance.new("UIStroke")
    dotStroke.Color = Color3.fromRGB(255, 255, 255)
    dotStroke.Thickness = 2
    dotStroke.Parent = playerDot

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 24
    closeBtn.Parent = container

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        self:hide()
    end)

    self.gui = screenGui
    self.mapFrame = mapFrame
    self.playerDot = playerDot

    return screenGui
end

function Minimap:show()
    if not self.gui then
        self:createGUI()
    end

    if self.isVisible then
        return
    end

    self.isVisible = true
    self.gui.Enabled = true

    -- Animate in
    self.gui.Container.Position = UDim2.new(1, 20, 0, 20) -- Start off-screen
    local tween = TweenService:Create(
        self.gui.Container,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(1, -20, 0, 20) }
    )
    tween:Play()

    -- Start updating player position
    self:startUpdating()
end

function Minimap:hide()
    if not self.isVisible or not self.gui then
        return
    end

    self.isVisible = false

    -- Animate out
    local tween = TweenService:Create(
        self.gui.Container,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(1, 20, 0, 20) }
    )
    tween:Play()
    tween.Completed:Wait()

    self.gui.Enabled = false
    self:stopUpdating()
end

function Minimap:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

function Minimap:startUpdating()
    if self.updateConnection then
        return
    end

    -- Simple update: center player dot (for now)
    -- TODO: Add actual island bounds and coordinate mapping
    self.updateConnection = RunService.Heartbeat:Connect(function()
        if not self.isVisible or not LocalPlayer.Character then
            return
        end

        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            -- For now, just keep player centered
            -- In future, map world coordinates to minimap coordinates
            self.playerDot.Position = UDim2.fromScale(0.5, 0.5)
        end
    end)
end

function Minimap:stopUpdating()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
end

-- Singleton instance
local minimapInstance = Minimap.new()

-- Export
return minimapInstance
