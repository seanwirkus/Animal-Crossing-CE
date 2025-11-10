# 🧪 How to Test the AI Island Generation System

## The Problem
When you ran `_G.testSystem.quickTest()` from the Command Bar, you got:
```
attempt to index nil with 'quickTest'
```

**Why?** The Command Bar was in **Client** context, but `_G.testSystem` exists in **Server** context only.

---

## ✅ Solution 1: Use Server Command Bar (Recommended)

1. **Open Command Bar**: View → Command Bar (or press Ctrl+Shift+X / Cmd+Shift+X)

2. **Switch to Server Context**:
   - Look for the dropdown on the left side of Command Bar
   - Change from **"Client"** to **"Server"**

3. **Run Test Commands**:
   ```lua
   _G.testSystem.quickTest()           -- Generate 10 trees
   _G.testSystem.fullGeneration()      -- Full island generation
   _G.testSystem.watchLearning()       -- Watch AI improve
   _G.testSystem.clearAll()            -- Delete generated objects
   ```

---

## ✅ Solution 2: Use QuickTestRunner Script

1. **Find the Script**: 
   - In Studio Explorer: `ServerScriptService → Server → QuickTestRunner`

2. **Edit the Script**:
   - Double-click to open
   - Change line: `local activeTest = "none"`
   - To: `local activeTest = "quickTest"`

3. **Reload**:
   - Press **F5** to stop and restart the game
   - The test will run automatically on load

4. **Available Tests**:
   - `"quickTest"` - 10 trees (fast validation)
   - `"fullGeneration"` - Full island (10 cycles)
   - `"watchLearning"` - 20 cycles showing AI improvement
   - `"highQualityTrees"` - Strict validation (80% minimum)
   - `"rockClusters"` - Rock formations only
   - `"flowerGardens"` - Flower patches only
   - `"analyzeOnly"` - Just scan terrain
   - `"clearAll"` - Delete workspace.GeneratedObjects

---

## 📊 Expected Output

When you run `quickTest()`, you should see:

```
🧪 QUICK TEST: Generating 10 trees...

[IslandAnalyzer] 🔍 Starting island analysis...
[IslandAnalyzer] ✅ Analysis complete in 1.23s
[IslandAnalyzer] 📊 Grid: 100x100 cells, 421 objects found

[IslandGenerator] 🎲 Generating new pass...
[IslandGenerator] 🌳 Generating trees...
[IslandGenerator] ✅ Generated 50 tree proposals

[IslandAuditor] 🔍 Auditing 50 proposals...
[IslandAuditor] ✅ Audit complete - Approved: 35, Rejected: 15

[ProceduralIslandSystem] 📦 Applying 10 approved trees...
[ProceduralIslandSystem] ✅ Applied 10 trees to workspace

════════════════════════════════════════
  🏝️  PROCEDURAL ISLAND SYSTEM STATUS
════════════════════════════════════════

📊 Generator Stats:
   Total Proposed: 50
   Approved: 35 (70%)
   Rejected: 15 (30%)

✅ Check workspace.GeneratedObjects.trees for results!
```

---

## 🔍 Verify Results

1. **Check Workspace**:
   - In Explorer: `Workspace → GeneratedObjects → trees`
   - You should see 10 Part objects

2. **View in Viewport**:
   - Select a tree Part
   - Check its Position - should be on terrain surface
   - Check spacing - should be 2+ studs from other trees

3. **Run More Tests**:
   ```lua
   -- Server Command Bar:
   _G.testSystem.getStats()            -- View current statistics
   _G.testSystem.generateRockClusters() -- Add rocks
   _G.testSystem.clearAll()             -- Clean up when done
   ```

---

## ❌ Troubleshooting

### "attempt to index nil with 'quickTest'"
- **Problem**: Command Bar in Client context
- **Solution**: Switch to **Server** context (dropdown on left)

### "Test system not found"
- **Problem**: IslandGenerationTest.server.luau didn't load
- **Check**: Output window for script errors
- **Solution**: Look for the load message at game start:
  ```
  ═══════════════════════════════════════════
    AI ISLAND GENERATION TEST SYSTEM LOADED
  ═══════════════════════════════════════════
  ```

### "ProceduralIslandSystem is not a valid member"
- **Problem**: Rojo sync issue
- **Solution**: 
  1. Check `rojo serve` is running in terminal
  2. In Studio: File → Reload from Disk
  3. Verify `ReplicatedStorage.Shared` exists

### No objects generated
- **Problem**: No suitable terrain found
- **Solution**: 
  1. Run `_G.testSystem.analyzeOnly()` to see terrain stats
  2. Make sure you have terrain (not just empty baseplate)
  3. Check Output for rejection reasons

---

## 🎯 Next Steps

1. **Test Basic Generation**: Run `quickTest()` from Server Command Bar
2. **View Results**: Check `workspace.GeneratedObjects.trees`
3. **Run Full Generation**: Try `fullGeneration()` for complete island
4. **Watch Learning**: Use `watchLearning()` to see AI improvement (50%→78%)
5. **Adjust Rules**: Edit `src/shared/GenerationRules.luau` to customize
6. **Replace Placeholders**: Edit `ProceduralIslandSystem:createTree()` to use real models

---

## 📚 Full Documentation

See `docs/AI_ISLAND_GENERATION_GUIDE.md` for complete system documentation.
