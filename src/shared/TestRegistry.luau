--!strict
-- Central registry for exposing test systems and debug helpers without relying on _G.

export type Registry = { [string]: any }

local TestRegistry = {}
local registry: Registry = {}

function TestRegistry.register(name: string, value: any)
    registry[name] = value
end

function TestRegistry.unregister(name: string)
    registry[name] = nil
end

function TestRegistry.get(name: string): any
    return registry[name]
end

function TestRegistry.getAll(): Registry
    return table.clone(registry)
end

return TestRegistry
