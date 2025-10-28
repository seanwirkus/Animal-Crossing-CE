local InventoryConstants = require(script.Parent.InventoryConstants)
local InventorySchemas = require(script.Parent.InventorySchemas)

local InventoryValidation = {}

local function isPositiveInteger(value)
    return typeof(value) == "number" and value >= 0 and value % 1 == 0
end

function InventoryValidation.validateSlot(slot)
    if typeof(slot) ~= "table" then
        return false, "Slot must be a table"
    end

    if not isPositiveInteger(slot.index) then
        return false, "Slot index must be a positive integer"
    end

    if slot.stack then
        local stack = slot.stack
        if typeof(stack.id) ~= "string" or stack.id == "" then
            return false, "Slot stack must include a non-empty id"
        end
        if not isPositiveInteger(stack.count) then
            return false, "Slot stack count must be a positive integer"
        end
    end

    return true
end

function InventoryValidation.validateSnapshot(snapshot)
    if typeof(snapshot) ~= "table" then
        return false, "Snapshot must be a table"
    end

    if not isPositiveInteger(snapshot.maxSlots) then
        return false, "Snapshot requires a maxSlots number"
    end

    for index = 1, snapshot.maxSlots do
        local slot = snapshot.slots and snapshot.slots[index]
        if not slot then
            return false, string.format("Snapshot missing slot at index %d", index)
        end
        local ok, reason = InventoryValidation.validateSlot(slot)
        if not ok then
            return false, string.format("Slot %d invalid: %s", index, reason)
        end
    end

    return true
end

function InventoryValidation.captureIssues(snapshot)
    local ok, reason = InventoryValidation.validateSnapshot(snapshot)
    if ok then
        return { valid = true, issues = {} }
    end

    return {
        valid = false,
        issues = { reason },
        snapshot = InventorySchemas.cloneSnapshot(snapshot),
        defaults = {
            maxSlots = InventoryConstants.DEFAULT_MAX_SLOTS,
            maxStack = InventoryConstants.DEFAULT_MAX_STACK,
        },
    }
end

return InventoryValidation
