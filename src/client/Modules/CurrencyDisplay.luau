--[[
    CurrencyDisplay.luau
    Client-side HUD display for Bells and Nook Miles
    
    TODO: PHASE 1 - DAY 1 PRIORITY
    - Create HUD frame in top-right corner
    - Show Bells icon + amount
    - Show Miles icon + amount
    - Listen to server currency updates
    - Animate when currency changes
    - Add number formatting (1000 → 1,000)
    
    DEPENDS ON: CurrencyManager.luau (server)
    USED BY: init.client.luau
]]

local CurrencyDisplay = {}
CurrencyDisplay.__index = CurrencyDisplay

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local currencyRemote = ReplicatedStorage:WaitForChild("CurrencyEvent")

local BELL_ICON_ASSET = "rbxassetid://140175723274467"
local MILES_ICON_ASSET = "rbxassetid://12966818258"

local function createUIScale(parent: Instance)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = parent
    return scale
end

local function playPulse(scaleObject: UIScale)
    if not scaleObject then
        return
    end

    local grow = TweenService:Create(scaleObject, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = 1.08,
    })
    local shrink = TweenService:Create(scaleObject, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = 1,
    })

    task.spawn(function()
        grow:Play()
        grow.Completed:Wait()
        shrink:Play()
    end)
end

function CurrencyDisplay.new()
    local self = setmetatable({}, CurrencyDisplay)

    self.player = Players.LocalPlayer
    self.gui = nil
    self.bellsLabel = nil
    self.milesLabel = nil
    self.bellsScale = nil
    self.milesScale = nil
    self.connections = {}

    self.currentBells = 0
    self.currentMiles = 0

    self:createGUI()
    self:connectToServer()

    return self
end

function CurrencyDisplay:createGUI()
    local playerGui = self.player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CurrencyHUD"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 15
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    self.gui = screenGui

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.BackgroundTransparency = 1
    container.AnchorPoint = Vector2.new(1, 0)
    container.Position = UDim2.new(1, -24, 0, 20)
    container.Size = UDim2.new(0, 240, 0, 96)
    container.Parent = screenGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    local function createCurrencyFrame(name: string, icon: string, color: Color3, layoutOrder: number)
        local frame = Instance.new("Frame")
        frame.Name = name .. "Frame"
        frame.LayoutOrder = layoutOrder
        frame.Size = UDim2.new(0, 220, 0, 44)
        frame.BackgroundColor3 = color
        frame.BackgroundTransparency = 0.15
        frame.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = color:Lerp(Color3.new(1, 1, 1), 0.5)
        stroke.Thickness = 1.5
        stroke.Transparency = 0.35
        stroke.Parent = frame

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.PaddingTop = UDim.new(0, 6)
        padding.PaddingBottom = UDim.new(0, 6)
        padding.Parent = frame

        local content = Instance.new("Frame")
        content.Name = "Content"
        content.BackgroundTransparency = 1
        content.Size = UDim2.new(1, 0, 1, 0)
        content.Parent = frame

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.FillDirection = Enum.FillDirection.Horizontal
        contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        contentLayout.Padding = UDim.new(0, 8)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = content

        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Name = name .. "Icon"
        iconLabel.BackgroundTransparency = 1
        iconLabel.Size = UDim2.new(0, 32, 0, 32)
        iconLabel.Image = icon
        iconLabel.ScaleType = Enum.ScaleType.Fit
        iconLabel.LayoutOrder = 1
        iconLabel.Parent = content

        local amountLabel = Instance.new("TextLabel")
        amountLabel.Name = name .. "Amount"
        amountLabel.BackgroundTransparency = 1
        amountLabel.Text = "0"
        amountLabel.Font = Enum.Font.GothamSemibold
        amountLabel.TextSize = 26
        amountLabel.TextColor3 = Color3.new(1, 1, 1)
        amountLabel.TextStrokeTransparency = 0.7
        amountLabel.TextXAlignment = Enum.TextXAlignment.Right
        amountLabel.Size = UDim2.new(1, -40, 1, 0)
        amountLabel.LayoutOrder = 2
        amountLabel.Parent = content

        local scale = createUIScale(frame)

        return amountLabel, scale
    end

    self.bellsLabel, self.bellsScale = createCurrencyFrame("Bells", BELL_ICON_ASSET, Color3.fromRGB(255, 170, 64), 1)
    self.milesLabel, self.milesScale = createCurrencyFrame("Miles", MILES_ICON_ASSET, Color3.fromRGB(120, 180, 255), 2)

    self:updateBells(self.currentBells, false)
    self:updateMiles(self.currentMiles, false)
end

function CurrencyDisplay:updateBells(amount: number, animate: boolean)
    self.currentBells = math.max(0, math.floor(amount or 0))
    if self.bellsLabel then
        self.bellsLabel.Text = self:formatNumber(self.currentBells)
    end

    if animate and self.bellsScale then
        playPulse(self.bellsScale)
    end
end

function CurrencyDisplay:updateMiles(amount: number, animate: boolean)
    self.currentMiles = math.max(0, math.floor(amount or 0))
    if self.milesLabel then
        self.milesLabel.Text = self:formatNumber(self.currentMiles)
    end

    if animate and self.milesScale then
        playPulse(self.milesScale)
    end
end

function CurrencyDisplay:connectToServer()
    if not currencyRemote then
        warn("[CurrencyDisplay] CurrencyEvent remote not found")
        return
    end

    local connection = currencyRemote.OnClientEvent:Connect(function(action, data)
        data = data or {}
        if action == "UpdateBells" then
            local amount = tonumber(data.bells)
            if amount == nil then
                amount = self.currentBells
            end
            self:updateBells(amount, data.animate ~= false)
        elseif action == "UpdateMiles" then
            local amount = tonumber(data.miles)
            if amount == nil then
                amount = self.currentMiles
            end
            self:updateMiles(amount, data.animate ~= false)
        end
    end)

    table.insert(self.connections, connection)
end

function CurrencyDisplay:formatNumber(num: number): string
    local sign = ""
    if num < 0 then
        sign = "-"
        num = math.abs(num)
    end

    local integer = math.floor(num + 0.5)
    local str = tostring(integer)
    local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. formatted
end

return CurrencyDisplay
