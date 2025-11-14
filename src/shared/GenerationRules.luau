--[[
	GenerationRules.luau
	
	Animal Crossing: New Horizons accurate generation rules for:
	- Tree placement and spacing
	- Rock formation rules
	- Flower patterns
	- Building placement zones
	- Furniture/object placement
	
	These rules are used by both the IslandGenerator (to propose placements)
	and the IslandAuditor (to validate placements)
]]

local GenerationRules = {}

--[[
	TREE RULES (Based on ACNH mechanics)
]]
GenerationRules.Trees = {
    -- Minimum spacing between trees (in studs) - INCREASED for better distribution
    MIN_SPACING = 10, -- Increased from 2 to 10 studs - trees should be spread out

    -- Trees should be at least this far from buildings
    BUILDING_CLEARANCE = 8, -- Increased from 4

    -- Trees should be at least this far from water
    WATER_CLEARANCE = 3, -- Increased from 1

    -- Trees should be at least this far from cliffs/edges
    CLIFF_CLEARANCE = 2, -- Increased from 1

    -- Maximum trees per zone (prevents overcrowding) - REDUCED for better distribution
    MAX_PER_ZONE = 2, -- Reduced from 8 to 2 - prevents clustering
    ZONE_SIZE = 20, -- Size of zone in studs (20x20 stud area)

    -- Tree types and their spawn weights
    TYPES = {
        { name = "Hardwood Tree", weight = 40 },
        { name = "Cedar Tree", weight = 30 },
        { name = "Fruit Tree", weight = 20 },
        { name = "Palm Tree", weight = 10 }, -- Only near beaches
    },

    -- Natural clustering: DISABLED - trees should be evenly distributed
    CLUSTER_PREFERENCE = false, -- Changed to false - no clustering
    CLUSTER_DISTANCE = 5, -- Trees within 5 studs are considered "clustered"

    -- Height requirements (terrain slope)
    MAX_SLOPE = 0.3, -- Cannot plant on steep slopes

    -- Preferred material for trees (Grass is preferred)
    PREFERRED_MATERIAL = Enum.Material.Grass,
    PREFERRED_MATERIAL_WEIGHT = 3, -- 3x more likely to spawn on grass

    -- Distribution settings
    USE_GRID_DISTRIBUTION = true, -- Use grid-based distribution for even spread
    GRID_CELL_SIZE = 25, -- Each grid cell is 25x25 studs
    TREES_PER_GRID_CELL = 1, -- Max 1 tree per grid cell
}

--[[
	ROCK RULES (Based on ACNH mechanics)
]]
GenerationRules.Rocks = {
    -- Rocks spawn in clusters of up to 6
    MAX_CLUSTER_SIZE = 6,
    MIN_CLUSTER_SIZE = 3,

    -- Spacing within a cluster
    MIN_SPACING_IN_CLUSTER = 2,
    MAX_SPACING_IN_CLUSTER = 5,

    -- Spacing between different rock clusters
    MIN_CLUSTER_SPACING = 15,

    -- Rocks need flat ground
    MAX_SLOPE = 0.2,

    -- Clearance from other objects
    TREE_CLEARANCE = 2,
    BUILDING_CLEARANCE = 5,
    WATER_CLEARANCE = 1,

    -- Rock types
    TYPES = {
        { name = "Gray Rock", weight = 50 },
        { name = "Brown Rock", weight = 30 },
        { name = "Money Rock", weight = 15 }, -- Spawns bells when hit
        { name = "Rare Rock", weight = 5 },
    },
}

--[[
	FLOWER RULES (Based on ACNH mechanics)
]]
GenerationRules.Flowers = {
    -- Flowers grow in patches
    MIN_PATCH_SIZE = 3,
    MAX_PATCH_SIZE = 12,

    -- Spacing within patch (can be close together)
    MIN_SPACING = 1,

    -- Spacing between patches
    MIN_PATCH_SPACING = 4,

    -- Clearance from objects
    TREE_CLEARANCE = 1,
    ROCK_CLEARANCE = 1,
    BUILDING_CLEARANCE = 2,

    -- Flowers prefer flat ground
    MAX_SLOPE = 0.4,

    -- Flower types (spawn in same-species patches)
    TYPES = {
        { name = "Rose", colors = { "Red", "White", "Yellow", "Pink", "Orange" }, weight = 20 },
        { name = "Tulip", colors = { "Red", "White", "Yellow", "Pink", "Black" }, weight = 20 },
        { name = "Pansy", colors = { "Red", "White", "Yellow", "Blue", "Orange" }, weight = 15 },
        { name = "Cosmos", colors = { "Red", "White", "Yellow", "Pink", "Orange" }, weight = 15 },
        { name = "Lily", colors = { "Red", "White", "Yellow", "Pink", "Orange" }, weight = 15 },
        { name = "Hyacinth", colors = { "Red", "White", "Yellow", "Pink", "Blue" }, weight = 15 },
    },

    -- Hybrid breeding rules (advanced)
    BREEDING_ENABLED = false, -- For future expansion
}

--[[
	BUILDING RULES (Based on ACNH mechanics)
]]
GenerationRules.Buildings = {
    -- Buildings need large flat areas
    MIN_FLAT_AREA = 15, -- studs radius
    MAX_SLOPE = 0.1,

    -- Spacing from other buildings
    MIN_SPACING = 10,

    -- Spacing from terrain features
    WATER_CLEARANCE = 3,
    CLIFF_CLEARANCE = 3,

    -- Types and their size requirements
    TYPES = {
        { name = "Resident Services", size = Vector3.new(10, 6, 10), unique = true },
        { name = "Nook's Cranny", size = Vector3.new(8, 5, 8), unique = true },
        { name = "Museum", size = Vector3.new(12, 6, 10), unique = true },
        { name = "Able Sisters", size = Vector3.new(8, 5, 6), unique = true },
        { name = "Villager House", size = Vector3.new(6, 5, 6), maxCount = 10 },
        { name = "Player House", size = Vector3.new(8, 6, 8), maxCount = 8 },
    },

    -- Buildings should face open areas (not walls/cliffs)
    REQUIRES_OPEN_FRONT = true,
    FRONT_CLEARANCE = 5,
}

--[[
	FURNITURE/OBJECT RULES (Based on ACNH mechanics)
]]
GenerationRules.Furniture = {
    -- Outdoor furniture placement
    MIN_SPACING = 1.5,

    -- Clearance from buildings
    BUILDING_CLEARANCE = 2,

    -- Can be placed near trees/rocks
    TREE_CLEARANCE = 0.5,
    ROCK_CLEARANCE = 0.5,

    -- Furniture categories and placement preferences
    CATEGORIES = {
        {
            name = "Seating",
            items = { "Log Bench", "Iron Bench", "Garden Bench" },
            preferLocations = { "near trees", "near buildings", "scenic spots" },
        },
        {
            name = "Lighting",
            items = { "Street Lamp", "Garden Lantern" },
            preferLocations = { "paths", "building entrances" },
        },
        {
            name = "Decorative",
            items = { "Fountain", "Statue" },
            preferLocations = { "plazas", "open areas" },
        },
    },
}

--[[
	PATH RULES (Based on ACNH mechanics)
]]
GenerationRules.Paths = {
    -- Path width (in studs)
    MIN_WIDTH = 2,
    STANDARD_WIDTH = 3,
    MAX_WIDTH = 5,

    -- Paths connect buildings and points of interest
    CONNECTS_BUILDINGS = true,
    CONNECTS_LANDMARKS = true,

    -- Path types
    TYPES = {
        { name = "Dirt Path", weight = 30 },
        { name = "Stone Path", weight = 25 },
        { name = "Brick Path", weight = 20 },
        { name = "Wood Path", weight = 15 },
        { name = "Sand Path", weight = 10 },
    },

    -- Pathfinding preferences
    PREFER_FLAT_TERRAIN = true,
    AVOID_WATER = true,
    CAN_HAVE_BRIDGES = true,
    CAN_HAVE_INCLINES = true,
}

--[[
	TERRAIN ANALYSIS RULES
]]
GenerationRules.Terrain = {
    -- What counts as "flat" ground
    FLAT_SLOPE_THRESHOLD = 0.1,

    -- What counts as "water"
    WATER_MATERIAL = Enum.Material.Water,

    -- Beach detection (sand near water)
    BEACH_MATERIALS = { Enum.Material.Sand, Enum.Material.Ground },
    BEACH_WATER_DISTANCE = 10,

    -- Grid size for analysis (studs)
    ANALYSIS_GRID_SIZE = 5,

    -- Sampling density (how many points to check per grid cell)
    SAMPLE_DENSITY = 4,
}

--[[
	GENERATION CONSTRAINTS (Global limits)
]]
GenerationRules.Constraints = {
    -- Maximum objects per generation pass
    MAX_TREES_PER_PASS = 100, -- Increased for better island coverage
    MAX_ROCKS_PER_PASS = 30, -- Increased for better distribution
    MAX_FLOWERS_PER_PASS = 150, -- Increased for better distribution
    MAX_FURNITURE_PER_PASS = 30,

    -- Island boundaries (studs from origin)
    ISLAND_RADIUS = 200,

    -- Reserved zones (no generation)
    RESERVED_ZONES = {
        -- Example: {center = Vector3.new(0, 0, 0), radius = 20, name = "Town Square"}
    },

    -- Performance limits
    MAX_RAYCAST_OPERATIONS = 1000, -- Increased for better distribution
    MAX_GENERATION_TIME = 10, -- Increased for better distribution

    -- Distribution settings
    USE_EVEN_DISTRIBUTION = true, -- Enable even distribution across island
    DISTRIBUTION_GRID_SIZE = 25, -- Grid cell size for distribution
}

--[[
	SCORING SYSTEM (For AI Auditor)
	Higher scores = better placement
]]
GenerationRules.Scoring = {
    -- Tree placement scoring
    Trees = {
        SPACING_PENALTY = -10, -- Per tree too close
        CLUSTERING_BONUS = 5, -- Trees near other trees
        NATURAL_DISTRIBUTION = 10, -- Not too uniform
        CLEARANCE_BONUS = 5, -- Good spacing from buildings
    },

    -- Rock placement scoring
    Rocks = {
        CLUSTER_BONUS = 15, -- Rocks in natural clusters
        SPACING_PENALTY = -15, -- Rocks too close/far
        FLAT_GROUND_BONUS = 10, -- On flat surface
    },

    -- Flower placement scoring
    Flowers = {
        PATCH_BONUS = 8, -- Flowers in patches
        COLOR_HARMONY = 5, -- Complementary colors
        SPECIES_GROUPING = 10, -- Same species together
    },

    -- Overall island scoring
    Overall = {
        VARIETY_BONUS = 20, -- Good mix of features
        BALANCE_BONUS = 15, -- Even distribution
        NATURAL_FEEL = 25, -- Looks organic, not grid-like
        PLAYABILITY = 20, -- Easy to navigate
    },
}

--[[
	Helper: Check if two positions are within spacing requirement
]]
function GenerationRules.checkSpacing(pos1: Vector3, pos2: Vector3, minSpacing: number): boolean
    local distance = (pos1 - pos2).Magnitude
    return distance >= minSpacing
end

--[[
	Helper: Get total weight for weighted random selection
]]
function GenerationRules.getTotalWeight(items: { { weight: number } }): number
    local total = 0
    for _, item in ipairs(items) do
        total = total + item.weight
    end
    return total
end

--[[
	Helper: Pick random item using weights
]]
function GenerationRules.weightedRandom(items: { { weight: number } }): any
    local totalWeight = GenerationRules.getTotalWeight(items)
    local random = math.random() * totalWeight

    local cumulative = 0
    for _, item in ipairs(items) do
        cumulative = cumulative + item.weight
        if random <= cumulative then
            return item
        end
    end

    return items[#items] -- Fallback
end

return GenerationRules
