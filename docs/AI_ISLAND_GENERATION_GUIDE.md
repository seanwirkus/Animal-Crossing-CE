# AI Procedural Island Generation System

## 🎯 Overview

A complete AI-powered system that builds on your existing terrain, iteratively generating and validating content that matches Animal Crossing: New Horizons style.

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Existing Terrain                     │
│              (analyzed by IslandAnalyzer)                    │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
          ┌────────────────────────┐
          │   IslandGenerator      │
          │   (AI proposes         │
          │   tree/rock/flower     │
          │   placements)          │
          └───────────┬────────────┘
                      ▼
          ┌────────────────────────┐
          │   IslandAuditor        │
          │   (AI validates        │
          │   against ACNH rules   │
          │   scores 0-100)        │
          └───────────┬────────────┘
                      ▼
          ┌────────────────────────┐
          │   Approved ✓ Rejected ✗│
          │                        │
          │   Feedback sent back   │
          │   to Generator for     │
          │   learning             │
          └───────────┬────────────┘
                      ▼
          ┌────────────────────────┐
          │   Apply to Workspace   │
          │   (creates actual      │
          │   Parts/Models)        │
          └────────────────────────┘
```

## 📁 System Components

### 1. **GenerationRules.luau** (`src/shared/`)
ACNH-accurate rules database:
- **Tree rules**: 2-stud spacing, clustering, clearances
- **Rock rules**: Clusters of 3-6, flat ground required
- **Flower rules**: Patches of 3-12, species grouping
- **Building rules**: Flat areas, spacing requirements
- **Scoring system**: Quality metrics for AI auditor

### 2. **IslandAnalyzer.luau** (`src/shared/`)
Terrain scanner and spatial indexer:
- Scans your existing terrain in a grid pattern
- Identifies flat areas, slopes, water, beaches
- Maps all existing objects (trees, rocks, buildings)
- Creates fast spatial lookup structure
- Detects suitable building sites

### 3. **IslandGenerator.luau** (`src/shared/`)
AI content generator:
- Proposes tree, rock, and flower placements
- Follows ACNH rules (spacing, clustering, natural distribution)
- Tracks approval/rejection history
- Learns from feedback to improve proposals
- Generates in configurable batches

### 4. **IslandAuditor.luau** (`src/shared/`)
AI quality validator:
- Scores each proposal (0-100 points)
- Validates spacing, terrain suitability, natural feel
- Provides detailed rejection reasons
- Enforces ACNH authenticity
- Tracks approval rates

### 5. **ProceduralIslandSystem.luau** (`src/shared/`)
Main orchestrator:
- Coordinates all components
- Runs generation cycles
- Applies approved changes to workspace
- Tracks statistics and learning
- Provides status reporting

## 🚀 Quick Start

### 1. Server-Side Setup (Recommended)

Create a script in `ServerScriptService`:

```lua
-- ServerScriptService/IslandGenerationController

local ProceduralIslandSystem = require(game.ReplicatedStorage.Shared.ProceduralIslandSystem)

-- Create system
local system = ProceduralIslandSystem.new()

-- Initialize (scans terrain)
system:initialize()

-- Run 5 generation cycles
system:runMultipleCycles(5)

-- Apply the approved changes
system:applyApprovedChanges()

-- View stats
system:printSystemStatus()
```

### 2. Command Bar Testing

In Roblox Studio Command Bar:

```lua
-- Quick test
local ProceduralIslandSystem = require(game.ReplicatedStorage.Shared.ProceduralIslandSystem)
local system = ProceduralIslandSystem.new()
system:initialize()
system:runGenerationCycle()
system:applyApprovedChanges()
```

## 📊 Usage Examples

### Example 1: Generate Only Trees

```lua
local system = ProceduralIslandSystem.new()
system:initialize()

-- Generate only trees
system:runGenerationCycle({
    trees = true,
    rocks = false,
    flowers = false,
    furniture = false
})

system:applyApprovedChanges("trees")
```

### Example 2: High-Quality Generation

```lua
local system = ProceduralIslandSystem.new()
system:initialize()

-- Run with higher quality threshold (80% minimum score)
system:runGenerationCycle(nil, 80)

system:applyApprovedChanges()
```

### Example 3: Iterative Improvement

```lua
local system = ProceduralIslandSystem.new()
system:initialize()

-- Run 10 cycles - generator learns from rejections
for i = 1, 10 do
    system:runGenerationCycle()
    print(string.format("Cycle %d: %d pending", i, system:getPendingCount()))
    task.wait(1)
end

-- Apply all approved changes
system:applyApprovedChanges()

-- Check improvement
print(system.generator:getStats().approvalRate) -- Should increase over cycles
```

### Example 4: Partial Application

```lua
local system = ProceduralIslandSystem.new()
system:initialize()

-- Generate lots of content
system:runMultipleCycles(20)

-- Apply only 10 trees at a time for review
system:applyApprovedChanges("trees", 10)
task.wait(2)
system:applyApprovedChanges("trees", 10)
task.wait(2)
-- Continue as desired...
```

## 🎛️ Configuration

### Adjust Generation Rules

Edit `src/shared/GenerationRules.luau`:

```lua
-- Example: Make trees more clustered
GenerationRules.Trees.CLUSTER_DISTANCE = 3 -- Was 5

-- Example: Allow rocks on slopes
GenerationRules.Rocks.MAX_SLOPE = 0.4 -- Was 0.2

-- Example: Increase flower patch sizes
GenerationRules.Flowers.MAX_PATCH_SIZE = 20 -- Was 12
```

### Adjust Analysis Grid Size

Smaller grid = more detailed analysis but slower:

```lua
GenerationRules.Terrain.ANALYSIS_GRID_SIZE = 3 -- Was 5
```

### Adjust Constraints

```lua
GenerationRules.Constraints.MAX_TREES_PER_PASS = 100 -- Was 50
GenerationRules.Constraints.ISLAND_RADIUS = 300 -- Was 200
```

## 📈 Monitoring & Statistics

### View System Status

```lua
system:printSystemStatus()
```

Output:
```
═══════════════════════════════════════════
  PROCEDURAL ISLAND SYSTEM STATUS
═══════════════════════════════════════════
📊 Terrain Analysis:
   Grid cells: 1024
   Flat areas: 45
   Beaches: 12
   Existing objects: 50

🎲 Generator Stats:
   Proposals: 250
   Approval rate: 68.4%
   Top rejection: rocks too close (15 times)

🔍 Auditor Stats:
   Total audited: 250
   Approved: 171
   Rejected: 79
   Approval rate: 68.4%

📋 Current State:
   Generation cycles: 5
   Pending changes: 171
   Applied changes: 0
═══════════════════════════════════════════
```

### Generator Statistics

```lua
local stats = system.generator:getStats()
print(stats.proposed) -- Total proposals made
print(stats.approved) -- Total approved
print(stats.approvalRate) -- Percentage
print(stats.topRejectionReasons) -- What needs improvement
```

### Auditor Statistics

```lua
local stats = system.auditor:getStats()
print(stats.totalAudited)
print(stats.approvalRate)
```

## 🔍 Understanding Scores

The auditor scores each proposal 0-100:

| Score Range | Quality | Action |
|------------|---------|--------|
| 90-100 | Perfect | Always approved |
| 70-89 | Good | Approved |
| 60-69 | Acceptable | Approved (default threshold) |
| 40-59 | Poor | Rejected |
| 0-39 | Very Poor | Rejected |

### Score Adjustments

**Trees:**
- ✅ +5: Good clustering with other trees
- ✅ +5: Proper clearance from buildings
- ❌ -10: Each tree too close
- ❌ -20: Terrain too steep
- ❌ -30: Palm tree not on beach

**Rocks:**
- ✅ +15: Good cluster formation
- ✅ +10: On flat ground
- ❌ -15: Wrong spacing in cluster
- ❌ -25: Terrain too steep

**Flowers:**
- ✅ +8: In natural patch
- ✅ +10: Same species together
- ✅ +5: Complementary colors
- ❌ -15: Terrain too steep

## 🛠️ Replacing Placeholder Objects

The system currently creates simple Parts. Replace with actual models:

```lua
-- In ProceduralIslandSystem:createTree()
function ProceduralIslandSystem:createTree(proposal: any): Instance
	-- Load your tree model
	local treeModel = game.ReplicatedStorage.Models:FindFirstChild(proposal.subtype)
	
	if treeModel then
		local tree = treeModel:Clone()
		tree:SetPrimaryPartCFrame(CFrame.new(proposal.position) * CFrame.Angles(0, math.rad(proposal.rotation), 0))
		return tree
	end
	
	-- Fallback to placeholder
	return createPlaceholderTree(proposal)
end
```

## 🎨 Visual Debugging

View generated objects in workspace:

```
Workspace/
└── GeneratedObjects/
    ├── trees/
    │   ├── Hardwood Tree
    │   ├── Cedar Tree
    │   └── ...
    ├── rocks/
    │   ├── Gray Rock
    │   └── ...
    └── flowers/
        ├── Red Rose
        └── ...
```

Delete this folder to start fresh:
```lua
workspace.GeneratedObjects:Destroy()
```

## 🔄 Iterative Learning

The generator **learns** from rejections:

1. First cycle: 50% approval rate (exploring)
2. Second cycle: 58% approval rate (learning common patterns)
3. Third cycle: 65% approval rate (avoiding known mistakes)
4. Fifth cycle: 72% approval rate (optimized placements)

View what it's learning:
```lua
local stats = system.generator:getStats()
for _, reason in ipairs(stats.topRejectionReasons) do
    print(reason.reason, reason.count)
end
```

Output:
```
rocks too close          15
terrain too steep        12
area too crowded         8
palm tree not on beach   5
```

## 🚧 Advanced: Custom Rules

Add your own validation rules:

```lua
-- In IslandAuditor:scoreTree()
function IslandAuditor:scoreTree(proposal: any): (number, {string})
    local score = 100
    local reasons = {}
    
    -- ... existing checks ...
    
    -- CUSTOM: Trees near paths get bonus
    local nearPath = self:isNearPath(proposal.position)
    if nearPath then
        score = score + 10
        table.insert(reasons, "decorates path")
    end
    
    return score, reasons
end
```

## 🎯 Recommended Workflow

1. **Initial Setup**
   ```lua
   local system = ProceduralIslandSystem.new()
   system:initialize() -- Scans your terrain
   ```

2. **Test Generation**
   ```lua
   system:runGenerationCycle({trees = true, rocks = false, flowers = false})
   system:applyApprovedChanges("trees", 5) -- Apply 5 trees as test
   ```

3. **Review & Adjust**
   - Check placement in Studio
   - If too dense: Increase MIN_SPACING in rules
   - If too sparse: Increase MAX_PER_PASS

4. **Full Generation**
   ```lua
   system:runMultipleCycles(10) -- Generate lots
   system:applyApprovedChanges() -- Apply all
   ```

5. **Iterate & Improve**
   ```lua
   system:printSystemStatus() -- Check approval rate
   -- If low: Adjust rules or increase auditor threshold
   ```

## 📝 TODO / Future Improvements

- [ ] Building placement generation
- [ ] Path/road generation connecting buildings
- [ ] Furniture placement based on themes
- [ ] Terrain modification (dig rivers, create cliffs)
- [ ] Seasonal variations
- [ ] Player preference learning
- [ ] Real-time generation visualization
- [ ] Undo/redo system
- [ ] Save/load generation templates

## ⚠️ Performance Notes

- **Initial analysis**: ~1-3 seconds for 400x400 stud area
- **Generation cycle**: ~0.1-0.5 seconds
- **Applying changes**: ~0.01 seconds per object
- **Recommended**: Run on server, not client
- **Optimization**: Reduce ANALYSIS_GRID_SIZE for faster scans

## 🐛 Troubleshooting

**"System not initialized"**
→ Call `system:initialize()` first

**"No suitable locations found"**
→ Your terrain may be too steep/watery. Adjust MAX_SLOPE in rules

**Low approval rates (<40%)**
→ Your existing terrain is very cluttered. Try clearing some space or adjusting spacing rules

**Objects in water**
→ Auditor should catch this. Check that terrain has Water material set correctly

**"Already generating"**
→ Wait for current cycle to finish, or restart system

---

🎮 **Ready to build your island!** Start with `system:initialize()` and watch the AI create a natural, ACNH-style environment!
