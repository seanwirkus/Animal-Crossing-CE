--[[
    ProductPurchaseHandler.luau
    Handles Robux purchases via MarketplaceService
    Processes developer product receipts and grants rewards
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductPurchaseHandler = {}

-- Product definitions (must match client-side PremiumShopGUI)
local PRODUCTS = {
    [0] = { -- Replace 0 with your actual product ID
        id = "bells_small",
        name = "Bells Bundle (Small)",
        reward = { bells = 5000, miles = 0 },
    },
    -- Add more products here with their actual product IDs
    -- Example:
    -- [123456789] = {
    --     id = "bells_medium",
    --     name = "Bells Bundle (Medium)",
    --     reward = { bells = 12000, miles = 0 },
    -- },
}

-- Get CurrencyManager
local function getCurrencyManager()
    local success, currencyManager = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CurrencyManager"))
    end)
    if success and currencyManager then
        return currencyManager
    end
    return nil
end

-- Process receipt
local function processReceipt(receiptInfo)
    local success, errorMessage = pcall(function()
        local playerId = receiptInfo.PlayerId
        local productId = receiptInfo.ProductId
        local purchaseId = receiptInfo.PurchaseId

        -- Get product data
        local product = PRODUCTS[productId]
        if not product then
            warn("[ProductPurchaseHandler] ❌ Unknown product ID:", productId)
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        -- Get player
        local player = Players:GetPlayerByUserId(playerId)
        if not player then
            warn("[ProductPurchaseHandler] ❌ Player not found for ID:", playerId)
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        -- Check if already processed (prevent duplicate grants)
        -- TODO: Implement receipt tracking in DataStore to prevent duplicates

        -- Grant rewards
        local currencyManager = getCurrencyManager()
        if currencyManager then
            if product.reward.bells and product.reward.bells > 0 then
                currencyManager.addBells(player, product.reward.bells)
                print(
                    string.format(
                        "[ProductPurchaseHandler] ✅ Granted %d Bells to %s",
                        product.reward.bells,
                        player.Name
                    )
                )
            end

            if product.reward.miles and product.reward.miles > 0 then
                currencyManager.addMiles(player, product.reward.miles)
                print(
                    string.format(
                        "[ProductPurchaseHandler] ✅ Granted %d Nook Miles to %s",
                        product.reward.miles,
                        player.Name
                    )
                )
            end
        else
            warn("[ProductPurchaseHandler] ❌ CurrencyManager not available")
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        -- Notify client
        local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if remoteEventsFolder then
            local purchaseRemote = remoteEventsFolder:FindFirstChild("PremiumPurchase")
            if purchaseRemote then
                purchaseRemote:FireClient(player, true, product.id, string.format("Purchased %s!", product.name))
            end
        end

        print(
            string.format(
                "[ProductPurchaseHandler] ✅ Processed purchase: %s (%s) - Product: %s",
                player.Name,
                purchaseId,
                product.name
            )
        )

        return Enum.ProductPurchaseDecision.PurchaseGranted
    end)

    if not success then
        warn("[ProductPurchaseHandler] ❌ Error processing receipt:", errorMessage)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    return errorMessage -- This is the ProductPurchaseDecision from the pcall
end

function ProductPurchaseHandler.init()
    -- Ensure RemoteEvent exists for client notifications
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = ReplicatedStorage
    end

    local purchaseRemote = remoteEventsFolder:FindFirstChild("PremiumPurchase")
    if not purchaseRemote then
        purchaseRemote = Instance.new("RemoteEvent")
        purchaseRemote.Name = "PremiumPurchase"
        purchaseRemote.Parent = remoteEventsFolder
        print("[ProductPurchaseHandler] ✅ Created PremiumPurchase RemoteEvent")
    end

    -- Set up ProcessReceipt handler
    MarketplaceService.ProcessReceipt = processReceipt

    -- Count products
    local productCount = 0
    for _ in pairs(PRODUCTS) do
        productCount = productCount + 1
    end

    print("[ProductPurchaseHandler] ✅ Initialized - Ready to process purchases")
    print(string.format("[ProductPurchaseHandler] 📦 Registered %d products", productCount))

    -- Warn if no products configured
    if productCount == 0 then
        warn("[ProductPurchaseHandler] ⚠️ No products configured! Add product IDs to PRODUCTS table.")
        warn("[ProductPurchaseHandler] ⚠️ To add products:")
        warn("[ProductPurchaseHandler]    1. Create Developer Products in Roblox Creator Dashboard")
        warn("[ProductPurchaseHandler]    2. Add product IDs to PRODUCTS table in this file")
        warn("[ProductPurchaseHandler]    3. Update PremiumShopGUI.luau with matching product IDs")
    end
end

return ProductPurchaseHandler
