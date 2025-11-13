--[[
	IslandGenerator.luau
	
	AI-powered procedural island generator that:
	- Proposes placements for trees, rocks, flowers, furniture
	- Uses GenerationRules for ACNH-accurate behavior
	- Works with existing terrain (analyzed by IslandAnalyzer)
	- Proposes changes that get validated by IslandAuditor
	- Learns from rejections to improve future proposals
	
	Generation happens in "passes" - each pass proposes a batch of changes
	that can be reviewed and approved/rejected.
]]

local GenerationRules = require(script.Parent.Parent.Shared.GenerationRules)

local IslandGenerator = {}
IslandGenerator.__index = IslandGenerator

--[[
	Create a new generator
	@param analyzer IslandAnalyzer instance with terrain data
]]
function IslandGenerator.new(analyzer)
	local self = setmetatable({}, IslandGenerator)
	
	self.analyzer = analyzer
	self.random = Random.new()
	
	-- Generation history (for learning)
	self.history = {
		proposed = 0,
		approved = 0,
		rejected = 0,
		rejectionReasons = {} -- Track why proposals failed
	}
	
	-- Current generation pass
	self.currentPass = {
		trees = {},
		rocks = {},
		flowers = {},
		furniture = {}
	}
	
	print("[IslandGenerator] ✅ Initialized")
	
	return self
end

--[[
	Generate a complete pass of proposals
	@param config Optional config {trees = true, rocks = true, etc.}
	@return Proposal batch ready for audit
]]
function IslandGenerator:generatePass(config: {[string]: boolean}?): {any}
	print("[IslandGenerator] 🎲 Generating new pass...")
	
	-- Default: generate everything
	local finalConfig = config or {
		trees = true,
		rocks = true,
		flowers = true,
		furniture = false -- Furniture requires more context
	}
	
	-- Clear current pass
	self.currentPass = {
		trees = {},
		rocks = {},
		flowers = {},
		furniture = {}
	}
	
	-- Generate each type
	if finalConfig.trees then
		self:generateTrees()
	end
	
	if finalConfig.rocks then
		self:generateRocks()
	end
	
	if finalConfig.flowers then
		self:generateFlowers()
	end
	
	if finalConfig.furniture then
		self:generateFurniture()
	end
	
	-- Count total proposals
	local totalProposals = #self.currentPass.trees + #self.currentPass.rocks 
		+ #self.currentPass.flowers + #self.currentPass.furniture
	
	print(string.format("[IslandGenerator] ✅ Generated %d proposals", totalProposals))
	print(string.format("  - Trees: %d", #self.currentPass.trees))
	print(string.format("  - Rocks: %d", #self.currentPass.rocks))
	print(string.format("  - Flowers: %d", #self.currentPass.flowers))
	print(string.format("  - Furniture: %d", #self.currentPass.furniture))
	
	self.history.proposed = self.history.proposed + totalProposals
	
	return self.currentPass
end

--[[
	Generate tree placements with even distribution across island
]]
function IslandGenerator:generateTrees()
	local maxTrees = GenerationRules.Constraints.MAX_TREES_PER_PASS
	local treesGenerated = 0
	local attempts = 0
	local maxAttempts = maxTrees * 20 -- Increased attempts for better distribution
	
	-- Grid-based distribution to ensure even spread
	local gridCellSize = GenerationRules.Trees.GRID_CELL_SIZE
	local treesPerCell = GenerationRules.Trees.TREES_PER_GRID_CELL
	local usedGridCells = {} -- Track which grid cells have trees
	local preferredMaterial = GenerationRules.Trees.PREFERRED_MATERIAL
	local preferredMaterialWeight = GenerationRules.Trees.PREFERRED_MATERIAL_WEIGHT
	
	-- Collect all valid grass cells first (prioritize grass)
	local grassCells = {}
	local otherValidCells = {}
	
	for _, column in pairs(self.analyzer.grid) do
		for _, cell in pairs(column) do
			if cell.isFlat and not cell.isWater and cell.material ~= Enum.Material.Water then
				local validMaterials = {
					[Enum.Material.Grass] = true,
					[Enum.Material.Ground] = true,
					[Enum.Material.Sand] = true,
					[Enum.Material.Snow] = true,
					[Enum.Material.Mud] = true,
				}
				
				if validMaterials[cell.material] and cell.slope <= GenerationRules.Trees.MAX_SLOPE then
					-- Prioritize grass material
					if cell.material == preferredMaterial then
						table.insert(grassCells, cell)
					else
						table.insert(otherValidCells, cell)
					end
				end
			end
		end
	end
	
	-- Shuffle cells for random distribution
	local function shuffleArray(array)
		local shuffled = {}
		for i = 1, #array do
			shuffled[i] = array[i]
		end
		for i = #shuffled, 2, -1 do
			local j = math.random(i)
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		end
		return shuffled
	end
	
	-- Combine cells with preference for grass (grass appears more frequently)
	local allCells = {}
	for i = 1, preferredMaterialWeight do
		for _, cell in ipairs(grassCells) do
			table.insert(allCells, cell)
		end
	end
	for _, cell in ipairs(otherValidCells) do
		table.insert(allCells, cell)
	end
	allCells = shuffleArray(allCells)
	
	-- Function to get grid cell key for position
	local function getGridKey(position)
		local gridX = math.floor(position.X / gridCellSize)
		local gridZ = math.floor(position.Z / gridCellSize)
		return gridX .. "," .. gridZ
	end
	
	-- Function to check if position is in a used grid cell
	local function isGridCellUsed(position)
		local key = getGridKey(position)
		return usedGridCells[key] and usedGridCells[key] >= treesPerCell
	end
	
	-- Function to mark grid cell as used
	local function markGridCellUsed(position)
		local key = getGridKey(position)
		usedGridCells[key] = (usedGridCells[key] or 0) + 1
	end
	
	-- Try placing trees with even distribution - use random sampling instead of sequential
	-- Create shuffled indices to prevent line patterns
	local shuffledIndices = {}
	for i = 1, #allCells do
		table.insert(shuffledIndices, i)
	end
	-- Shuffle indices for random access
	for i = #shuffledIndices, 2, -1 do
		local j = self.random:NextInteger(1, i)
		shuffledIndices[i], shuffledIndices[j] = shuffledIndices[j], shuffledIndices[i]
	end

	for _, index in ipairs(shuffledIndices) do
		if treesGenerated >= maxTrees then
			break
		end

		attempts = attempts + 1
		if attempts >= maxAttempts then
			break
		end

		local cell = allCells[index]
		if cell then
			-- Check if grid cell is already used
			if not isGridCellUsed(cell.position) then
				-- Verify material is suitable for trees (not water)
				local validMaterials = {
					[Enum.Material.Grass] = true,
					[Enum.Material.Ground] = true,
					[Enum.Material.Sand] = true,
					[Enum.Material.Snow] = true,
					[Enum.Material.Mud] = true,
				}

				if validMaterials[cell.material] then
					-- Get position
					local position = cell.position

					-- Verify position is not on water using raycast
					local rayOrigin = Vector3.new(position.X, position.Y + 50, position.Z)
					local rayDirection = Vector3.new(0, -100, 0)

					local raycastParams = RaycastParams.new()
					raycastParams.FilterType = Enum.RaycastFilterType.Include
					raycastParams.FilterDescendantsInstances = {workspace.Terrain}
					raycastParams.IgnoreWater = false -- We want to detect water

					local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
					if rayResult then
						-- Check if we hit water
						if rayResult.Material ~= Enum.Material.Water then
							-- Verify the actual terrain material is valid for trees
							if validMaterials[rayResult.Material] then
								-- Update position to terrain surface
								position = rayResult.Position

								-- Check spacing from existing trees
								local tooClose = false
								local minSpacing = GenerationRules.Trees.MIN_SPACING

								for _, existingTree in ipairs(self.analyzer.existingObjects.trees) do
									local distance = (position - existingTree.position).Magnitude
									if distance < minSpacing then
										tooClose = true
										break
									end
								end

								-- Check spacing from proposed trees in this pass
								if not tooClose then
									for _, proposedTree in ipairs(self.currentPass.trees) do
										local distance = (position - proposedTree.position).Magnitude
										if distance < minSpacing then
											tooClose = true
											break
										end
									end
								end

								if not tooClose and cell.slope <= GenerationRules.Trees.MAX_SLOPE then
									-- Pick tree type
									local treeType = GenerationRules.weightedRandom(GenerationRules.Trees.TYPES)

									-- Special case: Palm trees only on beaches
									if treeType.name == "Palm Tree" and not self:isBeach(position) then
										treeType = GenerationRules.Trees.TYPES[1] -- Fallback to hardwood
									end

									-- Create proposal
									local proposal = {
										type = "tree",
										subtype = treeType.name,
										position = position,
										rotation = self.random:NextNumber(0, 360),
										metadata = {
											cellX = cell.gridX,
											cellZ = cell.gridZ,
											slope = cell.slope,
											material = cell.material
										}
									}

									table.insert(self.currentPass.trees, proposal)
									markGridCellUsed(position)
									treesGenerated = treesGenerated + 1
								end
							end
						end
					end
				end
			end
		end
	end
	
	print(string.format("[IslandGenerator] ✅ Generated %d trees with even distribution (attempts: %d)", treesGenerated, attempts))

	-- Fallback: if no trees were generated, relax constraints to ensure baseline coverage
	if treesGenerated == 0 then
		print("[IslandGenerator] ⚠️ Tree generation produced zero results; running fallback placement...")
		local fallbackTarget = math.min(30, GenerationRules.Constraints.MAX_TREES_PER_PASS)
		local placed = 0

		-- Collect all valid cells for fallback
		local fallbackCells = {}
		for _, column in pairs(self.analyzer.grid) do
			for _, cell in pairs(column) do
				if cell.isFlat and not cell.isWater then
					table.insert(fallbackCells, cell)
				end
			end
		end

		-- Shuffle fallback cells to prevent straight lines
		fallbackCells = shuffleArray(fallbackCells)

		-- Place trees using shuffled cells
		for _, cell in ipairs(fallbackCells) do
			if placed >= fallbackTarget then break end
			local position = cell.position
			-- Raycast to terrain and ensure not water
			local rayOrigin = Vector3.new(position.X, position.Y + 50, position.Z)
			local rayDirection = Vector3.new(0, -100, 0)
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Include
			rp.FilterDescendantsInstances = {workspace.Terrain}
			rp.IgnoreWater = false
			local rr = workspace:Raycast(rayOrigin, rayDirection, rp)
			if rr and rr.Material ~= Enum.Material.Water then
				position = rr.Position
				-- Simple spacing check against proposals in this pass only
				local tooClose = false
				for _, proposed in ipairs(self.currentPass.trees) do
					if (position - proposed.position).Magnitude < 8 then
						tooClose = true
						break
					end
				end
				if not tooClose then
					local treeType = GenerationRules.weightedRandom(GenerationRules.Trees.TYPES)
					-- Avoid palms unless on beach
					if treeType.name == "Palm Tree" and not self:isBeach(position) then
						treeType = GenerationRules.Trees.TYPES[1]
					end
					table.insert(self.currentPass.trees, {
						type = "tree",
						subtype = treeType.name,
						position = position,
						rotation = self.random:NextNumber(0, 360),
						metadata = { fallback = true }
					})
					placed += 1
				end
			end
		end
		print(string.format("[IslandGenerator] ✅ Fallback placed %d baseline trees", placed))
	end
end

--[[
	Generate rock cluster placements
]]
function IslandGenerator:generateRocks()
	local maxRocks = GenerationRules.Constraints.MAX_ROCKS_PER_PASS
	local rocksGenerated = 0
	local attempts = 0
	local maxAttempts = maxRocks * 20 -- Prevent infinite loop
	
	-- Generate in clusters
	while rocksGenerated < maxRocks and attempts < maxAttempts do
		attempts = attempts + 1
		
		local clusterSize = self.random:NextInteger(
			GenerationRules.Rocks.MIN_CLUSTER_SIZE,
			GenerationRules.Rocks.MAX_CLUSTER_SIZE
		)
		
		-- Don't exceed max
		clusterSize = math.min(clusterSize, maxRocks - rocksGenerated)
		
		-- Find a seed position for the cluster
		-- RockPatch should only spawn on Sand and Ground (dirt) materials
		local seedCell = self:getRandomCell({isFlat = true, isWater = false})
		
		if seedCell then
			-- CRITICAL: RockPatch should only spawn on Sand and Ground (dirt) materials
			local validRockMaterials = {
				[Enum.Material.Sand] = true,
				[Enum.Material.Ground] = true,  -- Dirt
				[Enum.Material.Rock] = true,    -- Rock material is also valid
			}
			
			-- Check if material is valid for rocks
			if not validRockMaterials[seedCell.material] then
				-- Skip invalid materials (like Grass, Water, etc.)
				continue
			end
			
			-- Verify using raycast
			local rayOrigin = Vector3.new(seedCell.position.X, seedCell.position.Y + 50, seedCell.position.Z)
			local rayDirection = Vector3.new(0, -100, 0)
			
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Include
			raycastParams.FilterDescendantsInstances = {workspace.Terrain}
			raycastParams.IgnoreWater = false
			
			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			if rayResult then
				-- Check material at hit point
				local hitMaterial = rayResult.Material
				if not validRockMaterials[hitMaterial] then
					-- Not valid material - skip
					continue
				end
			end
			
			if seedCell.slope <= GenerationRules.Rocks.MAX_SLOPE then
				-- Generate cluster around seed position
				local cluster = self:generateRockCluster(seedCell.position, clusterSize)
				
				for _, rock in ipairs(cluster) do
					table.insert(self.currentPass.rocks, rock)
					rocksGenerated = rocksGenerated + 1
				end
			end
		else
			break -- Can't find suitable location
		end
	end

	-- Fallback: ensure at least a small number of rocks
	if rocksGenerated == 0 then
		print("[IslandGenerator] ⚠️ Rock generation produced zero results; running fallback placement...")
		local validRockMaterials = {
			[Enum.Material.Sand] = true,
			[Enum.Material.Ground] = true,
			[Enum.Material.Rock] = true,
		}
		local target = math.min(6, maxRocks)
		local placed = 0
		for _, column in pairs(self.analyzer.grid) do
			for _, cell in pairs(column) do
				if placed >= target then break end
				if cell.isFlat and not cell.isWater then
					local rayOrigin = Vector3.new(cell.position.X, cell.position.Y + 50, cell.position.Z)
					local rayDirection = Vector3.new(0, -100, 0)
					local rp = RaycastParams.new()
					rp.FilterType = Enum.RaycastFilterType.Include
					rp.FilterDescendantsInstances = {workspace.Terrain}
					rp.IgnoreWater = false
					local rr = workspace:Raycast(rayOrigin, rayDirection, rp)
					if rr and validRockMaterials[rr.Material] then
						local pos = rr.Position
						local rockType = GenerationRules.weightedRandom(GenerationRules.Rocks.TYPES)
						table.insert(self.currentPass.rocks, {
							type = "rock",
							subtype = rockType.name,
							position = pos,
							rotation = self.random:NextNumber(0, 360),
							metadata = { fallback = true }
						})
						placed += 1
					end
				end
			end
			if placed >= target then break end
		end
		print(string.format("[IslandGenerator] ✅ Fallback placed %d baseline rocks", placed))
	end
end

--[[
	Generate a rock cluster around a seed position
]]
function IslandGenerator:generateRockCluster(seedPosition: Vector3, size: number): {any}
	local cluster = {}
	local validRockMaterials = {
		[Enum.Material.Sand] = true,
		[Enum.Material.Ground] = true,  -- Dirt
		[Enum.Material.Rock] = true,    -- Rock material
	}
	
	for i = 1, size do
		local attempts = 0
		local maxAttempts = 20
		local placed = false
		
		while not placed and attempts < maxAttempts do
			attempts = attempts + 1
			
			-- Random offset from seed
			local offset = Vector3.new(
				self.random:NextNumber(-GenerationRules.Rocks.MAX_SPACING_IN_CLUSTER, GenerationRules.Rocks.MAX_SPACING_IN_CLUSTER),
				0,
				self.random:NextNumber(-GenerationRules.Rocks.MAX_SPACING_IN_CLUSTER, GenerationRules.Rocks.MAX_SPACING_IN_CLUSTER)
			)
			
			local position = seedPosition + offset
			
			-- Verify material at this position (RockPatch only on sand/dirt)
			local rayOrigin = Vector3.new(position.X, position.Y + 50, position.Z)
			local rayDirection = Vector3.new(0, -100, 0)
			
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Include
			raycastParams.FilterDescendantsInstances = {workspace.Terrain}
			raycastParams.IgnoreWater = false
			
			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			if rayResult then
				-- Check material
				local hitMaterial = rayResult.Material
				if not validRockMaterials[hitMaterial] then
					-- Not valid material - skip this position
					continue
				end
				
				-- Update position to terrain surface
				position = rayResult.Position
			else
				-- No terrain found - skip
				continue
			end
			
			-- Check spacing from other rocks in cluster
			local validSpacing = true
			for _, otherRock in ipairs(cluster) do
				if not GenerationRules.checkSpacing(position, otherRock.position, GenerationRules.Rocks.MIN_SPACING_IN_CLUSTER) then
					validSpacing = false
					break
				end
			end
			
			if validSpacing then
				-- Pick rock type
				local rockType = GenerationRules.weightedRandom(GenerationRules.Rocks.TYPES)
				
				local proposal = {
					type = "rock",
					subtype = rockType.name,
					position = position,
					rotation = self.random:NextNumber(0, 360),
					metadata = {
						cluster = seedPosition,
						clusterSize = size,
						material = rayResult and rayResult.Material or Enum.Material.Ground
					}
				}
				
				table.insert(cluster, proposal)
				placed = true
			end
		end
	end
	
	return cluster
end

--[[
	Generate flower patch placements
]]
function IslandGenerator:generateFlowers()
	local maxFlowers = GenerationRules.Constraints.MAX_FLOWERS_PER_PASS
	local flowersGenerated = 0
	
	-- Generate in patches
	while flowersGenerated < maxFlowers do
		local patchSize = self.random:NextInteger(
			GenerationRules.Flowers.MIN_PATCH_SIZE,
			GenerationRules.Flowers.MAX_PATCH_SIZE
		)
		
		-- Don't exceed max
		patchSize = math.min(patchSize, maxFlowers - flowersGenerated)
		
		-- Find seed position
		local seedCell = self:getRandomCell({isFlat = true, isWater = false})
		
		if seedCell and seedCell.slope <= GenerationRules.Flowers.MAX_SLOPE then
			-- Pick flower species for this patch (all same species)
			local flowerType = GenerationRules.weightedRandom(GenerationRules.Flowers.TYPES)
			
			-- Generate patch
			local patch = self:generateFlowerPatch(seedCell.position, patchSize, flowerType)
			
			for _, flower in ipairs(patch) do
				table.insert(self.currentPass.flowers, flower)
				flowersGenerated = flowersGenerated + 1
			end
		else
			break
		end
	end
end

--[[
	Generate a flower patch around a seed position
]]
function IslandGenerator:generateFlowerPatch(seedPosition: Vector3, size: number, flowerType: any): {any}
	local patch = {}
	
	for i = 1, size do
		local attempts = 0
		local maxAttempts = 20
		local placed = false
		
		while not placed and attempts < maxAttempts do
			attempts = attempts + 1
			
			-- Random offset from seed (flowers can be close together)
			local offset = Vector3.new(
				self.random:NextNumber(-2, 2),
				0,
				self.random:NextNumber(-2, 2)
			)
			
			local position = seedPosition + offset
			
			-- Check minimum spacing
			local validSpacing = true
			for _, otherFlower in ipairs(patch) do
				if (position - otherFlower.position).Magnitude < GenerationRules.Flowers.MIN_SPACING then
					validSpacing = false
					break
				end
			end
			
			if validSpacing then
				-- Pick random color from this species
				local color = flowerType.colors[self.random:NextInteger(1, #flowerType.colors)]
				
				local proposal = {
					type = "flower",
					subtype = flowerType.name,
					color = color,
					position = position,
					rotation = self.random:NextNumber(0, 360),
					metadata = {
						patch = seedPosition,
						patchSize = size
					}
				}
				
				table.insert(patch, proposal)
				placed = true
			end
		end
	end
	
	return patch
end

--[[
	Generate furniture placements (basic implementation)
]]
function IslandGenerator:generateFurniture()
	-- TODO: Implement furniture generation
	-- Requires more context about player preferences and themed areas
	print("[IslandGenerator] ℹ️ Furniture generation not yet implemented")
end

--[[
	Get a random grid cell matching criteria
]]
function IslandGenerator:getRandomCell(criteria: {[string]: any}): any
	-- Collect matching cells
	local candidates = {}
	
	for _, column in pairs(self.analyzer.grid) do
		for _, cell in pairs(column) do
			local matches = true
			
			-- Check each criterion
			for key, value in pairs(criteria) do
				if cell[key] ~= value then
					matches = false
					break
				end
			end
			
			if matches then
				table.insert(candidates, cell)
			end
		end
	end
	
	if #candidates > 0 then
		return candidates[self.random:NextInteger(1, #candidates)]
	end
	
	return nil
end

--[[
	Check if position is on a beach
]]
function IslandGenerator:isBeach(position: Vector3): boolean
	for _, beach in ipairs(self.analyzer.beaches) do
		if (position - beach.position).Magnitude < 10 then
			return true
		end
	end
	return false
end

--[[
	Record approval/rejection of proposals
	(Called by IslandAuditor after validation)
]]
function IslandGenerator:recordFeedback(approved: number, rejected: number, reasons: {string})
	self.history.approved = self.history.approved + approved
	self.history.rejected = self.history.rejected + rejected
	
	-- Track rejection reasons for learning
	for _, reason in ipairs(reasons) do
		self.history.rejectionReasons[reason] = (self.history.rejectionReasons[reason] or 0) + 1
	end
	
	print(string.format("[IslandGenerator] 📊 Feedback recorded - Approved: %d, Rejected: %d", approved, rejected))
end

--[[
	Get generation statistics
]]
function IslandGenerator:getStats(): {any}
	local approvalRate = 0
	if self.history.proposed > 0 then
		approvalRate = (self.history.approved / self.history.proposed) * 100
	end
	
	return {
		proposed = self.history.proposed,
		approved = self.history.approved,
		rejected = self.history.rejected,
		approvalRate = approvalRate,
		topRejectionReasons = self:getTopRejections(5)
	}
end

--[[
	Get top rejection reasons
]]
function IslandGenerator:getTopRejections(count: number): {{reason: string, count: number}}
	local sorted = {}
	
	for reason, cnt in pairs(self.history.rejectionReasons) do
		table.insert(sorted, {reason = reason, count = cnt})
	end
	
	table.sort(sorted, function(a, b)
		return a.count > b.count
	end)
	
	local result = {}
	for i = 1, math.min(count, #sorted) do
		table.insert(result, sorted[i])
	end
	
	return result
end

return IslandGenerator
