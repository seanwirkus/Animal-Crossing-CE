--[[
	Components - Animal Crossing GUI Components
	Reusable GUI components for the Animal Crossing game
]]

local Components = {}

-- Import components
local Hi = require(script.hi)
local Test = require(script.test)

-- Component registry
Components.Hi = Hi
Components.Test = Test

-- Component metadata
Components.Metadata = {
	["hi"] = {
		name = "Stats GUI",
		description = "Currency and stats display component",
		author = "ACNH Team",
		version = "1.0.0"
	},
	["test"] = {
		name = "Test Component", 
		description = "Test component for development",
		author = "ACNH Team",
		version = "1.0.0"
	}
}

-- Utility functions
function Components.CreateComponent(componentName: string, parent: Instance)
	local component = Components[componentName]
	if not component then
		warn(`[Components] Component {componentName} not found`)
		return nil
	end
	
	return component.new(parent)
end

function Components.ListComponents()
	print("[Components] Available components:")
	for name, metadata in Components.Metadata do
		print(`  - {name}: {metadata.name} - {metadata.description}`)
	end
end

return Components
