local InventoryConstants = {}

InventoryConstants.DEFAULT_MAX_SLOTS = 20
InventoryConstants.LEGACY_MAX_SLOTS = 40
InventoryConstants.DEFAULT_MAX_STACK = 99
InventoryConstants.LEGACY_DATASET_ID = "legacy_v1"
InventoryConstants.DEFAULT_DATASET_ID = "default"
InventoryConstants.DEFAULT_CHANGESET_VERSION = "2024.01"

function InventoryConstants.resolveMaxSlots(config)
    if config and typeof(config) == "table" then
        local maxSlots = config.maxSlots or config.MAX_SLOTS or config.capacity
        if typeof(maxSlots) == "number" and maxSlots > 0 then
            return maxSlots
        end
    end
    return InventoryConstants.DEFAULT_MAX_SLOTS
end

return InventoryConstants
