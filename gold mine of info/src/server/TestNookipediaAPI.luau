--[[
	TestNookipediaAPI
	Quick test script to verify Nookipedia API connection and generate data
	
	To run this:
	1. Enable HTTP requests in Studio (Home → Game Settings → Security → Allow HTTP Requests)
	2. Paste this code into the Command Bar in Studio
	3. Run it
	
	Or create a server script temporarily and run the server
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Import services
local NookipediaService = require(ServerScriptService.Server.Services.NookipediaService)
local DataGenerator = require(ServerScriptService.Server.DataGenerator)

print("===========================================")
print("🌴 NOOKIPEDIA DATA TEST (OFFLINE MODE)")
print("===========================================")

print("\n📦 Verifying local data repository...")
local success, result = pcall(function()
	return NookipediaService:GetVillagers({species = "cat", limit = 5})
end)

if success and result then
	print("✅ Local villager lookup successful!")
	print(string.format("   Found %d villager entries", #result))
	if #result > 0 then
		print("   Example villager:", result[1].name)
	end
else
	warn("❌ Failed to access local villager data:", result)
	return
end

print("\n🎨 Generating game data from local tables...")
print("This may take a few seconds...")

local genSuccess, genResult = pcall(function()
	return DataGenerator.GenerateAllData()
end)

if genSuccess then
	print("✅ Data generation complete!")
	print("\n📊 Generated Data Summary:")
	if genResult.villagers then
		print(string.format("   🦝 Villagers: %d", #genResult.villagers))
	end
	if genResult.fish then
		print(string.format("   🐟 Fish: %d", #genResult.fish))
	end
	if genResult.bugs then
		print(string.format("   🐛 Bugs: %d", #genResult.bugs))
	end
	if genResult.furniture then
		print(string.format("   🪑 Furniture: %d", #genResult.furniture))
	end
	if genResult.tools then
		print(string.format("   🔨 Tools: %d", #genResult.tools))
	end
	
	print("\n📝 Local data cached in memory!")
	print("   Call NookipediaService:ClearCache() to refresh after editing data tables.")
else
	warn("❌ Data generation failed:", genResult)
end

print("\n===========================================")
print("Test complete! Check output above.")
print("===========================================")
