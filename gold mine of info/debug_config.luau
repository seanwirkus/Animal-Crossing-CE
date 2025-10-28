-- Debug script to check Config module availability
-- Place this in ServerScriptService to test

print("=== Config Module Debug ===")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Check if Shared folder exists
local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
if not sharedFolder then
    warn("❌ Shared folder not found in ReplicatedStorage")
    return
end
print("✅ Shared folder found")

-- Check if Config module exists
local configModule = sharedFolder:FindFirstChild("Config")
if not configModule then
    warn("❌ Config module not found in ReplicatedStorage.Shared")
    return
end
print("✅ Config module found")

-- Try to require Config
local success, config = pcall(function()
    return require(configModule)
end)

if not success then
    warn("❌ Failed to require Config:", config)
    return
end
print("✅ Config module required successfully")

-- Check if Config has expected properties
if config.StartingBells then
    print("✅ Config.StartingBells =", config.StartingBells)
else
    warn("❌ Config.StartingBells not found")
end

if config.StartingMiles then
    print("✅ Config.StartingMiles =", config.StartingMiles)
else
    warn("❌ Config.StartingMiles not found")
end

print("=== Debug Complete ===")
