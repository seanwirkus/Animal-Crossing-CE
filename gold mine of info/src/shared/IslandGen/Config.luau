--[[
	IslandGen/Config.luau
	Configuration for deterministic ACNH-style island generation
	Simplified for 2-tier system with custom textures
]]

local Config = {}

-- world sizing (ACNH ~600x600 studs total)
Config.ISLAND_RADIUS        = 300       -- studs (radius), total ~600x600
Config.WATER_LEVEL          = -100      -- Far below - no water visible
Config.TIER_1_HEIGHT        = 0         -- Ground level
Config.TIER_2_HEIGHT        = 10        -- Elevated tier
Config.CELL                 = 6         -- grid step (smaller = smoother, slower)

-- NO rivers or ponds in simplified version
Config.RIVER_BANK_RADIUS    = 0         -- Disabled
Config.RIVER_MEANDER        = 0
Config.RIVER_MIN_POINTS     = 0
Config.RIVER_MAX_POINTS     = 0
Config.POND_COUNT_RANGE     = {0, 0}    -- No ponds
Config.POND_RADIUS_RANGE    = {0, 0}

-- determinism
Config.DEFAULT_SEED         = 123456

return Config
