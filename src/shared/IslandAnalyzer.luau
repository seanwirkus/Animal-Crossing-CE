--[[
	IslandAnalyzer.luau
	
	Scans existing terrain to understand the island layout:
	- Identifies flat areas, slopes, cliffs
	- Detects water bodies and beaches
	- Maps existing objects (trees, rocks, buildings)
	- Creates a spatial grid for efficient querying
	
	Used by IslandGenerator to make informed placement decisions.
]]

local GenerationRules = require(script.Parent.Parent.Shared.GenerationRules)

local IslandAnalyzer = {}
IslandAnalyzer.__index = IslandAnalyzer

--[[
	Create a new analyzer for the given terrain
	@param terrain The Terrain instance to analyze
	@param bounds Optional bounds (defaults to island radius from rules)
]]
function IslandAnalyzer.new(terrain: Terrain, bounds: Region3?)
	local self = setmetatable({}, IslandAnalyzer)
	
	self.terrain = terrain
	self.bounds = bounds or Region3.new(
		Vector3.new(-GenerationRules.Constraints.ISLAND_RADIUS, -50, -GenerationRules.Constraints.ISLAND_RADIUS),
		Vector3.new(GenerationRules.Constraints.ISLAND_RADIUS, 100, GenerationRules.Constraints.ISLAND_RADIUS)
	)
	
	-- Spatial grid for fast lookups
	self.gridSize = GenerationRules.Terrain.ANALYSIS_GRID_SIZE
	self.grid = {} -- [gridX][gridZ] = {terrainType, height, slope, objects}
	
	-- Existing objects mapped by type
	self.existingObjects = {
		trees = {},
		rocks = {},
		flowers = {},
		buildings = {},
		furniture = {},
		other = {}
	}
	
	-- Analysis results
	self.flatAreas = {} -- Areas suitable for buildings
	self.beaches = {} -- Sandy areas near water
	self.waterBodies = {} -- Lakes, rivers, ocean
	self.cliffs = {} -- Steep areas
	
	print("[IslandAnalyzer] ✅ Initialized")
	
	return self
end

--[[
	Scan the entire island and populate analysis data
]]
function IslandAnalyzer:analyzeIsland()
	print("[IslandAnalyzer] 🔍 Starting island analysis...")
	local startTime = tick()
	
	-- Step 1: Analyze terrain
	self:analyzeTerrain()
	
	-- Step 2: Map existing objects
	self:mapExistingObjects()
	
	-- Step 3: Identify special zones
	self:identifyZones()
	
	local elapsed = tick() - startTime
	print(string.format("[IslandAnalyzer] ✅ Analysis complete in %.2fs", elapsed))
	print(string.format("  - Grid cells: %d", self:getGridCellCount()))
	print(string.format("  - Flat areas: %d", #self.flatAreas))
	print(string.format("  - Beaches: %d", #self.beaches))
	print(string.format("  - Existing trees: %d", #self.existingObjects.trees))
	print(string.format("  - Existing rocks: %d", #self.existingObjects.rocks))
	print(string.format("  - Existing buildings: %d", #self.existingObjects.buildings))
end

--[[
	Analyze terrain elevation, slope, and materials
]]
function IslandAnalyzer:analyzeTerrain()
	print("[IslandAnalyzer] 📐 Analyzing terrain...")
	
	local min = self.bounds.CFrame.Position - self.bounds.Size / 2
	local max = self.bounds.CFrame.Position + self.bounds.Size / 2
	
	-- Sample in grid pattern
	for x = min.X, max.X, self.gridSize do
		for z = min.Z, max.Z, self.gridSize do
			local gridX = math.floor(x / self.gridSize)
			local gridZ = math.floor(z / self.gridSize)
			
			-- Sample multiple points within this grid cell
			local heights = {}
			local materials = {}
			
			for dx = 0, self.gridSize, self.gridSize / 2 do
				for dz = 0, self.gridSize, self.gridSize / 2 do
					local samplePos = Vector3.new(x + dx, max.Y, z + dz)
					local ray = Ray.new(samplePos, Vector3.new(0, -(max.Y - min.Y), 0))
					local region = Region3.new(samplePos - Vector3.new(0.1, 0.1, 0.1), samplePos + Vector3.new(0.1, 0.1, 0.1))
					region = region:ExpandToGrid(4)
					
					-- Read terrain at this point
					local materials_arr, sizes = self.terrain:ReadVoxels(region, 4)
					local size = materials_arr.Size
					if size.X > 0 and size.Y > 0 and size.Z > 0 then
						local material = materials_arr[1][1][1]
						table.insert(materials, material)
						
						-- Estimate height (simplified)
						if material ~= Enum.Material.Air then
							table.insert(heights, samplePos.Y)
						end
					end
				end
			end
			
			-- Calculate average height and slope
			local avgHeight = 0
			if #heights > 0 then
				for _, h in ipairs(heights) do
					avgHeight = avgHeight + h
				end
				avgHeight = avgHeight / #heights
			end
			
			local slope = 0
			if #heights >= 2 then
				local minHeight = math.min(table.unpack(heights))
				local maxHeight = math.max(table.unpack(heights))
				slope = (maxHeight - minHeight) / self.gridSize
			end
			
			-- Determine dominant material
			local materialCounts = {}
			for _, mat in ipairs(materials) do
				materialCounts[mat] = (materialCounts[mat] or 0) + 1
			end
			
			local dominantMaterial = Enum.Material.Air
			local maxCount = 0
			for mat, count in pairs(materialCounts) do
				if count > maxCount then
					maxCount = count
					dominantMaterial = mat
				end
			end
			
			-- Store in grid
			if not self.grid[gridX] then
				self.grid[gridX] = {}
			end
			
			self.grid[gridX][gridZ] = {
				position = Vector3.new(x + self.gridSize/2, avgHeight, z + self.gridSize/2),
				height = avgHeight,
				slope = slope,
				material = dominantMaterial,
				isFlat = slope < GenerationRules.Terrain.FLAT_SLOPE_THRESHOLD,
				isWater = dominantMaterial == Enum.Material.Water,
				isBeach = dominantMaterial == Enum.Material.Sand or dominantMaterial == Enum.Material.Ground,
				objects = {} -- Will be populated by mapExistingObjects
			}
		end
	end
	
	print(string.format("[IslandAnalyzer] ✅ Terrain analysis complete - %d grid cells", self:getGridCellCount()))
end

--[[
	Map all existing objects in the workspace
]]
function IslandAnalyzer:mapExistingObjects()
	print("[IslandAnalyzer] 🗺️ Mapping existing objects...")
	
	-- Find all objects within bounds
	local objectsFound = 0
	
	-- Scan workspace for objects
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("Model") then
			local pos = nil
			
			if obj:IsA("BasePart") then
				pos = obj.Position
			elseif obj:IsA("Model") then
				pos = obj:GetPivot().Position
			end
			
			if pos and self:isWithinBounds(pos) then
				-- Classify object
				local objType = self:classifyObject(obj)
				
				if objType ~= "other" then
					local objData = {
						instance = obj,
						position = pos,
						size = obj:IsA("Model") and obj:GetExtentsSize() or obj.Size,
						type = objType
					}
					
					table.insert(self.existingObjects[objType], objData)
					
					-- Add to spatial grid
					local gridX, gridZ = self:worldToGrid(pos)
					if self.grid[gridX] and self.grid[gridX][gridZ] then
						table.insert(self.grid[gridX][gridZ].objects, objData)
					end
					
					objectsFound = objectsFound + 1
				end
			end
		end
	end
	
	print(string.format("[IslandAnalyzer] ✅ Mapped %d objects", objectsFound))
end

--[[
	Classify an object into a category
]]
function IslandAnalyzer:classifyObject(obj: Instance): string
	local name = obj.Name:lower()
	
	if name:find("tree") then
		return "trees"
	elseif name:find("rock") or name:find("stone") or name:find("boulder") then
		return "rocks"
	elseif name:find("flower") or name:find("rose") or name:find("tulip") then
		return "flowers"
	elseif name:find("house") or name:find("building") or name:find("shop") or name:find("museum") then
		return "buildings"
	elseif name:find("bench") or name:find("lamp") or name:find("fountain") then
		return "furniture"
	else
		return "other"
	end
end

--[[
	Identify special zones (flat areas, beaches, etc.)
]]
function IslandAnalyzer:identifyZones()
	print("[IslandAnalyzer] 🏝️ Identifying zones...")
	
	-- Find flat areas suitable for buildings
	for gridX, column in pairs(self.grid) do
		for gridZ, cell in pairs(column) do
			if cell.isFlat and not cell.isWater then
				-- Check if area is large enough
				local flatRadius = self:getFlatAreaRadius(gridX, gridZ)
				
				if flatRadius >= GenerationRules.Buildings.MIN_FLAT_AREA then
					table.insert(self.flatAreas, {
						position = cell.position,
						radius = flatRadius,
						gridX = gridX,
						gridZ = gridZ
					})
				end
			end
			
			-- Identify beaches (sand near water)
			if cell.isBeach then
				local nearWater = self:isNearWater(cell.position, GenerationRules.Terrain.BEACH_WATER_DISTANCE)
				if nearWater then
					table.insert(self.beaches, {
						position = cell.position,
						gridX = gridX,
						gridZ = gridZ
					})
				end
			end
		end
	end
	
	print(string.format("[IslandAnalyzer] ✅ Identified %d flat areas, %d beaches", #self.flatAreas, #self.beaches))
end

--[[
	Get radius of flat area around a grid cell
]]
function IslandAnalyzer:getFlatAreaRadius(centerX: number, centerZ: number): number
	local radius = 0
	
	for r = 1, 10 do
		local allFlat = true
		
		-- Check cells in square around center
		for dx = -r, r do
			for dz = -r, r do
				local x = centerX + dx
				local z = centerZ + dz
				
				if self.grid[x] and self.grid[x][z] then
					if not self.grid[x][z].isFlat or self.grid[x][z].isWater then
						allFlat = false
						break
					end
				else
					allFlat = false
					break
				end
			end
			if not allFlat then break end
		end
		
		if allFlat then
			radius = r * self.gridSize
		else
			break
		end
	end
	
	return radius
end

--[[
	Check if position is near water
]]
function IslandAnalyzer:isNearWater(position: Vector3, maxDistance: number): boolean
	local gridX, gridZ = self:worldToGrid(position)
	
	-- Check surrounding cells
	local searchRadius = math.ceil(maxDistance / self.gridSize)
	
	for dx = -searchRadius, searchRadius do
		for dz = -searchRadius, searchRadius do
			local x = gridX + dx
			local z = gridZ + dz
			
			if self.grid[x] and self.grid[x][z] and self.grid[x][z].isWater then
				return true
			end
		end
	end
	
	return false
end

--[[
	Convert world position to grid coordinates
]]
function IslandAnalyzer:worldToGrid(position: Vector3): (number, number)
	local gridX = math.floor(position.X / self.gridSize)
	local gridZ = math.floor(position.Z / self.gridSize)
	return gridX, gridZ
end

--[[
	Convert grid coordinates to world position
]]
function IslandAnalyzer:gridToWorld(gridX: number, gridZ: number): Vector3
	return Vector3.new(
		gridX * self.gridSize + self.gridSize / 2,
		0, -- Height will be determined by terrain
		gridZ * self.gridSize + self.gridSize / 2
	)
end

--[[
	Check if position is within analysis bounds
]]
function IslandAnalyzer:isWithinBounds(position: Vector3): boolean
	local min = self.bounds.CFrame.Position - self.bounds.Size / 2
	local max = self.bounds.CFrame.Position + self.bounds.Size / 2
	
	return position.X >= min.X and position.X <= max.X
		and position.Z >= min.Z and position.Z <= max.Z
end

--[[
	Get grid cell at world position
]]
function IslandAnalyzer:getCell(position: Vector3): any
	local gridX, gridZ = self:worldToGrid(position)
	
	if self.grid[gridX] and self.grid[gridX][gridZ] then
		return self.grid[gridX][gridZ]
	end
	
	return nil
end

--[[
	Get all objects near a position
]]
function IslandAnalyzer:getObjectsNear(position: Vector3, radius: number): {any}
	local objects = {}
	local gridX, gridZ = self:worldToGrid(position)
	local searchRadius = math.ceil(radius / self.gridSize)
	
	for dx = -searchRadius, searchRadius do
		for dz = -searchRadius, searchRadius do
			local x = gridX + dx
			local z = gridZ + dz
			
			if self.grid[x] and self.grid[x][z] then
				for _, obj in ipairs(self.grid[x][z].objects) do
					local distance = (obj.position - position).Magnitude
					if distance <= radius then
						table.insert(objects, obj)
					end
				end
			end
		end
	end
	
	return objects
end

--[[
	Get total number of grid cells
]]
function IslandAnalyzer:getGridCellCount(): number
	local count = 0
	for _, column in pairs(self.grid) do
		for _, _ in pairs(column) do
			count = count + 1
		end
	end
	return count
end

--[[
	Export analysis data for debugging/visualization
]]
function IslandAnalyzer:exportData(): {any}
	return {
		gridSize = self.gridSize,
		cellCount = self:getGridCellCount(),
		flatAreas = #self.flatAreas,
		beaches = #self.beaches,
		objects = {
			trees = #self.existingObjects.trees,
			rocks = #self.existingObjects.rocks,
			flowers = #self.existingObjects.flowers,
			buildings = #self.existingObjects.buildings,
			furniture = #self.existingObjects.furniture,
		}
	}
end

return IslandAnalyzer
