return {
    {
        name = "ShovelDig",
        type = "RemoteEvent",
        server = {
            "src/server/ShovelSystem.luau",
        },
        client = {
            "src/client/Modules/ShovelClient.luau",
        },
    },
    {
        name = "InventoryEvent",
        type = "RemoteEvent",
        server = {
            "src/server/init.server.luau",
            "src/server/TreeShakingSystem.luau",
        },
        client = {
            "src/client/Modules/RecipesInventoryGUI.luau",
            "src/client/Modules/CraftingGUI.luau",
            "src/client/Modules/DIYWorkbenchGUI.luau",
        },
    },
    {
        name = "CurrencyEvent",
        type = "RemoteEvent",
        server = {
            "src/server/CurrencyManager.luau",
        },
        client = {
            "src/client/Modules/CurrencyDisplay.luau",
            "src/client/Modules/ShopGUI.luau",
            "src/client/Modules/NookShoppingGUI.luau",
            "src/client/Modules/HomeBuildingGUI.luau",
        },
    },
    {
        name = "CraftingEvent",
        type = "RemoteEvent",
        server = {
            "src/server/CraftingSetup.luau",
        },
        client = {
            "src/client/Modules/CraftingGUI.luau",
            "src/client/Modules/DIYWorkbenchGUI.luau",
            "src/client/Modules/RecipesInventoryGUI.luau",
        },
    },
    {
        name = "FishingEvent",
        type = "RemoteEvent",
        server = {
            "src/server/init.server.luau",
            "src/server/FishingSystem.luau",
        },
        client = {
            "src/client/Modules/FishingController.luau",
        },
    },
    {
        name = "QuestEvent",
        type = "RemoteEvent",
        server = {
            "src/server/QuestService.luau",
        },
        client = {
            "src/client/Modules/QuestGUI.luau",
        },
    },
    {
        name = "GenerateIsland",
        type = "RemoteEvent",
        server = {
            "src/server/IslandGenerationInterface.server.luau",
        },
        client = {
            "src/client/IslandGenerationGUI.client.luau",
        },
    },
    {
        name = "SaveIsland",
        type = "RemoteEvent",
        server = {
            "src/server/IslandGenerationInterface.server.luau",
        },
        client = {
            "src/client/IslandGenerationGUI.client.luau",
        },
    },
    {
        name = "ClearIsland",
        type = "RemoteEvent",
        server = {
            "src/server/IslandGenerationInterface.server.luau",
        },
        client = {
            "src/client/IslandGenerationGUI.client.luau",
        },
    },
    {
        name = "UpdateProgress",
        type = "RemoteEvent",
        server = {
            "src/server/IslandGenerationInterface.server.luau",
        },
        client = {
            "src/client/IslandGenerationGUI.client.luau",
        },
    },
    {
        name = "PremiumPurchase",
        type = "RemoteEvent",
        server = {
            "src/server/ProductPurchaseHandler.luau",
        },
        client = {
            "src/client/Modules/PremiumShopGUI.luau",
        },
    },
    {
        name = "BalloonHit",
        type = "RemoteEvent",
        server = {
            "src/server/init.server.luau",
        },
        client = {
            "src/shared/ToolObjects.luau",
        },
    },
}
