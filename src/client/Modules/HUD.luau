-- HUD.luau
-- Manages the HUD display with time, date, and day labels
-- Finds or creates HudGUI with TimeFrame, TimeLabel, DateLabel, and DayLabel

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local HUD = {}
HUD.__index = HUD

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

    self:_findOrCreateGUI()
    self:_startUpdating()

    print("[HUD] ✅ HUD system initialized")
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

    -- Create Currency Frame (for bells and miles display)
    local currencyFrame = self.hudGui:FindFirstChild("CurrencyFrame")

    if not currencyFrame then
        currencyFrame = Instance.new("Frame")
        currencyFrame.Name = "CurrencyFrame"
        currencyFrame.Size = UDim2.new(0, 250, 0, 80)
        currencyFrame.Position = UDim2.new(1, -490, 0, 20) -- Next to TimeFrame, to the left
        currencyFrame.BackgroundColor3 = Color3.fromRGB(60, 50, 40)
        currencyFrame.BackgroundTransparency = 0.3
        currencyFrame.BorderSizePixel = 0

        -- Add rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = currencyFrame

        -- Add border
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(120, 100, 80)
        stroke.Thickness = 2
        stroke.Parent = currencyFrame

        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.PaddingTop = UDim.new(0, 8)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.Parent = currencyFrame

        -- Add layout
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 4)
        layout.Parent = currencyFrame

        -- Create Bells display
        local bellsContainer = Instance.new("Frame")
        bellsContainer.Name = "BellsCount"
        bellsContainer.Size = UDim2.new(1, 0, 0, 20)
        bellsContainer.BackgroundTransparency = 1
        bellsContainer.Parent = currencyFrame

        local bellsLabel = Instance.new("TextLabel")
        bellsLabel.Name = "BellsLabel"
        bellsLabel.Size = UDim2.new(1, 0, 1, 0)
        bellsLabel.BackgroundTransparency = 1
        bellsLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
        bellsLabel.TextScaled = true
        bellsLabel.Font = Enum.Font.GothamBold
        bellsLabel.Text = "Bells: 0"
        bellsLabel.Parent = bellsContainer

        -- Create Miles display
        local milesContainer = Instance.new("Frame")
        milesContainer.Name = "MilesCount"
        milesContainer.Size = UDim2.new(1, 0, 0, 20)
        milesContainer.BackgroundTransparency = 1
        milesContainer.Parent = currencyFrame

        local milesLabel = Instance.new("TextLabel")
        milesLabel.Name = "MilesLabel"
        milesLabel.Size = UDim2.new(1, 0, 1, 0)
        milesLabel.BackgroundTransparency = 1
        milesLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        milesLabel.TextScaled = true
        milesLabel.Font = Enum.Font.GothamBold
        milesLabel.Text = "Miles: 0"
        milesLabel.Parent = milesContainer

        currencyFrame.Parent = self.hudGui
        print("[HUD] Created CurrencyFrame with Bells and Miles labels")
    else
        print("[HUD] ✅ Found existing CurrencyFrame!")
    end

    -- Ensure GUI is enabled
    self.hudGui.Enabled = true
end

function HUD:_formatTime(clockTime)
    local hours = math.floor(clockTime)
    local minutes = math.floor((clockTime - hours) * 60)
    local ampm = "AM"

    if hours >= 12 then
        ampm = "PM"
    end

    if hours > 12 then
        hours = hours - 12
    elseif hours == 0 then
        hours = 12
    end

    return string.format("%d:%02d %s", hours, minutes, ampm)
end

function HUD:_formatDate(dayOfYear)
    -- Simple date calculation (approximate)
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

    -- Days per month (approximate, ignoring leap years)
    local daysPerMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

    local day = dayOfYear
    local month = 1

    for i = 1, 12 do
        if day <= daysPerMonth[i] then
            month = i
            break
        end
        day = day - daysPerMonth[i]
    end

    return monthNames[month] .. " " .. tostring(day)
end

function HUD:_getDayOfWeek(dayOfYear)
    -- Simple calculation: cycle through days of week
    local dayIndex = (dayOfYear - 1) % 7
    return DAY_NAMES[dayIndex + 1]
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

    -- Get time from Lighting service
    local clockTime = Lighting.ClockTime or 12.0

    -- Calculate day of year (cycle through year)
    -- Use a simple counter that increments each day
    -- For now, use a day counter based on game time
    local gameTime = tick()
    local daysPassed = math.floor(gameTime / 86400) -- 86400 seconds = 1 day
    local dayOfYear = (daysPassed % 365) + 1 -- Cycle through year

    -- Update labels
    self.timeLabel.Text = self:_formatTime(clockTime)
    self.dateLabel.Text = self:_formatDate(dayOfYear)
    self.dayLabel.Text = self:_getDayOfWeek(dayOfYear)
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
end

return HUD
