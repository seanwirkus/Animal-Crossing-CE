-- PASTE THIS AT THE TOP OF src/server/init.server.luau
-- This will reset your island data when you join

game.Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	print("[RESET] Resetting island data for", player.Name)
	
	local DataStoreService = game:GetService("DataStoreService")
	local playerDataStore = DataStoreService:GetDataStore("PlayerIslands")
	
	local success, err = pcall(function()
		playerDataStore:RemoveAsync("Player_" .. player.UserId)
	end)
	
	if success then
		print("[RESET] ✅ Island data reset for", player.Name)
		player:Kick("✅ Island data reset! Press F5 again to start fresh with onboarding!")
	else
		warn("[RESET] ❌ Failed to reset:", err)
	end
end)

-- DELETE THIS CODE AFTER TESTING!
-- Once you've reset your data, remove this entire section

