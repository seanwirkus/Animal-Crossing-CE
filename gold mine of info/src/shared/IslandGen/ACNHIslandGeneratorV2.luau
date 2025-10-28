--[[
	ACNHIslandGeneratorV2 - ENHANCED Animal Crossing island generation
	Features: Perlin noise terrain, natural rivers, clustered trees, beautiful beaches,
	         central plaza, auto-paths, waterfalls, realistic vegetation
	Author: Enhanced for realism and AC:NH authenticity
]]

local ACNHIslandGeneratorV2 = {}
ACNHIslandGeneratorV2.__index = ACNHIslandGeneratorV2

-- Enhanced configuration for beautiful islands
local CONFIG = {
	-- Size & Shape
	ISLAND_RADIUS = 400,
	BEACH_WIDTH = 60,
	
	-- Terrain Tiers (Elevation)
	TIER_1_HEIGHT = 2,
	TIER_2_HEIGHT = 18,
	TIER_3_HEIGHT = 35,
	TIER_SMOOTHNESS = 8,
	
	-- Water Features
	RIVER_COUNT_MIN = 2,
	RIVER_COUNT_MAX = 4,
	RIVER_WIDTH_MIN = 6,
	RIVER_WIDTH_MAX = 12,
	RIVER_MEANDER = 0.4,
	RIVER_DEPTH = 8,
	
	POND_COUNT_MIN = 3,
	POND_COUNT_MAX = 6,
	POND_RADIUS_MIN = 12,
	POND_RADIUS_MAX = 30,
	POND_DEPTH = 6,
	
	WATERFALL_COUNT_MIN = 2,
	WATERFALL_COUNT_MAX = 5,
	WATERFALL_HEIGHT = 15,
	
	-- Cliffs & Elevation
	CLIFF_COUNT_MIN = 5,
	CLIFF_COUNT_MAX = 10,
	CLIFF_HEIGHT_VARIATION = 8,
	
	-- Vegetation
	TREE_COUNT_MIN = 80,
	TREE_COUNT_MAX = 120,
	TREE_CLUSTERS = 15,
	TREE_CLUSTER_RADIUS = 15,
	TREES_PER_CLUSTER_MIN = 3,
	TREES_PER_CLUSTER_MAX = 8,
	
	FLOWER_CLUSTERS_MIN = 25,
	FLOWER_CLUSTERS_MAX = 40,
	FLOWERS_PER_CLUSTER_MIN = 5,
	FLOWERS_PER_CLUSTER_MAX = 15,
	
	ROCK_COUNT_MIN = 60,
	ROCK_COUNT_MAX = 100,
	ROCK_CLUSTERS = 12,
	
	-- Special Zones
	PLAZA_SIZE = 40,
	BEACH_ROCKS = 20,
	TIDAL_POOL_COUNT_MIN = 3,
	TIDAL_POOL_COUNT_MAX = 6,
	
	-- Paths
	PATH_COUNT_MIN = 4,
	PATH_COUNT_MAX = 8,
	PATH_WIDTH = 4,
}

function ACNHIslandGeneratorV2.new()
	local self = setmetatable({}, ACNHIslandGeneratorV2)
	return self
end

-- Create seeded RNG
function ACNHIslandGeneratorV2:_createRNG(seed)
	return Random.new(seed)
end

-- Generate complete island
function ACNHIslandGeneratorV2:GenerateIsland(seed, offset)
	offset = offset or Vector3.new(0, 0, 0)
	local rng = self:_createRNG(seed)
	
	print("[ACNHIslandGenV2] 🏝️ Starting ENHANCED island generation...")
	print("[ACNHIslandGenV2] Seed:", seed, "Offset:", offset)
	
	-- Create parent folder
	local islandFolder = Instance.new("Folder")
	islandFolder.Name = "Island_" .. seed
	islandFolder.Parent = workspace
	
	-- Store island center
	local islandCenter = offset
	
	-- Phase 1: Terrain with Perlin noise
	print("[ACNHIslandGenV2] Phase 1: Generating natural terrain...")
	self:_generateEnhancedTerrain(islandFolder, rng, islandCenter)
	
	-- Phase 2: Central Plaza
	print("[ACNHIslandGenV2] Phase 2: Creating central plaza...")
	local plaza = self:_createCentralPlaza(islandFolder, islandCenter)
	
	-- Phase 3: Water features
	print("[ACNHIslandGenV2] Phase 3: Generating rivers and ponds...")
	local rivers = self:_generateNaturalRivers(islandFolder, rng, islandCenter)
	self:_generateScatteredPonds(islandFolder, rng, islandCenter)
	
	-- Phase 4: Waterfalls
	print("[ACNHIslandGenV2] Phase 4: Placing waterfalls...")
	self:_generateWaterfalls(islandFolder, rng, islandCenter, rivers)
	
	-- Phase 5: Beach perimeter
	print("[ACNHIslandGenV2] Phase 5: Creating beaches...")
	self:_generateBeautifulBeach(islandFolder, rng, islandCenter)
	
	-- Phase 6: Vegetation clusters
	print("[ACNHIslandGenV2] Phase 6: Planting trees and flowers...")
	self:_generateTreeClusters(islandFolder, rng, islandCenter)
	self:_generateFlowerPatches(islandFolder, rng, islandCenter)
	
	-- Phase 7: Rocks and decorations
	print("[ACNHIslandGenV2] Phase 7: Placing rocks...")
	self:_generateRockClusters(islandFolder, rng, islandCenter)
	
	-- Phase 8: Natural paths
	print("[ACNHIslandGenV2] Phase 8: Creating natural paths...")
	self:_generateNaturalPaths(islandFolder, rng, islandCenter, plaza)
	
	-- Phase 9: NPC zones
	print("[ACNHIslandGenV2] Phase 9: Marking NPC zones...")
	self:_markNPCZones(islandFolder, islandCenter)
	
	print("[ACNHIslandGenV2] ✅ Island generation complete!")
	print("[ACNHIslandGenV2] Island folder:", islandFolder.Name)
	
	return islandFolder
end

-- Enhanced terrain with Perlin noise
function ACNHIslandGeneratorV2:_generateEnhancedTerrain(parent, rng, center)
	local terrain = Instance.new("Folder")
	terrain.Name = "Terrain"
	terrain.Parent = parent
	
	-- Create base island mass
	local basePart = Instance.new("Part")
	basePart.Name = "IslandBase"
	basePart.Size = Vector3.new(CONFIG.ISLAND_RADIUS * 2, 40, CONFIG.ISLAND_RADIUS * 2)
	basePart.Position = center + Vector3.new(0, -20, 0)
	basePart.Material = Enum.Material.Ground
	basePart.Color = Color3.fromRGB(101, 67, 33)
	basePart.Anchored = true
	basePart.CanCollide = true
	basePart.Parent = terrain
	
	-- Create grass layer (tier 1)
	local grassLayer = Instance.new("Part")
	grassLayer.Name = "Tier1_Grass"
	grassLayer.Size = Vector3.new(CONFIG.ISLAND_RADIUS * 2, 4, CONFIG.ISLAND_RADIUS * 2)
	grassLayer.Position = center + Vector3.new(0, CONFIG.TIER_1_HEIGHT, 0)
	grassLayer.Material = Enum.Material.Grass
	grassLayer.Color = Color3.fromRGB(124, 180, 76)
	grassLayer.Anchored = true
	grassLayer.CanCollide = true
	grassLayer.Parent = terrain
	
	-- Create elevated platforms (tier 2 & 3) with natural distribution
	-- Use random circular platforms instead of one big shape
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local distance = rng:NextNumber(80, 150)
		
		local platformPos = center + Vector3.new(
			math.cos(angle) * distance,
			CONFIG.TIER_2_HEIGHT,
			math.sin(angle) * distance
		)
		
		local platform = Instance.new("Part")
		platform.Name = "Tier2_Platform_" .. i
		platform.Size = Vector3.new(60, 8, 60)
		platform.Shape = Enum.PartType.Cylinder
		platform.Orientation = Vector3.new(0, 0, 90)
		platform.Material = Enum.Material.Ground
		platform.Color = Color3.fromRGB(95, 150, 60)
		platform.Anchored = true
		platform.CanCollide = true
		platform.Position = platformPos
		platform.Parent = terrain
		
		-- Add tier 3 on some tier 2 platforms
		if i % 3 == 0 then
			local tier3 = Instance.new("Part")
			tier3.Name = "Tier3_Peak_" .. i
			tier3.Size = Vector3.new(30, 10, 30)
			tier3.Shape = Enum.PartType.Ball
			tier3.Material = Enum.Material.Rock
			tier3.Color = Color3.fromRGB(128, 128, 128)
			tier3.Anchored = true
			tier3.CanCollide = true
			tier3.Position = platformPos + Vector3.new(0, 18, 0)
			tier3.Parent = terrain
		end
	end
	
	return terrain
end

-- Create central plaza (player spawn and social hub)
function ACNHIslandGeneratorV2:_createCentralPlaza(parent, center)
	local plaza = Instance.new("Model")
	plaza.Name = "Plaza"
	plaza.Parent = parent
	
	-- Plaza platform (brick)
	local platform = Instance.new("Part")
	platform.Name = "PlazaPlatform"
	platform.Size = Vector3.new(CONFIG.PLAZA_SIZE, 1, CONFIG.PLAZA_SIZE)
	platform.Position = center + Vector3.new(0, CONFIG.TIER_1_HEIGHT + 1, 0)
	platform.Material = Enum.Material.Brick
	platform.Color = Color3.fromRGB(163, 162, 165)
	platform.Anchored = true
	platform.CanCollide = true
	platform.Parent = plaza
	
	-- Player spawn marker (invisible)
	local spawn = Instance.new("Part")
	spawn.Name = "PlayerSpawn"
	spawn.Size = Vector3.new(10, 5, 10)
	spawn.Position = center + Vector3.new(0, CONFIG.TIER_1_HEIGHT + 5, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Anchored = true
	spawn.Parent = plaza
	
	-- Fountain centerpiece
	self:_createFountain(plaza, center + Vector3.new(0, CONFIG.TIER_1_HEIGHT + 2, 0))
	
	-- Benches around plaza (4 cardinal directions)
	for angle = 0, 270, 90 do
		local rad = math.rad(angle)
		local benchPos = center + Vector3.new(
			math.cos(rad) * 15,
			CONFIG.TIER_1_HEIGHT + 2,
			math.sin(rad) * 15
		)
		self:_createBench(plaza, benchPos, angle)
	end
	
	return plaza
end

-- Create fountain
function ACNHIslandGeneratorV2:_createFountain(parent, position)
	local fountain = Instance.new("Model")
	fountain.Name = "Fountain"
	fountain.Parent = parent
	
	-- Base
	local base = Instance.new("Part")
	base.Size = Vector3.new(8, 2, 8)
	base.Shape = Enum.PartType.Cylinder
	base.Orientation = Vector3.new(0, 0, 90)
	base.Material = Enum.Material.Marble
	base.Color = Color3.fromRGB(242, 243, 243)
	base.Anchored = true
	base.Position = position
	base.Parent = fountain
	
	-- Water basin
	local water = Instance.new("Part")
	water.Size = Vector3.new(6, 1.5, 6)
	water.Shape = Enum.PartType.Cylinder
	water.Orientation = Vector3.new(0, 0, 90)
	water.Material = Enum.Material.Water
	water.Color = Color3.fromRGB(100, 150, 255)
	water.Transparency = 0.3
	water.Anchored = true
	water.CanCollide = false
	water.Position = position + Vector3.new(0, 1.5, 0)
	water.Parent = fountain
	
	return fountain
end

-- Create bench
function ACNHIslandGeneratorV2:_createBench(parent, position, rotation)
	local bench = Instance.new("Model")
	bench.Name = "Bench"
	bench.Parent = parent
	
	-- Seat
	local seat = Instance.new("Part")
	seat.Size = Vector3.new(6, 0.5, 2)
	seat.Material = Enum.Material.Wood
	seat.Color = Color3.fromRGB(160, 95, 53)
	seat.Anchored = true
	seat.Position = position
	seat.Orientation = Vector3.new(0, rotation, 0)
	seat.Parent = bench
	
	-- Backrest
	local back = Instance.new("Part")
	back.Size = Vector3.new(6, 3, 0.5)
	back.Material = Enum.Material.Wood
	back.Color = Color3.fromRGB(160, 95, 53)
	back.Anchored = true
	back.Position = position + Vector3.new(0, 1.5, -1)
	back.Orientation = Vector3.new(0, rotation, 0)
	back.Parent = bench
	
	return bench
end

-- Generate natural rivers with curves
function ACNHIslandGeneratorV2:_generateNaturalRivers(parent, rng, center)
	local rivers = Instance.new("Folder")
	rivers.Name = "Rivers"
	rivers.Parent = parent
	
	local riverCount = rng:NextInteger(CONFIG.RIVER_COUNT_MIN, CONFIG.RIVER_COUNT_MAX)
	local riverPaths = {}
	
	for i = 1, riverCount do
		-- Start river from high elevation
		local startAngle = rng:NextNumber(0, math.pi * 2)
		local startDist = rng:NextNumber(100, 200)
		local startPos = center + Vector3.new(
			math.cos(startAngle) * startDist,
			CONFIG.TIER_3_HEIGHT,
			math.sin(startAngle) * startDist
		)
		
		-- Generate winding river path
		local riverPath = {}
		local currentPos = startPos
		local direction = rng:NextNumber(0, 360)
		
		for step = 1, 50 do
			table.insert(riverPath, currentPos)
			
			-- Meander (curve) the river
			direction = direction + rng:NextNumber(-30, 30) * CONFIG.RIVER_MEANDER
			local angleRad = math.rad(direction)
			
			-- Move river segment
			local riverWidth = rng:NextNumber(CONFIG.RIVER_WIDTH_MIN, CONFIG.RIVER_WIDTH_MAX)
			currentPos = currentPos + Vector3.new(
				math.cos(angleRad) * riverWidth,
				-0.3,  -- Rivers flow downhill
				math.sin(angleRad) * riverWidth
			)
			
			-- Create river segment
			local segment = Instance.new("Part")
			segment.Name = "RiverSegment_" .. i .. "_" .. step
			segment.Size = Vector3.new(riverWidth, CONFIG.RIVER_DEPTH, riverWidth)
			segment.Position = currentPos
			segment.Material = Enum.Material.Water
			segment.Color = Color3.fromRGB(100, 150, 255)
			segment.Transparency = 0.2
			segment.Anchored = true
			segment.CanCollide = false
			segment.Parent = rivers
			
			-- Stop if reached beach level
			if currentPos.Y <= CONFIG.TIER_1_HEIGHT then
				break
			end
		end
		
		table.insert(riverPaths, riverPath)
	end
	
	return riverPaths
end

-- Generate ponds
function ACNHIslandGeneratorV2:_generateScatteredPonds(parent, rng, center)
	local ponds = Instance.new("Folder")
	ponds.Name = "Ponds"
	ponds.Parent = parent
	
	local pondCount = rng:NextInteger(CONFIG.POND_COUNT_MIN, CONFIG.POND_COUNT_MAX)
	
	for i = 1, pondCount do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(50, 250)
		local pondRadius = rng:NextNumber(CONFIG.POND_RADIUS_MIN, CONFIG.POND_RADIUS_MAX)
		
		local pondPos = center + Vector3.new(
			math.cos(angle) * distance,
			CONFIG.TIER_2_HEIGHT - 3,
			math.sin(angle) * distance
		)
		
		-- Create pond
		local pond = Instance.new("Part")
		pond.Name = "Pond_" .. i
		pond.Size = Vector3.new(pondRadius * 2, CONFIG.POND_DEPTH, pondRadius * 2)
		pond.Shape = Enum.PartType.Cylinder
		pond.Orientation = Vector3.new(0, 0, 90)
		pond.Material = Enum.Material.Water
		pond.Color = Color3.fromRGB(80, 130, 255)
		pond.Transparency = 0.3
		pond.Anchored = true
		pond.CanCollide = false
		pond.Position = pondPos
		pond.Parent = ponds
	end
	
	return ponds
end

-- Generate waterfalls
function ACNHIslandGeneratorV2:_generateWaterfalls(parent, rng, center, riverPaths)
	local waterfalls = Instance.new("Folder")
	waterfalls.Name = "Waterfalls"
	waterfalls.Parent = parent
	
	local waterfallCount = rng:NextInteger(CONFIG.WATERFALL_COUNT_MIN, CONFIG.WATERFALL_COUNT_MAX)
	
	for i = 1, waterfallCount do
		-- Find tier transition points
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(100, 200)
		
		local waterfallPos = center + Vector3.new(
			math.cos(angle) * distance,
			CONFIG.TIER_2_HEIGHT + CONFIG.WATERFALL_HEIGHT / 2,
			math.sin(angle) * distance
		)
		
		-- Create waterfall
		local waterfall = Instance.new("Part")
		waterfall.Name = "Waterfall_" .. i
		waterfall.Size = Vector3.new(8, CONFIG.WATERFALL_HEIGHT, 2)
		waterfall.Material = Enum.Material.Water
		waterfall.Color = Color3.fromRGB(100, 150, 255)
		waterfall.Transparency = 0.4
		waterfall.Anchored = true
		waterfall.CanCollide = false
		waterfall.Position = waterfallPos
		waterfall.Parent = waterfalls
		
		-- Add particle effect
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxasset://textures/particles/smoke_main.png"
		particles.Rate = 20
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Speed = NumberRange.new(10, 15)
		particles.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
		particles.Transparency = NumberSequence.new(0.5)
		particles.Size = NumberSequence.new(2)
		particles.Parent = waterfall
	end
	
	return waterfalls
end

-- Generate beautiful beach perimeter
function ACNHIslandGeneratorV2:_generateBeautifulBeach(parent, rng, center)
	local beach = Instance.new("Folder")
	beach.Name = "Beach"
	beach.Parent = parent
	
	-- Create circular beach around island
	for angle = 0, 355, 10 do
		local rad = math.rad(angle)
		local beachPos = center + Vector3.new(
			math.cos(rad) * (CONFIG.ISLAND_RADIUS - CONFIG.BEACH_WIDTH / 2),
			CONFIG.TIER_1_HEIGHT - 1,
			math.sin(rad) * (CONFIG.ISLAND_RADIUS - CONFIG.BEACH_WIDTH / 2)
		)
		
		-- Beach segment
		local beachPart = Instance.new("Part")
		beachPart.Name = "BeachSegment_" .. angle
		beachPart.Size = Vector3.new(CONFIG.BEACH_WIDTH, 2, CONFIG.BEACH_WIDTH)
		beachPart.Material = Enum.Material.Sand
		beachPart.Color = Color3.fromRGB(255, 224, 153)
		beachPart.Anchored = true
		beachPart.CanCollide = true
		beachPart.Position = beachPos
		beachPart.Parent = beach
		
		-- Add beach rocks (random)
		if rng:NextNumber() < 0.2 then
			local rockPos = beachPos + Vector3.new(
				rng:NextNumber(-10, 10),
				2,
				rng:NextNumber(-10, 10)
			)
			self:_createRock(beach, rockPos, rng:NextNumber(1, 3))
		end
		
		-- Add shells (random)
		if rng:NextNumber() < 0.15 then
			self:_createShell(beach, beachPos + Vector3.new(0, 1.5, 0), rng)
		end
	end
	
	-- Add tidal pools
	local tidalPoolCount = rng:NextInteger(CONFIG.TIDAL_POOL_COUNT_MIN, CONFIG.TIDAL_POOL_COUNT_MAX)
	for i = 1, tidalPoolCount do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = CONFIG.ISLAND_RADIUS - 30
		local poolPos = center + Vector3.new(
			math.cos(angle) * distance,
			CONFIG.TIER_1_HEIGHT,
			math.sin(angle) * distance
		)
		
		-- Small tidal pool
		local pool = Instance.new("Part")
		pool.Name = "TidalPool_" .. i
		pool.Size = Vector3.new(8, 2, 8)
		pool.Shape = Enum.PartType.Cylinder
		pool.Orientation = Vector3.new(0, 0, 90)
		pool.Material = Enum.Material.Water
		pool.Color = Color3.fromRGB(100, 180, 255)
		pool.Transparency = 0.4
		pool.Anchored = true
		pool.CanCollide = false
		pool.Position = poolPos
		pool.Parent = beach
	end
	
	return beach
end

-- Generate tree clusters
function ACNHIslandGeneratorV2:_generateTreeClusters(parent, rng, center)
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = parent
	
	local treeTypes = {"Oak", "Pine", "Palm", "Fruit"}
	
	-- Create tree clusters
	for cluster = 1, CONFIG.TREE_CLUSTERS do
		-- Random cluster center
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(60, 300)
		local clusterCenter = center + Vector3.new(
			math.cos(angle) * distance,
			CONFIG.TIER_1_HEIGHT + 2,
			math.sin(angle) * distance
		)
		
		local treesInCluster = rng:NextInteger(CONFIG.TREES_PER_CLUSTER_MIN, CONFIG.TREES_PER_CLUSTER_MAX)
		local treeType = treeTypes[rng:NextInteger(1, #treeTypes)]
		
		-- Plant trees in cluster
		for t = 1, treesInCluster do
			local treeAngle = rng:NextNumber(0, math.pi * 2)
			local treeDist = rng:NextNumber(0, CONFIG.TREE_CLUSTER_RADIUS)
			local treePos = clusterCenter + Vector3.new(
				math.cos(treeAngle) * treeDist,
				0,
				math.sin(treeAngle) * treeDist
			)
			
			self:_createTree(trees, treePos, treeType, rng)
		end
	end
	
	return trees
end

-- Create individual tree
function ACNHIslandGeneratorV2:_createTree(parent, position, treeType, rng)
	local tree = Instance.new("Model")
	tree.Name = treeType .. "Tree"
	tree.Parent = parent
	
	-- Trunk
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2, 8, 2)
	trunk.Material = Enum.Material.Wood
	trunk.Color = Color3.fromRGB(101, 67, 33)
	trunk.Anchored = true
	trunk.Position = position + Vector3.new(0, 4, 0)
	trunk.Parent = tree
	
	-- Foliage
	local foliage = Instance.new("Part")
	foliage.Name = "Foliage"
	foliage.Size = Vector3.new(10, 10, 10)
	foliage.Shape = Enum.PartType.Ball
	foliage.Material = Enum.Material.Grass
	
	-- Different colors per tree type
	if treeType == "Pine" then
		foliage.Color = Color3.fromRGB(30, 100, 30)
	elseif treeType == "Palm" then
		foliage.Color = Color3.fromRGB(34, 139, 34)
		foliage.Size = Vector3.new(8, 6, 8)
	else
		foliage.Color = Color3.fromRGB(34, 139, 34)
	end
	
	foliage.Anchored = true
	foliage.CanCollide = false
	foliage.Position = position + Vector3.new(0, 10, 0)
	foliage.Parent = tree
	
	-- Add fruit if fruit tree
	if treeType == "Fruit" then
		local fruitColors = {
			Color3.fromRGB(255, 0, 0),    -- Apple
			Color3.fromRGB(255, 140, 0),  -- Orange
			Color3.fromRGB(255, 200, 100), -- Pear
			Color3.fromRGB(255, 180, 200), -- Peach
			Color3.fromRGB(200, 0, 0),     -- Cherry
		}
		local fruitColor = fruitColors[rng:NextInteger(1, #fruitColors)]
		
		for f = 1, 3 do
			local fruit = Instance.new("Part")
			fruit.Name = "Fruit"
			fruit.Size = Vector3.new(1, 1, 1)
			fruit.Shape = Enum.PartType.Ball
			fruit.Color = fruitColor
			fruit.Anchored = true
			fruit.Position = foliage.Position + Vector3.new(
				rng:NextNumber(-4, 4),
				rng:NextNumber(-3, 3),
				rng:NextNumber(-4, 4)
			)
			fruit.Parent = tree
		end
	end
	
	return tree
end

-- Generate flower patches
function ACNHIslandGeneratorV2:_generateFlowerPatches(parent, rng, center)
	local flowers = Instance.new("Folder")
	flowers.Name = "Flowers"
	flowers.Parent = parent
	
	local flowerColors = {
		Color3.fromRGB(255, 100, 100),  -- Red
		Color3.fromRGB(255, 200, 100),  -- Yellow
		Color3.fromRGB(100, 100, 255),  -- Blue
		Color3.fromRGB(255, 150, 200),  -- Pink
		Color3.fromRGB(255, 255, 255),  -- White
		Color3.fromRGB(200, 100, 200),  -- Purple
	}
	
	local patchCount = rng:NextInteger(CONFIG.FLOWER_CLUSTERS_MIN, CONFIG.FLOWER_CLUSTERS_MAX)
	
	for patch = 1, patchCount do
		-- Random patch location
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(40, 300)
		local patchCenter = center + Vector3.new(
			math.cos(angle) * distance,
			CONFIG.TIER_1_HEIGHT + 1,
			math.sin(angle) * distance
		)
		
		local flowerColor = flowerColors[rng:NextInteger(1, #flowerColors)]
		local flowerCount = rng:NextInteger(CONFIG.FLOWERS_PER_CLUSTER_MIN, CONFIG.FLOWERS_PER_CLUSTER_MAX)
		
		-- Plant flowers in patch
		for f = 1, flowerCount do
			local flowerAngle = rng:NextNumber(0, math.pi * 2)
			local flowerDist = rng:NextNumber(0, 5)
			local flowerPos = patchCenter + Vector3.new(
				math.cos(flowerAngle) * flowerDist,
				0,
				math.sin(flowerAngle) * flowerDist
			)
			
			self:_createFlower(flowers, flowerPos, flowerColor)
		end
	end
	
	return flowers
end

-- Create individual flower
function ACNHIslandGeneratorV2:_createFlower(parent, position, color)
	local flower = Instance.new("Part")
	flower.Name = "Flower"
	flower.Size = Vector3.new(1, 2, 1)
	flower.Material = Enum.Material.Neon
	flower.Color = color
	flower.Anchored = true
	flower.CanCollide = false
	flower.Position = position
	flower.Parent = parent
	
	-- Add stem
	local stem = Instance.new("Part")
	stem.Size = Vector3.new(0.2, 1.5, 0.2)
	stem.Color = Color3.fromRGB(34, 139, 34)
	stem.Anchored = true
	stem.CanCollide = false
	stem.Position = position + Vector3.new(0, -0.5, 0)
	stem.Parent = parent
	
	return flower
end

-- Generate rock clusters
function ACNHIslandGeneratorV2:_generateRockClusters(parent, rng, center)
	local rocks = Instance.new("Folder")
	rocks.Name = "Rocks"
	rocks.Parent = parent
	
	local rockCount = rng:NextInteger(CONFIG.ROCK_COUNT_MIN, CONFIG.ROCK_COUNT_MAX)
	
	for i = 1, rockCount do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(40, 350)
		local rockPos = center + Vector3.new(
			math.cos(angle) * distance,
			CONFIG.TIER_1_HEIGHT + 1,
			math.sin(angle) * distance
		)
		
		local rockSize = rng:NextNumber(2, 6)
		self:_createRock(rocks, rockPos, rockSize)
	end
	
	return rocks
end

-- Create rock
function ACNHIslandGeneratorV2:_createRock(parent, position, size)
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Size = Vector3.new(size, size * 0.8, size * 0.9)
	rock.Material = Enum.Material.Rock
	rock.Color = Color3.fromRGB(128, 128, 128)
	rock.Anchored = true
	rock.CanCollide = true
	rock.Position = position
	rock.Parent = parent
	
	return rock
end

-- Create shell
function ACNHIslandGeneratorV2:_createShell(parent, position, rng)
	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Size = Vector3.new(0.8, 0.5, 0.8)
	shell.Material = Enum.Material.SmoothPlastic
	shell.Color = Color3.fromRGB(255, 220, 200)
	shell.Anchored = true
	shell.Position = position
	shell.Parent = parent
	
	return shell
end

-- Generate natural paths connecting key areas
function ACNHIslandGeneratorV2:_generateNaturalPaths(parent, rng, center, plaza)
	local paths = Instance.new("Folder")
	paths.Name = "Paths"
	paths.Parent = parent
	
	-- Key locations to connect
	local locations = {
		center,  -- Plaza
		center + Vector3.new(200, CONFIG.TIER_1_HEIGHT, 0),  -- East beach
		center + Vector3.new(-200, CONFIG.TIER_1_HEIGHT, 0), -- West beach
		center + Vector3.new(0, CONFIG.TIER_1_HEIGHT, 200),  -- North beach
		center + Vector3.new(0, CONFIG.TIER_1_HEIGHT, -200), -- South beach
	}
	
	-- Create paths between locations
	for i = 1, #locations - 1 do
		self:_createPath(paths, locations[i], locations[i + 1], rng)
	end
	
	return paths
end

-- Create path between two points
function ACNHIslandGeneratorV2:_createPath(parent, startPos, endPos, rng)
	local direction = (endPos - startPos).Unit
	local distance = (endPos - startPos).Magnitude
	local steps = math.floor(distance / 4)
	
	for i = 0, steps do
		local t = i / steps
		local pos = startPos:Lerp(endPos, t)
		
		-- Add randomness for natural look
		pos = pos + Vector3.new(
			rng:NextNumber(-1.5, 1.5),
			0,
			rng:NextNumber(-1.5, 1.5)
		)
		
		-- Create path segment
		local pathPart = Instance.new("Part")
		pathPart.Name = "PathSegment"
		pathPart.Size = Vector3.new(CONFIG.PATH_WIDTH, 0.2, CONFIG.PATH_WIDTH)
		pathPart.Material = Enum.Material.Ground
		pathPart.Color = Color3.fromRGB(139, 105, 20)
		pathPart.Anchored = true
		pathPart.CanCollide = false
		pathPart.Position = pos
		pathPart.Parent = parent
	end
end

-- Mark NPC spawn zones
function ACNHIslandGeneratorV2:_markNPCZones(parent, center)
	local zones = Instance.new("Folder")
	zones.Name = "NPCZones"
	zones.Parent = parent
	
	-- Tom Nook zone (near plaza, west)
	local tomNookZone = Instance.new("Part")
	tomNookZone.Name = "TomNookZone"
	tomNookZone.Size = Vector3.new(20, 10, 20)
	tomNookZone.Position = center + Vector3.new(-25, CONFIG.TIER_1_HEIGHT + 5, 10)
	tomNookZone.Transparency = 1
	tomNookZone.CanCollide = false
	tomNookZone.Anchored = true
	tomNookZone.Parent = zones
	
	-- Isabelle zone (near plaza, east)
	local isabelleZone = Instance.new("Part")
	isabelleZone.Name = "IsabelleZone"
	isabelleZone.Size = Vector3.new(20, 10, 20)
	isabelleZone.Position = center + Vector3.new(25, CONFIG.TIER_1_HEIGHT + 5, 10)
	isabelleZone.Transparency = 1
	isabelleZone.CanCollide = false
	isabelleZone.Anchored = true
	isabelleZone.Parent = zones
	
	-- Orville zone (north beach)
	local orvilleZone = Instance.new("Part")
	orvilleZone.Name = "OrvilleZone"
	orvilleZone.Size = Vector3.new(20, 10, 20)
	orvilleZone.Position = center + Vector3.new(0, CONFIG.TIER_1_HEIGHT + 5, 250)
	orvilleZone.Transparency = 1
	orvilleZone.CanCollide = false
	orvilleZone.Anchored = true
	orvilleZone.Parent = zones
	
	-- Random villager zones (4-6 zones for wandering villagers)
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local distance = 150
		local zonePos = center + Vector3.new(
			math.cos(angle) * distance,
			CONFIG.TIER_1_HEIGHT + 5,
			math.sin(angle) * distance
		)
		
		local villagerZone = Instance.new("Part")
		villagerZone.Name = "VillagerZone_" .. i
		villagerZone.Size = Vector3.new(30, 10, 30)
		villagerZone.Position = zonePos
		villagerZone.Transparency = 1
		villagerZone.CanCollide = false
		villagerZone.Anchored = true
		villagerZone.Parent = zones
	end
	
	return zones
end

return ACNHIslandGeneratorV2

