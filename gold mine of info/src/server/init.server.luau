--[[
	Server Init - Animal Crossing server initialization
	Proper server-side entry point using ModuleLoader
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for ReplicatedStorage to be ready
local moduleLoader = ReplicatedStorage:WaitForChild("ModuleLoader", 10)
if not moduleLoader then
	warn("[Server] ModuleLoader not found in ReplicatedStorage!")
	return
end

-- Load the module loader
local ModuleLoader = require(moduleLoader)

-- Initialize the module loading system
ModuleLoader()

print("[Server] Animal Crossing server initialized!")
