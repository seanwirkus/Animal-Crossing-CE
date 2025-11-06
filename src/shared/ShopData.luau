--[[
    ShopData.luau
    Shop items, prices, and unlock conditions
    
    TODO: PHASE 1 - DAY 4 PRIORITY
    - Define 15-20 starter shop items
    - Set buy prices and sell prices (70% of buy)
    - Add sprite indices
    - Add unlock requirements (level, achievements, etc)
    
    USED BY: ShopGUI, ShopManager
]]

local ShopData = {}

-- TODO: Define shop categories
ShopData.Categories = {
    "Tools",
    "Furniture",
    "DIY Recipes",
    "Upgrades",
    "Special"
}

-- TODO: Define shop items
ShopData.Items = {
    --[[
    fishing_rod = {
        name = "Fishing Rod",
        category = "Tools",
        buyPrice = 500,
        sellPrice = 350,  -- 70% of buy price
        spriteIndex = 5,
        description = "Catch fish in rivers and oceans",
        unlockLevel = 1,
        stock = -1  -- -1 = infinite
    },
    net = {
        name = "Net",
        category = "Tools",
        buyPrice = 500,
        sellPrice = 350,
        spriteIndex = 3,
        description = "Catch bugs and butterflies",
        unlockLevel = 1,
        stock = -1
    },
    -- TODO: Add 13+ more items
    ]]
}

-- TODO: Add placeholder items
ShopData.Items.placeholder_tool = {
    name = "Basic Tool",
    category = "Tools",
    buyPrice = 500,
    sellPrice = 350,
    spriteIndex = 1,
    description = "TODO: Define real shop items",
    unlockLevel = 1,
    stock = -1
}

-- TODO: Function to get items by category
function ShopData.getItemsByCategory(category: string): table
    warn("[ShopData] getItemsByCategory() NOT IMPLEMENTED - category:", category)
    return {}
end

-- TODO: Function to get item info
function ShopData.getItemInfo(itemId: string): table?
    return ShopData.Items[itemId]
end

-- TODO: Function to check if player can buy
function ShopData.canPlayerBuy(playerLevel: number, itemId: string): boolean
    local item = ShopData.Items[itemId]
    if not item then return false end
    
    return playerLevel >= item.unlockLevel
end

return ShopData
