--[[
	QUICK TEST RUNNER
	
	Click this script in Studio Explorer and press F5 to run a quick test!
	Or modify the activeTest variable below to change which test runs.
]]

-- Wait for test system to load
task.wait(1)

-- Choose which test to run (uncomment the one you want):
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
	_G.testSystem.quickTest()
	_G.testSystem.fullGeneration()
	_G.testSystem.clearAll()
	
Make sure Command Bar is set to SERVER context!
	]])
	return
end

-- Run the selected test
if _G.testSystem and _G.testSystem[activeTest] then
	print("\n🚀 Running test:", activeTest, "\n")
	_G.testSystem[activeTest]()
else
	warn("❌ Test system not found! Make sure IslandGenerationTest.server.luau loaded.")
	warn("   Available:", _G.testSystem and "✅ _G.testSystem exists" or "❌ _G.testSystem missing")
end
