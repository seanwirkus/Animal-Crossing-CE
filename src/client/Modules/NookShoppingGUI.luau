--[[
    NookShoppingGUI.luau
    Full Nook Marketplace with:
    - Compact 68x68 item cards
    - Home page with featured deals, bundles, and daily specials
    - Search bar with real-time filtering
    - Rarity system (Common, Uncommon, Rare, Epic, Legendary)
    - Stock limits (some items are limited or out of stock)
    - Quantity selector for purchases
    - Sales and discounts
    - Category filtering
    - Bundles section
    - RESOURCES tab (softwood, hardwood, iron, clay, etc.) - always in stock
    - SELL tab - sell items from your inventory for bells
    - Full marketplace experience
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local NookShoppingGUI = {}
NookShoppingGUI.__index = NookShoppingGUI

local DEBUG = RunService:IsStudio()

local function debugLog(...)
    if DEBUG then
        print("[NookShoppingGUI]", ...)
    end
end

local function debugWarn(...)
    if DEBUG then
        warn("[NookShoppingGUI]", ...)
    end
end

-- ACNH Color Palette
local COLORS = {
    -- Backgrounds
    BG_CREAM = Color3.fromRGB(255, 251, 231),
    BG_WHITE = Color3.fromRGB(255, 255, 255),
    BG_LIGHT = Color3.fromRGB(250, 246, 235),
    BG_DARK = Color3.fromRGB(45, 45, 50),
    BG_SIDEBAR = Color3.fromRGB(248, 244, 230),

    -- Accent Colors
    TEAL = Color3.fromRGB(4, 175, 166),
    TEAL_HOVER = Color3.fromRGB(5, 195, 185),
    TEAL_DARK = Color3.fromRGB(3, 140, 133),
    GOLD = Color3.fromRGB(255, 193, 77),
    GOLD_DARK = Color3.fromRGB(180, 130, 40),
    BROWN = Color3.fromRGB(139, 90, 43),
    BROWN_DARK = Color3.fromRGB(80, 50, 30),

    -- Rarity Colors
    RARITY_COMMON = Color3.fromRGB(180, 180, 180),
    RARITY_UNCOMMON = Color3.fromRGB(100, 200, 100),
    RARITY_RARE = Color3.fromRGB(80, 140, 220),
    RARITY_EPIC = Color3.fromRGB(180, 80, 220),
    RARITY_LEGENDARY = Color3.fromRGB(255, 180, 50),

    -- Status
    SUCCESS = Color3.fromRGB(100, 180, 100),
    ERROR = Color3.fromRGB(220, 100, 100),
    SALE_RED = Color3.fromRGB(220, 60, 60),
    OUT_OF_STOCK = Color3.fromRGB(150, 150, 150),

    -- Text
    TEXT_DARK = Color3.fromRGB(50, 45, 40),
    TEXT_MEDIUM = Color3.fromRGB(100, 90, 80),
    TEXT_LIGHT = Color3.fromRGB(255, 255, 255),
    TEXT_MUTED = Color3.fromRGB(140, 130, 120),
}

-- Rarity definitions
local RARITY = {
    COMMON = { name = "Common", color = COLORS.RARITY_COMMON, weight = 60 },
    UNCOMMON = { name = "Uncommon", color = COLORS.RARITY_UNCOMMON, weight = 25 },
    RARE = { name = "Rare", color = COLORS.RARITY_RARE, weight = 10 },
    EPIC = { name = "Epic", color = COLORS.RARITY_EPIC, weight = 4 },
    LEGENDARY = { name = "Legendary", color = COLORS.RARITY_LEGENDARY, weight = 1 },
}

-- Layout constants (compact Amazon-style)
local LAYOUT = {
    WINDOW_SIZE = UDim2.new(0.82, 0, 0.78, 0),
    WINDOW_MIN = Vector2.new(640, 440),
    WINDOW_MAX = Vector2.new(980, 700),
    HEADER_HEIGHT = 48,
    TAB_BAR_HEIGHT = 34,
    FILTER_BAR_HEIGHT = 34,
    CART_BAR_HEIGHT = 56,
    SEARCH_HEIGHT = 30,
    ITEM_SIZE = 68,
    ITEM_META_HEIGHT = 40,
    ITEM_PADDING = 8,
    CORNER_RADIUS = 8,
}

local MIN_DELIVERY_TOTAL = 500

-- Navigation tabs
local NAV_TABS = {
    { id = "home", icon = "🏠", name = "Highlights" },
    { id = "all", icon = "📚", name = "Catalog" },
    { id = "diy", icon = "🔨", name = "DIY Recipes" },
    { id = "resources", icon = "🪵", name = "Resources" },
    { id = "deals", icon = "🔥", name = "Deals" },
    { id = "bundles", icon = "📦", name = "Bundles" },
    { id = "rare", icon = "✨", name = "Curated" },
    { id = "sell", icon = "💰", name = "Sell" },
}

local SORT_OPTIONS = {
    { id = "name", label = "Name" },
    { id = "price_low", label = "Price ↑" },
    { id = "price_high", label = "Price ↓" },
    { id = "rarity", label = "Rarity" },
}

-- Categories for filtering
local CATEGORIES = {
    "All", "Resources", "Furniture", "Housewares", "Tools", "Miscellaneous", "Wall-Mounted", "Clothing"
}

-- Resource items that are always in stock
local RESOURCE_ITEMS = {
    -- Wood types
    { id = "softwood", name = "Softwood", price = 60, sellPrice = 60, icon = "🪵", category = "Resources", description = "Soft, easy to work with wood" },
    { id = "wood", name = "Wood", price = 60, sellPrice = 60, icon = "🪵", category = "Resources", description = "Regular wood from trees" },
    { id = "hardwood", name = "Hardwood", price = 60, sellPrice = 60, icon = "🪵", category = "Resources", description = "Dense, sturdy wood" },
    { id = "bamboo-piece", name = "Bamboo Piece", price = 80, sellPrice = 80, icon = "🎋", category = "Resources", description = "A piece of bamboo" },
    { id = "young-spring-bamboo", name = "Young Spring Bamboo", price = 200, sellPrice = 200, icon = "🎋", category = "Resources", description = "Seasonal spring bamboo" },

    -- Minerals & Ores
    { id = "iron-nugget", name = "Iron Nugget", price = 375, sellPrice = 375, icon = "🔩", category = "Resources", description = "Essential crafting material" },
    { id = "gold-nugget", name = "Gold Nugget", price = 10000, sellPrice = 10000, icon = "🥇", category = "Resources", description = "Rare and valuable gold" },
    { id = "clay", name = "Clay", price = 100, sellPrice = 100, icon = "🧱", category = "Resources", description = "Moldable clay for crafting" },
    { id = "stone", name = "Stone", price = 75, sellPrice = 75, icon = "🪨", category = "Resources", description = "Common stone material" },

    -- Nature items
    { id = "tree-branch", name = "Tree Branch", price = 5, sellPrice = 5, icon = "🌿", category = "Resources", description = "Fallen branch from a tree" },
    { id = "weeds", name = "Clump of Weeds", price = 10, sellPrice = 10, icon = "🌱", category = "Resources", description = "Common weeds" },
    { id = "coconut", name = "Coconut", price = 250, sellPrice = 250, icon = "🥥", category = "Resources", description = "Tropical coconut" },

    -- Shells
    { id = "conch", name = "Conch", price = 700, sellPrice = 700, icon = "🐚", category = "Resources", description = "Beautiful spiral shell" },
    { id = "coral", name = "Coral", price = 500, sellPrice = 500, icon = "🪸", category = "Resources", description = "Ocean coral" },
    { id = "giant-clam", name = "Giant Clam", price = 900, sellPrice = 900, icon = "🦪", category = "Resources", description = "Large ocean clam" },
    { id = "sand-dollar", name = "Sand Dollar", price = 120, sellPrice = 120, icon = "⭐", category = "Resources", description = "Flat sea urchin shell" },
    { id = "sea-snail", name = "Sea Snail", price = 180, sellPrice = 180, icon = "🐌", category = "Resources", description = "Small sea snail shell" },
    { id = "venus-comb", name = "Venus Comb", price = 300, sellPrice = 300, icon = "🐚", category = "Resources", description = "Spiky decorative shell" },
    { id = "cowrie", name = "Cowrie", price = 60, sellPrice = 60, icon = "🐚", category = "Resources", description = "Small smooth shell" },
    { id = "summer-shell", name = "Summer Shell", price = 600, sellPrice = 600, icon = "🐚", category = "Resources", description = "Seasonal summer shell" },

    -- Seasonal & Special
    { id = "star-fragment", name = "Star Fragment", price = 250, sellPrice = 250, icon = "⭐", category = "Resources", description = "Fragment from a shooting star" },
    { id = "large-star-fragment", name = "Large Star Fragment", price = 500, sellPrice = 500, icon = "🌟", category = "Resources", description = "Large glowing star piece" },
    { id = "snowflake", name = "Snowflake", price = 200, sellPrice = 200, icon = "❄️", category = "Resources", description = "Winter snowflake" },
    { id = "large-snowflake", name = "Large Snowflake", price = 2500, sellPrice = 2500, icon = "❄️", category = "Resources", description = "Perfect large snowflake" },
    { id = "maple-leaf", name = "Maple Leaf", price = 200, sellPrice = 200, icon = "🍁", category = "Resources", description = "Autumn maple leaf" },
    { id = "cherry-blossom-petal", name = "Cherry-Blossom Petal", price = 200, sellPrice = 200, icon = "🌸", category = "Resources", description = "Spring cherry blossom" },
    { id = "acorn", name = "Acorn", price = 200, sellPrice = 200, icon = "🌰", category = "Resources", description = "Fall acorn from trees" },
    { id = "pine-cone", name = "Pine Cone", price = 200, sellPrice = 200, icon = "🌲", category = "Resources", description = "Pine cone from cedar trees" },
    { id = "mushroom", name = "Mushroom", price = 200, sellPrice = 200, icon = "🍄", category = "Resources", description = "Common forest mushroom" },

    -- Flowers & Plants
    { id = "flower-seeds", name = "Flower Seeds", price = 120, sellPrice = 40, icon = "🌻", category = "Resources", description = "Pack of flower seeds" },
    { id = "bush-start", name = "Bush Start", price = 280, sellPrice = 100, icon = "🌳", category = "Resources", description = "Young bush sapling" },
    { id = "sapling", name = "Sapling", price = 640, sellPrice = 200, icon = "🌱", category = "Resources", description = "Young tree sapling" },
    { id = "cedar-sapling", name = "Cedar Sapling", price = 640, sellPrice = 200, icon = "🌲", category = "Resources", description = "Young cedar sapling" },
    { id = "coconut-tree-sapling", name = "Coconut Sapling", price = 1000, sellPrice = 250, icon = "🌴", category = "Resources", description = "Tropical palm sapling" },

    -- Crafting Materials
    { id = "wasp-nest", name = "Wasp Nest", price = 300, sellPrice = 300, icon = "🐝", category = "Resources", description = "Abandoned wasp nest" },
    { id = "flimsy-axe", name = "Flimsy Axe", price = 800, sellPrice = 200, icon = "🪓", category = "Tools", description = "Basic axe for chopping" },
    { id = "flimsy-fishing-rod", name = "Flimsy Fishing Rod", price = 400, sellPrice = 100, icon = "🎣", category = "Tools", description = "Basic fishing rod" },
    { id = "flimsy-net", name = "Flimsy Net", price = 400, sellPrice = 100, icon = "🥅", category = "Tools", description = "Basic bug net" },
    { id = "flimsy-shovel", name = "Flimsy Shovel", price = 800, sellPrice = 200, icon = "⛏️", category = "Tools", description = "Basic shovel for digging" },
    { id = "flimsy-watering-can", name = "Flimsy Watering Can", price = 400, sellPrice = 100, icon = "🚿", category = "Tools", description = "Basic watering can" },
    { id = "ladder", name = "Ladder", price = 2000, sellPrice = 500, icon = "🪜", category = "Tools", description = "Climb cliffs and ledges" },
    { id = "vaulting-pole", name = "Vaulting Pole", price = 2000, sellPrice = 500, icon = "🏃", category = "Tools", description = "Jump over rivers" },
}

function NookShoppingGUI.new()
    local self = setmetatable({}, NookShoppingGUI)

    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.gui = nil
    self.visible = false
    self.bells = 0
    self.currentTab = "all"
    self.currentCategory = "All"
    self.searchQuery = ""
    self.selectedQuantity = 1
    self.sortMode = "name"
    self.showAvailableOnly = false

    -- Item data with rarity, stock, and sales
    self.shopItems = {}
    self.resourceItems = {}
    self.catalogItems = {}
    self.catalogItemMap = {}
    self.catalogCategories = {}
    self.dailyDeals = {}
    self.bundles = {}
    self.featuredItems = {}
    self.craftingRecipes = {} -- DIY recipes from ItemDataFetcher

    -- Cart state
    self.cartItems = {}
    self.cartTotal = 0
    self.cartCount = 0
    self.cartBar = nil
    self.cartTotalLabel = nil
    self.cartHintLabel = nil
    self.checkoutButton = nil
    self.cartCountLabel = nil
    self.pendingCartCheckout = false

    -- Player inventory for selling
    self.playerInventory = {}
    self.inventoryClient = nil
    self.inventoryConnection = nil

    -- Load dependencies
    local shared = ReplicatedStorage:WaitForChild("Shared")
    self.spriteConfig = require(shared:WaitForChild("SpriteConfig"))
    self.shopData = require(shared:WaitForChild("ShopData"))
    self.itemDataFetcher = require(shared:WaitForChild("ItemDataFetcher"))

    -- Remotes (wait for server to create them)
    self.currencyRemote = ReplicatedStorage:WaitForChild("CurrencyEvent")
    local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
    if remoteEventsFolder then
        -- Wait for the shop transaction remote (server creates it during init)
        self.shopRemote = remoteEventsFolder:WaitForChild("ShopTransaction", 10)
        if not self.shopRemote then
            debugWarn("ShopTransaction remote not found after waiting")
        else
            debugLog("ShopTransaction remote found")
        end
    else
        debugWarn("RemoteEvents folder not found")
    end

    -- Initialize shop data with rarity and stock
    self:initializeShopData()
    self:buildGui()
    self:connectToServer()

    debugLog("Marketplace initialized", "shopItems", #self.shopItems, "catalogItems", #self.catalogItems)
    return self
end

--[[
    Initialize shop items with rarity, stock limits, and sales
]]
function NookShoppingGUI:initializeShopData()
    local allItems = self.itemDataFetcher.getAllItems() or {}
    local availableItems = self.shopData.getAllItems() or {}
    local rng = Random.new(os.time())

    -- Generate daily seed for consistent daily deals
    local daySeed = math.floor(os.time() / 86400)
    local dailyRng = Random.new(daySeed)

    self.shopItems = {}
    self.resourceItems = {}
    self.catalogItems = {}
    self.catalogCategories = {}
    self.dailyDeals = {}
    self.featuredItems = {}
    self.bundles = {}

    local catalogById = {}
    local reservedIds = {}

    if #allItems == 0 then
        debugWarn("ItemDataFetcher returned 0 items")
    end
    if #availableItems == 0 then
        debugWarn("ShopData returned 0 available items")
    end

    local function isCatalogEligible(item)
        if not item or not item.id then
            return false
        end
        if not item.spriteIndex or item.spriteIndex <= 0 then
            return false
        end
        local category = item.category
        if category == "placeholder" or category == "legacy" then
            return false
        end
        return true
    end

    -- Build catalog from ItemBrowser-visible items (sprite-backed)
    for _, item in ipairs(allItems) do
        if not isCatalogEligible(item) then
            continue
        end
        local buyPrice = item.buy or item.buyPrice or 0
        local sellPrice = item.sell or item.sell_price or item.sellPrice or 0
        local catalogItem = {
            id = item.id,
            name = item.name or item.displayName or item.id,
            category = item.category or "Miscellaneous",
            spriteIndex = item.spriteIndex,
            originalPrice = buyPrice,
            price = buyPrice,
            sellPrice = sellPrice,
            isOnSale = false,
            salePercent = 0,
            rarity = "COMMON",
            stock = 0,
            description = item.description or "",
            themes = item.themes or {},
            series = item.series,
            tag = item.tag,
            source = item.source or {},
            isAvailable = false,
        }
        catalogById[item.id] = catalogItem
        table.insert(self.catalogItems, catalogItem)
    end

    -- Initialize resource items (always in stock)
    for _, resource in ipairs(RESOURCE_ITEMS) do
        local catalogItem = catalogById[resource.id]
        if not catalogItem then
            local resourceRecord = self.itemDataFetcher.getItem(resource.id)
            if resourceRecord and resourceRecord.spriteIndex and resourceRecord.spriteIndex > 0 then
                catalogItem = {
                    id = resource.id,
                    name = resource.name,
                    category = resource.category or "Resources",
                    description = resource.description or "",
                    themes = {},
                    source = {},
                    spriteIndex = resourceRecord.spriteIndex,
                }
                catalogById[resource.id] = catalogItem
                table.insert(self.catalogItems, catalogItem)
            else
                debugWarn("Skipping resource without sprite", resource.id)
            end
        end

        if not catalogItem then
            continue
        end

        catalogItem.icon = resource.icon
        catalogItem.category = resource.category or catalogItem.category
        catalogItem.originalPrice = resource.price
        catalogItem.price = resource.price
        catalogItem.sellPrice = resource.sellPrice
        catalogItem.isOnSale = false
        catalogItem.salePercent = 0
        catalogItem.rarity = "COMMON"
        catalogItem.stock = -1 -- Always in stock
        catalogItem.description = resource.description or catalogItem.description
        catalogItem.isResource = true
        catalogItem.isAvailable = true

        table.insert(self.resourceItems, catalogItem)
        table.insert(self.shopItems, catalogItem)
        reservedIds[catalogItem.id] = true
    end

    for _, item in ipairs(availableItems) do
        if not reservedIds[item.id] then
            local catalogItem = catalogById[item.id]
            if not catalogItem then
                catalogItem = {
                    id = item.id,
                    name = item.name or item.displayName or item.id,
                    category = item.category or "Miscellaneous",
                    spriteIndex = item.spriteIndex,
                    description = item.description or "",
                    themes = item.themes or {},
                    series = item.series,
                    tag = item.tag,
                    source = item.source or {},
                }
                catalogById[item.id] = catalogItem
                table.insert(self.catalogItems, catalogItem)
            end

            -- Assign rarity based on price and randomness
            local rarity = self:assignRarity(item, rng)

            -- Determine stock (some items are limited)
            local stock = -1 -- -1 = unlimited
            if rarity == "LEGENDARY" then
                stock = rng:NextInteger(1, 3)
            elseif rarity == "EPIC" then
                stock = rng:NextInteger(2, 5)
            elseif rarity == "RARE" and rng:NextNumber() < 0.3 then
                stock = rng:NextInteger(3, 10)
            end

            -- Some items are out of stock (but less frequently)
            if rng:NextNumber() < 0.05 then
                stock = 0
            end

            -- Determine if on sale (15% chance)
            local isOnSale = rng:NextNumber() < 0.15
            local salePercent = isOnSale and rng:NextInteger(10, 40) or 0
            local originalPrice = item.buyPrice or item.buy or catalogItem.originalPrice or 0
            local salePrice = isOnSale and math.floor(originalPrice * (1 - salePercent / 100)) or originalPrice

            -- Calculate sell price (usually 25% of buy price, or use item.sell if available)
            local sellPrice = item.sell or item.sellPrice or catalogItem.sellPrice or math.floor(originalPrice * 0.25)

            catalogItem.originalPrice = originalPrice
            catalogItem.price = salePrice
            catalogItem.sellPrice = sellPrice
            catalogItem.isOnSale = isOnSale
            catalogItem.salePercent = salePercent
            catalogItem.rarity = rarity
            catalogItem.stock = stock
            catalogItem.isAvailable = true

            table.insert(self.shopItems, catalogItem)

            -- Daily deals (picked deterministically per day)
            if dailyRng:NextNumber() < 0.05 and #self.dailyDeals < 8 then
                local dealItem = table.clone(catalogItem)
                dealItem.isOnSale = true
                dealItem.salePercent = dailyRng:NextInteger(20, 50)
                dealItem.price = math.floor(originalPrice * (1 - dealItem.salePercent / 100))
                dealItem.isDailyDeal = true
                table.insert(self.dailyDeals, dealItem)
            end

            -- Featured items (rare/epic/legendary)
            if (rarity == "RARE" or rarity == "EPIC" or rarity == "LEGENDARY") and #self.featuredItems < 12 then
                table.insert(self.featuredItems, catalogItem)
            end
        end
    end

    self.catalogItemMap = catalogById

    -- Build categories from catalog items
    local categorySet = { ["All"] = true }
    for _, item in ipairs(self.catalogItems) do
        local category = item.category or "Miscellaneous"
        if not categorySet[category] then
            categorySet[category] = true
            table.insert(self.catalogCategories, category)
        end
    end
    table.sort(self.catalogCategories)
    table.insert(self.catalogCategories, 1, "All")

    table.sort(self.catalogItems, function(a, b)
        return (a.name or a.id) < (b.name or b.id)
    end)

    -- Create bundles
    self:generateBundles(rng)

    -- Load crafting recipes (DIY items)
    self.craftingRecipes = self.itemDataFetcher.getCraftableItems() or {}
    debugLog("Loaded", #self.craftingRecipes, "crafting recipes")

    debugLog(
        "Shop data ready",
        "catalog", #self.catalogItems,
        "shop", #self.shopItems,
        "resources", #self.resourceItems,
        "dailyDeals", #self.dailyDeals,
        "bundles", #self.bundles,
        "categories", #self.catalogCategories,
        "recipes", #self.craftingRecipes
    )
end

function NookShoppingGUI:assignRarity(item, rng)
    local price = item.buyPrice or 0
    local roll = rng:NextNumber() * 100

    -- Higher priced items tend to be rarer
    if price > 50000 then
        if roll < 20 then return "LEGENDARY"
        elseif roll < 50 then return "EPIC"
        else return "RARE" end
    elseif price > 20000 then
        if roll < 10 then return "LEGENDARY"
        elseif roll < 35 then return "EPIC"
        elseif roll < 70 then return "RARE"
        else return "UNCOMMON" end
    elseif price > 5000 then
        if roll < 5 then return "EPIC"
        elseif roll < 25 then return "RARE"
        elseif roll < 60 then return "UNCOMMON"
        else return "COMMON" end
    else
        if roll < 2 then return "RARE"
        elseif roll < 15 then return "UNCOMMON"
        else return "COMMON" end
    end
end

function NookShoppingGUI:generateBundles(rng)
    -- Starter Bundle
    table.insert(self.bundles, {
        id = "starter_bundle",
        name = "Starter Pack",
        description = "Everything you need to begin!",
        icon = "🎁",
        items = self:pickRandomItems(5, "Tools", rng),
        originalPrice = 5000,
        price = 2500,
        salePercent = 50,
    })

    -- Furniture Bundle
    table.insert(self.bundles, {
        id = "furniture_bundle",
        name = "Home Makeover",
        description = "Transform your home!",
        icon = "🏠",
        items = self:pickRandomItems(8, "Furniture", rng),
        originalPrice = 25000,
        price = 15000,
        salePercent = 40,
    })

    -- Rare Collection
    table.insert(self.bundles, {
        id = "rare_bundle",
        name = "Rare Collection",
        description = "Exclusive rare items!",
        icon = "✨",
        items = self:pickRareItems(4, rng),
        originalPrice = 100000,
        price = 75000,
        salePercent = 25,
    })
end

function NookShoppingGUI:pickRandomItems(count, category, rng)
    local picked = {}
    local candidates = {}
    for _, item in ipairs(self.shopItems) do
        if category == "All" or item.category == category then
            table.insert(candidates, item)
        end
    end
    for i = 1, math.min(count, #candidates) do
        local idx = rng:NextInteger(1, #candidates)
        table.insert(picked, candidates[idx])
        table.remove(candidates, idx)
    end
    return picked
end

function NookShoppingGUI:pickRareItems(count, rng)
    local picked = {}
    local candidates = {}
    for _, item in ipairs(self.shopItems) do
        if item.rarity == "RARE" or item.rarity == "EPIC" or item.rarity == "LEGENDARY" then
            table.insert(candidates, item)
        end
    end
    for i = 1, math.min(count, #candidates) do
        local idx = rng:NextInteger(1, #candidates)
        table.insert(picked, candidates[idx])
        table.remove(candidates, idx)
    end
    return picked
end

function NookShoppingGUI:buildGui()
    local oldGui = self.playerGui:FindFirstChild("NookShoppingGUI")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NookShoppingGUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 50
    screenGui.Enabled = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = self.playerGui
    self.gui = screenGui

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.4
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = screenGui
    backdrop.Active = true
    backdrop.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:hide()
        end
    end)

    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = LAYOUT.WINDOW_SIZE
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.BackgroundColor3 = COLORS.BG_CREAM
    container.BorderSizePixel = 0
    container.ZIndex = 2
    container.Parent = screenGui
    self.container = container

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, LAYOUT.CORNER_RADIUS)
    containerCorner.Parent = container

    local containerStroke = Instance.new("UIStroke")
    containerStroke.Thickness = 2
    containerStroke.Color = COLORS.BROWN
    containerStroke.Parent = container

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = LAYOUT.WINDOW_MIN
    sizeConstraint.MaxSize = LAYOUT.WINDOW_MAX
    sizeConstraint.Parent = container

    self:buildHeader()
    self:buildTabBar()
    self:buildFilterBar()
    self:buildContentArea()
    self:buildCartBar()
end

function NookShoppingGUI:buildHeader()
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, LAYOUT.HEADER_HEIGHT)
    header.BackgroundColor3 = COLORS.TEAL
    header.BorderSizePixel = 0
    header.ZIndex = 10
    header.Parent = self.container

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, LAYOUT.CORNER_RADIUS)
    headerCorner.Parent = header

    -- Cover bottom corners
    local bottomCover = Instance.new("Frame")
    bottomCover.Size = UDim2.new(1, 0, 0, LAYOUT.CORNER_RADIUS)
    bottomCover.Position = UDim2.new(0, 0, 1, -LAYOUT.CORNER_RADIUS)
    bottomCover.BackgroundColor3 = COLORS.TEAL
    bottomCover.BorderSizePixel = 0
    bottomCover.ZIndex = 9
    bottomCover.Parent = header

    -- Logo/Title with icon
    local logoIcon = Instance.new("TextLabel")
    logoIcon.Size = UDim2.fromOffset(28, 28)
    logoIcon.Position = UDim2.fromOffset(12, 11)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Text = "🛒"
    logoIcon.TextSize = 22
    logoIcon.ZIndex = 11
    logoIcon.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.fromOffset(200, 26)
    titleLabel.Position = UDim2.fromOffset(44, 12)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = COLORS.TEXT_LIGHT
    titleLabel.Text = "Nook Shopping"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 11
    titleLabel.Parent = header

    -- Search bar
    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "SearchFrame"
    searchFrame.Size = UDim2.fromOffset(280, LAYOUT.SEARCH_HEIGHT)
    searchFrame.Position = UDim2.new(0.5, -140, 0.5, -math.floor(LAYOUT.SEARCH_HEIGHT / 2))
    searchFrame.BackgroundColor3 = COLORS.BG_WHITE
    searchFrame.BorderSizePixel = 0
    searchFrame.ZIndex = 11
    searchFrame.Parent = header

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 16)
    searchCorner.Parent = searchFrame

    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.fromOffset(26, LAYOUT.SEARCH_HEIGHT)
    searchIcon.Position = UDim2.fromOffset(6, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 12
    searchIcon.ZIndex = 12
    searchIcon.Parent = searchFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -40, 1, 0)
    searchBox.Position = UDim2.fromOffset(32, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.TextColor3 = COLORS.TEXT_DARK
    searchBox.PlaceholderText = "Search the catalog..."
    searchBox.PlaceholderColor3 = COLORS.TEXT_MUTED
    searchBox.Text = ""
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 12
    searchBox.Parent = searchFrame
    self.searchBox = searchBox

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self.searchQuery = searchBox.Text
        self:refreshContent()
    end)

    -- Bells display
    local bellsFrame = Instance.new("Frame")
    bellsFrame.Size = UDim2.fromOffset(140, 34)
    bellsFrame.Position = UDim2.new(1, -210, 0.5, -17)
    bellsFrame.BackgroundColor3 = COLORS.GOLD
    bellsFrame.BorderSizePixel = 0
    bellsFrame.ZIndex = 11
    bellsFrame.Parent = header

    local bellsCorner = Instance.new("UICorner")
    bellsCorner.CornerRadius = UDim.new(0, 16)
    bellsCorner.Parent = bellsFrame

    local bellsLabel = Instance.new("TextLabel")
    bellsLabel.Size = UDim2.fromScale(1, 1)
    bellsLabel.BackgroundTransparency = 1
    bellsLabel.Font = Enum.Font.GothamBold
    bellsLabel.TextSize = 14
    bellsLabel.TextColor3 = COLORS.BROWN_DARK
    bellsLabel.Text = "0 Bells"
    bellsLabel.ZIndex = 12
    bellsLabel.Parent = bellsFrame
    self.bellsLabel = bellsLabel

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(30, 30)
    closeBtn.Position = UDim2.new(1, -44, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.TEXT_LIGHT
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 18
    closeBtn.TextStrokeTransparency = 0.6
    closeBtn.ZIndex = 11
    closeBtn.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        self:hide()
    end)

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(220, 80, 80)}):Play()
    end)
end

function NookShoppingGUI:buildTabBar()
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, LAYOUT.TAB_BAR_HEIGHT)
    tabBar.Position = UDim2.fromOffset(0, LAYOUT.HEADER_HEIGHT)
    tabBar.BackgroundColor3 = COLORS.BG_LIGHT
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = 9
    tabBar.Parent = self.container
    self.tabBar = tabBar

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name = "TabScroll"
    tabScroll.Size = UDim2.new(1, -24, 1, 0)
    tabScroll.Position = UDim2.fromOffset(12, 0)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 0
    tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.ZIndex = 10
    tabScroll.Parent = tabBar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabScroll

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 4)
    tabPadding.PaddingRight = UDim.new(0, 4)
    tabPadding.Parent = tabScroll

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabScroll.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 8, 0, 0)
    end)

    self.navButtons = {}

    for i, tab in ipairs(NAV_TABS) do
        local btn = Instance.new("TextButton")
        btn.Name = "Nav_" .. tab.id
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.Size = UDim2.fromOffset(0, 28)
        btn.BackgroundColor3 = (self.currentTab == tab.id) and COLORS.TEAL or COLORS.BG_WHITE
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextColor3 = (self.currentTab == tab.id) and COLORS.TEXT_LIGHT or COLORS.TEXT_DARK
        btn.Text = tab.icon .. "  " .. tab.name
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        btn.ZIndex = 11
        btn.Parent = tabScroll

        local btnPadding = Instance.new("UIPadding")
        btnPadding.PaddingLeft = UDim.new(0, 12)
        btnPadding.PaddingRight = UDim.new(0, 12)
        btnPadding.Parent = btn

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 12)
        btnCorner.Parent = btn

        self.navButtons[tab.id] = btn

        btn.MouseButton1Click:Connect(function()
            self:selectTab(tab.id)
        end)

        btn.MouseEnter:Connect(function()
            if self.currentTab ~= tab.id then
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.TEAL_DARK:Lerp(COLORS.BG_WHITE, 0.7)}):Play()
            end
        end)

        btn.MouseLeave:Connect(function()
            if self.currentTab ~= tab.id then
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BG_WHITE}):Play()
            end
        end)
    end
end

function NookShoppingGUI:buildFilterBar()
    local filterBar = Instance.new("Frame")
    filterBar.Name = "FilterBar"
    filterBar.Size = UDim2.new(1, 0, 0, LAYOUT.FILTER_BAR_HEIGHT)
    filterBar.Position = UDim2.fromOffset(0, LAYOUT.HEADER_HEIGHT + LAYOUT.TAB_BAR_HEIGHT)
    filterBar.BackgroundColor3 = COLORS.BG_WHITE
    filterBar.BorderSizePixel = 0
    filterBar.ZIndex = 8
    filterBar.Parent = self.container
    self.filterBar = filterBar

    local categoryScroll = Instance.new("ScrollingFrame")
    categoryScroll.Name = "CategoryScroll"
    categoryScroll.Size = UDim2.new(1, -240, 1, 0)
    categoryScroll.Position = UDim2.fromOffset(12, 0)
    categoryScroll.BackgroundTransparency = 1
    categoryScroll.BorderSizePixel = 0
    categoryScroll.ScrollBarThickness = 0
    categoryScroll.ScrollingDirection = Enum.ScrollingDirection.X
    categoryScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    categoryScroll.ZIndex = 9
    categoryScroll.Parent = filterBar
    self.categoryFrame = categoryScroll

    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.FillDirection = Enum.FillDirection.Horizontal
    categoryLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    categoryLayout.Padding = UDim.new(0, 6)
    categoryLayout.Parent = categoryScroll

    local categoryPadding = Instance.new("UIPadding")
    categoryPadding.PaddingLeft = UDim.new(0, 2)
    categoryPadding.PaddingRight = UDim.new(0, 2)
    categoryPadding.Parent = categoryScroll

    categoryLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        categoryScroll.CanvasSize = UDim2.new(0, categoryLayout.AbsoluteContentSize.X + 6, 0, 0)
    end)

    self.categoryButtons = {}
    local categories = table.clone(self.catalogCategories or CATEGORIES)
    if categories[1] ~= "All" then
        table.insert(categories, 1, "All")
    end

    for i, category in ipairs(categories) do
        local catBtn = Instance.new("TextButton")
        catBtn.Name = "Cat_" .. category
        catBtn.AutomaticSize = Enum.AutomaticSize.X
        catBtn.Size = UDim2.fromOffset(0, 26)
        catBtn.BackgroundColor3 = (self.currentCategory == category) and COLORS.TEAL or COLORS.BG_LIGHT
        catBtn.BorderSizePixel = 0
        catBtn.Font = Enum.Font.GothamMedium
        catBtn.TextSize = 12
        catBtn.TextColor3 = (self.currentCategory == category) and COLORS.TEXT_LIGHT or COLORS.TEXT_DARK
        catBtn.Text = category
        catBtn.AutoButtonColor = false
        catBtn.LayoutOrder = i
        catBtn.ZIndex = 10
        catBtn.Parent = categoryScroll

        local catPadding = Instance.new("UIPadding")
        catPadding.PaddingLeft = UDim.new(0, 10)
        catPadding.PaddingRight = UDim.new(0, 10)
        catPadding.Parent = catBtn

        local catCorner = Instance.new("UICorner")
        catCorner.CornerRadius = UDim.new(0, 10)
        catCorner.Parent = catBtn

        self.categoryButtons[category] = catBtn

        catBtn.MouseButton1Click:Connect(function()
            self:selectCategory(category)
        end)
    end

    local availabilityButton = Instance.new("TextButton")
    availabilityButton.Name = "AvailabilityButton"
    availabilityButton.Size = UDim2.fromOffset(110, 26)
    availabilityButton.AnchorPoint = Vector2.new(1, 0.5)
    availabilityButton.Position = UDim2.new(1, -140, 0.5, 0)
    availabilityButton.BackgroundColor3 = COLORS.BG_LIGHT
    availabilityButton.BorderSizePixel = 0
    availabilityButton.Font = Enum.Font.GothamMedium
    availabilityButton.TextSize = 12
    availabilityButton.TextColor3 = COLORS.TEXT_DARK
    availabilityButton.Text = "Show: All"
    availabilityButton.AutoButtonColor = false
    availabilityButton.ZIndex = 9
    availabilityButton.Parent = filterBar
    self.availabilityButton = availabilityButton

    local availabilityCorner = Instance.new("UICorner")
    availabilityCorner.CornerRadius = UDim.new(0, 10)
    availabilityCorner.Parent = availabilityButton

    availabilityButton.MouseButton1Click:Connect(function()
        self.showAvailableOnly = not self.showAvailableOnly
        self:updateFilterButtons()
        self:refreshContent()
    end)

    local sortButton = Instance.new("TextButton")
    sortButton.Name = "SortButton"
    sortButton.Size = UDim2.fromOffset(120, 26)
    sortButton.AnchorPoint = Vector2.new(1, 0.5)
    sortButton.Position = UDim2.new(1, -12, 0.5, 0)
    sortButton.BackgroundColor3 = COLORS.BG_LIGHT
    sortButton.BorderSizePixel = 0
    sortButton.Font = Enum.Font.GothamMedium
    sortButton.TextSize = 12
    sortButton.TextColor3 = COLORS.TEXT_DARK
    sortButton.Text = "Sort: Name"
    sortButton.AutoButtonColor = false
    sortButton.ZIndex = 9
    sortButton.Parent = filterBar
    self.sortButton = sortButton

    local sortCorner = Instance.new("UICorner")
    sortCorner.CornerRadius = UDim.new(0, 10)
    sortCorner.Parent = sortButton

    sortButton.MouseButton1Click:Connect(function()
        self:cycleSortMode()
        self:refreshContent()
    end)

    self:updateFilterButtons()
    filterBar.Visible = (self.currentTab == "all")
end

function NookShoppingGUI:buildCartBar()
    local cartBar = Instance.new("Frame")
    cartBar.Name = "CartBar"
    cartBar.Size = UDim2.new(1, 0, 0, LAYOUT.CART_BAR_HEIGHT)
    cartBar.Position = UDim2.fromOffset(0, LAYOUT.HEADER_HEIGHT + LAYOUT.TAB_BAR_HEIGHT)
    cartBar.BackgroundColor3 = Color3.fromRGB(255, 252, 245)
    cartBar.BackgroundTransparency = 1
    cartBar.BorderSizePixel = 0
    cartBar.ZIndex = 9
    cartBar.Visible = false
    cartBar.Parent = self.container
    self.cartBar = cartBar

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 10)
    barCorner.Parent = cartBar

    local barStroke = Instance.new("UIStroke")
    barStroke.Color = Color3.fromRGB(223, 204, 175)
    barStroke.Thickness = 1
    barStroke.Parent = cartBar

    local barGradient = Instance.new("UIGradient")
    barGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 252, 246)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(249, 242, 232)),
    })
    barGradient.Rotation = 90
    barGradient.Parent = cartBar

    local barScale = Instance.new("UIScale")
    barScale.Scale = 0.98
    barScale.Parent = cartBar
    self.cartBarScale = barScale

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = cartBar

    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Vertical
    rowLayout.Padding = UDim.new(0, 4)
    rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rowLayout.Parent = cartBar

    local topRow = Instance.new("Frame")
    topRow.Size = UDim2.new(1, 0, 0, 20)
    topRow.BackgroundTransparency = 1
    topRow.LayoutOrder = 1
    topRow.ZIndex = 10
    topRow.Parent = cartBar

    local cartIcon = Instance.new("TextLabel")
    cartIcon.Size = UDim2.fromOffset(18, 18)
    cartIcon.Position = UDim2.fromOffset(0, 1)
    cartIcon.BackgroundTransparency = 1
    cartIcon.Text = "🧺"
    cartIcon.TextSize = 16
    cartIcon.ZIndex = 11
    cartIcon.Parent = topRow

    local cartTitle = Instance.new("TextLabel")
    cartTitle.Size = UDim2.fromOffset(60, 18)
    cartTitle.Position = UDim2.fromOffset(22, 0)
    cartTitle.BackgroundTransparency = 1
    cartTitle.Font = Enum.Font.GothamBold
    cartTitle.TextSize = 12
    cartTitle.TextColor3 = COLORS.TEXT_DARK
    cartTitle.Text = "Cart"
    cartTitle.TextXAlignment = Enum.TextXAlignment.Left
    cartTitle.ZIndex = 11
    cartTitle.Parent = topRow

    local cartCountBadge = Instance.new("TextLabel")
    cartCountBadge.Size = UDim2.fromOffset(56, 16)
    cartCountBadge.Position = UDim2.fromOffset(84, 2)
    cartCountBadge.BackgroundColor3 = COLORS.TEAL
    cartCountBadge.Font = Enum.Font.GothamBold
    cartCountBadge.TextSize = 10
    cartCountBadge.TextColor3 = COLORS.TEXT_LIGHT
    cartCountBadge.Text = "0 items"
    cartCountBadge.TextTruncate = Enum.TextTruncate.AtEnd
    cartCountBadge.TextXAlignment = Enum.TextXAlignment.Center
    cartCountBadge.ZIndex = 11
    cartCountBadge.Parent = topRow
    self.cartCountLabel = cartCountBadge

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 9)
    badgeCorner.Parent = cartCountBadge

    local cartTotalLabel = Instance.new("TextLabel")
    cartTotalLabel.Size = UDim2.fromOffset(200, 18)
    cartTotalLabel.AnchorPoint = Vector2.new(1, 0)
    cartTotalLabel.Position = UDim2.new(1, 0, 0, 0)
    cartTotalLabel.BackgroundTransparency = 1
    cartTotalLabel.Font = Enum.Font.GothamBold
    cartTotalLabel.TextSize = 12
    cartTotalLabel.TextColor3 = COLORS.TEXT_DARK
    cartTotalLabel.Text = "Total: 0 Bells"
    cartTotalLabel.TextXAlignment = Enum.TextXAlignment.Right
    cartTotalLabel.ZIndex = 11
    cartTotalLabel.Parent = topRow
    self.cartTotalLabel = cartTotalLabel

    local bottomRow = Instance.new("Frame")
    bottomRow.Size = UDim2.new(1, 0, 0, 20)
    bottomRow.BackgroundTransparency = 1
    bottomRow.LayoutOrder = 2
    bottomRow.ZIndex = 10
    bottomRow.Parent = cartBar

    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(1, -210, 1, 0)
    hintLabel.Position = UDim2.fromOffset(0, 0)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Font = Enum.Font.Gotham
    hintLabel.TextSize = 10
    hintLabel.TextColor3 = COLORS.TEXT_MUTED
    hintLabel.Text = ""
    hintLabel.TextXAlignment = Enum.TextXAlignment.Left
    hintLabel.ZIndex = 11
    hintLabel.Parent = bottomRow
    self.cartHintLabel = hintLabel

    local actionFrame = Instance.new("Frame")
    actionFrame.Size = UDim2.fromOffset(200, 20)
    actionFrame.AnchorPoint = Vector2.new(1, 0)
    actionFrame.Position = UDim2.new(1, 0, 0, 0)
    actionFrame.BackgroundTransparency = 1
    actionFrame.ZIndex = 11
    actionFrame.Parent = bottomRow

    local actionLayout = Instance.new("UIListLayout")
    actionLayout.FillDirection = Enum.FillDirection.Horizontal
    actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    actionLayout.Padding = UDim.new(0, 6)
    actionLayout.Parent = actionFrame

    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.fromOffset(64, 20)
    clearBtn.BackgroundColor3 = COLORS.BG_LIGHT
    clearBtn.BorderSizePixel = 0
    clearBtn.Font = Enum.Font.GothamMedium
    clearBtn.TextSize = 10
    clearBtn.TextColor3 = COLORS.TEXT_DARK
    clearBtn.Text = "Clear"
    clearBtn.ZIndex = 12
    clearBtn.Parent = actionFrame

    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 8)
    clearCorner.Parent = clearBtn

    local checkoutBtn = Instance.new("TextButton")
    checkoutBtn.Size = UDim2.fromOffset(110, 20)
    checkoutBtn.BackgroundColor3 = COLORS.TEAL
    checkoutBtn.BorderSizePixel = 0
    checkoutBtn.Font = Enum.Font.GothamBold
    checkoutBtn.TextSize = 10
    checkoutBtn.TextColor3 = COLORS.TEXT_LIGHT
    checkoutBtn.Text = "Checkout"
    checkoutBtn.ZIndex = 12
    checkoutBtn.Parent = actionFrame

    local checkoutCorner = Instance.new("UICorner")
    checkoutCorner.CornerRadius = UDim.new(0, 8)
    checkoutCorner.Parent = checkoutBtn

    self.checkoutButton = checkoutBtn

    clearBtn.MouseButton1Click:Connect(function()
        self:clearCart()
    end)

    checkoutBtn.MouseButton1Click:Connect(function()
        self:checkoutCart()
    end)

    self:updateCartBar()
end

function NookShoppingGUI:recalculateCart()
    local total = 0
    local count = 0
    for _, entry in pairs(self.cartItems) do
        if entry and entry.item and entry.count then
            total = total + (entry.item.price * entry.count)
            count = count + entry.count
        end
    end

    self.cartTotal = total
    self.cartCount = count
end

function NookShoppingGUI:updateCartBar()
    if not self.cartBar then
        return
    end

    if self.cartCount <= 0 then
        self:animateCartBar(false)
        return
    end

    self:animateCartBar(true)

    if self.cartCountLabel then
        local label = self.cartCount == 1 and "1 item" or (tostring(self.cartCount) .. " items")
        self.cartCountLabel.Text = label
    end

    if self.cartTotalLabel then
        self.cartTotalLabel.Text = "Total: " .. self:formatBells(self.cartTotal) .. " Bells"
    end

    if self.cartHintLabel then
        if self.cartTotal < MIN_DELIVERY_TOTAL then
            local remaining = MIN_DELIVERY_TOTAL - self.cartTotal
            self.cartHintLabel.Text = "Add " .. self:formatBells(remaining) .. " more for delivery"
            self.cartHintLabel.TextColor3 = COLORS.ERROR
        else
            self.cartHintLabel.Text = "Ready for delivery"
            self.cartHintLabel.TextColor3 = COLORS.TEXT_MUTED
        end
    end

    if self.checkoutButton then
        local canCheckout = self.cartTotal >= MIN_DELIVERY_TOTAL
        self.checkoutButton.Active = canCheckout
        self.checkoutButton.AutoButtonColor = canCheckout
        self.checkoutButton.Text = canCheckout and "Checkout" or "Min 500 Bells"
        self.checkoutButton.BackgroundColor3 = canCheckout and COLORS.TEAL or COLORS.OUT_OF_STOCK
        self.checkoutButton.TextTransparency = canCheckout and 0 or 0.1
    end

    self:updateContentLayout()
end

function NookShoppingGUI:animateCartBar(visible)
    if not self.cartBar then
        return
    end

    if visible then
        if self.cartBar.Visible then
            return
        end

        self.cartBar.Visible = true
        if self.cartBarScale then
            self.cartBarScale.Scale = 0.97
        end
        self.cartBar.BackgroundTransparency = 1

        TweenService:Create(self.cartBar, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
        }):Play()

        if self.cartBarScale then
            TweenService:Create(self.cartBarScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 1,
            }):Play()
        end

        self:updateContentLayout()
        return
    end

    if not self.cartBar.Visible then
        return
    end

    local fadeTween = TweenService:Create(self.cartBar, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
    })

    if self.cartBarScale then
        TweenService:Create(self.cartBarScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Scale = 0.97,
        }):Play()
    end

    fadeTween.Completed:Connect(function()
        if self.cartBar then
            self.cartBar.Visible = false
            self:updateContentLayout()
        end
    end)
    fadeTween:Play()
end

function NookShoppingGUI:pulseCartBar()
    if not self.cartBar or not self.cartBar.Visible or not self.cartBarScale then
        return
    end

    local grow = TweenService:Create(self.cartBarScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Scale = 1.03,
    })
    local shrink = TweenService:Create(self.cartBarScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Scale = 1,
    })

    grow.Completed:Connect(function()
        if self.cartBarScale then
            shrink:Play()
        end
    end)
    grow:Play()
end

function NookShoppingGUI:addToCart(item, quantity)
    quantity = math.clamp(math.floor(quantity or 1), 1, 99)
    if item.isAvailable == false or item.stock == 0 then
        self:showNotification(false, { reason = "Item unavailable" })
        return
    end

    local entry = self.cartItems[item.id]
    if entry then
        entry.count = math.clamp(entry.count + quantity, 1, 99)
    else
        self.cartItems[item.id] = {
            item = item,
            count = quantity,
        }
    end

    self:recalculateCart()
    self:updateCartBar()
    self:pulseCartBar()
    self:showNotification(true, {
        action = "cart_add",
        itemName = item.name or item.id,
        count = quantity,
    })
end

function NookShoppingGUI:clearCart()
    self.cartItems = {}
    self.cartTotal = 0
    self.cartCount = 0
    self.pendingCartCheckout = false
    self:updateCartBar()
end

function NookShoppingGUI:checkoutCart()
    if self.cartCount <= 0 then
        return
    end

    if self.cartTotal < MIN_DELIVERY_TOTAL then
        self:showNotification(false, { reason = "Minimum delivery is " .. self:formatBells(MIN_DELIVERY_TOTAL) .. " Bells" })
        return
    end

    if self.bells < self.cartTotal then
        self:showNotification(false, { reason = "Not enough bells!" })
        return
    end

    if not self.shopRemote then
        self:showNotification(false, { reason = "Shop unavailable" })
        return
    end

    local items = {}
    for _, entry in pairs(self.cartItems) do
        table.insert(items, {
            itemId = entry.item.id,
            count = entry.count,
            unitPrice = entry.item.price,
        })
    end

    self.pendingCartCheckout = true
    debugLog("Cart checkout", "items", #items, "total", self.cartTotal)
    self.shopRemote:FireServer("BuyCart", {
        items = items,
        total = self.cartTotal,
        deliveryMethod = "nookplane",
    })
end

function NookShoppingGUI:buildSidebar()
    -- Deprecated: sidebar navigation replaced by top tab + filter bars.
end

function NookShoppingGUI:buildContentArea()
    local content = Instance.new("Frame")
    content.Name = "ContentArea"
    local topOffset = LAYOUT.HEADER_HEIGHT + LAYOUT.TAB_BAR_HEIGHT + LAYOUT.FILTER_BAR_HEIGHT
    content.Size = UDim2.new(1, -16, 1, -(topOffset + 16))
    content.Position = UDim2.fromOffset(8, topOffset + 8)
    content.BackgroundTransparency = 1
    content.ZIndex = 5
    content.Parent = self.container
    self.contentArea = content

    -- Scroll frame for items
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemsScroll"
    scrollFrame.Size = UDim2.fromScale(1, 1)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 0
    scrollFrame.ScrollBarImageTransparency = 1
    scrollFrame.ZIndex = 6
    scrollFrame.Parent = content
    self.scrollFrame = scrollFrame

    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingTop = UDim.new(0, 4)
    scrollPadding.PaddingLeft = UDim.new(0, 4)
    scrollPadding.PaddingRight = UDim.new(0, 4)
    scrollPadding.Parent = scrollFrame

    self:updateContentLayout()
end

function NookShoppingGUI:updateContentLayout()
    if not self.contentArea then
        return
    end

    local cartHeight = (self.cartBar and self.cartBar.Visible) and LAYOUT.CART_BAR_HEIGHT or 0
    local filterHeight = (self.filterBar and self.filterBar.Visible) and LAYOUT.FILTER_BAR_HEIGHT or 0
    local topOffset = LAYOUT.HEADER_HEIGHT + LAYOUT.TAB_BAR_HEIGHT + cartHeight + filterHeight

    if self.cartBar then
        self.cartBar.Position = UDim2.fromOffset(0, LAYOUT.HEADER_HEIGHT + LAYOUT.TAB_BAR_HEIGHT)
    end

    if self.filterBar then
        self.filterBar.Position = UDim2.fromOffset(0, LAYOUT.HEADER_HEIGHT + LAYOUT.TAB_BAR_HEIGHT + cartHeight)
    end
    self.contentArea.Position = UDim2.fromOffset(8, topOffset + 8)
    self.contentArea.Size = UDim2.new(1, -16, 1, -(topOffset + 16))
end

function NookShoppingGUI:selectTab(tabId)
    self.currentTab = tabId
    debugLog("Tab selected", tabId)

    -- Update nav button styles
    for id, btn in pairs(self.navButtons) do
        local isSelected = (id == tabId)
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = isSelected and COLORS.TEAL or COLORS.BG_WHITE,
            TextColor3 = isSelected and COLORS.TEXT_LIGHT or COLORS.TEXT_DARK,
        }):Play()
    end

    if self.filterBar then
        -- Show filter bar on tabs that use filtering
        self.filterBar.Visible = (tabId == "all" or tabId == "diy" or tabId == "resources")
    end
    self:updateContentLayout()

    self:refreshContent()
end

function NookShoppingGUI:selectCategory(category)
    self.currentCategory = category
    debugLog("Category selected", category)

    for cat, btn in pairs(self.categoryButtons) do
        local isSelected = (cat == category)
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = isSelected and COLORS.TEAL or COLORS.BG_LIGHT,
            TextColor3 = isSelected and COLORS.TEXT_LIGHT or COLORS.TEXT_DARK,
        }):Play()
    end

    self:refreshContent()
end

function NookShoppingGUI:getSortLabel()
    for _, option in ipairs(SORT_OPTIONS) do
        if option.id == self.sortMode then
            return option.label
        end
    end
    return "Name"
end

function NookShoppingGUI:updateFilterButtons()
    if self.sortButton then
        self.sortButton.Text = "Sort: " .. self:getSortLabel()
    end

    if self.availabilityButton then
        self.availabilityButton.Text = self.showAvailableOnly and "Show: Available" or "Show: All"
        self.availabilityButton.BackgroundColor3 = self.showAvailableOnly and COLORS.TEAL or COLORS.BG_LIGHT
        self.availabilityButton.TextColor3 = self.showAvailableOnly and COLORS.TEXT_LIGHT or COLORS.TEXT_DARK
    end
end

function NookShoppingGUI:cycleSortMode()
    for index, option in ipairs(SORT_OPTIONS) do
        if option.id == self.sortMode then
            local nextIndex = (index % #SORT_OPTIONS) + 1
            self.sortMode = SORT_OPTIONS[nextIndex].id
            debugLog("Sort mode", self.sortMode)
            break
        end
    end
    self:updateFilterButtons()
end

function NookShoppingGUI:sortItems(items)
    local rarityRank = {
        LEGENDARY = 1,
        EPIC = 2,
        RARE = 3,
        UNCOMMON = 4,
        COMMON = 5,
    }

    table.sort(items, function(a, b)
        local aAvailable = a.isAvailable and 0 or 1
        local bAvailable = b.isAvailable and 0 or 1
        if aAvailable ~= bAvailable then
            return aAvailable < bAvailable
        end

        if self.sortMode == "price_low" then
            local aPrice = (a.price and a.price > 0) and a.price or math.huge
            local bPrice = (b.price and b.price > 0) and b.price or math.huge
            if aPrice ~= bPrice then
                return aPrice < bPrice
            end
        elseif self.sortMode == "price_high" then
            local aPrice = (a.price and a.price > 0) and a.price or -1
            local bPrice = (b.price and b.price > 0) and b.price or -1
            if aPrice ~= bPrice then
                return aPrice > bPrice
            end
        elseif self.sortMode == "rarity" then
            local aRank = rarityRank[a.rarity or "COMMON"] or 6
            local bRank = rarityRank[b.rarity or "COMMON"] or 6
            if aRank ~= bRank then
                return aRank < bRank
            end
        end

        local aName = string.lower(a.name or a.id or "")
        local bName = string.lower(b.name or b.id or "")
        return aName < bName
    end)
end

function NookShoppingGUI:filterCatalogItems()
    local signature = string.format(
        "%s|%s|%s|%s|%s",
        tostring(self.currentTab),
        tostring(self.currentCategory),
        tostring(self.searchQuery),
        tostring(self.showAvailableOnly),
        tostring(self.sortMode)
    )
    local logFilters = DEBUG and signature ~= self._lastFilterSignature
    if logFilters then
        self._lastFilterSignature = signature
        debugLog(
            "Filtering catalog",
            "category", self.currentCategory,
            "query", self.searchQuery,
            "availableOnly", self.showAvailableOnly,
            "sort", self.sortMode
        )
    end

    local filtered = {}
    local query = string.lower(self.searchQuery or "")

    for _, item in ipairs(self.catalogItems) do
        local matchesCategory = (self.currentCategory == "All" or item.category == self.currentCategory)
        local matchesSearch = (query == "" or string.find(string.lower(item.name or ""), query, 1, true))
        local matchesAvailability = (not self.showAvailableOnly) or item.isAvailable

        if matchesCategory and matchesSearch and matchesAvailability then
            table.insert(filtered, item)
        end
    end

    self:sortItems(filtered)
    if logFilters then
        debugLog("Filter results", #filtered, "of", #self.catalogItems)
    end
    return filtered
end

function NookShoppingGUI:refreshContent()
    if not self.scrollFrame then return end
    debugLog(
        "Refresh content",
        "tab", self.currentTab,
        "category", self.currentCategory,
        "query", self.searchQuery
    )

    -- Clear existing content
    for _, child in ipairs(self.scrollFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("UIGridLayout") then
            child:Destroy()
        end
    end

    if self.currentTab == "home" then
        self:renderHomePage()
    elseif self.currentTab == "all" then
        self:renderAllItems()
    elseif self.currentTab == "diy" then
        self:renderDIYRecipes()
    elseif self.currentTab == "resources" then
        self:renderResources()
    elseif self.currentTab == "deals" then
        self:renderDeals()
    elseif self.currentTab == "bundles" then
        self:renderBundles()
    elseif self.currentTab == "rare" then
        self:renderRareItems()
    elseif self.currentTab == "sell" then
        self:renderSellItems()
    end
end

function NookShoppingGUI:renderHomePage()
    local yOffset = 0

    -- Featured banner
    yOffset = self:createSectionHeader("Featured Items", "✨", yOffset)
    yOffset = self:renderItemGrid(self.featuredItems, yOffset, 6)

    -- Daily deals
    if #self.dailyDeals > 0 then
        yOffset = yOffset + 20
        yOffset = self:createSectionHeader("Today's Deals", "🔥", yOffset)
        yOffset = self:renderItemGrid(self.dailyDeals, yOffset, 8)
    end

    -- Quick access to bundles
    yOffset = yOffset + 20
    yOffset = self:createSectionHeader("Popular Bundles", "📦", yOffset)
    yOffset = self:renderBundlePreview(yOffset)

    self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 20)
end

function NookShoppingGUI:renderAllItems()
    local filtered = self:filterCatalogItems()

    if #filtered == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 100)
        emptyLabel.Position = UDim2.fromOffset(0, 50)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 16
        emptyLabel.TextColor3 = COLORS.TEXT_MUTED
        emptyLabel.Text = "No items found in the catalog"
        emptyLabel.ZIndex = 7
        emptyLabel.Parent = self.scrollFrame
        return
    end

    -- Grid layout
    local gridLayout = Instance.new("UIGridLayout")
    local cardHeight = LAYOUT.ITEM_SIZE + LAYOUT.ITEM_META_HEIGHT
    gridLayout.CellSize = UDim2.fromOffset(LAYOUT.ITEM_SIZE, cardHeight)
    gridLayout.CellPadding = UDim2.fromOffset(LAYOUT.ITEM_PADDING, LAYOUT.ITEM_PADDING)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = self.scrollFrame

    for i, item in ipairs(filtered) do
        self:createCompactItemCard(item, i)
    end

    task.wait()
    self.scrollFrame.CanvasSize = UDim2.fromOffset(0, gridLayout.AbsoluteContentSize.Y + 20)
end

function NookShoppingGUI:renderDeals()
    local yOffset = 0
    yOffset = self:createSectionHeader("Hot Deals - Limited Time!", "🔥", yOffset)

    local deals = {}
    for _, item in ipairs(self.shopItems) do
        if item.isOnSale then
            table.insert(deals, item)
        end
    end

    yOffset = self:renderItemGrid(deals, yOffset, 100)
    self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 20)
end

function NookShoppingGUI:renderBundles()
    local yOffset = 10

    for i, bundle in ipairs(self.bundles) do
        local bundleCard = Instance.new("Frame")
        bundleCard.Name = "Bundle_" .. bundle.id
        bundleCard.Size = UDim2.new(1, -20, 0, 120)
        bundleCard.Position = UDim2.fromOffset(10, yOffset)
        bundleCard.BackgroundColor3 = COLORS.BG_WHITE
        bundleCard.BorderSizePixel = 0
        bundleCard.ZIndex = 7
        bundleCard.Parent = self.scrollFrame

        local bundleCorner = Instance.new("UICorner")
        bundleCorner.CornerRadius = UDim.new(0, 8)
        bundleCorner.Parent = bundleCard

        local bundleStroke = Instance.new("UIStroke")
        bundleStroke.Thickness = 2
        bundleStroke.Color = COLORS.GOLD
        bundleStroke.Parent = bundleCard

        -- Bundle icon
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.fromOffset(60, 60)
        iconLabel.Position = UDim2.fromOffset(20, 30)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = bundle.icon
        iconLabel.TextSize = 40
        iconLabel.ZIndex = 8
        iconLabel.Parent = bundleCard

        -- Bundle name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.fromOffset(200, 24)
        nameLabel.Position = UDim2.fromOffset(90, 15)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 16
        nameLabel.TextColor3 = COLORS.TEXT_DARK
        nameLabel.Text = bundle.name
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 8
        nameLabel.Parent = bundleCard

        -- Description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.fromOffset(300, 20)
        descLabel.Position = UDim2.fromOffset(90, 40)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 12
        descLabel.TextColor3 = COLORS.TEXT_MEDIUM
        descLabel.Text = bundle.description .. " (" .. #bundle.items .. " items)"
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.ZIndex = 8
        descLabel.Parent = bundleCard

        -- Price
        local priceFrame = Instance.new("Frame")
        priceFrame.Size = UDim2.fromOffset(120, 50)
        priceFrame.Position = UDim2.new(1, -140, 0.5, -25)
        priceFrame.BackgroundTransparency = 1
        priceFrame.ZIndex = 8
        priceFrame.Parent = bundleCard

        local originalPrice = Instance.new("TextLabel")
        originalPrice.Size = UDim2.new(1, 0, 0, 16)
        originalPrice.BackgroundTransparency = 1
        originalPrice.Font = Enum.Font.Gotham
        originalPrice.TextSize = 12
        originalPrice.TextColor3 = COLORS.TEXT_MUTED
        originalPrice.Text = self:formatBells(bundle.originalPrice)
        originalPrice.RichText = true
        originalPrice.ZIndex = 9
        originalPrice.Parent = priceFrame

        -- Strikethrough effect
        local strikethrough = Instance.new("Frame")
        strikethrough.Size = UDim2.new(0.8, 0, 0, 1)
        strikethrough.Position = UDim2.new(0.1, 0, 0.5, 0)
        strikethrough.BackgroundColor3 = COLORS.TEXT_MUTED
        strikethrough.BorderSizePixel = 0
        strikethrough.ZIndex = 10
        strikethrough.Parent = originalPrice

        local salePrice = Instance.new("TextLabel")
        salePrice.Size = UDim2.new(1, 0, 0, 24)
        salePrice.Position = UDim2.fromOffset(0, 18)
        salePrice.BackgroundTransparency = 1
        salePrice.Font = Enum.Font.GothamBold
        salePrice.TextSize = 18
        salePrice.TextColor3 = COLORS.SALE_RED
        salePrice.Text = self:formatBells(bundle.price)
        salePrice.ZIndex = 9
        salePrice.Parent = priceFrame

        -- Sale badge
        local saleBadge = Instance.new("TextLabel")
        saleBadge.Size = UDim2.fromOffset(50, 20)
        saleBadge.Position = UDim2.fromOffset(90, 65)
        saleBadge.BackgroundColor3 = COLORS.SALE_RED
        saleBadge.Font = Enum.Font.GothamBold
        saleBadge.TextSize = 11
        saleBadge.TextColor3 = COLORS.TEXT_LIGHT
        saleBadge.Text = "-" .. bundle.salePercent .. "%"
        saleBadge.ZIndex = 9
        saleBadge.Parent = bundleCard

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = saleBadge

        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.fromOffset(90, 32)
        buyBtn.Position = UDim2.new(1, -110, 1, -45)
        buyBtn.BackgroundColor3 = COLORS.TEAL
        buyBtn.BorderSizePixel = 0
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.TextSize = 12
        buyBtn.TextColor3 = COLORS.TEXT_LIGHT
        buyBtn.Text = "Buy Bundle"
        buyBtn.ZIndex = 9
        buyBtn.Parent = bundleCard

        local buyCorner = Instance.new("UICorner")
        buyCorner.CornerRadius = UDim.new(0, 6)
        buyCorner.Parent = buyBtn

        buyBtn.MouseButton1Click:Connect(function()
            self:buyBundle(bundle)
        end)

        yOffset = yOffset + 130
    end

    self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 20)
end

function NookShoppingGUI:renderRareItems()
    local yOffset = 0
    yOffset = self:createSectionHeader("Rare Finds - Limited Stock!", "✨", yOffset)

    local rareItems = {}
    for _, item in ipairs(self.shopItems) do
        if item.rarity == "RARE" or item.rarity == "EPIC" or item.rarity == "LEGENDARY" then
            table.insert(rareItems, item)
        end
    end

    -- Sort by rarity (legendary first)
    table.sort(rareItems, function(a, b)
        local order = { LEGENDARY = 1, EPIC = 2, RARE = 3 }
        return (order[a.rarity] or 4) < (order[b.rarity] or 4)
    end)

    yOffset = self:renderItemGrid(rareItems, yOffset, 100)
    self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 20)
end

function NookShoppingGUI:renderDIYRecipes()
    local yOffset = 0

    -- Info banner
    local banner = Instance.new("Frame")
    banner.Size = UDim2.new(1, -10, 0, 50)
    banner.Position = UDim2.fromOffset(5, yOffset)
    banner.BackgroundColor3 = Color3.fromRGB(139, 90, 43) -- Brown color for DIY
    banner.BorderSizePixel = 0
    banner.ZIndex = 7
    banner.Parent = self.scrollFrame

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UDim.new(0, 8)
    bannerCorner.Parent = banner

    local bannerLabel = Instance.new("TextLabel")
    bannerLabel.Size = UDim2.fromScale(1, 1)
    bannerLabel.BackgroundTransparency = 1
    bannerLabel.Font = Enum.Font.GothamBold
    bannerLabel.TextSize = 14
    bannerLabel.TextColor3 = Color3.new(1, 1, 1)
    bannerLabel.Text = "🔨 DIY Recipes - Craft these at a workbench!"
    bannerLabel.ZIndex = 8
    bannerLabel.Parent = banner

    yOffset = yOffset + 60

    -- Filter recipes by search
    local query = string.lower(self.searchQuery or "")
    local filtered = {}

    for _, recipe in ipairs(self.craftingRecipes) do
        local name = recipe.name or recipe.result and recipe.result.name or recipe.itemId or ""
        local matchesSearch = (query == "" or string.find(string.lower(name), query, 1, true))
        if matchesSearch then
            table.insert(filtered, recipe)
        end
    end

    if #filtered == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, -20, 0, 100)
        emptyLabel.Position = UDim2.fromOffset(10, yOffset)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 16
        emptyLabel.TextColor3 = COLORS.TEXT_MUTED
        emptyLabel.Text = #self.craftingRecipes == 0 and "No DIY recipes available" or "No recipes match your search"
        emptyLabel.ZIndex = 7
        emptyLabel.Parent = self.scrollFrame
        self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 120)
        return
    end

    -- Sort by name
    table.sort(filtered, function(a, b)
        local aName = a.name or (a.result and a.result.name) or a.itemId or ""
        local bName = b.name or (b.result and b.result.name) or b.itemId or ""
        return string.lower(aName) < string.lower(bName)
    end)

    -- Render recipe cards
    for i, recipe in ipairs(filtered) do
        local recipeCard = self:createRecipeCard(recipe, i, yOffset)
        yOffset = yOffset + 110
    end

    self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 20)
end

function NookShoppingGUI:createRecipeCard(recipe, index, yOffset)
    local result = recipe.result or {}
    local recipeName = recipe.name or result.name or recipe.itemId or "Unknown"
    local spriteIndex = result.spriteIndex or recipe.spriteIndex

    local card = Instance.new("Frame")
    card.Name = "Recipe_" .. (recipe.id or index)
    card.Size = UDim2.new(1, -16, 0, 100)
    card.Position = UDim2.fromOffset(8, yOffset)
    card.BackgroundColor3 = COLORS.BG_WHITE
    card.BorderSizePixel = 0
    card.ZIndex = 7
    card.Parent = self.scrollFrame

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Thickness = 1
    cardStroke.Color = COLORS.BROWN
    cardStroke.Parent = card

    -- Result item sprite
    local spriteFrame = Instance.new("Frame")
    spriteFrame.Name = "SpriteFrame"
    spriteFrame.Size = UDim2.fromOffset(64, 64)
    spriteFrame.Position = UDim2.fromOffset(16, 18)
    spriteFrame.BackgroundColor3 = COLORS.BG_LIGHT
    spriteFrame.BorderSizePixel = 0
    spriteFrame.ZIndex = 8
    spriteFrame.Parent = card

    local spriteCorner = Instance.new("UICorner")
    spriteCorner.CornerRadius = UDim.new(0, 6)
    spriteCorner.Parent = spriteFrame

    if spriteIndex and self.spriteConfig then
        local spriteImage = Instance.new("ImageLabel")
        spriteImage.Size = UDim2.fromScale(1, 1)
        spriteImage.BackgroundTransparency = 1
        spriteImage.Image = self.spriteConfig.SPRITESHEET_ID
        spriteImage.ImageRectSize = Vector2.new(self.spriteConfig.SPRITE_SIZE, self.spriteConfig.SPRITE_SIZE)

        local col = (spriteIndex - 1) % self.spriteConfig.COLUMNS
        local row = math.floor((spriteIndex - 1) / self.spriteConfig.COLUMNS)
        spriteImage.ImageRectOffset = Vector2.new(
            col * self.spriteConfig.SPRITE_SIZE,
            row * self.spriteConfig.SPRITE_SIZE
        )
        spriteImage.ZIndex = 9
        spriteImage.Parent = spriteFrame
    else
        local placeholder = Instance.new("TextLabel")
        placeholder.Size = UDim2.fromScale(1, 1)
        placeholder.BackgroundTransparency = 1
        placeholder.Text = "🔨"
        placeholder.TextSize = 32
        placeholder.ZIndex = 9
        placeholder.Parent = spriteFrame
    end

    -- Recipe name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.fromOffset(300, 24)
    nameLabel.Position = UDim2.fromOffset(96, 12)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = COLORS.TEXT_DARK
    nameLabel.Text = recipeName
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 8
    nameLabel.Parent = card

    -- Materials list
    local materials = recipe.materials or {}
    local materialsText = "Materials: "
    for i, mat in ipairs(materials) do
        local matName = mat.name or mat.itemId or "?"
        local matCount = mat.count or 1
        materialsText = materialsText .. matName .. " x" .. matCount
        if i < #materials then
            materialsText = materialsText .. ", "
        end
    end

    local materialsLabel = Instance.new("TextLabel")
    materialsLabel.Size = UDim2.new(1, -180, 0, 40)
    materialsLabel.Position = UDim2.fromOffset(96, 38)
    materialsLabel.BackgroundTransparency = 1
    materialsLabel.Font = Enum.Font.Gotham
    materialsLabel.TextSize = 12
    materialsLabel.TextColor3 = COLORS.TEXT_MEDIUM
    materialsLabel.Text = materialsText
    materialsLabel.TextXAlignment = Enum.TextXAlignment.Left
    materialsLabel.TextWrapped = true
    materialsLabel.ZIndex = 8
    materialsLabel.Parent = card

    -- Craft time
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.fromOffset(80, 20)
    timeLabel.Position = UDim2.new(1, -100, 0, 12)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 11
    timeLabel.TextColor3 = COLORS.TEXT_MUTED
    timeLabel.Text = "⏱️ " .. (recipe.time or 6) .. "s"
    timeLabel.TextXAlignment = Enum.TextXAlignment.Right
    timeLabel.ZIndex = 8
    timeLabel.Parent = card

    -- "View in Workbench" button
    local viewBtn = Instance.new("TextButton")
    viewBtn.Size = UDim2.fromOffset(120, 30)
    viewBtn.Position = UDim2.new(1, -136, 1, -42)
    viewBtn.BackgroundColor3 = COLORS.BROWN
    viewBtn.BorderSizePixel = 0
    viewBtn.Font = Enum.Font.GothamBold
    viewBtn.TextSize = 11
    viewBtn.TextColor3 = COLORS.TEXT_LIGHT
    viewBtn.Text = "View Recipe"
    viewBtn.ZIndex = 9
    viewBtn.Parent = card

    local viewCorner = Instance.new("UICorner")
    viewCorner.CornerRadius = UDim.new(0, 6)
    viewCorner.Parent = viewBtn

    viewBtn.MouseButton1Click:Connect(function()
        -- Close this GUI and open the crafting menu
        self:hide()
        -- Try to open the crafting GUI via GUIManager
        local GUIManager = self.playerGui:FindFirstChild("GUIManager")
        if GUIManager then
            local manager = require(GUIManager)
            if manager and manager.showGui then
                manager.showGui("crafting")
            end
        end
    end)

    viewBtn.MouseEnter:Connect(function()
        TweenService:Create(viewBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BROWN_DARK}):Play()
    end)
    viewBtn.MouseLeave:Connect(function()
        TweenService:Create(viewBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BROWN}):Play()
    end)

    return card
end

function NookShoppingGUI:renderResources()
    local yOffset = 0

    -- Filter by search query
    local query = string.lower(self.searchQuery)
    local filtered = {}

    for _, item in ipairs(self.resourceItems) do
        local matchesSearch = (query == "" or string.find(string.lower(item.name), query, 1, true))
        if matchesSearch then
            table.insert(filtered, item)
        end
    end

    -- Group by category subcategories
    local woodItems = {}
    local mineralItems = {}
    local natureItems = {}
    local shellItems = {}
    local seasonalItems = {}
    local toolItems = {}
    local otherItems = {}

    for _, item in ipairs(filtered) do
        local id = item.id
        if string.find(id, "wood") or id == "bamboo-piece" or id == "young-spring-bamboo" then
            table.insert(woodItems, item)
        elseif id == "iron-nugget" or id == "gold-nugget" or id == "clay" or id == "stone" then
            table.insert(mineralItems, item)
        elseif string.find(id, "shell") or id == "conch" or id == "coral" or id == "giant-clam" or id == "sand-dollar" or id == "sea-snail" or id == "venus-comb" or id == "cowrie" then
            table.insert(shellItems, item)
        elseif string.find(id, "star") or string.find(id, "snow") or id == "maple-leaf" or id == "cherry-blossom-petal" or id == "acorn" or id == "pine-cone" or id == "mushroom" then
            table.insert(seasonalItems, item)
        elseif string.find(id, "flimsy") or id == "ladder" or id == "vaulting-pole" then
            table.insert(toolItems, item)
        elseif id == "tree-branch" or id == "weeds" or id == "coconut" or id == "wasp-nest" then
            table.insert(natureItems, item)
        else
            table.insert(otherItems, item)
        end
    end

    -- Always in stock banner
    local banner = Instance.new("Frame")
    banner.Size = UDim2.new(1, -10, 0, 40)
    banner.Position = UDim2.fromOffset(5, yOffset)
    banner.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    banner.BorderSizePixel = 0
    banner.ZIndex = 7
    banner.Parent = self.scrollFrame

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UDim.new(0, 8)
    bannerCorner.Parent = banner

    local bannerLabel = Instance.new("TextLabel")
    bannerLabel.Size = UDim2.fromScale(1, 1)
    bannerLabel.BackgroundTransparency = 1
    bannerLabel.Font = Enum.Font.GothamBold
    bannerLabel.TextSize = 14
    bannerLabel.TextColor3 = COLORS.TEXT_LIGHT
    bannerLabel.Text = "Always In Stock - Essential crafting materials!"
    bannerLabel.ZIndex = 8
    bannerLabel.Parent = banner

    yOffset = yOffset + 50

    -- Render each category
    if #woodItems > 0 then
        yOffset = self:createSectionHeader("Wood & Bamboo", "🪵", yOffset)
        yOffset = self:renderItemGrid(woodItems, yOffset, 100)
        yOffset = yOffset + 10
    end

    if #mineralItems > 0 then
        yOffset = self:createSectionHeader("Minerals & Ores", "🔩", yOffset)
        yOffset = self:renderItemGrid(mineralItems, yOffset, 100)
        yOffset = yOffset + 10
    end

    if #natureItems > 0 then
        yOffset = self:createSectionHeader("Nature Items", "🌿", yOffset)
        yOffset = self:renderItemGrid(natureItems, yOffset, 100)
        yOffset = yOffset + 10
    end

    if #shellItems > 0 then
        yOffset = self:createSectionHeader("Shells", "🐚", yOffset)
        yOffset = self:renderItemGrid(shellItems, yOffset, 100)
        yOffset = yOffset + 10
    end

    if #seasonalItems > 0 then
        yOffset = self:createSectionHeader("Seasonal Materials", "⭐", yOffset)
        yOffset = self:renderItemGrid(seasonalItems, yOffset, 100)
        yOffset = yOffset + 10
    end

    if #toolItems > 0 then
        yOffset = self:createSectionHeader("Basic Tools", "🪓", yOffset)
        yOffset = self:renderItemGrid(toolItems, yOffset, 100)
        yOffset = yOffset + 10
    end

    if #otherItems > 0 then
        yOffset = self:createSectionHeader("Other Resources", "📦", yOffset)
        yOffset = self:renderItemGrid(otherItems, yOffset, 100)
    end

    self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 20)
end

function NookShoppingGUI:renderSellItems()
    local yOffset = 0

    -- Info banner
    local banner = Instance.new("Frame")
    banner.Size = UDim2.new(1, -10, 0, 50)
    banner.Position = UDim2.fromOffset(5, yOffset)
    banner.BackgroundColor3 = COLORS.GOLD
    banner.BorderSizePixel = 0
    banner.ZIndex = 7
    banner.Parent = self.scrollFrame

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UDim.new(0, 8)
    bannerCorner.Parent = banner

    local bannerLabel = Instance.new("TextLabel")
    bannerLabel.Size = UDim2.fromScale(1, 1)
    bannerLabel.BackgroundTransparency = 1
    bannerLabel.Font = Enum.Font.GothamBold
    bannerLabel.TextSize = 14
    bannerLabel.TextColor3 = COLORS.BROWN_DARK
    bannerLabel.Text = "💰 Sell your items for Bells! Click to sell."
    bannerLabel.ZIndex = 8
    bannerLabel.Parent = banner

    yOffset = yOffset + 60

    -- Get player inventory
    local inventorySnapshot = self:getPlayerInventory()

    if not inventorySnapshot or not inventorySnapshot.slots then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, -20, 0, 100)
        emptyLabel.Position = UDim2.fromOffset(10, yOffset)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 16
        emptyLabel.TextColor3 = COLORS.TEXT_MUTED
        emptyLabel.Text = "No items in inventory to sell"
        emptyLabel.ZIndex = 7
        emptyLabel.Parent = self.scrollFrame
        self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 120)
        return
    end

    -- Convert slots to sellable items
    local sellableItems = {}
    for slotIndex, slotData in pairs(inventorySnapshot.slots) do
        if slotData and slotData.itemId and slotData.count and slotData.count > 0 then
            -- Get item info for sell price
            local itemInfo = self:getItemSellPrice(slotData.itemId)
            table.insert(sellableItems, {
                slotIndex = slotIndex,
                id = slotData.itemId,
                name = itemInfo.name or slotData.itemId,
                count = slotData.count,
                sellPrice = itemInfo.sellPrice or 0,
                spriteIndex = itemInfo.spriteIndex,
                icon = itemInfo.icon,
            })
        end
    end

    if #sellableItems == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, -20, 0, 100)
        emptyLabel.Position = UDim2.fromOffset(10, yOffset)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 16
        emptyLabel.TextColor3 = COLORS.TEXT_MUTED
        emptyLabel.Text = "Your inventory is empty!"
        emptyLabel.ZIndex = 7
        emptyLabel.Parent = self.scrollFrame
        self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 120)
        return
    end

    yOffset = self:createSectionHeader("Your Items", "🎒", yOffset)

    -- Create grid for sellable items
    local gridContainer = Instance.new("Frame")
    gridContainer.Name = "SellGridContainer"
    gridContainer.Size = UDim2.new(1, -10, 0, 0)
    gridContainer.Position = UDim2.fromOffset(5, yOffset)
    gridContainer.BackgroundTransparency = 1
    gridContainer.AutomaticSize = Enum.AutomaticSize.Y
    gridContainer.ZIndex = 7
    gridContainer.Parent = self.scrollFrame

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.fromOffset(LAYOUT.ITEM_SIZE + 20, LAYOUT.ITEM_SIZE + 44)
    gridLayout.CellPadding = UDim2.fromOffset(LAYOUT.ITEM_PADDING, LAYOUT.ITEM_PADDING)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = gridContainer

    for i, item in ipairs(sellableItems) do
        self:createSellItemCard(item, i, gridContainer)
    end

    task.wait()
    yOffset = yOffset + gridLayout.AbsoluteContentSize.Y + 10

    -- Sell All button
    local totalValue = 0
    for _, item in ipairs(sellableItems) do
        totalValue = totalValue + (item.sellPrice * item.count)
    end

    if totalValue > 0 then
        local sellAllFrame = Instance.new("Frame")
        sellAllFrame.Size = UDim2.new(1, -20, 0, 50)
        sellAllFrame.Position = UDim2.fromOffset(10, yOffset + 10)
        sellAllFrame.BackgroundColor3 = COLORS.TEAL
        sellAllFrame.BorderSizePixel = 0
        sellAllFrame.ZIndex = 7
        sellAllFrame.Parent = self.scrollFrame

        local sellAllCorner = Instance.new("UICorner")
        sellAllCorner.CornerRadius = UDim.new(0, 10)
        sellAllCorner.Parent = sellAllFrame

        local sellAllBtn = Instance.new("TextButton")
        sellAllBtn.Size = UDim2.fromScale(1, 1)
        sellAllBtn.BackgroundTransparency = 1
        sellAllBtn.Font = Enum.Font.GothamBold
        sellAllBtn.TextSize = 16
        sellAllBtn.TextColor3 = COLORS.TEXT_LIGHT
        sellAllBtn.Text = "💰 Sell All - " .. self:formatBells(totalValue) .. " Bells"
        sellAllBtn.ZIndex = 8
        sellAllBtn.Parent = sellAllFrame

        sellAllBtn.MouseButton1Click:Connect(function()
            self:sellAllItems(sellableItems)
        end)

        sellAllBtn.MouseEnter:Connect(function()
            TweenService:Create(sellAllFrame, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.TEAL_HOVER}):Play()
        end)
        sellAllBtn.MouseLeave:Connect(function()
            TweenService:Create(sellAllFrame, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.TEAL}):Play()
        end)

        yOffset = yOffset + 70
    end

    self.scrollFrame.CanvasSize = UDim2.fromOffset(0, yOffset + 20)
end

function NookShoppingGUI:createSellItemCard(item, index, parent)
    local cardWidth = LAYOUT.ITEM_SIZE + 20
    local cardHeight = LAYOUT.ITEM_SIZE + LAYOUT.ITEM_META_HEIGHT

    local card = Instance.new("Frame")
    card.Name = "SellItem_" .. item.id
    card.Size = UDim2.fromOffset(cardWidth, cardHeight)
    card.BackgroundColor3 = COLORS.BG_WHITE
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.ZIndex = 8
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Thickness = 1
    cardStroke.Color = COLORS.GOLD
    cardStroke.Parent = card

    -- Item sprite or icon
    local spriteFrame = Instance.new("Frame")
    spriteFrame.Size = UDim2.fromOffset(LAYOUT.ITEM_SIZE - 4, LAYOUT.ITEM_SIZE - 8)
    spriteFrame.Position = UDim2.fromOffset(10 + 2, 4)
    spriteFrame.BackgroundTransparency = 1
    spriteFrame.ZIndex = 9
    spriteFrame.Parent = card

    if item.spriteIndex then
        local sprite = Instance.new("ImageLabel")
        sprite.Size = UDim2.fromScale(0.85, 0.85)
        sprite.Position = UDim2.fromScale(0.5, 0.5)
        sprite.AnchorPoint = Vector2.new(0.5, 0.5)
        sprite.BackgroundTransparency = 1
        sprite.ZIndex = 10
        sprite.Parent = spriteFrame
        self.spriteConfig.applySprite(sprite, item.spriteIndex)
    elseif item.icon then
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.fromScale(1, 1)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = item.icon
        iconLabel.TextSize = 28
        iconLabel.ZIndex = 10
        iconLabel.Parent = spriteFrame
    end

    -- Count badge
    if item.count > 1 then
        local countBadge = Instance.new("TextLabel")
        countBadge.Size = UDim2.fromOffset(24, 16)
        countBadge.Position = UDim2.new(1, -26, 0, 2)
        countBadge.BackgroundColor3 = COLORS.TEAL
        countBadge.Font = Enum.Font.GothamBold
        countBadge.TextSize = 10
        countBadge.TextColor3 = COLORS.TEXT_LIGHT
        countBadge.Text = "x" .. item.count
        countBadge.ZIndex = 15
        countBadge.Parent = card

        local countCorner = Instance.new("UICorner")
        countCorner.CornerRadius = UDim.new(0, 4)
        countCorner.Parent = countBadge
    end

    -- Price display
    local priceFrame = Instance.new("Frame")
    priceFrame.Size = UDim2.new(1, 0, 0, 20)
    priceFrame.Position = UDim2.fromOffset(0, LAYOUT.ITEM_SIZE - 4)
    priceFrame.BackgroundColor3 = COLORS.GOLD
    priceFrame.BorderSizePixel = 0
    priceFrame.ZIndex = 10
    priceFrame.Parent = card

    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.fromScale(1, 1)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 10
    priceLabel.TextColor3 = COLORS.BROWN_DARK
    priceLabel.Text = self:formatBells(item.sellPrice * item.count)
    priceLabel.ZIndex = 11
    priceLabel.Parent = priceFrame

    -- Sell button
    local sellBtn = Instance.new("TextButton")
    sellBtn.Size = UDim2.new(1, 0, 0, 22)
    sellBtn.Position = UDim2.new(0, 0, 1, -22)
    sellBtn.BackgroundColor3 = COLORS.TEAL
    sellBtn.BorderSizePixel = 0
    sellBtn.Font = Enum.Font.GothamBold
    sellBtn.TextSize = 11
    sellBtn.TextColor3 = COLORS.TEXT_LIGHT
    sellBtn.Text = "Sell"
    sellBtn.ZIndex = 10
    sellBtn.Parent = card

    local sellCorner = Instance.new("UICorner")
    sellCorner.CornerRadius = UDim.new(0, 6)
    sellCorner.Parent = sellBtn

    -- Only round bottom corners
    local topCover = Instance.new("Frame")
    topCover.Size = UDim2.new(1, 0, 0, 6)
    topCover.BackgroundColor3 = COLORS.TEAL
    topCover.BorderSizePixel = 0
    topCover.ZIndex = 10
    topCover.Parent = sellBtn

    sellBtn.MouseButton1Click:Connect(function()
        self:showSellConfirmation(item)
    end)

    sellBtn.MouseEnter:Connect(function()
        TweenService:Create(sellBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.TEAL_HOVER}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.1), {Thickness = 2}):Play()
    end)
    sellBtn.MouseLeave:Connect(function()
        TweenService:Create(sellBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.TEAL}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.1), {Thickness = 1}):Play()
    end)

    return card
end

function NookShoppingGUI:showSellConfirmation(item)
    -- Remove existing detail panel
    local existing = self.gui:FindFirstChild("SellDetailPanel")
    if existing then existing:Destroy() end

    local panel = Instance.new("Frame")
    panel.Name = "SellDetailPanel"
    panel.Size = UDim2.fromOffset(280, 280)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.BackgroundColor3 = COLORS.BG_CREAM
    panel.BorderSizePixel = 0
    panel.ZIndex = 100
    panel.Parent = self.gui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Thickness = 3
    panelStroke.Color = COLORS.GOLD
    panelStroke.Parent = panel

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -8, 0, 8)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = COLORS.TEXT_LIGHT
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.ZIndex = 102
    closeBtn.Parent = panel

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        panel:Destroy()
    end)

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 0, 30)
    titleLabel.Position = UDim2.fromOffset(15, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = COLORS.TEXT_DARK
    titleLabel.Text = "💰 Sell " .. item.name
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 101
    titleLabel.Parent = panel

    -- Item info
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -30, 0, 20)
    infoLabel.Position = UDim2.fromOffset(15, 45)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 12
    infoLabel.TextColor3 = COLORS.TEXT_MEDIUM
    infoLabel.Text = "You have " .. item.count .. " in inventory"
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.ZIndex = 101
    infoLabel.Parent = panel

    -- Price per unit
    local pricePerLabel = Instance.new("TextLabel")
    pricePerLabel.Size = UDim2.new(1, -30, 0, 20)
    pricePerLabel.Position = UDim2.fromOffset(15, 70)
    pricePerLabel.BackgroundTransparency = 1
    pricePerLabel.Font = Enum.Font.Gotham
    pricePerLabel.TextSize = 12
    pricePerLabel.TextColor3 = COLORS.TEXT_MEDIUM
    pricePerLabel.Text = "Price per item: " .. self:formatBells(item.sellPrice) .. " Bells"
    pricePerLabel.TextXAlignment = Enum.TextXAlignment.Left
    pricePerLabel.ZIndex = 101
    pricePerLabel.Parent = panel

    -- Quantity selector
    local qtyFrame = Instance.new("Frame")
    qtyFrame.Size = UDim2.fromOffset(150, 40)
    qtyFrame.Position = UDim2.new(0.5, -75, 0, 100)
    qtyFrame.BackgroundColor3 = COLORS.BG_WHITE
    qtyFrame.BorderSizePixel = 0
    qtyFrame.ZIndex = 101
    qtyFrame.Parent = panel

    local qtyCorner = Instance.new("UICorner")
    qtyCorner.CornerRadius = UDim.new(0, 8)
    qtyCorner.Parent = qtyFrame

    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.fromOffset(40, 40)
    minusBtn.BackgroundColor3 = COLORS.TEAL
    minusBtn.Text = "-"
    minusBtn.TextColor3 = COLORS.TEXT_LIGHT
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.TextSize = 22
    minusBtn.ZIndex = 102
    minusBtn.Parent = qtyFrame

    local minusCorner = Instance.new("UICorner")
    minusCorner.CornerRadius = UDim.new(0, 8)
    minusCorner.Parent = minusBtn

    local qtyLabel = Instance.new("TextLabel")
    qtyLabel.Size = UDim2.fromOffset(70, 40)
    qtyLabel.Position = UDim2.fromOffset(40, 0)
    qtyLabel.BackgroundTransparency = 1
    qtyLabel.Font = Enum.Font.GothamBold
    qtyLabel.TextSize = 20
    qtyLabel.TextColor3 = COLORS.TEXT_DARK
    qtyLabel.Text = tostring(item.count)
    qtyLabel.ZIndex = 102
    qtyLabel.Parent = qtyFrame

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.fromOffset(40, 40)
    plusBtn.Position = UDim2.fromOffset(110, 0)
    plusBtn.BackgroundColor3 = COLORS.TEAL
    plusBtn.Text = "+"
    plusBtn.TextColor3 = COLORS.TEXT_LIGHT
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.TextSize = 22
    plusBtn.ZIndex = 102
    plusBtn.Parent = qtyFrame

    local plusCorner = Instance.new("UICorner")
    plusCorner.CornerRadius = UDim.new(0, 8)
    plusCorner.Parent = plusBtn

    local quantity = item.count

    -- Total display
    local totalLabel = Instance.new("TextLabel")
    totalLabel.Size = UDim2.new(1, -30, 0, 30)
    totalLabel.Position = UDim2.fromOffset(15, 155)
    totalLabel.BackgroundTransparency = 1
    totalLabel.Font = Enum.Font.GothamBold
    totalLabel.TextSize = 18
    totalLabel.TextColor3 = COLORS.GOLD_DARK
    totalLabel.Text = "Total: " .. self:formatBells(item.sellPrice * quantity) .. " Bells"
    totalLabel.ZIndex = 101
    totalLabel.Parent = panel

    local function updateTotal()
        totalLabel.Text = "Total: " .. self:formatBells(item.sellPrice * quantity) .. " Bells"
        qtyLabel.Text = tostring(quantity)
    end

    minusBtn.MouseButton1Click:Connect(function()
        if quantity > 1 then
            quantity = quantity - 1
            updateTotal()
        end
    end)

    plusBtn.MouseButton1Click:Connect(function()
        if quantity < item.count then
            quantity = quantity + 1
            updateTotal()
        end
    end)

    -- Sell button
    local sellBtn = Instance.new("TextButton")
    sellBtn.Size = UDim2.fromOffset(200, 45)
    sellBtn.Position = UDim2.new(0.5, -100, 1, -65)
    sellBtn.BackgroundColor3 = COLORS.TEAL
    sellBtn.Font = Enum.Font.GothamBold
    sellBtn.TextSize = 16
    sellBtn.TextColor3 = COLORS.TEXT_LIGHT
    sellBtn.Text = "💰 Sell Now"
    sellBtn.ZIndex = 101
    sellBtn.Parent = panel

    local sellCorner = Instance.new("UICorner")
    sellCorner.CornerRadius = UDim.new(0, 10)
    sellCorner.Parent = sellBtn

    sellBtn.MouseButton1Click:Connect(function()
        self:sellItem(item.id, quantity, item.slotIndex)
        panel:Destroy()
    end)

    sellBtn.MouseEnter:Connect(function()
        TweenService:Create(sellBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.TEAL_HOVER}):Play()
    end)
    sellBtn.MouseLeave:Connect(function()
        TweenService:Create(sellBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.TEAL}):Play()
    end)

    -- Animate in
    panel.Size = UDim2.fromOffset(0, 0)
    TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(280, 280)
    }):Play()
end

function NookShoppingGUI:getPlayerInventory()
    -- Try to get inventory from InventoryClient
    local inventoryClient = self.inventoryClient
    if inventoryClient and inventoryClient.getInventorySnapshot then
        return inventoryClient:getInventorySnapshot()
    end
    return self.playerInventory
end

function NookShoppingGUI:getItemSellPrice(itemId)
    -- Check resources first
    for _, resource in ipairs(RESOURCE_ITEMS) do
        if resource.id == itemId then
            return {
                name = resource.name,
                sellPrice = resource.sellPrice,
                icon = resource.icon,
            }
        end
    end

    -- Check shop items
    local catalogItem = self.catalogItemMap and self.catalogItemMap[itemId]
    if catalogItem then
        return {
            name = catalogItem.name,
            sellPrice = catalogItem.sellPrice
                or math.floor((catalogItem.originalPrice or catalogItem.price or 0) * 0.25),
            spriteIndex = catalogItem.spriteIndex,
            icon = catalogItem.icon,
        }
    end

    -- Default fallback
    return {
        name = itemId,
        sellPrice = 100,
    }
end

function NookShoppingGUI:sellItem(itemId, count, slotIndex)
    if not self.shopRemote then
        debugWarn("ShopTransaction remote missing; sell aborted", itemId)
        return
    end

    debugLog("Sell request", itemId, "count", count, "slot", slotIndex)
    self.shopRemote:FireServer("SellItem", {
        itemId = itemId,
        count = count,
        slotIndex = slotIndex,
    })
    -- Refresh after a short delay
    task.delay(0.3, function()
        if self.currentTab == "sell" then
            self:refreshContent()
        end
    end)
end

function NookShoppingGUI:sellAllItems(items)
    if not self.shopRemote then
        debugWarn("ShopTransaction remote missing; sell-all aborted")
        return
    end

    debugLog("Sell all request", #items, "items")
    for _, item in ipairs(items) do
        self.shopRemote:FireServer("SellItem", {
            itemId = item.id,
            count = item.count,
            slotIndex = item.slotIndex,
        })
    end
    -- Refresh after selling
    task.delay(0.5, function()
        if self.currentTab == "sell" then
            self:refreshContent()
        end
    end)
end

function NookShoppingGUI:createSectionHeader(title, icon, yOffset)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 30)
    header.Position = UDim2.fromOffset(10, yOffset)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 16
    header.TextColor3 = COLORS.TEXT_DARK
    header.Text = icon .. "  " .. title
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.ZIndex = 7
    header.Parent = self.scrollFrame

    return yOffset + 35
end

function NookShoppingGUI:renderItemGrid(items, yOffset, maxItems)
    local gridContainer = Instance.new("Frame")
    gridContainer.Name = "GridContainer"
    gridContainer.Size = UDim2.new(1, -10, 0, 0)
    gridContainer.Position = UDim2.fromOffset(5, yOffset)
    gridContainer.BackgroundTransparency = 1
    gridContainer.AutomaticSize = Enum.AutomaticSize.Y
    gridContainer.ZIndex = 7
    gridContainer.Parent = self.scrollFrame

    local gridLayout = Instance.new("UIGridLayout")
    local cardHeight = LAYOUT.ITEM_SIZE + 44
    gridLayout.CellSize = UDim2.fromOffset(LAYOUT.ITEM_SIZE, cardHeight)
    gridLayout.CellPadding = UDim2.fromOffset(LAYOUT.ITEM_PADDING, LAYOUT.ITEM_PADDING)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = gridContainer

    for i, item in ipairs(items) do
        if i > maxItems then break end
        self:createCompactItemCard(item, i, gridContainer)
    end

    task.wait()
    return yOffset + gridLayout.AbsoluteContentSize.Y + 10
end

function NookShoppingGUI:renderBundlePreview(yOffset)
    local previewContainer = Instance.new("Frame")
    previewContainer.Size = UDim2.new(1, -10, 0, 80)
    previewContainer.Position = UDim2.fromOffset(5, yOffset)
    previewContainer.BackgroundTransparency = 1
    previewContainer.ZIndex = 7
    previewContainer.Parent = self.scrollFrame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 10)
    layout.Parent = previewContainer

    for i, bundle in ipairs(self.bundles) do
        local card = Instance.new("TextButton")
        card.Size = UDim2.fromOffset(180, 70)
        card.BackgroundColor3 = COLORS.BG_WHITE
        card.BorderSizePixel = 0
        card.Text = ""
        card.LayoutOrder = i
        card.ZIndex = 8
        card.Parent = previewContainer

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 6)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = COLORS.GOLD
        cardStroke.Thickness = 2
        cardStroke.Parent = card

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.fromOffset(40, 40)
        iconLabel.Position = UDim2.fromOffset(10, 15)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = bundle.icon
        iconLabel.TextSize = 28
        iconLabel.ZIndex = 9
        iconLabel.Parent = card

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.fromOffset(120, 20)
        nameLabel.Position = UDim2.fromOffset(55, 15)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = COLORS.TEXT_DARK
        nameLabel.Text = bundle.name
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 9
        nameLabel.Parent = card

        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.fromOffset(120, 16)
        priceLabel.Position = UDim2.fromOffset(55, 38)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Font = Enum.Font.GothamMedium
        priceLabel.TextSize = 11
        priceLabel.TextColor3 = COLORS.SALE_RED
        priceLabel.Text = self:formatBells(bundle.price)
        priceLabel.TextXAlignment = Enum.TextXAlignment.Left
        priceLabel.ZIndex = 9
        priceLabel.Parent = card

        card.MouseButton1Click:Connect(function()
            self:selectTab("bundles")
        end)
    end

    return yOffset + 90
end

function NookShoppingGUI:createCompactItemCard(item, index, parent)
    parent = parent or self.scrollFrame

    local cardHeight = LAYOUT.ITEM_SIZE + 44
    local isUnavailable = item.isAvailable == false
    local isSoldOut = (item.stock == 0) and not isUnavailable

    local card = Instance.new("TextButton")
    card.Name = "Item_" .. item.id
    card.Size = UDim2.fromOffset(LAYOUT.ITEM_SIZE, cardHeight)
    card.BackgroundColor3 = isUnavailable and COLORS.BG_LIGHT or COLORS.BG_WHITE
    card.BorderSizePixel = 0
    card.Text = ""
    card.AutoButtonColor = false
    card.LayoutOrder = index
    card.ZIndex = 8
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    -- Subtle shadow effect
    local cardShadow = Instance.new("ImageLabel")
    cardShadow.Name = "Shadow"
    cardShadow.Size = UDim2.new(1, 6, 1, 6)
    cardShadow.Position = UDim2.fromOffset(-3, 2)
    cardShadow.BackgroundTransparency = 1
    cardShadow.Image = "rbxassetid://1316045217"
    cardShadow.ImageColor3 = Color3.new(0, 0, 0)
    cardShadow.ImageTransparency = 0.85
    cardShadow.ScaleType = Enum.ScaleType.Slice
    cardShadow.SliceCenter = Rect.new(10, 10, 118, 118)
    cardShadow.ZIndex = 7
    cardShadow.Parent = card

    -- Rarity indicator (colored border)
    local rarityData = RARITY[item.rarity] or RARITY.COMMON
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Thickness = (item.rarity == "LEGENDARY" or item.rarity == "EPIC") and 2 or 1
    cardStroke.Color = isUnavailable and COLORS.OUT_OF_STOCK or rarityData.color
    cardStroke.Parent = card

    -- Unavailable / out of stock overlay
    if isUnavailable or isSoldOut then
        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundColor3 = isUnavailable and Color3.fromRGB(60, 60, 60) or Color3.new(0, 0, 0)
        overlay.BackgroundTransparency = isUnavailable and 0.35 or 0.5
        overlay.ZIndex = 20
        overlay.Parent = card

        local overlayCorner = Instance.new("UICorner")
        overlayCorner.CornerRadius = UDim.new(0, 6)
        overlayCorner.Parent = overlay

        local soldLabel = Instance.new("TextLabel")
        soldLabel.Size = UDim2.fromScale(1, 1)
        soldLabel.BackgroundTransparency = 1
        soldLabel.Font = Enum.Font.GothamBold
        soldLabel.TextSize = 10
        soldLabel.TextColor3 = COLORS.TEXT_LIGHT
        soldLabel.Text = isUnavailable and "UNAVAILABLE" or "SOLD OUT"
        soldLabel.ZIndex = 21
        soldLabel.Parent = overlay
    end

    -- Item sprite or emoji icon (centered in top portion)
    local spriteSize = LAYOUT.ITEM_SIZE - 18
    local spriteFrame = Instance.new("Frame")
    spriteFrame.Size = UDim2.fromOffset(spriteSize, spriteSize)
    spriteFrame.Position = UDim2.fromOffset((LAYOUT.ITEM_SIZE - spriteSize) / 2, 6)
    spriteFrame.BackgroundTransparency = 1
    spriteFrame.ZIndex = 9
    spriteFrame.Parent = card

    if item.spriteIndex then
        local sprite = Instance.new("ImageLabel")
        sprite.Size = UDim2.fromScale(0.9, 0.9)
        sprite.Position = UDim2.fromScale(0.5, 0.5)
        sprite.AnchorPoint = Vector2.new(0.5, 0.5)
        sprite.BackgroundTransparency = 1
        sprite.ImageTransparency = isUnavailable and 0.45 or 0
        sprite.ZIndex = 10
        sprite.Parent = spriteFrame
        self.spriteConfig.applySprite(sprite, item.spriteIndex)
    elseif item.icon then
        -- Use emoji icon for resource items
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.fromScale(1, 1)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = item.icon
        iconLabel.TextSize = 30
        iconLabel.TextTransparency = isUnavailable and 0.45 or 0
        iconLabel.ZIndex = 10
        iconLabel.Parent = spriteFrame
    end

    -- Sale badge
    if item.isOnSale and not isUnavailable then
        local saleBadge = Instance.new("TextLabel")
        saleBadge.Size = UDim2.fromOffset(26, 13)
        saleBadge.Position = UDim2.fromOffset(3, 3)
        saleBadge.BackgroundColor3 = COLORS.SALE_RED
        saleBadge.Font = Enum.Font.GothamBold
        saleBadge.TextSize = 8
        saleBadge.TextColor3 = COLORS.TEXT_LIGHT
        saleBadge.Text = "-" .. item.salePercent .. "%"
        saleBadge.ZIndex = 15
        saleBadge.Parent = card

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = saleBadge
    end

    -- Stock indicator for limited items
    if item.stock > 0 and item.stock <= 5 then
        local stockBadge = Instance.new("TextLabel")
        stockBadge.Size = UDim2.fromOffset(20, 12)
        stockBadge.Position = UDim2.new(1, -25, 0, 3)
        stockBadge.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
        stockBadge.Font = Enum.Font.GothamBold
        stockBadge.TextSize = 8
        stockBadge.TextColor3 = COLORS.TEXT_LIGHT
        stockBadge.Text = item.stock .. "!"
        stockBadge.ZIndex = 15
        stockBadge.Parent = card

        local stockCorner = Instance.new("UICorner")
        stockCorner.CornerRadius = UDim.new(0, 4)
        stockCorner.Parent = stockBadge
    end

    local nameHeight = 16
    local priceHeight = 20

    -- Item name (centered below sprite)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -8, 0, nameHeight)
    nameLabel.Position = UDim2.new(0, 4, 0, LAYOUT.ITEM_SIZE - 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 10
    nameLabel.TextColor3 = isUnavailable and COLORS.TEXT_MUTED or COLORS.TEXT_DARK
    nameLabel.Text = item.name or item.id
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 10
    nameLabel.Parent = card

    -- Price display at bottom
    local priceFrame = Instance.new("Frame")
    priceFrame.Size = UDim2.new(1, 0, 0, priceHeight)
    priceFrame.Position = UDim2.new(0, 0, 1, -priceHeight)
    priceFrame.BackgroundColor3 = isUnavailable and COLORS.BG_LIGHT or COLORS.GOLD
    priceFrame.BorderSizePixel = 0
    priceFrame.ZIndex = 10
    priceFrame.Parent = card

    local priceCorner = Instance.new("UICorner")
    priceCorner.CornerRadius = UDim.new(0, 6)
    priceCorner.Parent = priceFrame

    -- Only round bottom corners
    local topCover = Instance.new("Frame")
    topCover.Size = UDim2.new(1, 0, 0, 6)
    topCover.BackgroundColor3 = priceFrame.BackgroundColor3
    topCover.BorderSizePixel = 0
    topCover.ZIndex = 10
    topCover.Parent = priceFrame

    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.fromScale(1, 1)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 10
    priceLabel.TextColor3 = isUnavailable and COLORS.TEXT_MUTED or COLORS.BROWN_DARK
    if isUnavailable then
        priceLabel.Text = "Unavailable"
    else
        priceLabel.Text = self:formatBells(item.price)
    end
    priceLabel.ZIndex = 11
    priceLabel.Parent = priceFrame

    -- Hover effects
    card.MouseEnter:Connect(function()
        if not isUnavailable and item.stock ~= 0 then
            TweenService:Create(card, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(245, 250, 255)}):Play()
            TweenService:Create(cardStroke, TweenInfo.new(0.1), {Thickness = 2}):Play()
        end
    end)

    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.1), {
            BackgroundColor3 = isUnavailable and COLORS.BG_LIGHT or COLORS.BG_WHITE,
        }):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.1), {
            Thickness = (item.rarity == "LEGENDARY" or item.rarity == "EPIC") and 2 or 1
        }):Play()
    end)

    -- Click to show detail/buy
    card.MouseButton1Click:Connect(function()
        if not isUnavailable and item.stock ~= 0 then
            self:showItemDetail(item)
        end
    end)

    return card
end

function NookShoppingGUI:showItemDetail(item)
    -- Remove existing detail panel
    local existing = self.gui:FindFirstChild("ItemDetailPanel")
    if existing then existing:Destroy() end

    local panel = Instance.new("Frame")
    panel.Name = "ItemDetailPanel"
    panel.Size = UDim2.fromOffset(300, 320)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.BackgroundColor3 = COLORS.BG_CREAM
    panel.BorderSizePixel = 0
    panel.ZIndex = 100
    panel.Parent = self.gui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Thickness = 3
    panelStroke.Color = COLORS.BROWN
    panelStroke.Parent = panel

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -8, 0, 8)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = COLORS.TEXT_LIGHT
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.ZIndex = 102
    closeBtn.Parent = panel

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        panel:Destroy()
    end)

    -- Item sprite (larger)
    local spriteFrame = Instance.new("Frame")
    spriteFrame.Size = UDim2.fromOffset(100, 100)
    spriteFrame.Position = UDim2.new(0.5, -50, 0, 20)
    spriteFrame.BackgroundColor3 = COLORS.BG_WHITE
    spriteFrame.BorderSizePixel = 0
    spriteFrame.ZIndex = 101
    spriteFrame.Parent = panel

    local spriteCorner = Instance.new("UICorner")
    spriteCorner.CornerRadius = UDim.new(0, 8)
    spriteCorner.Parent = spriteFrame

    if item.spriteIndex then
        local sprite = Instance.new("ImageLabel")
        sprite.Size = UDim2.fromScale(0.8, 0.8)
        sprite.Position = UDim2.fromScale(0.5, 0.5)
        sprite.AnchorPoint = Vector2.new(0.5, 0.5)
        sprite.BackgroundTransparency = 1
        sprite.ZIndex = 102
        sprite.Parent = spriteFrame
        self.spriteConfig.applySprite(sprite, item.spriteIndex)
    end

    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -20, 0, 24)
    nameLabel.Position = UDim2.fromOffset(10, 130)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = COLORS.TEXT_DARK
    nameLabel.Text = item.name
    nameLabel.ZIndex = 101
    nameLabel.Parent = panel

    -- Rarity
    local rarityData = RARITY[item.rarity] or RARITY.COMMON
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.fromOffset(80, 20)
    rarityLabel.Position = UDim2.new(0.5, -40, 0, 156)
    rarityLabel.BackgroundColor3 = rarityData.color
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.TextSize = 11
    rarityLabel.TextColor3 = COLORS.TEXT_LIGHT
    rarityLabel.Text = rarityData.name
    rarityLabel.ZIndex = 101
    rarityLabel.Parent = panel

    local rarityCorner = Instance.new("UICorner")
    rarityCorner.CornerRadius = UDim.new(0, 4)
    rarityCorner.Parent = rarityLabel

    -- Stock info
    local stockText = item.stock == -1 and "In Stock" or (item.stock > 0 and "Only " .. item.stock .. " left!" or "Out of Stock")
    local stockLabel = Instance.new("TextLabel")
    stockLabel.Size = UDim2.new(1, -20, 0, 18)
    stockLabel.Position = UDim2.fromOffset(10, 182)
    stockLabel.BackgroundTransparency = 1
    stockLabel.Font = Enum.Font.Gotham
    stockLabel.TextSize = 12
    stockLabel.TextColor3 = item.stock == 0 and COLORS.ERROR or (item.stock > 0 and item.stock <= 5 and Color3.fromRGB(255, 150, 50) or COLORS.SUCCESS)
    stockLabel.Text = stockText
    stockLabel.ZIndex = 101
    stockLabel.Parent = panel

    -- Price
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(1, -20, 0, 30)
    priceLabel.Position = UDim2.fromOffset(10, 205)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 22
    priceLabel.TextColor3 = item.isOnSale and COLORS.SALE_RED or COLORS.GOLD_DARK
    priceLabel.Text = self:formatBells(item.price)
    priceLabel.ZIndex = 101
    priceLabel.Parent = panel

    if item.isOnSale then
        local originalLabel = Instance.new("TextLabel")
        originalLabel.Size = UDim2.fromOffset(100, 16)
        originalLabel.Position = UDim2.fromOffset(10, 235)
        originalLabel.BackgroundTransparency = 1
        originalLabel.Font = Enum.Font.Gotham
        originalLabel.TextSize = 12
        originalLabel.TextColor3 = COLORS.TEXT_MUTED
        originalLabel.Text = "Was: " .. self:formatBells(item.originalPrice)
        originalLabel.TextXAlignment = Enum.TextXAlignment.Left
        originalLabel.ZIndex = 101
        originalLabel.Parent = panel
    end

    -- Quantity selector
    local qtyFrame = Instance.new("Frame")
    qtyFrame.Size = UDim2.fromOffset(120, 32)
    qtyFrame.Position = UDim2.fromOffset(20, 260)
    qtyFrame.BackgroundColor3 = COLORS.BG_WHITE
    qtyFrame.BorderSizePixel = 0
    qtyFrame.ZIndex = 101
    qtyFrame.Parent = panel

    local qtyCorner = Instance.new("UICorner")
    qtyCorner.CornerRadius = UDim.new(0, 6)
    qtyCorner.Parent = qtyFrame

    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.fromOffset(32, 32)
    minusBtn.BackgroundColor3 = COLORS.TEAL
    minusBtn.Text = "-"
    minusBtn.TextColor3 = COLORS.TEXT_LIGHT
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.TextSize = 18
    minusBtn.ZIndex = 102
    minusBtn.Parent = qtyFrame

    local minusCorner = Instance.new("UICorner")
    minusCorner.CornerRadius = UDim.new(0, 6)
    minusCorner.Parent = minusBtn

    local qtyLabel = Instance.new("TextLabel")
    qtyLabel.Size = UDim2.fromOffset(56, 32)
    qtyLabel.Position = UDim2.fromOffset(32, 0)
    qtyLabel.BackgroundTransparency = 1
    qtyLabel.Font = Enum.Font.GothamBold
    qtyLabel.TextSize = 16
    qtyLabel.TextColor3 = COLORS.TEXT_DARK
    qtyLabel.Text = "1"
    qtyLabel.ZIndex = 102
    qtyLabel.Parent = qtyFrame

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.fromOffset(32, 32)
    plusBtn.Position = UDim2.fromOffset(88, 0)
    plusBtn.BackgroundColor3 = COLORS.TEAL
    plusBtn.Text = "+"
    plusBtn.TextColor3 = COLORS.TEXT_LIGHT
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.TextSize = 18
    plusBtn.ZIndex = 102
    plusBtn.Parent = qtyFrame

    local plusCorner = Instance.new("UICorner")
    plusCorner.CornerRadius = UDim.new(0, 6)
    plusCorner.Parent = plusBtn

    local quantity = 1
    local maxQty = item.stock == -1 and 99 or item.stock

    minusBtn.MouseButton1Click:Connect(function()
        if quantity > 1 then
            quantity = quantity - 1
            qtyLabel.Text = tostring(quantity)
        end
    end)

    plusBtn.MouseButton1Click:Connect(function()
        if quantity < maxQty then
            quantity = quantity + 1
            qtyLabel.Text = tostring(quantity)
        end
    end)

    -- Add to cart button
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.fromOffset(130, 36)
    buyBtn.Position = UDim2.fromOffset(150, 258)
    buyBtn.BackgroundColor3 = COLORS.TEAL
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 14
    buyBtn.TextColor3 = COLORS.TEXT_LIGHT
    buyBtn.Text = "Add to Cart"
    buyBtn.ZIndex = 101
    buyBtn.Parent = panel

    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 8)
    buyCorner.Parent = buyBtn

    buyBtn.MouseButton1Click:Connect(function()
        self:addToCart(item, quantity)
        panel:Destroy()
    end)

    buyBtn.MouseEnter:Connect(function()
        TweenService:Create(buyBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.TEAL_HOVER}):Play()
    end)
    buyBtn.MouseLeave:Connect(function()
        TweenService:Create(buyBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.TEAL}):Play()
    end)

    -- Animate in
    panel.Size = UDim2.fromOffset(0, 0)
    TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(300, 320)
    }):Play()
end

function NookShoppingGUI:buyItem(item, quantity)
    self:addToCart(item, quantity)
end

function NookShoppingGUI:buyBundle(bundle)
    if self.bells < bundle.price then
        self:showNotification(false, { reason = "Not enough bells!" })
        debugWarn("Bundle buy blocked", bundle.id, "insufficient bells", self.bells, "needed", bundle.price)
        return
    end

    -- Buy each item in the bundle
    if not self.shopRemote then
        self:showNotification(false, { reason = "Shop unavailable" })
        debugWarn("ShopTransaction remote missing; bundle buy aborted", bundle.id)
        return
    end

    debugLog("Bundle buy request", bundle.id, "price", bundle.price)
    local bundleItems = {}
    for _, item in ipairs(bundle.items) do
        table.insert(bundleItems, {
            itemId = item.id,
            count = 1,
        })
    end

    self.shopRemote:FireServer("BuyBundle", {
        bundleId = bundle.id,
        bundleName = bundle.name,
        price = bundle.price,
        items = bundleItems,
        deliveryMethod = "nookplane",
    })
end

function NookShoppingGUI:formatBells(amount)
    local formatted = tostring(amount or 0):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return formatted
end

function NookShoppingGUI:updateBells(bells)
    self.bells = bells
    if self.bellsLabel then
        self.bellsLabel.Text = self:formatBells(bells) .. " Bells"
    end
end

function NookShoppingGUI:showSellNotification(success, data)
    local toast = Instance.new("Frame")
    toast.Name = "SellToast"
    toast.Size = UDim2.fromOffset(300, 50)
    toast.Position = UDim2.new(0.5, -150, 1, 10)
    toast.BackgroundColor3 = success and COLORS.GOLD or COLORS.ERROR
    toast.BorderSizePixel = 0
    toast.ZIndex = 200
    toast.Parent = self.gui

    local toastCorner = Instance.new("UICorner")
    toastCorner.CornerRadius = UDim.new(0, 10)
    toastCorner.Parent = toast

    local toastLabel = Instance.new("TextLabel")
    toastLabel.Size = UDim2.fromScale(1, 1)
    toastLabel.BackgroundTransparency = 1
    toastLabel.Font = Enum.Font.GothamBold
    toastLabel.TextSize = 14
    toastLabel.TextColor3 = success and COLORS.BROWN_DARK or COLORS.TEXT_LIGHT
    toastLabel.Text = success and ("Sold for " .. self:formatBells(data.bells or 0) .. " Bells!") or (data.reason or "Sell failed")
    toastLabel.ZIndex = 201
    toastLabel.Parent = toast

    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -150, 1, -70)
    }):Play()

    task.delay(2.5, function()
        if toast.Parent then
            TweenService:Create(toast, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -150, 1, 10)}):Play()
            task.wait(0.2)
            toast:Destroy()
        end
    end)
end

function NookShoppingGUI:showNotification(success, data)
    -- Remove any existing toasts
    local existingToast = self.gui:FindFirstChild("PurchaseToast")
    if existingToast then existingToast:Destroy() end

    local isCartAdd = success and data.action == "cart_add"
    local isCartCheckout = success and data.action == "cart_checkout"
    local isDelivery = success and data.deliveryMethod == "nookplane"
    local toastHeight = (isDelivery and not isCartAdd) and 70 or 50

    local toast = Instance.new("Frame")
    toast.Name = "PurchaseToast"
    toast.Size = UDim2.fromOffset(340, toastHeight)
    toast.Position = UDim2.new(0.5, -170, 1, 10)
    toast.BackgroundColor3 = success and COLORS.TEAL or COLORS.ERROR
    toast.BorderSizePixel = 0
    toast.ZIndex = 200
    toast.Parent = self.gui

    local toastCorner = Instance.new("UICorner")
    toastCorner.CornerRadius = UDim.new(0, 12)
    toastCorner.Parent = toast

    -- Add shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.fromOffset(-10, 2)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = 199
    shadow.Parent = toast

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.fromOffset(40, 40)
    iconLabel.Position = UDim2.fromOffset(12, toastHeight/2 - 20)
    iconLabel.BackgroundTransparency = 1
    if success then
        if isCartAdd then
            iconLabel.Text = "🧺"
        elseif isDelivery then
            iconLabel.Text = "✈️"
        else
            iconLabel.Text = "✅"
        end
    else
        iconLabel.Text = "❌"
    end
    iconLabel.TextSize = 28
    iconLabel.ZIndex = 202
    iconLabel.Parent = toast

    -- Main message
    local itemName = data.itemName or data.itemId or data.bundleName or "item"
    local count = data.count or data.bundleCount or 1
    local mainText = ""
    if success then
        if isCartAdd then
            mainText = "Added to cart: " .. itemName .. (count > 1 and (" x" .. count) or "")
        elseif isCartCheckout then
            local cartCount = data.cartCount or count or 1
            mainText = "Order placed (" .. cartCount .. " items)"
        elseif data.bundleName then
            mainText = "Ordered " .. itemName .. " (" .. count .. " items)"
        elseif count > 1 then
            mainText = "Purchased " .. count .. "x " .. itemName .. "!"
        else
            mainText = "Purchased " .. itemName .. "!"
        end
    else
        mainText = data.reason or "Purchase failed"
    end

    local toastLabel = Instance.new("TextLabel")
    toastLabel.Size = UDim2.new(1, -70, 0, 24)
    toastLabel.Position = UDim2.fromOffset(56, isDelivery and 10 or 13)
    toastLabel.BackgroundTransparency = 1
    toastLabel.Font = Enum.Font.GothamBold
    toastLabel.TextSize = 14
    toastLabel.TextColor3 = COLORS.TEXT_LIGHT
    toastLabel.Text = mainText
    toastLabel.TextXAlignment = Enum.TextXAlignment.Left
    toastLabel.ZIndex = 201
    toastLabel.Parent = toast

    -- Delivery message (if applicable)
    if isDelivery and not isCartAdd then
        local deliveryLabel = Instance.new("TextLabel")
        deliveryLabel.Size = UDim2.new(1, -70, 0, 20)
        deliveryLabel.Position = UDim2.fromOffset(56, 36)
        deliveryLabel.BackgroundTransparency = 1
        deliveryLabel.Font = Enum.Font.Gotham
        deliveryLabel.TextSize = 12
        deliveryLabel.TextColor3 = Color3.fromRGB(200, 255, 245)
        deliveryLabel.Text = data.message or "DAL plane arriving soon with your package!"
        deliveryLabel.TextXAlignment = Enum.TextXAlignment.Left
        deliveryLabel.ZIndex = 201
        deliveryLabel.Parent = toast
    end

    -- Price deducted indicator
    if success and data.price and data.price > 0 then
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.fromOffset(80, 20)
        priceLabel.Position = UDim2.new(1, -90, 0.5, -10)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Font = Enum.Font.GothamBold
        priceLabel.TextSize = 12
        priceLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
        priceLabel.Text = "-" .. self:formatBells(data.price)
        priceLabel.TextXAlignment = Enum.TextXAlignment.Right
        priceLabel.ZIndex = 201
        priceLabel.Parent = toast
    end

    -- Animate in
    TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -170, 1, -90)
    }):Play()

    -- Auto-dismiss
    local displayTime = isDelivery and 4 or 2.5
    task.delay(displayTime, function()
        if toast.Parent then
            TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -170, 1, 20)
            }):Play()
            task.wait(0.25)
            if toast.Parent then toast:Destroy() end
        end
    end)
end

function NookShoppingGUI:connectToServer()
    if self.currencyRemote then
        self.currencyConnection = self.currencyRemote.OnClientEvent:Connect(function(action, data)
            if action == "UpdateAll" or action == "UpdateBells" then
                self:updateBells(data.bells or data.amount or 0)
            end
        end)
    else
        debugWarn("CurrencyEvent remote missing")
    end

    local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
    if remoteEventsFolder then
        -- Wait for shop feedback remote (created by server during init)
        local shopFeedback = remoteEventsFolder:WaitForChild("ShopFeedback", 10)
        if shopFeedback then
            debugLog("ShopFeedback remote connected")
            self.shopFeedbackConnection = shopFeedback.OnClientEvent:Connect(function(action, data)
                debugLog("ShopFeedback received", action)
                if action == "PurchaseSuccess" then
                    if self.pendingCartCheckout then
                        self.pendingCartCheckout = false
                        self:clearCart()
                    end
                    self:showNotification(true, data)
                    if self.currencyRemote then
                        self.currencyRemote:FireServer("GetCurrency")
                    end
                elseif action == "PurchaseFailed" then
                    if self.pendingCartCheckout then
                        self.pendingCartCheckout = false
                    end
                    self:showNotification(false, data)
                elseif action == "SellSuccess" then
                    self:showSellNotification(true, data)
                    if self.currencyRemote then
                        self.currencyRemote:FireServer("GetCurrency")
                    end
                    -- Refresh sell tab
                    if self.currentTab == "sell" then
                        task.delay(0.2, function()
                            self:refreshContent()
                        end)
                    end
                elseif action == "SellFailed" then
                    self:showSellNotification(false, data)
                end
            end)
        else
            debugWarn("ShopFeedback remote not found after waiting")
        end
    else
        debugWarn("RemoteEvents folder not found")
    end

    if self.currencyRemote then
        self.currencyRemote:FireServer("GetCurrency")
    end
end

function NookShoppingGUI:show()
    if self.visible then return end
    if not self.gui then return end

    self.visible = true
    self.gui.Enabled = true
    debugLog("Show GUI")

    -- Default to catalog view for the full item browser experience
    self:selectTab("all")

    if self.currencyRemote then
        self.currencyRemote:FireServer("GetCurrency")
    end

    -- Animate in
    if self.container then
        self.container.Position = UDim2.new(0.5, 0, 0.6, 0)
        TweenService:Create(self.container, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.fromScale(0.5, 0.5)
        }):Play()
    end
end

function NookShoppingGUI:hide()
    if not self.visible then return end

    self.visible = false
    debugLog("Hide GUI")

    if self.container then
        local tween = TweenService:Create(self.container, TweenInfo.new(0.15), {
            Position = UDim2.new(0.5, 0, 0.6, 0)
        })
        tween:Play()
        tween.Completed:Wait()
    end

    if self.gui then
        self.gui.Enabled = false
    end

    -- Close any detail panels
    local detailPanel = self.gui and self.gui:FindFirstChild("ItemDetailPanel")
    if detailPanel then detailPanel:Destroy() end
end

function NookShoppingGUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function NookShoppingGUI:isVisible()
    return self.visible
end

function NookShoppingGUI:setInventoryClient(inventoryClient)
    self.inventoryClient = inventoryClient

    -- Connect to inventory changes to refresh sell tab
    if inventoryClient and inventoryClient.onInventoryChanged then
        self.inventoryConnection = inventoryClient:onInventoryChanged(function(snapshot)
            self.playerInventory = snapshot
            -- Refresh if on sell tab
            if self.visible and self.currentTab == "sell" then
                self:refreshContent()
            end
        end)
    end
end

function NookShoppingGUI:cleanup()
    if self.currencyConnection then
        self.currencyConnection:Disconnect()
    end
    if self.shopFeedbackConnection then
        self.shopFeedbackConnection:Disconnect()
    end
    if self.inventoryConnection then
        self.inventoryConnection:Disconnect()
    end
    self:hide()
end

-- Alias methods
NookShoppingGUI.Show = NookShoppingGUI.show
NookShoppingGUI.Hide = NookShoppingGUI.hide
NookShoppingGUI.Toggle = NookShoppingGUI.toggle

return NookShoppingGUI
