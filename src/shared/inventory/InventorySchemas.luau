local InventoryConstants = require(script.Parent.InventoryConstants)
local InventorySchemas = {}

function InventorySchemas.createEmptySlot(index)
    return {
        index = index,
        stack = nil,
        locked = false,
        maxStack = InventoryConstants.DEFAULT_MAX_STACK,
        tags = {},
    }
end

function InventorySchemas.createSlotFromStack(index, stack)
    local slot = InventorySchemas.createEmptySlot(index)
    slot.stack = stack and {
        id = stack.id,
        count = stack.count or 0,
        metadata = stack.metadata,
        createdAt = stack.createdAt,
    } or nil
    if stack and stack.maxStack then
        slot.maxStack = stack.maxStack
    end
    if stack and stack.tags then
        slot.tags = table.clone(stack.tags)
    end
    return slot
end

function InventorySchemas.ensureSlotTable(maxSlots)
    local slots = {}
    for index = 1, maxSlots do
        slots[index] = InventorySchemas.createEmptySlot(index)
    end
    return slots
end

function InventorySchemas.createSnapshot(options)
    local maxSlots = InventoryConstants.resolveMaxSlots(options)
    local snapshot = {
        id = options and options.id or nil,
        dataset = options and options.dataset or InventoryConstants.DEFAULT_DATASET_ID,
        version = options and options.version or InventoryConstants.DEFAULT_CHANGESET_VERSION,
        updatedAt = options and options.updatedAt or os.time(),
        source = options and options.source or "runtime",
        maxSlots = maxSlots,
        slots = InventorySchemas.ensureSlotTable(maxSlots),
    }

    if options and typeof(options.slots) == "table" then
        for index, slot in ipairs(options.slots) do
            if index <= maxSlots then
                snapshot.slots[index] = InventorySchemas.normalizeSlot(index, slot)
            end
        end
    end

    return snapshot
end

function InventorySchemas.normalizeSlot(index, slot)
    if not slot then
        return InventorySchemas.createEmptySlot(index)
    end

    if slot.index ~= index then
        slot = table.clone(slot)
        slot.index = index
    end

    if slot.stack then
        slot.stack = {
            id = slot.stack.id,
            count = slot.stack.count or 0,
            metadata = slot.stack.metadata,
            createdAt = slot.stack.createdAt,
        }
    end

    slot.maxStack = slot.maxStack or InventoryConstants.DEFAULT_MAX_STACK
    slot.locked = slot.locked or false
    if slot.tags then
        slot.tags = table.clone(slot.tags)
    else
        slot.tags = {}
    end

    return slot
end

function InventorySchemas.cloneSnapshot(snapshot)
    if not snapshot then
        return nil
    end

    local copy = {
        id = snapshot.id,
        dataset = snapshot.dataset,
        maxSlots = snapshot.maxSlots,
        version = snapshot.version,
        updatedAt = snapshot.updatedAt,
        source = snapshot.source,
        slots = {},
    }

    for index, slot in ipairs(snapshot.slots or {}) do
        copy.slots[index] = InventorySchemas.normalizeSlot(index, slot)
    end

    return copy
end

return InventorySchemas
