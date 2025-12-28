--[[
    ShopData.luau
    Shop items, prices, and unlock conditions
    Loads items from ItemDataFetcher that are available from "Nook Shopping"
    
    USED BY: ShopGUI, ShopManager, NookShoppingGUI
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ItemDataFetcher = require(sharedFolder:WaitForChild("ItemDataFetcher"))

local ShopData = {}

-- Shop categories based on item categories
ShopData.Categories = {
    "All",
    "Tools",
    "Furniture",
    "Housewares",
    "Miscellaneous",
    "Wall-Mounted",
    "Clothing",
    "Special",
}

-- Cache of shop items (items available from Nook Shopping)
ShopData.Items = {}
ShopData.ItemsByCategory = {}

-- Initialize shop items from ItemDataFetcher
-- Items with sprites AND buy prices are purchasable in the shop
local function initializeShopItems()
    print("[ShopData] 🛒 Initializing Nook Shopping items...")

    -- Get all items from ItemDataFetcher
    local allItems = ItemDataFetcher.getAllItems()
    local shopItemCount = 0
    local itemsWithBuyPrice = 0
    local itemsWithSprite = 0

    print("[ShopData] 📦 Processing", #allItems, "total items from ItemDataFetcher...")

    -- Include ALL items that have both a sprite AND a buy price
    -- This makes the shop show all purchasable items from ItemBrowser
    for _, item in ipairs(allItems) do
        -- Check if item has a buy price (required for shop)
        if item.buy and item.buy > 0 then
            itemsWithBuyPrice = itemsWithBuyPrice + 1

            -- Check if item has a sprite (required for display)
            if item.spriteIndex and item.spriteIndex > 0 then
                itemsWithSprite = itemsWithSprite + 1

                local itemId = item.id
                local category = item.category or "Miscellaneous"

                -- Skip placeholder/legacy items
                if category ~= "legacy" and category ~= "placeholder" then
                    ShopData.Items[itemId] = {
                        id = itemId,
                        name = item.name or item.displayName or itemId,
                        category = category,
                        buyPrice = item.buy,
                        sellPrice = item.sell or math.floor(item.buy * 0.25), -- Default to 25% of buy price
                        spriteIndex = item.spriteIndex,
                        description = item.description or "",
                        unlockLevel = item.unlockLevel or 1,
                        stock = -1, -- -1 = infinite stock
                        themes = item.themes or {},
                        series = item.series,
                        tag = item.tag,
                        source = item.source or {},
                    }

                    -- Add to category list
                    if not ShopData.ItemsByCategory[category] then
                        ShopData.ItemsByCategory[category] = {}
                    end
                    table.insert(ShopData.ItemsByCategory[category], itemId)

                    shopItemCount = shopItemCount + 1
                end
            end
        end
    end

    print("[ShopData] ✅ Loaded", shopItemCount, "purchasable items for Nook Shopping")
    print("[ShopData] 📊 Items with buy prices:", itemsWithBuyPrice)
    print("[ShopData] 📊 Items with sprites:", itemsWithSprite)

    -- Print category breakdown
    for category, items in pairs(ShopData.ItemsByCategory) do
        print("[ShopData]   📦", category .. ":", #items, "items")
    end

    -- If no items were loaded, warn
    if shopItemCount == 0 then
        warn("[ShopData] ⚠️ No items loaded! Shop will be empty.")
        warn("[ShopData] ⚠️ Check ItemDataFetcher - items need both spriteIndex and buy price.")
    end
end

-- Initialize on first require
initializeShopItems()

-- Function to get items by category
function ShopData.getItemsByCategory(category: string): table
    if category == "All" then
        local allItems = {}
        for itemId, itemData in pairs(ShopData.Items) do
            table.insert(allItems, itemData)
        end
        return allItems
    end

    local itemIds = ShopData.ItemsByCategory[category] or {}
    local items = {}
    for _, itemId in ipairs(itemIds) do
        local itemData = ShopData.Items[itemId]
        if itemData then
            table.insert(items, itemData)
        end
    end
    return items
end

-- Function to get item info
function ShopData.getItemInfo(itemId: string): table?
    return ShopData.Items[itemId]
end

-- Function to check if player can buy
function ShopData.canPlayerBuy(playerLevel: number, itemId: string): boolean
    local item = ShopData.Items[itemId]
    if not item then
        return false
    end

    return playerLevel >= (item.unlockLevel or 1)
end

-- Function to get all shop items
function ShopData.getAllItems(): table
    local allItems = {}
    for itemId, itemData in pairs(ShopData.Items) do
        table.insert(allItems, itemData)
    end
    -- Sort by name
    table.sort(allItems, function(a, b)
        return (a.name or a.id) < (b.name or b.id)
    end)
    return allItems
end

return ShopData
