--[[
	IslandGen/TerrainGenerator.luau
	Simplified 2-tier island generation with clean platforms
	No water, no gradients - just Tier 1 and Tier 2
]]

local Terrain = workspace.Terrain
local Config  = require(script.Parent.Config)
local Util    = require(script.Parent.Util)

local TerrainGenerator = {}

-- Simplified terrain generation ---------------------------------------------------

function TerrainGenerator.GenerateIsland(seed, offset)
	seed = seed or Config.DEFAULT_SEED
	offset = offset or Vector3.new(0, 0, 0)
	local rng = Util.rng(seed)

	-- Validate config
	if not Config.CELL or Config.CELL <= 0 then
		warn("[TerrainGenerator] Invalid CELL size:", Config.CELL, "- using default 6")
		Config.CELL = 6
	end

	-- Don't clear terrain - preserve other islands

	-- Island is split into two zones:
	-- - Inner circle (radius 200): Tier 2 (elevated at height 10)
	-- - Outer ring (200-300): Tier 1 (ground level at height 0)

	local innerRadius = 200    -- Inner circle boundary
	local outerRadius = Config.ISLAND_RADIUS  -- 300
	local cellSize = Vector3.new(Config.CELL, Config.CELL, Config.CELL)

	-- Generate Tier 1 (ground level) - outer ring
	for x = -outerRadius, outerRadius, Config.CELL do
		for z = -outerRadius, outerRadius, Config.CELL do
			local distFromCenter = math.sqrt(x*x + z*z)
			
			-- Tier 1: Outer ring
			if distFromCenter > innerRadius and distFromCenter <= outerRadius then
				local cf = CFrame.new(x + offset.X, Config.TIER_1_HEIGHT + Config.CELL*0.5 + offset.Y, z + offset.Z)
				Terrain:FillBlock(cf, Vector3.new(Config.CELL, Config.CELL, Config.CELL), Enum.Material.Grass)
			end
		end
	end

	-- Generate Tier 2 (elevated) - inner circle
	for x = -innerRadius, innerRadius, Config.CELL do
		for z = -innerRadius, innerRadius, Config.CELL do
			local distFromCenter = math.sqrt(x*x + z*z)
			
			-- Tier 2: Inner circle (elevated)
			if distFromCenter <= innerRadius then
				-- Top surface: Grass
				local cfTop = CFrame.new(x + offset.X, Config.TIER_2_HEIGHT + Config.CELL*0.5 + offset.Y, z + offset.Z)
				Terrain:FillBlock(cfTop, Vector3.new(Config.CELL, Config.CELL, Config.CELL), Enum.Material.Grass)
				
				-- Cliff face (below Tier 2, above Tier 1): Rock/cliff material
				local cliffHeight = Config.TIER_2_HEIGHT - Config.TIER_1_HEIGHT - Config.CELL
				if cliffHeight > 0 then
					local cfCliff = CFrame.new(x + offset.X, Config.TIER_1_HEIGHT + cliffHeight*0.5 + offset.Y, z + offset.Z)
					Terrain:FillBlock(cfCliff, Vector3.new(Config.CELL, cliffHeight, Config.CELL), Enum.Material.Rock)
				end
			end
		end
	end

	-- Create a smooth cliff edge (transition zone from Tier 2 to Tier 1)
	-- Rock blocks along the border create natural cliff walls
	local borderSize = Config.CELL * 3
	for angle = 0, math.pi * 2, 0.1 do
		local x = math.cos(angle) * innerRadius
		local z = math.sin(angle) * innerRadius
		
		-- Place rock blocks to form cliff edge
		for i = 0, Config.TIER_2_HEIGHT - Config.TIER_1_HEIGHT, Config.CELL do
			local cf = CFrame.new(x + offset.X, Config.TIER_1_HEIGHT + i + Config.CELL*0.5 + offset.Y, z + offset.Z)
			Terrain:FillBlock(cf, Vector3.new(Config.CELL, Config.CELL, Config.CELL), Enum.Material.Rock)
		end
	end

	print("[TerrainGenerator] Generated 2-tier island at", offset)
end

return TerrainGenerator
