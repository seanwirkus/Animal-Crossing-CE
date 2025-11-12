--[[
	WhiteboardConstants.luau
	
	Shared constants for whiteboard system (client and server)
]]

local WhiteboardConstants = {}

WhiteboardConstants.MARKER_COLORS = {
	RedMarker = Color3.fromRGB(255, 71, 76),
	BlueMarker = Color3.fromRGB(72, 127, 255),
	YellowMarker = Color3.fromRGB(255, 216, 82),
	GreenMarker = Color3.fromRGB(86, 220, 129),
	BlackMarker = Color3.fromRGB(30, 30, 36),
}

WhiteboardConstants.CANVAS_SIZE = Vector2.new(1024, 1024)
WhiteboardConstants.DEFAULT_THICKNESS = 10
WhiteboardConstants.MAX_POINTS = 5000

-- Marker spawning configuration
WhiteboardConstants.MARKER_RESPAWN_TIME = 45 -- Seconds before marker respawns after pickup
WhiteboardConstants.MARKER_SPAWN_POINTS = {
	-- Default spawn points (can be overridden by workspace markers)
	RedMarker = Vector3.new(0, 5, 0),
	BlueMarker = Vector3.new(2, 5, 0),
	YellowMarker = Vector3.new(4, 5, 0),
	GreenMarker = Vector3.new(6, 5, 0),
	BlackMarker = Vector3.new(8, 5, 0),
}

return WhiteboardConstants



