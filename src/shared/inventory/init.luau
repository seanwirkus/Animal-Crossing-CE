local InventoryModule = {}

InventoryModule.Constants = require(script.InventoryConstants)
InventoryModule.Types = require(script.InventoryTypes)
InventoryModule.Schemas = require(script.InventorySchemas)
InventoryModule.Validation = require(script.InventoryValidation)
InventoryModule.AdapterClass = require(script.InventoryAdapters)

function InventoryModule.newAdapterRegistry()
    local registry = InventoryModule.AdapterClass.new()
    registry:registerLegacyAdapter(InventoryModule.Constants.LEGACY_DATASET_ID, InventoryModule.AdapterClass.defaultLegacyAdapter)
    return registry
end

return InventoryModule
