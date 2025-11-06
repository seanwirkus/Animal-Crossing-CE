--[[
    ShopGUI.luau
    Client-side shop interface for buying/selling items
    
    TODO: PHASE 1 - DAY 4 PRIORITY
    - Create shop GUI with tabs (Buy, Sell, Robux)
    - Buy tab: Browse items, show prices, purchase button
    - Sell tab: Show inventory, show sell prices, sell button
    - Robux tab: Show Game Passes and Developer Products
    - Handle NPC interaction (press E near Tom Nook)
    - Integrate with GUIManager for exclusive visibility
    
    DEPENDS ON: ShopData, CurrencyManager, GamePassManager
    CALLS: ShopManager (server) via RemoteEvent
]]

local ShopGUI = {}
ShopGUI.__index = ShopGUI

-- TODO: Import services
-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local MarketplaceService = game:GetService("MarketplaceService")

function ShopGUI.new()
    local self = setmetatable({}, ShopGUI)
    
    self.gui = nil
    self.currentTab = "Buy"
    self.shopData = {}
    
    warn("[ShopGUI] new() NOT IMPLEMENTED")
    
    return self
end

-- TODO: Create shop GUI
function ShopGUI:createGUI()
    --[[
    Structure:
    ScreenGui "TomNookShop"
        Frame "ShopContainer" (centered, 600x400)
            Frame "Header"
                TextLabel "Tom Nook's Store"
                TextButton "CloseButton"
            Frame "TabButtons"
                TextButton "BuyTab"
                TextButton "SellTab"
                TextButton "RobuxTab"
            ScrollingFrame "ItemList"
                -- Populated dynamically
    ]]
    warn("[ShopGUI] createGUI() NOT IMPLEMENTED")
end

-- TODO: Switch between tabs
function ShopGUI:switchTab(tabName: string)
    -- Hide current tab
    -- Show new tab
    -- Refresh item list
    warn("[ShopGUI] switchTab() NOT IMPLEMENTED - tab:", tabName)
end

-- TODO: Populate buy tab
function ShopGUI:populateBuyTab()
    --[[
    For each shop item:
    - Show sprite
    - Show name
    - Show price in Bells
    - Show "Buy" button
    - Disable if can't afford
    ]]
    warn("[ShopGUI] populateBuyTab() NOT IMPLEMENTED")
end

-- TODO: Populate sell tab
function ShopGUI:populateSellTab()
    --[[
    For each inventory item:
    - Show sprite
    - Show name
    - Show sell price (70% of buy price)
    - Show "Sell" button
    - Show count if > 1
    Add "Sell All Fish" button
    Add "Sell All Bugs" button
    ]]
    warn("[ShopGUI] populateSellTab() NOT IMPLEMENTED")
end

-- TODO: Handle purchase
function ShopGUI:buyItem(itemId: string)
    -- Validate price
    -- Fire to server
    -- Wait for response
    -- Show success/error message
    warn("[ShopGUI] buyItem() NOT IMPLEMENTED - itemId:", itemId)
end

-- TODO: Handle sell
function ShopGUI:sellItem(itemId: string, count: number)
    -- Fire to server
    -- Wait for response
    -- Show success message
    warn("[ShopGUI] sellItem() NOT IMPLEMENTED - itemId:", itemId, "count:", count)
end

-- TODO: Show/hide shop
function ShopGUI:toggle()
    warn("[ShopGUI] toggle() NOT IMPLEMENTED")
end

return ShopGUI
