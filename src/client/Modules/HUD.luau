-- HUD.luau
-- Manages the HUD display with time, date, and day labels
-- Finds or creates HudGUI with TimeFrame, TimeLabel, DateLabel, and DayLabel
-- Also handles notification badges and delivery indicators

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HUD = {}
HUD.__index = HUD

-- Notification badge colors (iPhone style)
local BADGE_COLOR = Color3.fromRGB(255, 59, 48) -- Apple red
local BADGE_TEXT_COLOR = Color3.new(1, 1, 1)

-- Day names for Animal Crossing style (abbreviated)
local DAY_NAMES = {
    "Sun.",
    "Mon.",
    "Tues.",
    "Wed.",
    "Thurs.",
    "Fri.",
    "Sat.",
}

function HUD.new()
    local self = setmetatable({}, HUD)

    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")

    self.hudGui = nil
    self.timeFrame = nil
    self.timeLabel = nil
    self.dateLabel = nil
    self.dayLabel = nil
    self.connection = nil

    -- Notification system
    self.notificationFrame = nil
    self.deliveryBadge = nil
    self.deliveryIndicator = nil
    self.pendingDeliveries = 0
    self.deliveryRemote = nil

    self:_findOrCreateGUI()
    self:_createNotificationBadges()
    self:_createDeliveryIndicator()
    self:_setupDeliveryListener()
    self:_startUpdating()

    print("[HUD] ✅ HUD system initialized with notifications")
    return self
end

function HUD:_findOrCreateGUI()
    -- Wait a moment for GUI to load if it exists in Roblox
    task.wait(0.5)

    -- Try to find existing HudGUI
    self.hudGui = self.playerGui:FindFirstChild("HudGUI")

    if not self.hudGui then
        -- Wait a bit more and try again
        task.wait(0.5)
        self.hudGui = self.playerGui:FindFirstChild("HudGUI")
    end

    if not self.hudGui then
        -- Create new HudGUI only if it doesn't exist
        self.hudGui = Instance.new("ScreenGui")
        self.hudGui.Name = "HudGUI"
        self.hudGui.ResetOnSpawn = false
        self.hudGui.DisplayOrder = 5
        self.hudGui.Parent = self.playerGui
        print("[HUD] Created new HudGUI (no existing one found)")
    else
        print("[HUD] ✅ Found existing HudGUI!")
    end

    -- Find existing TimeFrame (don't create if it exists)
    self.timeFrame = self.hudGui:FindFirstChild("TimeFrame")

    if not self.timeFrame then
        -- Only create if it doesn't exist
        self.timeFrame = Instance.new("Frame")
        self.timeFrame.Name = "TimeFrame"
        self.timeFrame.Size = UDim2.new(0, 200, 0, 80)
        self.timeFrame.Position = UDim2.new(1, -220, 0, 20) -- Top right
        self.timeFrame.BackgroundColor3 = Color3.fromRGB(60, 50, 40)
        self.timeFrame.BackgroundTransparency = 0.3
        self.timeFrame.BorderSizePixel = 0

        -- Add rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = self.timeFrame

        -- Add border
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(120, 100, 80)
        stroke.Thickness = 2
        stroke.Parent = self.timeFrame

        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.PaddingTop = UDim.new(0, 8)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.Parent = self.timeFrame

        -- Add layout
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 4)
        layout.Parent = self.timeFrame

        self.timeFrame.Parent = self.hudGui
        print("[HUD] Created TimeFrame")
    else
        print("[HUD] ✅ Found existing TimeFrame!")
    end

    -- Find labels by searching all descendants of TimeFrame
    -- They might be in a DayDate frame or directly in TimeFrame
    local function findLabelInFrame(frame, labelName)
        if not frame then
            return nil
        end
        -- Search direct children first
        local found = frame:FindFirstChild(labelName)
        if found and found:IsA("TextLabel") then
            return found
        end

        -- Search all descendants
        for _, descendant in ipairs(frame:GetDescendants()) do
            if descendant.Name == labelName and descendant:IsA("TextLabel") then
                return descendant
            end
        end
        return nil
    end

    -- Store findLabelInFrame function for later use
    self.findLabelInFrame = findLabelInFrame

    self.dayLabel = findLabelInFrame(self.timeFrame, "DayLabel")
    self.dateLabel = findLabelInFrame(self.timeFrame, "DateLabel")
    self.timeLabel = findLabelInFrame(self.timeFrame, "TimeLabel")

    -- Print what we found
    print("[HUD] Found labels:")
    print("[HUD]   DayLabel:", self.dayLabel and self.dayLabel.Name or "NOT FOUND")
    print("[HUD]   DateLabel:", self.dateLabel and self.dateLabel.Name or "NOT FOUND")
    print("[HUD]   TimeLabel:", self.timeLabel and self.timeLabel.Name or "NOT FOUND")

    -- If labels not found, print all children of TimeFrame for debugging
    if not self.dayLabel or not self.dateLabel or not self.timeLabel then
        print("[HUD] TimeFrame children:")
        for _, child in ipairs(self.timeFrame:GetChildren()) do
            print("[HUD]   -", child.Name, "(" .. child.ClassName .. ")")
            if child:IsA("Frame") then
                for _, subChild in ipairs(child:GetChildren()) do
                    print("[HUD]     -", subChild.Name, "(" .. subChild.ClassName .. ")")
                end
            end
        end
    end

    -- Ensure GUI is enabled
    self.hudGui.Enabled = true
end

--[[
    Create iPhone-style notification badges
]]
function HUD:_createNotificationBadges()
    if not self.hudGui then return end

    -- Create a notification container in bottom right
    self.notificationFrame = Instance.new("Frame")
    self.notificationFrame.Name = "NotificationFrame"
    self.notificationFrame.Size = UDim2.new(0, 160, 0, 28)
    self.notificationFrame.AnchorPoint = Vector2.new(1, 1)
    self.notificationFrame.Position = UDim2.new(1, -16, 1, -16)
    self.notificationFrame.BackgroundTransparency = 1
    self.notificationFrame.Parent = self.hudGui

    -- Create delivery notification badge (red pill with text)
    self.deliveryBadge = self:_createBadge("DeliveryBadge", "0")
    self.deliveryBadge.Position = UDim2.new(0, 0, 0, 0)
    self.deliveryBadge.Visible = false -- Hidden until deliveries arrive
    self.deliveryBadge.Parent = self.notificationFrame

    print("[HUD] ✅ Notification badges created")
end

--[[
    Create a single badge with a number
]]
function HUD:_createBadge(name, initialCount)
    local badge = Instance.new("Frame")
    badge.Name = name
    badge.Size = UDim2.new(0, 160, 0, 28)
    badge.BackgroundColor3 = BADGE_COLOR
    badge.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14) -- Pill shape
    corner.Parent = badge

    -- White border for pop
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Thickness = 2
    stroke.Parent = badge

    -- Count text
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.fromScale(1, 1)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = initialCount
    countLabel.TextColor3 = BADGE_TEXT_COLOR
    countLabel.TextSize = 12
    countLabel.Font = Enum.Font.GothamBold
    countLabel.Parent = badge

    return badge
end

--[[
    Create delivery indicator (airplane icon with animation)
]]
function HUD:_createDeliveryIndicator()
    if not self.hudGui then return end

    -- Container for delivery indicator
    self.deliveryIndicator = Instance.new("Frame")
    self.deliveryIndicator.Name = "DeliveryIndicator"
    self.deliveryIndicator.Size = UDim2.new(0, 220, 0, 50)
    self.deliveryIndicator.Position = UDim2.new(0.5, -110, 0, 20)
    self.deliveryIndicator.AnchorPoint = Vector2.new(0, 0)
    self.deliveryIndicator.BackgroundColor3 = Color3.fromRGB(78, 186, 169) -- ACNH teal
    self.deliveryIndicator.BackgroundTransparency = 0.1
    self.deliveryIndicator.BorderSizePixel = 0
    self.deliveryIndicator.Visible = false
    self.deliveryIndicator.Parent = self.hudGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = self.deliveryIndicator

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = self.deliveryIndicator

    -- Plane icon
    local planeIcon = Instance.new("TextLabel")
    planeIcon.Name = "PlaneIcon"
    planeIcon.Size = UDim2.new(0, 40, 0, 40)
    planeIcon.Position = UDim2.new(0, 8, 0.5, -20)
    planeIcon.BackgroundTransparency = 1
    planeIcon.Text = "✈️"
    planeIcon.TextScaled = true
    planeIcon.Font = Enum.Font.GothamBold
    planeIcon.Parent = self.deliveryIndicator

    -- Status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(0, 160, 0, 20)
    statusText.Position = UDim2.new(0, 52, 0, 6)
    statusText.BackgroundTransparency = 1
    statusText.Text = "DAL Delivery Incoming!"
    statusText.TextColor3 = Color3.new(1, 1, 1)
    statusText.TextSize = 14
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Font = Enum.Font.GothamBold
    statusText.Parent = self.deliveryIndicator

    -- Countdown/progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(0, 160, 0, 16)
    progressText.Position = UDim2.new(0, 52, 0, 28)
    progressText.BackgroundTransparency = 1
    progressText.Text = "Arriving soon..."
    progressText.TextColor3 = Color3.fromRGB(220, 255, 250)
    progressText.TextSize = 12
    progressText.TextXAlignment = Enum.TextXAlignment.Left
    progressText.Font = Enum.Font.Gotham
    progressText.Parent = self.deliveryIndicator

    print("[HUD] ✅ Delivery indicator created")
end

--[[
    Setup listener for NookPlane delivery events
]]
function HUD:_setupDeliveryListener()
    local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
    if not remoteEventsFolder then
        print("[HUD] ⚠️ No RemoteEvents folder found")
        return
    end

    self.deliveryRemote = remoteEventsFolder:FindFirstChild("NookPlaneDelivery")
    if not self.deliveryRemote then
        -- Wait for it to be created
        task.spawn(function()
            self.deliveryRemote = remoteEventsFolder:WaitForChild("NookPlaneDelivery", 10)
            if self.deliveryRemote then
                self:_connectDeliveryEvents()
            end
        end)
    else
        self:_connectDeliveryEvents()
    end
end

function HUD:_connectDeliveryEvents()
    if not self.deliveryRemote then return end

    self.deliveryRemote.OnClientEvent:Connect(function(action, data)
        print("[HUD] 📦 Delivery event:", action)

        if action == "DeliveryScheduled" then
            -- Show delivery indicator with countdown
            self:_showDeliveryIncoming(data.arrivalTime, data.items)

        elseif action == "PlaneArriving" then
            -- Update indicator to show plane is arriving
            self:_updateDeliveryStatus("Plane arriving overhead!", "Look up! 🛩️")

        elseif action == "PackagesDropped" then
            -- Show packages dropped notification
            self:_updateDeliveryStatus("Packages dropped!", tostring(data.count) .. " package(s) falling!")
            self:_pulseDeliveryBadge()

        elseif action == "ItemCollected" then
            -- Decrement badge and show collection feedback
            self:_decrementDeliveryBadge()
            self:_showCollectionToast(data.itemId, data.count)

        elseif action == "ItemAutoCollected" then
            -- Item was auto-collected
            self:_decrementDeliveryBadge()
            self:_showCollectionToast(data.itemId, data.count, true)

        elseif action == "DeliveryStatus" then
            -- Update from status request
            if data.hasDeliveries then
                self:_updateDeliveryBadge(#data.items)
                if data.planeActive and data.timeRemaining > 0 then
                    self:_showDeliveryIncoming(data.timeRemaining, data.items)
                end
            else
                self:_hideDeliveryIndicator()
                self:_updateDeliveryBadge(0)
            end
        end
    end)

    -- Request current delivery status
    self.deliveryRemote:FireServer("GetStatus")

    print("[HUD] ✅ Delivery events connected")
end

function HUD:_showDeliveryIncoming(arrivalTime, items)
    if not self.deliveryIndicator then return end

    local itemCount = items and #items or 1
    self.pendingDeliveries = itemCount

    -- Update and show badge
    self:_updateDeliveryBadge(itemCount)

    -- Show indicator
    self.deliveryIndicator.Visible = true

    local statusText = self.deliveryIndicator:FindFirstChild("StatusText")
    local progressText = self.deliveryIndicator:FindFirstChild("ProgressText")

    if statusText then
        statusText.Text = "DAL Delivery Incoming!"
    end

    -- Start countdown
    local startTime = tick()
    local countdownConnection
    countdownConnection = RunService.Heartbeat:Connect(function()
        if not self.deliveryIndicator or not self.deliveryIndicator.Visible then
            countdownConnection:Disconnect()
            return
        end

        local elapsed = tick() - startTime
        local remaining = math.max(0, arrivalTime - elapsed)

        if progressText then
            if remaining > 0 then
                progressText.Text = string.format("Arriving in %d seconds...", math.ceil(remaining))
            else
                progressText.Text = "Arriving now!"
                task.wait(3)
                self:_hideDeliveryIndicator()
                countdownConnection:Disconnect()
            end
        end
    end)

    -- Animate plane icon
    self:_animatePlaneIcon()
end

function HUD:_animatePlaneIcon()
    if not self.deliveryIndicator then return end

    local planeIcon = self.deliveryIndicator:FindFirstChild("PlaneIcon")
    if not planeIcon then return end

    -- Subtle bobbing animation
    task.spawn(function()
        while self.deliveryIndicator and self.deliveryIndicator.Visible do
            local tween = TweenService:Create(planeIcon, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0, 8, 0.5, -24)
            })
            tween:Play()
            tween.Completed:Wait()

            if not self.deliveryIndicator or not self.deliveryIndicator.Visible then break end

            local tweenBack = TweenService:Create(planeIcon, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0, 8, 0.5, -16)
            })
            tweenBack:Play()
            tweenBack.Completed:Wait()
        end
    end)
end

function HUD:_updateDeliveryStatus(status, progress)
    if not self.deliveryIndicator then return end

    local statusText = self.deliveryIndicator:FindFirstChild("StatusText")
    local progressText = self.deliveryIndicator:FindFirstChild("ProgressText")

    if statusText then statusText.Text = status end
    if progressText then progressText.Text = progress end
end

function HUD:_hideDeliveryIndicator()
    if not self.deliveryIndicator then return end

    -- Fade out
    local tween = TweenService:Create(self.deliveryIndicator, TweenInfo.new(0.3), {
        BackgroundTransparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function()
        if self.deliveryIndicator then
            self.deliveryIndicator.Visible = false
            self.deliveryIndicator.BackgroundTransparency = 0.1
        end
    end)
end

function HUD:_updateDeliveryBadge(count)
    if not self.deliveryBadge then return end

    local countLabel = self.deliveryBadge:FindFirstChild("CountLabel")
    if countLabel then
        if count == 1 then
            countLabel.Text = "1 Notification"
        else
            countLabel.Text = tostring(count) .. " Notifications"
        end
    end

    self.pendingDeliveries = count
    self.deliveryBadge.Visible = count > 0

    -- Pulse animation when count increases
    if count > 0 then
        self:_pulseDeliveryBadge()
    end
end

function HUD:_decrementDeliveryBadge()
    self.pendingDeliveries = math.max(0, self.pendingDeliveries - 1)
    self:_updateDeliveryBadge(self.pendingDeliveries)
end

function HUD:_pulseDeliveryBadge()
    if not self.deliveryBadge then return end

    -- Pop animation
    local originalSize = self.deliveryBadge.Size

    local growTween = TweenService:Create(self.deliveryBadge, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 170, 0, 32)
    })
    growTween:Play()

    growTween.Completed:Connect(function()
        local shrinkTween = TweenService:Create(self.deliveryBadge, TweenInfo.new(0.1), {
            Size = originalSize
        })
        shrinkTween:Play()
    end)
end

function HUD:_showCollectionToast(itemId, count, autoCollected)
    if not self.hudGui then return end

    -- Create toast notification
    local toast = Instance.new("Frame")
    toast.Name = "CollectionToast"
    toast.Size = UDim2.new(0, 250, 0, 60)
    toast.Position = UDim2.new(0.5, -125, 1, 0) -- Start below screen
    toast.AnchorPoint = Vector2.new(0, 0)
    toast.BackgroundColor3 = Color3.fromRGB(78, 186, 169)
    toast.BackgroundTransparency = 0.1
    toast.BorderSizePixel = 0
    toast.Parent = self.hudGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Thickness = 2
    stroke.Parent = toast

    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Text = "📦"
    icon.TextScaled = true
    icon.Parent = toast

    -- Text
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0, 180, 0, 40)
    text.Position = UDim2.new(0, 55, 0.5, -20)
    text.BackgroundTransparency = 1
    text.Text = autoCollected and "Auto-collected!" or "Item collected!"
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextSize = 16
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Font = Enum.Font.GothamBold
    text.Parent = toast

    local subText = Instance.new("TextLabel")
    subText.Size = UDim2.new(0, 180, 0, 16)
    subText.Position = UDim2.new(0, 55, 0.5, 8)
    subText.BackgroundTransparency = 1
    subText.Text = string.format("%s x%d", itemId or "Item", count or 1)
    subText.TextColor3 = Color3.fromRGB(220, 255, 250)
    subText.TextSize = 12
    subText.TextXAlignment = Enum.TextXAlignment.Left
    subText.Font = Enum.Font.Gotham
    subText.Parent = toast

    -- Animate in
    local slideIn = TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -125, 1, -80)
    })
    slideIn:Play()

    -- Auto dismiss after 3 seconds
    task.spawn(function()
        task.wait(3)
        if toast.Parent then
            local slideOut = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -125, 1, 0)
            })
            slideOut:Play()
            slideOut.Completed:Connect(function()
                toast:Destroy()
            end)
        end
    end)
end

function HUD:_getNow()
    return os.date("*t", os.time())
end

function HUD:_formatTime(now)
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

function HUD:_formatDate(now)
    local monthNames = {
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
    }

    return string.format("%s %d", monthNames[now.month or 1], now.day or 1)
end

function HUD:_getDayOfWeek(now)
    return DAY_NAMES[now.wday or 1]
end

function HUD:_update()
    -- Re-find labels in case they loaded late (retry up to 10 times)
    if not self.timeLabel or not self.dateLabel or not self.dayLabel then
        if self.timeFrame and self.findLabelInFrame then
            if not self.timeLabel then
                self.timeLabel = self.findLabelInFrame(self.timeFrame, "TimeLabel")
            end
            if not self.dateLabel then
                self.dateLabel = self.findLabelInFrame(self.timeFrame, "DateLabel")
            end
            if not self.dayLabel then
                self.dayLabel = self.findLabelInFrame(self.timeFrame, "DayLabel")
            end

            -- If we just found them, log it
            if self.timeLabel and self.dateLabel and self.dayLabel then
                print("[HUD] ✅ Found all labels after retry!")
            end
        end
    end

    if not self.timeLabel or not self.dateLabel or not self.dayLabel then
        -- Don't spam warnings, just silently return
        return
    end

    local now = self:_getNow()

    -- Update labels
    self.timeLabel.Text = self:_formatTime(now)
    self.dateLabel.Text = self:_formatDate(now)
    self.dayLabel.Text = self:_getDayOfWeek(now)
end

function HUD:_startUpdating()
    -- Update immediately
    self:_update()

    -- Update every second
    self.connection = RunService.Heartbeat:Connect(function()
        -- Only update time every second (not every frame)
        local currentTime = tick()
        if not self._lastUpdate or (currentTime - self._lastUpdate) >= 1 then
            self._lastUpdate = currentTime
            self:_update()
        end
    end)
end

function HUD:Destroy()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    -- Clean up notification UI
    if self.notificationFrame then
        self.notificationFrame:Destroy()
    end
    if self.deliveryIndicator then
        self.deliveryIndicator:Destroy()
    end
end

-- Public method to manually trigger delivery notification (for testing)
function HUD:TestDeliveryNotification()
    self:_showDeliveryIncoming(15, {{itemId = "test_item", count = 1}})
end

-- Public method to update notification badge from external sources
function HUD:SetDeliveryCount(count)
    self:_updateDeliveryBadge(count)
end

return HUD
