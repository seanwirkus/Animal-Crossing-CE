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
local function initializeShopItems()
    print("[ShopData] 🛒 Initializing Nook Shopping items...")

    -- Get all items from ItemDataFetcher
    local allItems = ItemDataFetcher.getAllItems()
    local shopItemCount = 0
    local itemsWithBuyPrice = 0
    local nookShoppingCount = 0

    print("[ShopData] 📦 Processing", #allItems, "total items from ItemDataFetcher...")

    -- First pass: Collect items that match "Nook Shopping"
    for _, item in ipairs(allItems) do
        -- Check if item has a buy price (required for shop)
        if item.buy and item.buy > 0 then
            itemsWithBuyPrice = itemsWithBuyPrice + 1

            -- Check if item is available from "Nook Shopping"
            local source = item.source or {}
            local isNookShopping = false

            -- Try multiple variations of "Nook Shopping" name
            for _, sourceName in ipairs(source) do
                local sourceLower = string.lower(tostring(sourceName or ""))
                -- Check for exact "nook shopping" match first
                if string.find(sourceLower, "nook shopping", 1, true) then
                    isNookShopping = true
                    nookShoppingCount = nookShoppingCount + 1
                    break
                end
            end

            if isNookShopping then
                -- Add to shop items
                local itemId = item.id
                local category = item.category or "Miscellaneous"

                ShopData.Items[itemId] = {
                    id = itemId,
                    name = item.name or item.displayName or itemId,
                    category = category,
                    buyPrice = item.buy,
                    sellPrice = item.sell or math.floor(item.buy * 0.7), -- Default to 70% of buy price
                    spriteIndex = item.spriteIndex,
                    description = item.description or "",
                    unlockLevel = item.unlockLevel or 1,
                    stock = -1, -- -1 = infinite stock
                    themes = item.themes or {},
                    series = item.series,
                    tag = item.tag,
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

    -- Second pass: If we have very few "Nook Shopping" items, include all items with buy prices as fallback
    if shopItemCount < 5 and itemsWithBuyPrice > 0 then
        print(
            "[ShopData] ⚠️ Only",
            shopItemCount,
            "items match 'Nook Shopping' - including all items with buy prices as fallback"
        )

        -- Clear and re-add all items with buy prices
        ShopData.Items = {}
        ShopData.ItemsByCategory = {}
        shopItemCount = 0

        for _, item in ipairs(allItems) do
            if item.buy and item.buy > 0 then
                local itemId = item.id
                local category = item.category or "Miscellaneous"

                ShopData.Items[itemId] = {
                    id = itemId,
                    name = item.name or item.displayName or itemId,
                    category = category,
                    buyPrice = item.buy,
                    sellPrice = item.sell or math.floor(item.buy * 0.7),
                    spriteIndex = item.spriteIndex,
                    description = item.description or "",
                    unlockLevel = item.unlockLevel or 1,
                    stock = -1,
                    themes = item.themes or {},
                    series = item.series,
                    tag = item.tag,
                }

                if not ShopData.ItemsByCategory[category] then
                    ShopData.ItemsByCategory[category] = {}
                end
                table.insert(ShopData.ItemsByCategory[category], itemId)

                shopItemCount = shopItemCount + 1
            end
        end
    end

    print("[ShopData] ✅ Loaded", shopItemCount, "items for Nook Shopping")
    print("[ShopData] 📊 Items with buy prices:", itemsWithBuyPrice)
    print("[ShopData] 📊 Items matching 'Nook Shopping':", nookShoppingCount)

    -- Print category breakdown
    for category, items in pairs(ShopData.ItemsByCategory) do
        print("[ShopData]   📦", category .. ":", #items, "items")
    end

    -- If no items were loaded, warn
    if shopItemCount == 0 then
        warn("[ShopData] ⚠️ No items loaded! Shop will be empty.")
        warn("[ShopData] ⚠️ Check ItemDataFetcher and item source fields.")
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
