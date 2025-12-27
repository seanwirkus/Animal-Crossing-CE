--[[
    CurrencyDisplay.luau
    Client-side currency display for Bells and Nook Miles
    
    Searches for BellsLabel and MilesLabel TextLabels anywhere in PlayerGui hierarchy.
    This works with any GUI layout:
    - New embedded: InventoryGUI > InventoryFrame > BellsCount > BellsLabel
    - Old StatsBar: HudGUI > StatsBar > BellsCount > BellsLabel
    
    If StatsBar is re-added and made visible, updates will automatically apply to those labels too.
    
    DEPENDS ON: CurrencyManager.luau (server)
    USED BY: init.client.luau
]]

local CurrencyDisplay = {}
CurrencyDisplay.__index = CurrencyDisplay

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Wait for CurrencyEvent RemoteEvent (with timeout to avoid infinite yield)
local currencyRemote = nil
local _success = pcall(function()
    currencyRemote = ReplicatedStorage:WaitForChild("CurrencyEvent", 5)
end)

if not currencyRemote then
    print("[CurrencyDisplay] ⚠️ CurrencyEvent not found in ReplicatedStorage - creating it")
    currencyRemote = Instance.new("RemoteEvent")
    currencyRemote.Name = "CurrencyEvent"
    currencyRemote.Parent = ReplicatedStorage
end

-- Format number with commas (1000 -> "1,000")
local function formatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then
            break
        end
    end
    return formatted
end

function CurrencyDisplay.new()
    local self = setmetatable({}, CurrencyDisplay)

    self.player = Players.LocalPlayer
    self.hudGui = nil
    self.statsBar = nil
    self.bellsCount = nil
    self.milesCount = nil
    self.connections = {}

    self.currentBells = 0
    self.currentMiles = 0

    self:findGUI()
    self:connectToServer()

    print("[CurrencyDisplay] ✅ Initialized")
    return self
end

function CurrencyDisplay:findGUI()
    local playerGui = self.player:WaitForChild("PlayerGui")

    print("[CurrencyDisplay] 🔍 Searching for currency displays...")

    -- Strategy 1: Look for BellsCount and MilesCount directly anywhere in PlayerGui
    -- This handles the new embedded layout in InventoryFrame
    local function findLabelRecursive(parent, labelName)
        for _, child in ipairs(parent:GetDescendants()) do
            if child.Name == labelName and child:IsA("TextLabel") then
                return child
            end
        end
        return nil
    end

    -- Search for BellsLabel first
    self.bellsCount = findLabelRecursive(playerGui, "BellsLabel")
    if self.bellsCount then
        print("[CurrencyDisplay] ✅ Found BellsLabel at:", self.bellsCount:GetFullName())
    else
        warn("[CurrencyDisplay] ❌ BellsLabel not found in PlayerGui hierarchy!")
        print("[CurrencyDisplay] PlayerGui children:", playerGui:GetChildren())
    end

    -- Search for MilesLabel
    self.milesCount = findLabelRecursive(playerGui, "MilesLabel")
    if self.milesCount then
        print("[CurrencyDisplay] ✅ Found MilesLabel at:", self.milesCount:GetFullName())
    else
        warn("[CurrencyDisplay] ❌ MilesLabel not found in PlayerGui hierarchy!")
    end

    if self.bellsCount and self.milesCount then
        print("[CurrencyDisplay] ✅ Both currency labels found - ready to update!")
    else
        print("[CurrencyDisplay] ⚠️ One or both currency labels not found")
        print("[CurrencyDisplay] bellsCount:", self.bellsCount)
        print("[CurrencyDisplay] milesCount:", self.milesCount)
    end
end

function CurrencyDisplay:updateBells(amount)
    self.currentBells = amount

    if self.bellsCount then
        self.bellsCount.Text = "Bells: " .. formatNumber(amount)
        print("[CurrencyDisplay] ✅ Bells label updated to:", formatNumber(amount))

        -- Pulse animation
        if self.bellsCount:FindFirstChildOfClass("UIScale") then
            local scale = self.bellsCount:FindFirstChildOfClass("UIScale")
            local tween =
                TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Scale = 1.1,
                })
            tween:Play()
            tween.Completed:Connect(function()
                local shrink =
                    TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Scale = 1,
                    })
                shrink:Play()
            end)
        end
    else
        warn("[CurrencyDisplay] ⚠️ Bells label not found! Cannot update to:", amount)
    end
end

function CurrencyDisplay:updateMiles(amount)
    self.currentMiles = amount

    if self.milesCount then
        self.milesCount.Text = "Miles: " .. formatNumber(amount)
        print("[CurrencyDisplay] ✅ Miles label updated to:", formatNumber(amount))

        -- Pulse animation
        if self.milesCount:FindFirstChildOfClass("UIScale") then
            local scale = self.milesCount:FindFirstChildOfClass("UIScale")
            local tween =
                TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Scale = 1.1,
                })
            tween:Play()
            tween.Completed:Connect(function()
                local shrink =
                    TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Scale = 1,
                    })
                shrink:Play()
            end)
        end
    else
        warn("[CurrencyDisplay] ⚠️ Miles label not found! Cannot update to:", amount)
    end
end

function CurrencyDisplay:connectToServer()
    -- Listen for currency updates from server
    local connection = currencyRemote.OnClientEvent:Connect(function(action, data)
        print("[CurrencyDisplay] 📨 Received event - Action:", action, "Data:", data)

        if action == "UpdateBells" then
            self:updateBells(data.bells)
            print("[CurrencyDisplay] 💰 Bells updated:", data.bells)
        elseif action == "UpdateMiles" then
            self:updateMiles(data.miles)
            print("[CurrencyDisplay] ✈️ Miles updated:", data.miles)
        elseif action == "UpdateAll" then
            self:updateBells(data.bells)
            self:updateMiles(data.miles)
            print("[CurrencyDisplay] 💰✈️ Currency updated - Bells:", data.bells, "Miles:", data.miles)
        end
    end)

    table.insert(self.connections, connection)

    -- Request initial currency from server
    print("[CurrencyDisplay] 📤 Requesting initial currency from server...")
    currencyRemote:FireServer("GetCurrency")
end

function CurrencyDisplay:destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    self.connections = {}
end

return CurrencyDisplay
