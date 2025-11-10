--[[
	IslandAuditor.luau
	
	AI validation system that audits IslandGenerator proposals:
	- Validates against ACNH rules (spacing, placement, natural feel)
	- Scores each proposal (0-100)
	- Provides detailed feedback on rejections
	- Ensures island feels authentic and playable
	
	Acts as a quality control layer - only approved proposals get applied.
]]

local GenerationRules = require(script.Parent.Parent.Shared.GenerationRules)

local IslandAuditor = {}
IslandAuditor.__index = IslandAuditor

--[[
	Create a new auditor
	@param analyzer IslandAnalyzer instance with terrain data
]]
function IslandAuditor.new(analyzer)
	local self = setmetatable({}, IslandAuditor)
	
	self.analyzer = analyzer
	
	-- Audit statistics
	self.stats = {
		totalAudited = 0,
		approved = 0,
		rejected = 0,
		averageScore = 0
	}
	
	print("[IslandAuditor] ✅ Initialized")
	
	return self
end

--[[
	Audit a complete generation pass
	@param proposals Batch from IslandGenerator
	@param minScore Minimum score required for approval (default: 60)
	@return {approved, rejected, feedback}
]]
function IslandAuditor:auditPass(proposals: {any}, minScore: number?): {approved: {any}, rejected: {any}, feedback: {any}}
	print("[IslandAuditor] 🔍 Auditing generation pass...")
	
	local threshold = minScore or 60
	local approved = {trees = {}, rocks = {}, flowers = {}, furniture = {}}
	local rejected = {trees = {}, rocks = {}, flowers = {}, furniture = {}}
	local feedback = {reasons = {}, scores = {}}
	
	-- Audit each category
	for category, items in pairs(proposals) do
		for _, proposal in ipairs(items) do
			local score, reasons = self:scoreProposal(proposal, category)
			
			-- Record score
			table.insert(feedback.scores, {proposal = proposal, score = score, reasons = reasons})
			
			-- Approve or reject
			if score >= threshold then
				table.insert(approved[category], proposal)
			else
				table.insert(rejected[category], proposal)
				table.insert(feedback.reasons, string.format("%s rejected (score: %.0f) - %s", 
					category, score, table.concat(reasons, ", ")))
			end
			
			self.stats.totalAudited = self.stats.totalAudited + 1
		end
	end
	
	-- Count totals
	local approvedCount = #approved.trees + #approved.rocks + #approved.flowers + #approved.furniture
	local rejectedCount = #rejected.trees + #rejected.rocks + #rejected.flowers + #rejected.furniture
	
	self.stats.approved = self.stats.approved + approvedCount
	self.stats.rejected = self.stats.rejected + rejectedCount
	
	print(string.format("[IslandAuditor] ✅ Audit complete - Approved: %d, Rejected: %d", approvedCount, rejectedCount))
	print(string.format("  - Trees: %d/%d", #approved.trees, #approved.trees + #rejected.trees))
	print(string.format("  - Rocks: %d/%d", #approved.rocks, #approved.rocks + #rejected.rocks))
	print(string.format("  - Flowers: %d/%d", #approved.flowers, #approved.flowers + #rejected.flowers))
	
	return {
		approved = approved,
		rejected = rejected,
		feedback = feedback
	}
end

--[[
	Score a single proposal (0-100)
	@return score, reasons array
]]
function IslandAuditor:scoreProposal(proposal: any, category: string): (number, {string})
	local score = 100 -- Start at perfect score
	local reasons = {}
	
	-- Category-specific validation
	if category == "trees" then
		score, reasons = self:scoreTree(proposal)
	elseif category == "rocks" then
		score, reasons = self:scoreRock(proposal)
	elseif category == "flowers" then
		score, reasons = self:scoreFlower(proposal)
	elseif category == "furniture" then
		score, reasons = self:scoreFurniture(proposal)
	end
	
	-- Clamp score
	score = math.clamp(score, 0, 100)
	
	return score, reasons
end

--[[
	Score a tree proposal
]]
function IslandAuditor:scoreTree(proposal: any): (number, {string})
	local score = 100
	local reasons = {}
	
	-- Check spacing from existing trees
	local nearbyTrees = self:getObjectsNear(proposal.position, GenerationRules.Trees.MIN_SPACING, "trees")
	if #nearbyTrees > 0 then
		score = score + (GenerationRules.Scoring.Trees.SPACING_PENALTY * #nearbyTrees)
		table.insert(reasons, string.format("%d trees too close", #nearbyTrees))
	end
	
	-- Check spacing from buildings
	local nearbyBuildings = self:getObjectsNear(proposal.position, GenerationRules.Trees.BUILDING_CLEARANCE, "buildings")
	if #nearbyBuildings > 0 then
		score = score - 15
		table.insert(reasons, "too close to building")
	end
	
	-- Check for clustering (bonus)
	local clusteredTrees = self:getObjectsNear(proposal.position, GenerationRules.Trees.CLUSTER_DISTANCE, "trees")
	if #clusteredTrees >= 2 and #clusteredTrees <= 5 then
		score = score + GenerationRules.Scoring.Trees.CLUSTERING_BONUS
	end
	
	-- Check terrain slope
	local cell = self.analyzer:getCell(proposal.position)
	if cell then
		if cell.slope > GenerationRules.Trees.MAX_SLOPE then
			score = score - 20
			table.insert(reasons, "terrain too steep")
		end
		
		if cell.isWater then
			score = score - 50
			table.insert(reasons, "in water")
		end
	end
	
	-- Palm trees only on beaches
	if proposal.subtype == "Palm Tree" then
		local isBeach = self:isOnBeach(proposal.position)
		if not isBeach then
			score = score - 30
			table.insert(reasons, "palm tree not on beach")
		end
	end
	
	-- Check density (not too crowded)
	local nearbyAllTrees = self:getObjectsNear(proposal.position, 10, "trees")
	if #nearbyAllTrees > GenerationRules.Trees.MAX_PER_ZONE then
		score = score - 15
		table.insert(reasons, "area too crowded with trees")
	end
	
	return score, reasons
end

--[[
	Score a rock proposal
]]
function IslandAuditor:scoreRock(proposal: any): (number, {string})
	local score = 100
	local reasons = {}
	
	-- Rocks should be in clusters
	local nearbyRocks = self:getObjectsNear(proposal.position, GenerationRules.Rocks.MAX_SPACING_IN_CLUSTER, "rocks")
	if #nearbyRocks >= 2 and #nearbyRocks <= 5 then
		score = score + GenerationRules.Scoring.Rocks.CLUSTER_BONUS
	elseif #nearbyRocks == 0 then
		score = score - 10
		table.insert(reasons, "rock too isolated")
	end
	
	-- Check spacing within cluster
	for _, otherRock in ipairs(nearbyRocks) do
		local distance = (proposal.position - otherRock.position).Magnitude
		if distance < GenerationRules.Rocks.MIN_SPACING_IN_CLUSTER then
			score = score + GenerationRules.Scoring.Rocks.SPACING_PENALTY
			table.insert(reasons, "rocks too close in cluster")
			break
		end
	end
	
	-- Check terrain slope (rocks need flat ground)
	local cell = self.analyzer:getCell(proposal.position)
	if cell then
		if cell.slope <= GenerationRules.Rocks.MAX_SLOPE then
			score = score + GenerationRules.Scoring.Rocks.FLAT_GROUND_BONUS
		else
			score = score - 25
			table.insert(reasons, "terrain too steep for rock")
		end
		
		if cell.isWater then
			score = score - 50
			table.insert(reasons, "rock in water")
		end
	end
	
	-- Check clearance from buildings
	local nearbyBuildings = self:getObjectsNear(proposal.position, GenerationRules.Rocks.BUILDING_CLEARANCE, "buildings")
	if #nearbyBuildings > 0 then
		score = score - 15
		table.insert(reasons, "rock too close to building")
	end
	
	return score, reasons
end

--[[
	Score a flower proposal
]]
function IslandAuditor:scoreFlower(proposal: any): (number, {string})
	local score = 100
	local reasons = {}
	
	-- Flowers should be in patches
	local nearbyFlowers = self:getObjectsNear(proposal.position, 3, "flowers")
	if #nearbyFlowers >= 2 then
		score = score + GenerationRules.Scoring.Flowers.PATCH_BONUS
	end
	
	-- Check for species grouping (same species together)
	local sameSpecies = 0
	for _, flower in ipairs(nearbyFlowers) do
		if flower.subtype == proposal.subtype then
			sameSpecies = sameSpecies + 1
		end
	end
	
	if sameSpecies > 0 then
		score = score + GenerationRules.Scoring.Flowers.SPECIES_GROUPING
	end
	
	-- Check terrain slope
	local cell = self.analyzer:getCell(proposal.position)
	if cell then
		if cell.slope > GenerationRules.Flowers.MAX_SLOPE then
			score = score - 15
			table.insert(reasons, "terrain too steep for flowers")
		end
		
		if cell.isWater then
			score = score - 50
			table.insert(reasons, "flowers in water")
		end
	end
	
	-- Check clearance from buildings
	local nearbyBuildings = self:getObjectsNear(proposal.position, GenerationRules.Flowers.BUILDING_CLEARANCE, "buildings")
	if #nearbyBuildings > 0 then
		score = score - 10
		table.insert(reasons, "flowers too close to building")
	end
	
	return score, reasons
end

--[[
	Score a furniture proposal
]]
function IslandAuditor:scoreFurniture(proposal: any): (number, {string})
	local score = 100
	local reasons = {}
	
	-- TODO: Implement furniture scoring
	-- Check spacing, placement on paths, near buildings, etc.
	
	return score, reasons
end

--[[
	Get objects near a position (from analyzer)
]]
function IslandAuditor:getObjectsNear(position: Vector3, radius: number, objectType: string?): {any}
	local allObjects = self.analyzer:getObjectsNear(position, radius)
	
	if objectType then
		local filtered = {}
		for _, obj in ipairs(allObjects) do
			if obj.type == objectType then
				table.insert(filtered, obj)
			end
		end
		return filtered
	end
	
	return allObjects
end

--[[
	Check if position is on a beach
]]
function IslandAuditor:isOnBeach(position: Vector3): boolean
	for _, beach in ipairs(self.analyzer.beaches) do
		if (position - beach.position).Magnitude < 5 then
			return true
		end
	end
	return false
end

--[[
	Get audit statistics
]]
function IslandAuditor:getStats(): {any}
	local approvalRate = 0
	if self.stats.totalAudited > 0 then
		approvalRate = (self.stats.approved / self.stats.totalAudited) * 100
	end
	
	return {
		totalAudited = self.stats.totalAudited,
		approved = self.stats.approved,
		rejected = self.stats.rejected,
		approvalRate = approvalRate
	}
end

return IslandAuditor
