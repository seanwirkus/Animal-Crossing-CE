--[[
	QUICK TEST RUNNER
	
	Click this script in Studio Explorer and press F5 to run a quick test!
	Or modify the activeTest variable below to change which test runs.
]]

-- Wait for test system to load
task.wait(1)

-- Choose which test to run (uncomment the one you want):
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TestRegistry"))

local activeTest = "none" -- Change this!

--[[ Available tests:
	"quickTest"           -- 10 trees
	"fullGeneration"      -- Full island (10 cycles)
	"watchLearning"       -- 20 cycles, watch AI improve
	"highQualityTrees"    -- Strict validation (80% min)
	"rockClusters"        -- Generate rock formations
	"flowerGardens"       -- Generate flower patches
	"analyzeOnly"         -- Just scan terrain
	"clearAll"            -- Delete generated objects
]]

if activeTest == "none" then
    print([[
		
🎮 QUICK TEST RUNNER LOADED!

To run a test, edit this script:
1. Change: local activeTest = "none"
2. To:     local activeTest = "quickTest"  
3. Press F5 to reload

Available tests: quickTest, fullGeneration, watchLearning, 
                highQualityTrees, rockClusters, flowerGardens,
                analyzeOnly, clearAll

Or use Server Command Bar:
		local registry = require(game:GetService("ReplicatedStorage").Shared.TestRegistry)
		local system = registry.get("testSystem")
		if system then
			system.quickTest()
		end
	
Make sure Command Bar is set to SERVER context!
	]])
    return
end

local testSystem = TestRegistry.get("testSystem")
if testSystem and testSystem[activeTest] then
    print("\n🚀 Running test:", activeTest, "\n")
    testSystem[activeTest]()
else
    warn("❌ Test system not found! Make sure IslandGenerationTest.server.luau loaded.")
    warn("   Available:", testSystem and "✅ testSystem exists" or "❌ testSystem missing")
end
