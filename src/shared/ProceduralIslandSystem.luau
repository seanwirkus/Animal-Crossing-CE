--[[
	ProceduralIslandSystem.luau
	
	Main orchestrator for AI-powered island generation:
	1. Analyzes existing terrain (IslandAnalyzer)
	2. Generates proposals (IslandGenerator)  
	3. Validates proposals (IslandAuditor)
	4. Applies approved changes to workspace
	5. Learns and iterates
	
	Usage:
		local system = ProceduralIslandSystem.new()
		system:initialize() -- Scan terrain
		system:runGenerationCycle() -- One pass
		system:runMultipleCycles(5) -- Multiple passes
		system:applyApprovedChanges() -- Place objects in world
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IslandAnalyzer = require(script.Parent.IslandAnalyzer)
local IslandGenerator = require(script.Parent.IslandGenerator)
local IslandAuditor = require(script.Parent.IslandAuditor)

local OAK_TREE_TEMPLATE: Model? = ReplicatedStorage:FindFirstChild("OakTree")

local function getOakTreeTemplate(): Model?
	if OAK_TREE_TEMPLATE and OAK_TREE_TEMPLATE.Parent then
		return OAK_TREE_TEMPLATE
	end

	OAK_TREE_TEMPLATE = ReplicatedStorage:FindFirstChild("OakTree")
	return OAK_TREE_TEMPLATE
end

local ProceduralIslandSystem = {}
ProceduralIslandSystem.__index = ProceduralIslandSystem

--[[
	Create a new procedural island system
]]
function ProceduralIslandSystem.new()
	local self = setmetatable({}, ProceduralIslandSystem)
	
	self.analyzer = nil
	self.generator = nil
	self.auditor = nil
	
	-- Pending changes (approved but not yet applied)
	self.pendingChanges = {
		trees = {},
		rocks = {},
		flowers = {},
		furniture = {}
	}
	
	-- Applied changes (for visualization/debugging)
	self.appliedChanges = {
		trees = {},
		rocks = {},
		flowers = {},
		furniture = {}
	}
	
	-- System state
	self.initialized = false
	self.isGenerating = false
	self.cycleCount = 0
	
	print("[ProceduralIslandSystem] ✅ Created")
	
	return self
end

--[[
	Initialize the system (analyze terrain)
	Must be called before generation
]]
function ProceduralIslandSystem:initialize()
	if self.initialized then
		warn("[ProceduralIslandSystem] ⚠️ Already initialized")
		return
	end
	
	print("[ProceduralIslandSystem] 🚀 Initializing system...")
	
	-- Create analyzer and scan terrain
	self.analyzer = IslandAnalyzer.new(workspace.Terrain)
	self.analyzer:analyzeIsland()
	
	-- Create generator and auditor
	self.generator = IslandGenerator.new(self.analyzer)
	self.auditor = IslandAuditor.new(self.analyzer)
	
	self.initialized = true
	
	print("[ProceduralIslandSystem] ✅ System initialized and ready")
	self:printSystemStatus()
end

--[[
	Run a single generation cycle
	@param config Optional {trees = true, rocks = true, etc.}
	@param minScore Minimum audit score (default: 60)
	@return Audit results
]]
function ProceduralIslandSystem:runGenerationCycle(config: {[string]: boolean}?, minScore: number?): {any}?
	if not self.initialized then
		warn("[ProceduralIslandSystem] ❌ System not initialized - call initialize() first")
		return nil
	end
	
	if self.isGenerating then
		warn("[ProceduralIslandSystem] ⚠️ Generation already in progress")
		return nil
	end
	
	self.isGenerating = true
	self.cycleCount = self.cycleCount + 1
	
	print(string.format("[ProceduralIslandSystem] 🎲 Running generation cycle #%d...", self.cycleCount))
	
	-- Step 1: Generate proposals
	local proposals = self.generator:generatePass(config)
	
	-- Step 2: Audit proposals
	local auditResults = self.auditor:auditPass(proposals, minScore)
	
	-- Step 3: Store approved changes as pending
	for category, items in pairs(auditResults.approved) do
		for _, item in ipairs(items) do
			table.insert(self.pendingChanges[category], item)
		end
	end
	
	-- Step 4: Provide feedback to generator
	local approvedCount = #auditResults.approved.trees + #auditResults.approved.rocks 
		+ #auditResults.approved.flowers + #auditResults.approved.furniture
	local rejectedCount = #auditResults.rejected.trees + #auditResults.rejected.rocks 
		+ #auditResults.rejected.flowers + #auditResults.rejected.furniture
	
	self.generator:recordFeedback(approvedCount, rejectedCount, auditResults.feedback.reasons)
	
	self.isGenerating = false
	
	print(string.format("[ProceduralIslandSystem] ✅ Cycle #%d complete", self.cycleCount))
	print(string.format("  - Pending changes: %d", self:getPendingCount()))
	
	return auditResults
end

--[[
	Run multiple generation cycles
	@param count Number of cycles to run
	@param config Optional generation config
	@param minScore Minimum audit score
]]
function ProceduralIslandSystem:runMultipleCycles(count: number, config: {[string]: boolean}?, minScore: number?)
	print(string.format("[ProceduralIslandSystem] 🔄 Running %d generation cycles...", count))
	
	for i = 1, count do
		self:runGenerationCycle(config, minScore)
		task.wait(0.1) -- Small delay between cycles
	end
	
	print(string.format("[ProceduralIslandSystem] ✅ Completed %d cycles", count))
	self:printSystemStatus()
end

--[[
	Apply pending changes to the workspace
	@param category Optional category to apply (nil = all)
	@param maxPerCategory Optional max items per category
]]
function ProceduralIslandSystem:applyApprovedChanges(category: string?, maxPerCategory: number?)
	print("[ProceduralIslandSystem] 🏗️ Applying changes to workspace...")
	
	local limit = maxPerCategory or 999999
	local totalApplied = 0
	
	-- Determine which categories to apply
	local categoriesToApply = {}
	if category then
		table.insert(categoriesToApply, category)
	else
		categoriesToApply = {"trees", "rocks", "flowers", "furniture"}
	end
	
	-- Apply each category
	for _, cat in ipairs(categoriesToApply) do
		local applied = 0
		
		for i, proposal in ipairs(self.pendingChanges[cat]) do
			if applied >= limit then break end
			
			-- Apply the proposal to workspace
			local success = self:applyProposal(proposal, cat)
			
			if success then
				table.insert(self.appliedChanges[cat], proposal)
				applied = applied + 1
				totalApplied = totalApplied + 1
			end
		end
		
		-- Clear pending for this category
		self.pendingChanges[cat] = {}
		
		print(string.format("[ProceduralIslandSystem] ✅ Applied %d %s", applied, cat))
	end
	
	print(string.format("[ProceduralIslandSystem] ✅ Total applied: %d objects", totalApplied))
end

--[[
	Apply a single proposal to the workspace
]]
function ProceduralIslandSystem:applyProposal(proposal: any, category: string): boolean
	-- Find or create storage folder
	local storageFolder = workspace:FindFirstChild("GeneratedObjects")
	if not storageFolder then
		storageFolder = Instance.new("Folder")
		storageFolder.Name = "GeneratedObjects"
		storageFolder.Parent = workspace
	end
	
	local categoryFolder = storageFolder:FindFirstChild(category)
	if not categoryFolder then
		categoryFolder = Instance.new("Folder")
		categoryFolder.Name = category
		categoryFolder.Parent = storageFolder
	end
	
	-- Create object based on type
	local object = nil
	
	print(string.format("[ProceduralIslandSystem] Creating %s at %s", category, tostring(proposal.position)))
	
	if category == "trees" then
		object = self:createTree(proposal)
	elseif category == "rocks" then
		object = self:createRock(proposal)
	elseif category == "flowers" then
		object = self:createFlower(proposal)
	elseif category == "furniture" then
		object = self:createFurniture(proposal)
	end
	
	if object then
		print(string.format("[ProceduralIslandSystem] ✅ Created %s: %s", category, object.Name))
		object.Parent = categoryFolder
		return true
	else
		warn(string.format("[ProceduralIslandSystem] ❌ Failed to create %s", category))
	end
	
	return false
end

--[[
	Create a tree object
]]
function ProceduralIslandSystem:createTree(proposal: any): Instance
	print("[ProceduralIslandSystem] 🌳 Creating tree...")
	
	-- Use raycast to find terrain surface
	local rayOrigin = Vector3.new(proposal.position.X, 200, proposal.position.Z) -- Start high up
	local rayDirection = Vector3.new(0, -400, 0) -- Cast downward
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {workspace.Terrain}
	
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	-- Use raycast result or proposal position as fallback
	local terrainHeight = rayResult and rayResult.Position.Y or proposal.position.Y
	
	print(string.format("[ProceduralIslandSystem] Terrain height: %.2f", terrainHeight))
	
	-- Create a container model for tree + hole + X marker
	local treeContainer = Instance.new("Model")
	treeContainer.Name = proposal.subtype or "Tree"
	
	print("[ProceduralIslandSystem] 🌲 Cloning OakTree from ReplicatedStorage...")
	
	local oakTemplate = getOakTreeTemplate()
	if oakTemplate and oakTemplate:IsA("Model") then
		local tree = oakTemplate:Clone()
		tree.Name = "OakTree"
		
		-- Ensure a PrimaryPart exists (prefer TreeRoot t or Root)
		if not tree.PrimaryPart then
			local preferredRoot = tree:FindFirstChild("TreeRoot t", true)
				or tree:FindFirstChild("Root", true)
			if preferredRoot and preferredRoot:IsA("BasePart") then
				tree.PrimaryPart = preferredRoot
			else
				local firstPart = tree:FindFirstChildWhichIsA("BasePart", true)
				if firstPart then
					tree.PrimaryPart = firstPart
				end
			end
		end
		
		-- Anchor parts so tree stays in place
		for _, descendant in ipairs(tree:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end
		
		-- Apply rotation and place at target position
		local rotationCFrame = CFrame.Angles(0, math.rad(proposal.rotation or 0), 0)
		local baseCFrame = CFrame.new(proposal.position.X, terrainHeight, proposal.position.Z)
		tree:PivotTo(baseCFrame * rotationCFrame)
		
		-- Adjust vertical position so roots sit on terrain
		local lowestPoint = math.huge
		for _, basePart in ipairs(tree:GetDescendants()) do
			if basePart:IsA("BasePart") then
				local partCF = basePart.CFrame
				local partSize = basePart.Size
				local partBottomY = (partCF.Position - (partCF.UpVector * (partSize.Y * 0.5))).Y
				if partBottomY < lowestPoint then
					lowestPoint = partBottomY
				end
			end
		end
		
		if lowestPoint < math.huge then
			local deltaY = terrainHeight - lowestPoint
			local currentPivot = tree:GetPivot()
			tree:PivotTo(currentPivot + Vector3.new(0, deltaY, 0))
		end
		
		tree.Parent = treeContainer
	else
		warn("[ProceduralIslandSystem] ❌ OakTree template missing - using fallback tree")
		
		-- Fallback: Simple part-based tree
		local tree = Instance.new("Part")
		tree.Name = "TreeModel"
		tree.Size = Vector3.new(0.4, 1.6, 0.4) -- 0.2x scale of 2,8,2
		tree.Position = Vector3.new(proposal.position.X, terrainHeight - 1, proposal.position.Z)
		tree.Anchored = true
		tree.Material = Enum.Material.Wood
		tree.BrickColor = BrickColor.new("Brown")
		tree.Rotation = Vector3.new(0, proposal.rotation or 0, 0)
		tree.Parent = treeContainer
		
		-- Add leaves
		local leaves = Instance.new("Part")
		leaves.Name = "Leaves"
		leaves.Size = Vector3.new(1.2, 1.2, 1.2) -- 0.2x scale of 6,6,6
		leaves.Position = tree.Position + Vector3.new(0, 1.4, 0)
		leaves.Anchored = true
		leaves.Material = Enum.Material.Grass
		leaves.BrickColor = BrickColor.new("Dark green")
		leaves.Shape = Enum.PartType.Ball
		leaves.Parent = treeContainer
	end
	
	-- Add hole model (dug up ground)
	local holeSuccess, holeModel = pcall(function()
		return game:GetService("InsertService"):LoadAsset(98139431900134)
	end)
	
	if holeSuccess and holeModel then
		local hole = holeModel:GetChildren()[1]:Clone()
		hole.Name = "Hole"
		
		if hole:IsA("Model") then
			hole:MoveTo(Vector3.new(proposal.position.X, terrainHeight, proposal.position.Z))
		else
			hole.Position = Vector3.new(proposal.position.X, terrainHeight, proposal.position.Z)
		end
		
		hole.Parent = treeContainer
		holeModel:Destroy()
	end
	
	-- Add X marker
	local xSuccess, xModel = pcall(function()
		return game:GetService("InsertService"):LoadAsset(95502544899864)
	end)
	
	if xSuccess and xModel then
		local xMarker = xModel:GetChildren()[1]:Clone()
		xMarker.Name = "XMarker"
		
		if xMarker:IsA("Model") then
			xMarker:MoveTo(Vector3.new(proposal.position.X, terrainHeight + 0.1, proposal.position.Z))
		else
			xMarker.Position = Vector3.new(proposal.position.X, terrainHeight + 0.1, proposal.position.Z)
		end
		
		xMarker.Parent = treeContainer
		xModel:Destroy()
	end
	
	return treeContainer
end

--[[
	Create a rock object
]]
function ProceduralIslandSystem:createRock(proposal: any): Instance
	-- Use raycast to find terrain surface
	local rayOrigin = Vector3.new(proposal.position.X, 200, proposal.position.Z) -- Start high up
	local rayDirection = Vector3.new(0, -400, 0) -- Cast downward
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {workspace.Terrain}
	
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	-- Use raycast result or proposal position as fallback
	local terrainHeight = rayResult and rayResult.Position.Y or proposal.position.Y
	
	-- Create container for rock + debris
	local rockContainer = Instance.new("Model")
	rockContainer.Name = proposal.subtype or "Rock"
	
	-- Load the actual rock model
	local rockSuccess, rockModel = pcall(function()
		return game:GetService("InsertService"):LoadAsset(5496069794)
	end)
	
	if rockSuccess and rockModel then
		local rock = rockModel:GetChildren()[1]:Clone()
		rock.Name = "RockModel"
		
		if rock:IsA("Model") then
			rock:MoveTo(Vector3.new(proposal.position.X, terrainHeight, proposal.position.Z))
			if rock.PrimaryPart then
				rock.PrimaryPart.Orientation = Vector3.new(0, proposal.rotation or 0, 0)
			end
		else
			rock.Position = Vector3.new(proposal.position.X, terrainHeight, proposal.position.Z)
			rock.Orientation = Vector3.new(0, proposal.rotation or 0, 0)
		end
		
		rock.Parent = rockContainer
		rockModel:Destroy()
	else
		warn("[ProceduralIslandSystem] Failed to load rock model, using fallback")
		
		-- Fallback rock
		local rockSize = Vector3.new(
			math.random(2, 4),
			math.random(1, 3),
			math.random(2, 4)
		)
		
		local rock = Instance.new("Part")
		rock.Name = "RockModel"
		rock.Size = rockSize
		rock.Position = Vector3.new(proposal.position.X, terrainHeight + (rockSize.Y / 2) + 0.5, proposal.position.Z)
		rock.Anchored = true
		rock.Material = Enum.Material.Rock
		rock.BrickColor = BrickColor.new("Medium stone grey")
		rock.Rotation = Vector3.new(
			math.random(-10, 10),
			proposal.rotation or 0,
			math.random(-10, 10)
		)
		rock.Shape = Enum.PartType.Ball
		rock.Parent = rockContainer
	end
	
	-- Add rock debris around it
	local debrisSuccess, debrisModel = pcall(function()
		return game:GetService("InsertService"):LoadAsset(85834323079936)
	end)
	
	if debrisSuccess and debrisModel then
		local debris = debrisModel:GetChildren()[1]:Clone()
		debris.Name = "RockDebris"
		
		-- Place debris near the rock
		local offsetX = math.random(-2, 2)
		local offsetZ = math.random(-2, 2)
		
		if debris:IsA("Model") then
			debris:MoveTo(Vector3.new(proposal.position.X + offsetX, terrainHeight, proposal.position.Z + offsetZ))
		else
			debris.Position = Vector3.new(proposal.position.X + offsetX, terrainHeight, proposal.position.Z + offsetZ)
		end
		
		debris.Parent = rockContainer
		debrisModel:Destroy()
	end
	
	return rockContainer
end

--[[
	Create a flower object
]]
function ProceduralIslandSystem:createFlower(proposal: any): Instance
	-- Use raycast to find terrain surface
	local rayOrigin = Vector3.new(proposal.position.X, 200, proposal.position.Z) -- Start high up
	local rayDirection = Vector3.new(0, -400, 0) -- Cast downward
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {workspace.Terrain}
	
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	-- Use raycast result or proposal position as fallback
	local terrainHeight = rayResult and rayResult.Position.Y or proposal.position.Y
	
	-- Load apple model (using as flower/fruit)
	local appleSuccess, appleModel = pcall(function()
		return game:GetService("InsertService"):LoadAsset(2759295720)
	end)
	
	if appleSuccess and appleModel then
		local apple = appleModel:GetChildren()[1]:Clone()
		apple.Name = string.format("%s %s", proposal.color or "Red", proposal.subtype or "Apple")
		
		if apple:IsA("Model") then
			apple:MoveTo(Vector3.new(proposal.position.X, terrainHeight, proposal.position.Z))
		else
			apple.Position = Vector3.new(proposal.position.X, terrainHeight, proposal.position.Z)
		end
		
		appleModel:Destroy()
		return apple
	else
		warn("[ProceduralIslandSystem] Failed to load apple model, using fallback")
		
		-- Fallback flower
		local flower = Instance.new("Part")
		flower.Name = string.format("%s %s", proposal.color or "Red", proposal.subtype or "Flower")
		flower.Size = Vector3.new(0.5, 1, 0.5)
		flower.Position = Vector3.new(proposal.position.X, terrainHeight + 0.5, proposal.position.Z)
		flower.Anchored = true
		flower.Material = Enum.Material.Grass
		
		-- Color based on proposal
		local colorMap = {
			Red = BrickColor.new("Bright red"),
			White = BrickColor.new("White"),
			Yellow = BrickColor.new("Bright yellow"),
			Pink = BrickColor.new("Pink"),
			Orange = BrickColor.new("Bright orange"),
			Blue = BrickColor.new("Bright blue"),
			Black = BrickColor.new("Black")
		}
		
		flower.BrickColor = colorMap[proposal.color] or BrickColor.new("Bright red")
		
		return flower
	end
end

--[[
	Create a furniture object
]]
function ProceduralIslandSystem:createFurniture(proposal: any): Instance
	-- TODO: Implement furniture creation
	local furniture = Instance.new("Part")
	furniture.Name = proposal.subtype or "Furniture"
	furniture.Size = Vector3.new(2, 2, 2)
	furniture.Position = proposal.position
	furniture.Anchored = true
	
	return furniture
end

--[[
	Get count of pending changes
]]
function ProceduralIslandSystem:getPendingCount(): number
	local count = 0
	for _, items in pairs(self.pendingChanges) do
		count = count + #items
	end
	return count
end

--[[
	Clear all pending changes
]]
function ProceduralIslandSystem:clearPending()
	self.pendingChanges = {
		trees = {},
		rocks = {},
		flowers = {},
		furniture = {}
	}
	print("[ProceduralIslandSystem] 🗑️ Cleared all pending changes")
end

--[[
	Print system status
]]
function ProceduralIslandSystem:printSystemStatus()
	print("\n═══════════════════════════════════════════")
	print("  PROCEDURAL ISLAND SYSTEM STATUS")
	print("═══════════════════════════════════════════")
	
	if self.analyzer then
		local analysisData = self.analyzer:exportData()
		print(string.format("📊 Terrain Analysis:"))
		print(string.format("   Grid cells: %d", analysisData.cellCount))
		print(string.format("   Flat areas: %d", analysisData.flatAreas))
		print(string.format("   Beaches: %d", analysisData.beaches))
		print(string.format("   Existing objects: %d", 
			analysisData.objects.trees + analysisData.objects.rocks 
			+ analysisData.objects.flowers + analysisData.objects.buildings))
	end
	
	if self.generator then
		local genStats = self.generator:getStats()
		print(string.format("\n🎲 Generator Stats:"))
		print(string.format("   Proposals: %d", genStats.proposed))
		print(string.format("   Approval rate: %.1f%%", genStats.approvalRate))
		if #genStats.topRejectionReasons > 0 then
			print(string.format("   Top rejection: %s (%d times)", 
				genStats.topRejectionReasons[1].reason, 
				genStats.topRejectionReasons[1].count))
		end
	end
	
	if self.auditor then
		local auditStats = self.auditor:getStats()
		print(string.format("\n🔍 Auditor Stats:"))
		print(string.format("   Total audited: %d", auditStats.totalAudited))
		print(string.format("   Approved: %d", auditStats.approved))
		print(string.format("   Rejected: %d", auditStats.rejected))
		print(string.format("   Approval rate: %.1f%%", auditStats.approvalRate))
	end
	
	print(string.format("\n📋 Current State:"))
	print(string.format("   Generation cycles: %d", self.cycleCount))
	print(string.format("   Pending changes: %d", self:getPendingCount()))
	print(string.format("   Applied changes: %d", 
		#self.appliedChanges.trees + #self.appliedChanges.rocks 
		+ #self.appliedChanges.flowers + #self.appliedChanges.furniture))
	
	print("═══════════════════════════════════════════\n")
end

return ProceduralIslandSystem
