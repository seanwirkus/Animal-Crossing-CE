--[[
	MockDataStore.luau
	
	Fake DataStore for fast Studio testing
	Keeps data in memory only (doesn't persist between sessions)
	
	Usage:
		local DataStoreService = USE_MOCK_DATASTORE 
			and require(script.Parent.MockDataStore) 
			or game:GetService("DataStoreService")
]]

local MockDataStore = {}
local storage = {} -- In-memory storage

local MockDataStoreObject = {}
MockDataStoreObject.__index = MockDataStoreObject

function MockDataStoreObject:GetAsync(key)
    print("[MockDataStore] 📖 GetAsync:", key)
    return storage[self.name .. "_" .. key]
end

function MockDataStoreObject:SetAsync(key, value)
    print("[MockDataStore] 💾 SetAsync:", key, "→", typeof(value))
    storage[self.name .. "_" .. key] = value
end

function MockDataStoreObject:UpdateAsync(key, transformFunction)
    print("[MockDataStore] 🔄 UpdateAsync:", key)
    local currentValue = storage[self.name .. "_" .. key]
    local newValue = transformFunction(currentValue)
    storage[self.name .. "_" .. key] = newValue
    return newValue
end

function MockDataStoreObject:RemoveAsync(key)
    print("[MockDataStore] 🗑️ RemoveAsync:", key)
    storage[self.name .. "_" .. key] = nil
end

-- Main MockDataStore service
function MockDataStore:GetDataStore(name)
    print("[MockDataStore] 📂 Creating mock DataStore:", name)
    return setmetatable({ name = name }, MockDataStoreObject)
end

return MockDataStore
