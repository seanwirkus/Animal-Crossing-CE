local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local SpriteManifest = require(sharedFolder:WaitForChild("SpriteManifest"))
local ItemsData = require(sharedFolder:WaitForChild("data"):WaitForChild("ItemsData"))

local ItemDataFetcher = {}

local rawItems = {}
local rawRecipes = {}
local rawMeta = {}

if ItemsData then
    rawItems = ItemsData.items or {}
    rawRecipes = ItemsData.recipes or {}
    rawMeta = ItemsData.meta or {}
end

local itemsById = {}
local displayItemMap = {}
local recipesByOutput = {}
local craftableList = {}

local function cloneShallow(value)
    if typeof(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, val in pairs(value) do
        copy[key] = val
    end
    return copy
end

local function cloneArray(array)
    local result = {}
    if typeof(array) ~= "table" then
        return result
    end
    for index, entry in ipairs(array) do
        result[index] = cloneShallow(entry)
    end
    return result
end

-- Helper function to find sprite entry with multiple ID variations
local function findSpriteEntry(itemId)
    if not itemId then
        return nil
    end
    
    -- Try exact match first
    local spriteEntry = SpriteManifest[itemId]
    if spriteEntry then
        return spriteEntry
    end
    
    -- Try with _gui suffix
    spriteEntry = SpriteManifest[itemId .. "_gui"]
    if spriteEntry then
        return spriteEntry
    end
    
    -- Try converting hyphens to underscores
    local idWithUnderscores = string.gsub(itemId, "-", "_")
    spriteEntry = SpriteManifest[idWithUnderscores]
    if spriteEntry then
        return spriteEntry
    end
    
    -- Try converting hyphens to underscores with _gui suffix
    spriteEntry = SpriteManifest[idWithUnderscores .. "_gui"]
    if spriteEntry then
        return spriteEntry
    end
    
    -- Try converting underscores to hyphens (for reverse mapping)
    local idWithHyphens = string.gsub(itemId, "_", "-")
    spriteEntry = SpriteManifest[idWithHyphens]
    if spriteEntry then
        return spriteEntry
    end
    
    return nil
end

for _, item in ipairs(rawItems) do
    if item.id and not itemsById[item.id] then
        local record = cloneShallow(item)
        local spriteEntry = findSpriteEntry(item.id)
        if spriteEntry then
            record.spriteIndex = spriteEntry.spriteIndex
            record.displayName = spriteEntry.name
        else
            record.displayName = item.name
        end
        itemsById[item.id] = record
    end
end

-- Also add entries from SpriteManifest that might not be in ItemsData
-- But try to match them to existing items first using ID variations
for id, spriteEntry in pairs(SpriteManifest) do
    -- Try to find matching item by various ID formats
    local matchedItemId = nil
    
    -- Try exact match
    if itemsById[id] then
        matchedItemId = id
    else
        -- Try removing _gui suffix
        local idWithoutGui = string.gsub(id, "_gui$", "")
        if itemsById[idWithoutGui] then
            matchedItemId = idWithoutGui
        else
            -- Try converting underscores to hyphens
            local idWithHyphens = string.gsub(id, "_", "-")
            if itemsById[idWithHyphens] then
                matchedItemId = idWithHyphens
            end
        end
    end
    
    if matchedItemId then
        -- Update existing item with sprite data
        local record = itemsById[matchedItemId]
        record.spriteIndex = record.spriteIndex or spriteEntry.spriteIndex
        record.displayName = record.displayName or spriteEntry.name
        if not record.name then
            record.name = spriteEntry.name
        end
    elseif not itemsById[id] then
        -- Create new entry for sprite-only items
        itemsById[id] = {
            id = id,
            name = spriteEntry.name,
            displayName = spriteEntry.name,
            category = "legacy",
            spriteIndex = spriteEntry.spriteIndex,
            sell = nil,
            buy = nil,
            source = {},
            themes = {},
        }
    end
end

for id, record in pairs(itemsById) do
    displayItemMap[id] = {
        id = record.id,
        name = record.displayName or record.name,
        spriteIndex = record.spriteIndex,
        category = record.category,
        sell = record.sell,
        buy = record.buy,
        source = record.source and cloneArray(record.source) or {},
        themes = record.themes and cloneArray(record.themes) or {},
    }
end

local fallback = {}
for id, entry in pairs(displayItemMap) do
    if entry.spriteIndex then
        fallback[id] = { index = entry.spriteIndex, name = entry.name }
    end
end

for recipeIdx, recipe in ipairs(rawRecipes) do
    if recipe.itemId then
        local resultItem = itemsById[recipe.itemId] or {
            id = recipe.itemId,
            name = recipe.name or recipe.itemId,
            displayName = recipe.name or recipe.itemId,
            category = "crafted",
        }
        
        -- If result item doesn't have spriteIndex, try to find it
        if not resultItem.spriteIndex then
            local spriteEntry = findSpriteEntry(recipe.itemId)
            if spriteEntry then
                resultItem.spriteIndex = spriteEntry.spriteIndex
                resultItem.displayName = spriteEntry.name
            end
        end

        local resolvedMaterials = {}
        for _, material in ipairs(recipe.materials or {}) do
            local materialItem = itemsById[material.itemId]
            
            -- If material item doesn't have spriteIndex, try to find it
            if materialItem and not materialItem.spriteIndex then
                local spriteEntry = findSpriteEntry(material.itemId)
                if spriteEntry then
                    materialItem.spriteIndex = spriteEntry.spriteIndex
                    materialItem.displayName = spriteEntry.name
                end
            end
            
            table.insert(resolvedMaterials, {
                itemId = material.itemId,
                name = materialItem and (materialItem.displayName or materialItem.name) or material.name or material.itemId,
                count = material.count or 1,
                spriteIndex = materialItem and materialItem.spriteIndex or nil,
            })
        end

        local recipeEntry = {
            id = recipe.id or recipe.itemId,
            itemId = resultItem.id,
            name = recipe.name or resultItem.displayName or resultItem.name,
            station = recipe.station or "workbench",
            time = recipe.time or 6,
            sell = recipe.sell,
            source = cloneArray(recipe.source),
            materials = resolvedMaterials,
            diyIconIndex = recipeIdx,  -- Assign DIY icon index based on recipe position (1-80)
            result = {
                itemId = resultItem.id,
                name = resultItem.displayName or resultItem.name,
                spriteIndex = resultItem.spriteIndex,
                category = resultItem.category,
            },
        }

        recipesByOutput[resultItem.id] = recipeEntry
        table.insert(craftableList, recipeEntry)
    end
end

local function cloneRecipe(recipeEntry)
    if not recipeEntry then
        return nil
    end

    local clone = cloneShallow(recipeEntry)
    clone.materials = cloneArray(recipeEntry.materials)
    clone.source = cloneArray(recipeEntry.source)
    clone.result = cloneShallow(recipeEntry.result)
    return clone
end

function ItemDataFetcher.getItem(itemId)
    local record = itemsById[itemId]
    if not record then
        return nil
    end
    return cloneShallow(record)
end

function ItemDataFetcher.getAllItems()
    local list = {}
    for _, record in pairs(itemsById) do
        table.insert(list, cloneShallow(record))
    end
    table.sort(list, function(a, b)
        return (a.name or a.id) < (b.name or b.id)
    end)
    return list
end

function ItemDataFetcher.getDisplayItemMap()
    local clone = {}
    for id, entry in pairs(displayItemMap) do
        clone[id] = cloneShallow(entry)
    end
    return clone
end

function ItemDataFetcher.getFallbackData()
    local clone = {}
    for id, entry in pairs(fallback) do
        clone[id] = { index = entry.index, name = entry.name }
    end
    return clone
end

function ItemDataFetcher.searchItems(term)
    if not term or term == "" then
        return {}
    end
    local lowerTerm = string.lower(term)
    local results = {}
    for _, record in pairs(itemsById) do
        local name = record.name or record.id
        if string.find(string.lower(name), lowerTerm, 1, true) then
            table.insert(results, cloneShallow(record))
        end
    end
    table.sort(results, function(a, b)
        return (a.name or a.id) < (b.name or b.id)
    end)
    return results
end

function ItemDataFetcher.getCraftingRecipe(itemId)
    return cloneRecipe(recipesByOutput[itemId])
end

function ItemDataFetcher.getCraftableItems()
    local list = {}
    for _, recipe in ipairs(craftableList) do
        table.insert(list, cloneRecipe(recipe))
    end
    return list
end

function ItemDataFetcher.getRawData()
    return {
        items = cloneArray(rawItems),
        recipes = cloneArray(rawRecipes),
        meta = cloneShallow(rawMeta),
    }
end

return ItemDataFetcher
