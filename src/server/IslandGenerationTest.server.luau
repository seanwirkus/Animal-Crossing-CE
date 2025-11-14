--[[
	TEST SCRIPT: AI Island Generation
	
	Place this in ServerScriptService to test the procedural generation system.
	
	Or run individual functions from Command Bar:
		_G.testSystem.quickTest()
		_G.testSystem.fullGeneration()
		_G.testSystem.clearAll()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProceduralIslandSystem = require(ReplicatedStorage.Shared.ProceduralIslandSystem)
local TestRegistry = require(ReplicatedStorage.Shared.TestRegistry)

local TestSystem = {}

-- Register with the shared test registry for command bar or other scripts
TestRegistry.register("testSystem", TestSystem)

-- Note: Instructions are available via _G.testSystem.help() or in docs/TESTING_AI_GENERATION.md
-- Removed automatic print statements to reduce console spam

--[[
	Quick test: Generate and apply 10 trees
]]
function TestSystem.quickTest()
    print("\n🧪 QUICK TEST: Generating 10 trees...\n")

    local system = ProceduralIslandSystem.new()
    system:initialize()

    -- Generate only trees
    system:runGenerationCycle({
        trees = true,
        rocks = false,
        flowers = false,
        furniture = false,
    })

    -- Apply just 10 for testing
    system:applyApprovedChanges("trees", 10)

    system:printSystemStatus()

    print("\n✅ Check workspace.GeneratedObjects.trees for results!")
end

--[[
	Full generation: Multiple cycles, all content types
]]
function TestSystem.fullGeneration()
    print("\n🎲 FULL GENERATION: Running 10 cycles...\n")

    local system = ProceduralIslandSystem.new()
    system:initialize()

    -- Run 10 generation cycles
    system:runMultipleCycles(10)

    -- Apply all approved changes
    system:applyApprovedChanges()

    system:printSystemStatus()

    print("\n✅ Generation complete! Check workspace.GeneratedObjects/")
end

--[[
	Iterative test: Watch AI learn over time
]]
function TestSystem.watchLearning()
    print("\n📊 LEARNING TEST: Observing AI improvement...\n")

    local system = ProceduralIslandSystem.new()
    system:initialize()

    -- Run 20 cycles and track approval rate
    for i = 1, 20 do
        system:runGenerationCycle()

        local stats = system.generator:getStats()
        print(string.format("Cycle %d: Approval rate: %.1f%%", i, stats.approvalRate))

        task.wait(0.5)
    end

    -- Apply everything
    system:applyApprovedChanges()

    print("\n📈 Final Stats:")
    system:printSystemStatus()
end

--[[
	Custom test: Trees only, high quality
]]
function TestSystem.highQualityTrees()
    print("\n🌳 HIGH QUALITY TREES: Strict validation...\n")

    local system = ProceduralIslandSystem.new()
    system:initialize()

    -- Run with 80% minimum score (very strict)
    for _ = 1, 5 do
        system:runGenerationCycle({
            trees = true,
            rocks = false,
            flowers = false,
        }, 80) -- 80% minimum score
    end

    system:applyApprovedChanges()
    system:printSystemStatus()
end

--[[
	Rock cluster test
]]
function TestSystem.generateRockClusters()
    print("\n🪨 ROCK CLUSTERS: Natural formations...\n")

    local system = ProceduralIslandSystem.new()
    system:initialize()

    system:runGenerationCycle({
        trees = false,
        rocks = true,
        flowers = false,
    })

    system:applyApprovedChanges("rocks")
    system:printSystemStatus()
end

--[[
	Flower garden test
]]
function TestSystem.generateFlowerGardens()
    print("\n🌸 FLOWER GARDENS: Colorful patches...\n")

    local system = ProceduralIslandSystem.new()
    system:initialize()

    -- Generate lots of flowers
    for _ = 1, 5 do
        system:runGenerationCycle({
            trees = false,
            rocks = false,
            flowers = true,
        })
    end

    system:applyApprovedChanges("flowers")
    system:printSystemStatus()
end

--[[
	Clear all generated objects
]]
function TestSystem.clearAll()
    print("\n🗑️ CLEARING: Removing all generated objects...\n")

    local generatedFolder = workspace:FindFirstChild("GeneratedObjects")
    if generatedFolder then
        generatedFolder:Destroy()
        print("✅ Cleared workspace.GeneratedObjects")
    else
        print("ℹ️ No generated objects found")
    end
end

--[[
	Analysis only (no generation)
]]
function TestSystem.analyzeOnly()
    print("\n🔍 ANALYSIS: Scanning terrain...\n")

    local IslandAnalyzer = require(game.ReplicatedStorage.Shared.IslandAnalyzer)
    local analyzer = IslandAnalyzer.new(workspace.Terrain)

    analyzer:analyzeIsland()

    local data = analyzer:exportData()
    print("\n📊 Analysis Results:")
    print(string.format("   Grid cells: %d", data.cellCount))
    print(string.format("   Flat areas: %d", data.flatAreas))
    print(string.format("   Beaches: %d", data.beaches))
    print("\n   Existing Objects:")
    print(string.format("   - Trees: %d", data.objects.trees))
    print(string.format("   - Rocks: %d", data.objects.rocks))
    print(string.format("   - Flowers: %d", data.objects.flowers))
    print(string.format("   - Buildings: %d", data.objects.buildings))
    print(string.format("   - Furniture: %d", data.objects.furniture))
end

--[[
	Stats only (no changes)
]]
function TestSystem.getStats()
    print("\n📊 STATISTICS TEST: Generating without applying...\n")

    local system = ProceduralIslandSystem.new()
    system:initialize()

    -- Run 5 cycles but don't apply
    system:runMultipleCycles(5)

    print(string.format("\n📈 Pending changes: %d", system:getPendingCount()))
    print("ℹ️ (Not applied - use system:applyApprovedChanges() to apply)")

    system:printSystemStatus()
end

-- Auto-run on server start (comment out if you want manual control)
-- TestSystem.quickTest()

-- Help function to show available commands
function TestSystem.help()
    print(
        "\n═══════════════════════════════════════════"
    )
    print("  AI ISLAND GENERATION TEST SYSTEM")
    print(
        "═══════════════════════════════════════════"
    )
    print("\nAvailable Commands (from Command Bar):")
    print("  _G.testSystem.quickTest()              -- Quick 10-tree test")
    print("  _G.testSystem.fullGeneration()         -- Full island generation")
    print("  _G.testSystem.watchLearning()          -- Watch AI learn")
    print("  _G.testSystem.highQualityTrees()       -- Strict tree placement")
    print("  _G.testSystem.generateRockClusters()   -- Rock formations")
    print("  _G.testSystem.generateFlowerGardens()  -- Flower patches")
    print("  _G.testSystem.analyzeOnly()            -- Just scan terrain")
    print("  _G.testSystem.clearAll()               -- Delete generated objects")
    print("  _G.testSystem.help()                   -- Show this help")
    print(
        "═══════════════════════════════════════════"
    )
    print("\n⚠️  IMPORTANT: Use COMMAND BAR in SERVER CONTEXT!")
    print("   (Change dropdown from 'Client' to 'Server')")
    print("\n📚 Full guide: docs/TESTING_AI_GENERATION.md\n")
end

return TestSystem
