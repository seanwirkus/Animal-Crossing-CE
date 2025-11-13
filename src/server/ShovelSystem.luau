--[[
	ShovelSystem.luau
	
	Handles shovel digging mechanics:
	- Digging holes in the ground
	- Finding buried items/bells
	- Filling holes back in
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ShovelSystem = {}

-- Load CurrencyManager for adding bells
local CurrencyManager = require(script.Parent:WaitForChild("CurrencyManager"))

-- Configuration
local HOLE_ASSET_ID = 98139431900134
local X_MARKER_ASSET_ID = 95502544899864
local DIG_RANGE = 10  -- How close player needs to be
local DIG_COOLDOWN = 1  -- Seconds between digs

-- Player cooldowns
local playerCooldowns = {}

-- Possible items to find when digging
local BURIED_ITEMS = {
	{itemId = "bells", chance = 0.4, amount = {min = 100, max = 1000}},
	{itemId = "iron_nugget", chance = 0.2, amount = {min = 1, max = 3}},
	{itemId = "clay", chance = 0.15, amount = {min = 1, max = 2}},
	{itemId = "stone", chance = 0.15, amount = {min = 1, max = 3}},
	{itemId = "fossil", chance = 0.1, amount = {min = 1, max = 1}},
}

--[[
	Creates a hole at the given position
]]
local function createHole(position)
	local success, holeModel = pcall(function()
		return game:GetService("InsertService"):LoadAsset(HOLE_ASSET_ID)
	end)
	
	if not success or not holeModel then
		return nil
	end
	
	local hole = holeModel:GetChildren()[1]
	if not hole then
		holeModel:Destroy()
		return nil
	end
	
	hole = hole:Clone()
	holeModel:Destroy()
	
	-- Position the hole
	if hole:IsA("Model") and hole.PrimaryPart then
		hole:MoveTo(position)
	elseif hole:IsA("BasePart") then
		hole.Position = position
	end
	
	hole.Name = "DugHole"
	
	-- Parent to workspace
	local holesFolder = Workspace:FindFirstChild("DugHoles")
	if not holesFolder then
		holesFolder = Instance.new("Folder")
		holesFolder.Name = "DugHoles"
		holesFolder.Parent = Workspace
	end
	
	hole.Parent = holesFolder
	
	return hole
end

--[[
	Finds the nearest X marker (dig spot) - checks Fossils, Bells, and Holes folders
]]
local function findNearestDigSpot(position)
	local nearestSpot = nil
	local nearestDistance = DIG_RANGE
	
	-- Check Fossils folder (X markers for fossils)
	local fossilsFolder = Workspace:FindFirstChild("Fossils")
	if fossilsFolder then
		for _, fossil in ipairs(fossilsFolder:GetChildren()) do
			local fossilPos = fossil:IsA("Model") and fossil:GetPivot().Position or fossil.Position
			local distance = (position - fossilPos).Magnitude
			
			if distance < nearestDistance then
				nearestDistance = distance
				nearestSpot = fossil
			end
		end
	end
	
	-- Check Bells folder (bell markers)
	local bellsFolder = Workspace:FindFirstChild("Bells")
	if bellsFolder then
		for _, bell in ipairs(bellsFolder:GetChildren()) do
			local bellPos = bell:IsA("Model") and bell:GetPivot().Position or bell.Position
			local distance = (position - bellPos).Magnitude
			
			if distance < nearestDistance then
				nearestDistance = distance
				nearestSpot = bell
			end
		end
	end
	
	-- Check Holes folder (legacy X markers)
	local holesFolder = Workspace:FindFirstChild("Holes")
	if holesFolder then
		for _, hole in ipairs(holesFolder:GetChildren()) do
			local holePos = hole:IsA("Model") and hole:GetPivot().Position or hole.Position
			local distance = (position - holePos).Magnitude
			
			if distance < nearestDistance then
				nearestDistance = distance
				nearestSpot = hole
			end
		end
	end
	
	return nearestSpot
end

--[[
	Rolls for a random buried item
]]
local function rollForItem()
	local roll = math.random()
	local cumulative = 0
	
	for _, item in ipairs(BURIED_ITEMS) do
		cumulative = cumulative + item.chance
		if roll <= cumulative then
			local amount = math.random(item.amount.min, item.amount.max)
			return item.itemId, amount
		end
	end
	
	-- Fallback to bells
	return "bells", math.random(100, 500)
end

--[[
	Handles a player digging
]]
local function handleDig(player)
	local userId = player.UserId
	
	-- Check cooldown
	if playerCooldowns[userId] and tick() - playerCooldowns[userId] < DIG_COOLDOWN then
		return
	end
	
	-- Check if player has shovel equipped
	local character = player.Character
	if not character then return end
	
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or not tool.Name:lower():find("shovel") then
		return  -- Not holding a shovel
	end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Find nearest dig spot
	local digSpot = findNearestDigSpot(rootPart.Position)
	
	if digSpot then
		-- Digging an X marker spot
		local holePos = digSpot:IsA("Model") and digSpot:GetPivot().Position or digSpot.Position
		
		-- Check dig spot type (Fossil, Bell, or generic)
		local digType = digSpot:GetAttribute("DigType")
		local itemId = digSpot:GetAttribute("ItemId")
		local bellAmount = digSpot:GetAttribute("BellAmount")
		
		local foundItemId = itemId
		local foundAmount = 1
		
		if digType == "bells" and bellAmount then
			-- This is a bell marker - give bells directly
			foundItemId = "bells"
			foundAmount = tonumber(bellAmount) or math.random(100, 1000)
			
			-- Add bells to player currency
			local success = CurrencyManager.addBells(player, foundAmount)
			if success then
				print("[ShovelSystem] 💰 Player", player.Name, "dug up", foundAmount, "bells")
			else
				warn("[ShovelSystem] ❌ Failed to add bells to player", player.Name)
			end
		elseif digType == "fossil" then
			-- This is a fossil marker - give fossil
			foundItemId = "fossil"
			foundAmount = 1
			
			-- TODO: Add fossil to inventory
			print("[ShovelSystem] 🦴 Player", player.Name, "dug up a fossil")
		else
			-- Generic dig spot - roll for item
			foundItemId, foundAmount = rollForItem()
			
			-- If it's bells, add to currency
			if foundItemId == "bells" then
				local success = CurrencyManager.addBells(player, foundAmount)
				if success then
					print("[ShovelSystem] 💰 Player", player.Name, "dug up", foundAmount, "bells")
				else
					warn("[ShovelSystem] ❌ Failed to add bells to player", player.Name)
				end
			else
				-- TODO: Add item to inventory
				print("[ShovelSystem] Player", player.Name, "dug up", foundAmount, "x", foundItemId)
			end
		end
		
		-- Create hole
		createHole(holePos)
		
		-- Remove the X marker
		digSpot:Destroy()
		
		-- Set cooldown
		playerCooldowns[userId] = tick()
		
		-- Fire event to client for visual feedback
		local digEvent = ReplicatedStorage:FindFirstChild("ShovelDig")
		if digEvent then
			digEvent:FireClient(player, foundItemId, foundAmount)
		end
		
	else
		-- Digging in random spot - just create a hole
		local digPos = rootPart.Position + (rootPart.CFrame.LookVector * 3)
		
		-- Raycast to ground
		local rayOrigin = digPos + Vector3.new(0, 5, 0)
		local rayDirection = Vector3.new(0, -20, 0)
		
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = {Workspace.Terrain}
		
		local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		
		if rayResult then
			createHole(rayResult.Position + Vector3.new(0, 0.5, 0))
			print("[ShovelSystem] Player", player.Name, "dug a hole")
			
			-- Set cooldown
			playerCooldowns[userId] = tick()
		end
	end
end

--[[
	Initializes the shovel system
]]
function ShovelSystem.init()
	print("[ShovelSystem] 🔨 Initializing shovel system...")
	
	-- Create RemoteEvent for shovel actions
	local shovelEvent = ReplicatedStorage:FindFirstChild("ShovelDig")
	if not shovelEvent then
		shovelEvent = Instance.new("RemoteEvent")
		shovelEvent.Name = "ShovelDig"
		shovelEvent.Parent = ReplicatedStorage
	end
	
	-- Listen for dig requests
	shovelEvent.OnServerEvent:Connect(function(player)
		handleDig(player)
	end)
	
	print("[ShovelSystem] ✅ Shovel system initialized")
end

return ShovelSystem
