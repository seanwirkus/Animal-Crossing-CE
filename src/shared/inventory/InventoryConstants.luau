local InventoryConstants = {}

InventoryConstants.DEFAULT_MAX_SLOTS = 20
InventoryConstants.LEGACY_MAX_SLOTS = 40
InventoryConstants.DEFAULT_MAX_STACK = 99
InventoryConstants.LEGACY_DATASET_ID = "legacy_v1"
InventoryConstants.DEFAULT_DATASET_ID = "default"
InventoryConstants.DEFAULT_CHANGESET_VERSION = "2024.01"

-- Inventory level system: Level 1 = 10 slots (1 row), Level 2 = 20 slots (2 rows), etc.
InventoryConstants.SLOTS_PER_LEVEL = 10
InventoryConstants.STARTING_INVENTORY_LEVEL = 1

-- Calculate max slots from inventory level
function InventoryConstants.getMaxSlotsFromLevel(level)
    if typeof(level) ~= "number" or level < 1 then
        level = InventoryConstants.STARTING_INVENTORY_LEVEL
    end
    return level * InventoryConstants.SLOTS_PER_LEVEL
end

-- Calculate inventory level from max slots
function InventoryConstants.getLevelFromMaxSlots(maxSlots)
    if typeof(maxSlots) ~= "number" or maxSlots < 1 then
        return InventoryConstants.STARTING_INVENTORY_LEVEL
    end
    return math.max(1, math.ceil(maxSlots / InventoryConstants.SLOTS_PER_LEVEL))
end

function InventoryConstants.resolveMaxSlots(config)
    if config and typeof(config) == "table" then
        local maxSlots = config.maxSlots or config.MAX_SLOTS or config.capacity
        if typeof(maxSlots) == "number" and maxSlots > 0 then
            return maxSlots
        end
        -- If inventory level is provided, calculate from it
        local level = config.inventoryLevel or config.level
        if typeof(level) == "number" and level > 0 then
            return InventoryConstants.getMaxSlotsFromLevel(level)
        end
    end
    return InventoryConstants.DEFAULT_MAX_SLOTS
end

return InventoryConstants
