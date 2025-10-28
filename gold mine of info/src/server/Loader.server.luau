--[[
	Server Loader - Animal Crossing server initialization
	Proper server-side module loading
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for ModuleLoader to be available
local moduleLoader = ReplicatedStorage:WaitForChild("ModuleLoader", 10)
if not moduleLoader then
	warn("[Server] ModuleLoader not found!")
	return
end

local ModuleLoader = require(moduleLoader)

-- Initialize the module loading system
ModuleLoader()