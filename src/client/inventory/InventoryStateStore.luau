local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local InventoryDomain = require(sharedFolder:WaitForChild("inventory"))

local InventorySchemas = InventoryDomain.Schemas
local InventoryValidation = InventoryDomain.Validation
local InventoryConstants = InventoryDomain.Constants

local InventoryStateStore = {}
InventoryStateStore.__index = InventoryStateStore

function InventoryStateStore.new(options)
    local self = setmetatable({}, InventoryStateStore)

    self.maxSlots = options and options.maxSlots or InventoryConstants.DEFAULT_MAX_SLOTS
    self.snapshot = InventorySchemas.createSnapshot({
        maxSlots = self.maxSlots,
        source = "client-store",
    })
    self._event = Instance.new("BindableEvent")

    return self
end

function InventoryStateStore:destroy()
    if self._event then
        self._event:Destroy()
        self._event = nil
    end
end

function InventoryStateStore:onChanged(callback)
    if not self._event then
        error("InventoryStateStore has been destroyed")
    end
    return self._event.Event:Connect(callback)
end

function InventoryStateStore:getSnapshot()
    return InventorySchemas.cloneSnapshot(self.snapshot)
end

function InventoryStateStore:setSnapshot(snapshot)
    local ok, reason = InventoryValidation.validateSnapshot(snapshot)
    if not ok then
        warn("[InventoryStateStore] Invalid snapshot provided:", reason)
        return
    end

    self.snapshot = InventorySchemas.cloneSnapshot(snapshot)
    self.maxSlots = self.snapshot.maxSlots
    if self._event then
        self._event:Fire(self.snapshot)
    end
end

function InventoryStateStore:updateSlot(index, stack)
    if type(index) ~= "number" then
        error("Slot index must be a number")
    end

    local snapshot = InventorySchemas.cloneSnapshot(self.snapshot)
    if index < 1 or index > snapshot.maxSlots then
        return
    end

    if stack then
        snapshot.slots[index] = InventorySchemas.createSlotFromStack(index, stack)
    else
        snapshot.slots[index] = InventorySchemas.createEmptySlot(index)
    end

    self:setSnapshot(snapshot)
end

function InventoryStateStore:exportLegacyPayload(adapterRegistry, dataset)
    local registry = adapterRegistry or InventoryDomain.newAdapterRegistry()
    local targetDataset = dataset or InventoryConstants.LEGACY_DATASET_ID
    return registry:serializeForLegacy(targetDataset, self.snapshot)
end

return InventoryStateStore
