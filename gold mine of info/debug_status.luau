--[[
	DEBUG STATUS CHECKER
	Run this in Command Bar in Studio to see what's spawned
	
	Usage: Copy and paste into Command Bar, press Enter
]]

print("=== 🔍 GAME STATUS CHECK ===")

-- Check terrain
local terrainFolder = workspace:FindFirstChild("forest_glade_terrain")
if terrainFolder then
    print("✅ Island terrain folder exists")
    print("   Parts in terrain:", #terrainFolder:GetChildren())
    for _, child in ipairs(terrainFolder:GetChildren()) do
        if child:IsA("BasePart") then
            print("   - " .. child.Name .. " at " .. tostring(child.Position))
        end
    end
else
    print("❌ No terrain folder found")
end

-- Check villagers
local villagersFolder = workspace:FindFirstChild("Villagers")
if villagersFolder then
    print("\n✅ Villagers folder exists")
    local count = 0
    for _, villager in ipairs(villagersFolder:GetChildren()) do
        if villager:IsA("Model") then
            count = count + 1
            local primary = villager.PrimaryPart or villager:FindFirstChild("Body")
            if primary then
                print("   - " .. villager.Name .. " at Y=" .. math.floor(primary.Position.Y))
            end
        end
    end
    print("   Total villagers:", count)
else
    print("❌ No villagers folder found")
end

-- Check trees
local treesFolder = workspace:FindFirstChild("Trees")
if treesFolder then
    print("\n✅ Trees folder exists")
    local count = 0
    for _, tree in ipairs(treesFolder:GetChildren()) do
        if tree:IsA("Model") then
            count = count + 1
        end
    end
    print("   Total trees:", count)
else
    print("❌ No trees folder found")
end

-- Check spawn location
local spawn = workspace:FindFirstChild("SpawnLocation")
if spawn then
    print("\n✅ Spawn location at Y=" .. math.floor(spawn.Position.Y))
else
    print("\n❌ No spawn location")
end

-- Check player
local player = game.Players:GetPlayers()[1]
if player and player.Character then
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        print("\n✅ Player at position:", humanoidRootPart.Position)
    end
end

print("\n=== 📊 QUICK FIXES ===")
print("1. Camera to villagers: Move camera to Y=100-150 area")
print("2. Check HUD: Look for PlayerGui > ScreenGui")
print("3. Bells not updating: Check EconomyService remote events")
