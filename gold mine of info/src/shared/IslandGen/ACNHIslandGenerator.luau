--[[
	ACNHIslandGenerator - Complete Animal Crossing island generation
	Features: 3-tier terrain, rivers, ponds, waterfalls, beaches, rocks, flowers
	Deterministic seeding for unique but reproducible islands per player
]]

local ACNHIslandGenerator = {}
ACNHIslandGenerator.__index = ACNHIslandGenerator

-- Island configuration matching ACNH
local CONFIG = {
	ISLAND_RADIUS = 300,           -- Total ~600x600 studs
	TIER_1_HEIGHT = 0,             -- Ground level (beaches, water)
	TIER_2_HEIGHT = 10,            -- First elevated tier
	TIER_3_HEIGHT = 20,            -- Second elevated tier (cliffs)
	CELL_SIZE = 4,                 -- Terrain grid cell size
	BEACH_WIDTH = 50,              -- Width of sandy beach perimeter
	
	-- River configuration
	RIVER_COUNT = 2,
	RIVER_WIDTH = 8,
	RIVER_MEANDER = 0.3,           -- 0-1 how curvy rivers are
	
	-- Pond configuration
	POND_COUNT = 3,
	POND_RADIUS_MIN = 15,
	POND_RADIUS_MAX = 25,
	
	-- Waterfall configuration
	WATERFALL_COUNT = 2,
	
	-- Decoration configuration
	ROCK_COUNT = 40,
	FLOWER_CLUSTERS = 15,
}

function ACNHIslandGenerator.new()
	local self = setmetatable({}, ACNHIslandGenerator)
	return self
end

--[[
	Main island generation function
	seed: unique seed per player (e.g., UserId)
	offset: position offset for island placement
]]
function ACNHIslandGenerator:GenerateIsland(seed, offset)
	offset = offset or Vector3.new(0, 0, 0)
	local rng = self:_createRNG(seed)
	
	print("[ACNHIslandGenerator] Starting island generation with seed:", seed)
	
	-- Create parent folder for island
	local islandFolder = Instance.new("Folder")
	islandFolder.Name = "ACNHIsland_" .. seed
	islandFolder.Parent = workspace
	
	-- Phase 1: Base terrain layers
	self:_generateBaseTerrain(islandFolder, rng, offset)
	
	-- Phase 2: Water features
	self:_generateRivers(islandFolder, rng, offset)
	self:_generatePonds(islandFolder, rng, offset)
	self:_generateWaterfalls(islandFolder, rng, offset)
	
	-- Phase 3: Beach/shoreline
	self:_generateBeach(islandFolder, rng, offset)
	
	-- Phase 4: Decorations
	self:_generateRocks(islandFolder, rng, offset)
	self:_generateFlowers(islandFolder, rng, offset)
	
	-- Phase 5: NPC spawn zones (pre-calculated for NPCManager)
	self:_markNPCZones(islandFolder, offset)
	
	print("[ACNHIslandGenerator] Island generation complete!")
	return islandFolder
end

--[[
	Generate base terrain: 3 tiers with natural distribution
]]
function ACNHIslandGenerator:_generateBaseTerrain(parent, rng, offset)
	print("[ACNHIslandGenerator] Generating base terrain tiers...")
	
	-- Tier 1: Ground level (largest area)
	local tier1 = Instance.new("Part")
	tier1.Name = "Tier1_Ground"
	tier1.Shape = Enum.PartType.Ball
	tier1.Size = Vector3.new(CONFIG.ISLAND_RADIUS * 2, 5, CONFIG.ISLAND_RADIUS * 2)
	tier1.Position = offset + Vector3.new(0, CONFIG.TIER_1_HEIGHT - 2.5, 0)
	tier1.Material = Enum.Material.Grass
	tier1.Color = Color3.fromRGB(124, 180, 76)  -- ACNH grass green
	tier1.TopSurface = Enum.SurfaceType.Smooth
	tier1.BottomSurface = Enum.SurfaceType.Smooth
	tier1.CanCollide = true
	tier1.Anchored = true
	tier1.Parent = parent
	
	-- Tier 2: Elevated platform (medium area)
	local tier2 = Instance.new("Part")
	tier2.Name = "Tier2_Elevated"
	tier2.Shape = Enum.PartType.Ball
	tier2.Size = Vector3.new(CONFIG.ISLAND_RADIUS * 1.4, 5, CONFIG.ISLAND_RADIUS * 1.4)
	tier2.Position = offset + Vector3.new(0, CONFIG.TIER_2_HEIGHT - 2.5, 0)
	tier2.Material = Enum.Material.Grass
	tier2.Color = Color3.fromRGB(124, 180, 76)
	tier2.TopSurface = Enum.SurfaceType.Smooth
	tier2.BottomSurface = Enum.SurfaceType.Smooth
	tier2.CanCollide = true
	tier2.Anchored = true
	tier2.Parent = parent
	
	-- Tier 3: High cliff (small area)
	local tier3 = Instance.new("Part")
	tier3.Name = "Tier3_Cliff"
	tier3.Shape = Enum.PartType.Ball
	tier3.Size = Vector3.new(CONFIG.ISLAND_RADIUS * 0.8, 5, CONFIG.ISLAND_RADIUS * 0.8)
	tier3.Position = offset + Vector3.new(0, CONFIG.TIER_3_HEIGHT - 2.5, 0)
	tier3.Material = Enum.Material.Grass
	tier3.Color = Color3.fromRGB(124, 180, 76)
	tier3.TopSurface = Enum.SurfaceType.Smooth
	tier3.BottomSurface = Enum.SurfaceType.Smooth
	tier3.CanCollide = true
	tier3.Anchored = true
	tier3.Parent = parent
	
	-- Cliff faces (rock material)
	local cliffFace = Instance.new("Part")
	cliffFace.Name = "CliffFace"
	cliffFace.Size = Vector3.new(CONFIG.ISLAND_RADIUS * 1.5, 8, CONFIG.ISLAND_RADIUS * 1.5)
	cliffFace.Position = offset + Vector3.new(0, CONFIG.TIER_2_HEIGHT - 2, 0)
	cliffFace.Material = Enum.Material.Rock
	cliffFace.Color = Color3.fromRGB(150, 140, 130)
	cliffFace.CanCollide = false
	cliffFace.Anchored = true
	cliffFace.Parent = parent
end

--[[
	Generate meandering rivers
]]
function ACNHIslandGenerator:_generateRivers(parent, rng, offset)
	print("[ACNHIslandGenerator] Generating rivers...")
	
	for i = 1, CONFIG.RIVER_COUNT do
		-- Generate river path using random walk with meander
		local startX = self:_randomRange(rng, -CONFIG.ISLAND_RADIUS + 50, CONFIG.ISLAND_RADIUS - 50)
		local startZ = -CONFIG.ISLAND_RADIUS + 30
		
		local pathPoints = {}
		table.insert(pathPoints, Vector3.new(startX, CONFIG.TIER_1_HEIGHT, startZ))
		
		-- Random walk to create meandering path
		local currentX = startX
		for z = startZ, CONFIG.ISLAND_RADIUS - 30, 15 do
			currentX = currentX + self:_randomRange(rng, -8, 8)
			currentX = math.max(-CONFIG.ISLAND_RADIUS + 30, math.min(CONFIG.ISLAND_RADIUS - 30, currentX))
			table.insert(pathPoints, Vector3.new(currentX, CONFIG.TIER_1_HEIGHT, z))
		end
		
		-- Create river blocks along path
		for _, point in ipairs(pathPoints) do
			local river = Instance.new("Part")
			river.Name = "River_" .. i
			river.Size = Vector3.new(CONFIG.RIVER_WIDTH, 2, 15)
			river.Position = offset + point
			river.Material = Enum.Material.Water
			river.Color = Color3.fromRGB(70, 130, 180)
			river.CanCollide = false
			river.Anchored = true
			river.Parent = parent
		end
	end
end

--[[
	Generate scattered ponds
]]
function ACNHIslandGenerator:_generatePonds(parent, rng, offset)
	print("[ACNHIslandGenerator] Generating ponds...")
	
	for i = 1, CONFIG.POND_COUNT do
		local x = self:_randomRange(rng, -CONFIG.ISLAND_RADIUS + 80, CONFIG.ISLAND_RADIUS - 80)
		local z = self:_randomRange(rng, -CONFIG.ISLAND_RADIUS + 80, CONFIG.ISLAND_RADIUS - 80)
		local radius = self:_randomRange(rng, CONFIG.POND_RADIUS_MIN, CONFIG.POND_RADIUS_MAX)
		
		local pond = Instance.new("Part")
		pond.Name = "Pond_" .. i
		pond.Shape = Enum.PartType.Ball
		pond.Size = Vector3.new(radius * 2, 2, radius * 2)
		pond.Position = offset + Vector3.new(x, CONFIG.TIER_1_HEIGHT - 1, z)
		pond.Material = Enum.Material.Water
		pond.Color = Color3.fromRGB(70, 130, 180)
		pond.CanCollide = false
		pond.Anchored = true
		pond.Parent = parent
	end
end

--[[
	Generate waterfalls at cliff edges
]]
function ACNHIslandGenerator:_generateWaterfalls(parent, rng, offset)
	print("[ACNHIslandGenerator] Generating waterfalls...")
	
	for i = 1, CONFIG.WATERFALL_COUNT do
		-- Place waterfalls on edges of tier 2 cliffs
		local angle = (i - 1) * (math.pi * 2 / CONFIG.WATERFALL_COUNT)
		local dist = CONFIG.ISLAND_RADIUS * 0.6
		local x = math.cos(angle) * dist
		local z = math.sin(angle) * dist
		
		-- Water cascade
		local waterfall = Instance.new("Part")
		waterfall.Name = "Waterfall_" .. i
		waterfall.Size = Vector3.new(10, 15, 10)
		waterfall.Position = offset + Vector3.new(x, CONFIG.TIER_2_HEIGHT + 3, z)
		waterfall.Material = Enum.Material.Water
		waterfall.Color = Color3.fromRGB(100, 150, 200)
		waterfall.CanCollide = false
		waterfall.Anchored = true
		waterfall.Parent = parent
	end
end

--[[
	Generate sandy beach perimeter
]]
function ACNHIslandGenerator:_generateBeach(parent, rng, offset)
	print("[ACNHIslandGenerator] Generating beach...")
	
	-- Create beach ring around tier 1
	local beach = Instance.new("Part")
	beach.Name = "Beach"
	beach.Shape = Enum.PartType.Cylinder
	beach.Size = Vector3.new(5, (CONFIG.ISLAND_RADIUS + CONFIG.BEACH_WIDTH) * 2, (CONFIG.ISLAND_RADIUS + CONFIG.BEACH_WIDTH) * 2)
	beach.Rotation = Vector3.new(90, 0, 0)
	beach.Position = offset + Vector3.new(0, CONFIG.TIER_1_HEIGHT - 2, 0)
	beach.Material = Enum.Material.Sand
	beach.Color = Color3.fromRGB(255, 220, 170)  -- Sandy yellow
	beach.CanCollide = true
	beach.Anchored = true
	beach.Parent = parent
end

--[[
	Generate decorative rocks scattered around
]]
function ACNHIslandGenerator:_generateRocks(parent, rng, offset)
	print("[ACNHIslandGenerator] Generating rocks...")
	
	for i = 1, CONFIG.ROCK_COUNT do
		local x = self:_randomRange(rng, -CONFIG.ISLAND_RADIUS + 60, CONFIG.ISLAND_RADIUS - 60)
		local z = self:_randomRange(rng, -CONFIG.ISLAND_RADIUS + 60, CONFIG.ISLAND_RADIUS - 60)
		local size = self:_randomRange(rng, 2, 6)
		
		-- Random tier placement
		local tierChoice = math.random(1, 3)
		local height = CONFIG.TIER_1_HEIGHT
		if tierChoice == 2 then height = CONFIG.TIER_2_HEIGHT end
		if tierChoice == 3 then height = CONFIG.TIER_3_HEIGHT end
		
		local rock = Instance.new("Part")
		rock.Name = "Rock_" .. i
		rock.Shape = Enum.PartType.Ball
		rock.Size = Vector3.new(size, size, size)
		rock.Position = offset + Vector3.new(x, height + size / 2, z)
		rock.Material = Enum.Material.Rock
		rock.Color = Color3.fromRGB(150, 150, 150)
		rock.CanCollide = true
		rock.Anchored = true
		rock.Parent = parent
	end
end

--[[
	Generate flower clusters
]]
function ACNHIslandGenerator:_generateFlowers(parent, rng, offset)
	print("[ACNHIslandGenerator] Generating flowers...")
	
	local flowerColors = {
		Color3.fromRGB(255, 100, 100),  -- Red
		Color3.fromRGB(255, 200, 100),  -- Orange
		Color3.fromRGB(255, 255, 100),  -- Yellow
		Color3.fromRGB(100, 255, 100),  -- Green
		Color3.fromRGB(100, 200, 255),  -- Blue
		Color3.fromRGB(200, 100, 255),  -- Purple
	}
	
	for i = 1, CONFIG.FLOWER_CLUSTERS do
		-- Cluster center
		local centerX = self:_randomRange(rng, -CONFIG.ISLAND_RADIUS + 80, CONFIG.ISLAND_RADIUS - 80)
		local centerZ = self:_randomRange(rng, -CONFIG.ISLAND_RADIUS + 80, CONFIG.ISLAND_RADIUS - 80)
		local color = flowerColors[math.random(1, #flowerColors)]
		
		-- 3-5 flowers per cluster
		local clusterSize = math.random(3, 5)
		for j = 1, clusterSize do
			local offsetX = self:_randomRange(rng, -5, 5)
			local offsetZ = self:_randomRange(rng, -5, 5)
			
			local flower = Instance.new("Part")
			flower.Name = "Flower_" .. i .. "_" .. j
			flower.Size = Vector3.new(1, 1, 1)
			flower.Position = offset + Vector3.new(centerX + offsetX, CONFIG.TIER_1_HEIGHT + 0.5, centerZ + offsetZ)
			flower.Material = Enum.Material.Neon
			flower.Color = color
			flower.CanCollide = false
			flower.Anchored = true
			flower.Parent = parent
		end
	end
end

--[[
	Mark NPC spawn zones for IslandNPCManager
]]
function ACNHIslandGenerator:_markNPCZones(parent, offset)
	-- Town Square: center Tier 1
	local townSquare = Instance.new("Part")
	townSquare.Name = "NPCZone_TownSquare"
	townSquare.Size = Vector3.new(60, 0.1, 60)
	townSquare.Position = offset + Vector3.new(0, CONFIG.TIER_1_HEIGHT + 0.1, 0)
	townSquare.Transparency = 1
	townSquare.CanCollide = false
	townSquare.Anchored = true
	townSquare.Parent = parent
	
	-- Housing area: Tier 2 left side
	local housingArea = Instance.new("Part")
	housingArea.Name = "NPCZone_Housing"
	housingArea.Size = Vector3.new(80, 0.1, 80)
	housingArea.Position = offset + Vector3.new(-100, CONFIG.TIER_2_HEIGHT + 0.1, 0)
	housingArea.Transparency = 1
	housingArea.CanCollide = false
	housingArea.Anchored = true
	housingArea.Parent = parent
	
	-- Beach: perimeter
	local beachZone = Instance.new("Part")
	beachZone.Name = "NPCZone_Beach"
	beachZone.Size = Vector3.new(100, 0.1, 100)
	beachZone.Position = offset + Vector3.new(0, CONFIG.TIER_1_HEIGHT + 0.1, CONFIG.ISLAND_RADIUS - 50)
	beachZone.Transparency = 1
	beachZone.CanCollide = false
	beachZone.Anchored = true
	beachZone.Parent = parent
end

--[[
	Helper: Create deterministic RNG from seed
]]
function ACNHIslandGenerator:_createRNG(seed)
	math.randomseed(seed)
	return {}
end

--[[
	Helper: Random range
]]
function ACNHIslandGenerator:_randomRange(rng, min, max)
	return math.random() * (max - min) + min
end

return ACNHIslandGenerator
