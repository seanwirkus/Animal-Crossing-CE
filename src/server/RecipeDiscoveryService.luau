local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ItemDataFetcher = require(sharedFolder:WaitForChild("ItemDataFetcher"))
local RecipeDiscoveryConfig = require(sharedFolder:WaitForChild("recipes"):WaitForChild("RecipeDiscoveryConfig"))

local RecipeDiscoveryService = {}

local recipeRemote = ReplicatedStorage:FindFirstChild("RecipeDiscoveryEvent") or Instance.new("RemoteEvent")
recipeRemote.Name = "RecipeDiscoveryEvent"
recipeRemote.Parent = ReplicatedStorage

local playerRecipes: { [number]: { recipes: { [string]: boolean }, history: { [string]: string } } } = {}

local function ensureState(player: Player)
    local state = playerRecipes[player.UserId]
    if state then
        return state
    end

    state = { recipes = {}, history = {} }
    playerRecipes[player.UserId] = state
    return state
end

local function isValidRecipe(recipeId: string): boolean
    if not recipeId or recipeId == "" then
        return false
    end

    local recipe = ItemDataFetcher.getCraftingRecipe and ItemDataFetcher.getCraftingRecipe(recipeId)
    if recipe then
        return true
    end

    -- Some entries exist only as craftable items but still need to be discoverable
    local entry = ItemDataFetcher.getItemDefinition and ItemDataFetcher.getItemDefinition(recipeId)
    return entry ~= nil
end

local function pushRecipes(player: Player)
    local state = ensureState(player)
    local discovered = {}
    for recipeId in pairs(state.recipes) do
        table.insert(discovered, recipeId)
    end
    table.sort(discovered)

    recipeRemote:FireClient(player, "DiscoveredRecipes", {
        recipes = discovered,
        count = #discovered,
    })
end

function RecipeDiscoveryService.unlockRecipes(player: Player, recipeIds: { string }?, reason: string?)
    if not player or type(recipeIds) ~= "table" then
        return
    end

    local state = ensureState(player)
    local unlocked = {}

    for _, recipeId in ipairs(recipeIds) do
        if type(recipeId) == "string" and isValidRecipe(recipeId) and not state.recipes[recipeId] then
            state.recipes[recipeId] = true
            state.history[recipeId] = reason or "system"
            table.insert(unlocked, recipeId)
        end
    end

    if #unlocked > 0 then
        recipeRemote:FireClient(player, "RecipesUnlocked", {
            recipes = unlocked,
            reason = reason,
        })
        pushRecipes(player)
    end
end

function RecipeDiscoveryService.unlockForInventoryLevel(player: Player, level: number)
    local recipeIds = RecipeDiscoveryConfig.inventoryUnlocks and RecipeDiscoveryConfig.inventoryUnlocks[level]
    if recipeIds then
        RecipeDiscoveryService.unlockRecipes(player, recipeIds, string.format("inventory_level_%d", level))
    end
end

function RecipeDiscoveryService.unlockForTag(player: Player, tag: string?)
    if not tag then
        return
    end

    local recipeIds = RecipeDiscoveryConfig.stationUnlocks and RecipeDiscoveryConfig.stationUnlocks[tag]
    if recipeIds then
        RecipeDiscoveryService.unlockRecipes(player, recipeIds, tag)
    end
end

function RecipeDiscoveryService.getDiscoveredMap(player: Player)
    local state = ensureState(player)
    return state.recipes
end

function RecipeDiscoveryService.filterRecipes(player: Player, recipes)
    local state = ensureState(player)
    if not recipes or type(recipes) ~= "table" then
        return {}
    end

    local filtered = {}
    for _, recipe in ipairs(recipes) do
        local recipeId = recipe.itemId or recipe.id
        if not recipeId then
            continue
        end

        if state.recipes[recipeId] then
            table.insert(filtered, recipe)
        end
    end

    return filtered
end

function RecipeDiscoveryService.handlePlayerAdded(player: Player)
    ensureState(player)
    RecipeDiscoveryService.unlockRecipes(player, RecipeDiscoveryConfig.starterRecipes, "starter")
    pushRecipes(player)
end

function RecipeDiscoveryService.handlePlayerRemoving(player: Player)
    playerRecipes[player.UserId] = nil
end

function RecipeDiscoveryService.init()
    for _, player in ipairs(Players:GetPlayers()) do
        RecipeDiscoveryService.handlePlayerAdded(player)
    end

    Players.PlayerAdded:Connect(RecipeDiscoveryService.handlePlayerAdded)
    Players.PlayerRemoving:Connect(RecipeDiscoveryService.handlePlayerRemoving)

    recipeRemote.OnServerEvent:Connect(function(player, action)
        if action == "RequestDiscovered" then
            pushRecipes(player)
        end
    end)
end

return RecipeDiscoveryService
