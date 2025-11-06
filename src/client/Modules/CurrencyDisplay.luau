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

-- TODO: Import services
-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local TweenService = game:GetService("TweenService")

-- TODO: Reference to currency remote
-- local currencyRemote = ReplicatedStorage:WaitForChild("CurrencyEvent")

function CurrencyDisplay.new()
    local self = setmetatable({}, CurrencyDisplay)
    
    -- TODO: Create HUD
    self.gui = nil
    self.bellsLabel = nil
    self.milesLabel = nil
    
    self.currentBells = 0
    self.currentMiles = 0
    
    warn("[CurrencyDisplay] new() NOT IMPLEMENTED")
    
    return self
end

-- TODO: Create the HUD GUI
function CurrencyDisplay:createGUI()
    --[[
    Structure:
    ScreenGui "CurrencyHUD"
        Frame "Container" (top-right, 200x80)
            Frame "BellsFrame"
                ImageLabel "BellIcon"
                TextLabel "BellsAmount"
            Frame "MilesFrame"
                ImageLabel "MilesIcon"
                TextLabel "MilesAmount"
    ]]
    warn("[CurrencyDisplay] createGUI() NOT IMPLEMENTED")
end

-- TODO: Update bells display
function CurrencyDisplay:updateBells(amount: number, animate: boolean)
    -- Format number with commas
    -- Update label
    -- Optionally animate (scale effect)
    warn("[CurrencyDisplay] updateBells() NOT IMPLEMENTED - amount:", amount)
end

-- TODO: Update miles display
function CurrencyDisplay:updateMiles(amount: number, animate: boolean)
    warn("[CurrencyDisplay] updateMiles() NOT IMPLEMENTED - amount:", amount)
end

-- TODO: Listen to server updates
function CurrencyDisplay:connectToServer()
    --[[
    currencyRemote.OnClientEvent:Connect(function(action, data)
        if action == "UpdateBells" then
            self:updateBells(data.bells, true)
        elseif action == "UpdateMiles" then
            self:updateMiles(data.miles, true)
        end
    end)
    ]]
    warn("[CurrencyDisplay] connectToServer() NOT IMPLEMENTED")
end

-- TODO: Format number with commas
function CurrencyDisplay:formatNumber(num: number): string
    -- 1000 → "1,000"
    -- 1000000 → "1,000,000"
    return tostring(num)
end

return CurrencyDisplay
