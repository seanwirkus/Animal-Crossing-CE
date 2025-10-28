local InventoryConstants = require(script.Parent.InventoryConstants)
local InventorySchemas = require(script.Parent.InventorySchemas)

local InventoryAdapters = {}
InventoryAdapters.__index = InventoryAdapters

function InventoryAdapters.new()
    local self = setmetatable({
        _legacyAdapters = {},
    }, InventoryAdapters)
    return self
end

function InventoryAdapters:registerLegacyAdapter(name, adapter)
    assert(typeof(name) == "string" and name ~= "", "Legacy adapter name must be a non-empty string")
    assert(typeof(adapter) == "table", "Legacy adapter must be a table")
    assert(typeof(adapter.toSnapshot) == "function", "Legacy adapter must provide toSnapshot method")
    assert(typeof(adapter.fromSnapshot) == "function", "Legacy adapter must provide fromSnapshot method")

    self._legacyAdapters[name] = adapter
end

function InventoryAdapters:hasLegacyAdapter(name)
    return self._legacyAdapters[name] ~= nil
end

function InventoryAdapters:getLegacyAdapter(name)
    local adapter = self._legacyAdapters[name]
    if not adapter then
        error(string.format("No legacy inventory adapter registered for '%s'", name))
    end
    return adapter
end

function InventoryAdapters:convertLegacySnapshot(name, payload, options)
    local adapter = self:getLegacyAdapter(name)
    local snapshot = adapter.toSnapshot(payload, options)
    snapshot.dataset = snapshot.dataset or name
    return InventorySchemas.cloneSnapshot(snapshot)
end

function InventoryAdapters:serializeForLegacy(name, snapshot)
    local adapter = self:getLegacyAdapter(name)
    local normalized = InventorySchemas.cloneSnapshot(snapshot)
    return adapter.fromSnapshot(normalized)
end

-- Default adapter template seeded with assumptions from the legacy repository.
local defaultLegacyAdapter = {}

function defaultLegacyAdapter.toSnapshot(payload, options)
    local maxSlots = InventoryConstants.resolveMaxSlots(payload)
    local snapshot = InventorySchemas.createSnapshot({
        dataset = options and options.dataset or InventoryConstants.LEGACY_DATASET_ID,
        version = payload and payload.version or options and options.version,
        updatedAt = payload and payload.updatedAt or os.time(),
        maxSlots = maxSlots,
    })

    local legacySlots = payload and payload.inventory or {}
    for _, legacySlot in ipairs(legacySlots) do
        local index = legacySlot.slot or (#snapshot.slots + 1)
        if index >= 1 and index <= snapshot.maxSlots then
            local stack
            if legacySlot.itemId and legacySlot.itemId ~= "" then
                stack = {
                    id = legacySlot.itemId,
                    count = legacySlot.amount or 1,
                    metadata = legacySlot.data,
                }
            end

            snapshot.slots[index] = InventorySchemas.createSlotFromStack(index, stack)
        end
    end

    return snapshot
end

function defaultLegacyAdapter.fromSnapshot(snapshot)
    local serialized = {
        capacity = snapshot and snapshot.maxSlots or InventoryConstants.DEFAULT_MAX_SLOTS,
        version = snapshot and snapshot.version or InventoryConstants.DEFAULT_CHANGESET_VERSION,
        inventory = {},
    }

    if not snapshot then
        return serialized
    end

    for _, slot in ipairs(snapshot.slots or {}) do
        if slot.stack then
            table.insert(serialized.inventory, {
                slot = slot.index,
                itemId = slot.stack.id,
                amount = slot.stack.count,
                data = slot.stack.metadata,
            })
        end
    end

    return serialized
end

InventoryAdapters.defaultLegacyAdapter = defaultLegacyAdapter

return InventoryAdapters
